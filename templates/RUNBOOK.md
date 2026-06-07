# 医疗地图更新 Runbook

本文件服务于目标仓库的本地 `_local/` 工作区，不提交到目标仓库。

## 快速入口

当用户要求执行医疗地图本地工作流时：

1. 确认当前目录是 clone 后的目标仓库根目录。
2. 优先运行 preflight：

   ```bash
   bash ./_local/scripts/preflight-medical-workflow.sh --task-slug "update-medical-map-data-YYYYMMDD"
   ```

   Windows:

   ```powershell
   .\_local\scripts\preflight-medical-workflow.ps1 -TaskSlug "update-medical-map-data-YYYYMMDD"
   ```

3. 如果 preflight 更新了 skill 仓库，停止当前流程，重启 Codex 或重新开始任务后再继续。
4. 读取 `_local/input/medical-feedback.csv`。
5. 读取三个目标 JSON。
6. 先输出整体分析和逐行处理方案。
7. 等待用户人工批准后再修改 JSON。
8. 只在用户明确要求时 commit、push 或创建 PR。

## 数据源规则

当前唯一入口：

```text
_local/input/medical-feedback.csv
```

不要再使用：

- `_local/input/medical-feedback.tsv`
- `_local/.env`
- credentials
- Google API
- Service Account
- OAuth
- `pnpm sync:sheet`
- 持久化代理配置

公开 CSV 链接默认使用已批准的工作流配置，也可由用户在运行脚本时覆盖。不要把原始 CSV、私密反馈或日志提交到目标仓库。

## Preflight 要求

preflight 必须：

- 检查 skill 仓库是否落后 upstream；如果自动 fast-forward 更新了 skill，立即停止并要求重启 Codex 或重新开始任务。
- 检查已安装 Codex skill 目录中的 `.codex-skill-version.json` 是否等于远端 `main` 最新版本；如果不是最新，卸载并重装 `~/.codex/skills/qingshan-medical-map-data-update-skill` 后立即停止。
- 如果 skill 仓库有本地改动，停止并报告，不能自动覆盖。
- 确认目标仓库 root、`origin`、`git`、`gh auth status` 和 `node`。
- 缺少 `_local/` 时自动创建本地工作区并同步 CSV。
- 切到 `main`，执行 `git pull --ff-only origin main`，再创建或切换到 `codex/<task-slug>` 分支。
- GitHub 连接失败时，先在当前有代理的情况下尝试不走代理；直连失败后再尝试 `127.0.0.1:7890`。

## 处理原则

- `未更新` 行是默认处理候选。
- `已更新` 行默认只统计和跳过，不做查重或逐行方案；只有用户要求 audit 时才展开。
- `无效信息` 默认报告并跳过，除非用户明确批准处理。
- `分类` 只作初筛，目标文件还要结合地区、医院、科室、医生、诊疗方向和备注判断。
- `shares` 永远由用户手动维护；Codex 不新增、不修改、不删除。
- 没有医生姓名但信息有效时，优先考虑医院级 `notes`，不要生成占位医生。
- `capacity` 只追加明确支持项，不因为新信息较少而覆盖或删除旧值。
- `notes` 必须面向地图用户，去掉截图状态、内部审核判断和聊天口吻。

目标文件一般规则：

- 国内成人或泛用资源：`src/_data/medicalData.json`
- 儿童/青少年相关资源：`src/_data/medicalChildData.json`
- 海外或境外资源：`src/_data/medicalAbroadData.json`

## 修改前必须输出方案

实际编辑 JSON 前，对默认候选行逐行给出：

1. CSV 序号。
2. 目标文件。
3. 新增还是合并。
4. 目标 area / hospital / doctor。
5. `capacity` 处理方式。
6. `notes` 准备写入的文本。
7. 不更新时的原因。
8. 风险或不确定点。

等待用户明确批准后才能修改 JSON。

## 检查

JSON 修改后至少运行：

```bash
node -e "for (const f of ['src/_data/medicalData.json','src/_data/medicalChildData.json','src/_data/medicalAbroadData.json']) { const text = require('fs').readFileSync(f,'utf8').replace(/^\uFEFF/, ''); JSON.parse(text); console.log(f + ' OK'); }"
git diff --check
git status --short --branch
```

## 目标仓库边界

目标仓库只允许提交：

- `.gitignore` 中忽略 `/_local/` 的规则。
- 经人工批准后的 `src/_data/*.json` 数据变更。

目标仓库不要提交：

- `.codex/`
- `_local/`
- 同步脚本
- package 文件或 lockfile
- CSV / TSV
- 日志
- `.env`
- 凭据
- 代理配置
- git hook
- `pnpm-workspace.yaml`

提交前必须检查：

```bash
git diff --cached --name-only
```

医疗数据提交只能包含三份 JSON：

```text
src/_data/medicalData.json
src/_data/medicalChildData.json
src/_data/medicalAbroadData.json
```
