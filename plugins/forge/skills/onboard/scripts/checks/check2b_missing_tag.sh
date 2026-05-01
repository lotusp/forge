#!/usr/bin/env bash
#
# check2b_missing_tag.sh — heuristic detector for fact lines missing
# a confidence tag (R10 violation: "every fact must carry one").
#
# Heuristics for "this looks like a fact line":
#   - Markdown table data row (starts with `|` and is not a header /
#     separator row)
#   - Bullet list item (`- ` or `* `) that contains code / version /
#     identifier-like tokens
#   - Has at least 30 chars and contains at least one of:
#       version pattern (e.g. 2.5.12) / @-annotation / file path /
#       all-caps identifier
#
# Lines exempt from the check:
#   - inside the `what-this-is` section (R10 narrative exemption)
#   - inside any <!-- forge:preserve --> block (user-controlled)
#   - inside fenced code blocks (```...```)
#   - already carry a confidence tag (handled by check2a)
#   - header / separator rows
#
# This is HEURISTIC and WARNING-ONLY (exit 1, never 2). False positives
# are expected; the authoritative tag enforcement happens at render time
# inside profiles. Use this output as a "things to look at" hint.
#
# stats.json: r10_missing_tags += <flagged count>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../lib" && pwd)"
# shellcheck source=../lib/stats.sh
source "$LIB_DIR/stats.sh"
# shellcheck source=../lib/artifact-parser.sh
source "$LIB_DIR/artifact-parser.sh"

CTX="${1:-.forge/context}"
STATS="${2:-$CTX/.validation-stats.json}"

MISSING=0

# Test if a line in $1 (line number) is inside any of the supplied
# "start-end" ranges (newline-separated).
in_any_range() {
  local lineno="$1" ranges="$2"
  [ -z "$ranges" ] && return 1
  while IFS=- read -r start end; do
    [ -z "$start" ] && continue
    if [ "$lineno" -ge "$start" ] && [ "$lineno" -le "$end" ]; then
      return 0
    fi
  done <<< "$ranges"
  return 1
}

scan_file() {
  local file="$1"

  local whatthisis_range preserve_ranges
  whatthisis_range=$(get_section_range "$file" "what-this-is" 2>/dev/null || true)
  preserve_ranges=$(list_preserve_ranges "$file")

  local in_code_block=0
  local lineno=0
  while IFS= read -r line; do
    lineno=$((lineno + 1))

    # Track fenced code blocks (skip their interior).
    if [[ "$line" =~ ^[[:space:]]*\`\`\` ]]; then
      in_code_block=$(( 1 - in_code_block ))
      continue
    fi
    [ "$in_code_block" -eq 1 ] && continue

    # Skip what-this-is and preserve-block ranges.
    [ -n "$whatthisis_range" ] && in_any_range "$lineno" "$whatthisis_range" && continue
    in_any_range "$lineno" "$preserve_ranges" && continue

    # Skip lines that already have a confidence tag.
    [[ "$line" =~ \[(high|medium|low|inferred)\] ]] && continue

    # Skip very short lines and pure structural markdown.
    [ ${#line} -lt 30 ] && continue
    [[ "$line" =~ ^[[:space:]]*\<\!-- ]] && continue   # HTML comments / markers
    [[ "$line" =~ ^[[:space:]]*\| ]] || [[ "$line" =~ ^[[:space:]]*[-*][[:space:]] ]] || \
    [[ "$line" =~ ^[[:space:]]*[0-9]+\.[[:space:]] ]] || continue

    # Skip table separator rows (|---|---|).
    [[ "$line" =~ ^[[:space:]]*\|[[:space:]]*[-:]+[-:|[:space:]]*$ ]] && continue
    # Skip header rows (which are above separator; heuristic: no | on adjacent line)
    # — keeping it simple: require some content beyond a single token.

    # Heuristic: must contain at least one fact-like token to flag.
    if [[ "$line" =~ [0-9]+\.[0-9]+ ]] \
       || [[ "$line" =~ @[A-Z][a-zA-Z0-9]+ ]] \
       || [[ "$line" =~ /[a-zA-Z][a-zA-Z0-9_/.-]+\.(java|ts|py|go|kt|sql|yml|yaml) ]] \
       || [[ "$line" =~ \b[A-Z][A-Z0-9_]{2,}\b ]]; then
      echo "MISSING-TAG $file:$lineno: ${line:0:120}" >&2
      MISSING=$((MISSING + 1))
    fi
  done < "$file"
}

main() {
  [ -d "$CTX" ] || { echo "no context dir at $CTX" >&2; return 0; }

  local file
  for file in "$CTX"/*.md; do
    [ -f "$file" ] || continue
    scan_file "$file"
  done

  if [ -f "$STATS" ] && [ "$MISSING" -gt 0 ]; then
    stats_increment "$STATS" r10_missing_tags "$MISSING"
  fi

  if [ "$MISSING" -gt 0 ]; then
    echo "check2b R10: $MISSING fact line(s) missing confidence tag (warning, no auto-fix)" >&2
    return 1
  fi
  return 0
}

main "$@"
