[CmdletBinding()]
param([string]$Repository = 'codex-native2', [ValidateSet('private','public')][string]$Visibility = 'public')
$ErrorActionPreference = 'Stop'
try {
    if ($Repository -notmatch '^[A-Za-z0-9_.-]+$') { throw 'Nome de repositorio invalido.' }
    foreach ($command in @('git','gh')) {
        if (-not (Get-Command $command -ErrorAction SilentlyContinue)) { throw "Instale $command e tente novamente. Este script nao instala programas." }
    }
    & gh auth status
    if ($LASTEXITCODE -ne 0) { throw 'Entre na sua conta executando gh auth login.' }
    if (Test-Path -LiteralPath (Join-Path $PSScriptRoot 'mcp.json')) { throw 'Nao publique um pacote pessoal com mcp.json.' }
    foreach ($dir in @('dados','logs','releases')) {
        if (Test-Path -LiteralPath (Join-Path $PSScriptRoot $dir)) { throw 'Use uma copia limpa do codigo-fonte, sem dados pessoais.' }
    }
    Push-Location $PSScriptRoot
    try {
        if (-not (Test-Path -LiteralPath '.git')) {
            & git init -b main
            if ($LASTEXITCODE -ne 0) { throw 'Falha ao iniciar Git.' }
            & git add -- .
            if ($LASTEXITCODE -ne 0) { throw 'Falha ao preparar arquivos.' }
            & git commit -m 'Release 0.4.0 beta: portable connection setup'
            if ($LASTEXITCODE -ne 0) { throw 'Configure sua identidade Git e repita o commit.' }
        }
        & gh repo create $Repository "--$Visibility" --source . --remote origin --push
        if ($LASTEXITCODE -ne 0) { throw 'Publicacao nao concluida. Confira a conta, permissoes e se o repositorio ja existe.' }
    } finally { Pop-Location }
} catch { Write-Error $_; exit 1 }
