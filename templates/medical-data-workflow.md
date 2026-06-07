# Codex 本地医疗地图数据更新工作流

你正在目标仓库根目录协助维护“就诊地图 / 医疗地图”数据。

## 核心边界

- 当前唯一数据入口是 `_local/input/medical-feedback.csv`。
- CSV 来自 Google Sheet “发布到网络”的公开 CSV 链接。
- 不使用 Google API、Service Account、OAuth、`.env`、持久化代理配置、TSV 或 pnpm 同步命令。
- `_local/` 是目标仓库忽略的本地工作区，可以由用户手动作为独立本地 Git 仓库维护。
- 目标仓库不要提交 `_local/`、`.codex/`、同步脚本、CSV/TSV、日志、`.env`、凭据、代理配置、package 文件、lockfile、git hook 或 `pnpm-workspace.yaml`。
- `shares` 永远由用户手动维护；Codex 不新增、不修改、不删除。

未经用户明确批准，禁止修改任何 JSON 数据文件。

## 开始前检查

先运行 preflight：

```powershell
.\_local\scripts\preflight-medical-workflow.ps1 -TaskSlug "update-medical-map-data-YYYYMMDD"
```

```bash
bash ./_local/scripts/preflight-medical-workflow.sh --task-slug "update-medical-map-data-YYYYMMDD"
```

preflight 必须确认：

```text
.git/
src/_data/medicalData.json
src/_data/medicalChildData.json
src/_data/medicalAbroadData.json
```

并且必须检查 skill 仓库是否已落后 upstream。若 skill 被 fast-forward 更新，停止当前流程，让用户重启 Codex 或重新开始任务后再继续。若 skill 仓库有本地改动，停止并报告。

preflight 还必须检查 `git`、`gh auth status`、`node`，确认 `origin` 指向 `ittuann/qingshanasd`，拉取最新 `main`，并创建或切换到 `codex/<task-slug>` 分支。

## 同步公开 CSV

如果 `_local/input/medical-feedback.csv` 不存在，preflight 默认使用已批准的公开 CSV URL 同步。用户也可以提供公开 CSV 链接，根据系统选择：

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
- `未更新` 行作为默认候选。
- `无效信息` 行作为默认跳过项。
- `已更新` 行作为默认跳过统计项；除非用户明确要求 audit，否则不做查重或逐行方案。
- 关键字段缺失情况。
- 和现有 JSON 的查重情况。
- 疑似重复医院 / 医生。
- 需要人工判断的行。

## 第二阶段：逐行处理方案

必须对默认候选行给出处理方案，不能静默忽略候选行。默认候选行是 `未更新`；`无效信息` 默认报告并跳过，`已更新` 默认只统计和跳过，除非用户要求 audit。

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

提交前必须运行：

```bash
git diff --cached --name-only
```

医疗数据提交只能包含：

```text
src/_data/medicalData.json
src/_data/medicalChildData.json
src/_data/medicalAbroadData.json
```

如包含 `_local/`、`.learnings/`、skill 文件、脚本、文档、CSV/TSV、日志、凭据、package 文件、lockfile、hook 或其他无关文件，必须停止。

## GitHub 连接恢复

GitHub 连接失败时，检查 `HTTP_PROXY`、`HTTPS_PROXY`、`ALL_PROXY`、小写变量以及 Git proxy config。当前设置了代理却失败时，先临时清空代理重试一次；直连失败后，再检查 `127.0.0.1:7890` 是否可达，并用 `HTTP_PROXY=http://127.0.0.1:7890`、`HTTPS_PROXY=http://127.0.0.1:7890` 重试一次。仍失败时，尝试等价 `gh` 路径；如果都失败，明确报告已尝试的路径。
