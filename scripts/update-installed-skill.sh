#!/usr/bin/env bash
set -euo pipefail

skill_name="qingshan-medical-map-data-update-skill"
installed_skill_root="${CODEX_SKILL_ROOT:-$HOME/.codex/skills/$skill_name}"
repo_url="https://github.com/RaspberryCoke/qingshan-medical-map-data-update-skill.git"
branch="main"
force=0
version_file=".codex-skill-version.json"
proxy_vars=(HTTP_PROXY HTTPS_PROXY ALL_PROXY http_proxy https_proxy all_proxy)

while [[ $# -gt 0 ]]; do
  case "$1" in
    --installed-skill-root)
      installed_skill_root="${2:?Missing value for --installed-skill-root}"
      shift 2
      ;;
    --repo-url)
      repo_url="${2:?Missing value for --repo-url}"
      shift 2
      ;;
    --branch)
      branch="${2:?Missing value for --branch}"
      shift 2
      ;;
    --force)
      force=1
      shift
      ;;
    *)
      printf 'Error: unknown argument: %s\n' "$1" >&2
      exit 1
      ;;
  esac
done

fail() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "Required command not found: $1"
}

save_proxy_env() {
  local name
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

read_skill_version() {
  local root="$1"
  local path="$root/$version_file"
  [[ -f "$path" ]] || {
    printf '\n'
    return
  }
  sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$path" | head -n 1
}

assert_install_destination() {
  local expected_parent="$HOME/.codex/skills"
  local expected_path="$expected_parent/$skill_name"
  local full_path
  full_path="$(cd "$(dirname "$installed_skill_root")" 2>/dev/null && pwd)/$(basename "$installed_skill_root")"
  [[ "$full_path" == "$expected_path" ]] || fail "Refusing to reinstall unexpected skill path: $full_path"
  case "$full_path" in
    "$expected_parent"/*) ;;
    *) fail "Refusing to reinstall path outside Codex skills directory: $full_path" ;;
  esac
  printf '%s\n' "$full_path"
}

install_tracked_files() {
  local source_root="$1"
  local destination_root="$2"
  local count=0

  rm -rf "$destination_root"
  mkdir -p "$destination_root"

  while IFS= read -r relative; do
    [[ -n "$relative" ]] || continue
    mkdir -p "$destination_root/$(dirname "$relative")"
    cp "$source_root/$relative" "$destination_root/$relative"
    count=$((count + 1))
  done < <(git -C "$source_root" ls-files)

  printf '%s\n' "$count"
}

require_command git

mkdir -p "$HOME/.codex/skills"
installed_root="$(assert_install_destination)"
current_version="$(read_skill_version "$installed_root")"
temporary_root="$(mktemp -d "${TMPDIR:-/tmp}/$skill_name-update.XXXXXX")"

cleanup() {
  rm -rf "$temporary_root"
}
trap cleanup EXIT

invoke_github_command "clone latest skill repository" git clone --depth 1 --branch "$branch" "$repo_url" "$temporary_root"
latest_version="$(read_skill_version "$temporary_root")"
if [[ -z "$latest_version" ]]; then
  printf 'Warning: remote skill repository is missing %s. Skipping installed skill version enforcement until metadata is available on %s.\n' "$version_file" "$branch" >&2
  exit 0
fi

if [[ "$force" -eq 0 && "$current_version" == "$latest_version" ]]; then
  printf 'Installed skill is current: %s\n' "$latest_version"
  exit 0
fi

installed_count="$(install_tracked_files "$temporary_root" "$installed_root")"
printf "Installed skill updated from '%s' to '%s'.\n" "$current_version" "$latest_version"
printf 'Files installed: %s\n' "$installed_count"
fail "Installed skill was updated. Restart Codex or start a new run so the updated skill instructions are loaded."
