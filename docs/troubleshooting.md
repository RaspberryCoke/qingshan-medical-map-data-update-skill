# Troubleshooting

## Script says the current directory is not the target repository root

Run the scripts from the cloned target repository root:

```bash
git clone <target-repo-url>
cd <target-repo>
```

The current directory must contain `.git/` and the three medical map JSON files.

## CSV download fails

- Confirm the Google Sheet is published to the web as CSV.
- Confirm the URL starts with `https://`.
- Do not add credentials, `.env`, Google API setup, or persistent proxy config
  to this workflow.
- Re-run the sync script and inspect `_local/logs/sync-public-sheet.log`; it
  records success or failure without storing the real URL.

## GitHub or Git network access fails

Inspect proxy environment variables and Git proxy config:

```bash
env | grep -i proxy
git config --get-regexp 'http.*proxy'
```

On PowerShell:

```powershell
Get-ChildItem Env:*proxy*
git config --get-regexp 'http.*proxy'
```

If proxy variables are set, retry the failed GitHub command once with proxy
variables cleared. If direct access still fails, check whether
`127.0.0.1:7890` is reachable and retry once with:

```bash
HTTP_PROXY=http://127.0.0.1:7890 HTTPS_PROXY=http://127.0.0.1:7890 <command>
```

If a Git operation still fails, try the equivalent `gh` command when possible.
If all safe alternatives fail, stop and report the attempted direct/proxy paths.

## `gh auth refresh` times out

Browser or device authorization can time out in a non-interactive agent shell.
Ask the user to run `gh auth refresh` or `gh auth login` locally, then re-run:

```bash
gh auth status
```

Do not keep retrying auth refresh inside the agent shell after the first timeout.

## Skill self-update stops the workflow

The preflight checks `.codex-skill-version.json` in the installed Codex skill
directory against the latest `main` version. If the installed version is stale,
it removes and reinstalls only
`~/.codex/skills/qingshan-medical-map-data-update-skill` from the remote
repository's tracked files, then stops immediately because the current Codex run
may still have loaded the older instructions. Restart Codex or start a new run,
then execute the workflow again.

If the skill repository has local changes, preflight stops without pulling.
Commit, stash, or discard those changes intentionally before re-running
preflight.

## CSV header validation fails

The first row must include at least:

```text
序号,更新状态,分类,省份/城市,医院名称,医生姓名,诊疗方向,就诊评价与详细更新信息,链接
```

The full expected header is:

```text
序号,更新状态,更新时间,分类,数据来源,省份/城市,医院名称,科室,医生姓名,诊疗方向,就诊评价与详细更新信息,链接,提取文字,内容概括,人工审核,审核时间,人工校验,校验时间,来源用户
```

## JSON parse validation fails

Open the failing JSON file and fix syntax before continuing. Do not create a
missing target JSON file automatically; the target repository should already
contain all three files.

## `_local/` appears in Git status

Add `/_local/` to the target repository `.gitignore` only after user approval.
Do not commit `_local/`, CSV files, logs, local scripts, or local workflow notes.

## Notes look too raw

Rewrite notes using `docs/notes-style-guide.md`. Remove internal source
language and convert the feedback into concise public guidance.
