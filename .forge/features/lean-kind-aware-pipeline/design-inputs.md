# Design Inputs: lean-kind-aware-pipeline

> 生成时间：2026-04-23
> 来源：用户在 clarify 会话中主动提出的实现级预约束
> 用途：预先约束 design 阶段的设计空间，避免 design 重复讨论已有偏好

---

## DI-1 — tasks 独立存放，不与 design.md 合并

用户明确要求：design 产物分两个文件

- `.forge/features/{slug}/design.md` —— 纯技术设计（decisions, scenarios, wire protocols）
- `.forge/features/{slug}/plan.md` —— 任务列表（T{NNN} IDs, deps, 验收标准）

设计含义：
- 新 design skill 内部分两个写入阶段：先写 design.md → 触发 embedded spec-review → 通过后再写 plan.md
- design.md 和 plan.md 解耦，允许设计不变仅 plan 迭代（如追加漏掉的 task）
- task ID 全局唯一的惯例（forge 内跨 feature 全局）保留

---

## DI-2 — code 首次对话触发条件 = conventions 覆盖缺口

用户明确：仅当 conventions.md（或其他前置文档）**未覆盖本次 task 所需的开发规范**时才触发 Q&A

- 触发条件：
  - 本 task 需要测试策略指导 + conventions.md 的 Testing 章节为空 → 问
  - 本 task 涉及 commit 规范 + conventions.md 无相关条款 → 问
- 不触发：相关章节已有内容
- 检测方式由 design 阶段定（实现细节），但触发语义由本 DI 固定

---

## DI-3 — 规范写回路径非锁定单一文件

用户明确：新发现的约定可写到 conventions.md **或其他合适文档**

- 首选 conventions.md
- testing-specific 的 → testing.md
- architecture-level 的 → architecture.md
- 硬性边界类 → constraints.md
- design 阶段需明确"哪类约定写哪个文件"的决策树

---

## DI-4 — 文档更新作为 T{last} 任务，不新增 skill

用户明确：feature 完成后的 README 等文档更新放在 code skill 内执行，不新增 skill

- 实现方式：design 生成 plan.md 时**必须**在末尾插入 T{last} 类型为 `docs` 的任务
- 任务描述 kind-driven：
  - claude-code-plugin kind → README.md + CLAUDE.md
  - web-backend kind → OpenAPI spec / docs / CHANGELOG
  - monorepo kind → 根 README + 涉及子包的 README
- 该 task 由 `/forge:code T{last}` 正常执行，跟其他 task 同级
- design 阶段需决策：task 模板字面内容 / kind 判断点

---

## DI-5 — "Excluded sections" 元数据头部补偿 Q4 答案

用户选 Q4 选项 A（不适用章节完全不出现），但失去了"考虑过但 NA"这一信号。
我提议的补偿机制：onboard 产物头部在元数据中明示本 kind 排除的章节列表。
用户未明确拒绝此补偿；design 阶段可按此方向细化。

草拟形式（design 阶段字面化）：
```
<!-- forge:onboard header kind=claude-code-plugin excluded-sections="logging,database,deployment" ... -->
```

若 design 阶段判断此补偿机制本身"增添额外知识负担"，可去掉；留给 design 决策。

---

## 非 DI（不在本文件约束范围）

以下仍由 design 阶段自由决策：
- `onboard` 合并 `calibrate` 后的 Step 编号 / 内部流程图
- 4 个 context 文件的 kind-aware 模板**具体内容**
- clarify self-review 的**具体检查点清单**
- design Scenario Walkthrough 的**场景产出格式**
- design embedded spec-review 的**通过判据字面化**
- code Q&A 的**具体问法 / 问题清单**（按 kind 差异）
- inspect 如何从 feature slug **枚举**改动文件
- orchestrator state-machine 的**状态转移表重写**
