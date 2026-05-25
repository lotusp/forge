#!/usr/bin/env bash
#
# check7_inventory_truth.sh — strip precise inventory numbers in
# artifact files, replacing them with qualitative size words sourced
# from `.forge/_session/facts.json`.
#
# v0.5.x version of this check tried to substitute the LLM-stated
# number with a detector-supplied "truth" number. Two problems:
#   1. The LLM's number was already wrong ~50% of the time.
#   2. The detector's count is fragile against build-output noise,
#      source-set variations, and language-specific definition of
#      "what counts."
#
# v0.6 takes a different stance: we don't try to be accurate about
# counts at all. We replace numeric claims with qualitative size
# buckets ("a handful of", "many", "a large set of"), which are
# always true and unambiguously imply scale. The LLM gets concrete
# file:line samples for "what" exists; the size word answers "how
# many" without committing to a wrong number.
#
# Behaviour:
#   - For each known inventory noun phrase in the artifact, find a
#     leading integer in the same matching position.
#   - Look up the matching fact-id in facts.json. Use its
#     `.inferred_size` (one of: none / tiny / small / medium / large
#     / very-large).
#   - Rewrite `<N> <noun>` to `<size-word> <noun>` and prepend
#     `<!-- ev:id=<fact-id> -->` anchor for auditability.
#   - Idempotent: if the line already has `<!-- ev:id=<fact-id> -->`
#     and no leading integer for the matched phrase, leave it alone.
#   - Inside `<!-- forge:preserve -->` blocks: skip.
#
# Size-word mapping:
#   none       → "no"
#   tiny       → "a handful of"
#   small      → "a few"
#   medium     → "several"
#   large      → "many"
#   very-large → "a large set of"
#
# Exit code:
#   0  no rewrites needed
#   1  one or more rewrites applied (warning class)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../lib" && pwd)"
# shellcheck source=../lib/stats.sh
source "$LIB_DIR/stats.sh"

CTX="${1:-.forge/context}"
STATS="${2:-$CTX/.validation-stats.json}"

SESSION_DIR=$(cd "$CTX" 2>/dev/null && cd ..; pwd 2>/dev/null)/_session
FACTS="$SESSION_DIR/facts.json"

REWRITES=0

if [ ! -f "$FACTS" ]; then
  echo "check7: no facts.json at $FACTS — skipping (run inject-facts first)" >&2
  exit 0
fi

# Look up `.inferred_size` for a fact-id. Echoes "none" if absent.
fact_size() {
  local id="$1"
  jq -r --arg k "$id" '.facts[$k].inferred_size // "none"' "$FACTS" 2>/dev/null
}

# Size bucket → qualitative noun phrase prefix.
size_to_word() {
  case "${1:-none}" in
    none)       echo "no" ;;
    tiny)       echo "a handful of" ;;
    small)      echo "a few" ;;
    medium)     echo "several" ;;
    large)      echo "many" ;;
    very-large) echo "a large set of" ;;
    *)          echo "" ;;
  esac
}

