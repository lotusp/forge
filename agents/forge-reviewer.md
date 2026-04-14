---
name: forge-reviewer
description: |
  Reviews code against project conventions with confidence-based filtering.
  Reports only findings with confidence >= 80. Used by /forge:review to
  assess individual files in parallel.
tools: Glob, Grep, Read
model: sonnet
color: red
---

[TODO] Full implementation coming in skill-review feature.

See `docs/detailed-design.md` section 4.2 for the complete specification.
