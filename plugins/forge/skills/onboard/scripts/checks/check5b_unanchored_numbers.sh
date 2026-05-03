#!/usr/bin/env bash
#
# check5b_unanchored_numbers.sh — heuristic detector for inventory-style
# numbers that lack an `<!-- ev:id=... -->` evidence anchor.
#
# Two enforcement modes:
#   - Inside the `what-this-is` section: precise inventory numbers are
#     FORBIDDEN. The narrative section is exempt from R10 tag rules
#     (per Step 3.2), but allowing precise numbers there would let
#     authors bypass the entire evidence pipeline. Hits trigger
#     exit 2 (hard halt).
#   - Anywhere else: an unanchored inventory number is a warning
#     (exit 1). False positives are expected — this is a heuristic, not
#     authoritative. The detector sidecar pipeline is what really keeps
#     numbers honest.
#
# Heuristic for "inventory-style number":
#   - >= 10 (single-digit numbers are usually status codes / version parts)
#   - followed within ~5 words by an inventory keyword
#     (controllers / files / classes / entities / migrations / listeners /
#      routes / endpoints / handlers / tables / annotations / repositories /
#      mappings / consumers / producers)
#
# Exclusion patterns (these numbers are NOT inventory):
#   - semver (1.2.3 / 2.5.12)
#   - HTTP status (HTTP 200, code 404)
#   - language version (Java 11 / Spring Boot 3.2)
#   - percent (60% / 85.5%)
#   - hex (0x1234)
#   - migration version dates (V2026_04_30)
#   - port numbers (port 3000)
#
# Exit code:
#   0  no flagged inventory numbers without an anchor
#   1  warning(s) outside what-this-is
#   2  precise inventory number found inside what-this-is (hard halt)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../lib" && pwd)"
# shellcheck source=../lib/stats.sh
source "$LIB_DIR/stats.sh"
# shellcheck source=../lib/artifact-parser.sh
source "$LIB_DIR/artifact-parser.sh"

CTX="${1:-.forge/context}"
STATS="${2:-$CTX/.validation-stats.json}"

UNANCHORED=0
WHATTHISIS_VIOLATIONS=0
WHATTHISIS_REWRITES=0

INVENTORY_KW='controllers|files|classes|entities|migrations|listeners|routes|endpoints|handlers|tables|annotations|repositories|mappings|consumers|producers'

# Exclude regex (combined). Match → skip.
EXCLUDE_RE='\b([0-9]+\.[0-9]+(\.[0-9]+)?|HTTP[[:space:]]*[0-9]{3}|Java[[:space:]]+[0-9]+|Spring([[:space:]]+Boot)?[[:space:]]+[0-9]+|[0-9]+(\.[0-9]+)?%|0x[0-9a-fA-F]+|V[0-9]{4}_[0-9]{2}|port[[:space:]]+[0-9]+|version[[:space:]]+[0-9]+)\b'

# Returns 0 if line $1 is in inclusive range "$2-$3"
in_range() {
  local n="$1" start="$2" end="$3"
  [ -z "$start" ] && return 1
  [ "$n" -ge "$start" ] && [ "$n" -le "$end" ]
}

scan_file() {
  local file="$1"

  local wti_range
  wti_range=$(get_section_range "$file" "what-this-is" 2>/dev/null || true)
  local wti_start="" wti_end=""
  if [ -n "$wti_range" ]; then
    wti_start="${wti_range%-*}"
    wti_end="${wti_range#*-}"
  fi

  local total_lines
  total_lines=$(wc -l < "$file" | tr -d ' ')

  local lineno=0
  while IFS= read -r line; do
    lineno=$((lineno + 1))

    # Inventory keyword + 2+ digit number on same line?
    [[ "$line" =~ ([0-9]{2,}).*($INVENTORY_KW) ]] || continue

    # Exclusion patterns kill the match.
    if [[ "$line" =~ $EXCLUDE_RE ]]; then
      continue
    fi

    # Inside what-this-is section?
    if in_range "$lineno" "$wti_start" "$wti_end"; then
      # v0.5.4: auto-rewrite "<N>+ <noun>" forms (e.g. "60+ tables")
      # to qualitative phrasing. The N+ form is the LLM's most common
      # WTI shape and trivially mechanically recoverable. Anything
      # without a `+` (a hard count like "60 tables") is still a
      # FORBIDDEN halt — the author needs to re-think the prose.
      if [[ "$line" =~ ([0-9]+)\+[[:space:]]+($INVENTORY_KW) ]]; then
        local nplus="${BASH_REMATCH[1]}+"
        # In-place rewrite of just this line. "60+ tables" → "many tables".
        LINENO="$lineno" NPLUS="$nplus" perl -i -pe '
          if ($. == $ENV{LINENO}) {
            my $np = $ENV{NPLUS};
            s/\Q$np\E\s+/many /;
          }
        ' "$file"
        echo "REWROTE $file:$lineno: precise WTI '$nplus' → 'many' (qualitative)" >&2
        # Rewrites are warning-class (auto-repaired); only HARD COUNTS
        # without a `+` qualifier escalate to FORBIDDEN/halt below.
        WHATTHISIS_REWRITES=$((WHATTHISIS_REWRITES + 1))
        continue
      fi
      echo "FORBIDDEN $file:$lineno: precise inventory number in What This Is — replace with qualitative wording" >&2
      echo "  > ${line:0:120}" >&2
      WHATTHISIS_VIOLATIONS=$((WHATTHISIS_VIOLATIONS + 1))
      continue
    fi

    # Outside what-this-is: check for nearby ev:id anchor (window ±3 lines).
    local start_line end_line
    start_line=$(( lineno > 3 ? lineno - 3 : 1 ))
    end_line=$(( lineno + 3 > total_lines ? total_lines : lineno + 3 ))

    if ! sed -n "${start_line},${end_line}p" "$file" | grep -qE '<!-- ev:id=[a-z0-9_]+ -->'; then
      echo "UNANCHORED $file:$lineno: ${line:0:120}" >&2
      UNANCHORED=$((UNANCHORED + 1))
    fi
  done < "$file"
}

main() {
  [ -d "$CTX" ] || { echo "no context dir at $CTX" >&2; return 0; }

  local file
  for file in "$CTX"/*.md; do
    [ -f "$file" ] || continue
    scan_file "$file"
  done

  if [ -f "$STATS" ]; then
    if [ "$UNANCHORED" -gt 0 ]; then
      stats_increment "$STATS" count_drifts "$UNANCHORED"
    fi
    local total_wti=$(( WHATTHISIS_VIOLATIONS + WHATTHISIS_REWRITES ))
    if [ "$total_wti" -gt 0 ]; then
      stats_increment "$STATS" r9_violations "$total_wti"
    fi
  fi

  if [ "$WHATTHISIS_VIOLATIONS" -gt 0 ]; then
    echo "check5b: $WHATTHISIS_VIOLATIONS precise number(s) inside What This Is (FORBIDDEN — hard halt)" >&2
    return 2
  fi
  if [ "$UNANCHORED" -gt 0 ]; then
    echo "check5b: $UNANCHORED unanchored inventory number(s) (warning)" >&2
    return 1
  fi
  return 0
}

main "$@"
