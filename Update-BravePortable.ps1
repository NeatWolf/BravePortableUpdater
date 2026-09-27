<#
.SYNOPSIS
Updates a Portapps-style Brave Portable app payload.

.DESCRIPTION
Update-BravePortable resolves the latest public Brave Windows x64 release for
the selected channel, downloads Brave's GitHub zip asset, requires Brave's
SHA256 file by default, stages extraction in a temporary folder, verifies the
staged brave.exe version, backs up the existing app folder, and installs the new
app payload.

The updater is intentionally scoped to the app payload. It does not create,
delete, or modify the portable data directory that contains the user's profile,
bookmarks, extensions, settings, cookies, and sessions.

.PARAMETER Edition
Brave channel to install. The default is stable. The release alias is accepted
for stable.

.PARAMETER PortableDir
Path to the Portapps Brave Portable root that contains brave-portable.exe and
app. When omitted, the script uses its own directory.

.PARAMETER Force
Reinstall the currently resolved Brave version even if it is already installed.

.PARAMETER AllowDowngrade
Explicitly allow installing an older Brave version. Older browsers may not be
compatible with profiles opened by newer versions. Force alone does not allow this.

.PARAMETER Launch
Launch brave-portable.exe after a successful update or current-version check.

.PARAMETER DryRun
Resolve versions and report intended actions without downloading or changing
the Brave app payload or portable profile files. Unless -NoLog is set, the
updater still appends status lines to its log.

.PARAMETER RestoreLatestBackup
Restore the newest app payload backup from update-backups instead of resolving
or downloading a Brave release. Use with -DryRun first to preview the restore.

.PARAMETER WaitForExit
Wait for Brave Portable processes from this directory to close instead of
failing immediately.

.PARAMETER AllowMissingHash
Continue when Brave does not publish a SHA256 file for the selected zip. Without
this switch, the updater stops before downloading that asset.

.PARAMETER NoLog
Print status to the console without appending brave-portable-update.log.
Intended for read-only verification passes; normal runs should keep logs on.

.PARAMETER NoPause
Accepted for parity with Update-BravePortable.cmd. The PowerShell script does
not pause by itself.

.EXAMPLE
.\Update-BravePortable.ps1 -DryRun

Checks the target portable folder and reports whether the stable channel would
update without changing the app payload or profile files.

.EXAMPLE
.\Update-BravePortable.ps1 -DryRun -Force -NoLog

Runs a screen-only verification pass that exercises the dry-run action output
even when Brave is already current, without appending the updater log.

.EXAMPLE
.\Update-BravePortable.ps1 -Edition beta

Updates the portable app payload to the latest public beta channel build.

.EXAMPLE
.\Update-BravePortable.ps1 -RestoreLatestBackup -DryRun -NoLog

Shows which app payload backup would be restored without changing app, data, or
the updater log.

.EXAMPLE
.\Update-BravePortable.ps1 -PortableDir D:\Portable\brave-portable -WaitForExit

Runs against an explicit portable root and waits until that copy of Brave exits
before updating.

.INPUTS
None. This script does not accept pipeline input.

.OUTPUTS
None. The updater writes human-readable status messages and uses the process
exit code to report success or failure.

.LINK
https://github.com/NeatWolf/BravePortableUpdater

.LINK
https://github.com/NeatWolf/BravePortableUpdater/releases/latest

