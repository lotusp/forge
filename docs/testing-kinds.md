# Testing Kinds

> How to verify a new / modified `onboard` kind before shipping.

forge 目前支持 4 种 kind：`web-backend` / `web-frontend` / `plugin` / `monorepo`。
本文档描述扩充或修改 kind 时的标准测试流程。

---

## Why testing kinds is different from testing code

Kind 不是代码，而是**给 sub-agent LLM 的 prompt 片段**。测试它意味着：

1. 验证 kind detection 算法产出正确的置信度 + 边界（margin）
2. 验证 profile 加载列表符合 kind 声明
3. 验证 Stage 3 产物符合 excluded-dimensions 约束
4. 验证内容质量（sub-agent 不会发明内容、不会漏扫）

传统 unit test 不适用；需要**fixture-based LLM 执行测试**。

---

## The 3-layer test pyramid for kinds

```
┌─────────────────────────────────────────┐
│  Layer 3 — Content quality (human)      │  慢、主观、高价值
├─────────────────────────────────────────┤
│  Layer 2 — End-to-end (LLM execution)   │  中等成本
├─────────────────────────────────────────┤
│  Layer 1 — Structural (grep / ls)       │  快、机械、低价值
└─────────────────────────────────────────┘
```

### Layer 1 — Structural tests（加/改 kind 时必跑）

检查文件结构本身，不需要 LLM。可以脚本化：

```bash
# 所需文件齐全？
test -f plugins/forge/skills/onboard/profiles/kinds/<kind-id>.md
test -f plugins/forge/skills/onboard/profiles/context/kinds/<kind-id>.md

# Kind file frontmatter 合法？
grep -E '^kind-id:' plugins/forge/skills/onboard/profiles/kinds/<kind-id>.md
grep -E '^detection-signals:' plugins/forge/skills/onboard/profiles/kinds/<kind-id>.md
grep -E '^profiles:' plugins/forge/skills/onboard/profiles/kinds/<kind-id>.md
grep -E '^output-sections:' plugins/forge/skills/onboard/profiles/kinds/<kind-id>.md

# profiles: 列出的每个路径都真实存在？
# （伪代码；实际写成 .mjs 脚本更方便）
for p in $(yq '.profiles[]' kinds/<kind-id>.md); do
  test -f "plugins/forge/skills/onboard/profiles/$p.md" || echo "MISSING: $p"
done

# applies-to 双向一致性？
# 每个 kind 声明的 profile 的 applies-to 必须包含该 kind
# 反向：每个 profile 的 applies-to 列出的 kind 都有对应 kind file
```

**产出：** 一段 shell / node 脚本，CI 可跑。

### Layer 2 — End-to-end（最关键）

用**代表性 fixture 项目**触发 `/forge:onboard`，观察行为。

**Fixture 项目准则：**

- **最小可识别** —— 只保留 kind 检测必需的文件（package.json, 1-2 个典型源文件，README）
- **可运行但不需真跑** —— fixture 不必是可启动的项目
- **无外部项目标识符** —— 符合 C8 Content Hygiene（用 com.example.* / Order/Customer 等）

建议放在 `tests/fixtures/<kind-id>/`：

```
tests/fixtures/
├── web-backend/       # Spring Boot + PG + Kafka 最小骨架
├── web-frontend/      # React + Vite + React Router 最小骨架
├── plugin/            # (forge 仓库自身已是)
└── monorepo/          # pnpm-workspace + 3 个子包骨架
```

**E2E 测试流程**（每个 fixture 都跑）：

```
Fresh Claude Code session
  │
  ▼
cd tests/fixtures/<kind-id>/
  │
  ▼
删除已存在的 .forge/context/*（若有）
  │
  ▼
/forge:onboard
  │
  ▼
观察并记录:
  ✅ Kind detection:
     - 识别的 kind == <kind-id>?
     - 置信度 ≥ 0.60?
     - 与次高 kind 的 margin ≥ 0.15?
  ✅ Stage 2:
     - onboard.md 含 Excluded-dimensions header line?
     - 所有 section marker 6 属性齐备?
     - section 顺序 == kind file 的 output-sections?
  ✅ Stage 3:
     - 产出的 context 文件 == kind 的 output-files?
     - 未产出 excluded-dimensions 维度?
     - 所有 fact 带 [high|medium|low|inferred] tag?
  ✅ Batch conflict (如有):
     - 用户被一次性问完（而非逐个）?
```

