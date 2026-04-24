# Clarify: lean-kind-aware-pipeline

> 生成时间：2026-04-23
> 生成方式：/forge:clarify
> 上游触发：onboard-kind-profiles v0.4.0 开发过程复盘，暴露流水线质量与 kind-awareness 两类系统性缺陷
> 下一步：/forge:design lean-kind-aware-pipeline

---

## Intent (restated)

将 forge 流水线从 9 个 skill 简化为 7 个，全面引入 kind-awareness，
并补上开发过程中暴露的质量关键路径：

```
v0.4.0:  onboard → calibrate → clarify → design → tasking → code → inspect → test   (9)
v0.5.0:  onboard                → clarify → design                 → code → inspect → test   (7)
```

- `calibrate` 并入 `onboard`
- `tasking` 并入 `design`
- 所有产物（onboard.md + 4 个 context 文件 + design.md + plan.md）全部 kind-aware
- clarify 自我校验 + design 内嵌 spec-review + code 首次开发规范对话

---

## Scope

### 纳入范围

1. **新 onboard**（吸收 calibrate 职责）
   - 产出 `.forge/context/onboard.md` + `conventions.md` + `testing.md` + `architecture.md` + `constraints.md`（5 文件）
   - 所有产物 kind-aware（web-backend / plugin / monorepo 三 kind，与 v0.4.0 一致）
   - 扫描阶段**非交互**；发现约定冲突后**批量一次性交互**裁决（不再逐个询问）
   - 增量模式与 preserve 块机制沿用 v0.4.0
   - 对老项目已有 4 个 context 文件：**智能合并**（保留 preserve 块，吸收旧内容到新 kind-aware 模板对应位置）

2. **新 clarify**（保留 skill，增自校验）
   - Step 6 Q 分类升级为操作级硬约束（每 Q 必须带 `[WHAT]` / `[HOW]` 标签）
   - 产出前新增 **self-review** 步骤：LLM 对首版 clarify 草稿做严重性检查（scope creep / 未解 unknowns / 与 onboard 矛盾），发现问题自行 revise 后再展示给用户确认

3. **新 design**（吸收 tasking 职责）
   - 产出**独立两个文件**：`design.md`（技术设计）+ `plan.md`（任务列表）
   - 新增强制 **Scenario Walkthrough** 章节：LLM 生成 3 个典型场景走完决策流（发现漏洞必须回到 decision 层修正）
   - 新增**线协议字面化**章节：产物格式 / API 合约 / 持久化结构等必须给出可 copy-paste 的字面示例
   - 产出后自动触发 **embedded spec-review**：对照 clarify.md 的 Success Criteria 与 Gaps 逐条核对，**硬阻断**缺口存在时的 design.md 产出；允许回溯到 design decision 层重审
   - 每次 design 产出的 plan.md 末尾必须自动包含一个 T{last} "文档更新"任务

4. **新 code**（增首次对话）
   - 执行 task 前检查 `.forge/context/conventions.md` 是否覆盖本次 task 所需的开发规范（是否写单元测试、是否 TDD、commit 规范、分支策略等）
   - 若 **本次 task 需要但 conventions 未覆盖** → 触发 Q&A 对话，答案写回 conventions.md
   - 若 conventions 已覆盖 → 直接按 task 执行，不询问
   - 任何 skill 运行中新发现的约定/规范都可追加到 conventions.md 或其他合适文档

5. **新 inspect**（小幅调整）
   - 评审范围明确为"本 feature 所有代码修改 vs conventions"
   - 用 feature slug 识别范围（不再用 feature-agnostic 的"最近改动"）

6. **test skill 本 feature 不动**
   - 保留现状；kind-sensitive 的详细方案留给独立 feature `test-workflow-per-kind`

### 不纳入范围

- `spec-review` 作为独立 skill（Y 类 = SKILL.md 误解模式扫查）→ 留给 `skill-spec-review-tool` feature
- test skill 的 kind 适配 → 留给 `test-workflow-per-kind` feature
- 老 forge 命令 `/forge:calibrate` / `/forge:tasking` 的 deprecation 过渡期→ 默认直接移除（v0.5.0 breaking change）
- scan-state 共享 → 已失效（onboard/calibrate 合并后内部共享，无需跨 skill 文件）

