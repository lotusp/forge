#!/usr/bin/env bash
# Detector: feign_clients
# Locates @FeignClient interface declarations (outbound service calls).
# v0.6 schema.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/sampling.sh
source "$SCRIPT_DIR/lib/sampling.sh"

ROOT="${1:-src/main/java}"

if [ ! -d "$ROOT" ]; then
  jq -n --arg detector "feign_clients" --arg root "$ROOT" \
        '{detector: $detector, root: $root,
          samples: [], inferred_size: "none",
          error: "root not found"}'
  exit 0
fi

PATTERN='@FeignClient'
COUNT=$(count_from_grep   "$ROOT" '*.java' "$PATTERN")
SIZE=$(inferred_size_for_count "$COUNT")
SAMPLES=$(samples_from_grep "$ROOT" '*.java' "$PATTERN" 5)

EVIDENCE_CMD="grep -rlE --include='*.java' [excl-build-outputs] '$PATTERN' -- '$ROOT' | head -5"

jq -n --arg detector "feign_clients" --arg root "$ROOT" \
      --arg size "$SIZE" --argjson samples "$SAMPLES" \
      --arg cmd "$EVIDENCE_CMD" \
      '{detector: $detector, root: $root,
        samples: $samples, inferred_size: $size,
        evidence_cmd: $cmd}'
