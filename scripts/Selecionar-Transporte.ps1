# Codex Native2 - transporte local ou tunel OpenAI existente.
# Sem credenciais embutidas. "Local" significa stdio no computador; nao implica acesso pelo ChatGPT.
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [ValidateSet('Auto','Local','Existing','Online')][string]$Mode='Auto',
    [ValidateSet('Inspect','Configure','Doctor','Run')][string]$Action='Inspect',
    [ValidatePattern('^[A-Za-z0-9_-]{1,40}$')][string]$Profile='codex-native2-local',
    [string]$TunnelId='',
    [switch]$Json
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

function Get-LauncherSettings {
    $file=Join-Path $env:USERPROFILE '.codex-chatgpt-web\config.json'
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { return $null }
    try {
        if ((Get-Item -LiteralPath $file).Length -gt 262144) { return $null }
        return (Get-Content -LiteralPath $file -Raw -Encoding UTF8 | ConvertFrom-Json)
    } catch { return $null }
}
function Get-ExistingTunnelId {
    param($Config)
    if ($null -eq $Config) { return '' }
    # Apenas um ID unico, extraido da configuracao existente; nao imprimir em relatorios.
    $matches=@([regex]::Matches(($Config | ConvertTo-Json -Depth 15), 'tunnel_[0-9a-f]{32}') |
      ForEach-Object { $_.Value } | Sort-Object -Unique)
    if ($matches.Count -eq 1) { return [string]$matches[0] }
    return ''
}
function Get-LocalRuntime {
    param($Config)
    if ($null -eq $Config -or $Config.mode -ne 'full') { return $null }
    $argsList=@($Config.runtimeCommand)
    if ($argsList.Count -ne 2 -or [string]::IsNullOrWhiteSpace($Config.brokerSocketPath)) { return $null }
    $exe=[string]$argsList[0]; $entry=[string]$argsList[1]
    if ([IO.Path]::GetFileName($exe).ToLowerInvariant() -notin @('node.exe','bun.exe','node','bun')) { return $null }
    if ([IO.Path]::GetFileName($entry).ToLowerInvariant() -ne 'cli.js') { return $null }
    if (-not (Test-Path -LiteralPath $exe -PathType Leaf) -or -not (Test-Path -LiteralPath $entry -PathType Leaf)) { return $null }
    return [pscustomobject]@{ exe=$exe; entry=$entry; brokerSocketPath=[string]$Config.brokerSocketPath }
}
function Invoke-Checked {
    param([string]$Exe,[string[]]$Arguments)
    # Nao repassar stdout/stderr ao chat: podem conter paths, IDs e erros com dados locais.
    $output=& $Exe @Arguments 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) { throw 'COMMAND_EXIT_NONZERO' }
}
function Save-ModePreference {
    param([string]$SelectedMode,[string]$SelectedProfile)
    $dir=Join-Path $env:LOCALAPPDATA 'CodexNative2'
    $file=Join-Path $dir 'transporte.json'
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    $data=[ordered]@{ mode=$SelectedMode; profile=$SelectedProfile; updatedAt=(Get-Date).ToString('o'); containsCredentials=$false }
    $text=$data | ConvertTo-Json -Depth 4
    $temporary=Join-Path $dir ('.transport-'+[guid]::NewGuid().ToString('N')+'.tmp')
    try {
        [IO.File]::WriteAllText($temporary, $text, (New-Object System.Text.UTF8Encoding($false)))
        if (Test-Path -LiteralPath $file) {
            Copy-Item -LiteralPath $file -Destination ($file+'.bak') -Force
        }
        Move-Item -LiteralPath $temporary -Destination $file -Force
    } finally {
        if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary }
    }
}
function Get-SafeCommandText {
    param($Runtime)
    # O comando ficara apenas no perfil local do tunnel-client, nao em logs remotos.
    foreach ($part in @($Runtime.exe,$Runtime.entry,$Runtime.brokerSocketPath)) {
        if ($part.Contains('"') -or $part.Contains([char]10) -or $part.Contains([char]13)) {
            throw 'UNSAFE_LOCAL_RUNTIME_PATH'
        }
    }
    return ('"{0}" "{1}" mcp --contract native --broker-socket "{2}"' -f $Runtime.exe,$Runtime.entry,$Runtime.brokerSocketPath)
}

