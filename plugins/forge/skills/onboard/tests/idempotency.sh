#!/usr/bin/env bash
#
# idempotency.sh — Phase 1 alpha hard-gate test.
#
# Asserts that running validate-onboard-artifacts.sh twice on the same
# context dir produces:
#   1. exit code 0 on the second run
#   2. zero mutations recorded in stats.json on the second run
#   3. byte-identical context files between the two post-run states
#
# Three axes catch different bugs:
#   - exit code  → check returned the wrong severity
#   - mutations  → check forgot to call stats_record_mutation
#   - file md5   → check mutated file content via a path that bypasses
#                   stats recording entirely
#
# Usage:
#   tests/idempotency.sh <context-dir> [<validator-path>]
#
# Default validator is ../scripts/validate-onboard-artifacts.sh relative
# to this script.
#
# Exit code:
#   0   IDEMPOTENT
#   1   not idempotent (any of the three axes failed)

set -euo pipefail

THIS_DIR="$(cd "$(dirname "$0")" && pwd)"
VALIDATOR_DEFAULT="$(cd "$THIS_DIR/../scripts" && pwd)/validate-onboard-artifacts.sh"

CTX="${1:-}"
VALIDATOR="${2:-$VALIDATOR_DEFAULT}"

if [ -z "$CTX" ] || [ ! -d "$CTX" ]; then
  echo "Usage: $0 <context-dir> [<validator-path>]" >&2
  echo "  context dir not found or not specified: '$CTX'" >&2
  exit 2
fi

if [ ! -x "$VALIDATOR" ]; then
  echo "ERROR: validator not executable: $VALIDATOR" >&2
  exit 2
fi

# Cross-platform md5 wrapper. Returns lowercase hex digest of the input.
md5_hex() {
  if command -v md5sum >/dev/null 2>&1; then
    md5sum | awk '{print $1}'
  elif command -v md5 >/dev/null 2>&1; then
    md5 -q
  else
    echo "ERROR: neither md5sum nor md5 available" >&2
    return 127
  fi
}

# Snapshot all .md files under CTX into one combined md5.
snapshot_md5() {
  find "$CTX" -name '*.md' -type f \
    | LC_ALL=C sort \
    | while read -r f; do
        printf '%s ' "$f"
        md5_hex < "$f"
      done \
    | md5_hex
}

echo "=== idempotency test ==="
echo "  context:   $CTX"
echo "  validator: $VALIDATOR"
echo ""

# ─────── First run (warm up; may auto-repair) ───────
echo "→ first run"
set +e
"$VALIDATOR" "$CTX" >/dev/null
status1=$?
set -e
mutations1=$(jq '.mutations | length' "$CTX/.validation-stats.json")
md5_after_first=$(snapshot_md5)
echo "  exit=$status1, mutations=$mutations1"

# ─────── Second run (must be a no-op) ───────
echo "→ second run"
set +e
"$VALIDATOR" "$CTX" >/dev/null
status2=$?
set -e
mutations2=$(jq '.mutations | length' "$CTX/.validation-stats.json")
md5_after_second=$(snapshot_md5)
echo "  exit=$status2, mutations=$mutations2"

# ─────── Three-axis assertion ───────
echo ""
fail=0

# Hard halt is always a failure; warnings (exit 1) are tolerated on the
# second run iff no mutations were recorded and file content didn't change.
# Some checks are heuristic-only (e.g. check2b missing-tag, check5b
# unanchored numbers): they emit warnings every run without mutating
# anything, which is the correct behavior — not an idempotency violation.
if [ "$status2" -eq 2 ]; then
  echo "FAIL [exit code]: second run hard-halted (status=2)"
  fail=1
fi

if [ "$mutations2" -ne 0 ]; then
  echo "FAIL [mutations]: second run recorded $mutations2 mutations (expected 0)"
  fail=1
fi

if [ "$md5_after_first" != "$md5_after_second" ]; then
  echo "FAIL [file content]: md5 changed between runs"
  echo "  first:  $md5_after_first"
  echo "  second: $md5_after_second"
  echo "  → some check mutated artifacts but did not call stats_record_mutation"
  fail=1
fi

if [ "$fail" -eq 1 ]; then
  echo ""
  echo "NOT IDEMPOTENT ✗"
  exit 1
fi

echo "IDEMPOTENT ✓"
exit 0
