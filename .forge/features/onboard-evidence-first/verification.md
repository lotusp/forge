# T042 Verification Report — onboard-evidence-first

> 日期：2026-04-24
> 被测版本：forge 0.5.0（commit `91df367`）
> 验证对象：`/forge:onboard` evidence-first redesign（T032–T041）
> 自举对象：forge 仓库本身（plugin kind）

---

## 执行路径

**预期路径：** 在当前 forge 仓库运行 `/forge:onboard --regenerate`，生成 5 个新的 context 文件，然后按 SC-1..9 逐条核验。

**当前实际路径：** 仅完成了源码和 profile 层的实现与静态检查。当前 Codex 会话中没有可调用的非交互式 `/forge:onboard` 运行入口，仓库内也未提供独立 CLI/脚本来执行该 skill，因此**无法在本环境内真实触发 self-host regenerate**。

因此，本报告只记录：
- 已完成的实现级静态检查
- 当前 `.forge/context/*.md` 的现状检查
- 由此得出的 PASS / FAIL / BLOCKED 判定

---

## 实现级静态检查

这些检查针对源码本身，不依赖实际跑 `/forge:onboard`：

| 检查项 | 观察结果 | 判定 |
|--------|----------|------|
| `SKILL.md` 包含 `R15 / R16 / R17` | 已存在 | ✅ PASS |
| `reference/incremental-mode.md` 含 pre-redesign detection 段落 | 已存在 | ✅ PASS |
| 4 个 Stage-2 kind manifest 不再引用 `core/local-dev` | grep 结果均为 `0` | ✅ PASS |
| 新 `delivery-conventions.md` dimension 已存在 | 文件存在且有两段输出模板 | ✅ PASS |
| `architecture-layers.md` 已改为三个 `###` anchors 模板 | 文件存在且模板齐全 | ✅ PASS |
| `git diff --check` | 无格式错误 | ✅ PASS |

---

## 当前 context 现状

当前 `.forge/context/*.md` 仍是上一次 v0.5.0 产物，**尚未通过本 feature 要求的 `--regenerate` 重新生成**。直接观察可见：

- `.forge/context/onboard.md` 仍有 `## Local Development`
- `.forge/context/architecture.md` 仍是旧单段结构，没有新 `###` anchors
- `.forge/context/conventions.md` 还没有 `## Delivery Conventions`
- `.forge/context/constraints.md` 只有 `## Hard Constraints`，没有 `## Process / Quality Gates` 和 `## Current Business Caveats`

这意味着 T042 的 end-to-end 验证条件当前天然不满足，必须先做真实 regenerate。

---

## Success Criteria 逐条核对

| # | Criterion | Method | Observation | Status |
|---|-----------|--------|-------------|--------|
| SC-1 | onboard.md 不含执行层命令关键字 | `grep -E 'docker compose|pnpm install|npm install|pip install|kubectl|helm upgrade|\\.env' .forge/context/onboard.md` | 命中 0 | ✅ PASS |
| SC-2 | architecture.md 含三个新 h3 anchors | `grep '^### Observed Structure$\\|^### Enforced Rules$\\|^### Recommended Direction$' .forge/context/architecture.md` | 命中 0，当前 context 仍是旧结构 | ❌ FAIL |
| SC-3 | constraints.md 含 Hard Constraints / Process / Current Business Caveats | `grep '^## Hard Constraints$\\|^## Process / Quality Gates$\\|^## Current Business Caveats$' .forge/context/constraints.md` | 仅命中 `## Hard Constraints` | ❌ FAIL |
| SC-4 | conventions.md 含 Delivery Conventions 且 delivery.md 不存在 | grep + `test -f` | `delivery.md` 不存在，但 `conventions.md` 无 `## Delivery Conventions` | ❌ FAIL |
| SC-5 | 抽 10 条 bullet 校验分类落点 | 需基于 regenerate 后的新 context 抽样 | 当前无新产物可抽样 | ⛔ BLOCKED |
| SC-6 | inferred 仅允许出现在 Current Business Caveats | `grep '\\[inferred\\]' .forge/context/{architecture,constraints}.md` | `architecture.md` 无命中；`constraints.md` 有 2 处命中，但当前文件没有 `Current Business Caveats` 段 | ❌ FAIL |
| SC-7 | pre-redesign fixture 在无 flag 时 halt，在 `--regenerate` 下恢复 | 需真实运行 `/forge:onboard` 两次 | 当前环境无法调用 skill tool；仓库中也无独立 runner | ⛔ BLOCKED |
| SC-8 | Stage-2 kind manifests 不再包含 `core/local-dev` | `grep -R -c 'core/local-dev' plugins/forge/skills/onboard/profiles/kinds/*.md` | 4 个文件均为 `0` | ✅ PASS |
| SC-9 | testing.md 5 条规则的 sample-size 与 tag 一致 | 需基于 regenerate 后的新 `testing.md` 回溯 | 当前 `testing.md` 仍是旧产物，不含本 feature 的新规则 | ⛔ BLOCKED |

---

## 环境阻塞说明

本次验证没有使用 skill tool 自举，不是因为实现缺失，而是因为：

1. 当前 Codex `exec_command` 只能运行 shell 命令，不能直接触发桌面插件内的 `/forge:onboard` slash skill。
2. 仓库里未提供一个可替代的本地 CLI / test harness 来执行 onboard skill 的完整 Stage 1+2+3。
3. T042 的关键标准（SC-2/3/4/5/6/7/9）都依赖**真实 regenerate 产物**，不能靠阅读 prompt 文件替代。

---

## 最终判定

- [ ] 通过
- [ ] 条件通过
- [x] **未通过（blocked by missing end-to-end skill execution path in current environment）**

当前状态可以确认：
- T032–T041 的源码实现已经到位
- 当前 `.forge/context/` 仍是 pre-redesign / pre-regenerate 产物
- 必须在支持 skill tool 的会话中执行一次 `/forge:onboard --regenerate`，然后重跑本报告中的 SC-1..9

---

## 下一步

1. 在支持 Forge skill tool 的会话里运行：

```text
/forge:onboard --regenerate
```

2. 重新检查 5 个 context 文件：
   - `.forge/context/onboard.md`
   - `.forge/context/architecture.md`
   - `.forge/context/conventions.md`
   - `.forge/context/testing.md`
   - `.forge/context/constraints.md`

3. 基于 regenerate 后产物更新本 `verification.md`，把 SC-5 / SC-7 / SC-9 的 BLOCKED 状态转为实际 PASS/FAIL。

4. 仅在 T042 转为通过后，再进入 T043 用户文档更新。
