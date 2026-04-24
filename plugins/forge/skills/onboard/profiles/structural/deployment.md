---
name: deployment
section: Deployment
applies-to:
  - web-backend
  - web-frontend
  - monorepo
confidence-signals:
  - Dockerfile present
  - k8s/ or kubernetes/ or helm/ directory
  - vercel.json / netlify.toml / render.yaml / Procfile present
  - deploy workflow in CI (release.yml / deploy.yml)
token-budget: 450
---

# Profile: Deployment

## Scan Patterns

**Deploy-shape signals:**

- `Dockerfile` — deployable container target
- `k8s/` / `kubernetes/` / `manifests/` — raw Kubernetes manifests
- `helm/` / `charts/` — Helm chart target
- `vercel.json` / `.vercel/` — Vercel target
- `netlify.toml` — Netlify target
- `render.yaml` — Render target
- `Procfile` — Procfile-style process target
- `.github/workflows/deploy.yml` / `release.yml` — deploy pipeline signal

## Extraction Rules

1. Extract only the **deployment shape** that helps a developer locate deploy
   manifests or understand whether the project is deployable.
2. Prefer a single line of the form `Target: <platform> via <manifest-path>`.
3. Do not emit runtime instructions, rollout procedures, rollback procedures,
   image registries, environment lists, or secret locations.
4. If no direct deploy-shape signal exists, omit the section rather than infer.
5. For monorepos, keep this workspace-level and high level; do not enumerate
   per-service deploy detail.

## Claim Classification Annotations

Each fact extracted by this profile MUST be classified before render.

| Extracted fact type | Claim category | Target artifact | Target section | Min confidence |
|---------------------|----------------|-----------------|----------------|----------------|
| Deploy platform directly evidenced by manifest or workflow | `fact` | `onboard.md` | `## Deployment` | `[high]` |
| Manifest/charts directory locating deploy config | `fact` | `onboard.md` | `## Deployment` | `[high]` |

**Forbidden routes:**

- Deployment commands → omit
- Registry / URL / secret path → omit
- Environment names / promotion flow / rollback mechanics → omit

## Section Template

```markdown
## Deployment

- **Target:** <platform> via `<manifest-path>` [high] [build]
```

## Confidence Tags

- `[high]` — target and manifest path both verified from config/build/workflow files
- `[medium]` — platform is visible but manifest path is indirect
- `[low]` — weak signal only; should usually be omitted
- `[inferred]` — not allowed in this profile's output
