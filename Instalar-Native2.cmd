@echo off
setlocal
echo Instalador do painel local Codex Native2.
echo A politica Bypass vale apenas para este processo PowerShell.
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Instalar-Native2.ps1"
if errorlevel 1 echo A instalacao nao foi concluida.
pause
