---
name: qingshan-medical-map-data-update-skill
description: Local review-first workflow for maintaining Qingshan medical map JSON data from a public Google Sheet CSV. Use when the user says to run the medical map local workflow, sync a public Sheet and analyze it, or process _local/input/medical-feedback.csv; requires a cloned target repo root and human approval before JSON edits.
---

# Qingshan Medical Map Data Update

Use this skill to process medical map feedback from a public CSV in a cloned
target repository. Keep the workflow local, auditable, and review-first.

## Preconditions

Require the user to clone the target repository first and run from its root:

```bash
git clone <target-repo-url>
cd <target-repo>
```

The current directory must contain:

```text
.git/
src/_data/medicalData.json
src/_data/medicalChildData.json
src/_data/medicalAbroadData.json
```

Stop if the current directory is Desktop, Downloads, a parent directory, or any
directory that lacks the required repository markers.

Use only this data entrypoint:

```text
_local/input/medical-feedback.csv
```

Do not use TSV, Google API, Service Account, OAuth, `.env`, persistent proxy
configuration, pnpm sync commands, or credentials.

The approved default public CSV URL for this workflow is:

```text
https://docs.google.com/spreadsheets/d/e/2PACX-1vRxiGx8JadZ-HPRJBb8-PMscizOv-4UpMqa56XZOhvr8ddkS99vm7hFJ-yee7c3btGrR4eXPRW_SAdi/pub?gid=1596563937&single=true&output=csv
```

## Start Every Run

Before processing data, run strict preflight. The preflight must:

- Check whether this skill repository can fast-forward to its upstream. If it
  updates the skill, stop and ask the user to restart Codex or start a new run
  so the updated instructions are loaded.
- Check `.codex-skill-version.json` in the installed Codex skill directory
  against the latest `main` version. If the installed version is not current,
  uninstall and reinstall the installed skill from the tracked files on GitHub,
  then stop and ask the user to restart Codex or start a new run.
- Stop if the skill repository has local changes.
- Confirm the current directory is the target repository root with `.git/` and
  the three required JSON files.
- Confirm `origin` points to `ittuann/qingshanasd`, or stop and report the
  mismatch.
- Check `git`, `gh`, `gh auth status`, and `node`.
- Initialize `_local/input`, `_local/scripts`, `_local/logs`, and
  `_local/workflow` when missing.
- Sync `_local/input/medical-feedback.csv` from the approved/default public CSV
  URL when the CSV is missing.
- Switch to `main`, run `git pull --ff-only origin main`, and create or switch
  to one short-lived normalized `codex/<task-slug>` branch for this task.

Use the platform preflight when it is available:

```powershell
.\_local\scripts\preflight-medical-workflow.ps1 -TaskSlug "update-medical-map-data-YYYYMMDD"
```

```bash
bash ./_local/scripts/preflight-medical-workflow.sh --task-slug "update-medical-map-data-YYYYMMDD"
```

If preflight is unavailable, do the same checks manually. First inspect Git
state and report anything risky:

```bash
git status --short --branch
git branch --show-current
git remote -v
```

Then run:

```bash
git switch main
git pull --ff-only origin main
git switch -c codex/<task-slug>
```

If CSV sync is needed, choose the platform script:

```powershell
.\_local\scripts\sync-public-sheet.ps1 -Url "<published-csv-url>"
```

```bash
bash ./_local/scripts/sync-public-sheet.sh "<published-csv-url>"
```

Then read:

```text
_local/input/medical-feedback.csv
src/_data/medicalData.json
src/_data/medicalChildData.json
src/_data/medicalAbroadData.json
```

## Phase 1: Read-Only Analysis

Do not edit files in this phase.

Output:

- CSV total data row count.
- `更新状态` distribution.
- `分类` distribution.
- `未更新` rows as update candidates.
- `无效信息` rows as reported skips unless the user explicitly approves work on
  them.
- `已更新` rows as count-only skips unless the user explicitly requests an audit.
- Missing key field summary.
- Duplicate checks against existing JSON.
- Suspected duplicate hospitals or doctors.
- Rows that need human judgment.

## Phase 2: Row-by-Row Plan

Give a plan for every default candidate row. By default, candidate rows are
`未更新`; report `无效信息` rows as skipped, and report `已更新` rows as skipped
without duplicate checks or row plans unless the user explicitly requests an
audit.

Each row plan must include:

