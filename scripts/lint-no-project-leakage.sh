#!/usr/bin/env bash
#
# lint-no-project-leakage.sh — guard the forge codebase from leaking
# downstream project-specific identifiers (project names, abbreviations,
# internal paths, package names, domain names, ...).
#
# CRITICAL: this script MUST NOT itself contain any project keywords.
# The list of forbidden terms is read from a LOCAL file (.lint-keywords)
# which is gitignored. Each developer maintains their own copy.
#
# Usage:
#   scripts/lint-no-project-leakage.sh             # scan working tree (tracked files)
#   scripts/lint-no-project-leakage.sh --history   # scan all of git history
#   scripts/lint-no-project-leakage.sh --staged    # scan only staged changes (pre-commit)
#
# Exit code:
#   0  no leak detected
#   1  one or more leaks detected (printed to stderr)
#   2  configuration error (no keyword file, not in repo, etc.)

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$REPO_ROOT" ]; then
  echo "ERROR: not inside a git repository" >&2
  exit 2
fi

KEYWORD_FILE="$REPO_ROOT/.lint-keywords"
if [ ! -f "$KEYWORD_FILE" ]; then
  cat >&2 <<EOF
ERROR: keyword file not found: $KEYWORD_FILE

This file lists project-specific terms that must not appear in committed
code. It is gitignored — each developer creates their own copy locally.

Create it with one keyword per line, e.g.:
  echo "your-project-name" >  $KEYWORD_FILE
  echo "internal-abbrev"   >> $KEYWORD_FILE
EOF
  exit 2
fi

# Build the alternation pattern from non-comment, non-empty lines.
PATTERN=$(grep -vE '^\s*(#|$)' "$KEYWORD_FILE" | sed 's/[[:space:]]*$//' \
          | awk 'NF' | paste -sd '|' -)

if [ -z "$PATTERN" ]; then
  echo "WARN: keyword file is empty; nothing to scan for" >&2
  exit 0
fi

MODE="${1:-tree}"
HITS=0

scan_tree() {
  # Scan tracked files in HEAD's working tree.
  cd "$REPO_ROOT"
  local file matches n
  while IFS= read -r file; do
    [ -f "$file" ] || continue
    case "$file" in
      .lint-keywords|scripts/lint-no-project-leakage.sh) continue ;;
    esac
    matches=$(grep -niE "$PATTERN" "$file" 2>/dev/null || true)
    if [ -n "$matches" ]; then
      n=$(printf '%s\n' "$matches" | wc -l | tr -d ' ')
      printf '%s\n' "$matches" | sed "s|^|$file:|" >&2
      HITS=$((HITS + n))
    fi
  done < <(git ls-files)
}

scan_history() {
  cd "$REPO_ROOT"
  # Scan tracked file content across all reachable commits, plus all
  # commit messages. Output: <commit>:<path>:<line>:<text>
  echo "[history] scanning commit messages..." >&2
  git log --all --format='%H%n%B%n###END_COMMIT_MSG###' \
    | awk -v pat="$PATTERN" '
        /^###END_COMMIT_MSG###$/ { sha=""; next }
        /^[0-9a-f]{40}$/ { sha=$0; next }
        { if (tolower($0) ~ tolower(pat)) print sha ":<commit-msg>: " $0 }
      ' | grep -iE "$PATTERN" >&2 \
    && HITS=$((HITS + 1)) || true

  echo "[history] scanning blob content (this may take a while)..." >&2
  # git grep across all reachable revs is the canonical way.
  if git grep -niE "$PATTERN" $(git rev-list --all) -- ':!.lint-keywords' ':!scripts/lint-no-project-leakage.sh' 2>/dev/null >&2; then
    HITS=$((HITS + 1))
  fi
}

scan_staged() {
  cd "$REPO_ROOT"
  local file
  while IFS= read -r file; do
    [ -f "$file" ] || continue
    case "$file" in
      .lint-keywords|scripts/lint-no-project-leakage.sh) continue ;;
    esac
    git diff --cached -- "$file" \
      | grep -E '^\+' \
      | grep -niE "$PATTERN" \
      | sed "s|^|$file:|" >&2 \
      && HITS=$((HITS + 1)) || true
  done < <(git diff --cached --name-only)
}

case "$MODE" in
  tree|"")     scan_tree ;;
  --history)   scan_history ;;
  --staged)    scan_staged ;;
  -h|--help)
    sed -n '3,20p' "$0"
    exit 0
    ;;
  *)
    echo "ERROR: unknown mode: $MODE" >&2
    exit 2
    ;;
esac

if [ "$HITS" -gt 0 ]; then
  echo "" >&2
  echo "lint-no-project-leakage: $HITS leak(s) detected — see lines above" >&2
  exit 1
fi
echo "lint-no-project-leakage: clean" >&2
exit 0
