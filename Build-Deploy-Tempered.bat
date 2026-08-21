@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Build-Deploy-Tempered.ps1"
if errorlevel 1 (
    echo.
    echo [FAILED] Tempered build or deployment failed.
    pause
    exit /b 1
)
echo.
echo [SUCCESS] Tempered build and deployment completed.
endlocal
