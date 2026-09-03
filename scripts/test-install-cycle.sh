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
    if [ -e "$1" ]; then fail "$1 should not exist"; else pass "$(basename "$1") absent"; fi
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

# indent <text> — prefix every line, so captured output nests under the assertion above.
indent() {
    local pad="         "
    printf '%s%s\n' "$pad" "${1//$'\n'/$'\n'$pad}"
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
    indent "$OUT"
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

# ── Case 6 — hooks are opt-in ────────────────────────────────────────────────

new_case "Default install: no hook, no settings.json"
PROJ=$(new_project)
(cd "$PROJ" && bash .claude/framework/scripts/init-project.sh >/dev/null 2>&1)
expect_absent "$PROJ/.claude/hooks"
expect_absent "$PROJ/.claude/settings.json"
rm -rf "$PROJ"

# ── Case 7 — --with-hooks on a project with no settings.json ─────────────────

new_case "--with-hooks: installs the script and wires settings.json"
PROJ=$(new_project)
(cd "$PROJ" && bash .claude/framework/scripts/init-project.sh --with-hooks >/dev/null 2>&1)
expect_file "$PROJ/.claude/hooks/on-file-edit.sh"
expect_file "$PROJ/.claude/settings.json"
expect_grep "$PROJ/.claude/settings.json" "on-file-edit.sh" "settings.json wires the hook"
expect_grep "$PROJ/.claude/settings.json" "PostToolUse" "hook is on PostToolUse"
if [ -x "$PROJ/.claude/hooks/on-file-edit.sh" ]; then
    pass "hook script is executable"
else
    fail "hook script is not executable"
fi
# The stub must be a silent no-op until configured, whatever it is fed.
OUT=$(echo '{"tool_name":"Edit","tool_input":{"file_path":"'"$PROJ"'/CLAUDE.md"}}' |
      bash "$PROJ/.claude/hooks/on-file-edit.sh" 2>&1)
if [ -z "$OUT" ]; then
    pass "unconfigured hook produces no output"
else
    fail "unconfigured hook wrote output: $OUT"
fi
# --selftest must emit the JSON envelope Claude Code reads context back from.
OUT=$(bash "$PROJ/.claude/hooks/on-file-edit.sh" --selftest 2>&1)
case "$OUT" in
    *'"hookEventName": "PostToolUse"'* | *'"hookEventName":"PostToolUse"'*)
        pass "--selftest emits a valid PostToolUse context envelope" ;;
    *)
        fail "--selftest output is not a PostToolUse envelope: $OUT" ;;
esac

# ── Case 8 — --with-hooks must never clobber an existing settings.json ───────

new_case "--with-hooks: existing settings.json is left untouched"
printf '{\n  "env": { "PROJECT_OWNED": "keep me" }\n}\n' > "$PROJ/.claude/settings.json"
(cd "$PROJ" && bash .claude/framework/scripts/init-project.sh --with-hooks >/dev/null 2>&1)
expect_grep "$PROJ/.claude/settings.json" "PROJECT_OWNED" "project settings preserved"
expect_missing_line "$PROJ/.claude/settings.json" "on-file-edit.sh"

# ── Case 9 — uninstall removes the hook script ───────────────────────────────

new_case "Uninstall: removes the hook script, keeps project settings"
(cd "$PROJ" && bash .claude/framework/scripts/uninstall.sh >/dev/null 2>&1)
expect_absent "$PROJ/.claude/hooks"
expect_grep "$PROJ/.claude/settings.json" "PROJECT_OWNED" "project settings survived uninstall"
rm -rf "$PROJ"

# ── Case 10 — check-updates degrades instead of crashing ─────────────────────

new_case "check-updates.sh: reports cleanly when the framework is not a git checkout"
PROJ=$(new_project)
(cd "$PROJ" && bash .claude/framework/scripts/init-project.sh >/dev/null 2>&1)
# new_project strips the framework's .git, so this exercises the degraded path
OUT=$(cd "$PROJ" && bash .claude/framework/scripts/check-updates.sh --offline 2>&1)
CODE=$?
case "$OUT" in
    *"Not a git checkout of the framework"*)
        pass "detects that git resolved to the project, not the framework" ;;
    *)
        fail "unexpected output:"; indent "$OUT" ;;
esac
if [ "$CODE" -eq 2 ]; then
    pass "exits 2 (cannot tell)"
else
    fail "expected exit 2, got $CODE"
fi
case "$OUT" in
    *"Commands are from"*) pass "still answers the local-drift half" ;;
    *) fail "local drift section missing from output" ;;
esac
rm -rf "$PROJ"

# ── Cases 11–14 — check-install.sh conformance ───────────────────────────────

# run_check <project> — runs check-install.sh there, leaving its exit code in
# $check_code and its combined output in $check_out.
check_out=""
check_code=0
run_check() {
    check_out=$(cd "$1" && bash .claude/framework/scripts/check-install.sh 2>&1)
    check_code=$?
}

