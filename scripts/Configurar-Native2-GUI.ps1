# Painel local de primeira configuracao do Codex Native2 (Windows).
# Este painel gerencia SOMENTE um perfil nao secreto por usuario.
# Nao substitui o tunnelId do conector ChatGPT nem altera arquivos do Codex Web GPT.
[CmdletBinding()]
param([switch]$CheckOnly)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$SettingsRoot = Join-Path $env:LOCALAPPDATA 'CodexNative2'
$SettingsPath = Join-Path $SettingsRoot 'settings.json'
$LauncherConfigPath = Join-Path $HOME '.codex-chatgpt-web\config.json'
$TunnelPattern = '^tunnel_[0-9a-f]{32}$'

function Test-TunnelId {
    param([string]$Value)
    return ($null -ne $Value -and $Value -cmatch $TunnelPattern)
}

function Get-ConfiguredTunnelId {
    if (-not (Test-Path -LiteralPath $LauncherConfigPath)) { return $null }
    try {
        $raw = [IO.File]::ReadAllText($LauncherConfigPath)
        # Examine apenas identificadores sintaticamente validos. Nunca imprimir o JSON.
        $matches = [regex]::Matches($raw, 'tunnel_[0-9a-f]{32}')
        $ids = @($matches | ForEach-Object { $_.Value } | Sort-Object -Unique)
        if ($ids.Count -eq 1) { return [string]$ids[0] }
    } catch { return $null }
    return $null
}

function Get-LocalProfile {
    if (-not (Test-Path -LiteralPath $SettingsPath)) { return $null }
    try {
        $profile = Get-Content -LiteralPath $SettingsPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($profile.format -ne 'codex-native2-settings' -or $profile.version -ne 1 -or
            -not (Test-TunnelId ([string]$profile.tunnelId))) { return $null }
        return [string]$profile.tunnelId
    } catch { return $null }
}

function Save-LocalProfile {
    param([string]$TunnelId)
    if (-not (Test-TunnelId $TunnelId)) {
        throw 'Tunnel ID invalido. Informe tunnel_ seguido de 32 caracteres hexadecimais minusculos.'
    }
    if (-not (Test-Path -LiteralPath $SettingsRoot)) {
        New-Item -ItemType Directory -Path $SettingsRoot -Force | Out-Null
    }
    $tmp = Join-Path $SettingsRoot ('.settings-' + [guid]::NewGuid().ToString('N') + '.tmp')
    $backup = Join-Path $SettingsRoot ('settings.backup-' + (Get-Date).ToString('yyyyMMdd-HHmmss') + '.json')
    $payload = [ordered]@{
        format = 'codex-native2-settings'
        version = 1
        tunnelId = $TunnelId
        updatedAt = (Get-Date).ToUniversalTime().ToString('o')
    }
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    try {
        [IO.File]::WriteAllText($tmp, ($payload | ConvertTo-Json -Depth 4), $utf8)
        if (Test-Path -LiteralPath $SettingsPath) {
            [IO.File]::Replace($tmp, $SettingsPath, $backup)
        } else {
            [IO.File]::Move($tmp, $SettingsPath)
        }
    } finally {
        if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force }
    }
}

function Get-SafeDiagnostics {
    $result = New-Object System.Collections.Generic.List[string]
    $result.Add('CODEX NATIVE2 - DIAGNOSTICO SOMENTE LEITURA')
    $command = Get-Command codex -ErrorAction SilentlyContinue
    if ($null -eq $command) {
        $fallback = Join-Path $env:LOCALAPPDATA 'Programs\OpenAI\Codex\bin\codex.exe'
        if (Test-Path -LiteralPath $fallback) { $command = Get-Item -LiteralPath $fallback }
    }
    if ($null -ne $command) {
        try {
            $exe = if ($command.PSObject.Properties.Name -contains 'Source') { $command.Source } else { $command.FullName }
            $version = (& $exe --version 2>&1 | Select-Object -First 1)
            $result.Add('Codex CLI: ' + [string]$version)
        } catch { $result.Add('Codex CLI: erro ao consultar versao') }
    } else { $result.Add('Codex CLI: nao encontrado') }
    try {
        $health = Invoke-RestMethod -Uri 'http://127.0.0.1:17841/healthz' -TimeoutSec 3
        $result.Add('Launcher: ' + [string]$health.status + '; modo=' + [string]$health.mode + '; versao=' + [string]$health.version)
    } catch { $result.Add('Launcher: sem resposta em 127.0.0.1:17841') }
    $p = @(Get-Process -Name 'tunnel-client' -ErrorAction SilentlyContinue)
    $result.Add('Processo tunnel-client: ' + $(if ($p.Count -gt 0) { 'em execucao' } else { 'nao detectado' }))
    $launcherId = Get-ConfiguredTunnelId
    $profileId = Get-LocalProfile
    if (-not $profileId) { $result.Add('Perfil local: nao configurado') }
    elseif (-not $launcherId) { $result.Add('Perfil local: salvo; tunel do launcher nao identificado') }
    elseif ($profileId -eq $launcherId) { $result.Add('Perfil local e launcher: IDs coincidem') }
    else { $result.Add('Perfil local e launcher: IDs diferentes (alteracao ainda nao aplicada ao launcher)') }
    $result.Add('ATENCAO: processo e porta local nao comprovam MCP ChatGPT.')
    $result.Add('A conexao real requer Verify runtime e uma chamada nativa de leitura.')
    $result.Add('Nenhum segredo, cookie ou chave API foi consultado.')
    return ($result -join [Environment]::NewLine)
}

