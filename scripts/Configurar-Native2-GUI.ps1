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
$form.ClientSize = New-Object System.Drawing.Size(770, 640)
$form.StartPosition = 'CenterScreen'
$form.MinimumSize = New-Object System.Drawing.Size(780, 680)
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

$integrations = New-Object System.Windows.Forms.Button
$integrations.Text = 'Integracoes'
$integrations.SetBounds(609, 179, 130, 36)
$form.Controls.Add($integrations)

$reportPreview = New-Object System.Windows.Forms.Button
$reportPreview.Text = 'Previa de falha'
$reportPreview.SetBounds(24, 232, 198, 36)
$form.Controls.Add($reportPreview)

$reportPublish = New-Object System.Windows.Forms.Button
$reportPublish.Text = 'Enviar Issue no GitHub'
$reportPublish.SetBounds(242, 232, 220, 36)
$form.Controls.Add($reportPublish)

$reportDelete = New-Object System.Windows.Forms.Button
$reportDelete.Text = 'Apagar Issue corrigida'
$reportDelete.SetBounds(480, 232, 259, 36)
$form.Controls.Add($reportDelete)

$settingsInfo = New-Object System.Windows.Forms.Label
$settingsInfo.Text = 'O perfil local nao altera automaticamente o tunel do launcher nem o conector ChatGPT. Publicar envia somente um resumo sanitizado ao GitHub. Apagar exige comprovacao de correcao e confirmacao.'
$settingsInfo.SetBounds(24, 280, 716, 62)
$form.Controls.Add($settingsInfo)

$log = New-Object System.Windows.Forms.TextBox
$log.Multiline = $true
$log.ReadOnly = $true
$log.ScrollBars = 'Vertical'
$log.Font = New-Object System.Drawing.Font('Consolas', 9)
$log.SetBounds(24, 350, 715, 200)
$form.Controls.Add($log)
$log.Text = Get-SafeDiagnostics

