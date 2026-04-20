---
name: forge
description: |
  Master orchestrator for the Forge workflow. Detects the current project
  state, interprets your intent, and runs the right skill automatically.
  Use this instead of calling individual skills directly.
argument-hint: "[feature description, feature-slug, task-id, or blank to continue]"
allowed-tools: "Read Glob Grep Bash"
model: sonnet
effort: high
---

## Runtime snapshot
- Onboard: !`test -f .forge/context/onboard.md && echo "✓" || echo "✗ missing"`
- Conventions: !`test -f .forge/context/conventions.md && echo "✓" || echo "✗ missing"`
- Features: !`ls .forge/features/ 2>/dev/null | tr '\n' ', ' || echo "(none)"`
- Features with clarify: !`ls .forge/features/*/clarify.md 2>/dev/null | sed 's|.forge/features/||;s|/clarify.md||' | tr '\n' ', ' || echo "(none)"`
- Features with design: !`ls .forge/features/*/design.md 2>/dev/null | sed 's|.forge/features/||;s|/design.md||' | tr '\n' ', ' || echo "(none)"`
- Features with plan: !`ls .forge/features/*/plan.md 2>/dev/null | sed 's|.forge/features/||;s|/plan.md||' | tr '\n' ', ' || echo "(none)"`
- Completed tasks: !`ls .forge/features/*/tasks/T*-summary.md 2>/dev/null | grep -oE 'T[0-9]+' | tr '\n' ', ' || echo "(none)"`
- Inspect results: !`ls .forge/features/*/inspect.md 2>/dev/null | sed 's|.forge/features/||;s|/inspect.md||' | tr '\n' ', ' || echo "(none)"`
- Status script: !`find ~/.claude -name "status.mjs" -path "*/forge/scripts/*" 2>/dev/null | head -1 || echo "(not found — will use manual detection)"`
- Recent activity: !`tail -30 .forge/JOURNAL.md 2>/dev/null || echo "(no journal yet — first session)"`

---

## IRON RULES

These rules have no exceptions. Do not rationalise around them.

- **The status script determines the next action — not your inference.** Run the status script (found via `find ~/.claude -name "status.mjs" -path "*/forge/scripts/*"`) and follow the `[ACTION]` line exactly. Never decide the next step from memory or context alone.
- **Never skip onboard or calibrate.** If `[ACTION]` says `skill=onboard` or `skill=calibrate`, that is the only valid next step regardless of what the user asked for.
- **Never chain skills without user confirmation.** After each skill completes, ask "Continue to the next step?" before proceeding. Never auto-chain silently.
- **Never invent feature state.** If `.forge/features/` is empty or a feature has no artifacts, report it accurately — do not assume a prior step was done.
- **When executing a sub-skill, read its full SKILL.md first.** Do not execute from memory. Read `{SKILLS}/SKILL_NAME/SKILL.md` before starting its process.
- **If the user says "just proceed" or "continue", re-run the status script** — do not continue from your own last remembered state.

---

## Path variables (relative to this skill's directory)

| Variable | Path | Contents |
|----------|------|----------|
| `{SKILLS}` | `..` | Parent directory — all sibling skill folders |
| `{REFERENCE}` | `reference` | State machine and routing reference docs |

Use these when reading sub-skill files:
- `{SKILLS}/onboard/SKILL.md`
- `{SKILLS}/calibrate/SKILL.md`
- `{SKILLS}/clarify/SKILL.md`
- `{SKILLS}/design/SKILL.md`
- `{SKILLS}/tasking/SKILL.md`
- `{SKILLS}/code/SKILL.md`
- `{SKILLS}/inspect/SKILL.md`
- `{SKILLS}/test/SKILL.md`

---

## Prerequisites

Read `{REFERENCE}/state-machine.md` to understand the workflow transitions
before reading the runtime snapshot or processing any argument.

---

## Process

### Step 1 — Run the status script

First, locate the status script:
```bash
FORGE_STATUS=$(find ~/.claude -name "status.mjs" -path "*/forge/scripts/*" 2>/dev/null | head -1)
echo "Status script: ${FORGE_STATUS:-not found}"
```

If found, run it with flags based on the user's argument (`$ARGUMENTS`):
- Argument looks like a task ID (`T001`, `T023`): `node "$FORGE_STATUS" --task T001`
- Argument matches an existing slug in `.forge/`: `node "$FORGE_STATUS" --feature {slug}`
- Argument is free-text description: `node "$FORGE_STATUS" --intent "text"`
- No argument: `node "$FORGE_STATUS"`

Read the `[ACTION]` line at the end of the script's output. This line
is the authoritative routing decision.

If the script is not found or Node.js is unavailable, fall back to
Step 1b.

### Step 1b — Manual state detection (fallback)

If the status script is unavailable, manually inspect `.forge/`:

