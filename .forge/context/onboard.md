<!-- forge:onboard header kind=claude-code-plugin version=0.3.2-dev verified=d3db26a generated=2026-04-22 -->
# Project Onboard Map — Forge

> Last updated by `/forge:onboard` (Mode B — incremental, 2026-04-22)
> Kind: **claude-code-plugin** | Confidence: 0.90
> Profiles loaded: core/tech-stack · core/module-map · core/entry-points · core/local-dev · core/data-flows · core/notes
<!-- /forge:onboard header -->

---

<!-- forge:onboard section=what-this-is verified=d3db26a generated=2026-04-22 -->
## 1. What This Is

Forge is a Claude Code plugin for AI-driven software development on existing and legacy
codebases. It is packaged as a suite of Claude Code skills with the `/forge:` invocation
prefix and distributed via the Claude Code marketplace. [code]

The core paradigm: AI is the developer; humans provide intent and context. Forge is
designed for maintenance and evolutionary development on legacy systems — not greenfield
projects. It solves four common failure modes of AI-assisted development: context loss
across sessions, convention drift, scope creep, and silent assumptions replacing careful
reasoning. [readme]

The repository is structured as a **marketplace repo** at root (`github.com/lotusp/forge`)
with the actual installable plugin content living in `plugins/forge/`. This nesting is
required by the Claude Code marketplace model. [code]

<!-- /forge:onboard section=what-this-is -->

---

<!-- forge:onboard section=tech-stack verified=d3db26a generated=2026-04-22 -->
## 2. Tech Stack

| Layer | Technology |
|-------|-----------|
| Plugin type | Claude Code Plugin — skill/agent/markdown-only [high] |
| Plugin version | `0.3.2-dev` (plugin.json) — README badge still shows `0.3.1` **[conflict]** [build] |
| Runtime | Claude Code client reads SKILL.md files at invocation time; no build step [high] |
| Scripting | Node.js / `.mjs` scripts (calibrate + forge skill helpers) [code] |
| Content format | Markdown (SKILL.md, agent .md files, profile .md files) [code] |
| Distribution | GitHub URL via `extraKnownMarketplaces` in Claude Code settings.json [readme] |

No database, no HTTP framework, no container images. All "infrastructure" is the Claude
Code client reading markdown files. [code]

<!-- forge:preserve -->
**[TEST-MARKER-PRESERVE-1]** This block was inserted by hand during T015 Phase 2
incremental verification. If this text survives a re-run of /forge:onboard, the
preserve-block mechanism works. Timestamp: 2026-04-22 evening.
<!-- /forge:preserve -->

> 完整技术约定见 `.forge/context/conventions.md`（由 `/forge:calibrate` 产生）

<!-- /forge:onboard section=tech-stack -->

---

<!-- forge:onboard section=module-map verified=d3db26a generated=2026-04-22 -->
## 3. Module Map

### Skills (9 total) [code]

| Module | Path | Responsibility |
|--------|------|----------------|
| `forge` | `plugins/forge/skills/forge/` | Master orchestrator; auto-detects project state and routes to the right skill [code] |
| `onboard` | `plugins/forge/skills/onboard/` | Scans project; produces kind-aware navigation map via composable profile files [code] |
| `calibrate` | `plugins/forge/skills/calibrate/` | Extracts implicit conventions; produces 4 authoritative context files [high] |
| `clarify` | `plugins/forge/skills/clarify/` | Traces code paths; surfaces unknowns before design begins [high] |
| `design` | `plugins/forge/skills/design/` | Produces concrete technical design grounded in codebase conventions [high] |
| `tasking` | `plugins/forge/skills/tasking/` | Breaks design into ordered executable tasks with acceptance criteria [high] |
| `code` | `plugins/forge/skills/code/` | Implements a single task strictly within its scope [high] |
| `inspect` | `plugins/forge/skills/inspect/` | Reviews implemented code against conventions and design [high] |
| `test` | `plugins/forge/skills/test/` | Generates test plan and test code matching project conventions [high] |

### Agents (3 total) [code]

