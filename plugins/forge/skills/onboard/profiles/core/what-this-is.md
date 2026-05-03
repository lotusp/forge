---
name: what-this-is
section: What This Is
applies-to:
  - web-backend
  - web-frontend
  - plugin
  - monorepo
confidence-signals:
  - README.md present
  - top-level package / module structure observable
  - build manifest with `name` / `description` fields
token-budget: 400
---

# Profile: What This Is

## Scope

The opening section of every generated artifact. Two short paragraphs of
plain prose that let a non-technical reader (or an AI agent on first
contact) form an accurate mental model of the project in under a minute.

Synthesised primarily from current-repo evidence:

- top-level directory layout (`src/`, `services/`, `cmd/`, ...)
- build manifest project name / description (`build.gradle` `rootProject.name`,
  `pom.xml` `<artifactId>` + `<description>`, `package.json` `name` + `description`,
  `Cargo.toml` `[package]`, `pyproject.toml` `[project]`)
- a single skim of `README.md` (if non-empty)
- `CLAUDE.md` project description (if present, secondary)

## Extraction Rules

1. **Two paragraphs maximum.** Paragraph 1: what the project IS and who
   uses it. Paragraph 2: deployment shape + primary stack at a glance +
   what it does NOT own.

2. **No bullet lists, no tables, no fenced code blocks.** Plain prose
   only. This section is the human-facing "elevator pitch" of the
   artifact.

3. **No precise inventory numbers.** This section is exempt from R10
   per-fact tag enforcement (Step 3.2 narrative exemption), but precise
   counts (`645+ mapped endpoints`, `~80 Feign clients`, `40+ controllers`)
   are FORBIDDEN here — they would let authors bypass the entire
   evidence pipeline. Use qualitative wording instead:

   - ✅ "exposes a large REST API surface"
   - ✅ "many Feign-based downstream calls"
   - ✅ "non-trivial controller count"
   - ❌ "645+ mapped endpoints across 40+ controllers"

   `check5b_unanchored_numbers.sh` enforces this with a hard halt
   (exit 2) when a precise inventory number appears inside the
   `what-this-is` section range.

4. **README.md / CLAUDE.md / org docs are SECONDARY evidence.** If they
   are not corroborated by current-repo files, soften the language and
   surface the inconsistency under Notes (or a `[conflict]` flag in
   another section). Never let stale README content silently shape the
   first impression.

5. **Empty README → say so.** If `README.md` is missing, empty, or
   under 200 bytes, mention this fact in paragraph 2 alongside the
   deployment-shape sentence. New maintainers should know the
   onboarding doc is thin.

## Section Template

The body is plain prose; no marker-internal structure. The wrapping
forge:onboard marker is still required (R9), with `profile=core/what-this-is`:

```markdown
<!-- forge:onboard source-file="onboard.md" section="what-this-is" profile="core/what-this-is" verified-commit="<sha>" body-signature="<16hex>" generated="<YYYY-MM-DD>" -->

## What This Is

<paragraph 1: name, what it is, who uses it, what it owns>

<paragraph 2: deployment shape, primary technology stack at a glance,
key boundaries / what it does NOT own>

<!-- /forge:onboard section="what-this-is" -->
```

## Confidence Tags

This section is the R10 narrative exemption (Step 3.2): individual
sentences do NOT carry per-fact `[high]` / `[medium]` / `[code]` tags.
Tags belong on tabular / list facts in subsequent sections (`Tech
Stack`, `Module Map`, ...).

The expected reader can decode bracket annotations elsewhere via the
`Tag legend:` line in the artifact header (Step 3.1).

## Common Errors (LLM trap log)

- **Marker `profile="core/tech-stack"`** — observed in v0.5.1 outputs;
  the marker MUST use `profile="core/what-this-is"` (this profile).
- **No marker at all** — observed in v0.5.1 biz-svc-b output;
  Step 6.5 Check 1 will hard-halt this on the next regenerate.
- **Inventory numbers leaked in** — `645+ mapped endpoints`-style
  phrasing is hard-halted by check5b. Replace with qualitative wording
  before re-running.
