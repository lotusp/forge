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
# This check reads .forge/_session/facts.json (produced by
# inject-facts.sh). For each kind of issue (mismatch / duplicate),
# it checks for an idempotency marker; if absent, appends a
# [conflict]-tagged finding under Notes (or Build System) and stamps
# the marker on the line so a second run is a no-op.
#
# Marker format: `<!-- check8:sonar=<kind> -->` where <kind> is one of
# `mismatch` or `duplicate`.
#
# Append-only mutation: never modifies LLM-authored prose; just adds
# one or two finding lines with the appropriate marker.
#
# Exit code:
#   0  no Sonar issue OR all issues already attested
#   1  appended one or more findings (warning class)
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

# Read sonar verdict. Use `tostring` not `// empty` because jq's `//`
# treats `false` as nullish and would drop the value.
SONAR_BUILD=$(jq -r '.sonar.build_file // empty'                  "$FACTS")
SONAR_MATCH=$(jq -r '.sonar.match | tostring'                     "$FACTS" 2>/dev/null || echo "")
SONAR_NAME=$( jq -r '.sonar.project_name // empty'                "$FACTS")
SONAR_KEY=$(  jq -r '.sonar.project_key  // empty'                "$FACTS")
SONAR_KCNT=$( jq -r '.sonar.key_declaration_count  // 0'          "$FACTS")
SONAR_NCNT=$( jq -r '.sonar.name_declaration_count // 0'          "$FACTS")

# No sonar config detected at all → nothing to attest.
if [ -z "$SONAR_NAME" ] && [ -z "$SONAR_KEY" ]; then
  exit 0
fi

# Determine which findings are needed.
need_mismatch=0
need_duplicate=0
[ "$SONAR_MATCH" = "false" ] && [ -n "$SONAR_NAME" ] && [ -n "$SONAR_KEY" ] && need_mismatch=1
[ "$SONAR_KCNT" -gt 1 ] && need_duplicate=1
[ "$SONAR_NCNT" -gt 1 ] && need_duplicate=1

# Already-attested? (marker from previous run, OR LLM-original
# same-line projectKey + [conflict] for the mismatch case).
attested_mismatch=0
attested_duplicate=0

if grep -qF '<!-- check8:sonar=mismatch -->'  "$ART" 2>/dev/null; then
  attested_mismatch=1
fi
if grep -qF '<!-- check8:sonar=duplicate -->' "$ART" 2>/dev/null; then
  attested_duplicate=1
fi
# LLM-original mismatch attestation: same-line projectKey + [conflict].
if [ "$attested_mismatch" = 0 ] && [ -n "$SONAR_KEY" ] \
   && grep -F "$SONAR_KEY" "$ART" 2>/dev/null | grep -qE '\[conflict\]'; then
  attested_mismatch=1
fi

# Compose the finding lines that still need to be appended.
findings=()
if [ "$need_mismatch" = 1 ] && [ "$attested_mismatch" = 0 ]; then
  findings+=("- <!-- check8:sonar=mismatch --> **Sonar projectKey/projectName mismatch** — \`projectName=\"$SONAR_NAME\"\` vs \`projectKey=\"$SONAR_KEY\"\` — likely typo; SonarQube history matching will not align if this is unintentional. [high] [conflict] [build]")
fi
if [ "$need_duplicate" = 1 ] && [ "$attested_duplicate" = 0 ]; then
  if [ "$SONAR_KCNT" -gt 1 ]; then
    findings+=("- <!-- check8:sonar=duplicate --> **Duplicate \`sonar.projectKey\` declaration** — \`$SONAR_KCNT\` occurrences in \`$(basename "$SONAR_BUILD")\`. SonarQube will use one of them non-deterministically. [high] [conflict] [build]")
  fi
  if [ "$SONAR_NCNT" -gt 1 ]; then
    findings+=("- <!-- check8:sonar=duplicate --> **Duplicate \`sonar.projectName\` declaration** — \`$SONAR_NCNT\` occurrences in \`$(basename "$SONAR_BUILD")\`. [high] [conflict] [build]")
  fi
fi

# Nothing to do.
if [ "${#findings[@]}" = 0 ]; then
  exit 0
fi

# Pick insertion target — prefer Notes, then Build System.
if grep -qE '<!-- /forge:onboard section="notes"' "$ART"; then
  TARGET_SECTION="notes"
elif grep -qE '<!-- /forge:onboard section="build-system"' "$ART"; then
  TARGET_SECTION="build-system"
else
  TARGET_SECTION=""
fi

if [ -z "$TARGET_SECTION" ]; then
  # No suitable section — append at end of file.
  {
    printf '\n## Sonar Configuration Findings (auto-appended by check8)\n\n'
    printf '%s\n' "${findings[@]}"
  } >> "$ART"
else
  TGT="$TARGET_SECTION" perl -i -pe '
    BEGIN {
      our @findings = ();
      while (defined(my $f = <STDIN>)) {
        chomp $f;
        push @findings, $f;
      }
    }
    if (/<!-- \/forge:onboard section="$ENV{TGT}"/ && @findings) {
      for my $f (@findings) { print "$f\n"; }
      print "\n";
      @findings = ();
    }
  ' "$ART" < <(printf '%s\n' "${findings[@]}")
fi

ATTESTATIONS=${#findings[@]}
echo "ATTESTED $ART: appended ${ATTESTATIONS} Sonar finding(s) under '$TARGET_SECTION'" >&2

if [ -f "$STATS" ]; then
  stats_increment "$STATS" sonar_attestations "$ATTESTATIONS"
  for f in "${findings[@]}"; do
    stats_record_mutation "$STATS" check8 "$ART" \
      "sonar=$SONAR_KEY,$SONAR_NAME" "appended ${f:0:80}"
  done
fi

exit 1
