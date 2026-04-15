---
name: test
description: |
  Generates a test plan and test code for a completed feature, matching the
  project's testing conventions. Use after /forge:review returns a "ready"
  or "needs-work" verdict and the must-fix items have been resolved.
argument-hint: "<feature-slug>"
allowed-tools: "Read Glob Grep Write"
model: sonnet
effort: high
---

## Prerequisites

### Required

Read `.forge/conventions.md`. The testing section defines:
- Where test files live (co-located vs separate directory)
- Naming conventions for describe/it blocks
- Mock strategy (what to mock, what level to mock at)
- Test data patterns (factories, fixtures, seeds)

If conventions.md does not exist:
```
[FORGE:TEST] Missing conventions

.forge/conventions.md not found. Without it I cannot match your project's
testing patterns. Please run /forge:calibrate first, or describe your
testing conventions briefly so I can proceed.
```

### Recommended (read if they exist)

- `.forge/design-{feature-slug}.md` — the intended behaviour to test against
- `.forge/review-{feature-slug}.md` — may flag untested scenarios
- Implemented source files for the feature (from code summaries)
- Existing test files adjacent to the feature's files (to match patterns)

---

## Process

### Step 1 — Determine test strategy

From `conventions.md`, extract the testing approach:
- Which test types apply: unit / integration / end-to-end / contract
- Where each type lives and how files are named
- What mock strategy is used (e.g. mock at repository boundary, never mock
  internal services)
- What test data tooling is available (factories, seeds, builders)

If the conventions are silent on a test type needed for this feature,
ask the user:
```
[FORGE:TEST] Testing convention gap

The feature requires {integration tests / e2e tests / contract tests},
but conventions.md does not describe the approach for this type.

How should these tests be structured? (Or should I skip this type?)
```

### Step 2 — Identify test cases

Read the design document (if available) and the implemented files.
Derive test cases for each of these categories:

**Happy path:** The primary success scenario for each public function,
endpoint, or behaviour.

**Input validation:** Invalid, missing, or malformed inputs — one test case
per distinct validation rule.

**Edge cases:** Boundary values (empty collections, zero, max values),
concurrent execution concerns, large inputs.

**Failure modes:** Expected failures — dependency unavailable, not found,
permission denied, timeout. Each should verify correct error response.

**State transitions:** Any stateful behaviour (e.g. order status flow)
should have tests covering valid and invalid transitions.

Present the test case list to the user before writing any code:

```
[FORGE:TEST] Proposed test cases for {feature-slug}

Unit tests (src/services/__tests__/foo.test.ts):
  ✓ returns user when found by valid ID
  ✓ throws NotFoundError when user ID does not exist
  ✓ throws ValidationError when ID format is invalid
  ...

Integration tests (tests/integration/foo.test.ts):
  ✓ POST /users returns 201 with created user
  ✓ POST /users returns 400 when email is missing
  ...

{N} test cases total. Proceed, or adjust the list?
```

Wait for confirmation or adjustments before writing test code.

### Step 3 — Check existing tests for update needs

Grep for existing test files that test the same code paths the feature
modifies. List any that need updating:

```
[FORGE:TEST] Existing tests requiring update

These tests cover code modified by {feature-slug} and may need updating:

- src/services/__tests__/user.test.ts
  Reason: UserService.findById() signature changed

Please confirm you'd like me to update these alongside the new tests.
```

### Step 4 — Write test code

Generate test files following the project's exact patterns. For each file:
- Match the describe/it block structure of existing test files
- Use the same assertion library and style (e.g. `expect(x).toBe(y)` not `assert.equal(x, y)`)
- Use the same mock approach (e.g. `jest.mock('../repository')` at file level,
  not per-test)
- Use factories or builders if they exist in the project for test data
- Do not use `any` types in TypeScript test files

For tests that need infrastructure (real DB, real queue), add a clear
`// requires: postgres` comment at the top of the file and note them in
the test plan artifact.

### Step 5 — Update existing tests

If the user confirmed in Step 3, update the listed existing test files
to account for the changed interfaces. Minimise changes — update only
what is broken by the feature, not the full test suite.

### Step 6 — Write the test plan artifact

Write `.forge/test-{feature-slug}.md` following the output template.

---

## Output

**Files:** Test source files (paths per conventions) + `.forge/test-{feature-slug}.md`

**Test plan artifact:**

```markdown
# Test Plan: {feature-slug}

> 生成时间：YYYY-MM-DD
> 基于：design-{feature-slug}.md + conventions.md + implemented source files

---

## Coverage Map

| Scenario | Type | File | Status |
|----------|------|------|--------|
| {Scenario description} | unit / integration / e2e | `path/to/test.ts` | ✅ Generated / ⚠️ Needs infra / ❌ Not covered |

---

## Existing Tests Updated

| File | Change | Reason |
|------|--------|--------|
| `path/to/existing.test.ts` | {What changed} | {Why it needed updating} |

_None._ ← use this if no existing tests required changes

---

## Known Gaps

{Test scenarios that are not covered and why.}

| Scenario | Reason not covered |
|----------|--------------------|
| {Scenario} | Requires {external service / manual testing / E2E infrastructure} |

_None._ ← use this if all scenarios are covered

---

## Infrastructure Prerequisites

{Tests that require special setup to run.}

| Test file | Requires | Setup notes |
|-----------|----------|-------------|
| `tests/integration/foo.test.ts` | PostgreSQL, Redis | Run `docker-compose up -d` first |

_None._ ← use this if all tests are self-contained
```

---

## Interaction Rules

- **Always confirm the test case list before writing code** (Step 2). The user
  may have knowledge of edge cases or constraints not visible from the code.
- **One confirmation for existing test updates** (Step 3) before modifying
  any existing file.
- If a scenario is important but cannot be tested without infrastructure not
  yet in place, write the test file with a clear skip annotation
  (`test.skip(...)` or equivalent) and document it in Known Gaps.
- After completing, summarise what was generated and suggest running the tests.

---

## Constraints

- Write test files only — do not modify source implementation files.
- Do not generate tests for code outside the feature's scope.
- Match the existing test patterns exactly — do not introduce a new test
  library, assertion style, or mock strategy without flagging it to the user.
- Do not generate tests that test implementation details (private methods,
  internal state) rather than observable behaviour.