---

## Resolved Questions

### Q1 — onboard 合并后的交互模式 [WHAT]

**答：C — 扫描非交互，批量一次性冲突裁决**

- 扫描阶段：快速、非交互（LLM 自动识别冲突，不中断）
- 冲突裁决：扫描完成后，所有冲突汇总为一批，一次性交互询问用户
- 鲁棒性：比旧 calibrate 的"逐个询问"节约用户时间；比纯自动推断保留人工控制点

### Q2 — spec-review 语义取舍 [WHAT]

**答：X only，Y 不在当前 feature**

- **X（design 是否满足 clarify 需求）** → 纳入，作为 design 内嵌后置步骤
- **Y（SKILL.md 是否有 LLM 误解模式）** → 留给独立 feature，类比 test skill 之于 code

### Q3 — 老项目 context 文件迁移 [WHAT]

**答：C — 智能合并**

- 读旧文件，将内容按新 kind-aware 模板的章节位置重新组织
- 保留所有 `<!-- forge:preserve -->` 块（沿用 v0.4.0 preserve 机制）
- 无法对位的历史内容归入 "Legacy Notes" 附录章节而非丢弃
- 用户首次运行新 onboard 即自动迁移，无需手工操作

### Q4 — Kind 不适用章节的表达 [WHAT]

**答：A — 完全不出现**

- 修正我初始 Recommend（C "保留标题 + NA 解释 + 等价替代"）
- 用户明确选择 A：文档更短、更专注、减轻读者认知负担
- 理由："实用价值 不增添额外知识负担"——与 forge 的核心理念契合
- 代价：读者看不到"这个章节考虑过但 NA"这个信号；但新 onboard 会在元数据头部列出"本 kind 已排除的章节"作为补偿（例如 plugin onboard.md 头部会列 "Excluded sections: Logging, Database Access, Deployment"）

### Q5 — design 内嵌 spec-review 失败行为 [WHAT]

**答：A + Q — 硬阻断 + 允许回溯 decision 层**

- A（硬阻断）：spec-review 发现缺口时 design.md 不产出，必须补足
- Q（允许 decision 层回溯）：不限于在 tasks 层修补，也可以回到 decision 层重审
- 与新增 Scenario Walkthrough 的硬阻断策略一致，保证质量关

---

## Success Criteria

1. **Skill 数量**：`/skills` 列表中 forge 有且仅有 7 个 skill（`onboard` / `clarify` / `design` / `code` / `inspect` / `test` / `forge`）；`calibrate` 与 `tasking` 不再出现

2. **onboard 产物完整**：任何一个 kind 的 first-run 后，`.forge/context/` 存在 `onboard.md` + 最多 4 个 kind-applicable 的 context 文件；不适用的文件完全不创建

3. **kind-aware 覆盖**：三个 MVP kind 各自的 conventions.md / testing.md / architecture.md / constraints.md 内容显著差异化（可抽样比较，plugin 无 Logging 章节、web-backend 有完整 ORM 规约等）

4. **老项目升级**：在本 forge 仓库跑新 onboard，旧的 4 个 context 文件被智能合并为 kind-aware 版本，用户手写内容（若有 preserve 块）完全保留

5. **clarify 自校验生效**：首次产出 clarify 草稿后 LLM 必定执行 self-review 步骤（在 JOURNAL 或 clarify.md 头部可见自校验记录）；若发现 scope creep 或 contradiction，revise 后再呈现

6. **design 双文件 + Walkthrough + spec-review**：design skill 运行完产出 `design.md` + `plan.md`；design.md 含 "Scenario Walkthrough" 章节覆盖 3 场景；plan.md 末尾含 T{last} 文档更新任务；若 spec-review 发现缺口则不产出，必须修复

7. **design 线协议字面化**：涉及产物格式 / API / 持久化结构的 design 章节含 "Wire Protocol Examples" 子节，内有可 copy-paste 的字面值（非 `<placeholder>` 占位符）

