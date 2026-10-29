# Diagnostico local, somente leitura; nenhuma senha ou token e exibido.
$ErrorActionPreference = 'Continue'
Write-Host '=== CODEX NATIVE2 - DIAGNOSTICO LOCAL (READ ONLY) ===' -ForegroundColor Cyan

$configPath = Join-Path $HOME '.codex-chatgpt-web\config.json'
if (Test-Path -LiteralPath $configPath) {
    try {
        $cfg = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
        Write-Host "Modo do Codex Web GPT: $($cfg.mode)"
    } catch {
        Write-Warning 'config.json existe, mas nao foi possivel ler o modo.'
    }
} else {
    Write-Warning 'config.json nao encontrado no local padrao.'
}

$codex = Get-Command 'codex' -ErrorAction SilentlyContinue
if ($null -ne $codex) {
    try { & codex --version } catch { Write-Warning 'Codex CLI encontrado, mas falhou ao consultar versao.' }
} else {
    Write-Warning 'Codex CLI nao encontrado no PATH.'
}

$listener = Get-NetTCPConnection -LocalPort 17841 -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1
if ($null -ne $listener) {
    $owner = Get-Process -Id $listener.OwningProcess -ErrorAction SilentlyContinue
    Write-Host "Proxy 17841: LISTEN; processo=$($owner.ProcessName); PID=$($listener.OwningProcess)"
} else {
    Write-Host 'Proxy 17841: sem listener detectado.'
}

$procs = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -like '*tunnel*' })
if ($procs.Count -gt 0) {
    foreach ($p in $procs) {
        $connections = @(Get-NetTCPConnection -OwningProcess $p.Id -State Established -ErrorAction SilentlyContinue)
        Write-Host "Tunel: processo=$($p.ProcessName); PID=$($p.Id); conexoes TCP estabelecidas=$($connections.Count)"
    }
} else {
    Write-Host 'Tunel: nenhum processo com nome tunnel detectado.'
}

Write-Host '=== ESPACO LOCAL ==='
Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' |
    Select-Object DeviceID, @{N='Livre_GB';E={[math]::Round($_.FreeSpace / 1GB, 2)}} |
    Format-Table -AutoSize
Write-Host 'ENOSPC: libere espaco na unidade do perfil e temporarios; instalar o painel em outro disco nao move o launcher.'
Write-Host 'OBS: estado TCP nao comprova registro/autenticacao MCP no ChatGPT.'
Write-Host 'Diagnostico concluido: nenhuma configuracao alterada.' -ForegroundColor Green
