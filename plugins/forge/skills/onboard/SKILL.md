---
name: onboard
description: |
  Generates a complete project context for AI developers and humans working
  on an existing codebase. Adapts its output to the project's kind
  (web-backend / web-frontend / plugin / monorepo / ...) by composing profile
  files from ./profiles/. Produces .forge/context/onboard.md AND the
  kind-applicable subset of conventions.md / testing.md / architecture.md /
  constraints.md.

  Execution is three-stage:
    Stage 1 — detect kind, produce a frozen Execution Plan (profiles, sections,
              confidence). Halt on low confidence or unknown kind.
    Stage 2 — read-do-discard loop over onboard.md profiles. Produces
              .forge/context/onboard.md with kind-appropriate sections.
    Stage 3 — scan for convention evidence across all kind-applicable
              dimensions; batch-resolve conflicts in ONE interactive step;
              smart-merge with existing context files; produce 1–4 context
              files (conventions/testing/architecture/constraints).

  Supports incremental updates: later runs reconcile section markers against
  the current commit and rewrite only dirty sections, while preserving any
  user-authored content inside <!-- forge:preserve --> blocks.

  onboard is the first skill in the forge workflow. Run it before any clarify
  or design work — downstream skills depend on its context files.
argument-hint: "[--regenerate | --section=<section-name> | --kind=<kind-id>]"
allowed-tools: "Read Glob Grep Bash Write"
context: fork
model: sonnet
effort: high
---

## Runtime snapshot

- Current commit: !`git rev-parse --short HEAD 2>/dev/null || echo "(not a git repo)"`
- Existing onboard.md: !`test -f .forge/context/onboard.md && echo "FOUND — read header for kind + last verified commit" || echo "(absent — first run)"`
- Existing context files: !`ls .forge/context/*.md 2>/dev/null | grep -v onboard.md | xargs -n1 basename 2>/dev/null || echo "(none — Stage 3 will produce from scratch)"`
- Root contents: !`ls -1 2>/dev/null | head -30`
- CLAUDE.md: !`test -f CLAUDE.md && echo "present — read fully before Step 1" || echo "absent"`
- Claude plugin marker: !`test -f .claude-plugin/plugin.json && echo "present" || echo "absent"`
- Workspace markers: !`ls pnpm-workspace.yaml turbo.json nx.json lerna.json go.work 2>/dev/null || true; grep -l '^\[workspace\]' Cargo.toml 2>/dev/null || true`
- Nested plugin manifests: !`find . -maxdepth 4 -path ./node_modules -prune -o -name 'plugin.json' -path '*/.claude-plugin/*' -print 2>/dev/null | head -5`
- Recent commit subjects: !`git log --pretty=%s -n 20 2>/dev/null || echo "(no git log)"`

> Note: The kind catalogue itself is enumerated in Step 1.1 via Glob against
> this skill's own `profiles/kinds/` directory (resolved by Claude Code, not
> the user project).

---

## IRON RULES

These rules have no exceptions. A run that violates any of them must stop and
correct itself before writing the artifact.

### R1 — Three-stage hard isolation (Stage 1 ⊥ Stage 2 ⊥ Stage 3)

The three stages run in strict order and do not cross-contaminate:

- **Stage 1** (kind detection) MUST produce an **Execution Plan** text block
  containing: `selected-kind`, `confidence`, `profiles[]`, `skipped[]`,
  `output-sections[]`, `context-kinds-file`, `context-dimensions[]`,
  `context-output-files[]`.
- **Stage 2** (onboard.md generation) follows the plan's `profiles[]`
  exactly, produces onboard.md, terminates. MUST NOT re-read the Stage-1
  kind file; MUST NOT load Stage-3 context profiles.
- **Stage 3** (context generation) loads the Stage-1 plan's
  `context-dimensions[]`, scans, batch-resolves conflicts, writes
  context files. MUST NOT re-open Stage-1 or Stage-2 artifacts for
  re-parsing.

