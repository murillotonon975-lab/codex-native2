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
echo 5. Inventariar MCPs e ferramentas do computador (somente leitura)
echo 6. Verificar 6 ferramentas nativas do runtime (somente leitura)
echo 7. Vincular ChatGPT ao tunel MCP oficial (assistente somente leitura)
echo 8. Selecionar transporte local ou tunel online
echo 9. Ler guia de instalacao
echo 0. Sair
choice /c 1234567890 /n /m "Escolha: "
if errorlevel 10 exit /b 0
if errorlevel 9 (start "" notepad.exe "%~dp0README-PTBR.md" & goto menu)
if errorlevel 8 (call "%~dp0Selecionar-Transporte.cmd" & goto menu)
if errorlevel 7 (call "%~dp0Vincular-ChatGPT.cmd" & goto menu)
if errorlevel 6 (call "%~dp0Verificar-Catalogo-MCP.cmd" & goto menu)
if errorlevel 5 (call "%~dp0Inventariar-Integracoes.cmd" & goto menu)
if errorlevel 4 (call "%~dp0Diagnosticar.cmd" & goto menu)
if errorlevel 3 (call "%~dp0Configurar-Conexao.cmd" & goto menu)
if errorlevel 2 (call "%~dp0Abrir-Painel.cmd" & goto menu)
if errorlevel 1 (powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Configurar-Native2-GUI.ps1" & goto menu)
