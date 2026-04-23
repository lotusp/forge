---
name: artifact-writing
output-file: conventions.md
applies-to:
  - claude-code-plugin
scan-sources:
  - glob: ".forge/**/*.md"
  - glob: "plugins/*/skills/*/SKILL.md"
  - grep: "forge:onboard section=" 
  - grep: "forge:preserve"
confidence-signals:
  - .forge/ artifact tree present
  - section markers with declared attributes
  - preserve-block conventions visible
token-budget: 1000
---

# Dimension: Artifact Writing Discipline

## Scan Patterns

**Artifact tree structure:**
```
Glob ".forge/**"
  → catalogue which paths are written by which skills
  → validate against skill SKILL.md's declared Output
```

**Section marker format survey:**
```
Grep "<!-- forge:onboard.*section=" / "<!-- forge:.*section="
  → collect marker attribute sets
  → detect attribute conventions (5-attr: section / profile /
     verified-commit / body-signature / generated)
```

**Preserve block usage:**
```
Grep "<!-- forge:preserve" / "<!-- /forge:preserve"
  → count instances across artifacts
  → verify pairing (opening + closing)
```

**JOURNAL.md conventions:**
```
Read .forge/JOURNAL.md
  → section pattern: "## YYYY-MM-DD — /forge:<skill> <args>"
  → content patterns: bullet list, next-step line
```

## Extraction Rules

1. Document the **artifact path schema** (what goes where)
2. Document **section marker** requirements (attributes, ordering, quoting)
3. Document **preserve block** semantics and ironclad rules
4. Document **JOURNAL.md** append-only discipline
5. Document the **output contract** each skill must honor (its SKILL.md's
   Output section)
6. Note any **smart merge** rules for incremental updates

## Output Template

```markdown
## Artifact Writing Discipline

### Path schema

\`\`\`
.forge/
├── context/                    ← project-wide, one per dimension
│   ├── onboard.md
│   ├── conventions.md
│   ├── testing.md
│   ├── architecture.md
│   └── constraints.md
├── features/                   ← one directory per feature
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
├── JOURNAL.md                  ← append-only log of all skill invocations
└── _session/                   ← transient, not committed
\`\`\`

[high] [code]

### Section marker contract

Every section in onboard.md / conventions.md / ... is wrapped in a 5-attribute
HTML comment:

\`\`\`
<!-- forge:onboard section="<id>" profile="<profile-id>" verified-commit="<git-short>" body-signature="<16hex>" generated="<YYYY-MM-DD>" -->
\`\`\`

**All 5 attributes are required, in this order, with double-quoted values.**
`verified-commit` and `body-signature` are two **separate** attributes, NOT
alternatives.

[high] [code]

### Preserve blocks (sacred)

Any human-edited content wrapped in:
\`\`\`
<!-- forge:preserve -->
...
<!-- /forge:preserve -->
\`\`\`

...is carried forward verbatim across all regeneration runs, regardless of
section rewrite status. **Preserve blocks always win over generated content.**

[high] [code]

### JOURNAL.md discipline

- Append-only — never rewrite history [high] [code]
- One section per skill invocation [high] [code]
- Format: `## YYYY-MM-DD — /forge:<skill> <args>`
- Content: bulleted facts about what was produced + next step [high] [code]

### Skill output contracts

Each skill's SKILL.md § Output section declares the exact artifact path(s)
it writes. No skill may write outside its declared output. [high] [code]

### What to avoid

- Editing an artifact's section marker attributes by hand (breaks
  incremental reconciliation)
- Removing preserve blocks silently (user content must survive)
- Editing old JOURNAL entries (breaks timeline)
- Writing to non-declared paths inside `.forge/`
- Bypassing status.mjs in the forge orchestrator (`/forge:forge` always
  consults it)
```

## Confidence Tags

- `[high]` — `.forge/` artifacts exist AND marker format consistent across files
- `[medium]` — discipline documented but not fully enforced in older artifacts
- `[low]` — only a couple of artifacts to compare; pattern nascent
- `[inferred]` — discipline derived from SKILL.md declarations without observing
                 actual artifacts
