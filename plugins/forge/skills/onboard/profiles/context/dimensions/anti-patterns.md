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
confidence-signals:
  - pattern present in > 1 file (replicated antipattern)
  - pattern explicitly flagged in previous review / TODO comment
  - pattern contradicts a stated convention (from conventions.md)
token-budget: 900
---

# Dimension: Anti-Patterns

## Scan Patterns

**For web-backend / monorepo:**
- SQL strings in controllers: grep `SELECT .* FROM` in `**/controllers/**`
- Business logic in route handlers: controllers with > 50 LOC or > 3
  business conditionals
- Caught-and-swallowed errors: `catch (e) {` blocks with no re-throw or logger call
- Hardcoded secrets: grep `password = "` / `apiKey = "` literals
- Shared mutable state: module-level `let counter = 0` without synchronization

**For plugin:**
- Skill directly writing to target project's source: grep Write to
  non-`.forge/` paths inside SKILL.md
- Hardcoded skill names in cross-reference: `/forge:<old-name>` after rename
- Interaction message using wrong prefix: `[FORGE:` capitalized where
  convention dictates lowercase `[forge:`
- External project identifier leak: scan all *.md for `com.<company>.*`
  patterns or specific product names

**Universal:**
- TODO / FIXME / XXX markers older than 6 months: `git blame` age check
- Commented-out code blocks (dead code): `^\\s*//` or `^\\s*#` runs > 5 lines

## Extraction Rules

1. Each anti-pattern: name + description + current code locations +
   why it's bad + preferred pattern
2. Quantify: "found in N files" rather than listing every occurrence
3. Group by severity: blocker (security / data loss) / major
   (correctness) / minor (style drift)
4. Include `AP1..APN` identifiers for traceability
5. If anti-pattern is documented in CLAUDE.md, reference that doc

## Output Template

```markdown
## Anti-Patterns

### AP1 — <short name>

**现状：** <1-2 sentence description, with file:line refs for top 3 occurrences>

**问题：** <why it's problematic>

**正确做法：** <recommended alternative>

**Found in:** <N files; top 3 refs> [high] [code]

---

### AP2 — <next>

...

---

## Known Technical Debt

| ID | 位置 | 描述 | 优先级 |
|----|------|------|--------|
| TD-001 | <file:line> | <1-line description> | 高 |
| TD-002 | <file:line> | <1-line description> | 中 |

---

## Scope Boundaries

明确不在项目职责范围内的事项：

| 超出范围 | 原因 |
|---------|------|
| <responsibility> | <reason> |
```

## Confidence Tags

- `[high]` — pattern found in ≥ 3 files AND contradicts conventions.md
- `[medium]` — pattern found in 2 files AND inferred bad from context
- `[low]` — pattern in 1 file; may be intentional edge case
- `[inferred]` — pattern is textbook-bad but not yet observed; preemptive
