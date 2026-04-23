---
kind-id: web-backend
display-name: Web Backend Service
output-files:
  - conventions.md
  - testing.md
  - architecture.md
  - constraints.md
dimensions-loaded:
  conventions:
    - dimensions/naming
    - dimensions/error-handling
    - dimensions/logging
    - dimensions/validation
    - dimensions/api-design
    - dimensions/database-access
    - dimensions/messaging
    - dimensions/authentication
    - dimensions/commit-format
  testing:
    - dimensions/testing-strategy
  architecture:
    - dimensions/architecture-layers
  constraints:
    - dimensions/hard-constraints
    - dimensions/anti-patterns
excluded-dimensions:
  - skill-format
  - artifact-writing
  - markdown-conventions
---

# Context Kind: Web Backend Service

## When this kind applies

Projects whose primary product is a deployable service accepting inbound
requests and persisting state. Typical signals:

- HTTP / gRPC routes (Express, Spring, Gin, FastAPI, etc.)
- A datastore (relational DB, document store, state backend)
- Container or long-running VM deployment
- Non-trivial business domain model

## Context file strategy

- **conventions.md** — full stack of engineering conventions (naming, errors,
  logging, validation, API, DB, messaging, auth, commits). The richest file
  for this kind.
- **testing.md** — traditional framework + mocking strategy + coverage
  expectations. Real automated tests are expected.
- **architecture.md** — layered architecture (controllers / services /
  repositories or equivalent). Inter-module dependency rules.
- **constraints.md** — hard rules (no SQL in controllers, no business logic
  in handlers, etc.) + observed anti-patterns.

## Excluded dimensions — rationale

- **skill-format / artifact-writing / markdown-conventions** — 这些仅对
  Claude Code plugin 项目有意义。Web 后端项目内不存在 SKILL.md / .forge/
  产物写入纪律 / plugin 级 markdown 风格问题。
