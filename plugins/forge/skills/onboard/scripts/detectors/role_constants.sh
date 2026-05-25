#!/usr/bin/env bash
# Detector: role_constants
# Locates ROLE_* constants — typically declared in RolePrivilege.java
# style central role registries. High counts often signal privilege
# bloat worth flagging in Notes. v0.6 schema.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/sampling.sh
source "$SCRIPT_DIR/lib/sampling.sh"

ROOT="${1:-src/main/java}"

if [ ! -d "$ROOT" ]; then
  jq -n --arg detector "role_constants" --arg root "$ROOT" \
        '{detector: $detector, root: $root,
          samples: [], inferred_size: "none",
          error: "root not found"}'
  exit 0
fi

# Match `public static final String ROLE_FOO = "..."` style declarations.
PATTERN='public[[:space:]]+static[[:space:]]+final[[:space:]]+String[[:space:]]+ROLE_'
COUNT=$(count_from_grep   "$ROOT" '*.java' "$PATTERN")
SIZE=$(inferred_size_for_count "$COUNT")
SAMPLES=$(samples_from_grep "$ROOT" '*.java' "$PATTERN" 5)

EVIDENCE_CMD="grep -rnE --include='*.java' [excl-build-outputs] 'public static final String ROLE_' -- '$ROOT' | head -5"

jq -n --arg detector "role_constants" --arg root "$ROOT" \
      --arg size "$SIZE" --argjson samples "$SAMPLES" \
      --arg cmd "$EVIDENCE_CMD" \
      '{detector: $detector, root: $root,
        samples: $samples, inferred_size: $size,
        evidence_cmd: $cmd}'
