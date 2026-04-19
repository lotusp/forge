# Project Onboard: forge

> 生成时间：2026-04-19
> 生成方式：/forge:onboard
> 文件路径：.forge/context/onboard.md

---

## What This Is

Forge 是一个 **Claude Code 插件**，为存量/遗留代码库提供 AI 驱动的软件开发工作流。
它将完整的功能开发周期拆解为 9 个相互衔接的 skill，每个 skill 产出结构化的 Markdown
文档产物，存储在目标项目的 `.forge/` 目录下，下一个 skill 直接读取，形成可跨会话持续
的上下文链。

核心设计理念：**AI 是开发者，人类提供意图和判断**。Forge 专为存量系统的维护性迭代开发
而设计。使用者无需预先了解完整工作流——主编排器 `/forge:forge` 会自动检测项目当前状态
并告知下一步。

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| 插件格式 | Claude Code Plugin（`.claude-plugin/plugin.json`） |
| Skill 格式 | SKILL.md（YAML frontmatter + Markdown 正文） |
| Agent 格式 | `agents/*.md`（YAML frontmatter + Markdown 正文） |
| 状态检测脚本 | Node.js ESM（`status.mjs`，269 行） |
| 辅助脚本 | Node.js ESM（`calibrate/scripts/*.mjs`，3 个） |
| 产物格式 | 纯 Markdown（`.forge/context/` + `.forge/features/{slug}/`） |
| 版本控制 | Git，托管于 GitHub（`lotusp/forge`） |
| 运行环境 | Claude Code（claude.ai/code） |

无外部依赖、无 package.json、无构建步骤。

---

## Module Map

| 模块 | 路径 | 职责 |
|------|------|------|
| Plugin manifest | `.claude-plugin/` | `plugin.json`（插件元数据）+ `marketplace.json`（市场安装配置） |
| **forge orchestrator** | `skills/forge/` | 主编排器：运行 `status.mjs` 检测状态，路由到正确子 skill |
| onboard skill | `skills/onboard/` | 扫描项目，生成人可读的项目地图 |
| calibrate skill | `skills/calibrate/` | 提取代码约定，交互式裁决矛盾，产出 4 个 context 文件 |
| clarify skill | `skills/clarify/` | 追踪代码路径，澄清需求，提取未知项（调用 forge-explorer） |
| design skill | `skills/design/` | 并发探索技术方向，产出设计方案（调用 forge-architect） |
| tasking skill | `skills/tasking/` | 将设计拆解为带验收标准的有序任务列表 |
| code skill | `skills/code/` | 严格按任务范围实现，含 Scope Creep 和 New Pattern 协议 |
| inspect skill | `skills/inspect/` | 并发逐文件评审，置信度 ≥80 才上报（调用 forge-reviewer） |
| test skill | `skills/test/` | 生成符合项目测试规范的测试代码和测试计划 |
| forge-explorer agent | `agents/forge-explorer.md` | 代码路径追踪（🟡），由 clarify 并发调用 |
| forge-architect agent | `agents/forge-architect.md` | 技术方向设计（🟢），由 design 并发调用 |
| forge-reviewer agent | `agents/forge-reviewer.md` | 逐文件评审（🔴），由 inspect 并发调用 |
| Status script | `skills/forge/scripts/status.mjs` | 唯一权威状态检测器，输出 `[ACTION]` 路由指令 |
| Calibrate scripts | `skills/calibrate/scripts/` | 前置检查、扫描状态保存、产物校验（3 个脚本） |
| Reference docs | `skills/*/reference/` | 各 skill 的输出模板和参考文档 |
| Design docs | `docs/` | 原始设计愿景、完整技术规范、产物结构说明（只读参考） |

---

## Entry Points

Forge 是 Claude Code 插件，无 HTTP / CLI / 消息队列入口。所有调用通过
Claude Code 的 `/forge:{skill-name}` 命令触发。

### 主入口（推荐）

- `/forge:forge [intent | slug | task-id]` — 自动检测状态并路由，适合所有用户

### 各 skill 直接入口

| 命令 | 参数 | 触发时机 |
|------|------|----------|
| `/forge:onboard` | 无 | 项目首次使用 |
| `/forge:calibrate` | 无 | onboard 后 |
| `/forge:clarify` | `<需求描述>` | 有新功能需求时 |
| `/forge:design` | `<feature-slug>` | clarify 完成后 |
| `/forge:tasking` | `<feature-slug>` | design 完成后 |
| `/forge:code` | `<task-id>` | 按任务逐个实现 |
| `/forge:inspect` | `<slug 或 file-path>` | 所有任务完成后 |
| `/forge:test` | `<feature-slug>` | inspect 通过后 |

---

## Local Development

```bash
# 克隆仓库
git clone https://github.com/lotusp/forge.git

# 本地开发模式（在 claude.ai/code 中）
claude --plugin-dir ./forge

# 修改 SKILL.md 后热更新（Claude Code 内执行）
/reload-plugins

# 验证 skill 列表（应看到 9 个 forge:* skill 处于 on 状态）
/skills

# 安装已发布版本：配置 ~/.claude/settings.json 后重启 Claude Code
# 更新已安装版本（Claude Code 内执行）
/plugin update forge
```

---

## Key Data Flows

1. **编排器自动路由：**
   `/forge:forge "新需求"` → `status.mjs` 扫描 `.forge/` 输出 `[ACTION]` →
   forge skill 路由到 `/forge:clarify {slug}` → 执行 clarify 流程 →
   写入 `.forge/features/{slug}/clarify.md`

2. **手动执行单个 skill：**
   `/forge:code T005` → 在所有 `plan.md` 中定位 T005 →
   读取 `.forge/context/conventions.md` → 实现代码 →
   写入 `.forge/features/{slug}/tasks/T005-summary.md`

3. **inspect 并发评审：**
   `/forge:inspect {slug}` → 读取 `tasks/T*-summary.md` 获取变更文件 →
   并发 spawn forge-reviewer agent（每文件一个）→
   过滤置信度 <80 的发现 → 汇总写入 `.forge/features/{slug}/inspect.md`

---

## Notes

- **无运行时代码**：Forge 完全由 Markdown 文件组成，唯一可执行代码是 Node.js 脚本（`status.mjs` + calibrate 的 3 个辅助脚本）。所有逻辑对人类完全可读。
- **自举开发**：本项目使用 Forge 自身的工作流开发自身。`.forge/` 目录是 forge 在真实项目中产生的产物结构的活样本。
- **命名冲突规避**：`tasking`（非 `plan`）和 `inspect`（非 `review``）是为了避免与 Claude Code 内置命令冲突。
- **plugin 缓存**：Claude Code 将插件缓存于 `~/.claude/plugins/cache/`，本地修改后需 `/reload-plugins` 才生效。
- **`status.mjs` 是唯一路由权威**：forge orchestrator 的 IRON RULES 明确禁止绕过脚本自行判断下一步，防止编排逻辑分散。
