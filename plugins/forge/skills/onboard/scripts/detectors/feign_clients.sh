#!/usr/bin/env bash
# Detector: feign_clients
# Counts files declaring @FeignClient (interface declarations for outbound
# service calls).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/excludes.sh
source "$SCRIPT_DIR/lib/excludes.sh"
ROOT="${1:-src/main/java}"

if [ ! -d "$ROOT" ]; then
  jq -n --arg detector "feign_clients" --arg root "$ROOT" \
        '{detector: $detector, root: $root, result: 0, error: "root not found"}'
  exit 0
fi

mapfile -t EXCLUDES < <(detector_grep_excludes)

N=$( { grep -rlE --include='*.java' "${EXCLUDES[@]}" '@FeignClient' -- "$ROOT" 2>/dev/null || true; } | wc -l | tr -d ' ')
EVIDENCE_CMD="grep -rlE --include='*.java' "${EXCLUDES[@]}" '@FeignClient' -- '$ROOT' | wc -l"

jq -n --arg detector "feign_clients" --arg root "$ROOT" \
      --argjson result "$N" --arg cmd "$EVIDENCE_CMD" \
      '{detector: $detector, root: $root, result: $result, evidence_cmd: $cmd}'
