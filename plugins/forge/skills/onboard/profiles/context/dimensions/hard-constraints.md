---
name: hard-constraints
output-file: constraints.md
applies-to:
  - web-backend
  - claude-code-plugin
  - monorepo
scan-sources:
  - glob: "**/*.{md,ts,js,java,go,py}"
  - cli: "grep -r 'NEVER\\|MUST NOT\\|禁止\\|IRON RULE' --include=*.md"
  - glob: "CLAUDE.md"
  - glob: "CONTRIBUTING.md"
confidence-signals:
  - explicit IRON RULES section in CLAUDE.md or SKILL.md
  - banned-list in CONTRIBUTING.md / style guide
  - CI checks enforcing constraints (security scanners, linters at "error" level)
token-budget: 1000
---

# Dimension: Hard Constraints

## Scan Patterns

**Explicit IRON RULE blocks:**
```
Grep "IRON RULE" / "hard constraint" / "MUST NOT" / "NEVER" across
  *.md files (CLAUDE.md, SKILL.md, docs/**)
  → collect each statement
```

**Security rules:**
```
Grep for comments / docs referencing:
  - "secret" / "credential" / "API key" → likely secret-handling rules
  - "PII" / "personal data" → data-protection rules
  - "SQL injection" / "XSS" → injection-prevention rules
```

**CI enforcement:**
```
Read .github/workflows/*.yml / .gitlab-ci.yml
  → lint / format / security-scan / test-coverage gates
  → each CI-enforced rule becomes a constraint
```

**Custom scanning:**
- For forge-like plugins: scan SKILL.md files for C1..CN style constraints
- For web-backend: scan controllers for SQL strings, services for direct DB calls

## Extraction Rules

1. Catalogue each hard constraint as a numbered item `C1..CN`
2. Each constraint gets:
   - Short imperative title (e.g. "No business logic in controllers")
   - "Violation appearance" — how violation looks in code
   - Known locations in current code that comply / violate
3. Group by category: Security / Layering / API / Data / Style
4. If multiple sources contradict (e.g. CLAUDE.md says one thing, CI
   enforces another) → batch as conflict

## Output Template

```markdown
## Hard Constraints

These rules have zero exceptions. Violations are `must-fix` severity.

### C1 — <imperative statement>

<One-paragraph explanation of the rule and why it exists>

**Violation appearance:** <what non-compliance looks like in code>

**Enforcement:** <CI check name | pre-commit hook | code review checklist |
                  manual>

**Current known violations:** <path:line references, if any> [high] [code]

---

### C2 — <next rule>

...

---

### Content Hygiene (if applicable — claude-code-plugin kind)

### C<N> — No external project identifiers in artifacts

**Scope:** commit messages, all repo docs, all SKILL.md / agent files,
all scripts, all `.forge/` artifacts (except self-bootstrap where
`forge` is the subject).

**Forbidden:** external company / product names, internal system
acronyms, private Java/Go/Python namespaces, production infrastructure
hostnames / registries / ports / schemas, private DB / table names,
production URLs, production feature slugs.

**Allowed:** forge's own identifiers, public open-source tools
(Spring Boot, MySQL, Nacos, REST), generic business terms (Order,
Customer, Payment), `com.example.*` namespace, `{placeholder}` tokens.
```

## Confidence Tags

- `[high]` — rule declared in CLAUDE.md / CONTRIBUTING.md / SKILL.md
            AND enforced (CI / linter / grep check)
- `[medium]` — rule declared but not enforced; relies on reviewer vigilance
- `[low]` — rule inferred from a single code-review comment or commit message
- `[inferred]` — rule guessed from framework norms without explicit statement
