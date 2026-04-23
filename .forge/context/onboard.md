# Project Onboard: Forge

> Kind:                 claude-code-plugin
> Confidence:           1.00
> Generated:            2026-04-23
> Commit:               59836a2
> Generator:            /forge:onboard (v0.5.0-dev)
> Excluded-dimensions:  logging, validation, api-design, database-access, messaging, authentication

## What This Is

Forge is a Claude Code plugin that brings a structured, AI-driven development workflow to existing and legacy codebases. Rather than relying on ad-hoc prompting, Forge breaks the software development lifecycle into seven interconnected skills — each producing a persistent artifact that the next skill reads. The result is a context chain that survives session boundaries and enforces discipline: AI is the developer, humans provide intent and judgment.

The core paradigm is maintenance-first: Forge is designed for evolutionary development on real codebases with existing inconsistencies, not greenfield projects. Every skill is constrained by project-specific conventions captured in `.forge/context/`, preventing convention drift even as Claude Code sessions come and go.

---

<!-- forge:onboard source-file="onboard.md" section="tech-stack" profile="core/tech-stack" verified-commit="59836a2" body-signature="182c2f29cc2aa572" generated="2026-04-23" -->

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Plugin manifest | Claude Code Plugin (plugin.json v0.5.0-dev) [high] |
| Primary content format | Markdown (SKILL.md files) [high] |
| Scripting | JavaScript / ESM (`status.mjs`) [medium] |
| Runtime environment | Claude Code client (reads skill files natively) [high] |

<!-- /forge:onboard section="tech-stack" -->

---

<!-- forge:onboard source-file="onboard.md" section="module-map" profile="core/module-map" verified-commit="59836a2" body-signature="32eee1b9c716a339" generated="2026-04-23" -->

## Module Map

| Module | Path | Responsibility |
|--------|------|----------------|
| `forge` | `plugins/forge/skills/forge/` | Orchestrates workflow state and routes to correct skill [high] |
| `onboard` | `plugins/forge/skills/onboard/` | Generates kind-aware project map via composable profiles [high] |
| `clarify` | `plugins/forge/skills/clarify/` | Traces code paths and surfaces requirement unknowns [high] |
| `design` | `plugins/forge/skills/design/` | Produces technical design and task plan in four stages [high] |
| `code` | `plugins/forge/skills/code/` | Implements single task strictly within declared scope [high] |
| `inspect` | `plugins/forge/skills/inspect/` | Reviews all changed files for a feature against conventions [high] |
| `test` | `plugins/forge/skills/test/` | Generates test plan and test code for a completed feature [high] |
| `forge-explorer` | `plugins/forge/agents/forge-explorer.md` | Traces one code path end-to-end; spawned by clarify [high] |
| `forge-architect` | `plugins/forge/agents/forge-architect.md` | Designs one technical approach direction; spawned by design [high] |
| `forge-reviewer` | `plugins/forge/agents/forge-reviewer.md` | Reviews one file per instance; spawned by inspect [high] |
| `profiles/` | `plugins/forge/skills/onboard/profiles/` | Kind definitions and profile templates for onboard [high] |

<!-- /forge:onboard section="module-map" -->

---

<!-- forge:onboard source-file="onboard.md" section="entry-points" profile="core/entry-points" verified-commit="59836a2" body-signature="01dc88567806312b" generated="2026-04-23" -->

## Entry Points

### Plugin Skills
- `/forge:forge` — master orchestrator, auto-detects state and routes (`plugins/forge/skills/forge/SKILL.md`) [high]
- `/forge:onboard` — generates kind-aware project map (`plugins/forge/skills/onboard/SKILL.md`) [high]
- `/forge:clarify <requirement>` — requirement analysis and code path tracing (`plugins/forge/skills/clarify/SKILL.md`) [high]
- `/forge:design <feature>` — four-stage technical design + task decomposition (`plugins/forge/skills/design/SKILL.md`) [high]
- `/forge:code <task-id>` — implements a single task (e.g. `/forge:code T001`) (`plugins/forge/skills/code/SKILL.md`) [high]
- `/forge:inspect <feature-slug>` — feature-scoped code review (`plugins/forge/skills/inspect/SKILL.md`) [high]
- `/forge:test <feature-slug>` — test plan and test code generation (`plugins/forge/skills/test/SKILL.md`) [high]