If new evidence mid-stage contradicts the plan, stop the run and surface
the contradiction — do not silently adapt.

### R2 — Single kind-file read per stage

Two kind files exist, each read exactly once per run:

- `profiles/kinds/<kind-id>.md` (Stage 1 / Stage 2) — drives onboard.md
  section composition. Read once in Stage 1.1; `profiles:` + `output-sections:`
  copied into the Execution Plan; file closed.
- `profiles/context/kinds/<kind-id>.md` (Stage 3) — drives context-file
  composition. Read once at Stage 3.0; `dimensions-loaded:` +
  `output-files:` + `excluded-dimensions:` copied into the plan; file closed.

Neither file is reopened after its stage has consumed it.

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

Any `<!-- forge:preserve -->...<!-- /forge:preserve -->` block in any
existing forge artifact (`onboard.md`, `conventions.md`, `testing.md`,
`architecture.md`, `constraints.md`) MUST be carried forward verbatim,
even when the enclosing section is being rewritten, deleted due to kind
drift, or renamed. Preserve blocks always win over generated content.

If a block's anchor context (surrounding text) no longer exists after
regeneration, attach it to the containing section's tail with
`<!-- forge:preserve orphaned=true -->` — never delete.

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

**Header** (Step 3.1) — markdown blockquote style only. Per R13, the
`Excluded-dimensions:` line is REQUIRED (even when empty — write
`Excluded-dimensions: (none)`):

```markdown
# Project Onboard: {project-name}

> Kind:                 {kind-id}
> Confidence:           {confidence}
> Generated:            {YYYY-MM-DD}
> Commit:               {short-sha}
> Generator:            /forge:onboard (v{plugin-version})
> Excluded-dimensions:  {comma-separated list from Stage-1 plan}
```

Do NOT wrap the header in an HTML comment (`<!-- forge:onboard header ... -->`).
The header is plain-text markdown so humans reading the file get project
identity immediately.

**Section marker** (Step 3.3) — every section marker MUST carry **all 6**
of the following attributes (5 base attributes + `source-file`), in the
exact order shown, with double-quoted values:

```
<!-- forge:onboard source-file="<file>.md" section="<id>" profile="<profile-path>" verified-commit="<git-short>" body-signature="<16hex>" generated="<YYYY-MM-DD>" -->
```

**`source-file`** identifies which artifact file the section belongs to
(`onboard.md` / `conventions.md` / `testing.md` / `architecture.md` /
`constraints.md`). Required so incremental mode can route per-file.

**`verified-commit` and `body-signature` are two separate, independently
required attributes. They are NOT alternatives.** Both must be present on
every section marker. They encode different signals:

- `verified-commit` = git short-hash (7–12 hex) — Mode B's fast-skip trigger
- `body-signature` = SHA-256 first 16 hex of canonicalized body — Mode B's
  tamper-detect trigger

A marker carrying only one of them is **non-compliant** and will be
flagged as structurally broken by `/forge:inspect`.

**Examples:**

✅ Correct for onboard.md section (6 attributes):

```
<!-- forge:onboard source-file="onboard.md" section="tech-stack" profile="core/tech-stack" verified-commit="a3f2c1d4" body-signature="9f8e7d6c5b4a3210" generated="2026-04-23" -->
```

✅ Correct for context-file section (6 attributes):

```
<!-- forge:onboard source-file="conventions.md" section="error-handling" profile="context/dimensions/error-handling" verified-commit="a3f2c1d4" body-signature="7b2e8f91c5a03d46" generated="2026-04-23" -->
```

❌ Wrong — missing `source-file` attribute:

```
<!-- forge:onboard section="tech-stack" profile="core/tech-stack" verified-commit="a3f2c1d4" body-signature="9f8e7d6c5b4a3210" generated="2026-04-23" -->
```

❌ Wrong — single `verified` attribute (legacy form, deprecated):

