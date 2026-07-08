# Contributing

Thanks for improving Brave Portable Updater. Keep changes small, practical, and
easy to verify.

## Scope

Good contributions usually improve one of these areas:

- updater safety
- Explorer/operator usability
- PowerShell help
- documentation clarity
- release packaging
- maintenance evidence

The updater must remain focused on a Portapps-style Brave Portable folder. Do
not add Brave binaries, Portapps binaries, or system-wide install behavior.

## Safety Rules

- Do not modify, delete, inspect, or package a user's `data/` profile folder.
- Do not add executable helper scripts beyond `Update-BravePortable.cmd` and
  `Update-BravePortable.ps1`.
- Prefer `-DryRun` when verifying against a live portable install.
- Treat "Brave is running" process detection as a correct safety result.
- Preserve the behavior that only the `app/` payload is replaced.

## Verification

Before submitting a change, run the checks that match the change:

```powershell
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command '$path=(Resolve-Path -LiteralPath .\Update-BravePortable.ps1).Path; $tokens=$null; $errors=$null; [System.Management.Automation.Language.Parser]::ParseFile($path,[ref]$tokens,[ref]$errors) | Out-Null; if ($errors.Count) { $errors | ForEach-Object Message; exit 1 }; "PowerShell parse OK"'
```

```bat
D:\Portable\brave-portable\Update-BravePortable.cmd -NoPause -DryRun
```

If a change affects user-facing script behavior, copy the updated script files
into `D:\Portable\brave-portable` and verify the live command.

## Licensing

Contributions are accepted under this repository's attribution and no-AI-training
license terms. Do not submit code or text unless you are allowed to license it
under those terms.
