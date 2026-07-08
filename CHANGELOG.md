# Changelog

All notable user-facing changes for this repository are recorded here.

## v0.1.5 - 2026-07-08

Repository-discoverability release.

- Clarified the beginner download path: get exactly the two updater files from
  a release and place them beside `brave-portable.exe`.
- Added a small folder-shape example for average Windows users.
- Kept the release package limited to the two updater files.

## v0.1.4 - 2026-07-08

Operator-usability release.

- Clarified dry-run output so it distinguishes app/profile changes from the
  expected updater log append.
- Documented the same dry-run/log behavior in the README.
- Kept the release package limited to the two updater files.

## v0.1.3 - 2026-07-08

Maintenance-evidence release.

- Documented the repeatable maintainer verification commands in the README.
- Recorded how live dry-run evidence should treat Brave-running detection.
- Kept the release package limited to the two updater files.

## v0.1.2 - 2026-07-08

Community-profile release.

- Added `CODE_OF_CONDUCT.md`.
- Added GitHub issue and pull request templates.
- Linked contribution, conduct, and security guidance from the README.

## v0.1.1 - 2026-07-08

Code-quality release.

- Fixed all current PSScriptAnalyzer findings in `Update-BravePortable.ps1`.
- Preserved dry-run and Explorer-friendly launcher behavior.
- Kept the release package limited to the two updater files.

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
