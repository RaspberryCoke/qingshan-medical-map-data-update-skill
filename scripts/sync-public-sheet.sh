#!/usr/bin/env bash
set -euo pipefail

url="${1:-}"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
output_path="${OUTPUT_PATH:-$script_dir/../input/medical-feedback.csv}"
log_path="${LOG_PATH:-$script_dir/../logs/sync-public-sheet.log}"
tmp_path="$output_path.tmp"

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
required_json_files=(
  "src/_data/medicalData.json"
  "src/_data/medicalChildData.json"
  "src/_data/medicalAbroadData.json"
)

fail() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

write_log() {
  mkdir -p "$(dirname "$log_path")"
  printf '%s\n' "$1" >> "$log_path"
}

log_failure() {
  local message="$1"
  write_log "[$started_at]
url: (provided at runtime, not logged)
output: $output_path
success: no
error: $message
"
}

[[ -n "$url" ]] || fail "Usage: bash ./_local/scripts/sync-public-sheet.sh \"<published-csv-url>\""
[[ -d ".git" ]] || fail "Current directory is not the cloned target repository root: missing .git/."
for required_json_file in "${required_json_files[@]}"; do
  [[ -f "$required_json_file" ]] || fail "Current directory is not the expected target repository root: missing $required_json_file."
done
[[ "$url" == https://* ]] || fail "The published CSV URL must use https://."
command -v curl >/dev/null 2>&1 || fail "curl is required."

started_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
mkdir -p "$(dirname "$output_path")"

if ! curl --fail --location --silent --show-error "$url" --output "$tmp_path"; then
  log_failure "curl failed to download the CSV"
  rm -f "$tmp_path"
  exit 1
fi

if [[ ! -s "$tmp_path" ]]; then
  log_failure "Downloaded CSV is empty"
  rm -f "$tmp_path"
  exit 1
fi

header="$(head -n 1 "$tmp_path" || true)"
for required_header in "${required_headers[@]}"; do
  if [[ "$header" != *"$required_header"* ]]; then
    log_failure "Downloaded CSV header is missing required column: $required_header"
    rm -f "$tmp_path"
    exit 1
  fi
done

mv "$tmp_path" "$output_path"
line_count="$(wc -l < "$output_path" | tr -d ' ')"

write_log "[$started_at]
url: (provided at runtime, not logged)
output: $output_path
lines: $line_count
success: yes
"

printf 'Downloaded public CSV.\n'
printf 'Output: %s\n' "$output_path"
printf 'Lines: %s\n' "$line_count"
printf 'Log: %s\n' "$log_path"
