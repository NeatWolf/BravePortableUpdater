@echo off
setlocal
set "PAUSE_AFTER=1"
for %%A in (%*) do (
    if /I "%%~A"=="-NoPause" set "PAUSE_AFTER=0"
    if /I "%%~A"=="/NoPause" set "PAUSE_AFTER=0"
)
set "BRAVE_PORTABLE_DIR=%~dp0"
if "%BRAVE_PORTABLE_DIR:~-1%"=="\" set "BRAVE_PORTABLE_DIR=%BRAVE_PORTABLE_DIR:~0,-1%"
set "BRAVE_PORTABLE_LOG=%BRAVE_PORTABLE_DIR%\brave-portable-update.log"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Update-BravePortable.ps1" -PortableDir "%BRAVE_PORTABLE_DIR%" %*
set "EXIT_CODE=%ERRORLEVEL%"
if not "%EXIT_CODE%"=="0" (
    echo.
    echo Update did not complete.
    echo Log: "%BRAVE_PORTABLE_LOG%"
    if "%PAUSE_AFTER%"=="1" (
        echo This window is staying open so you can read the details above.
        echo.
        pause
    )
    exit /b %EXIT_CODE%
)
echo.
echo Updater finished. Review the status above to see whether Brave was updated or already current.
echo Log: "%BRAVE_PORTABLE_LOG%"
if "%PAUSE_AFTER%"=="1" (
    echo.
    pause
)
exit /b %EXIT_CODE%