**关键：一定在 fresh session 跑。** 同一会话内 Skill tool 对 SKILL.md
有 prompt cache，修改不生效（见 `.forge/context/testing.md` § Known LLM
behavior quirks）。

### Layer 3 — Content quality（主观，最重要）

人读产物，评估：

| 问题 | 检查点 |
|------|--------|
| kind 识别是否应得分？ | signals 扫描到的东西是否真的是本 kind 的特征 |
| 内容是否 kind-appropriate？ | plugin kind 的 conventions.md 不应提 logging；web-frontend 不应有 database-access |
| 事实是否准确？ | 抽样 5 行事实回源到 git 验证 |
| 证据强度匹配？ | [high] 标签的事实是否真的 high confidence |
| 冲突是否被识别？ | 如果 fixture 故意植入矛盾，是否被 batch conflict 捕获 |
| 内容是否臃肿？ | 有无无信息量的占位条目 |

Layer 3 没有自动化方法，只能人工。**每次加/改 kind 至少做一轮。**

---

## Workflow: adding a new kind

```
1. 起草 Stage 2 kind file (profiles/kinds/<new>.md)
   - detection-signals 覆盖 3-7 个正向信号 + 2-4 个负向信号
   - 权重之和 positive 理论上限 1.0（正信号可加总超过 1，clamped）
   - 列出 profiles 和 output-sections

2. 起草 Stage 3 context kind file (profiles/context/kinds/<new>.md)
   - 选定 output-files（可以是 1-4 的任何子集）
   - 声明 dimensions-loaded（按 output-file 分组）
   - 声明 excluded-dimensions

3. 更新 applies-to 列表
   - 每个被 <new> kind 加载的 profile / dimension 的 applies-to 加上 <new>
   - 反向：每个 excluded-dimensions 列出的 dimension 其 applies-to 不应有 <new>

4. 如果 <new> 是全新架构型态（web-frontend 是典型案例）:
   - architecture-layers.md 加 "Output Template — <new>" 小节
   - testing-strategy.md 加 "Output Template — <new>" 小节
   - 其他 kind-branched dimension 同样处理

5. Layer 1 跑脚本化结构检查（未来可做成 CI）

6. 建 fixture: tests/fixtures/<new>/
   - 选 3-5 个典型代表项（真实开源项目结构抽象化）
   - 每个 fixture 的 ~10 个文件足够触发 kind detection

7. Fresh Claude Code session 跑 Layer 2 E2E
   - 记录 verification：detection confidence / margin / profiles loaded /
     excluded-dimensions / content highlights

8. Layer 3 人工 review 产物
   - 抽样 5 行事实回源
   - kind-appropriate 检查
   - 冲突识别检查

9. 写 kind verification report
   - tests/verification/<kind-id>-<date>.md（可选，作为证据存档）

10. 更新文档
    - profiles/README.md 的 kind 列表
    - profiles/context/README.md 的 kind 列表
    - onboard SKILL.md description
    - README.md + CLAUDE.md 如果必要

11. Commit + release（单独 commit，便于回滚）
```

---

## Workflow: modifying an existing kind

### 场景 A — 修 detection signals（加/删/改权重）

1. 改 `profiles/kinds/<kind-id>.md` 的 `detection-signals`
2. **对所有 fixture 重跑 Layer 2**：确认未引入 regression
   - 本 kind 的 fixture 仍正确识别
   - 其他 kind 的 fixture 不会误判为本 kind
3. 如果信号权重累加 > 1.0，记得算 clamp 后是否仍 ≥ 0.60

### 场景 B — 加/删/改 dimensions

1. 改 `profiles/context/kinds/<kind-id>.md` 的 `dimensions-loaded` /
   `excluded-dimensions`
