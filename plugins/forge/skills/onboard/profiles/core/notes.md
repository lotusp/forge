---
name: notes
section: Notes
applies-to:
  - web-backend
  - claude-code-plugin
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
