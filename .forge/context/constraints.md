# Constraints: forge

> Kind:      claude-code-plugin
> Generated: 2026-04-23
> Commit:    9dbca95
> Generator: /forge:onboard (v0.5.0-dev)

<!-- forge:onboard source-file="constraints.md" section="hard-constraints" profile="context/dimensions/hard-constraints" verified-commit="9dbca95" body-signature="6686507870e5aa90" generated="2026-04-23" -->

## Hard Constraints

These rules have zero exceptions. Violations are `must-fix` severity.

### C1 — Skills are read + write-to-.forge/ only

No skill may modify project source files, configs, or manifests. Every skill's write permission is limited to `.forge/` paths declared in its `allowed-tools` and Output section.

**Violation appearance:** `Write` calls to non-`.forge/` paths inside a skill's execution [high] [code]

**Enforcement:** SKILL.md Constraints section + code review [medium] [readme]

**Current known violations:** none observed [high] [code]

---

### C2 — Never proceed by guessing; halt when context is insufficient

When a required input is absent or confidence is below threshold, a skill MUST surface a structured halt message rather than proceeding with assumptions.

**Violation appearance:** skill generating content without sufficient evidence; "N/A", "TBD", "unknown" values in artifact rows [high] [code]

**Enforcement:** IRON RULES R3, R4, R7 in onboard; "Pause before guessing" design principle [high] [readme]

**Current known violations:** none [high] [code]

---

### C3 — Scope discipline; skills do not exceed their declared role

`code` does not redesign; `design` does not implement; `inspect` does not modify source. If a task requires broader scope than stated, stop and surface it.

**Violation appearance:** skill writing outside its declared artifact paths; implementing logic during design phase [high] [code]

**Enforcement:** per-skill Constraints section in SKILL.md [high] [code]

---

### C4 — No external project identifiers in artifacts or skill files

Commit messages, docs, SKILL.md files, agent files, profile files, and `.forge/` artifacts must not contain real external company/product names, internal system acronyms, private namespaces, production hostnames/registries/ports, or private DB/table names.

**Allowed:** forge's own identifiers, public open-source tool names (Spring Boot, MySQL, Nacos), generic business terms (Order, Customer, Payment), `com.example.*` namespace, `{placeholder}` tokens.

**Violation appearance:** `com.<real-company>.*` namespace, specific production hostnames, private feature slugs [high] [readme]

**Enforcement:** manual review; grep scan in code review [medium] [readme]

---

### C5 — Preserve blocks are sacred

Any `<!-- forge:preserve -->...<!-- /forge:preserve -->` block in any forge artifact MUST be carried forward verbatim in every incremental update or regeneration. These blocks always win over generated content.

**Violation appearance:** preserve block content absent from regenerated artifact [high] [code]

**Enforcement:** R5 in onboard SKILL.md; incremental-mode algorithm [high] [code]

---

### C6 — Section markers must be complete (all 6 attributes)

Every forge artifact section marker must carry all 6 attributes in the exact order: `source-file`, `section`, `profile`, `verified-commit`, `body-signature`, `generated`. Missing, reordered, or merged attributes break incremental reconciliation.

**Violation appearance:** marker with fewer than 6 attributes; `verified="..."` instead of separate `verified-commit` + `body-signature` [high] [code]

**Enforcement:** R9 in onboard SKILL.md; `/forge:inspect` structural check [high] [code]

<!-- /forge:onboard section="hard-constraints" -->

<!-- forge:onboard source-file="constraints.md" section="anti-patterns" profile="context/dimensions/anti-patterns" verified-commit="9dbca95" body-signature="a66e4dab2e3fcff8" generated="2026-04-23" -->

## Anti-Patterns

### AP1 — Stale deprecated skill references

**Status:** Found in approximately 5 profile files and 1 SKILL.md file (test/SKILL.md line 51) — references to `/forge:calibrate` which no longer exists as a standalone skill since v0.5.0.

**Problem:** These references mislead users and new contributors into thinking a separate `calibrate` step is required. They also indicate the files were not updated during the v0.5.0 consolidation.

**Correct approach:** Replace all `/forge:calibrate` references with the correct v0.5.0 equivalent: `/forge:onboard` (which covers Stage 3 context generation that calibrate formerly did).

**Found in:** ~5 profile files, 1 SKILL.md, 1 reference file [medium] [cli]

---

### AP2 — Skills writing outside declared output contracts

**Status:** Not observed in current code. Preemptive constraint from design principles.

**Problem:** A skill writing to paths not declared in its Output section breaks the artifact isolation model and makes cross-skill dependencies unpredictable.

**Correct approach:** Audit any `Write` call's path against the skill's declared output paths. [inferred]

---

### AP3 — Invocation message using wrong prefix format

**Status:** Not observed. Known risk from anti-patterns dimension scan.

**Problem:** Using capitalized `[FORGE:` in interaction messages instead of lowercase `[forge:` breaks the consistent user-facing pattern established across all 7 skills.

**Correct approach:** All skill interaction messages use `[forge:<skill-name>]` lowercase prefix. [inferred]

---

## Known Technical Debt

| ID | Location | Description | Priority |
|----|----------|-------------|----------|
| TD-001 | `plugins/forge/skills/test/SKILL.md:51` | References deprecated `/forge:calibrate` | Medium |
| TD-002 | `plugins/forge/skills/onboard/profiles/core/entry-points.md:87` | References deprecated `/forge:calibrate` | Low |
| TD-003 | `plugins/forge/skills/onboard/profiles/core/data-flows.md:66` | References deprecated `/forge:calibrate` | Low |
| TD-004 | `plugins/forge/skills/onboard/reference/incremental-mode.md:275` | References deprecated `/forge:calibrate` | Low |

---

## Scope Boundaries

| Out of scope | Reason |
|-------------|--------|
| HTTP API design | Plugin has no HTTP surface |
| Database schema | Plugin has no persistence layer |
| Authentication/Authorization | Handled by Claude Code client |
| Deployment pipelines | Plugin is distributed via marketplace, no deployment artifacts |
| Monorepo workspace coordination | Plugin is a single-package unit |

<!-- /forge:onboard section="anti-patterns" -->
