# Conventions: forge

> Kind:      plugin
> Generated: 2026-04-23
> Commit:    9dbca95
> Generator: /forge:onboard (v0.5.0-dev)

<!-- forge:onboard source-file="conventions.md" section="naming" profile="context/dimensions/naming" verified-commit="9dbca95" body-signature="cb7d16fb46fe560e" generated="2026-04-23" -->

## Naming Conventions

### Files
kebab-case for skill directories and reference files — e.g. `skill-format.md`, `incremental-mode.md`, `forge-explorer.md` [high] [code]
UPPER-CASE for primary skill instruction files — `SKILL.md`, `JOURNAL.md` [high] [code]

### Skill names and IDs
lowercase single-word (or hyphenated) — e.g. `onboard`, `clarify`, `design`, `forge-explorer` [high] [code]
Skill `name:` frontmatter field matches directory name exactly [high] [code]

### Artifact sections
section IDs in section markers: kebab-case — e.g. `section="tech-stack"`, `section="error-handling"` [high] [code]
profile paths: kebab-case directory/file — e.g. `core/tech-stack`, `context/dimensions/naming` [high] [code]

### Feature slugs and task IDs
Feature slugs: kebab-case — e.g. `onboard-kind-profiles`, `lean-kind-aware-pipeline`, `plugin-bootstrap` [high] [code]
Task IDs: globally unique `T{NNN}` uppercase — e.g. `T001`, `T030` [high] [code]

### Frontmatter keys
All lowercase with hyphens — e.g. `kind-id`, `output-file`, `scan-sources`, `allowed-tools` [high] [code]

### Tag system identifiers
Confidence tags: `[high]` / `[medium]` / `[low]` / `[inferred]` [high] [code]
Source tags: `[code]` / `[build]` / `[config]` / `[readme]` / `[cli]` [high] [code]
Conflict flag: `[conflict]` [high] [code]

<!-- /forge:onboard section="naming" -->

<!-- forge:onboard source-file="conventions.md" section="error-handling" profile="context/dimensions/error-handling" verified-commit="9dbca95" body-signature="1ba9674d2ff94102" generated="2026-04-23" -->

## Error Handling

**Mode:** Skill halt-and-surface

For Claude Code plugin skills, error handling means structured halts rather than runtime exceptions. A skill that cannot proceed surfaces a precise `[forge:<skill-name>]` prefixed message explaining what is missing and what the user should do next.

**Convention for new code:**
- Skills that cannot proceed produce a structured `[forge:<skill-name>]` block and stop; never silently fall back to defaults [high] [code]
- IRON RULE violations halt the run immediately; the user receives a precise "why" + "next step" message [high] [code]
- Low-confidence detection (< 0.60) halts with candidate list — never proceeds by guessing [high] [code]
- Scripts (`.mjs`) exit non-zero on hard errors; SKILL.md routes on exit code [medium] [code]

**What to avoid:**
- Silently proceeding when a required input is absent — always surface the gap [high] [code]
- Best-guess defaults when context is insufficient — pause and ask [high] [code]
- Swallowing errors without informing the user [high] [code]

<!-- /forge:onboard section="error-handling" -->

<!-- forge:onboard source-file="conventions.md" section="skill-format" profile="context/dimensions/skill-format" verified-commit="9dbca95" body-signature="af2925a79cbc53c5" generated="2026-04-23" -->

## SKILL.md / Agent File Format

### SKILL.md frontmatter

Required keys:
- `name` — skill id, matches directory name [high] [code]
- `description` — multi-line paragraph describing when to use [high] [code]
- `allowed-tools` — space-separated tool list [high] [code]
- `model` — `sonnet` | `opus` | `haiku` [high] [code]

Optional keys:
- `argument-hint` — shown in help text for `<feature-slug>` etc. [medium] [code]
- `effort` — `low` | `medium` | `high` [medium] [code]
- `context` — `fork` (spawns a forked session) [medium] [code]

Example:
```yaml
---
name: onboard
description: |
  Generates a navigation-oriented project map...
argument-hint: "[--regenerate | --section=<name> | --kind=<kind-id>]"
allowed-tools: "Read Glob Grep Bash Write"
context: fork
model: sonnet
effort: high
---
```

