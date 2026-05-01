#!/usr/bin/env bash
#
# Cross-platform SHA-256 helper.
#
# Dual-mode:
#   - SOURCED:  source hash.sh; then call `sha256` or `sha256_first16`
#   - EXECUTED: cat foo | hash.sh         → full 64-char hex
#               cat foo | hash.sh -16     → first 16 hex chars (body-signature)
#
# Resolves to `sha256sum` on Linux, `shasum -a 256` on macOS. Falls back
# to error+exit when neither is available (preflight should have caught
# this earlier).

set -euo pipefail

_hash_impl() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 | awk '{print $1}'
  else
    echo "ERROR: neither sha256sum nor shasum available; install one or fix PATH" >&2
    return 127
  fi
}

# SOURCED API
sha256() { _hash_impl; }
sha256_first16() { _hash_impl | cut -c1-16; }

# EXECUTED mode: stdin filter
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  case "${1:-}" in
    -16) sha256_first16 ;;
    *)   sha256 ;;
  esac
fi
