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

## 2026-04-22 — /forge:tasking onboard-kind-profiles
- 产出：.forge/features/onboard-kind-profiles/plan.md
- 任务：11 个（T006–T016），高风险：2 个（T012 SKILL.md 改写、T013 incremental-mode.md 更新）
- 关键调整：采纳用户反馈，拆分版本升级为两步（T014 过渡版 0.3.2-dev + T016 正式版 0.4.0），避免 T015 验证失败时回滚困难
- 风险缓解写入验收标准：两阶段硬隔离、伪代码循环、preserve 块 IRON RULE、hash 算法显式定义、增量模式强制二次运行验证
- 下一步：/forge:code T006

## 2026-04-22 — Batch A: T006–T011 onboard-kind-profiles
- T006：建立 profiles/ 目录（7 个子目录）+ profiles/README.md（profile/kind schema、执行合约说明）
- T007：6 个 core profile 文件（tech-stack、module-map、entry-points、local-dev、data-flows、notes）
- T008：3 个 structural profile 文件（build-system、config-management、deployment）
- T009：4 个 model/entry-points 文件（domain-model、db-schema、http-api、event-consumers）
- T010：4 个 integration/monorepo 文件（third-party-apis、auth、messaging、workspace-layout）
- T011：3 个 kind 定义文件（web-backend、claude-code-plugin、monorepo）
- 所有示例使用 e-commerce 调色板（Order/Customer/Product/Payment + com.example.shop.*），遵守 C8
- claude-code-plugin kind 明确仅加载 6 个 core profiles（K-12 Decision）
- monorepo kind 的 workspace-layout 预留 K-14 recursive-targets 扩展点
- 下一步：检查点 1 — 人工过一遍 profile/kind 一致性，随后进入 Batch B (T012 SKILL.md 改写)

## 2026-04-22 — T012 onboard-kind-profiles SKILL.md 全量改写
- 产出：plugins/forge/skills/onboard/SKILL.md（481 → 505 行）
- 8 IRON RULES：两阶段硬隔离、kind 单次读、低置信度 halt、unknown halt、preserve 神圣、模板遵循、证据或省略、只读源码
- Process 两阶段：Step 1 kind detection → Execution Plan (frozen) → Step 2 read-do-discard 伪代码循环
- 5 Run Modes：first-run / incremental / regenerate / single-section / force-kind
- 4 halt 场景交互消息模板齐备（低置信度 / unknown / 歧义 / kind drift）
- 人工走读：3 种 kind 各模拟一次，修复 runtime snapshot 路径依赖 + claude-code-plugin 嵌套布局检测
- 下一步：T013 incremental-mode.md 更新

## 2026-04-22 — T013 incremental-mode.md 更新
- 产出：plugins/forge/skills/onboard/reference/incremental-mode.md（211 → 428 行）
- 4 reference-local IRON RULES：I-R1 preserve 神圣 / I-R2 hash 算法精确定义 / I-R3 kind drift 优先 / I-R4 section 顺序跟随当前 kind
- Kind Drift Handling 独立小节 + 4 状态决策表（Stable / Confidence drop / Kind change / Loss of signal）+ 每状态 section 处理规则
- Hash 算法显式定义：first_16_hex(SHA-256(canonicalized_body_without_preserve_blocks))，5 步 canonicalization 规则 + pseudo-code
- Mode B/C/D 完整算法重写，删除硬编码"10 canonical sections"，改为按 current_kind.output_sections 动态处理
- 预留 Future --dry-run 占位（非 MVP）
- 顺带更新：SKILL.md Step 3.3 补充 generated= 属性说明，与 incremental-mode.md 对齐
- 下一步：T014 清理 + 过渡版本 0.3.2-dev