- CSV `序号`.
- Original `更新状态`.
- Decision: `更新`, `跳过`, `无效`, or `需要人工判断`.
- Target file.
- Add or merge.
- Target area, hospital, and doctor.
- How `capacity` should change.
- Draft `notes`.
- Reason when not updating.
- Risks or uncertainties.

Wait for explicit user approval after the plan. Accept approvals such as
`批准`, `全部批准`, `批准 12、13 行`, or scoped approvals like `只批准广西相关行`.

Without explicit approval, do not modify JSON.

## Approved Edits

After approval, modify only:

```text
src/_data/medicalData.json
src/_data/medicalChildData.json
src/_data/medicalAbroadData.json
```

Keep JSON valid and use 2-space formatting. Do not add, modify, or delete
`shares`; those are always maintained manually by the user.

After edits, run:

```bash
node -e "for (const f of ['src/_data/medicalData.json','src/_data/medicalChildData.json','src/_data/medicalAbroadData.json']) { const text = require('fs').readFileSync(f,'utf8').replace(/^\uFEFF/, ''); JSON.parse(text); console.log(f + ' OK'); }"
git diff --check
git status --short --branch
```

Default to no push and no PR. Commit, push, or create a PR only when the user
explicitly asks.

## Data Rules

Use `未更新` rows as primary candidates. Report `已更新` rows and skip them by
default without duplicate checks or row plans. Report `无效信息` rows and do not
write them to JSON by default unless the user explicitly approves a scoped
exception.

Use `分类` only as an initial signal. Choose the target file by combining
region, hospital, department, doctor, treatment direction, and feedback notes:

- Adult or general mainland resources: `src/_data/medicalData.json`.
- Child or adolescent resources: `src/_data/medicalChildData.json`.
- Overseas or outside-mainland resources: `src/_data/medicalAbroadData.json`.

Merge into existing area, hospital, and doctor entries. Do not duplicate names
or near-duplicates.

If the doctor name is empty or is `未提及`, `无`, `不详`, `未知`, or `N/A`, do
not create a placeholder doctor. Prefer hospital-level `notes` when the
information is useful.

Append only clearly supported `capacity` values. Do not overwrite or delete
existing values. Normalize order to `ADHD`, then `ASD` when touching a capacity
array.

Use `就诊评价与详细更新信息` as the main source for public `notes`, but never
copy raw feedback verbatim. Use links only as human reference; do not write
them into `shares` automatically. Treat `提取文字`, `内容概括`, `人工审核`,
`审核时间`, `人工校验`, `校验时间`, and `来源用户` as judgment references, not
direct JSON fields.

## Notes Style

Write `notes` for map users: concise, accurate, and actionable.

Do not include internal processing traces such as:

- 截图显示
- 文字被截断
- 反馈者表示
- 来源用户
- 群友说
- 医生姓名来自截图文字
- OCR
- AI 判断
- 建议后续核对医院挂号页

Prefer cautious public wording:

- 建议就诊前核对医院挂号信息。
- 确诊检查需另行预约。
- 成人就诊前建议确认是否接诊。
- 可作为开药分流选择，建议携带既往确诊材料、处方记录和检查资料。
- 有反馈提到院内可咨询相关开药情况，建议就诊前或现场确认库存与处方要求。

## Network And GitHub Recovery

On Git, GitHub, or network failures, inspect `HTTP_PROXY`, `HTTPS_PROXY`,
`ALL_PROXY`, lowercase variants, and Git proxy config. If proxy variables are
set, retry the failing GitHub command once with proxy variables cleared. If
direct access fails, check whether `127.0.0.1:7890` is reachable and retry once
with `HTTP_PROXY=http://127.0.0.1:7890` and
`HTTPS_PROXY=http://127.0.0.1:7890`.

When a Git operation still fails, try an equivalent `gh` path when possible. If
`gh auth refresh` times out in a non-interactive shell, tell the user to run
`gh auth refresh` or `gh auth login` locally, then re-check `gh auth status`.

## Skill Version Updates

The installed Codex skill version is recorded in:

```text
.codex-skill-version.json
```

When the preflight updater finds that the installed version differs from the
latest `main` version, it must reinstall the Codex skill directory from the
remote repository's tracked files. The updater must only reinstall:

```text
~/.codex/skills/qingshan-medical-map-data-update-skill
```

It must not touch the target `qingshanasd` repository data. After reinstalling,
stop immediately because the current Codex run may still have loaded older skill
instructions.

