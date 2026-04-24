# Code Summary: T038

> Feature: onboard-evidence-first | 完成时间：2026-04-24

## Changes Made

| File | Action | Description |
|------|--------|-------------|
| `plugins/forge/skills/onboard/profiles/context/dimensions/delivery-conventions.md` | created | 新增交付规范 dimension，承接 commit 粒度、verification-before-done、artifact 更新等要求 |
| `plugins/forge/skills/onboard/profiles/context/dimensions/commit-format.md` | updated | 收窄到 commit message 格式本身，显式把交付类约束移交给 `delivery-conventions` |

## Key Implementation Decisions

- 不引入新的 dual-output-file frontmatter 语义。
- claim 落到 `conventions.md` 还是 `constraints.md`，统一由 annotations + kind manifests 决定。

## Acceptance Criteria Status

- [x] 新 dimension 已存在并包含 Scan Sources / Claim Classification Annotations / Output Templates
- [x] conventions 路由和 process gate 路由都在同一份 dimension 中声明
- [x] commit-format 与 delivery-conventions 范围已拆清

## Assumptions Made

- 无
