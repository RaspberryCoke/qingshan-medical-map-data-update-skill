# 鍖荤枟鍦板浘鏇存柊 Runbook

鏈枃浠舵湇鍔′簬鐩爣浠撳簱鐨勬湰鍦?`_local/` 宸ヤ綔鍖猴紝涓嶆彁浜ゅ埌鐩爣浠撳簱銆?

## 蹇€熷叆鍙?

褰撶敤鎴疯姹傛墽琛屽尰鐤楀湴鍥炬湰鍦板伐浣滄祦鏃讹細

1. 纭褰撳墠鐩綍鏄?clone 鍚庣殑鐩爣浠撳簱鏍圭洰褰曘€?
2. 浼樺厛杩愯 preflight锛?

   ```bash
   bash ./_local/scripts/preflight-medical-workflow.sh --task-slug "update-medical-map-data-YYYYMMDD"
   ```

   Windows:

   ```powershell
   .\_local\scripts\preflight-medical-workflow.ps1 -TaskSlug "update-medical-map-data-YYYYMMDD"
   ```

3. 濡傛灉 preflight 鏇存柊浜?skill 浠撳簱锛屽仠姝㈠綋鍓嶆祦绋嬶紝閲嶅惎 Codex 鎴栭噸鏂板紑濮嬩换鍔″悗鍐嶇户缁€?
4. 璇诲彇 `_local/input/medical-feedback.csv`銆?
5. 璇诲彇涓変釜鐩爣 JSON銆?
6. 鍏堣緭鍑烘暣浣撳垎鏋愬拰閫愯澶勭悊鏂规銆?
7. 绛夊緟鐢ㄦ埛浜哄伐鎵瑰噯鍚庡啀淇敼 JSON銆?
8. 鍙湪鐢ㄦ埛鏄庣‘瑕佹眰鏃?commit銆乸ush 鎴栧垱寤?PR銆?

## 鏁版嵁婧愯鍒?

褰撳墠鍞竴鍏ュ彛锛?

```text
_local/input/medical-feedback.csv
```

涓嶈鍐嶄娇鐢細

- `_local/input/medical-feedback.tsv`
- `_local/.env`
- credentials
- Google API
- Service Account
- OAuth
- `pnpm sync:sheet`
- 鎸佷箙鍖栦唬鐞嗛厤缃?

鍏紑 CSV 閾炬帴榛樿浣跨敤宸叉壒鍑嗙殑宸ヤ綔娴侀厤缃紝涔熷彲鐢辩敤鎴峰湪杩愯鑴氭湰鏃惰鐩栥€備笉瑕佹妸鍘熷 CSV銆佺瀵嗗弽棣堟垨鏃ュ織鎻愪氦鍒扮洰鏍囦粨搴撱€?

## Preflight 瑕佹眰

preflight 蹇呴』锛?

