#!/usr/bin/env bash
# Detector: jpa_entities
# Counts files declaring JPA @Entity (line-anchored to avoid false matches
# inside javadoc / strings). Restricted to *.java; build outputs pruned.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/excludes.sh
source "$SCRIPT_DIR/lib/excludes.sh"

ROOT="${1:-src/main/java}"

if [ ! -d "$ROOT" ]; then
  jq -n --arg detector "jpa_entities" --arg root "$ROOT" \
        '{detector: $detector, root: $root, result: 0, error: "root not found"}'
  exit 0
fi

mapfile -t EXCLUDES < <(detector_grep_excludes)

N=$( { grep -rlE --include='*.java' "${EXCLUDES[@]}" '^@Entity[[:space:]]*(\(|$)' -- "$ROOT" 2>/dev/null || true; } | wc -l | tr -d ' ')
EVIDENCE_CMD="grep -rlE --include='*.java' [excl-build-outputs] '^@Entity\s*(\(|$)' -- '$ROOT' | wc -l"

jq -n --arg detector "jpa_entities" --arg root "$ROOT" \
      --argjson result "$N" --arg cmd "$EVIDENCE_CMD" \
      '{detector: $detector, root: $root, result: $result, evidence_cmd: $cmd}'
