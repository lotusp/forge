---
name: hard-constraints
output-file: constraints.md
applies-to:
  - web-backend
  - web-frontend
  - plugin
  - monorepo
scan-sources:
  - glob: "**/*.{md,ts,js,java,go,py}"
  - cli: "grep -r 'NEVER\\|MUST NOT\\|禁止\\|IRON RULE' --include=*.md"
  - glob: "CLAUDE.md"
  - glob: "CONTRIBUTING.md"
confidence-signals:
  - explicit IRON RULES section in CLAUDE.md or SKILL.md
  - banned-list in CONTRIBUTING.md / style guide
  - CI checks enforcing constraints (security scanners, linters at error level)
token-budget: 900
---

# Dimension: Hard Constraints

## Scan Patterns

**Explicit rule sources:**

- IRON RULE / MUST NOT / NEVER blocks in CLAUDE.md, SKILL.md, CONTRIBUTING.md
- CI or lint rules that turn violations into hard failures
- Framework/runtime constraints that stop execution if violated

**Custom scanning:**

- For plugin projects: artifact-writing and source-file mutation prohibitions
- For application projects: severe security/data-integrity constraints backed
  by code or policy

## Extraction Rules

1. Only extract claims that are both **stable** and **hard**.
2. Each constraint must have a concrete enforcement source.
3. Process expectations are routed to `delivery-conventions`, not this
   dimension.
4. Current business exceptions and temporary caveats are routed elsewhere.

## Claim Classification Annotations

| Extracted fact type | Claim category | Target artifact | Target section | Min confidence |
|---------------------|----------------|-----------------|----------------|----------------|
| IRON RULE / policy with concrete enforcement location | `enforced-rule` | `constraints.md` | `## Hard Constraints` | `[high]` |
| CI/lint/static-check rule that blocks merge/build | `enforced-rule` | `constraints.md` | `## Hard Constraints` | `[high]` |
| Framework/runtime invariant that prevents execution when violated | `enforced-rule` | `constraints.md` | `## Hard Constraints` | `[high]` |

**Forbidden routes:**

- `process-rule` → route to `delivery-conventions`
- `current-caveat` → route to `anti-patterns`
- `[inferred]` → not allowed in this dimension's output

## Output Template

```markdown
## Hard Constraints

These rules have zero exceptions. Violations are `must-fix` severity.

### C1 — <imperative statement>

<One-paragraph explanation of the rule and why it exists>

**Enforcement:** <IRON RULE / CI check / framework constraint with location>

**Violation appearance:** <what non-compliance looks like in code>

**Current known violations:** <path:line references, if any> [high] [code]

---

### C2 — <next rule>
```

## Confidence Tags

- `[high]` — explicitly documented and concretely enforced
- `[medium]` — not allowed for final output; downgrade by rerouting or omit
- `[low]` — not allowed for final output; omit
- `[inferred]` — not allowed in this dimension's output
