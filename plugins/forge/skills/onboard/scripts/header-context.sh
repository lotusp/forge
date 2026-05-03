#!/usr/bin/env bash
#
# header-context.sh — produce the deterministic values the LLM is
# required to interpolate into the onboard.md / context-file headers.
#
# v0.5.2 field-test failures (downstream services) showed that prompt-only
# constraints in SKILL.md ("read plugin.json", "use git -C \$TARGET")
# are not reliably honoured by the LLM. This script computes the same
# values from disk and emits them as `KEY=VALUE` lines so the LLM can
# read once and emit verbatim, with no judgement involved.
#
# Usage:
#   header-context.sh [<target-path>]
#       <target-path> — defaults to the current working directory
#
# Output (stdout): four lines, in this order:
#   PROJECT_NAME=<inferred from package.json / pom.xml / build.gradle / dirname>
#   GENERATED=<YYYY-MM-DD, UTC>
#   COMMIT=<7-12 hex short SHA>  OR  COMMIT=(no-commit)
#   PLUGIN_VERSION=<x.y.z>       OR  PLUGIN_VERSION=(unknown)
#
# Stderr: human-readable diagnostics. Only stdout should be parsed.
#
# Exit code:
#   0  — output was produced (some fields may be sentinels)
#   2  — fatal: target path does not exist

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="${1:-.}"

if [ ! -d "$TARGET" ]; then
  echo "ERROR: target not a directory: $TARGET" >&2
  exit 2
fi
TARGET="$(cd "$TARGET" && pwd)"

# ─── PROJECT_NAME ────────────────────────────────────────────────
project_name=""
if [ -f "$TARGET/package.json" ]; then
  project_name=$(jq -r '.name // empty' "$TARGET/package.json" 2>/dev/null \
                 | head -1 || true)
fi
if [ -z "$project_name" ] && [ -f "$TARGET/pom.xml" ]; then
  project_name=$(grep -oE '<artifactId>[^<]+</artifactId>' "$TARGET/pom.xml" \
                 | head -1 | sed -E 's|</?artifactId>||g' || true)
fi
if [ -z "$project_name" ] && [ -f "$TARGET/build.gradle" ]; then
  project_name=$(grep -oE "rootProject\.name *= *['\"][^'\"]+['\"]" \
                   "$TARGET/build.gradle" "$TARGET/settings.gradle" 2>/dev/null \
                 | head -1 | sed -E "s|.*['\"]([^'\"]+)['\"]|\1|" || true)
fi
[ -z "$project_name" ] && project_name="$(basename "$TARGET")"

# ─── COMMIT ──────────────────────────────────────────────────────
commit=""
if git -C "$TARGET" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  commit=$(git -C "$TARGET" rev-parse --short HEAD 2>/dev/null || true)
fi
[ -z "$commit" ] && commit="(no-commit)"

# ─── GENERATED ───────────────────────────────────────────────────
# UTC date so artifacts produced in different timezones agree.
generated="$(date -u +%Y-%m-%d)"

# ─── PLUGIN_VERSION ──────────────────────────────────────────────
# SKILL.md lives at .../plugins/forge/skills/onboard/SKILL.md.
# plugin.json lives at .../plugins/forge/.claude-plugin/plugin.json.
plugin_version=""
plugin_root="$(cd "$SCRIPT_DIR/../../.." && pwd)"
plugin_manifest="$plugin_root/.claude-plugin/plugin.json"
if [ -f "$plugin_manifest" ]; then
  plugin_version=$(jq -r '.version // empty' "$plugin_manifest" 2>/dev/null || true)
fi
[ -z "$plugin_version" ] && plugin_version="(unknown)"

# ─── emit ────────────────────────────────────────────────────────
printf 'PROJECT_NAME=%s\n' "$project_name"
printf 'GENERATED=%s\n'    "$generated"
printf 'COMMIT=%s\n'       "$commit"
printf 'PLUGIN_VERSION=%s\n' "$plugin_version"
