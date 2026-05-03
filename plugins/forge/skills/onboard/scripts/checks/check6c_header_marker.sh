#!/usr/bin/env bash
#
# check6c_header_marker.sh — header ↔ marker commit consistency.
#
# Three responsibilities:
#   1. **Same-commit length normalize.** When the artifact header and a
#      section marker reference the same commit but with different
#      short-hash lengths (e.g. header `e30346c79d` vs marker
#      `e30346c7`), normalize both to the current `git rev-parse --short
#      HEAD` value so Mode B's fast-skip works reliably.
#   2. **Different-commit drift report.** When two refs disagree on the
#      actual commit, surface a DRIFT warning. Do NOT silently rewrite —
#      this is the user's call.
#   3. **no-git tolerance.** When the workspace has no git history,
#      never normalize. Only warn if header / marker have different
#      lengths (no canonical to align to).
#
# Implementation note: PROJECT_ROOT is derived from CTX
# (`<project>/.forge/context`) so the validator can be invoked from
# any working directory. All git invocations use `git -C "$PROJECT_ROOT"`.
#
# Exit code:
#   0  no inconsistency / no action needed
#   1  warning (drift reported and/or length-difference normalized)
#   2  not used

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../lib" && pwd)"
# shellcheck source=../lib/stats.sh
source "$LIB_DIR/stats.sh"

CTX="${1:-.forge/context}"
STATS="${2:-$CTX/.validation-stats.json}"

WARNINGS=0

# Two commits are "the same" when one is a prefix of the other.
same_commit() {
  local a="$1" b="$2"
  [ "$a" = "$b" ] && return 0
  case "$b" in "$a"*) return 0 ;; esac
  case "$a" in "$b"*) return 0 ;; esac
  return 1
}

main() {
  [ -d "$CTX" ] || { echo "no context dir at $CTX" >&2; return 0; }

  # Derive PROJECT_ROOT from CTX (= <project>/.forge/context).
  local project_root=""
  if [ -d "$CTX" ]; then
    local candidate
    candidate=$(cd "$CTX" 2>/dev/null && cd ../.. 2>/dev/null && pwd) || candidate=""
    if [ -n "$candidate" ] \
       && git -C "$candidate" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      project_root="$candidate"
    fi
  fi

  local current_head=""
  if [ -n "$project_root" ]; then
    current_head=$(git -C "$project_root" rev-parse --short HEAD 2>/dev/null || echo "")
  fi

  local file
  for file in "$CTX"/*.md; do
    [ -f "$file" ] || continue

    local header_commit
    header_commit=$(grep -E '^> Commit:' "$file" | head -1 \
                    | sed -E 's/.*Commit:[[:space:]]+//' | tr -d ' ' || true)
    [ -z "$header_commit" ] && continue
    [ "$header_commit" = "(no-commit)" ] && continue

    local marker_commits
    marker_commits=$(grep -oE 'verified-commit="[^"]+"' "$file" \
                     | sed -E 's/.*"([^"]+)"/\1/' | sort -u)

    local mc
    while IFS= read -r mc; do
      [ -z "$mc" ] && continue
      [ "$mc" = "(no-commit)" ] && continue

      # 1. Header ↔ marker comparison
      if ! same_commit "$header_commit" "$mc"; then
        echo "DRIFT $file: header=$header_commit ≠ marker=$mc (different commits)" >&2
        WARNINGS=$((WARNINGS + 1))
        continue   # do not normalize different-commit refs
      fi

      # Same commit; only normalize when length differs AND we have HEAD.
      if [ "$header_commit" != "$mc" ]; then
        if [ -n "$current_head" ]; then
          if same_commit "$current_head" "$header_commit" \
             && same_commit "$current_head" "$mc"; then
            local before
            before=$(grep -c "$mc" "$file" || true)
            sed -i.bak "s|^> Commit:.*|> Commit:           $current_head|" "$file"
            perl -i -pe "s|verified-commit=\"\Q$mc\E\"|verified-commit=\"$current_head\"|g" "$file"
            rm -f "$file.bak"
            echo "NORMALIZED $file: header=$header_commit, marker=$mc → $current_head (HEAD)" >&2
            WARNINGS=$((WARNINGS + 1))

            if [ -f "$STATS" ]; then
              stats_record_mutation "$STATS" check6c "$file" \
                "header=$header_commit / marker=$mc" \
                "both → $current_head"
            fi
          fi
        else
          echo "WARN $file: header=$header_commit ≠ marker=$mc (length differs, no git HEAD to normalize against)" >&2
          WARNINGS=$((WARNINGS + 1))
        fi
      fi
    done <<< "$marker_commits"

    # 2. Artifact-vs-HEAD drift (separate from header/marker mismatch).
    if [ -n "$current_head" ] && ! same_commit "$header_commit" "$current_head"; then
      echo "DRIFT $file: artifact header=$header_commit ≠ git HEAD=$current_head — context is stale; consider --regenerate" >&2
      WARNINGS=$((WARNINGS + 1))
    fi
  done

  if [ -f "$STATS" ] && [ "$WARNINGS" -gt 0 ]; then
    stats_increment "$STATS" drift_warnings "$WARNINGS"
  fi

  [ "$WARNINGS" -gt 0 ] && return 1 || return 0
}

main "$@"
