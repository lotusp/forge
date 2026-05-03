#!/usr/bin/env bash
#
# Detector: spring_mappings
# Counts Spring MVC HTTP mapping annotations under <root>:
#   @GetMapping / @PostMapping / @PutMapping / @DeleteMapping /
#   @PatchMapping / @RequestMapping
#
# Output: JSON with .result = total annotation count.
# Read-only. No eval. Safe against arbitrary ROOT inputs.
#
# Build outputs (build/ bin/ target/ .gradle/ etc.) are skipped via
# the shared exclude list in lib/excludes.sh — without this, pointing
# the detector at the project root inflates the count by ~6%
# (compiled-class duplicates).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/excludes.sh
source "$SCRIPT_DIR/lib/excludes.sh"

ROOT="${1:-src/main/java}"

if [ ! -d "$ROOT" ]; then
  jq -n --arg detector "spring_mappings" \
        --arg root "$ROOT" \
        '{detector: $detector, root: $root, result: 0, error: "root not found"}'
  exit 0
fi

mapfile -t EXCLUDES < <(detector_grep_excludes)

N=$( { grep -rE --include='*.java' "${EXCLUDES[@]}" '@(Get|Post|Put|Delete|Patch|Request)Mapping' -- "$ROOT" 2>/dev/null || true; } \
    | wc -l \
    | tr -d ' ')

EVIDENCE_CMD="grep -rE --include='*.java' [excl-build-outputs] '@(Get|Post|Put|Delete|Patch|Request)Mapping' -- '$ROOT' | wc -l"

jq -n --arg detector "spring_mappings" \
      --arg root "$ROOT" \
      --argjson result "$N" \
      --arg cmd "$EVIDENCE_CMD" \
      '{detector: $detector, root: $root, result: $result, evidence_cmd: $cmd}'