| Module | Path | Responsibility |
|--------|------|----------------|
| `forge-explorer` | `plugins/forge/agents/forge-explorer.md` | Traces code paths and data flows per entry point [high] |
| `forge-architect` | `plugins/forge/agents/forge-architect.md` | Explores technical directions concurrently; produces design blueprints [high] |
| `forge-reviewer` | `plugins/forge/agents/forge-reviewer.md` | Reviews files against conventions; reports findings at ≥ 80% confidence [high] |

### Support Directories [code]

| Module | Path | Responsibility |
|--------|------|----------------|
| `profiles/` | `plugins/forge/skills/onboard/profiles/` | Kind definitions and per-section scan profiles for onboard skill [high] |
| `reference/` | `plugins/forge/skills/onboard/reference/` | Incremental-mode algorithm and scan patterns reference [high] |
| `docs/` | `docs/` | Design documents (read-only reference; not shipped in plugin) [high] |
| `.forge/` | `.forge/` | Self-hosting artifacts — context, journal, feature plans [high] |

> 分层规则与模块间通信规则见 `.forge/context/architecture.md`（由 `/forge:calibrate` 产生）

<!-- /forge:onboard section=module-map -->

---

<!-- forge:onboard section=entry-points verified=d3db26a generated=2026-04-22 -->
## 4. Entry Points

### Plugin Skills (9 total) [code]

Each `skills/<name>/SKILL.md` file is one invocable skill:

- `/forge:forge` — master orchestrator; auto-detects project state and routes (`plugins/forge/skills/forge/SKILL.md`) [high]
- `/forge:onboard` — project map generation; now kind-aware with profile architecture (`plugins/forge/skills/onboard/SKILL.md`) [high]
- `/forge:calibrate` — conventions extraction; produces 4 context files (`plugins/forge/skills/calibrate/SKILL.md`) [high]
- `/forge:clarify <feature>` — requirement tracing and unknown surfacing (`plugins/forge/skills/clarify/SKILL.md`) [high]
- `/forge:design <feature>` — technical design production (`plugins/forge/skills/design/SKILL.md`) [high]
- `/forge:tasking <feature>` — task breakdown from approved design (`plugins/forge/skills/tasking/SKILL.md`) [high]
- `/forge:code T{NNN}` — single-task implementation (`plugins/forge/skills/code/SKILL.md`) [high]
- `/forge:inspect <feature|path>` — code review against conventions (`plugins/forge/skills/inspect/SKILL.md`) [high]
- `/forge:test <feature>` — test plan and test code generation (`plugins/forge/skills/test/SKILL.md`) [high]

### Agents (3 total) [code]

- `forge-explorer` — called by `/forge:clarify`; one instance per entry point [high]
- `forge-architect` — called by `/forge:design`; concurrent direction exploration [high]
- `forge-reviewer` — called by `/forge:inspect`; per-file review [high]

### Helper Scripts [code]

Skills invoke Node.js `.mjs` scripts for specific sub-tasks:

- `plugins/forge/skills/forge/scripts/status.mjs` — reads `.forge/` state; used by orchestrator [code]
- `plugins/forge/skills/calibrate/scripts/check-prerequisites.mjs` — pre-flight checks [code]
- `plugins/forge/skills/calibrate/scripts/save-scan-state.mjs` — writes calibrate checkpoint [code]
- `plugins/forge/skills/calibrate/scripts/validate-output.mjs` — validates context file output [code]

No HTTP routes, no CLI commands, no cron jobs, no event consumers.

<!-- /forge:onboard section=entry-points -->

---

<!-- forge:onboard section=local-development verified=d3db26a generated=2026-04-22 -->
## 5. Local Development

### Prerequisites

