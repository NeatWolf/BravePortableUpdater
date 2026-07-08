@echo off
setlocal
set "PAUSE_AFTER=1"
set "SHOW_HELP=0"
set "SHOW_FULL_HELP=0"
set "NO_LOG=0"
for %%A in (%*) do (
    if /I "%%~A"=="-NoPause" set "PAUSE_AFTER=0"
    if /I "%%~A"=="/NoPause" set "PAUSE_AFTER=0"
    if /I "%%~A"=="-NoLog" set "NO_LOG=1"
    if /I "%%~A"=="/NoLog" set "NO_LOG=1"
    if /I "%%~A"=="-FullHelp" set "SHOW_FULL_HELP=1"
    if /I "%%~A"=="--full-help" set "SHOW_FULL_HELP=1"
    if /I "%%~A"=="/FullHelp" set "SHOW_FULL_HELP=1"
    if /I "%%~A"=="-Help" set "SHOW_HELP=1"
    if /I "%%~A"=="--help" set "SHOW_HELP=1"
    if /I "%%~A"=="-?" set "SHOW_HELP=1"
    if /I "%%~A"=="/?" set "SHOW_HELP=1"
)
set "BRAVE_PORTABLE_DIR=%~dp0"
if "%BRAVE_PORTABLE_DIR:~-1%"=="\" set "BRAVE_PORTABLE_DIR=%BRAVE_PORTABLE_DIR:~0,-1%"
set "BRAVE_PORTABLE_LOG=%BRAVE_PORTABLE_DIR%\brave-portable-update.log"
if "%SHOW_FULL_HELP%"=="1" (
    powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "Get-Help -Full -Name '%~dp0Update-BravePortable.ps1'"
    set "EXIT_CODE=%ERRORLEVEL%"
    if "%PAUSE_AFTER%"=="1" (
        echo.
        pause
    )
    exit /b %EXIT_CODE%
)
if "%SHOW_HELP%"=="1" (
    echo Brave Portable Updater
    echo.
    echo Put these two files next to brave-portable.exe:
    echo   Update-BravePortable.cmd
    echo   Update-BravePortable.ps1
    echo.
    echo Common commands:
    echo   Update-BravePortable.cmd
    echo      Update Brave Portable.
    echo.
    echo   Update-BravePortable.cmd -DryRun
    echo      Preview without changing app or data.
    echo.
    echo   Update-BravePortable.cmd -RestoreLatestBackup -DryRun
    echo      Preview restoring the newest app backup.
    echo.
    echo Safety:
    echo   The updater changes app\ only. It leaves data\ alone.
    echo   If Brave is open, close it and run this again.
    echo.
    echo Windows warning:
    echo   Run only files downloaded from this repository's GitHub release.
    echo   If Properties shows Unblock, use it before running again.
    echo.
    echo More options:
    echo   Update-BravePortable.cmd -FullHelp
    if "%PAUSE_AFTER%"=="1" (
        echo.
        pause
    )
    exit /b 0
)
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Update-BravePortable.ps1" -PortableDir "%BRAVE_PORTABLE_DIR%" %*
set "EXIT_CODE=%ERRORLEVEL%"
if not "%EXIT_CODE%"=="0" (
    echo.
    echo Requested updater action did not complete.
    if "%NO_LOG%"=="1" (
        echo Log: disabled by -NoLog.
    ) else (
        echo Log: "%BRAVE_PORTABLE_LOG%"
    )
    if "%PAUSE_AFTER%"=="1" (
        echo This window is staying open so you can read the details above.
        echo.
        pause
    )
    exit /b %EXIT_CODE%
)
echo.
echo Updater finished. Review the status above to see whether Brave was updated, restored, or already current.
if "%NO_LOG%"=="1" (
    echo Log: disabled by -NoLog.
) else (
    echo Log: "%BRAVE_PORTABLE_LOG%"
)
if "%PAUSE_AFTER%"=="1" (
    echo.
    pause
)
exit /b %EXIT_CODE%
