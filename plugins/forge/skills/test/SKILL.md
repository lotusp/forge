---
name: test
description: |
  Generates a test plan and test code for a completed feature, matching the
  project's testing conventions. Use after /forge:inspect returns a "ready"
  or "needs-work" verdict and the must-fix items have been resolved.
argument-hint: "<feature-slug>"
allowed-tools: "Read Glob Grep Write"
model: sonnet
effort: high
---

## Runtime snapshot
- Feature artifacts: !`ls .forge/features/ 2>/dev/null || echo "(none)"`
- Testing conventions available: !`test -f .forge/context/testing.md && echo "YES" || echo "NO — cannot match testing patterns without conventions"`
- Conventions available: !`test -f .forge/context/conventions.md && echo "YES" || echo "NO"`
- Existing test files: !`find . -name '*Test*' -o -name '*.test.*' -o -name '*.spec.*' 2>/dev/null | grep -v '.git' | grep -v build | grep -v node_modules | wc -l | tr -d ' '` test files found

---

## IRON RULES

These rules have no exceptions.

- **`context/testing.md` is mandatory input.** If it does not exist, stop and ask the user before proceeding — do not invent a testing approach.
- **Confirm the test case list before writing any test code.** The user may know edge cases not visible from the code. The confirmation step is not optional.
- **Never test implementation internals.** Only test observable behaviour: return values, thrown errors, side effects (DB writes, events emitted).
- **Match existing test patterns exactly.** Never introduce a new test library, assertion style, or mock strategy without flagging it as a new pattern and getting confirmation.
- **One confirmation for existing test updates.** Before modifying any existing test file, list the files and get explicit confirmation.

---

## Prerequisites

### Required

Read `.forge/context/testing.md`. This defines:
- Which test types apply: unit / integration / end-to-end / contract
- Where test files live (co-located vs separate directory)
- Naming conventions for test methods
- Mock strategy (what to mock, at which layer boundary)
- Test data patterns (factories, fixtures, builders)
- Base classes or test infrastructure to use
- Coverage expectations

If testing.md does not exist:
```
[forge:test] Missing testing conventions

.forge/context/testing.md not found. Without it I cannot match your project's
testing patterns. Please run /forge:onboard first (Stage 3 produces
testing.md), or describe your testing conventions so I can proceed.
```

### Recommended (read if they exist)

- `.forge/context/conventions.md` — additional coding conventions
- `.forge/features/{feature-slug}/design.md` — the intended behaviour to test against
- `.forge/features/{feature-slug}/inspect.md` — may flag untested scenarios
- `.forge/features/{feature-slug}/tasks/T*-summary.md` — to find implemented files
- Existing test files adjacent to the feature's files — to match patterns exactly

---

## Process

### Step 1 — Determine test strategy

From `context/testing.md`, extract the testing approach:
- Which test types apply: unit / integration / end-to-end / contract
- Where each type lives and how files are named
- Mock strategy (e.g. mock at repository boundary, never mock internal services)
- Test data tooling (factories, seeds, builders — use what exists)

If `context/testing.md` is silent on a test type this feature needs:
```
[forge:test] Testing convention gap

The feature requires {integration tests / e2e tests / contract tests},
but conventions.md does not describe the approach for this type.

How should these tests be structured? (Or should I skip this type?)
```

### Step 2 — Identify test cases

Read the design document (if available) and the implemented source files.
Derive test cases for each category:

**Happy path:** Primary success scenario for each public function, endpoint,
or behaviour. One test per entry point.

**Input validation:** One test per distinct validation rule (invalid, missing,
malformed inputs).

**Edge cases:** Boundary values (empty collections, zero, max), concurrent
concerns, large inputs.

**Failure modes:** Each expected failure — dependency unavailable, not found,
permission denied, timeout. Verify correct error response for each.

**State transitions:** If stateful (e.g. order status flow), cover valid and
invalid transitions.

Present the test case list before writing any code (mandatory):

```
[forge:test] Proposed test cases for {feature-slug}

Unit tests ({path}):
  ✓ {test case description}
  ✓ {test case description}
  ...

Integration tests ({path}):
  ✓ {test case description}
  ...

{N} test cases total. Proceed, or adjust the list?
```

Wait for confirmation or adjustments.

### Step 3 — Check existing tests for update needs

Grep for existing test files that cover the same code paths the feature
modifies. List any requiring updates:

```
[forge:test] Existing tests requiring update

These tests cover code modified by {feature-slug}:

- {path/to/test-file}
  Reason: {what changed that affects this test}

Confirm you'd like me to update these alongside the new tests.
```

Wait for confirmation before modifying any existing file.

### Step 4 — Write test code

Generate test files following the project's exact patterns:
- Match the describe/it/test block structure of existing test files
- Use the same assertion library and style (do not mix `toBe` with `assertEquals`)
- Use the same mock approach (file-level vs per-test, same mock library)
- Use factories or builders if they exist — never construct test data inline
  with `new EntityClass()` if a builder exists

For tests requiring infrastructure (real DB, real queue), add a clear
`// requires: <dependency>` comment and note them in the test plan.

### Step 5 — Update existing tests (if confirmed in Step 3)

Minimise changes — update only what is broken by the feature, not the full
test suite.

### Step 6 — Write the test plan artifact

Write `.forge/features/{feature-slug}/test.md`.

### Step 7 — Append to JOURNAL.md

Append one entry to `.forge/JOURNAL.md`:

```markdown
## YYYY-MM-DD — /forge:test {feature-slug}
- 产出：.forge/features/{slug}/test.md + {N} 个测试文件
- 覆盖：{N} 个 unit, {N} 个 integration, {N} 个 e2e
- 下一步：运行测试套件验证覆盖
```

---

## Output

**Files:** Test source files (at paths per conventions) + `.forge/features/{feature-slug}/test.md`

```markdown
# Test Plan: {feature-slug}

> 生成时间：YYYY-MM-DD
> 基于：features/{feature-slug}/design.md + context/testing.md + implemented source files

---

## Coverage Map

| Scenario | Type | File | Status |
|----------|------|------|--------|
| {Scenario} | unit / integration / e2e | `path/to/test.ts` | ✅ Generated / ⚠️ Needs infra / ❌ Not covered |

---

## Existing Tests Updated

| File | Change | Reason |
|------|--------|--------|
| `path/to/test.ts` | {What changed} | {Why} |

_None._ ← use this if no existing tests required changes

---

## Known Gaps

| Scenario | Reason not covered |
|----------|--------------------|
| {Scenario} | Requires {external service / manual testing / E2E infra} |

_None._

---

## Infrastructure Prerequisites

| Test file | Requires | Setup notes |
|-----------|----------|-------------|
| `tests/integration/foo.test.ts` | PostgreSQL, Redis | `docker-compose up -d` first |

_None._
```

---

## Interaction Rules

- **Always confirm the test case list before writing code** (Step 2).
- **One confirmation for existing test updates** (Step 3) before modifying
  any existing file.
- If a scenario is important but untestable without missing infrastructure,
  write the test with a skip annotation and document it in Known Gaps.
- After completing, summarise what was generated and suggest running the tests.

---

## Constraints

- Write test files only — do not modify source implementation files.
- Do not generate tests for code outside the feature's scope.
- Match existing test patterns exactly — no new libraries or styles without
  flagging as new pattern.
- Do not test implementation details (private methods, internal state).