```
<!-- forge:onboard source-file="onboard.md" section="tech-stack" profile="core/tech-stack" verified="9f8e7d6c5b4a3210" generated="2026-04-23" -->
```

❌ Wrong — missing `body-signature`:

```
<!-- forge:onboard source-file="onboard.md" section="tech-stack" profile="core/tech-stack" verified-commit="a3f2c1d4" generated="2026-04-23" -->
```

❌ Wrong — missing `verified-commit`:

```
<!-- forge:onboard source-file="onboard.md" section="tech-stack" profile="core/tech-stack" body-signature="9f8e7d6c5b4a3210" generated="2026-04-23" -->
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

### R11 — Stage 3 scan is non-interactive; conflicts are batched

Stage 3 (context scan & synthesis) MUST scan all applicable dimensions
without pausing for user input. Any convention conflict detected during
the scan is **collected** (never interactively surfaced mid-scan) and
presented to the user in a **single batch** interaction AFTER the full
scan completes. The user gives per-conflict answers in one reply; Stage 3
then synthesizes rules and writes files.

Rationale: fragment-by-fragment interaction destroys the user's flow and
the scan's atomicity. One interactive checkpoint per run is the budget.

### R12 — Do not create context files that do not apply to the kind

If the current kind's `profiles/context/kinds/<kind-id>.md` does not list
a given `output-file` (e.g. `testing.md` is absent from a library-only
kind), Stage 3 MUST NOT create that file — not even empty, not even with
an "N/A" placeholder. The file simply does not exist.

Similarly, dimensions listed under the kind's `excluded-dimensions` MUST
NOT produce any content in any context file.

### R13 — onboard.md header MUST list excluded dimensions

To compensate for R12's silent omission (readers cannot tell whether a
missing file / section was "considered and skipped" vs "forgotten"),
the onboard.md header MUST include an `Excluded-dimensions:` metadata
line enumerating which dimensions this kind deliberately skipped.

This is the only redundancy on omissions the reader gets; in return,
context files stay lean and kind-appropriate.

### R14 — Context files are smart-merged, never overwritten wholesale

If a context file already exists (from an older forge version or
user-authored content), Stage 3.4 MUST:

1. Parse existing section markers
2. Extract all `<!-- forge:preserve -->` blocks (sacred — always carried
   forward verbatim, per R5)
3. Map existing sections to current kind's dimensions:
   - Matched dimension → rewrite section body with fresh scan results;
     preserve blocks re-anchored
   - Orphaned section (dimension removed or kind drift) → move content
     to a `## Legacy Notes` appendix at file's end; do NOT delete
4. Write the merged file

Wholesale overwrite without merge is a data-loss bug.

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
│  (halts on low confidence or unknown; plan names BOTH the    │
│   onboard.md profiles AND the context dimensions to load)    │
╰──────────────────────────────────────────────────────────────╯
                              │
                              ▼
╭── Stage 2: onboard.md generation (read-do-discard) ──────────╮
│  for profile in Plan.profiles:                               │
│      read profile file                                       │
│      execute Scan Patterns + Extraction Rules                │
│      write section to onboard.md using Section Template      │
│      discard profile from working context                    │
│  → writes .forge/context/onboard.md                          │
╰──────────────────────────────────────────────────────────────╯
                              │
                              ▼
╭── Stage 3: context generation (scan + conflicts + merge) ────╮
│  3.1 non-interactive scan                                    │
│      for dim in Plan.context-dimensions:                     │
│          read dim file; run Scan Patterns; collect evidence  │
│          detect conflicts → append to batch list             │
│  3.2 batch conflict resolution (ONE interactive checkpoint)  │
│      present all conflicts → user gives per-conflict answers │
│  3.3 smart-merge with existing context files                 │
│      for each Plan.context-output-files:                     │
│          read existing file (if any); extract preserve blocks│
│          synthesize rules from resolved evidence             │
│          merge: matched sections rewritten, orphans → Legacy │
│          preserve blocks re-anchored verbatim                │
│  3.4 write context files (only those kind-applicable)        │
│      → writes .forge/context/{conventions,testing,...}.md    │
╰──────────────────────────────────────────────────────────────╯
                              │
                              ▼
                       Append JOURNAL entry
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

