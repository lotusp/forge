#!/usr/bin/env bash
# Detector: transactional_uses
# Counts @Transactional occurrences (class-level + method-level).
# Useful as a transaction-boundary scale signal.
set -euo pipefail
ROOT="${1:-src/main/java}"

if [ ! -d "$ROOT" ]; then
  jq -n --arg detector "transactional_uses" --arg root "$ROOT" \
        '{detector: $detector, root: $root, result: 0, error: "root not found"}'
  exit 0
fi

N=$( { grep -rE '@Transactional\b' -- "$ROOT" 2>/dev/null || true; } | wc -l | tr -d ' ')
EVIDENCE_CMD="grep -rE '@Transactional\b' -- '$ROOT' | wc -l"

jq -n --arg detector "transactional_uses" --arg root "$ROOT" \
      --argjson result "$N" --arg cmd "$EVIDENCE_CMD" \
      '{detector: $detector, root: $root, result: $result, evidence_cmd: $cmd}'
