---
name: build-system
section: Build System
applies-to:
  - web-backend
  - web-frontend
  - monorepo
confidence-signals:
  - Makefile / build config files present
  - CI workflow files (.github/workflows/, .gitlab-ci.yml, etc.)
  - Dockerfile present
token-budget: 800
---

# Profile: Build System

## Scan Patterns

**Build tool detection:**

| Evidence | Tool |
|----------|------|
| `pnpm-workspace.yaml` / `turbo.json` | pnpm + Turborepo |
| `lerna.json` | Lerna |
| `nx.json` | Nx |
| `build.gradle` + `settings.gradle` | Gradle (multi-module) |
| `pom.xml` with `<modules>` | Maven multi-module |
| `go.work` | Go workspaces |
| `Cargo.toml` with `[workspace]` | Cargo workspaces |
| `Makefile` alone | custom make-based build |

**Artifact / output patterns:**

- `dist/` / `build/` / `target/` / `out/` (gitignored) → build output directory
- `docker-bake.hcl` / multi-stage Dockerfile → containerized build
- release scripts under `scripts/release*` or `.github/workflows/release.yml`

**CI integration:**

- `.github/workflows/*.yml` — GitHub Actions
- `.gitlab-ci.yml` — GitLab CI
- `Jenkinsfile` — Jenkins
- `.circleci/config.yml` — CircleCI
- `.buildkite/pipeline.yml` — Buildkite

## Extraction Rules

1. **Build tool** — one-line statement with version if pinned.
2. **Artifact shape** — what the build produces (jar / docker image / npm package /
   static bundle).
3. **CI summary** — list workflow files with one-line purpose each (build / test /
   release / deploy).
4. **Skip dev-only hot-reload tooling** unless it is the primary build path.
5. **If project has no build step** (pure-source library), state that and omit artifact
   rows.
6. **Field-pair consistency check.** When a build manifest contains a
   pair of fields that should mirror each other, extract both and
   compare verbatim. Mismatches surface under `Notes` (or
   `constraints.md` Current Business Caveats) tagged `[conflict]`:

   | Pair | File | Note |
   |------|------|------|
   | `sonar.projectName` ↔ `sonar.projectKey` | `build.gradle` / `pom.xml` | Spelling/typo detector — a prior review found a one-letter typo silently breaking SonarQube history matching |
   | `<artifactId>` ↔ `<name>` | `pom.xml` | Identity mirror |
   | `name` ↔ `description` | `package.json` | Sanity |
   | `bootJar.archiveBaseName` ↔ `bootJar.archiveFileName` | `build.gradle` | Artifact naming |

   **Sonar pair (v0.6).** `.forge/_session/facts.json` includes a
   top-level `sonar` object with `project_name`, `project_key`,
   `match`, `key_declaration_count`, `name_declaration_count`. These
   are literal facts (not counts) and are kept verbatim.

   When `match: false`, surface a `[conflict]` row in `Notes` quoting
   both projectKey and projectName verbatim. When
   `key_declaration_count > 1` or `name_declaration_count > 1`,
   surface a `[conflict]` row about the duplicate declaration. Both
   findings are also auto-appended by check8 if the LLM omits them.

   Eyeballing the comparison is forbidden; a prior real-world review
   missed a one-letter typo because the LLM read both lines as "the
   same thing" without character-level diff.

8. **Coverage-exclusion transparency.** When a
   `jacocoTestCoverageVerification` (or similar) block declares an
   exclusion list, expand the globs with `find` and report the total
   excluded file count next to the coverage threshold. A prior review
   found a project claiming "60% branch coverage" while the
   exclusion list silently dropped 30+ core classes from the
   denominator — readers MUST see this caveat next to the threshold.

## Section Template

```markdown
## Build System

- **Build tool:** pnpm workspaces + Turborepo 1.13 [high]
- **Artifact:** Docker image `ghcr.io/example/orders:<sha>` via multi-stage Dockerfile [high]
- **Build command:** `pnpm build` (runs `turbo run build --filter=...`) [high]

### CI Workflows

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `.github/workflows/ci.yml` | push / pull_request | lint + test + build [high] |
| `.github/workflows/release.yml` | tag `v*` | publish Docker image + changelog [high] |
| `.github/workflows/nightly.yml` | cron 02:00 UTC | integration tests against staging [medium] |
```

## Confidence Tags

- `[high]` — tool / artifact / CI file read directly
- `[medium]` — inferred from presence without reading workflow body
- `[low]` — guessed from directory naming
- `[inferred]` — avoid in this profile
