---
name: observability
section: Observability
applies-to:
  - web-backend
  - monorepo
confidence-signals:
  - actuator / health endpoint dependency present
  - micrometer / prometheus / opentelemetry deps in build manifest
  - structured-logging encoder configured (logback / pino / zerolog)
  - gradle-git-properties / similar build-info plugin
token-budget: 700
must-grep:
  - 'spring-boot-starter-actuator'
  - 'micrometer-registry-(prometheus|otlp)'
  - 'opentelemetry'
  - 'gradle-git-properties'
  - 'logstash-logback-encoder'
must-cross-check:
  - if-zero: 'micrometer-registry-prometheus'
    and-output: 'omit prometheus claim'
  - if-config-missing: 'management\.endpoints\.web\.exposure\.include.*prometheus'
    and-dep-present: 'micrometer-registry-prometheus'
    then-emit: 'prometheus dep present but exposure does not list it — endpoint NOT available'
---

# Profile: Observability

## Scope

A first-day SRE / on-call view of the service: what metrics flow out,
what health probes exist, how logs are structured, what tracing (if
any) is wired up, and what build metadata reaches `/actuator/info`.

Aimed at the engineer who gets paged at 3am — not at exhaustive APM
inventory. Kept under one page.

## Scan Patterns

**Spring Boot ecosystem:**
- `spring-boot-starter-actuator` in deps
- `micrometer-registry-prometheus` / `micrometer-registry-otlp`
- `OpenTelemetry` SDK + autoconfigure starter

**Logging:**
- `logback-spring.xml` / `logback.xml` for the encoder choice
- JSON encoder (`logstash-logback-encoder`, `LogstashEncoder`)
- MDC field setters (`MDC.put` / `Sleuth` `B3` headers)

**Health probes:**
- `/actuator/health`, `liveness`, `readiness` endpoint config
- `management.endpoints.web.exposure.include` literal value (fact, NOT
  inferred from "actuator dep is on classpath")

**Tracing:**
- `spring-cloud-sleuth-zipkin` / `OpenTelemetry` exporter starter

**Build-time metadata:**
- `gradle-git-properties` plugin (build.gradle)
- `git.properties` resource (auto-emitted) feeding `/actuator/info`

## Extraction Rules

1. **Endpoint exposure is a fact, not an inference.** A dependency on
   the classpath does NOT mean its endpoint is exposed. Spring Boot
   2.0+ requires explicit `management.endpoints.web.exposure.include`.
   Read the literal config value and quote it; if the key is missing,
   write "uses Spring Boot defaults (health only)" — do not assume
   prometheus is reachable just because the dep is there.

2. **Tracing claims need both library AND exporter.** Sleuth/OpenTelemetry
   on classpath without a configured exporter URL is not "tracing in
   place". Check both before claiming tracing.

3. **Log encoder honesty.** Default `logback-spring.xml` produces plain
   text. Only claim "JSON logs" when a JSON encoder is configured in
   the logback XML (or when the SVC / org-internal log starter wraps
   it explicitly).

4. **Build metadata footprint.** `gradle-git-properties` (or
   `git-commit-id-maven-plugin`) means `/actuator/info` carries
   commit SHA / branch / build time. Surface this as a fact only when
   the plugin is in build deps.

5. **`detectors[]` integration:** when the v0.5.2-beta detector
   pipeline is active, this profile may invoke a future `actuator_exposure`
   detector to read `management.endpoints.web.exposure.include`
   verbatim instead of regex-grepping config files.

## Section Template

```markdown
## Observability

### Metrics
- Library: Micrometer + Prometheus registry [high] [build]
- Exposure (literal): `management.endpoints.web.exposure.include = health, info, prometheus` [high] [config]

### Health
- `/actuator/health` exposed [high] [config]
- Liveness/readiness probes derive from it; no custom probe config observed [medium] [config]

### Logging
- Encoder: <plain text via default logback-spring.xml | JSON via logstash-logback-encoder> [high] [code]
- MDC fields observed: `orderId`, `dealerId` [medium] [code]

### Tracing
- <none observed | Sleuth+Zipkin | OpenTelemetry → <exporter type, host redacted>> [confidence]

### Build metadata
- `gradle-git-properties` plugin → `/actuator/info` carries git commit, branch, build time [high] [build]

### Gaps (only when present)
- No tracing instrumentation observed despite distributed deployment [medium] [code]
- No structured-log JSON encoder configured (text logs in production) [medium] [code]
```

## Confidence Tags

- `[high]` — dep + config + exposure all directly observed
- `[medium]` — dep observed but exposure / encoder config not verified
- `[low]` — claim from README / CLAUDE.md only
- `[inferred]` — avoid; observability claims need direct evidence per
  Extraction Rule 1

## Why This Profile Exists

v0.5.1 review of `svc-web-bff-svc` found the doc claiming
`/actuator/prometheus` was exposed when the actual config only listed
`health, shutdown, prometheus` (it WAS — but for a different config
key value than the doc reproduced). Earlier SVC reviews also caught
projects asserting Prometheus availability based purely on dependency
presence, with no exposure config to back it. Both failure modes are
prevented by the "endpoint exposure is a fact, not an inference" rule.
