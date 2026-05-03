#!/usr/bin/env bash
#
# Detector: test_files
#
# Counts test files separately for the three common JVM test scopes:
#   - unit         (src/test/...)
#   - integration  (src/integrationTest/... | src/it/... | src/intTest/...)
#   - api          (src/apiTest/... | src/contractTest/...)
#
# Output JSON .result is the GRAND TOTAL (across all scopes); the
# breakdown lives in .by_scope so the LLM can render either number
# accurately.
#
# Why this detector exists: review of v0.5.2 outputs found projects
# claiming "428 test files" when the actual scopes were 231 unit +
# 89 integration + 12 api = 332. The single-number style mis-attributes
# scope and inflates the total. By emitting the breakdown explicitly,
# downstream profiles can phrase claims correctly ("231 unit / 89
# integration test files") instead of guessing.
#
# Files are restricted to *.java / *.kt / *.groovy (test class
# extensions). Build outputs and vendored deps are pruned via the
# shared exclude list.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/excludes.sh
source "$SCRIPT_DIR/lib/excludes.sh"

ROOT="${1:-.}"

if [ ! -d "$ROOT" ]; then
  jq -n --arg detector "test_files" --arg root "$ROOT" \
        '{detector: $detector, root: $root, result: 0, unit: "files",
          error: "root not found"}'
  exit 0
fi

mapfile -t EXCLUDES < <(detector_grep_excludes)

count_in_scope() {
  local pattern="$1"
  # find -path with the shared excludes via grep -v fall-through (find -path
  # doesn't accept --exclude-dir; we filter post hoc).
  EXCL=$(detector_find_excludes)
  local n
  n=$( eval "find \"\$ROOT\" $EXCL -type f \\( -name '*.java' -o -name '*.kt' -o -name '*.groovy' \\) -print" 2>/dev/null \
       | grep -E "$pattern" \
       | wc -l \
       | tr -d ' ' )
  echo "${n:-0}"
}

UNIT=$(count_in_scope '/src/test/')
INT=$(count_in_scope  '/src/(integrationTest|intTest|it)/')
API=$(count_in_scope  '/src/(apiTest|contractTest)/')
TOTAL=$(( UNIT + INT + API ))

EVIDENCE_CMD="find '$ROOT' [excl-build] -type f -name '*.java' | grep -E '/src/(test|intTest|integrationTest|it|apiTest|contractTest)/' | wc -l"

jq -n \
  --arg detector "test_files" \
  --arg root "$ROOT" \
  --argjson result "$TOTAL" \
  --argjson unit_count "$UNIT" \
  --argjson int_count "$INT" \
  --argjson api_count "$API" \
  --arg cmd "$EVIDENCE_CMD" \
  '{detector: $detector, root: $root, result: $result, unit: "files",
    by_scope: {unit: $unit_count, integration: $int_count, api: $api_count},
    evidence_cmd: $cmd}'
