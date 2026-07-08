# Changelog

All notable user-facing changes for this repository are recorded here.

## v0.1.16 - 2026-07-08

Operator-usability release.

- Reworded Brave release feed-skew messages so non-technical users see what is
  happening: Brave announced a build before its detailed release index caught
  up, so the updater checks Brave's official GitHub release directly.
- Kept updater behavior unchanged and preserved the existing SHA256 requirement.

## v0.1.15 - 2026-07-08

Resolver reliability release.

- Added a GitHub release-tag fallback when Brave's latest-version endpoint is
  ahead of `brave-versions.json`.
- Preserved the existing asset and SHA256 checks when using the fallback.
- Fixed the observed `Brave versions JSON did not contain channel 'release'`
  error for feed-skewed Brave releases.

## v0.1.14 - 2026-07-08

Maintenance-evidence release.

- Updated the bug report template to use the current screen-only repro command:
  `Update-BravePortable.cmd -NoPause -DryRun -Force -NoLog`.
- Clarified that log excerpts are only expected when `-NoLog` was not used.
- Kept behavior unchanged and release packaging limited to the two updater
  files.

## v0.1.13 - 2026-07-08

Repository-discoverability release.

- Updated the pull request template to use the current screen-only live
  verification command: `Update-BravePortable.cmd -NoPause -DryRun -Force
  -NoLog`.
- Kept behavior unchanged and release packaging limited to the two updater
  files.

## v0.1.12 - 2026-07-08

Maintenance-evidence release.

- Updated contributor verification to use the current screen-only live check:
  `Update-BravePortable.cmd -NoPause -DryRun -Force -NoLog`.
- Aligned agent operating notes with the same no-log dry-run command.
- Kept behavior unchanged and release packaging limited to the two updater
  files.

## v0.1.11 - 2026-07-08

PowerShell-help release.

- Added a script help example for `-DryRun -Force -NoLog`, the screen-only
  verification path for already-current installs.
- Kept behavior unchanged and release packaging limited to the two updater
  files.

## v0.1.10 - 2026-07-08

Maintenance-evidence release.

- Enabled GitHub private vulnerability reporting for the public repository.
- Replaced conditional security-reporting wording with the concrete private
  vulnerability report URL.
- Documented the safe fallback for users who cannot access the private-reporting
  page without exposing details publicly.

## v0.1.9 - 2026-07-08

Repository-discoverability release.

- Updated `SECURITY.md` for the now-public repository.
- Added a concrete private-reporting path using GitHub private vulnerability
  reporting when available, with public issues limited to non-sensitive defects.
- Updated the security boundary to match the hash-required default.

## v0.1.8 - 2026-07-08

Maintenance-evidence release.

- Added `-NoLog` so dry-run verification can print to the console without
  appending `brave-portable-update.log`.
- Removed the optional `data/` existence probe from root preflight; the updater
  does not inspect or require profile data.
- Updated maintainer verification to use `-DryRun -Force -NoLog`.

Verification evidence:

- Script boundary: `Update-BravePortable.cmd` and `Update-BravePortable.ps1`
  are the only tracked updater scripts.
- Parser: `PowerShell parse OK`.
- PSScriptAnalyzer: `PSScriptAnalyzer passed with no findings.`
- Live no-log dry run: `Update-BravePortable.cmd -NoPause -DryRun -Force
  -NoLog` exited 0, reported no app/profile/log changes, and left
  `brave-portable-update.log` length and timestamp unchanged.
- Release asset hashes:
  - `Update-BravePortable.cmd`:
    `2209A4FE6760139E6E81A71F74C4F5D765BEA5528507CAD0868FC76167F858EA`
  - `Update-BravePortable.ps1`:
    `C42174A2514DEE9C28B2B47E24E4B996B21E8EFF9F1B697D45BD0F5AD0479006`

## v0.1.7 - 2026-07-08

Repository-discoverability release.

- Made the GitHub repository public so average Windows users can reach the repo
  and release downloads without collaborator access.
- Clarified in the README that releases are public and contain the two updater
  files only.
- Checked tracked content for obvious credentials before changing visibility.

## v0.1.6 - 2026-07-08

Install/update-safety release.

- Changed missing Brave `.sha256` files from a warning into a default stop
  before download or install.
- Added explicit `-AllowMissingHash` override for users who knowingly accept
  version-check-only verification for a specific release.
- Added dry-run output that reports whether SHA256 verification would be used,
  skipped by explicit override, or required before download.

Verification evidence:

- Script boundary: `Update-BravePortable.cmd` and `Update-BravePortable.ps1`
  are the only tracked updater scripts.
- Parser: `PowerShell parse OK`.
- PSScriptAnalyzer: `PSScriptAnalyzer passed with no findings.`
- Live dry run: `Update-BravePortable.cmd -NoPause -DryRun -Force` reported
  no app/profile changes and the Brave SHA256 URL it would verify.
- Release asset hashes:
  - `Update-BravePortable.cmd`:
    `72F2CC3249FF44C25D5121BF2F2827BCB60E7E78065997A90F0276A27153E49A`
  - `Update-BravePortable.ps1`:
    `7F6CE390AFCCE5EF552772748DDCABFCED94F72B7306E286001B86B9123C92D9`

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
