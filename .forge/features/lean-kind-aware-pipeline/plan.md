# Plan: lean-kind-aware-pipeline

> 基于：`.forge/features/lean-kind-aware-pipeline/design.md`
> 生成时间：2026-04-23
> 生成方式：/forge:tasking
> 目标版本：forge 0.5.0（major / breaking change）

---

## 概览

将 forge 流水线从 9 skills 精简为 7 skills（合并 calibrate→onboard、tasking→design）、
全面推广 kind-aware 到所有产物、质量关卡内嵌到 clarify/design 标准流程。

**15 个任务（T017–T031），4 个高风险。**

---

## Task List

### T017 — 删除 calibrate/ 和 tasking/ 两个 skill 目录 `infra`

**描述：** 整个目录删除 `plugins/forge/skills/calibrate/` 和 `plugins/forge/skills/tasking/`。

**依赖：** 无

**范围：**
- 删除 `plugins/forge/skills/calibrate/` 整个子树
- 删除 `plugins/forge/skills/tasking/` 整个子树

**验收标准：**
- [ ] `plugins/forge/skills/calibrate/` 不存在（`ls` 验证）
- [ ] `plugins/forge/skills/tasking/` 不存在
- [ ] `git status` 显示两个目录被删除

**规模预估：** small

---

### T018 — 建立 profiles/context/ 目录骨架 + README `infra`

**描述：** 在 `plugins/forge/skills/onboard/profiles/` 下新增 `context/` 子目录，
下含 `kinds/` 和 `dimensions/` 两个子目录，以及 README 规范文档。

**依赖：** 无

**范围：**
- `plugins/forge/skills/onboard/profiles/context/` 目录
- `plugins/forge/skills/onboard/profiles/context/kinds/` 目录
- `plugins/forge/skills/onboard/profiles/context/dimensions/` 目录
- `plugins/forge/skills/onboard/profiles/context/README.md`

**验收标准：**
- [ ] 3 个目录存在
- [ ] README 包含：dimension 文件 schema、kind 索引文件 schema、
      onboard Stage 3 调用时的加载合约（参考 v0.4.0 profiles/README.md 风格）
- [ ] README 含与 design.md §4.1 一致的目录树图

**规模预估：** small

---

### T019 — 编写 3 个 context kind 索引文件 `docs`

**描述：** 为 3 个 MVP kind 编写 context 加载索引文件，声明本 kind 加载哪些
dimension 文件、输出到哪些 context 文件、excluded dimensions 列表。

**依赖：** T018

**范围：**
- `profiles/context/kinds/web-backend.md`
- `profiles/context/kinds/claude-code-plugin.md`
- `profiles/context/kinds/monorepo.md`

**验收标准：**
- [ ] 3 文件均含 frontmatter：`kind-id`、`dimensions-loaded`（数组）、
      `output-files`（conventions.md / testing.md / architecture.md / constraints.md
      中本 kind 适用的子集）、`excluded-dimensions`（数组）
- [ ] `claude-code-plugin.md` 显式排除 logging / database-access / api-design /
      messaging / authentication / validation 六维度
- [ ] `web-backend.md` 排除 skill-format / artifact-writing / markdown-conventions
- [ ] `monorepo.md` 的 `dimensions-loaded` 覆盖 workspace 级规范（不含 per-package 细节）
- [ ] 示例合规 C8（e-commerce 调色板）

**规模预估：** small

---

### T020 — 编写 7 个通用 dimension 模板文件 `docs`

**描述：** 编写通用（applies-to 涵盖 ≥2 kind）的 dimension 模板，每个文件定义：
扫描模式 + 提取规则 + 产出 section 模板 + confidence tag 规则。

**依赖：** T018

**范围：**
- `profiles/context/dimensions/naming.md`（通用）
- `profiles/context/dimensions/error-handling.md`（通用）
- `profiles/context/dimensions/commit-format.md`（通用）
- `profiles/context/dimensions/architecture-layers.md`（通用）
- `profiles/context/dimensions/hard-constraints.md`（通用）
- `profiles/context/dimensions/anti-patterns.md`（通用）
- `profiles/context/dimensions/testing-strategy.md`（通用；内容按 kind 分支）