2. 确认新加入的 dimension 的 `applies-to` 有这个 kind
3. 确认从 dimensions-loaded 移除的 dimension 若需要，也从 applies-to
   移除该 kind
4. Fresh-session 跑本 kind 的 fixture：
   - 新 dimension 的内容是否出现
   - 被移除的 dimension 是否真的消失
   - 是否触发 smart merge 迁移历史内容到 Legacy Notes

### 场景 C — 改 dimension 内容（如 testing-strategy 输出模板）

1. 改 `profiles/context/dimensions/<dim>.md`
2. 覆盖所有使用该 dimension 的 kind（applies-to 列出的全部）
3. Fresh-session 跑每个相关 kind 的 fixture
4. 对比输出与改前预期差异

---

## Debugging: "kind detection failed"

### 症状：confidence < 0.60

1. **Run `/forge:onboard` with verbose mode** (if exists) or observe
   Stage 1 output carefully
2. 确认**正向信号命中**：每条 positive pattern 理论上对应 fixture 里的
   什么文件？grep 一遍确认实际存在
3. 确认**负向信号未误触**：某条 negative 是不是被 fixture 里无关文件
   触发了？
4. 计算实际得分：`max(0, sum(positive_hits * weight) - sum(negative_hits * weight))`
5. 若仍 < 0.60，要么加强 positive 权重，要么减弱 negative 权重，要么
   加新 positive 信号

### 症状：误识别为错误 kind（margin 不够）

例：React 项目被识别成 web-backend。

1. 对比两个 kind 的 signals：哪些 positive 信号重叠？
2. 核心诊断：**哪些文件是 kind 特有的？** web-frontend 特有 = `index.html` /
   Vite config / React 依赖；web-backend 特有 = Express/Spring 依赖 /
   migrations。
3. 加强 web-frontend 的 positive signal，或加 web-backend 的 negative
   signal（"无 HTTP framework deps"）

### 症状：Stage 3 产出不适用的 dimension

例：plugin kind 的 conventions.md 出现 logging section。

1. 检查 `profiles/context/kinds/plugin.md` 的 `excluded-dimensions` 是否
   包含 logging ✓
2. 检查 `profiles/context/dimensions/logging.md` 的 `applies-to` 是否
   **不**包含 plugin ✓
3. 若两处都正确却仍出现，可能是 sub-agent 忽略 applies-to；检查 SKILL.md
   R12 措辞是否足够硬（"MUST NOT create context files that do not apply
   to the kind"）
4. 升级警告为 "Common LLM trap" 块（参见 v0.5.0 lesson）

---

## Smoke-test script （建议未来工程化）

把 Layer 1 自动化成脚本：

```javascript
// scripts/validate-kinds.mjs — 建议未来实现
//
// 对每个 kind file 检查:
// 1. frontmatter 必需字段齐全
// 2. profiles[] 路径全部存在
// 3. 与 context kind file 的 output-sections 对齐
// 4. applies-to 双向一致性
//
// Exit code: 0 if all pass, 1 otherwise
// CI 可在 PR 时跑
```

目前（v0.5.1）未实现；手工跑上述 grep/glob 检查即可。

---

## Checklist before shipping a kind change

```
□ Layer 1 structural check 通过（grep / ls / frontmatter 校验）
□ applies-to 双向一致
□ 相关 dimension 的 Output Template — <kind> 小节齐全（如需 kind 分支）
□ Fixture 项目存在且代表性充足
□ Fresh-session 跑 Layer 2，记录 detection + artifacts 合规
□ Layer 3 抽样 5 行回源验证
□ Verification report 归档（可选）
□ 文档同步（profiles/README + onboard SKILL.md description + README）
□ Commit 独立可回滚
```

---

## Related docs

- `.forge/context/testing.md` — 解释 forge 本身的 testing paradigm
- `plugins/forge/skills/onboard/profiles/README.md` — profile/kind schema
- `plugins/forge/skills/onboard/profiles/context/README.md` — Stage 3
  schema
- `plugins/forge/skills/onboard/SKILL.md` — IRON RULES R12 / R13（kind
  不适用处理规则）
