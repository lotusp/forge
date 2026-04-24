# Code Summary: T032

> Feature: onboard-evidence-first | 完成时间：2026-04-24

## Changes Made

| File | Action | Description |
|------|--------|-------------|
| `plugins/forge/skills/onboard/SKILL.md` | updated | 新增 R15/R16/R17，重写 Stage 2/3 的 classify、pre-route、pre-redesign detection、smart-merge 流程 |
| `plugins/forge/skills/onboard/reference/incremental-mode.md` | updated | 补齐 pre-redesign detection 算法、marker/header 示例、anchor 白名单说明 |

## Key Implementation Decisions

- Claim 必须先分类再渲染；artifact 落点由分类和各 dimension 的 annotations 决定。
- 将 execution-layer 内容排除做成独立 IRON RULE，而不是散落在各 profile 中。
- pre-redesign detection 放在 smart-merge 之前，避免旧格式 context 被增量逻辑误复用。

## Acceptance Criteria Status

- [x] `SKILL.md` 包含 R15 / R16 / R17 三条新 IRON RULE
- [x] Stage 2/3 明确先分类、再路由、再写入
- [x] Step 6 明确 pre-redesign detection 与 smart-merge 顺序
- [x] halt message 与 reference 算法说明对齐

## Assumptions Made

- 无
