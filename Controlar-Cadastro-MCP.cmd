@echo off
setlocal
echo CODEX NATIVE2 - PROTECAO CONTRA CADASTROS REPETIDOS
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Controlar-Cadastro-MCP.ps1" -Action Inspect
echo.
echo 1. Registrar que o ChatGPT apresentou limite de solicitacoes (define pausa local)
echo 2. Registrar sucesso de cadastro ja confirmado no ChatGPT
echo 3. Voltar sem alterar nada
choice /c 123 /n /m "Escolha: "
if errorlevel 3 exit /b 0
if errorlevel 2 (
    powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Controlar-Cadastro-MCP.ps1" -Action RecordSuccess
    pause
    exit /b 0
)
if errorlevel 1 (
    powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Controlar-Cadastro-MCP.ps1" -Action ReportRateLimit
    pause
)