## 2026-04-22 — T014 清理 + 过渡版本 0.3.2-dev
- 删除 plugins/forge/skills/onboard/reference/output-template.md（521 行，被 profile 架构完全取代）
- plugin.json 版本 0.3.1 → 0.3.2-dev（过渡版本，待 T015 自举验证通过后由 T016 正式升 0.4.0）
- onboard 内部无悬挂引用：SKILL.md grep 0 match；profiles/README.md 仅保留历史"曾被取代"说明（非链接）
- README.md 版本 badge 和 onboard 描述更新延后到 T016（正式版本跃迁）
- 下一步：检查点 3 — 用户决定是否立即跑 T015 自举验证

## 2026-04-22 — /forge:onboard (Mode A — first run, T015 自举验证)
- 产出：.forge/context/onboard.md (7 sections written, 0 reused)
- Kind 检测：claude-code-plugin（置信度 0.90），加载 6 个 core profiles
- 摘要：9 个 skill, 3 个 agent, 4 个辅助脚本, 0 个外部集成
- 置信度警示：1 个 [conflict]（plugin.json 版本 0.3.2-dev vs README badge 0.3.1）
- 自举发现：
  1. Kind 检测逻辑运行正常 — claude-code-plugin 识别置信度 0.90，无歧义
  2. 6 个 core profile 覆盖了所有有意义的截面；excluded profiles (structural/model/integration) 确实无内容
  3. Section 4 (Core Domain Objects) 对 plugin 项目不适用 — 由 kind 的 output-sections 设计正确排除
  4. notes.md profile 对自举项目效果良好，CLAUDE.md + JOURNAL 提供了充足信号
- 下一步：/forge:calibrate

## 2026-04-22 — /forge:onboard (Mode B — incremental)
- 产出：.forge/context/onboard.md (2 sections rewritten, 5 reused)
- Kind 检测：claude-code-plugin（置信度 0.90）；HEAD d3db26a 与上次 verified hash 一致，无新提交
- 变更摘要：
  - Section 3 (module-map)：修正 `forge` skill 描述（原 [TEST-MARKER-DIRTY-2] → 正确描述），更新 `onboard` 描述反映 kind-aware profile 架构
  - Section 7 (notes)：更新 onboard-kind-profiles 状态（T015 验证完成，T016 待完成）
  - Section 2 (tech-stack) preserve 块原文保留（[TEST-MARKER-PRESERVE-1] 完整携带）
- 置信度警示：1 个 [conflict]（plugin.json 版本 0.3.2-dev vs README badge 0.3.1，待 T016）
- 下一步：/forge:calibrate

## 2026-04-22 — T015 自举验证（条件通过）
- Phase 1 first-run：kind 识别 `claude-code-plugin` @ 0.90 confidence；7 sections 齐备，6 core profiles 加载；219 行产物
- Phase 2 incremental（3 处手改触发）：
  - Tech Stack preserve 块：✅ 原样保留
  - Module Map 非 preserve 修改：✅ 重写覆盖
  - Notes bullet 删除：✅ 用户删除被尊重，不恢复
- Mode B：HEAD 未变 → 5 reused + 2 written（module-map / notes）
- 发现 3 项 Minor 偏差：
  - M1 Section marker 缺 `profile=` 属性（可回退从 kind 文件推导）
  - M2 Header 用 HTML marker 而非 markdown 引用块
  - M3 Confidence tag 被扩展为 `[code]/[conflict]/[build]/[readme]`（有信息价值）
- 我的规范缺陷：I-R2 body-hash 设计不能支撑"跳过昂贵扫描"核心价值；应拆分为 verified-commit + body-signature 双属性
- 判定：条件通过。T016 可进，但需先完成 T012a + T013a follow-up 任务修正规范
- 产出 T012a、T013a 两个 follow-up task（写入 verification.md）
- 下一步：开 T012a/T013a 修复规范 → 重跑自举一次 → 进入 T016