# Apply rewrite: $1 file, $2 line#, $3 fact_id, $4 llm-number,
# $5 noun-text (literal), $6 size-word.
apply_rewrite() {
  local file="$1" lineno="$2" fact_id="$3" llm="$4" noun="$5" word="$6"
  LINENO="$lineno" FACT_ID="$fact_id" LLM="$llm" NOUN="$noun" WORD="$word" \
    perl -i -pe '
      if ($. == $ENV{LINENO}) {
        my $llm     = $ENV{LLM};
        my $fact_id = $ENV{FACT_ID};
        my $noun    = $ENV{NOUN};
        my $word    = $ENV{WORD};
        my $anchor  = "<!-- ev:id=$fact_id -->";
        # Substitute first "<llm><sep><opt-backtick><noun><opt-backtick>"
        # with "<word> <noun>". [\s`*]+ accepts space + markdown
        # ornaments (backtick, asterisk) between number and noun;
        # `?<noun>`? keeps any wrapping backticks on the noun itself.
        s/\b\Q$llm\E[\s`*]+`?\Q$noun\E`?/$word $noun/;
        # Prepend anchor unless already present.
        unless (/\Q$anchor\E/) {
          s/^(\s*[-*|]?\s*)/$1$anchor /;
        }
      }
    ' "$file"

  REWRITES=$((REWRITES + 1))
  echo "REWROTE $file:$lineno  ev:id=$fact_id  '$llm $noun' → '$word $noun'" >&2

  if [ -f "$STATS" ]; then
    stats_record_mutation "$STATS" check7 "$file" \
      "claim:$fact_id=$llm $noun" "truth:$fact_id=$word $noun"
  fi
}

# Phrase → fact-id mapping. Each entry is a POSIX ERE that captures
# the integer in BASH_REMATCH[1] and the literal noun in
# BASH_REMATCH[2] (so we know what to keep). Strong context tokens
# only — false positives from prose must be rare.
#
# (POSIX ERE — bash =~ does NOT support \s / \b. Use [[:space:]].)
# Each pattern uses `[[:space:]`*\``\*]*` as a "soft separator" so the
# number can be followed by markdown ornaments (backtick, asterisk,
# space) before the noun. Captures stay: [1] = number, [2] = noun.
declare -a PHRASES=(
  # rest_controllers ─ file count
  '([0-9]+)[[:space:]`*]+(@RestController)'
  '([0-9]+)[[:space:]`*]+(RestController[[:space:]]+files?)'
  '([0-9]+)[[:space:]`*]+(REST[[:space:]]+controllers?)'
  '([0-9]+)[[:space:]`*]+(controller[[:space:]]+files?)'

  # spring_mappings ─ occurrence count
  '([0-9]+)[[:space:]`*]+(@\*?Mapping[[:space:]]+annotations?)'
  '([0-9]+)[[:space:]`*]+(HTTP[[:space:]]+mapping[[:space:]]+annotations?)'
  '([0-9]+)[[:space:]`*]+(mapping[[:space:]]+annotations?)'
  '([0-9]+)[[:space:]`*]+(route[[:space:]]+annotations?)'
  '([0-9]+)[[:space:]`*]+(HTTP[[:space:]]+route[[:space:]]+annotations?)'

  # flyway_migrations ─ file count
  '([0-9]+)[[:space:]`*]+(Flyway[[:space:]`*]+migration[[:space:]]+files?)'
  '([0-9]+)[[:space:]`*]+(Flyway[[:space:]`*]+`\.sql`?[[:space:]]+files?)'
  '([0-9]+)[[:space:]`*]+(migration[[:space:]]+files?)'
  '([0-9]+)[[:space:]`*]+(migrations?[[:space:]]+(in|under|applied))'

  # test_unit ─ file count
  '([0-9]+)[[:space:]`*]+(test[[:space:]]+(Java[[:space:]]+|JUnit[[:space:]]+)?files?)'
  '([0-9]+)[[:space:]`*]+(unit[[:space:]]+test[[:space:]]+files?)'
  '([0-9]+)[[:space:]`*]+(controller[[:space:]]+test[[:space:]]+files?)'

  # test_integration ─ file count
  '([0-9]+)[[:space:]`*]+(integration[[:space:]]+test[[:space:]]+files?)'

  # jpa_entities ─ file count
  '([0-9]+)[[:space:]`*]+(@Entity)'
  '([0-9]+)[[:space:]`*]+(JPA[[:space:]]+entit(y|ies))'
  '([0-9]+)[[:space:]`*]+(entity[[:space:]]+classes?)'

  # feign_clients ─ file count
  '([0-9]+)[[:space:]`*]+(@FeignClient)'
  '([0-9]+)[[:space:]`*]+(Feign[[:space:]]+(downstream[[:space:]]+)?(clients?|interfaces?))'
)
declare -a PHRASE_FACTS=(
  rest_controllers rest_controllers rest_controllers rest_controllers
  spring_mappings spring_mappings spring_mappings spring_mappings spring_mappings
  flyway_migrations flyway_migrations flyway_migrations flyway_migrations
  test_unit test_unit test_unit
  test_integration
  jpa_entities jpa_entities jpa_entities
  feign_clients feign_clients
)

process_file() {
  local file="$1"
  local n=${#PHRASES[@]}
  local lineno=0
  local in_preserve=0
  while IFS= read -r line; do
    lineno=$((lineno + 1))

    case "$line" in
      *"<!-- forge:preserve -->"*)  in_preserve=1 ;;
      *"<!-- /forge:preserve -->"*) in_preserve=0; continue ;;
    esac
    [ "$in_preserve" = 1 ] && continue

    local i=0
    while [ "$i" -lt "$n" ]; do
      local pat="${PHRASES[$i]}"
      local fact_id="${PHRASE_FACTS[$i]}"
      i=$((i + 1))

      if [[ "$line" =~ $pat ]]; then
        local llm_num="${BASH_REMATCH[1]}"
        local noun="${BASH_REMATCH[2]}"
        [ -z "$llm_num" ] && continue
        [ -z "$noun" ] && continue

        local size
        size=$(fact_size "$fact_id")
        local word
        word=$(size_to_word "$size")
        [ -z "$word" ] && continue

        # If size is "none", we have no detector evidence; skip and
        # let check5b warn about the unanchored number.
        [ "$size" = "none" ] && continue

        apply_rewrite "$file" "$lineno" "$fact_id" "$llm_num" "$noun" "$word"
        break  # one rewrite per line
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

  if [ -f "$STATS" ] && [ "$REWRITES" -gt 0 ]; then
    stats_increment "$STATS" inventory_corrections "$REWRITES"
  fi

  if [ "$REWRITES" -gt 0 ]; then
    echo "check7: $REWRITES inventory number(s) stripped → size word" >&2
    return 1
  fi
  return 0
}

main "$@"
