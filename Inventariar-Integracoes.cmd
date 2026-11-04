@echo off
setlocal
where node.exe >nul 2>nul
if errorlevel 1 (
  echo O inventario de integracoes requer Node.js 22 ou superior.
  echo O diagnostico basico continua disponivel em Diagnosticar.cmd.
  pause
  exit /b 1
)
node.exe "%~dp0scripts\Inventariar-Integracoes.mjs"
set "RESULT=%ERRORLEVEL%"
echo.
echo Este inventario NAO libera automaticamente plugins internos do ChatGPT.
echo Cada chamada precisa estar disponivel e autorizada na conversa ou tarefa atual.
pause
exit /b %RESULT%
