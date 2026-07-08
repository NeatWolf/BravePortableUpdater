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

## Working Rules

- Do not modify or delete a user's live `data/` profile directory.
- Do not run an updater path that can change the live install unless the current
  task requires it; prefer `-DryRun` for verification.
- On an already-current install, use `-Force -DryRun` to exercise dry-run action
  messages without downloading or replacing `app/`.
- If Brave is running, treat that as a successful safety check, not a failure to
  work around.
- Copy script changes into `D:\Portable\brave-portable` when the change affects
  the live command.
- Keep the GitHub repo and the live portable copy aligned for user-facing script
  changes.
- Do not add executable scripts beyond `Update-BravePortable.cmd` and
  `Update-BravePortable.ps1`.
- Commit and push completed polish passes.