## 2026-04-22 — T012a onboard SKILL.md 规范强化
- 修复 T015 发现的 3 项 Minor + 1 项规范缺陷
- 新增 R9（marker 格式硬约束）：header markdown blockquote + section marker 5 属性（section / profile / verified-commit / body-signature / generated）顺序与引号固定
- 新增 R10（tag 三轴枚举）：confidence（必）[high|medium|low|inferred] + source（可选）[code|build|config|readme|cli] + conflict（可选）[conflict]；严禁发明新 tag
- Step 3.3 marker 示例用真实 hex 字面值（`verified-commit="a3f2c1d4"` + `body-signature="9f8e7d6c5b4a3210"`），避免 LLM 用 git hash 糊弄过去
- Step 2 confidence tag 引用指向 R10
- profiles/README.md 同步 Tag System 权威定义章节，含范例 + 严禁条款
- SKILL.md 505 → 595 行；profiles/README.md 149 → 206 行
- 下一步：T013a 定义 verified-commit / body-signature 的算法与 Mode B 判定逻辑

## 2026-04-22 — T013a incremental-mode.md 修正 I-R2 为双属性
- 修复 T015 发现的"I-R2 body-hash 不能支撑跳过昂贵扫描"核心设计缺陷
- I-R2 拆分为：
  - I-R2a：`verified-commit=<git-short>`（Stage 2 用 git rev-parse --short HEAD 记录扫描时的 HEAD；primary fast-skip 信号）
  - I-R2b：`body-signature=<sha256-16hex>`（SHA-256 of canonicalized body；secondary tamper-detect 信号）
- Mode B 流程重写为两阶段检查：Stage A 先比对 verified-commit（HEAD 未变直接 CLEAN-FAST，不跑 profile）→ Stage B 再算 body-signature 识别 out-of-band 手改
- 4 种状态语义：CLEAN-FAST / CLEAN-MAYBE-STALE / DIRTY-TAMPERED / NEW
- 新增 "Why two stages?" 决策表 + 边界情况（same HEAD + edited body = 尊重用户编辑）
- 后向兼容：旧 `verified=` 属性 fallback 到 body-signature only + JOURNAL warning
- Hash pseudo-code 更新：verified_commit() + body_signature() 双函数 + worked example
- Mode C/D + Announcement + Recovery 全部同步新属性名
- `--refresh-stale` 标注 future（不在 MVP，不污染 SKILL.md Run Modes）
- incremental-mode.md 428 → 567 行；与 T012a SKILL.md 交叉一致
- 下一步：重跑自举验证 T012a + T013a 修复是否生效

---

## 2026-04-23 — /forge:onboard
- Kind:        claude-code-plugin (confidence 0.95)
- Sections:    6 written / 0 preserved / 0 skipped
- Profiles:    tech-stack, module-map, entry-points, local-dev, data-flows, notes
- Mode:        first-run
- Commit:      edb4f98
- Next:        /forge:calibrate

## 2026-04-23 — T012b SKILL.md R9 强化（marker 双属性歧义修复）
- 第二轮自举发现：Run-2 sub-agent 把 `verified-commit="..." body-signature="..."` 理解成"二选一"，只输出 `verified="<16hex>"` 单属性
- T012b 修复：R9 新增显式段落 "two separate, independently required attributes. They are NOT alternatives."
- 新增 4 个反例（legacy `verified=` / 缺 body-signature / 缺 verified-commit / 合并成单属性）
- Step 3.3 开头添加 R9 cross-reference 强化语
- cache 同步到 0.3.2-dev，准备第三轮自举
- 下一步：清理产物 → 再跑 /forge:onboard → 验证 5 属性合规

## 2026-04-23 — /forge:onboard
- Kind:        claude-code-plugin (confidence 1.00)
- Sections:    6 written / 0 preserved / 0 skipped
- Profiles:    tech-stack, module-map, entry-points, local-dev, data-flows, notes
- Mode:        first-run
- Commit:      460e04d
- Next:        /forge:calibrate

## 2026-04-23 — T016 正式升 0.4.0
- plugin.json 版本 0.3.2-dev → 0.4.0
- README.md：badge 0.3.1 → 0.4.0；onboard 描述更新为"Kind 驱动 + profiles 组合加载 + 增量 + preserve 块"
- CLAUDE.md：
  - 仓库结构树加入 onboard/profiles/ + reference/ 层级（kinds / core / structural / model / entry-points / integration / monorepo 分类可见）
  - .forge/context/onboard.md 描述更新为 kind-driven
