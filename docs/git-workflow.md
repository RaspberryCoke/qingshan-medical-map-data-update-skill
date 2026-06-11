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

At the start of a target repository run, switch to `main`, run
`git pull --ff-only origin main`, then create or switch to a normalized
short-lived `codex/<task-slug>` branch. Use one task branch per medical data
update, and do not make data commits directly on `main`.

Default to no push and no PR when using the workflow in the target repository.
Only commit, push, or create a PR when the user explicitly requests it. When
publishing is requested, default to pushing the `codex/<task-slug>` branch and
opening a draft PR.

Before creating a PR, refresh remote state and prove that the branch is based on
latest `origin/main`:

```bash
git fetch origin main
git merge-base --is-ancestor origin/main HEAD
git rev-list --count origin/main..HEAD
git log --oneline origin/main..HEAD
git diff --cached --name-only
```

If `origin/main` advanced while the task branch was open, do not update the PR
branch by merging `origin/main`. Rebase and push with a lease:

```bash
git fetch origin main
git rebase origin/main
git push --force-with-lease
```

Never use `git merge origin/main` or a GitHub "Update branch" action that creates
a merge commit for this workflow. The PR branch should remain a linear series of
task commits on top of `origin/main`.

PR bodies should be reviewer-facing. Mention committed JSON changes, map-user
visible impact, validation for committed files, and `Please use squash merge when
this PR is ready.` Do not include local workflow internals such as `_local/`, CSV
sync details, candidate row bookkeeping, transient tool failures, proxy recovery,
or uncommitted logs. If the full app test suite was not run locally, mention that
briefly without local toolchain logs.

If upstream push fails because the authenticated GitHub account lacks write
permission, push to the user's fork and open a cross-repo PR. If GitHub Actions
checks pass but Vercel reports `Authorization required to deploy` on a fork PR,
explain that the preview deployment is blocked by authorization and is not
necessarily a code build failure.

Direct merge to upstream `main` is allowed only when the user explicitly
confirms upstream permission and requests direct merge, and only after
validation/checks pass. Before merging, refresh remote state and check linear
history plus GitHub status:

```bash
git fetch origin main
git merge-base --is-ancestor origin/main HEAD
git rev-list --count origin/main..HEAD
git log --oneline --graph origin/main..HEAD
gh pr view <PR> --json mergeStateStatus,isDraft,state,statusCheckRollup
gh pr checks <PR>
```

The PR must not be draft, the merge state must be clean or equivalently
mergeable, required/relevant checks must pass, and the graph must not contain a
merge commit. Stop on pending or failed CI, Vercel, CodeQL, authorization, or
review state.

Medical map PRs must be integrated with squash merge:

```bash
gh pr merge <PR> --squash --delete-branch
```

Do not use `gh pr merge --merge` for this workflow. After merge, confirm the PR
is merged, confirm `origin/main` contains the squash commit, prune deleted remote
branches, fast-forward local `main`, and delete the local task branch only after
it has no unpushed commits:

```bash
gh pr view <PR> --json state,mergeCommit
git fetch origin main --prune
git switch main
git pull --ff-only origin main
git branch -d codex/<task-slug>
```