### Canonical body outline

Every SKILL.md follows this top-level section order [high] [code]:

1. `## Runtime snapshot` — bash-backticked context for invocation time
2. `## IRON RULES` — hard constraints, bold imperative
3. `## Prerequisites` — required inputs + missing-input handling
4. `## Process` — numbered `### Step N` subsections
5. `## Output` — artifact file path + template reference
6. `## Interaction Rules` — user-facing conversation patterns (optional)
7. `## Constraints` — what the skill will not do

### IRON RULES style

- Each rule = one numbered section `### R{N}` (e.g. `### R1`) [high] [code]
- Rule title in bold after the section marker [high] [code]
- Imperative mood; "A run that violates..." halt language [high] [code]
- Rationale follows the constraint statement [high] [code]

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

### Skill subdirectories (optional)

- `<skill>/reference/` — detailed algorithm docs loaded only when needed [high] [code]
- `<skill>/scripts/*.mjs` — deterministic helpers invoked via Bash [medium] [code]
- `<skill>/profiles/` — kind-aware templates (onboard uses this) [high] [code]

### What to avoid

- Ad-hoc frontmatter keys not in the established schema [high] [code]
- IRON RULES buried inside Process prose (must stay in their own section) [high] [code]
- Cross-file rule references without inline backup (key rules echoed in SKILL.md body) [medium] [code]

<!-- /forge:onboard section="skill-format" -->

<!-- forge:onboard source-file="conventions.md" section="artifact-writing" profile="context/dimensions/artifact-writing" verified-commit="9dbca95" body-signature="845f9915d80a5804" generated="2026-04-23" -->

## Artifact Writing Discipline

### Path schema

```
.forge/
├── context/                    <- project-wide, one per dimension
│   ├── onboard.md
│   ├── conventions.md
│   ├── testing.md
│   ├── architecture.md
│   └── constraints.md
├── features/                   <- one directory per feature
│   └── {feature-slug}/
│       ├── clarify.md
│       ├── design.md
│       ├── plan.md
│       ├── design-inputs.md    (optional)
│       ├── inspect.md
│       ├── test.md
│       ├── verification.md     (for skill features, optional)
│       └── tasks/
│           └── T{NNN}-summary.md
├── JOURNAL.md                  <- append-only log of all skill invocations
└── _session/                   <- transient, not committed
```

[high] [code]

### Section marker contract (R9)

Every section in any `.forge/context/*.md` file is wrapped in a 6-attribute HTML comment pair:

```
<!-- forge:onboard source-file="<file>.md" section="<id>" profile="<profile-path>" verified-commit="<git-short>" body-signature="<16hex>" generated="<YYYY-MM-DD>" -->
```

**All 6 attributes are required, in this exact order, with double-quoted values.**
`verified-commit` and `body-signature` are two **separate** independently required attributes — not alternatives.

Closing marker uses only `section`:
```
<!-- /forge:onboard section="<id>" -->
```

[high] [code]

### Preserve blocks (sacred, per R5)

Any human-edited content wrapped in:
```
<!-- forge:preserve -->
...
<!-- /forge:preserve -->
```
is carried forward verbatim across all regeneration runs, regardless of section rewrite status. Preserve blocks always win over generated content.

[high] [code]

### JOURNAL.md discipline

- Append-only — never rewrite history [high] [code]
- One section per skill invocation [high] [code]
- Format: `## YYYY-MM-DD — /forge:<skill> <args>`
- Content: bulleted facts about what was produced + next step [high] [code]

### Skill output contracts

Each skill's SKILL.md § Output section declares the exact artifact path(s) it writes. No skill may write outside its declared output. [high] [code]

### What to avoid

- Editing an artifact's section marker attributes by hand (breaks incremental reconciliation) [high] [code]
- Removing preserve blocks silently [high] [code]
- Editing old JOURNAL entries [high] [code]
- Writing to non-declared paths inside `.forge/` [high] [code]

<!-- /forge:onboard section="artifact-writing" -->

