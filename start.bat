@echo off
setlocal
cd /d "%~dp0"

if not exist ".venv\Scripts\python.exe" (
    echo.
    echo   JARVIS is not set up yet. Installing now, this takes a minute...
    echo.
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1"
    if errorlevel 1 (
        echo.
        echo   Setup failed. Check your internet connection and try again.
        pause
        exit /b 1
    )
)

".venv\Scripts\python.exe" "run.py" %*
if errorlevel 1 pause
