# Project Conventions: forge

> Kind:                 claude-code-plugin
> Generated:            2026-04-23
> Commit:               59836a2
> Generator:            /forge:onboard Stage 3 (v0.5.0-dev)
> Dimensions loaded:    naming, error-handling, skill-format, artifact-writing, markdown-conventions, commit-format
> Excluded-dimensions:  logging, validation, api-design, database-access, messaging, authentication

---

<!-- forge:onboard source-file="conventions.md" section="naming" profile="context/dimensions/naming" verified-commit="59836a2" body-signature="a7c4e2f891b03d56" generated="2026-04-23" -->

## Naming Conventions

### Files
kebab-case — e.g. `forge-explorer.md`, `state-machine.md`, `incremental-mode.md` [high] [code]

### SKILL.md names
Fixed literal `SKILL.md` (uppercase, no variation). [high] [code]

### Directory names
kebab-case for skill directories (`onboard/`, `forge/`); singular nouns (`profiles/` is plural because it's a collection). [high] [code]

### Frontmatter keys
kebab-case — `allowed-tools`, `argument-hint`, `kind-id`, `verified-commit`, `body-signature`. [high] [code]

### IRON RULES identifiers
`R<N>` format, globally numbered per skill (e.g. `R1..R14` in onboard/SKILL.md). [high] [code]

### Task IDs
`T<NNN>` three-digit zero-padded; globally unique across all features (shared pool). [high] [code]

### Section IDs (marker attributes)
kebab-case matching the `output-sections` entry in the kind file. [high] [code]

<!-- /forge:onboard section="naming" -->

---

<!-- forge:onboard source-file="conventions.md" section="error-handling" profile="context/dimensions/error-handling" verified-commit="59836a2" body-signature="c3f91e4a7b250648" generated="2026-04-23" -->

## Error Handling

**Mode:** Skill halt-and-surface pattern.

Skills that cannot proceed must produce a structured block and halt — never silently fall back to defaults. [high] [code]

### Convention for new skills

- Use `[forge:<skill-name>]` lowercase prefix for all user-facing messages (consistency with `/forge:<skill>` invocation form). [high] [code]
- Halt messages must include: (1) WHAT went wrong, (2) WHICH options the user has, (3) HOW to recover. Never dead-end. [high] [code]
- IRON RULE violations halt the run immediately; the offending rule is cited by number. [high] [code]
- Scripts (`.mjs`) exit non-zero on hard errors; SKILL.md may route on exit code. [medium] [code]

### Example halt message format

```
[forge:onboard] Kind detection confidence is low

Top candidates:
  1. web-backend        — score 0.42
  2. claude-code-plugin — score 0.38

Minimum confidence required: 0.60.

Options:
  1. Re-run with --kind=<kind-id> to force one of the candidates
  2. Describe the project so a new kind definition can be added
  3. Exit

Which do you prefer?
```

### What to avoid

- Proceeding with best-guess defaults when a required input is missing
- `try { } catch { }` blocks in `.mjs` scripts that swallow errors silently
- Halt messages that tell the user "failed" without explaining why or what to do

<!-- /forge:onboard section="error-handling" -->

---

<!-- forge:onboard source-file="conventions.md" section="skill-format" profile="context/dimensions/skill-format" verified-commit="59836a2" body-signature="e1b0a6d8cf47f392" generated="2026-04-23" -->

## SKILL.md / Agent File Format

### SKILL.md frontmatter

Required keys:
- `name` — skill id, matches directory name [high] [code]
- `description` — multi-paragraph describing when to use; may span multiple lines with YAML `|` [high] [code]
- `allowed-tools` — whitespace-separated tool list [high] [code]
- `model` — `sonnet` / `opus` / `haiku` [high] [code]

Optional keys:
- `argument-hint` — shown in help for the argument [high] [code]
- `effort` — `low` / `medium` / `high` (rarely `low`) [medium] [code]
- `context` — `fork` (spawns a forked session) [medium] [code]

### Canonical body outline

Every SKILL.md follows this top-level section order [high] [code]:

1. `## Runtime snapshot` — bash-backticked context for invocation-time state
2. `## IRON RULES` — hard constraints, numbered `R<N>` with bold sentinel
3. `## Prerequisites` — required inputs + missing-input handling
4. `## Process` — numbered `### Step <N>` subsections, may group under Stages
5. `## Output` — artifact file path(s) + template reference
6. `## Interaction Rules` — user-facing conversation patterns
7. `## Constraints` — what the skill will not do

### IRON RULES style

- Each rule headed with `### R<N> — <short title>` [high] [code]
- Body: one paragraph explaining the rule + rationale [high] [code]
- Imperative / directive voice ("MUST NOT", "MUST", "NEVER") [high] [code]

### Agent file frontmatter

```yaml
---
name: forge-explorer
description: |
  Traces a single code path end-to-end...
tools: [Read, Glob, Grep, Bash]
model: sonnet
color: yellow
---
```

### Skill subdirectory conventions

- `<skill>/reference/` — detailed algorithm docs loaded only when needed [high] [code]
- `<skill>/scripts/*.mjs` — deterministic helpers invoked via Bash [medium] [code]
- `<skill>/profiles/` — kind-aware templates (onboard uses this) [medium] [code]

### What to avoid

- Ad-hoc frontmatter keys not in the schema (breaks plugin loader)
- IRON RULES as bullet points buried in Process prose (LLM may miss them)
- Describing "how" inside IRON RULES (should be imperative constraints)
- Cross-file rule references without inline backup (LLM may not load reference files; key rules MUST be in SKILL.md body — lesson from v0.4.0 T015)

<!-- /forge:onboard section="skill-format" -->

---

<!-- forge:onboard source-file="conventions.md" section="artifact-writing" profile="context/dimensions/artifact-writing" verified-commit="59836a2" body-signature="b8e2f04d7c91a358" generated="2026-04-23" -->

## Artifact Writing Discipline

### Path schema

```
.forge/
├── context/                   ← project-wide, generated by onboard
│   ├── onboard.md
│   ├── conventions.md
│   ├── testing.md
│   ├── architecture.md
│   └── constraints.md
├── features/                  ← one directory per feature
│   └── {slug}/
│       ├── clarify.md
│       ├── design-inputs.md   (optional, from clarify Step 6 HOW-routing)
│       ├── design.md
│       ├── plan.md
│       ├── inspect.md
│       ├── test.md
│       └── tasks/
│           └── T{NNN}-summary.md
├── JOURNAL.md                 ← append-only log of all skill invocations
└── _session/                  ← transient scratch (not committed)
```

[high] [code]

### Section marker contract

6 attributes required, in exact order, double-quoted values:

```
<!-- forge:onboard source-file="<file>.md" section="<id>" profile="<profile-path>" verified-commit="<git-short>" body-signature="<16hex>" generated="<YYYY-MM-DD>" -->
```

`verified-commit` and `body-signature` are **two separate, independently required attributes** — not alternatives. [high] [code]

### Preserve blocks (sacred)

```
<!-- forge:preserve -->
...user content to survive regeneration...
<!-- /forge:preserve -->
```

Preserve blocks are carried forward verbatim across all runs, even when the enclosing section is rewritten. Orphaned preserve blocks (anchor text changed) get `orphaned=true` attribute and append to section tail — never deleted. [high] [code]

### JOURNAL.md discipline

- Append-only — never rewrite history [high] [code]
- One section per skill invocation, headed `## YYYY-MM-DD — /forge:<skill> <args>` [high] [code]
- Content: bulleted facts about what was produced + next step [high] [code]

### Skill output contracts

Each skill's `## Output` section declares the exact artifact path(s) it writes. No skill may write outside its declared output paths. [high] [code]

### What to avoid

- Editing section marker attributes by hand (breaks incremental reconciliation)
- Removing preserve blocks silently (user content must survive)
- Editing old JOURNAL entries (breaks timeline)
- Writing to non-declared `.forge/` paths
- Bypassing status.mjs in the forge orchestrator (`/forge:forge` always consults it)

<!-- /forge:onboard section="artifact-writing" -->

---

<!-- forge:onboard source-file="conventions.md" section="markdown-conventions" profile="context/dimensions/markdown-conventions" verified-commit="59836a2" body-signature="6a4e1f2b90c83d47" generated="2026-04-23" -->

## Markdown Conventions (plugin-internal)

### Heading hierarchy

- `#` reserved for document title (one per file) [high] [code]
- `##` top-level sections [high] [code]
- `###` subsections [high] [code]
- `####` sparingly, only when really needed [medium] [code]

### Code fences

- Always include language tag: ` ```yaml `, ` ```bash `, ` ```json `, ` ```markdown `, ` ```typescript ` [high] [code]
- Use ` ```text ` for generic pseudo-code that shouldn't be highlighted [medium] [code]

### Lists

- Bullet character: `- ` (dash-space); never `*` or `+` [high] [code]
- Nested bullets indent by 2 spaces [high] [code]

### Emphasis

- Bold: `**word**` (double asterisk) [high] [code]
- Italic: `*word*` (single asterisk) [medium] [code]

### Tag system for evidence claims (SKILL.md R10 authoritative definition)

Every fact in a context / onboard artifact carries:
- Required: one confidence tag — `[high]` / `[medium]` / `[low]` / `[inferred]`
- Optional: one source tag — `[code]` / `[build]` / `[config]` / `[readme]` / `[cli]`
- Optional: conflict flag — `[conflict]`

Order: `<fact> [confidence] [source?] [conflict?]`. See plugins/forge/skills/onboard/SKILL.md R10 for full enumeration. [high] [code]

### Bilingual conventions (forge-specific)

- User-facing text may be Chinese (interaction messages, JOURNAL entries, CLAUDE.md sections, README user guides) [high] [readme]
- Structural keywords stay English (frontmatter keys, section IDs, profile names, marker attributes) [high] [code]
- SKILL.md body may mix: IRON RULES bilingual OK; Process usually English; examples use e-commerce palette per C8 [medium] [code]

### Marker comments

- `<!-- forge:<skill> ... -->` HTML comments are machine-parseable markers [high] [code]
- Always paired (opening + closing) for wrapping blocks [high] [code]
- Attribute syntax: `key="value"` with double quotes [high] [code]

### What to avoid

- Deep nesting beyond `####` (hurts outline readability)
- Missing code-fence languages (breaks highlighting)
- Unpaired preserve / section markers (breaks incremental reconciliation)
- Invented confidence / source tags (R10 closed enumeration)

<!-- /forge:onboard section="markdown-conventions" -->

---

<!-- forge:onboard source-file="conventions.md" section="commit-format" profile="context/dimensions/commit-format" verified-commit="59836a2" body-signature="d3a7e2f49b81c056" generated="2026-04-23" -->

## Commit Message Format

**Style:** Conventional Commits (project-enforced) [high] [cli]

**Format:**
```
<type>(<scope>): <subject>

[body — optional, explains why]

[footer — optional, Co-Authored-By lines]
```

**Types used:** `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `perf`, `build` [high] [cli]

**Scope conventions:**
- `skill/<name>` — changes to a specific skill (e.g. `skill/onboard`) [high] [cli]
- `agent/<name>` — changes to an agent (e.g. `agent/explorer`) [high] [cli]
- `plugin` — plugin-level changes (`.claude-plugin/plugin.json`, etc.) [high] [cli]
- `forge` — repo-level (`.forge/` artifacts, design docs) [high] [cli]
- `pipeline` — cross-skill restructure (used for v0.5.0 consolidation) [medium] [cli]

**Subject rules:**
- Lowercase start, imperative mood ("add", not "added") [high] [cli]
- ≤ 72 characters [high] [cli]
- No period at end [high] [cli]

**Body / footer:**
- `Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>` for AI-paired work [high] [cli]
- Body explains WHY, not WHAT (the diff shows WHAT) [medium] [cli]

**Cadence:** One commit per Task (T{NNN}); no batch commits across tasks. `.forge/` artifacts (design, plan) committed on produce, separate from task commits. [high] [readme]

**Example (from recent history):**
```
feat(skill/onboard): absorb calibrate as Stage 3 (T023) ⚠ high risk

Wave C 核心改造：onboard 从两阶段升级到三阶段...

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
```

<!-- /forge:onboard section="commit-format" -->

---

## Development Workflow

### Pair-programming pattern

forge development follows a human+AI pair pattern:
- Claude does the skill-writing and code execution
- Human provides domain intent, validates output, and catches misinterpretations [high] [readme]

### Testing paradigm

Traditional unit tests are NOT applicable to SKILL.md / agent markdown files. Validation is via **self-bootstrap**: running the plugin against itself or a sample project. See `testing.md`. [high] [readme]

### Review cadence

- Each Wave (cluster of related Tasks) ends with a commit + checkpoint with human [high] [readme]
- High-risk Tasks (marked `⚠` in plan.md) get independent commits for rollback granularity [high] [readme]

### Branch strategy

- `main` is the only long-lived branch [high] [readme]
- Push directly to `main` (pre-1.0 dogfooding phase); tag releases via `git tag vX.Y.Z` [high] [readme]
