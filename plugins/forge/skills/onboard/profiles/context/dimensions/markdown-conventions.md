---
name: markdown-conventions
output-file: conventions.md
applies-to:
  - plugin
scan-sources:
  - glob: "plugins/*/skills/*/SKILL.md"
  - glob: "plugins/*/agents/*.md"
  - glob: ".forge/**/*.md"
  - glob: "docs/**/*.md"
  - glob: "README.md"
confidence-signals:
  - consistent heading hierarchy across SKILL.md files
  - consistent use of code blocks with language tags
  - consistent use of confidence tag syntax (`[high]` / `[code]` / `[conflict]`)
token-budget: 800
---

# Dimension: Markdown Conventions (plugin-internal)

## Scan Patterns

**Heading hierarchy:**
```
For each SKILL.md / agent.md / .forge/*.md:
  Collect heading levels used (# ## ### ####)
  Detect max depth + typical outline skeleton
```

**Code fence languages:**
```
Grep "^\\`\\`\\`[a-z]+"
  → collect language tags used (bash, yaml, json, typescript, markdown)
```

**List style:**
```
Grep "^- " vs "^\\* " vs "^\\+ "
  → detect bullet convention
```

**Emphasis style:**
```
Grep "\\*\\*.+\\*\\*" vs "__.+__"  → bold convention
Grep "\\*.+\\*" vs "_.+_"          → italic convention
```

**Tag usage (for skill artifacts):**
```
Grep "\\[(high|medium|low|inferred)\\]" → confidence tag usage
Grep "\\[(code|build|config|readme|cli)\\]" → source tag usage
Grep "\\[conflict\\]" → conflict flag
```

## Extraction Rules

1. Document **heading conventions** (max depth, common outline)
2. Document **code-fence language tags** consistently used
3. Document **list / emphasis style**
4. Document the **tag system** (confidence + source + conflict) — refer
   to SKILL.md R10 if the project is forge itself; otherwise state the
   observed subset
5. Document any **Chinese/English mixing conventions** if project has
   bilingual docs (forge does)
6. Note **marker comment** conventions (`<!-- forge:* -->` HTML comments)

## Output Template

```markdown
## Markdown Conventions (plugin-internal)

### Heading hierarchy

- `#` reserved for document title (one per file) [high] [code]
- `##` for top-level sections [high] [code]
- `###` for subsections [high] [code]
- `####` sparingly, only when needed [medium] [code]

### Code fences

- Always include language tag: ` ```yaml ` / ` ```bash ` / ` ```json ` /
  ` ```typescript ` / ` ```markdown ` [high] [code]
- Use ` ```text ` for generic pseudo-code blocks that shouldn't be
  highlighted [medium] [code]

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

See SKILL.md R10 (in onboard) for the authoritative enumeration.

### Bilingual conventions (forge-specific)

- User-facing text may be Chinese (interaction messages, JOURNAL entries,
  CLAUDE.md, README user sections) [high] [readme]
- Structural keywords stay English (frontmatter keys, section IDs, profile
  names, marker attributes) [high] [code]
- SKILL.md body may mix: IRON RULES often bilingual; Process usually English;
  examples in e-commerce palette [medium] [code]

### Marker comments

- `<!-- forge:<skill> ... -->` HTML comments are machine-parseable markers [high] [code]
- Always paired (opening + closing) for wrapping blocks [high] [code]
- Attribute syntax: `key="value"` with double quotes [high] [code]
- Do NOT put markdown content inside attribute values [high] [code]

### What to avoid

- Deep nesting beyond `####` (hurts outline readability)
- Missing code-fence languages (breaks syntax highlighting in docs)
- Unpaired preserve / section markers (breaks incremental reconciliation)
- Confidence / source tags invented on the fly (R10 closed enumeration)
- English-only interaction messages in a bilingual project (user expectation)
```

## Confidence Tags

- `[high]` — ≥ 5 artifacts share the convention
- `[medium]` — convention visible in 2–4 artifacts with minor drift
- `[low]` — convention observed in 1 artifact; pattern nascent
- `[inferred]` — convention borrowed from common markdown practice without
                 direct evidence in this repo
