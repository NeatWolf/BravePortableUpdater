# Verification Checklist

Use this checklist before commits that affect behavior, packaging, or release
docs. It is intentionally local-first because the live portable check requires a
real Brave Portable folder.

## Repository Checks

Run from the repository root:

```powershell
git status --short --branch
git ls-files -- '*.cmd' '*.ps1'
```

Expected script list:

```text
Update-BravePortable.cmd
Update-BravePortable.ps1
```

Verify the release checksum manifest:

```powershell
$expected = @{}
Get-Content -LiteralPath .\SHA256SUMS.txt | ForEach-Object {
    if ($_ -notmatch '^([a-f0-9]{64})\s+(\S+)$') { throw "Bad checksum line: $_" }
    $expected[$Matches[2]] = $Matches[1]
}
foreach ($name in 'Update-BravePortable.cmd', 'Update-BravePortable.ps1') {
    $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath ".\$name").Hash.ToLowerInvariant()
    if ($expected[$name] -ne $actual) { throw "Checksum mismatch for $name" }
}
'checksum manifest OK'
```

Parse the PowerShell script:

```powershell
$tokens = $null
$errors = $null
$path = (Resolve-Path -LiteralPath .\Update-BravePortable.ps1).Path
[System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors) | Out-Null
if ($errors.Count) { $errors | ForEach-Object Message; exit 1 }
'PowerShell parse OK'
```

Run PSScriptAnalyzer. This command uses an installed copy when available; if
not, it downloads a temporary copy, runs the check, and removes the temporary
module folder afterward.

```powershell
$tempRoot = [System.IO.Path]::GetFullPath($env:TEMP)
$temp = $null
try {
    if (Get-Command Invoke-ScriptAnalyzer -ErrorAction SilentlyContinue) {
        $results = Invoke-ScriptAnalyzer -Path .\Update-BravePortable.ps1 -Severity Information,Warning,Error
        if ($results) { $results | Format-Table -AutoSize; exit 1 }
    }
    else {
        $temp = Join-Path $tempRoot ('pssa-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $temp -Force | Out-Null
        Save-Module -Name PSScriptAnalyzer -Path $temp -Force -ErrorAction Stop
        Get-ChildItem -LiteralPath $temp -Recurse -File | Unblock-File -ErrorAction SilentlyContinue
        $manifest = Get-ChildItem -LiteralPath $temp -Recurse -Filter PSScriptAnalyzer.psd1 | Select-Object -First 1
        $env:PSSA_MANIFEST = $manifest.FullName
        $env:PSSA_REPO = (Get-Location).Path
        $child = @'
$ProgressPreference = 'SilentlyContinue'
Import-Module $env:PSSA_MANIFEST -Force -ErrorAction Stop
Set-Location -LiteralPath $env:PSSA_REPO
$results = Invoke-ScriptAnalyzer -Path .\Update-BravePortable.ps1 -Severity Information,Warning,Error
if ($results) {
    $results | Format-Table -AutoSize
    exit 1
}
'@
        $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($child))
        powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -EncodedCommand $encoded
        if ($LASTEXITCODE) { exit $LASTEXITCODE }
    }
    'PSScriptAnalyzer passed with no findings.'
}
finally {
    Remove-Item Env:\PSSA_MANIFEST -ErrorAction SilentlyContinue
    Remove-Item Env:\PSSA_REPO -ErrorAction SilentlyContinue
    if ($temp -and (Test-Path -LiteralPath $temp)) {
        Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue
    }
}
```

## Live Portable Dry Run

Use the no-log dry run for live evidence unless an actual update is required:

```bat
D:\Portable\brave-portable\Update-BravePortable.cmd -NoPause -DryRun -Force -NoLog
```

Expected evidence:

- exit code `0`
- output says no app payload, profile files, or updater log were changed
- output says it would replace only `D:\Portable\brave-portable\app`
- output says it would leave `D:\Portable\brave-portable\data` untouched

If Brave is running, process detection is valid safety evidence. Do not bypass
it for a dry-run check.

## Restore Preview

When restore behavior changes, verify with:

```bat
D:\Portable\brave-portable\Update-BravePortable.cmd -NoPause -RestoreLatestBackup -DryRun -NoLog
```

Expected evidence:

- exit code `0`
- output selects an `update-backups\app-*` folder
- output says no app payload, backup folders, profile files, or updater log were
  changed
- output says it would leave `D:\Portable\brave-portable\data` untouched

