## Summary

This PR updates medical map data based on manually reviewed feedback.

## 摘要

本 PR 基于人工审核后的反馈更新医疗地图数据。

## Related Issue

Closes #<issue-number>

## 关联 Issue

关联并关闭 #<issue-number>。

## Changes

- Updated approved medical map JSON entries only.
- Did not commit `_local/`, CSV/TSV files, logs, credentials, package files, lockfiles, hooks, or local workflow files.
- Did not modify `shares`.

## 变更

- 仅更新已批准的医疗地图 JSON 条目。
- 未提交 `_local/`、CSV/TSV 文件、日志、凭据、package 文件、lockfile、hook 或本地 workflow 文件。
- 未修改 `shares`。

## Validation

- JSON parse passed.
- `git diff --check` passed.
- `git status --short --branch` reviewed.

## 验证

- JSON parse 已通过。
- `git diff --check` 已通过。
- 已检查 `git status --short --branch`。

## Risk

Risk is limited to the approved JSON data changes. Medical resource information can become stale, so cautious notes wording and manual review remain required.

## 风险

风险限于已批准的 JSON 数据变更。医疗资源信息可能过期，因此仍需谨慎措辞和人工审核。

## Notes

No real CSV URL, raw CSV dump, credentials, logs, or private feedback snapshots are included.

## 备注

未包含真实 CSV URL、原始 CSV 全量内容、凭据、日志或用户反馈隐私快照。
