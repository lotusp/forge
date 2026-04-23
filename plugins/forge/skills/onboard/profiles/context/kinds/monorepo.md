---
kind-id: monorepo
display-name: Monorepo Workspace
output-files:
  - conventions.md
  - testing.md
  - architecture.md
  - constraints.md
dimensions-loaded:
  conventions:
    - dimensions/naming
    - dimensions/error-handling
    - dimensions/logging
    - dimensions/validation
    - dimensions/api-design
    - dimensions/database-access
    - dimensions/messaging
    - dimensions/authentication
    - dimensions/commit-format
  testing:
    - dimensions/testing-strategy
  architecture:
    - dimensions/architecture-layers
  constraints:
    - dimensions/hard-constraints
    - dimensions/anti-patterns
excluded-dimensions:
  - skill-format
  - artifact-writing
  - markdown-conventions
---

# Context Kind: Monorepo Workspace

## When this kind applies

Repos coordinating multiple deployable units or libraries under a single
workspace manifest (`pnpm-workspace.yaml`, `go.work`, Cargo `[workspace]`,
`nx.json`, `turbo.json`, Maven/Gradle multi-module). The workspace root
itself is not deployed; individual sub-packages are.

## Context file strategy

- **conventions.md** — workspace-level engineering conventions. Loaded
  dimensions overlap with web-backend because most monorepos house web
  services. **Cross-package import direction rules** and **shared tooling
  conventions** sit here.
- **testing.md** — workspace-level test orchestration (how turbo/nx runs
  tests, which packages gate CI); per-package specifics stay in each
  package's future onboard (K-14 placeholder).
- **architecture.md** — package-dependency graph / forbidden cycles /
  public vs internal packages.
- **constraints.md** — workspace-level hard rules (e.g. no direct
  `packages/*/node_modules/` access, CI gating requirements).

## Excluded dimensions — rationale

- **skill-format / artifact-writing / markdown-conventions** — monorepo
  仓库本体不是 Claude Code plugin；这些维度不适用。若某个子包**是** plugin，
  将来 K-14 递归 onboard 的该子包会用 claude-code-plugin kind。

## Forward compatibility note

Per-package recursive onboard (K-14) is out of MVP scope. Currently the
monorepo kind produces workspace-level context only. Future recursive
onboard will run `/forge:onboard` inside each sub-package directory,
producing `packages/<name>/.forge/context/*.md` with whichever kind
(`web-backend` / `claude-code-plugin`) that sub-package identifies as.