## Release Checks

### Safety Regression Cases

The 2026-09-27 repair was checked using functions loaded from the PowerShell AST
into an isolated process, plus disposable folders under the Windows temp folder.
No browser was launched and no live app or profile files were moved.

Repeat these cases after changing installation, restore, logging, or version
selection. Use a disposable fixture, never the live portable folder:

| Case | Setup | Required result |
| --- | --- | --- |
| Install rollback with log failure | Make the log path a directory; force the replacement move to fail | Original app restored; log warning does not replace the installation error |
| Restore rollback with log failure | Same log failure; force selected backup move to fail | Current app restored; selected backup retained |
| Missing app recovery | Valid launcher and backup, absent app | Preflight accepts restore; backup moves into app |
| Process-query error | Inject a CIM error | Stop before moving app |
| Inconclusive process identity | Return a Brave process with no path or command line | Stop before moving app |
| Brave opened during preparation | Return a matching process at the install/restore function boundary | Stop before moving app |
| Already current, dry run and launch | Equal installed and release versions; launch stub exits 99 | Exit 0; launch stub is never reached |
| Downgrade with Force | Installed 2.0.0, resolved 1.0.0 | Exit 1 before download or app replacement |
| Explicit downgrade preview | Same versions with AllowDowngrade and DryRun | Exit 0; preview only |
| Normal upgrade preview | Installed 0.9.0, resolved 1.0.0, DryRun | Exit 0; preview only |

The directory-move checks use real file operations; browser version metadata
and process enumeration may be stubbed in the isolated fixture. Top-level
decision checks must run in child processes because the updater calls `exit`.
These checks do not prove crash atomicity or prevent a user launching Brave
after the final process check.

### Runnable Safety Checks

Run the following block in PowerShell from the repository root. It uses only
temporary fixtures and child processes, never the live portable installation.
Expected: fourteen PASS lines. Logging-failure cases intentionally print warnings.
Fixture folders are retained under `%TEMP%` for inspection. Version metadata,
release metadata and process enumeration are stubbed; directory moves are real.
No additional executable scripts are added to the project.

