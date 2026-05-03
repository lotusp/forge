#!/usr/bin/env bash
#
# check6d_journal_consistency.sh — JOURNAL ↔ artifact reconciliation.
#
# `.forge/JOURNAL.md` records counts the LLM may have estimated wrong
# (v0.5.1 review of biz-svc-b found "12 sections written" claimed
# while the artifact actually contained 15 marker pairs). This check
# compares JOURNAL claims against the real artifact state.
#
# Single-writer boundary (R7 / v6 G8): this check NEVER writes
# `.forge/JOURNAL.md`. It only writes `journal_inconsistency` to the
# stats sidecar. Step 7 of the onboard run is the SOLE writer of
# JOURNAL — when stats reports inconsistencies, Step 7 should rewrite
# the most recent entry's count line to match the grep evidence.
#
# Exit code:
#   0  no inconsistency detected
#   1  inconsistency reported in stats (warning)
#   2  not used

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../lib" && pwd)"
# shellcheck source=../lib/stats.sh
source "$LIB_DIR/stats.sh"

CTX="${1:-.forge/context}"
STATS="${2:-$CTX/.validation-stats.json}"

INCONSISTENCIES=0

main() {
  [ -d "$CTX" ] || { echo "no context dir at $CTX" >&2; return 0; }

  # JOURNAL lives at <project>/.forge/JOURNAL.md (sibling of context/).
  local journal="$CTX/../JOURNAL.md"
  if [ ! -f "$journal" ]; then
    return 0
  fi

  local onboard="$CTX/onboard.md"
  if [ ! -f "$onboard" ]; then
    return 0
  fi

  # Real counts from the artifact (authoritative).
  local actual_sections actual_preserved
  actual_sections=$(grep -c '<!-- forge:onboard source-file=' "$onboard" || true)
  actual_preserved=$(grep -c '<!-- forge:preserve' "$onboard" || true)

  # JOURNAL most-recent claim. The expected line shape is:
  #   - onboard.md: 12 sections written / 0 preserved blocks / 0 skipped
  # We pick the LAST such line in the file.
  local journal_line
  journal_line=$(grep -E 'onboard\.md:[[:space:]]*[0-9]+[[:space:]]+sections' "$journal" 2>/dev/null \
                 | tail -1 || true)

  if [ -z "$journal_line" ]; then
    return 0   # no claim to reconcile against
  fi

  local journal_sections journal_preserved
  journal_sections=$(echo "$journal_line" | sed -nE 's/.*onboard\.md:[[:space:]]*([0-9]+)[[:space:]]+sections.*/\1/p')
  journal_preserved=$(echo "$journal_line" | sed -nE 's/.*[[:space:]]([0-9]+)[[:space:]]+preserved.*/\1/p')

  # Compare; report each axis independently so Step 7 knows which to fix.
  if [ -n "$journal_sections" ] && [ "$journal_sections" != "$actual_sections" ]; then
    echo "INCONSISTENCY: JOURNAL claims $journal_sections sections; artifact has $actual_sections" >&2
    INCONSISTENCIES=$((INCONSISTENCIES + 1))
  fi
  if [ -n "$journal_preserved" ] && [ "$journal_preserved" != "$actual_preserved" ]; then
    echo "INCONSISTENCY: JOURNAL claims $journal_preserved preserved blocks; artifact has $actual_preserved" >&2
    INCONSISTENCIES=$((INCONSISTENCIES + 1))
  fi

  if [ -f "$STATS" ] && [ "$INCONSISTENCIES" -gt 0 ]; then
    stats_increment "$STATS" journal_inconsistency "$INCONSISTENCIES"
  fi

  if [ "$INCONSISTENCIES" -gt 0 ]; then
    echo "check6d: $INCONSISTENCIES JOURNAL inconsistency(ies) recorded in stats; Step 7 will rewrite the entry" >&2
    return 1
  fi
  return 0
}

main "$@"
