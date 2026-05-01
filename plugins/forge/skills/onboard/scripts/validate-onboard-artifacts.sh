#!/usr/bin/env bash
#
# validate-onboard-artifacts.sh — orchestrator for Step 6.5.
#
# Usage:   validate-onboard-artifacts.sh [<context-dir>]
#          (default: .forge/context relative to CWD)
#
# Exit code:
#   0  clean — no warnings, no halts
#   1  warning(s) — at least one check repaired or flagged something
#   2  hard halt — at least one structural / unrecoverable failure
#
# Two-pass order (alpha — extends in beta/final):
#
#   preflight        (tools / dependencies)
#   ─────────────── PASS 1 ───────────────
#   check4           resolve "(pending)" + initial signatures
#   check1           strict marker regex (post-pending)
#   ───────── MUTATING CHECKS ────────────
#   check3           R17 redaction (alpha-only mutator)
#   ─────────────── PASS 2 ───────────────
#   check4           refresh signatures after mutations
#   check1           re-validate structure after mutations
#
# This two-pass ordering closes the v6 E1 gap: any mutating check
# invalidates signatures recorded in PASS 1, so PASS 2 is required.
#
# Severity is always decided by EXIT CODE of each check (not by name),
# so adding new mutating checks in beta/final does not require touching
# the dispatch logic here.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CTX="${1:-.forge/context}"
STATS="$CTX/.validation-stats.json"

# ============================================================================
# Function definitions FIRST (avoid forward-reference at hard-halt early exit)
# ============================================================================

# shellcheck source=lib/stats.sh
source "$SCRIPT_DIR/lib/stats.sh"

WARN=0
HALT=0

run_check() {
  local script="$1"
  local script_path="$SCRIPT_DIR/checks/$script"

  if [ ! -x "$script_path" ]; then
    echo "ERROR: missing or non-executable check: $script_path" >&2
    HALT=1
    return
  fi

  local rc=0
  "$script_path" "$CTX" "$STATS" || rc=$?
  case "$rc" in
    0) ;;
    1) WARN=1 ;;
    2) HALT=1 ;;
    *)
      echo "WARN: $script returned unexpected code $rc; treating as halt" >&2
      HALT=1
      ;;
  esac
}

emit_summary_and_exit() {
  if [ -f "$STATS" ]; then
    stats_summary_line "$STATS"
  fi

  if [ "$HALT" -eq 1 ]; then
    echo "validate-onboard-artifacts: HARD HALT" >&2
    exit 2
  fi
  if [ "$WARN" -eq 1 ]; then
    echo "validate-onboard-artifacts: warnings (auto-repaired)" >&2
    exit 1
  fi
  echo "validate-onboard-artifacts: clean" >&2
  exit 0
}

# Helper for early-exit on hard halt without skipping summary emission.
halt_if_needed() {
  if [ "$HALT" -eq 1 ]; then
    emit_summary_and_exit
  fi
}

# ============================================================================
# Main flow
# ============================================================================

if [ ! -d "$CTX" ]; then
  echo "ERROR: context dir not found: $CTX" >&2
  exit 2
fi

# Step 0 — preflight
"$SCRIPT_DIR/preflight.sh" || exit 2

# Initialize per-run stats schema
stats_init "$STATS"

# ─────────────────────────── PASS 1 ───────────────────────────
# check4 first: resolves "(pending)" placeholders + initial signatures.
# check1 next:  strict regex (no "(pending)" exception by design).
run_check check4_signature_recompute.sh
halt_if_needed
run_check check1_marker_structural.sh
halt_if_needed

# ─────────────────────── MUTATING CHECKS ──────────────────────
# alpha includes only check3. beta/final will add check2a/check2b/
# check5/check5b/check6a/check6b/check6c/check6d here.
run_check check3_redaction.sh
# (do not halt_if_needed — Tier A redaction is exit 1 by design)

# ─────────────────────────── PASS 2 ───────────────────────────
# Mutations above may have changed body content; re-derive signatures
# and re-validate structure to guarantee on-disk artifact is consistent.
run_check check4_signature_recompute.sh
halt_if_needed
run_check check1_marker_structural.sh
halt_if_needed

emit_summary_and_exit
