#!/usr/bin/env bash
#
# Canonicalizes a section body for body-signature computation (R9 / I-R2b).
#
# Rules applied in order:
#   1. Remove all <!-- forge:preserve --> ... <!-- /forge:preserve --> blocks
#      (including the markers themselves)
#   2. Strip leading/trailing whitespace from each line
#   3. Collapse consecutive blank lines to a single blank line
#   4. Line endings stay \n (default on Unix; we don't normalize CRLF here)
#
# Dual-mode (same shape as hash.sh):
#   - SOURCED:  source canonicalize.sh; then call `canonicalize_body`
#   - EXECUTED: cat body.txt | canonicalize.sh   → canonicalized stdin

set -euo pipefail

_canonicalize_impl() {
  perl -0777 -pe 's/<!-- forge:preserve -->.*?<!-- \/forge:preserve -->//gs' \
    | sed -E 's/^[[:space:]]+|[[:space:]]+$//g' \
    | awk '
        BEGIN { blank = 0 }
        /^$/ { blank++; if (blank <= 1) print; next }
        { blank = 0; print }
      '
}

# SOURCED API
canonicalize_body() { _canonicalize_impl; }

# EXECUTED mode: stdin filter
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  _canonicalize_impl
fi
