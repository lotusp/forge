# Scan Patterns Reference

Exact grep/glob patterns used by `/forge:onboard` Steps 2–9. This file
exists so SKILL.md stays readable; when running scans, consult the table
for the language/framework in scope.

Each scan below has a target section (the output section it feeds) and
a confidence tag to apply to each finding.

---

## Step 2 — Configuration scan

### Build / version files

| Pattern | Target | Tag |
|---------|--------|-----|
| `package.json` — `"engines"`, `"dependencies"`, `"scripts"` | Tech stack, commands | `[build]` |
| `gradle.properties` — `javaVersion`, `*Version` constants | Tech stack | `[build]` |
| `build.gradle` root + subprojects — `ext { }`, `dependencies { }`, `plugins { }` | Tech stack, side effects | `[build]` |
| `pom.xml` — `<parent>`, `<properties>`, `<dependencies>` | Tech stack | `[build]` |
| `go.mod` — `go`, `require` | Tech stack | `[build]` |
| `Cargo.toml` — `[package]`, `[dependencies]` | Tech stack | `[build]` |
| `pyproject.toml` / `requirements.txt` | Tech stack | `[build]` |

### Runtime config

| Pattern | Target | Tag |
|---------|--------|-----|
| `application*.yml` / `application*.properties` | Tech stack, config keys | `[config]` |
| `bootstrap.yml` / `bootstrap.properties` | Default profile, port | `[config]` |
| `docker-compose*.yml` — `services:` | Infra dependencies | `[config]` |
| `Dockerfile` — `FROM`, `EXPOSE` | Runtime base image, ports | `[config]` |
| `.env.example` / `.env.sample` | Required env vars | `[config]` |

### Side-effect surfacing (easy to miss)

Grep root build files (`build.gradle`, root `package.json`, `Makefile`)
for:

```
git config
core.hooksPath
System.setProperty
afterEvaluate\s*\{
exec\s*\{
execSync
Runtime.getRuntime\(\)
```

Each hit may indicate developer-environment mutation and belongs in Known
Traps or Local Development prerequisites.

---

## Step 3 — Codebase structure

Detect business domain vs. technical layer:

```
# Business domain candidates (have full layering)
Glob: src/main/java/**/{adapter,service,repository,domain}/
Glob: src/{controllers,services,repositories}/

# Technical layer candidates (cross-cutting)
Glob: src/main/java/**/{framework,common,config,util,clients,authentication}/
```

A sub-directory qualifies as a **business domain** when Glob returns
matches for all three of `adapter/`, `service/`, and `repository/` (or
analogues) beneath it. Otherwise it's a **technical layer**.

---

## Step 4 — Core domain objects

### Java / Kotlin

```
# Aggregate root candidates
rg -l '@Entity' src/main/java/ --type java
rg '@Entity' -A 1 src/main/java/ --type java | rg 'class\s+(\w+)'

# Status field enums
rg 'enum\s+\w*Status' src/main/java/ --type java

# Events
Glob: **/*Event.java
rg 'extends\s+ApplicationEvent|implements\s+DomainEvent' --type java
```

### TypeScript / JavaScript (NestJS-style)

```
rg '@Entity\(\)' src/ --type ts
rg '@Column.*enum' src/ --type ts
Glob: **/*.event.ts
```

### Go

```
Glob: internal/domain/**/*.go
rg 'type\s+\w+\s+struct' internal/domain/ --type go
```

---

## Step 5 — Entry points

### HTTP (Spring)

```
rg '@(RestController|Controller)\b' --type java -l
rg '@(GetMapping|PostMapping|PutMapping|PatchMapping|DeleteMapping|RequestMapping)' --type java
```

For each mapping annotation, the method value (or class-level
`@RequestMapping`) gives the HTTP verb. **Do not infer from method name**
(IRON RULE 1).

### HTTP (Express / Fastify / Koa)

```
rg '(app|router)\.(get|post|put|patch|delete)\s*\(' --type ts --type js
rg '@(Get|Post|Put|Patch|Delete)\(' --type ts   # NestJS
```

### HTTP (Gin / Echo — Go)

```
rg '\.(GET|POST|PUT|PATCH|DELETE)\s*\(' --type go
```

### HTTP (FastAPI / Flask — Python)

```
rg '@(app|router)\.(get|post|put|patch|delete)' --type py
```

### Event listeners / message consumers (Spring)

```
rg '@EventListener' --type java
rg 'implements\s+ApplicationListener<' --type java
rg '@(KafkaListener|RabbitListener|JmsListener|ServiceBusListener|MessageListener|Consumer)' --type java
```

### Scheduled jobs

