#!/usr/bin/env bash
#
# inject-facts.sh — run every applicable detector against the target
# project and write a single fact registry to
# `.forge/_session/facts.json`.
#
# v0.6 schema (samples + inferred_size). v0.5.x kept precise counts;
# field testing showed counts can't be reliably produced by the LLM
# + script combo, and wrong counts are worse than no counts. The new
# schema gives the LLM 3-5 file:line citations per fact (concrete
# evidence) and a coarse size bucket (tiny / small / medium / large /
# very-large). Profiles consume samples directly and qualitative size
# words instead of numeric claims.
#
# Output schema (.forge/_session/facts.json):
#   {
#     "generated_at": "2026-05-25T...Z",
#     "target_root":   "<absolute path>",
#     "source_root":   "<src/main/java or equivalent>",
#     "resources_root":"<src/main/resources or equivalent>",
#     "facts": {
#       "rest_controllers": {
#         "samples": [{file, line, snippet}, ...],
#         "inferred_size": "medium",
#         "detector": "rest_controllers"
#       },
#       "spring_mappings": { ... },
#       ...
#       "test_unit":        { samples + inferred_size from .by_scope.unit },
#       "test_integration": { samples + inferred_size from .by_scope.integration },
#       "test_api":         { samples + inferred_size from .by_scope.api }
#     },
#     "sonar": { ... full sonar_field_pair output (literal facts kept as-is) ... }
#   }
#
# Usage:
#   inject-facts.sh <target-root>
#       <target-root> — defaults to cwd
#
# Exit code:
#   0  — facts written
#   2  — target not a directory

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DETECTORS_DIR="$SCRIPT_DIR/detectors"

TARGET="${1:-.}"
if [ ! -d "$TARGET" ]; then
  echo "ERROR: target not a directory: $TARGET" >&2
  exit 2
fi
TARGET="$(cd "$TARGET" && pwd)"

# Discover language-specific roots. Shallow find (depth 5) to handle
# multi-module projects without descending into build outputs.
SOURCE_ROOT=$(find "$TARGET" -maxdepth 5 -type d -path '*/src/main/java' \
  -not -path '*/build/*' -not -path '*/.gradle*' \
  -print 2>/dev/null | head -1 || true)
[ -z "$SOURCE_ROOT" ] && SOURCE_ROOT=$(find "$TARGET" -maxdepth 5 -type d -path '*/src/main/kotlin' \
  -not -path '*/build/*' -not -path '*/.gradle*' \
  -print 2>/dev/null | head -1 || true)

RESOURCES_ROOT=$(find "$TARGET" -maxdepth 5 -type d -path '*/src/main/resources' \
  -not -path '*/build/*' -not -path '*/.gradle*' \
  -print 2>/dev/null | head -1 || true)

SESSION_DIR="$TARGET/.forge/_session"
mkdir -p "$SESSION_DIR"
OUT="$SESSION_DIR/facts.json"
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# ─── Helpers ────────────────────────────────────────────────────────

# Run detector with new v0.6 schema; emit a fact entry under $fact_id.
# Uses temp files (not echo) to preserve backslash-bearing JSON
# strings — macOS bash strips \ from `echo`-piped output.
fact_v6() {
  local fact_id="$1" detector="$2" root="$3"
  if [ -z "$root" ] || [ ! -d "$root" ]; then
    jq -n --arg id "$fact_id" --arg det "$detector" \
          '{($id): {samples: [], inferred_size: "none", detector: $det,
                    error: "root not found"}}'
    return
  fi
  local tmp
  tmp=$(mktemp)
  if "$DETECTORS_DIR/$detector.sh" "$root" >"$tmp" 2>/dev/null; then
    jq --arg id "$fact_id" --arg det "$detector" \
       '{($id): {samples: .samples, inferred_size: .inferred_size, detector: $det}}' \
       "$tmp"
  else
    jq -n --arg id "$fact_id" --arg det "$detector" \
          '{($id): {samples: [], inferred_size: "none", detector: $det,
                    error: "detector failed"}}'
  fi
  rm -f "$tmp"
}

