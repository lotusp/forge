#!/usr/bin/env bash
#
# Detector: test_files
#
# Locates test files separately for the three common JVM test scopes:
#   - unit         (src/test/...)
#   - integration  (src/integrationTest/ | src/it/ | src/intTest/ |
#                   src/test-integration/ | src/itTest/ | src/integration/)
#   - api          (src/apiTest/ | src/contractTest/)
#
# v0.6 schema: each scope reports its own samples + inferred_size.
# No precise counts at scope or total level.
#
# Files restricted to *.java / *.kt / *.groovy. Build outputs +
# vendored deps pruned via shared exclude list.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/sampling.sh
source "$SCRIPT_DIR/lib/sampling.sh"

ROOT="${1:-.}"

if [ ! -d "$ROOT" ]; then
  jq -n --arg detector "test_files" --arg root "$ROOT" \
        '{detector: $detector, root: $root,
          by_scope: {unit: {samples:[],inferred_size:"none"},
                     integration: {samples:[],inferred_size:"none"},
                     api: {samples:[],inferred_size:"none"}},
          error: "root not found"}'
  exit 0
fi

# Build a single find result; filter by path-substring per scope.
# (find -path with shared excludes is non-trivial; we use the same
#  approach the v0.5.x detector used and filter via grep.)
EXCL=$(detector_find_excludes)
# shellcheck disable=SC2086  # intentional word-splitting on excludes
ALL=$(eval "find \"\$ROOT\" $EXCL -type f \
            \\( -name '*.java' -o -name '*.kt' -o -name '*.groovy' \\) \
            -print" 2>/dev/null || true)

# Per scope: count + 5 samples. samples here are simple {file,line:null,snippet:null}
# entries; we don't read content because test class bodies are large.
scope_block() {
  local path_pattern="$1"
  local hits
  hits=$(printf '%s\n' "$ALL" | grep -E "$path_pattern" 2>/dev/null || true)
  local count=0
  if [ -n "$hits" ]; then
    count=$(printf '%s\n' "$hits" | wc -l | tr -d ' ')
  fi
  local size
  size=$(inferred_size_for_count "$count")
  local samples='[]'
  if [ "$count" -gt 0 ]; then
    samples=$(printf '%s\n' "$hits" | head -5 \
              | jq -nR --arg root "$ROOT" '
                  [ inputs
                    | { file: (. | sub("^\($root)/?"; "")),
                        line: null,
                        snippet: null } ]
                ')
  fi
  jq -n --arg size "$size" --argjson samples "$samples" \
        '{samples: $samples, inferred_size: $size}'
}

UNIT=$(scope_block '/src/test/')
INT=$( scope_block '/src/(integrationTest|intTest|it|test-integration|itTest|integration)/')
API=$( scope_block '/src/(apiTest|contractTest)/')

EVIDENCE_CMD="find '$ROOT' [excl-build] -type f -name '*.java' | grep -E '/src/(test|intTest|integrationTest|it|test-integration|itTest|integration|apiTest|contractTest)/' | head -5"

jq -n \
  --arg detector "test_files" \
  --arg root "$ROOT" \
  --argjson unit "$UNIT" \
  --argjson int "$INT" \
  --argjson api "$API" \
  --arg cmd "$EVIDENCE_CMD" \
  '{detector: $detector, root: $root,
    by_scope: {unit: $unit, integration: $int, api: $api},
    evidence_cmd: $cmd}'
