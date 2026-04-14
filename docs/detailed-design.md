# Forge Plugin — Detailed Technical Design

> 参考来源：`docs/forge-plugin-design.md`  
> 技术规范基于 Claude Code 官方插件系统文档和 `feature-dev` 参考实现。

---

## 一、Plugin 架构总览

### 1.1 Claude Code Plugin 机制

Claude Code 通过 `.claude-plugin/plugin.json` 识别插件元数据，通过约定目录（`skills/`、`agents/`、`hooks/` 等）自动发现组件，无需在 `plugin.json` 中逐一注册。

用户通过 `/forge:<skill>` 触发调用：

```
用户输入 /forge:clarify "需求描述"
      ↓
Claude Code 找到 forge 插件 → 加载 skills/clarify/SKILL.md 的 frontmatter + 正文
      ↓
Claude 按 SKILL.md 中定义的流程执行
（内部委派 forge-explorer agent 并发追踪代码路径）
      ↓
产出 .forge/clarify-[feature].md + 交互式追问
```

### 1.2 目录结构（完整目标态）

```
forge/
├── .claude-plugin/
│   └── plugin.json              # 插件元数据（精简，组件靠约定目录自动发现）
│
├── skills/                      # Slash commands，用户或 Claude 自动调用
│   ├── onboard/
│   │   └── SKILL.md
│   ├── calibrate/
│   │   └── SKILL.md
│   ├── clarify/
│   │   └── SKILL.md
│   ├── design/
│   │   └── SKILL.md
│   ├── plan/
│   │   └── SKILL.md
│   ├── code/
│   │   └── SKILL.md
│   ├── review/
│   │   └── SKILL.md
│   └── test/
│       └── SKILL.md
│
├── agents/                      # 专用子 agent，被 skill 内部委派
│   ├── forge-explorer.md        # 代码追踪 agent（供 clarify 使用）
│   ├── forge-architect.md       # 方案设计 agent（供 design 使用）
│   └── forge-reviewer.md        # 规范审查 agent（供 review 使用）
│
├── docs/                        # 开发文档
├── .forge/                      # 自托管：用 Forge 开发 Forge 的上下文
├── CLAUDE.md
└── README.md
```

---

## 二、plugin.json 规范

`plugin.json` 只承载元数据，组件通过约定目录自动发现，不需要手动注册。

```json
{
  "name": "forge",
  "version": "0.1.0",
  "description": "AI-driven development workflow for existing codebases. Guides you from requirement to tested code through persistent artifacts.",
  "author": {
    "name": "Gordon"
  }
}
```

**约定目录自动发现规则：**
- `skills/*/SKILL.md` → 注册为 `/forge:<dirname>` slash command
- `agents/*.md` → 注册为可委派的子 agent
- `hooks/hooks.json` → 自动激活 hooks（v2）
- `.mcp.json` → 自动注册 MCP 工具（v2）

---

## 三、SKILL.md 格式规范

每个 `SKILL.md` 由两部分组成：**YAML frontmatter**（元数据）+ **Markdown 正文**（指令）。

### 3.1 Frontmatter 字段

```yaml
---
name: clarify                         # skill 标识符（通常与目录名一致）
description: |                        # 触发条件描述，Claude 据此判断是否自动调用
  Analyzes a requirement by tracing code paths and surfacing unknowns.
  Use when user provides a feature requirement or change request.
argument-hint: "<requirement>"        # 命令行补全提示
allowed-tools: "Read Glob Grep Bash"  # 允许无需逐次确认的工具
model: sonnet                         # 模型选择（sonnet / opus / haiku）
effort: high                          # 努力程度（low / medium / high / max）
---
```

**常用字段说明：**

