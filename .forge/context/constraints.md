# Constraints & Anti-Patterns: forge

> Kind:                 claude-code-plugin
> Generated:            2026-04-23
> Commit:               59836a2
> Generator:            /forge:onboard Stage 3 (v0.5.0-dev)
> Dimensions loaded:    hard-constraints, anti-patterns
> Historical authority:  this file carries forward C1-C8 rules from pre-v0.5.0 that the community has adopted as forge-wide discipline.

**Important:** This file is the authoritative source of hard rules for all forge development. Every new skill / agent / artifact must respect these constraints. Violations are `must-fix` severity.

---

<!-- forge:onboard source-file="constraints.md" section="hard-constraints" profile="context/dimensions/hard-constraints" verified-commit="59836a2" body-signature="e4b0f23a81c75d96" generated="2026-04-23" -->

## Hard Constraints

### C1 — Status script is the only routing authority

`skills/forge/scripts/status.mjs` is the sole basis for orchestrator routing. The forge skill MUST execute this script and read its `[ACTION]` output; it MUST NOT infer the next step from memory or context alone.

**Violation appearance:** forge skill deciding next action based on reading `.forge/` files directly and inferring state.

**Enforcement:** code review + SKILL.md R-level IRON RULE in `skills/forge/SKILL.md`.

### C2 — Interaction messages use lowercase prefix

All user-facing messages follow the format `[forge:{skill-name}]` in lowercase.

**Violation appearance:** `[FORGE:ONBOARD]`, `[Forge:Code]`, etc.

**Enforcement:** manual grep in review; pre-commit scan could catch.

### C3 — Artifact paths use nested structure

All `.forge/` artifacts follow these paths:

```
.forge/context/{filename}.md         # project-wide context
.forge/features/{slug}/{filename}.md # feature-level artifacts
.forge/features/{slug}/tasks/T{NNN}-summary.md  # per-task summaries
```

**Violation appearance:** old flat paths like `.forge/conventions.md`, `.forge/clarify-{slug}.md`.

### C4 — Skill references use current names

`clarify / design / code / inspect / test / onboard / forge` are the 7 canonical names in v0.5.0.

**No references to `/forge:calibrate` or `/forge:tasking` in active documentation.** These were absorbed in v0.5.0.

Historical mentions allowed only in:
- v0.5.0 migration guides
- JOURNAL entries from before v0.5.0
- CHANGELOG

### C5 — Inspect skill modifies no source files

`inspect` is strictly read-only. It does not suggest code edits inline — only reports findings with line:number references. Fixes are then routed back to `code`.

### C6 — Code skill does not exceed task scope

`code` only modifies files listed in the task's Scope section in plan.md. If a task reveals need for additional file changes, trigger Scope Creep Protocol (pause + ask user) — do NOT silently expand.

### C7 — Agents do not write artifacts

`forge-explorer`, `forge-architect`, `forge-reviewer` return report text to the calling skill. They never `Write` directly. The calling skill (`clarify`, `design`, `inspect`) is responsible for artifact persistence.

### C8 — No external project identifiers in artifacts

**Scope:** commit messages (subject/body/footer), all repo docs (`README.md`, `CLAUDE.md`, `docs/**`), all SKILL.md / agent files, all scripts, all `.forge/` artifacts.

**Forbidden:**
- External company / product / internal-system names (including 3-5 letter acronyms used inside a company)
- External Java/Go/Python namespaces (`com.{company}.*` patterns)
- External infrastructure hosts / registry domains / production ports / production schema names
- External DB names / table names / production URLs / production feature slugs

**Allowed:**
- forge's own identifiers (skill names, agent names, artifact paths)
- Public open-source tools & protocols (Spring Boot, MySQL, Nacos, REST)
- Generic business nouns (`Order`, `Customer`, `Payment`)
- `com.example.*` namespace
- `{placeholder}` tokens

**Exception:** `.forge/context/onboard.md` self-bootstrap artifacts may use forge's real identifiers — because forge IS the target project in the bootstrap.

**Violation appearance:** commit messages mentioning a specific client name; example code paths using `com.{brand}.{product}.*`; docs with specific registry domain instead of placeholder.

### C9 — Every fact carries a confidence tag

Per SKILL.md R10, every fact in an onboard / context artifact carries `[high]` / `[medium]` / `[low]` / `[inferred]` confidence tag. May additionally carry a source tag (`[code]` / `[build]` / `[config]` / `[readme]` / `[cli]`) and a `[conflict]` flag. No invented tags.

