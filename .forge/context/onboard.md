# Project Onboard: forge

> Kind:                 claude-code-plugin
> Confidence:           1.00
> Generated:            2026-04-23
> Commit:               9dbca95
> Generator:            /forge:onboard (v0.5.0-dev)
> Excluded-dimensions:  logging, validation, api-design, database-access, messaging, authentication

<!-- forge:onboard source-file="onboard.md" section="what-this-is" profile="core/notes" verified-commit="9dbca95" body-signature="c4125c65f5f49896" generated="2026-04-23" -->

## What This Is

Forge is a Claude Code plugin that brings a structured, multi-stage development workflow to existing (legacy) codebases. Rather than treating the AI as an autocomplete tool, Forge makes the AI the developer: it reads persistent context from `.forge/` artifacts, follows strict scope and convention rules, and produces structured outputs at each stage that feed the next.

The plugin consists of 7 skills (`forge`, `onboard`, `clarify`, `design`, `code`, `inspect`, `test`) and 3 specialist agents (`forge-explorer`, `forge-architect`, `forge-reviewer`). Skills are invoked as `/forge:<name>` inside Claude Code. All state persists in `.forge/` so work survives across sessions.

<!-- /forge:onboard section="what-this-is" -->

<!-- forge:onboard source-file="onboard.md" section="tech-stack" profile="core/tech-stack" verified-commit="9dbca95" body-signature="bacc06aaf8ae77f5" generated="2026-04-23" -->

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Kind | Claude Code plugin [high] [build] |
| Version | 0.5.0-dev [high] [build] |
| Language | Markdown (SKILL.md, agent definitions, dimension profiles) [high] [readme] |
| Auxiliary scripts | Node.js (MJS) — status.mjs orchestrator helper [inferred] [cli] |
| Distribution | Claude Code marketplace (github.com/lotusp/forge) [high] [readme] |
| Key libraries | No runtime dependencies; Claude Code client is the runtime [high] [build] |

<!-- /forge:onboard section="tech-stack" -->

<!-- forge:onboard source-file="onboard.md" section="module-map" profile="core/module-map" verified-commit="9dbca95" body-signature="11f5f4928c1c81c6" generated="2026-04-23" -->

## Module Map

| Module | Path | Responsibility |
|--------|------|----------------|
| `forge` | `plugins/forge/skills/forge/` | Orchestrates Forge workflow; detects state and routes [high] |
| `onboard` | `plugins/forge/skills/onboard/` | Generates project map and context files via 3-stage process [high] |
| `clarify` | `plugins/forge/skills/clarify/` | Analyzes requirements by tracing code paths and surfacing unknowns [high] |
| `design` | `plugins/forge/skills/design/` | Produces technical design and task plan via 4-stage process [high] |
| `code` | `plugins/forge/skills/code/` | Implements one task from the plan following conventions strictly [high] |
| `inspect` | `plugins/forge/skills/inspect/` | Reviews implemented code against conventions for a feature slug [high] |
| `test` | `plugins/forge/skills/test/` | Generates test plan and test code matching project testing conventions [high] |
| `forge-explorer` | `plugins/forge/agents/forge-explorer.md` | Traces code paths and data flows per entry point [high] |
| `forge-architect` | `plugins/forge/agents/forge-architect.md` | Explores technical directions concurrently for design [high] |
| `forge-reviewer` | `plugins/forge/agents/forge-reviewer.md` | Reviews files against conventions file-by-file [high] |
| `profiles/` | `plugins/forge/skills/onboard/profiles/` | Profiles and kind definitions driving onboard Stage 2 [high] |
| `docs/` | `docs/` | Read-only reference design documents [high] |

<!-- /forge:onboard section="module-map" -->

<!-- forge:onboard source-file="onboard.md" section="entry-points" profile="core/entry-points" verified-commit="9dbca95" body-signature="48a3fb1b21df3924" generated="2026-04-23" -->

## Entry Points

### Plugin Skills

- `/forge:forge` — master orchestrator; auto-detects state and routes (`plugins/forge/skills/forge/SKILL.md`) [high]
- `/forge:onboard` — 3-stage project context generation (`plugins/forge/skills/onboard/SKILL.md`) [high]
- `/forge:clarify <requirement>` — requirement analysis and tracing (`plugins/forge/skills/clarify/SKILL.md`) [high]
- `/forge:design <feature>` — technical design + task plan (`plugins/forge/skills/design/SKILL.md`) [high]
- `/forge:code T{NNN}` — single-task implementation (`plugins/forge/skills/code/SKILL.md`) [high]
- `/forge:inspect <feature-slug>` — feature-scoped code review (`plugins/forge/skills/inspect/SKILL.md`) [high]
- `/forge:test <feature>` — test plan and test code generation (`plugins/forge/skills/test/SKILL.md`) [high]

