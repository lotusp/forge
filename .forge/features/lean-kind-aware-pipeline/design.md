# Design: lean-kind-aware-pipeline

> 生成时间：2026-04-23
> 基于：clarify.md + design-inputs.md
> 方案：Option A — 扩展 profiles/ 目录；保留 v0.4.0 profile 架构一脉相承
> 目标版本：forge 0.5.0（major / breaking change）
> 风险：High（skill 名变更 / 流水线重塑 / kind-aware 全量铺开）
> 下一步：/forge:tasking lean-kind-aware-pipeline

---

## 1 · Overview

将 forge 流水线从 9 个 skill 精简为 7 个，全面推广 kind-aware 到所有产物，
并将质量关卡内嵌到 clarify 和 design 的标准流程中。

```
v0.4.0:  onboard → calibrate → clarify → design → tasking → code → inspect → test   (9)
v0.5.0:  onboard                → clarify → design                 → code → inspect → test   (7)
```

| 旧 skill 消失 | 职责归属 |
|-------------|---------|
| `calibrate` | 并入 `onboard` 的 Stage 3 |
| `tasking` | 并入 `design` 的 Stage 4 |

---

## 2 · Key Decisions

| ID | 决策 | 选择 | 理由 |
|----|------|------|------|
| K-1 | Context 文件模板位置 | 扩展 `profiles/context/` 目录（Option A） | 与 v0.4.0 profile 架构一致；新增 kind 零侵入 |
| K-2 | `calibrate` 目录处理 | 完全删除 | v0.5.0 是 major 版本，干净升级；无需 deprecation 过渡 |
| K-3 | `tasking` 目录处理 | 完全删除 | 同上 |
| K-4 | 新 `design` 写入顺序 | 先 design.md → spec-review 通过 → 再 plan.md | spec-review 需完整设计才能验证 |
| K-5 | `code` 首次 Q&A 触发 | 检测 `conventions.md` 中 `## Development Workflow` 章节是否存在且非空 | 最简可靠 |
| K-6 | Excluded-sections 元数据格式 | onboard 产物 header 显式列出 kind 排除的维度 | 补偿 Q4=A 失去的"考虑过但 NA"信号 |
| K-7 | Batch 冲突裁决时机 | onboard Stage 3 扫描完成、写 context 文件**前**，一次性批量呈现 | 避免逐个打断用户；扫描不被交互阻塞 |
| K-8 | clarify self-review 产出 | self-review 报告作为 clarify.md 头部元数据块嵌入 | 可审计但不额外加文件 |
| K-9 | design Scenario Walkthrough 场景数 | 固定 3 个：happy path + 2 个 edge cases | 与 v0.4.0 IRON RULE 演化经验一致 |
| K-10 | embedded spec-review 阻断级别 | Hard block + decision-level 回溯允许（Q5 = A+Q）| 与 Walkthrough 策略一致 |
| K-11 | plan.md T{last} 任务类型 | `docs`，kind-driven 描述 | DI-4 |
| K-12 | orchestrator state-machine 更新范围 | `forge/SKILL.md` + `forge/reference/state-machine.md`；`status.mjs` 不变 | status.mjs 基于产物路径判断，skill 名变化与其无关 |

---

## 3 · Component Changes

### 3.1 New `onboard` skill（吸收 calibrate 职责）

**两阶段合一架构：**

```
Stage 1 — Kind Detection       (v0.4.0 existing, unchanged)
   ↓
Stage 2 — Read-do-discard on kind profiles  (v0.4.0 existing, unchanged)
   → writes .forge/context/onboard.md
   ↓
Stage 3 — Context Scan & Synthesis  (NEW, absorbs calibrate)
   3.1 Non-interactive scan across all context dimensions
   3.2 Conflict detection (batch collection)
   3.3 Batch conflict resolution (ONE interactive checkpoint)
   3.4 Rule synthesis + smart merge with existing context files
   → writes conventions.md / testing.md / architecture.md / constraints.md
       (only the files applicable to current kind)
```

**Runtime Snapshot 增补：**
- 读取 `profiles/context/kinds/<kind-id>.md` 确定本 kind 加载哪些 dimension
- 检查 `.forge/context/` 下已有 context 文件（用于 smart merge）

