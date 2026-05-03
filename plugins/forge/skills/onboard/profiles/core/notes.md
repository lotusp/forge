---
name: notes
section: Notes
applies-to:
  - web-backend
  - web-frontend
  - plugin
  - monorepo
confidence-signals:
  - CLAUDE.md present (project-specific AI guidance)
  - TODO / FIXME / DEPRECATED markers in code
  - README.md "Known Issues" / "Caveats" sections
  - docs/ migration guides or upgrade notes
token-budget: 900
---

# Profile: Notes

## Scan Patterns

This profile captures **non-obvious context** that a new team member would want to know:

- Deprecated systems still in use
- Known tech debt hotspots
- External services that require credentials to test
- Gotchas (e.g. "this endpoint is dark-launched via header X")
- Project-specific conventions not captured elsewhere

**Sources:**

- `CLAUDE.md` — highest priority; read fully
- `README.md` — "Caveats", "Known Issues", "Troubleshooting" sections
- `docs/**/*.md` — migration guides, ADRs
- `TODO:` / `FIXME:` / `DEPRECATED:` / `HACK:` grep across source (count only, don't
  enumerate unless ≤ 5)

## Extraction Rules

1. **Signal over noise** — only surface items that would affect onboarding decisions.
   Skip trivia (style preferences, past refactor history).
2. **CLAUDE.md is authoritative** — if it contains project-specific guidance, pull the
   relevant bullets verbatim.
3. **Cap at 8 bullets** — if more items qualify, group or link to a docs file.
4. **Quantify debt, don't catalog it** — "~40 `TODO` markers, concentrated in
   `src/legacy/`" is more useful than listing each.
5. **Flag credential-gated dependencies** — services the dev cannot test without secrets.
6. **If no notable context exists** — omit the section entirely (do not output an empty
   "Notes" heading).

## Forensic Sweep (mandatory checks before render)

Before composing the Notes section, run a fixed checklist of "what
should be here but isn't" inspections. Any positive finding becomes a
bullet — do NOT silently swallow these. v0.5.1 review found multiple
projects that failed every one of these checks without any of them
being mentioned in Notes.

| Check (Bash one-liner approximation) | If true, surface as |
|--------------------------------------|----------------------|
| `[ -f README.md ] && [ $(wc -c < README.md) -lt 200 ]` | "README is essentially empty (size: {N} bytes); no project guidance from this source — new maintainers should not rely on it" `[high] [readme]` |
| `[ -f Dockerfile ] && [ $(wc -c < Dockerfile) -eq 0 ]` | "Dockerfile is 0 bytes — container build NOT verifiable from this repo alone" `[medium] [build]` |
| Spring `actuator` dep present AND `application*.yml` `management.endpoints.web.exposure.include` does NOT list a key referenced elsewhere | "actuator/<endpoint> dep is on classpath but exposure config does NOT list it — endpoint is NOT available in this build" `[medium] [config]` |
| `sonar.projectKey` ↔ `sonar.projectName` differ after normalising `:` ↔ `-` | "Sonar projectKey/projectName mismatch — likely typo (`{actual-key}` vs `{actual-name}`); silently breaks SonarQube history matching" `[high] [build] [conflict]` |
| MySQL Connector/J major version ≠ `application*.yml` `driver-class-name` style (e.g. connector 8.x but `com.mysql.jdbc.Driver` legacy class) | "Connector v{X} but runtime driver-class is legacy ({Y}) — version mismatch between dep and config" `[medium] [conflict]` |
| `0 @Entity` AND Spring Data JPA in deps AND no `exclude = {DataSourceAutoConfiguration.class}` | "Spring Data JPA in deps but no `@Entity` found — JPA may be unintentionally enabled with empty schema" `[medium] [code]` |
| `0 @MessageListener` AND Service Bus / Kafka / RabbitMQ starter in deps | "Messaging starter in deps but no inbound consumer detected — outbound only? Verify intent" `[medium] [build]` |
| `application*.yml` has `*_cron` / `cron:` keys AND `0 @Scheduled` annotations | "Cron config exists but no `@Scheduled` in code — service is likely triggered by an external scheduler via messaging queue" `[medium] [config]` |
| Test coverage threshold declared (`branchCoverage = 0.6` / similar) AND coverage exclusion list expands to >10 files | "Coverage threshold 60% applies to a denominator that excludes {N} core classes; effective coverage signal is weaker than the headline number" `[high] [build]` |

Implementation note: the v0.5.2-final mechanism for these checks lives
in profile prose (Stage 2 LLM grep). v0.5.3 will move them under
`scripts/detectors/forensic/` with executable scripts and a JSON output
contract.

## Section Template

```markdown
## Notes

- **Legacy payment path** in `src/legacy/payments/` is still reachable via feature flag
  `USE_LEGACY_PAYMENTS`. Do not extend; new work should use `src/payments/`. [high]
- **Stripe webhook handler** requires valid signing secret in `.env`. Local testing needs
  `stripe listen --forward-to localhost:3000/webhooks/stripe`. [high]
- **~40 TODO markers** concentrated in `src/legacy/` — tracked in
  `docs/tech-debt-register.md`. [medium]
- **CLAUDE.md** contains project-specific AI guidance; skills should read it before
  changing code in `src/core/`. [high]
- **Cron jobs** are registered in code but executed by an external scheduler
  (details in `infra/scheduler/README.md`). [medium]
```

## Confidence Tags

- `[high]` — sourced from CLAUDE.md or README with explicit statement
- `[medium]` — inferred from code markers + file structure
- `[low]` — single-source mention, not corroborated
- `[inferred]` — avoid in this profile's output (Notes should be grounded facts, not
  guesses)
