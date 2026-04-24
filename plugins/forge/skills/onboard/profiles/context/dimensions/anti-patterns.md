---
name: anti-patterns
output-file: constraints.md
applies-to:
  - web-backend
  - web-frontend
  - plugin
  - monorepo
scan-sources:
  - glob: "src/**/*.{ts,js,java,go,py,rs}"
  - glob: "plugins/*/skills/*/SKILL.md"
  - glob: "**/*.md"
confidence-signals:
  - pattern present in > 1 file
  - pattern explicitly flagged in previous review / TODO comment
  - pattern contradicts a stated convention
token-budget: 900
---

# Dimension: Anti-Patterns

## Scan Patterns

**Current caveat signals:**

- stale references to removed commands, skills, or artifact schemas
- transitional comments referencing old versions
- documented exceptions that are still live in the codebase

**Recommended-direction signals:**

- repeated soft-pattern drift that is undesirable but not enforced
- "What to avoid" guidance with multiple examples
- code smells that do not meet hard-constraint severity

**Do not extract here:**

- process expectations already covered by delivery conventions
- true hard constraints already covered by hard-constraints

## Extraction Rules

1. Separate temporary/project-specific caveats from reusable guidance.
2. Current caveats must describe present state, not timeless rules.
3. Soft guidance belongs in recommended direction, not in hard constraints.
4. Process expectations are routed to `delivery-conventions`, not this
   dimension.
5. Do not emit a standalone "technical debt table"; route each claim by type.

## Claim Classification Annotations

| Extracted fact type | Claim category | Target artifact | Target section | Min confidence |
|---------------------|----------------|-----------------|----------------|----------------|
| Temporary/project-specific caveat with direct evidence | `current-caveat` | `constraints.md` | `## Current Business Caveats` | `[medium]` |
| Temporary/project-specific caveat inferred from mixed signals | `current-caveat` | `constraints.md` | `## Current Business Caveats` | `[inferred]` |
| Soft anti-pattern guidance | `recommended-pattern` | `architecture.md` | `### Recommended Direction` | `[medium]` |
| Soft convention reminder better expressed as coding style | `recommended-pattern` | `conventions.md` | `## Delivery Conventions` or other relevant conventions section | `[medium]` |

**Forbidden routes:**

- `process-rule` → route to `delivery-conventions`
- `enforced-rule` → route to `hard-constraints`

## Output Template

### Output Template — current caveats

```markdown
## Current Business Caveats

- <temporary or project-specific caveat> [medium] [code]
- <temporary or project-specific caveat with softened wording> [inferred] [code]
```

### Output Template — recommended direction

```markdown
### Recommended Direction

- <soft anti-pattern guidance with preferred direction> [medium] [code]
```

## Confidence Tags

- `[high]` — unusual for this dimension; reserve for directly evidenced caveats
- `[medium]` — current caveat or recommended direction is evidenced but not enforced
- `[low]` — weak signal; usually omit
- `[inferred]` — allowed only for `## Current Business Caveats` with softened wording
