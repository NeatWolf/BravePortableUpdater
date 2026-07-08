# Brave Portable Updater

Small Windows updater for a Portapps-style Brave Portable directory.

It updates only the Brave application payload in `app/` and leaves portable profile data in `data/` untouched. The updater resolves the current public Brave channel version from `versions.brave.com`, downloads the matching Brave GitHub release zip, verifies the SHA256 file when available, stages extraction, verifies `brave.exe`, then swaps the `app/` folder after backing up the old payload.

## Usage

Copy these two files into the same directory as `brave-portable.exe`:

- `Update-BravePortable.cmd`
- `Update-BravePortable.ps1`

Run:

```bat
Update-BravePortable.cmd
```

The default edition is stable. Other examples:

```bat
Update-BravePortable.cmd -DryRun
Update-BravePortable.cmd -Launch
Update-BravePortable.cmd -Force
Update-BravePortable.cmd -Edition beta
Update-BravePortable.cmd -Edition nightly
```

You can also run it from another folder by passing the portable root:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Update-BravePortable.ps1 -PortableDir D:\Portable\brave-portable
```

## Safety Behavior

- Refuses to run unless the target has `brave-portable.exe` and `app/`.
- Refuses to update while Brave from that portable directory is running, unless `-WaitForExit` is used.
- Downloads into a temp directory first.
- Verifies the downloaded zip SHA256 when Brave publishes the `.sha256` asset.
- Verifies the staged `brave.exe` version before touching the live install.
- Moves the previous `app/` folder into `update-backups/`.
- Does not create, delete, or modify the portable `data/` profile directory.

## Prior Art

The portable-update flow was found through this Reddit thread:

- https://www.reddit.com/r/brave_browser/comments/1pxz62w/brave_portable_with_updates_solution_for_windows/

That thread points to Chaython's Brave Portable updater:

- https://github.com/Chaython/Brave-Portable-Updater

This repository's script was written independently for this local workflow and does not copy third-party updater code. The Chaython repository did not expose a license through GitHub's license endpoint when checked, so treat it as prior art unless its licensing changes.

Brave Browser itself is developed by Brave Software:

- https://github.com/brave/brave-browser
- https://versions.brave.com/

This repository does not include Brave binaries or Portapps binaries.