| 字段 | 类型 | 说明 |
|------|------|------|
| `name` | string | skill 名称，覆盖目录名 |
| `description` | string | 触发描述，影响 Claude 自动调用判断 |
| `argument-hint` | string | 参数占位提示，显示在补全菜单 |
| `allowed-tools` | string | 空格分隔，无需每次用户确认 |
| `model` | string | 覆盖当前会话模型 |
| `effort` | string | 覆盖当前努力级别 |
| `user-invocable` | boolean | false 则只有 Claude 可调用，不出现在菜单 |
| `context` | string | `fork` 表示在独立子 agent 中运行 |
| `agent` | string | 配合 `context: fork` 指定 agent 类型 |

### 3.2 Markdown 正文结构

```markdown
---
[frontmatter]
---

## Prerequisites
列出此 skill 依赖的 .forge/ 文件。文件不存在时，提示用户先运行哪个前置 skill。

## Process
按顺序列出执行步骤。每步说明：做什么、判断依据、何时向用户提问。

## Interaction Rules
- 何时暂停并提问（结构化编号列表，说明背景）
- 确认后继续的条件

## Output
写入的文件路径、命名规则、Markdown 结构模板。

## Constraints
不允许做的事（范围边界）。
```

---

## 四、Agent 规范

### 4.1 Agent 文件格式

```yaml
---
name: forge-explorer
description: |
  Traces code paths, maps data flows, and analyzes architecture for a given
  feature or entry point. Use when deep codebase understanding is needed.
tools: Glob, Grep, Read, Bash
model: sonnet
color: yellow
---

[Agent 的详细指令...]
```

**Frontmatter 字段：**

| 字段 | 说明 |
|------|------|
| `name` | agent 标识符 |
| `description` | 委派触发描述，Claude 据此决定何时派发 |
| `tools` | 逗号分隔，agent 可用的工具 |
| `model` | 模型选择 |
| `color` | 显示颜色（yellow / green / red / blue 等） |

### 4.2 三个核心 Agent

#### `forge-explorer`（黄色）
- **供哪个 skill 使用：** `clarify`
- **职责：** 从给定入口点追踪完整调用链，输出：入口位置、调用链（带文件:行号）、数据流、外部依赖
- **工具：** `Glob, Grep, Read, Bash`
- **并发模式：** `clarify` 可同时派出多个 explorer 分别追踪不同入口

#### `forge-architect`（绿色）
- **供哪个 skill 使用：** `design`
- **职责：** 基于 clarify 产物和 conventions，提出具体设计方案，输出：受影响文件列表、变更描述、数据模型变更、API 变更
- **工具：** `Glob, Grep, Read, Bash`
- **并发模式：** `design` 可派出多个 architect 分别探索不同技术方向

#### `forge-reviewer`（红色）
- **供哪个 skill 使用：** `review`
- **职责：** 对照 conventions.md 审查单个文件，输出带置信度评分（≥80 才上报）的发现列表
- **工具：** `Glob, Grep, Read`
- **并发模式：** `review` 对每个受影响文件并发派出 reviewer

---

## 五、各 Skill 详细规范

### 5.1 `/forge:onboard`

**frontmatter：**
```yaml
---
name: onboard
description: |
  Generates a human-readable project map for anyone new to the codebase.
  Use when starting work on an unfamiliar project or onboarding new team members.
allowed-tools: "Read Glob Grep Bash"
model: sonnet
effort: high
---
```

**执行流程：**
1. 扫描目录结构，识别项目类型（monorepo / single app / library）
2. 读取配置文件（`package.json`, `pom.xml`, `go.mod`, `Makefile`, `docker-compose.yml`, `.env.example` 等）
3. 识别入口点（HTTP routes, CLI entrypoints, event handlers, cron jobs）
4. 读取 README.md 提取已有描述
5. 识别模块/服务边界，生成职责描述
6. 提取本地开发、测试、构建命令
7. 输出 `.forge/onboard.md`

**输出文件：** `.forge/onboard.md`

