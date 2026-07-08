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

Run PSScriptAnalyzer:

```powershell
Import-Module PSScriptAnalyzer -Force
$results = Invoke-ScriptAnalyzer -Path .\Update-BravePortable.ps1 -Severity Information,Warning,Error
if ($results) { $results | Format-Table -AutoSize; exit 1 }
'PSScriptAnalyzer passed with no findings.'
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

Before creating a release:

```powershell
git status --short --branch
Get-Content -LiteralPath .\SHA256SUMS.txt
```

Attach only:

- `Update-BravePortable.cmd`
- `Update-BravePortable.ps1`
- `SHA256SUMS.txt`

Do not attach Brave binaries, Portapps binaries, logs, backups, or profile
folders.