**IRON RULES 增量：**
- R11：Stage 3 的扫描必须非交互；冲突必须批量收集；交互只在 Step 3.3 发生一次
- R12：不适用于当前 kind 的 context 文件**不应被创建**（Q4=A）
- R13：Excluded dimensions 必须在 onboard.md header 元数据块中显式列出（K-6 补偿）
- R14：已存在的 context 文件（旧格式或 preserve 块）**必须 smart merge**，禁止整文件覆盖

### 3.2 New `clarify` skill（保留 skill + 增 self-review）

**新 Step 6 升级（DI-3 / Q 分类硬约束）：**
- 每个 Q 必须带 `[WHAT]` / `[HOW]` 标签
- `[HOW]` 类 Q 自动重定向到 `design-inputs.md`（不进入 Q&A 批次）
- 违反（未分类 Q）→ skill 自行纠正，不写 clarify.md

**新 Step 8 — Self-Review（draft 后、write 前）：**

```
draft = synthesize(all answers)
issues = self_review(draft, {
  checks: [
    "scope-creep: any [HOW] Q slipped through?",
    "contradiction: Gaps contradict onboard.md?",
    "unresolved-blocking: any Open Question marked blocking?",
    "success-criteria-too-vague: any criterion without verification method?",
    "gap-success-mismatch: Gaps don't fully cover all Success Criteria?"
  ]
})
if issues.severity >= "major":
    revise(draft, issues)
    log_revision_to_metadata_header()
write(.forge/features/{slug}/clarify.md)
```

**IRON RULES 增量：**
- R15：Self-Review 必须执行且至少检查 K-8 列出的 5 项
- R16：Revise 过的 draft 必须在 clarify.md 头部记录 self-review 日志

### 3.3 New `design` skill（吸收 tasking 职责）

**四阶段架构：**

```
Stage 1 — Understand clarify + conventions      (existing)
Stage 2 — Design draft + Scenario Walkthrough   (NEW gate)
Stage 3 — Embedded spec-review                   (NEW gate)
Stage 4 — Task decomposition → plan.md           (absorbs tasking)
```

**Stage 2 新增 Scenario Walkthrough：**
- 固定 3 个场景：happy path + 2 edge cases（K-9）
- LLM 对每个场景 trace 一遍设计决策
- 若任一场景暴露漏洞 → 硬阻断，回到 design decision 层重审（K-10）
- Walkthrough 内容作为 design.md 的一个必备章节

**Stage 2 新增 Wire Protocol Literalization：**
- 任何涉及"产物格式 / API 合约 / 持久化结构 / 交互协议"的设计
  必须在 design.md 的 "Wire Protocol Examples" 子节给出**可 copy-paste 的字面值**
- 禁用 `<hash>` / `<placeholder>` 格式；必须真实字面量（如 `"a3f2c1d4"`）

**Stage 3 Embedded Spec-Review（X 类）：**
- 对照 clarify.md 的 Success Criteria 和 Gaps 逐条核对
- 检查项：
  - 每条 Success Criteria 是否有对应的设计组件
  - 每个 Gap 是否有解决方案
  - 设计是否超出 clarify 范围（scope creep 反向检查）
- Hard block：任何缺口 → 回到 Stage 2 修改 design（允许 decision 层回溯，K-10）

**Stage 4 Task Decomposition：**
- 产出 `plan.md`（独立文件，DI-1）
- Task 类型枚举扩展：`infra / model / migration / logic / api / ui / test / docs / skill / agent / profile / kind-def`
  （后 4 个为 plugin kind 新增）
- **强制 T{last}** 类型为 `docs` 的任务（DI-4 / K-11），描述 kind-driven

**IRON RULES 增量：**
- R17：必须产出 Scenario Walkthrough 含 ≥3 场景
- R18：涉及线协议的设计必须含字面值示例
- R19：Embedded spec-review 硬阻断（通过才写 plan.md）
- R20：plan.md 末尾必须含 T{last}（docs 类型，描述 kind-driven）

### 3.4 New `code` skill（首次对话）

**新 Step 0.5 — Convention Gap Check：**

```
task = read plan.md entry for {T-ID}
required_conventions = infer_required_conventions(task)
  # 示例：task 含 test 工作 → required = ["testing-strategy"]
  # 示例：task 是首个 commit → required = ["commit-format"]

for conv in required_conventions:
    if not has_section(conventions.md, conv):
        ask_user(conv)
        write_back_to(conventions.md, conv)

proceed_with_task()
```

