---
name: calibrate
description: |
  Extracts the project's implicit coding conventions and codifies them into
  authoritative constraints for all future development. Run after /forge:onboard
  and before beginning any feature work. The resulting conventions.md is the
  single source of truth referenced by /forge:code, /forge:review, and
  /forge:test.
argument-hint: ""
allowed-tools: "Read Glob Grep"
model: sonnet
effort: max
---

## Prerequisites

Read `.forge/onboard.md`. This provides the module map and tech stack needed
to guide sampling. If it does not exist:

```
[FORGE:CALIBRATE] Missing prerequisite

.forge/onboard.md not found. Please run /forge:onboard first so I have
a module map to guide the codebase scan.
```

If `.forge/conventions.md` already exists, show the user:
```
[FORGE:CALIBRATE] Existing conventions found

.forge/conventions.md was last generated on {date}.

Options:
1. Re-calibrate from scratch (overwrites existing)
2. Extend / update existing conventions (re-runs scan, merges findings)
3. Exit

Which do you prefer?
```

---

## Process

### Step 1 — Sample the codebase

Using the module map from `onboard.md`, select representative files to read.

**Sampling strategy:**
- For each major module or layer identified in `onboard.md`, read **3–5 files**
  that are most representative of typical production code (not generated files,
  not test fixtures, not migration scripts)
- Prioritise files that: handle core business logic, define data models,
  expose API endpoints, and contain tests
- For a codebase with more than 10 modules, sample at most 3 files per module
  and no more than 40 files total

From each file, extract evidence for these **convention dimensions**:

| Dimension | What to look for |
|-----------|-----------------|
| Architecture & layering | Import directions, which layer calls which, where business logic lives |
| Naming | Files, classes, functions, variables, DB tables/columns, constants |
| Logging | Logger library, log levels used, fields always included, structured vs plain |
| Error handling | Exception types thrown, error return patterns, where errors are caught |
| Validation | When and where input is validated, library used, error response format |
| Testing | Test file location, naming convention, assertion style, mock strategy, factory patterns |
| API design | URL structure, HTTP verb usage, response envelope, status codes, pagination |
| Database access | ORM vs raw queries, repository pattern, transaction boundaries, N+1 handling |
| Code style | Async patterns (async/await vs callbacks vs promises), null handling, type usage |

For each dimension, record:
- The pattern(s) observed (with file:line references)
- Whether a single pattern dominates or multiple patterns coexist

### Step 2 — Identify contradictions

A contradiction exists when two or more distinct patterns serve the same
purpose in different parts of the codebase.

Examples:
- Some modules throw `AppError`, others return `{ success: false }`
- Some files use `snake_case` for DB columns, others use `camelCase`
- Some tests mock at the repository level, others mock at the service level

List all contradictions found, noting which modules use which approach.

### Step 3 — Adjudicate contradictions (interactive)

For each contradiction, present a structured question and wait for the user's
answer before moving to the next.

Format:
```
[FORGE:CALIBRATE] Convention conflict {N} of {M}

Dimension: {Error handling}

Pattern A — used in {Module X}, {Module Y}:
  throw new AppError(ErrorCode.NOT_FOUND, "User not found")
  (src/services/user.ts:34, src/services/order.ts:91)

Pattern B — used in {Module Z}:
  return { success: false, error: "User not found", code: "NOT_FOUND" }
  (src/services/payment.ts:17)

Recommendation: Pattern A
Reason: Centralises error handling in a global middleware; callers cannot
forget to check return values; aligns with Express error-handling conventions.

Options:
  1. Adopt Pattern A for all new code (recommended)
  2. Adopt Pattern B for all new code
  3. Allow both — context-dependent
  4. Neither — I'll describe what I want instead

Your choice:
```

Record the decision and the rationale. After all contradictions are resolved,
proceed to Step 4.

### Step 4 — Confirm non-contradicted patterns

For each dimension where a single pattern dominates without contradiction,
briefly state the observed pattern and ask for confirmation or correction:

```
[FORGE:CALIBRATE] Confirming established patterns

The following patterns were observed consistently. Please correct any that
are wrong or should not apply to new code.

Logging: Winston with structured JSON. Always include { service, requestId,
userId? }. Use logger.error() for caught exceptions, logger.warn() for
expected failures, logger.info() for significant state changes.
  → Correct? (yes / correct it)

Naming — files: kebab-case (user-service.ts, auth-middleware.ts)
  → Correct? (yes / correct it)

...
```

Accept corrections, then proceed.

### Step 5 — Identify anti-patterns

