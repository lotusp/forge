# Testing: forge

> Kind:      plugin
> Generated: 2026-04-23
> Commit:    9dbca95
> Generator: /forge:onboard (v0.5.0-dev)

<!-- forge:onboard source-file="testing.md" section="testing-strategy" profile="context/dimensions/testing-strategy" verified-commit="9dbca95" body-signature="ebf897f5819f5b97" generated="2026-04-23" -->

## Testing Strategy

**Testing paradigm:** Self-bootstrap verification

Traditional unit tests are not applicable to skill / agent markdown files. Verification is performed by running the plugin against itself (the forge repo) or a representative sample project and observing the produced artifacts.

### Verification workflow

- Each significant feature produces a `verification.md` report under `.forge/features/<slug>/` [high] [code]
- Report captures: kind detection result, artifact compliance checks, preserve-block survival, Success Criteria coverage [high] [code]
- Before shipping a new SKILL.md change, run `/forge:<skill>` against the forge repo itself as smoke test [medium] [readme]
- Existing verification reports: `plugin-bootstrap/`, `onboard-kind-profiles/`, `lean-kind-aware-pipeline/` [high] [code]

### Evidence level

- **Skill behaviour changes** — require new verification.md
- **Profile / reference file changes** — may share existing verification
- **Bugfix** — should add a reproduction case to the relevant verification.md

### Test scenarios

- `tests/scenarios/` directory contains scenario descriptions [medium] [cli]

### What to avoid

- Declaring a skill "works" without running it [high] [readme]
- Skipping verification because "the change is small" [high] [readme]
- Trusting human walkthrough as sufficient proof (only LLM execution matches real LLM misinterpretation patterns) [high] [readme]

<!-- /forge:onboard section="testing-strategy" -->
