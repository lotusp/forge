---
name: workspace-layout
section: Workspace Layout
applies-to:
  - monorepo
confidence-signals:
  - pnpm-workspace.yaml / lerna.json / nx.json / turbo.json
  - go.work
  - Cargo.toml [workspace]
  - settings.gradle with multiple includes
  - pom.xml with <modules>
token-budget: 1200
---

# Profile: Workspace Layout

## Scope

For monorepo kind only. Describes the top-level package graph, build orchestration, and
how sub-packages relate. Does **not** recurse into each package — per-package onboard
is a future capability (K-14 Monorepo Future-Proofing).

## Scan Patterns

**Workspace declaration:**

| File | Tool |
|------|------|
| `pnpm-workspace.yaml` | pnpm workspaces |
| `lerna.json` | Lerna |
| `nx.json` + `workspace.json` / `project.json`s | Nx |
| `turbo.json` | Turborepo (orchestration layer) |
| `go.work` | Go workspaces |
| `Cargo.toml` with `[workspace]` | Cargo workspaces |
| `settings.gradle` / `pom.xml <modules>` | Gradle / Maven multi-module |
| `rush.json` | Rush |

**Package discovery:**

- enumerate directories matching workspace globs (`packages/*`, `apps/*`, `libs/*`)
- read per-package manifest (`package.json`, `go.mod`, `Cargo.toml`) for name + version
- detect package type from directory parent (`apps/` → deployable, `libs/` → shared)

**Dependency graph:**

- cross-package imports (workspace protocol: `"workspace:*"` / `path = "../x"`)
- Turbo / Nx task dependencies
- Gradle `implementation project(':name')`

## Extraction Rules

1. **Package inventory** — grouped by role (apps / services / libs / tools). Table of
   package name + path + one-line purpose.
2. **Cap at 25 packages shown** — if more, group by role and cite count.
3. **Build orchestrator** — which tool coordinates cross-package builds
   (Turbo / Nx / bazel / lerna / raw scripts).
4. **Cross-package dependency density** — rough statement: "apps depend on ~5 shared
   libs on average".
5. **Versioning strategy** — fixed (all same version) / independent / pinned ranges.
6. **Publish target** — which packages publish externally (npm / Maven / container).
7. **Forward pointer to future recursive onboard** — note that per-package deep
   onboarding is planned (K-14) but not yet implemented.

## Section Template

```markdown
## Workspace Layout

- **Workspace tool:** pnpm workspaces + Turborepo 1.13 [high]
- **Package count:** 18 packages (6 apps, 9 libs, 3 tools) [high]
- **Versioning:** independent (each package pins its own version) [high]
- **Publish target:** libs under `@example/*` published to private npm registry
  (host redacted per C8); apps deploy as Docker images [medium]

### Packages

| Role | Package | Path | Purpose |
|------|---------|------|---------|
| app | `@example/orders-api` | `apps/orders-api/` | Public HTTP API [high] |
| app | `@example/orders-worker` | `apps/orders-worker/` | Async job / event consumer [high] |
| app | `@example/admin-bff` | `apps/admin-bff/` | Back-office BFF [high] |
| lib | `@example/domain` | `libs/domain/` | Shared domain models + types [high] |
| lib | `@example/platform` | `libs/platform/` | Logging / config / telemetry [high] |
| lib | `@example/db` | `libs/db/` | Prisma client + migrations [high] |
| tool | `@example/codegen` | `tools/codegen/` | OpenAPI → TS client generator [medium] |

(11 more packages — see `pnpm-workspace.yaml`)

### Cross-Package Dependencies

- Apps depend on `@example/domain`, `@example/platform`, `@example/db` universally
- Libs have no cross-lib dependencies except `@example/platform` (utilities) [high]
- Turbo pipeline: `build` depends on `^build`; `test` depends on `build` [high]

### Per-Package Onboarding

A future enhancement (tracked as K-14) will allow running `/forge:onboard` recursively
per package to produce `apps/<name>/.forge/context/onboard.md`. Current MVP produces
only the workspace-level map above. [inferred]
```

## Confidence Tags

- `[high]` — workspace config + package manifests read
- `[medium]` — packages enumerated without manifest inspection
- `[low]` — package list from README only
- `[inferred]` — forward-looking statements (e.g. about K-14)
