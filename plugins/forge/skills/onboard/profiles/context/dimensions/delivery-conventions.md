---
name: delivery-conventions
output-file: conventions.md
applies-to:
  - plugin
  - web-backend
  - web-frontend
  - monorepo
scan-sources:
  - glob: "CLAUDE.md"
  - glob: ".forge/JOURNAL.md"
  - glob: ".forge/features/*/verification.md"
  - glob: "AGENTS.md"
token-budget: 900
---

# Dimension: Delivery Conventions

## Scan Patterns

- `CLAUDE.md` / `AGENTS.md` sections about commit conventions, delivery rules,
  testing before done, and artifact maintenance
- `.forge/JOURNAL.md` for observed task/commit cadence
- `.forge/features/*/verification.md` for evidence of "verification before done"

## Extraction Rules

1. Extract delivery expectations that shape how work is finished and handed
   off, not how code is written.
2. Cover these areas when evidenced:
   - task-to-commit granularity
   - testing-before-done expectations
   - `.forge` artifact update expectations
   - summary/review expectations if project-standard
3. Route descriptive guidance to `conventions.md`.
4. Route gate-like requirements to `constraints.md`.

## Claim Classification Annotations

| Extracted fact type | Claim category | Target artifact | Target section | Min confidence |
|---------------------|----------------|-----------------|----------------|----------------|
| Documented delivery convention | `fact` | `conventions.md` | `## Delivery Conventions` | `[high]` |
| Repeated observed delivery pattern | `recommended-pattern` | `conventions.md` | `## Delivery Conventions` | `[medium]` |
| Requirement that gates completion/review/acceptance | `process-rule` | `constraints.md` | `## Process / Quality Gates` | `[medium]` |

## Output Template

### Output Template — conventions.md

```markdown
## Delivery Conventions

### Task-to-commit granularity

- <delivery convention> [high] [readme]

### Testing before done

- <delivery convention> [high] [readme]

### `.forge/` artifact update expectations

- <delivery convention> [high] [readme]
```

### Output Template — constraints.md

```markdown
## Process / Quality Gates

- <gating rule> [medium] [readme]
```

## Confidence Tags

- `[high]` — explicitly documented in project instructions
- `[medium]` — strongly evidenced by repeated project practice
- `[low]` — weak pattern only; usually omit
- `[inferred]` — not allowed in this dimension's output
