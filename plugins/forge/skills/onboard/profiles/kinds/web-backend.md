---
kind-id: web-backend
display-name: Web Backend Service
detection-signals:
  positive:
    - pattern: "package.json with express|fastify|koa|hono|nestjs in dependencies"
      weight: 0.30
    - pattern: "pom.xml with spring-boot-starter-web"
      weight: 0.30
    - pattern: "go.mod with gin-gonic/gin|labstack/echo|gofiber/fiber"
      weight: 0.30
    - pattern: "pyproject.toml with fastapi|flask|django"
      weight: 0.30
    - pattern: "HTTP route definitions found by grep (≥ 10 matches)"
      weight: 0.25
    - pattern: "Dockerfile exposing HTTP port (EXPOSE 3000|8000|8080|80)"
      weight: 0.15
    - pattern: "database migration directory present"
      weight: 0.10
  negative:
    - pattern: ".claude-plugin/plugin.json present"
      weight: 0.40
    - pattern: "workspace declaration (pnpm-workspace.yaml | go.work | [workspace])"
      weight: 0.25
    - pattern: "no source files outside docs/ or examples/"
      weight: 0.30
# v0.5.x stack gate — Stage 1 must verify required-stack signals before
# proceeding to Stage 2. Non-Java projects pass kind detection but produce
# low-quality output, so we halt explicitly. Removed once adapter model
# lands in v0.6.0.
stage2-stack-gate:
  required-stack: java-spring
  signals:
    - file: build.gradle
      grep: "spring-boot-starter-web|spring-boot-starter-webflux"
    - file: build.gradle.kts
      grep: "spring-boot-starter-web|spring-boot-starter-webflux"
    - file: pom.xml
      grep: "<artifactId>spring-boot-starter-web(flux)?</artifactId>"
  on-mismatch:
    action: halt
    message: |
      v0.5.x supports Java/Spring only.
      Detected web-backend kind but no Spring Boot signal found.
      To proceed anyway: re-run with --override-stack-gate
      (output quality will be low — see Current Scope in SKILL.md).
profiles:
  - core/what-this-is        # MUST stay first — produces the opening section
  - core/tech-stack
  - core/module-map
  - core/entry-points
  - core/data-flows
  - core/notes
  - structural/build-system
  - structural/config-management
  - structural/deployment
  - structural/observability
  - model/domain-model
  - model/db-schema
  - entry-points/http-api
  - entry-points/event-consumers
  - integration/auth
  - integration/third-party-apis
  - integration/messaging
output-sections:
  - What This Is
  - Tech Stack
  - Module Map
  - Entry Points
  - HTTP API Surface
  - Event Consumers
  - Domain Model
  - Database Schema
  - Authentication & Authorization
  - Third-Party Integrations
  - Messaging & Events
  - Build System
  - Configuration
  - Deployment
  - Observability
  - Key Data Flows
  - Notes
---

# Kind: Web Backend Service

## When to Use

Apply this kind when the project is a deployable service that accepts inbound requests
(HTTP / gRPC / events) and persists state. Typical signals:

- Long-running process (not a CLI that exits)
- Has at least one of: HTTP routes, event consumers, scheduled jobs
- Owns a datastore (relational DB, document DB, or state backend)
- Deployed as a container or long-running VM process

**Not this kind:**
- Plugins / SDKs / libraries (no deployable service)
- Frontend-only apps (React / Vue SPA without a backend in the same repo) — there is
  no `web-frontend` kind yet; treat as `unknown` and skip the `unknown`-blocking flow
- Pure CLI tools

## Execution Notes

- **Run profiles in the listed order** — this order matches the output section layout.
- **Conditional profiles** inside this kind:
  - `model/db-schema` — skip if no migration directory found during `module-map` scan;
    note the skip in the execution plan.
  - `entry-points/event-consumers` — skip if no event client in deps (Kafka / RabbitMQ
    / SQS / NATS).
  - `integration/messaging` — skip under the same condition as event-consumers.
- **Multi-framework projects** (e.g. NestJS with a Vite admin panel) — prefer the
  framework serving the primary HTTP surface; mention secondary framework in `notes`.

## Excluded Profiles

- `monorepo/workspace-layout` — not applicable; use `monorepo` kind if applicable
