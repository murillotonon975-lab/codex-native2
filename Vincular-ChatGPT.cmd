@echo off
setlocal
echo Assistente de vinculacao oficial ChatGPT MCP - somente leitura.
echo Nenhuma alteracao sera feita no launcher, tunel, plugins ou credenciais.
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Vincular-ChatGPT.ps1"
set "RESULT=%ERRORLEVEL%"
pause
exit /b %RESULT%
