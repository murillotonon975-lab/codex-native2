@echo off
setlocal
where node.exe >nul 2>nul
if errorlevel 1 (
  echo Teste de catalogo MCP requer Node.js 22 ou superior.
  echo O diagnostico basico continua disponivel em Diagnosticar.cmd.
  echo Nao sera alterada nenhuma configuracao.
  pause
  exit /b 1
)
node.exe "%~dp0scripts\Verificar-Catalogo-MCP.mjs"
set "RESULT=%ERRORLEVEL%"
echo.
if not "%RESULT%"=="0" echo O teste nao comprovou as seis ferramentas. Revise o resultado.
echo Este teste nao executa comandos do Codex e nao valida o conector ChatGPT.
pause
exit /b %RESULT%
