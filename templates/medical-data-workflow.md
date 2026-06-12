# Codex 鏈湴鍖荤枟鍦板浘鏁版嵁鏇存柊宸ヤ綔娴?

浣犳鍦ㄧ洰鏍囦粨搴撴牴鐩綍鍗忓姪缁存姢鈥滃氨璇婂湴鍥?/ 鍖荤枟鍦板浘鈥濇暟鎹€?

## 鏍稿績杈圭晫

- 褰撳墠鍞竴鏁版嵁鍏ュ彛鏄?`_local/input/medical-feedback.csv`銆?
- CSV 鏉ヨ嚜 Google Sheet 鈥滃彂甯冨埌缃戠粶鈥濈殑鍏紑 CSV 閾炬帴銆?
- 涓嶄娇鐢?Google API銆丼ervice Account銆丱Auth銆乣.env`銆佹寔涔呭寲浠ｇ悊閰嶇疆銆乀SV 鎴?pnpm 鍚屾鍛戒护銆?
- `_local/` 鏄洰鏍囦粨搴撳拷鐣ョ殑鏈湴宸ヤ綔鍖猴紝鍙互鐢辩敤鎴锋墜鍔ㄤ綔涓虹嫭绔嬫湰鍦?Git 浠撳簱缁存姢銆?
- 鐩爣浠撳簱涓嶈鎻愪氦 `_local/`銆乣.codex/`銆佸悓姝ヨ剼鏈€丆SV/TSV銆佹棩蹇椼€乣.env`銆佸嚟鎹€佷唬鐞嗛厤缃€乸ackage 鏂囦欢銆乴ockfile銆乬it hook 鎴?`pnpm-workspace.yaml`銆?
- `shares` 姘歌繙鐢辩敤鎴锋墜鍔ㄧ淮鎶わ紱Codex 涓嶆柊澧炪€佷笉淇敼銆佷笉鍒犻櫎銆?

鏈粡鐢ㄦ埛鏄庣‘鎵瑰噯锛岀姝慨鏀逛换浣?JSON 鏁版嵁鏂囦欢銆?

## 寮€濮嬪墠妫€鏌?

鍏堣繍琛?preflight锛?

```powershell
.\_local\scripts\preflight-medical-workflow.ps1 -TaskSlug "update-medical-map-data-YYYYMMDD"
```

```bash
bash ./_local/scripts/preflight-medical-workflow.sh --task-slug "update-medical-map-data-YYYYMMDD"
```

preflight 蹇呴』纭锛?

```text
.git/
src/_data/medicalData.json
src/_data/medicalChildData.json
src/_data/medicalAbroadData.json
```

骞朵笖蹇呴』妫€鏌ュ凡瀹夎 Codex skill 鐨?`.codex-skill-version.json` 鏄惁绛変簬杩滅 `main` 鏈€鏂扮増鏈紱鑻ヤ笉鏄渶鏂帮紝鍗歌浇骞堕噸瑁?`~/.codex/skills/qingshan-medical-map-data-update-skill` 鍚庡仠姝㈠綋鍓嶆祦绋嬶紝璁╃敤鎴烽噸鍚?Codex 鎴栭噸鏂板紑濮嬩换鍔″悗鍐嶇户缁€傝嫢 skill 浠撳簱鏈夋湰鍦版敼鍔紝鍋滄骞舵姤鍛娿€?

preflight 杩樺繀椤绘鏌?`git`銆乣gh auth status`銆乣node`锛岀‘璁?`origin` fork, `upstream` points to `ittuann/qingshanasd`锛屼粠 `upstream/main` 鍒涘缓鎴栧垏鎹㈠埌 `codex/<task-slug>` 鍒嗘敮锛屼笉 push `origin/main`銆?

## 鍚屾鍏紑 CSV

濡傛灉 `_local/input/medical-feedback.csv` 涓嶅瓨鍦紝preflight 榛樿浣跨敤宸叉壒鍑嗙殑鍏紑 CSV URL 鍚屾銆傜敤鎴蜂篃鍙互鎻愪緵鍏紑 CSV 閾炬帴锛屾牴鎹郴缁熼€夋嫨锛?

```powershell
.\_local\scripts\sync-public-sheet.ps1 -Url "<published-csv-url>"
```

```bash
bash ./_local/scripts/sync-public-sheet.sh "<published-csv-url>"
```

鑴氭湰杈撳嚭锛?

```text
_local/input/medical-feedback.csv
_local/logs/sync-public-sheet.log
```

鏃ュ織涓嶅簲璁板綍鐪熷疄 CSV URL銆?

## CSV 绾﹀畾

褰撳墠鏂囦欢锛?

```text
_local/input/medical-feedback.csv
```

瀹屾暣棰勬湡琛ㄥご锛?

```text
搴忓彿,鏇存柊鐘舵€?鏇存柊鏃堕棿,鍒嗙被,鏁版嵁鏉ユ簮,鐪佷唤/鍩庡競,鍖婚櫌鍚嶇О,绉戝,鍖荤敓濮撳悕,璇婄枟鏂瑰悜,灏辫瘖璇勪环涓庤缁嗘洿鏂颁俊鎭?閾炬帴,鎻愬彇鏂囧瓧,鍐呭姒傛嫭,浜哄伐瀹℃牳,瀹℃牳鏃堕棿,浜哄伐鏍￠獙,鏍￠獙鏃堕棿,鏉ユ簮鐢ㄦ埛
```

瀛楁浣跨敤锛?

- `鍒嗙被`锛氬垵姝ュ垽鏂洰鏍囨枃浠躲€?
- `鐪佷唤/鍩庡競`锛氬垽鏂?`area`銆?
- `鍖婚櫌鍚嶇О`锛氭煡鎵炬垨鏂板鍖婚櫌銆?
- `绉戝`锛氬彲鍐欏叆鍖婚櫌鎴栧尰鐢?notes锛岃褰掑睘鑰屽畾銆?
- `鍖荤敓濮撳悕`锛氭煡鎵炬垨鏂板鍖荤敓锛涗负绌烘垨鍗犱綅鏃朵笉瑕佺敓鎴愬尰鐢熴€?
- `璇婄枟鏂瑰悜`锛氳浆鎹负 `capacity` 鍊欓€夈€?
- `灏辫瘖璇勪环涓庤缁嗘洿鏂颁俊鎭痐锛氭鼎鑹插悗鍐欏叆鐢ㄦ埛鍙 `notes`銆?
- `閾炬帴`锛氬彧浣滀汉宸ュ弬鑰冿紱涓嶈嚜鍔ㄥ啓鍏?`shares`銆?
- `鎻愬彇鏂囧瓧`銆乣鍐呭姒傛嫭`銆乣浜哄伐瀹℃牳`銆乣瀹℃牳鏃堕棿`銆乣浜哄伐鏍￠獙`銆乣鏍￠獙鏃堕棿`銆乣鏉ユ簮鐢ㄦ埛`锛氶粯璁ゅ彧浣滃垽鏂弬鑰冦€?