```powershell
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$source = Get-Content .\Update-BravePortable.ps1 -Raw
$ast = [System.Management.Automation.Language.Parser]::ParseInput($source, [ref]$null, [ref]$null)
$definitions = $ast.FindAll({param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst]}, $false)
function Assert-Test($ok, $why) { if (-not $ok) { throw $why } }

$cases=@(
@{ Name='Install rollback survives logging failure'; Run={
    function Add-Content { param($LiteralPath,$Value,$Encoding) throw 'log failure' }
    function Move-Item { param($LiteralPath,$Destination)
        if ($LiteralPath -eq $newApp) { throw 'install failure' }
        Microsoft.PowerShell.Management\Move-Item -LiteralPath $LiteralPath -Destination $Destination
    }
    $reason = ''
    try { Install-AppPayload $newApp '1.0.0' '2.0.0' } catch { $reason=$_.Exception.Message }
    Assert-Test ($reason -eq 'install failure') 'Original install failure lost'
    Assert-Test (Test-Path "$AppDir\old.marker") 'Rollback did not restore app'
}},
@{ Name='Restore missing app'; Run={
    Move-Item -LiteralPath $AppDir -Destination "$fixture\aside"
    Assert-PortappsBraveRoot -AllowMissingApp
    Restore-AppPayloadBackup $savedApp
    Assert-Test (Test-Path "$AppDir\brave.exe") 'Restore did not recover missing app'
}},
@{ Name='Restore rollback survives logging failure'; Run={
    function Add-Content { param($LiteralPath,$Value,$Encoding) throw 'log failure' }
    function Move-Item { param($LiteralPath,$Destination)
        if ($LiteralPath -eq $savedApp) { throw 'restore failure' }
        Microsoft.PowerShell.Management\Move-Item -LiteralPath $LiteralPath -Destination $Destination
    }
    $reason = ''
    try { Restore-AppPayloadBackup $savedApp } catch { $reason=$_.Exception.Message }
    Assert-Test ($reason -eq 'restore failure') 'Original restore failure lost'
    Assert-Test (Test-Path "$AppDir\old.marker") 'Restore rollback lost current app'
    Assert-Test (Test-Path "$savedApp\brave.exe") 'Selected backup lost'
}},
@{ Name='CIM failure stops update'; Run={
    function Get-CimInstance { [CmdletBinding()]param($ClassName,$Filter) Write-Error 'CIM failure' }
    $stopped=$false
    try { Wait-ForPortableBraveExit } catch { $stopped=$true }
    Assert-Test $stopped 'CIM failure ignored'
}},
@{ Name='Unknown process path stops update'; Run={
    function Get-CimInstance { [CmdletBinding()]param($ClassName,$Filter)
        [pscustomobject]@{ExecutablePath=$null;CommandLine=$null}
    }
    $stopped=$false
    try { Wait-ForPortableBraveExit } catch { $stopped=$true }
    Assert-Test $stopped 'Unknown process ignored'
}},
@{ Name='Install rechecks processes'; Run={
    function Get-CimInstance { [CmdletBinding()]param($ClassName,$Filter)
        [pscustomobject]@{ExecutablePath="$AppDir\brave.exe";CommandLine='';Name='brave.exe';ProcessId=123}
    }
    $stopped=$false
    try { Install-AppPayload $newApp '1.0.0' '2.0.0' } catch { $stopped=$true }
    Assert-Test $stopped 'Install ignored running Brave'
    Assert-Test (Test-Path "$AppDir\old.marker") 'Install moved active app'
}},
@{ Name='Restore rechecks processes'; Run={
    function Get-CimInstance { [CmdletBinding()]param($ClassName,$Filter)
        [pscustomobject]@{ExecutablePath="$AppDir\brave.exe";CommandLine='';Name='brave.exe';ProcessId=123}
    }
    $stopped=$false
    try { Restore-AppPayloadBackup $savedApp } catch { $stopped=$true }
    Assert-Test $stopped 'Restore ignored running Brave'
    Assert-Test (Test-Path "$AppDir\old.marker") 'Restore moved active app'
}}
)
foreach ($case in $cases) { & {
    foreach ($definition in $definitions) { . ([scriptblock]::Create($definition.Extent.Text)) }
    $fixture=Join-Path ([IO.Path]::GetTempPath()) ('brave-updater-test-'+[guid]::NewGuid().ToString('N'))
    $boundary=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')+'\brave-updater-test-'
    if (-not [IO.Path]::GetFullPath($fixture).StartsWith($boundary)) { throw 'Unsafe fixture path' }
    $PortableDir=$fixture; $PortableExe="$fixture\brave-portable.exe"; $AppDir="$fixture\app"
    $BackupRoot="$fixture\update-backups"; $DataDir="$fixture\data"; $LogPath="$fixture\test.log"
    $savedApp="$BackupRoot\app-1.0.0-20260101-000000"; $newApp="$fixture\new-app"
    $NoLog=$false; $DryRun=$false; $InstallFreeSpaceMarginBytes=256MB
    function Get-CimInstance { [CmdletBinding()]param($ClassName,$Filter) }
    try {
        New-Item -ItemType Directory -Path $AppDir,$savedApp,$newApp -Force | Out-Null
        New-Item -ItemType File -Path $PortableExe,"$AppDir\old.marker" | Out-Null
        # Versioned file fixture, never executed.
        New-Item -ItemType File -Path "$savedApp\brave.exe" | Out-Null
        function Get-BraveVersionFromAppDir { param($Path) [pscustomobject]@{Raw="150.1.0.0";Normalized="1.0.0"} }
        & $case.Run
        "PASS: $($case.Name)"
    } finally { "Fixture retained for inspection: $fixture" }
} }

$main=$ast.EndBlock.Statements[-1]
foreach($case in @(
 @{Name='Current dry run never launches';Version='1.0.0';Allow='$false';Exit=0},
 @{Name='Downgrade denied even with Force';Version='2.0.0';Allow='$false';Exit=1},
 @{Name='Explicit downgrade preview allowed';Version='2.0.0';Allow='$true';Exit=0},
 @{Name='Ordinary upgrade preview allowed';Version='0.9.0';Allow='$false';Exit=0}
)) {
 $child=@(
 '$ErrorActionPreference=''Stop''; $DryRun=$true; $NoLog=$true; $Launch=$true; $Force=$false; $RestoreLatestBackup=$false; $WaitForExit=$false; $Edition=''stable''; $AppDir=''fixture''; $DataDir=''fixture''; $PortableDir=''fixture''',
 ('$AllowDowngrade='+$case.Allow),
 'function Assert-PortappsBraveRoot {param([switch]$AllowMissingApp)}',
 'function Wait-ForPortableBraveExit {param([switch]$Wait)}',
 'function Write-UpdaterLog {param($Message) Write-Output $Message}',
 'function Write-DryRunNoChangeMessage {param($NoLogItems,$LoggedItems)}',
 ('function Get-InstalledBraveVersion { [pscustomobject]@{Raw='''+$case.Version+''';Normalized='''+$case.Version+'''} }'),
 'function Resolve-BraveRelease {param($RequestedEdition) [pscustomobject]@{Channel=''release'';Version=''1.0.0'';Tag=''v1.0.0'';Published=''fixture'';Sha256Url=''fixture'';AssetUrl=''fixture''}}',
 'function Start-BravePortable {exit 99}',
 $(if($case.Name -like '*Force*') {'$Force=$true'}),
 $main.Extent.Text
 ) -join [Environment]::NewLine
 $encoded=[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($child))
 $output=& powershell.exe -NoLogo -NoProfile -NonInteractive -EncodedCommand $encoded 2>$null
 Assert-Test ($LASTEXITCODE -eq $case.Exit) "$($case.Name): exit $LASTEXITCODE. $output"
 Assert-Test ($output.Count -gt 0) 'Child did not execute'
 "PASS: $($case.Name)"
}
# Exclusive file handle must reject a second owner and release cleanly.
& {
 foreach($definition in $definitions) { . ([scriptblock]::Create($definition.Extent.Text)) }
 $PortableDir=Join-Path $env:TEMP ('brave-lock-test-'+[guid]::NewGuid().ToString('N'))
 New-Item -ItemType Directory -Path $PortableDir | Out-Null
 $first=Open-UpdaterLock
 try {
  $second=$null
  try { $second=Open-UpdaterLock } catch { }
  if($null -ne $second) { $second.Dispose(); throw 'Second lock owner was accepted' }
 } finally { $first.Dispose() }
 $again=Open-UpdaterLock
 $again.Dispose()
 'PASS: exclusive lock rejects concurrent owner and releases'
}
# Only copies of the two original scripts are used.
$helpRoot=Join-Path $env:TEMP ("brave-help's-test-"+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $helpRoot,"$helpRoot\missing" | Out-Null
Copy-Item .\Update-BravePortable.cmd,.\Update-BravePortable.ps1 -Destination $helpRoot
Copy-Item .\Update-BravePortable.cmd -Destination "$helpRoot\missing"
$output=& "$helpRoot\Update-BravePortable.cmd" -FullHelp -NoPause 2>&1
Assert-Test ($LASTEXITCODE -eq 0 -and ($output -join ' ') -match 'AllowDowngrade') 'Full help failed in apostrophe path'
'PASS: full help handles apostrophe path'
$previousPreference=$ErrorActionPreference
$ErrorActionPreference='Continue'
$output=& "$helpRoot\missing\Update-BravePortable.cmd" -FullHelp -NoPause 2>&1
$result=$LASTEXITCODE
$ErrorActionPreference=$previousPreference
Assert-Test ($result -ne 0) 'Missing script help incorrectly reported success'
'PASS: full help propagates failure exit code'

```

