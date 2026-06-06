# Data Rules

Use these rules when converting public CSV feedback into medical map JSON
changes.

## CSV Status

- `未更新`: primary update candidates.
- `已更新`: skip by default, but report them and explain why no change is needed.
- `无效信息`: do not write to JSON by default, but report the row and reason.
- Any row that matches existing JSON exactly still needs a visible
  "no update required" explanation.

## Target Files

Do not decide by `分类` alone. Combine `分类`, region, hospital, department,
doctor, treatment direction, and feedback notes.

- Domestic adult or general resources: `src/_data/medicalData.json`.
- Child or adolescent resources: `src/_data/medicalChildData.json`.
- Overseas or outside-mainland resources: `src/_data/medicalAbroadData.json`.

## Merging

- Merge into existing `area`; do not create duplicate or near-duplicate areas.
- Merge into existing `hospital`; do not create duplicate hospital names.
- Merge into existing `doctor`; do not create duplicate doctor names.
- Preserve valuable existing notes. Do not clear old notes because new notes are
  empty.
- If multiple doctors are mentioned and cannot be attributed safely, use
  hospital-level notes or ask for human judgment.

## Doctor Names

If `医生姓名` is empty or equals `未提及`, `无`, `不详`, `未知`, or `N/A`, do not
create a placeholder doctor. If the feedback is useful, prefer hospital-level
notes.

## Capacity

- Append only clearly supported values.
- Do not overwrite or delete existing values.
- Convert `诊疗方向` into a capacity candidate only after checking feedback and
  human review fields.
- Keep order as `ADHD`, then `ASD` when changing a capacity array.

## Shares

`shares` are always manually maintained by the user. Do not add, modify, or
delete shares automatically. Treat links as human reference only.

## Fields Used as References

Use `就诊评价与详细更新信息` as the main notes source, but rewrite it for public
map users. Treat `链接`, `提取文字`, `内容概括`, `人工审核`, `审核时间`, `人工校验`,
`校验时间`, and `来源用户` as judgment references unless the user explicitly
instructs otherwise.
