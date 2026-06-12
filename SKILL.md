---
name: qingshan-medical-map-data-update-skill
description: Guided local workflow for maintaining Qingshan medical map JSON data from a public Google Sheet CSV. Use when the user wants to run the medical map update wizard, sync and analyze a public Sheet/CSV, process _local/input/medical-feedback.csv, update medical JSON, commit, push to a fork, or prepare PR handoff; requires a cloned target repo root, staged auto-run summaries, fork-only writes, and human approval before JSON edits, commits, pushes, or PR steps.
---

# Qingshan Medical Map Data Update

Use this skill to process medical map feedback from a public CSV in a cloned
target repository. Keep the workflow local, auditable, and review-first.

## Staged Auto-Run And Handoff Protocol

Act like a guarded update wizard for non-technical users. Every stage must:

```md
我接下来要做的事：
- <本阶段要完成的检查或操作>
- <本阶段要产出的结论>

我会自动执行这些检查；除非发现风险，否则不会中途打断你。
```

Then execute the stage automatically. Do not ask for confirmation for each small
command inside a stage. After the stage finishes, output:

```md
本阶段已完成：
- <关键结论 1>
- <关键结论 2>
- 风险判断：可以继续 / 暂停处理

你现在需要做的事：
- <用户需要审核或手动完成的事项>
- 如果没有问题，发送下面这条指令继续：

下一条指令：
<用户应复制发送的下一条指令>
```

Include technical logs only after a plain-language summary. Never end a stage
with only "完成了", an error dump, or an unstated next step.

Within a stage, continue automatically unless one of these risks appears:

- About to modify the core JSON data.
- About to create a commit.
- About to push to any remote.
- About to create any PR.
- `upstream/main` has changed or the branch is behind it.
- Conflicts, uncommitted changes, non-linear history, or ambiguous staged files
  are present.
- The current repository is not the expected target repository.
- An operation may affect production `main`, `origin/main`, or `upstream/main`.

Always stop for explicit user confirmation before:

1. Writing analyzed CSV/Sheet results into JSON.
2. Creating a commit after JSON edits.
3. Pushing to the fork.
4. Creating a fork Draft PR.
5. Asking the user to create or mark a production PR ready.
6. Running any operation that might affect production repository history.

## Stage Map

Use these stages and exact handoff prompts unless the user explicitly asks for a
scoped subtask:

| Stage | Purpose | Stop / next instruction |
| --- | --- | --- |
| 0 | Environment and repository safety check. | `继续执行阶段 1：同步公开 CSV，并只读分析本次反馈，不修改任何 JSON。` |
| 1 | Sync public CSV and analyze feedback read-only. | `我已审核分析结果，可以继续阶段 2：根据分析结果修改 JSON，但不要 commit。` |
| 2 | Modify approved JSON and validate, without commit. | `我已审核 JSON 修改结果，可以继续阶段 3：创建本地 commit，但不要 push。` |
| 3 | Create local commit only. | `继续阶段 4：在 push 前同步上游主仓库，确保历史线性。` |
| 4 | Fetch/rebase on latest `upstream/main` before push. | `确认可以 push 到 fork 仓库，继续阶段 5：push 当前分支。` |
| 5 | Push current branch to the fork only. | `继续阶段 6：在 fork 仓库创建 draft PR。` |
| 6 | Create a Draft PR inside the fork repository only. | `我已检查 fork 仓库 draft PR，没有问题。继续阶段 7：准备向主仓库提交 PR 前的最终同步检查。` |
| 7 | Final sync/readiness check before user submits production PR. | `确认最终检查通过。继续阶段 8：向主仓库提交 PR。` |
| 8 | Guide the user to manually submit the production PR. | Ask the user to paste the production PR link after creation; do not create it for them. |

## Preconditions

Require the user to clone the target repository first and run from its root:

