# Codex 本地医疗地图数据更新工作流

你正在目标仓库根目录协助维护“就诊地图 / 医疗地图”数据。

## 核心边界

- 当前唯一数据入口是 `_local/input/medical-feedback.csv`。
- CSV 来自 Google Sheet “发布到网络”的公开 CSV 链接。
- 不使用 Google API、Service Account、OAuth、`.env`、代理配置、TSV 或 pnpm 同步命令。
- `_local/` 是目标仓库忽略的本地工作区，可以由用户手动作为独立本地 Git 仓库维护。
- 目标仓库不要提交 `_local/`、`.codex/`、同步脚本、CSV/TSV、日志、`.env`、凭据、代理配置、package 文件、lockfile、git hook 或 `pnpm-workspace.yaml`。
- `shares` 永远由用户手动维护；Codex 不新增、不修改、不删除。

未经用户明确批准，禁止修改任何 JSON 数据文件。

## 开始前检查

先运行并向用户报告：

```bash
git status --short --branch
git branch --show-current
git remote -v
```

确认当前目录包含：

```text
.git/
src/_data/medicalData.json
src/_data/medicalChildData.json
src/_data/medicalAbroadData.json
```

## 同步公开 CSV

如果用户提供公开 CSV 链接，根据系统选择：

```powershell
.\_local\scripts\sync-public-sheet.ps1 -Url "<published-csv-url>"
```

```bash
bash ./_local/scripts/sync-public-sheet.sh "<published-csv-url>"
```

脚本输出：

```text
_local/input/medical-feedback.csv
_local/logs/sync-public-sheet.log
```

日志不应记录真实 CSV URL。

## CSV 约定

当前文件：

```text
_local/input/medical-feedback.csv
```

完整预期表头：

```text
序号,更新状态,更新时间,分类,数据来源,省份/城市,医院名称,科室,医生姓名,诊疗方向,就诊评价与详细更新信息,链接,提取文字,内容概括,人工审核,审核时间,人工校验,校验时间,来源用户
```

字段使用：

- `分类`：初步判断目标文件。
- `省份/城市`：判断 `area`。
- `医院名称`：查找或新增医院。
- `科室`：可写入医院或医生 notes，视归属而定。
- `医生姓名`：查找或新增医生；为空或占位时不要生成医生。
- `诊疗方向`：转换为 `capacity` 候选。
- `就诊评价与详细更新信息`：润色后写入用户可读 `notes`。
- `链接`：只作人工参考；不自动写入 `shares`。
- `提取文字`、`内容概括`、`人工审核`、`审核时间`、`人工校验`、`校验时间`、`来源用户`：默认只作判断参考。

## 第一阶段：只读分析

读取 CSV 和三个 JSON 后，先只做分析，禁止修改文件。

必须输出：

- CSV 总行数。
- `更新状态` 分布。
- `分类` 分布。
- `未更新` 行。
- `已更新` 行。
- `无效信息` 行。
- 关键字段缺失情况。
- 和现有 JSON 的查重情况。
- 疑似重复医院 / 医生。
- 需要人工判断的行。

## 第二阶段：逐行处理方案

必须对每一行给出处理方案，不能静默忽略任何行。

每行方案必须包含：

- CSV 序号。
- 原更新状态。
- 处理决定：更新 / 跳过 / 无效 / 需要人工判断。
- 目标文件。
- 新增还是合并。
- 目标 area / hospital / doctor。
- `capacity` 如何处理。
- `notes` 准备怎么写。
- 不更新时的原因。
- 风险或不确定点。

输出方案后停止，等待用户明确批准。

## 修改后检查

批准后只修改：

```text
src/_data/medicalData.json
src/_data/medicalChildData.json
src/_data/medicalAbroadData.json
```

修改后运行：

```bash
node -e "for (const f of ['src/_data/medicalData.json','src/_data/medicalChildData.json','src/_data/medicalAbroadData.json']) { const text = require('fs').readFileSync(f,'utf8').replace(/^\uFEFF/, ''); JSON.parse(text); console.log(f + ' OK'); }"
git diff --check
git status --short --branch
```

默认不 push，不自动创建 PR。只有用户明确要求时才 commit、push 或 PR。