8. **code 首次对话触发**：新项目首次运行 `/forge:code` 时若 conventions 无开发规范覆盖则触发 Q&A；已有规范则不打断；Q&A 答案写回 conventions

9. **文档更新 task 自动化**：design.md 生成的 plan.md 末尾永远有一个类型为 docs 的 T{last} 任务，描述"更新本 feature 涉及的 user-facing 文档"

10. **流水线自举不回归**：用本 feature 完成后，forge 自身跑一次 `/forge:onboard` → `/forge:clarify` → `/forge:design`（dry-run，不 code）全链路无报错，产物全部 kind-aware

---

## Open Questions

无。所有阻塞需求级问题已解。

---

## Gaps（当前代码库 vs 需求）

| ID | Gap | 工作类型 |
|----|-----|---------|
| G-01 | onboard SKILL.md 不含 calibrate 的约定提取逻辑 | 扩写 onboard |
| G-02 | calibrate SKILL.md 需废弃并从 plugin.json 摘除 | 删除 |
| G-03 | context 文件模板（conventions/testing/architecture/constraints）无 kind 变体 | 新建 per-kind 模板 |
| G-04 | 合并冲突"批量裁决"UX 不存在 | 新增 onboard Step |
| G-05 | clarify 无 self-review 步骤 | 扩写 clarify Step |
| G-06 | clarify Q 分类未进 SKILL.md 为正式 Step（现为 IRON RULE） | 重构 clarify Step 6 |
| G-07 | design SKILL.md 无 Scenario Walkthrough 章节要求 | 扩写 design |
| G-08 | design SKILL.md 无"线协议字面化"要求 | 扩写 design |
| G-09 | design SKILL.md 不含任务分解逻辑 | 合并 tasking 职责 |
| G-10 | tasking SKILL.md 需废弃 | 删除 |
| G-11 | design 无内嵌 spec-review 后置步骤 | 扩写 design |
| G-12 | design 无"T{last} 文档更新任务强制生成" | 扩写 design |
| G-13 | code SKILL.md 无首次开发规范对话 | 扩写 code |
| G-14 | inspect SKILL.md 未按 feature slug 明确评审范围 | 扩写 inspect |
| G-15 | forge orchestrator SKILL.md + state-machine.md 引用老 skill 名 | 更新 orchestrator |
| G-16 | plugin.json / README / CLAUDE.md 引用老流水线 | 更新文档 |
| G-17 | preserve 块机制需复用到 context 文件（不仅 onboard.md） | 扩展 preserve 适用范围 |

---

## Success Criteria 与 Gap 对照

| Success Criteria | 覆盖的 Gap |
|------------------|-----------|
| #1 Skill 数量 | G-02, G-10, G-15 |
| #2 onboard 产物完整 | G-01, G-03 |
| #3 kind-aware 覆盖 | G-03 |
| #4 老项目升级 | G-17 |
| #5 clarify 自校验 | G-05, G-06 |
| #6 design 双文件 + Walkthrough + spec-review | G-07, G-09, G-11, G-12 |
| #7 design 线协议字面化 | G-08 |
| #8 code 首次对话 | G-13 |
| #9 文档更新 task | G-12 |
| #10 自举不回归 | 全链路 |

---

## Notes

- **Breaking changes**: v0.5.0 是 major 变更，skill 名 `calibrate` 和 `tasking` 消失；建议在 README / CHANGELOG 明示升级指南（"旧 /forge:calibrate → 现在合并进 /forge:onboard"）
- **复用 v0.4.0 经验**：onboard 的 kind-detection + profile 架构、marker + preserve 块机制、5 属性 section marker 在本 feature 中全面扩展复用，不另起炉灶
- **开发顺序暗示**：G-01/G-03 是底座（新 onboard + 模板），其他 gap 大多建立在其上；tasking 阶段需注意依赖图
- **dogfooding**：本 feature 验证时建议 forge 仓库自身跑一遍，像 v0.4.0 那样做 self-bootstrap；同时推荐拿一个 web-backend 样板项目对照跑，确保 kind-aware 在非 plugin 场景也 work
