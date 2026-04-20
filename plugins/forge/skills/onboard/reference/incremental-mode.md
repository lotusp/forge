# Incremental Mode Reference

Detailed logic for `/forge:onboard` Mode B (incremental, default when
artifact exists). Also governs `--regenerate` and `--section=` modes.

## Why incremental?

A full onboard scan on a mature codebase is expensive: reading dozens of
controllers, tracing call chains, grepping event observers, and verifying
integrations can take 10+ minutes. Most of the time the codebase hasn't
changed that much since the last run — only one or two sections need to
be refreshed. Incremental mode re-verifies cheaply and rewrites only what
changed.

## Section-level state

Every section in `.forge/context/onboard.md` is wrapped in HTML comments:

```markdown
<!-- forge:onboard section=<name> verified=<commit-hash> generated=<YYYY-MM-DD> -->
## N. Section Title

...body...

<!-- /forge:onboard section=<name> -->
```

### Attributes

- **`section=<name>`** — one of the 10 canonical names
  (`project-identity`, `architecture-overview`, `codebase-structure`,
  `core-domain-objects`, `entry-points`, `integration-topology`,
  `change-navigation`, `local-development`, `known-traps`,
  `document-confidence`).
- **`verified=<short-hash>`** — the git short-hash at which the section's
  scan was last successfully run. If current `HEAD == verified`, the
  section is known-good and can be skipped entirely.
- **`generated=<YYYY-MM-DD>`** — the date the section body was last
  written. Stays the same when only `verified=` is bumped.

## Mode B (incremental) flow

```
1. Read existing .forge/context/onboard.md
2. Parse section markers → { section: (verified, generated, body) }
3. Extract all preserve blocks → { section: [preserve_blocks...] }
4. Compute current HEAD short-hash

5. For each of the 10 sections, decide one of:

   a. SKIP       — verified == current HEAD
   b. REFRESH    — verified != current HEAD, but rescan result matches body
                   → rewrite marker only (body unchanged)
   c. REWRITE    — verified != current HEAD, rescan result differs
                   → rewrite body + both attributes
   d. KEEP_HUMAN — section body is inside a preserve block
                   → carry forward untouched

6. Write sections back in order. Section-by-section to disk — interrupted
   runs leave a valid partially-updated artifact.

7. Update header `Last run:` and `Verified against commit:` lines.
8. Append Document Confidence footer with the b/c/d counts.
```

### Decision table for each section

| Section scan result vs. body | Verified == HEAD | Action |
|------------------------------|------------------|--------|
| — | yes | **SKIP** |
| Identical | no | **REFRESH** marker only |
| Differs | no | **REWRITE** body + markers |
| Covered by preserve block | — | **KEEP_HUMAN** |

### When "rescan result matches body" — cheap checks

Instead of diffing the full body text, compare **scan signatures** — a
small fingerprint per section:

| Section | Signature |
|---------|-----------|
| project-identity | Hash of README first paragraph + startup class FQN |
| architecture-overview | Hash of tech-stack versions + top-3-level package tree |
| codebase-structure | Hash of business-domain list + technical-layer list |
| core-domain-objects | Hash of `@Entity` class list + status enums |
| entry-points | Hash of controller count + listener count + job count |
| integration-topology | Hash of `@FeignClient` list + event→listener map |
| change-navigation | Hash of last 50 commit messages touching the listed layers |
| local-development | Hash of build file + config templates + task list |
| known-traps | Hash of README/build version conflicts + test base-class list |

If signature unchanged → REFRESH (cheap). If changed → full rescan +
REWRITE (expensive).

## Mode C (`--regenerate`) flow

Same as Mode A (first run) but:

1. Read existing artifact
2. Extract all preserve blocks keyed by (section name, anchor text before/after)
3. Run all scans from scratch
4. When writing each section, re-inject preserve blocks at their anchors

### Preserve-block anchoring

The skill identifies preserve-block position by the surrounding content:

```markdown
## 9. Known Traps

### Environment

- Azure CN cert must be imported...

<!-- forge:onboard:preserve -->
- **Team-added**: We also need to run `corp-vpn up` before any ./gradlew
  command or it'll hang for 30s per dep resolution.
<!-- /forge:onboard:preserve -->

### History / legacy
```

Anchor: content immediately before the opening marker (`- Azure CN
cert...`) and content immediately after the closing marker (`### History
/ legacy`). On regeneration, locate the same anchors in the new body and
insert the preserve block between them. If anchors can't be matched
(significant restructure), emit a warning and append the orphaned
preserve block to the section's tail with a comment:

```markdown
<!-- forge:onboard:preserve orphaned-during-regeneration -->
...
<!-- /forge:onboard:preserve -->
```

## Mode D (`--section=<name>`) flow

1. Validate `<name>` is one of the 10 canonical names
2. Parse existing artifact
3. Run only the scans that feed that section
4. Compute signature, decide REFRESH vs REWRITE
5. Replace that section's block (preserve blocks re-anchored as in Mode C)
6. Update header's `Last run:` line
7. Do NOT update other sections' `verified=` markers — they are still
   verified against their own hashes

## Interrupted run recovery

Because sections are written one at a time, an interrupted run produces
a partially-valid artifact where some sections have the new `verified=`
hash and some still have the old one. The next run in Mode B will:

1. See the mixed state (some sections verified at commit X, others at Y)
2. For each section still at older hash, run the normal Mode B logic
3. Resume from where the interrupted run stopped

No special recovery flag needed — `verified=` markers are self-healing.

## Announce output

Mode B announces upfront:

```
[forge:onboard] Existing artifact found
  Last run:            2026-04-10 14:32 (incremental)
  Last verified commit: abc1234
  Current HEAD:         def5678 (17 commits ahead)
  Preserve blocks:      3 found, will carry forward

Scanning 10 sections...
```

And at the end:

```
[forge:onboard] Incremental update complete

Sections:
  written   (body changed):    3  (entry-points, integration-topology, known-traps)
  refreshed (marker only):     4  (project-identity, architecture, structure, local-dev)
  skipped   (HEAD unchanged):  2  (domain-objects, change-navigation)
  preserved (human blocks):    3

Verified against commit: def5678
Open items requiring verification: 2
Next step: /forge:calibrate (if not yet run)
```

## Signature computation — implementation note

Signatures are string hashes (SHA-1 short) over canonicalized scan
results. Canonicalization:
- Sort lists alphabetically
- Strip whitespace
- Normalise case for file paths
- Drop line numbers and dates

This makes signatures stable across trivial reformatting so a section
isn't rewritten just because a file was re-indented.

## What incremental mode does NOT do

- It does **not** skip the Step 10 verification pass. Every run, even
  incremental, runs the full verification on the final artifact state.
- It does **not** rely on the skill's own IRON RULES being stable — if
  the skill itself is updated (e.g. adds a new IRON RULE), a full Mode C
  (`--regenerate`) is recommended to bring the artifact into compliance.
- It does **not** delete sections present in the artifact but missing
  from the current template. Orphaned sections get a `<!-- WARNING:
  unknown section name -->` comment and are preserved for human review.
