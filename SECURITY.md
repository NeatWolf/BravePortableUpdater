# Security Policy

## Supported Versions

Only the latest `main` branch and the latest GitHub release are supported.

## Reporting A Vulnerability

This is a small public utility repo. Report security issues through GitHub's
private vulnerability reporting when available, or contact the repository owner
privately before opening a public issue when the issue could expose:

- profile data loss risks
- unsafe update or rollback behavior
- command execution risks
- incorrect download or hash verification
- accidental packaging of Brave, Portapps, profile data, logs, or backups

Use a public GitHub issue only for non-sensitive defects that do not expose
private data or a practical exploit path.

Include:

- the affected file and version or commit
- exact command used
- expected behavior
- observed behavior
- whether `data/` or `app/` was touched

Do not include real browser profile contents, cookies, credentials, wallet data,
or other private files in a report.

## Security Boundaries

The updater is intended to:

- download Brave release zip assets from Brave's GitHub releases
- require and verify Brave's `.sha256` asset by default
- stage extraction before touching the live install
- replace only the portable `app/` payload
- leave `data/` profile contents untouched

The updater is not intended to:

- install Brave system-wide
- bypass running-process checks
- redistribute Brave or Portapps binaries
- inspect or package profile data
