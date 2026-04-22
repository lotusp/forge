---
kind-id: claude-code-plugin
display-name: Claude Code Plugin
detection-signals:
  positive:
    - pattern: ".claude-plugin/plugin.json exists (plain plugin repo)"
      weight: 0.45
    - pattern: "plugins/*/.claude-plugin/plugin.json exists (marketplace-with-plugins layout)"
      weight: 0.45
    - pattern: ".claude-plugin/marketplace.json exists"
      weight: 0.20
    - pattern: "skills/*/SKILL.md OR plugins/*/skills/*/SKILL.md files present (≥ 1)"
      weight: 0.20
    - pattern: "agents/*.md OR plugins/*/agents/*.md files present (≥ 1)"
      weight: 0.10
    - pattern: "README.md or docs/ mentions 'Claude Code plugin'"
      weight: 0.10
  negative:
    - pattern: "HTTP framework in deps (express | spring-boot | gin | fastapi)"
      weight: 0.35
    - pattern: "database migration directory"
      weight: 0.20
    - pattern: "Dockerfile exposing HTTP port"
      weight: 0.15
profiles:
  - core/tech-stack
  - core/module-map
  - core/entry-points
  - core/local-dev
  - core/data-flows
  - core/notes
output-sections:
  - What This Is
  - Tech Stack
  - Module Map
  - Entry Points
  - Local Development
  - Key Data Flows
  - Notes
---

# Kind: Claude Code Plugin

## When to Use

Apply when the repository is a Claude Code plugin: a collection of skills / agents /
commands packaged for distribution via a Claude Code marketplace.

Typical signals:
- `.claude-plugin/plugin.json` is present
- Content is markdown-heavy (SKILL.md files, agent definitions, reference docs)
- No HTTP server, no database, no deployment artifacts
- "Runtime" is the Claude Code client reading the skill files

**Not this kind:**
- A web service that *uses* Claude API internally (that's a `web-backend`)
- An IDE extension / VS Code plugin (no kind for that yet)

## Execution Notes

- **Minimal profile set by design** — plugins have no DB, no HTTP surface, no
  third-party integrations. Loading those profiles produces empty sections and wastes
  tokens. K-12 Decision: claude-code-plugin uses only the 6 core profiles.
- **Module Map adaptation** — each `skills/<name>/` and `agents/<name>/` counts as
  a module. Responsibility = the skill's one-line purpose from its `description`
  frontmatter.
- **Entry Points adaptation** — entry points are **skill invocations**
  (`/forge:<name>`) and **agent types**. There are no HTTP routes or CLI commands in
  the traditional sense.
- **Key Data Flows adaptation** — flows are artifact pipelines (skill A produces
  artifact X → skill B reads X). See `data-flows.md` for the plugin-specific template.
- **Local Development adaptation** — "run locally" = `claude --plugin-dir ./` or
  `/reload-plugins` inside Claude Code. No build step unless the plugin has scripts.

## Excluded Profiles

- All `structural/*` (build-system / config-management / deployment)
  — plugins have no build / deploy pipeline worth documenting
- All `model/*` (domain-model / db-schema) — no datastore
- All `entry-points/*` except what `core/entry-points` already covers
  — no HTTP API, no event consumers
- All `integration/*` (auth / third-party-apis / messaging) — plugins don't integrate
  with external services
- `monorepo/workspace-layout` — a plugin may live inside a monorepo, but the plugin
  itself isn't the workspace; run `monorepo` kind at the workspace root instead