## 绗竴闃舵锛氬彧璇诲垎鏋?

璇诲彇 CSV 鍜屼笁涓?JSON 鍚庯紝鍏堝彧鍋氬垎鏋愶紝绂佹淇敼鏂囦欢銆?

蹇呴』杈撳嚭锛?

- CSV 鎬昏鏁般€?
- `鏇存柊鐘舵€乣 鍒嗗竷銆?
- `鍒嗙被` 鍒嗗竷銆?
- `鏈洿鏂癭 琛屼綔涓洪粯璁ゅ€欓€夈€?
- `鏃犳晥淇℃伅` 琛屼綔涓洪粯璁よ烦杩囬」銆?
- `宸叉洿鏂癭 琛屼綔涓洪粯璁よ烦杩囩粺璁￠」锛涢櫎闈炵敤鎴锋槑纭姹?audit锛屽惁鍒欎笉鍋氭煡閲嶆垨閫愯鏂规銆?
- 鍏抽敭瀛楁缂哄け鎯呭喌銆?
- 鍜岀幇鏈?JSON 鐨勬煡閲嶆儏鍐点€?
- 鐤戜技閲嶅鍖婚櫌 / 鍖荤敓銆?
- 闇€瑕佷汉宸ュ垽鏂殑琛屻€?

## 绗簩闃舵锛氶€愯澶勭悊鏂规

蹇呴』瀵归粯璁ゅ€欓€夎缁欏嚭澶勭悊鏂规锛屼笉鑳介潤榛樺拷鐣ュ€欓€夎銆傞粯璁ゅ€欓€夎鏄?`鏈洿鏂癭锛沗鏃犳晥淇℃伅` 榛樿鎶ュ憡骞惰烦杩囷紝`宸叉洿鏂癭 榛樿鍙粺璁″拰璺宠繃锛岄櫎闈炵敤鎴疯姹?audit銆?

