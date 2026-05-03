#!/usr/bin/env bash
# Detector: rest_controllers
# Counts files containing @RestController.
#
# Restricted to *.java; build outputs (build/ bin/ target/ ...)
# are pruned via the shared exclude list. This makes the count
# stable whether ROOT is the project root or src/main/java.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/excludes.sh
source "$SCRIPT_DIR/lib/excludes.sh"

ROOT="${1:-src/main/java}"

if [ ! -d "$ROOT" ]; then
  jq -n --arg detector "rest_controllers" --arg root "$ROOT" \
        '{detector: $detector, root: $root, result: 0, error: "root not found"}'
  exit 0
fi

mapfile -t EXCLUDES < <(detector_grep_excludes)

N=$( { grep -rlE --include='*.java' "${EXCLUDES[@]}" '@RestController' -- "$ROOT" 2>/dev/null || true; } | wc -l | tr -d ' ')
EVIDENCE_CMD="grep -rlE --include='*.java' [excl-build-outputs] '@RestController' -- '$ROOT' | wc -l"

jq -n --arg detector "rest_controllers" --arg root "$ROOT" \
      --argjson result "$N" --arg cmd "$EVIDENCE_CMD" --arg unit "files" \
      '{detector: $detector, root: $root, result: $result, unit: $unit, evidence_cmd: $cmd}'
