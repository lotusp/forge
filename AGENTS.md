# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## What This Project Is

**Forge** is a Codex plugin for AI-driven software development on existing/legacy codebases. It is implemented as a suite of Codex skills with the `/forge:` invocation prefix. The primary design document is `docs/forge-plugin-design.md`.

The core paradigm: AI is the developer, humans provide intent and context. Forge is designed for maintenance and evolutionary development on legacy systems — not greenfield projects.

## Repository Structure

```
forge/                             ← marketplace root (github.com/lotusp/forge)
├── .Codex-plugin/
│   └── marketplace.json           ← marketplace manifest, source: "./plugins/forge"
├── plugins/
│   └── forge/                     ← actual plugin content
│       ├── .Codex-plugin/
│       │   └── plugin.json        ← plugin manifest
│       ├── skills/
│       │   ├── forge/             ← master orchestrator
│       │   │   ├── SKILL.md
│       │   │   ├── reference/state-machine.md
│       │   │   └── scripts/status.mjs
│       │   ├── onboard/SKILL.md
│       │   ├── calibrate/
│       │   │   ├── SKILL.md
│       │   │   ├── reference/
│       │   │   └── scripts/
│       │   ├── clarify/SKILL.md
│       │   ├── design/SKILL.md
│       │   ├── tasking/SKILL.md   ← formerly "plan"
│       │   ├── code/SKILL.md
│       │   ├── inspect/SKILL.md   ← formerly "review"
│       │   └── test/SKILL.md
│       └── agents/
│           ├── forge-explorer.md
│           ├── forge-architect.md
│           └── forge-reviewer.md
├── docs/                          ← design documents (read-only reference)
├── .forge/                        ← self-hosting artifacts
├── AGENTS.md
└── README.md
```

> **Why the nested structure?** Codex's marketplace model requires the plugin
> to live in a subdirectory of the marketplace repo. The repo root acts as the
> marketplace (via `.Codex-plugin/marketplace.json`) and `plugins/forge/` is the
> actual installable plugin content.

## Skill Flow

```
onboard → calibrate → clarify → design → tasking → code → inspect → test
```

Or use the master orchestrator which auto-detects state and routes:
```
/forge:forge [intent or slug or task-id]
```

> Note: `tasking` was formerly `plan` and `inspect` was formerly `review`.
> Both were renamed because Codex has native `/plan` and `/review` commands
> that conflicted even under the `/forge:` namespace prefix.

Each skill reads from and writes to `.forge/` artifacts in the **target project** (not this repo). Skills can run independently when context already exists.

## The `.forge/` Artifact Store

When Forge is used in a target project, all persistent context lives in `.forge/` at that project's root:

```
.forge/
├── context/                    ← project-wide knowledge
│   ├── onboard.md              ← project map
│   ├── conventions.md          ← coding style: naming, logging, error handling, validation, API, DB, messaging
│   ├── testing.md              ← testing strategy: framework, isolation, mocks, data patterns, coverage
│   ├── architecture.md         ← layering rules, inter-module communication, tech debt
│   └── constraints.md          ← hard rules, anti-patterns (with file locations), security rules
├── features/                   ← one directory per feature
│   └── {slug}/
│       ├── clarify.md          ← requirement analysis
│       ├── design.md           ← technical design
│       ├── plan.md             ← ordered task list
│       ├── inspect.md          ← review findings
│       ├── test.md             ← test plan
│       └── tasks/
│           └── T{NNN}-summary.md  ← implementation summary per task
├── JOURNAL.md                  ← chronological log of all skill invocations
└── _session/
    └── calibrate-scan.md       ← calibrate scan state (resume checkpoint)
```

## Core Design Principles to Uphold When Implementing Skills

1. **Context files as collective source of truth** — `calibrate` produces four files under `.forge/context/`. Every `code`, `inspect`, and `test` skill must read the relevant context files before acting.
2. **Pause before guessing** — when context is insufficient, surface a structured list of questions rather than assuming. Never silently assume.
3. **Scope discipline** — `code` does not redesign; `design` does not implement. If a task requires broader scope than stated, stop and surface it.
4. **Legacy-first** — work with existing inconsistencies; nudge new code toward better patterns without breaking existing code.
5. **Accessible outputs** — plain-language outputs; technical depth is available but not required.

## Key Documents

| Document | Purpose |
|----------|---------|
| `docs/forge-plugin-design.md` | Original vision — read-only reference |
| `docs/detailed-design.md` | Full technical spec: SKILL.md format, plugin.json schema, per-skill I/O contracts |
| `docs/artifact-structure.md` | Where every artifact lives, how it's named, how to read the project timeline |
| `.forge/JOURNAL.md` | Chronological log of all skill invocations and decisions — start here to understand history |
| `.forge/context/conventions.md` | SKILL.md writing standards (generated by `/forge:calibrate` when ready) |

## Self-Hosting

This project uses Forge's own workflow to develop itself. The `.forge/` directory contains Forge's development context (not a target project's context). Feature slugs follow the pattern `skill-{name}` (e.g., `skill-onboard`). Task IDs (`T001`, `T002`, ...) are globally unique across the entire project.

## Git Commit Convention

使用 [Conventional Commits](https://www.conventionalcommits.org/) 规范，每个 task 完成后单独提交。

**格式：**
```
<type>(<scope>): <subject>

[body]

Co-Authored-By: Codex Sonnet 4.6 <noreply@anthropic.com>
```

**Type：**

| Type | 用途 |
|------|------|
| `feat` | 新增可用的 skill 或 agent 功能 |
| `fix` | 修复 skill / agent 的行为错误 |
| `docs` | 文档变更（含 `.forge/` 产物） |
| `chore` | 项目结构、配置、目录骨架 |
| `refactor` | 重构已有 skill/agent，不改变外部行为 |
| `test` | 测试场景和测试报告 |

**Scope（可选）：**

| Scope | 示例 | 说明 |
|-------|------|------|
| `skill/<name>` | `skill/tasking` | 某个 skill 的实现 |
| `agent/<name>` | `agent/explorer` | 某个 agent 的实现 |
| `plugin` | — | plugin.json 或整体插件结构 |
| `forge` | — | `.forge/` 产物（设计、计划、摘要） |

**Subject 规则：**
- 祈使句，小写开头，结尾不加句号
- 不超过 72 个字符
- 说明"做了什么"，body 说明"为什么"

**示例：**
```
chore(plugin): initialize directory skeleton and plugin manifest

feat(skill/tasking): implement tasking skill with full process instructions

docs(forge): add design and plan artifacts for plugin-bootstrap
```

**提交节奏：** 每个 Task（T001、T002...）完成后独立提交，不批量合并。`.forge/` 产物（design、plan 等）在产出时即提交。

## Planned Future Skills

| Skill | Purpose |
|-------|---------|
| `/forge:migrate` | Plan and execute DB schema / API breaking changes with rollback |
| `/forge:debt` | Catalog and prioritize technical debt |
| `/forge:commit` | Generate structured commit messages and PR descriptions from Forge artifacts |
| `/forge:incident` | Trace root cause of a production issue using codebase and Forge context |
