# Brave Portable Updater
**By [NeatWolf](https://github.com/NeatWolf)**

Keep portable Brave current. Keep your browser data in place.

[![Release](https://img.shields.io/github/v/release/NeatWolf/BravePortableUpdater?label=download&color=238636)](https://github.com/NeatWolf/BravePortableUpdater/releases/latest)
![Windows x64](https://img.shields.io/badge/Windows-x64-0078D4)
![No admin required](https://img.shields.io/badge/admin-not_required-555555)

A small updater for an existing **Portapps Brave Portable** installation.
It downloads Brave's official browser files, verifies them, and keeps a backup
of the previous application. Your bookmarks, extensions, settings, and sessions
stay in the portable `data/` folder, which this updater does not modify.

**[Download BravePortableUpdater.zip](https://github.com/NeatWolf/BravePortableUpdater/releases/latest/download/BravePortableUpdater.zip)**

[Release notes](https://github.com/NeatWolf/BravePortableUpdater/releases/latest) · [Report a problem](https://github.com/NeatWolf/BravePortableUpdater/issues/new/choose)

## Get Started

1. Download the zip above and choose **Extract All** in Windows.
2. Put the extracted files beside `brave-portable.exe`.
3. Close Brave Portable. Keep it closed while the updater runs.
4. Double-click **`Update-BravePortable.cmd`**.

Your folder should look like this:

```text
brave-portable.exe
app\
data\
Update-BravePortable.cmd
Update-BravePortable.ps1
SHA256SUMS.txt
```

The updater files belong in this folder, not inside `app/` or `data/`.
The checksum file is included for optional download verification.

**Requirements:** Windows x64, Windows PowerShell 5.1 or later, internet access,
and an existing [Portapps Brave Portable](https://portapps.io/app/brave-portable/)
folder. The Windows-provided PowerShell is sufficient; no separate installation
or administrator prompt is normally needed. This is not an installer for
ordinary, system-wide Brave.

Already using this updater? Close its window, then replace the two updater
files with the new download. Leave your browser folders alone.

## Know When It Is Done

The window stays open until you press a key. Read the status before closing it.

| Status | What it means |
| --- | --- |
| **Update complete** | The new browser files are installed. Open Brave normally. |
| **Already up to date** | Nothing needed replacing. |
| **Dry run only** | This was a preview; no browser files were replaced. |
| **ERROR / action did not complete** | Read the reason and next step above the final message. |

For example, a successful run includes these lines (versions will vary):

```text
Verified downloaded zip SHA256.
Verified staged brave.exe version 154.1.96.59.
Update complete. Installed brave.exe version: 154.1.96.59 (Brave 1.96.59)
```

The window also shows the previous application's backup location and the log
path: **`brave-portable-update.log`**, beside the updater.

## If Something Stops

| What you see | What to do |
| --- | --- |
| Brave is still running | Close every Brave Portable window, wait a few seconds, then run the updater again. |
| Another updater may be running | Close the other updater window and retry. If none is open, check that you can write to the portable folder. |
| Windows warns about downloaded files | Check that they came from this repository's release. If **Properties > Unblock** is available, select it. Do not disable Windows security features. |
| Cannot download or check the release | Check your connection and retry later. A newly announced release may still be publishing. |
| Not enough free space | Free space on the affected drive and retry. Keep your app backups until you know the new version works. |
| Cannot load built-in PowerShell tools | Restart Windows and retry. If it persists, report the message and log. |
| Installed version is newer | Keep the newer browser unless you deliberately intend to downgrade. |
| Cannot append to the log | Read the console result; the log may be incomplete. Check folder permissions and free space. |

For help, [open an issue](https://github.com/NeatWolf/BravePortableUpdater/issues/new/choose)
with the command and relevant error text. Remove personal information from log
excerpts. Never upload `data/`, cookies, credentials, or your browser profile.
Use [private reporting](SECURITY.md) for security-sensitive problems.

## Restore a Previous Version

Close Brave first. In File Explorer, open the portable folder, type `cmd` in its
address bar, and press Enter. Preview which backup will be restored:

```bat
Update-BravePortable.cmd -RestoreLatestBackup -DryRun -NoLog
```

If the displayed backup is the one you want, run:

```bat
Update-BravePortable.cmd -RestoreLatestBackup
```

The updater preserves the current application before restoring the newest saved
backup. It can also recover a missing `app/` folder after an interrupted update.

**An app backup is not a profile backup.** Restoring an older browser does not
undo profile changes made by a newer one. Keep separate backups of important
browser data.

## What Protects Your Installation

- Downloads come from Brave's official releases and require a matching SHA256
  checksum by default.
- Files are extracted and their browser version checked before replacing `app/`.
- The previous application is kept in `update-backups/`.
- Running-browser checks and an updater lock prevent known conflicts.
- Downgrades require explicit consent. A failed process check stops the update.

Keep Brave closed throughout the operation. These checks do not prevent someone
opening it immediately afterward or make an interrupted update crash-proof.
The updater changes browser application files; it does not install Brave
system-wide or update the Portapps launcher.

<details>
<summary><strong>Advanced Commands</strong></summary>

Run these from a command prompt in the portable folder.

| Task | Command |
| --- | --- |
| Short help | `Update-BravePortable.cmd -Help` |
| Full parameter help | `Update-BravePortable.cmd -FullHelp` |
| Preview, including an already-current version, without writing the log | `Update-BravePortable.cmd -DryRun -Force -NoLog` |
| Update and open Brave afterward | `Update-BravePortable.cmd -Launch` |
| Wait for Brave to close | `Update-BravePortable.cmd -WaitForExit` |
| Use beta or nightly | `Update-BravePortable.cmd -Edition beta` (or `nightly`) |
| Reinstall the selected version | `Update-BravePortable.cmd -Force` |
| Omit the final pause for automation | `Update-BravePortable.cmd -NoPause` |

Stable is the default channel. `-DryRun` never launches Brave; without `-NoLog`,
it still appends status to the log.

`-Force` does not permit a downgrade. `-AllowDowngrade` is a separate, deliberate
override; make a profile backup first. `-AllowMissingHash` permits a release
without a published checksum and weakens download verification.

To target another folder, use the PowerShell script directly with `-PortableDir`.
See `-FullHelp` for an example.

The small `.brave-portable-update.lock` file may remain after a run. The open
file handle, not the file's presence, holds the lock; it releases when the
updater exits. You do not need to delete it.

</details>

<details>
<summary><strong>Individual Downloads and Verification</strong></summary>

The convenience zip contains only the two updater scripts and their checksum
manifest. No Brave or Portapps binaries are bundled.

- [Update-BravePortable.cmd](https://github.com/NeatWolf/BravePortableUpdater/releases/latest/download/Update-BravePortable.cmd)
- [Update-BravePortable.ps1](https://github.com/NeatWolf/BravePortableUpdater/releases/latest/download/Update-BravePortable.ps1)
- [SHA256SUMS.txt](https://github.com/NeatWolf/BravePortableUpdater/releases/latest/download/SHA256SUMS.txt)

To check your downloads, compare the output of this PowerShell command with
the corresponding entries in `SHA256SUMS.txt`:

```powershell
Get-FileHash -Algorithm SHA256 -LiteralPath .\Update-BravePortable.cmd, .\Update-BravePortable.ps1
```

These hashes check the updater downloads. The updater separately verifies the
Brave archive during an update.

</details>

## Credits and License

Inspired by the [portable-update discussion on Reddit](https://www.reddit.com/r/brave_browser/comments/1pxz62w/brave_portable_with_updates_solution_for_windows/)
and [Chaython's Brave Portable updater](https://github.com/Chaython/Brave-Portable-Updater).
These scripts were written independently; see [NOTICE.md](NOTICE.md) for attribution.

[Brave](https://github.com/brave/brave-browser) is developed by Brave Software;
[Brave Portable](https://github.com/portapps/brave-portable) is maintained by Portapps.
This project is independent and is not endorsed by either.

Use, modification, and redistribution are permitted under the
[custom attribution license](LICENSE). **AI training is not licensed.**
The full terms, including the model-rights clause, are in that license.
It is not an OSI-approved open-source license.

---

[Changelog](CHANGELOG.md) · [Contributing](CONTRIBUTING.md) ·
[Verification and regression checks](VERIFICATION.md) ·
[Security](SECURITY.md) · [Code of conduct](CODE_OF_CONDUCT.md)
