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
  - explicit IRON RULES section that applies to files in the current repo
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
2. Each constraint must have a concrete enforcement source from the
   **closed five-category set** (mirrors SKILL.md R16 v7 R1):
   - `archunit-rule` (e.g. `*ArchitectureTest.java` ArchUnit assertion)
   - `compile-failure` (missing required annotation breaks `javac`)
   - `test-assertion` (JUnit / contract test that fails on violation)
   - `lint-rule` at ERROR severity (PMD / checkstyle / eslint hard rule)
   - `framework-runtime-invariant` (JPA `@Id` required; bean scan rejects)
3. The enforcement source must be verified in the current repository and must
   apply to files or artifacts this repository actually contains.
4. External or parent documentation is secondary evidence. If it is not
   corroborated by current-repo enforcement, route it to a softer destination
   or omit it.
5. **Forbidden as enforcement source for Hard Constraints** (route to softer
   sections instead):
   - git-hook (`pre-push`, `pre-commit`) — bypassable via `--no-verify`,
     belongs in `delivery-conventions` Process / Quality Gates
   - team convention / "we always do X" — no automated check, belongs in
     `architecture-layers` Recommended Direction
   - documentation `should` / `must` wording — wording, not enforcement
   - architectural intent / "avoid this pattern" — design wish, belongs in
     `architecture-layers` Recommended Direction
6. Process expectations are routed to `delivery-conventions`, not this
   dimension.
7. Current business exceptions, inconsistencies, risks, and temporary caveats
   are routed elsewhere.
8. `Current known violations: none` may be written only after performing the
   inverse search implied by the constraint, AND the search command must
   appear next to the claim (e.g. inline `[cli]` source tag).
9. **Scope qualifier on "none found".** A `Hard Constraints` section
   that says "none found" MUST add an explicit scope qualifier:
   "No hard constraints found in current-repo source code; team policy
   and CI external rules not scanned." Otherwise readers may
   misinterpret silence as confirmation.

> **Stage-2 ↔ Stage-3 sync note (v7 R1):** The five-category closed
> set above mirrors SKILL.md R16. Whenever R16 is amended, this
> dimension MUST be updated in the same commit so the Hard Constraints
> rendered into `constraints.md` cannot drift from the rule LLM uses
> when classifying claims.

## Claim Classification Annotations

| Extracted fact type | Claim category | Target artifact | Target section | Min confidence |
|---------------------|----------------|-----------------|----------------|----------------|
| IRON RULE / policy with concrete enforcement location | `enforced-rule` | `constraints.md` | `## Hard Constraints` | `[high]` |
| CI/lint/static-check rule that blocks merge/build | `enforced-rule` | `constraints.md` | `## Hard Constraints` | `[high]` |
| Framework/runtime invariant that prevents execution when violated | `enforced-rule` | `constraints.md` | `## Hard Constraints` | `[high]` |

**Forbidden routes:**

- `process-rule` → route to `delivery-conventions`
- `current-caveat` → route to `anti-patterns`
- External docs without current-repo enforcement → not a hard constraint
- Repository does not contain affected files/artifacts → omit as out of scope
- `[inferred]` → not allowed in this dimension's output

## Output Template

```markdown
## Hard Constraints

Only rules with current-repo enforcement appear here. If a rule is merely a
team preference, industry practice, parent-doc instruction, or observed risk,
route it elsewhere.

### C1 — <imperative statement>

<One-paragraph explanation of the rule and why it exists>

**Enforcement:** <IRON RULE / CI check / framework constraint with location>

**Violation appearance:** <what non-compliance looks like in code>

**Current known violations:** <path references found by inverse search, or omit
this line if no inverse search was performed> [high] [code]

---

### C2 — <next rule>
```

## Confidence Tags

- `[high]` — explicitly documented and concretely enforced
- `[medium]` — not allowed for final output; downgrade by rerouting or omit
- `[low]` — not allowed for final output; omit
- `[inferred]` — not allowed in this dimension's output
