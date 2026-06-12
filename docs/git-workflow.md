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
- Logs from live syncs.
- Credentials, tokens, or service account files.
- Private user feedback snapshots.

The approved default public CSV URL may be stored as workflow configuration in
the skill repository. Do not commit raw CSV exports or private feedback.

Before using the skill, check whether the installed Codex skill version in
`.codex-skill-version.json` matches the latest `main` version. If not, reinstall
only `~/.codex/skills/qingshan-medical-map-data-update-skill` from the remote
repository's tracked files and stop the current run so Codex can reload the new
skill instructions. If the skill repository is itself a Git checkout with local
changes, stop and report them instead of pulling over local work.

## Repository Identity Gate

Before any GitHub write operation, prove where the command will act:

```bash
git remote -v
git branch --show-current
gh repo view --json nameWithOwner,defaultBranchRef
```

Report the current repository, current branch, `origin`, `upstream`, default
branch, target operation, and whether the operation writes to a remote. Stop if
any of those are unclear or do not match the intended repository. Draft PRs are a
review workflow, not a permission boundary.

Repository roles:

```text
upstream: production repository, read-only for AI/Codex.
origin: fork repository, writable only for codex/<task-slug>.
main: default branch, never directly modified by AI/Codex.
codex/<task-slug>: task feature branch.
```

The only AI/Codex write scope is local `codex/<task-slug>` and
`origin/codex/<task-slug>`. Do not push to `upstream`, `upstream/main`, or
`origin/main`.

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

Before committing target repository data updates, run:

```bash
git diff --cached --name-only
```

Medical data commits may include only:

```text
src/_data/medicalData.json
src/_data/medicalChildData.json
src/_data/medicalAbroadData.json
```

Stop if staged files include `_local/`, `.learnings/`, skill files, scripts,
docs, CSV/TSV files, logs, credentials, package files, lockfiles, hooks, or
unrelated source files.

## Review Gate

Codex must output a read-only analysis and row-by-row plan before editing JSON.
No JSON changes are allowed without explicit user approval.

## Branch, Push, PR, And Merge

At the start of a target repository run, fetch the production repository,
refresh local `main` from `upstream/main`, then create or switch to a normalized
short-lived `codex/<task-slug>` branch based on `upstream/main`:

```bash
git fetch upstream
git switch main
git reset --hard upstream/main
git switch -c codex/<task-slug> upstream/main
```

Stop before `git reset --hard upstream/main` if the worktree is dirty or local
`main` has commits that are not in `upstream/main`. Do not push `origin/main`.
Use one task branch per medical data update, and do not make data commits
directly on `main`.

Default to no push and no PR when using the workflow in the target repository.
Only commit, push, or create a PR when the user explicitly requests it. When
publishing is requested, push only to `origin/codex/<task-slug>` and open a Draft
PR from that fork branch to `upstream/main`.

Before creating a Draft PR, refresh remote state and rebase on latest
`upstream/main`:

```bash
git fetch upstream
git switch codex/<task-slug>
git rebase upstream/main
git status
```

If rebase produces conflicts, stop and report the conflicted files. After a
successful rebase, push only the fork task branch:

```bash
git push --force-with-lease origin codex/<task-slug>
```

`git push --force-with-lease` is allowed only for `origin/codex/<task-slug>`.
Never use it for `upstream`, `origin/main`, or any default branch. Never use
`git merge upstream/main`, `git merge origin/main`, or a GitHub "Update branch"
action that creates a merge commit. The PR branch should remain a linear series
of task commits on top of `upstream/main`.

PR bodies should be reviewer-facing. Mention committed JSON changes, map-user
visible impact, validation for committed files, and `Please use squash merge when
this PR is ready.` Do not include local workflow internals such as `_local/`, CSV
sync details, candidate row bookkeeping, transient tool failures, proxy recovery,
or uncommitted logs. If the full app test suite was not run locally, mention that
briefly without local toolchain logs.

Draft PRs must be from `origin/codex/<task-slug>` to `upstream/main`. If GitHub
Actions checks pass but Vercel reports `Authorization required to deploy` on a
fork PR, explain that the preview deployment is blocked by authorization and is
not necessarily a code build failure.

Merging is a human-maintainer action. Do not run `gh pr merge`. Before marking a
Draft PR Ready for review, or before asking a maintainer to merge, refresh remote
state and check linear history plus GitHub status:

```bash
git fetch upstream
git switch codex/<task-slug>
git rebase upstream/main
git status
git log --oneline --graph --decorate --all -20
gh pr view <PR> --json mergeStateStatus,isDraft,state,statusCheckRollup
gh pr checks <PR>
```

Confirm the current branch is `codex/<task-slug>`, the PR branch is based on
latest `upstream/main`, the graph has no merge commits, the worktree is clean,
the diff only contains task-related changes, and CI has passed or the blocker is
clearly explained.

Medical map PRs must be integrated with squash merge:

```bash
gh pr merge <PR> --squash --delete-branch
```

The command above is for the human maintainer to run after review and passing CI.
AI/Codex must not run it. Do not use `gh pr merge --merge`, do not close PRs, do
not delete remote branches, and do not merge directly to `upstream/main`. After a
human Squash merge, confirm the PR is merged, confirm `upstream/main` contains
the squash commit, refresh local `main`, and delete the local task branch only
after it has no unpushed commits:

```bash
gh pr view <PR> --json state,mergeCommit
git fetch upstream main --prune
git switch main
git reset --hard upstream/main
git branch -d codex/<task-slug>
```

Recommended upstream protections:

```text
Require a pull request before merging
Require status checks to pass
Require branches to be up to date before merging
Require linear history
Block force pushes
Block deletions
Restrict who can push to main
```
