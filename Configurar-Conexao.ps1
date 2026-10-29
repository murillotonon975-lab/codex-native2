[CmdletBinding()]
param([string]$TunnelId, [string]$OutputDirectory, [switch]$NoOpen)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
try {
    if ($env:OS -ne 'Windows_NT') { throw 'Este assistente requer Windows.' }
    if ([string]::IsNullOrWhiteSpace($TunnelId)) {
        Write-Host 'Copie o ID do SEU tunel no launcher Codex Web GPT. Nao informe uma chave API.'
        $TunnelId = Read-Host 'ID do tunel (tunnel_ seguido de 32 caracteres hexadecimais)'
    }
    $TunnelId = $TunnelId.Trim()
    if ($TunnelId -cnotmatch '^tunnel_[0-9a-f]{32}$') { throw 'ID invalido. Use o ID fornecido pelo launcher; nao uma URL, token ou senha.' }
    if (-not $OutputDirectory) { $OutputDirectory = Join-Path $PSScriptRoot 'dados' }
    $OutputDirectory = [IO.Path]::GetFullPath($OutputDirectory)
    # Recusar junctions e links em qualquer ancestral existente.
    $current = $OutputDirectory
    while ($current) {
        if (Test-Path -LiteralPath $current) {
            $item = Get-Item -LiteralPath $current -Force
            if (-not $item.PSIsContainer -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'Escolha uma pasta direta, sem links ou junctions.' }
        }
        $parent = Split-Path $current -Parent
        if (-not $parent -or $parent -eq $current) { break }; $current = $parent
    }
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
    $id = [guid]::NewGuid().ToString('N')
    $stage = Join-Path $OutputDirectory ('pacote-' + $id)
    $package = Join-Path $stage 'codex-native2'
    New-Item -ItemType Directory -Path $package | Out-Null
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'plugin.json') -Destination $package
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'skills') -Destination $package -Recurse
    $mcp = @{ '$schema'='https://agent-plugins.org/schemas/1.0.0/mcp.schema.json'; mcpServers=@{ 'codex-native2'=@{ type='streamable-http'; extensions=@{ 'com.openai'=@{ tunnelId=$TunnelId; auth=@{type='none'} } } } } }
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [IO.File]::WriteAllText((Join-Path $package 'mcp.json'), ($mcp | ConvertTo-Json -Depth 10), $encoding)
    $zip = Join-Path $OutputDirectory ('Codex-Native2-conectado-' + $id + '.zip')
    Compress-Archive -LiteralPath $package -DestinationPath $zip -CompressionLevel Optimal
    Write-Host "Pacote pessoal gerado: $zip" -ForegroundColor Green
    Write-Host 'Importe este ZIP no ChatGPT e autorize o tunel correto. Mantenha o launcher aberto.'
    Write-Host 'Auth none corresponde ao tunel gerenciado pelo host; nao exponha um servidor HTTP publico sem autenticacao.'
    Write-Host 'Depois: Verify runtime, listar ferramentas e chamada somente de leitura. O ZIP gerado nao comprova conexao.'
    Write-Host 'Nao publique este pacote pessoal em repositorios. Nenhuma configuracao do launcher foi alterada.'
    if (-not $NoOpen) { Start-Process explorer.exe -ArgumentList ('/select,"' + $zip + '"') }
} catch { Write-Error $_; exit 1 }