```bash
git clone <target-repo-url>
cd <target-repo>
git remote add upstream <production-repo-url>
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

Git remotes must use the fork-based workflow:

```text
upstream = production repository, read-only for AI/Codex
origin = the user's fork, writable only for codex/<task-slug> branches
```

The default AI/Codex write scope is only:

```text
local codex/<task-slug>
origin/codex/<task-slug>
```

Never write to `upstream/main` or `origin/main`.

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

## Stage 0: Environment And Repository Safety Check

Start with the staged protocol. Say that you will verify the repository,
remotes, branch, worktree, tools, and upstream sync state, then run strict
preflight. The preflight must:

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
- Confirm `upstream` points to `ittuann/qingshanasd`, `origin` points to a fork,
  and `origin` is not the production repository. Stop if either remote is
  missing or ambiguous.
- Before any GitHub write operation, confirm and report repository identity:
  current repository, current branch, `origin`, `upstream`, default branch,
  target operation, and whether the operation writes to a remote. If the
  repository identity is unclear or not the expected repository for the task,
  stop.
- Check `git`, `gh`, `gh auth status`, and `node`.
- Initialize `_local/input`, `_local/scripts`, `_local/logs`, and
  `_local/workflow` when missing.
- Sync `_local/input/medical-feedback.csv` from the approved/default public CSV
  URL when the CSV is missing.
- Fetch `upstream/main`, reset local `main` to `upstream/main` only after the
  worktree is clean and local `main` has no extra commits, then create or switch
  to one short-lived normalized `codex/<task-slug>` branch based on
  `upstream/main`. Do not push `origin/main`.

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
gh repo view --json nameWithOwner,defaultBranchRef
```

Then run:

```bash
git switch main
git fetch upstream main
git reset --hard upstream/main
git switch -c codex/<task-slug> upstream/main
```

Before `git reset --hard upstream/main`, stop if local `main` has uncommitted
changes or commits that are not in `upstream/main`. The reset is local-only and
must not be followed by `git push origin main`.

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

End Stage 0 with a human-readable report:

- Current repository and whether it is the expected target repository.
- Current branch and whether it is a safe `codex/<task-slug>` branch.
- `origin` and `upstream` roles.
- Worktree status: clean or has uncommitted changes.
- Upstream sync status: synchronized or needs sync.
- Risk judgment: continue or pause with recovery steps.
- Next instruction:
  `继续执行阶段 1：同步公开 CSV，并只读分析本次反馈，不修改任何 JSON。`

## Stage 1: Sync Data And Read-Only Analysis

Start with the staged protocol. Sync `_local/input/medical-feedback.csv` from
the approved public CSV when needed, then analyze CSV feedback and existing JSON
read-only. Do not edit files in this stage.

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
- Effective feedback count.
- Affected hospitals, doctors, and regions.
- Rows not recommended for JSON writes and why.
- Whether the result is ready for Stage 2 JSON edits.

### Stage 1 Row-By-Row Plan

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

End Stage 1 with the next instruction:

```text
我已审核分析结果，可以继续阶段 2：根据分析结果修改 JSON，但不要 commit。
```

## Stage 2: Modify JSON After Approval

Start only after explicit user approval of the analysis/row plan. Modify only:

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

End Stage 2 with:

- Files modified.
- Entries added, changed, skipped, or removed.
- JSON parse validation result.
- `git diff --check` result.
- `git diff --stat` and a concise diff summary.
- Confirmation that no commit, push, or PR was created.
- Next instruction:
  `我已审核 JSON 修改结果，可以继续阶段 3：创建本地 commit，但不要 push。`

Default to no commit, no push, and no PR. Commit, push, or create a PR only when
the user explicitly follows the staged handoff.

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

## Fork-Based Linear PR Workflow

Core principles:

```text
AI/Codex can modify the fork, not upstream.
AI/Codex can create fork branches and fork-internal Draft PRs, not merge.
The only entry into upstream/main is a human-created protected PR.
Sync from upstream with rebase; final integration uses Squash merge.
Permission constraints are stronger than prompt constraints.
```

Repository roles:

```text
upstream: main/production repository, read-only for AI/Codex.
origin: fork repository, writable only for task branches.
main: default branch, never directly modified by AI/Codex.
codex/<task-slug>: one feature branch per task.
```

Treat fork Draft PRs as workflow review, not as a permission boundary. Default
to local-only work: modify files only after approval, validate, then output
summary, file list, test results, diff, and a suggested commit message.

Before creating an issue, branch, commit, PR, or any other GitHub write, run and
report:

