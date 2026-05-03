---
name: module-map
section: Module Map
applies-to:
  - web-backend
  - web-frontend
  - plugin
  - monorepo
confidence-signals:
  - src/ or lib/ directory with subdirectories
  - packages/ or apps/ directory (monorepo)
  - skills/ or agents/ directory (plugin)
  - explicit module index files (mod.rs / index.ts / __init__.py at subdirectory roots)
token-budget: 1500
---

# Profile: Module Map

## Scan Patterns

**Top-level source directories (glob):**

- `src/*/` — typical single-app layout
- `packages/*/` / `apps/*/` / `libs/*/` / `services/*/` — monorepo layout
- `skills/*/` / `agents/*/` — plugin layout
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
3. **No silent truncation.** Phrases like `(N more auxiliary modules)`,
   `(omitted for brevity)`, or `(other auxiliary adapters)` are
   FORBIDDEN. v0.5.1 review of biz-svc-a found
   `(4+ more auxiliary adapters: aftermarket, reports, lead, rtm)`
   silently misplaced one of those packages and dropped five others.
   When the package count exceeds ~15, group by responsibility but
   list every name in the rendered output.
4. **Adapter / clients sub-package full enumeration.** For any package
   whose path matches `*/adapter/`, `*/adapters/`, `*/clients/`,
   `*/integration/`, `*/connectors/`, or `*/external/`:

   ```bash
   find <pkg> -maxdepth 1 -mindepth 1 -type d
   ```

   List EVERY directory returned. These adapter sub-packages are the
   most common "where does feature X live?" surface for new
   maintainers; truncation here directly causes file-not-found pain.
5. **Top-level package enumeration.** For `src/main/java/<base-package>/`
   (or equivalent), use `find . -maxdepth 1 -mindepth 1 -type d -- "$ROOT"`
   to obtain a literal count. Replace prose like "more than 70 packages"
   with the exact count, e.g. `88 first-level packages under
   `com.example.shop` (top 12 listed below; full list available via the
   command above)`.
6. **Skip generated / vendor directories** — `node_modules/`, `vendor/`,
   `target/`, `dist/`, `build/`, `.gradle/`, `__pycache__/`,
   `bin/main/`, `out/`.
7. **If no clear module boundary exists** — output a single row "`src/`"
   describing the whole codebase and tag `[low]`; architecture.md
   (produced by onboard Stage 3) will contain the deeper per-layer
   analysis.

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
