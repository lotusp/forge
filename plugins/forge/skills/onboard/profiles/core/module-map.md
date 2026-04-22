---
name: module-map
section: Module Map
applies-to:
  - web-backend
  - claude-code-plugin
  - monorepo
confidence-signals:
  - src/ or lib/ directory with subdirectories
  - packages/ or apps/ directory (monorepo)
  - skills/ or agents/ directory (claude-code-plugin)
  - explicit module index files (mod.rs / index.ts / __init__.py at subdirectory roots)
token-budget: 1500
---

# Profile: Module Map

## Scan Patterns

**Top-level source directories (glob):**

- `src/*/` — typical single-app layout
- `packages/*/` / `apps/*/` / `libs/*/` / `services/*/` — monorepo layout
- `skills/*/` / `agents/*/` — claude-code-plugin layout
- `internal/*/` / `pkg/*/` / `cmd/*/` — Go layout convention
- `<kebab-name>/src/main/java/...` — JVM multi-module

**Module intent hints:**

- README.md inside each subdirectory → pull first paragraph as responsibility line
- package.json `description` field (for JS packages)
- `// Package X provides...` block comment at top of Go package
- module-info.java / build.gradle per-module description

## Extraction Rules

1. **Breadth over depth** — list first-level modules only; do not recurse into sub-modules
   unless the project has a documented multi-level convention (e.g. DDD bounded contexts).
2. **One-line responsibility** — describe each module in ≤ 12 words. Start with a verb
   (Handles / Manages / Exposes / Persists / Orchestrates).
3. **Cap at 15 modules** — if more exist, group by theme and note "(N more auxiliary
   modules)" below the table.
4. **Skip generated / vendor directories** — `node_modules/`, `vendor/`, `target/`,
   `dist/`, `build/`, `.gradle/`, `__pycache__/`.
5. **If no clear module boundary exists** — output a single row "`src/`" describing the
   whole codebase and tag `[low]`; recommend running `/forge:calibrate` for deeper
   architecture analysis.

## Section Template

```markdown
## Module Map

| Module | Path | Responsibility |
|--------|------|----------------|
| `auth` | `src/auth/` | Handles session tokens and OAuth callbacks [high] |
| `order` | `src/order/` | Orchestrates order lifecycle and payment dispatch [high] |
| `catalog` | `src/catalog/` | Exposes product search and detail queries [medium] |
| `platform` | `src/platform/` | Shared logging / config / error helpers [high] |
```

Rows use backtick-quoted module name and path. Responsibility is ≤ 12 words.

## Confidence Tags

- `[high]` — module boundary + responsibility both confirmed by code (README + imports)
- `[medium]` — boundary clear but responsibility inferred from file names
- `[low]` — boundary is heuristic (e.g. grouped by directory name only)
- `[inferred]` — responsibility guessed without reading any file inside the module