```markdown
# Project Onboard: <project-name>

## What This Is
[一段话：项目目的和业务领域]

## Tech Stack
[列表：语言、框架、数据库、消息队列、云服务]

## Module Map
| Module/Service | Path | Responsibility |
|----------------|------|----------------|

## Entry Points
- **API:** [routes / base URL]
- **CLI:** [commands]
- **Jobs:** [scheduled tasks / workers]
- **Events:** [consumers / publishers]

## Local Development
```bash
# 启动 / 测试 / 构建
```

## Key Data Flows
[1-3 个最核心的数据流]

## Notes
[扫描中发现的特殊约定或注意点]
```

**约束：** 只读，不修改任何项目文件。

---

### 5.2 `/forge:calibrate`

**frontmatter：**
```yaml
---
name: calibrate
description: |
  Extracts the project's implicit coding conventions and codifies them into
  actionable constraints. Run once before starting feature development.
  Requires onboard.md to exist.
allowed-tools: "Read Glob Grep"
model: sonnet
effort: max
---
```

**执行流程（Phase 1 — 扫描）：**
1. 读取 `.forge/onboard.md`；如不存在，提示先运行 `/forge:onboard`
2. 按模块抽样源代码（每个主要模块 3-5 个有代表性的文件）
3. 提取以下维度的模式：架构分层、命名、日志、异常处理、校验、测试、API 设计、DB 访问

**执行流程（Phase 2 — 裁决，与用户交互）：**
1. 对每个存在**矛盾**的维度，呈现：矛盾描述、两侧代码示例（2-4行）、建议选择+理由
2. 用户确认或选择后进入下一个矛盾
3. 对无矛盾的维度，陈述发现的规则，用户可修正

**问题模板：**
```
[CALIBRATE] 约定矛盾 (N/M)

维度：错误处理
Module A (src/auth):    throw new AppError(code, message)
Module B (src/payment): return { success: false, error: message }

建议：采用 AppError（理由：统一异常流，配合全局 error handler）

1. 采用 AppError（推荐）
2. 采用 return 错误对象
3. 视场景而定
4. 需讨论（请描述偏好）
```

**输出文件：** `.forge/conventions.md`

```markdown
# Project Conventions
> 生成时间：YYYY-MM-DD | 由 /forge:calibrate 生成，经人工裁决

## Architecture & Layering
## Naming Conventions
## Logging
## Error Handling
## Validation
## Testing
## API Design
## Database Access
## What to Avoid
## Open Questions
```

**约束：** 只读源代码，不修改任何项目文件。

---

### 5.3 `/forge:clarify`

**frontmatter：**
```yaml
---
name: clarify
description: |
  Analyzes a requirement by tracing existing code paths, mapping data flows,
  and surfacing unknowns. Use when given a feature request or change requirement.
argument-hint: "<requirement description>"
allowed-tools: "Read Glob Grep Bash"
model: sonnet
effort: high
---
```

**feature-slug 规则：** 从用户输入提取 2-4 个英文词，kebab-case，如 `phone-verification`。

**执行流程：**
1. 识别涉及的业务实体和入口点
2. 并发委派多个 `forge-explorer` agent，每个追踪一个入口的完整调用链
3. 汇总 explorer 结果，构建完整代码地图
4. 识别**仅凭代码无法确定**的信息（业务规则、外部系统、运维配置）
5. 生成结构化问题清单，向用户提问（每批最多 5 个，按重要性分级）
6. 收到回答后补充文档，确认完整性

**输出文件：** `.forge/clarify-{feature-slug}.md`

```markdown
# Clarify: {feature-slug}
> 原始需求："{用户原话}" | 生成时间：YYYY-MM-DD

## Requirement Restatement
[用精确技术语言重新描述]

## Current Implementation
### Entry Points
### Call Chain
[调用链，带 file:line]
### Data Flow

## Affected Components
| Component | Path | Impact |

## External Dependencies

## Assumptions Made

## Questions & Answers
| # | Question | Answer | Source |

## Gaps (What Doesn't Exist Yet)
```

