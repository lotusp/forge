---
name: review
description: |
  Reviews implemented code against project conventions and feature design.
  Use after /forge:code has completed one or more tasks for a feature,
  or to review a specific file path.
argument-hint: "<feature-slug or file-path>"
allowed-tools: "Read Glob Grep"
context: fork
model: sonnet
effort: high
## Runtime snapshot
- Conventions available: !`test -f .forge/conventions.md && echo "YES — primary benchmark loaded" || echo "NO — reviewing for internal consistency only"`
- Code summaries in .forge: !`ls .forge/code-T*-summary.md 2>/dev/null | wc -l | tr -d ' '` summaries found
- Design artifacts: !`ls .forge/design-*.md 2>/dev/null | sed 's|.forge/design-||;s|.md||' | tr '\n' ' ' || echo "(none)"`

---

## IRON RULES

These rules have no exceptions.

- **Every `must-fix` finding must cite a specific section and rule from `conventions.md`.** If you cannot cite a rule, it is not a `must-fix` — downgrade to `should-fix`.
- **Confidence < 80% means the finding is dropped.** Never include uncertain findings. Precision over recall.
- **Never penalise deviations confirmed by the user.** If the code summary's "Deviations from Plan" section documents an intentional deviation, do not flag it.
- **Line numbers are required for every finding.** Vague findings ("this file has naming issues") are not acceptable.
- **Spawn all forge-reviewer agents in parallel.** Never review files sequentially — it wastes time and context.
- **`consider` findings are never blockers.** They must never use language like "problem" or "issue" — use "suggestion" or "opportunity" only.

---

## Prerequisites

Read `.forge/conventions.md`. This is the primary benchmark for review.
If it does not exist, note the absence and review only for internal
consistency and general quality — not convention compliance.

Determine the review scope from the argument:

- **Feature slug** (e.g. `phone-verification`): review all files modified
  by any `code-T*-summary.md` whose Feature field matches this slug.
- **File path** (e.g. `src/auth/phone.ts`): review that specific file only.

If the argument is a feature slug, read:
- All matching `.forge/code-T*-summary.md` files to get the list of
  changed files
- `.forge/design-{feature-slug}.md` if it exists (to verify implementation
  matches design intent)

---

## Process

### Step 1 — Collect changed files

Build the list of files to review. For a feature slug, union the "Changes
Made" tables from all matching code summaries. For a file path, the list
has one entry.

### Step 2 — Spawn forge-reviewer agents (one per file, all in parallel)

For each file in the list, spawn a **forge-reviewer** agent. Each agent
receives:
- The file content
- The full `conventions.md`
- The relevant section of the design document (if available)
- The task description from the matching plan entry (if available)
- The "Deviations from Plan" section from the matching code summary (to
  avoid penalising confirmed deviations)

All agents run in parallel. Each returns a list of findings with:
- Location (file + line number)
- Severity: `must-fix` / `should-fix` / `consider`
- Confidence score (0–100)
- Description and suggested fix

**Confidence filter:** Discard any finding with confidence < 80.

### Step 3 — Synthesise results

Collect all agent outputs. Deduplicate findings that reference the same
issue from multiple agents. Group by file, then by severity.

### Step 4 — Assess design adherence

If `.forge/design-{feature-slug}.md` exists, check:
- Were all components listed in "Component Changes" actually changed?
- Do the changes match the described intent, or do they deviate?
- Is there scope creep (files changed that are not in the design)?

### Step 5 — Determine overall verdict

- **ready**: no `must-fix` findings; `should-fix` findings are minor
- **needs-work**: one or more `must-fix` findings, or significant
  `should-fix` items
- **needs-redesign**: the implementation fundamentally diverges from
  the design, or a structural problem was found that cannot be fixed
  by editing individual files

### Step 6 — Write the review artifact

Write `.forge/review-{feature-slug}.md` following the output template.

---

## Output

**File:** `.forge/review-{feature-slug}.md`

```markdown
# Review: {feature-slug}

> 评审时间：YYYY-MM-DD
> 评审范围：{list of files reviewed}
> Conventions：{found / not found — reviewed for internal consistency only}

---

## Overall Verdict

**ready** / **needs-work** / **needs-redesign**

{One paragraph summarising the overall state of the implementation.}

---

## Findings

### `path/to/file.ts`

#### [must-fix] {Short title}
**位置：** Line N (or lines N–M)
**问题：** {What is wrong}
**依据：** conventions.md > {Section name} — "{relevant rule quoted}"
**建议：** {Specific change to make}

#### [should-fix] {Short title}
**位置：** Line N
**问题：** {What could be better}
**建议：** {Specific change}

#### [consider] {Short title}
**建议：** {Optional improvement suggestion — no obligation}

---

### `path/to/another-file.ts`

_No findings above confidence threshold._

---

## Convention Compliance Summary

| Dimension | Status | Notes |
|-----------|--------|-------|
| Architecture / layering | ✅ / ⚠️ / ❌ | |
| Naming | ✅ / ⚠️ / ❌ | |
| Logging | ✅ / ⚠️ / ❌ | |
| Error handling | ✅ / ⚠️ / ❌ | |
| Validation | ✅ / ⚠️ / ❌ | |
| Testing | ✅ / ⚠️ / ❌ | |

✅ Compliant  ⚠️ Minor issues  ❌ Violations found

---

## Design Adherence

{Was the implementation faithful to .forge/design-{slug}.md?
Note any deviations — intentional or not.}

_No design artifact available._ ← use this if design doc was not found

---

## Scope Creep

{Files changed that were not in the design or plan scope.}

_None._
```

---

## Interaction Rules

- Present the review results to the user after writing the artifact.
- If the verdict is `needs-redesign`, explain clearly why individual fixes
  are insufficient and what structural change is required.
- If the verdict is `ready` with only `consider` items, explicitly confirm
  that the implementation is ready to proceed to `/forge:test`.
- Do not suggest fixes that would change the feature's behaviour beyond
  what the design specifies — flag those as potential design changes instead.

---

## Constraints

- Do not modify any source files. This skill is strictly read-only.
- Only report findings with confidence ≥ 80. When in doubt, omit.
- Do not penalise deliberate deviations documented in code summaries.
- A `consider` finding must never block the workflow.
