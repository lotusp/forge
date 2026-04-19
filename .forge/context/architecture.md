# Architecture Conventions: forge

> 生成时间：2026-04-19
> 生成方式：/forge:calibrate — 基于代码扫描 + 人工裁决
> 更新方式：重新运行 /forge:calibrate
> 文件路径：.forge/context/architecture.md

**Important:** 本文件描述 Forge 插件自身的架构约定。
另见：context/conventions.md、context/testing.md、context/constraints.md

---

## System Architecture

Forge 是一个**无运行时、纯声明式的 Claude Code 插件**。系统由以下层次构成：

```
┌─────────────────────────────────────────────────────┐
│                  Claude Code 宿主                    │
│  (/forge:{skill} 命令调用 → 加载 SKILL.md 执行)      │
└──────────────────┬──────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────┐
│               编排层 (Orchestration)                  │
│  skills/forge/SKILL.md  ←→  scripts/status.mjs      │
│  职责：检测状态、路由到正确子 skill                    │
└──────────┬──────────────────────────────────────────┘
           │ 路由到
┌──────────▼──────────────────────────────────────────┐
│               Skill 层 (Skills)                      │
│  onboard / calibrate / clarify / design /            │
│  tasking / code / inspect / test                     │
│  职责：每个 skill 完成一个明确定义的开发阶段            │
└──────────┬──────────────────────────────────────────┘
           │ 按需 spawn
┌──────────▼──────────────────────────────────────────┐
│               Agent 层 (Agents)                      │
│  forge-explorer / forge-architect / forge-reviewer   │
│  职责：并发执行单一专项分析任务（代码追踪/设计/评审）    │
└──────────┬──────────────────────────────────────────┘
           │ 读写
┌──────────▼──────────────────────────────────────────┐
│               产物层 (Artifacts)                     │
│  .forge/context/   .forge/features/{slug}/           │
│  职责：跨 skill、跨会话的持久化上下文                  │
└─────────────────────────────────────────────────────┘
```

---

## Layer Responsibilities

### 编排层

- **唯一文件：** `skills/forge/SKILL.md` + `skills/forge/scripts/status.mjs`
- **职责：** 读取目标项目的 `.forge/` 状态，确定下一步动作，路由给用户
- **IRON RULE：** `status.mjs` 是唯一路由权威。编排器不可绕过脚本自行判断

### Skill 层

- **每个 skill 对应一个目录：** `skills/{name}/SKILL.md`
- **职责范围严格对应工作流阶段：** 不跨阶段执行
- **只读 vs 读写：**
  - `onboard`, `calibrate`, `clarify`, `inspect` — 主要只读源文件，输出到 `.forge/`
  - `design`, `tasking` — 只读 `.forge/` 产物，输出新产物到 `.forge/`
  - `code`, `test` — 读写源文件和 `.forge/` 产物
- **禁止越权：** `code` 不可修改不在任务范围内的文件；`inspect` 不可修改任何源文件

### Agent 层

- **每个 agent 对应一个文件：** `agents/forge-{role}.md`
- **总是被 skill 并发 spawn，不单独调用**
- **单一职责：** 每个 agent 实例接收一个具体对象（一条代码路径 / 一个技术方向 / 一个文件）
- **无副作用：** agent 只返回报告，不写文件

### 产物层

```
.forge/
├── context/              # 项目级（所有 feature 共享）
│   ├── onboard.md
│   ├── conventions.md    # 最关键产物，所有下游 skill 必须读取
│   ├── testing.md
│   ├── architecture.md
│   └── constraints.md
├── features/
│   └── {slug}/           # 每个 feature 一个目录
│       ├── clarify.md
│       ├── design.md
│       ├── plan.md
│       ├── inspect.md
│       ├── test.md
│       └── tasks/
│           └── T{NNN}-summary.md   # 每个 task 一份
└── _session/             # 临时会话状态（不提交也可以）
    └── calibrate-scan.md
```

---

## Dependency Rules

### Skill 间依赖（强制顺序）

```
onboard → calibrate → clarify → design → tasking → code → inspect → test
```

- 每个 skill 在 Prerequisites 章节明确声明其依赖的前置产物
- 如果前置产物不存在，skill 必须友好报错，不可尝试推断或跳过

### Conventions 依赖（所有下游 skill）

`code`、`inspect`、`test` 在开始前必须读取 `context/conventions.md`。
这是规范漂移的主要防护措施。

### Agent 依赖（由调用 skill 传入）

Agent 不直接读取 `.forge/` 产物。所有上下文由调用 skill 在 spawn 时传入：
- 文件内容
- 相关的 conventions 片段
- 设计文档的相关章节
- 任务描述

---

## What Does NOT Belong Here

| 不应出现的内容 | 原因 |
|--------------|------|
| 外部依赖（npm packages） | 无 package.json，运行时只有 Claude Code 宿主 |
| HTTP 服务器 / API 路由 | Forge 无运行时服务，所有调用通过 Claude Code 命令 |
| 数据库 / 持久化层 | 持久化完全靠 Markdown 文件（.forge/ 目录） |
| 构建系统 | 无构建步骤，.mjs 脚本直接被 Node.js 执行 |
| 测试框架 | 无自动化测试，见 context/testing.md |

---

## Scripts Architecture

唯一可执行代码是 Node.js ESM 脚本，职责极为单一：

| 脚本 | 职责 | 调用方 |
|------|------|--------|
| `skills/forge/scripts/status.mjs` | 扫描 `.forge/`，输出 `[ACTION]` 路由指令 | forge skill（通过 `!` 命令） |
| `skills/calibrate/scripts/check-prerequisites.mjs` | 验证 onboard.md 存在且有效 | calibrate skill |
| `skills/calibrate/scripts/save-scan-state.mjs` | 将扫描中间状态写到 `_session/` | calibrate skill |
| `skills/calibrate/scripts/validate-output.mjs` | 验证 4 个产物文件格式正确 | calibrate skill |

**约定：** 新脚本只在以下情况创建：
1. 需要在 SKILL.md 的 Runtime snapshot 中运行（`!` 命令）
2. 需要机器可验证的结构检查（validate 类脚本）

否则逻辑应写在 SKILL.md 的 Process 章节中，由 Claude 执行。

---

## Extension Points

新增 skill 时：
1. 在 `skills/{name}/` 目录创建 `SKILL.md`（遵守 conventions.md 的格式规范）
2. 在 `plugin.json` 的 `skills` 数组中注册
3. 如需 agent，在 `agents/forge-{role}.md` 创建，并在 `plugin.json` 的 `agents` 数组中注册
4. 更新 `skills/forge/scripts/status.mjs` 加入新 skill 的状态检测逻辑
5. 更新 `skills/forge/reference/state-machine.md` 加入新的状态转换