---

### 5.4 `/forge:design`

**frontmatter：**
```yaml
---
name: design
description: |
  Produces a concrete technical design for a feature, grounded in existing
  conventions and the clarify analysis. Requires clarify and conventions artifacts.
argument-hint: "<feature-slug>"
allowed-tools: "Read Glob Grep"
model: sonnet
effort: high
---
```

**执行流程：**
1. 读取 `.forge/clarify-{slug}.md` 和 `.forge/conventions.md`
2. 并发委派多个 `forge-architect` agent，分别探索不同技术方向
3. 汇总方案，对比权衡，选定推荐方案
4. 对需要人工决策的设计点，提问确认后继续
5. 输出完整设计文档

**输出文件：** `.forge/design-{feature-slug}.md`

```markdown
# Design: {feature-slug}
> 基于：clarify-{slug}.md + conventions.md | 生成时间：YYYY-MM-DD

## Solution Overview

## Approach Options (if applicable)
| Option | Pros | Cons | Verdict |

## Component Changes
### New / Modified / Deleted

## API Changes

## Data Model Changes

## Impact Analysis
| Area | Risk Level | Description |

## Key Decisions
| Decision | Options | Chosen | Rationale |

## Constraints & Trade-offs

## Open Decisions（需人工确认）
```

---

### 5.5 `/forge:plan`

**frontmatter：**
```yaml
---
name: plan
description: |
  Breaks an approved design into an ordered, executable task list with
  acceptance criteria. Requires design artifact to exist.
argument-hint: "<feature-slug>"
allowed-tools: "Read"
model: sonnet
effort: medium
---
```

**执行流程：**
1. 读取 `.forge/design-{slug}.md`
2. 分解为原子任务，识别依赖关系（拓扑排序）
3. 分配全局唯一 Task ID（`T001`, `T002`...，跨 feature 不重复）
4. 指定类型和验收标准，标记高风险任务

**任务类型：** `infra` / `model` / `migration` / `logic` / `api` / `ui` / `test` / `docs`

**输出文件：** `.forge/plan-{feature-slug}.md`

```markdown
# Plan: {feature-slug}
> 基于：design-{slug}.md | 生成时间：YYYY-MM-DD

## Task List

### T001 — [任务名] `[type]` [⚠ 高风险]
**描述：**
**依赖：** 无 / T00X
**范围：**
- 创建/修改 `path/to/file`
**验收标准：**
- [ ] ...
**规模预估：** small / medium / large

## Dependency Graph
```
T001 → T003
T002 → T003
```

## Risk Register
| Task | Risk | Mitigation |

## Execution Order
```

---

### 5.6 `/forge:code`

**frontmatter：**
```yaml
---
name: code
description: |
  Implements a specific task from the plan, strictly following project conventions.
  Use with a task ID from the plan artifact (e.g., /forge:code T003).
argument-hint: "<task-id>"
allowed-tools: "Read Glob Grep Write Edit Bash"
model: sonnet
effort: high
---
```

**执行流程：**
1. 读取 `.forge/plan-*.md` 中对应任务的验收标准和范围
2. 读取 `.forge/conventions.md`
3. 读取任务涉及的现有源文件
4. 生成代码，严格遵循项目命名、结构和模式
5. 发现任务范围比预期更大时，**停止并报告**，不擅自扩展
6. 输出修改文件 + 摘要

**输出：** 修改后的源文件 + `.forge/code-{task-id}-summary.md`

```markdown
# Code Summary: {task-id}
> Feature: {feature-slug} | 完成时间：YYYY-MM-DD

## Changes Made
| File | Action | Description |

## Key Implementation Decisions

## Deviations from Plan

## Scope Creep Warnings
[发现但未执行的计划外改动]

## Acceptance Criteria Status
- [x] 已完成
- [ ] 未完成（原因）
```

**约束：**
- 不修改任务 scope 外的文件
- 不引入 conventions.md 未定义的新模式（需先讨论）
- 范围外问题：记录，不修复