### Agents (spawned internally by skills)
- `forge-explorer` — spawned by `/forge:clarify`, one instance per entry point [high]
- `forge-architect` — spawned by `/forge:design`, parallel direction exploration [high]
- `forge-reviewer` — spawned by `/forge:inspect`, one instance per changed file [high]

<!-- /forge:onboard section="entry-points" -->

---

<!-- forge:onboard source-file="onboard.md" section="local-development" profile="core/local-dev" verified-commit="59836a2" body-signature="c446453a11d0b357" generated="2026-04-23" -->

## Local Development

### Install (local development mode)

```bash
git clone https://github.com/lotusp/forge.git
claude --plugin-dir ./forge
```

### Hot-reload after skill edits

```bash
/reload-plugins
```

### Install via marketplace (end users)

Add to `~/.claude/settings.json`:
```json
{
  "extraKnownMarketplaces": {
    "forge": { "source": { "source": "url", "url": "https://github.com/lotusp/forge.git" } }
  },
  "enabledPlugins": { "forge@forge": true }
}
```

Verify: run `/skills` in Claude Code — 7 `forge:*` skills should show **on**. [high]

<!-- /forge:onboard section="local-development" -->

---

<!-- forge:onboard source-file="onboard.md" section="key-data-flows" profile="core/data-flows" verified-commit="59836a2" body-signature="aaccb62c038449a1" generated="2026-04-23" -->

## Key Data Flows

1. **Feature development pipeline**: `/forge:onboard` produces `.forge/context/onboard.md` →
   `/forge:clarify <feature>` reads context + traces code paths → produces `.forge/features/{slug}/clarify.md` →
   `/forge:design` reads clarify.md + context → produces `.forge/features/{slug}/design.md` + `plan.md` →
   `/forge:code T00N` reads plan.md + conventions → writes source files + task summary →
   `/forge:inspect <slug>` reads all task summaries + convention files → produces `inspect.md` →
   `/forge:test <slug>` reads inspect.md + design.md → produces test files + `test.md` [high]

2. **Orchestrator routing**: `/forge:forge [intent]` reads `.forge/JOURNAL.md` (last 30 lines) +
   `.forge/context/` files + `.forge/features/` state → determines next skill to invoke →
   routes transparently with carry-over context [high]

3. **Convention lock-in**: `/forge:onboard` Stage 3 scans source for conventions → resolves conflicts →
   writes `.forge/context/conventions.md` / `testing.md` / `architecture.md` / `constraints.md` →
   every subsequent `code` / `inspect` / `test` invocation reads these files before acting [medium]

<!-- /forge:onboard section="key-data-flows" -->

---

<!-- forge:onboard source-file="onboard.md" section="notes" profile="core/notes" verified-commit="59836a2" body-signature="8538836bf1bcd109" generated="2026-04-23" -->

## Notes

- **Self-hosting**: This repo develops Forge using Forge itself. The `.forge/` directory contains Forge's own development artifacts, not a target project's context. Feature slugs follow the `skill-{name}` or descriptive kebab-case convention. [high]
- **v0.5.0 pipeline consolidation**: `calibrate` was absorbed into `onboard` Stage 3; `tasking` was absorbed into `design` Stage 4. The old 9-skill flow is now 7 skills. [high]
- **Naming conflict history**: `tasking` (formerly `plan`) and `inspect` (formerly `review`) were renamed because Claude Code has native `/plan` and `/review` commands that conflict even under the `/forge:` prefix. [high]
- **Marketplace nested structure**: Plugin content lives under `plugins/forge/` (not the repo root) because the Claude Code marketplace model requires plugins to be in a subdirectory; the repo root acts as the marketplace via `.claude-plugin/marketplace.json`. [high]
- **Active feature work**: `.forge/features/` contains 3 active features: `plugin-bootstrap`, `onboard-kind-profiles`, and `lean-kind-aware-pipeline`. [medium]
- **~6 TODO/FIXME markers** across skill SKILL.md files — low density, no concentration hotspot. [medium]
- **Docs are read-only reference**: `docs/forge-plugin-design.md` and `docs/detailed-design.md` are design references; do not modify during feature implementation. [high]

<!-- /forge:onboard section="notes" -->
