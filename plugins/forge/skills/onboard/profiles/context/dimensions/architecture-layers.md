---
name: architecture-layers
output-file: architecture.md
applies-to:
  - web-backend
  - web-frontend
  - plugin
  - monorepo
scan-sources:
  - glob: "src/**/*.{ts,js,java,go,py}"
  - glob: "plugins/*/skills/*/SKILL.md"
  - glob: "plugins/*/agents/*.md"
  - glob: "packages/*/package.json"
confidence-signals:
  - explicit directory layout (controllers/ services/ repositories/)
  - DDD-style bounded contexts
  - import-direction consistency across modules
token-budget: 1000
---

# Dimension: Architecture Layers

## Scan Patterns

**For web-backend / monorepo:**
- Enumerate subdirectories under `src/`: look for `controllers/ services/
  repositories/ domain/ application/ infrastructure/` patterns
- Grep import directions to detect layering violations
- Read 3–5 representative service files to infer where business logic sits

**For plugin:**
- Enumerate `skills/` subdirectories (each = one skill module)
- Enumerate `agents/*.md` (sub-agent layer)
- Enumerate `plugins/*/skills/<name>/{reference,scripts,profiles}/`
  sub-layers per skill
- Read `.claude-plugin/plugin.json` for plugin-level structure
- For marketplace-with-plugins layout: `plugins/<name>/` is one plugin

**For monorepo (workspace-level):**
- Read workspace manifest for package enumeration
- Grep cross-package imports (`"workspace:*"`, `"path"` references)
- Detect public vs internal packages (published vs not)

## Extraction Rules

1. Identify the **layering model** in use (traditional 3-tier / DDD /
   skill-agent-artifact / workspace packages)
2. Record **import direction rules** — which layer may depend on which
3. List **modules in each layer** (top 5–10, skip generated)
4. For plugin: document skill ↔ agent ↔ script boundaries
5. For monorepo: document package dependency direction + forbidden cycles

## Output Template

### Output Template — web-backend

```markdown
## Architecture Layers

**Model:** <3-tier MVC / DDD / Hexagonal / custom>

**Layers (top → bottom):**
- `<controllers/>` — <role>; allowed to import <...>  [high] [code]
- `<services/>` — <role>; allowed to import <...>     [high] [code]
- `<repositories/>` — <role>; allowed to import <...> [high] [code]

**Import direction rules:**
- `controllers → services → repositories`; no backward imports [high] [code]
- `repositories → ORM / DB driver`; never touch controllers [high] [code]
- Cross-layer utilities in `shared/` / `platform/` only  [high] [code]

**What to avoid:**
- Business logic inside `controllers/` — always delegate to `services/`
- Direct DB calls in `services/` — use repository pattern
- Circular imports between service modules
```

### Output Template — plugin

```markdown
## Architecture Layers

**Model:** Skill / Agent / Script / Artifact 四层

**Layers:**
- `skills/<name>/SKILL.md` — skill layer (instructions for main agent)
  [high] [code]
- `agents/<name>.md` — sub-agent layer (specialized, tools limited)
  [high] [code]
- `skills/<name>/scripts/*.mjs` — script layer (deterministic helpers,
  no LLM) [medium] [code]
- `.forge/<path>.md` — artifact layer (persistent structured context)
  [high] [code]

**Composition rules:**
- Skill may spawn agents (declared via Agent tool) [high] [code]
- Skill may invoke scripts via Bash [high] [code]
- Skill reads/writes artifacts per its declared contract [high] [code]
- Agent does NOT write artifacts; it returns report text to skill [high] [code]

**What to avoid:**
- Agent directly writing to `.forge/` (violates agent-skill boundary)
- Skills bypassing status.mjs (the routing authority for orchestrator)
- Cross-skill imports (each skill is self-contained prompt)
```

### Output Template — web-frontend

```markdown
## Architecture Layers

**Model:** <Page/Route → Component → Hook/Store → API Client>

**Layers (top → bottom):**
- `<pages/ | routes/ | app/>` — page / route components, 1-to-1 with URL
  [high] [code]
- `<components/>` — reusable UI pieces; presentational + container
  distinction if applicable [high] [code]
- `<hooks/>` — React hooks / Vue composables; encapsulate stateful logic
  reusable across components [high] [code]
- `<stores/ | state/>` — global state containers (Redux / Zustand /
  Pinia / Vuex / Recoil) [medium] [code]
- `<services/ | api/>` — API client wrappers, HTTP interceptors, error
  transformers [high] [code]

**Import direction rules:**
- `pages → components → hooks → services`; no backward imports
  [high] [code]
- `stores` can be read from anywhere but writes centralized in action
  files or store setters [high] [code]
- `services` never import from `pages` or `components` [high] [code]

**Routing:** <React Router | Vue Router | Next.js App Router | file-based>
[high] [code]

**State management:** <Redux Toolkit | Zustand | Pinia | Context+useReducer
| none> [high] [code]

**Styling:** <CSS Modules | Tailwind | styled-components | emotion |
vanilla-extract> [high] [code]

**What to avoid:**
- Direct DOM manipulation (document.querySelector) bypassing the framework
- Business logic in components (push to hooks or stores)
- API calls inside components (always via services layer)
- Global CSS leak (use Modules or CSS-in-JS scoping)
```

### Output Template — monorepo

```markdown
## Architecture Layers (Workspace-Level)

**Model:** <pnpm workspace | Turborepo | Nx | Gradle multi-module | ...>

**Package layers:**
- `apps/*` — deployable services [high] [build]
- `libs/*` — shared libraries (published or internal) [high] [build]
- `tools/*` — build / codegen utilities [medium] [build]

**Dependency direction rules:**
- `apps → libs` allowed; `libs → apps` forbidden [high] [code]
- `libs/<X> → libs/<Y>` allowed only if X's domain is broader than Y
  [medium] [code]
- `tools → anything` allowed (scripts run over everything) [high] [build]

**What to avoid:**
- Cross-app imports (apps are independent deployables)
- Circular library dependencies (enforce with `dependency-cruiser` or
  Nx's `enforce-module-boundaries`)
```

## Confidence Tags

- `[high]` — layering rule visible in directory layout AND import pattern
- `[medium]` — directory layout suggests rule but imports don't fully comply
- `[low]` — rule inferred from a single file or READ path
- `[inferred]` — rule is best-guess from framework conventions (e.g.
  assuming Spring's default MVC layout without verifying)
