---
name: onboard
description: |
  Generates a navigation-oriented project map for AI developers and humans
  working on an existing codebase. Adapts its output to the project's kind
  (web-backend / claude-code-plugin / monorepo / ...) by composing profile
  files from ./profiles/. Produces .forge/context/onboard.md with sections
  declared by the detected kind.

  Execution is two-stage:
    Stage 1 — detect kind, produce a frozen Execution Plan (profiles, sections,
              confidence). Halt on low confidence or unknown kind.
    Stage 2 — read-do-discard loop over profiles. Each profile is loaded,
              applied, its section written, then evicted from context.

  Supports incremental updates: later runs reconcile section markers against
  the current commit and rewrite only dirty sections, while preserving any
  user-authored content inside <!-- forge:preserve --> blocks.

  Run before /forge:calibrate. Onboard records observed facts; calibrate
  produces authoritative rules.
argument-hint: "[--regenerate | --section=<section-name> | --kind=<kind-id>]"
allowed-tools: "Read Glob Grep Bash Write"
context: fork
model: sonnet
effort: high
---

## Runtime snapshot

- Current commit: !`git rev-parse --short HEAD 2>/dev/null || echo "(not a git repo)"`
- Existing artifact: !`test -f .forge/context/onboard.md && echo "FOUND — read header for kind + last verified commit" || echo "(absent — first run)"`
- Root contents: !`ls -1 2>/dev/null | head -30`
- CLAUDE.md: !`test -f CLAUDE.md && echo "present — read fully before Step 1" || echo "absent"`
- Claude plugin marker: !`test -f .claude-plugin/plugin.json && echo "present" || echo "absent"`
- Workspace markers: !`ls pnpm-workspace.yaml turbo.json nx.json lerna.json go.work 2>/dev/null || true; grep -l '^\[workspace\]' Cargo.toml 2>/dev/null || true`
- Nested plugin manifests: !`find . -maxdepth 4 -path ./node_modules -prune -o -name 'plugin.json' -path '*/.claude-plugin/*' -print 2>/dev/null | head -5`

> Note: The kind catalogue itself is enumerated in Step 1.1 via Glob against
> this skill's own `profiles/kinds/` directory (resolved by Claude Code, not
> the user project).

---

## IRON RULES

These rules have no exceptions. A run that violates any of them must stop and
correct itself before writing the artifact.

### R1 — Two-stage hard isolation (Stage 1 ⊥ Stage 2)

Stage 1 (kind detection) MUST produce an **Execution Plan** text block
containing: `selected-kind`, `confidence`, `profiles[]`, `skipped[]`,
`output-sections[]`. Once the plan is emitted, Stage 2 MUST follow it
exactly. Stage 2 MUST NOT re-read the kind file or alter the plan.
If new evidence appears mid-Stage-2 that contradicts the plan, stop the run
and surface the contradiction — do not silently adapt.

### R2 — Single kind-file read

The selected kind file (`profiles/kinds/<kind-id>.md`) is read exactly once,
in Stage 1. Its `profiles:` list and `output-sections:` list are copied into
the Execution Plan. The kind file is then closed and not reopened.

### R3 — Low confidence halts the run

If the top kind's detection score is below **0.60**, the run MUST halt
and present the user with the top 3 candidates + their scores + the
option to force a kind via `--kind=<kind-id>`. Never proceed by guessing.

### R4 — Unknown kind halts the run

If no kind file matches any positive signal, the run MUST halt and list
the available kinds in `profiles/kinds/`, asking the user to either
re-run with `--kind=<kind-id>` or describe the project so a new kind
can be added. Do not fall back to a default kind.

### R5 — Preserve blocks are sacred

Any `<!-- forge:preserve -->...<!-- /forge:preserve -->` block in an existing
`onboard.md` MUST be carried forward verbatim, even when the enclosing
section is being rewritten, deleted due to kind drift, or renamed.
Preserve blocks always win over generated content.

### R6 — Profile outputs obey their Section Template

Each profile declares a Section Template. The generated section MUST
follow that template's structure (table shape, bullet form, confidence
tag placement). Do not merge, reorder, or invent sections not declared
by the selected kind's `output-sections:`.

### R7 — Evidence or omission, never invention

Every fact in the artifact MUST be traceable to a file path, pattern match,
or explicit user statement. When evidence is absent, omit the row/bullet.
Never write "N/A", "unknown", "TBD" — omit the line entirely.