<!-- forge:onboard source-file="conventions.md" section="markdown-conventions" profile="context/dimensions/markdown-conventions" verified-commit="9dbca95" body-signature="80111ac2dc9133a7" generated="2026-04-23" -->

## Markdown Conventions (plugin-internal)

### Heading hierarchy

- `#` reserved for document title (one per file) [high] [code]
- `##` for top-level sections [high] [code]
- `###` for subsections [high] [code]
- `####` sparingly, only when needed [medium] [code]

### Code fences

- Always include language tag: ` ```yaml ` / ` ```bash ` / ` ```json ` / ` ```markdown ` / ` ```text ` [high] [code]
- Use ` ```text ` for generic pseudo-code blocks [medium] [code]

### Lists

- Bullet character: `- ` (dash-space); never `*` or `+` [high] [code]
- Nested bullets indent by 2 spaces [high] [code]
- Numbered lists only when order matters [high] [code]

### Emphasis

- Bold: `**word**` (double asterisk) [high] [code]
- Italic: `*word*` (single asterisk) [medium] [code]

### Tag system (artifacts with evidence claims)

Every fact in a context / onboard artifact carries:
- Required: one confidence tag — `[high]` / `[medium]` / `[low]` / `[inferred]`
- Optional: one source tag — `[code]` / `[build]` / `[config]` / `[readme]` / `[cli]`
- Optional: conflict flag — `[conflict]`

Order: `<fact> [confidence] [source?] [conflict?]`

See onboard SKILL.md R10 for the authoritative closed enumeration.

### Bilingual conventions (forge-specific)

- User-facing text may be Chinese (interaction messages, JOURNAL entries, README user sections) [high] [readme]
- Structural keywords stay English (frontmatter keys, section IDs, profile names, marker attributes) [high] [code]
- SKILL.md body may mix; IRON RULES typically bilingual; Process typically English [medium] [code]

### Marker comments

- `<!-- forge:<skill> ... -->` HTML comments are machine-parseable markers [high] [code]
- Always paired (opening + closing) for wrapping blocks [high] [code]
- Attribute syntax: `key="value"` with double quotes [high] [code]
- Do NOT put markdown content inside attribute values [high] [code]

### What to avoid

- Deep nesting beyond `####` [high] [code]
- Missing code-fence language tags [high] [code]
- Unpaired preserve / section markers [high] [code]
- Confidence / source tags invented outside R10 enumeration [high] [code]

<!-- /forge:onboard section="markdown-conventions" -->

<!-- forge:onboard source-file="conventions.md" section="commit-format" profile="context/dimensions/commit-format" verified-commit="9dbca95" body-signature="e96934b1b2269d7d" generated="2026-04-23" -->

## Commit Message Format

**Style:** Conventional Commits [high] [cli]

**Format:**
```
<type>(<scope>): <subject>

[body — optional]

Co-Authored-By: Claude <model> <noreply@anthropic.com>
```

**Types used:** `feat` / `fix` / `chore` / `docs` / `refactor` / `test` [high] [cli]

**Scope conventions:**
- `skill/<name>` — e.g. `skill/onboard`, `skill/clarify` [high] [cli]
- `agent/<name>` — e.g. `agent/explorer` [high] [cli]
- `plugin` — plugin.json or overall plugin structure [medium] [cli]
- `forge` — `.forge/` artifacts (design, plan, summaries) [high] [cli]
- `pipeline` — cross-skill pipeline changes [medium] [cli]

**Subject rules:**
- Imperative mood, lowercase first letter, no trailing period [high] [cli]
- Max 72 characters [medium] [cli]
- Include task ID(s) in subject: e.g. `(T026-T029)` [high] [cli]

**Body / footer:**
- `Co-Authored-By: Claude <model> <noreply@anthropic.com>` for AI-paired work [high] [cli]
- Task IDs in subject when a commit covers one or more tasks [high] [cli]

**Commit cadence:** one independent commit per task (T001, T002, ...); `.forge/` artifacts committed when produced. [high] [readme]

**Example (recent):**
```
feat(skill/onboard): absorb calibrate as Stage 3 (T023)
```

<!-- /forge:onboard section="commit-format" -->
