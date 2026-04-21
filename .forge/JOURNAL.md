# Forge Development Journal

> 操作日志，追加写入，不修改历史。  
> 任何人打开此文件，可以看到项目从零到完整的演进历史。
> `/forge:forge` 在 Runtime snapshot 中读取末尾 30 行作为新会话上下文。

---

## 2026-04-14

### 项目启动
- 创建仓库，首次提交 `docs/forge-plugin-design.md`（原始愿景）
- 创建 `CLAUDE.md`（项目上下文入口）

### 设计文档完成
- 创建 `docs/detailed-design.md`（各 skill 完整技术规范、SKILL.md 格式、plugin.json 格式）
- 创建 `docs/artifact-structure.md`（产物规范：命名、位置、时间线索引）
- 创建 `.forge/JOURNAL.md`（本文件，时间线正式启动）
- 建立目录骨架：`.forge/`、`docs/decisions/`、`docs/milestones/`、`tests/scenarios/`

**当前状态：** 设计阶段完成，进入实现阶段。  
**下一步：** 运行 `/forge:onboard` 生成项目地图，然后 `/forge:calibrate` 建立 SKILL.md 写作规范。

### 设计调整（基于官方文档研究）
- 更新 `docs/detailed-design.md`：SKILL.md 改为 YAML frontmatter 格式；新增 agents/ 目录和三个核心 agent 规范；plugin.json 简化为纯元数据
- 确认插件可包含：skills、agents、hooks、MCP servers（v1 只用 skills + agents）
- 确认官方 `feature-dev` 插件与 Forge 设计方向相似，作为参考实现

### /forge:design plugin-bootstrap（模拟）
- 产出：`.forge/design-plugin-bootstrap.md`
- 关键决策：首个完整 skill 选 `plan`；plugin.json 最小化；占位文件需含合法 frontmatter

### /forge:plan plugin-bootstrap（模拟）
- 产出：`.forge/plan-plugin-bootstrap.md`
- Tasks：T001（目录骨架）→ T002+T003+T004（并行）→ T005（plan skill 完整实现）
- 下一步：开始 `/forge:code T001`

---

## 2026-04-19 — /forge:onboard
- 产出：.forge/context/onboard.md
- 摘要：9 个 skill、3 个 agent、4 个脚本；Claude Code Plugin 无外部依赖
- 下一步：/forge:calibrate

## 2026-04-19 — /forge:calibrate
- 产出：conventions.md, testing.md, architecture.md, constraints.md
- 裁决：1 个矛盾（交互消息大小写），关键决策：`[forge:{skill}]` 全小写
- 下一步：持续优化 skill 实现

## 2026-04-20 — 优化：JOURNAL.md + Assumptions Made（非 skill 执行，直接代码变更）
- 变更：forge:forge Runtime snapshot 加 JOURNAL 读取；所有 9 个 skill 加 JOURNAL 追加步骤；
  forge:code 加 assumption tracking IRON RULE、Step 3 说明、summary Assumptions Made 章节；
  forge:inspect 扩展 prerequisites 和 Step 2 以接收 assumptions；
  conventions.md 更新产物路径表和 Decision #6；初始化 JOURNAL.md 格式头
- 下一步：评估中优先级改进项（conventions-quickref、design Rejected Approaches 等）

## 2026-04-20 — /forge:onboard (--regenerate, self-bootstrap)
- 产出：.forge/context/onboard.md (575 行, 107 confidence tags, 10 section markers)
- 摘要：验证新 skill（v0.3.0）在 forge 自身项目上的行为；全 9 section 均产出
- 自举发现：
  1. 模板中 "Business Domain vs Technical Layer" 的二分法不适合 meta-project；Section 3 需要明确支持 plugin/library/tool 类项目
  2. Section 4 (Core Domain Objects) 在无数据库项目上需用 "artifact types" 等类比概念填充
  3. Section 5 (Entry Points) 模板预设 HTTP/events/jobs；slash-command 型项目需新子类别
  4. Section 6 (Integration Topology) 对 meta-project 大部分 N/A，模板需说明如何优雅处理