# Pull a sub-scope out of test_files structured output ($path = a
# top-level by_scope key like "unit" / "integration" / "api").
fact_test_scope() {
  local fact_id="$1" root="$2" scope="$3"
  if [ -z "$root" ] || [ ! -d "$root" ]; then
    jq -n --arg id "$fact_id" --arg scope "$scope" \
          '{($id): {samples: [], inferred_size: "none",
                    detector: "test_files", via: ("by_scope." + $scope),
                    error: "root not found"}}'
    return
  fi
  local tmp
  tmp=$(mktemp)
  if "$DETECTORS_DIR/test_files.sh" "$root" >"$tmp" 2>/dev/null; then
    jq --arg id "$fact_id" --arg scope "$scope" \
       '{($id): {samples: .by_scope[$scope].samples,
                 inferred_size: .by_scope[$scope].inferred_size,
                 detector: "test_files",
                 via: ("by_scope." + $scope)}}' \
       "$tmp"
  else
    jq -n --arg id "$fact_id" --arg scope "$scope" \
          '{($id): {samples: [], inferred_size: "none",
                    detector: "test_files", via: ("by_scope." + $scope),
                    error: "detector failed"}}'
  fi
  rm -f "$tmp"
}

# ─── Collect all facts ──────────────────────────────────────────────
{
  fact_v6 rest_controllers      rest_controllers      "$SOURCE_ROOT"
  fact_v6 spring_mappings       spring_mappings       "$SOURCE_ROOT"
  fact_v6 jpa_entities          jpa_entities          "$SOURCE_ROOT"
  fact_v6 feign_clients         feign_clients         "$SOURCE_ROOT"
  fact_v6 ms_listeners          ms_listeners          "$SOURCE_ROOT"
  fact_v6 application_listeners application_listeners "$SOURCE_ROOT"
  fact_v6 slf4j_classes         slf4j_classes         "$SOURCE_ROOT"
  fact_v6 transactional_uses    transactional_uses    "$SOURCE_ROOT"
  fact_v6 role_constants        role_constants        "$SOURCE_ROOT"
  fact_v6 exception_classes     exception_classes     "$SOURCE_ROOT"
  fact_v6 flyway_migrations     flyway_migrations     "$RESOURCES_ROOT"
  fact_test_scope test_unit        "$TARGET" unit
  fact_test_scope test_integration "$TARGET" integration
  fact_test_scope test_api         "$TARGET" api
} | jq -s 'add' > "$SESSION_DIR/.facts-only.tmp"

# sonar_field_pair: object-shape facts (project name/key, match flag,
# duplicate flag). Keep the whole thing verbatim — these are literal
# fact values, not counts.
"$DETECTORS_DIR/sonar_field_pair.sh" "$TARGET" 2>/dev/null \
  > "$SESSION_DIR/.sonar.tmp" \
  || echo '{}' > "$SESSION_DIR/.sonar.tmp"

# Compose final document.
jq -n \
  --arg ts "$TS" \
  --arg target "$TARGET" \
  --arg src "${SOURCE_ROOT:-}" \
  --arg res "${RESOURCES_ROOT:-}" \
  --slurpfile facts "$SESSION_DIR/.facts-only.tmp" \
  --slurpfile sonar "$SESSION_DIR/.sonar.tmp" \
  '{
     generated_at: $ts,
     target_root: $target,
     source_root: $src,
     resources_root: $res,
     facts: $facts[0],
     sonar: $sonar[0]
   }' > "$OUT"

rm -f "$SESSION_DIR/.facts-only.tmp" "$SESSION_DIR/.sonar.tmp"

echo "inject-facts: wrote $OUT" >&2
exit 0
