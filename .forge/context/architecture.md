# Architecture: forge

> Kind:      plugin
> Generated: 2026-04-23
> Commit:    9dbca95
> Generator: /forge:onboard (v0.5.0-dev)

<!-- forge:onboard source-file="architecture.md" section="architecture-layers" profile="context/dimensions/architecture-layers" verified-commit="9dbca95" body-signature="395a16e6043e9fb8" generated="2026-04-23" -->

## Architecture Layers

**Model:** Skill / Agent / Script / Artifact (四层架构)

**Layers:**
- `skills/<name>/SKILL.md` — Skill layer: instruction files for the main agent; each skill is self-contained [high] [code]
- `agents/<name>.md` — Sub-agent layer: specialized agents with limited tool sets, spawned by skills [high] [code]
- `skills/<name>/scripts/*.mjs` — Script layer: deterministic Node.js helpers invoked via Bash; no LLM [medium] [code]
- `.forge/<path>.md` — Artifact layer: persistent structured context produced and consumed by skills [high] [code]

**Composition rules:**
- Skill may spawn sub-agents (via Agent tool call) [high] [code]
- Skill may invoke scripts via Bash [high] [code]
- Skill reads/writes artifacts per its declared output contract [high] [code]
- Agent does NOT write artifacts directly; it returns report text to the skill [high] [code]
- Skills do not call other skills directly; the `forge` orchestrator routes between them [high] [code]

**Kind awareness (onboard-specific):**
- `profiles/kinds/<kind-id>.md` — Stage-2 kind definitions driving onboard.md composition [high] [code]
- `profiles/context/kinds/<kind-id>.md` — Stage-3 kind definitions driving context file composition [high] [code]
- `profiles/{category}/*.md` — Stage-2 profile templates (one per output section) [high] [code]
- `profiles/context/dimensions/*.md` — Stage-3 dimension templates (one per convention dimension) [high] [code]

**What to avoid:**
- Agent directly writing to `.forge/` (violates agent-skill boundary) [high] [code]
- Skills bypassing `status.mjs` in the forge orchestrator [high] [code]
- Cross-skill imports (each skill is a self-contained prompt document) [high] [code]
- Putting business logic in the orchestrator (`forge`) that belongs in a specific skill [medium] [code]

<!-- /forge:onboard section="architecture-layers" -->
