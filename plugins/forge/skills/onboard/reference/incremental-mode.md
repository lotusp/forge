# Incremental Mode Reference

Detailed merge / diff / preserve algorithm for `/forge:onboard`.

This reference complements `SKILL.md`:
- **SKILL.md** defines the execution contract (what happens and in what order).
- **This file** defines the algorithms (how to compute hashes, how to reconcile
  section markers, how to handle kind drift, how preserve blocks survive).

**Read this file when running in Mode B (incremental) or Mode C (regenerate).**

---

## Scope

Governs:
- Mode B — incremental (default when artifact exists)
- Mode C — `--regenerate` (preserve blocks carried across full rewrite)
- Mode D — `--section=<name>` (single-section refresh)

Mode A (first-run) and Mode E (`--kind=<id>` forced) do not need this reference
unless an artifact already exists to merge with.

---

## IRON RULES (reference-local)

These reinforce SKILL.md's IRON RULES for the specific context of incremental
updates. Violating any of them corrupts user data.

### I-R1 — Preserve blocks are sacred (echo of SKILL.md R5)

Every `<!-- forge:preserve -->...<!-- /forge:preserve -->` block in the
existing artifact MUST be carried forward verbatim. This holds even when:

- The enclosing section is being rewritten (dirty)
- The enclosing section is being deleted (kind drift)
- The enclosing section is being renamed (kind drift)
- The surrounding text has been restructured (anchor loss)

If anchor-based re-insertion fails, the preserve block MUST be appended to
the artifact tail under a `<!-- forge:preserve orphaned=true -->` wrapper,
never discarded.

### I-R2 — Section hash is defined exactly

The `verified="<hash>"` attribute in a section marker is computed as:

```
hash = first_16_hex_chars(SHA-256(canonicalized_body_without_preserve_blocks))
```

Canonicalization rules (applied in order):
1. Remove all `<!-- forge:preserve -->...<!-- /forge:preserve -->` blocks
   (including markers themselves) from the section body
2. Strip leading/trailing whitespace from each line
3. Collapse consecutive blank lines to a single blank line
4. Normalise line endings to `\n`
5. No case normalisation (content case is meaningful)

Any deviation from this algorithm produces incompatible hashes across runs,
making every section look dirty. LLMs MUST NOT invent a different hash
scheme.

### I-R3 — Kind drift detection happens before section reconciliation

When an existing artifact is found, the **first** incremental step is to
compare the artifact's recorded kind against current project signals.
Only after kind reconciliation is resolved does the section-level diff
proceed. Running section diffs against a changed-kind artifact produces
meaningless output.

### I-R4 — Section order follows the current kind's `output-sections`

When a kind emits a new `output-sections` order (due to kind file update
or kind drift), the rewritten artifact MUST follow the new order, not the
order found in the existing artifact. Preserve blocks move with their
parent sections; orphaned sections go to the tail (I-R1).

---

## Section Marker Contract

Each profile-generated section is wrapped:

```markdown
<!-- forge:onboard section="<section-name>" profile="<profile-id>" verified="<hash>" generated="<YYYY-MM-DD>" -->

## <Section Title>

<rendered content, may contain preserve blocks>

<!-- /forge:onboard section="<section-name>" -->
```

### Attributes

| Attribute | Meaning | Set by |
|-----------|---------|--------|
| `section` | kebab-case ID matching the kind's `output-sections` entry | Stage 2 |
| `profile` | source profile's `name` frontmatter (e.g. `tech-stack`) | Stage 2 |
| `verified` | SHA-256 of canonicalized body (I-R2), first 16 hex chars | Stage 2 |
| `generated` | ISO date when body was last written (YYYY-MM-DD) | Stage 2 |

### Artifact header (kind + commit anchor)

The artifact starts with:

```markdown
# Project Onboard: <project-name>

> Kind:             <kind-id>
> Confidence:       <score>
> Generated:        <YYYY-MM-DD>
> Commit:           <short-sha>
> Generator:        /forge:onboard (v<plugin-version>)
```

Incremental runs read `Kind:` and `Commit:` from this header before any
other parsing.

---

## Mode B (Incremental) Flow