### C10 — Section markers use 6 attributes, exact order

Per SKILL.md R9, every section marker in onboard.md or context files uses:

```
<!-- forge:onboard source-file="<file>.md" section="<id>" profile="<profile-path>" verified-commit="<git-short>" body-signature="<16hex>" generated="<YYYY-MM-DD>" -->
```

All 6 attributes required, in this order, double-quoted. `verified-commit` and `body-signature` are independent (not alternatives).

<!-- /forge:onboard section="hard-constraints" -->

---

<!-- forge:onboard source-file="constraints.md" section="anti-patterns" profile="context/dimensions/anti-patterns" verified-commit="59836a2" body-signature="92d37f8b04e1a586" generated="2026-04-23" -->

## Anti-Patterns

### AP1 — Large-scale string-concat SKILL.md without IRON RULE grouping

**现状:** New skills may accumulate IRON RULES as unnumbered bullets interleaved with prose, making them hard for LLM to parse as discrete constraints.

**问题:** LLM may skip rules buried in Process prose; rules cannot be cross-referenced.

**正确做法:** Each IRON RULE gets its own `### R<N> — <short title>` heading and its own paragraph body. Skills > 300 lines should use this structure.

### AP2 — Cross-document rule reference without inline backup

**现状:** v0.4.0 T015 revealed: when a rule is stored only in `reference/<topic>.md` and not echoed in SKILL.md body, first-run LLMs don't load the reference file and violate the rule.

**问题:** Silent rule violations that pass walkthrough review but fail on actual execution.

**正确做法:** Key rules (marker format, tag enumeration, hash algorithm) must be **inline** in SKILL.md IRON RULES section, with reference files carrying only detailed algorithms / edge cases.

### AP3 — Placeholder syntax in Wire Protocol examples

**现状:** `verified="<hash>"` in examples leads LLMs to output literal `<hash>` in production.

**问题:** Non-functional markers that break incremental-mode reconciliation.

**正确做法:** Use concrete literal values in all format examples — `verified-commit="a3f2c1d4"`, `body-signature="9f8e7d6c5b4a3210"`. Design skill R18 enforces this across all "wire protocol" designs.

### AP4 — Silent Stage-transition drift

**现状:** v0.5.0 T030 revealed: Skill tool sub-agents may stop at Stage 2 despite SKILL.md explicitly requiring Stage 3.

**问题:** First-run produces incomplete artifacts (onboard.md but no conventions.md).

**正确做法:** Use "Common LLM trap" callouts + positive "Continue now to Step N" instructions at stage boundaries. Confirm this via a fresh-session Skill invocation (not the same session where edits were made).

### AP5 — Ambiguous "or" between required items

**现状:** v0.4.0 T012b revealed: "A or B" can be read as either "A union B" (both) or "A xor B" (one).

**问题:** LLM misinterprets and provides only one when both are required.

**正确做法:** Explicit language — "A AND B, both required, NOT alternatives" plus ✅/❌ examples.

### AP6 — Private project identifiers leaking into public artifacts

**现状:** Before v0.3.x, skill templates used client-specific class names, package paths, infrastructure domains.

**问题:** Leaks private information to public repo; reduces template reusability.

**正确做法:** C8 Content Hygiene rule + canonical e-commerce example palette (Order / Customer / Product / Payment / `com.example.shop.*`).

<!-- /forge:onboard section="anti-patterns" -->

---

## Known Technical Debt

| ID | Location | Description | Priority |
|----|----------|-------------|----------|
| TD-008 | `skills/onboard/SKILL.md` | Skill tool session-cache issue causes Stage 3 to skip on same-session invocation; verification requires fresh session | Medium |
| TD-009 | all skills | `--audit <slug>` read-only compliance scan not yet implemented | Medium |
| TD-010 | CI | Pre-commit automated content-hygiene scan (C8) not yet implemented — relies on manual grep | Medium |

---

## Scope Boundaries

| Out of scope | Reason |
|--------------|--------|
| Test execution | forge analyzes and generates; doesn't run tests |
| Deployment | no deploy skill; forge is not CI/CD |
| Database migration execution | may generate migration scripts; never executes them |
| Code formatting | project's own linter owns this; forge does not interfere |
| Git operations beyond commit | never pushes, branches, or rebases autonomously |
