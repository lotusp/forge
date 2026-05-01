#!/usr/bin/env bash
#
# Locates this skill's root directory (the one containing SKILL.md).
#
# Resolution order:
#   1. $SKILL_ROOT environment variable, if set and points to a SKILL.md
#      whose frontmatter declares `name: onboard`.
#   2. Walk up from the caller's BASH_SOURCE looking for an ancestor
#      directory that contains a SKILL.md whose frontmatter declares
#      `name: onboard`.
#   3. Hard fail with explicit error message and exit 1.
#
# Dual-mode:
#   - SOURCED:  source skill-root.sh; then call `find_skill_root`
#   - EXECUTED: bash skill-root.sh   → prints resolved path or exits 1

set -euo pipefail

# Extract the YAML frontmatter region (between the first two `---` lines).
# Returns empty if the file has no frontmatter.
_skill_root_extract_frontmatter() {
  local file="$1"
  awk '
    /^---[[:space:]]*$/ {
      c++
      if (c == 1) { next }
      if (c == 2) { exit }
    }
    c == 1 { print }
  ' "$file"
}

# Tests whether a directory is a forge:onboard skill root.
_skill_root_is_match() {
  local d="$1"
  [ -f "$d/SKILL.md" ] || return 1
  _skill_root_extract_frontmatter "$d/SKILL.md" \
    | grep -qE '^[[:space:]]*name:[[:space:]]*onboard[[:space:]]*$'
}

find_skill_root() {
  # Priority 1: explicit env var
  if [ -n "${SKILL_ROOT:-}" ] && _skill_root_is_match "$SKILL_ROOT"; then
    echo "$SKILL_ROOT"
    return 0
  fi

  # Priority 2: walk up from caller's BASH_SOURCE.
  # When sourced, BASH_SOURCE[1] is the caller; when executed directly,
  # BASH_SOURCE[0] is this file itself — both work for upward walk.
  local caller_file="${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}"
  local d
  d="$(cd "$(dirname "$caller_file")" && pwd)"

  while [ "$d" != "/" ]; do
    if _skill_root_is_match "$d"; then
      echo "$d"
      return 0
    fi
    d="$(dirname "$d")"
  done

  echo "ERROR: cannot locate the onboard skill root (SKILL.md ancestor)" >&2
  echo "  searched upward from: $(dirname "$caller_file")" >&2
  echo "  set SKILL_ROOT environment variable explicitly to override." >&2
  return 1
}

# Filter mode: when this file is executed directly, print resolved path.
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  find_skill_root
fi
