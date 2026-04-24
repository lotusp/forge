# Plan: onboard-kind-profiles

> 基于：`.forge/features/onboard-kind-profiles/design.md`
> 生成时间：2026-04-22
> 生成方式：/forge:tasking

---

## 概览

将 `/forge:onboard` 从单一模板改造为 kind-driven + profile-composed 架构：

- **Kind detection**（Step 1）：扫描项目产出执行计划（kind、profile 列表、跳过项、置信度）
- **Read-do-discard**（Step 2）：按计划逐个加载 profile → 提取信息 → 写入 section → 清理上下文

本计划涵盖 3 个 MVP kinds（`web-backend`、`plugin`、`monorepo`）、
17 个 profile 文件、SKILL.md 改写、incremental-mode.md 更新、自举验证。

---

## Task List

### T006 — 建立 profiles/ 目录骨架 + README `infra`

**描述：** 在 `plugins/forge/skills/onboard/` 下创建 `profiles/` 及其 6 个子目录，
并编写 `profiles/README.md` 说明目录用途、profile 文件 frontmatter schema、
kind file 结构。

**依赖：** 无

**范围：**
- `plugins/forge/skills/onboard/profiles/core/`
- `plugins/forge/skills/onboard/profiles/structural/`
- `plugins/forge/skills/onboard/profiles/model/`
- `plugins/forge/skills/onboard/profiles/entry-points/`
- `plugins/forge/skills/onboard/profiles/integration/`
- `plugins/forge/skills/onboard/profiles/monorepo/`
- `plugins/forge/skills/onboard/profiles/kinds/`
- `plugins/forge/skills/onboard/profiles/README.md`

**验收标准：**
- [ ] 7 个目录存在（6 个 profile 分类 + 1 个 kinds/）
- [ ] `profiles/README.md` 包含：profile frontmatter schema、kind file 结构、命名规范
- [ ] README 中的 frontmatter schema 与后续 T007–T011 使用的结构一致

**规模预估：** small

---

### T007 — 编写 6 个 core 剖面文件 `docs`

**描述：** 编写 core 分类下的 6 个 profile 文件，每个文件描述一个核心剖面的
扫描模式、提取规则、section 产出格式。这些是任何 kind 都会加载的基础剖面。

**依赖：** T006

**范围：**
- `profiles/core/tech-stack.md`
- `profiles/core/module-map.md`
- `profiles/core/entry-points.md`
- `profiles/core/local-dev.md`
- `profiles/core/data-flows.md`
- `profiles/core/notes.md`

**验收标准：**
- [ ] 6 个文件均包含合法 frontmatter（`name`、`section`、`applies-to`、`confidence-signals`、`token-budget`）
- [ ] 每个文件正文包含：扫描模式（grep/glob）、提取规则、section 产出模板、confidence tag 判定
- [ ] 示例完全使用 `com.example.shop.*` / e-commerce 调色板（遵守 C8）
- [ ] 文件大小控制在 token-budget 声明范围内（core 建议 ≤ 1500 tokens/file）

**规模预估：** medium

---

### T008 — 编写 3 个 structural 剖面文件 `docs`

**描述：** 编写 structural 分类下的 3 个 profile 文件，描述构建、配置、部署相关
信息的提取方式。

**依赖：** T006

**范围：**
- `profiles/structural/build-system.md`
- `profiles/structural/config-management.md`
- `profiles/structural/deployment.md`

**验收标准：**
- [ ] 3 个文件均包含合法 frontmatter（schema 与 T007 一致）
- [ ] 每个文件明确"不适用"的场景（如纯 library 项目无 deployment）
- [ ] 示例遵守 C8（无外部项目标识符）

**规模预估：** small

---

### T009 — 编写 4 个 model / entry-points 剖面文件 `docs`

**描述：** 编写 model 和 entry-points 分类下共 4 个 profile 文件。

**依赖：** T006

**范围：**
- `profiles/model/domain-model.md`
- `profiles/model/db-schema.md`
- `profiles/entry-points/http-api.md`
- `profiles/entry-points/event-consumers.md`

**验收标准：**
- [ ] 4 个文件均包含合法 frontmatter
- [ ] `db-schema.md` 显式说明"跳过生成 ERD，仅提取表/关系名"（遵守 onboard vs calibrate 职责边界）
- [ ] `http-api.md` 支持多框架扫描（Spring `@Controller`、Express `app.*` / Router、Gin、FastAPI 等）
- [ ] 示例遵守 C8

**规模预估：** medium

---

### T010 — 编写 4 个 integration / monorepo 剖面文件 `docs`

**描述：** 编写 integration 和 monorepo 分类下共 4 个 profile 文件。

**依赖：** T006

**范围：**
- `profiles/integration/third-party-apis.md`
- `profiles/integration/auth.md`
- `profiles/integration/messaging.md`
- `profiles/monorepo/workspace-layout.md`

