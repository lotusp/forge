# Forge Workflow State Machine (v0.5.0)

This document defines the authoritative state transitions for the Forge
workflow. Referenced by `/forge:forge` and `scripts/status.mjs`.

> **v0.5.0 note:** The pipeline shrank from 9 skills to 7.
> `calibrate` is absorbed into `onboard` Stage 3; `tasking` is absorbed
> into `design` Stage 4.

---

## Workflow Stages (in order)

```
onboard → clarify → design → code → inspect → test
```

(Plus `forge` itself as the orchestrator — not a stage, just routing.)

Each stage produces artifact(s) in `.forge/`. The presence of an artifact
is the canonical record that a stage is complete.

---

## Artifact → Stage Mapping

| Artifact | Stage completed |
|----------|----------------|
| `.forge/context/onboard.md` | onboard Stage 1-2 (project map) |
| `.forge/context/conventions.md` | onboard Stage 3 (conventions dimension) |
| `.forge/context/testing.md` | onboard Stage 3 (testing dimension) |
| `.forge/context/architecture.md` | onboard Stage 3 (architecture dimension) |
| `.forge/context/constraints.md` | onboard Stage 3 (constraints dimension) |
| `.forge/features/{slug}/clarify.md` | clarify for {slug} |
| `.forge/features/{slug}/design.md` | design Stage 1-3 for {slug} |
| `.forge/features/{slug}/plan.md` | design Stage 4 for {slug} (task decomposition) |
| `.forge/features/{slug}/tasks/{taskId}-summary.md` | code for {taskId} |
| `.forge/features/{slug}/inspect.md` | inspect for {slug} |
| `.forge/features/{slug}/test.md` | test for {slug} |

**Important:** some context files may not exist for certain kinds
(claude-code-plugin kind excludes `logging`, `api-design`, etc. — if
no dimension in a context file applies to the kind, the file is simply
not created). Check `.forge/context/onboard.md` header's
`Excluded-dimensions:` line to understand which were deliberately
omitted. This is **not** the same as "incomplete onboard".

---

## State Transitions

### Project-wide preconditions (gate before any feature work)

```
[start]
  │
  └── .forge/context/onboard.md missing?  → run /forge:onboard
       (onboard also generates conventions/testing/architecture/constraints
        as its Stage 3; a single invocation covers both the old onboard
        and old calibrate steps)
```

**One gate, not two.** If `.forge/context/onboard.md` exists, all
applicable context files should also exist (they're generated in the
same run). If the user previously ran v0.4.x onboard without Stage 3,
the first v0.5.0 run will smart-merge into the new format (see
onboard SKILL.md R14).

### Per-feature state machine

```
[new feature request]
  │
  ▼
CLARIFY — run /forge:clarify "<description>"
  │ produces: .forge/features/{slug}/clarify.md
  │            (+ .forge/features/{slug}/design-inputs.md if [HOW] items)
  │
  ├── self-review revise loop internally — no external state change
  │
  ▼
DESIGN — run /forge:design {slug}
  │ Stage 1-2: design.md draft (with Scenario Walkthrough + Wire Protocol)
  │ Stage 3:   embedded spec-review (may rollback to Stage 2)
  │ Stage 4:   task decomposition
  │ produces: .forge/features/{slug}/design.md + plan.md
  │
  ▼
CODE (loop) — run /forge:code {task-id}  ← repeat for each pending task
  │ Step 0.5: convention gap check (may trigger focused Q&A once per project)
  │ Steps 1-N: implement + verify + summarize
  │ produces: .forge/features/{slug}/tasks/{task-id}-summary.md per task
  │ loop exits when all task IDs in plan.md have a summary file
  │
  ▼
INSPECT — run /forge:inspect {slug}
  │ scope: deterministic, from plan.md + task summaries (R23)
  │ produces: .forge/features/{slug}/inspect.md
  │ verdict: ready / needs-work / needs-redesign
  │
  ├── needs-work?      → return to CODE for must-fix items, then re-run INSPECT
  ├── needs-redesign?  → return to DESIGN
  │
  ▼
TEST — run /forge:test {slug}
  │ produces: .forge/features/{slug}/test.md + test files
  │
  ▼
[complete]
```

---

## Determining "next action" from state

The `scripts/status.mjs` script applies this logic:

```
1. If no .forge/context/onboard.md → suggest onboard
2. If explicit task ID given (T001) → suggest code {task-id}
3. If explicit feature slug given:
     - Find slug's current phase (highest artifact present)
     - Suggest the next phase after that
4. If no argument:
     - Find all in-progress features (not complete)
     - Pick the most advanced one (closest to completion wins)
     - Suggest its next phase
5. If no in-progress features and no argument:
     - Ask user for intent
```

**status.mjs authority:** the script reads `.forge/` artifact paths; it
does NOT depend on skill names. Renaming a skill does not break routing
as long as the artifact paths stay the same. (This is why v0.5.0's
skill consolidation required no change to status.mjs.)

---

## Feature phase priority (for "most advanced" selection)

When multiple features are in progress, the orchestrator continues the
one closest to completion first. Priority order (highest = most advanced):

```
inspect > code > design > clarify
```

(Note: `tasking` removed from the priority chain — design now produces
both design.md and plan.md in one invocation, so having plan.md without
design.md is no longer a valid intermediate state.)

Rationale: finishing a feature in progress is more valuable than starting
a new one from scratch.

---

## Edge cases

### "needs-work" after inspect

The `features/{slug}/inspect.md` file exists but the verdict is
`needs-work`. The orchestrator detects this by reading the first few
lines of the inspect artifact. If `needs-work` is found, it routes back
to `code` with the task IDs from the "Findings" section.

### Re-running onboard

`/forge:forge onboard` always routes to onboard. If onboard.md already
exists, the onboard skill enters Mode B (incremental) and smart-merges;
if the user passes `--regenerate`, it fully regenerates while preserving
`<!-- forge:preserve -->` blocks.

### Legacy v0.4.x artifacts

If the project has old-format context files (missing kind-aware structure),
the next `/forge:onboard` run detects this via missing marker attributes
and performs smart migration (onboard R14). Users don't need to manually
delete old files.

### Legacy command invocations

Users running `/forge:forge calibrate` or `/forge:forge tasking` after
the v0.5.0 upgrade will be informed that those commands have been
absorbed:

```
[forge] `calibrate` is no longer a separate skill in v0.5.0.
It's absorbed into onboard Stage 3. Running /forge:onboard instead.
```

```
[forge] `tasking` is no longer a separate skill in v0.5.0.
It's absorbed into design Stage 4. Running /forge:design {slug} instead.
(plan.md will be regenerated as part of design.)
```

---

## What the orchestrator does NOT do

- Does not merge, commit, or branch (git operations are out of scope)
- Does not run tests (delegates to `/forge:test`)
- Does not modify source files directly (delegates to `/forge:code`)
- Does not skip user confirmation steps required by sub-skills
- Does not choose a kind on behalf of the user (onboard Stage 1 halts
  on low confidence; user must force via `--kind=<id>`)
