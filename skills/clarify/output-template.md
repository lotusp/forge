# clarify.md Output Template

This file defines the exact structure for `.forge/clarify-{feature-slug}.md`.
Referenced by `/forge:clarify` Step 8.

---

```markdown
# Clarify: {feature-slug}

> 原始需求："{user's verbatim input}"
> 生成时间：YYYY-MM-DD

---

## Requirement Restatement

{Precise technical restatement of what is being built or changed.
One to three paragraphs. Should be unambiguous enough to drive design.}

---

## Current Implementation

### Entry Points

| Entry point | Path | Line | Description |
|-------------|------|------|-------------|
| {route / function / command} | `path/to/file` | N | What it does |

_No existing implementation._ ← use this for fully new features

### Call Chain

{For each entry point, the full call sequence with file:line references.}

```
EntryHandler (src/routes/foo.ts:42)
  └─ FooService.process() (src/services/foo.ts:18)
       └─ FooRepository.findById() (src/repositories/foo.ts:55)
            └─ DB query
```

### Data Flow

{How data enters the system, is transformed, and exits or persists.}

---

## Affected Components

| Component | Path | Nature of Impact |
|-----------|------|-----------------|
| `ClassName / function` | `path/to/file` | modified / extended / dependent |

---

## External Dependencies

| Dependency | Type | Relevance |
|------------|------|-----------|
| {Service / API / Queue} | third-party / internal | {Why it matters} |

---

## Assumptions Made

{Assumptions taken during analysis that should be confirmed before design.}

- Assumed that {X} because {reason}. Please confirm.

---

## Questions & Answers

| # | Question | Answer | Source |
|---|----------|--------|--------|
| 1 | {Question} | {Answer} | User / Inferred from code |

---

## Open Questions

Items the user deferred. Must be resolved before planning.

| # | Question | Impact if unresolved |
|---|----------|----------------------|
| 1 | {Question} | {What it blocks} |

---

## Gaps (What Doesn't Exist Yet)

{Everything the requirement needs that is not in the current codebase.
These become the raw material for the design artifact.}

- {Gap description} — affects {area}
```