- 妫€鏌?skill 浠撳簱鏄惁钀藉悗 upstream锛涘鏋滆嚜鍔?fast-forward 鏇存柊浜?skill锛岀珛鍗冲仠姝㈠苟瑕佹眰閲嶅惎 Codex 鎴栭噸鏂板紑濮嬩换鍔°€?
- 妫€鏌ュ凡瀹夎 Codex skill 鐩綍涓殑 `.codex-skill-version.json` 鏄惁绛変簬杩滅 `main` 鏈€鏂扮増鏈紱濡傛灉涓嶆槸鏈€鏂帮紝鍗歌浇骞堕噸瑁?`~/.codex/skills/qingshan-medical-map-data-update-skill` 鍚庣珛鍗冲仠姝€?
- 濡傛灉 skill 浠撳簱鏈夋湰鍦版敼鍔紝鍋滄骞舵姤鍛婏紝涓嶈兘鑷姩瑕嗙洊銆?
- 纭鐩爣浠撳簱 root銆乣origin`銆乣git`銆乣gh auth status` 鍜?`node`銆?
- 缂哄皯 `_local/` 鏃惰嚜鍔ㄥ垱寤烘湰鍦板伐浣滃尯骞跺悓姝?CSV銆?
- 浠?`upstream/main` 鍚屾鏈湴 `main`锛屽啀鍒涘缓鎴栧垏鎹㈠埌 `codex/<task-slug>` 鍒嗘敮锛屼笉 push `origin/main`銆?
- GitHub 杩炴帴澶辫触鏃讹紝鍏堝湪褰撳墠鏈変唬鐞嗙殑鎯呭喌涓嬪皾璇曚笉璧颁唬鐞嗭紱鐩磋繛澶辫触鍚庡啀灏濊瘯 `127.0.0.1:7890`銆?

## 澶勭悊鍘熷垯

- `鏈洿鏂癭 琛屾槸榛樿澶勭悊鍊欓€夈€?
- `宸叉洿鏂癭 琛岄粯璁ゅ彧缁熻鍜岃烦杩囷紝涓嶅仛鏌ラ噸鎴栭€愯鏂规锛涘彧鏈夌敤鎴疯姹?audit 鏃舵墠灞曞紑銆?
- `鏃犳晥淇℃伅` 榛樿鎶ュ憡骞惰烦杩囷紝闄ら潪鐢ㄦ埛鏄庣‘鎵瑰噯澶勭悊銆?
- `鍒嗙被` 鍙綔鍒濈瓫锛岀洰鏍囨枃浠惰繕瑕佺粨鍚堝湴鍖恒€佸尰闄€佺瀹ゃ€佸尰鐢熴€佽瘖鐤楁柟鍚戝拰澶囨敞鍒ゆ柇銆?
- `shares` 姘歌繙鐢辩敤鎴锋墜鍔ㄧ淮鎶わ紱Codex 涓嶆柊澧炪€佷笉淇敼銆佷笉鍒犻櫎銆?
- 娌℃湁鍖荤敓濮撳悕浣嗕俊鎭湁鏁堟椂锛屼紭鍏堣€冭檻鍖婚櫌绾?`notes`锛屼笉瑕佺敓鎴愬崰浣嶅尰鐢熴€?
- `capacity` 鍙拷鍔犳槑纭敮鎸侀」锛屼笉鍥犱负鏂颁俊鎭緝灏戣€岃鐩栨垨鍒犻櫎鏃у€笺€?
- `notes` 蹇呴』闈㈠悜鍦板浘鐢ㄦ埛锛屽幓鎺夋埅鍥剧姸鎬併€佸唴閮ㄥ鏍稿垽鏂拰鑱婂ぉ鍙ｅ惢銆?

鐩爣鏂囦欢涓€鑸鍒欙細

- 鍥藉唴鎴愪汉鎴栨硾鐢ㄨ祫婧愶細`src/_data/medicalData.json`
- 鍎跨/闈掑皯骞寸浉鍏宠祫婧愶細`src/_data/medicalChildData.json`
- 娴峰鎴栧澶栬祫婧愶細`src/_data/medicalAbroadData.json`

## 淇敼鍓嶅繀椤昏緭鍑烘柟妗?

瀹為檯缂栬緫 JSON 鍓嶏紝瀵归粯璁ゅ€欓€夎閫愯缁欏嚭锛?

1. CSV 搴忓彿銆?
2. 鐩爣鏂囦欢銆?
3. 鏂板杩樻槸鍚堝苟銆?
4. 鐩爣 area / hospital / doctor銆?
5. `capacity` 澶勭悊鏂瑰紡銆?
6. `notes` 鍑嗗鍐欏叆鐨勬枃鏈€?
7. 涓嶆洿鏂版椂鐨勫師鍥犮€?
8. 椋庨櫓鎴栦笉纭畾鐐广€?

绛夊緟鐢ㄦ埛鏄庣‘鎵瑰噯鍚庢墠鑳戒慨鏀?JSON銆?

## 妫€鏌?

JSON 淇敼鍚庤嚦灏戣繍琛岋細

```bash
node -e "for (const f of ['src/_data/medicalData.json','src/_data/medicalChildData.json','src/_data/medicalAbroadData.json']) { const text = require('fs').readFileSync(f,'utf8').replace(/^\uFEFF/, ''); JSON.parse(text); console.log(f + ' OK'); }"
git diff --check
git status --short --branch
```

## 鐩爣浠撳簱杈圭晫

鐩爣浠撳簱鍙厑璁告彁浜わ細

- `.gitignore` 涓拷鐣?`/_local/` 鐨勮鍒欍€?
- 缁忎汉宸ユ壒鍑嗗悗鐨?`src/_data/*.json` 鏁版嵁鍙樻洿銆?

鐩爣浠撳簱涓嶈鎻愪氦锛?

- `.codex/`
- `_local/`
- 鍚屾鑴氭湰
- package 鏂囦欢鎴?lockfile
- CSV / TSV
- 鏃ュ織
- `.env`
- 鍑嵁
- 浠ｇ悊閰嶇疆
- git hook
- `pnpm-workspace.yaml`

鎻愪氦鍓嶅繀椤绘鏌ワ細

```bash
git diff --cached --name-only
```

鍖荤枟鏁版嵁鎻愪氦鍙兘鍖呭惈涓変唤 JSON锛?

```text
src/_data/medicalData.json
src/_data/medicalChildData.json
src/_data/medicalAbroadData.json
```

## Staged Handoff

For every stage, first say what will happen, then execute the stage
automatically unless a safety risk appears. After the stage, report what was
done, what the user must check, and the exact next instruction to send.

Mandatory stops: before JSON writes, before commit, before push, before creating
a fork Draft PR, before production PR handoff, and before any operation that
could affect production repository history.

Use these handoff prompts:

```text
继续执行阶段 1：同步公开 CSV，并只读分析本次反馈，不修改任何 JSON。
我已审核分析结果，可以继续阶段 2：根据分析结果修改 JSON，但不要 commit。
我已审核 JSON 修改结果，可以继续阶段 3：创建本地 commit，但不要 push。
继续阶段 4：在 push 前同步上游主仓库，确保历史线性。
确认可以 push 到 fork 仓库，继续阶段 5：push 当前分支。
继续阶段 6：在 fork 仓库创建 draft PR。
我已检查 fork 仓库 draft PR，没有问题。继续阶段 7：准备向主仓库提交 PR 前的最终同步检查。
确认最终检查通过。继续阶段 8：向主仓库提交 PR。
```

## Publishing PRs

Default to no push and no PR. Only commit, push, or create a fork Draft PR when
the user follows the staged handoff. Before any GitHub write, report `git remote -v`,
`git branch --show-current`, `gh repo view --json nameWithOwner,defaultBranchRef`,
`origin`, `upstream`, the target operation, and whether it writes to a remote.
Stop if the repository identity is unclear.

Repository roles: `upstream` is the production repository and read-only for
AI/Codex; `origin` is the user's fork and writable only for
`codex/<task-slug>`; `main` is never directly modified by AI/Codex. Use one
short-lived branch per task:

```bash
git fetch upstream
git switch main
git reset --hard upstream/main
git switch -c codex/<task-slug> upstream/main
```

Stop before `git reset --hard upstream/main` if the worktree is dirty or local
`main` has commits that are not in `upstream/main`. Do not push `origin/main`.

Before pushing or creating a fork Draft PR:

```bash
git fetch upstream
git switch codex/<task-slug>
git rebase upstream/main
git status
git diff --cached --name-only
```

If rebase produces conflicts, stop and report the conflicted files. After a
successful rebase, push only to the fork task branch:

```bash
git push --force-with-lease origin codex/<task-slug>
```

`git push --force-with-lease` is allowed only for `origin/codex/<task-slug>`.
Never use it for `upstream`, `origin/main`, or any default branch. Never use
`git merge upstream/main`, `git merge origin/main`, `gh pr merge --merge`, or a
GitHub "Update branch" action that creates a merge commit. Keep medical map PR
history linear on top of `upstream/main`.

Keep PR bodies reviewer-facing: committed JSON changes, map-user-visible impact,
committed-file validation, and `Please use squash merge when this PR is ready.`
Do not include `_local/`, CSV sync details, row-count bookkeeping, local tool
failures, proxy recovery, or uncommitted logs.

Fork Draft PRs must be from `origin/codex/<task-slug>` to the fork default
branch. Do not create the production PR; guide the user to create it manually
from the fork branch to the production repository after the final sync check.
Merging is a human-maintainer action. Do not run `gh pr merge`. For production
PR readiness:

```bash
git fetch upstream
git switch codex/<task-slug>
git rebase upstream/main
git status
git log --oneline --graph --decorate --all -20
gh pr view <PR> --json mergeStateStatus,isDraft,state,statusCheckRollup
gh pr checks <PR>
```

Confirm the current branch is `codex/<task-slug>`, the PR branch is based on
latest `upstream/main`, there are no merge commits, there are no uncommitted
changes, the diff only contains task-related changes, and CI has passed or the
blocker is explained.

Final integration must use squash merge:

```bash
gh pr merge <PR> --squash --delete-branch
```

The command above is for the human maintainer to run after review and passing CI.
AI/Codex must not run it, close PRs, delete remote branches, or merge directly to
`upstream/main`. After a human Squash merge:

```bash
gh pr view <PR> --json state,mergeCommit
git fetch upstream main --prune
git switch main
git reset --hard upstream/main
git branch -d codex/<task-slug>
```
