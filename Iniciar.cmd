@echo off
setlocal
:menu
cls
echo CODEX NATIVE2 - CANAL DE DESENVOLVIMENTO
echo.
echo 1. Configuracao inicial e editar perfil de tunel
echo 2. Abrir painel de perfis MCP
echo 3. Gerar pacote de conexao por usuario (modo legado)
echo 4. Diagnosticar conexao (somente leitura)
echo 5. Ler guia de instalacao
echo 6. Sair
choice /c 123456 /n /m "Escolha: "
if errorlevel 6 exit /b 0
if errorlevel 5 (start "" notepad.exe "%~dp0README-PTBR.md" & goto menu)
if errorlevel 4 (call "%~dp0Diagnosticar.cmd" & pause & goto menu)
if errorlevel 3 (call "%~dp0Configurar-Conexao.cmd" & pause & goto menu)
if errorlevel 2 (call "%~dp0Abrir-Painel.cmd" & goto menu)
if errorlevel 1 (powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Configurar-Native2-GUI.ps1" & goto menu)
