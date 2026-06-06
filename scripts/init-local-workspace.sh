#!/usr/bin/env bash
set -euo pipefail

required_json_files=(
  "src/_data/medicalData.json"
  "src/_data/medicalChildData.json"
  "src/_data/medicalAbroadData.json"
)

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
skill_root="$(cd "$script_dir/.." && pwd)"

fail() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

assert_target_repo_root() {
  [[ -d ".git" ]] || fail "Current directory is not the cloned target repository root: missing .git/. Run this script after git clone and cd <target-repo>."

  local file
  for file in "${required_json_files[@]}"; do
    [[ -f "$file" ]] || fail "Current directory is not the expected target repository root: missing $file."
  done
}

copy_required_file() {
  local source="$1"
  local destination="$2"

  [[ -f "$source" ]] || fail "Required skill file was not found: $source"
  mkdir -p "$(dirname "$destination")"
  cp "$source" "$destination"
}

assert_target_repo_root

mkdir -p _local/input _local/scripts _local/logs _local/workflow

copy_required_file "$skill_root/scripts/sync-public-sheet.sh" "_local/scripts/sync-public-sheet.sh"
copy_required_file "$skill_root/scripts/validate-local-workspace.sh" "_local/scripts/validate-local-workspace.sh"
copy_required_file "$skill_root/templates/medical-data-workflow.md" "_local/workflow/medical-data-workflow.md"
copy_required_file "$skill_root/templates/RUNBOOK.md" "_local/workflow/RUNBOOK.md"
copy_required_file "$skill_root/templates/medical-workflow-lessons.md" "_local/workflow/medical-workflow-lessons.md"

if [[ ! -f ".gitignore" ]] || ! grep -Eq '^[[:space:]]*/_local/[[:space:]]*$' .gitignore; then
  printf 'Warning: the target repository .gitignore does not appear to ignore /_local/.\n' >&2
  printf 'Add this line manually if needed: /_local/\n' >&2
fi

printf 'Local medical map workspace initialized.\n'
printf 'Created or verified: _local/input, _local/scripts, _local/logs, _local/workflow\n'
printf 'Copied Bash workflow scripts and templates.\n'
printf 'Do not commit _local/, CSV exports, logs, credentials, or local workflow scratch files to the target repository.\n'
