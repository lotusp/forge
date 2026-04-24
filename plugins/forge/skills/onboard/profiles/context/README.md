# Onboard Context Profiles

> onboard skill 的 **Stage 3**（context 阶段，吸收原 calibrate 职责）依赖此目录。
> 本目录定义了 4 个 context 文件（conventions / testing / architecture / constraints）
> 按 kind 组合加载的扫描与产出规范。
>
> 与姊妹目录 `../kinds/` + `../{core,structural,...}/`（Stage 2 用）相对应；
> 两者架构一致，文件 schema 一致，加载流程一致。

---

## 目录结构

```
profiles/context/
├── README.md              # 本文件
├── kinds/                 # 每个 kind 的 context 维度索引
│   ├── web-backend.md
│   ├── web-frontend.md
│   ├── plugin.md
│   └── monorepo.md
└── dimensions/            # 每个维度的扫描 + 产出模板（16 个）
    ├── naming.md          # 通用
    ├── error-handling.md  # 通用
    ├── commit-format.md   # 通用
    ├── architecture-layers.md  # 通用（内容按 kind 分支）
    ├── hard-constraints.md     # 通用
    ├── anti-patterns.md        # 通用
    ├── testing-strategy.md     # 通用（内容按 kind 分支）
    ├── logging.md              # web-backend / monorepo
    ├── validation.md           # web-backend / monorepo
    ├── api-design.md           # web-backend / monorepo
    ├── database-access.md      # web-backend / monorepo
    ├── messaging.md            # web-backend / monorepo
    ├── authentication.md       # web-backend / monorepo
    ├── skill-format.md         # plugin
    ├── artifact-writing.md     # plugin
    └── markdown-conventions.md # plugin
```

---

## Context Kind File Schema

每个 `kinds/<kind-id>.md` 文件声明本 kind 加载哪些 dimension、产出到哪些 context 文件。

### Frontmatter 字段

```yaml
---
kind-id: <unique-id>                # web-backend / plugin / monorepo
display-name: <human-readable>
output-files:                       # 本 kind 产出的 context 文件子集
  - conventions.md
  - testing.md
  - architecture.md
  - constraints.md
dimensions-loaded:                  # 本 kind 加载的 dimension 文件（按产出文件分组）
  conventions:
    - dimensions/naming
    - dimensions/error-handling
    - dimensions/logging       # 仅 web-backend / monorepo
    # ...
  testing:
    - dimensions/testing-strategy
  architecture:
    - dimensions/architecture-layers
  constraints:
    - dimensions/hard-constraints
    - dimensions/anti-patterns
excluded-dimensions:                # 明示本 kind 不适用的维度
  - logging
  - database-access
  - api-design
  # ...
---
```

### 正文

- **When this kind applies** —— 本 kind 的识别特征（与 `../kinds/<id>.md` 保持一致）
- **Context file strategy** —— 本 kind 产出 context 文件的思路（例：
  plugin 的 testing.md 内容以"self-bootstrap 为验证"为核心，而非传统单测）
- **Excluded rationale** —— 被排除的维度为什么不适用（简短说明）

---

## Dimension File Schema

每个 `dimensions/<dim-id>.md` 文件定义一个 context 维度的扫描与产出规则。

### Frontmatter 字段

```yaml
---
name: <dimension-id>                # 全局唯一（naming / error-handling / ...）
output-file: <one-of>               # conventions.md / testing.md / architecture.md / constraints.md
applies-to:                         # 适用的 kind 列表
  - web-backend
  - monorepo
scan-sources:                       # 扫描范围（glob + grep 模式）
  - glob: "src/**/*.ts"
  - glob: "build.gradle"
confidence-signals:                 # 置信度提升信号
  - <description>
token-budget: <number>              # 建议产出内容 token 上限
---
```

### 正文

每个 dimension 文件含 4 个固定小节（与 `../core/*` profile 同 schema）：

1. **Scan Patterns** —— glob / grep 模式，说明从哪些文件抓取信号
2. **Extraction Rules** —— 从扫描结果提取规则，如何识别冲突
3. **Output Template** —— 写入 context 文件的 markdown 结构
4. **Confidence Tags** —— `[high|medium|low|inferred]` 判定标准

对 kind 分支的 dimension（如 `testing-strategy.md`），Output Template
分为 kind-branch 子小节：
```markdown
### Output Template — plugin
{模板 A}

### Output Template — web-backend / monorepo
{模板 B}
```

---

## Execution Contract（onboard Stage 3 调用约定）

1. **入口**：onboard Stage 3 开始时，读取当前 `kind-id` 对应的
   `context/kinds/<kind-id>.md`
2. **加载 dimension**：按 `dimensions-loaded` 列出的顺序逐个读取 dimension 文件
3. **扫描（非交互）**：对每个 dimension，执行其 Scan Patterns + Extraction Rules
4. **冲突收集**：扫描过程中发现的冲突**不立即交互**，累积到冲突清单
5. **批量交互**（一次性）：所有 dimension 扫描完成后，一次性呈现冲突清单给用户
6. **smart merge**：读现有 context 文件（若存在），按 v0.4.0 preserve 块机制保留
   人工内容；新生成内容与旧内容按 dimension 归属合并
7. **写入**：按 `output-files` 列出的文件写入最终产物；**不适用的文件不创建**
8. **Header 元数据**：写入 `Excluded-dimensions:` 字段，列出本 kind 排除的维度
   （补偿 excluded 维度完全不出现时失去的"考虑过但 NA"信号）

---

## Section Marker Contract

每个 context 文件的每个 section 使用 5 属性 marker（复用 `../../SKILL.md` R9）：

```markdown
<!-- forge:onboard source-file="conventions.md" section="error-handling" profile="context/dimensions/error-handling" verified-commit="a3f2c1d4" body-signature="9f8e7d6c5b4a3210" generated="2026-04-23" -->

## Error Handling

...rules synthesized from scanned evidence...

<!-- /forge:onboard section="error-handling" -->
```

新增 `source-file` 属性（区分 onboard.md / conventions.md / testing.md 等产物
文件）；其余 4 属性与 v0.4.0 onboard.md marker 一致。

---

## Content Hygiene

所有 dimension 文件和 kind 文件的示例必须遵守 `.forge/context/constraints.md` C8：

- 使用 e-commerce 调色板（`Order` / `Customer` / `Product` / `Payment` /
  `com.example.shop.*`）
- 禁止出现外部真实公司、产品、内部系统缩写、生产基础设施域名

---

## Adding a New Dimension

1. 在 `dimensions/` 下新建 `<dim-id>.md`，按上述 schema 填写
2. 在所有适用 kind 的 `kinds/<kind-id>.md` 的 `dimensions-loaded` 中追加
3. 在不适用 kind 的 `excluded-dimensions` 中追加（若默认不可见则需显式排除）
4. 在本 README 的目录结构图中追加一行

## Adding a New Kind

1. 在 `../kinds/` 新建 kind 文件（Stage 2 onboard.md 用）——见 v0.4.0 文档
2. 在 `./kinds/` 新建 kind 文件（Stage 3 context 用）
3. 在 `./kinds/<new>.md` 的 `dimensions-loaded` 声明本 kind 加载哪些现有 dimension
4. 若需新维度，按 "Adding a New Dimension" 流程补上
