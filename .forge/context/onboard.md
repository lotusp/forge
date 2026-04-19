# Project Onboard: forge

> 生成时间：2025-01-01
> 生成方式：手工补录（自举阶段跳过了 /forge:onboard）
> 文件路径：.forge/context/onboard.md

---

## What This Is

Forge 是一个 Claude Code 插件，为存量/遗留代码库提供 AI 驱动的开发工作流。
它将完整的功能开发周期拆解为一组相互衔接的 skill，每个 skill 产出结构化的
文档产物，存储在 `.forge/` 目录中，下一个 skill 直接读取，形成可跨会话持续
的上下文链。

核心设计：AI 是开发者，人类提供意图和判断。Forge 专为遗留系统的维护性开发
而设计，而不是绿地项目。

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| 语言 | Markdown + JavaScript (Node.js 脚本) |
| 插件格式 | Claude Code Plugin（`.claude-plugin/plugin.json`） |
| Skill 格式 | SKILL.md（YAML frontmatter + Markdown 正文） |
| Agent 格式 | agents/*.md（YAML frontmatter + Markdown 正文） |
| 脚本 | Node.js ESM（`.mjs`），用于状态检测和校验 |

---

## Module Map

| Module | Path | Responsibility |
|--------|------|----------------|
| Plugin manifest | `.claude-plugin/` | plugin.json + marketplace.json |
| Skills | `skills/` | 9 个 skill，每个一个子目录 |
| Agents | `agents/` | 3 个专用 agent（explorer、architect、reviewer） |
| Forge orchestrator | `skills/forge/` | 主编排器，自动检测状态并路由 |
| Docs | `docs/` | 设计文档（只读参考） |

---

## Entry Points

所有 skill 通过 `/forge:{name}` 调用。主要入口：

- `/forge:forge` — 主编排器（推荐入口）
- `/forge:onboard` → `/forge:calibrate` → 各功能 skill

---

## Notes

- 本项目使用 forge 自身的工作流来开发自身（自举）
- `.forge/context/` 在自举阶段是手工补录的，不是由 `/forge:onboard` 和 `/forge:calibrate` 自动生成的
- 生产环境中这两个文件由对应 skill 生成，格式遵循 `skills/onboard/reference/output-template.md`
