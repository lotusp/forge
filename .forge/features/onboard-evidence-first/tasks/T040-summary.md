# Code Summary: T040

> Feature: onboard-evidence-first | 完成时间：2026-04-24

## Changes Made

| File | Action | Description |
|------|--------|-------------|
| `plugins/forge/skills/onboard/SKILL.md` | updated | 将 Step 6 的 pre-redesign detection 指向 reference，并明确 halt / regenerate 语义 |
| `plugins/forge/skills/onboard/reference/incremental-mode.md` | updated | 补齐 pre-redesign format detection 的算法细节、anchor 白名单和 halt message |

## Key Implementation Decisions

- anchor 白名单来自各 dimension 的 Output Template，不单独维护第二份列表。
- 只要检测到 pre-redesign section，非 `--regenerate` 模式必须 halt。

## Acceptance Criteria Status

- [x] `incremental-mode.md` 有独立的 `Pre-redesign format detection` 段落
- [x] `SKILL.md` 中的 Step 6 与 reference 文档互相对齐
- [x] halt message 已固化为明确文案

## Assumptions Made

- 无
