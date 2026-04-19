---
name: onboard
description: |
  Generates a human-readable project map for anyone new to the codebase.
  Use when starting work on an unfamiliar project, onboarding a new team
  member, or beginning a new Claude Code session on an existing codebase.
  Run this before /forge:calibrate.
argument-hint: ""
allowed-tools: "Read Glob Grep Bash"
context: fork
agent: Explore
model: sonnet
effort: high
---

## Runtime snapshot
- Root contents: !`ls -1 2>/dev/null`
- Existing .forge artifacts: !`ls .forge/context/ .forge/features/ 2>/dev/null || echo "(none)"`
- Source file counts: !`echo "Java: $(find . -name '*.java' 2>/dev/null | grep -v '.git' | grep -v build | wc -l | tr -d ' ') | TS: $(find . -name '*.ts' 2>/dev/null | grep -v node_modules | grep -v '.git' | wc -l | tr -d ' ') | Go: $(find . -name '*.go' 2>/dev/null | grep -v '.git' | wc -l | tr -d ' ')"`
- Controller/Handler count: !`find . \( -name '*Controller*' -o -name '*Handler*' -o -name '*Router*' \) -name '*.java' -o -name '*.ts' -o -name '*.go' 2>/dev/null | grep -v '.git' | grep -v build | grep -v test | wc -l | tr -d ' '` files
- Listener/Consumer count: !`find . \( -name '*Listener*' -o -name '*Consumer*' -o -name '*Subscriber*' \) -name '*.java' -o -name '*.ts' -o -name '*.go' 2>/dev/null | grep -v '.git' | grep -v build | wc -l | tr -d ' '` files

---

## IRON RULES

These rules have no exceptions.

- **Never describe a module from its directory name alone.** Read at least one substantive source file per module before writing its description.
- **Entry point counts are mandatory.** If a section lists listeners, controllers, or consumers, state the total count ("28 listeners total, 6 representative examples below") — do not silently list only a subset.
- **Sub-systems must be listed separately.** If a sub-directory has its own complete adapter/service/repository layering (not just a few helper files), it is its own module entry — never fold it into its parent.
- **URL versioning inconsistency must be noted explicitly.** If some routes use `/api/v2/` and others use `/api/`, state this in the Notes section rather than picking one and ignoring the other.
- **Never copy-paste from README without verifying against code.** READMEs are often stale. Confirm claims against actual build files and source.
- **Local development commands must come from actual config files** (Makefile, package.json scripts, build.gradle tasks) — not invented.

---

## Prerequisites

None. This is the first skill in the Forge workflow and has no dependencies.

If `.forge/context/onboard.md` already exists, show the user:
```
[forge:onboard] Existing onboard artifact found

.forge/context/onboard.md was last generated on {date from file header}.

Options:
1. Regenerate (overwrites existing)
2. View existing and exit

Which do you prefer?
```

---

## Process

### Step 1 — Identify project type and root

Determine what kind of project this is:
- **Monorepo**: multiple packages / services under one root (look for
  `packages/`, `apps/`, `services/`, `libs/` directories, or workspace
  config in `package.json` / `pnpm-workspace.yaml` / `lerna.json`)
- **Single application**: one deployable unit
- **Library / SDK**: published package with no runtime server

For monorepos, list each package/service as its own module entry.

### Step 2 — Read configuration files

Scan the project root and common config locations for:

| File | Information to extract |
|------|----------------------|
| `package.json` / `package-lock.json` | Language (Node.js), framework, scripts, main dependencies |
| `pom.xml` / `build.gradle` | Language (Java/Kotlin), framework, dependencies, exposed ports |
| `go.mod` | Language (Go), module name, major dependencies |
| `Cargo.toml` | Language (Rust), crate type, dependencies |
| `pyproject.toml` / `setup.py` / `requirements.txt` | Language (Python), dependencies |
| `Makefile` | Build, test, run targets |
| `docker-compose.yml` / `docker-compose.yaml` | Services, ports, infrastructure dependencies |
| `.env.example` / `.env.sample` | Required environment variables |
| `Dockerfile` | Runtime environment, exposed ports |
| `README.md` | Project description, setup instructions (verify before using) |
| `CLAUDE.md` | Project-specific AI guidance (high priority — read fully) |

