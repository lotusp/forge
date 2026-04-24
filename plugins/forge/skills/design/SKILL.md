---
name: design
description: |
  Produces a concrete technical design AND an executable task plan for a
  feature, grounded in existing codebase conventions and prior requirement
  analysis. Absorbs the task-decomposition responsibility previously held
  by the deprecated /forge:tasking skill.

  Execution is four-stage:
    Stage 1 — ingest clarify.md + context files; understand scope and gaps
    Stage 2 — explore approaches; write design.md draft; mandatory Scenario
              Walkthrough (3 scenarios); mandatory Wire Protocol Literalization
              for any persistence / API / message format
    Stage 3 — embedded spec-review against clarify.md Success Criteria and
              Gaps; HARD BLOCK on uncovered items (may rollback to Stage 2
              at the decision level)
    Stage 4 — task decomposition → plan.md (independent file); mandatory
              T{last} docs-update task kind-driven

  Use after /forge:clarify has produced a clarify artifact, or when the
  user provides sufficient context directly.
argument-hint: "<feature-slug>"
allowed-tools: "Read Glob Grep Bash Write"
model: sonnet
effort: high
---

## Runtime snapshot
- Existing .forge features: !`ls .forge/features/ 2>/dev/null || echo "(none)"`
- Existing clarify artifact: !`test -f .forge/features/$1/clarify.md && echo "YES" || echo "NO"`
- Existing design-inputs: !`test -f .forge/features/$1/design-inputs.md && echo "YES — pre-constraints from clarify" || echo "(none)"`
- Onboard kind: !`grep -oE '^> Kind:\s+\S+' .forge/context/onboard.md 2>/dev/null | awk '{print $3}' || echo "(unknown — run /forge:onboard first)"`
- Conventions available: !`test -f .forge/context/conventions.md && echo "YES — will enforce" || echo "NO — design will be unconstrained"`
- Testing strategy available: !`test -f .forge/context/testing.md && echo "YES" || echo "NO"`
- Architecture rules: !`test -f .forge/context/architecture.md && echo "YES" || echo "NO"`
- Hard constraints: !`test -f .forge/context/constraints.md && echo "YES" || echo "NO"`
- Highest existing Task ID: !`grep -roh 'T[0-9][0-9][0-9]' .forge/features/*/plan.md 2>/dev/null | sort -u | tail -1 || echo "(no prior plans)"`

---

## IRON RULES

These rules have no exceptions. Numbered for cross-skill reference.

### R1 — Four-stage hard isolation (Stage 1 ⊥ 2 ⊥ 3 ⊥ 4)

Each stage completes before the next begins. Stage 2 cannot mix with
Stage 3's spec-review (that would defeat the review). Stage 4 task
decomposition cannot precede Stage 3 pass (tasks must reflect a verified
design).

### R2 — Approach options come before details

For non-trivial features, present 2–3 approach options with trade-offs,
get user confirmation, THEN define the chosen approach in full detail.
Never silently pick.

For small single-option features: state "no meaningful architectural
choice; proceeding with single approach" and continue.

### R3 — Design stays at "what and why"

No specific variable names, no line-by-line algorithm internals. Those
belong in `/forge:code`. Acceptable: pseudo-code for loops, function
signatures with types, table schemas, API shape diagrams.

### R4 — Component → conventions layer mapping

Every new component MUST specify which layer it belongs to per
`.forge/context/architecture.md` (e.g. controller / service /
repository, or skill / agent / profile for plugins). A component
without layer assignment is non-compliant.

### R5 — Convention deviations must be explicit

Any deviation from `.forge/context/conventions.md` MUST be flagged
as a "Deviation" row in the Key Decisions section, with a stated
reason and a stakeholder sign-off marker. Silent deviation is
forbidden.

### R6 — Open Decisions block the design artifact

design.md may not be written if any blocking decision is unresolved.
Only items explicitly `deferred with user acknowledgement` may remain;
these must flag their dependent tasks as elevated risk in plan.md.

### R17 — Scenario Walkthrough (3 scenarios) is mandatory

Stage 2 MUST produce a `## Scenario Walkthroughs` section in design.md
with exactly 3 scenarios covering:
- 1 happy-path scenario (the typical flow)
- 2 edge-case scenarios (error / boundary / scale / migration)