### Agents (invoked by skills, not directly by users)

- `forge-explorer` — spawned by `/forge:clarify`; one instance per entry point [high]
- `forge-architect` — spawned by `/forge:design`; concurrent direction exploration [high]
- `forge-reviewer` — spawned by `/forge:inspect`; file-by-file review [high]

<!-- /forge:onboard section="entry-points" -->

<!-- forge:onboard source-file="onboard.md" section="local-dev" profile="core/local-dev" verified-commit="9dbca95" body-signature="f6f4e4a99912e7a6" generated="2026-04-23" -->

## Local Development

### Prerequisites
- Claude Code installed [high]
- Plugin installed via marketplace or local plugin-dir mode [high]

### Commands

```bash
# Clone and run in local plugin mode
git clone https://github.com/lotusp/forge.git
claude --plugin-dir ./forge

# Reload plugins after editing skill files (no restart needed)
# Inside Claude Code:
/reload-plugins

# Update installed plugin
# Inside Claude Code:
/plugin update forge
```

### Verification
After installation, run `/skills` inside Claude Code to verify 7 `forge:*` skills show **on** status. [high] [readme]

<!-- /forge:onboard section="local-dev" -->

<!-- forge:onboard source-file="onboard.md" section="key-data-flows" profile="core/data-flows" verified-commit="9dbca95" body-signature="a804d9698509fbbf" generated="2026-04-23" -->

## Key Data Flows

1. **First-run context bootstrap**: `/forge:onboard` (Stage 1) detects project kind → (Stage 2) reads-do-discards profiles → writes `.forge/context/onboard.md` → (Stage 3) scans convention dimensions, batch-resolves conflicts, smart-merges → writes `conventions.md` / `testing.md` / `architecture.md` / `constraints.md` (kind-applicable subset) [high]

2. **Feature development pipeline**: `/forge:clarify <req>` reads context files + traces code → writes `.forge/features/{slug}/clarify.md` → `/forge:design <slug>` reads clarify.md + designs + decomposes tasks → writes `design.md` + `plan.md` → `/forge:code T{NNN}` reads plan + implements → writes source files + `tasks/T{NNN}-summary.md` → `/forge:inspect <slug>` reviews changed files → writes `inspect.md` → `/forge:test <slug>` writes test files + `test.md` [high]

3. **Orchestrated routing**: `/forge:forge [intent|slug|task-id]` reads `.forge/JOURNAL.md` + existing artifacts → auto-detects current pipeline stage → delegates to the appropriate sub-skill with correct arguments [medium]

<!-- /forge:onboard section="key-data-flows" -->

<!-- forge:onboard source-file="onboard.md" section="notes" profile="core/notes" verified-commit="9dbca95" body-signature="bd056b60ac592c85" generated="2026-04-23" -->

## Notes

- **Self-hosting**: this repo uses Forge's own workflow to develop itself; `.forge/` contains Forge's development context, not a sample target project. Feature slugs follow `skill-{name}` convention; task IDs (`T001`...) are globally unique across the project. [high] [readme]
- **v0.5.0 breaking change**: pipeline consolidated from 9 to 7 skills — `calibrate` absorbed into `onboard` Stage 3, `tasking` absorbed into `design` Stage 4. Old invocations of `/forge:calibrate` and `/forge:tasking` no longer exist. [high] [build]
- **Incremental naming conflicts**: `tasking` was formerly `plan` and `inspect` was formerly `review`; both renamed due to conflicts with Claude Code native `/plan` and `/review` commands that persisted even under the `/forge:` namespace prefix. [high] [readme]
- **Commit convention**: Conventional Commits format with Scope `skill/{name}` or `agent/{name}` or `plugin` or `forge`; each task (T001, T002, ...) gets an independent commit. [high] [readme]
- **IRON RULES pattern**: skill SKILL.md files use uppercase "IRON RULES" sections for non-negotiable behavioral constraints; a run violating any rule must stop and self-correct. [high] [code]
- **docs/ is read-only reference**: do not edit files under `docs/`; they are the original design vision and detailed spec that generated skills must honor but not modify. [high] [readme]
- **~6 TODO markers** spread across plugin skill files — no concentrated debt hotspots identified. [medium] [cli]

<!-- /forge:onboard section="notes" -->
