# Upgrading Forge from 0.4.x to 0.5.0

> **TL;DR:** Pipeline shrunk from 9 skills to 7. `calibrate` and `tasking`
> are gone — absorbed into `onboard` and `design` respectively. Your old
> `.forge/` artifacts smart-merge automatically on the next `/forge:onboard`
> run; no manual migration needed.

---

## What changed

### Pipeline consolidation (9 → 7 skills)

| Before (v0.4.x) | After (v0.5.0) |
|-----------------|----------------|
| `onboard → calibrate → clarify → design → tasking → code → inspect → test` (8 steps) | `onboard → clarify → design → code → inspect → test` (6 steps) |
| Plus `forge` orchestrator (9 total) | Plus `forge` orchestrator (7 total) |

- `/forge:calibrate` is **removed**. Its responsibilities (convention
  extraction across 4 context files) are now **Stage 3** of `/forge:onboard`.
- `/forge:tasking` is **removed**. Its responsibility (task decomposition
  into `plan.md`) is now **Stage 4** of `/forge:design`.

### Full kind-awareness

Where v0.4.x made `onboard.md` kind-aware, v0.5.0 extends kind-awareness to
**all context files** (conventions / testing / architecture / constraints).
A `claude-code-plugin` kind project no longer produces a Logging section
that doesn't apply; a `web-backend` project no longer produces a
Skill-Format section.

### New quality gates

- **clarify** — every Q is classified `[WHAT]` or `[HOW]`; `[HOW]` items
  auto-route to `design-inputs.md`. Before writing, a 5-check self-review
  runs and can trigger up to 3 revise iterations.
- **design** — mandatory 3-scenario Walkthrough, mandatory Wire Protocol
  Literalization for any persistence/API/message format, mandatory
  embedded spec-review against `clarify.md` Success Criteria and Gaps
  (hard block on coverage gaps; rollback permitted to decision level).
- **design** — produces both `design.md` and `plan.md` in one run.
- **code** — first-time Step 0.5 checks for convention gaps and asks a
  focused Q&A if needed; answers persist to `conventions.md § Development
  Workflow`.
- **inspect** — now requires a `<feature-slug>` argument (file-path mode
  removed); scope is deterministically enumerated from `plan.md` + task
  summaries.

### Artifact format changes

Section markers now carry **6 attributes** (was 5):

```
<!-- forge:onboard source-file="conventions.md" section="naming" profile="context/dimensions/naming" verified-commit="a3f2c1d4" body-signature="9f8e7d6c5b4a3210" generated="2026-04-23" -->
```

- New: `source-file` — identifies which artifact file the section belongs
  to (so incremental mode can route per-file)
- Split: the old single `verified=<hash>` is now two attributes:
  - `verified-commit` — git short-hash (primary fast-skip signal)
  - `body-signature` — SHA-256 of canonicalized body (tamper-detect)

`onboard.md` headers now include an `Excluded-dimensions:` line listing
the dimensions that this kind deliberately skipped (compensates for
R12's silent-omission approach).

---

## How to upgrade

### Step 1 — Update the plugin

```bash
# Inside Claude Code:
/plugin update forge
```

The marketplace will pull v0.5.0. Verify with:

```bash
/skills
# Expect 7 forge:* skills (no calibrate, no tasking)
```

### Step 2 — Re-run onboard on your existing project

```bash
# Inside Claude Code:
/forge:onboard
```

This triggers **Mode B incremental** (not a full regenerate):

- Existing `onboard.md` is smart-merged into the new 6-attribute marker
  format. Any `<!-- forge:preserve -->` blocks survive verbatim.
- Existing `conventions.md` / `testing.md` / `architecture.md` /
  `constraints.md` are smart-merged into the new kind-aware layout.
  Sections that no longer apply to your kind (e.g. Logging in a plugin
  project) move to a `## Legacy Notes` appendix — **not deleted**.
- New Stage 3 scan runs; any convention conflicts batch-resolve in one
  interactive prompt.

If you prefer a clean regeneration:

```bash
/forge:onboard --regenerate
```

Preserve blocks still survive.

### Step 3 — Verify

```bash
ls .forge/context/
# Expect: onboard.md + the subset of
# {conventions,testing,architecture,constraints}.md applicable to your
# project's kind.
```

Open `onboard.md` — its header should include an `Excluded-dimensions:`
line enumerating skipped dimensions.

---

## Breaking changes detail

### `/forge:calibrate` removed

**If your workflow invoked it explicitly:** stop doing so. The work now
happens automatically in `/forge:onboard` Stage 3. If you want to
re-extract conventions without re-mapping the project, use:

```bash
/forge:onboard --section=<dimension-name>
```

### `/forge:tasking` removed

**If your workflow invoked it explicitly:** stop doing so. `/forge:design`
now produces `plan.md` automatically as its Stage 4 output.

If you want to regenerate `plan.md` without re-designing, **currently
not supported**; run the full `/forge:design <slug>` again (it will
re-run Stages 1–4 but should produce identical outputs if nothing
substantive changed).

### `/forge:inspect <file-path>` removed

**Before (v0.4.x):** `/forge:inspect src/auth/phone.ts`

**After (v0.5.0):** `/forge:inspect <feature-slug>` only. Inspect now
enumerates changed files deterministically from `plan.md` + task
summaries.

If you want to review an ad-hoc file not tied to a feature, use
a generic code-review tool — this is outside forge's current scope.

### Section marker format

Any tooling that parsed the old 5-attribute markers needs to handle the
new 6-attribute format. The new format is strictly additive (`source-file`
added, `verified` split into `verified-commit` + `body-signature`).

The first `/forge:onboard` run after upgrade rewrites all markers to the
new format.

---

## Rollback

If something breaks and you need to return to v0.4.x:

```bash
# Inside Claude Code:
# Pin the plugin source to v0.4.0 tag in ~/.claude/settings.json:
"forge": {
  "source": {
    "source": "url",
    "url": "https://github.com/lotusp/forge.git#v0.4.0"
  }
}
# Then:
/plugin update forge
```

Your `.forge/` artifacts from v0.5.0 will not be fully compatible with
v0.4.x — specifically the 6-attribute markers and new `Excluded-dimensions:`
header — but v0.4.x will regenerate them on the next `/forge:onboard` run.

---

## Questions / issues

See [`.forge/features/lean-kind-aware-pipeline/`](../.forge/features/lean-kind-aware-pipeline/)
for the full design, plan, and verification record of this release.

For bug reports: https://github.com/lotusp/forge/issues
