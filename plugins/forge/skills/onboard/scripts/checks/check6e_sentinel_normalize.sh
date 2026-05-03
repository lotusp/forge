#!/usr/bin/env bash
#
# check6e_sentinel_normalize.sh — coerce non-spec verified-commit /
# Header `> Commit:` values into the spec form before R9 runs.
#
# R9 only allows two forms for verified-commit:
#   - 7–12 hex (lowercase) commit short-hash
#   - the literal sentinel "(no-commit)"
#
# In practice, LLMs invent ad-hoc placeholders when they don't know the
# commit (or when invoked with a target path that differs from the
# shell cwd). Observed variants:
#   (none)            no-git              (no-git)            (no git)
#   no-git-000        (not a git repo)    unknown             (unknown)
#   n/a / N/A         tbd / TBD / (TBD)
#
# Without normalization these all hit R9 hard-halt in PASS 1, which
# blocks every downstream check from running. This check runs AFTER
# check4 (which resolves "(pending)") and BEFORE check1 (the strict
# regex), so PASS 1 sees a normalized value either way.
#
# Resolution policy:
#   1. Derive PROJECT_ROOT from CTX (<project>/.forge/context → ../..).
#   2. If `git -C $PROJECT_ROOT rev-parse --short HEAD` succeeds → use
#      that hash (LLM was wrong; we have the truth).
#   3. Otherwise → write "(no-commit)" (the spec sentinel).
#
# Both `verified-commit="..."` attribute values inside markers AND the
# `> Commit: <value>` line in artifact headers are normalized.
#
# Exit code:
#   0  no normalization needed
#   1  one or more values normalized (warning)
#   2  unrecoverable (project root unreachable AND git fails — should
#      not happen because (no-commit) is always available as fallback)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../lib" && pwd)"
# shellcheck source=../lib/stats.sh
source "$LIB_DIR/stats.sh"

CTX="${1:-.forge/context}"
STATS="${2:-$CTX/.validation-stats.json}"

NORMALIZED=0

# Spec form: 7–12 hex OR exact "(no-commit)".
is_spec_valid() {
  local v="$1"
  [ "$v" = "(no-commit)" ] && return 0
  if printf '%s' "$v" | grep -qE '^[a-f0-9]{7,12}$'; then return 0; fi
  return 1
}

