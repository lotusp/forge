# Testing Strategy: forge

> Kind:                 claude-code-plugin
> Generated:            2026-04-23
> Commit:               59836a2
> Generator:            /forge:onboard Stage 3 (v0.5.0-dev)
> Dimensions loaded:    testing-strategy

---

<!-- forge:onboard source-file="testing.md" section="testing-strategy" profile="context/dimensions/testing-strategy" verified-commit="59836a2" body-signature="f4a92e7b1c50d683" generated="2026-04-23" -->

## Testing Strategy

**Testing paradigm:** Self-bootstrap verification

Traditional unit tests are not applicable to skill / agent markdown files. Validation is performed by running the plugin against itself or a representative sample project and observing the produced artifacts.

### Verification workflow

- Each significant feature produces a `verification.md` report under `.forge/features/<slug>/` [high] [code]
- Report captures: kind detection result, artifact compliance checks, preserve-block survival, Success Criteria coverage [high] [code]
- Before shipping a new SKILL.md change, run `/forge:<skill>` against the forge repo itself as smoke test [medium] [readme]

### Evidence levels by change type

- **Skill behaviour change (SKILL.md Process / IRON RULES):** require new `verification.md`
- **Profile / reference file change:** may share existing verification (document which one)
- **Bugfix:** add a reproduction case to the relevant verification.md
- **Pure docs change (README, CLAUDE.md):** no verification needed

### Known LLM behavior quirks (v0.4.0 + v0.5.0 lessons)

When verifying skill changes via Skill tool invocation, observed quirks:
- **Session-level prompt cache:** Claude Code's Skill tool may cache skill content within a session; file edits to SKILL.md may not be picked up until a fresh session [medium] [code]
- **Training-data fallback:** sub-agents may default to "familiar" behavior (e.g. old `/forge:calibrate` next-step) even when the current SKILL.md explicitly forbids it. Stronger IRON RULES + explicit "Common LLM trap" warnings help but don't fully solve [medium] [code]
- **Remedy:** when Skill tool produces incorrect output, verify manually as main agent (with knowledge of the new SKILL.md) — this is pragmatic for development, but a fresh Claude Code session provides the truest verification [medium] [readme]

### What to avoid

- Declaring a skill "works" without running it
- Skipping verification because "the change is small"
- Trusting human walkthrough alone as sufficient proof — v0.4.0 T015/T012a/T012b showed LLM interpretation differs from human walkthrough

<!-- /forge:onboard section="testing-strategy" -->