**验收标准：**
- [ ] 4 个文件均包含合法 frontmatter
- [ ] `workspace-layout.md` 为 K-14 Monorepo Future-Proofing 预留接口：说明未来递归每个子包的调用约定
- [ ] `third-party-apis.md` 不泄漏调用的第三方服务具体域名，只保留类别（遵守 C8）
- [ ] 示例遵守 C8

**规模预估：** medium

---

### T011 — 编写 3 个 kind 定义文件 `docs`

**描述：** 编写 3 个 MVP kinds 的定义文件，每个文件声明该 kind 需要加载的 profile
列表、kind 特有的扫描信号（kind detection 依据）、kind-specific section 顺序。

**依赖：** T007、T008、T009、T010（需要知道所有可用 profile）

**范围：**
- `profiles/kinds/web-backend.md`
- `profiles/kinds/plugin.md`
- `profiles/kinds/monorepo.md`

**验收标准：**
- [ ] 3 个 kind 文件均包含 frontmatter：`kind-id`、`display-name`、`detection-signals`、`profiles`（按顺序）、`output-sections`
- [ ] 每个 kind 的 `profiles` 列表所引用的路径都存在（T007–T010 产物）
- [ ] `detection-signals` 结构化（正向信号 + 负向信号 + 每项权重/置信度贡献）
- [ ] `plugin.md` 的 detection-signals 能唯一识别 forge 自身（自举要求）

**规模预估：** medium

---

### T012 — SKILL.md 全量改写（Option C 两阶段流程）`logic` ⚠ 高风险

**描述：** 按 design.md Option C 重写 `plugins/forge/skills/onboard/SKILL.md`，
实现 Step 1 kind detection → 执行计划 → Step 2 read-do-discard 循环的两阶段流程。

**依赖：** T006、T011

**范围：**
- `plugins/forge/skills/onboard/SKILL.md`（全量改写）

**风险缓解（采纳自 2026-04-22 讨论）：**
1. **先写骨架再填内容：** 第一轮只写 IRON RULES + Process 标题 + 每步意图；第二轮再填详细指令。
2. **两阶段硬隔离：** Step 1 必须显式产出"执行计划"文本块（kind、profile 列表、跳过项、置信度）；IRON RULE 锁死 Step 2 不得重新读 kind file。
3. **低置信度/unknown kind 必须中断：** K-11 (0.6 阈值) 和 K-13 (unknown) 必须列入 IRON RULES，不能只在 Process 中顺带提及。
4. **read-do-discard 用伪代码循环：** 不用散文描述，写成 `for profile in plan.profiles: read → extract → write section → clear context`。
5. **人工走读验收：** 完成后在进入 T013 前模拟 3 种 kind 各跑一次，确认无逻辑歧义。

**验收标准：**
- [ ] IRON RULES 中包含：两阶段硬隔离、kind file 单次读取、低置信度中断、preserve 块无条件保留
- [ ] Step 1 明确输出"执行计划" block（结构化文本，4 个必填字段）
- [ ] Step 2 包含伪代码形式的 read-do-discard 循环
- [ ] K-11 (0.6 threshold) 和 K-13 (unknown kind) 都在 IRON RULES 中出现
- [ ] frontmatter `allowed-tools` 包含 `Write`（不含 `agent: Explore`）
- [ ] 文档开头声明 version 与 plugin.json 一致
- [ ] **人工走读：** 模拟 web-backend / plugin / monorepo 三种 kind 各跑一遍 Process，无歧义分支
- [ ] 示例遵守 C8

**规模预估：** large

---

### T013 — 更新 incremental-mode.md（kind drift + 动态 section）`logic` ⚠ 高风险

**描述：** 重写 `plugins/forge/skills/onboard/reference/incremental-mode.md`，
加入 kind drift 处理逻辑和动态 section 名支持。

**依赖：** T012

**范围：**
- `plugins/forge/skills/onboard/reference/incremental-mode.md`

**风险缓解（采纳自 2026-04-22 讨论）：**
1. **Kind drift 独立小节 + 决策表：** 专门一节列全 4 种状态（未变 / 置信度下降 / kind 改变 / unknown→known），每种注明 section 保留/删除/新增策略。
2. **Preserve 块作为 IRON RULE：** "任何 `<!-- forge:preserve -->` 块必须无条件保留，即使所在 section 因 kind drift 被标记删除。"
3. **Hash 算法显式：** `verified=<hash>` 定义为 `SHA-256(section body without preserve blocks)`，禁止 LLM 自行发明。
4. **预留 dry-run 占位：** 留一行 "Future: --dry-run outputs diff without writing"，MVP 不实现但结构上给未来留口。

**验收标准：**
- [ ] 包含独立 "Kind Drift Handling" 小节，附 4 状态决策表
- [ ] "Preserve Block Precedence" 作为 IRON RULE 级条款出现
- [ ] 显式定义 hash 算法（SHA-256 + 排除 preserve 块）
- [ ] 包含 Future 占位行（dry-run）
- [ ] 所有章节与 T012 的 SKILL.md 流程一致（无矛盾描述）

**规模预估：** medium

---

### T014 — 清理 + 过渡版本（0.3.2-dev）`infra`