**验收标准：**
- [ ] 7 文件均含 frontmatter：`name`、`output-file`（conventions / testing / architecture /
      constraints 之一）、`applies-to`（kind 列表）、`scan-sources`、`token-budget`
- [ ] 每个文件正文含 4 小节：Scan Patterns / Extraction Rules / Output Template /
      Confidence Tags（与 v0.4.0 onboard profile schema 对齐）
- [ ] `testing-strategy.md` 必须含 kind 分支：claude-code-plugin 输出"以 self-bootstrap
      为验证"模板；web-backend / monorepo 输出传统框架+mock+覆盖率模板
- [ ] 示例遵守 C8

**规模预估：** medium

---

### T021 — 编写 6 个 web-backend 专用 dimension 文件 `docs`

**描述：** 编写 web-backend（以及大部分 monorepo）适用的 dimension 模板。

**依赖：** T018、T020（保持 schema 一致）

**范围：**
- `profiles/context/dimensions/logging.md`
- `profiles/context/dimensions/validation.md`
- `profiles/context/dimensions/api-design.md`
- `profiles/context/dimensions/database-access.md`
- `profiles/context/dimensions/messaging.md`
- `profiles/context/dimensions/authentication.md`

**验收标准：**
- [ ] 6 文件 schema 与 T020 一致
- [ ] `applies-to` 包含 web-backend（monorepo 可选）
- [ ] 每个 dimension 明确"claude-code-plugin 不加载"
- [ ] 多框架扫描覆盖（logging 含 Slf4j/Winston/Pino/zap；api-design 含 Spring/Express/
      Gin/FastAPI；database-access 含 JPA/Prisma/GORM/SQLAlchemy）
- [ ] 示例遵守 C8

**规模预估：** medium

---

### T022 — 编写 3 个 claude-code-plugin 专用 dimension 文件 `docs`

**描述：** 编写 claude-code-plugin 专用 dimension 模板，支撑 forge 自举
（以及其他 Claude Code plugin 项目）的 kind-aware 产出。

**依赖：** T018、T020

**范围：**
- `profiles/context/dimensions/skill-format.md`（SKILL.md 结构约定、frontmatter 字段）
- `profiles/context/dimensions/artifact-writing.md`（.forge/ 产物编写纪律、marker 格式）
- `profiles/context/dimensions/markdown-conventions.md`（SKILL.md / agent.md / 文档的
  markdown 风格：标题层级、列表、代码块语言标注、tag 用法）

**验收标准：**
- [ ] 3 文件 schema 与 T020 一致
- [ ] `applies-to` 仅含 claude-code-plugin
- [ ] `skill-format.md` 覆盖 IRON RULES 结构、Step 编号、R9/R10 的 marker + tag 系统
      （复用 v0.4.0 onboard 经验）
- [ ] `artifact-writing.md` 覆盖 preserve 块 / section marker / commit 规范与 .forge/
      产物的绑定关系
- [ ] 示例遵守 C8

**规模预估：** small-medium

---

### T023 — 改写 onboard/SKILL.md — Stage 3 + R11-R14 `skill` ⚠ 高风险

**描述：** 在现有 onboard SKILL.md（v0.4.0，636 行）基础上新增 Stage 3 阶段，
吸收 calibrate 职责：扫描 convention 证据、批量检测冲突、一次性交互裁决、
smart merge 既有 context 文件、写入 4 个（kind 适用的子集）产物。

**依赖：** T017、T018、T019、T020、T021、T022

**范围：**
- `plugins/forge/skills/onboard/SKILL.md`（+约 250–300 行）

**风险缓解：**
1. 先骨架后填内容（Stage 3 标题 + 每步意图 → 再填扫描模式引用 + 冲突 UX + merge 算法）
2. Stage 3.3 batch conflict UX 用完整字面示例锁定（参照 design.md §5.3）
3. smart merge 算法用伪代码描述（读 old file → 对位 new template 章节 → orphaned 移 Legacy
   Notes → preserve 块无条件保留）
4. R11-R14 语言采用 v0.4.0 R9 "two separate attributes, NOT alternatives" 硬阻断风格
5. 完成后人工走读 3 场景（fresh web-backend / forge self / monorepo）一遍确认

