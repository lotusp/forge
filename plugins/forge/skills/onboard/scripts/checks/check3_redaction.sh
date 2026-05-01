#!/usr/bin/env bash
#
# check3_redaction.sh — R17 internal-host / secret redactor.
#
# Replaces internal-host and secret-shape strings with
# "<redacted: <category>>" in every .forge/context/*.md.
# Preserve blocks (<!-- forge:preserve --> ... <!-- /forge:preserve -->)
# are NEVER touched — they are user-controlled.
#
# Allowlisted public domains (localhost, github.com, etc.) bypass
# redaction even when matched.
#
# Implementation: each file is piped through perl, which:
#   - splits content into preserve / non-preserve segments
#   - applies tier-A and tier-B substitutions to non-preserve segments
#   - emits the redacted content to stdout
#   - emits the replacement count to stderr as "COUNT:<n>"
# Bash then captures both, compares to decide whether to overwrite.
#
# Exit code:
#   0  no redactions performed
#   1  one or more redactions performed (warning class)
#   2  reserved for future "secret unredactable" hard halt

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LIB_DIR="$(cd "$SCRIPT_DIR/../lib" && pwd)"
# shellcheck source=../lib/stats.sh
source "$LIB_DIR/stats.sh"

CTX="${1:-.forge/context}"
STATS="${2:-$CTX/.validation-stats.json}"

TOTAL_REDACTIONS=0

redact_file() {
  local file="$1"
  local tmp_out tmp_err
  tmp_out=$(mktemp)
  tmp_err=$(mktemp)

  set +e
  perl -0777 -e '
    use strict;
    my $content = do { local $/; <STDIN> };

    my $allow = qr/(localhost|127\.0\.0\.1|0\.0\.0\.0|github\.com|npmjs\.com|maven\.apache\.org|spring\.io|apache\.org|docker\.io|hub\.docker\.com|nodejs\.org|python\.org|crates\.io|rubygems\.org)/;

    my @tier_a = (
      [ qr/\b[a-z0-9-]+\.azurecr\.cn(?::\d+)?\b/,                    "<redacted: azure-acr>"        ],
      [ qr/\b[a-z0-9-]+\.azurecr\.io(?::\d+)?\b/,                    "<redacted: azure-acr>"        ],
      [ qr/\b[a-z0-9-]+\.aliyuncs\.com(?::\d+)?\b/,                  "<redacted: aliyun-host>"      ],
      [ qr/\bci\.[a-z0-9.-]+\.com(?:\.[a-z]+)?(?::\d+)?\b/,          "<redacted: internal-ci-host>" ],
      [ qr/\b[a-z0-9-]+\.execute-api\.[a-z0-9-]+\.amazonaws\.com\b/, "<redacted: aws-apigw>"        ],
    );

    # Tier B: explicit secret-shape only. We intentionally do NOT include
    # bare "token" — it collides with prose labels ("Token: foo"). Three
    # narrow keywords minimise false positives.
    my $tier_b_pattern = qr/\b((?:api[-_]?key|password|secret)\s*[:=]\s*"?)([a-zA-Z0-9_\/+=\-]{20,})/i;

    my $count = 0;
    my @segments = split /(<!-- forge:preserve -->.*?<!-- \/forge:preserve -->)/s, $content;

    for my $i (0 .. $#segments) {
      next if $segments[$i] =~ /^<!-- forge:preserve -->/;

      for my $rule (@tier_a) {
        my ($pat, $repl) = @$rule;
        $segments[$i] =~ s{$pat}{ ($& =~ /$allow/) ? $& : do { $count++; $repl } }ge;
      }

      $segments[$i] =~ s{$tier_b_pattern}{ $count++; "$1<redacted: secret>" }ge;
    }

    print join("", @segments);
    print STDERR "COUNT:$count\n";
  ' < "$file" > "$tmp_out" 2> "$tmp_err"
  local rc=$?
  set -e

  if [ "$rc" -ne 0 ]; then
    echo "ERROR: perl failed on $file (rc=$rc)" >&2
    cat "$tmp_err" >&2
    rm -f "$tmp_out" "$tmp_err"
    return 1
  fi

  local count
  count=$(grep -oE 'COUNT:[0-9]+' "$tmp_err" | head -1 | sed 's/COUNT://')
  rm -f "$tmp_err"

  if [ -z "$count" ] || [ "$count" -eq 0 ]; then
    rm -f "$tmp_out"
    return 0
  fi

  # Capture one before/after sample for audit trail
  local before_sample after_sample
  before_sample=$(diff -u "$file" "$tmp_out" 2>/dev/null | grep -E '^-[^-]' | head -1 || true)
  after_sample=$(diff -u "$file" "$tmp_out" 2>/dev/null | grep -E '^\+[^+]' | head -1 || true)

  mv "$tmp_out" "$file"
  TOTAL_REDACTIONS=$((TOTAL_REDACTIONS + count))

  if [ -f "$STATS" ]; then
    stats_record_mutation "$STATS" check3 "$file" \
      "${before_sample:-(redaction sample n/a)}" \
      "${after_sample:-(redaction sample n/a)}"
  fi
  echo "REDACTED $file: $count internal-host / secret occurrence(s)" >&2
}

main() {
  [ -d "$CTX" ] || { echo "no context dir at $CTX" >&2; return 0; }

  local file
  for file in "$CTX"/*.md; do
    [ -f "$file" ] || continue
    redact_file "$file"
  done

  if [ -f "$STATS" ] && [ "$TOTAL_REDACTIONS" -gt 0 ]; then
    stats_increment "$STATS" r17_redactions "$TOTAL_REDACTIONS"
  fi

  if [ "$TOTAL_REDACTIONS" -gt 0 ]; then
    echo "check3 R17: $TOTAL_REDACTIONS total redaction(s)" >&2
    return 1
  fi
  return 0
}

main "$@"