Review the sampled code for patterns that exist but should be avoided in new
code. Common examples:
- Direct DB queries bypassing the repository layer
- Business logic inside route handlers
- Catching errors and logging them without re-throwing or responding
- Inconsistent use of `any` type in TypeScript
- Synchronous file I/O in an async codebase

For each anti-pattern found, describe it and explain why new code should
avoid it.

### Step 6 — Write the conventions artifact

Write `.forge/conventions.md` following the output template.

---

## Output

**File:** `.forge/conventions.md`

```markdown
# Project Conventions

> 生成时间：YYYY-MM-DD
> 生成方式：/forge:calibrate — 基于代码扫描 + 人工裁决
> 更新方式：重新运行 /forge:calibrate

**Important:** This file is the authoritative source of truth for all new
development. /forge:code, /forge:review, and /forge:test all reference this
document. If conventions change, regenerate this file.

---

## Architecture & Layering

{Rules about which layer calls which, where business logic lives, what each
layer is responsible for. Include: what is NOT allowed (e.g. "routes must not
contain business logic").}

---

## Naming Conventions

### Files
{Pattern with example: kebab-case — `user-service.ts`, `auth-middleware.ts`}

### Classes
{Pattern with example}

### Functions & methods
{Pattern with example}

### Variables & constants
{Pattern with example}

### Database tables & columns
{Pattern with example}

---

## Logging

- **Library:** {e.g. Winston, Pino, Zap}
- **Format:** {structured JSON / plain text}
- **Required fields:** {e.g. `service`, `requestId`, `userId` when available}
- **Level semantics:**
  - `error`: {when to use}
  - `warn`: {when to use}
  - `info`: {when to use}
  - `debug`: {when to use}

---

## Error Handling

{Chosen pattern with a short code example. Include: where errors are caught,
how they are converted to HTTP responses, how internal errors are distinguished
from user-facing errors.}

---

## Validation

- **Location:** {e.g. route handler / middleware / service boundary}
- **Library:** {e.g. Zod, Joi, class-validator}
- **Error response format:** {example JSON}

---

## Testing

- **Test file location:** {e.g. co-located `*.test.ts` / `tests/` directory}
- **Naming:** {e.g. `describe("UserService")` → `it("should return null when user not found")`}
- **Mock strategy:** {e.g. mock at repository level using jest.mock(); never mock internal services}
- **Test data:** {e.g. factory functions in `tests/factories/`}
- **Coverage expectation:** {e.g. unit tests for all service methods; integration tests for all routes}

---

## API Design

- **URL structure:** {e.g. `/api/v1/{resource}/{id}`}
- **HTTP verbs:** {how GET/POST/PUT/PATCH/DELETE are used}
- **Response envelope:** {e.g. `{ data, meta }` for success / `{ error: { code, message } }` for failure}
- **Pagination:** {e.g. cursor-based with `{ data, nextCursor, hasMore }`}
- **Status codes:** {which codes are used for which situations}

---

## Database Access

- **Pattern:** {e.g. Repository pattern — all DB access through `*Repository` classes}
- **ORM / query builder:** {e.g. Prisma, TypeORM, Knex, raw SQL}
- **Transaction boundaries:** {e.g. transactions live in the service layer}
- **Migration tool:** {e.g. Prisma Migrate, Flyway, golang-migrate}

---

## What to Avoid

{Anti-patterns found in the codebase that must not appear in new code.}

- **{Anti-pattern name}:** {Description}. Found in {file} — do not replicate.
- ...

---

## Open Questions

{Convention dimensions that could not be resolved during calibration.
These require a follow-up decision before work in that area begins.}

| Dimension | Question | Impact |
|-----------|----------|--------|
| {area} | {unresolved question} | {what it affects} |
```

---

## Interaction Rules

- **Never skip a contradiction** — every conflict in the codebase must be
  resolved before writing the final artifact. Unresolved contradictions produce
  inconsistent code that future reviews will flag.
- **Present one contradiction at a time.** Do not dump all conflicts in one
  message.
- **Accept the user's choice without argument.** If they prefer a pattern you
  did not recommend, record their choice with their stated reason.
- After completing calibration, suggest the next step:
  - If there is a feature to work on: `/forge:clarify {feature}`
  - If starting fresh: `/forge:clarify` with a description of the first feature

---

## Constraints

- Do not modify any source files. This skill is strictly read-only.
- Do not invent conventions. Every rule in the output must be traceable to
  observed code or an explicit user decision made during this session.
- Do not carry over rules from previous calibration sessions unless the user
  chooses "extend existing" at the start. A fresh calibration starts clean.
