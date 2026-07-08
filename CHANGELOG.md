# Changelog

All notable user-facing changes for this repository are recorded here.

## v0.1.0 - 2026-07-08

Initial packaged release.

- Added `Update-BravePortable.ps1` for staged Brave payload updates.
- Added `Update-BravePortable.cmd` for Explorer-friendly launches.
- Preserved Portapps profile data by replacing only the `app/` payload.
- Added SHA256 verification for Brave release zip assets when available.
- Added backup of the previous `app/` folder into `update-backups/`.
- Added clear success/failure status, persistent log path, and `-NoPause`.
- Added comment-based PowerShell help and `.cmd -Help` routing.
- Added attribution and no-AI-training license terms.
