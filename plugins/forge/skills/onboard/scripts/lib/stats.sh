#!/usr/bin/env bash
#
# Atomic JSON helpers for .forge/context/.validation-stats.json
#
# Each Step 6.5 check uses these helpers; never echo raw JSON or `>>` append.
# stats.json is per-run (re-initialized at validator entry); the persistent
# audit trail is captured by Step 7 reading this file into JOURNAL.
#
# This file is sourced (not executed). It does not have a filter mode.

set -euo pipefail

# Initialize / reset the stats file with the canonical schema.
stats_init() {
  local file="$1"
  cat > "$file" <<'EOF'
{
  "r9_violations": 0,
  "r10_count_violations": 0,
  "r10_missing_tags": 0,
  "r17_redactions": 0,
  "sig_repairs": 0,
  "count_drifts": 0,
  "consistency_repairs": 0,
  "drift_warnings": 0,
  "journal_inconsistency": 0,
  "sentinel_normalizations": 0,
  "inventory_corrections": 0,
  "sonar_attestations": 0,
  "confidence_caps": 0,
  "mutations": []
}
EOF
}

# Increment a counter field by `delta` (default 1).
# Atomic via mktemp + mv; tmp is cleaned on jq failure.
stats_increment() {
  local file="$1" field="$2" delta="${3:-1}"
  local tmp
  tmp=$(mktemp)
  if jq --arg f "$field" --argjson d "$delta" \
        '.[$f] = ((.[$f] // 0) + $d)' "$file" > "$tmp"; then
    mv "$tmp" "$file"
  else
    rm -f "$tmp"
    return 1
  fi
}

# Append a mutation record (before/after diff) to the audit trail.
# Used by every mutating check (check3, check5, check6a, check6c, ...).
stats_record_mutation() {
  local file="$1" check="$2" target="$3" before="$4" after="$5"
  local tmp
  tmp=$(mktemp)
  if jq --arg c "$check" --arg t "$target" --arg b "$before" --arg a "$after" \
        '.mutations += [{
           "check": $c,
           "file": $t,
           "before": $b,
           "after": $a,
           "ts": now
         }]' "$file" > "$tmp"; then
    mv "$tmp" "$file"
  else
    rm -f "$tmp"
    return 1
  fi
}

# Render the one-line summary that Step 7 appends to JOURNAL.
stats_summary_line() {
  local file="$1"
  jq -r '
    "  - self-validation: " +
    (.r9_violations|tostring)        + " R9 / " +
    (.r10_count_violations|tostring) + " R10-count / " +
    (.r10_missing_tags|tostring)     + " R10-missing / " +
    (.r17_redactions|tostring)       + " R17 / " +
    (.sig_repairs|tostring)          + " sig / " +
    (.count_drifts|tostring)         + " drift / " +
    (.consistency_repairs|tostring)  + " consistency / " +
    (.sentinel_normalizations|tostring) + " sentinel-norm / " +
    (.inventory_corrections|tostring) + " inventory-fix / " +
    (.sonar_attestations|tostring) + " sonar-attest / " +
    (.confidence_caps|tostring) + " conf-cap"
  ' "$file"
}
