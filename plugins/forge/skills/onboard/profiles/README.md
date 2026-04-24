# Onboard Profiles

> 由 `/forge:onboard` skill 按 **kind** 和 **profile** 组合加载。
> 本目录替代了旧的 `reference/output-template.md` 单体模板。

---

## 目录结构

```
profiles/
├── core/          # 任何 kind 都会加载的基础剖面（6 个）
├── structural/    # 构建/配置/部署剖面（3 个）
├── model/         # 领域模型 / 数据库模式剖面（2 个）
├── entry-points/  # HTTP API / 事件消费者剖面（2 个）
├── integration/   # 第三方 API / 鉴权 / 消息队列剖面（3 个）
├── monorepo/      # monorepo 专用剖面（1 个）
└── kinds/         # kind 定义文件（web-backend / web-frontend / plugin / monorepo）
```

---

## Profile File Schema

每个 profile 文件是一份独立的 Markdown，顶部 YAML frontmatter 声明元数据，
正文给出扫描模式、提取规则、section 产出模板。

### Frontmatter 字段

```yaml
---
name: <profile-id>              # 全局唯一，如 tech-stack / http-api
section: <section-title>        # 产出时在 onboard.md 中的章节标题
applies-to:                     # 哪些 kind 会加载此 profile
  - web-backend
  - plugin
confidence-signals:             # 置信度提升信号（供 kind detection 复用）
  - <signal-description>
token-budget: <number>          # 建议该 profile 提取的内容 token 上限
                                # core: ≤ 1500 / 其他: ≤ 1000
---
```

### 正文结构

每个 profile 正文包含 4 个固定小节：

1. **Scan Patterns** — grep / glob 模式，说明从哪些文件抓取信号
2. **Extraction Rules** — 从扫描结果提取什么信息，如何归类
3. **Section Template** — 写入 onboard.md 时的 markdown 结构
4. **Confidence Tags** — 何时标注 `[high]` / `[medium]` / `[low]` / `[inferred]`

---

## Kind File Schema

`kinds/<kind-id>.md` 定义一个 kind 的执行计划。

### Frontmatter 字段

```yaml
---
kind-id: <unique-id>            # web-backend / plugin / monorepo
display-name: <human-readable>  # 用于交互消息
detection-signals:
  positive:                     # 正向信号（存在即加分）
    - pattern: <glob-or-grep>
      weight: <0.0–1.0>
  negative:                     # 负向信号（存在即减分）
    - pattern: <glob-or-grep>
      weight: <0.0–1.0>
profiles:                       # 按加载顺序列出
  - core/tech-stack
  - core/module-map
  - structural/build-system
  - ...
output-sections:                # onboard.md 的 section 顺序（与 profiles 一一对应）
  - What This Is
  - Tech Stack
  - ...
---
```

### 正文结构

Kind 文件正文描述：

1. **When to Use** — 识别本 kind 的典型项目特征（给 LLM 判断用）
2. **Execution Notes** — 本 kind 特有的扫描策略或注意事项
3. **Excluded Profiles** — 哪些 profile **不** 加载（显式声明，避免误加）

---

## Execution Contract

`/forge:onboard` 的 Step 1 产出 **Execution Plan**，内容来源于选定 kind 文件：

```text
[Execution Plan]
- Selected kind:        <kind-id>
- Confidence:           <0.0–1.0>
- Profiles to load:     [<path>, <path>, ...]
- Skipped profiles:     [<path>, ...]   (with reason)
- Output sections:      [<title>, ...]  (in order)
```

Step 2 按此计划逐个执行 read-do-discard 循环，不再回读 kind 文件。
（详见 SKILL.md IRON RULES。）

---

## Naming Conventions

- Profile 文件名：`<short-id>.md`，小写短横线（如 `tech-stack.md`）
- Profile `name` frontmatter：与文件名同
- Kind 文件名：`<kind-id>.md`，小写短横线
- `section` 字段：英文标题大小写（Tech Stack / Local Development）

---

## Tag System (SKILL.md R10 — canonical definition)

每个 profile 产出的事实（表格行、bullet、参数）**必须**携带至少一个 confidence
tag，**可以**附加 source tag 和 conflict flag。顺序固定：
`<fact> [confidence] [source?] [conflict?]`。

### Confidence axis（必须 1 个）

```
[high]       — source verified; fact directly observed
[medium]     — pattern observed + partial cross-verification
[low]        — single-source evidence; not cross-verified
[inferred]   — derived from directory layout / file names without body inspection
```

**每个 profile 文件的 "Confidence Tags" 小节定义本 profile 下这 4 个 tag 的
具体判定标准**（例如 `tech-stack.md` 的 `[high]` = "declared in authoritative
config"；`module-map.md` 的 `[high]` = "boundary + responsibility 都从 README
或导入关系确认"）。新增 profile 时必须填写该小节。

### Source axis（可选，最多 1 个）

```
[code]    — read from source file bodies (.java, .ts, .go, etc.)
[build]   — read from build manifests (pom.xml / package.json / Dockerfile / CI YAML)
[config]  — read from runtime config (application.yml / .env / k8s manifests)
[readme]  — read from README.md / docs/**/*.md / CLAUDE.md
[cli]     — output of a shell command in Runtime snapshot (ls / find / grep)
```

用途：让读者快速判断该事实的验证深度（代码级 > 配置级 > 文档级）。在
onboard.md 的 `Document Confidence` 汇总表也按 source 分类。

### Conflict flag（可选）

```
[conflict]  — 本事实与文档中另一处声明矛盾（例：plugin.json 版本 vs README badge 版本）
```

用途：提示人类 reviewer 此处需要裁决。每个 [conflict] 都应该在 onboard.md 的
`Conflicts requiring human review` 列表里有对应条目。

### 范例

```markdown
| Plugin version | `0.3.2-dev` (plugin.json) — README badge shows `0.3.1` [high] [build] [conflict] |
| Language       | TypeScript 5.x [high] [build] |
| Framework      | Express 4 + Zod validation [medium] [code] |
| Rate limit     | 100 req/min globally [low] [readme] |
| HTTP port      | 3000 (guessed from Dockerfile EXPOSE directive) [inferred] [build] |
```

### 严禁

- 发明新 tag（`[code-verified]` / `[certain]` / `[guess]` 均违反 R10）
- 使用中文 tag
- 颠倒顺序（`[code] [high]` ❌；必须 confidence 在前）
- 省略 confidence tag（R7 违反）

---

## Content Hygiene

所有 profile 和 kind 文件的示例必须遵守 `.forge/context/constraints.md` C8：

- 使用通用调色板（e-commerce order platform：`Order` / `Customer` / `Payment` /
  `com.example.shop.*`）
- 禁止出现任何外部真实公司、产品、内部系统缩写、生产基础设施域名

---

## Adding a New Profile

1. 选定分类目录（core / structural / model / ...）
2. 新建 `<profile-id>.md`，按上述 schema 填写
3. 在需要加载它的 kind 文件的 `profiles:` 列表中追加路径
4. 在 `applies-to:` frontmatter 中反向登记支持的 kind
5. 自举跑一遍 `/forge:onboard --regenerate` 验证 section 产出

## Adding a New Kind

1. 在 `kinds/` 下新建 `<kind-id>.md`
2. 列出 `detection-signals` 的正/负向信号及权重
3. 选定需要的 profile 组合
4. 定义 `output-sections` 顺序
5. 自举或在目标项目运行 `/forge:onboard` 验证识别置信度 ≥ 0.6
