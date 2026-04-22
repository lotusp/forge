---
name: deployment
section: Deployment
applies-to:
  - web-backend
  - monorepo
confidence-signals:
  - Dockerfile present
  - k8s/ or kubernetes/ or helm/ directory
  - terraform/ or infra/ or deploy/ directory
  - deploy workflow in CI (release.yml / deploy.yml)
token-budget: 900
---

# Profile: Deployment

## Scan Patterns

**Containerization:**

- `Dockerfile` — extract base image, exposed ports, CMD/ENTRYPOINT
- `docker-compose.yml` — local / dev stack (may differ from prod)
- `docker-bake.hcl` — multi-target builds

**Orchestration manifests:**

- `k8s/` / `kubernetes/` / `manifests/` — raw YAML
- `helm/` / `charts/` — Helm charts (look for `Chart.yaml`)
- `kustomize/` — Kustomize overlays

**Infrastructure as code:**

- `terraform/` / `infra/` — Terraform modules
- `pulumi/` — Pulumi programs
- `cdk/` — AWS CDK

**Platform-specific signals:**

- `vercel.json` / `.vercel/` — Vercel
- `netlify.toml` — Netlify
- `fly.toml` — Fly.io
- `railway.json` — Railway
- `render.yaml` — Render
- `app.yaml` — Google App Engine
- `Procfile` — Heroku / Heroku-likes

**Deploy workflow:**

- `.github/workflows/deploy.yml` / `release.yml`
- `.gitlab-ci.yml` `deploy` stages

## Extraction Rules

1. **State the deploy target** — platform or infrastructure kind (k8s / serverless / VM /
   platform-as-a-service).
2. **Environments list** — dev / staging / prod identified from manifests or CI envs.
   **Redact** specific cluster / project / account identifiers (follow C8) — use
   generic placeholders.
3. **Deploy trigger** — manual / tag push / merge to main / scheduled.
4. **Rollback mechanism** — if documented (blue-green / canary / rolling).
5. **Skip if project is a library** — no deployment, omit the section.
6. **Monorepo note** — if multiple services deploy from one repo, list service names only
   (no per-service detail; that belongs in sub-package onboards).

## Section Template

```markdown
## Deployment

- **Target:** Kubernetes via Helm chart in `helm/orders-api/` [high]
- **Environments:** `dev`, `staging`, `production` (separate namespaces) [high]
- **Deploy trigger:** tag push `v*` → `.github/workflows/deploy.yml` → promotes
  staging → prod after manual approval [high]
- **Image registry:** configured via `DEPLOY_REGISTRY` env var (value redacted per
  Content Hygiene) [medium]
- **Rollback:** Helm `--atomic` with automatic revert on failed readiness probe;
  manual `helm rollback` for post-deploy issues [medium]
- **Infrastructure:** Terraform modules in `infra/terraform/` manage cluster + RDS +
  Redis; applied via separate workflow not in this repo [medium]
```

## Confidence Tags

- `[high]` — deploy config file read, environments enumerated
- `[medium]` — platform identified but specifics inferred
- `[low]` — directory exists without manifest inspection
- `[inferred]` — avoid
