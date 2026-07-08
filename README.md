# Brave Portable Updater

![Windows](https://img.shields.io/badge/platform-Windows-0078D4?logo=windows&logoColor=white)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell&logoColor=white)
![Brave](https://img.shields.io/badge/Brave-release%20zip-FB542B?logo=brave&logoColor=white)
![No admin](https://img.shields.io/badge/admin-not%20required-2EA043)
![No AI training](https://img.shields.io/badge/AI%20training-not%20licensed-B00020)
![License](https://img.shields.io/badge/license-attribution%20%2B%20no%20AI%20training-6F42C1)

A small, cautious Windows updater for a Portapps-style Brave Portable folder.

It updates only the Brave application payload in `app/`. It does not touch the
portable profile in `data/`, where bookmarks, extensions, cookies, sessions,
settings, and other user state live.

## Why

Portapps Brave Portable keeps profile data portable, but the bundled Brave
browser can lag behind current security releases. This updater keeps the
portable wrapper and profile in place while refreshing the browser payload from
Brave's own GitHub release zips.

## Quick Start

Easiest path: download
[`BravePortableUpdater.zip`](https://github.com/NeatWolf/BravePortableUpdater/releases/latest/download/BravePortableUpdater.zip),
open it, and copy its contents next to `brave-portable.exe`.

Manual path: download exactly these two updater files:

- [`Update-BravePortable.cmd`](https://github.com/NeatWolf/BravePortableUpdater/releases/latest/download/Update-BravePortable.cmd)
- [`Update-BravePortable.ps1`](https://github.com/NeatWolf/BravePortableUpdater/releases/latest/download/Update-BravePortable.ps1)

They come from the latest GitHub release. The zip and release also include
[`SHA256SUMS.txt`](https://github.com/NeatWolf/BravePortableUpdater/releases/latest/download/SHA256SUMS.txt)
so users who know how to verify downloads can check that the two updater files
arrived unchanged.

Put both files in the same folder as `brave-portable.exe`. A typical folder
looks like this before you run the updater:

```text
brave-portable.exe
app\
data\
Update-BravePortable.cmd
Update-BravePortable.ps1
```

Then double-click `Update-BravePortable.cmd`, or run:

```bat
Update-BravePortable.cmd
```

The default channel is stable.
Double-clicking `Update-BravePortable.cmd` from Explorer is supported. If the
update finishes or does not complete, the window stays open so the result can
be read. If Brave is open, close it and run the updater again.

## Examples

Show built-in help:

```bat
Update-BravePortable.cmd -Help
```

Show the full PowerShell help:

```bat
Update-BravePortable.cmd -FullHelp
```

Preview without changing files:

```bat
Update-BravePortable.cmd -DryRun
```

Dry runs still append status lines to `brave-portable-update.log`, but they do
not download, replace `app/`, or modify `data/`. For screen-only verification
that does not append the log, use:

```bat
Update-BravePortable.cmd -DryRun -Force -NoLog
```

Update stable and launch Brave afterward:

```bat
Update-BravePortable.cmd -Launch
```

Use another channel:

```bat
Update-BravePortable.cmd -Edition beta
Update-BravePortable.cmd -Edition nightly
```

Force reinstall of the current resolved version:

```bat
Update-BravePortable.cmd -Force
```

Preview restoring the newest app backup:

```bat
Update-BravePortable.cmd -RestoreLatestBackup -DryRun -NoLog
```

Run without the final pause, for scheduled tasks or automation:

```bat
Update-BravePortable.cmd -NoPause
```

Run from another folder:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Update-BravePortable.ps1 -PortableDir D:\Portable\brave-portable
```

## What It Changes

- Downloads the selected public Brave Windows x64 release zip.
- Requires and verifies Brave's `.sha256` file for that asset by default.
- Extracts into a temporary staging folder first.
- Verifies the staged `brave.exe` version.
- Moves the current `app/` folder into `update-backups/`.
- Installs the new Brave payload into `app/`.
- When `-RestoreLatestBackup` is used, moves the current `app/` folder into
  `update-backups/` and restores the newest saved app payload into `app/`.

## What It Does Not Change

- Does not modify `data/`.
- Does not install Brave system-wide.
- Does not require administrator rights.
- Does not run Brave's installer.
- Does not include or redistribute Brave binaries.
- Does not include or redistribute Portapps binaries.
- Does not inspect or require `data/`.

## Safety Checks

The updater refuses to proceed unless the target folder looks like a Portapps
Brave Portable root with `brave-portable.exe` and `app/`.

It also refuses to update while Brave from that portable directory is running.
Close Brave first, or use:

```bat
Update-BravePortable.cmd -WaitForExit
```

If Brave does not publish a `.sha256` file for the selected zip, the updater
stops before downloading or installing anything. `-AllowMissingHash` exists only
for users who knowingly accept version-check-only verification for that release.

Logs are appended to:

```text
brave-portable-update.log
```

Use `-NoLog` only when you want console output without appending that log.

The `.cmd` launcher prints the full log path before it pauses, so Explorer
launches still leave both an on-screen result and a persistent log.

Previous app payloads are stored in:

```text
update-backups/
```

## Releases

Releases are tagged from `main` and use [CHANGELOG.md](CHANGELOG.md) as the
source of release notes. The repository is public so Windows users can download
the two updater files directly from the latest GitHub release:

- `Update-BravePortable.cmd`
- `Update-BravePortable.ps1`

Each release also carries `SHA256SUMS.txt`, a small text file with SHA256 hashes
for those two updater files. This repository does not publish Brave or Portapps
binaries.

## Maintainer Verification

See [VERIFICATION.md](VERIFICATION.md) for the full checklist, expected output,
and release asset boundaries. Before tagging a release, run the same core
checks from a clean working tree:

```powershell
git status --short --branch
git ls-files -- '*.cmd' '*.ps1'
Get-FileHash -Algorithm SHA256 -LiteralPath .\Update-BravePortable.cmd, .\Update-BravePortable.ps1
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command '$path=(Resolve-Path -LiteralPath .\Update-BravePortable.ps1).Path; $tokens=$null; $errors=$null; [System.Management.Automation.Language.Parser]::ParseFile($path,[ref]$tokens,[ref]$errors) | Out-Null; if ($errors.Count) { $errors | ForEach-Object Message; exit 1 }; Write-Output ''PowerShell parse OK'''
cmd /c "D:\Portable\brave-portable\Update-BravePortable.cmd -NoPause -DryRun -Force -NoLog"
```

The dry run must report what would happen without changing the app payload or
profile files. Use `-Force` with `-DryRun` on an already-current install to
exercise the dry-run action lines without downloading or replacing `app/`. Add
`-NoLog` when the check must also avoid appending `brave-portable-update.log`.
Run the PSScriptAnalyzer command in [VERIFICATION.md](VERIFICATION.md) as part
of the full checklist; it works even when the analyzer is not already installed.
If the live portable copy of Brave is running, process detection is a valid
safety result: close Brave or rerun with `-WaitForExit` only when an actual
update is intended.
The only executable release assets are `Update-BravePortable.cmd` and
`Update-BravePortable.ps1`. `BravePortableUpdater.zip` is a convenience bundle
containing those two scripts plus `SHA256SUMS.txt`, and `SHA256SUMS.txt` is a
non-executable checksum manifest for the scripts.

## Contributing And Security

See [CONTRIBUTING.md](CONTRIBUTING.md) for scope, safety rules, and verification
expectations. See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) for participation
rules. Report security-sensitive issues using [SECURITY.md](SECURITY.md).

## Recovery

If a new Brave payload misbehaves, close Brave and preview the restore first:

```bat
Update-BravePortable.cmd -RestoreLatestBackup -DryRun -NoLog
```

If the preview selects the backup you want, run:

```bat
Update-BravePortable.cmd -RestoreLatestBackup
```

The restore uses the same running-process safety check as updates. It moves the
current `app/` folder into `update-backups/`, restores the newest saved app
payload into `app/`, and leaves `data/` untouched.

## Credits

This project exists because of the portable-update flow described in:

- https://www.reddit.com/r/brave_browser/comments/1pxz62w/brave_portable_with_updates_solution_for_windows/

That thread points to Chaython's Brave Portable updater:

- https://github.com/Chaython/Brave-Portable-Updater

This repository's scripts were written independently for this workflow and do
not copy third-party updater code. Chaython's repository did not expose a
GitHub-detected license when checked, so it is treated here as prior art.

Brave Browser is developed by Brave Software:

- https://github.com/brave/brave-browser
- https://versions.brave.com/

Portapps Brave Portable is developed by Portapps:

- https://portapps.io/app/brave-portable/
- https://github.com/portapps/brave-portable

This project is not affiliated with, endorsed by, or sponsored by Brave
Software, Portapps, Reddit, or Chaython.

## License

This repository uses a custom attribution license. You may use, copy, modify,
and redistribute the original scripts with visible credit to this repository.

AI training is not licensed. Any unauthorized use for AI training is subject to
the model-rights grant described in [LICENSE](LICENSE).

Because the license restricts AI training, it is not an OSI-style open-source
license.
