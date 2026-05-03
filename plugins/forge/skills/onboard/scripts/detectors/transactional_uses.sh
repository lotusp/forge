#!/usr/bin/env bash
# Detector: transactional_uses
# Counts @Transactional occurrences (class-level + method-level).
# Useful as a transaction-boundary scale signal.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/excludes.sh
source "$SCRIPT_DIR/lib/excludes.sh"
ROOT="${1:-src/main/java}"

if [ ! -d "$ROOT" ]; then
  jq -n --arg detector "transactional_uses" --arg root "$ROOT" \
        '{detector: $detector, root: $root, result: 0, error: "root not found"}'
  exit 0
fi

mapfile -t EXCLUDES < <(detector_grep_excludes)

N=$( { grep -rE --include='*.java' "${EXCLUDES[@]}" '@Transactional\b' -- "$ROOT" 2>/dev/null || true; } | wc -l | tr -d ' ')
EVIDENCE_CMD="grep -rE --include='*.java' "${EXCLUDES[@]}" '@Transactional\b' -- '$ROOT' | wc -l"

jq -n --arg detector "transactional_uses" --arg root "$ROOT" \
      --argjson result "$N" --arg cmd "$EVIDENCE_CMD" \
      '{detector: $detector, root: $root, result: $result, evidence_cmd: $cmd}'