**1.5 — Read Stage-3 kind file**

Also read `profiles/context/kinds/<kind-id>.md` (the context-side kind
file). Extract:

- `dimensions-loaded` (grouped by output-file: conventions / testing /
  architecture / constraints)
- `output-files` (the kind-applicable subset — files not in this list
  will NOT be created per R12)
- `excluded-dimensions` (for the onboard.md header's `Excluded-dimensions:`
  line per R13)

Close the file. Per R2, Stage 3 will load the individual dimension files
but will not reopen the context kind file.

**1.6 — Emit Execution Plan**

Produce the plan as a fenced text block. This is the handoff to both
Stage 2 and Stage 3. The plan is **frozen** — downstream stages must not
modify it.

```text
[Execution Plan]
Selected kind:         <kind-id>
Display name:          <display-name>
Confidence:            <0.00–1.00>   (source: scored | user-forced)
Kind file:             profiles/kinds/<kind-id>.md
Context kind file:     profiles/context/kinds/<kind-id>.md

── Stage 2 (onboard.md) ──
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

── Stage 3 (context files) ──
Context dimensions to load:
  conventions.md:
    - dimensions/naming
    - dimensions/error-handling
    - ...
  testing.md:
    - dimensions/testing-strategy
  architecture.md:
    - dimensions/architecture-layers
  constraints.md:
    - dimensions/hard-constraints
    - dimensions/anti-patterns

Context output files (kind-applicable subset):
  - conventions.md
  - testing.md
  - architecture.md
  - constraints.md

Excluded dimensions (will NOT appear in any file; recorded in onboard.md header):
  - logging
  - database-access
  - ...
```

Show the plan to the user and pause for confirmation on first-run. On
incremental mode with unchanged kind, auto-proceed.

**1.7 — Close kind files**

Once the plan is emitted, both kind files are done. Do not reopen either
in Stage 2 or Stage 3. (R2)

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
the exact format — 6 attributes total (`source-file`, `section`,
`profile`, `verified-commit`, `body-signature`, `generated`).
`verified-commit` and `body-signature` are **two separate, independently
required attributes** (not alternatives).
Use this literal shape (substitute values, keep attribute order and quotes):

```markdown
<!-- forge:onboard source-file="onboard.md" section="tech-stack" profile="core/tech-stack" verified-commit="a3f2c1d4" body-signature="9f8e7d6c5b4a3210" generated="2026-04-23" -->

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Language | TypeScript 5.x [high] [build] |
| Runtime | Node.js 20 LTS [high] [build] |

<!-- /forge:onboard section="tech-stack" -->
```

**Attribute definitions:**

- `source-file` = which artifact file this section belongs to
  (`onboard.md` | `conventions.md` | `testing.md` | `architecture.md` |
  `constraints.md`). Required for incremental mode's per-file routing.
- `section` = lowercase, kebab-case; for onboard.md it matches an entry
  in the kind's `output-sections`; for context files it matches a
  dimension name (e.g. `error-handling`, `naming`).
- `profile` = source profile path relative to `profiles/` root:
  - onboard.md sections: `core/tech-stack`, `integration/auth`, etc.
  - context sections: `context/dimensions/error-handling`, `context/dimensions/naming`, etc.
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

**Stage 2 writes onboard.md. Stage 3 (Steps 4–6 below) is the other
half of a first-run / regenerate pass and MUST execute next.**