Each scenario traces through the design step-by-step and explicitly
calls out the design decisions it exercises. If any scenario exposes a
design flaw (a decision that cannot satisfy the scenario), Stage 2
**halts and returns to the decision layer** — the flaw must be fixed
before Stage 3, not documented away.

Scenarios default to LLM-generated from design content; users may
supplement with custom scenarios in design-inputs.md which are then
required to be among the 3.

### R18 — Wire Protocol Literalization is mandatory for persistence / API / message formats

Any design that introduces or modifies:
- Persistent artifact formats (marker schemas, file layouts, column shapes)
- API contracts (endpoints, request/response JSON shapes)
- Message queue payloads (event schemas)
- CLI output formats
- Inter-skill handoff structures

...MUST include a `## Wire Protocol Examples` section with
**copy-paste-ready literal values**. Placeholder syntax like `<hash>`
or `<name>` is **forbidden** — use concrete literals
(`"a3f2c1d4"`, `"order-export-csv"`). The purpose is anchoring
downstream LLM executors to exact forms, not leaving room for creative
interpretation.

Small features with no new wire formats may omit this section (state
"No new wire formats" in Stage 2 summary).

### R19 — Embedded spec-review hard-blocks design.md write

Stage 3 runs the **spec-review** check against clarify.md:
- Every Success Criterion must map to ≥ 1 design component OR an
  explicit plan task (criteria may be satisfied by verification tasks
  in plan.md, not only by design components)
- Every Gap from clarify.md must have a resolution (either component
  change in design.md or task in plan.md)
- Scope-creep reverse check: no design component that isn't traceable
  to a Success Criterion / Gap

If any coverage gap remains: design.md is NOT written. Rollback to
Stage 2 is permitted AT THE DECISION LEVEL (Q5 answer = A+Q — not
limited to adding new tasks; may adjust core decisions).

### R20 — plan.md ends with a mandatory T{last} docs task

Stage 4 task decomposition MUST emit a final task of type `docs`
whose description is kind-driven (from onboard.md kind):

