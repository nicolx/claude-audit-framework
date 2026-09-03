#!/bin/bash
# qa.sh — the framework's quality gate, in one command.
#
# Subcriteria 7.7 asks for exactly this, and until it existed the gate was three
# commands in CLAUDE.md, four jobs in CI, and the documented list omitted one of
# them — so a developer could run the gate as written and still go red.
#
#   bash scripts/qa.sh
#
# Exit codes:  0 all checks passed · 1 a check failed · 2 a check could not run

set -uo pipefail

cd "$(git rev-parse --show-toplevel)" || exit 2

FAILED=""
SKIPPED=""

run() {
    local name="$1"; shift
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
    # Pinned to 0.11.0 in CI because versions report different codes for the same
    # finding; a local mismatch is a warning, not a failure.
    LOCAL_SC=$(shellcheck --version | awk '/^version:/ { print $2 }')
    [ "$LOCAL_SC" = "0.11.0" ] ||
        echo "  ⚠  local shellcheck is $LOCAL_SC; CI pins 0.11.0 — findings may differ"
    run "shellcheck" shellcheck scripts/*.sh templates/hooks/*.sh || true
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
    echo "   CI runs all four, so this is not a clean bill of health."
    exit 2
fi
echo "✅ All four checks passed."
exit 0
