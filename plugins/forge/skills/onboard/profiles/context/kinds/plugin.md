---
kind-id: plugin
display-name: Claude Code Plugin
output-files:
  - conventions.md
  - testing.md
  - architecture.md
  - constraints.md
dimensions-loaded:
  conventions:
    - dimensions/naming
    - dimensions/error-handling
    - dimensions/skill-format
    - dimensions/artifact-writing
    - dimensions/markdown-conventions
    - dimensions/commit-format
    - dimensions/delivery-conventions
  testing:
    - dimensions/testing-strategy
  architecture:
    - dimensions/architecture-layers
  constraints:
    - dimensions/hard-constraints
    - dimensions/anti-patterns
    - dimensions/delivery-conventions
excluded-dimensions:
  - logging
  - validation
  - api-design
  - database-access
  - messaging
  - authentication
---

# Context Kind: Claude Code Plugin

## When this kind applies

Repositories packaged as a Claude Code plugin:
`.claude-plugin/plugin.json` at root (or `plugins/*/`), markdown-heavy
content, `skills/*/SKILL.md` files, `agents/*.md` files. No HTTP server,
no database, no deployment. The "runtime" is the Claude Code client
reading markdown files.

## Context file strategy

- **conventions.md** — focuses on SKILL.md structure, artifact-writing
  nomenclature, markdown style, and commit format. Zero traditional
  runtime concerns.
- **testing.md** — "self-bootstrap is the test"—no automated unit tests.
  Validation strategy centers on running the plugin against the forge repo
  itself (or a sample project).
- **architecture.md** — layering concept = skill / agent / profile / script
  hierarchy. Kind-awareness, invocation routing, artifact pipeline.
- **constraints.md** — IRON RULES pattern conventions (C1..CN), Content
  Hygiene rules (no external project identifiers), anti-patterns observed.

## Excluded dimensions — rationale

- **logging** — 插件无运行时日志输出（Claude Code 本身的日志系统与插件无关）
- **validation** — 无入参结构（SKILL.md 参数由 argument-hint 声明即可）
- **api-design** — 无 HTTP API；skill 调用由 Claude Code 处理
- **database-access** — 无持久化存储
- **messaging** — 无事件 / 消息传递
- **authentication** — 无授权层；Claude Code 已处理
