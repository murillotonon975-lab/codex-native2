# Instalador local do painel; nao altera Codex Web GPT, MCP ou autenticacao.
[CmdletBinding()]
param(
    [string]$Destination,
    [switch]$NoOpen,
    [switch]$PlanOnly
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-NoReparsePoint {
    param([string]$Path)
    $current = $Path
    while ($current) {
        if (Test-Path -LiteralPath $current) {
            $item = Get-Item -LiteralPath $current -Force
            if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "Destino passa por link ou junction: $current. Escolha uma pasta direta."
            }
            if (-not $item.PSIsContainer) { throw "Destino passa por um arquivo: $current" }
        }
        $parent = Split-Path -Path $current -Parent
        if (-not $parent -or $parent -eq $current) { break }
        $current = $parent
    }
}

try {
    if ($env:OS -ne 'Windows_NT') { throw 'Este instalador requer Windows.' }
    $source = $PSScriptRoot
    $manifest = Get-Content -LiteralPath (Join-Path $source 'plugin.json') -Raw | ConvertFrom-Json
    if ($manifest.name -ne 'codex-native2' -or $manifest.version -notmatch '^\d+\.\d+\.\d+$') {
        throw 'Manifesto do Native2 invalido.'
    }

    # Considera somente discos locais fixos. Destinos removiveis e de rede ficam excluidos.
    $volumes = @(Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' |
        Where-Object { $_.FreeSpace -gt 0 -and $_.DeviceID -match '^[A-Za-z]:$' } |
        Sort-Object -Property FreeSpace -Descending)
    if ($volumes.Count -eq 0) { throw 'Nenhuma unidade local fixa com espaco livre encontrada.' }

    Write-Host '=== CODEX NATIVE2: INSTALACAO DO PAINEL LOCAL ===' -ForegroundColor Cyan
    $volumes | Select-Object DeviceID,
        @{N='Livre_GB';E={[math]::Round($_.FreeSpace / 1GB, 2)}} | Format-Table -AutoSize

    if ([string]::IsNullOrWhiteSpace($Destination)) {
        $suggested = Join-Path ($volumes[0].DeviceID + '\') 'CodexNative2'
        Write-Host "Destino sugerido (mais espaco): $suggested"
        if ($PlanOnly) {
            $Destination = $suggested
        } else {
            $choice = Read-Host 'Enter para usar o destino sugerido ou informe outra pasta completa'
            if ([string]::IsNullOrWhiteSpace($choice)) { $Destination = $suggested } else { $Destination = $choice.Trim() }
        }
    }
    if ($Destination -notmatch '^[A-Za-z]:[\\/]') { throw 'Use uma pasta completa de disco local, como D:\CodexNative2.' }
    $Destination = [IO.Path]::GetFullPath($Destination)
    $root = [IO.Path]::GetPathRoot($Destination)
    $drive = $volumes | Where-Object { $_.DeviceID -eq $root.TrimEnd('\') } | Select-Object -First 1
    if ($null -eq $drive) { throw 'O destino deve estar em uma unidade local fixa disponivel.' }
    if ($Destination.TrimEnd('\') -eq $root.TrimEnd('\')) { throw 'Escolha uma subpasta, nao a raiz do disco.' }
    Assert-NoReparsePoint -Path $Destination

    $files = @(Get-ChildItem -LiteralPath $source -Recurse -File -Force)
    $links = @(Get-ChildItem -LiteralPath $source -Recurse -Force |
        Where-Object { ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0 })
    if ($links.Count -gt 0) { throw 'O pacote contem links. Use o ZIP original extraido.' }
    $bytes = ($files | Measure-Object -Property Length -Sum).Sum
    $required = [math]::Max(100MB, [double]$bytes * 3)
    if ([double]$drive.FreeSpace -lt $required) { throw 'Espaco insuficiente. Reserve ao menos 100 MB para este pacote.' }

    $sourceFull = [IO.Path]::GetFullPath($source).TrimEnd('\')
    $destinationFull = $Destination.TrimEnd('\')
    if ($destinationFull.Equals($sourceFull, [StringComparison]::OrdinalIgnoreCase) -or
        $destinationFull.StartsWith($sourceFull + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Escolha um destino fora da pasta do pacote extraido.'
    }
    $install = Join-Path $Destination ('releases\' + $manifest.version + '-' + [guid]::NewGuid().ToString('N'))
    Write-Host "Pacote: $($manifest.version)"
    Write-Host "Instalacao: $install"
    Write-Host 'Nao registra MCP e nao move o Codex Web GPT existente.'
    if ($PlanOnly) {
        Write-Host 'SIMULACAO: nenhum arquivo alterado.'
        return
    }

    # Versao nova em pasta exclusiva: nenhuma instalacao anterior e sobrescrita.
    New-Item -ItemType Directory -Path $install | Out-Null
    $probe = Join-Path $install '.write-test'
    [IO.File]::WriteAllText($probe, 'Native2')
    Remove-Item -LiteralPath $probe
    foreach ($file in $files) {
        $relative = $file.FullName.Substring($sourceFull.Length).TrimStart('\')
        $target = Join-Path $install $relative
        $parent = Split-Path -Path $target -Parent
        if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
        Copy-Item -LiteralPath $file.FullName -Destination $target
        if ((Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash -ne
            (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash) {
            throw "Falha na verificacao de copia: $relative"
        }
    }
    foreach ($folder in @('dados', 'logs')) {
        New-Item -ItemType Directory -Path (Join-Path $install $folder) | Out-Null
    }
    $record = [ordered]@{
        version = $manifest.version
        installedAt = (Get-Date).ToString('o')
        installPath = $install
        profilesFolder = (Join-Path $install 'dados')
        chatgptMcpRegistered = $false
    }
    $record | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $install 'logs\instalacao.json') -Encoding UTF8
    Write-Host "Instalacao verificada: $install" -ForegroundColor Green
    Write-Host "Ao exportar os perfis no navegador, salve em: $(Join-Path $install 'dados')"
    Write-Host 'Use Iniciar.cmd nesta pasta para abrir o menu novamente.'
    if (-not $NoOpen) { Start-Process -FilePath (Join-Path $install 'Iniciar.cmd') }
} catch {
    Write-Host ('Falha: ' + $_.Exception.Message) -ForegroundColor Red
    Write-Host 'Instalacoes anteriores foram preservadas. Se a copia comecou, pode haver uma pasta parcial no destino informado.'
    exit 1
}
