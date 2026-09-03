#!/bin/bash
# test-install-cycle.sh — exercise init-project.sh and uninstall.sh against throwaway projects.
#
# Covers the behaviours that are easy to break and expensive to notice: idempotency, the
# pre-1.0 @-include migration, and uninstall leaving project-owned files alone. Runs on
# macOS and Linux — which is the point, since the scripts edit files in place.
#
#   bash scripts/test-install-cycle.sh [framework-dir]

set -uo pipefail

FRAMEWORK_SRC="${1:-$(git rev-parse --show-toplevel)}"
FAILURES=0
CASES=0

pass() { echo "    ✓  $1"; }
fail() { echo "    ✗  $1"; FAILURES=$((FAILURES + 1)); }

expect_file() {
    if [ -f "$1" ]; then pass "$(basename "$1") exists"; else fail "$1 is missing"; fi
}

expect_absent() {
    if [ -e "$1" ]; then fail "$1 should have been removed"; else pass "$(basename "$1") removed"; fi
}

expect_dir() {
    if [ -d "$1" ]; then pass "$(basename "$1")/ kept"; else fail "$1/ should have been kept"; fi
}

# expect_grep <file> <fixed-string> <description>
expect_grep() {
    if grep -qF "$2" "$1" 2>/dev/null; then pass "$3"; else fail "$3 — '$2' not found in $1"; fi
}

expect_count() {
    local file="$1" pattern="$2" want="$3" got
    got=$(grep -cF "$pattern" "$file" 2>/dev/null || true)
    if [ "$got" -eq "$want" ]; then
        pass "'$pattern' appears $want time(s) in $(basename "$file")"
    else
        fail "'$pattern' appears $got time(s) in $(basename "$file"), expected $want"
    fi
}

expect_missing_line() {
    if grep -qF "$2" "$1" 2>/dev/null; then
        fail "'$2' should not be present in $(basename "$1")"
    else
        pass "'$2' absent from $(basename "$1")"
    fi
}

# new_project [existing-claude-md-content] — a git repo with the framework mounted
# where a submodule would put it. Echoes the project path.
new_project() {
    local dir
    dir=$(mktemp -d)
    git -C "$dir" init --quiet
    git -C "$dir" config user.email test@example.com
    git -C "$dir" config user.name Test
    mkdir -p "$dir/.claude"
    cp -R "$FRAMEWORK_SRC" "$dir/.claude/framework"
    rm -rf "$dir/.claude/framework/.git"
    if [ $# -eq 1 ]; then
        printf '%s\n' "$1" > "$dir/CLAUDE.md"
    fi
    echo "$dir"
}

new_case() {
    CASES=$((CASES + 1))
    echo ""
    echo "  [$CASES] $1"
}

echo "────────────────────────────────────────────────"
echo "🧪 install / uninstall cycle"
echo "   framework: $FRAMEWORK_SRC"
echo "────────────────────────────────────────────────"

# ── Case 1 — fresh project, no CLAUDE.md ─────────────────────────────────────

new_case "Fresh project: scaffolds everything, reports no errors"
PROJ=$(new_project)
OUT=$(cd "$PROJ" && bash .claude/framework/scripts/init-project.sh 2>&1)
if echo "$OUT" | grep -q "0 error"; then
    pass "no errors reported"
elif echo "$OUT" | grep -qE "^✅"; then
    pass "reported success"
else
    fail "init reported errors:"
    echo "$OUT" | sed 's/^/         /'
fi
expect_file "$PROJ/CLAUDE.md"
expect_file "$PROJ/.claude/PROJECT_AUDIT_FRAMEWORK.md"
expect_file "$PROJ/.claude/CODING_STANDARDS.md"
expect_file "$PROJ/.claude/commands/project-audit.md"
expect_file "$PROJ/.claude/.framework-version"
expect_count "$PROJ/CLAUDE.md" "@.claude/framework/INSTRUCTIONS.md" 1
expect_grep "$PROJ/.claude/.framework-version" "version=1" "version marker records a version"

# ── Case 2 — same project, run again ─────────────────────────────────────────

new_case "Second run: idempotent, no duplicated include"
(cd "$PROJ" && bash .claude/framework/scripts/init-project.sh >/dev/null 2>&1)
expect_count "$PROJ/CLAUDE.md" "@.claude/framework/INSTRUCTIONS.md" 1
expect_count "$PROJ/.gitattributes" ".claude/ export-ignore" 1
rm -rf "$PROJ"

# ── Case 3 — pre-1.0 install ─────────────────────────────────────────────────

new_case "Pre-1.0 install: migrates the @-include in place"
PROJ=$(new_project "$(printf '@.claude/framework/CLAUDE.md\n\n# My Project\n\nSome context.')")
(cd "$PROJ" && bash .claude/framework/scripts/init-project.sh >/dev/null 2>&1)
expect_count "$PROJ/CLAUDE.md" "@.claude/framework/INSTRUCTIONS.md" 1
expect_missing_line "$PROJ/CLAUDE.md" "@.claude/framework/CLAUDE.md"
expect_grep "$PROJ/CLAUDE.md" "# My Project" "existing project content preserved"

# ── Case 4 — uninstall with a project-owned command present ──────────────────

new_case "Uninstall: removes only framework files"
echo "project's own command" > "$PROJ/.claude/commands/deploy.md"
(cd "$PROJ" && bash .claude/framework/scripts/uninstall.sh >/dev/null 2>&1)
expect_absent "$PROJ/.claude/commands/project-audit.md"
expect_absent "$PROJ/.claude/commands/competency-review.md"
expect_absent "$PROJ/.claude/PROJECT_AUDIT_FRAMEWORK.md"
expect_absent "$PROJ/.claude/.framework-version"
expect_file "$PROJ/.claude/commands/deploy.md"
expect_dir "$PROJ/.claude/commands"
expect_missing_line "$PROJ/CLAUDE.md" "@.claude/framework/"
expect_grep "$PROJ/CLAUDE.md" "# My Project" "project content survived uninstall"
expect_absent "$PROJ/.gitattributes"
rm -rf "$PROJ"

# ── Case 5 — uninstall with nothing project-owned ────────────────────────────

new_case "Uninstall: removes the commands directory when it ends up empty"
PROJ=$(new_project)
(cd "$PROJ" && bash .claude/framework/scripts/init-project.sh >/dev/null 2>&1)
(cd "$PROJ" && bash .claude/framework/scripts/uninstall.sh >/dev/null 2>&1)
expect_absent "$PROJ/.claude/commands"
rm -rf "$PROJ"

# ── Summary ──────────────────────────────────────────────────────────────────

echo ""
echo "────────────────────────────────────────────────"
if [ "$FAILURES" -eq 0 ]; then
    echo "✅ $CASES cases passed."
    exit 0
fi
echo "❌ $FAILURES assertion failure(s) across $CASES cases."
exit 1