- 打标签 v0.4.0
- onboard-kind-profiles 功能完整闭环：T006–T016 + T012a + T012b + T013a（11 + 3 = 14 个 commit）
- 下一步：self-bootstrap 再跑一次验证 T016 后 onboard.md 的 verified-commit 会随 HEAD 自动演进；或直接进 T5 质量改进 / 其他 feature

## 2026-04-23 — /forge:clarify skill-quality-hardening
- 触发来源：onboard-kind-profiles v0.4.0 复盘暴露的流水线质量 + kind-awareness 两类系统性缺陷
- 产出：.forge/features/skill-quality-hardening/clarify.md + design-inputs.md
- 流水线重构（9 → 7 skills）：calibrate 并入 onboard，tasking 并入 design
- kind-aware 全面推广：所有 onboard 产物（5 文件）按 kind 适配
- 新机制：onboard 批量冲突裁决 / clarify self-review / design Scenario Walkthrough / design 线协议字面化 / design 内嵌 spec-review / code 首次开发规范对话 / design 自动 T{last} 文档更新任务
- 5 个需求级 Q 全部解决（Q1:C / Q2:X only / Q3:C / Q4:A / Q5:A+Q）
- 5 个 DI 记录（tasks 独立存放 / code Q&A 触发条件 / 规范写回多路径 / 文档更新 task / Excluded sections 头部元数据补偿）
- Y 类 spec-review（SKILL.md 误解模式扫查）不纳入当前 feature，留给 skill-spec-review-tool
- 未解问题：0 个
- Gaps 识别 17 个，与 10 条 Success Criteria 一一对照
- 下一步：/forge:design skill-quality-hardening

## 2026-04-23 — Feature rename
- skill-quality-hardening → lean-kind-aware-pipeline（范围已超出原 5 项 quality 优化，覆盖整体流水线简化 + kind 自适应）
- 目录已 mv，clarify.md / design-inputs.md slug 引用已更新
- 下一步：/forge:design lean-kind-aware-pipeline

## 2026-04-23 — /forge:design lean-kind-aware-pipeline
- 方案：Option A（扩展 profiles/context/ 目录，与 v0.4.0 profile 架构一脉相承）
- 12 个 Key Decisions（K-1..K-12）全部明确
- 3 个 Scenario Walkthrough 通过（web-backend fresh / forge self-bootstrap / monorepo）
- 全量 Wire Protocol 字面化（onboard header / context marker / batch conflict UX / plan T{last} / code Q&A / embedded spec-review 输出）
- Embedded spec-review 自检：10 条 Success Criteria 中 9 条 design 层覆盖，#10 自举不回归转为 tasking 层 T{last-1} 处理
- 17 个 Gap 全覆盖
- 风险等级：High（skill 名变更 + pipeline 重塑 + kind-aware 铺开）
- 遗留决策：0 个 deferred
- 产出：.forge/features/lean-kind-aware-pipeline/design.md
- 下一步：/forge:tasking lean-kind-aware-pipeline

## 2026-04-23 — /forge:tasking lean-kind-aware-pipeline
- 产出：.forge/features/lean-kind-aware-pipeline/plan.md
- 任务：15 个（T017–T031），高风险：4 个（T023 onboard Stage 3 / T024 clarify self-review / T025 design 四阶段 / T028 orchestrator）
- 执行顺序分 7 波（T017+T018 → T019+T020 → T021+T022 → T023 + {T024..T029} 并行 → T030 验证 → T031 docs finalize）
- 所有高风险任务均附缓解措施（字面示例照搬 design.md、先骨架后填内容、人工走读）
- 下一步：/forge:code T017

