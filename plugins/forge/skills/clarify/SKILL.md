---
name: clarify
description: |
  Deeply analyzes a requirement by tracing existing code paths, mapping data
  flows, and surfacing unknowns. Use when given a feature request or change
  requirement before design begins. Produces a structured clarify artifact
  that feeds into /forge:design.
argument-hint: "<requirement description>"
allowed-tools: "Read Glob Grep Bash Write"
model: sonnet
effort: high
---

## Runtime snapshot
- Existing .forge features: !`ls .forge/features/ 2>/dev/null || echo "(none)"`
- Onboard available: !`test -f .forge/context/onboard.md && echo "YES" || echo "NO — exploration will take longer"`
- Conventions available: !`test -f .forge/context/conventions.md && echo "YES" || echo "NO"`

---

## IRON RULES

These rules have no exceptions.

- **Confirm interpretation before exploring.** If the requirement is vague or ambiguous, restate it and get confirmation before reading a single file.
- **Never assume answers to business rules.** Any rule, constraint, or edge case that cannot be read directly from the code is a question — not an assumption.
- **Use forge-explorer agents for tracing.** Do not trace call chains manually from memory. Spawn agents for each distinct entry point.
- **Never write the clarify artifact before questions are answered.** If the user ends the session early, write what is known and populate Open Questions — never invent answers.
- **Do not propose solutions.** Clarify is about understanding what exists and what is needed — not how to build it. Any design suggestion belongs in `/forge:design`.
- **Q&A 必须限于需求级议题（WHAT / WHETHER），不涉及实现级（HOW / WHERE）。** 提问 "产品该不该有 X 能力"、"MVP 应支持哪些场景"、"是否向后兼容"、"如何裁剪范围" 属于需求；提问 "文件放什么路径"、"字段叫什么名"、"用什么数据结构 / 算法 / 命名规范" 属于设计。启发式：**如果一个问题的答案会直接指定某文件名、包路径、字段名、数据结构或算法选择，它属于 design 阶段，不是 clarify。** 若用户在 clarify 会话中主动提出实现级偏好（例如预先约束一些设计边界），记录在 `design-inputs.md`（需建立该文件），不放进 `clarify.md` 的 Q&A 节。
- **Every question MUST carry a `[WHAT]` or `[HOW]` label.** Step 6 performs explicit classification; Step 7 Q&A batches include ONLY `[WHAT]` items; `[HOW]` items are auto-redirected to `design-inputs.md`. A question without a label is non-compliant (R15 violation — halt and classify).
- **Self-review before writing (R16).** After synthesizing the draft in Step 8, run the 5 self-review checks (scope-creep / contradiction / unresolved-blocking / success-criteria-too-vague / gap-success-mismatch). Any issue of severity `major` or above triggers a revise pass; the revise log is embedded in `clarify.md`'s header. Minor issues are reported but do not trigger revision.

---

## Prerequisites

Read `.forge/context/onboard.md` if it exists — it provides the module map and entry
points needed to locate relevant code quickly. If it does not exist, proceed
without it; exploration will take longer.

Read `.forge/context/conventions.md` if it exists — useful context for understanding
whether the requirement fits or conflicts with current patterns.

---

## Process

### Step 1 — Understand the requirement

Parse the user's input. Identify:
- The core capability being requested (in one sentence)
- The affected business domain or user-facing feature
- Key entities, actions, and data mentioned

Restate the requirement in precise technical terms and confirm with the user
before exploring if the input is vague. Do not start code exploration until
the interpretation is confirmed.

### Step 2 — Derive the feature slug

Generate a feature slug: 2–4 English words, kebab-case, capturing the essence
of the requirement. Example: `phone-verification`, `order-export-csv`.

Check that no existing `.forge/features/{slug}/` directory uses the same slug. If a
collision exists, append a disambiguating word.

### Step 3 — Locate entry points

