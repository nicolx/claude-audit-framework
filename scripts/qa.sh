#!/bin/bash
# qa.sh — the framework's quality gate: every check CI runs, in one command.
#
#   bash scripts/qa.sh
#
# Exit codes:  0 all checks passed · 1 a check failed · 2 a check could not run

set -uo pipefail

for arg in "$@"; do
    case "$arg" in
        *) echo "❌ Unknown option: $arg"
           echo "   qa.sh takes no options — it always runs the whole gate."
           exit 2 ;;
    esac
done

# Resolved from $0 so the gate also runs, and fails with 2, outside a git repo.
# Physical path, because `git rev-parse` returns physical paths on macOS.
SCRIPT_DIR=$(cd -P "$(dirname "$0")" && pwd -P)
REPO_ROOT=$(dirname "$SCRIPT_DIR")

if [ ! -f "$REPO_ROOT/standards/PROJECT_AUDIT_FRAMEWORK.md" ]; then
    echo "❌ $REPO_ROOT is not the claude-audit-framework repository."
    echo "   This is the framework's own gate. A consumer project runs check-install.sh instead."
    exit 2
fi

cd "$REPO_ROOT" || exit 2

if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "❌ $REPO_ROOT is not a git repository — check-consistency.sh needs git ls-files."
    exit 2
fi

FAILED=""
SKIPPED=""
RAN=0

run() {
    local name="$1"; shift
    RAN=$((RAN + 1))
    echo ""
    echo "──────── $name ────────"
    if "$@"; then
        return 0
    fi
    FAILED="$FAILED $name"
    return 1
}

echo "════════════════════════════════════════════════"
echo "🧪 claude-audit-framework — quality gate"
echo "════════════════════════════════════════════════"

run "consistency" bash scripts/check-consistency.sh || true
run "install cycle" bash scripts/test-install-cycle.sh || true

if command -v shellcheck >/dev/null 2>&1; then
    # Versions report different codes for the same finding, so CI pins one.
    LOCAL_SC=$(shellcheck --version | awk '/^version:/ { print $2 }')
    [ "$LOCAL_SC" = "0.11.0" ] ||
        echo "  ⚠  local shellcheck is $LOCAL_SC; CI pins 0.11.0 — findings may differ"
    run "shellcheck" shellcheck -x scripts/*.sh scripts/lib/*.sh templates/hooks/*.sh || true
else
    SKIPPED="$SKIPPED shellcheck"
fi

if command -v npx >/dev/null 2>&1; then
    run "markdownlint" npx --yes markdownlint-cli@0.42.0 --config .markdownlint.json '**/*.md' || true
else
    SKIPPED="$SKIPPED markdownlint"
fi

echo ""
echo "════════════════════════════════════════════════"

if [ -n "$FAILED" ]; then
    echo "❌ Failed:$FAILED"
    [ -n "$SKIPPED" ] && echo "   Not run:$SKIPPED"
    exit 1
fi
if [ -n "$SKIPPED" ]; then
    echo "⚠  Passed what could run. Not run:$SKIPPED"
    echo "   CI runs the full set, so this is not a clean bill of health."
    exit 2
fi
echo "✅ All $RAN checks passed."
exit 0
