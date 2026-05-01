#!/usr/bin/env bash
#
# preflight.sh — runs before validate-onboard-artifacts.sh
#
# Verifies that all tools required by Step 6.5 checks are available on
# this machine. Hard-fails (exit 2) with explicit install hints when a
# tool is missing.
#
# alpha scope: tool dependency check only.
# beta will append `check_detector_registry` (gated by registry.json
# existence — see scripts/detectors/registry.json).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

check_tools() {
  local missing=()

  command -v jq   >/dev/null 2>&1 || missing+=("jq")
  command -v perl >/dev/null 2>&1 || missing+=("perl")
  # git CLI is required (used by check6c — final phase).
  # Note: this is independent of the (no-commit) sentinel, which only
  # describes a workspace that is not a git repository.
  command -v git  >/dev/null 2>&1 || missing+=("git")

  if ! command -v sha256sum >/dev/null 2>&1 \
     && ! command -v shasum >/dev/null 2>&1; then
    missing+=("sha256sum or shasum")
  fi

  if [ ${#missing[@]} -gt 0 ]; then
    cat >&2 <<EOF
ERROR: forge:onboard validator preflight failed.
Missing required tools: ${missing[*]}

Install hints:
  macOS:    brew install jq
  Debian:   apt install jq
  RHEL:     yum install jq
  perl is preinstalled on most systems.
  sha256sum (Linux) / shasum (macOS) ditto.
  git CLI is needed for commit-aware checks.
EOF
    return 2
  fi

  return 0
}

check_detector_registry() {
  local registry="$SCRIPT_DIR/detectors/registry.json"
  if [ ! -f "$registry" ]; then
    # No registry file means alpha-style install (detectors not yet
    # introduced); skip without error.
    return 0
  fi

  local fail=0

  # 1. Every registered detector must have an executable script.
  local missing_scripts=()
  while read -r script; do
    local path="$SCRIPT_DIR/detectors/$script"
    if [ ! -x "$path" ]; then
      missing_scripts+=("$script")
    fi
  done < <(jq -r '.detectors[]."detector-script"' "$registry")

  if [ ${#missing_scripts[@]} -gt 0 ]; then
    echo "ERROR: registered detectors missing or non-executable:" >&2
    printf "  - %s\n" "${missing_scripts[@]}" >&2
    fail=1
  fi

  # 2. Every detector-id referenced by a profile must be registered.
  # Profiles use `detector-id: <id>` lines; we lint that the id exists
  # in the registry.
  local profile_dir="$SCRIPT_DIR/../profiles"
  if [ -d "$profile_dir" ]; then
    local registered_ids
    registered_ids=$(jq -r '.detectors[]."detector-id"' "$registry" | sort -u)

    local unregistered=()
    while IFS= read -r ref_id; do
      [ -z "$ref_id" ] && continue
      if ! echo "$registered_ids" | grep -qx "$ref_id"; then
        unregistered+=("$ref_id")
      fi
    done < <(
      find "$profile_dir" -type f -name '*.md' -print0 \
        | xargs -0 grep -hE '^[[:space:]]*-?[[:space:]]*detector-id:' 2>/dev/null \
        | sed -E 's/.*detector-id:[[:space:]]*([a-z0-9_-]+).*/\1/' \
        | sort -u
    )

    if [ ${#unregistered[@]} -gt 0 ]; then
      echo "ERROR: profiles reference unregistered detectors:" >&2
      printf "  - %s\n" "${unregistered[@]}" >&2
      fail=1
    fi
  fi

  [ "$fail" -eq 1 ] && return 2
  return 0
}

main() {
  check_tools || return 2
  check_detector_registry || return 2
  return 0
}

main "$@"