```
1. Read existing artifact → extract:
     - header.kind, header.commit, header.plugin_version
     - section markers → { section_id: (profile, verified, generated, body) }
     - all preserve blocks → { section_id: [(anchor_before, block, anchor_after)] }

2. Detect kind drift (see "Kind Drift Handling" below).
   Depending on outcome, branch to: continue | regenerate | halt-and-ask.

3. For each section in current_kind.output_sections:
     a. If section exists in artifact:
          - recompute body hash per I-R2 → current_hash
          - if current_hash == verified  → status = CLEAN
          - else                          → status = DIRTY
     b. If section does NOT exist in artifact:
          - status = NEW
     c. If kind.output_sections adds a section → NEW
        If kind.output_sections removes a section → see kind drift table

4. For each CLEAN section: skip (no profile execution).
   For each DIRTY section: execute the source profile (read-do-discard),
                           re-render, re-hash. Preserve blocks re-anchored.
   For each NEW section:   execute the source profile, write fresh.

5. Assemble the new artifact:
     - Header updated (Generated, Commit)
     - Sections in current_kind.output_sections order
     - Orphaned preserve blocks (if any) appended at tail under
       <!-- forge:preserve orphaned=true section="<old-name>" -->

6. Write .forge/context/onboard.md (overwrite).

7. Append JOURNAL entry with counts (CLEAN / DIRTY / NEW / orphaned-preserved).
```

### Announcement (beginning)

```
[forge:onboard] Incremental update

Recorded kind:    <kind-id>  (confidence <old-score>)
Current signals:  support <same-kind> (confidence <new-score>)
Last run:         <old-date> at commit <old-sha>
Current HEAD:     <new-sha> (<N> commits ahead)
Preserve blocks:  <count> found — will carry forward

Scanning <M> sections ({CLEAN: estimated skips ~<X>})
```

### Announcement (end)

```
[forge:onboard] Incremental update complete

Sections:
  clean    (skipped):          <X>
  dirty    (rewritten):        <Y>
  new      (added):            <Z>
  orphaned-preserve blocks:    <W>

Kind:            <kind-id>
Commit:          <new-sha>
Next step:       /forge:calibrate (if not yet run)
```

---

## Kind Drift Handling

**Kind drift** is when the recorded kind in an existing artifact no longer
matches the kind that current project signals would produce.

### Detection

After parsing the artifact header:

1. Extract `recorded_kind` from `Kind:` line
2. Run Stage 1 detection against current project (cheap — no source file
   bodies)
3. Compare with the decision table below

### Four-State Decision Table

| State | `recorded_kind` valid? | Top-1 current kind | Top-1 score | Action |
|-------|------------------------|--------------------|-------------|--------|
| **Stable** | yes | == recorded_kind | ≥ 0.60 | continue Mode B normally; no user prompt |
| **Confidence drop** | yes | == recorded_kind | 0.40–0.60 | continue Mode B, but annotate JOURNAL with `confidence-drop: <new-score>`; suggest `/forge:onboard --regenerate` at end |
| **Kind change** | yes | ≠ recorded_kind, score ≥ 0.60 | ≥ 0.60 | **halt** — cross-kind merge is unsafe; surface "Kind Drift" interaction message (see SKILL.md) |
| **Loss of signal** | yes | none above 0.40 | < 0.40 | **halt** — something has changed so drastically that detection failed; surface unknown-kind message with recorded kind as a candidate |

### Per-State Section Handling

When a state permits continuation, section-level handling differs:

**State: Stable**
- Sections in both (old kind ∩ new kind) `output-sections`: standard dirty/clean diff
- (old kind) has section not in (new kind): N/A — same kind
- (new kind) has section not in (old kind): N/A — same kind
- Preserve blocks: re-anchored in-place

**State: Confidence drop**
- Same as Stable (kind is still the same, just weaker signals)
- Add annotation `<!-- forge:onboard confidence-drop=<score> -->` just
  below the header
- Emit end-of-run suggestion to regenerate

**State: Kind change** (after user confirms via `--regenerate` or
`--kind=<new>`)
- Sections in (old kind ∩ new kind): dirty/clean diff proceeds
- Sections only in (old kind): **removed**, but their preserve blocks
  become orphaned (I-R1 — appended at tail)
- Sections only in (new kind): **created** by running their source profile
- `recorded_kind` in artifact header updated to `new_kind`
- JOURNAL entry records the kind change explicitly

**State: Loss of signal**
- No section work performed until user resolves (via `--kind=<id>` or
  investigation)
- Existing artifact left untouched

---

## Mode C (`--regenerate`) Flow

Mode C is a full Stage 1 + Stage 2 rewrite that **carries preserve blocks
forward**.

```
1. Read existing artifact → extract all preserve blocks with their anchors:
     { section_id: [(anchor_before, block_content, anchor_after)] }

2. Run Stage 1 detection normally (respects --kind=<id> if supplied).

3. Run Stage 2 read-do-discard loop for ALL profiles.

4. Before writing each section, re-inject its preserve blocks:
     a. Match each preserve block's (anchor_before, anchor_after) against
        the new section body
     b. Fuzzy-match the anchors:
          - exact line match → insert between
          - ≥ 80% token overlap on ±3 surrounding lines → insert between
          - otherwise → mark orphaned (I-R1)
     c. Insert between matched anchor pairs

5. Append any orphaned preserve blocks at the artifact tail:
     <!-- forge:preserve orphaned=true original-section="<old-id>" -->
     <original block content>
     <!-- /forge:preserve -->

6. Write artifact + JOURNAL entry with mode=regenerate, orphaned-count=<W>.
```