## 2026-04-23 — Wave A: T017 + T018 complete
- T017: 删除 plugins/forge/skills/calibrate/ 和 plugins/forge/skills/tasking/ 两个目录；7 skill 保留
- T018: 建立 plugins/forge/skills/onboard/profiles/context/{kinds,dimensions}/ 目录 + README（206 行）
- README 含：目录结构图、kind file schema、dimension file schema、执行合约、section marker 合约、Content Hygiene、扩展指南
- 下一步：Wave B — T019 3 kind 索引 + T020/T021/T022 16 个 dimension 文件

## 2026-04-23 — Wave B: T019 + T020 + T021 + T022 complete
- T019: 3 个 context kind 索引（web-backend / claude-code-plugin / monorepo），声明每个 kind 加载的 dimension 子集 + excluded-dimensions
- T020: 7 个通用 dimension（naming / error-handling / commit-format / architecture-layers / hard-constraints / anti-patterns / testing-strategy），含 kind 分支输出模板
- T021: 6 个 web-backend 专用 dimension（logging / validation / api-design / database-access / messaging / authentication）
- T022: 3 个 claude-code-plugin 专用 dimension（skill-format / artifact-writing / markdown-conventions）
- 共计 19 个新文件，2180 行；所有示例遵守 C8（e-commerce 调色板 + C8 redaction）
- 每个文件符合 profiles/context/README.md 的 schema：frontmatter + 4 小节（Scan/Extraction/Output/Confidence）
- 下一步：Wave C — T023 onboard SKILL.md Stage 3 改写（高风险）

## 2026-04-23 — Wave C: T023 onboard Stage 3 rewrite 完成 ⚠
- SKILL.md 从 637 行扩到 1027 行 (+390 行)
- 新增 4 条 IRON RULES：R11 (Stage 3 非交互 + 批量冲突) / R12 (不创建非适用 context 文件) / R13 (onboard.md header Excluded-dimensions 元数据) / R14 (context 文件 smart merge 禁止整覆盖)
- R1 扩展为"Three-stage hard isolation" 涵盖 Stage 1 ⊥ Stage 2 ⊥ Stage 3
- R2 扩展为"Single kind-file read per stage"（两个 kind 文件各读一次：profiles/kinds/<id>.md + profiles/context/kinds/<id>.md）
- R5 扩展 preserve 块适用范围到所有 forge 产物（不仅 onboard.md）
- R9 marker 属性从 5 升到 6（新增 source-file 识别哪个产物文件）
- frontmatter description 全面改写为 three-stage 描述
- Runtime snapshot 新增 Existing context files + recent commit subjects（为 Stage 3 smart-merge + commit-format 扫描做准备）
- Process Overview ASCII 图从 2 stage 升到 3 stage，Stage 3 含 3.1/3.2/3.3/3.4 四子步
- Execution Plan（Step 1.6）增补 context-kinds-file / context-dimensions / context-output-files / excluded-dimensions 字段
- Step 3.1 header 新增 Excluded-dimensions 必备元数据行
- Step 3.3 marker 示例升级到 6 属性（含 source-file），给出 onboard.md 和 context file 两种字面示例 + 4 个❌反例
- 新增 Step 4 (Stage 3.1 非交互扫描伪代码) / Step 5 (Stage 3.2 批量冲突交互模板) / Step 6 (Stage 3.3+3.4 smart-merge 伪代码)
- 新增 Interaction Messages：Batch conflict resolution + Stage 3 no conflicts
- Run Modes A-E 全部更新反映 Stage 3：Mode A 从 3 步升到 4 步；Mode B 拆分 Stage 2 + Stage 3 incremental；Mode C 拓展 context files preserve；Mode D 增加冲突 halt 约束
- Constraints 章节新增 5 条 Stage 3 相关硬约束
- Reference Documents 表格新增 3 行（profiles/context/ 子目录）
- 人工走读 3 场景（forge self-bootstrap / fresh web-backend / monorepo workspace）流程均可跑通
- 下一步：Wave D — T024 clarify self-review + T025 design 4-stage 改写

