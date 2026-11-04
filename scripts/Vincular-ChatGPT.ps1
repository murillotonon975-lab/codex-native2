# Assistente de vinculacao oficial de servidor MCP ao ChatGPT.
# Somente leitura: nao recria tunel, nao manipula credenciais e nao modifica o host.
[CmdletBinding()]
param(
    [switch]$Json,
    [switch]$NoOpen
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-TunnelIds {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return @() }
    try {
        # O identificador nao e chave de API; ainda assim, nunca e incluido no relatorio.
        $raw = [IO.File]::ReadAllText($Path)
        return @([regex]::Matches($raw, 'tunnel_[0-9a-f]{32}') |
            ForEach-Object { $_.Value } | Sort-Object -Unique)
    } catch { return @() }
}

function Get-LocalCatalogStatus {
    param([string]$ScriptPath)
    $node = Get-Command node.exe -ErrorAction SilentlyContinue
    if (-not $node -or -not (Test-Path -LiteralPath $ScriptPath -PathType Leaf)) {
        return 'not_tested_node_unavailable'
    }
    # Um processo .NET isolado permite consultar o codigo de saida sem alterar
    # LASTEXITCODE do PowerShell chamador ou registrar os detalhes do stderr.
    $process = $null
    try {
        $info = New-Object System.Diagnostics.ProcessStartInfo
        $info.FileName = $node.Source
        $info.Arguments = ('"' + $ScriptPath + '" --json')
        $info.UseShellExecute = $false
        $info.CreateNoWindow = $true
        $info.RedirectStandardOutput = $true
        $info.RedirectStandardError = $true
        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $info
        if (-not $process.Start()) { return 'failed' }
        if (-not $process.WaitForExit(16000)) {
            $process.Kill() # Apenas o processo temporario iniciado por este teste.
            return 'timeout'
        }
        $output = $process.StandardOutput.ReadToEnd()
        if ($process.ExitCode -ne 0) { return 'failed' }
        $result = $output | ConvertFrom-Json
        if ($result.found -eq 6 -and $result.expected -eq 6 -and
            @($result.missing).Count -eq 0) { return 'six_of_six_local_only' }
        return 'incomplete'
    } catch { return 'failed' }
    finally {
        if ($null -ne $process) { $process.Dispose() }
    }
}

function Get-PluginManifestStatus {
    param([string]$ExpectedId, [string]$PluginRoot)
    if (-not (Test-Path -LiteralPath $PluginRoot -PathType Container)) {
        return 'not_found'
    }
    $releases = @(Get-ChildItem -LiteralPath $PluginRoot -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '^\d+\.\d+\.\d+$' } |
        Sort-Object { [version]$_.Name } -Descending)
    if ($releases.Count -eq 0) { return 'not_found' }
    $release = $releases[0]
    $detected = New-Object System.Collections.Generic.List[string]
    foreach ($name in @('mcp.json', '.mcp.json')) {
        $path = Join-Path $release.FullName $name
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { continue }
        try {
            $manifest = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
            $value = [string]$manifest.mcpServers.'codex-native2'.extensions.'com.openai'.tunnelId
            if ($value -notmatch '^tunnel_[0-9a-f]{32}$') { return 'invalid_manifest' }
            $detected.Add($value)
        } catch { return 'invalid_manifest' }
    }
    if ($detected.Count -eq 0) { return 'no_mcp_manifest' }
    if (-not $ExpectedId) { return 'launcher_tunnel_unknown' }
    foreach ($value in $detected) {
        if ($value -cne $ExpectedId) { return 'mismatch' }
    }
    return 'match'
}

$launcherConfig = Join-Path $env:USERPROFILE '.codex-chatgpt-web\config.json'
$pluginRoot = Join-Path $env:USERPROFILE '.codex\plugins\cache\created-by-me-remote\codex-native2'
$probe = Join-Path $PSScriptRoot 'Verificar-Catalogo-MCP.mjs'
$ids = @(Get-TunnelIds -Path $launcherConfig)
$expectedId = if ($ids.Count -eq 1) { [string]$ids[0] } else { '' }

$launcher = 'unavailable'
try {
    $health = Invoke-RestMethod -Uri 'http://127.0.0.1:17841/healthz' -TimeoutSec 4
    if ($health.status -eq 'ok' -and $health.mode -eq 'full') {
        $launcher = 'ok_full'
    } elseif ($health.status -eq 'ok') {
        $launcher = 'ok_not_full'
    } else {
        $launcher = 'unexpected_status'
    }
} catch { $launcher = 'unavailable' }

$tunnelClients = @(Get-Process -Name 'tunnel-client' -ErrorAction SilentlyContinue)
$catalog = if ($launcher -eq 'ok_full') {
    Get-LocalCatalogStatus -ScriptPath $probe
} else { 'not_tested_launcher_unavailable' }
$report = [ordered]@{
    launcher = $launcher
    tunnelClientProcess = $(if ($tunnelClients.Count -gt 0) { 'running' } else { 'not_detected' })
    launcherTunnelIdCount = $ids.Count
    pluginManifest = Get-PluginManifestStatus -ExpectedId $expectedId -PluginRoot $pluginRoot
    localToolCatalog = $catalog
    tunnelAuthenticated = 'not_verified'
    chatgptCustomMcpRegistered = 'not_verified'
    chatgptToolCatalog = 'not_verified'
    codexExecFromChatGPT = 'not_verified'
    modifiedFiles = 0
}

if ($Json) {
    $report | ConvertTo-Json -Depth 4
    return
}

Write-Host '=== CODEX NATIVE2 - VINCULACAO MCP COM CHATGPT ===' -ForegroundColor Cyan
$report.GetEnumerator() | Format-Table Name,Value -AutoSize | Out-Host
Write-Host ''
Write-Host 'Passos oficiais no ChatGPT (revisao manual obrigatoria):'
Write-Host '1. Deixe Codex Web GPT aberto no modo full e o tunnel-client ativo.'
Write-Host '2. Acesse ChatGPT > Plugins > + > Adicionar servidor MCP personalizado.'
Write-Host '3. Em Conexao, escolha Tunel e selecione o tunel associado a esta conta/workspace.'
Write-Host '4. Configure a autenticacao exigida pelo servidor e revise o aviso de seguranca.'
Write-Host '5. Crie o plugin, confira as SEIS ferramentas detectadas e habilite-o na conversa.'
Write-Host '6. Em uma NOVA conversa do ChatGPT, chame codex_tool_inventory e codex_exec'
Write-Host '   com uma operacao somente de leitura e confirme o resultado real.'
Write-Host ''
Write-Host 'Se o tunel nao aparecer: verifique associacao ao workspace e permissoes Tunnels Read + Use.'
Write-Host 'Verify runtime, processo ativo e tools/list LOCAL nao provam ferramentas no ChatGPT.'
Write-Host 'Nao reinstale ou apague o plugin anterior, nao recrie o tunel e nao copie chaves para o chat.'
Write-Host 'Nenhuma configuracao foi alterada.'
if (-not $NoOpen) {
    Start-Process 'https://chatgpt.com/'
}
