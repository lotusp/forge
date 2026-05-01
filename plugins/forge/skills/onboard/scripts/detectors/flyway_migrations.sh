#!/usr/bin/env bash
# Detector: flyway_migrations
# Counts Flyway migration SQL files. Default ROOT is the project's
# resources directory; the detector also walks down to find a
# `db/migration` subtree if one exists.
set -euo pipefail
ROOT="${1:-src/main/resources}"

if [ ! -d "$ROOT" ]; then
  jq -n --arg detector "flyway_migrations" --arg root "$ROOT" \
        '{detector: $detector, root: $root, result: 0, error: "root not found"}'
  exit 0
fi

# Look for migration files (V*.sql) anywhere under ROOT.
N=$( { find "$ROOT" -type f -name 'V*.sql' 2>/dev/null || true; } | wc -l | tr -d ' ')
EVIDENCE_CMD="find '$ROOT' -type f -name 'V*.sql' | wc -l"

jq -n --arg detector "flyway_migrations" --arg root "$ROOT" \
      --argjson result "$N" --arg cmd "$EVIDENCE_CMD" \
      '{detector: $detector, root: $root, result: $result, evidence_cmd: $cmd}'
