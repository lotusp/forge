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
  - explicit directory layout and module boundaries
  - repeated local dependency directions
  - enforcement evidence from tests, lint, build, or runtime framework rules
token-budget: 1200
---

# Dimension: Architecture Shape

## Scan Patterns

**For web-backend / monorepo:**

- Enumerate actual source roots, modules, packages, and framework entry points.
  Do not assume MVC, layered, DDD, hexagonal, or package-by-feature structure.
- Grep import/dependency directions only to describe observed coupling. Treat
  them as enforcement only when there is a matching build, test, lint, static
  analysis, framework, or runtime rule.
- Read representative classes only when needed to locate business logic and
  record that the result is sampled unless the scan is exhaustive.

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

1. Identify the architecture shape actually present in the codebase, even when
   it is mixed, legacy, sparse, or inconsistent.
2. Separate **observed organization**, **local conventions**, **enforced
   boundaries**, and **observed risks / inconsistencies**.
3. A rule belongs in `### Enforced Rules` only if backed by compile/test/
   static-check/framework/IRON-RULE evidence.
4. Directory layout, framework convention, common industry practice, or a test
   class name alone is never enough for `### Enforced Rules`.
5. Do not map the project to a best-practice architecture. If the codebase is
   only partially layered or uses multiple patterns, say so.
6. Potential friction found while reading the codebase belongs in
   `### Observed Risks / Inconsistencies`, not in hard constraints.

## Claim Classification Annotations

Each fact extracted by this dimension MUST be classified before render. The
table maps extracted fact types to claim category, target artifact/section,
and minimum confidence.

| Extracted fact type | Claim category | Target artifact | Target section | Min confidence |
|---------------------|----------------|-----------------|----------------|----------------|
| Directory layout observation | `fact` | `architecture.md` | `### Observed Organization` | `[medium]` |
| Module/package inventory | `fact` | `architecture.md` | `### Observed Organization` | `[medium]` |
| Import-direction rule backed by compile/test/static-check | `enforced-rule` | `architecture.md` | `### Enforced Rules` | `[high]` |
| Rule backed by framework constraint or explicit IRON RULE | `enforced-rule` | `architecture.md` | `### Enforced Rules` | `[high]` |
| Repeated local pattern observed in current repo | `recommended-pattern` | `architecture.md` | `### Local Conventions` | `[medium]` |
| Maintainer-facing friction or inconsistency | `current-caveat` | `architecture.md` | `### Observed Risks / Inconsistencies` | `[medium]` |

**Forbidden routes:**

- Directory-layout observation → NOT `### Enforced Rules`
- Industry practice or framework convention → NOT `### Local Conventions`
  unless the current repo repeats it or documents it
- `[inferred]` → NOT this dimension's output

## Output Template

### Output Template — web-backend

```markdown
## Architecture Shape

### Observed Organization

**Shape:** <describe the actual organization found in this repository>
  [medium] [code]

- `<source-root-or-module>/...` — <observed role from files read>
  [medium] [code]
- `<source-root-or-module>/...` — <observed role from files read>
  [medium] [code]

### Enforced Rules

- <rule backed by compile/test/static-check/framework/IRON RULE> [high] [code]

### Local Conventions

- <pattern repeatedly observed in current repo, phrased as local convention>
  [medium] [code]

### Observed Risks / Inconsistencies

- <inconsistency or maintenance risk observed in current repo; non-binding
  reference only> [medium] [code]
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