## Commit Guard

Medical data commits may include only:

```text
src/_data/medicalData.json
src/_data/medicalChildData.json
src/_data/medicalAbroadData.json
```

Before committing, inspect:

```bash
git diff --cached --name-only
```

Do not use `git add -A` in a mixed worktree. Stage only the approved medical
JSON files explicitly.

Stop if staged files include `_local/`, `.learnings/`, skill files, scripts,
docs, CSV/TSV files, logs, credentials, package files, lockfiles, hooks, or
unrelated source files.

## Publishing Strategy

Default to no push and no PR unless the user explicitly asks for publishing.
When publishing is requested, use one short-lived `codex/<task-slug>` branch per
task. Do not make medical data commits directly on `main`.

Before creating a PR:

```bash
git fetch origin main
git merge-base --is-ancestor origin/main HEAD
git rev-list --count origin/main..HEAD
git log --oneline origin/main..HEAD
git diff --cached --name-only
```

The PR branch must be based on latest `origin/main`, and the staged files must
pass the Commit Guard. If `origin/main` has advanced, do not update the PR branch
with a merge commit. Rebase instead:

```bash
git fetch origin main
git rebase origin/main
git push --force-with-lease
```

Never run `git merge origin/main` to update a medical map PR branch, and do not
use GitHub's "Update branch" path when it would create a merge commit. Preserve a
linear PR history.

PR bodies must be reviewer-facing. Include only committed data changes,
map-user-visible impact, files changed, validation that applies to committed
files, and this merge note:

```text
Please use squash merge when this PR is ready.
```

Do not include local workflow internals such as `_local/`, CSV sync steps,
candidate row bookkeeping, transient local tool failures, proxy recovery, or
uncommitted logs. It is acceptable to state briefly that the full app test suite
was not verified locally, without including local toolchain logs.

If upstream push fails because the authenticated account lacks write permission,
push to the user's fork and open a cross-repo PR. If a fork PR has passing GitHub
Actions but Vercel reports `Authorization required to deploy`, explain that the
deployment preview is blocked by authorization and is not necessarily a code
build failure.

Before merging a PR:

```bash
git fetch origin main
git merge-base --is-ancestor origin/main HEAD
git rev-list --count origin/main..HEAD
git log --oneline --graph origin/main..HEAD
gh pr view <PR> --json mergeStateStatus,isDraft,state,statusCheckRollup
gh pr checks <PR>
```

The graph output must show only the branch commits to be integrated, with no
merge commits. The PR must not be draft, `mergeStateStatus` must be `CLEAN` or
an equivalent mergeable state, and all required/relevant checks must pass. If CI,
Vercel, CodeQL, authorization, or review state is pending or failed, stop and
report the blocker.

Medical map data PRs must be integrated with squash merge:

```bash
gh pr merge <PR> --squash --delete-branch
```

Do not use `gh pr merge --merge` for this workflow. Only merge directly to
upstream `main` after the user explicitly confirms direct upstream permission and
requests direct merge, and only after validation/checks pass.

After merge:

```bash
gh pr view <PR> --json state,mergeCommit
git fetch origin main --prune
git switch main
git pull --ff-only origin main
git branch -d codex/<task-slug>
```

Confirm the PR is `MERGED`, `origin/main` contains the squash commit, the remote
temporary branch was deleted, and the local task branch has no unpushed commits
before deleting it. Update local `main` only by fast-forward/fetch, never by a
merge commit.

## Self-Audit And Difficult Problems

When the workflow reveals reusable lessons, record problem, cause, and fix in:

```text
_local/workflow/medical-workflow-lessons.md
```

For user-corrected workflow rules, command/auth/network failures, or new skill
capability requests, also use the available self-improvement process and record
only reusable, non-sensitive lessons. Do not record secrets, tokens,
credentials, full raw CSV, private user data, or full user feedback dumps. The
approved default public CSV URL may be recorded as a public workflow
configuration value.

If the user asks for `self-audit/report-issue`, or a run has repeated
corrections/failures, read `.learnings/`, current Git status, related PR/CI
state, and existing issues in this skill repository before creating a new issue.
Exclude secrets, tokens, raw CSV, and private feedback by default.

For a difficult blocker that cannot be solved, create an issue in this skill
repository with background, reproduction steps, actual result, expected result,
diagnosis, attempted fixes, impact, and suggested fix. If the blocker is later
solved, comment with the root cause and resolution, then close the issue.
