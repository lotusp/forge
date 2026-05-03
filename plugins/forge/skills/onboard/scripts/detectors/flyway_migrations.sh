#!/usr/bin/env bash
# Detector: flyway_migrations
# Counts Flyway migration SQL files. Default ROOT is the project's
# resources directory; the detector walks down to find a `db/migration`
# subtree if one exists.
#
# Build outputs are pruned via the shared exclude list so the count is
# stable whether ROOT is the project root or src/main/resources. A prior
# real-world review counted 750 *.sql files when only 251 exist in
# source — the rest were duplicates copied into build/ and bin/ during
# Gradle compilation.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/excludes.sh
source "$SCRIPT_DIR/lib/excludes.sh"

ROOT="${1:-src/main/resources}"

if [ ! -d "$ROOT" ]; then
  jq -n --arg detector "flyway_migrations" --arg root "$ROOT" \
        '{detector: $detector, root: $root, result: 0, error: "root not found"}'
  exit 0
fi

# shellcheck disable=SC2086  # intentional word-splitting on excludes
EXCL=$(detector_find_excludes)
N=$( { eval "find \"\$ROOT\" $EXCL -type f -name 'V*.sql' -print" 2>/dev/null || true; } | wc -l | tr -d ' ')
EVIDENCE_CMD="find '$ROOT' [excl-build-outputs] -type f -name 'V*.sql' | wc -l"

jq -n --arg detector "flyway_migrations" --arg root "$ROOT" \
      --argjson result "$N" --arg cmd "$EVIDENCE_CMD" \
      '{detector: $detector, root: $root, result: $result, evidence_cmd: $cmd}'