**验收标准：**
- [ ] SKILL.md 新增 Stage 3（扫描 + 冲突 + merge + 写入），IRON RULES 含 R11-R14
- [ ] Stage 3.1 非交互扫描流程明确（伪代码或流程图）
- [ ] Stage 3.3 批量冲突裁决含完整字面示例（照搬 design.md §5.3 batch UX）
- [ ] Stage 3.4 smart merge 算法伪代码覆盖 4 场景：
      unchanged section → reuse；changed section → rewrite；
      orphaned section → Legacy Notes；preserve block → verbatim
- [ ] R12 明确"不适用于当前 kind 的 context 文件不应被创建"
- [ ] R13 明确产物 header 必须含 `excluded-dimensions` 元数据
- [ ] onboard.md header 示例字面化（K-6 excluded-dimensions 样例，照搬 design.md §5.1）
- [ ] Context file section marker 字面示例（新增 `source-file` 属性，照搬 §5.2）
- [ ] 人工走读：模拟 3 个 kind 跑 Stage 3，无逻辑歧义

**规模预估：** large

---

### T024 — 更新 clarify/SKILL.md — Step 6 + Step 8 + R15-R16 `skill` ⚠ 高风险

**描述：** 升级 clarify skill：Step 6 强制 Q 分类（WHAT/HOW 标签）、
新增 Step 8 self-review 机制、IRON RULES 增 R15-R16。

**依赖：** T017

**范围：**
- `plugins/forge/skills/clarify/SKILL.md`（+约 80–120 行）

**风险缓解：**
1. Step 8 self-review 检查项列表固化 5 条（K-8），避免 LLM 自行发挥无尽检查
2. Revise 触发阈值明确：severity ≥ major 才触发；minor 仅记录不 revise
3. Self-review 日志作为 clarify.md 头部元数据块嵌入，可审计（K-8）

**验收标准：**
- [ ] Step 6 改为强制 Q 分类：每个 Q 必须带 `[WHAT]` 或 `[HOW]` 标签
- [ ] `[HOW]` 类 Q 自动重定向到 design-inputs.md，不进入 Q&A 批次
- [ ] 新增 Step 8（在 Step 7 Write 之前）描述 self-review 流程
- [ ] Self-review 检查项与 K-8 一致（scope-creep / contradiction / unresolved-blocking /
      success-criteria-too-vague / gap-success-mismatch）
- [ ] R15 要求 self-review 必触发且覆盖 5 项
- [ ] R16 要求 revise 后在 clarify.md 头部嵌入 self-review 日志
- [ ] Self-review 日志格式字面示例（用 `<!-- clarify:self-review ... -->` marker，
      明示触发检查数 / revise 次数 / 最终判定）
- [ ] 人工走读：假设一个 clarify 草稿含 2 个 scope-creep Q，走 Step 8 完整流程无歧义

**规模预估：** medium

---

### T025 — 改写 design/SKILL.md — Stage 2-4 + R17-R20 `skill` ⚠ 高风险

**描述：** 最大的单文件改写。design 从 202 行扩到预计 600+ 行，新增 3 个 Stage：
Stage 2 Scenario Walkthrough、Stage 3 Embedded spec-review、Stage 4 Task decomposition
（吸收 tasking 职责），IRON RULES 增 R17-R20。

**依赖：** T017

**范围：**
- `plugins/forge/skills/design/SKILL.md`（大改）

**风险缓解：**
1. 参考 v0.4.0 onboard Option C 两阶段流程的结构，用"Stage 产出冻结"语义
2. Stage 4 task decomposition 直接迁移 tasking/SKILL.md 现有内容并融合（不重新设计）
3. Walkthrough 场景数固定 3（K-9），避免 LLM 发散
4. Embedded spec-review 用 design.md §5.6 的字面示例锁定输出格式
5. T{last} docs 任务模板完整字面化（照搬 design.md §5.4），任何 kind 变体都有明确文本
6. 完成后人工走读 Scenario 1（web-backend feature），Stage 1→2→3→4 全流程无歧义

