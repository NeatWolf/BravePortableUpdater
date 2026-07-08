@echo off
setlocal
set "BRAVE_PORTABLE_DIR=%~dp0"
if "%BRAVE_PORTABLE_DIR:~-1%"=="\" set "BRAVE_PORTABLE_DIR=%BRAVE_PORTABLE_DIR:~0,-1%"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Update-BravePortable.ps1" -PortableDir "%BRAVE_PORTABLE_DIR%" %*
set "EXIT_CODE=%ERRORLEVEL%"
if not "%EXIT_CODE%"=="0" (
    echo.
    echo Brave Portable update failed. See the message above.
    echo.
    pause
)
exit /b %EXIT_CODE%
