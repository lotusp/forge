---
kind-id: monorepo
display-name: Monorepo Workspace
detection-signals:
  positive:
    - pattern: "pnpm-workspace.yaml present"
      weight: 0.30
    - pattern: "turbo.json present"
      weight: 0.15
    - pattern: "nx.json / workspace.json present"
      weight: 0.20
    - pattern: "lerna.json present"
      weight: 0.15
    - pattern: "go.work present"
      weight: 0.25
    - pattern: "Cargo.toml with [workspace] section"
      weight: 0.25
    - pattern: "settings.gradle with ≥ 3 include statements"
      weight: 0.20
    - pattern: "pom.xml with <modules> (≥ 3 children)"
      weight: 0.20
    - pattern: "top-level packages/ | apps/ | libs/ | services/ directory with ≥ 3 subdirs"
      weight: 0.20
  negative:
    - pattern: "single top-level src/ with no workspace config"
      weight: 0.30
    - pattern: ".claude-plugin/plugin.json at root and no workspace config"
      weight: 0.35
profiles:
  - core/tech-stack
  - core/module-map
  - core/entry-points
  - core/data-flows
  - core/notes
  - monorepo/workspace-layout
  - structural/build-system
output-sections:
  - What This Is
  - Tech Stack
  - Workspace Layout
  - Module Map
  - Build System
  - Entry Points
  - Key Data Flows
  - Notes
---

# Kind: Monorepo Workspace

## When to Use

Apply when the root repository is a **workspace** coordinating multiple deployable
units or libraries. The workspace itself is not deployed; individual sub-packages are.

Typical signals:
- Workspace config file (`pnpm-workspace.yaml` / `go.work` / `Cargo.toml [workspace]` /
  Gradle / Maven multi-module)
- Top-level `packages/` / `apps/` / `libs/` / `services/` directory with ≥ 3 subdirs
- Root `package.json` declares `"workspaces"` or similar
- Root build orchestrator (Turbo / Nx / Bazel / lerna scripts)

**Not this kind:**
- A single app that happens to have `packages/` for internal splits but no workspace
  declaration — that's `web-backend` with modular internals
- A repo containing one service + its helm chart in `deploy/` — that's `web-backend`

## Execution Notes

- **Stay at workspace level** — this kind produces a workspace-scoped onboard. It does
  not descend into `apps/*` or `libs/*` to run per-package profiles.
- **K-14 Forward compatibility** — per-package recursive onboard is planned but not in
  MVP. The `workspace-layout.md` profile output should mention this capability so
  users know it's a known extension point.
- **Module Map ≈ package list at high level** — prefer the `workspace-layout` profile's
  full inventory; keep `core/module-map` brief (top 5–10 roles) to avoid duplication.
- **Entry Points** — enumerate only workspace-level entry points (root scripts,
  workspace-wide CLIs); per-app entry points belong to each app's own onboard (future).
- **Build System always loaded** — monorepos live or die by their orchestration; this
  profile is mandatory.

## Excluded Profiles

- `structural/config-management` — usually per-app, not workspace-wide
- `structural/deployment` — deployment happens per sub-package, not at workspace level
- All `model/*` — data models belong to individual services
- All `entry-points/*` except what `core/entry-points` already covers
- All `integration/*` — integrations are per-app concerns

## Future Extension (K-14)

When per-package recursive onboard lands:
- The kind file will gain a `recursive-targets:` frontmatter listing which subdirs
  should receive their own onboard.md
- Each target will be re-classified (usually as `web-backend` or another kind)
- Output paths: `{target-path}/.forge/context/onboard.md`
- Workspace onboard will cross-link to each sub-package's onboard

Until then, treat the workspace onboard as a map + pointer, not a deep analysis.