.NOTES
Use Update-BravePortable.cmd for Explorer launches. The command wrapper keeps
the window open after completion and prints the log path.
#>
[CmdletBinding()]
param(
    [ValidateSet('stable', 'release', 'beta', 'nightly')]
    [string]$Edition = 'stable',

    [string]$PortableDir = '',

    [switch]$Force,
    [switch]$AllowDowngrade,
    [switch]$Launch,
    [switch]$DryRun,
    [switch]$RestoreLatestBackup,
    [switch]$WaitForExit,
    [switch]$AllowMissingHash,
    [switch]$NoLog,
    [switch]$NoPause
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

if ($NoPause) {
    Write-Verbose 'NoPause is handled by Update-BravePortable.cmd; this PowerShell script never pauses.'
}

if ($NoLog) {
    Write-Verbose 'NoLog is set; status will be printed but not appended to brave-portable-update.log.'
}

if ([string]::IsNullOrWhiteSpace($PortableDir)) {
    $PortableDir = $PSScriptRoot
}

function Resolve-FullPath {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (Test-Path -LiteralPath $Path) {
        return (Resolve-Path -LiteralPath $Path).Path
    }

    $parent = Split-Path -Parent $Path
    $leaf = Split-Path -Leaf $Path
    if (-not $parent) {
        $parent = Get-Location
    }

    return (Join-Path (Resolve-Path -LiteralPath $parent).Path $leaf)
}

$PortableDir = Resolve-FullPath $PortableDir
$PortableExe = Join-Path $PortableDir 'brave-portable.exe'
$AppDir = Join-Path $PortableDir 'app'
$DataDir = Join-Path $PortableDir 'data'
$BackupRoot = Join-Path $PortableDir 'update-backups'
$LogPath = Join-Path $PortableDir 'brave-portable-update.log'
$MetadataRequestTimeoutSec = 60
$DownloadRequestTimeoutSec = 300
$InstallFreeSpaceMarginBytes = 256MB
$BraveRequestHeaders = @{ 'User-Agent' = 'BravePortableUpdater/1.0' }

function Write-UpdaterLog {
    param([Parameter(Mandatory = $true)][string]$Message)

    $line = '[{0}] {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    Write-Information $Message -InformationAction Continue
    if (-not $NoLog) {
        try {
            Add-Content -LiteralPath $LogPath -Value $line -Encoding UTF8
        }
        catch {
            # A diagnostic failure must never interrupt installation or rollback.
            Write-Warning "Could not append to log '$LogPath': $($_.Exception.Message). Read the console output for this run." -WarningAction Continue
        }
    }
}

function Write-DryRunNoChangeMessage {
    param(
        [Parameter(Mandatory = $true)][string]$NoLogItems,
        [Parameter(Mandatory = $true)][string]$LoggedItems
    )

    if ($NoLog) {
        Write-UpdaterLog "Dry run only. No $NoLogItems, or updater log were changed."
        return
    }

    Write-UpdaterLog "Dry run only. No $LoggedItems were changed; only the updater log may have been appended."
}

function Assert-PortappsBraveRoot {
    param([switch]$AllowMissingApp)

    if (-not (Test-Path -LiteralPath $PortableExe -PathType Leaf)) {
        throw "This does not look like a Portapps Brave root. Missing: $PortableExe"
    }
    if (Test-Path -LiteralPath $AppDir -PathType Leaf) {
        throw "Expected an app folder, but found a file: $AppDir"
    }
    if (-not $AllowMissingApp -and -not (Test-Path -LiteralPath $AppDir -PathType Container)) {
        throw "This does not look like a Portapps Brave root. Missing: $AppDir"
    }
}

function Open-UpdaterLock {
    $lockPath = Join-Path $PortableDir '.brave-portable-update.lock'
    try {
        # Keep the file after closing: deleting it would race the next owner.
        return [IO.File]::Open($lockPath, [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
    }
    catch {
        throw "Could not reserve this portable folder for updating. Another updater may be running, or the folder may not be writable. Close other updater windows and retry. Lock: $lockPath. Technical detail: $($_.Exception.Message)"
    }
}

function ConvertTo-BraveVersion {
    param([string]$Version)

    if ([string]::IsNullOrWhiteSpace($Version)) {
        return $null
    }

    $match = [regex]::Match($Version.Trim(), '^(\d+)\.(\d+)\.(\d+)\.(\d+)')
    if ($match.Success -and [int]$match.Groups[1].Value -gt 20) {
        return '{0}.{1}.{2}' -f $match.Groups[2].Value, $match.Groups[3].Value, $match.Groups[4].Value
    }

    $match = [regex]::Match($Version.Trim(), '^(\d+\.\d+\.\d+)')
    if ($match.Success) {
        return $match.Groups[1].Value
    }

    return $Version.Trim()
}

function Get-BraveVersionFromAppDir {
    param([Parameter(Mandatory = $true)][string]$Path)

    $braveExe = Join-Path $Path 'brave.exe'
    if (-not (Test-Path -LiteralPath $braveExe -PathType Leaf)) {
        return [pscustomobject]@{
            Raw = $null
            Normalized = $null
        }
    }

    $raw = (Get-Item -LiteralPath $braveExe).VersionInfo.FileVersion
    return [pscustomobject]@{
        Raw = $raw
        Normalized = ConvertTo-BraveVersion $raw
    }
}

function Get-InstalledBraveVersion {
    Get-BraveVersionFromAppDir -Path $AppDir
}

function Format-ByteSize {
    param([Parameter(Mandatory = $true)][long]$Bytes)

    if ($Bytes -ge 1GB) {
        return '{0:N1} GB' -f ($Bytes / 1GB)
    }

    return '{0:N1} MB' -f ($Bytes / 1MB)
}

function Get-DirectoryByteSize {
    param([Parameter(Mandatory = $true)][string]$Path)

    $total = [long]0
    Get-ChildItem -LiteralPath $Path -Recurse -Force -File | ForEach-Object {
        $total += $_.Length
    }

    return $total
}

function Get-FreeSpaceForPath {
    param([Parameter(Mandatory = $true)][string]$Path)

    $root = [System.IO.Path]::GetPathRoot((Resolve-FullPath $Path))
    if (-not $root) {
        throw "Could not resolve drive root for free-space check: $Path"
    }

    $drive = New-Object -TypeName System.IO.DriveInfo -ArgumentList $root
    [pscustomobject]@{
        Root = $root
        Available = [long]$drive.AvailableFreeSpace
    }
}

function Assert-FreeSpaceForAppInstall {
    param([Parameter(Mandatory = $true)][string]$NewAppDir)

    $portableSpace = Get-FreeSpaceForPath -Path $PortableDir
    $newAppRoot = [System.IO.Path]::GetPathRoot((Resolve-FullPath $NewAppDir))
    $newAppBytes = Get-DirectoryByteSize -Path $NewAppDir
    $requiredBytes = $InstallFreeSpaceMarginBytes

    if (-not $newAppRoot.Equals($portableSpace.Root, [System.StringComparison]::OrdinalIgnoreCase)) {
        $requiredBytes += $newAppBytes
    }

    if ($portableSpace.Available -lt $requiredBytes) {
        throw "Not enough free space on $($portableSpace.Root) to install the staged app payload. Available: $(Format-ByteSize $portableSpace.Available). Required: $(Format-ByteSize $requiredBytes). Free some space and run the updater again. Profile data was not modified: $DataDir"
    }

    Write-UpdaterLog "Free space check passed on $($portableSpace.Root): $(Format-ByteSize $portableSpace.Available) available."
}

function Get-PortableBraveProcess {
    $root = $PortableDir.TrimEnd('\') + '\'
    $names = @('brave.exe', 'brave-portable.exe', 'chrome_proxy.exe')
    $filter = ($names | ForEach-Object { "Name='$_'" }) -join ' OR '

    try {
        $processes = @(Get-CimInstance Win32_Process -Filter $filter -ErrorAction Stop)
    }
    catch {
        throw "Could not check whether Brave Portable is running. No app files were moved. Close Brave and retry; if this persists, restart Windows. Technical detail: $($_.Exception.Message)"
    }
    if (@($processes | Where-Object { -not $_.ExecutablePath -and -not $_.CommandLine }).Count -gt 0) {
        throw 'Could not identify the folder of a running Brave process. Close all Brave instances and retry. No app files were moved.'
    }
    $processes |
        Where-Object {
            ($_.ExecutablePath -and $_.ExecutablePath.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) -or
            ($_.CommandLine -and $_.CommandLine.IndexOf($PortableDir, [System.StringComparison]::OrdinalIgnoreCase) -ge 0)
        }
}

function Wait-ForPortableBraveExit {
    param([switch]$Wait)

    $running = @(Get-PortableBraveProcess)
    if ($running.Count -eq 0) {
        return
    }

    if (-not $Wait) {
        $shown = @($running | Select-Object -First 8)
        $summary = ($shown | ForEach-Object { '{0}({1})' -f $_.Name, $_.ProcessId }) -join ', '
        if ($running.Count -gt $shown.Count) {
            $summary = "$summary, ... and $($running.Count - $shown.Count) more"
        }
        throw @"
Portable Brave is still running from this folder.

Detected $($running.Count) related processes: $summary

Close every Brave Portable window, wait a few seconds, then run Update-BravePortable.cmd again.
Or run Update-BravePortable.cmd -WaitForExit to leave this updater waiting until Brave closes.
"@
    }

    Write-UpdaterLog 'Portable Brave is running; waiting for it to exit...'
    while (@(Get-PortableBraveProcess).Count -gt 0) {
        Start-Sleep -Seconds 2
    }
}

function Invoke-BraveVersionsRequest {
    param([Parameter(Mandatory = $true)][string]$Uri)

    try {
        Invoke-RestMethod -Headers $BraveRequestHeaders -Uri $Uri -TimeoutSec $MetadataRequestTimeoutSec
    }
    catch {
        throw "Could not reach Brave release metadata at $Uri within $MetadataRequestTimeoutSec seconds. Check your internet connection or try again later. Technical detail: $($_.Exception.Message)"
    }
}

function Save-BraveDownload {
    param(
        [Parameter(Mandatory = $true)][string]$Uri,
        [Parameter(Mandatory = $true)][string]$OutFile,
        [Parameter(Mandatory = $true)][string]$Description
    )

    try {
        Invoke-WebRequest -Headers $BraveRequestHeaders -Uri $Uri -OutFile $OutFile -TimeoutSec $DownloadRequestTimeoutSec
    }
    catch {
        throw "Could not download $Description within $DownloadRequestTimeoutSec seconds. Check your internet connection or try again later. Technical detail: $($_.Exception.Message)"
    }
}

function Get-ReleaseAssetDownloadUrl {
    param([Parameter(Mandatory = $true)]$Asset)

    $downloadUrl = $Asset.PSObject.Properties['download_url']
    if ($downloadUrl -and $downloadUrl.Value) {
        return $downloadUrl.Value
    }

    $browserDownloadUrl = $Asset.PSObject.Properties['browser_download_url']
    if ($browserDownloadUrl -and $browserDownloadUrl.Value) {
        return $browserDownloadUrl.Value
    }

    return $null
}

function Resolve-BraveRelease {
    param([Parameter(Mandatory = $true)][string]$RequestedEdition)

    $channel = if ($RequestedEdition -eq 'stable') { 'release' } else { $RequestedEdition }
    $versionUri = "https://versions.brave.com/latest/$channel-windows-x64.version"
    $versionsUri = 'https://versions.brave.com/latest/brave-versions.json'

    Write-UpdaterLog "Resolving latest public $channel build for Windows x64..."
    $targetVersion = ((Invoke-BraveVersionsRequest $versionUri) | Out-String).Trim()
    if (-not $targetVersion) {
        throw "Could not resolve latest $channel version from $versionUri"
    }

    $allVersions = Invoke-BraveVersionsRequest $versionsUri
    $records = @($allVersions.PSObject.Properties.Value | Where-Object { $_.channel -eq $channel })
    $record = $records | Where-Object { $_.name -eq $targetVersion -or $_.tag -eq "v$targetVersion" } | Select-Object -First 1

    if ($record) {
        $tag = $record.tag
        $published = $record.published
        $assets = $record.github.assets
    }
    else {
        $tag = "v$targetVersion"
        $githubReleaseUri = "https://api.github.com/repos/brave/brave-browser/releases/tags/$tag"
        Write-UpdaterLog "Warning: Brave has announced $targetVersion, but its detailed release index has not caught up yet. Checking Brave's official GitHub release $tag instead..."
        try {
            $githubRelease = Invoke-BraveVersionsRequest $githubReleaseUri
        }
        catch {
            throw "Brave has announced $targetVersion, but its detailed release index is not ready yet and the official GitHub release $tag could not be checked. Try again later, or check your internet connection. Technical detail: $($_.Exception.Message)"
        }

        $published = $githubRelease.published_at
        $assets = $githubRelease.assets
    }

    $assetName = "brave-v$targetVersion-win32-x64.zip"
    $asset = $assets | Where-Object { $_.name -eq $assetName } | Select-Object -First 1
    if (-not $asset) {
        throw "Brave release $tag was found, but it does not include the expected Windows x64 zip ($assetName). This can happen while a release is still publishing; try again later."
    }

    $shaAsset = $assets | Where-Object { $_.name -eq "$assetName.sha256" } | Select-Object -First 1
    $assetUrl = Get-ReleaseAssetDownloadUrl $asset
    if (-not $assetUrl) {
        throw "Brave release $tag lists $assetName, but no download link was provided. Try again later; the release may still be publishing."
    }

    $sha256Url = $null
    if ($shaAsset) {
        $sha256Url = Get-ReleaseAssetDownloadUrl $shaAsset
        if (-not $sha256Url) {
            throw "Brave release $tag lists $assetName.sha256, but no checksum download link was provided. Try again later; the release may still be publishing."
        }
    }

    [pscustomobject]@{
        Channel = $channel
        Version = $targetVersion
        Tag = $tag
        Published = $published
        AssetName = $asset.name
        AssetUrl = $assetUrl
        Sha256Url = $sha256Url
    }
}

function Save-ReleaseAsset {
    param(
        [Parameter(Mandatory = $true)]$Release,
        [Parameter(Mandatory = $true)][string]$DownloadDir,
        [switch]$AllowMissingHash
    )

    New-Item -ItemType Directory -Path $DownloadDir -Force | Out-Null
    $zipPath = Join-Path $DownloadDir $Release.AssetName

    if (-not $Release.Sha256Url) {
        if (-not $AllowMissingHash) {
            throw "No SHA256 asset was published for $($Release.AssetName). The updater stopped before downloading or installing anything. Rerun with -AllowMissingHash only if you accept version-check-only verification for this release."
        }

        Write-UpdaterLog 'Warning: no SHA256 asset found for this release; -AllowMissingHash was set, so staged brave.exe version verification will be used after extraction.'
    }

    Write-UpdaterLog "Downloading $($Release.AssetName)..."
    Save-BraveDownload -Uri $Release.AssetUrl -OutFile $zipPath -Description $Release.AssetName

    if ($Release.Sha256Url) {
        $shaPath = "$zipPath.sha256"
        Save-BraveDownload -Uri $Release.Sha256Url -OutFile $shaPath -Description "$($Release.AssetName).sha256"
        $expectedText = Get-Content -LiteralPath $shaPath -Raw
        $match = [regex]::Match($expectedText, '([a-fA-F0-9]{64})')
        if (-not $match.Success) {
            throw "Could not parse SHA256 file: $shaPath"
        }

        $expected = $match.Groups[1].Value.ToLowerInvariant()
        $actual = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($actual -ne $expected) {
            throw "SHA256 mismatch for $zipPath. Expected $expected, got $actual."
        }

        Write-UpdaterLog 'Verified downloaded zip SHA256.'
    }

    return $zipPath
}

function Expand-BraveZip {
    param(
        [Parameter(Mandatory = $true)][string]$ZipPath,
        [Parameter(Mandatory = $true)][string]$ExtractDir,
        [Parameter(Mandatory = $true)][string]$NewAppDir,
        [Parameter(Mandatory = $true)][string]$ExpectedVersion
    )

    New-Item -ItemType Directory -Path $ExtractDir -Force | Out-Null
    New-Item -ItemType Directory -Path $NewAppDir -Force | Out-Null

    Write-UpdaterLog 'Extracting downloaded zip into a staging folder...'
    Expand-Archive -LiteralPath $ZipPath -DestinationPath $ExtractDir -Force

    $braveCandidates = @(Get-ChildItem -LiteralPath $ExtractDir -Recurse -Force -File -Filter 'brave.exe' |
        Sort-Object { $_.FullName.Length })

    if ($braveCandidates.Count -eq 0) {
        throw 'Extracted zip did not contain brave.exe.'
    }

    $payloadRoot = $braveCandidates[0].Directory.FullName
    Get-ChildItem -LiteralPath $payloadRoot -Force | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $NewAppDir -Recurse -Force
    }

    $newBraveExe = Join-Path $NewAppDir 'brave.exe'
    if (-not (Test-Path -LiteralPath $newBraveExe -PathType Leaf)) {
        throw 'Staged app payload does not contain brave.exe at its root.'
    }

    $fileVersion = (Get-Item -LiteralPath $newBraveExe).VersionInfo.FileVersion
    $normalized = ConvertTo-BraveVersion $fileVersion
    if ($normalized -ne $ExpectedVersion) {
        throw "Staged brave.exe version '$fileVersion' normalized to '$normalized', expected '$ExpectedVersion'."
    }

    Write-UpdaterLog "Verified staged brave.exe version $fileVersion."
}

function Install-AppPayload {
    param(
        [Parameter(Mandatory = $true)][string]$NewAppDir,
        [Parameter(Mandatory = $true)][string]$CurrentVersion,
        [Parameter(Mandatory = $true)][string]$TargetVersion
    )

    New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null
    Assert-FreeSpaceForAppInstall -NewAppDir $NewAppDir

    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $safeCurrent = if ($CurrentVersion) { $CurrentVersion } else { 'unknown' }
    $backupApp = Join-Path $BackupRoot "app-$safeCurrent-$timestamp"

    Write-UpdaterLog "Backing up current app payload to $backupApp"
    Wait-ForPortableBraveExit
    Move-Item -LiteralPath $AppDir -Destination $backupApp

    try {
        Write-UpdaterLog "Installing Brave $TargetVersion into $AppDir"
        Move-Item -LiteralPath $NewAppDir -Destination $AppDir
    }
    catch {
        Write-UpdaterLog 'Install failed after backup; restoring previous app payload.'
        if (Test-Path -LiteralPath $AppDir) {
            Rename-Item -LiteralPath $AppDir -NewName ("failed-app-$timestamp")
        }
        Move-Item -LiteralPath $backupApp -Destination $AppDir
        throw
    }

    return $backupApp
}

function Get-LatestAppBackup {
    if (-not (Test-Path -LiteralPath $BackupRoot -PathType Container)) {
        throw "No app payload backups were found. Missing backup folder: $BackupRoot"
    }

    $culture = [System.Globalization.CultureInfo]::InvariantCulture
    $styles = [System.Globalization.DateTimeStyles]::None
    $backups = @(Get-ChildItem -LiteralPath $BackupRoot -Directory -Filter 'app-*' -ErrorAction SilentlyContinue |
        ForEach-Object {
            $timestamp = $_.LastWriteTime
            $match = [regex]::Match($_.Name, '(\d{8}-\d{6})$')
            if ($match.Success) {
                $parsedTimestamp = [DateTime]::MinValue
                if ([DateTime]::TryParseExact($match.Groups[1].Value, 'yyyyMMdd-HHmmss', $culture, $styles, [ref]$parsedTimestamp)) {
                    $timestamp = $parsedTimestamp
                }
            }

            [pscustomobject]@{
                Name = $_.Name
                FullName = $_.FullName
                Timestamp = $timestamp
            }
        })

    if ($backups.Count -eq 0) {
        throw "No app payload backups were found in: $BackupRoot"
    }

    $latest = $backups |
        Sort-Object -Property @{ Expression = { $_.Timestamp }; Descending = $true }, @{ Expression = { $_.Name }; Descending = $true } |
        Select-Object -First 1

    return $latest.FullName
}

function Restore-AppPayloadBackup {
    param([Parameter(Mandatory = $true)][string]$BackupApp)

    $backupVersion = Get-BraveVersionFromAppDir -Path $BackupApp
    if (-not $backupVersion.Raw) {
        throw "Latest backup does not look like a Brave app payload. Missing: $(Join-Path $BackupApp 'brave.exe')"
    }

    $currentVersion = Get-InstalledBraveVersion
    $safeCurrent = if ($currentVersion.Normalized) { $currentVersion.Normalized } else { 'unknown' }
    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $currentBackup = Join-Path $BackupRoot "app-$safeCurrent-before-restore-$timestamp"
    $hasCurrentApp = Test-Path -LiteralPath $AppDir -PathType Container

    Write-UpdaterLog "Selected app payload backup: $BackupApp (Brave $($backupVersion.Normalized))"

    if ($DryRun) {
        Write-DryRunNoChangeMessage `
            -NoLogItems 'app payload, backup folders, profile files' `
            -LoggedItems 'app payload, backup folders, or profile files'
        if ($hasCurrentApp) {
            Write-UpdaterLog "Would move current app payload to: $currentBackup"
        }
        else {
            Write-UpdaterLog 'Current app folder is missing; would recover it from the selected backup.'
        }
        Write-UpdaterLog "Would restore backup into: $AppDir"
        Write-UpdaterLog "Would leave profile data untouched: $DataDir"
        return
    }

    Wait-ForPortableBraveExit
    if ($hasCurrentApp) {
        Write-UpdaterLog "Backing up current app payload to $currentBackup"
        Move-Item -LiteralPath $AppDir -Destination $currentBackup
    }

    try {
        Write-UpdaterLog "Restoring backup into $AppDir"
        Move-Item -LiteralPath $BackupApp -Destination $AppDir
    }
    catch {
        if ($hasCurrentApp) {
            Write-UpdaterLog 'Restore failed after current app backup; restoring the app payload that was just moved aside.'
        }
        else {
            Write-UpdaterLog "Restore failed. There was no current app to roll back to. Check the selected backup: $BackupApp"
        }
        if (Test-Path -LiteralPath $AppDir) {
            Rename-Item -LiteralPath $AppDir -NewName ("failed-restore-app-$timestamp")
        }
        if ($hasCurrentApp) {
            Move-Item -LiteralPath $currentBackup -Destination $AppDir
        }
        throw
    }

    $restored = Get-InstalledBraveVersion
    Write-UpdaterLog "Restore complete. Installed brave.exe version: $($restored.Raw) (Brave $($restored.Normalized))"
    if ($hasCurrentApp) {
        Write-UpdaterLog "Previous app payload backup: $currentBackup"
    }
    Write-UpdaterLog "Profile data was not modified by this updater: $DataDir"
}

function Start-BravePortable {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    if ($PSCmdlet.ShouldProcess($PortableExe, 'Launch Brave Portable')) {
        Write-UpdaterLog 'Launching brave-portable.exe...'
        Start-Process -FilePath $PortableExe -WorkingDirectory $PortableDir
    }
}

$updateLock = $null
try {
    try {
        # A launcher can inherit PowerShell 7 module paths while running Windows PowerShell 5.1.
        # Use this host's bundled modules instead of whichever version appears first in PSModulePath.
        foreach ($moduleName in 'Microsoft.PowerShell.Utility', 'Microsoft.PowerShell.Archive', 'CimCmdlets') {
            $modulePath = [IO.Path]::Combine($PSHOME, 'Modules', $moduleName, "$moduleName.psd1")
            Import-Module -Name $modulePath -Scope Local -Force -ErrorAction Stop
        }
        foreach ($requiredCommand in 'Get-FileHash', 'Expand-Archive', 'Get-CimInstance', 'Invoke-WebRequest', 'Invoke-RestMethod') {
            Get-Command -Name $requiredCommand -CommandType Cmdlet, Function -ErrorAction Stop | Out-Null
        }
    }
    catch {
        throw "Windows PowerShell could not load the built-in tools needed to update Brave. No download or app replacement has started. Restart Windows and run Update-BravePortable.cmd again. If it still fails, share this log with the maintainer. Technical detail: $($_.Exception.Message)"
    }
    Assert-PortappsBraveRoot -AllowMissingApp:$RestoreLatestBackup
    if (-not $DryRun) {
        $updateLock = Open-UpdaterLock
    }
    Wait-ForPortableBraveExit -Wait:$WaitForExit

    $installed = Get-InstalledBraveVersion
    if ($installed.Raw) {
        Write-UpdaterLog "Current installed brave.exe version: $($installed.Raw) (Brave $($installed.Normalized))"
    }
    else {
        Write-UpdaterLog 'Current installed brave.exe version: not found'
    }

    if ($RestoreLatestBackup) {
        $backupApp = Get-LatestAppBackup
        Restore-AppPayloadBackup -BackupApp $backupApp
        if ($Launch -and -not $DryRun) {
            Start-BravePortable
        }
        exit 0
    }

    $release = Resolve-BraveRelease $Edition
    Write-UpdaterLog "Latest public $($release.Channel) Windows x64 version: Brave $($release.Version) ($($release.Tag), published $($release.Published))"

    if ($installed.Normalized -and [version]$installed.Normalized -gt [version]$release.Version) {
        if (-not $AllowDowngrade) {
            throw "Installed Brave $($installed.Normalized) is newer than the selected $($release.Channel) release $($release.Version). Downgrade stopped. Keep the newer version, or use -AllowDowngrade only if you intentionally want an older browser and have a separate profile backup. -Force does not allow downgrades."
        }
        Write-UpdaterLog "Warning: -AllowDowngrade permits replacing Brave $($installed.Normalized) with older Brave $($release.Version)."
    }

    if ($installed.Normalized -eq $release.Version -and -not $Force) {
        Write-UpdaterLog 'Already up to date. Use -Force to reinstall the current version.'
        if ($Launch -and -not $DryRun) {
            Start-BravePortable
        }
        exit 0
    }

    if ($DryRun) {
        Write-DryRunNoChangeMessage `
            -NoLogItems 'app payload, profile files' `
            -LoggedItems 'app payload or profile files'
        if ($release.Sha256Url) {
            Write-UpdaterLog "Would download: $($release.AssetUrl)"
            Write-UpdaterLog "Would verify SHA256: $($release.Sha256Url)"
        }
        elseif ($AllowMissingHash) {
            Write-UpdaterLog "Would download: $($release.AssetUrl)"
            Write-UpdaterLog 'Would continue without Brave SHA256 because -AllowMissingHash was set; staged brave.exe version verification would still run.'
        }
        else {
            Write-UpdaterLog 'Would stop before download because Brave did not publish a SHA256 file for this asset. Use -AllowMissingHash only if you accept that risk.'
        }
        Write-UpdaterLog "Would replace only: $AppDir"
        Write-UpdaterLog "Would check free space before installing into: $PortableDir"
        Write-UpdaterLog "Would leave profile data untouched: $DataDir"
        exit 0
    }

    $tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('BravePortableUpdater-' + [guid]::NewGuid().ToString('N'))
    $downloadDir = Join-Path $tempRoot 'download'
    $extractDir = Join-Path $tempRoot 'extract'
    $newAppDir = Join-Path $tempRoot 'new-app'

    try {
        $zipPath = Save-ReleaseAsset -Release $release -DownloadDir $downloadDir -AllowMissingHash:$AllowMissingHash
        Expand-BraveZip -ZipPath $zipPath -ExtractDir $extractDir -NewAppDir $newAppDir -ExpectedVersion $release.Version
        $backupApp = Install-AppPayload -NewAppDir $newAppDir -CurrentVersion $installed.Normalized -TargetVersion $release.Version

        $updated = Get-InstalledBraveVersion
        Write-UpdaterLog "Update complete. Installed brave.exe version: $($updated.Raw) (Brave $($updated.Normalized))"
        Write-UpdaterLog "Old app payload backup: $backupApp"
        Write-UpdaterLog "Profile data was not modified by this updater: $DataDir"

        if ($Launch) {
            Start-BravePortable
        }
    }
    finally {
        if ($tempRoot -and (Test-Path -LiteralPath $tempRoot)) {
            Remove-Item -LiteralPath $tempRoot -Recurse -Force
        }
    }
}
catch {
    $message = $_.Exception.Message
    Write-Information '' -InformationAction Continue
    Write-Information 'ERROR:' -InformationAction Continue
    Write-Information $message -InformationAction Continue
    try {
        if (-not $NoLog) {
            Add-Content -LiteralPath $LogPath -Value ('[{0}] ERROR: {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $message) -Encoding UTF8
        }
    }
    catch {
        # Best-effort logging only; preserve the original failure as the process result.
        Write-Verbose "Failed to append error to log: $($_.Exception.Message)"
    }
    exit 1
}
finally {
    if ($null -ne $updateLock) {
        $updateLock.Dispose()
    }
}
