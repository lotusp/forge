---
name: onboard
description: |
  Generates a navigation-oriented project map for AI developers and humans
  working on an existing codebase. Produces .forge/context/onboard.md with
  9 structured sections: project identity, architecture overview, codebase
  structure, core domain objects, entry points with call chains, integration
  topology, change navigation, local development, and known traps.

  Supports incremental updates: subsequent runs re-verify each section against
  the current commit and rewrite only the sections whose underlying code has
  changed. Pass --regenerate to force a full rewrite, or --section=<name>
  to refresh a single section.

  Run before /forge:calibrate. Onboard records observed facts; calibrate
  produces authoritative rules.
argument-hint: "[--regenerate | --section=<section-name>]"
allowed-tools: "Read Glob Grep Bash Write"
context: fork
model: sonnet
effort: high
---

## Runtime snapshot
- Current commit: !`git rev-parse --short HEAD 2>/dev/null || echo "(not a git repo)"`
- Existing artifact: !`test -f .forge/context/onboard.md && echo "FOUND — read header for last verified commit" || echo "(absent — first run)"`
- Root contents: !`ls -1 2>/dev/null | head -30`
- CLAUDE.md: !`test -f CLAUDE.md && echo "present — read fully" || echo "absent"`
- Existing .forge artifacts: !`ls .forge/context/ .forge/features/ 2>/dev/null || echo "(none)"`
- Source file counts: !`echo "Java: $(find . -name '*.java' 2>/dev/null | grep -v '.git' | grep -v build | wc -l | tr -d ' ') | TS: $(find . -name '*.ts' 2>/dev/null | grep -v node_modules | grep -v '.git' | wc -l | tr -d ' ') | Go: $(find . -name '*.go' 2>/dev/null | grep -v '.git' | wc -l | tr -d ' ') | Py: $(find . -name '*.py' 2>/dev/null | grep -v '.git' | grep -v venv | wc -l | tr -d ' ')"`
- Controllers/Handlers: !`find . \( -name '*Controller*' -o -name '*Handler*' -o -name '*Router*' \) \( -name '*.java' -o -name '*.ts' -o -name '*.go' -o -name '*.py' \) 2>/dev/null | grep -v '.git' | grep -v build | grep -v test | wc -l | tr -d ' '` files
- Listeners/Consumers: !`find . \( -name '*Listener*' -o -name '*Consumer*' -o -name '*Subscriber*' \) \( -name '*.java' -o -name '*.ts' -o -name '*.go' -o -name '*.py' \) 2>/dev/null | grep -v '.git' | grep -v build | wc -l | tr -d ' '` files

---

## IRON RULES

These rules have no exceptions. A run that violates any of them must stop
and correct itself before writing the artifact.

### Verification rules