---

### 5.7 `/forge:review`

**frontmatter：**
```yaml
---
name: review
description: |
  Reviews implemented code against project conventions and feature design.
  Use after coding is complete for a feature or specific file.
argument-hint: "<feature-slug or file-path>"
allowed-tools: "Read Glob Grep"
model: sonnet
effort: high
---
```

**执行流程：**
1. 确定评审范围
2. 读取 `.forge/conventions.md` 和 `.forge/design-{slug}.md`
3. 对每个受影响文件并发委派 `forge-reviewer` agent
4. 汇总所有 reviewer 结果，去重并分级
5. 输出评审报告

**发现级别：**
- `must-fix`：违反 conventions 或设计
- `should-fix`：质量问题，强烈建议
- `consider`：可选改进

**输出文件：** `.forge/review-{feature-slug}.md`

```markdown
# Review: {feature-slug}
> 评审时间：YYYY-MM-DD

## Overall Verdict
**ready** / **needs-work** / **needs-redesign**

## Findings

### `path/to/file`
#### [must-fix] 标题
**位置：** 第 N 行 | **问题：** ... | **应改为：** ...

## Convention Compliance Summary
| Dimension | Status | Notes |

## Design Adherence

## Scope Creep
```

---

### 5.8 `/forge:test`

**frontmatter：**
```yaml
---
name: test
description: |
  Generates a test plan and test code matching the project's testing conventions.
  Use after implementation is reviewed and ready.
argument-hint: "<feature-slug>"
allowed-tools: "Read Glob Grep Write"
model: sonnet
effort: high
---
```

**执行流程：**
1. 从 conventions 确定测试策略（单元/集成/e2e 比重）
2. 从 design 提取需要覆盖的行为（happy path、边界、失败场景）
3. 扫描已有测试，识别需更新的测试
4. 生成新测试文件，严格遵循项目测试命名和结构规范
5. 标记需要特殊基础设施的场景

**输出：** 测试源文件 + `.forge/test-{feature-slug}.md`

```markdown
# Test Plan: {feature-slug}
> 生成时间：YYYY-MM-DD

## Coverage Map
| Scenario | Test Type | File | Status |

## Existing Tests to Update
| File | Reason |

## Known Gaps

## Infrastructure Prerequisites
```

---

## 六、跨 Skill 一致性要求

### 6.1 Feature Slug 命名规则
- 小写英文，单词间用 `-`，2-5 个单词
- 在同一项目中全局唯一
- 示例：`phone-verification`、`order-export`、`admin-rbac`

### 6.2 Task ID 规则
- 格式 `T{NNN}`，三位数字，**跨整个项目全局唯一**（不按 feature 分段）
- 从 `T001` 开始顺序递增，不跳号

### 6.3 读取顺序约定
每个 skill 执行前，必须按顺序读取：
1. `.forge/conventions.md`（如存在）
2. 当前 feature 的前序文档
3. 任务相关源文件

### 6.4 "暂停提问"触发条件（任何 skill 均适用）
- 业务规则不在代码中体现
- 存在多种技术选择且无明确偏好
- 现有代码中有相互矛盾的约定
- 任务范围超出预期
- 涉及安全敏感的设计决策

---

## 七、自托管开发策略（Bootstrap）

| Forge Skill | 在本项目中对应 |
|------------|--------------|
| `design` | 设计每个 skill 的 SKILL.md 结构和 prompt |
| `plan` | 制定每个 skill 的实现 task 列表 |
| `code` | 编写 SKILL.md、agent.md、plugin.json |
| `review` | 评审 SKILL.md 的完整性和一致性 |
| `test` | 设计 skill 的测试场景，手动验证 |

第一批实现完成（`plan` + `code` + `review`）后，才能用 skill 本身来做后续开发。  
所有产物存放位置见 `docs/artifact-structure.md`。