## 2026-04-23 — Wave D: T024 clarify self-review + T025 design 4-stage 完成 ⚠
- T024 clarify SKILL.md: 194 → 279 行
  - 新 IRON RULES: R15 Q 必带 [WHAT]/[HOW] label / R16 self-review 必执行
  - Step 6 升级：Q 分类矩阵 + 启发式判据 + [HOW] 自动路由到 design-inputs.md
  - Step 7 只招待 [WHAT] 项；Step 8 新增 synthesize + self-review 5 检查 + 3 轮 revise 上限 + 元数据块嵌入
  - Step 9 写入，Step 10 JOURNAL
- T025 design SKILL.md: 202 → 652 行（3.2 倍膨胀，吸收 tasking + 三个新阶段）
  - 新 IRON RULES: R17 Scenario Walkthrough 3 场景必出 / R18 线协议字面化禁 placeholder / R19 embedded spec-review 硬阻断 + decision 层回溯 / R20 plan.md 必带 T{last} docs 任务
  - 4 stage 架构：Ingest → Design draft (approach + components + Walkthrough + Wire Protocol) → Embedded spec-review → Task decomposition
  - Runtime snapshot 新增 onboard kind 识别 + 最高 Task ID 查询
  - Task 类型枚举扩展：+skill/agent/profile/kind-def（for claude-code-plugin）
  - 输出两个独立文件：design.md 和 plan.md（DI-1）
  - JOURNAL template 更新为新 4 阶段
- 两个 skill 的 IRON RULES 全部保留 R1-R6 原有项并用编号式
- 人工走读两个 skill 的 Process 流程均可跑通（clarify: Step 5 → 6 → 7 → 8 → 9 → 10；design: Stage 1 → 2 → 3 → 4）
- 下一步：Wave E — T026 code / T027 inspect / T028 orchestrator / T029 版本

## 2026-04-23 — Wave E: T026 + T027 + T028 + T029 complete
- T026 code SKILL.md: +Step 0.5 convention gap check + R21/R22；focused Q&A 触发条件明确；答案写回 conventions.md § Development Workflow
- T027 inspect SKILL.md: +R23 feature-slug 确定性范围（通过 plan.md + task summaries 枚举）；移除 file-path 参数支持；argument-hint 更新
- T028 forge orchestrator + state-machine.md 重写 + status.mjs 修正：
  - forge/SKILL.md: IRON RULES 去掉 calibrate；Path variables 更新为 7 个 skill；Action routing 合并 calibrate/tasking 分支；Quick shortcuts 去掉 2 个旧 shortcut；新增 "Removed in v0.5.0" 章节说明
  - reference/state-machine.md 全量重写：9 态 → 7 态（clarify → design → code → inspect → test + onboard + forge 编排器）；Artifact mapping 更新为 Stage 3 归属
  - status.mjs 修正（K-12 判断错误）：phase machine 去掉 tasking；action 合并 calibrate 路由到 onboard；状态排序删除 tasking；dashboard 显示 4 个 context 文件存在性而非仅 conventions
- T029 版本 + README + CLAUDE.md:
  - plugin.json 0.4.0 → 0.5.0-dev（过渡版；T031 正式升 0.5.0）
  - README badge + skill 表格重写（9→7）+ 使用指南去掉旧命令
  - CLAUDE.md 目录树更新（含 profiles/context/ 子目录）+ Skill Flow breaking change 说明
- 7 个 skill 文件（含 state-machine.md + status.mjs）的 calibrate/tasking 引用清零（除合法历史性说明）
- status.mjs 实测 node 运行正常，dashboard 输出正确
- 下一步：Wave F — T030 自举验证

## 2026-04-23 — /forge:onboard
- Kind:        claude-code-plugin (confidence 1.00)
- Sections:    6 written / 0 preserved / 0 skipped
- Profiles:    tech-stack, module-map, entry-points, local-dev, data-flows, notes
- Mode:        first-run
- Commit:      59836a2
- Next:        /forge:calibrate

## 2026-04-23 — /forge:onboard
- Kind:        claude-code-plugin (confidence 1.00)
- Sections:    6 written / 0 preserved / 0 skipped
- Profiles:    tech-stack, module-map, entry-points, local-dev, data-flows, notes
- Mode:        first-run
- Commit:      59836a2
- Next:        /forge:calibrate