**验收标准：**
- [ ] SKILL.md 含 Stage 2（Walkthrough）+ Stage 3（spec-review）+ Stage 4（task decomposition）
- [ ] Stage 2 强制产出 3 个场景（happy path + 2 edge cases），任一场景暴露漏洞硬阻断
- [ ] Stage 2 含 "Wire Protocol Literalization" 子章节，要求产物/API/持久化
      结构给出可 copy-paste 字面值
- [ ] Stage 3 embedded spec-review：对照 clarify Success Criteria 和 Gaps 逐条核对；
      hard block + 允许 decision 层回溯（K-10）
- [ ] Stage 4 task decomposition：原 tasking/SKILL.md 的 Step 1-5 被吸收；
      plan.md 末尾必须含 T{last} docs 任务（字面模板照搬 design.md §5.4）
- [ ] R17 场景 ≥3；R18 线协议字面化；R19 spec-review 硬阻断；R20 T{last} 强制
- [ ] Stage 2/3 输出字面示例（照搬 design.md §5.6 embedded spec-review 输出格式）
- [ ] Task 类型枚举扩充：`infra/model/migration/logic/api/ui/test/docs/skill/agent/profile/kind-def`
- [ ] 人工走读：模拟对本 feature（lean-kind-aware-pipeline）跑一遍 Stage 2-4，
      无逻辑歧义

**规模预估：** large

---

### T026 — 更新 code/SKILL.md — Step 0.5 + R21-R22 `skill`

**描述：** 在 code 的 Step 1（Read task）之前新增 Step 0.5（Convention Gap Check），
检测 conventions.md 是否覆盖本 task 所需的开发规范，缺口触发 Q&A 并写回。

**依赖：** T017

**范围：**
- `plugins/forge/skills/code/SKILL.md`（+约 80–100 行）

**验收标准：**
- [ ] SKILL.md 新增 Step 0.5，在 Step 1（Read task）之前
- [ ] Step 0.5 检测逻辑明确：读 `conventions.md` 的 `## Development Workflow` 章节，
      若缺失或为空 → 推断本 task 需要的规范维度 → Q&A
- [ ] Step 0.5 Q&A 字面示例（照搬 design.md §5.5 code Q&A 格式）
- [ ] Q&A 答案写回路径明确：默认 `conventions.md § Development Workflow`，
      testing-specific 可写到 `testing.md`（DI-3）
- [ ] R21 禁止 code 假设未记录的开发规范
- [ ] R22 要求 Q&A 答案必须持久化到合适文档
- [ ] 触发条件最小化：已有规范不打断，只在缺口时问
- [ ] 人工走读：模拟 task 首次在无 Development Workflow 章节项目跑，Step 0.5 触发顺畅

**规模预估：** medium

---

### T027 — 更新 inspect/SKILL.md — feature-slug 范围锁定 + R23 `skill`

**描述：** inspect 的评审范围改为 feature slug 确定性枚举，不再依赖"最近改动"。

**依赖：** T017

**范围：**
- `plugins/forge/skills/inspect/SKILL.md`（小改，+约 30–50 行）

**验收标准：**
- [ ] SKILL.md 明确 inspect 接受 feature-slug 参数
- [ ] 范围枚举方式明确：优先读 `plan.md` + `tasks/T*-summary.md` 列出改动文件；
      fallback 到 `git log --grep=<slug>`
- [ ] R23 要求 feature-slug 确定性枚举，禁止 "recent files" 启发式
- [ ] argument-hint 显示新语义（`<feature-slug>` 替代 `<feature-or-path>`）
- [ ] 人工走读：对 `onboard-kind-profiles` 跑一次 inspect，文件枚举结果吻合 plan.md

**规模预估：** small

---

### T028 — 更新 forge/SKILL.md + state-machine.md — 9→7 态 `skill` ⚠ 高风险

**描述：** 更新 orchestrator 的 SKILL.md 和 state-machine 引用，移除 calibrate/tasking
状态，合并为新的 7 态流水线。

**依赖：** T017

**范围：**
- `plugins/forge/skills/forge/SKILL.md`（引用更新）
- `plugins/forge/skills/forge/reference/state-machine.md`（状态转移表重写）

