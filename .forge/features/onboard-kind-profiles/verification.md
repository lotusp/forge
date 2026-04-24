# T015 Verification Report — onboard-kind-profiles

> 日期：2026-04-22
> 被测版本：forge 0.3.2-dev（commit `d3db26a`）
> 验证对象：`/forge:onboard` 新实现（T012 SKILL.md + T013 incremental-mode + T006–T011 profiles）
> 自举对象：forge 仓库本身（识别为 `plugin` kind）

---

## Phase 1 — First-run（Mode A）

### Execution 结果

| 项 | 值 |
|----|----|
| 触发方式 | 删除 `.forge/context/onboard.md` → invoke `/forge:onboard` |
| 识别 kind | `plugin` |
| 置信度 | **0.90** |
| 加载 profile 数 | 6（均为 core/*，完全符合 K-12 Decision） |
| 生成 section 数 | 7（What This Is + 6 profile sections） |
| 产物总行数 | 219（对比旧版 v0.3.0 的 575 行） |
| 运行耗时 | 一次前台执行，未精确计时；subjectively 3–5 分钟 |

### Confidence tag 实际使用

| Tag | 次数 | 规范符合 |
|-----|------|---------|
| `[high]` | 33 | ✅ 在规范内 |
| `[code]` | 23 | ⚠ 超出规范（扩展为"来源"维度）|
| `[inferred]` | 1 | ✅ 在规范内 |
| `[conflict]` | 3 | ⚠ 超出规范（扩展为"冲突"维度）|
| `[build]` / `[readme]` | 若干 | ⚠ 超出规范 |

---

## Phase 2 — Incremental（Mode B，3 处手改触发）

### 测试用例

| # | 手改目标 | 改动类型 | 实际行为 | 判定 |
|---|---------|---------|---------|------|
| 1 | Tech Stack 内插入 `<!-- forge:preserve -->` 块含 `[TEST-MARKER-PRESERVE-1]` | 新增 preserve 块 | 原样保留在 Tech Stack 内（Tech Stack 本身被判 CLEAN 未重跑）| ✅ PASS — I-R1 preserve 神圣 |
| 2 | Module Map 把 `forge` skill 描述改为 `[TEST-MARKER-DIRTY-2]` 错误文本 | 非 preserve 文本修改 | 整个 Module Map 被判 DIRTY 重跑，TEST-MARKER 被正确覆盖，`onboard` skill 描述顺带更新为新架构 | ✅ PASS — dirty 检测 + 重写 |
| 3 | Notes 删除 `tests/scenarios/ is empty` bullet | 删除 | Notes 被判 DIRTY 重跑，该 bullet 未被恢复（证据不强不再出现）| ✅ PASS — 用户删除被尊重 |

### Mode B 运行统计

- **HEAD 比对**：`d3db26a` = 上次 verified，no new commits
- **Sections written**：2（module-map、notes）
- **Sections reused**：5（what-this-is、tech-stack、entry-points、local-dev、key-data-flows）
- **Preserve 块迁移**：1 识别，0 orphan

### Sub-agent 实际采用的增量检测逻辑（推断）

从行为反推：
1. 先用 HEAD == verified 快速建立"潜在 CLEAN"假设
2. 对每个 section 做 body-level 比对（LLM judgment，非严格 hash），识别出与 profile 预期不符的用户修改 → 覆盖为 DIRTY
3. Preserve 块内的改动**不影响** section 的 dirty 判定（i-R2 canonicalization 精神遵守，虽然不是严格 SHA-256 hash）

这比我在 T013 写的纯 body-hash 方案更实用（见"问题诊断"章节）。

---

## Success Criteria 逐条核对

| 编号 | 标准 | 结果 |
|------|------|------|
| SC-1 | Kind 识别 `plugin`，置信度 ≥ 0.6 | ✅ 0.90 |
| SC-2 | Section 顺序 = kind 的 `output-sections` | ✅ 7/7 一致 |
| SC-3 | Section marker 含 `profile=` 属性 | ⚠ `profile=` **缺失**（可从 kind 文件回退推导，非 blocker）|
| SC-4 | Confidence tag 合规 | ⚠ 扩展了 `[code]/[conflict]/[build]/[readme]`；需要规范决策 |
| SC-5 | Preserve 块保留 | ✅ 100% |
| SC-6 | Dirty section 检测 | ✅ 实际工作，虽然机制非严格 I-R2 SHA-256 |
| SC-7 | Low-confidence / unknown halt | N/A（本次 Stable，未触发；建议单独补一次人工诱发测试） |
| SC-8 | Content Hygiene 合规 | ✅ 产物内无外部项目标识符 |

---

## 发现的问题与规范缺陷

### 🟡 Minor-1：Section marker 缺 `profile=` 属性

- **位置**：所有 7 个 section marker
- **影响**：Mode D (`--section=<name>`) 需要从 marker 反推 profile；当前需回退到 kind 文件查询 `output-sections ↔ profiles` 映射
- **修法**：T012a — SKILL.md Step 3.3 用更鲜明的字面示例 + IRON RULE "marker 必须四属性齐备"
- **不阻塞 T016**

### 🟡 Minor-2：Header 使用 HTML marker 而非 markdown 引用块

- **位置**：产物 line 1–7
- **偏离**：SKILL.md Step 3.1 要求 `> Kind:` 风格
- **影响**：功能一致，只是格式不统一
- **修法**：T012a — Step 3.1 用硬示例
- **不阻塞 T016**

### 🟡 Minor-3：Confidence tag 扩展

- **现象**：sub-agent 引入 `[code]`（来源 = 源代码）、`[conflict]`（冲突标记）、`[build]`/`[readme]`（具体来源）
- **分析**：这实际上把 "confidence 轴" 扩展为 "confidence + source" 两轴，有信息价值。但破坏了 profile 规范统一性。
- **修法（需要裁决）**：
  - 选项 A：收紧到 4 值 `[high|medium|low|inferred]`，source 信息靠 prose 表达 → 更保守
  - 选项 B：承认两轴结构，把 `source = code|build|readme|config|inferred` 明文化到规范 → 更灵活
  - 选项 C：分离关注点，用独立前缀如 `[⚠ conflict]` + `(source: code)` → 最显式
- **建议**：选项 B — 在 profiles/README.md 里把 confidence 4 值 + source 枚举并列定义
- **不阻塞 T016**

### ⚠️ 我的规范设计缺陷（非 sub-agent 问题）

1. **I-R2 (body hash) 设计缺陷**：
   - 增量模式的**核心价值**是"HEAD 未变就跳过昂贵扫描"
   - 但 body hash 要算必须先跑 profile，等于空做功
   - 旧版 incremental-mode.md 用的 git hash 粗筛 + signature 细筛才是正解
   - Sub-agent 用 git hash 作 `verified=` 值是**正确的**实用选择
   - **修法**：T013a — I-R2 改为混合策略：`verified-commit=<git-short>` + `body-signature=<hash>` 两个属性，前者做快速跳过，后者做 out-of-band 编辑检测

2. **IRON RULES 跨文档分裂**：
   - I-R2 只放 incremental-mode.md，SKILL.md 只 cross-reference
   - First-run 根本不读 incremental-mode.md，规则没覆盖到
   - **修法**：T012a — 关键算法（hash 定义 / marker 格式 / tag 枚举）在 SKILL.md 里硬复制，不再 DRY

---

## 最终判定

- [x] **条件通过** — 8 项 Success Criteria 中 5 项完全通过，3 项 Minor 偏差，0 项 blocker。
- T016 可进（版本跃迁到 0.4.0），前提是在进入 T016 前开 follow-up 任务 **T012a + T013a** 修正规范缺陷，并在首个 v0.4.x patch 中修复。
- [ ] 通过
- [ ] 不通过

## 后续 Follow-up Tasks

### T012a — SKILL.md 规范强化

- **验收 1**：Section marker format 用完整字面示例固定（含真实 hash 值形态）
- **验收 2**：新增 IRON RULE "section marker 必须含 section / profile / verified / generated 四属性"
- **验收 3**：Confidence tag 枚举在 SKILL.md IRON RULES 里明文列出，跳过 cross-reference
- **验收 4**：Step 3.1 header 格式示例与 Step 3.3 marker 格式对齐
- **优先级**：High（T016 前完成）

### T013a — incremental-mode.md 修正 I-R2

- **验收 1**：`verified=` 拆分为 `verified-commit=<git-short>`（快速跳过）+ `body-signature=<sha256-16hex>`（out-of-band 手改检测）
- **验收 2**：Mode B 流程说明：先 `verified-commit` 比对 → HEAD 未变直接 CLEAN，不跑 profile；HEAD 变了再看 `body-signature` 细筛
- **验收 3**：重新定义 canonicalization（仍排除 preserve 块，但仅用于 body-signature 计算）
- **验收 4**：与 T012a 的 SKILL.md marker 格式对齐
- **优先级**：High（T016 前完成）

### T015 补测（可选）

- 人工诱发 low-confidence kind detection（比如对一个完全非标项目跑 `/forge:onboard`）验证 halt 行为
- 人工诱发 kind drift（改 `.claude-plugin/plugin.json` 让 forge 看起来不像 plugin）验证 Mode B kind drift 决策表
- **优先级**：Medium（v0.4 后第一个补丁窗口做）

---

## Appendix A — First-run 产物结构摘要

```
Line 1-7    : 自定义 HTML header marker（非规范但工作）
Line 11-28  : Section 1 What This Is
Line 32-55  : Section 2 Tech Stack（含 Phase 2 preserve 块 line 47-51）
Line 59-95  : Section 3 Module Map
Line 99-133 : Section 4 Entry Points
Line 137-?  : Section 5 Local Development
Line ?-185  : Section 6 Key Data Flows
Line 189-206: Section 7 Notes
Line 208-223: Document Confidence 汇总
```

## Appendix B — Sub-agent 判断 DIRTY 的触发证据

| Section | 修改类型 | DIRTY 判定 |
|---------|---------|-----------|
| tech-stack | preserve 块 + 非 preserve 文本修改（有） | CLEAN（preserve 被 canonicalize 掉，非 preserve 部分本身未改）|
| module-map | 表格行文本修改 | DIRTY |
| notes | bullet 删除 | DIRTY |
| what-this-is / entry-points / local-dev / key-data-flows | 未改 | CLEAN |

判定标准：sub-agent 用 body-level 文本比对（不是严格 SHA-256），效果正确。
