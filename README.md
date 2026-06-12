# Qingshan Medical Map Data Update Skill

This repository contains a public Codex/AI skill for maintaining medical map
JSON data through a local, review-first workflow.

It helps maintainers download feedback from a public Google Sheet CSV URL,
prepare a local review workspace, analyze feedback against existing medical
map JSON, and apply only manually approved data updates.

## What This Is Not

- Not a fully automated repository editing tool.
- Not a permission boundary for production repositories; draft PRs still require
  repository identity checks and human-controlled merge permissions.
- Not a cloud sync service.
- Not a replacement for human review.
- Not a Google API, Service Account, OAuth, `.env`, persistent proxy, or pnpm
  workflow.
- Not a place to store real CSV files, logs, credentials, or private user
  feedback. The approved public CSV URL is documented as workflow
  configuration; raw CSV exports still must not be committed.

## Requirements

- Git.
- GitHub CLI (`gh`) with an authenticated session.
- Node.js, used only for JSON parse validation.
- Windows PowerShell 5.1+ on Windows, or Bash on Linux/macOS.
- A cloned target repository with these files:
  - `.git/`
  - `src/_data/medicalData.json`
  - `src/_data/medicalChildData.json`
  - `src/_data/medicalAbroadData.json`
- `origin` configured as the user's fork and `upstream` configured as the
  production repository.
- A Google Sheet already published to the web as a public CSV URL.

Run all setup commands from the cloned target repository root:

```bash
git clone <target-repo-url>
cd <target-repo>
git remote add upstream <production-repo-url>
```

The scripts intentionally stop if the current directory does not look like the
target repository root. Do not run them from Desktop, Downloads, or the parent
directory of the clone.

## Quick Start on Windows

```powershell
git clone <target-repo-url>
cd <target-repo>
.\path\to\skill\scripts\init-local-workspace.ps1
.\_local\scripts\preflight-medical-workflow.ps1 -TaskSlug "update-medical-map-data-YYYYMMDD"
.\_local\scripts\validate-local-workspace.ps1
```

Then ask Codex:

```text
请读取 _local/workflow/medical-data-workflow.md，按医疗地图本地工作流处理 _local/input/medical-feedback.csv。先只读分析并输出逐行方案，等我批准后再修改 JSON。
```

## Quick Start on Linux/macOS

```bash
git clone <target-repo-url>
cd <target-repo>
bash /path/to/skill/scripts/init-local-workspace.sh
bash ./_local/scripts/preflight-medical-workflow.sh --task-slug "update-medical-map-data-YYYYMMDD"
bash ./_local/scripts/validate-local-workspace.sh
```

Then ask Codex:

```text
请读取 _local/workflow/medical-data-workflow.md，按医疗地图本地工作流处理 _local/input/medical-feedback.csv。先只读分析并输出逐行方案，等我批准后再修改 JSON。
```

## What the Initializer Creates

The initializer creates this ignored local workspace inside the target
repository:

```text
_local/input/
_local/scripts/
_local/logs/
_local/workflow/
```

It copies the platform-specific preflight, sync, and validation scripts into
`_local/scripts/`, copies workflow templates into `_local/workflow/`, and writes
the local skill repository path to `_local/workflow/skill-root.txt` so preflight
can check whether the skill itself is up to date.

The preflight script:

- Checks whether the skill repository is behind its upstream. If it fast-forward
  updates the skill, it stops and asks you to restart Codex or start a new run
  so the updated instructions are loaded.
- Checks `.codex-skill-version.json` in the installed Codex skill directory
  against the latest `main` version. If it is outdated, it removes and reinstalls
  only `~/.codex/skills/qingshan-medical-map-data-update-skill` from the remote
  repository's tracked files, then stops so Codex can reload the updated skill.
- Stops when the skill repository has local changes.
- Confirms the target repository root, `origin` as a fork, `upstream` as the
  production repository, required tools, and `gh auth status`.
- Confirms the GitHub repository identity with `gh repo view --json
  nameWithOwner,defaultBranchRef` and reports the current repository, current
  branch, `origin`, `upstream`, default branch, and that preflight performs no
  remote write.
- Initializes missing `_local/` directories and syncs
  `_local/input/medical-feedback.csv` from the approved/default public CSV URL
  when the CSV is missing.
- Fetches latest `upstream/main`, refreshes local `main`, and creates or
  switches to a normalized `codex/<task-slug>` branch based on `upstream/main`
  without pushing `origin/main`.
- On GitHub connection failures, retries once without proxy when proxy
  variables are set, then tries `127.0.0.1:7890` when reachable.

If the target repository `.gitignore` does not ignore `/_local/`, the
initializer prints a reminder. It does not edit `.gitignore` automatically.

## Manual Inputs Still Required

- The maintainer must clone the target repository first.
- The maintainer must initialize `_local/` from the target repository root.
- The maintainer may override the approved/default public CSV URL at preflight
  or sync time.
- The maintainer must review Codex's row-by-row plan before any JSON changes.

The human review gate remains mandatory because feedback can be ambiguous,
medical information can become stale, and the target JSON is public map data
used by real users. Codex should help organize and apply approved changes, not
silently decide what medical resource data becomes public.