> ⚠ **Common LLM trap:** Do NOT stop here even though onboard.md is
> written. A run that ends after Stage 2 is incomplete — the user will
> have onboard.md but NO conventions.md / testing.md / architecture.md /
> constraints.md, which are needed by every downstream skill
> (/forge:clarify, /forge:design, /forge:code, /forge:inspect, /forge:test).
>
> In Mode B (incremental), if Stage 3 was completed in a prior run and
> nothing has changed, Stage 3 may short-circuit with "no changes
> detected" — but it still MUST be entered to make that determination.
>
> The run ONLY terminates at Step 7 (JOURNAL entry after Stage 3 finishes).

**Continue now to Step 4 (Stage 3 scan).**

---

### Step 4 — Stage 3.1: Non-interactive scan

For each dimension in `Plan.context-dimensions` (grouped by output file):

```pseudo
evidence_by_dim = {}
conflicts      = []

for dim_path in flatten(Plan.context-dimensions.values()):
    dim_doc = Read("profiles/context/" + dim_path + ".md")
    patterns = dim_doc.scan_patterns
    rules    = dim_doc.extraction_rules
    sources  = dim_doc.scan_sources

    # Apply glob + grep + cli patterns per sources
    observations = apply_patterns(patterns, sources)

    # Run extraction rules to normalize observations
    facts, detected_conflicts = extract(rules, observations)

    evidence_by_dim[dim_path] = facts
    conflicts.extend(detected_conflicts)

    discard(dim_doc, observations)   # free LLM context
```

**Discard discipline (DG1 / DG2):**

After processing each dimension, only the distilled `facts` (and any
conflicts flagged) are retained in working memory. The dimension file
itself and raw observations are evicted.

**Strictly non-interactive (R11):**

Do NOT ask the user anything during this step — not even "I found 3
conflicts, keep going?". Collect everything, proceed to Step 5.

---

### Step 5 — Stage 3.2: Batch conflict resolution

If `len(conflicts) == 0`: skip this step, proceed to Step 6.

Otherwise, present ALL conflicts in a single message:

```
[forge:onboard] Convention conflicts detected (Stage 3.2)

Scan complete. {N} conflicts require your resolution before context
files can be written.

────────────────────────────────────────────────
Conflict 1/{N} — {dimension-name}

Pattern A — observed in: {file-list}
  {concrete code excerpt showing pattern A, 3–5 lines}

Pattern B — observed in: {file-list}
  {concrete code excerpt showing pattern B, 3–5 lines}

Recommendation: {A | B | "allow both"}
Reason: {one-sentence rationale}

Options: [A] [B] [Both — context-dependent] [C — Other (specify)]

────────────────────────────────────────────────
Conflict 2/{N} — {dimension-name}

...

────────────────────────────────────────────────

Please answer in one reply, format: "1A 2B 3A" (or per-item explanation).
```

Wait for the user's single consolidated answer. Apply resolutions to
`evidence_by_dim`: conflicts marked A use Pattern A as the synthesized
rule; conflicts marked B use Pattern B; "Both" emits a rule explicitly
permitting context-dependent choice with guidance.

**One interaction only.** If the user asks for clarification, answer,
but do not re-surface the full conflict list a second time.

---

### Step 6 — Stage 3.3 + 3.4: Smart-merge + write context files

For each `output_file` in `Plan.context-output-files`:

