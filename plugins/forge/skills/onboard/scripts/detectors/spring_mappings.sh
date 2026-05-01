#!/usr/bin/env bash
#
# Detector: spring_mappings
# Counts Spring MVC HTTP mapping annotations under <root>:
#   @GetMapping / @PostMapping / @PutMapping / @DeleteMapping /
#   @PatchMapping / @RequestMapping
#
# Output: JSON with .result = total annotation count.
# Read-only. No eval. Safe against arbitrary ROOT inputs.

set -euo pipefail

ROOT="${1:-src/main/java}"

if [ ! -d "$ROOT" ]; then
  jq -n --arg detector "spring_mappings" \
        --arg root "$ROOT" \
        '{detector: $detector, root: $root, result: 0, error: "root not found"}'
  exit 0
fi

# Direct safe execution. ROOT is passed as -- "$ROOT" so no shell expansion
# of malicious input is possible.
#
# `grep` returns 1 when there are zero matches; combined with set -euo
# pipefail this would abort the script. Wrap with `|| true` so empty
# results are reported as result=0 rather than a silent exit 1.
N=$( { grep -rE '@(Get|Post|Put|Delete|Patch|Request)Mapping' -- "$ROOT" 2>/dev/null || true; } \
    | wc -l \
    | tr -d ' ')

# Evidence cmd is display-only (NEVER re-executed). Quoted ROOT for human reproducibility.
EVIDENCE_CMD="grep -rE '@(Get|Post|Put|Delete|Patch|Request)Mapping' -- '$ROOT' | wc -l"

jq -n --arg detector "spring_mappings" \
      --arg root "$ROOT" \
      --argjson result "$N" \
      --arg cmd "$EVIDENCE_CMD" \
      '{detector: $detector, root: $root, result: $result, evidence_cmd: $cmd}'