new_case "check-install.sh: a fresh install is conformant"
PROJ=$(new_project)
(cd "$PROJ" && bash .claude/framework/scripts/init-project.sh >/dev/null 2>&1)
run_check "$PROJ"
if [ "$check_code" -eq 0 ]; then
    pass "exits 0 on a fresh install"
else
    fail "expected exit 0, got $check_code:"; indent "$check_out"
fi
case "$check_out" in
    *"commands installed and identical"*) pass "verifies the command copies byte-for-byte" ;;
    *) fail "command comparison missing from output" ;;
esac

new_case "check-install.sh: a missing @-include is an error, not a warning"
# The exact failure that prompted this script: submodule updated, include never added
grep -v '@.claude/framework/INSTRUCTIONS.md' "$PROJ/CLAUDE.md" > "$PROJ/CLAUDE.tmp"
mv "$PROJ/CLAUDE.tmp" "$PROJ/CLAUDE.md"
run_check "$PROJ"
if [ "$check_code" -eq 1 ]; then
    pass "exits 1"
else
    fail "expected exit 1, got $check_code"
fi
case "$check_out" in
    *"nothing loads it into a session"*) pass "names the consequence, not just the missing line" ;;
    *) fail "expected the 'nothing loads it' diagnosis:"; indent "$check_out" ;;
esac

new_case "check-install.sh: a pre-1.0 @-include is diagnosed as such"
printf '@.claude/framework/CLAUDE.md\n\n# P\n' > "$PROJ/CLAUDE.md"
run_check "$PROJ"
case "$check_out" in
    *"still includes the pre-1.0 line"*) pass "identifies the legacy include specifically" ;;
    *) fail "expected the pre-1.0 diagnosis:"; indent "$check_out" ;;
esac

new_case "check-install.sh: a hand-edited command copy is detected"
(cd "$PROJ" && bash .claude/framework/scripts/init-project.sh >/dev/null 2>&1)
echo "# edited by hand" >> "$PROJ/.claude/commands/project-audit.md"
run_check "$PROJ"
case "$check_out" in
    *"differs: /project-audit"*) pass "content comparison catches what the version marker cannot" ;;
    *) fail "expected a 'differs' line:"; indent "$check_out" ;;
esac
if [ "$check_code" -eq 1 ]; then
    pass "exits 1"
else
    fail "expected exit 1, got $check_code"
fi
rm -rf "$PROJ"

# ── Case 15 — the breaking-change report survives the documented order ───────
# init-project.sh overwrites the marker before the verification runs, so without
# --compare-from the report has nothing left to compare and never fires.

new_case "Breaking-change report fires during an upgrade, not after"
PROJ=$(new_project)
(cd "$PROJ" && bash .claude/framework/scripts/init-project.sh >/dev/null 2>&1)
printf 'version=0.9.0\n' > "$PROJ/.claude/.framework-version"
OUT=$(cd "$PROJ" && bash .claude/framework/scripts/init-project.sh 2>&1)
case "$OUT" in
    *"breaking changes since 0.9.0"*) pass "init-project reports the breaking range" ;;
    *) fail "init-project did not report breaking changes" ;;
esac
run_check "$PROJ"
case "$check_out" in
    *"breaking changes since"*) fail "standalone check repeats the report after the upgrade" ;;
    *) pass "standalone check does not repeat it" ;;
esac
rm -rf "$PROJ"

# ── Case 16 — an uninitialised submodule must not read as conformant ─────────
# `git clone` without --recurse-submodules is the most common way to arrive here,
# and every check compares vacuously against an empty framework.

new_case "check-install.sh: an empty framework directory is an error, not a pass"
PROJ=$(mktemp -d)
git -C "$PROJ" init --quiet
mkdir -p "$PROJ/.claude/framework/scripts" "$PROJ/.claude/commands"
cp "$FRAMEWORK_SRC/scripts/check-install.sh" "$PROJ/.claude/framework/scripts/"
printf '@.claude/framework/INSTRUCTIONS.md\n\n# P\n' > "$PROJ/CLAUDE.md"
run_check "$PROJ"
if [ "$check_code" -eq 1 ]; then
    pass "exits 1 instead of reporting a vacuous pass"
else
    fail "expected exit 1, got $check_code:"; indent "$check_out"
fi
case "$check_out" in
    *"not checked out"*) pass "names the cause and the fix" ;;
    *) fail "expected the submodule diagnosis:"; indent "$check_out" ;;
esac
case "$check_out" in
    *"All 0 commands"*) fail "still claims 0 commands are in order" ;;
    *) pass "does not compare zero commands against zero" ;;
esac
rm -rf "$PROJ"

# ── Cases 17–22 — mutants that survived the audit's mutation testing ─────────
# Each of these passed a green suite while a real data-loss or load-nothing
# defect was injected, which is why they exist.

