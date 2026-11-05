# Codex Native2 - evita repeticao de cadastro MCP durante limite de solicitacoes.
# Nao invoca APIs do ChatGPT, nao tenta contornar limites e nao remove conectores remotos.
[CmdletBinding()]
param(
    [ValidateSet('Inspect','BeforeCreate','ReportRateLimit','RecordSuccess')]
    [string]$Action = 'Inspect',
    [ValidateRange(0,86400)][int]$RetryAfterSeconds = 0,
    [string]$StateRoot = '',
    [switch]$Json
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($StateRoot)) {
    $StateRoot = Join-Path $env:LOCALAPPDATA 'CodexNative2'
}
$statePath = Join-Path $StateRoot 'cadastro-mcp.json'
$now = [DateTimeOffset]::UtcNow
$state = [ordered]@{ schema = 1; consecutiveLimits = 0; nextAttemptUtc = $null; lastError = 'none' }
if (Test-Path -LiteralPath $statePath -PathType Leaf) {
    try {
        $file = Get-Item -LiteralPath $statePath
        if ($file.Length -gt 8192) { throw 'STATE_TOO_LARGE' }
        $saved = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($saved.schema -ne 1 -or $saved.consecutiveLimits -lt 0 -or $saved.consecutiveLimits -gt 20) {
            throw 'STATE_SCHEMA_INVALID'
        }
        $state.consecutiveLimits = [int]$saved.consecutiveLimits
        $state.nextAttemptUtc = $saved.nextAttemptUtc
        $state.lastError = [string]$saved.lastError
    } catch { throw 'CADASTRO_STATE_INVALID_REVIEW_BACKUP' }
}
function Save-State {
    if (-not (Test-Path -LiteralPath $StateRoot -PathType Container)) {
        New-Item -ItemType Directory -Path $StateRoot -Force | Out-Null
    }
    $tmp = Join-Path $StateRoot ('.cadastro-' + [guid]::NewGuid().ToString('N') + '.tmp')
    try {
        [IO.File]::WriteAllText($tmp, ($state | ConvertTo-Json -Depth 4), (New-Object System.Text.UTF8Encoding($false)))
        if (Test-Path -LiteralPath $statePath) {
            Copy-Item -LiteralPath $statePath -Destination ($statePath + '.bak') -Force
        }
        Move-Item -LiteralPath $tmp -Destination $statePath -Force
    } finally {
        if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp }
    }
}
if ($Action -eq 'ReportRateLimit') {
    # Sem cabecalho Retry-After, a espera e heuristica, nao uma autorizacao do servidor.
    $state.consecutiveLimits = [math]::Min(20, $state.consecutiveLimits + 1)
    $suggested = [int][math]::Min(3600, (900 * [math]::Pow(2, [math]::Min(3, $state.consecutiveLimits - 1))))
    $delay = [int][math]::Max($suggested, $RetryAfterSeconds)
    $nextAttempt = $now.AddSeconds($delay)
    # Nunca encurtar um prazo ja informado pelo servidor em nova falha.
    if ($state.nextAttemptUtc) {
        $previous = [DateTimeOffset]::MinValue
        if ([DateTimeOffset]::TryParse([string]$state.nextAttemptUtc, [ref]$previous) -and $previous -gt $nextAttempt) {
            $nextAttempt = $previous
        }
    }
    $state.nextAttemptUtc = $nextAttempt.ToString('o')
    $state.lastError = 'chatgpt_configuration_rate_limit_reported'
    Save-State
} elseif ($Action -eq 'RecordSuccess') {
    # Use somente apos confirmacao real de cadastro no host ChatGPT.
    $state.consecutiveLimits = 0
    $state.nextAttemptUtc = $null
    $state.lastError = 'none'
    Save-State
}
$wait = 0
if ($state.nextAttemptUtc) {
    $until = [DateTimeOffset]::MinValue
    if ([DateTimeOffset]::TryParse([string]$state.nextAttemptUtc, [ref]$until)) {
        $wait = [int][math]::Max(0, [math]::Ceiling(($until - $now).TotalSeconds))
    }
}
$cachePath = Join-Path $env:USERPROFILE '.codex\plugins\cache\created-by-me-remote\codex-native2'
$report = [ordered]@{
    action = $Action
    localCooldownActive = ($wait -gt 0)
    suggestedWaitSeconds = $wait
    canSuggestNewAttempt = ($wait -eq 0)
    native2PackageCachePresent = (Test-Path -LiteralPath $cachePath -PathType Container)
    existingChatGPTRegistration = 'not_verified_use_account_plugin_listing'
    hostRequestQuota = 'not_available'
    cloudConnectionsDeleted = 0
    cause = 'rate_limit_is_not_evidence_of_maximum_connection_count'
    manualRegistrationStillRequired = $true
    modifiedOnlyLocalCooldownState = ($Action -in @('ReportRateLimit','RecordSuccess'))
}
if ($Json) { $report | ConvertTo-Json -Depth 4; return }
Write-Host '=== Codex Native2 - protecao do cadastro MCP ===' -ForegroundColor Cyan
$report.GetEnumerator() | Format-Table Name,Value -AutoSize | Out-Host
if ($wait -gt 0) {
    Write-Host 'Aguarde o prazo informado pelo servidor; esta espera e apenas uma sugestao local.' -ForegroundColor Yellow
} else {
    Write-Host 'Antes de criar outro plugin, confira se Codex Native2 ja consta em ChatGPT > Plugins.'
}
Write-Host 'Reutilize o registro existente. Nao exclua o tunel ativo ou plugins de terceiros.'
Write-Host 'Este assistente nao remove registros remotos nem altera limites impostos pelo ChatGPT.'
