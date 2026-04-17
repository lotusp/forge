---
name: calibrate
description: |
  Extracts the project's implicit coding conventions and codifies them into
  authoritative constraints for all future development. Run after /forge:onboard
  and before beginning any feature work. The resulting conventions.md is the
  single source of truth referenced by /forge:code, /forge:review, and
  /forge:test.
argument-hint: ""
allowed-tools: "Read Glob Grep Bash"
model: sonnet
effort: max
---

## Runtime snapshot
- Existing .forge artifacts: !`ls .forge/ 2>/dev/null || echo "(none)"`
- Prior scan state: !`test -f .forge/calibrate-scan.md && echo "FOUND — prior scan exists, can resume from adjudication" || echo "(no prior scan — full scan required)"`
- Build files present: !`ls build.gradle pom.xml package.json go.mod Cargo.toml 2>/dev/null | tr '\n' ' ' || echo "(none found)"`
- Source file count: !`find . \( -name "*.java" -o -name "*.ts" -o -name "*.py" -o -name "*.go" \) 2>/dev/null | grep -v node_modules | grep -v ".git" | grep -v build | wc -l | tr -d ' '` files

---

## IRON RULES

These rules have no exceptions. Do not rationalise around them.

- **Never write `conventions.md` before all contradictions are adjudicated.** Partial conventions are worse than no conventions.
- **Never skip the build file read.** Declared dependencies can reveal active libraries (QueryDSL, MapStruct, event bus starters) that are invisible in source samples.
- **URL versioning is always a mandatory contradiction check** — mixed `/api/` and `/api/v2/` paths must be presented as a conflict, not silently averaged.
- **Every rule in `conventions.md` must cite a file:line** where it was observed. Invented rules are not conventions.
- **Every adjudicated decision must be recorded in the Decision Log.** Do not skip items that "seem obvious" — they aren't obvious to future contributors.
- **If a prior scan state exists (`.forge/calibrate-scan.md`), load it instead of re-scanning.** Never discard completed work.

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

If `.forge/calibrate-scan.md` exists (prior scan was saved), show:
```
[FORGE:CALIBRATE] Prior scan found

A codebase scan was saved on {date}. Resuming from adjudication step
saves significant time.

Options:
1. Resume from adjudication (use saved scan — recommended)
2. Re-scan from scratch (discards saved scan)

Which do you prefer?
```

---

## Process

### Step 1 — Read the build file (mandatory)

Before sampling any source files, read the project's primary build file in
full:

- **Java/Kotlin:** `build.gradle` / `build.gradle.kts` / `pom.xml`
- **Node.js:** `package.json`
- **Go:** `go.mod`
- **Rust:** `Cargo.toml`
- **Python:** `pyproject.toml` or `requirements.txt`

From the build file, extract:
- All declared dependencies (not just what appears in sampled source files)
- Custom plugins or internal starters (these often encode patterns invisible in code)
- Build profiles or environment-specific configurations

Record: `dependencies-from-build-file: [list]`. These become evidence for
the Logging, Messaging, and Testing dimensions even if the sampled code does
not visibly use them.

### Step 2 — Sample the codebase

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
| Messaging & events | Internal event bus vs external MQ, which scenarios use which, consumer structure |

For each dimension, record:
- The pattern(s) observed (with file:line references)
- Whether a single pattern dominates or multiple patterns coexist

### Step 3 — Save the scan state (mandatory checkpoint)

After completing Steps 1–2 and before any user interaction, write
`.forge/calibrate-scan.md`:

```markdown
# Calibrate Scan State

> Saved: YYYY-MM-DD
> Status: scan-complete / adjudication-in-progress / complete

## Build File Findings
{dependencies and relevant build config}

## Observed Patterns (per dimension)
{all findings with file:line citations}

## Contradictions Identified
{list of all conflicts, with pattern A / pattern B for each}

## Mandatory Checks Status
- URL versioning: {checked / not applicable — reason}
- Transaction boundaries: {checked / not applicable — reason}
- Test isolation strategy: {checked / not applicable — reason}
```

This checkpoint means a session interruption during adjudication does not
lose the scan work.

### Step 4 — Identify contradictions

A contradiction exists when two or more distinct patterns serve the same
purpose in different parts of the codebase.

