---
name: data-flows
section: Key Data Flows
applies-to:
  - web-backend
  - claude-code-plugin
  - monorepo
confidence-signals:
  - at least one entry point identified (prerequisite)
  - README describes user journeys
  - E2E test files document flows
token-budget: 1000
---

# Profile: Key Data Flows

## Scan Patterns

Data flows are **synthesized**, not directly scanned. This profile depends on output from:

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
2. **3–5 steps per flow** — this is a map, not a call graph. Detailed tracing belongs in
   `/forge:clarify`, not onboard.
3. **Format: `Entry → Step → Step → Outcome`** — arrow-separated.
4. **Start with the trigger** — HTTP verb + path / CLI command / event topic.
5. **If the project is too small to have non-trivial flows** (e.g. utility library),
   state "This project has no multi-step flows" and omit the flow list.
6. **For claude-code-plugin kind** — flows are skill-to-skill artifact dependencies
   (e.g. `onboard → calibrate → clarify → design → tasking → code`).

## Section Template

```markdown
## Key Data Flows

1. **User login**: `POST /auth/login` → validate credentials against `users` table →
   issue JWT → set HttpOnly cookie → return 200 [high]

2. **Order checkout**: `POST /orders` → validate cart → reserve inventory (redis lock)
   → create `orders` row → publish `order.created` → return 201 with order ID [medium]

3. **Payment reconciliation**: hourly cron → fetch unreconciled orders →
   call payment provider → update order status → publish `order.settled` [medium]
```

For **claude-code-plugin** kind, use this form instead:

```markdown
## Key Data Flows

1. **Skill pipeline**: `/forge:onboard` produces `.forge/context/onboard.md` →
   `/forge:calibrate` reads onboard.md + samples code → produces
   `.forge/context/conventions.md` (+ 3 other context files) →
   `/forge:clarify <feature>` reads conventions + explores code → produces
   `.forge/features/{slug}/clarify.md`
```

## Confidence Tags

- `[high]` — all steps verified against entry-points + module-map outputs
- `[medium]` — end-to-end logical flow, intermediate step inferred
- `[low]` — flow described in README but not verified in code
- `[inferred]` — guessed; avoid in this profile's output
