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

# Find ALL build files carrying sonar config. v0.5.5: monorepos can
# have multiple subprojects each with their own sonar block; checks
# need to attest each module independently. The first entry remains
# the "primary" reported at the top level (back-compat for check8 /
# facts.json consumers); additional entries land under
# `additional_modules[]`.
BUILD_FILES=()
while IFS= read -r candidate; do
  [ -f "$candidate" ] || continue
  if grep -qE "sonar[.](projectKey|projectName)" "$candidate" 2>/dev/null; then
    BUILD_FILES+=("$candidate")
  fi
done < <(find "$ROOT" -maxdepth 4 -type f \
  \( -name 'build.gradle' -o -name 'build.gradle.kts' -o -name 'pom.xml' \) \
  -not -path '*/build/*' -not -path '*/.gradle*' \
  -print 2>/dev/null | sort)

# Fall back to the shallowest build file even without sonar config —
# we still want to report 'no sonar declaration' clearly.
if [ "${#BUILD_FILES[@]}" = 0 ]; then
  fallback=$(find "$ROOT" -maxdepth 4 -type f \
    \( -name 'build.gradle' -o -name 'build.gradle.kts' -o -name 'pom.xml' \) \
    -not -path '*/build/*' -not -path '*/.gradle*' \
    -print 2>/dev/null | head -1 || true)
  if [ -n "$fallback" ]; then
    BUILD_FILES=("$fallback")
  fi
fi

if [ "${#BUILD_FILES[@]}" = 0 ]; then
  jq -n --arg detector "sonar_field_pair" --arg root "$ROOT" \
        '{detector: $detector, root: $root, unit: "object", error: "no build file found"}'
  exit 0
fi

# The first entry is the "primary" — keep top-level fields back-compat.
BUILD_FILE="${BUILD_FILES[0]}"

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

# Build one JSON entry per build-file. The first entry's keys are
# also exposed at the top level for back-compat with check8 etc.
analyze_one() {
  local bf="$1"
  local pn pk dk dn nn nk match
  BUILD_FILE="$bf" pn=$(extract_value 'projectName')
  BUILD_FILE="$bf" pk=$(extract_value 'projectKey')
  dk=$(grep -cE "['\"]sonar\.projectKey['\"]|<sonar\.projectKey>" "$bf" 2>/dev/null || true)
  dn=$(grep -cE "['\"]sonar\.projectName['\"]|<sonar\.projectName>" "$bf" 2>/dev/null || true)
  dk=${dk:-0}; dn=${dn:-0}
  nn=$(printf '%s' "$pn" | tr ':' '-')
  nk=$(printf '%s' "$pk" | tr ':' '-')
  match=true
  if [ -z "$pn" ] || [ -z "$pk" ]; then
    match=false
  elif [ "$nn" != "$nk" ]; then
    match=false
  fi
  jq -n \
    --arg build_file "$bf" \
    --arg project_name "$pn" \
    --arg project_key "$pk" \
    --arg normalized_name "$nn" \
    --arg normalized_key "$nk" \
    --argjson match "$match" \
    --argjson key_declaration_count "$dk" \
    --argjson name_declaration_count "$dn" \
    '{build_file: $build_file,
      project_name: $project_name, project_key: $project_key,
      normalized_name: $normalized_name, normalized_key: $normalized_key,
      match: $match,
      key_declaration_count: $key_declaration_count,
      name_declaration_count: $name_declaration_count}'
}

# extract_value uses BUILD_FILE — re-bind override above is fine because
# `BUILD_FILE="..." pn=$(...)` sets it ONLY for the inner $(...).
# But we also need the original function to honour BUILD_FILE on each call.
# Re-define extract_value to accept any path — simplest: the function
# already reads `$BUILD_FILE` so prefixed-env-var binding works.

PRIMARY_JSON=$(analyze_one "$BUILD_FILE")

# Additional modules (entries 2..N).
ADDITIONAL_JSON='[]'
if [ "${#BUILD_FILES[@]}" -gt 1 ]; then
  tmp=$(mktemp)
  for ((i = 1; i < ${#BUILD_FILES[@]}; i++)); do
    analyze_one "${BUILD_FILES[$i]}" >> "$tmp"
  done
  ADDITIONAL_JSON=$(jq -s '.' "$tmp")
  rm -f "$tmp"
fi

# evidence_cmd is display-only; avoid backslash escapes that some
# jq versions choke on inside JSON strings.
EVIDENCE_CMD="grep -E 'sonar[.](projectKey|projectName)' '$BUILD_FILE'"

jq -n \
  --arg detector "sonar_field_pair" \
  --arg root "$ROOT" \
  --argjson primary "$PRIMARY_JSON" \
  --argjson additional "$ADDITIONAL_JSON" \
  --arg cmd "$EVIDENCE_CMD" \
  '{detector: $detector, root: $root, unit: "object"}
   + $primary
   + {additional_modules: $additional, evidence_cmd: $cmd}'