**Mandatory contradiction checks** — always check these, regardless of
whether an obvious conflict exists. Record the finding either way:

1. **URL versioning** — Scan all route/controller annotations. Are versioned
   paths (`/api/v2/`, `/v1/`) mixed with unversioned paths (`/api/`)? Even
   if one is dominant, the minority must be addressed.

2. **Transaction boundaries** — Are `@Transactional` / `BEGIN TRANSACTION`
   annotations on Service methods only, or also on Controllers or Repositories?

3. **Test isolation strategy** — Is rollback-after-test the standard, or
   manual truncate? Or are both used? When is each used?

Additional contradictions to detect:
- Exception/error types thrown (typed exceptions vs generic vs error objects)
- Logger declaration style (class-level annotation vs manual instantiation)
- Mock strategy in tests (mock at repository vs service boundary)
- HTTP response envelope (wrapped vs unwrapped)
- DB column naming (camelCase vs snake_case in ORM mapping)

### Step 5 — Adjudicate contradictions (interactive, one at a time)

For each contradiction, present a structured question and wait for the user's
answer before moving to the next.

Format:
```
[FORGE:CALIBRATE] Convention conflict {N} of {M}

Dimension: {e.g. URL versioning}

Pattern A — used in {Module X}, {Module Y}:
  {code example or description}
  ({file:line}, {file:line})

Pattern B — used in {Module Z}:
  {code example or description}
  ({file:line})

Recommendation: Pattern A
Reason: {clear reason why Pattern A is better for new code}

Options:
  1. Adopt Pattern A for all new code (recommended)
  2. Adopt Pattern B for all new code
  3. Allow both — context-dependent (specify when each applies)
  4. Neither — I'll describe what I want instead

Your choice:
```

Record each decision in the scan state file under `## Adjudication Log`.

### Step 6 — Confirm non-contradicted patterns

For each dimension where a single pattern dominates without contradiction,
briefly confirm with the user before ratifying:

```
[FORGE:CALIBRATE] Confirming established patterns

The following patterns were observed consistently. Correct any that are
wrong or should not apply to new code.

{Dimension}: {pattern description} ({file:line example})
  → Correct? (yes / correct it)

{Dimension}: {pattern description}
  → Correct? (yes / correct it)
```

Accept corrections, record them.

### Step 7 — Identify anti-patterns

Review the sampled code for patterns that exist but should not appear in
new code. For each anti-pattern:
- Describe it concisely
- Cite where it was found (file:line)
- Explain why new code should avoid it

Common examples for legacy Java/Spring codebases:
- Repositories injected directly into Controllers
- Business logic in event Listeners
- Dual logger declarations (`@Slf4j` + manual `LoggerFactory`)
- Commented-out security annotations without explanation
- `@Transactional` on Controller methods

### Step 8 — Write the conventions artifact

See [output-template.md](reference/output-template.md) for the complete template.

Write `.forge/conventions.md` following that template exactly.

---

## Self-check before writing

Before writing `.forge/conventions.md`, verify:

- [ ] Build file was read and declared dependencies are reflected in the conventions
- [ ] URL versioning pattern was explicitly adjudicated (not silently ignored)
- [ ] Transaction boundaries were explicitly adjudicated
- [ ] Test isolation strategy was explicitly adjudicated
- [ ] Every rule cites at least one file:line source
- [ ] Every adjudicated decision is in the Decision Log
- [ ] Anti-patterns section cites specific files (not vague warnings)
- [ ] Open Questions section captures any unresolved items

If any checkbox is unchecked, address it before writing the file.

---

## Interaction Rules

- **Never skip a contradiction** — every conflict must be resolved before
  writing the final artifact.
- **Present one contradiction at a time.** Do not dump all conflicts.
- **Accept the user's choice without argument.** Record their choice and
  stated reason faithfully.
- After completing calibration, suggest the next step:
  - If there is a feature to work on: `/forge:clarify {feature}`
  - If starting fresh: `/forge:clarify` with a description of the first feature

---

## Constraints

- Do not modify any source files. This skill is strictly read-only.
- Do not invent conventions. Every rule must be traceable to observed code
  or an explicit user decision.
- Do not carry over rules from previous calibration sessions unless the user
  chooses "extend existing" at the start.
