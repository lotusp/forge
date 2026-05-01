#!/usr/bin/env bash
# Detector: exception_classes
# Counts files matching `*Exception.java` — proxy for exception
# hierarchy size. Useful for flagging exception-class explosion.
set -euo pipefail
ROOT="${1:-src/main/java}"

if [ ! -d "$ROOT" ]; then
  jq -n --arg detector "exception_classes" --arg root "$ROOT" \
        '{detector: $detector, root: $root, result: 0, error: "root not found"}'
  exit 0
fi

N=$( { find "$ROOT" -type f -name '*Exception.java' 2>/dev/null || true; } | wc -l | tr -d ' ')
EVIDENCE_CMD="find '$ROOT' -type f -name '*Exception.java' | wc -l"

jq -n --arg detector "exception_classes" --arg root "$ROOT" \
      --argjson result "$N" --arg cmd "$EVIDENCE_CMD" \
      '{detector: $detector, root: $root, result: $result, evidence_cmd: $cmd}'