new_case "Prepend branch: an existing CLAUDE.md keeps its content and gains the include"
PROJ=$(new_project "$(printf '# Their Project\n\nTheir own instructions.\n')")
(cd "$PROJ" && bash .claude/framework/scripts/init-project.sh >/dev/null 2>&1)
expect_count "$PROJ/CLAUDE.md" "@.claude/framework/INSTRUCTIONS.md" 1
expect_grep "$PROJ/CLAUDE.md" "# Their Project" "existing heading preserved"
expect_grep "$PROJ/CLAUDE.md" "Their own instructions." "existing body preserved"
if [ "$(head -1 "$PROJ/CLAUDE.md")" = "@.claude/framework/INSTRUCTIONS.md" ]; then
    pass "include is the first line"
else
    fail "include is not the first line: $(head -1 "$PROJ/CLAUDE.md")"
fi

new_case "Second run must not overwrite a specialization file the developer edited"
echo "# MY OWN RULES" >> "$PROJ/.claude/CODING_STANDARDS.md"
echo "# MY OWN CRITERIA" >> "$PROJ/.claude/PROJECT_AUDIT_FRAMEWORK.md"
(cd "$PROJ" && bash .claude/framework/scripts/init-project.sh >/dev/null 2>&1)
expect_grep "$PROJ/.claude/CODING_STANDARDS.md" "# MY OWN RULES" "edited CODING_STANDARDS survives"
expect_grep "$PROJ/.claude/PROJECT_AUDIT_FRAMEWORK.md" "# MY OWN CRITERIA" "edited PROJECT_AUDIT_FRAMEWORK survives"

new_case "Uninstall strips its own .gitattributes line and keeps the project's"
printf '*.php diff=php\n' >> "$PROJ/.gitattributes"
(cd "$PROJ" && bash .claude/framework/scripts/uninstall.sh >/dev/null 2>&1)
expect_file "$PROJ/.gitattributes"
expect_grep "$PROJ/.gitattributes" "*.php diff=php" "project's own attribute kept"
expect_missing_line "$PROJ/.gitattributes" ".claude/ export-ignore"
rm -rf "$PROJ"

new_case "init-project.sh propagates failure instead of exiting 0 after printing ❌"
PROJ=$(new_project)
(cd "$PROJ" && bash .claude/framework/scripts/init-project.sh >/dev/null 2>&1)
# Make the install non-conformant in a way init-project cannot repair
rm "$PROJ/.claude/commands/project-audit.md"
printf 'version=0.0.1\n' > "$PROJ/.claude/.framework-version"
chmod -w "$PROJ/.claude/commands" 2>/dev/null
OUT=$(cd "$PROJ" && bash .claude/framework/scripts/init-project.sh 2>&1)
CODE=$?
chmod +w "$PROJ/.claude/commands" 2>/dev/null
if [ "$CODE" -ne 0 ]; then
    pass "non-zero exit when the install is not conformant ($CODE)"
else
    case "$OUT" in
        *"❌"*) fail "printed ❌ and still exited 0 — the && chain cannot break" ;;
        *)      pass "install repaired itself, exit 0 is correct" ;;
    esac
fi
rm -rf "$PROJ"

new_case "uninstall.sh refuses an unknown option instead of removing anyway"
PROJ=$(new_project)
(cd "$PROJ" && bash .claude/framework/scripts/init-project.sh >/dev/null 2>&1)
OUT=$(cd "$PROJ" && bash .claude/framework/scripts/uninstall.sh --dry-run 2>&1)
CODE=$?
if [ "$CODE" -eq 2 ]; then
    pass "exits 2 on an unknown option"
else
    fail "expected exit 2, got $CODE"
fi
expect_file "$PROJ/.claude/commands/project-audit.md"
expect_grep "$PROJ/CLAUDE.md" "@.claude/framework/INSTRUCTIONS.md" "nothing was removed"
rm -rf "$PROJ"

new_case "check-consistency.sh cannot pass vacuously when its own extraction breaks"
# The gate script had the exact vacuity bug case 16 was written to kill: break the
# path-extraction regex and it reported "all 1 cited paths resolve", exit 0.
SANDBOX=$(mktemp -d)
cp -R "$FRAMEWORK_SRC/." "$SANDBOX/" 2>/dev/null
if [ -d "$SANDBOX/.git" ] && [ -f "$SANDBOX/scripts/check-consistency.sh" ]; then
    OUT=$(cd "$SANDBOX" && bash scripts/check-consistency.sh 2>&1)
    case "$OUT" in
        *"cited framework paths resolve"*) pass "reports how many paths it actually checked" ;;
        *) fail "no path count in output" ;;
    esac
    COUNT=$(printf '%s' "$OUT" | grep -oE 'all [0-9]+ cited framework paths' | grep -oE '[0-9]+')
    if [ "${COUNT:-0}" -ge 5 ]; then
        pass "checked $COUNT framework paths, not a vacuous handful"
    else
        fail "only $COUNT framework paths checked — extraction is probably broken"
    fi
else
    pass "skipped — sandbox copy incomplete"
fi
rm -rf "$SANDBOX"

# ── Summary ──────────────────────────────────────────────────────────────────

echo ""
echo "────────────────────────────────────────────────"
if [ "$FAILURES" -eq 0 ]; then
    echo "✅ $CASES cases passed."
    exit 0
fi
echo "❌ $FAILURES assertion failure(s) across $CASES cases."
exit 1
