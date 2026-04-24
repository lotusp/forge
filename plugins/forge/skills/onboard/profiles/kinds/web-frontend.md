---
kind-id: web-frontend
display-name: Web Frontend (SPA)
detection-signals:
  positive:
    - pattern: "package.json dependencies contain react | vue | @angular/core | svelte | solid-js | preact"
      weight: 0.35
    - pattern: "vite.config.* | webpack.config.* | next.config.* | nuxt.config.* | remix.config.* | astro.config.* present"
      weight: 0.20
    - pattern: "index.html at repo root OR public/"
      weight: 0.15
    - pattern: "src/ contains pages/ OR routes/ OR components/ subdirectories"
      weight: 0.15
    - pattern: "package.json scripts include 'dev' + 'build' targeting a bundler"
      weight: 0.10
    - pattern: "tailwind.config.* | *.module.css | styled-components | emotion dep present"
      weight: 0.05
  negative:
    - pattern: ".claude-plugin/plugin.json OR plugins/*/.claude-plugin/plugin.json present"
      weight: 0.40
    - pattern: "HTTP server framework in deps (express | fastify | koa | nestjs | spring-boot)"
      weight: 0.30
    - pattern: "database migration directory (db/migrations | prisma/migrations | migrations/*.sql)"
      weight: 0.20
    - pattern: "workspace declaration (pnpm-workspace.yaml | turbo.json | nx.json | go.work)"
      weight: 0.15
profiles:
  - core/tech-stack
  - core/module-map
  - core/entry-points
  - core/local-dev
  - core/data-flows
  - core/notes
  - structural/build-system
  - structural/config-management
  - structural/deployment
  - integration/third-party-apis
  - integration/auth
output-sections:
  - What This Is
  - Tech Stack
  - Module Map
  - Entry Points
  - Third-Party Integrations
  - Authentication & Authorization
  - Build System
  - Configuration
  - Deployment
  - Local Development
  - Key Data Flows
  - Notes
---

# Kind: Web Frontend (SPA)

## When to Use

Apply when the project's primary product is a browser-delivered application
(SPA or SSR-hybrid) that consumes APIs rather than serving them. Typical
signals:

- Frontend framework in dependencies (React / Vue / Angular / Svelte / Solid /
  Preact / similar)
- Bundler config (Vite / Webpack / Next.js / Nuxt / Remix / Astro)
- `index.html` at root or `public/`
- `src/` contains `pages/` / `routes/` / `components/` layout
- Has `build` script that outputs static assets

**Not this kind:**
- Full-stack framework (Next.js with API routes is ambiguous — if API routes
  are the primary concern, use `web-backend`; if UI is primary, use `web-frontend`
  and note API routes in `Notes`)
- Plugins / SDKs / libraries (no bundled application)
- Claude Code plugin (uses `plugin` kind)

## Execution Notes

- **Entry points are client-side** — routes (React Router / Vue Router / file-
  based routing), not HTTP endpoints. The `core/entry-points` profile should
  enumerate routes and major event handlers, not server endpoints.
- **`api-design` is excluded** — frontend **consumes** APIs rather than
  designing them. API consumption conventions belong in `conventions.md` via
  the `integration/third-party-apis` profile or a dedicated "API Client
  Conventions" section within `Notes`.
- **`database-access` and `messaging` are excluded** — frontend has no direct
  DB or message-queue access.
- **Auth from the frontend perspective** — `integration/auth` profile covers
  how the frontend stores tokens / refreshes sessions / displays login UI,
  NOT how authentication is implemented server-side.
- **Third-party integrations** tend to be analytics (GA / Segment / Mixpanel),
  error tracking (Sentry), payment widgets (Stripe Elements), feature flags
  (LaunchDarkly), etc. — redact specific tenant identifiers per C8.
- **Deployment** is usually static-hosting (Vercel / Netlify / CloudFront /
  GitHub Pages), not container/VM-based. The `structural/deployment` profile
  should reflect this.

## Excluded Profiles

- `entry-points/http-api` — frontend does not serve HTTP
- `entry-points/event-consumers` — frontend does not consume backend events
- `model/domain-model` — frontend has no server-side domain model (it may
  have view models / stores, but those are covered in `architecture.md`)
- `model/db-schema` — no database
- `integration/messaging` — no message queue consumption
- `monorepo/workspace-layout` — use `monorepo` kind instead if the repo is a
  workspace containing a frontend sub-package
