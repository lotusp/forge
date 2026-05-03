#!/usr/bin/env bash
#
# Detector: sonar_field_pair
#
# Compares `sonar.projectName` and `sonar.projectKey` declared in
# build.gradle / pom.xml. Flags:
#   - typos (e.g. one drops a letter from the other after `:` ↔ `-`
#     normalization)
#   - duplicate declarations on adjacent lines
#
# A prior real-world review found a one-letter typo (`projectKey`
# silently dropped a `v` from `service`) that broke SonarQube history
# matching for the entire project. The build-system profile asked the
# LLM to perform this comparison by eye; this detector makes it
# deterministic.
#
# Output JSON:
#   { detector, root, project_name, project_key,
#     normalized_name, normalized_key,
#     match: true|false,
#     duplicate_keys: <int>, duplicate_names: <int>,
#     evidence_cmd, error? }
#
# `match` compares the values after replacing `:` with `-` (the
# convention some teams use intentionally) — so a true mismatch
# signals a likely typo, not a punctuation difference.

set -euo pipefail

ROOT="${1:-.}"

if [ ! -d "$ROOT" ]; then
  jq -n --arg detector "sonar_field_pair" --arg root "$ROOT" \
        '{detector: $detector, root: $root, unit: "object", error: "root not found"}'
  exit 0
fi

# Find the build file that actually carries sonar config. In a
# multi-module project the root build.gradle often defines the
# subprojects but the sonar block lives in one of the children.
# Strategy: scan candidate files in shallow-first order; pick the
# first one that mentions sonar.projectKey or sonar.projectName.
BUILD_FILE=""
while IFS= read -r candidate; do
  [ -f "$candidate" ] || continue
  if grep -qE "sonar[.](projectKey|projectName)" "$candidate" 2>/dev/null; then
    BUILD_FILE="$candidate"
    break
  fi
done < <(find "$ROOT" -maxdepth 4 -type f \
  \( -name 'build.gradle' -o -name 'build.gradle.kts' -o -name 'pom.xml' \) \
  -not -path '*/build/*' -not -path '*/.gradle*' \
  -print 2>/dev/null)

# Fall back to the shallowest build file even without sonar config —
# we still want to report 'no sonar declaration' clearly.
if [ -z "$BUILD_FILE" ]; then
  BUILD_FILE=$(find "$ROOT" -maxdepth 4 -type f \
    \( -name 'build.gradle' -o -name 'build.gradle.kts' -o -name 'pom.xml' \) \
    -not -path '*/build/*' -not -path '*/.gradle*' \
    -print 2>/dev/null | head -1 || true)
fi

if [ -z "$BUILD_FILE" ]; then
  jq -n --arg detector "sonar_field_pair" --arg root "$ROOT" \
        '{detector: $detector, root: $root, unit: "object", error: "no build file found"}'
  exit 0
fi

# Extract values; the property line has shape like:
#   property "sonar.projectKey", "the-key"
#   <sonar.projectKey>the-key</sonar.projectKey>
extract_value() {
  local key="$1"
  local v=""
  # Gradle Groovy: property "sonar.projectKey", "VALUE"  (Perl required
  # for inline non-greedy + capture across alternation forms reliably).
  v=$(perl -ne '
        if (/["\x27]sonar\.'"$key"'["\x27]\s*,\s*["\x27]([^"\x27]+)["\x27]/) {
          print "$1\n"; exit;
        }
      ' "$BUILD_FILE" 2>/dev/null || true)
  # Maven property form: <sonar.projectKey>VALUE</sonar.projectKey>
  if [ -z "$v" ]; then
    v=$(perl -ne '
          if (/<sonar\.'"$key"'>([^<]+)<\/sonar\.'"$key"'>/) {
            print "$1\n"; exit;
          }
        ' "$BUILD_FILE" 2>/dev/null || true)
  fi
  printf '%s' "$v"
}

PROJECT_NAME=$(extract_value 'projectName')
PROJECT_KEY=$(extract_value 'projectKey')

# Counts of declarations (>1 = duplicate).
# grep -c always prints a number; exit 1 when zero. Use `|| true`
# to swallow the exit, NOT `|| echo 0` (which appends a second line
# and makes the captured value "0\n0", invalid for jq --argjson).
DUP_KEY=$(grep -cE "['\"]sonar\.projectKey['\"]|<sonar\.projectKey>" "$BUILD_FILE" 2>/dev/null || true)
DUP_NAME=$(grep -cE "['\"]sonar\.projectName['\"]|<sonar\.projectName>" "$BUILD_FILE" 2>/dev/null || true)
DUP_KEY=${DUP_KEY:-0}
DUP_NAME=${DUP_NAME:-0}

# Normalize `:` ↔ `-` before comparing.
NORM_NAME=$(printf '%s' "$PROJECT_NAME" | tr ':' '-')
NORM_KEY=$(printf '%s' "$PROJECT_KEY"  | tr ':' '-')

MATCH=true
if [ -z "$PROJECT_NAME" ] || [ -z "$PROJECT_KEY" ]; then
  MATCH=false
elif [ "$NORM_NAME" != "$NORM_KEY" ]; then
  MATCH=false
fi

# evidence_cmd is display-only; avoid backslash escapes that some
# jq versions choke on inside JSON strings.
EVIDENCE_CMD="grep -E 'sonar[.](projectKey|projectName)' '$BUILD_FILE'"

jq -n \
  --arg detector "sonar_field_pair" \
  --arg root "$ROOT" \
  --arg build_file "$BUILD_FILE" \
  --arg project_name "$PROJECT_NAME" \
  --arg project_key "$PROJECT_KEY" \
  --arg normalized_name "$NORM_NAME" \
  --arg normalized_key "$NORM_KEY" \
  --argjson match "$MATCH" \
  --argjson key_declaration_count "${DUP_KEY:-0}" \
  --argjson name_declaration_count "${DUP_NAME:-0}" \
  --arg cmd "$EVIDENCE_CMD" \
  '{detector: $detector, root: $root, unit: "object", build_file: $build_file,
    project_name: $project_name, project_key: $project_key,
    normalized_name: $normalized_name, normalized_key: $normalized_key,
    match: $match,
    key_declaration_count: $key_declaration_count,
    name_declaration_count: $name_declaration_count,
    evidence_cmd: $cmd}'
