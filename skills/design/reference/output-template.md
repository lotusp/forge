# design.md Output Template

This file defines the exact structure for `.forge/features/{feature-slug}/design.md`.
Referenced by `/forge:design` Step 7.

---

```markdown
# Design: {feature-slug}

> 基于：features/{feature-slug}/clarify.md + context/conventions.md
> 生成时间：YYYY-MM-DD
> 文件路径：.forge/features/{feature-slug}/design.md
> [注：无 clarify artifact，需求来自用户直接描述] ← 删除如不适用
> [注：无 conventions.md，设计不受约定约束] ← 删除如不适用

---

## Solution Overview

Two to four sentences describing the chosen approach and why it fits the
codebase and requirements.

---

## Approach Options

Only include if multiple approaches were explored.

| Option | Description | Pros | Cons | Verdict |
|--------|-------------|------|------|---------|
| A — {name} | ... | ... | ... | ✅ Chosen / ❌ Rejected |
| B — {name} | ... | ... | ... | ❌ Rejected — reason |

---

## Component Changes

### New Components

| Path | Layer | Type | Responsibility |
|------|-------|------|----------------|
| `path/to/new-file` | service / repository / controller / ... | class / function / config | What it does |

### Modified Components

| Path | What Changes | Why |
|------|-------------|-----|
| `path/to/existing-file` | Description of change | Reason |

### Deleted Components

| Path | Reason |
|------|--------|
| `path/to/removed-file` | Why it is being removed |

---

## API Changes

Describe new, modified, or removed API endpoints or function signatures.
Include request/response shapes where relevant.

_None_ if no API changes.

---

## Data Model Changes

Describe new tables, fields, indexes, or schema changes. Include migration
strategy if data already exists.

_None_ if no data model changes.

---

## Impact Analysis

| Area | Risk | Description |
|------|------|-------------|
| `path/or/module` | Low / Medium / High | What is affected and how |

---

## Key Decisions

| Decision | Options Considered | Chosen | Rationale |
|----------|--------------------|--------|-----------|
| ... | A / B | A | Because ... |

---

## Constraints & Trade-offs

What was ruled out and why. Helps future readers understand the design.

---

## Convention Deviations

Any intentional deviation from conventions.md. If empty, write _None_.

| Convention | Deviation | Reason |
|------------|-----------|--------|

---

## Open Decisions

Must be resolved before planning can begin. Write _None_ if all resolved.

| # | Question | Context | Status |
|---|----------|---------|--------|
| 1 | ... | ... | ⏳ Deferred (user acknowledged) — risk: {level} |
```
