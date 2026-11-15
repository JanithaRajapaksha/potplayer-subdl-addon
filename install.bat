@echo off
setlocal
title Install SubDL PotPlayer Add-on

:: Check for Administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [INFO] Requesting administrative privileges to install into PotPlayer directory...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd.exe -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

echo ==========================================================
echo    SubDL Subtitle Add-on Installer for Daum PotPlayer
echo ==========================================================
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"

echo.
pause