**触发检测（K-5）：**
- 读 `conventions.md` 中 `## Development Workflow` 章节
- 若该章节不存在或为空 → 本次 task 需要的开发规范可能未覆盖
- 只问**本次 task 真正需要**的规范（non-invasive）

**IRON RULES 增量：**
- R21：code 不得假设未记录的开发规范；缺口必须触发 Q&A 并写回 conventions
- R22：Q&A 答案写回 conventions.md 或其他合适文档（testing.md / architecture.md）

### 3.5 New `inspect` skill（feature-slug 范围锁定）

**评审范围明确化：**
- 输入：feature slug
- 评审对象：通过 `git log --grep=<slug>` 或 plan.md 的 `tasks/T*-summary.md` 获取本 feature 所有改动文件
- 不再依赖"最近改动"启发式

**IRON RULES 增量：**
- R23：inspect 范围必须通过 feature slug 确定性地枚举，不用 "recent files" 回退

### 3.6 `test` skill（本 feature 不动）

保留现状。kind-sensitive 的深度改造留给 `test-workflow-per-kind` feature。

### 3.7 `forge` orchestrator

**更新范围：**
- `forge/SKILL.md`：所有引用 `/forge:calibrate` 改为 "onboard（context 阶段）"；所有 `/forge:tasking` 改为 "design（task 阶段）"
- `forge/reference/state-machine.md`：状态转移表从 9 态精简到 7 态
- `scripts/status.mjs`：不动（基于产物路径，与 skill 名无关，K-12）

---

## 4 · File System Changes

### 4.1 新增文件

```
plugins/forge/skills/onboard/profiles/context/                  # NEW
├── README.md                                  # 规范文档
├── kinds/                                     # 每个 kind 的 context dimension 索引
│   ├── web-backend.md
│   ├── plugin.md
│   └── monorepo.md
└── dimensions/                                # 每个维度的扫描 + 模板
    ├── naming.md                              # 通用
    ├── error-handling.md                      # 通用
    ├── logging.md                             # web-backend / monorepo
    ├── validation.md                          # web-backend / monorepo
    ├── testing-strategy.md                    # 所有 kind（内容因 kind 不同）
    ├── api-design.md                          # web-backend
    ├── database-access.md                     # web-backend
    ├── messaging.md                           # web-backend
    ├── authentication.md                      # web-backend
    ├── skill-format.md                        # plugin
    ├── artifact-writing.md                    # plugin
    ├── markdown-conventions.md                # plugin
    ├── commit-format.md                       # 通用
    ├── architecture-layers.md                 # 通用（内容因 kind 不同）
    ├── hard-constraints.md                    # 通用
    └── anti-patterns.md                       # 通用
```

### 4.2 删除文件

```
plugins/forge/skills/calibrate/                # 整个目录删除
plugins/forge/skills/tasking/                  # 整个目录删除
```

### 4.3 大改文件

```
plugins/forge/skills/onboard/SKILL.md         # +Stage 3 流程 + R11-R14
plugins/forge/skills/clarify/SKILL.md         # Step 6 升级 + 新 Step 8 + R15-R16
plugins/forge/skills/design/SKILL.md          # +Stage 2/3/4 + R17-R20
plugins/forge/skills/code/SKILL.md            # +Step 0.5 + R21-R22
plugins/forge/skills/inspect/SKILL.md         # feature-slug 范围 + R23
plugins/forge/skills/forge/SKILL.md           # 引用更新
plugins/forge/skills/forge/reference/state-machine.md  # 9 态 → 7 态
plugins/forge/.claude-plugin/plugin.json      # version → 0.5.0
README.md                                     # badge + skill 表格（9→7）
CLAUDE.md                                     # skill 列表 + 目录树
```

---

## 5 · Wire Protocol Examples（所有新格式的字面化）

### 5.1 New onboard.md Header（K-6 Excluded Sections 元数据）

```markdown
# Project Onboard: forge

> Kind:             plugin
> Confidence:       0.95
> Generated:        2026-04-24
> Commit:           a3f2c1d4
> Generator:        /forge:onboard (v0.5.0)
> Excluded-dimensions: logging, database-access, api-design, messaging, authentication, validation
```

> **注**：`Excluded-dimensions` 仅列出因 kind 不适用而**完全跳过**的维度。
> 这些维度既不会出现在 onboard.md 的 section 中，也不会产出对应 context 文件章节。

### 5.2 Context 文件 Section Marker（复用 v0.4.0 R9 的 5 属性格式）