### R8 — No source files modified

This skill is strictly read + write-to-.forge/. Do not edit project source
files, configs, or manifests. Do not run package managers or build tools.

### R9 — Artifact structural format is fixed

Both the header and every section marker MUST follow the exact formats
defined in Step 3. Specifically:

**Header** (Step 3.1) — markdown blockquote style only:

```markdown
# Project Onboard: {project-name}

> Kind:             {kind-id}
> Confidence:       {confidence}
> Generated:        {YYYY-MM-DD}
> Commit:           {short-sha}
> Generator:        /forge:onboard (v{plugin-version})
```

Do NOT wrap the header in an HTML comment (`<!-- forge:onboard header ... -->`).
The header is plain-text markdown so humans reading the file get project
identity immediately.

**Section marker** (Step 3.3) — every section marker MUST carry **all 5**
of the following attributes, in the exact order shown, with double-quoted
values:

```
<!-- forge:onboard section="<id>" profile="<profile-id>" verified-commit="<git-short>" body-signature="<16hex>" generated="<YYYY-MM-DD>" -->
```

**`verified-commit` and `body-signature` are two separate, independently
required attributes. They are NOT alternatives.** Both must be present on
every section marker. They encode different signals:

- `verified-commit` = git short-hash (7–12 hex) — Mode B's fast-skip trigger
- `body-signature` = SHA-256 first 16 hex of canonicalized body — Mode B's
  tamper-detect trigger

A marker carrying only one of them is **non-compliant** and will be
flagged as structurally broken by `/forge:inspect`.

**Examples:**

✅ Correct (5 attributes):

```
<!-- forge:onboard section="tech-stack" profile="tech-stack" verified-commit="a3f2c1d4" body-signature="9f8e7d6c5b4a3210" generated="2026-04-23" -->
```

❌ Wrong — single `verified` attribute (legacy form, deprecated):

```
<!-- forge:onboard section="tech-stack" profile="tech-stack" verified="9f8e7d6c5b4a3210" generated="2026-04-23" -->
```

❌ Wrong — missing `body-signature`:

```
<!-- forge:onboard section="tech-stack" profile="tech-stack" verified-commit="a3f2c1d4" generated="2026-04-23" -->
```

❌ Wrong — missing `verified-commit`:

```
<!-- forge:onboard section="tech-stack" profile="tech-stack" body-signature="9f8e7d6c5b4a3210" generated="2026-04-23" -->
```

**Closing marker** uses only the `section` attribute (closing markers are
positional anchors, not state carriers):

```
<!-- /forge:onboard section="<id>" -->
```

Missing attributes, changed order, unquoted values, or collapsing
`verified-commit` + `body-signature` into a single `verified=` all
violate R9 and break incremental-mode reconciliation.

### R10 — Tag system is a closed enumeration

Every fact in a section body MUST carry exactly **one confidence tag** from:

```
[high]       — source verified; fact directly observed
[medium]     — pattern observed + partial cross-verification
[low]        — single-source evidence; not cross-verified
[inferred]   — derived from directory layout / file names without file body inspection
```

A fact MAY additionally carry **one source tag** from:

```
[code]        — read from source file bodies (`.java`, `.ts`, `.go`, etc.)
[build]       — read from build manifest (`pom.xml`, `package.json`, `Cargo.toml`, `plugin.json`, `Dockerfile`, CI YAML)
[config]      — read from runtime config (`application.yml`, `.env.example`, `k8s/*.yaml`)
[readme]      — read from `README.md`, `docs/**/*.md`, `CLAUDE.md`
[cli]         — output of a shell command (`ls`, `find`, `grep`) from Runtime snapshot
```

A fact MAY additionally carry the **conflict flag** `[conflict]` to mark
contradictions between two stated facts (e.g. version in `plugin.json` vs
version in README badge).

**Tag order**: `<fact text> [confidence] [source?] [conflict?]`.
No other bracketed values are permitted. Do not invent new tags mid-run.

---

## Prerequisites

None. Onboard is the first skill in the Forge workflow.

If `.forge/context/onboard.md` already exists, show the user:

```
[forge:onboard] Existing onboard artifact found

.forge/context/onboard.md was last generated on {date} for kind {kind-id}
at commit {sha}.

Options:
  1. Incremental update  (default — reconcile section markers, rewrite dirty sections)
  2. Regenerate          (--regenerate — full rewrite, preserve blocks retained)
  3. Single section      (--section=<name> — refresh one section only)
  4. Force different kind (--kind=<kind-id> — re-detect if project type changed)
  5. View and exit

Which do you prefer?
```

---

## Process

### Overview

```
╭── Stage 1: Kind Detection ───────────────────────────────────╮
│  scan project → score each kind → pick top → emit Plan       │
│  (halts on low confidence or unknown)                        │
╰──────────────────────────────────────────────────────────────╯
                              │
                              ▼
╭── Stage 2: Read-Do-Discard Loop ─────────────────────────────╮
│  for profile in Plan.profiles:                               │
│      read profile file                                       │
│      execute Scan Patterns + Extraction Rules                │
│      write section to artifact using Section Template        │
│      discard profile from working context                    │
╰──────────────────────────────────────────────────────────────╯
                              │
                              ▼
                  Write artifact + JOURNAL entry
```

---

### Step 1 — Detect kind

**1.1 — Enumerate kinds**

Glob `profiles/kinds/*.md` in this skill's directory. For each kind file,
read its frontmatter (`kind-id`, `detection-signals.positive[]`,
`detection-signals.negative[]`, `profiles[]`, `output-sections[]`).

**1.2 — If `--kind=<kind-id>` flag is passed**

Skip detection. Load the specified kind file. Set `confidence = 1.0`
(user-forced). Proceed to 1.5.

**1.3 — Score each kind**

For each kind:
- For each positive signal: if the signal matches (file glob / grep pattern
  found), add its `weight` to the kind's score.
- For each negative signal: if the signal matches, subtract its `weight`.
- Clamp to `[0.0, 1.0]`.

Scoring hints:
- Positive signals are ORed (any match adds weight; duplicates within the
  same bucket are not double-counted).
- Use the Runtime snapshot values where possible to avoid re-scanning.
- Do not read source file bodies during scoring — this is a cheap pass
  based on file existence, manifest contents, and pattern counts.

**1.4 — Rank and decide**

Sort kinds by score descending. Let `top1`, `top2` be the two highest.

| Condition | Action |
|-----------|--------|
| `top1.score ≥ 0.60` and `(top1.score − top2.score) ≥ 0.15` | accept `top1`, proceed |
| `top1.score ≥ 0.60` and margin `< 0.15` | ambiguous — surface both to user, halt |
| `top1.score < 0.60` | R3 triggers — halt with candidate list |
| all scores `= 0` | R4 triggers — halt with unknown-kind message |

**1.5 — Emit Execution Plan**

Produce the plan as a fenced text block. This is the handoff to Stage 2.
The plan is **frozen** — Stage 2 must not modify it.

```text
[Execution Plan]
Selected kind:      <kind-id>
Display name:       <display-name>
Confidence:         <0.00–1.00>   (source: scored | user-forced)
Kind file:          profiles/kinds/<kind-id>.md

Profiles to load (in order):
  1. <path-1>
  2. <path-2>
  ...

Skipped profiles (with reason):
  - <path>  —  <reason, e.g. "no database detected">
  - ...

Output sections (in order):
  1. <Section Title 1>
  2. <Section Title 2>
  ...
```

Show the plan to the user and pause for confirmation on first-run. On
incremental mode with unchanged kind, auto-proceed.

**1.6 — Close kind file**

Once the plan is emitted, the kind file is done. Do not reopen it in
Stage 2. (R2)

---

### Step 2 — Read-do-discard loop

For each `profile` in `Plan.profiles` (in listed order):

```pseudo
loop over Plan.profiles:
  profile_doc = Read(profile.path)
  patterns    = profile_doc.scan_patterns
  rules       = profile_doc.extraction_rules
  template    = profile_doc.section_template
  tags_guide  = profile_doc.confidence_tags

  evidence = apply(patterns, project_files)     # Glob / Grep / Bash ls
  extracted = extract(rules, evidence)          # follow Extraction Rules
  section_md = render(template, extracted, tags_guide)

  append_section(artifact_buffer, section_md)

  discard(profile_doc, evidence)                # clear from working context
```

**Discard discipline (DG1 — save tokens, DG2 — long-context stability):**

