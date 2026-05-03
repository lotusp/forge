#!/usr/bin/env bash
#
# install-hooks.sh — install repo git hooks into .git/hooks/.
#
# Run once after cloning:
#   scripts/install-hooks.sh
#
# Currently installs:
#   - pre-commit  → runs the project-leakage lint on staged changes,
#                   blocks the commit if any keyword is matched.
#
# .git/hooks/ is NOT tracked by git, so each clone needs to run this
# installer once. Re-running is safe (overwrites the hook).

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$REPO_ROOT" ]; then
  echo "ERROR: not inside a git repository" >&2
  exit 1
fi

HOOKS_DIR="$REPO_ROOT/.git/hooks"
mkdir -p "$HOOKS_DIR"

cat > "$HOOKS_DIR/pre-commit" <<'EOF'
#!/usr/bin/env bash
# Auto-installed by scripts/install-hooks.sh — do not edit by hand.
# Blocks commits that introduce project-specific identifiers.
# To bypass in an emergency: git commit --no-verify (use sparingly,
# and run scripts/lint-no-project-leakage.sh --history afterwards).

set -e

REPO_ROOT="$(git rev-parse --show-toplevel)"
LINT="$REPO_ROOT/scripts/lint-no-project-leakage.sh"

if [ ! -x "$LINT" ]; then
  echo "pre-commit: lint script missing or not executable: $LINT" >&2
  echo "pre-commit: skipping leakage check" >&2
  exit 0
fi

if [ ! -f "$REPO_ROOT/.lint-keywords" ]; then
  cat >&2 <<MSG
pre-commit: WARNING — $REPO_ROOT/.lint-keywords is missing.

The project-leakage lint requires a local keyword list (gitignored,
per-developer). Without it, the hook cannot check for downstream
project identifiers in your staged changes.

Create one with:
  touch $REPO_ROOT/.lint-keywords
  echo "your-project-name" >> $REPO_ROOT/.lint-keywords

The commit will proceed, but you are responsible for not introducing
sensitive identifiers.
MSG
  exit 0
fi

if "$LINT" --staged; then
  exit 0
else
  cat >&2 <<MSG

✗ pre-commit BLOCKED: project-leakage detected in staged changes.

The lines above match a keyword in .lint-keywords. Either:
  1. Remove / rephrase the offending content, then re-stage and re-commit
  2. Verify it's a false positive and refine .lint-keywords accordingly
  3. Bypass (DISCOURAGED): git commit --no-verify

Bypassing leaves sensitive content in history; rewriting later requires
git filter-repo + force-push (see CLAUDE.md § "Project Neutrality").
MSG
  exit 1
fi
EOF

chmod +x "$HOOKS_DIR/pre-commit"
echo "✓ installed pre-commit hook → $HOOKS_DIR/pre-commit"

# Self-test: run the lint on staged changes once.
if "$REPO_ROOT/scripts/lint-no-project-leakage.sh" --staged 2>/dev/null; then
  echo "✓ self-test passed (no staged leaks)"
else
  echo "⚠ self-test reported staged leaks — review before next commit" >&2
fi
