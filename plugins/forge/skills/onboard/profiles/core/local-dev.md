---
name: local-dev
section: Local Development
applies-to:
  - web-backend
  - web-frontend
  - plugin
  - monorepo
confidence-signals:
  - Makefile present
  - package.json scripts block
  - README.md "Getting Started" / "Development" section
  - justfile / Taskfile.yml / mise.toml
token-budget: 1000
---

# Profile: Local Development

## Scan Patterns

**Command sources (priority order):**

1. `Makefile` — targets
2. `package.json` `scripts` field
3. `pyproject.toml` `[tool.poetry.scripts]` / `[project.scripts]`
4. `justfile` / `Taskfile.yml` / `mise.toml`
5. `README.md` — `## Development` / `## Getting Started` / `## Running` sections

**Required commands to extract:**

- Install dependencies
- Run locally
- Run all tests
- Run a single test file
- Build for production
- Lint / format

## Extraction Rules

1. **Prefer the project's own conventions** — if README says `npm run dev`, use that even
   if `make dev` also exists.
2. **One canonical command per action** — if multiple equivalent commands exist, pick the
   one appearing in the project's own documentation.
3. **Never infer commands not in any source file** — if no build command is documented,
   omit the "Build" row rather than guess.
4. **Include prerequisites inline** — if setup requires `.env` copy or `docker compose up`
   first, note it.
5. **Format all commands as shell code blocks**, one block per section.

## Section Template

````markdown
## Local Development

### Prerequisites
- Copy `.env.example` → `.env` and fill in required values [high]
- Start infrastructure: `docker compose up -d postgres redis` [high]

### Commands

```bash
# Install dependencies
pnpm install

# Run locally
pnpm dev

# Run all tests
pnpm test

# Run a single test file
pnpm test path/to/file.test.ts

# Build for production
pnpm build

# Lint / format
pnpm lint && pnpm format
```
````

If any action has no documented command, **omit that line** — do not write "N/A" or
"See README".

## Confidence Tags

- `[high]` — command verified in Makefile / scripts / documented README section
- `[medium]` — command exists in config but not documented in README
- `[low]` — inferred from convention (e.g. "pnpm test" assumed because pnpm-lock exists)
- `[inferred]` — guessed entirely; should not appear in this profile's output
