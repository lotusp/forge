#!/usr/bin/env bash
#
# check7_inventory_truth.sh — auto-correct inventory numbers in
# artifact files using the deterministic facts registry produced by
# inject-facts.sh.
#
# v0.5.3 fact-check showed that LLMs continue to write eyeballed
# inventory numbers despite profile-level mandates to invoke the
# detectors. Examples observed across 4 real-world projects:
#
#   "40 files with route annotations"        (real: 25 @RestController)
#   "453 controller test files detected"     (real: 296 controllers, 581 tests)
#   "720 HTTP mapping annotations"           (real: 689 lines)
#   Sonar projectKey/projectName typos       (not reported)
#
# This check applies a curated list of "noun phrase => fact-id"
# mappings. For each phrase that matches a number-bearing line, it:
#   1. extracts the LLM-stated number
#   2. looks up the canonical value in facts.json
#   3. if the LLM number differs, rewrites the line to use the truth
#      and prepends an `<!-- ev:id=<fact-id> -->` anchor on the same
#      line (so future check5b passes are happy and the change is
#      auditable)
#
# Conservative match policy:
#   - phrases must be specific enough that false positives are rare
#   - tolerance: replace only when |llm - truth| / max(truth,1) > 5%
#     (small drifts are commonly approximation language; 'around 25'
#     is fine if truth is 24)
#   - lines inside `<!-- forge:preserve -->` blocks are skipped
#
# Exit code:
#   0  no corrections needed
#   1  one or more corrections applied (warning class)
#   2  facts.json missing AND target appears Java/Spring (should have
#      been generated; surface as halt so user re-runs inject-facts)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../lib" && pwd)"
# shellcheck source=../lib/stats.sh
source "$LIB_DIR/stats.sh"

CTX="${1:-.forge/context}"
STATS="${2:-$CTX/.validation-stats.json}"

# facts.json sits in the sibling _session directory.
SESSION_DIR=$(cd "$CTX" 2>/dev/null && cd ..; pwd 2>/dev/null)/_session
FACTS="$SESSION_DIR/facts.json"

CORRECTIONS=0

# Skip with message when facts file is absent — the validator
# orchestrator runs inject-facts before this check, but it's possible
# for a non-Java project (which has no detectable source/resources
# roots) to skip fact generation entirely. Don't halt; just no-op.
if [ ! -f "$FACTS" ]; then
  echo "check7: no facts.json at $FACTS — skipping (run inject-facts first to enable)" >&2
  return 0 2>/dev/null || exit 0
fi

# Look up a fact value. $1 = fact id. Echoes the integer or "" if
# absent / null.
fact_value() {
  local id="$1"
  jq -r --arg k "$id" '.facts[$k].value // empty' "$FACTS" 2>/dev/null
}

# Within-tolerance check: |a - b| / max(b, 1) <= 0.05.
within_tolerance() {
  local llm="$1" truth="$2"
  if [ "$truth" -le 0 ]; then
    [ "$llm" = "0" ] && return 0
    return 1
  fi
  local diff=$(( llm > truth ? llm - truth : truth - llm ))
  # multiply by 100, compare with 5*truth (avoid float)
  [ $((diff * 100)) -le $((truth * 5)) ]
}

# Apply one correction: $1 = file, $2 = line number, $3 = fact id,
# $4 = llm number, $5 = truth.
apply_correction() {
  local file="$1" lineno="$2" fact_id="$3" llm="$4" truth="$5"

  # Use perl to rewrite ONLY this specific line, replacing the first
  # occurrence of the LLM number with the truth and prepending the
  # ev:id anchor if not already present.
  LINENO="$lineno" FACT_ID="$fact_id" LLM="$llm" TRUTH="$truth" perl -i -pe '
    if ($. == $ENV{LINENO}) {
      my $llm_num  = $ENV{LLM};
      my $truth    = $ENV{TRUTH};
      my $fact_id  = $ENV{FACT_ID};
      my $anchor   = "<!-- ev:id=$fact_id -->";
      # Replace the first \b<llm>\b on the line with the truth.
      s/\b\Q$llm_num\E\b/$truth/;
      # Prepend the anchor if no ev:id for this fact is already on the line.
      unless (/\Q$anchor\E/) {
        s/^(\s*-\s*|\s*\|\s*|\s*\*\s*|\s*)/$1$anchor /;
      }
    }
  ' "$file"

  CORRECTIONS=$((CORRECTIONS + 1))
  echo "CORRECTED $file:$lineno  ev:id=$fact_id  $llm → $truth" >&2

  if [ -f "$STATS" ]; then
    stats_record_mutation "$STATS" check7 "$file" \
      "claim:$fact_id=$llm" "truth:$fact_id=$truth"
  fi
}

# Phrase → fact-id mapping. POSIX ERE — bash =~ does NOT support
# Perl-style \s or \b. Use [[:space:]] and explicit context tokens.
# Captures the integer in BASH_REMATCH[1].
#
# Each pattern intentionally requires a STRONG context token (the
# literal annotation name, or a clear unit phrase) so false positives
# from prose are rare.

declare -a PHRASES=(
  # rest_controllers — file count
  '([0-9]+)[[:space:]]+@RestController'
  '([0-9]+)[[:space:]]+RestController[[:space:]]+files?'
  '([0-9]+)[[:space:]]+REST[[:space:]]+controllers?'
  '([0-9]+)[[:space:]]+controller[[:space:]]+files?'
  # Approximation modifiers — LLM commonly writes "around 25 controllers"
  '(?:around|approximately|about|roughly|some|nearly)[[:space:]]+([0-9]+)[[:space:]]+(?:REST[[:space:]]+)?controller'
  '~[[:space:]]*([0-9]+)[[:space:]]+(?:REST[[:space:]]+)?controller'
)
declare -a PHRASES_FACTS=(
  rest_controllers
  rest_controllers
  rest_controllers
  rest_controllers
  rest_controllers
  rest_controllers
)