### Packaging

Before creating a release:

```powershell
git status --short --branch
Get-Content -LiteralPath .\SHA256SUMS.txt
```

Attach only:

- `BravePortableUpdater.zip`
- `Update-BravePortable.cmd`
- `Update-BravePortable.ps1`
- `SHA256SUMS.txt`

The zip must contain exactly:

- `Update-BravePortable.cmd`
- `Update-BravePortable.ps1`
- `SHA256SUMS.txt`

Do not attach Brave binaries, Portapps binaries, logs, backups, or profile
folders.

## Post-Release Checks

After publishing a release, verify the pushed commit, local tag, GitHub release
target, and asset list:

```powershell
git status --short --branch
git rev-parse HEAD
git rev-list -n 1 v0.1.31
git tag --points-at HEAD
gh release view v0.1.31 --json url,tagName,targetCommitish,assets --jq '{url:.url, tagName:.tagName, target:.targetCommitish, assets:[.assets[].name]}'
gh release list --limit 3
```

Replace `v0.1.31` with the release being checked. Expected evidence:

- working tree is clean and `main` is aligned with `origin/main`
- the tag points at the pushed `HEAD`
- the GitHub release target matches the pushed commit
- release assets are exactly `BravePortableUpdater.zip`, `Update-BravePortable.cmd`,
  `Update-BravePortable.ps1`, and `SHA256SUMS.txt`
