#!/usr/bin/env bash
# Detector: slf4j_classes
# Counts classes annotated with Lombok @Slf4j (proxy for "classes that
# emit logs"). Use as a rough size signal; not authoritative for
# logging coverage.
set -euo pipefail
ROOT="${1:-src/main/java}"

if [ ! -d "$ROOT" ]; then
  jq -n --arg detector "slf4j_classes" --arg root "$ROOT" \
        '{detector: $detector, root: $root, result: 0, error: "root not found"}'
  exit 0
fi

N=$( { grep -rlE '@Slf4j\b' -- "$ROOT" 2>/dev/null || true; } | wc -l | tr -d ' ')
EVIDENCE_CMD="grep -rlE '@Slf4j\b' -- '$ROOT' | wc -l"

jq -n --arg detector "slf4j_classes" --arg root "$ROOT" \
      --argjson result "$N" --arg cmd "$EVIDENCE_CMD" \
      '{detector: $detector, root: $root, result: $result, evidence_cmd: $cmd}'
