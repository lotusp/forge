#!/usr/bin/env bash
#
# check2a_tag_count.sh — R10 tag composition (count axis).
#
# Each line that already carries at least one confidence tag (a "fact line")
# MUST satisfy:
#   - exactly 1 confidence tag from {high, medium, low, inferred}
#   - at most 1 source tag from {code, build, config, readme, cli}
#   - at most 1 conflict flag
#
# Violations:
#   - 2+ source tags on the same line  → auto-strip extras (keep first)
#   - 2+ confidence tags on the same line → flag to stderr + stats; do
#                                            NOT auto-fix (we cannot
#                                            infer which tag was intended)
#   - 2+ conflict flags                → auto-strip extras
#
# Out of scope (handled by check2b):
#   - missing confidence tag on a line that should have one
#
# Exit code:
#   0  no violations
#   1  violations found (auto-stripped extras and/or ambiguous lines flagged)
#
# stats.json:
#   r10_count_violations += <fixed count + ambiguous flag count>
#   mutations[] += { check: "check2a", before, after }   (only for auto-fixes)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../lib" && pwd)"
# shellcheck source=../lib/stats.sh
source "$LIB_DIR/stats.sh"
# shellcheck source=../lib/artifact-parser.sh
source "$LIB_DIR/artifact-parser.sh"

CTX="${1:-.forge/context}"
STATS="${2:-$CTX/.validation-stats.json}"

VIOLATIONS=0
AMBIGUOUS_TOTAL=0

# Process one file: read each line, detect over-stacked tags, strip extras.
# Preserve blocks are skipped (user-controlled regions).
process_file() {
  local file="$1"
  local tmp_out
  tmp_out=$(mktemp)

  set +e
  perl -0777 -e '
    use strict;
    my $content = do { local $/; <STDIN> };

    my $confidence_re = qr/\[(high|medium|low|inferred)\]/;
    my $source_re     = qr/\[(code|build|config|readme|cli)\]/;
    my $conflict_re   = qr/\[(conflict)\]/;

    my $count = 0;
    my $ambiguous = 0;   # 2+ confidence tags on one line — flagged, not auto-fixed
    # Carve into preserve / non-preserve segments; only edit non-preserve.
    my @segments = split /(<!-- forge:preserve -->.*?<!-- \/forge:preserve -->)/s, $content;

    for my $i (0 .. $#segments) {
      next if $segments[$i] =~ /^<!-- forge:preserve -->/;

      my @lines = split /\n/, $segments[$i], -1;
      for my $j (0 .. $#lines) {
        my $line = $lines[$j];
        # Only process fact lines (have at least one confidence tag).
        next unless $line =~ /$confidence_re/;

        # Confidence count: 2+ on one line is ambiguous; flag but do NOT
        # auto-fix (the authors intent cannot be inferred mechanically).
        my @conf_matches = ($line =~ /$confidence_re/g);
        if (scalar(@conf_matches) > 1) {
          $ambiguous++;
          # Trim line for stderr to keep noise low
          my $preview = length($line) > 100 ? substr($line, 0, 100) . "..." : $line;
          print STDERR "AMBIGUOUS: multiple confidence tags on one line: $preview\n";
        }

        # Strip surplus source tags: keep first occurrence, drop rest.
        my $src_count = 0;
        $line =~ s{$source_re}{
          $src_count++;
          $src_count == 1 ? $& : ""
        }ge;
        if ($src_count > 1) {
          $count += ($src_count - 1);
        }

        # Strip surplus conflict flags: keep first.
        my $conflict_count = 0;
        $line =~ s{$conflict_re}{
          $conflict_count++;
          $conflict_count == 1 ? $& : ""
        }ge;
        if ($conflict_count > 1) {
          $count += ($conflict_count - 1);
        }

        # Tidy up double spaces left by stripped tags.
        $line =~ s/  +/ /g;
        $line =~ s/[[:space:]]+$//;

        $lines[$j] = $line;
      }
      $segments[$i] = join("\n", @lines);
    }

    print join("", @segments);
    print STDERR "VIOLATIONS:$count\n";
    print STDERR "AMBIGUOUS:$ambiguous\n";
  ' < "$file" > "$tmp_out" 2> >(grep -E '^(VIOLATIONS|AMBIGUOUS):' > "$tmp_out.err")
  local rc=$?
  set -e

  local count ambiguous
  count=$(grep -oE 'VIOLATIONS:[0-9]+' "$tmp_out.err" 2>/dev/null | head -1 | sed 's/VIOLATIONS://')
  ambiguous=$(grep -oE 'AMBIGUOUS:[0-9]+' "$tmp_out.err" 2>/dev/null | head -1 | sed 's/AMBIGUOUS://')

  # Surface the ambiguous lines that perl already printed to stderr.
  grep -v -E '^(VIOLATIONS|AMBIGUOUS):' "$tmp_out.err" >&2 || true
  rm -f "$tmp_out.err"

  # Track ambiguous occurrences against r10_count_violations even though
  # we don't auto-fix them (Major bug from review: contract said "flag";
  # silent acceptance was wrong).
  if [ -n "$ambiguous" ] && [ "$ambiguous" -gt 0 ]; then
    AMBIGUOUS_TOTAL=$((AMBIGUOUS_TOTAL + ambiguous))
  fi

  if [ "$rc" -ne 0 ]; then
    rm -f "$tmp_out"
    return 1
  fi

  if [ -z "$count" ] || [ "$count" -eq 0 ]; then
    rm -f "$tmp_out"
    return 0
  fi

  local before_sample after_sample
  before_sample=$(diff -u "$file" "$tmp_out" 2>/dev/null | grep -E '^-[^-]' | head -1 || true)
  after_sample=$(diff -u "$file" "$tmp_out" 2>/dev/null | grep -E '^\+[^+]' | head -1 || true)

  mv "$tmp_out" "$file"
  VIOLATIONS=$((VIOLATIONS + count))

  if [ -f "$STATS" ]; then
    stats_record_mutation "$STATS" check2a "$file" \
      "${before_sample:-(stripped extras)}" \
      "${after_sample:-(after strip)}"
  fi

  echo "STRIPPED $file: $count extra source/conflict tag(s)" >&2
}

main() {
  [ -d "$CTX" ] || { echo "no context dir at $CTX" >&2; return 0; }

  local file
  for file in "$CTX"/*.md; do
    [ -f "$file" ] || continue
    process_file "$file"
  done

  if [ -f "$STATS" ] && [ "$VIOLATIONS" -gt 0 ]; then
    stats_increment "$STATS" r10_count_violations "$VIOLATIONS"
  fi
  if [ -f "$STATS" ] && [ "$AMBIGUOUS_TOTAL" -gt 0 ]; then
    # Multiple confidence tags on a line are ambiguous; we count them
    # in r10_count_violations alongside auto-stripped violations so the
    # JOURNAL summary reflects the full R10 violation surface.
    stats_increment "$STATS" r10_count_violations "$AMBIGUOUS_TOTAL"
  fi

  local total=$((VIOLATIONS + AMBIGUOUS_TOTAL))
  if [ "$total" -gt 0 ]; then
    echo "check2a R10: $VIOLATIONS extra tag(s) stripped, $AMBIGUOUS_TOTAL ambiguous (multi-confidence) line(s) flagged" >&2
    return 1
  fi
  return 0
}

main "$@"