### Anchor Matching Details

Each preserve block has:
- `anchor_before` — the 1–3 non-blank lines immediately above the opening
  `<!-- forge:preserve -->` marker
- `anchor_after` — the 1–3 non-blank lines immediately below the closing
  `<!-- /forge:preserve -->` marker
- `section_id` — the section it was found in (from enclosing section marker)

Matching priority (first match wins):
1. **Strict**: both anchors match exactly in the new same-id section
2. **Loose**: both anchors match with ≥ 80% line-level similarity
3. **Anchor-before only**: only the before-anchor matches; insert below it
4. **Anchor-after only**: only the after-anchor matches; insert above it
5. **Orphan**: no match — append to tail

---

## Mode D (`--section=<name>`) Flow

Single-section refresh — lightest mode.

```
1. Validate <name> exists in current_kind.output_sections. Halt if not.

2. Read existing artifact → locate section marker for <name>.
   If section missing, treat as Mode B New-section path for that section only.

3. Read the source profile (from marker's profile= attribute).
   Execute read-do-discard for that single profile.

4. Extract preserve blocks in the old section → re-anchor into the new body
   (rules from Mode C).

5. Splice the new section back into the artifact, replacing the old block.
   All other sections untouched (their verified hashes still valid).

6. Update header's Generated date only. Commit stays the same unless all
   sections now verify against the new HEAD.

7. JOURNAL entry: mode=single-section, section=<name>.
```

Mode D **cannot change the kind**. If `--section=<name>` is passed while
kind drift is detected, halt and ask the user to `--regenerate` first.

---

## Interrupted Run Recovery

Because sections are written to a buffer and flushed once, a crashed run
leaves the old artifact intact. No partial writes. The next incremental
run starts cleanly from the unmodified artifact.

**If** a future optimisation introduces streaming writes, this section
must be updated to define recovery semantics (e.g. marker-level
self-healing via `verified=` comparison).

---

## Hash Algorithm Reference (canonical)

I-R2 above is the authoritative definition. This section is the
pseudo-code for clarity:

```pseudo
def section_hash(body: str) -> str:
    # 1. Remove preserve blocks (including markers)
    cleaned = regex_replace(
        body,
        r'<!-- forge:preserve[^>]*-->.*?<!-- /forge:preserve -->',
        '',
        flags=DOTALL,
    )
    # 2. Per-line whitespace trim
    lines = [line.strip() for line in cleaned.split('\n')]
    # 3. Collapse consecutive blank lines
    collapsed = collapse_blank_lines(lines)
    # 4. Normalise line endings
    normalised = '\n'.join(collapsed)
    # 5. SHA-256 + first 16 hex
    return sha256(normalised.encode('utf-8')).hexdigest()[:16]
```

Implementations (LLM or tool) MUST follow these steps exactly. Deviations
cause every section to appear dirty on the next run.

---

## Announce Message Catalogue

All messages use `[forge:onboard]` lowercase prefix.

### Mode B — Stable state (no drift)

See "Announcement (beginning)" and "Announcement (end)" above under Mode B.

### Mode B — Confidence drop

Add this line after the standard announcement:

```
⚠  Confidence dropped: was <old-score>, now <new-score>.
    Consider running /forge:onboard --regenerate to re-baseline.
```

### Mode B — Kind change detected

See SKILL.md → "Interaction Messages" → "Kind drift detected". This
reference does not reproduce it to avoid divergence.

### Mode B — Loss of signal

See SKILL.md → "Interaction Messages" → "Unknown kind halt". Adapt to
include the recorded kind as "previous".

---

## Future: `--dry-run` (placeholder, not MVP)

Future enhancement to preview incremental changes without writing:

```
/forge:onboard --dry-run
```

Would output:
- Sections that would be skipped (clean)
- Sections that would be rewritten (dirty) with a body diff
- Sections that would be added/removed (kind drift)
- Preserve blocks that would be re-anchored vs orphaned

Not implemented in v0.4.0. Tracked as a future capability; structure of
this reference leaves room for a dedicated `Mode F — --dry-run` section
to be added here without rewriting earlier content.

---

## What Incremental Mode Does NOT Do

- **Does not** skip the final artifact assembly pass. Every run writes
  a complete artifact, even if every section is CLEAN (timestamp updates
  still matter).
- **Does not** modify the selected kind file or any profile file. Those
  are skill-owned sources of truth.
- **Does not** rely on the skill's IRON RULES being stable across versions.
  If the skill itself upgrades (new IRON RULE, new section in a kind),
  `--regenerate` is the recommended path to re-baseline.
- **Does not** delete orphaned preserve blocks under any circumstance (I-R1).
- **Does not** merge content across kinds automatically — kind change
  requires user confirmation.
