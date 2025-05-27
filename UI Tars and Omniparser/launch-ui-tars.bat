@echo off
REM ===================================================
REM UI-TARS Application Launcher
REM ===================================================

echo Starting UI-TARS environment...

REM Check if PowerShell is available
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo PowerShell is not installed or not in PATH.
    echo Please install PowerShell or add it to your PATH.
    pause
    exit /b 1
)

REM Launch the PowerShell script that manages UI-TARS
powershell.exe -ExecutionPolicy Bypass -File "%~dp0launch-ui-tars.ps1"

REM If PowerShell script exits with an error, pause
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo An error occurred while running UI-TARS.
    pause
)
