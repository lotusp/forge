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
token-budget: 1200
---

# Dimension: Architecture Layers

## Scan Patterns

**For web-backend / monorepo:**

- Enumerate subdirectories under `src/`: look for `controllers/`, `services/`,
  `repositories/`, `domain/`, `application/`, `infrastructure/`
- Grep import directions to detect layering rules with real enforcement evidence
- Read representative classes only when needed to locate business logic

**For plugin:**

- Enumerate `skills/` subdirectories (each = one skill module)
- Enumerate `agents/*.md` (sub-agent layer)
- Enumerate `plugins/*/skills/<name>/{reference,scripts,profiles}/`
  sub-layers per skill
- Read `.claude-plugin/plugin.json` for plugin-level structure
- Read relevant SKILL.md / agent IRON RULE sections when they are the source of
  an enforced rule

**For monorepo (workspace-level):**

- Read workspace manifest for package enumeration
- Grep cross-package imports (`"workspace:*"`, path references)
- Detect public vs internal packages (published vs not)

## Extraction Rules

1. Identify the layering model in use.
2. Separate **observed structure** from **enforced rules** and from
   **recommended direction**.
3. A rule belongs in `### Enforced Rules` only if backed by compile/test/
   static-check/framework/IRON-RULE evidence.
4. Directory layout alone is never enough for `### Enforced Rules`.
5. Guidance formerly written as "What to avoid" belongs in
   `### Recommended Direction`.

## Claim Classification Annotations

Each fact extracted by this dimension MUST be classified before render. The
table maps extracted fact types to claim category, target artifact/section,
and minimum confidence.

| Extracted fact type | Claim category | Target artifact | Target section | Min confidence |
|---------------------|----------------|-----------------|----------------|----------------|
| Directory layout observation | `fact` | `architecture.md` | `### Observed Structure` | `[medium]` |
| Module/package inventory | `fact` | `architecture.md` | `### Observed Structure` | `[medium]` |
| Import-direction rule backed by compile/test/static-check | `enforced-rule` | `architecture.md` | `### Enforced Rules` | `[high]` |
| Rule backed by framework constraint or explicit IRON RULE | `enforced-rule` | `architecture.md` | `### Enforced Rules` | `[high]` |
| Soft guidance inferred from dominant layout/pattern | `recommended-pattern` | `architecture.md` | `### Recommended Direction` | `[medium]` |
| "What to avoid" guidance | `recommended-pattern` | `architecture.md` | `### Recommended Direction` | `[medium]` |

**Forbidden routes:**

- Directory-layout observation → NOT `### Enforced Rules`
- `[inferred]` → NOT this dimension's output

## Output Template

### Output Template — web-backend

```markdown
## Architecture Layers

### Observed Structure

**Model:** <3-tier MVC / DDD / Hexagonal / custom> [medium] [code]

- `<controllers/>` — inbound HTTP/adapters layer [medium] [code]
- `<services/>` — application/business orchestration layer [medium] [code]
- `<repositories/>` — persistence/data access layer [medium] [code]

### Enforced Rules

- <rule backed by compile/test/static-check/framework/IRON RULE> [high] [code]

### Recommended Direction

- Business logic should stay out of controllers and inside service/application
  layers where feasible [medium] [code]
- Prefer repository/adapter seams over direct infrastructure coupling in
  business logic [medium] [code]
```

### Output Template — plugin

```markdown
## Architecture Layers

### Observed Structure

**Model:** Skill / Agent / Script / Artifact [high] [code]

- `skills/<name>/SKILL.md` — main skill layer [high] [code]
- `agents/<name>.md` — specialized sub-agent layer [high] [code]
- `skills/<name>/scripts/*.mjs` — deterministic helper script layer [medium] [code]
- `.forge/<path>.md` — persistent artifact layer [high] [code]

### Enforced Rules

- Agent files and skill IRON RULES define artifact-writing boundaries when
  explicitly stated [high] [code]
- Section-marker / artifact-shape rules declared in SKILL.md are enforced by
  the skill contract [high] [code]

### Recommended Direction

- Keep orchestration logic in the owning skill instead of pushing it upward
  into the top-level router [medium] [code]
- Avoid cross-skill coupling when a shared artifact contract can carry the
  context instead [medium] [code]
```

### Output Template — web-frontend

```markdown
## Architecture Layers

### Observed Structure

**Model:** <Page/Route → Component → Hook/Store → API Client> [medium] [code]

- `<pages/ | routes/ | app/>` — page/route layer [medium] [code]
- `<components/>` — reusable UI layer [medium] [code]
- `<hooks/>` — reusable stateful logic [medium] [code]
- `<stores/ | state/>` — global state layer if present [medium] [code]
- `<services/ | api/>` — API client layer [medium] [code]

### Enforced Rules

- <frontend rule backed by lint/config/framework constraint> [high] [code]

### Recommended Direction

- Keep API calls and side effects out of presentational components when
  possible [medium] [code]
- Prefer hook/store extraction over embedding business logic directly in page
  components [medium] [code]
```

### Output Template — monorepo

```markdown
## Architecture Layers

### Observed Structure

**Model:** <workspace packages / apps-libs-tools / Gradle multi-module / ...>
  [medium] [build]

- `apps/*` or equivalent — deployable units [medium] [build]
- `libs/*` or equivalent — shared libraries [medium] [build]
- `tools/*` or equivalent — tooling/utilities [medium] [build]

### Enforced Rules

- <dependency rule backed by workspace/static-check tooling> [high] [code]

### Recommended Direction

- Prefer `apps -> libs` over cross-app dependencies [medium] [code]
- Avoid circular library dependencies even when the workspace tooling does not
  yet enforce them [medium] [code]
```

## Confidence Tags

- `[high]` — rule is backed by compile/test/static-check/framework/IRON RULE
- `[medium]` — structure/pattern is well evidenced but not enforced
- `[low]` — weak structure signal; should usually be omitted
- `[inferred]` — not allowed in this dimension's output