if ($CheckOnly) {
    Write-Output (Get-SafeDiagnostics)
    exit 0
}

if ($env:OS -ne 'Windows_NT') { throw 'Esta interface requer Windows.' }
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Codex Native2 | Configuracao'
$form.ClientSize = New-Object System.Drawing.Size(770, 570)
$form.StartPosition = 'CenterScreen'
$form.MinimumSize = New-Object System.Drawing.Size(780, 610)
$form.Font = New-Object System.Drawing.Font('Segoe UI', 10)

$title = New-Object System.Windows.Forms.Label
$title.Text = 'Codex Native2 - Configuracao inicial e diagnostico'
$title.Font = New-Object System.Drawing.Font('Segoe UI Semibold', 15)
$title.SetBounds(22, 17, 724, 35)
$form.Controls.Add($title)

$sub = New-Object System.Windows.Forms.Label
$sub.Text = 'Uma unica versao para todos. Cada conta tem seu proprio tunel e permissoes.'
$sub.SetBounds(24, 58, 715, 26)
$form.Controls.Add($sub)

$label = New-Object System.Windows.Forms.Label
$label.Text = 'ID do tunel OpenAI (nao cole chaves de API aqui)'
$label.SetBounds(24, 103, 720, 26)
$form.Controls.Add($label)

$idText = New-Object System.Windows.Forms.TextBox
$idText.SetBounds(24, 134, 715, 31)
$idText.Font = New-Object System.Drawing.Font('Consolas', 10)
$form.Controls.Add($idText)

$existing = Get-LocalProfile
if ($existing) { $idText.Text = $existing }
else {
    $launcher = Get-ConfiguredTunnelId
    if ($launcher) { $idText.Text = $launcher }
}

$detect = New-Object System.Windows.Forms.Button
$detect.Text = 'Detectar tunel do launcher'
$detect.SetBounds(24, 179, 225, 36)
$form.Controls.Add($detect)

$save = New-Object System.Windows.Forms.Button
$save.Text = 'Salvar perfil local'
$save.SetBounds(266, 179, 187, 36)
$form.Controls.Add($save)

$diagnose = New-Object System.Windows.Forms.Button
$diagnose.Text = 'Diagnosticar'
$diagnose.SetBounds(469, 179, 130, 36)
$form.Controls.Add($diagnose)

$settingsInfo = New-Object System.Windows.Forms.Label
$settingsInfo.Text = 'O perfil local nao altera automaticamente o tunel do launcher nem o conector ChatGPT. Para aplicar uma troca, use os fluxos MCP oficiais do Codex Web GPT e depois Verify runtime.'
$settingsInfo.SetBounds(24, 228, 716, 62)
$form.Controls.Add($settingsInfo)

$log = New-Object System.Windows.Forms.TextBox
$log.Multiline = $true
$log.ReadOnly = $true
$log.ScrollBars = 'Vertical'
$log.Font = New-Object System.Drawing.Font('Consolas', 9)
$log.SetBounds(24, 298, 715, 204)
$form.Controls.Add($log)
$log.Text = Get-SafeDiagnostics

$bottom = New-Object System.Windows.Forms.Label
$bottom.Text = 'Segredos nao sao armazenados. Troca do tunel no ChatGPT exige permissao e conexao real do host.'
$bottom.SetBounds(24, 517, 716, 35)
$form.Controls.Add($bottom)

$detect.Add_Click({
    $detected = Get-ConfiguredTunnelId
    if ($detected) {
        $idText.Text = $detected
        $log.Text = 'Tunel detectado do launcher. Clique Salvar perfil local para guardar a preferencia.'
    } else {
        $log.Text = 'Nao foi possivel identificar um unico tunel. Confira Codex Web GPT > MCP.'
    }
})
$save.Add_Click({
    try {
        Save-LocalProfile -TunnelId $idText.Text.Trim()
        $log.Text = 'Perfil nao secreto salvo em LOCALAPPDATA\CodexNative2\settings.json.' + [Environment]::NewLine +
            'Este passo NAO atualiza automaticamente a ligacao MCP do ChatGPT.' + [Environment]::NewLine +
            (Get-SafeDiagnostics)
    } catch { [System.Windows.Forms.MessageBox]::Show($_.Exception.Message,'Codex Native2') | Out-Null }
})
$diagnose.Add_Click({ $log.Text = Get-SafeDiagnostics })
[void]$form.ShowDialog()
