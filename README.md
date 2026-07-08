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

Copy these two files into the same folder as `brave-portable.exe`:

- `Update-BravePortable.cmd`
- `Update-BravePortable.ps1`

Run:

```bat
Update-BravePortable.cmd
```

The default channel is stable.
Double-clicking `Update-BravePortable.cmd` from Explorer is supported. If the
update finishes or does not complete, the window stays open so the result can
be read.

## Examples

Show built-in help:

```bat
Update-BravePortable.cmd -Help
```

Preview without changing files:

```bat
Update-BravePortable.cmd -DryRun
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
- Verifies Brave's `.sha256` file when published for that asset.
- Extracts into a temporary staging folder first.
- Verifies the staged `brave.exe` version.
- Moves the current `app/` folder into `update-backups/`.
- Installs the new Brave payload into `app/`.

## What It Does Not Change

- Does not modify `data/`.
- Does not install Brave system-wide.
- Does not require administrator rights.
- Does not run Brave's installer.
- Does not include or redistribute Brave binaries.
- Does not include or redistribute Portapps binaries.

## Safety Checks

The updater refuses to proceed unless the target folder looks like a Portapps
Brave Portable root with `brave-portable.exe` and `app/`.

It also refuses to update while Brave from that portable directory is running.
Close Brave first, or use:

```bat
Update-BravePortable.cmd -WaitForExit
```

Logs are appended to:

```text
brave-portable-update.log
```

The `.cmd` launcher prints the full log path before it pauses, so Explorer
launches still leave both an on-screen result and a persistent log.

Previous app payloads are stored in:

```text
update-backups/
```

## Releases

Releases are tagged from `main` and use [CHANGELOG.md](CHANGELOG.md) as the
source of release notes. Download the two updater files from a release or copy
them from the repo:

- `Update-BravePortable.cmd`
- `Update-BravePortable.ps1`

This repository does not publish Brave or Portapps binaries.

## Contributing And Security

See [CONTRIBUTING.md](CONTRIBUTING.md) for scope, safety rules, and verification
expectations. Report security-sensitive issues using [SECURITY.md](SECURITY.md).

## Recovery

If a new Brave payload misbehaves, close Brave, rename the current `app/`
folder, and move the most recent backup from `update-backups/` back to `app/`.
The profile in `data/` is separate from this app-payload swap.

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
