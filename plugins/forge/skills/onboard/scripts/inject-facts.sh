#!/usr/bin/env bash
#
# inject-facts.sh — run every applicable detector against the target
# project and write a single fact registry to
# `.forge/_session/facts.json`.
#
# This is the v0.5.4 deterministic fact pipeline. Field testing of
# v0.5.3 showed that profile-level "MUST invoke <detector>" rules
# were honoured by the LLM only intermittently (1-2/4 projects per
# rule). Rather than add more prose, the validator now collects the
# truth itself and check7 enforces consistency at write time.
#
# Output schema (.forge/_session/facts.json):
#   {
#     "generated_at": "2026-05-03T...Z",
#     "target_root": "<absolute path>",
#     "source_root": "<src/main/java or equivalent>",
#     "resources_root": "<src/main/resources or equivalent>",
#     "facts": {
#       "rest_controllers":   { "value": 25,  "unit": "files",       "detector": "rest_controllers"   },
#       "spring_mappings":    { "value": 330, "unit": "occurrences", "detector": "spring_mappings"    },
#       "jpa_entities":       { "value": 80,  "unit": "files",       "detector": "jpa_entities"       },
#       "feign_clients":      { "value": 15,  "unit": "files",       "detector": "feign_clients"      },
#       "ms_listeners":       { "value": 2,   "unit": "occurrences", "detector": "ms_listeners"       },
#       "application_listeners": { "value": 29, "unit": "occurrences", "detector": "application_listeners" },
#       "flyway_migrations":  { "value": 251, "unit": "files",       "detector": "flyway_migrations"  },
#       "slf4j_classes":      { "value": 150, "unit": "files",       "detector": "slf4j_classes"      },
#       "transactional_uses": { "value": 112, "unit": "occurrences", "detector": "transactional_uses" },
#       "role_constants":     { "value": 181, "unit": "occurrences", "detector": "role_constants"     },
#       "exception_classes":  { "value": 101, "unit": "files",       "detector": "exception_classes"  },
#       "test_unit":          { "value": 413, "unit": "files",       "detector": "test_files",      "via": ".by_scope.unit" },
#       "test_integration":   { "value":   0, "unit": "files",       "detector": "test_files",      "via": ".by_scope.integration" },
#       "test_api":           { "value":   0, "unit": "files",       "detector": "test_files",      "via": ".by_scope.api" }
#     },
#     "sonar": { ... full sonar_field_pair output ... }
#   }
#
# Usage:
#   inject-facts.sh <target-root>
#       <target-root> — defaults to the current working directory
#
# Exit code:
#   0  — facts written
#   2  — target not a directory or no roots discoverable

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DETECTORS_DIR="$SCRIPT_DIR/detectors"

TARGET="${1:-.}"
if [ ! -d "$TARGET" ]; then
  echo "ERROR: target not a directory: $TARGET" >&2
  exit 2
fi
TARGET="$(cd "$TARGET" && pwd)"

# Discover language-specific roots. We do shallow find first (depth 4)
# to handle multi-module projects without descending into build outputs.
SOURCE_ROOT=""
RESOURCES_ROOT=""

# Java/Kotlin/Scala main source.
SOURCE_ROOT=$(find "$TARGET" -maxdepth 5 -type d -path '*/src/main/java' \
  -not -path '*/build/*' -not -path '*/.gradle*' \
  -print 2>/dev/null | head -1 || true)
[ -z "$SOURCE_ROOT" ] && SOURCE_ROOT=$(find "$TARGET" -maxdepth 5 -type d -path '*/src/main/kotlin' \
  -not -path '*/build/*' -not -path '*/.gradle*' \
  -print 2>/dev/null | head -1 || true)

# Resources directory — for Flyway migrations etc.
RESOURCES_ROOT=$(find "$TARGET" -maxdepth 5 -type d -path '*/src/main/resources' \
  -not -path '*/build/*' -not -path '*/.gradle*' \
  -print 2>/dev/null | head -1 || true)

# Output path. The session dir is created on demand.
SESSION_DIR="$TARGET/.forge/_session"
mkdir -p "$SESSION_DIR"
OUT="$SESSION_DIR/facts.json"

# ─── Run each detector and collect into a working JSON ─────────────
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Helper: run a detector against a root; emit a fact entry (or "absent"
# if the root doesn't exist). $1 = fact_id, $2 = detector_id, $3 = root.
fact_from_count() {
  local fact_id="$1" detector="$2" root="$3"
  if [ -z "$root" ] || [ ! -d "$root" ]; then
    jq -n --arg id "$fact_id" --arg det "$detector" \
          '{($id): {value: null, unit: null, detector: $det, error: "root not found"}}'
    return
  fi
  local out
  out=$("$DETECTORS_DIR/$detector.sh" "$root" 2>/dev/null || echo '{}')
  local val unit
  val=$(echo "$out" | jq -r '.result // 0')
  unit=$(echo "$out" | jq -r '.unit // "unknown"')
  jq -n --arg id "$fact_id" --arg det "$detector" \
        --argjson val "${val:-0}" --arg unit "$unit" \
        '{($id): {value: $val, unit: $unit, detector: $det}}'
}

# Helper: pull a sub-key out of a structured detector (test_files).
fact_from_path() {
  local fact_id="$1" detector="$2" root="$3" path="$4"
  if [ -z "$root" ] || [ ! -d "$root" ]; then
    jq -n --arg id "$fact_id" --arg det "$detector" --arg p "$path" \
          '{($id): {value: null, unit: null, detector: $det, via: $p, error: "root not found"}}'
    return
  fi
  local out val
  out=$("$DETECTORS_DIR/$detector.sh" "$root" 2>/dev/null || echo '{}')
  val=$(echo "$out" | jq -r "$path // 0")
  jq -n --arg id "$fact_id" --arg det "$detector" --arg p "$path" \
        --argjson val "${val:-0}" \
        '{($id): {value: $val, unit: "files", detector: $det, via: $p}}'
}

# Collect all facts (one JSON object per call, then merged at the end).
{
  fact_from_count rest_controllers      rest_controllers      "$SOURCE_ROOT"
  fact_from_count spring_mappings       spring_mappings       "$SOURCE_ROOT"
  fact_from_count jpa_entities          jpa_entities          "$SOURCE_ROOT"
  fact_from_count feign_clients         feign_clients         "$SOURCE_ROOT"
  fact_from_count ms_listeners          ms_listeners          "$SOURCE_ROOT"
  fact_from_count application_listeners application_listeners "$SOURCE_ROOT"
  fact_from_count slf4j_classes         slf4j_classes         "$SOURCE_ROOT"
  fact_from_count transactional_uses    transactional_uses    "$SOURCE_ROOT"
  fact_from_count role_constants        role_constants        "$SOURCE_ROOT"
  fact_from_count exception_classes     exception_classes     "$SOURCE_ROOT"
  fact_from_count flyway_migrations     flyway_migrations     "$RESOURCES_ROOT"
  fact_from_path  test_unit             test_files            "$TARGET" '.by_scope.unit'
  fact_from_path  test_integration      test_files            "$TARGET" '.by_scope.integration'
  fact_from_path  test_api              test_files            "$TARGET" '.by_scope.api'
} | jq -s 'add' > "$SESSION_DIR/.facts-only.tmp"

# sonar_field_pair has a richer object output; keep the whole thing
# under a separate "sonar" key.
"$DETECTORS_DIR/sonar_field_pair.sh" "$TARGET" 2>/dev/null > "$SESSION_DIR/.sonar.tmp" || echo '{}' > "$SESSION_DIR/.sonar.tmp"

# Compose the final document.
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
