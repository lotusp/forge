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
# check4 first:  resolves "(pending)" placeholders + initial signatures.
# check6e next:  coerce non-spec verified-commit / Header sentinels
#                ("(none)" / "no-git" / "no-git-000" / ...) into the
#                canonical form so check1's strict regex doesn't halt
#                on what is essentially an LLM placeholder.
# check1 last:   strict regex (no "(pending)" exception by design).
run_check check4_signature_recompute.sh
halt_if_needed
run_check check6e_sentinel_normalize.sh
# (no halt_if_needed: check6e is a normalizer; warning-class by design)
run_check check1_marker_structural.sh
halt_if_needed

# ─────────────────────── MUTATING CHECKS ──────────────────────
# Beta: check2a (strip), check5 (drift).
# Final: check6a (cross-stage downgrade), check6c (commit normalize).
# All can mutate; Pass 2 below re-stamps the body-signature.
run_check check3_redaction.sh
# (do not halt_if_needed — Tier A redaction is exit 1 by design)
run_check check2a_tag_count.sh
run_check check5_evidence_verify.sh
halt_if_needed     # check5 may exit 2 if a referenced detector is missing
run_check check6a_cross_stage.sh
run_check check6c_header_marker.sh
# v0.5.4: inject-facts (truth registry) + check7 (auto-correct
# inventory numbers using the registry). inject-facts is a producer
# script, not a check, so it doesn't go through run_check.
"$SCRIPT_DIR/inject-facts.sh" "$CTX/.." 2>&1 \
  | sed 's/^/  [inject-facts] /' >&2 || true
run_check check7_inventory_truth.sh
run_check check8_sonar_attestation.sh

# ─────────────────────────── PASS 2 ───────────────────────────
# Mutations above may have changed body content; re-derive signatures
# and re-validate structure to guarantee on-disk artifact is consistent.
run_check check4_signature_recompute.sh
halt_if_needed
run_check check1_marker_structural.sh
halt_if_needed

# ─────────────────────────── WARNINGS ─────────────────────────
# Heuristic / warning-only checks run after the artifact is structurally
# stable. check5b can hard-halt if it finds precise numbers inside the
# What This Is narrative section (Step 3.2 forbids those).
run_check check2b_missing_tag.sh
run_check check5b_unanchored_numbers.sh
halt_if_needed
run_check check6b_intra_file.sh
run_check check6d_journal_consistency.sh

emit_summary_and_exit
