@echo off
setlocal EnableExtensions DisableDelayedExpansion
title Scavland Mod Runtime 0.2.0 Installer

set "PACKAGE_DIR=%~dp0"
set "INSTALLER=%PACKAGE_DIR%Install-Scavland-Mod-Runtime.ps1"

if not exist "%INSTALLER%" (
    echo [ERROR] Install-Scavland-Mod-Runtime.ps1 was not found next to this file.
    pause
    exit /b 1
)

if not "%~1"=="" (
    set "GAME_DIR=%~1"
) else if exist "%PACKAGE_DIR%Scavland.exe" (
    set "GAME_DIR=%PACKAGE_DIR%"
) else if exist "%PACKAGE_DIR%..\Scavland.exe" (
    set "GAME_DIR=%PACKAGE_DIR%..\"
) else (
    set /p "GAME_DIR=Scavland folder path (the folder containing Scavland.exe): "
)

if "%GAME_DIR%"=="" (
    echo [ERROR] No game folder was supplied.
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%INSTALLER%" -GameDirectory "%GAME_DIR%"
set "RESULT=%ERRORLEVEL%"
echo.
if not "%RESULT%"=="0" (
    echo Installation did not complete. Nothing outside the selected game folder was changed.
) else (
    echo Installation complete. Start Scavland normally through Steam.
)
pause
exit /b %RESULT%
