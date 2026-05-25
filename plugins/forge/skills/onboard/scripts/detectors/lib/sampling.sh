#!/usr/bin/env bash
#
# sampling.sh — v0.6 helpers for detector "samples + inferred size" output.
#
# v0.5.x detectors returned `{result: <count>}`. Field-testing showed
# precise counts can't be reliably produced by the LLM+script combo,
# and wrong counts are worse than no counts. v0.6 pivots: detectors
# emit a handful of canonical SAMPLES with file:line citations and a
# coarse SIZE bucket. Profiles use samples directly and write
# qualitative size words ("a large set of") instead of numbers.
#
# Provides:
#   inferred_size_for_count <n>
#     Echo the size bucket for an integer:
#       1–3      → "tiny"
#       4–10     → "small"
#       11–50    → "medium"
#       51–200   → "large"
#       201+     → "very-large"
#       0 / err  → "none"
#
#   samples_from_grep <root> <include-glob> <pattern> [n=5]
#     Run `grep -rnE --include=<glob> <excludes> <pattern> -- <root>`
#     and emit the first N matches as a compact JSON array:
#       [{file, line, snippet}, ...]
#     `file` is relative to <root> when possible; `snippet` is the
#     line content trimmed and truncated to 120 chars.
#
#   samples_from_find <root> <name-pattern> [n=5]
#     Run `find <root> [excludes] -type f -name <pattern>` and emit
#     the first N hits as:
#       [{file, line: null, snippet: null}, ...]
#     (file-only — find can't read content cheaply; line/snippet null)
#
# Both samplers honour the shared exclude list (excludes.sh).
# Output is one-line compact JSON suitable for jq --argjson.
#
# Caller pattern:
#   source "$LIB/sampling.sh"
#   size=$(inferred_size_for_count "$N")
#   samples=$(samples_from_grep "$ROOT" '*.java' '@RestController' 5)
#   jq -n --arg detector "..." \
#         --arg root "$ROOT" \
#         --arg size "$size" \
#         --argjson samples "$samples" \
#         --arg cmd "$EVIDENCE_CMD" \
#         '{detector: $detector, root: $root,
#           samples: $samples, inferred_size: $size,
#           evidence_cmd: $cmd}'

# Resolve excludes lib relative to this file.
__SAMPLING_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=excludes.sh
source "$__SAMPLING_DIR/excludes.sh"

inferred_size_for_count() {
  local n="${1:-0}"
  # Defensive: coerce non-numeric to 0.
  case "$n" in
    ''|*[!0-9]*) n=0 ;;
  esac
  if   [ "$n" -le 0 ];   then echo "none"
  elif [ "$n" -le 3 ];   then echo "tiny"
  elif [ "$n" -le 10 ];  then echo "small"
  elif [ "$n" -le 50 ];  then echo "medium"
  elif [ "$n" -le 200 ]; then echo "large"
  else                        echo "very-large"
  fi
}

# Internal: trim leading/trailing whitespace and clip to 120 chars.
__sample_trim_snippet() {
  local s="$1"
  # Trim left
  s="${s#"${s%%[![:space:]]*}"}"
  # Trim right
  s="${s%"${s##*[![:space:]]}"}"
  # Clip
  if [ "${#s}" -gt 120 ]; then
    s="${s:0:120}…"
  fi
  printf '%s' "$s"
}

samples_from_grep() {
  local root="$1"
  local include="$2"
  local pattern="$3"
  local n="${4:-5}"

  if [ ! -d "$root" ]; then
    echo "[]"
    return 0
  fi

  mapfile -t __excludes < <(detector_grep_excludes)

  # `grep -rnE` → file:line:content. We then sample N lines and use jq
  # to build the JSON array safely (no shell-quote pitfalls).
  #
  # Use `head -n $n` AFTER grep so we don't waste effort scanning more
  # than needed — but with `-r` grep walks the tree anyway, so this is
  # only a slight win. Acceptable.
  local lines
  lines=$( { grep -rnE --include="$include" "${__excludes[@]}" "$pattern" -- "$root" 2>/dev/null \
             || true; } | head -n "$n" )

  if [ -z "$lines" ]; then
    echo "[]"
    return 0
  fi

  # Build JSON via jq -nR --slurp parsing each line as "path:lineno:body".
  # We split on the first two colons only (filenames may contain colons,
  # though rarely in source trees).
  printf '%s\n' "$lines" | jq -nR --arg root "$root" '
    [ inputs
      | capture("^(?<file>[^:]+):(?<line>[0-9]+):(?<rest>.*)$")
      | .line |= tonumber
      | .snippet = (
          .rest
          | sub("^[[:space:]]+"; "")
          | sub("[[:space:]]+$"; "")
          | if length > 120 then .[0:120] + "…" else . end
        )
      | del(.rest)
      | .file = (.file | sub("^\($root)/?"; ""))
    ]
  '
}

samples_from_find() {
  local root="$1"
  local name_pattern="$2"
  local n="${3:-5}"

  if [ ! -d "$root" ]; then
    echo "[]"
    return 0
  fi

  # shellcheck disable=SC2086  # intentional word-splitting on excludes
  local excl
  excl=$(detector_find_excludes)

  local lines
  lines=$( { eval "find \"\$root\" $excl -type f -name '$name_pattern' -print" 2>/dev/null \
             || true; } | head -n "$n" )

  if [ -z "$lines" ]; then
    echo "[]"
    return 0
  fi

  printf '%s\n' "$lines" | jq -nR --arg root "$root" '
    [ inputs
      | { file: (. | sub("^\($root)/?"; "")),
          line: null,
          snippet: null }
    ]
  '
}

# Count for use alongside sampling. Wraps grep -c / find … | wc -l with
# the same exclusions, so detectors get the inferred_size bucket from
# the same scan they sample from.
count_from_grep() {
  local root="$1"
  local include="$2"
  local pattern="$3"

  if [ ! -d "$root" ]; then echo 0; return; fi
  mapfile -t __excludes < <(detector_grep_excludes)
  { grep -rlE --include="$include" "${__excludes[@]}" "$pattern" -- "$root" 2>/dev/null \
    || true; } | wc -l | tr -d ' '
}

count_from_find() {
  local root="$1"
  local name_pattern="$2"

  if [ ! -d "$root" ]; then echo 0; return; fi
  local excl
  excl=$(detector_find_excludes)
  # shellcheck disable=SC2086
  { eval "find \"\$root\" $excl -type f -name '$name_pattern' -print" 2>/dev/null \
    || true; } | wc -l | tr -d ' '
}
