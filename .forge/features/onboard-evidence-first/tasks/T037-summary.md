# Code Summary: T037

> Feature: onboard-evidence-first | 完成时间：2026-04-24

## Changes Made

| File | Action | Description |
|------|--------|-------------|
| `plugins/forge/skills/onboard/profiles/context/dimensions/anti-patterns.md` | rewritten | 将旧 anti-pattern / debt 混合模板拆分为 `Current Business Caveats` 与 `Recommended Direction` 两条产出路径 |

## Key Implementation Decisions

- 时间绑定、项目特有、临时性的 caveat 保留在 `constraints.md`。
- 推断型 anti-pattern 一律降为推荐方向，不再伪装成硬约束。

## Acceptance Criteria Status

- [x] current-caveat 与 recommended-pattern 有明确分流
- [x] process-rule 改由 `delivery-conventions` 承接
- [x] 新增 Claim Classification Annotations
- [x] 不再复用旧的 debt 表格式模板

## Assumptions Made

- 无