Based on the requirement, identify where in the codebase this feature starts:
- HTTP routes or GraphQL resolvers
- CLI command handlers
- Event/message consumers
- Scheduled job handlers
- Public API functions or exported module interfaces

Use Glob and Grep to find candidates. Read the most likely entry point files.

### Step 4 — Spawn forge-explorer agents

For each distinct entry point (or code path) identified, spawn a
**forge-explorer** agent. Each agent traces one path end-to-end and returns:
- The full call chain (with `file:line` references)
- Data flow (what data enters, how it transforms, where it goes)
- External dependencies encountered (third-party services, queues, DBs)
- Side effects observed (writes, events emitted, notifications sent)

Run agents in parallel when multiple entry points exist.

If the feature is entirely **new** (no existing code path to trace), skip
this step. Move directly to Step 5 and note that the implementation gap
covers the full requirement.

### Step 5 — Synthesise findings

Merge the agents' outputs. Build a single picture of:
- The current implementation (if any)
- All affected components and their relationships
- Where the gaps are (what doesn't exist yet that the requirement needs)

### Step 6 — Identify + classify unknowns

Review the synthesised picture and list everything that **cannot be determined
from the codebase alone**:
- Business rules not encoded in code (pricing logic, eligibility rules)
- External system behaviour (third-party API contracts, SLA expectations)
- Runtime configuration (feature flags, environment-specific values)
- Implicit requirements not stated (edge cases, error behaviour, scale)
- Decisions with non-obvious correct answers (security trade-offs, UX choices)

**Classify each unknown with a mandatory label (R15):**

| Label | Goes to | Goes where | Example |
|-------|---------|-----------|---------|
| `[WHAT]` | Step 7 Q&A batch | `clarify.md` § Resolved Questions | "MVP 应支持哪些 X?" "是否向后兼容?" "是否暴露 Y 能力给用户?" |
| `[HOW]` | Auto-redirect (no user interaction in clarify) | `design-inputs.md` (pre-design constraint memo) | "Y 文件放什么路径?" "Z 字段叫什么?" "用什么数据结构?" |

**Classification heuristic:** "If the answer directly specifies a file
path, package name, field name, data structure, or algorithm choice, it's
`[HOW]` — defer to design."

**Enforcement (R15):** no question may enter Step 7 without a label.
If you discover an unclassified item mid-Q&A, stop, classify it, route
it, then resume.

**Process for `[HOW]` items:**

1. Do NOT ask the user — these are implementation decisions, deferred to design
2. Append to `.forge/features/{slug}/design-inputs.md` under a section like
   `## Open Design Space (from clarify)`
3. Mark each as `DI-<N>` and include the original context (why it came
   up during clarify)

**User-volunteered `[HOW]` preferences:** if the user proactively states
implementation preferences during the clarify conversation (pre-constraining
design space), record them in `design-inputs.md` under a section like
`## User-provided Preconstraints`. Do NOT put them in `clarify.md` Q&A.

### Step 7 — Ask structured questions (`[WHAT]` only)

Only `[WHAT]`-labelled items from Step 6 enter this step. Group by
importance and ask the user to resolve them. Present in batches of at
most 5. For each question:
- State the question clearly (include `[WHAT]` label for traceability)
- Explain why it matters (what design decision it unblocks)
- Offer options where you can, with a recommendation if applicable

```
[forge:clarify] Questions — batch 1 of N

1. [WHAT] {Question}
   Why it matters: {Impact on design}
   Options: A) ... B) ...  (Recommend A because ...)

2. [WHAT] {Question}
   Why it matters: {Impact on design}

...

Please answer each. Type "skip" to defer any item to Open Questions.

({M} [HOW] items already auto-routed to design-inputs.md — no action needed from you.)
```

After each batch is answered, incorporate the answers and ask the next batch
if there is one.

### Step 8 — Synthesize draft + Self-review (R16)

**8.1 — Synthesize draft**

Build the clarify.md draft from:
- Intent (Step 1 restatement)
- Scope (Step 2-5 findings)
- Resolved Questions (Step 7 Q&A)
- Gaps (Step 5 synthesis)
- Success Criteria (derived from user's stated goals + Q&A)
- Open Questions (anything `skip`ped in Step 7)

**8.2 — Self-review against 5 checks**

Before writing the artifact, run the draft through 5 self-review checks:

| # | Check | Failure signal |
|---|-------|---------------|
| 1 | `scope-creep` | Any `[HOW]` item slipped into Resolved Questions |
| 2 | `contradiction` | Any Gap contradicts onboard.md facts |
| 3 | `unresolved-blocking` | Any Open Question marked blocking (should block, not defer) |
| 4 | `success-criteria-too-vague` | Any Success Criterion without a verifiable method (e.g. "works well") |
| 5 | `gap-success-mismatch` | Gaps do not collectively cover all Success Criteria |

**8.3 — Severity + revise decision**

For each failed check, assign severity:
- `major` — contradicts IRON RULES, breaks design downstream, or
  means a key requirement is missing/wrong → MUST revise
- `minor` — imperfect phrasing, redundancy, ambiguity that won't
  block design → record but do not revise

**8.4 — Revise (if needed)**

If ≥ 1 major issue found:
1. Apply fixes to the draft (reclassify questions, tighten criteria, add
   missing gaps, etc.)
2. Re-run the 5 checks on revised draft
3. Cap revise iterations at 3; if issues persist at iteration 3, promote
   remaining issues to Open Questions and proceed

**8.5 — Embed self-review log**

The artifact's header MUST carry a self-review log comment:

```markdown
<!-- clarify:self-review iterations=<N> checks-run=5 majors-fixed=<M> minors-reported=<K> final=<pass|conditional-pass> -->
```

Example:

```markdown
<!-- clarify:self-review iterations=2 checks-run=5 majors-fixed=1 minors-reported=2 final=pass -->
```

This log is embedded once at the top of `clarify.md` (between the title
and the first `##` heading).

### Step 9 — Write the clarify artifact

Write `.forge/features/{feature-slug}/clarify.md` following the output
template, with the self-review log embedded per Step 8.5.

### Step 10 — Append to JOURNAL.md

Append one entry to `.forge/JOURNAL.md`:

```markdown
## YYYY-MM-DD — /forge:clarify {feature-slug}
- 产出：.forge/features/{slug}/clarify.md + {N} design-inputs entries
- Q 分类：{N}[WHAT] + {M}[HOW]（前者 Q&A，后者 design-inputs.md 自动路由）
- Self-review：{iterations} 轮，{majors-fixed} 个 major 修复，{minors-reported} 个 minor 报告
- 未知项：{N} 个（blocking: {n}, deferred: {n}）
- 下一步：/forge:design {slug}
```

---

## Output

**File:** `.forge/features/{feature-slug}/clarify.md`

See [output-template.md](reference/output-template.md) for the complete artifact template.

---

## Interaction Rules

- **Confirm your interpretation first** before exploring if the requirement
  is vague or ambiguous.
- **Do not assume answers to unknowns.** Every business rule or edge case
  not readable from code must be listed as a question.
- **Batch questions, do not dump them all at once.** Present the most
  important 5 first.
- If the user says "just proceed" for a question, record a reasonable
  assumption in Assumptions Made and move on.
- If the user ends the session early, write the artifact with what is known
  and populate Open Questions.
- Self-review (Step 8) MUST run before writing; do not skip even if the
  draft "looks fine".

---

## Constraints

- Do not modify any source files. This skill is read-only.
- Do not propose solutions or design decisions.
- Do not invent answers to unknown business rules.
- Do not ask a question without classifying it as `[WHAT]` or `[HOW]` first (R15).
- Do not write `clarify.md` without the embedded self-review log header (R16).
- Do not skip self-review even on "obviously clean" drafts — the whole
  point is catching issues you can't see.
