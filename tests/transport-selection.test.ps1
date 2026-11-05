# Teste controlado de selecao de transporte. Ambiente temporario sem rede e sem tunel real.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$originalUserProfile=$env:USERPROFILE
$originalLocalAppData=$env:LOCALAPPDATA
$originalPath=$env:PATH
$root=Join-Path ([IO.Path]::GetTempPath()) ('Native2TransportTest-'+[guid]::NewGuid().ToString('N'))
try {
    $profile=Join-Path $root 'profile'
    $appdata=Join-Path $root 'appdata'
    $configDir=Join-Path $profile '.codex-chatgpt-web'
    $runtimeDir=Join-Path $root 'runtime'
    foreach ($p in @($configDir,$appdata,$runtimeDir)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
    $fakeNode=Join-Path $runtimeDir 'node.exe'
    $fakeEntrypoint=Join-Path $runtimeDir 'cli.js'
    [IO.File]::WriteAllBytes($fakeNode,[byte[]]@(0))
    [IO.File]::WriteAllText($fakeEntrypoint,'// fixture only')
    $configPath=Join-Path $configDir 'config.json'
    $config = [ordered]@{
        mode='full'
        runtimeCommand=@($fakeNode,$fakeEntrypoint)
        brokerSocketPath=(Join-Path $runtimeDir 'broker.sock')
    }
    $config | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $configPath -Encoding UTF8
    $env:USERPROFILE=$profile
    $env:LOCALAPPDATA=$appdata
    $script=Join-Path $PSScriptRoot '..\scripts\Selecionar-Transporte.ps1'
    $inspection=(& $script -Mode Auto -Action Inspect -Json | ConvertFrom-Json)
    if ($inspection.selectedMode -ne 'Local' -or $inspection.transportConfigured) { throw 'Auto detection should select local without writing.' }
    $modeFile=Join-Path $appdata 'CodexNative2\transporte.json'
    if (Test-Path -LiteralPath $modeFile) { throw 'Inspect wrote a profile.' }
    $local=(& $script -Mode Local -Action Configure -Json | ConvertFrom-Json)
    if ($local.selectedMode -ne 'Local' -or -not $local.transportConfigured) { throw 'Local config did not succeed.' }
    $saved=Get-Content -LiteralPath $modeFile -Raw | ConvertFrom-Json
    if ($saved.mode -ne 'Local' -or $saved.containsCredentials) { throw 'Local preference contains secrets or wrong mode.' }
    $config.existingTunnel = 'tunnel_' + ('a' * 32)
    $config | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $configPath -Encoding UTF8
    $existing=(& $script -Mode Existing -Action Configure -Json | ConvertFrom-Json)
    if ($existing.selectedMode -ne 'Existing' -or -not $existing.transportConfigured) { throw 'Existing tunnel reuse config failed.' }
    if (-not (Test-Path -LiteralPath ($modeFile+'.bak'))) { throw 'Profile rollback copy missing.' }
    if ((Get-Content -LiteralPath $modeFile -Raw | ConvertFrom-Json).mode -ne 'Existing') { throw 'Existing profile not saved.' }
    if ($existing.tunnelAuthenticated -ne 'not_verified' -or $existing.remoteExecution -ne 'not_verified') { throw 'Remote state incorrectly claimed.' }
    if ((Get-Content -LiteralPath $modeFile -Raw) -match 'tunnel_[a-f0-9]{32}') { throw 'Tunnel ID was written to local preference.' }
    # Fixture inerte: o caminho precisa ser detectado, mas nunca executado.
    $fakeClient=Join-Path $runtimeDir 'tunnel-client.exe'
    [IO.File]::WriteAllBytes($fakeClient,[byte[]]@(0))
    $script:mockTunnelPath=$fakeClient
    function Get-Process {
        [CmdletBinding()]
        param([string]$Name)
        if ($Name -eq 'tunnel-client') { [pscustomobject]@{Path=$script:mockTunnelPath} }
    }
    $processClient=(& $script -Mode Existing -Action Inspect -Json | ConvertFrom-Json)
    if (-not $processClient.tunnelClientExecutableAvailable -or $processClient.tunnelClientExecutableSource -ne 'running_process') {
        throw 'Running-process executable lookup failed.'
    }
    Remove-Item function:Get-Process -ErrorAction SilentlyContinue
    $env:PATH=$runtimeDir + [IO.Path]::PathSeparator + $originalPath
    $pathClient=(& $script -Mode Existing -Action Inspect -Json | ConvertFrom-Json)
    if (-not $pathClient.tunnelClientExecutableAvailable -or $pathClient.tunnelClientExecutableSource -ne 'PATH') {
        throw 'PATH executable lookup failed.'
    }
    if (($pathClient | ConvertTo-Json) -match [regex]::Escape($root)) { throw 'Private executable path leaked in report.' }
    Write-Host 'Transport inspect, local configure, existing reuse, binary lookup and rollback verification passed.'
} finally {
    $env:USERPROFILE=$originalUserProfile
    $env:LOCALAPPDATA=$originalLocalAppData
    $env:PATH=$originalPath
    Remove-Item function:Get-Process -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force }
}
