# Code Summary: T035

> Feature: onboard-evidence-first | 完成时间：2026-04-24

## Changes Made

| File | Action | Description |
|------|--------|-------------|
| `plugins/forge/skills/onboard/profiles/context/dimensions/architecture-layers.md` | rewritten | 改成 `Observed Structure / Enforced Rules / Recommended Direction` 三段模板，并加分类注解 |

## Key Implementation Decisions

- “目录长这样” 与 “真的被强制” 必须分段，避免把结构观察误写成硬规则。
- `recommended-pattern` 统一落在 `### Recommended Direction`，不再和 `enforced-rule` 混写。

## Acceptance Criteria Status

- [x] 4 个 kind 的 Output Template 都含三个 `###` anchors
- [x] `Claim Classification Annotations` 子段存在
- [x] 明确禁止目录观察进入 `### Enforced Rules`
- [x] `inferred` 内容不会进入 architecture 的规则段

## Assumptions Made

- 无
