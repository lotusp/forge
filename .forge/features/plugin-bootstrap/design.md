# Design: plugin-bootstrap

> 生成时间：2026-04-14  
> 注：此 feature 无前置 clarify 文档（空项目起点），直接从 design 开始。

---

## Solution Overview

搭建 Forge 插件的完整骨架，使插件可被 Claude Code 识别和加载，并交付第一个完整可用的 skill（`plan`）。

骨架包括：`plugin.json`、`skills/` 和 `agents/` 的目录结构、各 `SKILL.md` 和 `agent.md` 的占位文件，以及第一个完整实现的 `plan` skill。

---

## Component Changes

### New Components

| Component | Path | Description |
|-----------|------|-------------|
| Plugin manifest | `.claude-plugin/plugin.json` | 插件元数据 |
| Onboard skill | `skills/onboard/SKILL.md` | 占位（空骨架） |
| Calibrate skill | `skills/calibrate/SKILL.md` | 占位（空骨架） |
| Clarify skill | `skills/clarify/SKILL.md` | 占位（空骨架） |
| Design skill | `skills/design/SKILL.md` | 占位（空骨架） |
| **Plan skill** | `skills/plan/SKILL.md` | **完整实现** |
| Code skill | `skills/code/SKILL.md` | 占位（空骨架） |
| Review skill | `skills/review/SKILL.md` | 占位（空骨架） |
| Test skill | `skills/test/SKILL.md` | 占位（空骨架） |
| Explorer agent | `agents/forge-explorer.md` | 占位（空骨架） |
| Architect agent | `agents/forge-architect.md` | 占位（空骨架） |
| Reviewer agent | `agents/forge-reviewer.md` | 占位（空骨架） |

### Modified Components

无（空项目）

---

## Key Decisions

| Decision | Options Considered | Chosen | Rationale |
|----------|--------------------|--------|-----------|
| 首个完整 skill | onboard / plan / clarify | `plan` | 输入是纯文档，逻辑最简单，且立刻对自身开发有用 |
| plugin.json 内容 | 完整注册 vs 最小化元数据 | 最小化 | 官方约定目录自动发现，无需手动注册；feature-dev 验证了这一点 |
| 占位 SKILL.md 格式 | 空文件 vs 带 frontmatter 骨架 | 带骨架 | 有 frontmatter 才能被 Claude Code 识别为合法 skill，避免加载错误 |
| agents 目录 | bootstrap 一起实现 vs 后续 feature 实现 | 仅放占位 | agents 分属 clarify / design / review，bootstrap 阶段不需要它们 |

---

## Constraints & Trade-offs

- 占位 SKILL.md 必须包含合法的 frontmatter，否则插件加载时可能报错
- `plan` skill 的实现必须完全符合 `docs/detailed-design.md` 中的规范，作为后续 skills 的参考标准
- 不在 bootstrap 阶段引入 hooks 或 MCP 配置

---

## Open Decisions

无，可直接进入 plan 阶段。
