---
name: testing-strategy
output-file: testing.md
applies-to:
  - web-backend
  - claude-code-plugin
  - monorepo
scan-sources:
  - glob: "**/*.test.{ts,js}"
  - glob: "**/*_test.{go,py}"
  - glob: "**/test/**/*.java"
  - glob: "jest.config.*"
  - glob: "vitest.config.*"
  - glob: "pytest.ini"
  - glob: "Cargo.toml"
  - glob: ".forge/features/*/verification.md"
confidence-signals:
  - test framework declared in package.json / pom.xml / go.mod
  - CI pipeline runs tests (`test` job in workflow YAML)
  - tests/ directory or *.test.* files present (≥ 5)
  - self-bootstrap verification.md files in .forge/features/ (plugin kind)
token-budget: 1200
---

# Dimension: Testing Strategy

## Scan Patterns

**Test framework detection (universal):**

| Evidence | Framework |
|----------|-----------|
| `jest.config.*`, `.babelrc-jest.*` | Jest |
| `vitest.config.*` | Vitest |
| `pytest.ini`, `conftest.py` | pytest |
| JUnit `@Test` annotation | JUnit |
| Go `*_test.go` | Go testing |
| `Cargo.toml [dev-dependencies]` with `criterion` / `proptest` | Rust |

**Test co-location pattern:**
- `*.test.*` next to source → co-located convention
- `tests/` / `test/` dir at root → separated convention

**Mock level detection:**
- `jest.mock(...)` calls → module-level mocks (JS)
- `@MockBean` / `@Mock` → Spring/Mockito
- `unittest.mock.patch` → Python
- Absence of mocks + presence of `testcontainers` → integration-heavy

**For claude-code-plugin kind:**
- No traditional tests expected; look instead for:
  - `.forge/features/*/verification.md` files → self-bootstrap verification records
  - Test scenarios scripted in markdown
  - Dry-run invocation logs in JOURNAL.md

## Extraction Rules

1. Identify primary test framework + secondary (if any)
2. Determine co-location vs separated convention
3. Enumerate mock strategy (module / service / repository / none)
4. Detect coverage tooling (`coverage.py`, `jacoco`, `c8`, `nyc`) and
   any declared threshold
5. For plugin kind: describe self-bootstrap workflow in lieu of
   traditional testing; catalogue existing verification reports
6. Detect fixtures / factories / test data conventions

## Output Template

### Output Template — claude-code-plugin

```markdown
## Testing Strategy

**Testing paradigm:** Self-bootstrap verification

Traditional unit tests are not applicable to skill / agent markdown
files. Verification is performed by running the plugin against itself
or a representative sample project and observing the produced artifacts.

### Verification workflow

- Each significant feature produces a `verification.md` report under
  `.forge/features/<slug>/` [high] [code]
- Report captures: kind detection result, artifact compliance checks,
  preserve-block survival, Success Criteria coverage [high] [code]
- Before shipping a new SKILL.md change, run `/forge:<skill>` against
  the forge repo itself as smoke test [medium] [readme]

### Evidence level

- **Skill behaviour changes** — require new verification.md
- **Profile / reference file changes** — may share existing verification
- **Bugfix** — should add a reproduction case to the relevant
  verification.md

### What to avoid

- Declaring a skill "works" without running it
- Skipping verification because "the change is small"
- Trusting human walkthrough as sufficient proof (only LLM execution
  matches real LLM misinterpretation patterns — lesson from
  onboard-kind-profiles T012/T012a/T012b evolution)
```

### Output Template — web-backend / monorepo

```markdown
## Testing Strategy

**Primary framework:** <Jest / JUnit / pytest / Go testing / ...> [high] [build]
**Secondary framework:** <if any, e.g. Playwright for E2E> [medium] [build]

### File layout

- Unit tests: <co-located `*.test.ts` | `tests/unit/`> [high] [code]
- Integration tests: <path> [high] [code]
- E2E tests: <path, if present> [medium] [code]

### Naming

- Describe / it pattern: `describe("<Class>", ...)` →
  `it("should <behaviour> when <condition>")` [high] [code]
- Go: `TestXxx_<Scenario>` [high] [code]

### Mock strategy

- Level: <module | service | repository | no mocks> [high] [code]
- Library: <jest.mock / Mockito / unittest.mock / gomock> [high] [build]
- External services: <always mocked | integration tests allowed> [medium] [code]

### Test data

- Factories: <path to factories, e.g. `tests/factories/`> [medium] [code]
- Fixtures: <yaml / json / programmatic> [medium] [code]

### Coverage

- Tooling: <coverage.py / jacoco / nyc / c8> [high] [build]
- Threshold: <N%> [medium] [build]
- Gated in CI: <yes / no> [high] [build]

### What to avoid

- Writing tests against implementation details (use public API only)
- Over-mocking (test becomes tautological)
- Flaky time-dependent tests without clock abstraction
```

## Confidence Tags

- `[high]` — framework declared in build config AND CI gates tests
- `[medium]` — framework in use but coverage / mocking not consistent
- `[low]` — minimal test coverage; strategy inferred from < 5 test files
- `[inferred]` — strategy recommended based on framework defaults without
                 observed tests
