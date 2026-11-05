@echo off
setlocal
echo CODEX NATIVE2 - TRANSPORTE E CONEXAO
echo.
echo 1. Detectar e selecionar automaticamente (somente leitura)
echo 2. Reutilizar o tunel ativo, sem reiniciar processos
echo 3. Configurar modo MCP local via stdio
echo 4. Preparar tunel online oficial (requer identidade e autorizacao)
echo 5. Diagnosticar perfil online existente
echo 6. Voltar
choice /c 123456 /n /m "Escolha: "
if errorlevel 6 exit /b 0
if errorlevel 5 goto doctor
if errorlevel 4 goto online
if errorlevel 3 goto local
if errorlevel 2 goto existing
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Selecionar-Transporte.ps1" -Mode Auto -Action Inspect
goto end
:existing
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Selecionar-Transporte.ps1" -Mode Existing -Action Configure
goto end
:local
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Selecionar-Transporte.ps1" -Mode Local -Action Configure
goto end
:online
echo A operacao exige tunnel-client oficial, tunnel_id e credencial no ambiente local.
echo O ID de tunel sera reutilizado da configuracao do launcher quando disponivel.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Selecionar-Transporte.ps1" -Mode Online -Action Configure
goto end
:doctor
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Selecionar-Transporte.ps1" -Mode Online -Action Doctor
:end
set "RESULT=%ERRORLEVEL%"
pause
exit /b %RESULT%