```bash
ls .forge/context/ .forge/features/ 2>/dev/null || echo "(no .forge/ directory)"
```

Then apply the routing rules from `reference/state-machine.md` to
determine the next action.

### Step 2 — Present the status dashboard

Show the script's output (the full table before the `[ACTION]` line)
to the user. This gives them a clear picture of where the project stands.

If the user's argument was a free-text description, confirm:
```
[FORGE] Interpreting your request as: start /forge:clarify for "{description}"
Is that correct? (yes / use a different slug)
```

### Step 3 — Handle the action

Based on the `[ACTION]` line:

**`skill=onboard`**
→ Explain: "Your project has not been mapped yet. Running /forge:onboard first."
→ Read `{SKILLS}/onboard/SKILL.md` and execute its process in full.

**`skill=calibrate`**
→ Explain: "No coding conventions have been extracted yet. Running /forge:calibrate first."
→ Read `{SKILLS}/calibrate/SKILL.md` and execute its process in full.

**`skill=clarify arg={text}`**
→ Read `{SKILLS}/clarify/SKILL.md` and execute its process with `{text}` as the feature description.

**`skill=design arg={slug}`**
→ Read `{SKILLS}/design/SKILL.md` and execute its process with `{slug}`.

**`skill=tasking arg={slug}`**
→ Read `{SKILLS}/tasking/SKILL.md` and execute its process with `{slug}`.

**`skill=code arg={task-id}`**
→ Read `{SKILLS}/code/SKILL.md` and execute its process with `{task-id}`.

**`skill=inspect arg={slug}`**
→ Read `{SKILLS}/inspect/SKILL.md` and execute its process with `{slug}`.

**`skill=test arg={slug}`**
→ Read `{SKILLS}/test/SKILL.md` and execute its process with `{slug}`.

**`skill=ask`** (no context detected, no argument)
→ Show the status dashboard and present:
```
[FORGE] What would you like to work on?

Options:
  1. Start a new feature — describe what you want to build
  2. Continue an existing feature — provide the feature slug
  3. Run a specific skill — onboard / calibrate / clarify / design /
                            tasking / code / inspect / test
  4. Show full workflow guide
```

**`skill=none`** (all features complete)
→ Congratulate and show the complete feature list.
→ Ask: "Start a new feature?"

### Step 4 — Execute the sub-skill

Read the target skill's SKILL.md fully before beginning its process.
Execute it as if it were invoked directly — follow all its Iron Rules,
process steps, interaction rules, and output instructions.

Present all output using the sub-skill's own format (e.g.,
`[forge:clarify]`, `[forge:calibrate]`, etc.) so the user knows which
skill is running.

### Step 5 — After the sub-skill completes

When the sub-skill finishes and has written its artifact, run the
status script again to get the updated state:

```bash
FORGE_STATUS=$(find ~/.claude -name "status.mjs" -path "*/forge/scripts/*" 2>/dev/null | head -1)
[ -n "$FORGE_STATUS" ] && node "$FORGE_STATUS" || ls .forge/
```

Then ask:
```
[FORGE] ✓ /forge:{completed-skill} done.

Next step: /forge:{next-skill} {next-arg}
  {reason from status script}

Continue? (yes / stop here / skip to a different skill)
```

Wait for the user's answer. Never proceed automatically.

If the user says "stop here", summarise what was accomplished and
what remains to complete the feature.

---

## Quick shortcuts

The user can pass explicit skill names as the argument to jump directly:

| Argument | Routes to |
|----------|-----------|
| `onboard` | /forge:onboard |
| `calibrate` | /forge:calibrate |
| `clarify {desc}` | /forge:clarify |
| `design {slug}` | /forge:design |
| `tasking {slug}` | /forge:tasking |
| `code {id}` | /forge:code |
| `inspect {slug}` | /forge:inspect |
| `test {slug}` | /forge:test |
| `status` | Show dashboard only, no action |

> **Artifact paths:** All project context lives under `.forge/context/` and
> all feature artifacts live under `.forge/features/{slug}/`. See
> `reference/state-machine.md` for the full path mapping.

---

## Interaction Rules

- Always show the status dashboard before executing anything.
- Keep routing decisions transparent: tell the user what skill you're
  about to run and why, before running it.
- If the user's request is ambiguous (e.g., "add the search feature"
  when a `search` slug already exists mid-workflow), surface the
  ambiguity and ask before routing.
- After each skill, always show what's next and ask to continue.

---

## Constraints

- Do not modify any source files directly. All source changes are
  delegated to /forge:code.
- Do not skip sub-skill confirmation steps — if /forge:tasking requires
  user confirmation before writing the plan, that confirmation still happens.
- Do not attempt to run multiple sub-skills in parallel. The workflow
  is sequential; each step must complete before the next starts.
