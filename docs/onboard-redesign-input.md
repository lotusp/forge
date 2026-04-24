# Onboard Redesign Input

## Purpose

This document is an input brief for `/forge:clarify` and `/forge:design` for the next iteration of `/forge:onboard`.

It is intentionally **not** a formal `.forge/features/...` artifact. Its role is to help Forge produce clarify/design outputs that stay aligned with the intended redesign direction.

---

## Problem Statement

The current `/forge:onboard` implementation has moved beyond the "coverage too shallow" stage. The main issue is now **trustworthiness and classification discipline**:

- some high-confidence facts are wrong
- some inferred architecture patterns are written as enforced rules
- some process expectations are written as hard constraints
- some local development / configuration guidance is not executable from the repo as scanned

This weakens the value of `.forge/context/` as a reliable foundation for later `clarify`, `design`, `code`, `inspect`, and `test` work.

The redesign goal is to move `/forge:onboard` from a **prompt-driven summarizer** to an **evidence-first context compiler**.

---

## Product Goal

`/forge:onboard` should produce context that helps both AI and humans:

1. understand the current implementation when given a new requirement
2. design an appropriate future solution based on the current codebase shape
3. quickly locate the files / modules / tests likely to be changed once a solution is chosen
4. find project expectations in `.forge/context/` so generated code matches architecture, coding, testing, and delivery requirements

The output should optimize for **reliable code understanding and change navigation**, not for acting as a runbook or operations manual.

---

## Non-Goals

The redesigned `/forge:onboard` should not try to be:

- a local setup guide
- a deployment runbook
- an environment operations manual
- a substitute for active debugging / log inspection
- a complete project wiki

If a piece of information depends heavily on environment state, secrets, deployment topology, external config servers, or local machine setup, it should be excluded unless the evidence is unusually strong and the information materially affects code understanding.

---

## Redesign Direction

The redesign should follow this internal model:

1. extract evidence first
2. classify each claim before writing
3. render claims only into the artifact type that matches their meaning

In other words, the pipeline should conceptually be:

`scan codebase -> build evidence -> classify claims -> render context artifacts`

The redesign does **not** need to expose intermediate data structures to users. The evidence and classification layers are internal control mechanisms for the skill.

---

## Required Output Artifacts

The target output set remains:

- `.forge/context/onboard.md`
- `.forge/context/architecture.md`
- `.forge/context/conventions.md`
- `.forge/context/testing.md`
- `.forge/context/constraints.md`

No new standalone `delivery.md` file is needed. Delivery expectations should live inside `conventions.md`.

---

## File-Level Responsibilities

### `onboard.md`

Primary purpose:

- explain what the system is
- explain how the codebase is organized
- help locate likely change points

It should act as:

- a system map
- a module map
- a change navigation guide

Suggested section intent:

- What This Is
- Tech Stack
- Module Map
- Entry Surface
- Domain Model
- Integration Map
- Change Navigation Map
- Known Ambiguities

It should avoid:

- local startup steps
- config copy commands
- deployment operations
- environment-specific URLs and values
- low-value miscellaneous notes

### `architecture.md`

Primary purpose:

- document real structural boundaries
- separate enforced architecture from recommendation

Suggested sections:

- Observed Structure
- Enforced Rules
- Recommended Direction

Strict rule:

- anything not supported by code/tests/static checks/framework constraints must not appear under Enforced Rules

### `conventions.md`

Primary purpose:

- tell AI and humans how new code should look
- capture delivery expectations together with coding conventions

Suggested section intent:

- Naming Conventions
- API Conventions
- Error Handling Conventions
- Logging Conventions
- Validation Conventions
- Persistence / Mapping Conventions
- Integration Conventions
- Delivery Conventions

Delivery Conventions should include:

- commit message expectations
- task-to-commit granularity
- testing expectations before completion
- `.forge` artifact update expectations where applicable
- summary / review expectations if they are project-standard

### `testing.md`

Primary purpose:

- explain how the project is tested today
- guide what tests should be added for future changes

Suggested section intent:

- Testing Stack
- Test Layout
- Test Base / Infrastructure
- Mock Strategy
- Test Data Patterns
- Coverage / CI Gates
- Change-Type to Test-Type guidance

### `constraints.md`

Primary purpose:

- capture true boundaries and active caveats without mixing categories

Suggested sections:

- Hard Constraints
- Process / Quality Gates
- Current Business Caveats

Strict rule:

- process expectations must not be written as hard constraints
- current business exceptions must not be written as timeless architectural rules

---

## Claim Classification Model

Each claim should be classified internally before rendering.

Recommended categories:

- `fact`
- `inference`
- `enforced-rule`
- `recommended-pattern`
- `process-rule`
- `current-caveat`

Expected artifact mapping:

- `fact`
  - mainly `onboard.md`
  - sometimes `testing.md` or `conventions.md`

- `inference`
  - only allowed in limited form
  - mostly `onboard.md`
  - never promoted into constraints or enforced architecture

- `enforced-rule`
  - `architecture.md` -> Enforced Rules
  - `constraints.md` -> Hard Constraints

- `recommended-pattern`
  - `architecture.md` -> Recommended Direction
  - `conventions.md`

- `process-rule`
  - `conventions.md` -> Delivery Conventions
  - `constraints.md` -> Process / Quality Gates

- `current-caveat`
  - `constraints.md` -> Current Business Caveats
  - optionally echoed briefly in `onboard.md` -> Known Ambiguities if it affects change planning

---

## Evidence Discipline

### Confidence expectations

`high`

- direct evidence from source/build/config with no known conflict
- or multiple consistent sources
- counts only if scriptable and exact

`medium`

- evidence is present but partial
- or sources disagree slightly
- or the pattern is strong but not exhaustive

`low`

- based on a small sample
- based mainly on docs / README / comments

`inferred`

- best-effort interpretation
- should be rare
- should never support rules phrased as MUST / NEVER / ONLY / ENFORCED

### Hard evidence rules

- conflicting evidence must never be rendered as `high`
- count-based claims must come from deterministic extraction
- route/method claims must come from route definitions, not naming intuition
- executable guidance must pass existence checks before being emitted

---

## What Should Be Reduced or Removed

The redesign should intentionally reduce or exclude these content types from core output unless evidence is especially strong and directly useful for code understanding:

- local development command blocks
- Docker startup commands
- config template copy instructions
- deployment command details
- environment-specific URLs / registry paths / secret paths
- cron expressions and TTL values
- representative API calls with exact verb/path unless deterministically extracted
- approximate counts
- miscellaneous notes sections used as overflow buckets

Rationale:

These items are often expensive to keep accurate and are less important than code understanding. Wrong execution guidance is more harmful than missing execution guidance.

---

## Key New Capability To Add

The most important new section to add is a **Change Navigation Map** in `onboard.md`.

This should answer questions like:

- when changing order creation, where do I usually look first?
- when changing pricing or approval, which controllers/services/entities/events/tests are typically involved?
- when changing integration X, where are the inbound adapters, outbound clients, mapping points, retries, and related tests?

This section should be derived from real code relationships and should prioritize developer usefulness over narrative completeness.

---

## Design Constraints For The Redesign

The redesign should preserve the current strengths of `/forge:onboard` where possible:

- kind-aware generation
- separation of `onboard.md` and additional context files
- incremental update support
- preserve block survival
- conflict visibility
- section markers and structured artifact metadata

The redesign should improve:

- factual accuracy
- claim classification discipline
- trustworthiness of confidence labels
- usefulness for change navigation
- separation between code-understanding content and execution/runbook content

---

## Success Criteria

The redesign should be considered successful if it achieves all of the following:

1. `onboard.md` becomes primarily a code-understanding and change-navigation document, not a local runbook
2. `architecture.md` clearly separates observed structure, enforced rules, and recommendations
3. `constraints.md` clearly separates hard constraints, process gates, and current business caveats
4. `conventions.md` includes both coding conventions and delivery conventions without mixing in unstable caveats
5. `testing.md` describes actual test strategy without over-generalizing from a few examples
6. unsupported or conflicting claims are downgraded or omitted instead of being written confidently
7. count-based and route-based claims are deterministic where present
8. output trustworthiness improves even if some low-value content is removed

---

## Questions Clarify/Design Should Resolve

These are the most useful questions for the formal Forge flow to answer.

### For `/forge:clarify`

- What exact user/developer problems should `Change Navigation Map` solve?
- Which current sections are essential vs optional for the redesigned `onboard.md`?
- Which types of execution-layer information should be excluded by policy?
- How should delivery expectations be integrated into `conventions.md` without making that file noisy?
- What minimum confidence/verification bar should a claim meet before it is allowed into each artifact?

### For `/forge:design`

- What is the internal representation of an evidence item?
- How should claim classification be implemented in a way that stays stable under long prompts?
- Which current profiles should be rewritten, split, or removed?
- Which deterministic extraction helpers/scripts are needed first?
- How should `Change Navigation Map` be generated from code structure without becoming speculative?
- How should ambiguity/conflict reporting appear in the final artifacts?
- What validation or self-check rules should be added so future onboard runs catch these mistakes automatically?

---

## Suggested Priority

If the redesign is split into phases, the recommended order is:

1. tighten evidence/confidence rules
2. enforce claim classification and artifact boundaries
3. reduce unstable execution-layer content
4. add Change Navigation Map
5. improve deterministic extraction for routes/counts/dependencies

This prioritizes trustworthiness first and expansion second.
