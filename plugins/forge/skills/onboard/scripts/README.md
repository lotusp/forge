# onboard skill — validator scripts

Bash-implemented validator and helpers backing Step 6.5 (Self-validation pass).

## Layout

```
scripts/
├── preflight.sh                    Tool / dependency check; runs first
├── validate-onboard-artifacts.sh   Main entry; orchestrates all checks
├── lib/                            Shared helpers (sourced or piped)
│   ├── skill-root.sh               Locates this skill's root directory
│   ├── hash.sh                     Cross-platform SHA-256 (sha256sum / shasum)
│   ├── canonicalize.sh             Body canonicalization for signature input
│   ├── stats.sh                    Atomic JSON updates for .validation-stats.json
│   └── artifact-parser.sh          Stable markdown API (no naked sed)
└── checks/                         Per-check scripts (alpha covers a subset)
    ├── check1_marker_structural.sh   R9 marker regex validation
    ├── check3_redaction.sh           R17 internal-host / secret redactor
    └── check4_signature_recompute.sh body-signature recompute + repair
```

beta and final phases add more detectors and checks; see the dev plan
(`forge-onboard-dev-plan-claude-20260501.md`) for the full task list.

## Exit Code Convention

All scripts here return:

- `0` — clean
- `1` — warning (auto-repaired or non-fatal)
- `2` — hard halt (unrecoverable)

The main validator dispatches by exit code, **not by script name**, so
each script owns its own severity decision.

## Cross-platform Notes

- `sha256sum` (Linux) and `shasum -a 256` (macOS) are auto-detected by
  `lib/hash.sh`. No platform-specific assumptions in callers.
- `jq` and `perl` are required; `preflight.sh` enforces this on first run.
- Scripts must remain `shellcheck` clean and avoid GNU-only flags.
