@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0skills\codex-health\scripts\Check-CodexNative2.ps1"
pause
