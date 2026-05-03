#!/usr/bin/env bash
# Detector: role_constants
# Counts ROLE_* constants — typically declared in RolePrivilege.java
# style central role registries. High counts (>100) often signal
# privilege bloat worth flagging in Notes.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/excludes.sh
source "$SCRIPT_DIR/lib/excludes.sh"
ROOT="${1:-src/main/java}"

if [ ! -d "$ROOT" ]; then
  jq -n --arg detector "role_constants" --arg root "$ROOT" \
        '{detector: $detector, root: $root, result: 0, error: "root not found"}'
  exit 0
fi

# Match `public static final String ROLE_FOO = "..."` style declarations.
PATTERN='public[[:space:]]+static[[:space:]]+final[[:space:]]+String[[:space:]]+ROLE_'
mapfile -t EXCLUDES < <(detector_grep_excludes)

N=$( { grep -rE --include='*.java' "${EXCLUDES[@]}" "$PATTERN" -- "$ROOT" 2>/dev/null || true; } | wc -l | tr -d ' ')
EVIDENCE_CMD="grep -rE --include='*.java' "${EXCLUDES[@]}" 'public static final String ROLE_' -- '$ROOT' | wc -l"

jq -n --arg detector "role_constants" --arg root "$ROOT" \
      --argjson result "$N" --arg cmd "$EVIDENCE_CMD" \
      '{detector: $detector, root: $root, result: $result, evidence_cmd: $cmd}'