- Claude Code installed (the plugin's only runtime)
- Git clone: `git clone https://github.com/lotusp/forge.git` [readme]

### Commands

```bash
# Run the plugin locally (launch Claude Code pointing at this repo)
claude --plugin-dir ./forge

# Hot-reload after editing a SKILL.md or agent file (inside Claude Code)
/reload-plugins

# Verify installation: should show 9 forge:* skills as "on"
/skills
```

No build step, no dependency install, no test runner. [code]

All commands sourced from README.md "Local Development" section. [readme]

> 完整测试策略见 `.forge/context/testing.md`（由 `/forge:calibrate` 产生）

<!-- /forge:onboard section=local-development -->

---

<!-- forge:onboard section=key-data-flows verified=d3db26a generated=2026-04-22 -->
## 6. Key Data Flows

1. **Skill pipeline (full workflow)**: `/forge:onboard` → produces `.forge/context/onboard.md` →
   `/forge:calibrate` reads onboard.md + samples code → produces `.forge/context/` (4 files:
   conventions.md, architecture.md, testing.md, constraints.md) →
   `/forge:clarify <feature>` reads context + traces code → produces `.forge/features/{slug}/clarify.md` →
   `/forge:design` reads clarify artifact → produces `design.md` →
   `/forge:tasking` reads design → produces `plan.md` (task list) →
   `/forge:code T{NNN}` reads plan + context → produces source code + `tasks/T{NNN}-summary.md` →
   `/forge:inspect` reads code + conventions → produces `inspect.md` →
   `/forge:test` reads inspect + conventions → produces test code + `test.md` [high]

2. **Orchestrator routing**: `/forge:forge` → reads `.forge/JOURNAL.md` (last 30 lines) + `.forge/` artifact state via `status.mjs` → determines current workflow phase → routes to the appropriate next skill automatically [high]

3. **Onboard kind detection (v0.3.2-dev)**: `/forge:onboard` → reads `kinds/*.md` detection signals → scores repository → selects kind → loads only that kind's profile set → reads each profile as read-do-discard loop → produces kind-appropriate `onboard.md` sections [high]

<!-- /forge:onboard section=key-data-flows -->

---

<!-- forge:onboard section=notes verified=d3db26a generated=2026-04-22 -->
## 7. Notes

- **Self-hosting**: this repo uses Forge's own workflow to develop itself. `.forge/` contains Forge's development context. Feature slugs follow `skill-{name}`; task IDs (`T001`, `T002`, ...) are globally unique across the project. [code]

- **Plugin version conflict**: `plugin.json` declares `0.3.2-dev` but README badge still shows `0.3.1`. README update is deferred to T016 (the 0.4.0 formal release). **[conflict]** [build]

- **onboard skill `onboard-kind-profiles` feature complete (T006–T015 done)**: the `profiles/` architecture (T006–T011), SKILL.md rewrite (T012), `incremental-mode.md` update (T013), and cleanup (T014) are complete. T015 self-bootstrap validation passed. T016 (formal 0.4.0 version bump + README badge update) is the remaining task. [code]

- **`tasking` was formerly `plan`; `inspect` was formerly `review`**: renamed because Claude Code has native `/plan` and `/review` commands that conflicted under the `/forge:` namespace. [code]

- **Content Hygiene constraint (C8)**: all SKILL.md examples and profile templates use a generic e-commerce palette (`Order/Customer/Product/Payment`, `com.example.shop.*`). No real external project identifiers are permitted. Sourced from `.forge/context/constraints.md`. [code]

- **CLAUDE.md is authoritative** for AI guidance in this project — skills should read it before acting. Key note: self-hosting means `.forge/` context is about Forge itself, not a target project. [code]

> 反模式与硬性规则见 `.forge/context/constraints.md`（由 `/forge:calibrate` 产生）

<!-- /forge:onboard section=notes -->

---

## Document Confidence

| Claim type | Count | Source |
|------------|-------|--------|
| `[code]` — verified from source | 28 | Direct file reads + glob/ls |
| `[build]` — from build/manifest file | 3 | plugin.json, marketplace.json |
| `[readme]` — from README, not cross-verified | 4 | README.md |
| `[inferred]` | 0 | — |
| **[conflict]** | 1 | plugin.json version vs README badge |

**Conflicts requiring human review:**
- Plugin version: `plugin.json` = `0.3.2-dev`, README badge = `0.3.1` — README update deferred to T016.

Next step: `/forge:calibrate`