After each iteration, do not keep the profile file or its raw evidence in
working memory. Only the rendered section text is retained. When starting
the next iteration, the LLM should not reference the previous profile's
internals — only the current profile's contents drive the work.

**Confidence tag application (R7 + R10):**

Every row/bullet/fact in a section carries tags per R10:

- Required: one confidence tag `[high|medium|low|inferred]`
- Optional: one source tag `[code|build|config|readme|cli]`
- Optional: conflict flag `[conflict]`

Order: `<fact> [confidence] [source?] [conflict?]`. R7 forbids untagged
facts — no row or bullet may appear without at least the confidence tag.

**Budget enforcement:**

If the extracted content for a profile would exceed its declared
`token-budget`, trim to the most important items and note the truncation
as a bullet in the `Notes` section (if loaded).

---

### Step 3 — Assemble artifact

**3.1 — Header**

Emit the artifact header:

```markdown
# Project Onboard: {project-name}

> Kind:             {kind-id}
> Confidence:       {confidence}
> Generated:        {YYYY-MM-DD}
> Commit:           {short-sha}
> Generator:        /forge:onboard (v{plugin-version})
```

**3.2 — "What This Is" section**

Always the first section. Synthesize from README.md + CLAUDE.md + top-level
directory observations. 1–2 paragraphs, non-technical audience.

**3.3 — Section markers**

Each profile-generated section is wrapped in a marker pair. R9 enforces
the exact format — in particular, `verified-commit` and `body-signature`
are **two separate, independently required attributes** (not alternatives).
Use this literal shape (substitute values, keep attribute order and quotes):

```markdown
<!-- forge:onboard section="tech-stack" profile="tech-stack" verified-commit="a3f2c1d4" body-signature="9f8e7d6c5b4a3210" generated="2026-04-22" -->

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Language | TypeScript 5.x [high] [build] |
| Runtime | Node.js 20 LTS [high] [build] |

<!-- /forge:onboard section="tech-stack" -->
```

**Attribute definitions:**

- `section` = lowercase, kebab-case, matches an entry in the kind's `output-sections`
- `profile` = source profile's `name` frontmatter (e.g. `tech-stack`, `http-api`)
- `verified-commit` = git short-hash of the commit this section was scanned
  against; used by Mode B to skip re-scanning if HEAD has not moved
  (see `reference/incremental-mode.md` I-R2a)
- `body-signature` = first 16 hex chars of `SHA-256(canonicalized_body_without_preserve_blocks)`;
  used by Mode B to detect out-of-band edits to the artifact
  (see `reference/incremental-mode.md` I-R2b)
- `generated` = ISO date (YYYY-MM-DD) when body was last written

**Closing marker** only carries the `section` attribute (closing markers
are positional anchors, not state carriers):

```markdown
<!-- /forge:onboard section="tech-stack" -->
```

**3.4 — Preserve blocks**

Inside any section body, a user may insert:

```markdown
<!-- forge:preserve -->
This content is manually maintained and must not be overwritten.
<!-- /forge:preserve -->
```

During incremental updates (see `reference/incremental-mode.md`), preserve
blocks are carried forward verbatim regardless of section rewrite status
(R5).

**3.5 — Write**

Write the assembled buffer to `.forge/context/onboard.md`, overwriting any
existing file. (Incremental mode handles the merge before this write; by
the time we reach here, the buffer already reflects the final state.)

---

### Step 4 — Append JOURNAL entry

Append one entry to `.forge/JOURNAL.md`:

```markdown
## YYYY-MM-DD — /forge:onboard
- Kind:        {kind-id} (confidence {score})
- Sections:    {N} written / {M} preserved / {K} skipped
- Profiles:    {list of profile-ids loaded}
- Mode:        {first-run | incremental | regenerate | single-section}
- Commit:      {short-sha}
- Next:        /forge:calibrate
```

---

## Run Modes

### Mode A — first-run (no existing artifact)

1. Full Stage 1 detection
2. Full Stage 2 profile pass
3. Write artifact with all sections
4. JOURNAL entry with `mode: first-run`

### Mode B — incremental (default when artifact exists)

1. Read existing artifact header to extract `kind`, `commit`, section markers
2. If current kind signals still support the recorded kind → reuse it
   (no Stage 1 rescoring). Otherwise trigger **kind drift handling**
   (see `reference/incremental-mode.md`).