### Step 3 — Identify entry points

Scan for all places where the system receives work. For each type, **count
the total** first, then select representative examples.

**HTTP / REST APIs:**
- Grep for `@Controller`, `@RestController`, `@RequestMapping`, `router.get`,
  `app.post`, `func.*Handler`, or equivalent
- Count total controller/handler files
- Extract base URL patterns and main route groups
- Note any URL versioning inconsistency (`/api/` vs `/api/v2/`)

**Message consumers / event listeners:**
- Grep for `@EventListener`, `onApplicationEvent`, `@KafkaListener`,
  `@RabbitListener`, `consumer.subscribe`, or equivalent
- **Count the total number** — this is critical for understanding system complexity
- List 5–8 representative examples

**Background jobs / schedulers:**
- Grep for `@Scheduled`, `cron.schedule`, `setInterval`, job definitions
- List each with its schedule/trigger

**CLI commands:**
- Look for command definitions (`commander`, `cobra`, `click`, `argparse`)

**GraphQL / gRPC:**
- Look for schema definitions and resolver/handler registration

For each entry point type found, state the total count and then list
representative examples with file paths.

### Step 4 — Map modules and services

For monorepos: list each package/service with its path and one-line purpose.

For single applications: identify the main internal modules or layers.

**Critical: detect sub-systems.** A sub-system is a sub-directory that has
its own complete layering (e.g. its own controllers, services, and
repositories). Common in legacy monoliths. Each sub-system gets its own
row in the module map — never fold it into the parent module.

Read at least one representative file from each module or sub-system to
verify the description is accurate before writing it.

### Step 5 — Extract local development commands

Find and verify:
- How to install dependencies
- How to run the application locally (note the port)
- How to run tests (all tests, and a single test class/file)
- How to build for production
- How to run linting / formatting
- Any prerequisite infrastructure setup (Docker commands, DB creation)

Source these from `Makefile`, `package.json` scripts, `build.gradle` tasks,
or README. If a README command cannot be verified in a config file, flag it
as "unverified."

### Step 6 — Identify key data flows

Choose 2–3 of the most important or representative end-to-end flows.
Describe each in 3–5 steps (not full call chains — those belong in clarify).
Include at least one flow that crosses a significant system boundary
(external API call, message queue, database write).

### Step 7 — Self-check

Before writing the artifact, verify:

- [ ] Every module entry was verified by reading ≥1 source file
- [ ] Entry point totals (not just examples) are stated for listeners/consumers
- [ ] Sub-systems with their own layering are listed as separate modules
- [ ] URL versioning inconsistency (if any) is noted
- [ ] Local dev commands were sourced from actual config files
- [ ] Notes section contains at least one non-obvious gotcha

If any checkbox fails, address it before writing.

### Step 8 — Write the onboard artifact

Write `.forge/context/onboard.md` following the output template below.

---

## Output

**File:** `.forge/context/onboard.md`

See [output-template.md](reference/output-template.md) for the complete artifact template.

---

## Interaction Rules

- If CLAUDE.md exists, read it fully — it may contain corrections to what
  you would otherwise infer.
- If a section has no data (e.g. no CLI entry points), omit that section
  rather than writing "None."
- After writing the artifact, summarise what was found in 2–3 sentences and
  suggest the next step (`/forge:calibrate`).

---

## Constraints

- Do not modify any source files. This skill is strictly read-only.
- Do not guess at project purpose from directory names alone — read at least
  one substantive file before describing what a module does.
- Do not list every file or every route — this is a map, not an inventory.
  Aim for the 20% of information that gives 80% of orientation.
