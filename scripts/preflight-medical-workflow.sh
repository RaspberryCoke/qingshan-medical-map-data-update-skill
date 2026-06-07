#!/usr/bin/env bash
set -euo pipefail

task_slug="update-medical-map-data-$(date +%Y%m%d)"
expected_origin="ittuann/qingshanasd"
skill_root=""
published_csv_url="https://docs.google.com/spreadsheets/d/e/2PACX-1vRxiGx8JadZ-HPRJBb8-PMscizOv-4UpMqa56XZOhvr8ddkS99vm7hFJ-yee7c3btGrR4eXPRW_SAdi/pub?gid=1596563937&single=true&output=csv"
skip_skill_update=0
skip_csv_sync=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --task-slug)
      task_slug="${2:?Missing value for --task-slug}"
      shift 2
      ;;
    --expected-origin)
      expected_origin="${2:?Missing value for --expected-origin}"
      shift 2
      ;;
    --skill-root)
      skill_root="${2:?Missing value for --skill-root}"
      shift 2
      ;;
    --published-csv-url)
      published_csv_url="${2:?Missing value for --published-csv-url}"
      shift 2
      ;;
    --skip-skill-update)
      skip_skill_update=1
      shift
      ;;
    --skip-csv-sync)
      skip_csv_sync=1
      shift
      ;;
    *)
      printf 'Error: unknown argument: %s\n' "$1" >&2
      exit 1
      ;;
  esac
done

required_json_files=(
  "src/_data/medicalData.json"
  "src/_data/medicalChildData.json"
  "src/_data/medicalAbroadData.json"
)
proxy_vars=(HTTP_PROXY HTTPS_PROXY ALL_PROXY http_proxy https_proxy all_proxy)

fail() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "Required command not found: $1"
}

save_proxy_env() {
  for name in "${proxy_vars[@]}"; do
    if [[ -n "${!name+x}" ]]; then
      printf 'export %s=%q\n' "$name" "${!name}"
    else
      printf 'unset %s\n' "$name"
    fi
  done
}

clear_proxy_env() {
  local name
  for name in "${proxy_vars[@]}"; do
    unset "$name"
  done
}

restore_proxy_env() {
  local snapshot="$1"
  eval "$snapshot"
}

has_proxy_env() {
  local name
  for name in "${proxy_vars[@]}"; do
    if [[ -n "${!name-}" ]]; then
      return 0
    fi
  done
  return 1
}

local_proxy_reachable() {
  if command -v nc >/dev/null 2>&1; then
    nc -z 127.0.0.1 7890 >/dev/null 2>&1
    return $?
  fi
  if command -v bash >/dev/null 2>&1 && command -v timeout >/dev/null 2>&1; then
    timeout 1 bash -c '</dev/tcp/127.0.0.1/7890' >/dev/null 2>&1
    return $?
  fi
  return 1
}

invoke_github_command() {
  local description="$1"
  shift
  local snapshot
  snapshot="$(save_proxy_env)"

  printf 'Running: %s\n' "$description"
  if "$@"; then
    restore_proxy_env "$snapshot"
    return 0
  fi

  if has_proxy_env; then
    printf 'Warning: %s failed while proxy variables were set. Retrying once without proxy.\n' "$description" >&2
    clear_proxy_env
    if "$@"; then
      restore_proxy_env "$snapshot"
      return 0
    fi
  fi

  if local_proxy_reachable; then
    printf 'Warning: %s failed. Retrying once with HTTP(S)_PROXY=http://127.0.0.1:7890.\n' "$description" >&2
    export HTTP_PROXY="http://127.0.0.1:7890"
    export HTTPS_PROXY="http://127.0.0.1:7890"
    if "$@"; then
      restore_proxy_env "$snapshot"
      return 0
    fi
  fi

  restore_proxy_env "$snapshot"
  fail "$description failed after direct/proxy recovery attempts."
}

resolve_skill_root() {
  if [[ -n "$skill_root" ]]; then
    printf '%s\n' "$skill_root"
    return
  fi
  if [[ -f "_local/workflow/skill-root.txt" ]]; then
    head -n 1 "_local/workflow/skill-root.txt"
    return
  fi
}