```bash
git remote -v
git branch --show-current
gh repo view --json nameWithOwner,defaultBranchRef
```

The report must include:

```text
Current repository: <owner/name>
Current branch: <branch>
origin points to: <fork remote>
upstream points to: <production remote>
Default branch: <branch>
Target operation: <issue / branch / commit / push / PR / readiness check / none>
Remote write: <yes / no, and if yes exactly which remote/branch>
```

Stop if the current repository, branch, default branch, `origin`, `upstream`, or
target operation is unclear. Do not create issues, branches, commits, PRs, or
remote writes from an unverified repository.

Allowed AI/Codex write scope:

```text
local codex/<task-slug>
origin/codex/<task-slug>
```

Prohibited:

- Do not push directly to `main`, `master`, or the default branch.
- Do not push to `upstream`.
- Do not push to `origin/main`.
- Do not run `git push --force` or `git push --force-with-lease` against
  `upstream` or any `main` branch.
- Do not run `git merge upstream/main` or `git merge origin/main`; sync with
  rebase to preserve linear history.
- Do not merge PRs, close unrelated PRs or issues, delete branches, overwrite
  branches not created for this task, or edit repository settings, secrets,
  Actions permissions, or rulesets.
- Do not use AI-held write permission as the safety boundary for the production
  repository.

`git push --force-with-lease` is allowed only for updating
`origin/codex/<task-slug>` after a successful rebase. It is never allowed for
`upstream`, `origin/main`, or any default branch.

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

## Stage 3: Create Local Commit

Start only after the user approves the Stage 2 JSON diff. Before committing,
repeat the repository identity gate and inspect the worktree. Medical data
commits may include only:

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

Create one clear local commit and do not push. End Stage 3 with:

- Commit hash.
- Commit message.
- Current branch.
- Whether the branch is still linear and based on the expected upstream commit.
- Confirmation that nothing was pushed.
- Next instruction:
  `继续阶段 4：在 push 前同步上游主仓库，确保历史线性。`

## Stages 4-8: Fork Publishing And Production PR Handoff

Default to no push and no PR unless the user explicitly follows the staged
handoff. When publishing is requested, push only to
`origin/codex/<task-slug>` and create Draft PRs only inside the fork repository.
Use one short-lived `codex/<task-slug>` branch per task. Do not make medical
data commits directly on `main`, do not push `origin/main`, and do not create a
PR against the production repository for the user.

Allowed during the modification phase:

```bash
git add src/_data/medicalData.json src/_data/medicalChildData.json src/_data/medicalAbroadData.json
git commit -m "<message>"
git push origin codex/<task-slug>
```

Do not use `git add .` in this medical-data workflow unless the worktree
contains only approved files. Prefer explicit staging.

### Stage 4: Sync Upstream Before Push

Start only after the local commit exists. Fetch latest `upstream/main`, confirm
whether production changed since Stage 3, and rebase the task branch when
needed:

```bash
git fetch upstream
git switch codex/<task-slug>
git rebase upstream/main
git status
```

If rebase produces conflicts, stop and report the conflicted files with recovery
options. Do not make uncertain conflict resolutions. End Stage 4 with:

- Latest `upstream/main` commit.
- Whether the current branch is based on latest `upstream/main`.
- Whether a rebase happened.
- Whether conflicts occurred.
- Whether it is safe to push.
- Next instruction:
  `确认可以 push 到 fork 仓库，继续阶段 5：push 当前分支。`

### Stage 5: Push Current Branch To Fork

Start only after the user confirms Stage 4. Push only the fork task branch:

```bash
git push --force-with-lease origin codex/<task-slug>
```

Use `--force-with-lease` only after a successful rebase and only for
`origin/codex/<task-slug>`. A normal `git push origin codex/<task-slug>` is
preferred when no rebase rewrote the local commit. End Stage 5 with:

- Push target remote.
- Push target branch.
- Fork branch URL when available.
- Success or failure with recovery steps.
- Next instruction:
  `继续阶段 6：在 fork 仓库创建 draft PR。`

### Stage 6: Create Fork-Internal Draft PR

Start only after the user confirms Stage 5. Create a Draft PR inside the fork
repository, not against the production repository:

