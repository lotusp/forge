#!/usr/bin/env bash
# Detector: exception_classes
# Counts files matching `*Exception.java` — proxy for exception
# hierarchy size. Useful for flagging exception-class explosion.
# Build outputs are pruned via the shared exclude list so the count is
# stable whether ROOT is the project root or src/main/java.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/excludes.sh
source "$SCRIPT_DIR/lib/excludes.sh"

ROOT="${1:-src/main/java}"

if [ ! -d "$ROOT" ]; then
  jq -n --arg detector "exception_classes" --arg root "$ROOT" \
        '{detector: $detector, root: $root, result: 0, error: "root not found"}'
  exit 0
fi

# find with prune predicate (skip build/ bin/ target/ ...).
# shellcheck disable=SC2086  # intentional word-splitting on excludes
EXCL=$(detector_find_excludes)
N=$( { eval "find \"\$ROOT\" $EXCL -type f -name '*Exception.java' -print" 2>/dev/null || true; } | wc -l | tr -d ' ')
EVIDENCE_CMD="find '$ROOT' [excl-build-outputs] -type f -name '*Exception.java' | wc -l"

jq -n --arg detector "exception_classes" --arg root "$ROOT" \
      --argjson result "$N" --arg cmd "$EVIDENCE_CMD" \
      '{detector: $detector, root: $root, result: $result, evidence_cmd: $cmd}'
