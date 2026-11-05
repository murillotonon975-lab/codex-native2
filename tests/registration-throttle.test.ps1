# Teste offline do controle de cadastro; nao chama o ChatGPT nem apaga conexoes.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$originalUserProfile = $env:USERPROFILE
$root = Join-Path ([IO.Path]::GetTempPath()) ('Native2RateLimit-' + [guid]::NewGuid().ToString('N'))
try {
    $env:USERPROFILE = $root
    $stateDir = Join-Path $root 'local'
    # O controlador incluido no ZIP fica na raiz do projeto, junto ao .cmd.
    $script = Join-Path (Split-Path -Parent $PSScriptRoot) 'Controlar-Cadastro-MCP.ps1'
    if (-not (Test-Path -LiteralPath $script -PathType Leaf)) { throw 'Controller script missing from project root' }
    $inspection = & $script -Action Inspect -StateRoot $stateDir -Json | ConvertFrom-Json
    if ($inspection.localCooldownActive -or -not $inspection.canSuggestNewAttempt) { throw 'Initial state incorrect' }
    if (Test-Path -LiteralPath $stateDir) { throw 'Inspect must be read-only' }
    $limited = & $script -Action ReportRateLimit -RetryAfterSeconds 1200 -StateRoot $stateDir -Json | ConvertFrom-Json
    if (-not $limited.localCooldownActive -or $limited.suggestedWaitSeconds -lt 1180) { throw 'Rate limit cooldown failed' }
    if ($limited.cloudConnectionsDeleted -ne 0 -or $limited.hostRequestQuota -ne 'not_available') { throw 'False platform claims' }
    $again = & $script -Action ReportRateLimit -StateRoot $stateDir -Json | ConvertFrom-Json
    if ($again.suggestedWaitSeconds -lt 1780) { throw 'Exponential backoff failed' }
    # Se o servidor informar espera maior, novas falhas nao podem encurta-la.
    $long = & $script -Action ReportRateLimit -RetryAfterSeconds 7200 -StateRoot $stateDir -Json | ConvertFrom-Json
    if ($long.suggestedWaitSeconds -lt 7180) { throw 'Server Retry-After was not respected' }
    $afterLong = & $script -Action ReportRateLimit -StateRoot $stateDir -Json | ConvertFrom-Json
    if ($afterLong.suggestedWaitSeconds -lt 7180) { throw 'Repeated limit incorrectly shortened server wait' }
    if (-not (Test-Path -LiteralPath (Join-Path $stateDir 'cadastro-mcp.json.bak'))) { throw 'Backup missing' }
    $text = Get-Content -LiteralPath (Join-Path $stateDir 'cadastro-mcp.json') -Raw
    if ($text -match 'tunnel_[0-9a-f]{32}|sk-[A-Za-z0-9]{24,}') { throw 'Secret in local state' }
    $success = & $script -Action RecordSuccess -StateRoot $stateDir -Json | ConvertFrom-Json
    if ($success.localCooldownActive -or -not $success.canSuggestNewAttempt) { throw 'Cooldown was not cleared' }
    Write-Host 'Registration guard: inspect, rate-limit, backoff, backup and reset passed.'
} finally {
    $env:USERPROFILE = $originalUserProfile
    if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force }
}