```markdown
<!-- forge:onboard source-file="conventions.md" section="error-handling" profile="dimensions/error-handling" verified-commit="a3f2c1d4" body-signature="9f8e7d6c5b4a3210" generated="2026-04-24" -->

## Error Handling

...rules derived from scanned evidence...

<!-- /forge:onboard section="error-handling" -->
```

> **注**：新增 `source-file` 属性以区分产物文件（onboard.md vs conventions.md vs testing.md 等）。

### 5.3 Batch Conflict Resolution（K-7）

onboard Stage 3 扫描完成后，发现的所有冲突一次性呈现：

```
[forge:onboard] Convention conflicts detected (Stage 3.3)

Scan complete. 3 conflicts require your resolution before context
files can be written.

────────────────────────────────────────────────
Conflict 1/3 — Error Handling

Pattern A — 使用中：src/services/user.ts, src/services/order.ts
  throw new AppError(ErrorCode.NOT_FOUND, "User not found")

Pattern B — 使用中：src/services/payment.ts
  return { success: false, error: "NOT_FOUND", message: "..." }

Recommendation: A (exception-based centralises via middleware)

Options: [A] [B] [Both allowed, context-dependent] [C - Other (specify)]

────────────────────────────────────────────────
Conflict 2/3 — Naming: database columns

Pattern A — 使用中：users, orders tables
  snake_case (created_at, user_id)

Pattern B — 使用中：audit_log table
  camelCase (createdAt, userId)

Recommendation: A (dominant pattern + standard SQL convention)

Options: [A] [B] [C - Other]

────────────────────────────────────────────────
Conflict 3/3 — Testing: mock level

...

Please answer: "1A 2A 3B" or provide per-item explanation.
```

### 5.4 plan.md T{last} Docs Task（K-11 / DI-4）

```markdown
### T{last} — Update user-facing documentation `docs`

**描述：** 根据本 feature 实际实现的内容，更新项目的用户面向文档。

**kind-aware scope**（design 阶段从 onboard.md 读取当前 kind 确定）：

- `plugin` 项目 →
  - [ ] README.md 版本 badge / onboard 表格 / 安装说明（若接口变化）
  - [ ] CLAUDE.md 目录树 / skill 流程 / 规范引用（若结构变化）
- `web-backend` 项目 →
  - [ ] OpenAPI spec / docs/*.md
  - [ ] CHANGELOG.md（若公开 API 变化）
- `monorepo` 项目 →
  - [ ] 根 README
  - [ ] 涉及子包的 README

**依赖：** 所有 T{NNN}（N < last）

**验收标准：**
- [ ] 所有新引入的用户面向概念在相关 doc 中有覆盖
- [ ] 过时描述已更新（版本号 / 功能列表 / 命令示例）
- [ ] README badge / links 有效
- [ ] 若本 feature **未触达** user-facing 文档，task summary 明确记录
      "No user-facing documentation touched by this feature"

**规模预估：** small（大多数 feature ≤ 30 分钟）
```

### 5.5 code Convention Gap Q&A（K-4 / R21）

```
[forge:code T003] Convention gap detected

This task requires testing work, but .forge/context/conventions.md
does not yet document the project's testing strategy.

Before I proceed, please answer:

Q1. Should this feature include automated unit tests?
    [A] Yes, co-located *.test.ts (project default inferred)
    [B] Yes, separate tests/ directory
    [C] No, deferred to integration testing phase

Q2. TDD-style (test first) or test-after?
    [A] Test-first
    [B] Test-after
    [C] Case-by-case

Q3. Mock strategy for external services?
    [A] Mock at repository/gateway boundary
    [B] Mock at service boundary
    [C] Integration test only (no mocks)

Your answers will be written to conventions.md § Development Workflow
and all subsequent /forge:code runs will read them silently.
```

### 5.6 design Embedded Spec-Review Output（R19 / K-10）

