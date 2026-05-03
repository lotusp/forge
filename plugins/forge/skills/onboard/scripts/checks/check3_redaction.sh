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

    # Order matters: the loop applies rules sequentially, so a longer
    # pattern that contains a shorter one (e.g. db-url-with-creds vs the
    # host portion inside it) MUST come first — otherwise the inner
    # match consumes the host and leaves the credentials visible.
    my @tier_a = (
      # === Composite secrets first (longest enclosing match) ===========
      # DB connection strings carrying inline credentials.
      # Format: <scheme>://<user>:<pass>@<host>...
      # Single-quote intentionally omitted from char classes to keep
      # the regex valid inside the bash single-quoted heredoc.
      [ qr/\b(?:jdbc:)?(?:postgresql|postgres|mysql|mongodb(?:\+srv)?|mariadb|redis|amqp|amqps)\:\/\/[^\s\/:@"]+:[^\s\/:@"]+@[^\s"<>]+/i,
        "<redacted: db-url-with-creds>" ],

      # === High-value short tokens =====================================
      [ qr/\bAKIA[0-9A-Z]{16}\b/,                                    "<redacted: aws-access-key>"   ],
      [ qr/\bASIA[0-9A-Z]{16}\b/,                                    "<redacted: aws-temp-key>"     ],
      [ qr/\bgh[ps]_[A-Za-z0-9]{36,}\b/,                             "<redacted: github-token>"     ],
      [ qr/\bglpat-[A-Za-z0-9_-]{20,}\b/,                            "<redacted: gitlab-token>"     ],

      # === Cloud-specific hosts ========================================
      [ qr/\b[a-z0-9-]+\.azurecr\.cn(?::\d+)?\b/,                    "<redacted: azure-acr>"        ],
      [ qr/\b[a-z0-9-]+\.azurecr\.io(?::\d+)?\b/,                    "<redacted: azure-acr>"        ],
      [ qr/\b[a-z0-9-]+\.aliyuncs\.com(?::\d+)?\b/,                  "<redacted: aliyun-host>"      ],
      [ qr/\b[a-z0-9-]+\.execute-api\.[a-z0-9-]+\.amazonaws\.com\b/, "<redacted: aws-apigw>"        ],
      [ qr/\b\d{12}\.dkr\.ecr\.[a-z0-9-]+\.amazonaws\.com\b/,        "<redacted: aws-ecr>"          ],

      # === Internal corporate hosts ====================================
      [ qr/\bci\.[a-z0-9.-]+\.com(?:\.[a-z]+)?(?::\d+)?\b/,          "<redacted: internal-ci-host>" ],
      # *.internal / *.corp / *.lan / *.intranet at TLD position.
      # Allow single label ('jenkins.internal') and multi-label.
      [ qr/\b[a-z0-9][a-z0-9-]*(?:\.[a-z0-9][a-z0-9-]*)*\.(?:internal|corp|lan|intranet)\b(?::\d+)?/i,
        "<redacted: internal-host>" ],
      # corp/internal/intranet as mid-domain label, e.g. build.corp.example.com
      [ qr/\b[a-z0-9][a-z0-9-]*\.(?:corp|internal|intranet)\.[a-z0-9][a-z0-9.-]+\b(?::\d+)?/i,
        "<redacted: internal-host>" ],
      # *.local — require hostname-shape (3+ labels) and NOT a config
      # file name like application.local.yml.
      [ qr/(?<![a-zA-Z0-9])(?!.*\.(?:yml|yaml|properties|conf|json|xml)$)[a-z0-9][a-z0-9-]*(?:\.[a-z0-9][a-z0-9-]*){2,}\.local\b(?::\d+)?/i,
        "<redacted: internal-host>" ],

      # === Private RFC1918 IP addresses ================================
      [ qr/\b10\.\d{1,3}\.\d{1,3}\.\d{1,3}(?::\d+)?\b/,              "<redacted: private-ip>"       ],
      [ qr/\b172\.(?:1[6-9]|2\d|3[01])\.\d{1,3}\.\d{1,3}(?::\d+)?\b/,"<redacted: private-ip>"       ],
      [ qr/\b192\.168\.\d{1,3}\.\d{1,3}(?::\d+)?\b/,                 "<redacted: private-ip>"       ],
    );

    # Tier B: explicit secret-shape only. We intentionally do NOT include
    # bare "token" — it collides with prose labels ("Token: foo"). The
    # set is now: api_key | password | secret | bearer-token-prefix.
    my $tier_b_pattern = qr/\b((?:api[-_]?key|password|secret)\s*[:=]\s*"?)([a-zA-Z0-9_\/+=\-]{20,})/i;

    # Bearer / Authorization tokens. Match either a JWT (starts with
    # eyJ — base64 of {"alg":...) or any non-trivial token following
    # "Bearer " / "Authorization: ". We do NOT redact the literal word
    # "Bearer" itself — only the token that follows.
    my $bearer_pattern = qr/\b(Bearer\s+|Authorization:\s*Bearer\s+)((?:eyJ[A-Za-z0-9._-]+|[A-Za-z0-9._\-=\/+]{30,}))/;

    my $count = 0;
    my @segments = split /(<!-- forge:preserve -->.*?<!-- \/forge:preserve -->)/s, $content;

    for my $i (0 .. $#segments) {
      next if $segments[$i] =~ /^<!-- forge:preserve -->/;

      for my $rule (@tier_a) {
        my ($pat, $repl) = @$rule;
        $segments[$i] =~ s{$pat}{ ($& =~ /$allow/) ? $& : do { $count++; $repl } }ge;
      }

      $segments[$i] =~ s{$tier_b_pattern}{ $count++; "$1<redacted: secret>" }ge;
      $segments[$i] =~ s{$bearer_pattern}{ $count++; "$1<redacted: bearer-token>" }ge;
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
