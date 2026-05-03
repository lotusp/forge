#!/usr/bin/env bash
#
# check6b_intra_file.sh — heuristic intra-file consistency detector.
#
# Within a single artifact file (typically onboard.md), the same topic
# is sometimes described twice — once in the section that owns it
# (e.g. "HTTP API Surface" listing public routes) and once in a related
# section (e.g. "Authentication & Authorization" listing the same
# permitted routes). When the two lists drift, the artifact reads
# inconsistently.
#
# Failure mode (v0.5.1 review of web-bff-svc):
#   §HTTP API Surface lists 5 public routes
#   §Authentication & Authorization lists 10 public routes (incl. the 5)
#   Reader cannot tell which list is canonical.
#
# Detection (heuristic):
#   - For each forge:onboard section, count "path-shaped" bullets
#     (lines starting with `-` and containing a `/api/...` or `/`-rooted
#     URL-like token).
#   - Group sections by topic-class (auth-related vs api-related vs
#     other) using simple keyword match in the section heading.
#   - When two sections in the same topic-class have notably different
#     counts (ratio > 2x), flag the file as having intra-file drift.
#
# This is heuristic and warning-only. It does NOT auto-fix; reconciling
# the two lists is a judgement call that belongs to the author.
#
# Exit code:
#   0  no notable drift detected
#   1  warning: intra-file drift in at least one file
#   2  not used

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../lib" && pwd)"
# shellcheck source=../lib/stats.sh
source "$LIB_DIR/stats.sh"
# shellcheck source=../lib/artifact-parser.sh
source "$LIB_DIR/artifact-parser.sh"

CTX="${1:-.forge/context}"
STATS="${2:-$CTX/.validation-stats.json}"

DRIFT_WARNINGS=0

# Decide which topic-class a section belongs to, based on its id.
# Returns the class name on stdout, or empty if not a tracked topic.
classify_section() {
  case "$1" in
    auth*|*authentication*) echo "auth-routes" ;;
    http-api*|*http*|*api-surface*|http) echo "api-routes" ;;
    *) echo "" ;;
  esac
}

# Count path-shaped bullets ('-' or '*' starting lines containing a
# `/api/...` style URL) within a section body. `grep -c` returns 1 on
# zero matches and `set -euo pipefail` would kill the script — so we
# capture the count under `set +e` and report 0 when grep fails.
count_path_bullets() {
  local file="$1" section="$2"
  local body n
  body=$(extract_section_body "$file" "$section" 2>/dev/null || true)
  set +e
  n=$(printf '%s' "$body" | grep -cE '^[[:space:]]*[-*][[:space:]].*\b/api/|^[[:space:]]*[-*][[:space:]].*`/[a-z]')
  set -e
  echo "${n:-0}"
}

scan_file() {
  local file="$1"

  # Accumulate path-bullet counts per topic-class.
  local auth_total=0 auth_section=""
  local api_total=0 api_section=""

  local section
  while IFS= read -r section; do
    [ -z "$section" ] && continue
    local class
    class=$(classify_section "$section")
    [ -z "$class" ] && continue

    local n
    n=$(count_path_bullets "$file" "$section")
    [ "$n" -lt 2 ] && continue   # too few bullets to make drift judgements

    case "$class" in
      auth-routes)
        if [ "$n" -gt "$auth_total" ]; then
          auth_total=$n
          auth_section=$section
        fi
        ;;
      api-routes)
        if [ "$n" -gt "$api_total" ]; then
          api_total=$n
          api_section=$section
        fi
        ;;
    esac
  done < <(list_sections "$file")

  # Cross-class drift heuristic: flag when one section has at least 50%
  # more path bullets than the other (catches the v0.5.1 web-bff-svc
  # case of 5 vs 10 routes; tolerates minor noise like 4 vs 5).
  if [ "$auth_total" -gt 0 ] && [ "$api_total" -gt 0 ]; then
    local lo=$auth_total hi=$api_total
    if [ "$api_total" -lt "$auth_total" ]; then
      lo=$api_total
      hi=$auth_total
    fi
    if [ "$lo" -gt 0 ]; then
      local diff_pct=$(( (hi - lo) * 100 / lo ))
      if [ "$diff_pct" -ge 50 ]; then
        echo "DRIFT $file: §$auth_section lists $auth_total path bullets vs §$api_section lists $api_total (${diff_pct}% diff) — possibly inconsistent" >&2
        DRIFT_WARNINGS=$((DRIFT_WARNINGS + 1))
      fi
    fi
  fi
}

main() {
  [ -d "$CTX" ] || { echo "no context dir at $CTX" >&2; return 0; }

  local file
  for file in "$CTX"/*.md; do
    [ -f "$file" ] || continue
    scan_file "$file"
  done

  if [ -f "$STATS" ] && [ "$DRIFT_WARNINGS" -gt 0 ]; then
    stats_increment "$STATS" drift_warnings "$DRIFT_WARNINGS"
  fi

  if [ "$DRIFT_WARNINGS" -gt 0 ]; then
    echo "check6b: $DRIFT_WARNINGS file(s) with possible intra-file path-list drift" >&2
    return 1
  fi
  return 0
}

main "$@"