**描述：** 删除被 profile 架构取代的 output-template.md，bump 插件版本到
**过渡版本 0.3.2-dev**（非 0.4.0，待 T015 验证通过后再正式升 0.4.0）。

**依赖：** T012

**范围：**
- 删除 `plugins/forge/skills/onboard/reference/output-template.md`
- 修改 `plugins/forge/.claude-plugin/plugin.json`（版本 0.3.1 → 0.3.2-dev）
- 检查并移除任何引用已删除文件的内部链接

**验收标准：**
- [ ] `output-template.md` 已删除
- [ ] `plugin.json` 的 `version` 字段为 `0.3.2-dev`
- [ ] 代码库中 grep `output-template.md` 无残留引用（SKILL.md、其他 reference 文件、docs/ 均无引用）

**规模预估：** small

---

### T015 — 自举验证 + 增量模式验证 `test`

**描述：** 对 forge 仓库自身运行新 `/forge:onboard`，校验 clarify.md 中列出的
8 项 Success Criteria，并验证增量模式 + preserve 块行为。

**依赖：** T013、T014

**范围：**
- 实际运行 `/forge:onboard`（first-run 模式）
- 人工修改 onboard.md 若干处 preserve 块
- 再次运行 `/forge:onboard`（incremental 模式）
- 产出验证报告 `.forge/features/onboard-kind-profiles/verification.md`

**验收标准：**
- [ ] First-run：kind 正确识别为 `plugin`，置信度 ≥ 0.6
- [ ] First-run：生成的 onboard.md 包含所有 kind 声明的 section，顺序正确
- [ ] First-run：所有 section marker 格式合法（含 verified hash）
- [ ] First-run：confidence tag 覆盖率符合 scan-patterns.md 要求
- [ ] clarify.md Success Criteria 8 项全部通过（在 verification.md 中逐条记录结果）
- [ ] **Incremental 验证：** 手改 2–3 处 preserve 块后再跑，preserve 内容未被覆盖
- [ ] **Incremental 验证：** 修改 section body（非 preserve）后再跑，dirty section 被正确识别
- [ ] 示例遵守 C8（verification.md 本身也要干净）
- [ ] 如发现问题，记录为 OQ 或新 task 提案，不在本 task 内修复

**规模预估：** medium

---

### T016 — 正式版本跃迁 0.4.0 `infra`

**描述：** T015 验证通过后，将插件版本从 `0.3.2-dev` 正式升到 `0.4.0`，
更新 README.md 和 CLAUDE.md 中相关描述。

**依赖：** T015

**范围：**
- `plugins/forge/.claude-plugin/plugin.json`（0.3.2-dev → 0.4.0）
- `README.md`（版本 badge + onboard 描述更新）
- `CLAUDE.md`（如需同步 onboard 架构描述）

**验收标准：**
- [ ] `plugin.json` 的 `version` 字段为 `0.4.0`
- [ ] README.md 版本 badge 更新为 `0.4.0`
- [ ] README.md 中 onboard skill 描述反映 kind-driven + profile 架构（保持简洁，详细规范放 reference/）
- [ ] CLAUDE.md 中涉及 onboard 的描述与新架构一致
- [ ] 示例遵守 C8

**规模预估：** small

---

## Dependency Graph

```
T006 ──┬─→ T007 ──┐
       ├─→ T008 ──┤
       ├─→ T009 ──┼─→ T011 ─→ T012 ─┬─→ T013 ─┐
       └─→ T010 ──┘                 └─→ T014 ─┴─→ T015 ─→ T016
```

## Execution Order

1. **T006** — 目录骨架
2. **T007 + T008 + T009 + T010** — 4 个 profile 分类并行编写
3. **T011** — 3 个 kind 定义（依赖所有 profile 齐备）
4. **T012** — SKILL.md 全量改写 ⚠ 高风险
5. **T013 + T014** — reference 文档更新 + 清理并行 ⚠ T013 高风险
6. **T015** — 自举 + 增量验证
7. **T016** — 正式版本跃迁 0.4.0

---

## Risk Register

| Task | Risk | Mitigation |
|------|------|------------|
| T012 | 两阶段 Process 描述歧义导致每次运行偏轨 | IRON RULES 锁死两阶段硬隔离；伪代码循环；人工走读 3 种 kind |
| T012 | 低置信度/unknown kind 时 LLM 自行猜测继续执行 | K-11、K-13 列入 IRON RULES，不放在 Process 分支中 |
| T013 | 增量更新静默丢失用户 preserve 块 | preserve 块作为 IRON RULE；hash 算法显式定义 |
| T013 | Kind drift 后残留过期 section | 专门 "Kind Drift Handling" 章节 + 4 状态决策表 |
| T015 | 单次 first-run 无法暴露增量模式 bug | 验收强制包含"手改 preserve → 再跑"场景 |
| 全局 | 0.4.0 发布后发现问题回滚困难 | T014 先过渡到 0.3.2-dev，T015 通过后 T016 才跃迁正式版 |

---

## 下一步

运行 `/forge:code T006` 开始实施。