update_skill_if_needed() {
  [[ "$skip_skill_update" -eq 0 ]] || {
    printf 'Skipping skill self-update check.\n'
    return
  }

  local resolved_skill_root
  resolved_skill_root="$(resolve_skill_root || true)"
  if [[ -z "$resolved_skill_root" ]]; then
    printf 'Warning: skill root is unknown; skipping automatic skill update check.\n' >&2
    return
  fi
  if [[ ! -d "$resolved_skill_root/.git" ]]; then
    printf 'Warning: skill root is not a Git repository; skipping automatic skill update check: %s\n' "$resolved_skill_root" >&2
    return
  fi
  if [[ -n "$(git -C "$resolved_skill_root" status --porcelain)" ]]; then
    fail "Skill repository has local changes; stop before running the workflow: $resolved_skill_root"
  fi
  if ! git -C "$resolved_skill_root" rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
    printf 'Warning: skill repository has no upstream branch; skipping automatic skill update: %s\n' "$resolved_skill_root" >&2
    return
  fi

  invoke_github_command "fetch latest skill repository state" git -C "$resolved_skill_root" fetch origin
  local behind
  behind="$(git -C "$resolved_skill_root" rev-list --count 'HEAD..@{u}')"
  if [[ "$behind" -gt 0 ]]; then
    invoke_github_command "fast-forward update skill repository" git -C "$resolved_skill_root" pull --ff-only
    fail "The skill repository was updated. Restart Codex or start a new run so the updated skill instructions are loaded."
  fi
  printf 'Skill repository is up to date.\n'
}

normalize_task_slug() {
  local value
  value="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9._-]+/-/g; s/^-+//; s/-+$//')"
  [[ -n "$value" ]] || fail "Task slug cannot be empty after normalization."
  printf '%s\n' "$value"
}

assert_target_repo_root() {
  [[ -d ".git" ]] || fail "Current directory is not the cloned target repository root: missing .git/."
  local file
  for file in "${required_json_files[@]}"; do
    [[ -f "$file" ]] || fail "Current directory is not the expected target repository root: missing $file."
  done
}

assert_origin() {
  local origin
  origin="$(git remote get-url origin)"
  [[ "$origin" == *"$expected_origin"* ]] || fail "Unexpected origin remote. Expected it to contain '$expected_origin', got '$origin'."
}

assert_clean_worktree() {
  [[ -z "$(git status --porcelain)" ]] || fail "Target repository has local changes. Commit, stash, or discard them before preflight switches branches."
}

initialize_local_workspace() {
  mkdir -p _local/input _local/scripts _local/logs _local/workflow
  local resolved_skill_root
  resolved_skill_root="$(resolve_skill_root || true)"
  if [[ -n "$resolved_skill_root" && -d "$resolved_skill_root" ]]; then
    printf '%s\n' "$resolved_skill_root" > _local/workflow/skill-root.txt
  fi
}

sync_csv_if_needed() {
  [[ "$skip_csv_sync" -eq 0 ]] || {
    printf 'Skipping CSV sync.\n'
    return
  }
  if [[ -f "_local/input/medical-feedback.csv" ]]; then
    printf 'CSV already exists: _local/input/medical-feedback.csv\n'
    return
  fi
  if [[ ! -f "_local/scripts/sync-public-sheet.sh" ]]; then
    printf 'Warning: CSV is missing and sync script is unavailable: _local/scripts/sync-public-sheet.sh\n' >&2
    return
  fi
  bash ./_local/scripts/sync-public-sheet.sh "$published_csv_url"
}

update_skill_if_needed
require_command git
require_command gh
require_command node

assert_target_repo_root
assert_origin
assert_clean_worktree

git --version
gh --version
node --version
invoke_github_command "check GitHub CLI authentication" gh auth status

initialize_local_workspace
sync_csv_if_needed

git switch main
invoke_github_command "fast-forward target repository main" git pull --ff-only origin main

branch_name="codex/$(normalize_task_slug "$task_slug")"
if git branch --list "$branch_name" | grep -q .; then
  git switch "$branch_name"
else
  git switch -c "$branch_name"
fi

printf '\nPreflight complete.\n'
printf 'Task branch: %s\n' "$branch_name"
printf 'Continue with read-only CSV/JSON analysis before any approved JSON edits.\n'
