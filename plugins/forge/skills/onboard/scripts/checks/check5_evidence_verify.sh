#!/usr/bin/env bash
#
# check5_evidence_verify.sh — verify and refresh count-style evidence.
#
# Walks every `.forge/context/.evidence/*.json` sidecar. For each entry:
#   1. Re-run the named detector against its recorded `root`.
#   2. Compare the fresh result to the declared `result`.
#   3. If drift > 5%:
#        a. Rewrite the sidecar `result` to the fresh value.
#        b. Rewrite Markdown numbers anchored by
#           `<!-- ev:id=<id> --> <number>` to match (fact-id-bound update;
#           NEVER full-file sed — that can corrupt unrelated digits).
#
# Exit code:
#   0  no drift
#   1  one or more counts updated (warning)
#   2  unrecoverable (detector script missing for an entry)
#
# stats.json:
#   count_drifts += <updated count>
#   mutations[]  += { check: "check5", before, after }

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../lib" && pwd)"
DET_DIR="$(cd "$SCRIPT_DIR/../detectors" && pwd)"
# shellcheck source=../lib/stats.sh
source "$LIB_DIR/stats.sh"

CTX="${1:-.forge/context}"
STATS="${2:-$CTX/.validation-stats.json}"

DRIFTS=0
UNRECOVERABLE=0

# Replace the number that immediately follows `<!-- ev:id=<ID> -->` in any
# Markdown file under $CTX. Only the anchored number is touched; unrelated
# digits in the file are safe.
update_anchored_number() {
  local id="$1" old="$2" new="$3"
  local md
  for md in "$CTX"/*.md; do
    [ -f "$md" ] || continue
    # The anchor may be on the same line as the number, or on the line
    # immediately above it. Perl walks the file once and rewrites only
    # numbers anchored by the matching ev:id (fact-id-bound update —
    # never a full-file regex sweep, which could corrupt unrelated digits).
    EV_ID="$id" EV_OLD="$old" EV_NEW="$new" perl -i -0pe '
      my $id  = $ENV{EV_ID};
      my $old = $ENV{EV_OLD};
      my $new = $ENV{EV_NEW};
      # Same-line:   <!-- ev:id=foo --> 689
      # Cross-line:  <!-- ev:id=foo -->\n689
      s{(<!-- ev:id=\Q$id\E -->[\s\n]*)\Q$old\E\b}{${1}$new}g;
    ' "$md"
  done
}

verify_one_evidence() {
  local sidecar="$1" entry="$2"

  local id detector root declared
  id=$(echo "$entry" | jq -r '.id')
  detector=$(echo "$entry" | jq -r '.detector')
  root=$(echo "$entry" | jq -r '.root')
  declared=$(echo "$entry" | jq -r '.result')

  local detector_script="$DET_DIR/${detector}.sh"
  if [ ! -x "$detector_script" ]; then
    echo "ERROR: detector '$detector' (referenced by ev:id=$id) is missing or non-executable" >&2
    UNRECOVERABLE=$((UNRECOVERABLE + 1))
    return 0
  fi

  local fresh
  fresh=$(bash "$detector_script" "$root" 2>/dev/null | jq -r '.result // 0')

  if [ "$declared" = "$fresh" ]; then
    return 0
  fi

  # 5% drift threshold (skip noise on tiny absolute changes too)
  local diff abs_diff
  diff=$(( fresh - declared ))
  abs_diff=${diff#-}
  if [ "$declared" -gt 0 ]; then
    local threshold=$(( declared * 5 / 100 ))
    [ "$threshold" -lt 1 ] && threshold=1
    if [ "$abs_diff" -lt "$threshold" ]; then
      return 0
    fi
  fi

  # Update sidecar entry: result = fresh
  local tmp
  tmp=$(mktemp)
  if jq --arg id "$id" --argjson new "$fresh" \
        '(.evidence[] | select(.id == $id) | .result) = $new' "$sidecar" > "$tmp"; then
    mv "$tmp" "$sidecar"
  else
    rm -f "$tmp"
    return 1
  fi

  # Update Markdown anchored numbers
  update_anchored_number "$id" "$declared" "$fresh"

  if [ -f "$STATS" ]; then
    stats_record_mutation "$STATS" check5 "$sidecar" \
      "ev:id=$id was $declared" \
      "ev:id=$id now $fresh"
  fi

  echo "DRIFT [$id]: $declared -> $fresh (detector=$detector root=$root)" >&2
  DRIFTS=$((DRIFTS + 1))
}

main() {
  [ -d "$CTX" ] || { echo "no context dir at $CTX" >&2; return 0; }

  local ev_dir="$CTX/.evidence"
  if [ ! -d "$ev_dir" ]; then
    # No sidecar yet → nothing to verify (alpha state).
    return 0
  fi

  local sidecar
  for sidecar in "$ev_dir"/*.json; do
    [ -f "$sidecar" ] || continue
    while IFS= read -r entry; do
      [ -z "$entry" ] && continue
      verify_one_evidence "$sidecar" "$entry"
    done < <(jq -c '.evidence[]?' "$sidecar")
  done

  if [ -f "$STATS" ] && [ "$DRIFTS" -gt 0 ]; then
    stats_increment "$STATS" count_drifts "$DRIFTS"
  fi

  [ "$UNRECOVERABLE" -gt 0 ] && return 2
  [ "$DRIFTS" -gt 0 ] && return 1
  return 0
}

main "$@"