1. **HTTP methods must come from annotations, never from method names.**
   Before writing any route, read the source file and confirm the verb
   against `@GetMapping|@PostMapping|@PutMapping|@PatchMapping|@DeleteMapping|@RequestMapping.*method=`
   (or the stack's equivalent — see `reference/scan-patterns.md`).

2. **Module paths must be verified on disk.** Never record a path derived
   from a package name alone. For every module entry, run Glob on the path
   first. Remove entries that do not resolve.

3. **Versions come from build files, not README.** Read `gradle.properties`,
   `build.gradle`, `pom.xml`, `package.json`, `go.mod`, `Cargo.toml`, or
   `pyproject.toml` for versions. When README disagrees, record both with
   a `[conflict]` tag — never silently pick one.

4. **Never compress multi-observer events.** For each domain event, grep
   every file that listens to it (`@EventListener`, `implements
   ApplicationListener<EventName>`, `@KafkaListener`, `@RabbitListener`,
   etc.) and list all observers. Compressing N listeners into "downstream
   services" is forbidden.

5. **Tag confidence on every high-impact claim.** Use one of:
   - `[code]` — read directly from source
   - `[config]` — read from config file (`.yml`, `.properties`, `.env`)
   - `[build]` — read from build file (`build.gradle`, `package.json`)
   - `[readme]` — from README only, not verified against code
   - `[inferred]` — generated without direct verification

   Untagged factual claims about versions, paths, flows, or behaviour are
   forbidden.

6. **Commands must be sourced from actual config files.** Build/test/lint
   commands come from `Makefile`, `package.json` scripts, `build.gradle`
   tasks, or README (with the README's command verified against the build
   file). Invented commands are forbidden.

### Structural rules

7. **Observed fact vs. rule — onboard writes observations only.**

   | Observed fact (onboard writes) | Rule (belongs to /forge:calibrate) |
   |-------------------------------|-----------------------------------|
   | "Services live in `*.service.*`" | "Business logic MUST live in service layer" |
   | "BaseTestSetup uses @Rollback" | "New integration tests MUST extend BaseTestSetup" |
   | "fakedms/ returns canned responses" | "New code MUST NOT depend on fakedms" |
   | "Mixed /api and /api/v2 observed" | "New endpoints MUST use /api/v2" |

   If a sentence about to be written contains "must", "must not", "should",
   "forbidden", "never", "required to"—stop. That sentence belongs in
   calibrate's output. Record only the observation.

8. **Sub-systems with their own full layering are separate modules.** A
   sub-directory that has its own `controller/`, `service/`, and
   `repository/` (or equivalent trio) is its own module row — never fold
   into the parent.

9. **Entry point totals must precede examples.** "28 listeners total, 6
   representative below" — never list examples without the total.

10. **Preserve blocks are sacred.** Any content inside
    `<!-- forge:onboard:preserve -->` markers must be carried verbatim
    across regenerations, including `--regenerate`.

---

## Boundary with /forge:calibrate

Onboard produces navigation. Calibrate produces authoritative rules.

| Topic | Onboard writes | Calibrate writes |
|-------|----------------|------------------|
| Layering | Observed layers, call direction | `architecture.md` — rules & forbidden calls |
| Testing | Test base classes, known infra traps | `testing.md` — strategy, mock policy, coverage |
| Code style | — | `conventions.md` — naming, logging, error handling |
| Anti-patterns | — | `constraints.md` — what new code must not do |

Each onboard section with a calibrate counterpart must end with an explicit
pointer (even before calibrate runs — the pointer tells readers where rules
will appear):

- Architecture Overview → `> 分层规则与禁止事项见 .forge/context/architecture.md（由 /forge:calibrate 产生）`
- Local Development → `> 完整测试策略见 .forge/context/testing.md（由 /forge:calibrate 产生）`
- Known Traps → `> 反模式与硬性规则见 .forge/context/constraints.md（由 /forge:calibrate 产生）`

---

## Prerequisites & Run Modes

Parse the `$1` argument and detect artifact state, then pick a mode:

### Mode A — First run
No existing `.forge/context/onboard.md`. Run Steps 0–11 end-to-end and write
all 9 sections.

### Mode B — Incremental (default when artifact exists)
Existing artifact, no flag. Announce:

```
[forge:onboard] Existing artifact found
  last verified: {short-hash} ({date})
  current HEAD:  {short-hash}

Running in incremental mode. Will re-scan all sections and rewrite only
those whose underlying code has changed. Preserve blocks are carried
across. To force full regeneration: /forge:onboard --regenerate
```

For each section, compare the re-scan result against the stored content:
- **Unchanged** → keep content as-is, update `verified=<hash>` marker only
- **Changed** → show the user a one-line diff summary, rewrite the section
- **Inside a `forge:onboard:preserve` block** → never touch

Write sections one at a time to disk so an interrupted run leaves a valid,
partially-updated artifact.

### Mode C — `--regenerate`
Existing artifact, `--regenerate` flag. Prompt:

```
[forge:onboard] --regenerate will REWRITE all sections of
.forge/context/onboard.md. Preserve blocks will still be carried across.
Proceed? (y/N)
```

On `y`: behave like Mode A but carry preserve blocks forward.

### Mode D — `--section=<name>`
Single-section refresh. Valid names:
- `project-identity`
- `architecture-overview`
- `codebase-structure`
- `core-domain-objects`
- `entry-points`
- `integration-topology`
- `change-navigation`
- `local-development`
- `known-traps`

Run only the scans needed for that section, rewrite only that section's
block, update its `verified=<hash>` marker. Other sections unchanged.

---

## Process

Each Step maps to zero or more output sections and scans specific artifacts.
Skip Steps not required by the current run mode.

### Step 0 — Detect run mode and plan
Parse argument, read existing artifact header if present, announce mode
per the rules above. In Mode D, skip directly to the target section's step.

### Step 1 — Project identity
Feeds section **1. Project Identity**.

- Determine project type: monorepo / single application / library+SDK.
  For monorepos look for `packages/`, `apps/`, `services/`, `libs/`,
  workspace config.
- Read README's first paragraph and CLAUDE.md fully if present.
- Identify the primary runnable unit (startup class, `main` function,
  `@SpringBootApplication`, etc.) and its module/directory.
- Record one to two paragraphs covering purpose, business domain, primary
  users. Non-technical readers must understand this.

### Step 2 — Configuration scan (build + runtime + side effects)
Feeds sections **2. Architecture Overview** (tech stack table) and
**8. Local Development**.

Read common config files per `reference/scan-patterns.md`. Extract:
- Language + runtime + framework versions — tag `[build]`
- Database, cache, search, MQ — tag `[config]` or `[build]`
- Service discovery / config center — distinguish config-only (Nacos
  config) from discovery. Do not mislabel.
- Key internal/proprietary libraries
- Infrastructure (cloud region, container registry) — tag `[config]`

**Side-effect surfacing (critical, easy to miss):**
Grep root build files for:
- `git config` invocations
- `core.hooksPath` settings
- `System.setProperty` in init blocks
- `afterEvaluate { ... exec ... }` blocks
- init tasks that mutate the developer environment

Record all such side effects for Known Traps or Local Development.

### Step 3 — Codebase structure scan
Feeds section **3. Codebase Structure**.

Split the module map into **two layers**:

**Business Domains:** the top-level business units (`order`, `salesoption`,
`billing`, etc.). One row each.

**Technical Layers:** the cross-cutting packages (`framework`, `clients`,
`authentication`, `db`, `toggles`, etc.). One row each.

Detection rules:
- A sub-directory with its own full `adapter/`, `service/`, `repository/`
  triple is a **business domain** (IRON RULE 8 — must be separate row).
- A sub-directory that only contains infrastructure/cross-cutting code is
  a **technical layer**.
- Adapter sub-packages (`order.adapter.mbe`, `order.adapter.dms`) are
  **not** separate rows — fold into the parent domain, list integrations
  in Section 6 (Integration Topology) instead.

For every row, run Glob on the path and read ≥1 representative source
file before writing the responsibility. Every path gets `[code]` tag.

### Step 4 — Core domain object scan
Feeds section **4. Core Domain Objects**.

Scan `src/main/java/**/domain/**`, `src/main/java/**/entity/**`,
`**/models/**`, or language equivalent. Identify aggregate roots:
- `@Entity` + no `@ManyToOne` owning side → likely aggregate root
- Classes ending in `*Order`, `*Account`, `*Policy`, `*Program`, `*Ticket`
- Classes with `@OneToMany` to history/audit tables

For each aggregate root record:
- Class name + package `[code]`
- 1-line business meaning
- Key related entities (1:1 / 1:N)
- Status-field enum if present (for state machines)
- Which services mutate it (grep `{ClassName}Repository.save|persist`)

**Keep this section factual.** Record the shape, not "what developers
should do when modifying it."

### Step 5 — Entry points + call chains
Feeds section **5. Entry Points & Call Chains**.

For each category:

**HTTP API:**
- Grep for all controller annotations per `reference/scan-patterns.md`
- **State total count first** (IRON RULE 9)
- Select 5–10 representative routes spanning the major business domains
- For each representative route, trace **one level deeper** — the primary
  service method called, and the main side effects. Format:

```
### {Flow name}
- Entry: `QuotationOrderController#createOrder` (@PostMapping /api/v2/orders) [code]
- Service: `QuotationOrderService#createOrder` [code]
- Entity: `QuotationOrder` [code]
- Events published: `OrderCreatedEvent` [code]
- External calls: `StockManagementClient.reserveStock` (Feign) [code]
```

**Never** write just a bare `METHOD /path — file:line`. Line numbers shift;
use the class#method triplet.

**Event Listeners / Message Consumers / Background Jobs / CLI / gRPC:**
- State total count first for each category
- List representative examples with class + trigger

### Step 6 — Integration topology scan
Feeds section **6. Integration Topology**.

Run four greps (see `reference/scan-patterns.md` for exact patterns):
1. **Outbound REST:** `@FeignClient` classes or HTTP client wrappers
2. **Inbound REST from external systems:** filter `@*Mapping` for paths
   that look like integration endpoints (`/mbe/`, `/cdm/`, `/oasis/`)
3. **Inbound async:** `@MessageListener`, `@Consumer`, `@KafkaListener`,
   `@RabbitListener`, `@JmsListener`, `@ServiceBusListener`
4. **Outbound async:** `*Publisher`, `*Sender`, explicit `.send(...)` calls
   to queues/topics

Compile a matrix:

| System | Direction | Mechanism | Main class | Local dev needed | Notes |
|--------|-----------|-----------|------------|------------------|-------|

Then, for **internal events**, produce a second table showing each
`*Event` class and **all** its listeners (IRON RULE 4):

| Event | Publisher | Observers (all) | External effects |
|-------|-----------|-----------------|------------------|
| `OrderConfirmedEvent` | `OrderConfirmService` | `OrderConfirmedListener`, `OCCOrderConfirmListener`, `WallBoxOnOrderConfirmedListener` | DMS notify, OCC status, WallBox init |

### Step 7 — Test infrastructure scan (for Known Traps only)
Feeds section **9. Known Traps**. Does NOT feed a testing strategy section.

- Glob `**/BaseTest*.*`, `**/AbstractTest*.*` — record each base class's
  isolation mechanism (is there `@Transactional`? `@Rollback`? what does
  `cleanUp()` do?)
- Grep `@Disabled`, `@Ignore` across test sources — list currently-disabled
  tests
- Read test config for `stubMode=remote`, `wiremock.*`, embedded DB
  versions (MariaDB4j, H2, Testcontainers)
- Note cross-platform concerns (Apple Silicon ALPN, glibc-linked native
  libs, etc.) if discoverable from dependency versions

Surface only **observed facts** that will bite first-day developers. Do
NOT write a testing strategy — that is calibrate's job.

### Step 8 — Local development commands
Feeds section **8. Local Development**.

Structure into three distinct blocks:

1. **Prereqs** — infrastructure (DB, Redis, MQ). Include Docker commands
   when `docker-compose.yml` exists.
2. **Compile** — minimum to make the build succeed. If private repos are
   required (Nexus, Artifactory), state the env vars / credentials needed.
3. **Run** — minimum config for local startup. Include:
   - Config template file path (exact, e.g.
     `application-local.properties.sample`); if absent, state "(no local
     template in repo)"
   - Required config keys (grep main `application.yml` for `${...}`
     placeholders without defaults)
   - Port and profile defaults (read `bootstrap.yml` / `application.yml`)
4. **Test** — all tests + single test class/file commands
5. **Lint / format** — if `spotless`, `checkstyle`, `eslint`, `prettier`
   is configured, the command; else `# (no lint task configured)`

End the section with the testing-strategy pointer to calibrate.

### Step 9 — Change navigation synthesis
Feeds section **7. Change Navigation**.

From the scans in Steps 3–6, synthesize 4–6 typical change scenarios
**observed in the existing code**. Frame each as "if you change X, existing
code modifies these layers":

```
### Add / modify an order field
- Controller DTO: `QuotationOrderRequest` (in `order/adapter/api/dto/`)
- Service mapping: `QuotationOrderService#mapRequestToEntity`
- Entity: `QuotationOrder`
- Migration: `order-management-service/src/main/resources/db/migration/`
- Likely side effects: search indexing, export, CDM sync, contract tests
```

**Keep this factual, not prescriptive.** Describe what existing code does,
not what new code should do. If you can't find ≥3 similar existing changes
for a scenario, omit that scenario.

### Step 10 — Verification pass (MANDATORY)

Before writing the artifact, confirm every IRON RULE:

- [ ] Route sanity: every representative route's HTTP verb read from
  `@*Mapping` annotation in the actual file
- [ ] Path existence: every module and file path resolves on Glob
- [ ] Version cross-check: every version in Tech Stack appears in a
  build file; README conflicts marked `[conflict]`
- [ ] Observer completeness: for every event in Integration Topology,
  all listeners grep-verified
- [ ] Confidence tags: every factual claim tagged
- [ ] Command verification: every command in Local Development appears
  in an actual build/config file
- [ ] No rule-writing: re-read Known Traps / Architecture Overview /
  Change Navigation and remove any sentence with "must", "should",
  "forbidden", "never"
- [ ] Sub-system separation: every domain with full layering has its own row
- [ ] Entry-point totals: each category has a count before examples
- [ ] Calibrate pointers: Architecture Overview, Local Development,
  Known Traps each end with their pointer line

Any failed check must be fixed before Step 11.

### Step 11 — Write artifact (section-by-section)

Write each section independently to disk, in order. Each section is
wrapped in HTML-comment markers so incremental mode can diff them:

```markdown
<!-- forge:onboard section=project-identity verified={commit-hash} generated={YYYY-MM-DD} -->
## 1. Project Identity

...content...

<!-- /forge:onboard section=project-identity -->
```

Preserve blocks inside sections use their own markers:

```markdown
<!-- forge:onboard:preserve -->
团队补充 — skill 不会覆盖此块
...
<!-- /forge:onboard:preserve -->
```

See `reference/output-template.md` for the full 9-section structure and
`reference/incremental-mode.md` for the diff/merge logic.

Write in the order: header → sections 1–9 → Document Confidence footer.
After each section write, confirm the file still parses (opening/closing
markers match) before proceeding.

---

## Output

**File:** `.forge/context/onboard.md`

See [reference/output-template.md](reference/output-template.md) for the
complete artifact template including all section markers, the Document
Confidence footer, and the preserve-block syntax.

---

## Interaction Rules

- If CLAUDE.md exists, read it fully — it may contain corrections to what
  the skill would otherwise infer. Tag claims from CLAUDE.md as `[code]`
  only if cross-verified against source; otherwise `[inferred]`.
- If a section has no data (e.g. no CLI entry points), **still emit the
  section markers with an explicit "No {category} detected" body** — do
  not silently omit sections in the incremental-mode output (the markers
  anchor future diffs).
- After writing, summarise in 2–3 sentences:
  - total sections written vs reused vs skipped
  - any `[conflict]` or `[needs-verification]` tags that need human input
  - next step: `/forge:calibrate`
- Append one entry to `.forge/JOURNAL.md` (create if absent):

```markdown
## YYYY-MM-DD — /forge:onboard ({mode})
- 产出：.forge/context/onboard.md ({N} sections written, {M} reused)
- 摘要：{N} 个业务域, {N} 个技术层, {N} 个 entry points, {N} 个集成
- 置信度警示：{list of [conflict] or [needs-verification] items, or "无"}
- 下一步：/forge:calibrate
```

---

## Constraints

- Strictly read-only to source files. This skill never modifies code.
- Never guess project purpose from directory names — read at least one
  substantive file per module before describing it.
- Aim for navigation over inventory: 20% of information that gives 80%
  of orientation. Do not list every route or every file.
- In incremental mode, never overwrite a section whose scan result is
  unchanged — the `verified=` marker update is the only write.
- Preserve blocks are sacred: even `--regenerate` carries them across.
