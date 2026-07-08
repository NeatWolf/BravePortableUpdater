# Security Policy

## Supported Versions

Only the latest `main` branch and the latest GitHub release are supported.

## Reporting A Vulnerability

This is a small public utility repo. Report security-sensitive issues through
GitHub private vulnerability reporting for this repository:

https://github.com/NeatWolf/BravePortableUpdater/security/advisories/new

Do not open a public issue first when the issue could expose:

- profile data loss risks
- unsafe update or rollback behavior
- command execution risks
- incorrect download or hash verification
- accidental packaging of Brave, Portapps, profile data, logs, or backups

Use a public GitHub issue only for non-sensitive defects that do not expose
private data or a practical exploit path. If the private-reporting page is not
available to you, open a minimal public issue asking for private contact without
including exploit details, logs, profile data, or file contents.

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
- check portable-drive free space before replacing `app/`
- replace only the portable `app/` payload
- leave `data/` profile contents untouched

The updater is not intended to:

- install Brave system-wide
- bypass running-process checks
- redistribute Brave or Portapps binaries
- inspect or package profile data
