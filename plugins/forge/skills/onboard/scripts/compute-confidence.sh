#!/usr/bin/env bash
#
# compute-confidence.sh — derive a deterministic confidence ceiling
# for the artifact based on Step 6.5 validator activity.
#
# v0.5.4 review found that the LLM-set Confidence header bears no
# correlation with actual fact accuracy. One real-world project with
# 4/4 facts correct carried 0.70 while another with a sonar duplicate
# finding carried 0.85. Confidence is supposed to communicate
# trustworthiness; an opaque LLM judgement makes that signal noise.
#
# This script reads `.forge/context/.validation-stats.json` (produced
# by all the Step 6.5 checks) and computes a single number:
#
#   issues = r9_violations
#          + r10_count_violations
#          + r10_missing_tags
#          + r17_redactions
#          + sig_repairs
#          + count_drifts
#          + consistency_repairs
#          + sentinel_normalizations
#          + inventory_corrections
#          + sonar_attestations
#          + journal_inconsistency
#          + drift_warnings
#
#   confidence = max(0.40, 1.00 - issues * 0.01)
#
# Each issue subtracts 0.01 from the ceiling, with a floor at 0.40.
# 60 issues → 0.40 ceiling (saturated).
#
# Usage:
#   compute-confidence.sh <ctx-dir>
#
# Output (stdout): just the number with two decimals (e.g. "0.86").
# Stderr: a short breakdown for human eyes.
#
# Exit code:
#   0  — number printed
#   2  — stats file missing

set -euo pipefail

CTX="${1:-.forge/context}"
STATS="$CTX/.validation-stats.json"

if [ ! -f "$STATS" ]; then
  echo "ERROR: stats file not found: $STATS" >&2
  exit 2
fi

# Sum every numeric counter in the schema. Unknown / new counters
# are picked up automatically as long as they're top-level integers.
#
# `confidence_caps` is excluded because check9 itself increments it,
# and including it would create a feedback loop (each run lowers the
# ceiling by another 0.01, breaking idempotency).
ISSUES=$(jq -r '
  [ . | to_entries[]
    | select(.value | type == "number")
    | select(.key != "confidence_caps")
    | .value ]
  | add // 0
' "$STATS")

# Compute confidence using awk for two-decimal arithmetic.
CONF=$(awk -v issues="$ISSUES" 'BEGIN {
  c = 1.0 - issues * 0.01
  if (c < 0.40) c = 0.40
  printf "%.2f", c
}')

# Human-readable breakdown.
echo "compute-confidence: ${ISSUES} issue(s) → confidence ceiling ${CONF}" >&2
echo "  breakdown:" >&2
jq -r '
  to_entries[] |
  select(.value | type == "number") |
  select(.value > 0) |
  "    " + .key + ": " + (.value | tostring)
' "$STATS" >&2

# Single-line numeric output (callers parse this).
printf '%s\n' "$CONF"