- 置信度警示：无 [conflict]；2 处 [inferred]（空 docs/decisions/、空 docs/milestones/）
- 下一步：据自举发现做 skill 小幅修补（新增 project-kind 检测 + 各 section 的 N/A 指引）

## 2026-04-20 — 规则沉淀：Content Hygiene 约束（非 skill 执行，直接人工更新）
- 触发事件：commit `b1f1f8b` 清理了 skill 模板中来自 AI 辅助开发目标项目的私有标识符
- 变更：
  - conventions.md 新增 "Content Hygiene" 节（适用范围 / 允许内容 / 禁止内容 / 通用示例调色板 / 提交前自检 / 泄漏补救流程 / 例外）
  - conventions.md Decision Log 新增 #7
  - constraints.md 新增 C8（硬约束）+ AP5（反模式）+ TD-006（待建自动化扫描）
  - constraints.md 顶部标注「最近人工更新」日期
- 下一步：继续 onboard skill 的 T3（kind detection + profile 组合架构）

## 2026-04-20 — /forge:clarify onboard-kind-profiles
- 产出：.forge/features/onboard-kind-profiles/clarify.md
- 未知项：10 个问题全部回答（Batch 1 × 5 + Batch 2 × 5），5 个 Open Questions 推迟到 design
- 关键决策：
  - 3 个起手 kind：web-backend / claude-code-plugin / monorepo
  - Profile 位置：skill-local `reference/profiles/*.md`
  - 一次性发 v0.4.0 breaking（无存量用户）
  - IRON RULES 用 core + per-kind overlay 结构
  - Kind detection 信号走 kind 文件 frontmatter（G1 最优）
  - Profile 加载走 read-do-discard 节奏（G1+G2 最优）
  - Monorepo MVP 列包图 + 按包 detect；为未来递归预留 4 条架构约束
  - `--thorough` flag 开启 self-critique；默认关闭
  - Profile 丰度：Lean + golden-path 示例 + 压缩 IRON RULES 提醒
- 3 个设计目标（G1/G2/G3）形成矩阵评估后续每个决策
- 下一步：/forge:design onboard-kind-profiles

## 2026-04-20 — Self-review 修订 clarify.md + clarify skill 加 IRON RULE
- 触发事件：用户要求 review `.forge/features/onboard-kind-profiles/clarify.md`
- 发现：clarify.md 有 5 个实现级决策（Q2/Q4/Q6/Q7/Q10）越界进入 Q&A，违反 clarify skill 的"do not propose solutions"原则
- 变更：
  - 新增 `.forge/features/onboard-kind-profiles/design-inputs.md` (146 行)：
    DI-1..DI-5 收纳剥离的实现级预置边界
  - 重写 `.forge/features/onboard-kind-profiles/clarify.md` (231→303 行)：
    - Q&A 只保留需求级 Q-1..Q-5（范围/策略/能力）
    - 合并 Assumptions/OQ → 单 Open Questions 列表 (OQ-01..OQ-05)
    - 新增 Success Criteria 节 (8 条验收项，含 token 消耗 ≤ 1.5× 基准)
    - 统一编号 (DG1..3 for Goals, Gap-01..11, P-01..04, Q-1..5, OQ-01..05)
    - 合并"非目标" + Accommodation Gaps → 单 Out of Scope (Deferred / Future)
    - Data Flow 扩写含 v0.4.0 期望流程
    - Architectural Accommodation 重写为 Requirements 风格
    - 加 Content Hygiene Notice 节引用 conventions.md 通用调色板
  - `plugins/forge/skills/clarify/SKILL.md` (180→194 行)：
    - 新 IRON RULE：Q&A 限于需求级 (WHAT/WHETHER)；实现级偏好落 design-inputs.md
    - Step 6 加分类表 (requirement-level vs implementation-level) + 启发式判据
- 元层面收益：下次任何 /forge:clarify 会话，skill 级规则会阻止同类 scope creep
- 版本：plugin 0.3.0 → 0.3.1 (clarify skill patch)
- 下一步：/forge:design onboard-kind-profiles

