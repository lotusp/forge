#!/usr/bin/env bash
# Detector: application_listeners
# Counts internal Spring application-event listeners across all three
# tracks:
#   - implements ApplicationListener<T>      (interface-based)
#   - @EventListener                         (method annotation)
#   - @TransactionalEventListener            (transaction-bound variant)
#
# Why three tracks: a prior real-world review found 0 ApplicationListener
# implementations but 7 @EventListener methods; the old profile assumed
# only the interface form existed and missed the entire family.
set -euo pipefail
ROOT="${1:-src/main/java}"

if [ ! -d "$ROOT" ]; then
  jq -n --arg detector "application_listeners" --arg root "$ROOT" \
        '{detector: $detector, root: $root, result: 0, error: "root not found"}'
  exit 0
fi

PATTERN='implements ApplicationListener|@EventListener\b|@TransactionalEventListener\b'
N=$( { grep -rE "$PATTERN" -- "$ROOT" 2>/dev/null || true; } | wc -l | tr -d ' ')
EVIDENCE_CMD="grep -rE '$PATTERN' -- '$ROOT' | wc -l"

jq -n --arg detector "application_listeners" --arg root "$ROOT" \
      --argjson result "$N" --arg cmd "$EVIDENCE_CMD" \
      '{detector: $detector, root: $root, result: $result, evidence_cmd: $cmd}'
