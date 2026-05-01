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
  # alpha: registry.json doesn't exist yet; skip without error.
  # beta: real implementation iterates registry entries and verifies each
  # detector script is executable; also lints that every profile-referenced
  # detector ID is registered.
  local registry="$SCRIPT_DIR/detectors/registry.json"
  if [ ! -f "$registry" ]; then
    return 0
  fi

  # Placeholder for beta: extend here when registry.json lands.
  return 0
}

main() {
  check_tools || return 2
  check_detector_registry || return 2
  return 0
}

main "$@"