```text
from: origin/codex/<task-slug>
to: origin/main or the fork default branch
initial state: Draft PR
```

The fork Draft PR is for pre-checks, diff review, and discussion space. End
Stage 6 with:

- Fork Draft PR link.
- PR base and head.
- PR state.
- What the user should inspect.
- Next instruction:
  `我已检查 fork 仓库 draft PR，没有问题。继续阶段 7：准备向主仓库提交 PR 前的最终同步检查。`

### Stage 7: Final Check Before Production PR Handoff

Start only after the user confirms the fork Draft PR looks correct. Fetch
`upstream/main` again. If `upstream/main` changed, rebase, revalidate, and push
the updated fork branch before allowing Stage 8:

```bash
git fetch upstream
git switch codex/<task-slug>
git rebase upstream/main
git push --force-with-lease origin codex/<task-slug>
```

The PR branch should stay based on the latest `upstream/main` as much as
possible and must not contain merge commits.

End Stage 7 with:

- Latest `upstream/main` commit.
- Current branch latest commit.
- Whether the branch is fully based on latest `upstream/main`.
- Whether history is linear.
- Whether it is safe for the user to create the production PR.
- Next instruction:
  `确认最终检查通过。继续阶段 8：向主仓库提交 PR。`

### Stage 8: Guide Manual Production PR Creation

Do not create the production PR. Guide the user to manually create a PR from the
fork branch to the production repository. Tell the user to include:

- Data source: public CSV / Google Sheet.
- Modification summary.
- Changed medical JSON files.
- Validation results.
- Merge note: `Please use squash merge when this PR is ready.`

Tell the user not to merge directly. Recommend Squash merge after maintainer
review and passing checks. End Stage 8 with:

- Production PR link if the user already provided it; otherwise say that it is
  waiting for the user to create and paste the link.
- Base and head expected for the production PR.
- Modification summary.
- Validation/check results.
- How maintainers should review the change.
- Merge recommendation: Squash merge.

Production PR bodies must be reviewer-facing. Include only committed data
changes, map-user-visible impact, files changed, validation that applies to
committed files, and this merge note:

```text
Please use squash merge when this PR is ready.
```

Do not include local workflow internals such as `_local/`, CSV sync steps,
candidate row bookkeeping, transient local tool failures, proxy recovery, or
uncommitted logs. It is acceptable to state briefly that the full app test suite
was not verified locally, without including local toolchain logs.

Before telling the user that a production PR is ready to submit or asking a
maintainer to review/merge, inspect:

```bash
git fetch upstream
git switch codex/<task-slug>
git rebase upstream/main
git status
git log --oneline --graph --decorate --all -20
gh pr view <fork-pr-or-production-pr-if-user-provided> --json mergeStateStatus,isDraft,state,statusCheckRollup
gh pr checks <fork-pr-or-production-pr-if-user-provided>
```

Confirm:

```text
1. Current branch is codex/<task-slug>.
2. The fork branch is based on latest upstream/main.
3. There are no merge commits.
4. There are no uncommitted changes.
5. The diff contains only task-related changes.
6. CI has passed where available, or failures/authorization blockers are
   explained.
```

Medical map data PRs must be integrated with squash merge:

```bash
gh pr merge <PR> --squash --delete-branch
```

The command above is for the human maintainer to run after review and passing CI.
AI/Codex must not run it. Do not use `gh pr merge --merge`, do not close PRs, do
not delete remote branches, and do not merge directly to `upstream/main`.

After a human Squash merge:

```bash
gh pr view <PR> --json state,mergeCommit
git fetch upstream main --prune
git switch main
git reset --hard upstream/main
git branch -d codex/<task-slug>
```

Confirm the PR is `MERGED`, `upstream/main` contains the squash commit, and the
local task branch has no unpushed commits before deleting it. Do not delete the
remote fork branch unless a human maintainer explicitly asks.

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
repository only after repeating the repository identity gate and targeting the
skill repository explicitly. Include background, reproduction steps, actual
result, expected result, diagnosis, attempted fixes, impact, and suggested fix.
If the blocker is later solved, comment with the root cause and resolution, then
close the issue.