**风险缓解：**
1. state-machine 改动前先完整读 status.mjs，确认路由逻辑与 skill 名无关（K-12）
2. 所有 "/forge:calibrate" 文本全量替换为 "onboard stage 3"
3. 所有 "/forge:tasking" 文本全量替换为 "design stage 4"
4. state-machine.md 的状态表重新绘制：9 态 → 7 态，转移边重新审查

**验收标准：**
- [ ] `forge/SKILL.md` 中 `/forge:calibrate` / `/forge:tasking` 0 条残留
      （`grep -c` 验证）
- [ ] `state-machine.md` 状态列表为 7 态（onboard / clarify / design / code / inspect /
      test / forge-itself），完整转移图覆盖所有新状态
- [ ] `status.mjs` 未被修改（文件 hash 与改动前一致）
- [ ] 人工走读：模拟一个"刚跑完 onboard"的项目，/forge:forge 路由到 clarify；
      "刚跑完 design"的项目路由到 code T001

**规模预估：** small-medium

---

### T029 — 版本跃迁 + 文档同步 `infra`

**描述：** 版本号从 0.4.0 升到 0.5.0；README 和 CLAUDE.md 同步反映新流水线。

**依赖：** T017

**范围：**
- `plugins/forge/.claude-plugin/plugin.json`（version 0.4.0 → 0.5.0）
- `README.md`（version badge + skill 表 9→7）
- `CLAUDE.md`（skill 列表 + 目录树）

**验收标准：**
- [ ] `plugin.json` 的 version 字段 = `0.5.0`
- [ ] README badge 更新为 `0.5.0`
- [ ] README skill 表格删除 calibrate / tasking 两行，onboard 描述反映合并
- [ ] CLAUDE.md 目录树删除 calibrate/ / tasking/ 子目录
- [ ] CLAUDE.md 的 Skill Flow 描述更新为 7 节
- [ ] `grep -c "/forge:calibrate\|/forge:tasking" README.md CLAUDE.md` = 0
      （除非明确是"breaking change 告知"章节的旧命令说明）

**规模预估：** small

---

### T030 — 自举验证：对 forge 跑新 /forge:onboard `test`

**描述：** 对 forge 仓库自身跑一次完整新 onboard，验证 10 条 Success Criteria。
对 clarify/design/code 链路做 dry-run 验证（不真的写新 feature）。

**依赖：** T023、T024、T025、T026、T027、T028、T029

**范围：**
- 实际运行 `/forge:onboard`（smart merge 旧 context 文件）
- 虚构小 feature（如 `example-dry-run-flag`），跑 `/forge:clarify → /forge:design`
  dry-run（不跑 code）
- 产出 `.forge/features/lean-kind-aware-pipeline/verification.md` 验证报告

**验收标准：**
- [ ] Success Criteria #1 通过：`/skills` 显示 7 个 forge skill
- [ ] SC #2 通过：.forge/context/ 只有 kind 适用的 context 文件
- [ ] SC #3 通过：新产出的 conventions.md / testing.md 等显著区别于 v0.4.0 旧版
- [ ] SC #4 通过：旧 context 文件 preserve 块 100% 保留；Logging 章节被移到 Legacy Notes
- [ ] SC #5 通过：clarify dry-run 产出含 self-review 头部元数据
- [ ] SC #6 通过：design dry-run 产出 design.md + plan.md 双文件，含 Walkthrough
- [ ] SC #7 通过：design.md 含 "Wire Protocol Examples" 章节
- [ ] SC #8 通过：模拟 Development Workflow 章节为空时，code 首次对话触发
- [ ] SC #9 通过：design 生成的 plan.md 末尾含 T{last} docs 任务
- [ ] SC #10 通过：整链路无报错
- [ ] verification.md 逐条记录 10 条 SC 的实际结果
- [ ] 发现的 blocker 记录为 follow-up；非 blocker 以 Minor 形式归档

**规模预估：** medium

---

### T031 — 更新用户面向文档（T{last}）`docs`

**描述：** T{last} 文档更新任务（DI-4 / R20）。根据本 feature 实际实现内容，
更新 forge 项目的 README.md 和 CLAUDE.md，新增 v0.5.0 升级向导。

**依赖：** T030

