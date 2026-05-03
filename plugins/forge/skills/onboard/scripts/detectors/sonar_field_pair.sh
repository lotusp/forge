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
        '{detector: $detector, root: $root, error: "root not found"}'
  exit 0
fi

# Find the most likely Gradle/Maven build file under ROOT.
BUILD_FILE=""
for candidate in "$ROOT/build.gradle" "$ROOT/build.gradle.kts" "$ROOT/pom.xml"; do
  [ -f "$candidate" ] && { BUILD_FILE="$candidate"; break; }
done
# Fall back to the first match within depth 4.
if [ -z "$BUILD_FILE" ]; then
  BUILD_FILE=$(find "$ROOT" -maxdepth 4 -type f \
    \( -name 'build.gradle' -o -name 'build.gradle.kts' -o -name 'pom.xml' \) \
    -print 2>/dev/null | head -1 || true)
fi

if [ -z "$BUILD_FILE" ]; then
  jq -n --arg detector "sonar_field_pair" --arg root "$ROOT" \
        '{detector: $detector, root: $root, error: "no build file found"}'
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
DUP_KEY=$(grep -cE "['\"]sonar\.projectKey['\"]|<sonar\.projectKey>" "$BUILD_FILE" 2>/dev/null || echo 0)
DUP_NAME=$(grep -cE "['\"]sonar\.projectName['\"]|<sonar\.projectName>" "$BUILD_FILE" 2>/dev/null || echo 0)

# Normalize `:` ↔ `-` before comparing.
NORM_NAME=$(printf '%s' "$PROJECT_NAME" | tr ':' '-')
NORM_KEY=$(printf '%s' "$PROJECT_KEY"  | tr ':' '-')

MATCH=true
if [ -z "$PROJECT_NAME" ] || [ -z "$PROJECT_KEY" ]; then
  MATCH=false
elif [ "$NORM_NAME" != "$NORM_KEY" ]; then
  MATCH=false
fi

EVIDENCE_CMD="grep -E 'sonar\.(projectKey|projectName)' '$BUILD_FILE'"

jq -n \
  --arg detector "sonar_field_pair" \
  --arg root "$ROOT" \
  --arg build_file "$BUILD_FILE" \
  --arg project_name "$PROJECT_NAME" \
  --arg project_key "$PROJECT_KEY" \
  --arg normalized_name "$NORM_NAME" \
  --arg normalized_key "$NORM_KEY" \
  --argjson match "$MATCH" \
  --argjson duplicate_keys "${DUP_KEY:-0}" \
  --argjson duplicate_names "${DUP_NAME:-0}" \
  --arg cmd "$EVIDENCE_CMD" \
  '{detector: $detector, root: $root, build_file: $build_file,
    project_name: $project_name, project_key: $project_key,
    normalized_name: $normalized_name, normalized_key: $normalized_key,
    match: $match,
    duplicate_keys: $duplicate_keys, duplicate_names: $duplicate_names,
    evidence_cmd: $cmd}'