# spring_mappings — occurrence (line) count
PHRASES+=(
  '([0-9]+)[[:space:]]+@\*?Mapping[[:space:]]+annotations?'
  '([0-9]+)[[:space:]]+(HTTP[[:space:]]+)?mapping[[:space:]]+annotations?'
  '([0-9]+)[[:space:]]+route[[:space:]]+annotations?'
  '([0-9]+)\+?[[:space:]]+controller[[:space:]]+route[[:space:]]+annotations?'
  '([0-9]+)\+?[[:space:]]+HTTP[[:space:]]+route[[:space:]]+annotations?'
)
PHRASES_FACTS+=(
  spring_mappings
  spring_mappings
  spring_mappings
  spring_mappings
  spring_mappings
)

# 'files with route annotations' is best read as rest_controllers
# (the file-count fact) because "files with X" implies counting files.
PHRASES+=(
  '([0-9]+)[[:space:]]+files?[[:space:]]+with[[:space:]]+(@?[A-Za-z*]+[[:space:]]+)?(route|mapping)'
)
PHRASES_FACTS+=(
  rest_controllers
)

# flyway_migrations — file count
PHRASES+=(
  '([0-9]+)[[:space:]]+(Flyway[[:space:]]+)?migration[[:space:]]+files?'
  '([0-9]+)[[:space:]]+migrations?[[:space:]]+(in|under|applied|files?)'
)
PHRASES_FACTS+=(
  flyway_migrations
  flyway_migrations
)

# test_unit — file count
PHRASES+=(
  '([0-9]+)[[:space:]]+test[[:space:]]+(Java[[:space:]]+|JUnit[[:space:]]+)?files?'
  '([0-9]+)[[:space:]]+test[[:space:]]+files?[[:space:]]+(observed|in|co-located)'
  '([0-9]+)[[:space:]]+unit[[:space:]]+test[[:space:]]+files?'
  # Common LLM mis-phrasing: "controller test files" — observed in
  # field testing (a project wrote "453 controller test files
  # detected" under Route Inventory). Bind to test_unit since that
  # matches the actual file count.
  '([0-9]+)[[:space:]]+controller[[:space:]]+test[[:space:]]+files?'
)
PHRASES_FACTS+=(
  test_unit
  test_unit
  test_unit
  test_unit
)

# test_integration — file count
PHRASES+=(
  '([0-9]+)[[:space:]]+integration[[:space:]]+test[[:space:]]+files?'
  '([0-9]+)[[:space:]]+files?[[:space:]]+in[[:space:]]+test-integration'
  '([0-9]+)[[:space:]]+files?[[:space:]]+in[[:space:]]+integrationTest'
)
PHRASES_FACTS+=(
  test_integration
  test_integration
  test_integration
)

# jpa_entities — file count
PHRASES+=(
  '([0-9]+)[[:space:]]+@Entity'
  '([0-9]+)[[:space:]]+JPA[[:space:]]+entit(y|ies)'
  '([0-9]+)[[:space:]]+entity[[:space:]]+classes?'
)
PHRASES_FACTS+=(
  jpa_entities
  jpa_entities
  jpa_entities
)

# feign_clients — file count
PHRASES+=(
  '([0-9]+)[[:space:]]+@FeignClient'
  '([0-9]+)[[:space:]]+Feign[[:space:]]+(downstream[[:space:]]+)?(clients?|interfaces?)'
)
PHRASES_FACTS+=(
  feign_clients
  feign_clients
)

# Process one artifact file.
process_file() {
  local file="$1"
  local n=${#PHRASES[@]}
  local lineno=0
  while IFS= read -r line; do
    lineno=$((lineno + 1))
    # Skip lines inside preserve blocks (not modeled here — best-effort
    # via inline marker check; preserve-block awareness is in
    # artifact-parser but cheap to inline).
    case "$line" in
      *"<!-- forge:preserve -->"*) continue ;;
    esac

    local i=0
    while [ "$i" -lt "$n" ]; do
      local pat="${PHRASES[$i]}"
      local fact_id="${PHRASES_FACTS[$i]}"
      i=$((i + 1))

      # Match (case-insensitive) and capture the integer.
      if [[ "$line" =~ $pat ]]; then
        local llm_num="${BASH_REMATCH[1]}"
        [ -z "$llm_num" ] && continue
        local truth
        truth=$(fact_value "$fact_id")
        [ -z "$truth" ] && continue

        if ! within_tolerance "$llm_num" "$truth"; then
          apply_correction "$file" "$lineno" "$fact_id" "$llm_num" "$truth"
          break  # one correction per line
        fi
      fi
    done
  done < "$file"
}

main() {
  [ -d "$CTX" ] || { echo "no context dir at $CTX" >&2; return 0; }

  local file
  for file in "$CTX"/*.md; do
    [ -f "$file" ] || continue
    process_file "$file"
  done

  if [ -f "$STATS" ] && [ "$CORRECTIONS" -gt 0 ]; then
    stats_increment "$STATS" inventory_corrections "$CORRECTIONS"
  fi

  if [ "$CORRECTIONS" -gt 0 ]; then
    echo "check7: $CORRECTIONS inventory number(s) corrected against facts.json" >&2
    return 1
  fi
  return 0
}

main "$@"