```pseudo
dims_for_this_file = Plan.context-dimensions[output_file]   # e.g. ["dimensions/naming", "dimensions/error-handling", ...]

# Fresh content synthesis from scanned + resolved evidence
new_sections = {}
for dim in dims_for_this_file:
    template  = get_output_template(dim)               # from dim file
    new_sections[dim] = render(template, evidence_by_dim[dim])

# Read existing file (if any) and extract preservable content (R14)
existing_sections = {}
preserve_blocks_by_section = {}
orphans           = []

if file_exists(output_file):
    parsed = parse_section_markers(read(output_file))
    for sec in parsed:
        if sec.profile_key in dims_for_this_file:
            existing_sections[sec.profile_key] = sec
            preserve_blocks_by_section[sec.profile_key] = (
                extract_preserve_blocks(sec.body)
            )
        else:
            orphans.append(sec)   # dimension no longer applies to this kind

# Compose final file
final = header()
for dim in dims_for_this_file:
    body = new_sections[dim]
    body = re_anchor_preserve_blocks(body,
                                      preserve_blocks_by_section.get(dim, []))
    final += write_section_marker(
        source_file = output_file,
        section     = dim_to_section_id(dim),
        profile     = "context/" + dim,
        verified_commit = current_git_short(),
        body_signature  = sha256_first16(canonicalize(body)),
        generated       = today_iso(),
    )
    final += body
    final += write_closing_marker(section=dim_to_section_id(dim))

if orphans:
    final += "\n## Legacy Notes\n\n"
    for sec in orphans:
        final += f"### {sec.title} (migrated from previous kind or version)\n\n"
        final += sec.body
        final += "\n"

write(output_file, final)
```

**Applies to every kind-applicable output file** in turn
(conventions.md, testing.md, architecture.md, constraints.md per Plan).
Files NOT in `Plan.context-output-files` are neither created nor touched
(R12).

**Preserve-block invariant (R5 + R14):** every `<!-- forge:preserve -->`
block found in existing content MUST reach the final output verbatim.
If a block's natural anchor (surrounding text) no longer exists after
rewrite, append it to the section body's end with a comment marker
`<!-- forge:preserve orphaned=true -->`; never delete.

**Stage 3 terminates here.** Proceed to Step 7.

---

### Step 7 — Append JOURNAL entry (final step — run ends here)

This is the **only** correct place for the run to terminate. If you
reach this step, Stages 1 + 2 + 3 have all completed. Append one entry
to `.forge/JOURNAL.md`:

```markdown
## YYYY-MM-DD — /forge:onboard
- Kind:              {kind-id} (confidence {score})
- Mode:              {first-run | incremental | regenerate | single-section}
- Commit:            {short-sha}
- onboard.md:        {N} sections written / {M} preserved blocks / {K} skipped
- context files:     {list of context files written, e.g. "conventions.md, testing.md, constraints.md"}
- conflicts resolved:{count} (or "(none)")
- orphans migrated:  {count} (or "(none)")
- excluded dims:     {count} (or "(none)") — see onboard.md header for list
- Next:              /forge:clarify <your first feature>
```

**Never say "Next step: /forge:calibrate" — that skill no longer exists
in v0.5.0 (its responsibility absorbed into Stage 3 of this skill).**
The next step after onboard is always `/forge:clarify`.

---

## Run Modes

### Mode A — first-run (no existing artifact)

1. Full Stage 1 detection
2. Full Stage 2 profile pass → onboard.md written
3. Full Stage 3 scan + conflicts + merge → 1–4 context files written
4. JOURNAL entry with `mode: first-run`

### Mode B — incremental (default when artifact exists)

1. Read existing onboard.md header to extract `kind`, `commit`, section markers
2. If current kind signals still support the recorded kind → reuse it
   (no Stage 1 rescoring). Otherwise trigger **kind drift handling**
   (see `reference/incremental-mode.md`).
3. **Stage 2 incremental:** for each onboard.md section, compare
   `verified-commit` (fast-skip) → if HEAD unchanged, CLEAN; else compare
   `body-signature` → dirty detection. Rewrite dirty sections only.
4. **Stage 3 incremental:** for each context file, scan only dimensions
   not yet matching current HEAD's `verified-commit`. Apply smart merge
   (R14). Batch-resolve any new conflicts.
5. Preserve blocks carried forward verbatim (R5)
6. JOURNAL entry with `mode: incremental`

Details of merge / diff logic live in `reference/incremental-mode.md`.
This SKILL.md defines the contract; the reference defines the algorithm.

### Mode C — regenerate (`--regenerate`)

