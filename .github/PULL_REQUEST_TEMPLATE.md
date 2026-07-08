# Summary

What changed?

## Polish Category

Choose the closest category:

- [ ] Repository discoverability
- [ ] Operator usability
- [ ] PowerShell help
- [ ] Code quality
- [ ] Release packaging
- [ ] Install/update safety
- [ ] Maintenance evidence

## Verification

Paste the commands that match the change. See `VERIFICATION.md` for the full
checklist and expected evidence.

```powershell
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command '$path=(Resolve-Path -LiteralPath .\Update-BravePortable.ps1).Path; $tokens=$null; $errors=$null; [System.Management.Automation.Language.Parser]::ParseFile($path,[ref]$tokens,[ref]$errors) | Out-Null; if ($errors.Count) { $errors | ForEach-Object Message; exit 1 }; "PowerShell parse OK"'
```

```powershell
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "Import-Module PSScriptAnalyzer -Force; `$results = Invoke-ScriptAnalyzer -Path .\Update-BravePortable.ps1 -Severity Information,Warning,Error; if (`$results) { `$results | Format-Table -AutoSize; exit 1 } else { 'PSScriptAnalyzer passed with no findings.' }"
```

```bat
D:\Portable\brave-portable\Update-BravePortable.cmd -NoPause -DryRun -Force -NoLog
```

## Safety Checklist

- [ ] I did not modify or inspect `D:\Portable\brave-portable\data`.
- [ ] I did not add executable scripts beyond `Update-BravePortable.cmd` and `Update-BravePortable.ps1`.
- [ ] I did not include Brave binaries, Portapps binaries, profile data, logs, or backups.
- [ ] If user-facing scripts changed, I copied them into `D:\Portable\brave-portable` and verified the live command.