## 2026-04-20 — clarify.md 合规审计修正 (Commit A of Option Y)
- 审计方法：按新 IRON RULE "Q&A 限于需求级" 的启发式判据对 T3 clarify.md 全文逐项检查
- 发现（4 处）：
  - OQ-04（profile cross-reference 语法）— 🔴 纯 HOW，应归 design 自行裁决，不打扰用户
  - OQ-05（monorepo 子包 detection 并行度）— 🔴 纯 HOW，同上
  - SC-4（"`--kind=<name>` override 生效"）— 🟡 指定具体 flag 名，违反"不指定字段名"判据
  - SC-5（"`--thorough` flag 生效"）— 🟡 同上
- 修正：
  - OQ-04/OQ-05 从 Open Questions 移除；Open Questions 头部注明"纯实现选择不列入 OQ"
  - SC-4 改为"Kind 显式覆盖能力"（不提 flag 名）
  - SC-5 改为"Opt-in 质量模式"（不提 flag 名）
  - 顺手清理 Data Flow 图、Design Goals 表、Gap-06 中 3 处残留 `--kind` / `--thorough` 引用
  - 保留 `--regenerate` / `--section`（这些是既有 v0.3.0 flag，描述当前状态，非对新设计的预指定）
- 结果：clarify.md 对 clarify skill 当前全部 6 条 IRON RULES 合规
- 下一步：Commit B — 把"skill 规则演进后 artifact 审计"机制沉淀进 conventions.md

## 2026-04-20 — 沉淀 Skill Rule Evolution 机制 (Commit B of Option Y)
- 触发：clarify skill 加新 IRON RULE（commit 52f2e75）后，T3 clarify.md 立即需要审计（Commit A / 2bd25b3）——证明 skill 变更后的 artifact 合规问题是系统性的，不是个案
- 变更：
  - `conventions.md` 新增 "Skill Rule Evolution & Artifact Compliance" 节：
    - R1：Skill IRON RULES 变更 = breaking change，必须 bump 版本
    - R2：变更 commit 必须附带同期的 artifact 审计，三种动作（rewrite / regenerate / preserve-with-exception）
    - R3：审计结果必须追加 JOURNAL
    - 演进路径：现在纯人工 → 中期 skill `--audit` flag → 远期批量 + CI
    - 元规则：本节本身变更也触发对自己的审计
  - `conventions.md` Decision Log 新增 #8
  - `constraints.md` 新增 TD-007（skill `--audit <slug>` 支持）
- 意义：把"人工审计习惯"转化为显式的项目级责任边界；为未来 `--audit` 工具化提供依据
- 下一步：继续 T3 — `/forge:design onboard-kind-profiles`

## 2026-04-20 — /forge:design onboard-kind-profiles
- 产出：.forge/features/onboard-kind-profiles/design.md (348 行, 12 sections)
- 方案：Option C 两级 Process（kind detection + plan execution loop），风险：High（SKILL.md 整体重写 + 17 profile 首次编写）
- Key Decisions：14 条（K-1..K-14），涵盖 Process 风格、Kind 文件格式、检测算法、Profile 组织、IRON RULES overlay 语义、kind drift 处理、OQ-01/02/03 裁决、Monorepo Future-Proofing 落地方式
- DI 声明：DI-1..DI-5 全部 Accept（DI-5 含 minor refinement：5 节正文 + 压缩 IRON RULES 上限 5 行）
- 遗留决策：0 个 deferred
- 规模预估：新建 3 个 kind 定义 + 17 个 profile 文件（约 6 core + 3 structural + 2 model + 2 entry-points + 3 integration + 1 monorepo）+ 重写 SKILL.md + 更新 incremental-mode.md + 删除 output-template.md
- 3 个 kind 的 execution plan 已明确（claude-code-plugin 10 profile / web-backend 12 profile / monorepo 8 profile）
- 下一步：/forge:tasking onboard-kind-profiles
