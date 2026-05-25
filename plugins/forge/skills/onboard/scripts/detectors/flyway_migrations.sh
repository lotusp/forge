#!/usr/bin/env bash
# Detector: flyway_migrations
# Locates Flyway V*.sql migration files. v0.6 schema.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/sampling.sh
source "$SCRIPT_DIR/lib/sampling.sh"

ROOT="${1:-src/main/resources}"

if [ ! -d "$ROOT" ]; then
  jq -n --arg detector "flyway_migrations" --arg root "$ROOT" \
        '{detector: $detector, root: $root,
          samples: [], inferred_size: "none",
          error: "root not found"}'
  exit 0
fi

NAME_GLOB='V*.sql'
COUNT=$(count_from_find   "$ROOT" "$NAME_GLOB")
SIZE=$(inferred_size_for_count "$COUNT")
SAMPLES=$(samples_from_find "$ROOT" "$NAME_GLOB" 5)

EVIDENCE_CMD="find '$ROOT' [excl-build-outputs] -type f -name '$NAME_GLOB' | head -5"

jq -n --arg detector "flyway_migrations" --arg root "$ROOT" \
      --arg size "$SIZE" --argjson samples "$SAMPLES" \
      --arg cmd "$EVIDENCE_CMD" \
      '{detector: $detector, root: $root,
        samples: $samples, inferred_size: $size,
        evidence_cmd: $cmd}'
