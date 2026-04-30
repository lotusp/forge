---
name: data-flows
section: Code Path Walkthroughs
applies-to:
  - web-backend
  - web-frontend
  - plugin
  - monorepo
confidence-signals:
  - at least one entry point identified (prerequisite)
  - README describes user journeys
  - E2E test files document flows
token-budget: 1000
---

# Profile: Code Path Walkthroughs

## Scan Patterns

Data flows are **evidence-bounded walkthroughs**, not business stories. This
profile depends on output from:

- `entry-points` profile (source of flow starts)
- `module-map` profile (intermediate hops)
- `http-api` / `event-consumers` profile (if loaded)

**Supplementary sources:**

- README.md — look for "How it works" / "Architecture" / "Flow" sections
- `docs/` markdown files with sequence diagrams
- E2E test names (`describe("order checkout flow", ...)`)

## Extraction Rules

1. **Pick 2–3 flows, not more** — the most representative user/system journeys.
   Criteria: touches multiple modules, has business significance, would be asked about
   during onboarding.
2. **Declare trace depth** for each flow:
   - `traced` — every step was verified in code
   - `sampled` — representative path followed, not exhaustive
   - `doc-described` — described in docs/tests but not fully traced
3. **3–5 steps per flow** — this is a navigation map, not a full call graph.
   Detailed tracing belongs in `/forge:clarify`, not onboard.
4. **Format as code navigation.** Use entry point, key calls/components, side
   effects, and unverified gaps. Do not write downstream business effects unless
   they were traced to concrete code or tests.
5. **Start with the trigger** — HTTP route / CLI command / event/message /
   scheduler / framework hook / user action, whichever is actually evidenced.
6. **If the project is too small to have non-trivial flows** (e.g. utility library),
   state "This project has no multi-step flows" and omit the flow list.
7. **For plugin kind** — flows are skill-to-skill artifact dependencies
   (e.g. `onboard → calibrate → clarify → design → tasking → code`).

## Section Template

```markdown
## Code Path Walkthroughs

### Create Order

Evidence level: traced [high] [code]

1. Entry: `POST /orders` in `OrderController` [high] [code]
2. Calls: `OrderService.create(...)` [high] [code]
3. Side effects: creates an order record and emits `OrderCreatedEvent` [high] [code]
4. Unverified gaps: downstream listeners were not exhaustively traced [medium] [code]

### Reconcile Payments

Evidence level: sampled [medium] [code]

1. Entry: scheduled job or message handler observed in code [medium] [code]
2. Calls: payment integration component [medium] [code]
3. Side effects: updates payment status [medium] [code]
4. Unverified gaps: retry and idempotency behavior not fully traced [medium] [code]
```

For **plugin** kind, use this form instead:

```markdown
## Code Path Walkthroughs

1. **First-run context bootstrap**: `/forge:onboard` (Stage 1) detects
   project kind → (Stage 2) produces `.forge/context/onboard.md` →
   (Stage 3) scans convention dimensions + batch-resolves conflicts +
   smart-merges → writes `.forge/context/conventions.md` + 3 other
   kind-applicable context files

2. **Feature pipeline**: `/forge:clarify <feature>` reads context files +
   explores code → produces `.forge/features/{slug}/clarify.md` →
   `/forge:design <slug>` produces `design.md` + `plan.md` together →
   `/forge:code T{NNN}` implements each task → `/forge:inspect <slug>`
   reviews → `/forge:test <slug>` generates tests
```

## Confidence Tags

- `[high]` — all steps verified against entry-points + module-map outputs
- `[medium]` — sampled flow or partially traced intermediate step
- `[low]` — flow described in README but not verified in code
- `[inferred]` — guessed; avoid in this profile's output
