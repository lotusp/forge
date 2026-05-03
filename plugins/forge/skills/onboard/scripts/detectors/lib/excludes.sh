#!/usr/bin/env bash
#
# excludes.sh — shared exclusion list for count-class detectors.
#
# When a count detector is pointed at a project root instead of the
# language-specific source root, recursive grep/find can pick up
# duplicates from build outputs (build/, bin/, out/, target/),
# generated code, and vendored deps (node_modules/, vendor/). A
# field-test caught 3x inflation in flyway_migrations and 40%
# inflation in rest_controllers caused exactly by this.
#
# Sourced by detectors. Exposes:
#
#   DETECTOR_EXCLUDE_DIRS=(...)
#       The bare directory names to skip (no slashes).
#
#   detector_grep_excludes
#       Echoes a sequence of `--exclude-dir=NAME` args, one per line
#       (split into argv via mapfile in the caller).
#
#   detector_find_excludes
#       Echoes the find prune predicate as space-separated tokens:
#         ( -name X -o -name Y ... ) -prune -o
#       The caller MUST splat it directly into the `find` argv (no
#       quotes around the whole thing), then add their own match
#       predicate after.

# Directories never wanted in a "current source code" scan.
# Globs are intentional: `.gradle*` matches `.gradle`, `.gradle-local`,
# `.gradle-cache`, `.gradle-wrapper`, etc. Both grep --exclude-dir and
# find -name accept glob patterns.
DETECTOR_EXCLUDE_DIRS=(
  # JVM build outputs + Gradle/Maven local caches
  build bin out target '.gradle*' '.mvn'
  # Node.js
  node_modules dist '.next' '.nuxt'
  # Go
  vendor
  # Python
  __pycache__ '.venv' venv '.pytest_cache'
  # Generic VCS / IDE / coverage
  '.git' '.svn' '.hg' '.idea' '.vscode' coverage '.nyc_output'
)

# Print one --exclude-dir=NAME arg per line.
detector_grep_excludes() {
  local d
  for d in "${DETECTOR_EXCLUDE_DIRS[@]}"; do
    printf -- '--exclude-dir=%s\n' "$d"
  done
}

# Print the find prune predicate tokens, space-separated.
# Parens are escaped so the result can be safely passed through `eval`.
detector_find_excludes() {
  local d first=1 out='\('
  for d in "${DETECTOR_EXCLUDE_DIRS[@]}"; do
    if [ "$first" = 1 ]; then
      first=0
      out="$out -name $d"
    else
      out="$out -o -name $d"
    fi
  done
  out="$out \) -prune -o"
  printf '%s\n' "$out"
}
