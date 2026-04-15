---
name: onboard
description: |
  Generates a human-readable project map for anyone new to the codebase.
  Use when starting work on an unfamiliar project, onboarding new team
  members, or beginning a new Claude Code session on an existing codebase.
  Run this before /forge:calibrate.
argument-hint: ""
allowed-tools: "Read Glob Grep Bash"
model: sonnet
effort: high
---

## Prerequisites

None. This is the first skill in the Forge workflow and has no dependencies.

If `.forge/onboard.md` already exists, show the user:
```
[FORGE:ONBOARD] Existing onboard artifact found

.forge/onboard.md was last generated on {date from file header}.

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
| `pom.xml` / `build.gradle` | Language (Java/Kotlin), framework, dependencies |
| `go.mod` | Language (Go), module name, major dependencies |
| `Cargo.toml` | Language (Rust), crate type, dependencies |
| `pyproject.toml` / `setup.py` / `requirements.txt` | Language (Python), dependencies |
| `Makefile` | Build, test, run targets |
| `docker-compose.yml` / `docker-compose.yaml` | Services, ports, infrastructure dependencies |
| `.env.example` / `.env.sample` | Required environment variables |
| `Dockerfile` | Runtime environment, exposed ports |
| `kubernetes/` / `k8s/` / `helm/` | Deployment infrastructure |
| `terraform/` / `infra/` | Cloud infrastructure |
| `README.md` | Project description, setup instructions |
| `CLAUDE.md` | Project-specific AI guidance (high priority — read fully) |

### Step 3 — Identify entry points

Scan for the places where the system starts receiving work:

**HTTP / REST APIs:**
- Look for router definitions, Express/Fastify/Gin/Spring `@Controller` or
  equivalent
- Extract base URL patterns and main route groups

**GraphQL:**
- Look for schema definitions and resolver registration

**CLI:**
- Look for command definitions (`commander`, `cobra`, `click`, `argparse`)

**Workers / consumers:**
- Look for queue consumers, Kafka listeners, SQS handlers, cron schedulers

**Background jobs:**
- Look for job definitions, schedulers, cron expressions

**Events:**
- Look for event emitters and listeners (internal event bus or external)

For each entry point type found, note 3–5 representative examples with paths.

### Step 4 — Map modules and services

For monorepos: list each package/service with its path and one-line purpose.
For single applications: identify the main internal modules or layers (e.g.
controllers / services / repositories, or domain / application / infrastructure).

Read a small number of representative files from each module to verify the
description is accurate.

### Step 5 — Extract local development commands

Find and verify:
- How to install dependencies
- How to run the application locally
- How to run tests (all tests, single test, single file)
- How to build for production
- How to run linting / formatting

Prefer commands from `Makefile`, `package.json` scripts, or README.
If multiple options exist (e.g. `npm` and `make`), list the preferred one
based on which appears in the project's own documentation.

### Step 6 — Identify key data flows

Choose 2–3 of the most important or representative end-to-end flows.
Describe each in 3–5 steps (not full call chains — those belong in clarify).

Example: "User login: POST /auth/login → validate credentials → issue JWT → set cookie"

### Step 7 — Write the onboard artifact

Write `.forge/onboard.md` following the output template.

---

## Output

**File:** `.forge/onboard.md`

```markdown
# Project Onboard: {project-name}

> 生成时间：YYYY-MM-DD
> 生成方式：/forge:onboard

---

## What This Is

{One to two paragraphs describing the project's purpose, the business domain
it operates in, and its primary users. Non-technical readers should understand
this section.}

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Language | {e.g. TypeScript 5.x} |
| Runtime | {e.g. Node.js 20 / JVM 21} |
| Framework | {e.g. Express 4, Spring Boot 3} |
| Database | {e.g. PostgreSQL 15, MongoDB 6} |
| Cache | {e.g. Redis 7} |
| Message queue | {e.g. RabbitMQ, Kafka, SQS} |
| Infrastructure | {e.g. AWS ECS, Kubernetes, Railway} |
| Key libraries | {notable domain-specific libraries} |

---

## Module Map

{For monorepos:}
| Package / Service | Path | Responsibility |
|-------------------|------|----------------|
| `service-name` | `packages/service-name` | One sentence |

{For single apps — list internal layers or major modules:}
| Module | Path | Responsibility |
|--------|------|----------------|
| `ModuleName` | `src/module` | One sentence |

---

## Entry Points

### HTTP API
Base URL pattern: `{e.g. /api/v1}`
Representative routes:
- `POST /auth/login` — `src/routes/auth.ts`
- `GET /users/:id` — `src/routes/users.ts`

### CLI
- `{command}` — {what it does} (`src/cli/...`)

### Background Jobs
- `{job name}` — {schedule / trigger} (`src/jobs/...`)

### Event Consumers
- `{topic / queue}` — {what it handles} (`src/consumers/...`)

---

## Local Development

```bash
# Install dependencies
{command}

# Run locally
{command}

# Run all tests
{command}

# Run a single test file
{command}

# Build
{command}

# Lint / format
{command}
```

---

## Key Data Flows

1. **{Flow name}:** {step 1} → {step 2} → {step 3}
2. **{Flow name}:** {step 1} → {step 2} → {step 3}

---

## Notes

{Anything unusual, non-obvious, or important that a new team member should
know: deprecated systems still in use, known tech debt hotspots, gotchas,
external dependencies that need credentials to test, etc.}
```

---

## Interaction Rules

- If the project README contains a clear description, use it as a starting
  point for "What This Is" rather than inferring from scratch.
- If CLAUDE.md exists, read it fully — it may contain information that should
  be reflected in the Notes section or that corrects what you would otherwise
  infer.
- If a section has no data (e.g. no CLI entry points), omit that section
  rather than writing "None."
- After writing the artifact, summarise what was found in 2–3 sentences and
  suggest the next step (`/forge:calibrate`).

---

## Constraints

- Do not modify any source files. This skill is strictly read-only.
- Do not guess at project purpose from directory names alone — read at least
  one substantive file (README, main entry point, or core domain file) before
  describing what the project does.
- Do not list every file or every route — this is a map, not an inventory.
  Aim for the 20% of information that gives 80% of orientation.
