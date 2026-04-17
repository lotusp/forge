# onboard.md Output Template

This file defines the exact structure for `.forge/onboard.md`.
Referenced by `/forge:onboard` Step 8.

---

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
| Language | {e.g. Java 8 / TypeScript 5} |
| Runtime | {e.g. JVM 8 / Node.js 20} |
| Framework | {e.g. Spring Boot 2.x / Express 4} |
| Database | {e.g. MySQL 5.7, schema: xxx} |
| Cache | {e.g. Redis 4} |
| Messaging | {e.g. Azure Service Bus / Kafka} |
| Service Discovery | {e.g. Nacos / Consul} |
| Build | {e.g. Gradle 6.9 / npm} |
| Key internal libraries | {custom starters, shared libs} |

---

## Module Map

| Module | Path | Responsibility |
|--------|------|----------------|
| `ModuleName` | `src/module/` | One sentence |
| `SubSystemName` ← sub-system | `src/subsystem/` | One sentence — note if has own full layering |

---

## Entry Points

### HTTP API
Base URL pattern: `{e.g. /api/ and /api/v2/ (mixed — see Notes)}`
Total controllers: {N}
Representative routes:
- `{METHOD} {path}` — `path/to/Controller.java:line`
- ...

### Event Listeners / Message Consumers
Total: {N} listeners/consumers
Representative examples:
- `ListenerName` — triggers on {event} (`path/to/Listener.java`)
- ...

### Background Jobs ← omit section if none
- `{job name}` — {schedule / trigger} (`path/to/job`)

---

## Local Development

```bash
# Prerequisites
{docker run commands or brew install, etc.}

# Copy config templates (if needed)
{cp commands}

# Create database (if needed)
{sql or command}

# Build
{command}

# Run locally (port: {N})
{command}

# Run with migrations
{command}

# Run all tests
{command}

# Run a single test class / file
{command}
```

---

## Key Data Flows

1. **{Flow name}:** {entry point} → {service} → {persistence/external} → {response/event}
2. **{Flow name}:** {step 1} → {step 2} → {step 3}
3. **{Flow name}:** {step 1} → {step 2} → {step 3}

---

## Notes

{Non-obvious facts a new team member must know:}
- {Gotcha 1}
- {URL versioning note if mixed}
- {Cert or credential setup required locally}
- {Known tech debt hotspots}
- {Port numbers, artifact registry access, etc.}
```