```
rg '@Scheduled' --type java
rg 'cron:\s*".*"' --type java
# Node
rg '(cron|node-schedule|agenda)' package.json
# Go
rg 'cron\.AddFunc' --type go
```

### CLI commands

```
rg '(Command|@Command|cobra\.Command)' --type java --type go
rg '\.command\(' package.json   # Commander.js
```

---

## Step 6 — Integration topology

### Outbound REST (Feign)

```
rg '@FeignClient' --type java
# Extract: class name, value/name, url/path
```

### Outbound REST (other)

```
# Spring RestTemplate / WebClient
rg '(RestTemplate|WebClient)' --type java -l
# Node axios / fetch wrappers
rg 'axios\.create' --type ts --type js -l
```

### Inbound async

```
rg '@(MessageListener|Consumer|KafkaListener|RabbitListener|JmsListener|ServiceBusListener|EventHubConsumer)' --type java
```

### Outbound async (queue/topic senders)

```
rg '(ServiceBusSenderClient|KafkaTemplate|RabbitTemplate|JmsTemplate)' --type java
rg 'class\s+\w+(Publisher|Sender)\b' --type java
```

### Inbound REST from external systems

Filter `@*Mapping` results for path patterns that look like integration
endpoints:

```
rg '@(Get|Post)Mapping.*"(/[a-z]+/|/api/[a-z]+/)"' --type java
# Common external integration paths: /mbe/, /cdm/, /oasis/, /sims/, /dms/
```

---

## Step 7 — Test infrastructure

### Test base classes

```
Glob: **/BaseTest*.java
Glob: **/AbstractTest*.java
Glob: **/BaseIntegrationTest*.java

# For each base class, check:
rg '@Transactional' {file}
rg '@Rollback' {file}
rg 'cleanUp\(\)|tearDown\(\)|@(AfterEach|After)' {file}
```

### Disabled tests

```
rg '@Disabled' --type java src/test/
rg '@Ignore' --type java src/test/    # JUnit 4 — may indicate mistaken usage on JUnit 5 tests
```

### Test infrastructure tooling

```
rg '(MariaDB4j|H2|Testcontainers|@DataJpaTest|@SpringBootTest)' --type java src/test/ -l
rg 'stubMode\s*=\s*(remote|local|classpath)' --type java --type properties --type yml
rg 'wiremock' --type gradle --type xml
```

### Cross-platform concerns

```
# Apple Silicon + WireMock + ALPN
rg 'wiremock.*2\.[0-9]+' --type gradle build.gradle*
rg 'wiremock-jre8' --type gradle build.gradle*
# If present → note WireMock ALPN workaround in Known Traps
```

---

## Step 8 — Local development

### Required env / config keys

```
# Grep application.yml for unresolved placeholders
rg '\$\{[^:}]+\}' src/main/resources/application*.yml
# (placeholders without defaults need to be set locally)
```

### Config templates in repo

```
Glob: **/application-*.{yml,yaml,properties}.{sample,example,template}
Glob: .env.{sample,example,template}
```

### Build / run / test tasks

```
# Gradle
./gradlew tasks --all | grep -E '^(build|bootRun|test|check|spotless)'
# npm
cat package.json | jq '.scripts'
# Makefile
rg '^[a-z_-]+:' Makefile
```

### Lint tasks

```
# Spotless / Checkstyle (Java)
rg '(spotless|checkstyle|pmd)' build.gradle*
# ESLint / Prettier (Node)
rg '(eslint|prettier|biome)' package.json
# golangci-lint (Go)
rg 'golangci' Makefile .golangci.*
```

---

## Step 9 — Change navigation synthesis

To find ≥3 historical examples for a candidate change scenario, grep git
log:

```
git log --oneline --all | head -200
git log --all --pretty=format:"%s" | rg -i '(add|modify).*field' | head -20
git log --all --pretty=format:"%s" | rg -i 'status.*flow|transition'
```

Match file co-change patterns:

```
# For each candidate scenario, find commits that touched the layers together
git log --all --diff-filter=M --name-only --pretty=format:"COMMIT %h" | {parse}
```

If fewer than 3 commits touch the same layer combination, **omit that
scenario** — don't invent one.

---

## Confidence tag decision tree

```
Was this read from a source file?
├── Yes → [code]
└── No
    └── Was this read from a config file (.yml/.properties/.env)?
        ├── Yes → [config]
        └── No
            └── Was this read from a build file (build.gradle/package.json)?
                ├── Yes → [build]
                └── No
                    └── Was this read from README?
                        ├── Yes — verified against code? → [code]
                        ├── Yes — NOT verified → [readme]
                        └── No → [inferred]

Special cases:
- Two sources disagree → [conflict] + keep both
- Can't access source in this run → [needs-verification]
```
