#!/usr/bin/env bash
#
# check8_sonar_attestation.sh — surface Sonar configuration issues
# detected by sonar_field_pair into the artifact.
#
# v0.5.3 fact-check found that 2 of 4 real-world Java projects had a
# one-letter typo in `sonar.projectKey` ('serice' instead of 'service')
# that broke SonarQube history matching. None of the 4 onboard outputs
# reported this — sonar_field_pair detector existed but the LLM
# rarely invoked it.
#
# Strategy: read .forge/_session/facts.json (produced by inject-facts).
# When `.sonar.match == false` or `.sonar.key_declaration_count > 1`
# AND no existing prose in the artifact already mentions the issue,
# append a `[conflict]` row to the build-system / Notes section of
# onboard.md.
#
# Append-only mutation: never modifies LLM-authored prose; just adds
# a single line under the Build System or Notes heading.
#
# Exit code:
#   0  no Sonar issue OR issue already mentioned
#   1  appended a finding (warning class)
#   2  not used

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../lib" && pwd)"
# shellcheck source=../lib/stats.sh
source "$LIB_DIR/stats.sh"

CTX="${1:-.forge/context}"
STATS="${2:-$CTX/.validation-stats.json}"

SESSION_DIR=$(cd "$CTX" 2>/dev/null && cd ..; pwd 2>/dev/null)/_session
FACTS="$SESSION_DIR/facts.json"
ART="$CTX/onboard.md"

ATTESTATIONS=0

# Skip if facts or artifact missing.
if [ ! -f "$FACTS" ] || [ ! -f "$ART" ]; then
  exit 0
fi

# Read sonar verdict.
SONAR_BUILD=$(jq -r '.sonar.build_file // empty' "$FACTS")
# Use `tostring` not `// empty`: jq's `//` treats `false` as nullish
# and would drop the value, defeating the whole point of the check.
SONAR_MATCH=$(jq -r '.sonar.match | tostring'    "$FACTS" 2>/dev/null || echo "")
SONAR_NAME=$( jq -r '.sonar.project_name // empty' "$FACTS")
SONAR_KEY=$(  jq -r '.sonar.project_key  // empty' "$FACTS")
SONAR_KCNT=$( jq -r '.sonar.key_declaration_count  // 0' "$FACTS")
SONAR_NCNT=$( jq -r '.sonar.name_declaration_count // 0' "$FACTS")

# No sonar config detected at all → nothing to attest.
if [ -z "$SONAR_NAME" ] && [ -z "$SONAR_KEY" ]; then
  exit 0
fi

# Build a finding line (or skip if everything is fine).
finding=""
if [ "$SONAR_MATCH" = "false" ] && [ -n "$SONAR_NAME" ] && [ -n "$SONAR_KEY" ]; then
  finding="**Sonar projectKey/projectName mismatch** — \`projectName=\"$SONAR_NAME\"\` vs \`projectKey=\"$SONAR_KEY\"\` — likely typo; SonarQube history matching will not align if this is unintentional. [high] [conflict] [build]"
fi
if [ "$SONAR_KCNT" -gt 1 ]; then
  if [ -n "$finding" ]; then finding="$finding"$'\n'; fi
  finding="${finding}**Duplicate \`sonar.projectKey\` declaration** — \`$SONAR_KCNT\` occurrences in \`$(basename "$SONAR_BUILD")\`. SonarQube will use one of them non-deterministically. [high] [conflict] [build]"
fi
if [ "$SONAR_NCNT" -gt 1 ]; then
  if [ -n "$finding" ]; then finding="$finding"$'\n'; fi
  finding="${finding}**Duplicate \`sonar.projectName\` declaration** — \`$SONAR_NCNT\` occurrences in \`$(basename "$SONAR_BUILD")\`. [high] [conflict] [build]"
fi

[ -z "$finding" ] && { exit 0; }

# Detect whether the artifact already mentions the issue. We use a
# coarse signal: presence of the literal projectKey value in any
# existing [conflict]-tagged line. If the LLM already wrote it,
# skip — we don't double-report.
if [ -n "$SONAR_KEY" ] && grep -qF "$SONAR_KEY" "$ART" 2>/dev/null \
   && grep -qE '\[conflict\]' "$ART" 2>/dev/null; then
  # Sonar key appears AND a [conflict] tag exists somewhere — likely
  # already attested by the LLM. Conservative: don't append.
  exit 0
fi

# Append the finding under "## Notes" if present, else under
# "## Build System". Use perl for in-place insertion before the
# section closer.
if grep -qE '^## Notes\b' "$ART"; then
  HEADER="## Notes"
elif grep -qE '^## Build System\b' "$ART"; then
  HEADER="## Build System"
else
  HEADER=""
fi

if [ -z "$HEADER" ]; then
  # No suitable section — append at end of file.
  printf '\n## Sonar Configuration Findings (auto-appended by check8)\n\n%s\n' "$finding" >> "$ART"
else
  HEADER="$HEADER" FINDING="$finding" perl -i -pe '
    BEGIN { $inserted = 0 }
    if (!$inserted && /<!-- \/forge:onboard section="(notes|build-system)"/) {
      print "- " . $ENV{FINDING} . "\n\n";
      $inserted = 1;
    }
  ' "$ART"
fi

ATTESTATIONS=$((ATTESTATIONS + 1))
echo "ATTESTED $ART: appended Sonar finding under '$HEADER'" >&2

if [ -f "$STATS" ]; then
  stats_increment "$STATS" sonar_attestations 1
  stats_record_mutation "$STATS" check8 "$ART" \
    "sonar=$SONAR_KEY,$SONAR_NAME" "appended $finding"
fi

if [ "$ATTESTATIONS" -gt 0 ]; then
  exit 1
fi
exit 0
