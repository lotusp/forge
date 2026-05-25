#!/usr/bin/env bash
# Detector: application_listeners
# Locates internal Spring application-event listeners across all three
# tracks:
#   - implements ApplicationListener<T>      (interface-based)
#   - @EventListener                         (method annotation)
#   - @TransactionalEventListener            (transaction-bound variant)
#
# v0.6 schema: samples + inferred_size.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/sampling.sh
source "$SCRIPT_DIR/lib/sampling.sh"

ROOT="${1:-src/main/java}"

if [ ! -d "$ROOT" ]; then
  jq -n --arg detector "application_listeners" --arg root "$ROOT" \
        '{detector: $detector, root: $root,
          samples: [], inferred_size: "none",
          error: "root not found"}'
  exit 0
fi

PATTERN='implements ApplicationListener|@EventListener\b|@TransactionalEventListener\b'
COUNT=$(count_from_grep   "$ROOT" '*.java' "$PATTERN")
SIZE=$(inferred_size_for_count "$COUNT")
SAMPLES=$(samples_from_grep "$ROOT" '*.java' "$PATTERN" 5)

EVIDENCE_CMD="grep -rnE --include='*.java' [excl-build-outputs] '$PATTERN' -- '$ROOT' | head -5"

jq -n --arg detector "application_listeners" --arg root "$ROOT" \
      --arg size "$SIZE" --argjson samples "$SAMPLES" \
      --arg cmd "$EVIDENCE_CMD" \
      '{detector: $detector, root: $root,
        samples: $samples, inferred_size: $size,
        evidence_cmd: $cmd}'
