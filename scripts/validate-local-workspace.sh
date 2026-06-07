#!/usr/bin/env bash
set -euo pipefail

csv_path="_local/input/medical-feedback.csv"
json_files=(
  "src/_data/medicalData.json"
  "src/_data/medicalChildData.json"
  "src/_data/medicalAbroadData.json"
)
allowed_staged_files=(
  "src/_data/medicalData.json"
  "src/_data/medicalChildData.json"
  "src/_data/medicalAbroadData.json"
)
required_headers=(
  "序号"
  "更新状态"
  "分类"
  "省份/城市"
  "医院名称"
  "医生姓名"
  "诊疗方向"
  "就诊评价与详细更新信息"
  "链接"
)

fail() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

[[ -d ".git" ]] || fail "Current directory is not the cloned target repository root: missing .git/."

for json_file in "${json_files[@]}"; do
  [[ -f "$json_file" ]] || fail "Missing target JSON: $json_file"
done

[[ -f "$csv_path" ]] || fail "Missing CSV: $csv_path"
[[ -s "$csv_path" ]] || fail "CSV is empty: $csv_path"

header="$(head -n 1 "$csv_path" || true)"
[[ -n "$header" ]] || fail "CSV header is empty."

for required_header in "${required_headers[@]}"; do
  if [[ "$header" != *"$required_header"* ]]; then
    fail "CSV header is missing required column: $required_header"
  fi
done

command -v node >/dev/null 2>&1 || fail "Node.js is required for JSON parse validation."

for json_file in "${json_files[@]}"; do
  node -e "const text = require('fs').readFileSync(process.argv[1], 'utf8').replace(/^\uFEFF/, ''); JSON.parse(text); console.log(process.argv[1] + ' OK');" "$json_file"
done

git status --short --branch

if staged_files="$(git diff --cached --name-only)"; then
  while IFS= read -r staged_file; do
    [[ -n "$staged_file" ]] || continue
    allowed=0
    for allowed_staged_file in "${allowed_staged_files[@]}"; do
      if [[ "$staged_file" == "$allowed_staged_file" ]]; then
        allowed=1
        break
      fi
    done
    [[ "$allowed" -eq 1 ]] || fail "Unexpected staged file for a medical data commit: $staged_file"
  done <<< "$staged_files"
else
  fail "Could not inspect staged files."
fi

cat <<'EOF'

Validation complete.
Staged file guard passed. Medical data commits may include only:
- src/_data/medicalData.json
- src/_data/medicalChildData.json
- src/_data/medicalAbroadData.json

Never stage or commit:
- _local/
- .codex/
- .learnings/
- skill files, scripts, or docs
- CSV / TSV
- logs
- .env
- credentials
- package files
- lockfiles
- git hooks
- pnpm-workspace.yaml
EOF