- plugin → README.md / CLAUDE.md updates
- web-backend → OpenAPI / CHANGELOG / docs/*
- monorepo → root README + affected sub-package READMEs

The task's verification allows "No user-facing docs touched by this
feature" as a legitimate completion result, with that statement
explicitly written to the task summary.

---

## Prerequisites

### 1. Feature context

Read `.forge/features/{feature-slug}/clarify.md`.

If it does not exist:
```
[forge:design] Missing clarify artifact

.forge/features/{feature-slug}/clarify.md not found.

Options:
  1. Run /forge:clarify "<feature-description>" first (recommended)
  2. Proceed anyway — I will ask you for the necessary context

Which do you prefer?
```

### 2. Design-inputs (optional)

If `.forge/features/{feature-slug}/design-inputs.md` exists, read it
in full. These are pre-design constraints routed from clarify's Step 6
(`[HOW]`-labelled items) plus any user-volunteered implementation
preferences. They bound Stage 2's design space.

### 3. Context files (all four)

Read:
- `.forge/context/onboard.md` — extract kind (affects R20 task template)
- `.forge/context/conventions.md` — enforce; deviations per R5
- `.forge/context/testing.md` — affects test-related tasks in Stage 4
- `.forge/context/architecture.md` — enforce layer rules per R4
- `.forge/context/constraints.md` — hard constraints (must not violate)

Files that do not exist for the current kind are skipped (per onboard's
Excluded-dimensions). Note absent files in the design header.

---

## Process

### Overview

```
╭── Stage 1: Ingest ───────────────────────────────────────────╮
│  read clarify.md + design-inputs.md + 4 context files        │
│  understand gaps, Success Criteria, constraints              │
│  surface unresolved Open Questions from clarify (halt)       │
╰──────────────────────────────────────────────────────────────╯
                              │
                              ▼
╭── Stage 2: Design draft ─────────────────────────────────────╮
│  2.1 approach options (2–3, if non-trivial)                  │
│  2.2 user confirms approach                                  │
│  2.3 component design (files, APIs, schemas, layers)         │
│  2.4 Scenario Walkthrough (R17) — 3 scenarios                │
│  2.5 Wire Protocol Examples (R18) — if applicable            │
│  2.6 Impact + risk assessment                                │
│  2.7 Open Decisions (block until resolved)                   │
╰──────────────────────────────────────────────────────────────╯
                              │
                              ▼
╭── Stage 3: Embedded spec-review (R19) ───────────────────────╮
│  match every Success Criterion to design component or task   │
│  match every Gap to resolution                               │
│  reverse check: no orphan design components                  │
│  coverage gap? → rollback to Stage 2 (decision level ok)     │
│  pass → proceed to Stage 4                                   │
╰──────────────────────────────────────────────────────────────╯
                              │
                              ▼
╭── Stage 4: Task decomposition ───────────────────────────────╮
│  4.1 decompose design into atomic tasks                      │
│  4.2 assign T{NNN} IDs (continue from highest in project)    │
│  4.3 compute dependencies                                    │
│  4.4 flag risk per task                                      │
│  4.5 append mandatory T{last} docs task (R20)                │
│  4.6 user confirms task breakdown                            │
╰──────────────────────────────────────────────────────────────╯
                              │
                              ▼
        Write design.md + plan.md + JOURNAL entry
```

---

### Step 1 — Ingest (Stage 1)

**1.1 — Read clarify.md in full**

Identify:
- Intent + Scope
- Success Criteria (numbered list — remember the count)
- Gaps (numbered G-01..G-NN)
- Resolved Questions (context for decisions already made)
- Open Questions — if any are marked blocking, halt and ask user

**1.2 — Read design-inputs.md (if exists)**

Treat every DI entry as a binding pre-constraint on Stage 2. If a DI
contradicts a Success Criterion, halt and ask user to resolve before
proceeding.

**1.3 — Read 4 context files**

Extract the constraints relevant to this feature:
- Layer that owns the new logic (architecture.md)
- Naming / error / logging / API / DB rules (conventions.md)
- Test strategy (testing.md) — determines test tasks in Stage 4
- Hard constraints (constraints.md) — must not violate

If any context file is missing that's expected for the current kind
(check onboard.md header for Excluded-dimensions), note as a caveat
in the design header.

**1.4 — Surface unresolved inputs**

If any of:
- clarify.md has an Open Question marked `blocking`
- design-inputs.md contradicts clarify.md Success Criteria
- conventions.md is absent (no rules to enforce)

...surface these to the user and halt until addressed.

---

### Step 2 — Design draft (Stage 2)

**2.1 — Approach exploration**

For non-trivial features with real architectural choice, spawn 2–3
`forge-architect` agents in parallel, each exploring a distinct
direction:

- Agent 1: straightforward extension of existing patterns
- Agent 2: cleaner approach requiring more upfront work
- Agent 3 (optional): genuinely alternative paradigm

Each agent receives the clarify artifact + design-inputs + relevant
convention sections + its assigned direction.

**For small single-option features**, skip agents and state "no
meaningful architectural choice" in Stage 2 summary.

**2.2 — Present options; user confirms**

```
[forge:design] Approach options for <feature-slug>

Option A — <name>: <one sentence>
  Pros: ...
  Cons: ...
  Estimated risk: <low/medium/high>

Option B — <name>: <one sentence>
  ...

Recommended: <A | B | ...>, because <reason>.

Confirm approach, or choose a different one?
```

Wait for user confirmation before proceeding to details.

**2.3 — Component design**

Once confirmed, define the chosen approach:

- Exact files to create / modify / delete
- What each change entails (at "what + why" level per R3)
- API contract changes (endpoints, request / response shapes)
- Data model changes (tables, fields, indexes, migrations)
- Each new component's conventions layer (R4)
- Any convention deviation (R5)

Output into the `## Component Changes` section of design.md draft.

**2.4 — Scenario Walkthrough (R17, mandatory)**

Generate 3 scenarios:
1. Happy path — the typical flow this feature exists to serve
2. Edge case A — error / timeout / external failure
3. Edge case B — scale / migration / concurrency

For each, trace through the design step-by-step. Explicitly call out
which Key Decision is being exercised at each step. Format each
scenario as:

```markdown
### Scenario <N> — <short name>

**Setup:** <preconditions>

**Flow:**
1. <step 1, naming the component + decision exercised>
2. <step 2 ...>
3. ...

**Decisions exercised:** K-<id>, K-<id>, ...

**Walkthrough result:** ✅ passes (or) ⚠ flaw — <rollback needed>
```

**If any scenario returns "⚠ flaw":** HALT Stage 2. Return to 2.3
(component design) or earlier — address the flaw in design decisions,
not in documentation. After fix, re-run all 3 scenarios. Repeat until
all pass.

**2.5 — Wire Protocol Examples (R18, when applicable)**

If the design introduces or modifies persistent / API / message /
handoff formats, add `## Wire Protocol Examples` section with
copy-paste-ready literal values:

```markdown
## Wire Protocol Examples

### <format name>

<actual literal example with concrete values>

### <next format>

<concrete values>
```

Forbidden: `<placeholder>` / `<name>` / `<hash>` syntax inside this
section. Use real strings (`"a3f2c1d4"`, `"order-export-csv"`, etc.).

If no new wire formats exist, state: "No new wire formats in this
feature." in the Stage 2 summary.

**2.6 — Impact + risk**

Identify everything that could break or require updating:
- Other modules depending on affected code
- Existing tests that will need updating
- API consumers affected by contract changes
- Configuration / env-var changes
- Migration impact (if data model changes)

Assign feature-level risk: `Low` / `Medium` / `High`.

**2.7 — Open Decisions**

Collect any decisions the LLM cannot make. Present as:

```
[forge:design] Open Decisions ({N} items)

1. <question>
   Context: <why this matters>
   Options: A) ... B) ...
   Recommend: <A | B>, because <reason>

2. ...

Please answer each.
```

Record user answers in `## Key Decisions`. If user explicitly defers
one, mark `deferred-with-acknowledgement` — this flags the dependent
task in plan.md as elevated risk.

Cannot finalise design.md until all non-deferred items are answered.

---

### Step 3 — Embedded spec-review (Stage 3, R19)

Run two-way matching between clarify.md and the Stage 2 draft:

**Forward check — every Success Criterion covered:**

```pseudo
for sc in clarify.success_criteria:
    coverage = find_coverage(sc, design.components) ∪
               find_coverage(sc, planned_tasks)     # tasks may come in Stage 4
    if coverage is empty:
        report_gap(sc)
```

**Forward check — every Gap resolved:**

```pseudo
for gap in clarify.gaps:
    resolution = find_resolution(gap, design.components) ∪
                 find_resolution(gap, planned_tasks)
    if resolution is empty:
        report_gap(gap)
```

**Reverse check — no orphan design:**

```pseudo
for component in design.components:
    traces_to = find_success_criteria_or_gap(component)
    if traces_to is empty:
        report_orphan(component)
```

**Emit spec-review output block** in design.md as the "Embedded
Spec-Review Self-Run" section. Use the literal format:

```
[forge:design] Embedded spec-review (Stage 3)

Checking design against clarify.md Success Criteria + Gaps...

Success Criteria coverage:
  ✅ #1  <criterion> → <covered by: component X / task T{NNN}>
  ✅ #2  <criterion> → <covered by: ...>
  ⚠️  #N  <criterion> → NO COVERAGE — <rollback required>

Gap coverage:
  ✅ G-01 → ...
  ⚠️  G-02 → NO RESOLUTION

Orphan design (components not traceable to SC/Gap):
  (none) ← ideal
  (or list any)

Decision: <PASS | HARD BLOCK — {N} gaps require rollback>
```

**On HARD BLOCK:** do NOT write design.md. Return to Stage 2; allow
changes at the decision level (Q5 = A+Q), not only tasks. After fix,
re-run spec-review.

**On PASS:** proceed to Stage 4.

---

### Step 4 — Task decomposition (Stage 4)

**4.1 — Decompose design into atomic tasks**

Each task must be:
- Completable in one session (< ~5 files touched, one logical concern)
- Independently verifiable (≥ 2 file-level acceptance criteria)
- Scoped to a type from the enum:
  `infra | model | migration | logic | api | ui | test | docs | skill | agent | profile | kind-def`
  (last 4 for plugin kind)

**4.2 — Assign T{NNN} IDs**

Task IDs are GLOBALLY unique across the entire project. Scan all
existing `.forge/features/*/plan.md` for the highest ID; new tasks
continue from there.

Format: `T` + 3-digit zero-padded, grown to 4 digits when needed.

**4.3 — Dependencies**

For each task, determine which other tasks must complete first. A
dependency exists when the task:
- Reads a file created by another task
- Builds on a schema / model defined by another task
- Tests behaviour implemented by another task

**4.4 — Flag risk per task**

Mark tasks `⚠ 高风险` when they:
- Touch shared infrastructure or public API contract
- Involve data migration or schema changes
- Carry a deferred Open Decision from Stage 2
- Have inherently ambiguous acceptance criteria (surface + fix; don't
  hide)

**4.5 — Append T{last} docs task (R20, mandatory)**

Final task, type `docs`, template driven by onboard.md kind:

```markdown
### T{last} — Update user-facing documentation `docs`

