---
name: skill-format
output-file: conventions.md
applies-to:
  - claude-code-plugin
scan-sources:
  - glob: "plugins/*/skills/*/SKILL.md"
  - glob: "skills/*/SKILL.md"
  - glob: "plugins/*/agents/*.md"
  - glob: "agents/*.md"
confidence-signals:
  - multiple SKILL.md files sharing same frontmatter keys
  - IRON RULES section present in ≥ 1 SKILL.md
  - consistent Step numbering across skills
token-budget: 1000
---

# Dimension: SKILL.md / Agent File Format

## Scan Patterns

**SKILL.md frontmatter survey:**
```
Glob "**/SKILL.md"
For each: extract YAML frontmatter keys
  Common keys: name, description, argument-hint, allowed-tools, model,
               effort, context
```

**Body structure survey:**
```
Grep "^## IRON RULES" / "^## Prerequisites" / "^## Process" /
     "^## Output" / "^## Interaction Rules" / "^## Constraints"
  → detect whether skills share a canonical outline
```

**Agent file survey:**
```
Glob "**/agents/*.md"
Extract frontmatter keys: name, description, tools, model, color
```

**IRON RULES style:**
```
Grep "^- \\*\\*" within "## IRON RULES" sections
  → detect whether IRON RULES use bold imperative statements
```

## Extraction Rules

1. Record **frontmatter schema** for SKILL.md (required vs optional keys)
2. Record **canonical Process outline** (Step numbering, Section order)
3. Record **IRON RULES style** (bullet form, imperative voice, etc.)
4. Record **agent file schema** (typically shorter than SKILL.md)
5. Note any **reference/scripts** subdirectory conventions
6. Detect conflicts (e.g. some skills omit `argument-hint`, some have it)

## Output Template

```markdown
## SKILL.md / Agent File Format

### SKILL.md frontmatter

Required keys:
- `name` — skill id, matches directory name [high] [code]
- `description` — multi-line paragraph describing when to use [high] [code]
- `allowed-tools` — whitespace-separated tool list [high] [code]
- `model` — `sonnet` | `opus` | `haiku` [high] [code]

Optional keys:
- `argument-hint` — shown in help text for `<feature-slug>` etc. [high] [code]
- `effort` — `low` | `medium` | `high` [medium] [code]
- `context` — `fork` (spawns a forked session) [medium] [code]

Example:
\`\`\`yaml
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
\`\`\`

### Canonical body outline

Every SKILL.md follows this top-level section order [high] [code]:

1. `## Runtime snapshot` — bash-backticked context for invocation time
2. `## IRON RULES` — hard constraints, bold imperative
3. `## Prerequisites` — required inputs + missing-input handling
4. `## Process` — numbered `### Step N` subsections
5. `## Output` — artifact file path + template reference
6. `## Interaction Rules` — user-facing conversation patterns
7. `## Constraints` — what the skill will not do

### IRON RULES style

- Each rule = one `-` bullet [high] [code]
- Imperative mood + bold sentinel (e.g. `- **Never assume answers to
  business rules.**`) [high] [code]
- Rationale follows the sentinel in plain text [high] [code]

### Agent file frontmatter

\`\`\`yaml
---
name: forge-explorer
description: |
  Traces a single code path end-to-end...
tools: [Read, Glob, Grep, Bash]
model: sonnet
color: yellow
---
\`\`\`

### Skill subdirectories (optional)

- `<skill>/reference/` — detailed algorithm docs loaded only when needed
  [high] [code]
- `<skill>/scripts/*.mjs` — deterministic helpers invoked via Bash
  [medium] [code]
- `<skill>/profiles/` — kind-aware templates (onboard uses this) [medium] [code]

### What to avoid

- Ad-hoc frontmatter keys not in the schema (breaks plugin loader)
- IRON RULES buried inside Process prose (invisible to LLM)
- Describing "how" inside IRON RULES (should be imperative constraints)
- Cross-file rule references without inline backup (LLM may not load the
  reference file; key rules must be echoed in SKILL.md body)
```

## Confidence Tags

- `[high]` — ≥ 5 SKILL.md files share the same schema / outline
- `[medium]` — common pattern but 1–2 drift
- `[low]` — only 2 skills to compare; pattern not yet established
- `[inferred]` — single skill analyzed; convention guessed
