---
name: inspect
description: |
  Reviews implemented code against project conventions and feature design.
  Use after /forge:code has completed one or more tasks for a feature,
  or to review a specific file path.
argument-hint: "<feature-slug or file-path>"
allowed-tools: "Read Glob Grep"
context: fork
model: sonnet
effort: high
---

## Runtime snapshot
- Conventions available: !`test -f .forge/context/conventions.md && echo "YES — primary benchmark loaded" || echo "NO — reviewing for internal consistency only"`
- Code summaries in .forge: !`ls .forge/features/*/tasks/T*-summary.md 2>/dev/null | wc -l | tr -d ' '` summaries found
- Design artifacts: !`ls .forge/features/*/design.md 2>/dev/null | sed 's|.forge/features/||;s|/design.md||' | tr '\n' ' ' || echo "(none)"`

---

## IRON RULES

These rules have no exceptions.

- **Every `must-fix` finding must cite a specific section and rule from `context/conventions.md`.** If you cannot cite a rule, it is not a `must-fix` — downgrade to `should-fix`.
- **Confidence < 80% means the finding is dropped.** Never include uncertain findings. Precision over recall.
- **Never penalise documented assumptions or deviations.** If the code summary's "Assumptions Made" or "Deviations from Plan" section documents an intentional decision, do not flag it. These sections are pre-confirmed by the developer.
- **Line numbers are required for every finding.** Vague findings ("this file has naming issues") are not acceptable.
- **Spawn all forge-reviewer agents in parallel.** Never review files sequentially — it wastes time and context.
- **`consider` findings are never blockers.** They must never use language like "problem" or "issue" — use "suggestion" or "opportunity" only.

---

## Prerequisites

Read `.forge/context/conventions.md`. This is the primary benchmark for review.
If it does not exist, note the absence and review only for internal
consistency and general quality — not convention compliance.

Determine the review scope from the argument:

- **Feature slug** (e.g. `phone-verification`): review all files modified
  by any task summary under `.forge/features/{slug}/tasks/` whose Feature field matches this slug.
- **File path** (e.g. `src/auth/phone.ts`): review that specific file only.

If the argument is a feature slug, read:
- All `.forge/features/{feature-slug}/tasks/T*-summary.md` files to get the list of
  changed files and to extract the **Assumptions Made** and **Deviations from Plan**
  sections — these are intentional and must not be penalised
- `.forge/features/{feature-slug}/design.md` if it exists (to verify implementation
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
- The full `context/conventions.md`
- The relevant section of the design document (if available)
- The task description from the matching plan entry (if available)
- The **"Assumptions Made"** section from the matching code summary (to
  avoid penalising documented assumptions — these are pre-confirmed decisions)
- The **"Deviations from Plan"** section from the matching code summary (to
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

If `.forge/features/{feature-slug}/design.md` exists, check:
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

Write `.forge/features/{feature-slug}/inspect.md` following the output template.

### Step 7 — Append to JOURNAL.md

Append one entry to `.forge/JOURNAL.md`:

```markdown
## YYYY-MM-DD — /forge:inspect {feature-slug}
- 评审文件：{N} 个
- 发现：{must-fix 数} must-fix, {should-fix 数} should-fix, {consider 数} consider
- 结论：ready / needs-work / needs-redesign
- 下一步：{/forge:test {slug} if ready, or /forge:code {task-id} if needs-work}
```

---

## Output

**File:** `.forge/features/{feature-slug}/inspect.md`

See [output-template.md](reference/output-template.md) for the complete artifact template.

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
- Do not penalise deliberate deviations documented in task summaries.
- A `consider` finding must never block the workflow.