## 2026-04-23 — Wave F: T030 自举验证（条件通过）
- 预期路径: Skill tool 触发 /forge:onboard → sub-agent 按新 SKILL.md 执行 Stage 1+2+3
- 实际路径: 三次 Skill tool 调用均失败（sub-agent 停在 Stage 2，产出旧 5 属性 marker，说 "Next step: /forge:calibrate"）
- 根因: Claude Code Skill tool 在同一 session 内对 skill prompt 有缓存层；文件边写边测不生效
- Workaround: 主 agent 手工执行 Stage 3 产出 5 个 context 文件（onboard/conventions/testing/architecture/constraints）符合 v0.5.0 6 属性 marker + excluded-dimensions 头部 + kind 分化内容
- 补强: 在 onboard SKILL.md Step 3.5 + Step 7 新增 "Common LLM trap" 警告 + 显式否定 "Next step: /forge:calibrate"
- SC 核对: 5 PASS / 4 DEFERRED / 1 PARTIAL / 0 FAIL；DEFERRED 项待 fresh session 验证
- 产出: .forge/features/lean-kind-aware-pipeline/verification.md + 5 个 context 文件 + onboard SKILL.md 补强
- 判定: 条件通过，可进 T031
- 下一步: Wave H — T031 docs finalize + v0.5.0 tag

## 2026-04-23 — /forge:onboard
- Kind:              claude-code-plugin (confidence 1.00)
- Mode:              first-run
- Commit:            9dbca95
- onboard.md:        7 sections written / 0 preserved blocks / 0 skipped
- context files:     conventions.md (6 sections), testing.md (1 section), architecture.md (1 section), constraints.md (2 sections)
- conflicts resolved: (none)
- orphans migrated:  (none)
- excluded dims:     6 — logging, validation, api-design, database-access, messaging, authentication
- Next:              /forge:clarify <your first feature>

## 2026-04-23 (evening) — Fresh-session 自举 + Wave G (G1+G4)
- 用户关闭 Claude Code 会话后重启，删除 .forge/context/*.md 后直接执行 /forge:onboard
- 假设 1 得到验证：fresh sub-agent 按新 SKILL.md 完整跑完 Stage 1+2+3，自动产出 5 个 context 文件
- 产物 review：全部合规（R9 6 属性 marker / R10 tag / R13 header / kind-applicable 内容）
- 亮点：sub-agent 在 constraints.md 主动识别 4 处真实代码债务（TD-001~004），全部 true positive
- G1 修复 9 处 stale /forge:calibrate|tasking references：
  - test/SKILL.md:51, profiles/core/module-map.md:46, profiles/core/entry-points.md:87
  - profiles/core/data-flows.md:66, profiles/model/domain-model.md:42
  - profiles/model/db-schema.md:19,74, reference/incremental-mode.md:275
  - forge/SKILL.md:160,234
- G4 更新 verification.md：条件通过 → 通过；6 PASS / 3 DEFERRED / 1 PARTIAL / 0 FAIL
- 下一步：T031 v0.5.0 正式升版 + docs/upgrade-0.5.md + tag

## 2026-04-23 — T031 v0.5.0 formal release
- plugin.json 0.5.0-dev → 0.5.0
- README badge 0.5.0-dev → 0.5.0 + 新增 "v0.5.0 is here" 精简变更告知 + 链接 upgrade-0.5.md
- 新建 docs/upgrade-0.5.md（迁移向导：pipeline 变化 / 步骤 1-3 升级流程 / breaking changes 详情 / 回滚说明）
- CLAUDE.md 的 upgrade-0.5.md 链接修复（之前是 placeholder）
- onboard-kind-profiles feature (v0.4.0) + lean-kind-aware-pipeline feature (v0.5.0) 至此闭环
- 打 tag v0.5.0 并 push
- forge v0.5.0 正式发布
