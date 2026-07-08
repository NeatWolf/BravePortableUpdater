@echo off
setlocal
set "BRAVE_PORTABLE_DIR=%~dp0"
if "%BRAVE_PORTABLE_DIR:~-1%"=="\" set "BRAVE_PORTABLE_DIR=%BRAVE_PORTABLE_DIR:~0,-1%"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Update-BravePortable.ps1" -PortableDir "%BRAVE_PORTABLE_DIR%" %*
exit /b %ERRORLEVEL%
