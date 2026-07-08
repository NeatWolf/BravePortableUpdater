# Agent Operating Notes

This repo is a small Windows/PowerShell tool, so polish work should be concrete,
low-risk, and verified against the local portable Brave folder when possible.

## Startup Research Snapshot

When starting a new polish cycle, use this map to pick the next area. Refresh it
only when the work depends on current GitHub, PowerShell, or Brave behavior.

| Field | What To Polish | Evidence Source |
| --- | --- | --- |
| Repository discoverability | README clarity, badges, topics, description, license, notice, contribution/security files | GitHub community profile guidance: README, LICENSE, CONTRIBUTING, CODE_OF_CONDUCT are expected project health files. |
| Operator usability | Explorer behavior, clear success/failure state, log paths, actionable recovery steps | This tool is normally launched by double-clicking a `.cmd`; every path must leave an understandable result. |
| PowerShell help | Comment-based help, examples, parameter descriptions, `Get-Help` output | Microsoft documents script comment-based help using `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`, and related keywords. |
| Code quality | PSScriptAnalyzer, strict mode, predictable error handling, no avoidable noisy diagnostics | Microsoft PSScriptAnalyzer checks PowerShell code with built-in rules and recommendations. |
| Release packaging | Tags, GitHub releases, release notes, downloadable source bundles, checksums if publishing binaries | GitHub releases package software with release notes and downloadable assets. |
| Install/update safety | Preflight checks, process detection, staging, hash verification, backup/rollback, no profile mutation | Repo-specific invariant: `data/` is user state and must not be touched by updater polish. |
| Maintenance evidence | Test commands, dry-run evidence, clean Git state, pushed commits, concise changelog | Repo-specific invariant: a polish pass is not complete until verified and recorded. |

Useful references:

- https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/about-community-profiles-for-public-repositories
- https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_comment_based_help
- https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/overview
- https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases

## Cycle Rule

Each cycle should choose one polish field that is different from the most recent
cycle, make a narrow pass, verify it, then commit and push.

Use the category scores as the quality gate. The standing target is at least
9/10 in every listed polish category, with no major interrupting issue. If an
active user goal asks for a stricter score, follow that goal for completion.

Current cycle history:

- 2026-07-08: Operator usability - kept Explorer-launched status visible, added actionable error copy, printed log path.
- 2026-07-08: PowerShell help and operator discoverability - add script help and `.cmd` help routing.
- 2026-07-08: Release packaging - add changelog and release guidance, then tag the first GitHub release.
- 2026-07-08: Repository discoverability - add contribution and security guidance without adding executable scripts.
- 2026-07-08: Code quality - run PSScriptAnalyzer and fix all analyzer findings in the updater script.
- 2026-07-08: Repository discoverability - add code of conduct, issue template, and PR template.
- 2026-07-08: Maintenance evidence - documented repeatable verification commands and live dry-run expectations.
- 2026-07-08: Operator usability - clarified dry-run output and docs so expected log appends are not confused with app/profile changes.
- 2026-07-08: Repository discoverability - clarified the beginner download path and expected portable folder shape.
- 2026-07-08: Install/update safety - require Brave SHA256 assets by default and add explicit missing-hash override messaging.
- 2026-07-08: Repository discoverability - made the GitHub repo public and documented public release downloads.
- 2026-07-08: Maintenance evidence - added no-log dry-run verification and removed the data directory preflight probe.
- 2026-07-08: Repository discoverability - updated public-repo security reporting and hash-required security boundary.
- 2026-07-08: Maintenance evidence - enabled and verified GitHub private vulnerability reporting for the public repo.
- 2026-07-08: PowerShell help - added a screen-only dry-run example for already-current installs.
- 2026-07-08: Maintenance evidence - aligned contributor live verification with the no-log dry-run command.
- 2026-07-08: Repository discoverability - aligned pull request template live verification with the no-log dry-run command.
- 2026-07-08: Maintenance evidence - aligned bug report repro guidance with the no-log dry-run command.
- 2026-07-08: Operator usability - made Brave release feed-skew messages understandable without knowing Brave's JSON feeds.
- 2026-07-08: Install/update safety - added guarded latest-backup restore with dry-run preview and profile-safe docs.
- 2026-07-08: Release packaging - added a checksum manifest for the two updater files and documented release asset expectations.
- 2026-07-08: Maintenance evidence - added a local verification checklist for repo checks, live dry-run evidence, restore previews, and release assets.
- 2026-07-08: Repository discoverability - added direct latest-release download links for the two updater files and checksum manifest.
- 2026-07-08: Operator usability - made `.cmd -Help` beginner-focused and added `.cmd -FullHelp` for complete PowerShell help.
- 2026-07-08: Code quality - added bounded Brave metadata/download requests with shared headers and clearer timeout failures.
- 2026-07-08: Release packaging - documented a convenience zip bundle containing only the two updater scripts and checksum manifest.
- 2026-07-08: Maintenance evidence - made analyzer verification reproducible with a temporary-module fallback and linked docs to the shared checklist.
- 2026-07-08: Install/update safety - added portable-drive free-space preflight before replacing the live app payload.

## Working Rules

- Do not modify or delete a user's live `data/` profile directory.
- Do not run an updater path that can change the live install unless the current
  task requires it; prefer `-DryRun` for verification.
- On an already-current install, use `-Force -DryRun -NoLog` to exercise dry-run
  action messages without downloading, replacing `app/`, or appending the log.
- If Brave is running, treat that as a successful safety check, not a failure to
  work around.
- Copy script changes into `D:\Portable\brave-portable` when the change affects
  the live command.
- Keep the GitHub repo and the live portable copy aligned for user-facing script
  changes.
- Do not add executable scripts beyond `Update-BravePortable.cmd` and
  `Update-BravePortable.ps1`.
- Commit and push completed polish passes.
