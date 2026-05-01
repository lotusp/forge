#!/usr/bin/env bash
#
# Stable Markdown API for forge:onboard artifacts.
#
# All Step 6.5 checks MUST use these helpers when reading or mutating
# .forge/context/*.md. Direct `sed -i` on artifact bodies is forbidden:
# it tends to break preserve blocks, mismatch markers, or corrupt
# adjacent sections.
#
# This file is intended to be `source`d by checks. No filter mode.

set -euo pipefail

# List all section IDs in a file (deduplicated, sorted).
list_sections() {
  local file="$1"
  grep -oE '<!-- forge:onboard [^>]*section="[^"]+"' "$file" 2>/dev/null \
    | sed -E 's/.*section="([^"]+)".*/\1/' \
    | sort -u
}

# Get line range "start-end" of a section (open marker line, close marker line).
# Empty output if section not found or markers unbalanced.
get_section_range() {
  local file="$1" section="$2"
  awk -v sec="$section" '
    $0 ~ "<!-- forge:onboard " && $0 ~ "section=\""sec"\"" {
      start = NR
      next
    }
    start && $0 ~ "<!-- /forge:onboard section=\""sec"\"" {
      print start "-" NR
      exit
    }
  ' "$file"
}

# Extract the section body (between markers, exclusive of marker lines).
# Returns 1 if section not found.
extract_section_body() {
  local file="$1" section="$2"
  local range
  range=$(get_section_range "$file" "$section")
  [ -z "$range" ] && return 1
  local start="${range%-*}" end="${range#*-}"
  sed -n "$((start + 1)),$((end - 1))p" "$file"
}

# Emit "start-end" for every <!-- forge:preserve --> block in the file,
# one per line. Used by mutation helpers to skip user-controlled regions.
list_preserve_ranges() {
  local file="$1"
  awk '
    /<!-- forge:preserve -->/ { start = NR; next }
    start && /<!-- \/forge:preserve -->/ {
      print start "-" NR
      start = 0
    }
  ' "$file"
}

# Read one attribute from a section's opening marker.
# Returns empty if section or attribute not found.
get_marker_attr() {
  local file="$1" section="$2" attr="$3"
  grep -oE "<!-- forge:onboard [^>]*section=\"$section\"[^>]*-->" "$file" \
    | head -1 \
    | grep -oE "$attr=\"[^\"]+\"" \
    | sed -E "s/$attr=\"([^\"]+)\"/\\1/" \
    | head -1
}

# Replace an attribute value in a section's opening marker.
# Other attributes and markers are untouched.
replace_marker_attr() {
  local file="$1" section="$2" attr="$3" newval="$4"
  perl -i -pe \
    "s|(<!-- forge:onboard [^>]*section=\"\Q$section\E\"[^>]*$attr=)\"[^\"]*\"|\${1}\"$newval\"|g" \
    "$file"
}

# Replace `old_pattern` (perl regex) with `new_text` ONLY within the
# named section AND outside any preserve block. Preserve blocks are
# user-controlled regions and must never be auto-mutated by checks.
#
# Reference implementation: per-line awk pass that tracks two range
# memberships (section / preserve) and applies gsub on eligible lines.
# Open to optimization later (per-section in-memory replace), but the
# correctness contract is what callers must rely on.
replace_in_section_only() {
  local file="$1" section="$2" old_pattern="$3" new_text="$4"

  local section_range
  section_range=$(get_section_range "$file" "$section")
  [ -z "$section_range" ] && return 1
  local sec_start="${section_range%-*}" sec_end="${section_range#*-}"

  # Newline-separated list of "start-end" preserve ranges.
  local preserve_ranges
  preserve_ranges=$(list_preserve_ranges "$file")

  local tmp
  tmp=$(mktemp)
  trap 'rm -f "$tmp"' RETURN

  awk -v sec_start="$sec_start" -v sec_end="$sec_end" \
      -v preserves="$preserve_ranges" \
      -v old="$old_pattern" -v new="$new_text" '
    BEGIN {
      n_pres = 0
      if (length(preserves) > 0) {
        n_pres = split(preserves, lines, "\n")
        for (i = 1; i <= n_pres; i++) {
          split(lines[i], rng, "-")
          pres_start[i] = rng[1] + 0
          pres_end[i]   = rng[2] + 0
        }
      }
    }
    {
      in_section  = (NR >= sec_start && NR <= sec_end)
      in_preserve = 0
      for (i = 1; i <= n_pres; i++) {
        if (NR >= pres_start[i] && NR <= pres_end[i]) {
          in_preserve = 1
          break
        }
      }
      if (in_section && !in_preserve) {
        gsub(old, new)
      }
      print
    }
  ' "$file" > "$tmp" && mv "$tmp" "$file"
}