Full Stage 1 + Stage 2 + Stage 3, as if first-run, but preserve blocks
from all existing artifacts (onboard.md + context files) are extracted
first and re-inserted on write. Conflicts are re-surfaced for batch
re-resolution (user may answer identically as before).
JOURNAL entry with `mode: regenerate`.

### Mode D — single-section (`--section=<name>`)

1. Read existing artifact (onboard.md or any context file) to locate the
   requested section marker by `section="<name>"`
2. Read the profile that produced that section (from marker's
   `profile="..."` attribute)
3. Execute read-do-discard or scan-synthesize for that single profile
4. Splice the new section back into its source file, preserving all others
5. JOURNAL entry with `mode: single-section`

**Constraint:** single-section mode cannot change the kind. For kind
changes, use `--regenerate` or `--kind=<id>`. Also cannot resolve
conflicts — if the target section's scan surfaces conflicts, halt and
instruct user to use `--regenerate`.

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
  - plugin  — Claude Code skill / agent / command package
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

### Batch conflict resolution (Stage 3.2)

```
[forge:onboard] Convention conflicts detected (Stage 3.2)

Scan complete. {N} conflicts require your resolution before context
files can be written.

────────────────────────────────────────────────
Conflict 1/{N} — {dimension-name}

Pattern A — observed in: {file-list}
  {concrete code excerpt showing pattern A, 3–5 lines}

Pattern B — observed in: {file-list}
  {concrete code excerpt showing pattern B, 3–5 lines}

Recommendation: {A | B | "allow both"}
Reason: {one-sentence rationale}

Options: [A] [B] [Both — context-dependent] [C — Other (specify)]

────────────────────────────────────────────────
Conflict 2/{N} — {dimension-name}

...

────────────────────────────────────────────────

Please answer in one reply, format: "1A 2B 3A ..." (or per-item explanation).
```

### Stage 3 no conflicts (skip batch)

```
[forge:onboard] Stage 3 scan complete — no conflicts

Detected {D} dimensions without any pattern contradiction. Proceeding
to smart-merge + write context files ({list of files}).
```

---

## Reference Documents

| File | Purpose |
|------|---------|
| `profiles/README.md` | Profile + kind file schema, execution contract (Stage 2) |
| `profiles/kinds/*.md` | Stage-2 kind definitions (onboard.md section composition) |
| `profiles/{category}/*.md` | Stage-2 profile files (onboard.md sections) |
| `profiles/context/README.md` | Stage-3 schema + execution contract (context files) |
| `profiles/context/kinds/*.md` | Stage-3 kind definitions (context dimension composition) |
| `profiles/context/dimensions/*.md` | Stage-3 dimension files (scan + synthesize → rules) |
| `reference/scan-patterns.md` | Language/framework grep patterns + confidence decision tree |
| `reference/incremental-mode.md` | Incremental merge + kind drift algorithm (MUST read when in Mode B) |

---

## Constraints

- Do not modify any source file. This skill is read + write-to-.forge/ only.
- Do not read more than ~50 source files during Stage 2 total, across all
  profiles, to stay within long-context stability (DG2).
- Do not read more than ~60 source files during Stage 3 total, across all
  dimensions (DG2 again — Stage 3 is scan-heavy).
- Do not fabricate evidence (R7). If a profile cannot find signals, it
  produces an empty section body (not omitted — so the user sees the gap)
  with a single "No signals matched for this profile" note.
- Do not re-enter Stage 1 once Stage 2 has begun (R1).
- Do not enter Stage 3 if Stage 2 failed to write onboard.md.
- Do not reopen the selected kind file once closed (R2).
- Do not surface Stage 3 conflicts one-by-one; batch them (R11).
- Do not create context files not listed in the kind's `output-files` (R12).
- Do not overwrite an existing context file wholesale; always smart-merge
  (R14).
- Examples in any profile output must follow Content Hygiene (see
  `.forge/context/constraints.md` C8).
