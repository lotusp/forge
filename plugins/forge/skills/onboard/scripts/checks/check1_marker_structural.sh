#!/usr/bin/env bash
#
# check1_marker_structural.sh — R9 section marker structural validation.
#
# Verifies every <!-- forge:onboard ... --> opening marker in any
# .forge/context/*.md file:
#   - has all 6 required attributes in order:
#     source-file / section / profile / verified-commit /
#     body-signature / generated
#   - verified-commit  matches ^([a-f0-9]{7,12}|\(no-commit\))$
#   - body-signature   matches ^[a-f0-9]{16}$  (NO (pending) here —
#                                               check4 must run first)
#   - generated        matches ^[0-9]{4}-[0-9]{2}-[0-9]{2}$
#
# Exit code:
#   0  no violations
#   2  one or more structural violations  (hard halt class)
#
# Pre-condition: check4 has already eliminated "(pending)" placeholders.
# This check enforces strict 16-hex body-signature regex; do not relax it.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../lib" && pwd)"
# shellcheck source=../lib/stats.sh
source "$LIB_DIR/stats.sh"

CTX="${1:-.forge/context}"
STATS="${2:-$CTX/.validation-stats.json}"

VIOLATIONS=0

violation() {
  echo "VIOLATION R9: $*" >&2
  VIOLATIONS=$((VIOLATIONS + 1))
}

# Validate one opening marker line.
# Returns 0 (silent) on pass, increments VIOLATIONS on fail.
validate_marker() {
  local file="$1" lineno="$2" line="$3"

  # Required attributes — extract each. Empty string = missing.
  local sf sec prof vc bs gen
  sf=$(  echo "$line" | sed -nE 's/.*[[:space:]]source-file="([^"]*)".*/\1/p')
  sec=$( echo "$line" | sed -nE 's/.*[[:space:]]section="([^"]*)".*/\1/p')
  prof=$(echo "$line" | sed -nE 's/.*[[:space:]]profile="([^"]*)".*/\1/p')
  vc=$(  echo "$line" | sed -nE 's/.*[[:space:]]verified-commit="([^"]*)".*/\1/p')
  bs=$(  echo "$line" | sed -nE 's/.*[[:space:]]body-signature="([^"]*)".*/\1/p')
  gen=$( echo "$line" | sed -nE 's/.*[[:space:]]generated="([^"]*)".*/\1/p')

  for attr_pair in "source-file:$sf" "section:$sec" "profile:$prof" \
                   "verified-commit:$vc" "body-signature:$bs" "generated:$gen"; do
    local name="${attr_pair%%:*}"
    local val="${attr_pair#*:}"
    if [ -z "$val" ]; then
      violation "$file:$lineno missing required attribute '$name'"
    fi
  done

  # verified-commit regex
  if [ -n "$vc" ] && ! [[ "$vc" =~ ^([a-f0-9]{7,12}|\(no-commit\))$ ]]; then
    violation "$file:$lineno verified-commit=\"$vc\" (must be 7-12 hex or '(no-commit)')"
  fi

  # body-signature regex (strict 16 hex; no '(pending)' here)
  if [ -n "$bs" ] && ! [[ "$bs" =~ ^[a-f0-9]{16}$ ]]; then
    violation "$file:$lineno body-signature=\"$bs\" (must be exactly 16 lowercase hex chars)"
  fi

  # generated regex
  if [ -n "$gen" ] && ! [[ "$gen" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    violation "$file:$lineno generated=\"$gen\" (must be ISO date YYYY-MM-DD)"
  fi
}

main() {
  [ -d "$CTX" ] || { echo "no context dir at $CTX" >&2; return 0; }

  local file
  for file in "$CTX"/*.md; do
    [ -f "$file" ] || continue
    while IFS=: read -r lineno line; do
      [ -z "$line" ] && continue
      validate_marker "$file" "$lineno" "$line"
    done < <(grep -nE '<!-- forge:onboard ' "$file" 2>/dev/null || true)
  done

  if [ -f "$STATS" ] && [ "$VIOLATIONS" -gt 0 ]; then
    stats_increment "$STATS" r9_violations "$VIOLATIONS"
  fi

  if [ "$VIOLATIONS" -gt 0 ]; then
    echo "check1 R9: $VIOLATIONS violation(s) found" >&2
    return 2
  fi
  return 0
}

main "$@"
