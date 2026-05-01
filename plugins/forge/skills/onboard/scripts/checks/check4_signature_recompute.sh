#!/usr/bin/env bash
#
# check4_signature_recompute.sh — R9 / I-R2b enforcement.
#
# For each section in every .forge/context/*.md:
#   1. Extract the section body via artifact-parser
#   2. Canonicalize via canonicalize.sh (drop preserve blocks, strip ws,
#      collapse blanks)
#   3. Compute SHA-256 first 16 hex via hash.sh
#   4. Compare against the marker's body-signature attribute
#   5. If mismatch (or "(pending)" placeholder) → replace via
#      replace_marker_attr; count as REPAIRED
#
# Run order — this check goes BOTH:
#   - first (resolve "(pending)" + initial signatures), and
#   - last  (refresh signatures after mutating checks change bodies).
#
# Exit code:
#   0  no changes needed
#   1  signatures repaired (warning class)
#   2  unrecoverable (e.g. hash command unavailable)
#
# Each repair is recorded in stats.json:
#   - sig_repairs counter
#   - mutations[] entry with check="check4", before/after sigs

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../lib" && pwd)"
# shellcheck source=../lib/stats.sh
source "$LIB_DIR/stats.sh"
# shellcheck source=../lib/artifact-parser.sh
source "$LIB_DIR/artifact-parser.sh"
# shellcheck source=../lib/canonicalize.sh
source "$LIB_DIR/canonicalize.sh"
# shellcheck source=../lib/hash.sh
source "$LIB_DIR/hash.sh"

CTX="${1:-.forge/context}"
STATS="${2:-$CTX/.validation-stats.json}"

REPAIRED=0
UNRECOVERABLE=0

# Recompute and (if needed) repair the body-signature of one section.
recompute_one() {
  local file="$1" section="$2"

  local declared
  declared=$(get_marker_attr "$file" "$section" body-signature || true)

  local actual
  actual=$(extract_section_body "$file" "$section" \
           | canonicalize_body \
           | sha256_first16) || {
    echo "ERROR: cannot compute signature for $file section=$section" >&2
    UNRECOVERABLE=$((UNRECOVERABLE + 1))
    return 0
  }

  if [ -z "$actual" ]; then
    echo "ERROR: empty signature for $file section=$section" >&2
    UNRECOVERABLE=$((UNRECOVERABLE + 1))
    return 0
  fi

  if [ "$declared" = "$actual" ]; then
    return 0   # already correct, no mutation
  fi

  # Mismatch (or "(pending)" placeholder): repair in place.
  replace_marker_attr "$file" "$section" body-signature "$actual"
  REPAIRED=$((REPAIRED + 1))

  if [ "$declared" = "(pending)" ]; then
    echo "RESOLVED $file [$section]: (pending) -> $actual" >&2
  else
    echo "REPAIRED $file [$section]: $declared -> $actual" >&2
  fi

  if [ -f "$STATS" ]; then
    stats_record_mutation "$STATS" check4 "$file" \
      "body-signature=\"$declared\"" \
      "body-signature=\"$actual\""
  fi
}

main() {
  [ -d "$CTX" ] || { echo "no context dir at $CTX" >&2; return 0; }

  local file section
  for file in "$CTX"/*.md; do
    [ -f "$file" ] || continue
    while IFS= read -r section; do
      [ -z "$section" ] && continue
      recompute_one "$file" "$section"
    done < <(list_sections "$file")
  done

  if [ -f "$STATS" ] && [ "$REPAIRED" -gt 0 ]; then
    stats_increment "$STATS" sig_repairs "$REPAIRED"
  fi

  [ "$UNRECOVERABLE" -gt 0 ] && return 2
  [ "$REPAIRED" -gt 0 ] && return 1
  return 0
}

main "$@"