**描述：** 根据本 feature 实际实现的内容，更新项目的用户面向文档。

**Kind-driven scope:**
- <per-kind doc list — see plan.md output template>

**依赖：** 所有 T{NNN}（N < last）

**验收标准：**
- [ ] 所有新引入的用户面向概念在相关 doc 中有覆盖
- [ ] 过时描述已更新
- [ ] 若本 feature 未触达 user-facing 文档，task summary 明确记录
      "No user-facing documentation touched by this feature"
```

**4.6 — Confirm task breakdown (mandatory user confirmation)**

Present to user before writing plan.md:

```
[forge:design] Task breakdown for <feature-slug>

Tasks identified: N (T{first}–T{last})
High risk: n

  T{first}  [type]  <name>
  T{first+1} [type] <name>  ← depends on T{first}
  ...
  T{last}   [docs]  Update user-facing documentation

Execution order: T{first} → ...

Ready to write plan.md? (yes / adjust first)
```

Wait for confirmation. If user requests adjustments, revise and
re-confirm.

---

### Step 5 — Write artifacts

**5.1 — Write design.md**

Write `.forge/features/{feature-slug}/design.md` following the output
template. Include (in order):
- Header (feature name, date, kind, risk, revise log if any)
- Overview
- Key Decisions (including deferred items with ack)
- Component Changes
- Wire Protocol Examples (if R18 applies)
- Scenario Walkthroughs (3 scenarios per R17)
- Impact Analysis
- Embedded Spec-Review Self-Run (Stage 3 output)
- Open Decisions (deferred-with-ack only)
- Dogfooding Strategy (if applicable)

**5.2 — Write plan.md**

Write `.forge/features/{feature-slug}/plan.md` following the tasking
template. Include:
- Overview (links to design.md)
- Task list (each with description / scope / dependencies / acceptance
  criteria / risk)
- Dependency graph (ASCII or table)
- Execution order (waves, if parallelizable)
- Risk register

**5.3 — Append JOURNAL entry**

```markdown
## YYYY-MM-DD — /forge:design {feature-slug}
- 产出：.forge/features/{slug}/design.md + plan.md
- 方案：<chosen approach>, 风险：<low/medium/high>
- Scenario Walkthrough：3 场景 {pass/fail details}
- Wire Protocol Examples：{n} 种格式字面化 (or "N/A")
- Embedded spec-review：{pass | conditional-pass} — {details}
- Tasks: {N} 个 (T{first}–T{last}), 高风险: {n} 个
- 遗留决策: {M} deferred
- 下一步: /forge:code T{first}
```

---

## Output

**Files:** 
- `.forge/features/{feature-slug}/design.md`
- `.forge/features/{feature-slug}/plan.md`

See [output-template.md](reference/output-template.md) for design.md
template. plan.md template is embedded in this SKILL.md § Step 5.2
(task list shape) and the project's existing plan.md files serve as
reference.

---

## Interaction Rules

- **Approach selection is always confirmed** before writing component details
- **Open Decisions block design.md** — only deferred-with-ack may remain
- **Scenario Walkthroughs are mandatory** (R17) — cannot skip even if
  "obviously correct"
- **Wire Protocol must be literal** (R18) — cannot use `<placeholder>`
  syntax in that section
- **Embedded spec-review must pass** (R19) — hard block on any gap
- **Task breakdown is confirmed** before writing plan.md
- Keep the design at the "what and why" level (R3)
- If the clarify artifact has unresolved Open Questions, treat each as
  potentially blocking

---

## Constraints

- Do not modify any source files
- Do not include implementation code (pseudocode + signatures only)
- Do not silently choose between viable options — always surface trade-offs (R2)
- Do not skip Scenario Walkthrough even for simple features (R17)
- Do not use `<placeholder>` syntax in Wire Protocol Examples (R18)
- Do not write design.md if spec-review reports uncovered items (R19)
- Do not emit plan.md without a T{last} docs task (R20)
- All choices must be consistent with `.forge/context/conventions.md`
  OR explicitly flagged as deviations with reason (R5)
