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
- Do not add credentials, `.env`, Google API setup, or proxy config to this
  workflow.
- Re-run the sync script and inspect `_local/logs/sync-public-sheet.log`; it
  records success or failure without storing the real URL.

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