$config=Get-LauncherSettings
$runtime=Get-LocalRuntime -Config $config
$existing=Get-ExistingTunnelId -Config $config
$client=Get-Command 'tunnel-client.exe' -ErrorAction SilentlyContinue
if (-not $client) { $client=Get-Command 'tunnel-client' -ErrorAction SilentlyContinue }
$clientProcess=@(Get-Process -Name 'tunnel-client' -ErrorAction SilentlyContinue).Count -gt 0
$selected=$Mode
if ($Mode -eq 'Auto') {
    if ($existing -and $clientProcess) { $selected='Existing' }
    elseif ($runtime) { $selected='Local' }
    else { $selected='Unavailable' }
}
$id=$TunnelId.Trim()
if ($id -and $id -cnotmatch '^tunnel_[0-9a-f]{32}$') { throw 'INVALID_TUNNEL_ID' }
if (-not $id) { $id=$existing }
$report=[ordered]@{
    requestedMode=$Mode
    selectedMode=$selected
    action=$Action
    launcherRuntimeAvailable=($null -ne $runtime)
    existingTunnelConfigured=([bool]$existing)
    tunnelClientRunning=$clientProcess
    tunnelClientExecutableAvailable=($null -ne $client)
    transportConfigured=$false
    tunnelAuthenticated='not_verified'
    chatgptToolsExposed='not_verified'
    remoteExecution='not_verified'
}
if ($Action -eq 'Inspect') {
    # Nenhuma escrita, processo novo ou credencial lida.
} elseif ($selected -eq 'Unavailable') {
    throw 'LOCAL_RUNTIME_UNAVAILABLE'
} elseif ($selected -eq 'Existing') {
    if (-not $existing) { throw 'EXISTING_TUNNEL_NOT_FOUND' }
    if ($Action -eq 'Run') { throw 'EXISTING_TUNNEL_RUNNING_USE_LAUNCHER' }
    if ($Action -eq 'Doctor') {
        if (-not $clientProcess) { throw 'TUNNEL_CLIENT_NOT_RUNNING' }
        $report.tunnelAuthenticated='not_verified_use_launcher_verify_runtime'
    }
    if ($Action -eq 'Configure') {
        if ($PSCmdlet.ShouldProcess('CodexNative2 transport preference','Reuse existing tunnel')) {
            Save-ModePreference -SelectedMode $selected -SelectedProfile $Profile
            $report.transportConfigured=$true
        }
    }
} elseif ($selected -eq 'Local') {
    if (-not $runtime) { throw 'LOCAL_RUNTIME_UNAVAILABLE' }
    if ($Action -eq 'Configure') {
        if ($PSCmdlet.ShouldProcess('CodexNative2 transport preference','Save local stdio mode')) {
            Save-ModePreference -SelectedMode $selected -SelectedProfile $Profile
            $report.transportConfigured=$true
        }
    } elseif ($Action -eq 'Doctor') {
        $probe=Join-Path $PSScriptRoot 'Verificar-Catalogo-MCP.mjs'
        if (-not (Test-Path -LiteralPath $probe -PathType Leaf)) { throw 'LOCAL_PROBE_NOT_FOUND' }
        Invoke-Checked -Exe $runtime.exe -Arguments @($probe,'--json')
        $report.localMcpProbe='completed_without_error'
    } elseif ($Action -eq 'Run') {
        if (-not $PSCmdlet.ShouldProcess('Local MCP stdio process','Run in foreground')) { return }
        # Espera que um cliente MCP local forneca o protocolo JSON-RPC via stdin/stdout.
        & $runtime.exe $runtime.entry mcp --contract native --broker-socket $runtime.brokerSocketPath
        exit $LASTEXITCODE
    }
} elseif ($selected -eq 'Online') {
    if (-not $runtime) { throw 'LOCAL_RUNTIME_UNAVAILABLE' }
    if (-not $id) { throw 'TUNNEL_ID_REQUIRED_CREATE_IN_PLATFORM_FIRST' }
    if (-not $client) { throw 'TUNNEL_CLIENT_BINARY_REQUIRED' }
    if ($Action -eq 'Configure') {
        if ($clientProcess) { throw 'TUNNEL_ALREADY_RUNNING_USE_EXISTING' }
        if (-not $env:CONTROL_PLANE_API_KEY) { throw 'CONTROL_PLANE_API_KEY_REQUIRED_IN_LOCAL_ENVIRONMENT' }
        if ($PSCmdlet.ShouldProcess($Profile,'Initialize OpenAI Secure MCP Tunnel profile')) {
            $commandText=Get-SafeCommandText -Runtime $runtime
            Invoke-Checked -Exe $client.Source -Arguments @('init','--sample','sample_mcp_stdio_local','--profile',$Profile,'--tunnel-id',$id,'--mcp-command',$commandText)
            Save-ModePreference -SelectedMode $selected -SelectedProfile $Profile
            $report.transportConfigured=$true
        }
    } elseif ($Action -eq 'Doctor') {
        Invoke-Checked -Exe $client.Source -Arguments @('doctor','--profile',$Profile,'--explain')
        $report.onlineDoctor='completed_without_error'
    } elseif ($Action -eq 'Run') {
        if (-not $env:CONTROL_PLANE_API_KEY) { throw 'CONTROL_PLANE_API_KEY_REQUIRED_IN_LOCAL_ENVIRONMENT' }
        if ($clientProcess) { throw 'TUNNEL_ALREADY_RUNNING_USE_EXISTING' }
        if (-not $PSCmdlet.ShouldProcess($Profile,'Run OpenAI Secure MCP Tunnel in foreground')) { return }
        & $client.Source run --profile $Profile
        exit $LASTEXITCODE
    }
}
if ($Json) { $report | ConvertTo-Json -Depth 4 }
else {
    Write-Host '=== Codex Native2 - transporte seguro ==='
    $report.GetEnumerator() | Format-Table Name,Value -AutoSize | Out-Host
    Write-Host 'Local = MCP stdio apenas no PC; Online = tunnel-client e endpoint autorizado na Platform.'
    Write-Host 'Nenhuma modalidade libera por si ferramentas restritas pelo plano/workspace ChatGPT.'
    Write-Host 'Com ferramentas Native2 ausentes, Remote Desktop Commander pode executar tarefas autorizadas diretamente.'
}
