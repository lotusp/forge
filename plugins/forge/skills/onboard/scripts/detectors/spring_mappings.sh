#!/usr/bin/env bash
# Detector: spring_mappings
# Locates Spring MVC HTTP mapping annotations:
#   @GetMapping / @PostMapping / @PutMapping / @DeleteMapping /
#   @PatchMapping / @RequestMapping
# v0.6 schema: samples + inferred_size; no precise count.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/sampling.sh
source "$SCRIPT_DIR/lib/sampling.sh"

ROOT="${1:-src/main/java}"

if [ ! -d "$ROOT" ]; then
  jq -n --arg detector "spring_mappings" --arg root "$ROOT" \
        '{detector: $detector, root: $root,
          samples: [], inferred_size: "none",
          error: "root not found"}'
  exit 0
fi

PATTERN='@(Get|Post|Put|Delete|Patch|Request)Mapping'
COUNT=$(count_from_grep   "$ROOT" '*.java' "$PATTERN")
SIZE=$(inferred_size_for_count "$COUNT")
SAMPLES=$(samples_from_grep "$ROOT" '*.java' "$PATTERN" 5)

EVIDENCE_CMD="grep -rnE --include='*.java' [excl-build-outputs] '$PATTERN' -- '$ROOT' | head -5"

jq -n --arg detector "spring_mappings" --arg root "$ROOT" \
      --arg size "$SIZE" --argjson samples "$SAMPLES" \
      --arg cmd "$EVIDENCE_CMD" \
      '{detector: $detector, root: $root,
        samples: $samples, inferred_size: $size,
        evidence_cmd: $cmd}'
