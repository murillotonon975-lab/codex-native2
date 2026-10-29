@echo off
setlocal
:menu
cls
echo CODEX NATIVE2 0.4.0 BETA
echo.
echo 1. Abrir painel de perfis
echo 2. Configurar meu tunel e gerar plugin pessoal
echo 3. Diagnosticar conexao (somente leitura)
echo 4. Ler guia de instalacao
echo 5. Sair
choice /c 12345 /n /m "Escolha: "
if errorlevel 5 exit /b 0
if errorlevel 4 (start "" notepad.exe "%~dp0README-PTBR.md" & goto menu)
if errorlevel 3 (call "%~dp0Diagnosticar.cmd" & goto menu)
if errorlevel 2 (call "%~dp0Configurar-Conexao.cmd" & goto menu)
if errorlevel 1 (call "%~dp0Abrir-Painel.cmd" & goto menu)