main() {
  [ -d "$CTX" ] || { echo "no context dir at $CTX" >&2; return 0; }

  # Derive PROJECT_ROOT (one level up from .forge dir).
  local project_root="" current_head=""
  local candidate
  candidate=$(cd "$CTX" 2>/dev/null && cd ../.. 2>/dev/null && pwd) || candidate=""
  if [ -n "$candidate" ] \
     && git -C "$candidate" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    project_root="$candidate"
    current_head=$(git -C "$project_root" rev-parse --short HEAD 2>/dev/null || echo "")
  fi

  # Resolution: real HEAD if available, else spec sentinel.
  local resolved="(no-commit)"
  [ -n "$current_head" ] && resolved="$current_head"

  # Plugin version for Generator-line normalization. Same provenance as
  # header-context.sh: read .claude-plugin/plugin.json adjacent to the
  # SKILL.md ancestor of this script. Falls back to "(unknown)".
  local plugin_version=""
  local skill_root_dir
  skill_root_dir=$(cd "$SCRIPT_DIR/../.." 2>/dev/null && pwd) || skill_root_dir=""
  if [ -n "$skill_root_dir" ]; then
    local plugin_manifest="$skill_root_dir/../../.claude-plugin/plugin.json"
    if [ -f "$plugin_manifest" ]; then
      plugin_version=$(jq -r '.version // empty' "$plugin_manifest" 2>/dev/null || true)
    fi
  fi
  [ -z "$plugin_version" ] && plugin_version="(unknown)"

  local file
  for file in "$CTX"/*.md; do
    [ -f "$file" ] || continue

    # ------------------------------------------------------------
    # 1. Marker attribute: verified-commit="..."
    # ------------------------------------------------------------
    local bad_values
    bad_values=$(grep -oE 'verified-commit="[^"]*"' "$file" 2>/dev/null \
                 | sed -E 's/.*"([^"]*)"/\1/' | sort -u || true)

    local v
    while IFS= read -r v; do
      [ -z "$v" ] && continue
      if is_spec_valid "$v"; then continue; fi
      # Replace literal value with $resolved on every line.
      OLD_VAL="$v" NEW_VAL="$resolved" perl -i -pe '
        my $o = $ENV{OLD_VAL};
        my $n = $ENV{NEW_VAL};
        s|verified-commit="\Q$o\E"|verified-commit="$n"|g;
      ' "$file"
      NORMALIZED=$((NORMALIZED + 1))
      echo "NORMALIZED $file: verified-commit=\"$v\" → \"$resolved\"" >&2
      if [ -f "$STATS" ]; then
        stats_record_mutation "$STATS" check6e "$file" \
          "verified-commit=$v" "verified-commit=$resolved"
      fi
    done <<< "$bad_values"

    # ------------------------------------------------------------
    # 2. Header line: > Commit: <value>
    # ------------------------------------------------------------
    local header_value
    header_value=$(grep -E '^> Commit:' "$file" 2>/dev/null | head -1 \
                   | sed -E 's/^> Commit:[[:space:]]+//' \
                   | sed -E 's/[[:space:]]+$//' || true)
    if [ -n "$header_value" ] && ! is_spec_valid "$header_value"; then
      RESOLVED="$resolved" perl -i -pe '
        my $r = $ENV{RESOLVED};
        s|^(> Commit:[[:space:]]+).*$|$1$r|;
      ' "$file"
      NORMALIZED=$((NORMALIZED + 1))
      echo "NORMALIZED $file: > Commit: '$header_value' → '$resolved'" >&2
      if [ -f "$STATS" ]; then
        stats_record_mutation "$STATS" check6e "$file" \
          "header-commit=$header_value" "header-commit=$resolved"
      fi
    fi

    # ------------------------------------------------------------
    # 3. Generator line: > Generator: /forge:onboard (vX.Y.Z)
    # ------------------------------------------------------------
    # Field testing showed LLMs frequently fill the version from
    # prose hints ('a prior review found ...') instead of reading
    # plugin.json. Override unconditionally — the plugin manifest is
    # the single source of truth.
    if grep -qE '^> Generator:[[:space:]]+/forge:onboard' "$file" 2>/dev/null; then
      local current_gen
      current_gen=$(grep -E '^> Generator:[[:space:]]+/forge:onboard' "$file" \
                    | head -1 | sed -E 's/^> Generator:[[:space:]]+//' \
                    | sed -E 's/[[:space:]]+$//')
      local desired_gen="/forge:onboard (v${plugin_version})"
      if [ "$current_gen" != "$desired_gen" ]; then
        DESIRED="$desired_gen" perl -i -pe '
          my $d = $ENV{DESIRED};
          s|^(> Generator:[[:space:]]+).*$|$1$d|;
        ' "$file"
        NORMALIZED=$((NORMALIZED + 1))
        echo "NORMALIZED $file: > Generator: '$current_gen' → '$desired_gen'" >&2
        if [ -f "$STATS" ]; then
          stats_record_mutation "$STATS" check6e "$file" \
            "generator=$current_gen" "generator=$desired_gen"
        fi
      fi
    fi
  done

  if [ -f "$STATS" ] && [ "$NORMALIZED" -gt 0 ]; then
    stats_increment "$STATS" sentinel_normalizations "$NORMALIZED"
  fi

  if [ "$NORMALIZED" -gt 0 ]; then
    echo "check6e: $NORMALIZED sentinel value(s) normalized to '$resolved'" >&2
    return 1
  fi
  return 0
}

main "$@"
