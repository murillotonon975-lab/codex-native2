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
echo 5. Verificar catalogo de ferramentas MCP (somente leitura)
echo 6. Ler guia de instalacao
echo 7. Sair
choice /c 1234567 /n /m "Escolha: "
if errorlevel 7 exit /b 0
if errorlevel 6 (start "" notepad.exe "%~dp0README-PTBR.md" & goto menu)
if errorlevel 5 (call "%~dp0Verificar-Catalogo-MCP.cmd" & goto menu)
if errorlevel 4 (call "%~dp0Diagnosticar.cmd" & goto menu)
if errorlevel 3 (call "%~dp0Configurar-Conexao.cmd" & goto menu)
if errorlevel 2 (call "%~dp0Abrir-Painel.cmd" & goto menu)
if errorlevel 1 (powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Configurar-Native2-GUI.ps1" & goto menu)
