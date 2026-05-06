#!/usr/bin/env bash
#
# check9_confidence_normalize.sh — deterministic Header `> Confidence:`
# rewrite based on validator activity.
#
# v0.5.4 field testing showed that LLM-set Confidence does not
# correlate with actual fact accuracy: one real-world project with
# 4/4 numbers correct carried 0.70 while another with a sonar
# duplicate finding carried 0.85. This undermines the field's
# purpose as a reader signal.
#
# Strategy: run scripts/compute-confidence.sh against the run's
# stats.json; if the LLM-set value is HIGHER than the deterministic
# ceiling, lower it. If LLM is already below the ceiling, leave it
# alone (the LLM may have additional reasons for low confidence we
# don't model).
#
# Idempotency marker: a sentinel comment is inserted next to the
# rewritten line so a second run won't re-rewrite the already-correct
# value. Format: `> Confidence:           0.78  <!-- check9:capped -->`
#
# Run order: WARNINGS phase, AFTER every counter-incrementing check
# so issue counts are final.
#
# Exit code:
#   0  no change needed
#   1  Confidence lowered (warning class)
#   2  not used

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../lib" && pwd)"
# shellcheck source=../lib/stats.sh
source "$LIB_DIR/stats.sh"

CTX="${1:-.forge/context}"
STATS="${2:-$CTX/.validation-stats.json}"
ART="$CTX/onboard.md"

if [ ! -f "$ART" ] || [ ! -f "$STATS" ]; then
  exit 0
fi

# Read LLM-set Confidence value.
LLM_LINE=$(grep -E '^> Confidence:' "$ART" | head -1 || true)
if [ -z "$LLM_LINE" ]; then
  echo "check9: no '> Confidence:' line found; skipping" >&2
  exit 0
fi
LLM_VALUE=$(printf '%s' "$LLM_LINE" \
  | sed -E 's/^> Confidence:[[:space:]]+([0-9.]+).*/\1/')

# Compute deterministic ceiling.
CEILING=$("$SCRIPT_DIR/../compute-confidence.sh" "$CTX" 2>/dev/null \
          | tail -1)

if [ -z "$CEILING" ] || [ -z "$LLM_VALUE" ]; then
  echo "check9: could not parse confidence values (LLM='$LLM_VALUE' ceiling='$CEILING'); skipping" >&2
  exit 0
fi

# Compare LLM value vs ceiling using awk (bash can't do float).
COMPARE=$(awk -v llm="$LLM_VALUE" -v c="$CEILING" 'BEGIN {
  if (llm > c) print "lower"
  else         print "ok"
}')

if [ "$COMPARE" = "ok" ]; then
  exit 0
fi

# Already capped by an earlier run? Marker check.
if grep -qF '<!-- check9:capped -->' "$ART" 2>/dev/null; then
  # Marker present but value above ceiling — the stats changed since
  # last run. Re-rewrite (drop marker first) to refresh.
  perl -i -pe 's/[[:space:]]*<!-- check9:capped -->//g' "$ART"
fi

# Rewrite the line.
CEILING="$CEILING" perl -i -pe '
  if (/^> Confidence:[[:space:]]+/) {
    my $c = $ENV{CEILING};
    s/^(> Confidence:[[:space:]]+)[0-9.]+([[:space:]]*.*)$/$1$c$2  <!-- check9:capped -->/;
  }
' "$ART"

echo "CAPPED $ART: > Confidence: $LLM_VALUE → $CEILING (deterministic ceiling)" >&2

if [ -f "$STATS" ]; then
  stats_increment "$STATS" confidence_caps 1
  stats_record_mutation "$STATS" check9 "$ART" \
    "confidence=$LLM_VALUE" "confidence=$CEILING (capped)"
fi

exit 1
