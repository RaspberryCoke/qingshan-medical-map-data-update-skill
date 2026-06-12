#!/usr/bin/env bash
set -euo pipefail

task_slug="update-medical-map-data-$(date +%Y%m%d)"
expected_upstream="ittuann/qingshanasd"
skill_root=""
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
published_csv_url="https://docs.google.com/spreadsheets/d/e/2PACX-1vRxiGx8JadZ-HPRJBb8-PMscizOv-4UpMqa56XZOhvr8ddkS99vm7hFJ-yee7c3btGrR4eXPRW_SAdi/pub?gid=1596563937&single=true&output=csv"
skip_skill_update=0
skip_csv_sync=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --task-slug)
      task_slug="${2:?Missing value for --task-slug}"
      shift 2
      ;;
    --expected-upstream)
      expected_upstream="${2:?Missing value for --expected-upstream}"
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

invoke_github_output() {
  local description="$1"
  shift
  local snapshot output
  snapshot="$(save_proxy_env)"

  printf 'Running: %s\n' "$description" >&2
  if output="$("$@")"; then
    restore_proxy_env "$snapshot"
    printf '%s\n' "$output"
    return 0
  fi

  if has_proxy_env; then
    printf 'Warning: %s failed while proxy variables were set. Retrying once without proxy.\n' "$description" >&2
    clear_proxy_env
    if output="$("$@")"; then
      restore_proxy_env "$snapshot"
      printf '%s\n' "$output"
      return 0
    fi
  fi

  if local_proxy_reachable; then
    printf 'Warning: %s failed. Retrying once with HTTP(S)_PROXY=http://127.0.0.1:7890.\n' "$description" >&2
    export HTTP_PROXY="http://127.0.0.1:7890"
    export HTTPS_PROXY="http://127.0.0.1:7890"
    if output="$("$@")"; then
      restore_proxy_env "$snapshot"
      printf '%s\n' "$output"
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

  local updater_script="$script_dir/update-installed-skill.sh"
  if [[ ! -f "$updater_script" ]]; then
    updater_script="$resolved_skill_root/scripts/update-installed-skill.sh"
  fi
  if [[ -f "$updater_script" ]]; then
    bash "$updater_script" --installed-skill-root "$resolved_skill_root"
  else
    printf 'Warning: installed skill updater script is unavailable; falling back to Git repository update check.\n' >&2
  fi

  if [[ ! -d "$resolved_skill_root/.git" ]]; then
    printf 'Installed skill version check passed. Skill root is not a Git repository: %s\n' "$resolved_skill_root"
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

assert_repository_remotes() {
  local origin upstream
  origin="$(git remote get-url origin)"
  upstream="$(git remote get-url upstream)" || fail "Could not read upstream remote. Configure upstream to point to the production repository."
  [[ "$upstream" == *"$expected_upstream"* ]] || fail "Unexpected upstream remote. Expected it to contain '$expected_upstream', got '$upstream'."
  [[ "$origin" != "$upstream" && "$origin" != *"$expected_upstream"* ]] || fail "origin must be a fork, not the production repository. origin='$origin', upstream='$upstream'."
}

assert_github_repository_identity() {
  local current_branch repo_info repo_name origin_default_branch upstream_info upstream_repo upstream_default_branch origin upstream
  current_branch="$(git branch --show-current)"
  [[ -n "$current_branch" ]] || fail "Could not inspect current branch."
  origin="$(git remote get-url origin)"
  upstream="$(git remote get-url upstream)"

  repo_info="$(invoke_github_output "confirm GitHub repository identity" gh repo view --json nameWithOwner,defaultBranchRef --jq '[.nameWithOwner,.defaultBranchRef.name] | @tsv')"
  repo_name="${repo_info%%$'\t'*}"
  origin_default_branch="${repo_info#*$'\t'}"
  upstream_info="$(invoke_github_output "confirm upstream repository identity" gh repo view "$expected_upstream" --json nameWithOwner,defaultBranchRef --jq '[.nameWithOwner,.defaultBranchRef.name] | @tsv')"
  upstream_repo="${upstream_info%%$'\t'*}"
  upstream_default_branch="${upstream_info#*$'\t'}"

  printf '\nRepository safety gate:\n'
  printf 'Current repository: %s\n' "$repo_name"
  printf 'Current branch: %s\n' "$current_branch"
  printf 'origin points to: %s\n' "$origin"
  printf 'upstream points to: %s\n' "$upstream"
  printf 'Origin default branch: %s\n' "$origin_default_branch"
  printf 'Upstream default branch: %s\n' "$upstream_default_branch"
  printf 'Target operation: preflight sync from upstream/main and create or update local codex task branch\n'
  printf 'Remote write: no\n'

  [[ "$repo_name" != "$expected_upstream" ]] || fail "Current GitHub repository is the production repository '$repo_name'. origin must point to a fork."
  [[ "$upstream_repo" == "$expected_upstream" ]] || fail "Upstream repository mismatch. Expected '$expected_upstream', got '$upstream_repo'."
  [[ "$upstream_default_branch" == "main" ]] || fail "Unexpected upstream default branch. Expected 'main', got '$upstream_default_branch'."
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
assert_repository_remotes
assert_clean_worktree

git --version
gh --version
node --version
invoke_github_command "check GitHub CLI authentication" gh auth status
assert_github_repository_identity

initialize_local_workspace
sync_csv_if_needed

invoke_github_command "fetch production upstream main" git fetch upstream main
git switch main
local_main_extra_commits="$(git rev-list --count 'upstream/main..HEAD')"
[[ "$local_main_extra_commits" -eq 0 ]] || fail "Local main has commits that are not in upstream/main. Stop before resetting local main."
git reset --hard upstream/main

branch_name="codex/$(normalize_task_slug "$task_slug")"
if git branch --list "$branch_name" | grep -q .; then
  git switch "$branch_name"
  git rebase upstream/main
else
  git switch -c "$branch_name" upstream/main
fi

printf '\nPreflight complete.\n'
printf 'Task branch: %s\n' "$branch_name"
printf 'Continue with read-only CSV/JSON analysis before any approved JSON edits.\n'
