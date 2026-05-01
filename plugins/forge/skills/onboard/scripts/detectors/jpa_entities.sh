#!/usr/bin/env bash
# Detector: jpa_entities
# Counts files declaring JPA @Entity (line-anchored to avoid false matches
# inside javadoc / strings).
set -euo pipefail
ROOT="${1:-src/main/java}"

if [ ! -d "$ROOT" ]; then
  jq -n --arg detector "jpa_entities" --arg root "$ROOT" \
        '{detector: $detector, root: $root, result: 0, error: "root not found"}'
  exit 0
fi

N=$( { grep -rlE '^@Entity[[:space:]]*(\(|$)' -- "$ROOT" 2>/dev/null || true; } | wc -l | tr -d ' ')
EVIDENCE_CMD="grep -rlE '^@Entity\s*(\(|$)' -- '$ROOT' | wc -l"

jq -n --arg detector "jpa_entities" --arg root "$ROOT" \
      --argjson result "$N" --arg cmd "$EVIDENCE_CMD" \
      '{detector: $detector, root: $root, result: $result, evidence_cmd: $cmd}'