3. For each section: compare `verified` hash against recomputed hash of the
   rendered content → identify dirty sections
4. Rewrite dirty sections + all sections downstream of changed profiles
5. Preserve blocks carried forward verbatim (R5)
6. JOURNAL entry with `mode: incremental`

Details of merge / diff logic live in `reference/incremental-mode.md`.
This SKILL.md defines the contract; the reference defines the algorithm.

### Mode C — regenerate (`--regenerate`)

Full Stage 1 + Stage 2, as if first-run, but preserve blocks from the
existing artifact are extracted first and re-inserted at the end.
JOURNAL entry with `mode: regenerate`.

### Mode D — single-section (`--section=<name>`)

1. Read existing artifact, locate the requested section marker
2. Read the profile that produced that section (from marker metadata)
3. Execute read-do-discard for that single profile
4. Splice the new section back into the artifact, preserving all others
5. JOURNAL entry with `mode: single-section`

**Constraint:** single-section mode cannot change the kind. For kind
changes, use `--regenerate` or `--kind=<id>`.

### Mode E — force kind (`--kind=<kind-id>`)

Equivalent to Mode A/C with user-forced kind. Bypasses detection (R3/R4
not evaluated). Confidence recorded as `1.0 (user-forced)`.

---

## Interaction Messages

All messages use `[forge:onboard]` lowercase prefix.

### Low confidence halt

```
[forge:onboard] Kind detection confidence is low

Top candidates:
  1. {kind-1}  — score {s1}
  2. {kind-2}  — score {s2}
  3. {kind-3}  — score {s3}

Minimum confidence required: 0.60.

Options:
  1. Re-run with --kind=<kind-id> to force one of the candidates
  2. Describe the project type so a new kind definition can be added
  3. Exit and inspect the signals manually

Which do you prefer?
```

### Unknown kind halt

```
[forge:onboard] No matching kind found

Available kinds:
  - web-backend         — long-running HTTP service with persistence
  - claude-code-plugin  — Claude Code skill / agent / command package
  - monorepo            — workspace coordinating multiple sub-packages

Options:
  1. Re-run with --kind=<kind-id> if one of the above fits
  2. Describe the project so a new kind definition can be added
  3. Exit

Which do you prefer?
```

### Ambiguous (margin < 0.15)

```
[forge:onboard] Two kinds scored close

  1. {kind-1}  — score {s1}
  2. {kind-2}  — score {s2}
  Margin: {diff} (required ≥ 0.15)

Signals favouring {kind-1}: {list}
Signals favouring {kind-2}: {list}

Options:
  1. Use {kind-1}
  2. Use {kind-2}
  3. Re-run with --kind=<kind-id>
  4. Exit

Which do you prefer?
```

### Kind drift detected (incremental mode)

```
[forge:onboard] Kind drift detected

Recorded kind:  {old-kind}  (at commit {old-sha})
Current signals support: {new-kind}  (confidence {score})

This usually means the project has changed significantly. Incremental
merge across kinds is not safe.

Options:
  1. Re-detect and regenerate (--regenerate with auto-detected new kind)
  2. Force previous kind (--kind={old-kind}, ignore drift)
  3. Force new kind (--kind={new-kind})
  4. Exit to investigate

Which do you prefer?
```

---

## Reference Documents

| File | Purpose |
|------|---------|
| `profiles/README.md` | Profile + kind file schema, execution contract |
| `profiles/kinds/*.md` | Kind definitions (detection signals + profile list) |
| `profiles/{category}/*.md` | Individual profile files (scan + extract + template) |
| `reference/scan-patterns.md` | Language/framework grep patterns + confidence decision tree |
| `reference/incremental-mode.md` | Incremental merge + kind drift algorithm (MUST read when in Mode B) |

---

## Constraints

- Do not modify any source file. This skill is read + write-to-.forge/ only.
- Do not read more than ~50 source files during Stage 2 total, across all
  profiles, to stay within long-context stability (DG2).
- Do not fabricate evidence (R7). If a profile cannot find signals, it
  produces an empty section body (not omitted — so the user sees the gap)
  with a single "No signals matched for this profile" note.
- Do not re-enter Stage 1 once Stage 2 has begun (R1).
- Do not reopen the selected kind file once closed (R2).
- Examples in any profile output must follow Content Hygiene (see
  `.forge/context/constraints.md` C8).
