#!/usr/bin/env bash
#
# check6a_cross_stage.sh — Stage 2 ↔ Stage 3 self-contradiction detector.
#
# Stages 2 and 3 are isolated by R1 (no shared working memory), so it is
# possible for the same identifier to receive contradictory framing in
# `onboard.md` (Stage 2) vs `conventions.md` / `architecture.md` /
# `constraints.md` (Stage 3).
#
# Failure mode (observed in a prior real-world review):
#   onboard.md:    `QueueTopics.ORDER` topic [high] [code]
#   constraints.md: `QueueTopics.java` is empty (0 bytes)
#
# Both can be true individually, but together the artifact reads as
# self-contradictory. This check catches the pattern.
#
# Detection:
#   - extract "subject tokens" from onboard.md (class names ending in
#     `.java` / `.ts` / `.go` / `.py`, enum-style ALL_CAPS dotted refs)
#   - if the same token appears in any context file alongside a phrase
#     like "is empty" / "0 bytes" / "does not exist" / "unverified" /
#     "is not present", and the onboard.md occurrence is tagged
#     `[high]`, downgrade `[high]` → `[medium]` and append a
#     cross-reference to the contradicting file
#
# Mutation: replace `[high]` adjacent to the contradicted token with
# `[medium]` and append a `(see <file>#<section> for empty-file caveat)`
# note.
#
# Exit code:
#   0  no contradictions found
#   1  contradictions auto-repaired (warning)
#   2  unrecoverable

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../lib" && pwd)"
# shellcheck source=../lib/stats.sh
source "$LIB_DIR/stats.sh"

CTX="${1:-.forge/context}"
STATS="${2:-$CTX/.validation-stats.json}"

REPAIRS=0

# Extract subject tokens from onboard.md and reduce them to a "base
# name" that can be searched for across files. We track:
#   - filenames: QueueTopics.java -> "QueueTopics"
#   - enum/const refs: QueueTopics.ORDER -> "QueueTopics"
#   - PascalCase identifiers (3+ chars): QueueTopics -> "QueueTopics"
# Reducing to the base name lets us match a file-form mention
# (`QueueTopics.java is empty`) against an enum-form mention
# (`QueueTopics.ORDER published`).
extract_tokens() {
  local file="$1"
  {
    # File reference: ClassName.<ext>
    grep -oE '\b[A-Z][A-Za-z0-9_]+\.(java|ts|go|py|kt|rs|cs)\b' "$file" 2>/dev/null \
      | sed -E 's/\.(java|ts|go|py|kt|rs|cs)$//' || true
    # Enum/const reference: ClassName.MEMBER (PascalCase + ALL_CAPS)
    grep -oE '\b[A-Z][A-Za-z0-9_]+\.[A-Z][A-Z0-9_]+\b' "$file" 2>/dev/null \
      | sed -E 's/\.[A-Z][A-Z0-9_]+$//' || true
  } | sort -u
}

# Pattern that indicates "this thing is broken / empty / missing".
EMPTY_PHRASE_RE='is empty|0 bytes|does not exist|not present|unverified|is missing|empty file'

main() {
  [ -d "$CTX" ] || { echo "no context dir at $CTX" >&2; return 0; }

  local onboard="$CTX/onboard.md"
  [ -f "$onboard" ] || return 0

  local tokens
  tokens=$(extract_tokens "$onboard")
  [ -z "$tokens" ] && return 0

  local context_file token
  while IFS= read -r token; do
    [ -z "$token" ] && continue

    # Search every Stage 3 context file for the contradiction pattern.
    for context_file in "$CTX"/*.md; do
      [ "$context_file" = "$onboard" ] && continue
      [ -f "$context_file" ] || continue

      # Token mentioned alongside an "is empty" phrase on the same line?
      if grep -E "$(printf '%s' "$token" | sed 's|[].[^$*\\|]|\\&|g')" "$context_file" 2>/dev/null \
           | grep -qE "$EMPTY_PHRASE_RE"; then

        # Confirm onboard.md tags this token [high]. We only act on
        # high-confidence claims; medium/low aren't false-success risks.
        if grep -E "$(printf '%s' "$token" | sed 's|[].[^$*\\|]|\\&|g')" "$onboard" \
             | grep -q '\[high\]'; then

          # Downgrade [high] → [medium] on lines that mention this token.
          # Per F9 / R14 we use perl with explicit token matching; this
          # is safer than full-file sed because we only touch lines
          # that contain this specific subject.
          local before_md after_md
          before_md=$(md5_helper "$onboard")
          local cf_basename
          cf_basename=$(basename "$context_file")

          TOKEN="$token" CF="$cf_basename" perl -i -pe '
            my $token = $ENV{TOKEN};
            my $cf    = $ENV{CF};
            my $note  = " (see $cf for empty-file caveat)";
            if (/\Q$token\E/ && /\[high\]/ && !/\(see .*for empty-file caveat\)/) {
              s/\[high\]/[medium]/;
              s/$/$note/ unless /\Q$note\E/;
            }
          ' "$onboard"

          after_md=$(md5_helper "$onboard")
          if [ "$before_md" != "$after_md" ]; then
            REPAIRS=$((REPAIRS + 1))
            echo "DOWNGRADED [high]→[medium] for token '$token' in onboard.md (cross-ref: $cf_basename)" >&2

            if [ -f "$STATS" ]; then
              stats_record_mutation "$STATS" check6a "$onboard" \
                "[high] near $token" "[medium] near $token + see $cf_basename"
            fi
          fi
        fi
      fi
    done
  done <<< "$tokens"

  if [ -f "$STATS" ] && [ "$REPAIRS" -gt 0 ]; then
    stats_increment "$STATS" consistency_repairs "$REPAIRS"
  fi

  if [ "$REPAIRS" -gt 0 ]; then
    echo "check6a: $REPAIRS cross-stage contradiction(s) auto-downgraded" >&2
    return 1
  fi
  return 0
}

# Cross-platform md5 helper (used internally only).
md5_helper() {
  if command -v md5sum >/dev/null 2>&1; then
    md5sum "$1" | awk '{print $1}'
  else
    md5 -q "$1"
  fi
}

main "$@"
