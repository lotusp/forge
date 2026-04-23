# Architecture: forge

> Kind:                 claude-code-plugin
> Generated:            2026-04-23
> Commit:               59836a2
> Generator:            /forge:onboard Stage 3 (v0.5.0-dev)
> Dimensions loaded:    architecture-layers

---

<!-- forge:onboard source-file="architecture.md" section="architecture-layers" profile="context/dimensions/architecture-layers" verified-commit="59836a2" body-signature="c8b13e6af27905d4" generated="2026-04-23" -->

## Architecture Layers

**Model:** Skill / Agent / Script / Artifact 四层

**Layers (top → bottom):**

- `skills/<name>/SKILL.md` — skill layer (instructions for main agent) [high] [code]
- `agents/<name>.md` — sub-agent layer (specialized, tools limited) [high] [code]
- `skills/<name>/scripts/*.mjs` — script layer (deterministic helpers, no LLM) [medium] [code]
- `.forge/<path>.md` — artifact layer (persistent structured context) [high] [code]

**Composition rules:**

- Skill may spawn agents (declared via `Agent` tool in SKILL.md's `allowed-tools`) [high] [code]
- Skill may invoke scripts via `Bash` [high] [code]
- Skill reads/writes artifacts per its declared `## Output` contract [high] [code]
- Agent does NOT write artifacts; returns report text to calling skill [high] [code]
- Script is deterministic, no LLM — for routing decisions (`status.mjs`) or data validation [high] [code]

### Marketplace-plugin composition

forge's repo structure nests plugin content under `plugins/forge/` to satisfy the Claude Code marketplace model:

```
forge/                              ← marketplace repo root
├── .claude-plugin/
│   └── marketplace.json            ← marketplace manifest
└── plugins/
    └── forge/                      ← the actual plugin
        ├── .claude-plugin/
        │   └── plugin.json         ← plugin manifest
        ├── skills/
        └── agents/
```

Users install via `extraKnownMarketplaces` pointing to the repo URL; Claude Code resolves the plugin from `plugins/forge/`. [high] [build]

### v0.5.0 pipeline consolidation

Skill dependency graph (7 skills):

```
onboard  ──→ clarify  ──→ design  ──→ code (loop) ──→ inspect  ──→ test
                                                         │
                           ┌─────────────────────────────┘
                           ▼
              (feedback if needs-work)
```

`forge` orchestrator is cross-cutting: reads all artifact states, routes to correct skill. [high] [code]

### What to avoid

- Agent directly writing to `.forge/` (violates agent-skill boundary)
- Skills bypassing `status.mjs` (the routing authority for orchestrator)
- Cross-skill imports (each skill is self-contained prompt — no shared "lib")
- Modifying `.forge/` artifacts from inside skill scripts (scripts read-only to artifacts)

<!-- /forge:onboard section="architecture-layers" -->
