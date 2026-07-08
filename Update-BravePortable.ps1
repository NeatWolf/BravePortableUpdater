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

.PARAMETER Launch
Launch brave-portable.exe after a successful update or current-version check.

.PARAMETER DryRun
Resolve versions and report intended actions without downloading or changing
the Brave app payload or portable profile files. Unless -NoLog is set, the
updater still appends status lines to its log.

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
.\Update-BravePortable.ps1 -Edition beta

Updates the portable app payload to the latest public beta channel build.

.EXAMPLE
.\Update-BravePortable.ps1 -PortableDir D:\Portable\brave-portable -WaitForExit

Runs against an explicit portable root and waits until that copy of Brave exits
before updating.

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
    [switch]$Launch,
    [switch]$DryRun,
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

function Write-Log {
    param([Parameter(Mandatory = $true)][string]$Message)

    $line = '[{0}] {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    Write-Information $Message -InformationAction Continue
    if (-not $NoLog) {
        Add-Content -LiteralPath $LogPath -Value $line -Encoding UTF8
    }
}

function Assert-PortappsBraveRoot {
    if (-not (Test-Path -LiteralPath $PortableExe -PathType Leaf)) {
        throw "This does not look like a Portapps Brave root. Missing: $PortableExe"
    }
    if (-not (Test-Path -LiteralPath $AppDir -PathType Container)) {
        throw "This does not look like a Portapps Brave root. Missing: $AppDir"
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

function Get-InstalledBraveVersion {
    $braveExe = Join-Path $AppDir 'brave.exe'
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

function Get-PortableBraveProcess {
    $root = $PortableDir.TrimEnd('\') + '\'
    $names = @('brave.exe', 'brave-portable.exe', 'chrome_proxy.exe')
    $filter = ($names | ForEach-Object { "Name='$_'" }) -join ' OR '

    Get-CimInstance Win32_Process -Filter $filter -ErrorAction SilentlyContinue |
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

    Write-Log 'Portable Brave is running; waiting for it to exit...'
    while (@(Get-PortableBraveProcess).Count -gt 0) {
        Start-Sleep -Seconds 2
    }
}

function Invoke-BraveVersionsRequest {
    param([Parameter(Mandatory = $true)][string]$Uri)

    $headers = @{ 'User-Agent' = 'BravePortableUpdater/1.0' }
    Invoke-RestMethod -Headers $headers -Uri $Uri
}

function Resolve-BraveRelease {
    param([Parameter(Mandatory = $true)][string]$RequestedEdition)

    $channel = if ($RequestedEdition -eq 'stable') { 'release' } else { $RequestedEdition }
    $versionUri = "https://versions.brave.com/latest/$channel-windows-x64.version"
    $versionsUri = 'https://versions.brave.com/latest/brave-versions.json'

    Write-Log "Resolving latest public $channel build for Windows x64..."
    $targetVersion = ((Invoke-BraveVersionsRequest $versionUri) | Out-String).Trim()
    if (-not $targetVersion) {
        throw "Could not resolve latest $channel version from $versionUri"
    }

    $allVersions = Invoke-BraveVersionsRequest $versionsUri
    $records = @($allVersions.PSObject.Properties.Value | Where-Object { $_.channel -eq $channel })
    $record = $records | Where-Object { $_.name -eq $targetVersion -or $_.tag -eq "v$targetVersion" } | Select-Object -First 1

    if (-not $record) {
        throw "Brave versions JSON did not contain channel '$channel' version '$targetVersion'."
    }

    $assetName = "brave-v$targetVersion-win32-x64.zip"
    $asset = $record.github.assets | Where-Object { $_.name -eq $assetName } | Select-Object -First 1
    if (-not $asset) {
        throw "Release $($record.tag) does not contain expected asset '$assetName'."
    }

    $shaAsset = $record.github.assets | Where-Object { $_.name -eq "$assetName.sha256" } | Select-Object -First 1

    [pscustomobject]@{
        Channel = $channel
        Version = $targetVersion
        Tag = $record.tag
        Published = $record.published
        AssetName = $asset.name
        AssetUrl = $asset.download_url
        Sha256Url = if ($shaAsset) { $shaAsset.download_url } else { $null }
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

        Write-Log 'Warning: no SHA256 asset found for this release; -AllowMissingHash was set, so staged brave.exe version verification will be used after extraction.'
    }

    Write-Log "Downloading $($Release.AssetName)..."
    Invoke-WebRequest -Headers @{ 'User-Agent' = 'BravePortableUpdater/1.0' } -Uri $Release.AssetUrl -OutFile $zipPath

    if ($Release.Sha256Url) {
        $shaPath = "$zipPath.sha256"
        Invoke-WebRequest -Headers @{ 'User-Agent' = 'BravePortableUpdater/1.0' } -Uri $Release.Sha256Url -OutFile $shaPath
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

        Write-Log 'Verified downloaded zip SHA256.'
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

    Write-Log 'Extracting downloaded zip into a staging folder...'
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

    Write-Log "Verified staged brave.exe version $fileVersion."
}

function Install-AppPayload {
    param(
        [Parameter(Mandatory = $true)][string]$NewAppDir,
        [Parameter(Mandatory = $true)][string]$CurrentVersion,
        [Parameter(Mandatory = $true)][string]$TargetVersion
    )

    New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null

    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $safeCurrent = if ($CurrentVersion) { $CurrentVersion } else { 'unknown' }
    $backupApp = Join-Path $BackupRoot "app-$safeCurrent-$timestamp"

    Write-Log "Backing up current app payload to $backupApp"
    Move-Item -LiteralPath $AppDir -Destination $backupApp

    try {
        Write-Log "Installing Brave $TargetVersion into $AppDir"
        Move-Item -LiteralPath $NewAppDir -Destination $AppDir
    }
    catch {
        Write-Log 'Install failed after backup; restoring previous app payload.'
        if (Test-Path -LiteralPath $AppDir) {
            Rename-Item -LiteralPath $AppDir -NewName ("failed-app-$timestamp")
        }
        Move-Item -LiteralPath $backupApp -Destination $AppDir
        throw
    }

    return $backupApp
}

function Start-BravePortable {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    if ($PSCmdlet.ShouldProcess($PortableExe, 'Launch Brave Portable')) {
        Write-Log 'Launching brave-portable.exe...'
        Start-Process -FilePath $PortableExe -WorkingDirectory $PortableDir
    }
}

try {
    Assert-PortappsBraveRoot
    Wait-ForPortableBraveExit -Wait:$WaitForExit

    $installed = Get-InstalledBraveVersion
    if ($installed.Raw) {
        Write-Log "Current installed brave.exe version: $($installed.Raw) (Brave $($installed.Normalized))"
    }
    else {
        Write-Log 'Current installed brave.exe version: not found'
    }

    $release = Resolve-BraveRelease $Edition
    Write-Log "Latest public $($release.Channel) Windows x64 version: Brave $($release.Version) ($($release.Tag), published $($release.Published))"

    if ($installed.Normalized -eq $release.Version -and -not $Force) {
        Write-Log 'Already up to date. Use -Force to reinstall the current version.'
        if ($Launch) {
            Start-BravePortable
        }
        exit 0
    }

    if ($DryRun) {
        if ($NoLog) {
            Write-Log 'Dry run only. No app payload, profile files, or updater log were changed.'
        }
        else {
            Write-Log 'Dry run only. No app payload or profile files were changed; only the updater log may have been appended.'
        }
        if ($release.Sha256Url) {
            Write-Log "Would download: $($release.AssetUrl)"
            Write-Log "Would verify SHA256: $($release.Sha256Url)"
        }
        elseif ($AllowMissingHash) {
            Write-Log "Would download: $($release.AssetUrl)"
            Write-Log 'Would continue without Brave SHA256 because -AllowMissingHash was set; staged brave.exe version verification would still run.'
        }
        else {
            Write-Log 'Would stop before download because Brave did not publish a SHA256 file for this asset. Use -AllowMissingHash only if you accept that risk.'
        }
        Write-Log "Would replace only: $AppDir"
        Write-Log "Would leave profile data untouched: $DataDir"
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
        Write-Log "Update complete. Installed brave.exe version: $($updated.Raw) (Brave $($updated.Normalized))"
        Write-Log "Old app payload backup: $backupApp"
        Write-Log "Profile data was not modified by this updater: $DataDir"

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
