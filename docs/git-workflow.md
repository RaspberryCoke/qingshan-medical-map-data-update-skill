# Git Workflow

This skill repository and the target business repository have different roles.

## Skill Repository

This repository may contain:

- Skill instructions.
- Initialization, sync, and validation scripts.
- Templates.
- Documentation.
- Fake example CSV data.

It must not contain:

- Real CSV exports.
- Real public CSV URLs.
- Logs from live syncs.
- Credentials, tokens, or service account files.
- Private user feedback snapshots.

## Target Repository

The target repository should receive only:

- A `.gitignore` rule for `/_local/`, if manually approved.
- Manually approved `src/_data/*.json` changes.

Do not commit:

- `.codex/`
- `_local/`
- Sync scripts.
- CSV / TSV files.
- Logs.
- `.env`.
- Credentials.
- Proxy config.
- `package.json`.
- Lockfiles.
- `pnpm-workspace.yaml`.
- Git hooks.

## Review Gate

Codex must output a read-only analysis and row-by-row plan before editing JSON.
No JSON changes are allowed without explicit user approval.

## Push and PR

Default to no push and no PR when using the workflow in the target repository.
Only commit, push, or create a PR when the user explicitly requests it.