```
[forge:design] Embedded spec-review (Stage 3)

Checking design against clarify.md Success Criteria + Gaps...

Success Criteria coverage:
  ✅ #1  Skill count (design covers calibrate/tasking removal)
  ✅ #2  onboard artifacts (Stage 3 design explicit)
  ✅ #3  kind-aware coverage (profiles/context/ design explicit)
  ⚠️  #4  Old-project upgrade (smart merge mentioned but algorithm absent)
  ✅ #5  clarify self-review (Stage 8 + R15-R16)
  ✅ #6  design double-file (Stage 2-4 + R17-R20)
  ✅ #7  wire protocol literals (§ 5 of design.md)
  ✅ #8  code first-time Q&A (Step 0.5 + R21-R22)
  ✅ #9  docs T{last} (R20 + K-11)
  ⚠️  #10 self-bootstrap no-regression (no plan for verification)

Gap coverage:
  [G-01..G-17 逐条] ...

Uncovered items:
  - Success Criteria #4: smart merge algorithm details absent
  - Success Criteria #10: no self-bootstrap verification task in plan

Decision: HARD BLOCK — 2 uncovered items require design revision
         (falling back to Stage 2 to add merge algorithm specification
          and add a verification task to the plan)
```

---

## 6 · Scenario Walkthroughs（R17 / K-9）

### Scenario 1 — Fresh web-backend project

**Setup：** 全新 Spring Boot + PostgreSQL + Redis + Kafka 项目，用户首次装 forge v0.5.0

**Flow：**
1. `/forge:onboard`
   - Stage 1: kind = `web-backend` @ 0.85
   - Stage 2: 生成 onboard.md（6 个核心 section + tech-stack + module-map + ...）
   - Stage 3.1 扫描：识别 Logger = Slf4j, DB = Hibernate, 发现 2 处错误处理矛盾
   - Stage 3.3 交互：批量呈现 2 个冲突 → 用户选择
   - Stage 3.4: 写 conventions.md / testing.md / architecture.md / constraints.md
   - 产物头部：`Excluded-dimensions: skill-format, artifact-writing`（web-backend 不适用）
2. `/forge:clarify "add order status webhook notification"`
   - Step 6: 所有 Q 带 `[WHAT]` 标签
   - Step 8: self-review 检查 → 无 scope creep / 无 contradiction → 直接 write
3. `/forge:design order-webhook-notification`
   - Stage 1-2: draft 设计 + 3 scenarios（webhook delivery / retry / auth failure）
   - Stage 3: spec-review 通过
   - Stage 4: 写 plan.md（T001-T008 + T009 docs = OpenAPI + CHANGELOG 更新）
4. `/forge:code T001` → ... → `/forge:code T009`
   - T009 自动执行 OpenAPI spec 更新

**Walkthrough 结论：** ✅ 流程无断点；conventions 引导下游；T{last} 文档任务自然落地。

### Scenario 2 — forge self-bootstrap（plugin kind）

**Setup：** 当前 forge 仓库，已有旧的 4 个 context 文件（v0.3/v0.4 格式）

**Flow：**
1. `/forge:onboard`
   - Stage 1: kind = `plugin` @ 0.95
   - Stage 2: 生成 onboard.md（沿用 v0.4.0 行为）
   - Stage 3.1 扫描：识别 skill-format / artifact-writing / commit-format 等维度证据
   - Stage 3.3 交互：若与旧 conventions.md 有 drift，批量呈现；用户选择
   - Stage 3.4: smart merge 旧 context 文件 → 新 kind-aware 格式
     - 旧 conventions.md "Logging"（由旧模板误生成）→ 移到 Legacy Notes 附录
     - 新 conventions.md 含 Skill Format / Artifact Writing / Commit Format 三大块
   - 产物头部：`Excluded-dimensions: logging, database-access, api-design, messaging, authentication, validation`
2. `/forge:clarify "..."` → `/forge:design "..."` → `/forge:code T001..T{last}`
   - T{last} = 更新 README.md + CLAUDE.md（kind-driven scope）

**Walkthrough 结论：** ✅ 旧项目平滑升级；保留 preserve 块；不适用章节完全不出现。

### Scenario 3 — Monorepo workspace

**Setup：** pnpm-workspace + turbo + 6 包（3 apps / 3 libs）的 TypeScript 仓库

**Flow：**
1. `/forge:onboard`
   - Stage 1: kind = `monorepo` @ 0.72
   - Stage 2: 生成 onboard.md（含 Workspace Layout / Tech Stack / Module Map）
   - Stage 3.1 扫描：workspace 级规范（包间依赖方向、共享 tooling、CI）
   - Stage 3.3 交互：若有多包间风格矛盾，批量呈现
   - Stage 3.4: 写 **workspace-level** conventions / testing / architecture / constraints
     （注：包级别细节不在本 feature 范围，K-14 monorepo 递归 onboard 留给后续 feature）
2. 后续 clarify/design/code 流程对工作空间级 feature 正常运行