$bottom = New-Object System.Windows.Forms.Label
$bottom.Text = 'Segredos nao sao armazenados. Troca do tunel no ChatGPT exige permissao e conexao real do host.'
$bottom.SetBounds(24, 570, 716, 40)
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
$integrations.Add_Click({
    $node = Get-Command node.exe -ErrorAction SilentlyContinue
    $script = Join-Path $PSScriptRoot 'Inventariar-Integracoes.mjs'
    if ($null -eq $node -or -not (Test-Path -LiteralPath $script)) {
        $log.Text = 'Inventario indisponivel: Node.js ou script ausente. Use Diagnosticar sem alterar configuracoes.'
    } else {
        try {
            $log.Text = (& $node.Source $script 2>&1 | Out-String)
        } catch {
            $log.Text = 'Falha ao consultar catalogo local. Nenhuma configuracao foi alterada.'
        }
    }
})
$reportPreview.Add_Click({
    $node = Get-Command node.exe -ErrorAction SilentlyContinue
    $script = Join-Path $PSScriptRoot 'Relatorio-Falhas-GitHub.mjs'
    if ($null -eq $node -or -not (Test-Path -LiteralPath $script)) {
        $log.Text = 'Gerador de relatorios indisponivel: Node.js ou script ausente.'
    } else {
        try {
            $json = (& $node.Source $script --json 2>&1 | Out-String)
            if ($LASTEXITCODE -ne 0) { throw 'Nao foi possivel gerar o relatorio.' }
            $issue = $json | ConvertFrom-Json
            $log.Text = $issue.title + [Environment]::NewLine + $issue.body + [Environment]::NewLine +
                'PREVIA LOCAL. Nada foi enviado ao GitHub.'
        } catch {
            $log.Text = 'Erro na previa. Nenhuma informacao foi enviada ao GitHub.'
        }
    }
})
$reportPublish.Add_Click({
    $node = Get-Command node.exe -ErrorAction SilentlyContinue
    $script = Join-Path $PSScriptRoot 'Relatorio-Falhas-GitHub.mjs'
    if ($null -eq $node -or -not (Test-Path -LiteralPath $script)) {
        $log.Text = 'Gerador de relatorios indisponivel: Node.js ou script ausente.'
        return
    }
    try {
        $preview = (& $node.Source $script --json 2>&1 | Out-String)
        if ($LASTEXITCODE -ne 0) { throw 'Previa indisponivel.' }
        $issue = $preview | ConvertFrom-Json
        $question = 'Publicar esta Issue de diagnostico no repositorio PUBLICO do GitHub?' +
            [Environment]::NewLine + 'O conteudo sera somente o resumo sanitizado abaixo:' +
            [Environment]::NewLine + [Environment]::NewLine + $issue.body
        $choice = [System.Windows.Forms.MessageBox]::Show(
            $question,'Codex Native2 | Publicar relatorio',
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Warning)
        if ($choice -ne [System.Windows.Forms.DialogResult]::Yes) { return }
        $result = (& $node.Source $script --publish --confirm-publish 2>&1 | Out-String)
        if ($LASTEXITCODE -ne 0) { throw 'Publicacao nao confirmada. Verifique a autenticacao do GitHub.' }
        $published = $result | ConvertFrom-Json
        if ($published.status -ne 'published') { throw 'GitHub nao confirmou a publicacao.' }
        $log.Text = 'Relatorio publicado no GitHub:' + [Environment]::NewLine + $published.url +
            [Environment]::NewLine + 'Nao apagar ate a validacao REAL do Codex Native2 no ChatGPT.'
    } catch {
        $log.Text = 'Nao foi possivel confirmar a publicacao do relatorio. Confira o GitHub.'
    }
})
$reportDelete.Add_Click({
    $node = Get-Command node.exe -ErrorAction SilentlyContinue
    $script = Join-Path $PSScriptRoot 'Relatorio-Falhas-GitHub.mjs'
    if ($null -eq $node -or -not (Test-Path -LiteralPath $script)) {
        $log.Text = 'Gerador de relatorios indisponivel.'
        return
    }
    Add-Type -AssemblyName Microsoft.VisualBasic
    $issueNumber = [Microsoft.VisualBasic.Interaction]::InputBox(
        'Numero da Issue de diagnostico confirmadamente corrigida:',
        'Codex Native2 | Limpeza no GitHub','')
    if (-not ($issueNumber -cmatch '^[1-9][0-9]{0,8}$')) {
        $log.Text = 'Numero invalido ou operacao cancelada.'
        return
    }
    $selector = New-Object System.Windows.Forms.OpenFileDialog
    $selector.Filter = 'Comprovante JSON (*.json)|*.json'
    $selector.Title = 'Selecione a evidencia dos testes remotos aprovados'
    if ($selector.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }
    $question = 'A Issue sera EXCLUIDA no GitHub. Confirmou no ChatGPT que o workspace, ' +
        'codex_tool_inventory e uma chamada nativa de leitura passaram? ' +
        'Esta acao e irreversivel e exige prova recente.'
    $choice = [System.Windows.Forms.MessageBox]::Show(
        $question,'Codex Native2 | Excluir Issue',
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning)
    if ($choice -ne [System.Windows.Forms.DialogResult]::Yes) { return }
    try {
        $result = (& $node.Source $script --delete $issueNumber --proof $selector.FileName --confirm-delete 2>&1 | Out-String)
        if ($LASTEXITCODE -ne 0) { throw 'Exclusao nao confirmada.' }
        $deleted = $result | ConvertFrom-Json
        if ($deleted.status -ne 'deleted_on_github') { throw 'GitHub nao confirmou exclusao.' }
        $log.Text = 'Issue de diagnostico ' + $issueNumber + ' excluida do GitHub. Logs locais preservados.'
    } catch {
        $log.Text = 'Exclusao nao comprovada ou requisitos de validacao nao cumpridos. Issue preservada.'
    }
})
[void]$form.ShowDialog()
