---
kind-id: web-frontend
display-name: Web Frontend (SPA)
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
    - dimensions/authentication
    - dimensions/commit-format
    - dimensions/delivery-conventions
  testing:
    - dimensions/testing-strategy
  architecture:
    - dimensions/architecture-layers
  constraints:
    - dimensions/hard-constraints
    - dimensions/anti-patterns
    - dimensions/delivery-conventions
excluded-dimensions:
  - api-design
  - database-access
  - messaging
  - skill-format
  - artifact-writing
  - markdown-conventions
---

# Context Kind: Web Frontend (SPA)

## When this kind applies

Browser-delivered applications: React / Vue / Angular / Svelte / Solid /
Preact + a bundler (Vite / Webpack / Next.js / Nuxt / Remix / Astro).
The project **consumes** APIs; it does not design them.

## Context file strategy

- **conventions.md** — naming + error handling (error boundaries / toast
  patterns) + client-side logging (console policy + Sentry-like) + form
  validation (Zod / Yup / react-hook-form) + auth from client POV (token
  storage / refresh flow) + commit format. Focus on UI-layer concerns.
- **testing.md** — component / integration / E2E tiered strategy. Common
  frameworks: Vitest / Jest / Testing Library / Playwright / Cypress.
  Include what-to-mock guidance (API calls, timers, window APIs).
- **architecture.md** — typical SPA layering (pages/routes / components /
  hooks / stores / services). State-management library if relevant
  (Redux / Zustand / Pinia / MobX / Recoil / Jotai). Routing scheme.
- **constraints.md** — hard rules (no secrets in bundled code; no direct
  DOM manipulation bypassing the framework; accessibility floor) +
  anti-patterns.

## Excluded dimensions — rationale

- **api-design** — frontend consumes APIs; does not design them. API
  consumption patterns (client wrapper / error handling / retry / cache)
  belong in `conventions.md`'s error-handling or a dedicated sub-section;
  they're not a standalone dimension in v0.5.
- **database-access** — no direct DB access; all persistence via backend
  APIs.
- **messaging** — no direct message-queue access; server events reach
  the frontend via WebSocket / SSE / polling (which if used should be
  noted in architecture.md's data flows, not as a separate dimension).
- **skill-format / artifact-writing / markdown-conventions** — these are
  Claude Code plugin concerns; not applicable to a frontend project.

## Forward extensions (not MVP)

Possible future dimensions specific to web-frontend:
- `component-conventions` — component naming / file structure / prop API
- `state-management` — Redux vs Zustand vs Context patterns
- `styling-conventions` — CSS Modules vs Tailwind vs styled-components
- `accessibility` — a11y floor / aria conventions / keyboard navigation
- `bundle-strategy` — code splitting / lazy loading / tree shaking rules

For MVP (v0.5.0) these concerns live inline inside `conventions.md`'s
generic sections. If a frontend project accumulates enough
state-management conventions to warrant a dedicated dimension, add it
via `Adding a New Dimension` flow in `profiles/context/README.md`.
