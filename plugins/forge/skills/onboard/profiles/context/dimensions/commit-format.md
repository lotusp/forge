---
name: commit-format
output-file: conventions.md
applies-to:
  - web-backend
  - web-frontend
  - plugin
  - monorepo
scan-sources:
  - cli: "git log --pretty=%s -n 100"
  - glob: "CONTRIBUTING.md"
  - glob: ".gitmessage"
  - glob: "**/commit-convention*"
confidence-signals:
  - Conventional Commits format prevalence in `git log`
  - commitlint config present
  - CONTRIBUTING.md documents a commit style
token-budget: 500
---

# Dimension: Commit Message Format

## Scan Patterns

**Recent commit subject lines:**
```
git log --pretty=%s -n 100
  count: subjects matching "^(feat|fix|chore|docs|refactor|test|perf|build)(\\(|\\!|:)"
         → Conventional Commits usage ratio
```

**Config files:**
```
Glob ".commitlintrc*" / "commitlint.config.*"
  → enforced Conventional Commits (high confidence)
Glob ".gitmessage"
  → repo-wide commit template
Read CONTRIBUTING.md  → documented convention
```

**Co-author trailers:**
```
"Co-[Aa]uthored-[Bb]y:"  prevalence in recent commits
  → established convention for paired / AI-assisted work
```

## Extraction Rules

1. If commitlint / enforcement config exists → emit that style with
   `[high]` tag
2. Else, count last 100 commit subjects for Conventional pattern:
   - ≥ 80% match → emit "Conventional Commits" with `[high]`
   - 40–80% → emit "trending toward Conventional" with `[medium]`
   - < 40% → emit "free-form" with `[low]`
3. Extract any project-specific scope list (e.g. `skill/<name>`)
   observed in commit history
4. Note body / footer conventions if any (sign-off, co-author, issue refs)

## Output Template

```markdown
## Commit Message Format

**Style:** <Conventional Commits | Custom | Free-form> [high] [cli]

**Format:**
\`\`\`
<type>(<scope>): <subject>

[body — optional]

[footer — optional]
\`\`\`

**Types used:** <feat / fix / chore / docs / refactor / test / ...>
[high] [cli]

**Scope conventions:**
- <observed scope convention from git log, e.g. `skill/<name>`, `api/<resource>`>
  [medium] [cli]

**Subject rules:**
- <lowercase / imperative / ≤ 72 chars / no period, as observed>
  [high] [cli]

**Body / footer:**
- <Co-Authored-By lines for AI-paired work> [medium] [cli]
- <Issue references `#123` if observed> [low] [cli]

**Example (recent):**
\`\`\`
<one anonymized real example from git log>
\`\`\`
```

## Confidence Tags

- `[high]` — commitlint config present OR ≥ 80% commit subjects match
- `[medium]` — CONTRIBUTING.md documents it OR 40–80% commits match
- `[low]` — pattern inferred from < 40% of recent commits
- `[inferred]` — no evidence; using a recommended default