**范围：**
- `README.md`（完善：新版特性、升级向导章节）
- `CLAUDE.md`（skill 流程描述、目录树最终版）
- `docs/upgrade-0.5.md`（新建，breaking change 迁移指南）

**验收标准：**
- [ ] README 新增 "What's new in 0.5.0" 或类似章节（简短列举 4 项变化：
      skill 合并 / kind-aware 全面推广 / 新质量关卡 / 产物智能迁移）
- [ ] README 含"升级自 0.4.x 的用户注意事项"简短指引（指向 docs/upgrade-0.5.md）
- [ ] `docs/upgrade-0.5.md` 覆盖：
      - 命令变化（`/forge:calibrate` → onboard stage 3）
      - 命令变化（`/forge:tasking` → design stage 4）
      - 产物兼容性（smart merge 自动处理）
      - 新行为（clarify self-review / design Walkthrough）
- [ ] CLAUDE.md 所有 skill 引用为新 7 个
- [ ] 若本 feature 未触达某 doc，task summary 明确记录 "No user-facing
      doc touched"（本 feature 肯定触达了 README + CLAUDE，不适用）
- [ ] 最终 `git diff HEAD~N README.md CLAUDE.md` 可被人类一眼理解

**规模预估：** small

---

## Dependency Graph

```
T017 (删 calibrate/tasking) ──┬─→ T023 onboard Stage 3 ⚠
                               ├─→ T024 clarify ⚠
                               ├─→ T025 design ⚠
                               ├─→ T026 code
                               ├─→ T027 inspect
                               ├─→ T028 orchestrator ⚠
                               └─→ T029 版本跃迁
T018 (context/ 骨架) ──┬─→ T019 kinds
                        ├─→ T020 universal dims ──┬─→ T021 web-backend dims
                        │                          └─→ T022 plugin dims
                        └───────────────── T023 需要 T019+T020+T021+T022
                                           
T023 + T024 + T025 + T026 + T027 + T028 + T029 ──→ T030 自举验证 ──→ T031 docs finalize
```

## Execution Order

**波次 1（可并行）**
- T017 删除 calibrate / tasking
- T018 建 profiles/context/ 骨架

**波次 2（可并行，等 T018）**
- T019 3 个 kind 索引
- T020 7 个通用 dimension

**波次 3（可并行，等 T020）**
- T021 6 个 web-backend dimension
- T022 3 个 plugin dimension

**波次 4（等波次 3 + T017）**
- T023 onboard Stage 3 改写 ⚠

**波次 5（可并行，等 T017；与 T023 可并行）**
- T024 clarify self-review ⚠
- T025 design 四阶段 ⚠
- T026 code Step 0.5
- T027 inspect
- T028 orchestrator ⚠
- T029 版本跃迁

**波次 6（等 T023–T029 全部）**
- T030 自举验证

**波次 7（等 T030）**
- T031 docs finalize

---

## Risk Register

| Task | Risk | Mitigation |
|------|------|-----------|
| T023 | onboard Stage 3 引入首个 LLM-interactive 阶段，batch UX 若模糊会破坏用户体验 | 字面 UX 示例照搬 design.md §5.3；先骨架后填内容；人工走读 3 kind 场景 |
| T024 | self-review check 清单若过宽，LLM 在无问题时过度 revise，造成 clarify 草稿振荡 | 检查项固化 5 条（K-8）；revise 触发阈值 ≥ major |
| T025 | design SKILL.md 预计膨胀到 600+ 行，IRON RULES 达 20 条时 LLM 覆盖稳定性下降 | Stage 结构化；IRON RULES 分组编号（R1-R4 v0.4.0 继承 / R17-R20 本 feature 新增）；人工走读 |
| T028 | state-machine 改错 → /forge:forge 全链路路由失效 | 先确认 status.mjs 与 skill 名无关（K-12）；改动前后手动对比转移图 |
| T030 | 自举验证若发现 blocker → 需回到对应 T 修复再重跑 | verification.md 逐 SC 记录；blocker 作为 follow-up 单独开 task |

---

## 下一步

```
/forge:code T017
```

然后按波次顺序推进。波次 5 内部 6 个任务可并行（T024–T029），实际开发中建议串行以利人工走读质量。