姣忚鏂规蹇呴』鍖呭惈锛?

- CSV 搴忓彿銆?
- 鍘熸洿鏂扮姸鎬併€?
- 澶勭悊鍐冲畾锛氭洿鏂?/ 璺宠繃 / 鏃犳晥 / 闇€瑕佷汉宸ュ垽鏂€?
- 鐩爣鏂囦欢銆?
- 鏂板杩樻槸鍚堝苟銆?
- 鐩爣 area / hospital / doctor銆?
- `capacity` 濡備綍澶勭悊銆?
- `notes` 鍑嗗鎬庝箞鍐欍€?
- 涓嶆洿鏂版椂鐨勫師鍥犮€?
- 椋庨櫓鎴栦笉纭畾鐐广€?

杈撳嚭鏂规鍚庡仠姝紝绛夊緟鐢ㄦ埛鏄庣‘鎵瑰噯銆?

## 淇敼鍚庢鏌?

鎵瑰噯鍚庡彧淇敼锛?

```text
src/_data/medicalData.json
src/_data/medicalChildData.json
src/_data/medicalAbroadData.json
```

淇敼鍚庤繍琛岋細

```bash
node -e "for (const f of ['src/_data/medicalData.json','src/_data/medicalChildData.json','src/_data/medicalAbroadData.json']) { const text = require('fs').readFileSync(f,'utf8').replace(/^\uFEFF/, ''); JSON.parse(text); console.log(f + ' OK'); }"
git diff --check
git status --short --branch
```

榛樿涓?push锛屼笉鑷姩鍒涘缓 PR銆傚彧鏈夌敤鎴锋槑纭姹傛椂鎵?commit銆乸ush 鎴?PR銆?

鎻愪氦鍓嶅繀椤昏繍琛岋細

```bash
git diff --cached --name-only
```

鍖荤枟鏁版嵁鎻愪氦鍙兘鍖呭惈锛?

```text
src/_data/medicalData.json
src/_data/medicalChildData.json
src/_data/medicalAbroadData.json
```

濡傚寘鍚?`_local/`銆乣.learnings/`銆乻kill 鏂囦欢銆佽剼鏈€佹枃妗ｃ€丆SV/TSV銆佹棩蹇椼€佸嚟鎹€乸ackage 鏂囦欢銆乴ockfile銆乭ook 鎴栧叾浠栨棤鍏虫枃浠讹紝蹇呴』鍋滄銆?

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

Before pushing or creating a fork Draft PR, fetch latest `upstream/main`,
rebase, and verify only approved medical JSON files are staged:

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
GitHub "Update branch" action that creates a merge commit for medical map PRs.
Keep the PR branch linear on top of `upstream/main`.

The PR body must be reviewer-facing: summarize committed medical JSON changes,
map-user-visible impact, committed-file validation, and include `Please use
squash merge when this PR is ready.` Do not include `_local/`, CSV sync details,
candidate row bookkeeping, transient local tool failures, proxy recovery, or
uncommitted logs.

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
`upstream/main`. After a human Squash merge, confirm the PR is merged,
fetch/prune, refresh local `main`, and delete the local task branch only after it
has no unpushed commits:

```bash
gh pr view <PR> --json state,mergeCommit
git fetch upstream main --prune
git switch main
git reset --hard upstream/main
git branch -d codex/<task-slug>
```

## GitHub 杩炴帴鎭㈠

GitHub 杩炴帴澶辫触鏃讹紝妫€鏌?`HTTP_PROXY`銆乣HTTPS_PROXY`銆乣ALL_PROXY`銆佸皬鍐欏彉閲忎互鍙?Git proxy config銆傚綋鍓嶈缃簡浠ｇ悊鍗村け璐ユ椂锛屽厛涓存椂娓呯┖浠ｇ悊閲嶈瘯涓€娆★紱鐩磋繛澶辫触鍚庯紝鍐嶆鏌?`127.0.0.1:7890` 鏄惁鍙揪锛屽苟鐢?`HTTP_PROXY=http://127.0.0.1:7890`銆乣HTTPS_PROXY=http://127.0.0.1:7890` 閲嶈瘯涓€娆°€備粛澶辫触鏃讹紝灏濊瘯绛変环 `gh` 璺緞锛涘鏋滈兘澶辫触锛屾槑纭姤鍛婂凡灏濊瘯鐨勮矾寰勩€?