**Walkthrough 结论：** ✅ 工作空间级场景 OK；per-package 细节延后处理（与 clarify Notes 吻合）。

---

## 7 · Impact Analysis

| 维度 | 影响 | 风险等级 |
|------|------|---------|
| 用户命令破坏 | `/forge:calibrate` `/forge:tasking` 不再可用；用户需要知晓 | Medium |
| 产物兼容性 | 旧 context 文件需 smart merge；preserve 块沿用 | Low |
| 流水线脚本 | `scripts/status.mjs` 基于产物路径判断，skill 名无关 | Low |
| orchestrator 路由 | 需更新状态机（9→7 态） | Medium |
| kind 覆盖 | 3 kinds 全覆盖；新增 kind 需补 `profiles/context/kinds/` 索引 | Low |
| 向外兼容 | README/CLAUDE 必须更新明示 breaking change | Low |
| 自举风险 | forge 自己会用新流水线 develop 下一个 feature；v0.5.0 验收硬需求 | **High** |

**总体风险：High** — skill 名变更 + pipeline 重塑 + 全量 kind-aware 是本 feature 三大高风险点。

---

## 8 · Embedded Spec-Review Self-Run

**对照 clarify.md 10 条 Success Criteria 检查本 design.md：**

| Success Criteria | 本设计覆盖点 | 状态 |
|------------------|-------------|------|
| #1 Skill 数量 = 7 | K-2/K-3（删除 calibrate/tasking）+ § 4.2 | ✅ |
| #2 onboard 产物完整 | § 3.1 Stage 3 / R12 不适用不创建 | ✅ |
| #3 kind-aware 覆盖 | Option A + § 4.1 profiles/context/ 结构 | ✅ |
| #4 老项目升级 smart merge | § 3.1 Stage 3.4 + R14；**Scenario 2 Walkthrough** 演示 | ✅ |
| #5 clarify self-review | § 3.2 Step 8 + R15-R16 + K-8 | ✅ |
| #6 design 双文件 + Walkthrough + spec-review | § 3.3 Stage 2-4 + R17-R20 | ✅ |
| #7 design 线协议字面化 | § 5 全节字面值 + R18 | ✅ |
| #8 code 首次 Q&A | § 3.4 Step 0.5 + K-5 + R21 + § 5.5 字面示例 | ✅ |
| #9 文档更新 task | § 5.4 T{last} 字面模板 + R20 + DI-4 | ✅ |
| #10 自举不回归 | 作为 plan.md 的 T{last-1}（验证任务，在 docs 任务之前）| ⚠ **追加到 tasking 阶段** |

**Embedded spec-review 决策：**

- ✅ 9/10 Success Criteria 在 design 中明确覆盖
- ⚠ #10 (自举不回归) 作为 task 处理（不在 design 层，在 plan 层）——**不阻断 design.md 写入**，但 plan.md 必须含对应 task

**对照 clarify.md 17 个 Gap 检查：**

全部覆盖，无遗漏（见 §3 各 Component Changes 对 G-01..G-17 的对应处理）。

**Spec-review 判定：通过（conditional）** — design.md 可以写入；plan.md 必须在 tasking 阶段显式加入"自举验证"任务。

---

## 9 · Open Decisions

无阻塞决策。所有 K-1..K-12 已明确；Scenario Walkthrough 已通过；Embedded spec-review 已通过（conditional 条件记录在 § 8）。

---

## 10 · Dogfooding Strategy

本 feature 开发过程本身验证多项新 skill 行为，但当前使用的是**旧** design skill。v0.5.0 落地后，推荐的验收自举路径：

1. 回到 forge 仓库
2. 跑新 `/forge:onboard`（Stage 1-3 全走一遍，观察 batch conflict + smart merge 行为）
3. 开一个虚构小 feature（如 `example-dry-run-flag`），跑新 clarify → design → code 全链路
4. 观察：
   - clarify self-review 是否触发
   - design Scenario Walkthrough 是否强制执行
   - plan.md 是否自动含 T{last} docs 任务
   - code 首次对话是否触发（conventions.md Development Workflow 章节为空时）

（该验收方案由 tasking 阶段转化为具体的 T{last-1} 自举任务。）

---

## 11 · Next Step

```
/forge:tasking lean-kind-aware-pipeline
```

预计 task 规模：20–25 个（含 T{last-1} 自举验证 + T{last} 文档更新）。
