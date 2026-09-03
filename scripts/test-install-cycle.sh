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

# new_submodule_project — a project with the framework added as a REAL git submodule
# from a local upstream carrying tags. Echoes "<project> <upstream>".
# This is the fixture the suite lacked: without it everything from
# check-updates.sh's fetch onwards was unreachable, including a security fix.
new_submodule_project() {
    local root up proj
    root=$(mktemp -d)
    up="$root/upstream"
    proj="$root/project"

    git init -q "$up"
    git -C "$up" config user.email test@example.com
    git -C "$up" config user.name Test
    mkdir -p "$up/scripts" "$up/commands" "$up/templates" "$up/standards"
    cp -R "$FRAMEWORK_SRC/scripts/." "$up/scripts/"
    cp -R "$FRAMEWORK_SRC/commands/." "$up/commands/"
    cp -R "$FRAMEWORK_SRC/templates/." "$up/templates/"
    cp -R "$FRAMEWORK_SRC/standards/." "$up/standards/"
    cp "$FRAMEWORK_SRC/INSTRUCTIONS.md" "$FRAMEWORK_SRC/CHANGELOG.md" "$up/"
    printf '1.0.0\n' > "$up/VERSION"
    git -C "$up" add -A
    git -C "$up" commit -qm "feat: first release"
    git -C "$up" tag -a v1.0.0 -m v1.0.0
    printf '1.1.0\n' > "$up/VERSION"
    git -C "$up" commit -qam "feat: second release"
    git -C "$up" tag -a v1.1.0 -m v1.1.0

    git init -q "$proj"
    git -C "$proj" config user.email test@example.com
    git -C "$proj" config user.name Test
    printf '# Consumer\n' > "$proj/CLAUDE.md"
    git -C "$proj" add -A
    git -C "$proj" commit -qm init
    mkdir -p "$proj/.claude"
    git -C "$proj" -c protocol.file.allow=always submodule add -q "$up" .claude/framework >/dev/null 2>&1
    printf '%s %s\n' "$proj" "$up"
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
mkdir -p "$PROJ/.claude/framework" "$PROJ/.claude/commands"
# scripts/ and lib/ present, commands/ absent — a partial checkout, which is what
# the consumer actually hits. A wholly empty directory has no script to run.
cp -R "$FRAMEWORK_SRC/scripts" "$PROJ/.claude/framework/"
printf '@.claude/framework/INSTRUCTIONS.md\n\n# P\n' > "$PROJ/CLAUDE.md"
run_check "$PROJ"
if [ "$check_code" -eq 2 ]; then
    pass "exits 2 (cannot tell) instead of reporting a vacuous pass"
else
    fail "expected exit 2, got $check_code:"; indent "$check_out"
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
# Break the install in a way init-project cannot repair: a command file it cannot
# overwrite. No fallback arm — this case must observe a non-zero exit or fail.
chmod -w "$PROJ/.claude/commands/project-audit.md"
chmod -w "$PROJ/.claude/commands"
OUT=$(cd "$PROJ" && bash .claude/framework/scripts/init-project.sh 2>&1)
CODE=$?
chmod +w "$PROJ/.claude/commands" "$PROJ/.claude/commands/project-audit.md" 2>/dev/null
if [ "$CODE" -ne 0 ]; then
    pass "non-zero exit when the install cannot be made conformant ($CODE)"
else
    fail "exited 0 despite a broken install — the documented && chain cannot break:"
    indent "$OUT"
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

new_case "check-consistency.sh detects a broken path, not just counts them"
# The previous version of this case asserted only how many paths were counted, so
# neutering the checks left it green — a vacuous pass inside the case written to
# kill vacuous passes. Now it injects a real defect and requires a real failure.
SANDBOX=$(mktemp -d)
cp -R "$FRAMEWORK_SRC/." "$SANDBOX/"
if [ ! -f "$SANDBOX/scripts/check-consistency.sh" ] || [ ! -d "$SANDBOX/.git" ]; then
    fail "sandbox copy incomplete — cannot exercise the gate"
else
    if (cd "$SANDBOX" && bash scripts/check-consistency.sh >/dev/null 2>&1); then
        pass "passes on an unmodified copy"
    else
        fail "fails on an unmodified copy — the sandbox itself is wrong"
    fi
    # A document citing a framework path that does not exist must fail check 4.
    # shellcheck disable=SC2016  # the backticks are literal markdown, not a substitution
    printf '\nSee `.claude/framework/standards/DOES_NOT_EXIST.md` for details.\n' >> "$SANDBOX/README.md"
    if (cd "$SANDBOX" && bash scripts/check-consistency.sh >/dev/null 2>&1); then
        fail "a broken framework path did NOT fail the gate"
    else
        pass "a broken framework path fails the gate"
    fi
    (cd "$SANDBOX" && git checkout -- README.md 2>/dev/null) || true
    # A retired command reappearing must fail check 1. The literal is assembled at
    # runtime: written out, it would be found by the very check this asserts — and
    # excluding this file from the corpus to accommodate the test would weaken it.
    # shellcheck disable=SC2016  # the backticks are literal markdown, not a substitution
    printf '\nRun `git %s origin main` to update.\n' pull >> "$SANDBOX/README.md"
    if (cd "$SANDBOX" && bash scripts/check-consistency.sh >/dev/null 2>&1); then
        fail "a retired command did NOT fail the gate"
    else
        pass "a retired command fails the gate"
    fi
    (cd "$SANDBOX" && git checkout -- README.md 2>/dev/null) || true
    # VERSION out of step with the changelog must fail check 7.
    printf '99.0.0\n' > "$SANDBOX/VERSION"
    if (cd "$SANDBOX" && bash scripts/check-consistency.sh >/dev/null 2>&1); then
        fail "a VERSION/CHANGELOG mismatch did NOT fail the gate"
    else
        pass "a VERSION/CHANGELOG mismatch fails the gate"
    fi
fi
rm -rf "$SANDBOX"

# ── Cases 23–28 — gaps the re-audit measured ─────────────────────────────────

new_case "Install appends to a project's .gitattributes instead of replacing it"
PROJ=$(new_project)
printf '* text=auto\n*.php diff=php\n' > "$PROJ/.gitattributes"
(cd "$PROJ" && bash .claude/framework/scripts/init-project.sh >/dev/null 2>&1)
expect_grep "$PROJ/.gitattributes" "* text=auto" "project's first attribute survives install"
expect_grep "$PROJ/.gitattributes" "*.php diff=php" "project's second attribute survives install"
expect_grep "$PROJ/.gitattributes" ".claude/ export-ignore" "framework entry added"
rm -rf "$PROJ"

new_case "Uninstall keeps a project-owned file in .claude/hooks/"
PROJ=$(new_project)
(cd "$PROJ" && bash .claude/framework/scripts/init-project.sh --with-hooks >/dev/null 2>&1)
echo "project's own hook" > "$PROJ/.claude/hooks/on-commit.sh"
(cd "$PROJ" && bash .claude/framework/scripts/uninstall.sh >/dev/null 2>&1)
expect_absent "$PROJ/.claude/hooks/on-file-edit.sh"
expect_file "$PROJ/.claude/hooks/on-commit.sh"
expect_grep "$PROJ/.claude/hooks/on-commit.sh" "project's own hook" "its content is intact"
rm -rf "$PROJ"

new_case "A legacy include not on its own line is reported, not announced as migrated"
PROJ=$(new_project "$(printf 'See @.claude/framework/CLAUDE.md for details.\n\n# Project\n')")
OUT=$(cd "$PROJ" && bash .claude/framework/scripts/init-project.sh 2>&1)
case "$OUT" in
    *"Could not migrate the @-include"*) pass "reports the failure" ;;
    *"Migrated @-include"*) fail "announced a migration that did not happen" ;;
    *) fail "neither reported nor announced:"; indent "$OUT" ;;
esac
expect_missing_line "$PROJ/CLAUDE.md" "@.claude/framework/INSTRUCTIONS.md"
rm -rf "$PROJ"

new_case "Both mutating scripts refuse a non-git directory with a reason, not a raw fatal"
BARE=$(mktemp -d)
mkdir -p "$BARE/.claude"
cp -R "$FRAMEWORK_SRC" "$BARE/.claude/framework"
rm -rf "$BARE/.claude/framework/.git"
for script in init-project uninstall; do
    OUT=$(cd "$BARE" && bash ".claude/framework/scripts/$script.sh" 2>&1)
    CODE=$?
    case "$OUT" in
        *"not a git repository"*)
            if [ "$CODE" -eq 2 ]; then
                pass "$script.sh: explains and exits 2"
            else
                fail "$script.sh: explained but exited $CODE, expected 2"
            fi ;;
        *"fatal:"*) fail "$script.sh leaked a raw git fatal:" ;;
        *) fail "$script.sh gave no git-repo diagnosis:"; indent "$OUT" ;;
    esac
done
rm -rf "$BARE"

new_case "The hook speaks when it has no JSON parser, instead of no-opping silently"
PROJ=$(new_project)
(cd "$PROJ" && bash .claude/framework/scripts/init-project.sh --with-hooks >/dev/null 2>&1)
STUB=$(mktemp -d)
for b in cat printf grep git dirname basename sed; do
    real=$(command -v "$b" 2>/dev/null) && ln -sf "$real" "$STUB/$b"
done
BASH_BIN=$(command -v bash)
OUT=$(echo '{"tool_input":{"file_path":"'"$PROJ"'/CLAUDE.md"}}' |
      PATH="$STUB" "$BASH_BIN" "$PROJ/.claude/hooks/on-file-edit.sh" 2>&1)
case "$OUT" in
    *"neither jq nor python3"*) pass "reports that no checks ran" ;;
    "") fail "silent no-op — the failure this case exists to catch" ;;
    *) fail "unexpected output:"; indent "$OUT" ;;
esac
OUT=$(PATH="$STUB" "$BASH_BIN" "$PROJ/.claude/hooks/on-file-edit.sh" --selftest 2>&1)
case "$OUT" in
    *"neither jq nor python3"*) pass "--selftest reports it too, no false pass" ;;
    *) fail "--selftest gave a false pass:"; indent "$OUT" ;;
esac
rm -rf "$STUB" "$PROJ"

new_case "check-updates.sh: upstream half, and a hostile tag reaches neither shell nor output"
read -r PROJ UPSTREAM <<EOF
$(new_submodule_project)
EOF
if [ ! -d "$PROJ/.claude/framework/.git" ] && [ ! -f "$PROJ/.claude/framework/.git" ]; then
    fail "submodule fixture failed — cannot exercise the upstream half"
else
    git -C "$PROJ/.claude/framework" checkout -q v1.0.0
    printf 'version=1.0.0\n' > "$PROJ/.claude/.framework-version"
    # git refuses a refname containing "..", so the marker path must not have one —
    # otherwise update-ref fails and every assertion below passes vacuously.
    MARK="$(dirname "$UPSTREAM")/PWNED"
    git -C "$UPSTREAM" update-ref "refs/tags/--output=$MARK" HEAD 2>/dev/null
    # No space either: git forbids spaces in a refname, so the paste-vector tag uses
    # a redirection rather than a command with an argument.
    git -C "$UPSTREAM" update-ref "refs/tags/v9.9.9';id>$MARK;'" HEAD 2>/dev/null
    HOSTILE=$(git -C "$UPSTREAM" tag -l | grep -c -e '--output=' -e ";id>" || true)
    if [ "$HOSTILE" -ge 2 ]; then
        pass "both hostile tags exist upstream — the attack is really present"
    else
        fail "only $HOSTILE hostile tag(s) created; the assertions below would be vacuous"
    fi
    git -C "$PROJ/.claude/framework" fetch -q --tags origin 2>/dev/null || true
    OUT=$(cd "$PROJ" && bash .claude/framework/scripts/check-updates.sh --offline 2>&1)
    CODE=$?
    case "$OUT" in
        *"Pinned at v1.0.0"*) pass "reaches the upstream comparison at all" ;;
        *) fail "never reached the tag comparison:"; indent "$OUT" ;;
    esac
    case "$OUT" in
        *"upstream is at v1.1.0"*) pass "picks the newest well-formed release" ;;
        *) fail "wrong or missing latest tag" ;;
    esac
    case "$OUT" in
        *PWNED*|*"9.9.9'"*) fail "a hostile tag name reached the output — paste vector" ;;
        *) pass "no hostile tag name in the output" ;;
    esac
    if [ -e "$MARK" ]; then
        fail "a hostile tag name was EXECUTED"
    else
        pass "nothing was executed"
    fi
    if [ "$CODE" -eq 1 ]; then
        pass "exits 1 (action recommended)"
    else
        fail "expected exit 1, got $CODE"
    fi
fi
rm -rf "$(dirname "$PROJ")"

# ── Cases 29–32 — the bypasses an adversarial pass found ─────────────────────
# All four were working attacks against v1.8.1, three of them destructive.

new_case "A symlinked .claude/framework does not redirect writes to another project"
ROOT=$(mktemp -d)
for name in projA projB; do
    git init -q "$ROOT/$name"
    git -C "$ROOT/$name" config user.email test@example.com
    git -C "$ROOT/$name" config user.name Test
    printf '# %s\n' "$name" > "$ROOT/$name/CLAUDE.md"
    mkdir -p "$ROOT/$name/.claude"
done
cp -R "$FRAMEWORK_SRC" "$ROOT/projA/.claude/framework"
rm -rf "$ROOT/projA/.claude/framework/.git"
(cd "$ROOT/projA" && bash .claude/framework/scripts/init-project.sh >/dev/null 2>&1)
ln -s "$ROOT/projA/.claude/framework" "$ROOT/projB/.claude/framework"
OUT=$(cd "$ROOT/projB" && bash .claude/framework/scripts/uninstall.sh 2>&1)
expect_file "$ROOT/projA/.claude/commands/project-audit.md"
expect_grep "$ROOT/projA/CLAUDE.md" "@.claude/framework/INSTRUCTIONS.md" "projA keeps its @-include"
expect_file "$ROOT/projA/.gitattributes"
case "$OUT" in
    *"Project:   $ROOT/projB"*) pass "names projB as the target before acting" ;;
    *) fail "did not announce the target project:"; indent "$OUT" ;;
esac
case "$OUT" in
    *"(symlinked)"*) pass "discloses that the framework is a symlink" ;;
    *) fail "symlink not disclosed" ;;
esac

new_case "The legitimate shared-clone layout is accepted, not refused"
mkdir -p "$ROOT/shared"
cp -R "$FRAMEWORK_SRC" "$ROOT/shared/framework"
rm -rf "$ROOT/shared/framework/.git"
git init -q "$ROOT/projC"
git -C "$ROOT/projC" config user.email test@example.com
git -C "$ROOT/projC" config user.name Test
printf '# C\n' > "$ROOT/projC/CLAUDE.md"
mkdir -p "$ROOT/projC/.claude"
ln -s "$ROOT/shared/framework" "$ROOT/projC/.claude/framework"
(cd "$ROOT/projC" && bash .claude/framework/scripts/init-project.sh >/dev/null 2>&1)
expect_file "$ROOT/projC/.claude/commands/project-audit.md"
expect_grep "$ROOT/projC/CLAUDE.md" "@.claude/framework/INSTRUCTIONS.md" "projC got its include"
rm -rf "$ROOT"

new_case "GIT_WORK_TREE cannot widen the hook's project confinement"
PROJ=$(new_project)
(cd "$PROJ" && bash .claude/framework/scripts/init-project.sh --with-hooks >/dev/null 2>&1)
OUTSIDE=$(mktemp -d)
echo "x = 1" > "$OUTSIDE/target.py"
# Make a reached dispatch observable: replace a commented example with a report.
perl -pi -e 's|^        \# ruff format -- "\$FILE" 2>/dev/null|        report "DISPATCH-REACHED"|' \
    "$PROJ/.claude/hooks/on-file-edit.sh"
OUT=$(printf '%s' "{\"tool_input\":{\"file_path\":\"$OUTSIDE/target.py\"}}" |
      GIT_WORK_TREE="$OUTSIDE" GIT_DIR="$PROJ/.git" bash "$PROJ/.claude/hooks/on-file-edit.sh" 2>&1)
case "$OUT" in
    *DISPATCH-REACHED*) fail "GIT_WORK_TREE widened the confinement — out-of-project file reached the checks" ;;
    *) pass "the out-of-project file was refused" ;;
esac
# And an in-project file must still reach the checks, or the guard is useless.
echo "y = 2" > "$PROJ/inside.py"
OUT=$(printf '%s' "{\"tool_input\":{\"file_path\":\"$PROJ/inside.py\"}}" |
      bash "$PROJ/.claude/hooks/on-file-edit.sh" 2>&1)
case "$OUT" in
    *DISPATCH-REACHED*) pass "an in-project file still reaches the checks" ;;
    *) fail "the guard now refuses legitimate files too:"; indent "$OUT" ;;
esac
rm -rf "$OUTSIDE" "$PROJ"

new_case "Remote-controlled strings are stripped of terminal escapes before display"
read -r PROJ UPSTREAM <<EOF
$(new_submodule_project)
EOF
if [ ! -e "$PROJ/.claude/framework/.git" ]; then
    fail "submodule fixture failed"
else
    # A commit subject that moves the cursor up and erases the line above it,
    # forging a line over the block of commands the script tells you to paste.
    git -C "$UPSTREAM" commit -q --allow-empty \
        -m "$(printf 'chore: docs\033[1A\033[2Kforged-line')" 2>/dev/null
    git -C "$UPSTREAM" tag -a v1.2.0 -m v1.2.0 2>/dev/null
    # VERSION is submodule content, so equally remote. ESC is not in [:space:].
    printf '9.9.9\033[31mUPGRADE-NOW\033[0m\n' > "$UPSTREAM/VERSION"
    git -C "$UPSTREAM" commit -qam "chore: bump" 2>/dev/null
    git -C "$PROJ/.claude/framework" fetch -q --tags origin 2>/dev/null || true
    git -C "$PROJ/.claude/framework" checkout -q v1.0.0 2>/dev/null
    printf 'version=1.0.0\n' > "$PROJ/.claude/.framework-version"
    OUTFILE=$(mktemp)
    (cd "$PROJ" && bash .claude/framework/scripts/check-updates.sh --offline) > "$OUTFILE" 2>&1
    if grep -qc $'\033' "$OUTFILE" 2>/dev/null && [ "$(grep -c $'\033' "$OUTFILE")" -gt 0 ]; then
        fail "ESC bytes reached the terminal — the paste/overwrite vector is open"
    else
        pass "no ESC bytes in check-updates output"
    fi
    (cd "$PROJ" && bash .claude/framework/scripts/check-install.sh) > "$OUTFILE" 2>&1
    if [ "$(grep -c $'\033' "$OUTFILE")" -gt 0 ]; then
        fail "ESC bytes from the VERSION file reached the terminal"
    else
        pass "no ESC bytes in check-install output"
    fi
    rm -f "$OUTFILE"
fi
rm -rf "$(dirname "$PROJ")"

# ── Cases 33–35 — the second adversarial pass ────────────────────────────────

new_case "A symlinked .claude is refused, and the link target is untouched"
ROOT=$(mktemp -d)
mkdir -p "$ROOT/victim/.claude/commands"
echo "victim's own" > "$ROOT/victim/.claude/commands/project-audit.md"
printf 'version=9.9.9\n' > "$ROOT/victim/.claude/.framework-version"
cp -R "$FRAMEWORK_SRC" "$ROOT/victim/.claude/framework"
rm -rf "$ROOT/victim/.claude/framework/.git"
git init -q "$ROOT/myproj"
git -C "$ROOT/myproj" config user.email test@example.com
git -C "$ROOT/myproj" config user.name Test
(cd "$ROOT/myproj" && ln -s ../victim/.claude .claude)
for script in uninstall init-project; do
    OUT=$(cd "$ROOT/myproj" && bash ".claude/framework/scripts/$script.sh" 2>&1)
    CODE=$?
    case "$OUT" in
        *"is a symlink"*)
            if [ "$CODE" -eq 2 ]; then
                pass "$script.sh refuses it and exits 2"
            else
                fail "$script.sh refused but exited $CODE"
            fi ;;
        *) fail "$script.sh did not refuse a symlinked .claude:"; indent "$OUT" ;;
    esac
done
expect_file "$ROOT/victim/.claude/commands/project-audit.md"
expect_file "$ROOT/victim/.claude/.framework-version"
expect_grep "$ROOT/victim/.claude/commands/project-audit.md" "victim's own" "its content is intact"
rm -rf "$ROOT"

new_case "sanitize_display keeps printable ASCII and drops every control byte"
# The previous deny-list skipped 0x0D and let every byte >= 0x80 through, which
# carries C1 controls as UTF-8 and the bidirectional overrides.
#
# The property is "no byte outside tab + printable ASCII survives" — not "the
# whole escape sequence vanishes". In \033[1A only the ESC is a control byte;
# `[1A` is printable text and correctly stays.
# shellcheck source=scripts/lib/framework-paths.sh
. "$FRAMEWORK_SRC/scripts/lib/framework-paths.sh"

# probe_control <label> <printf-escape> — the byte must not survive sanitisation
probe_control() {
    local label="$1" seq="$2" out
    out=$(sanitize_display "$(printf 'a%bb' "$seq")" | od -An -tx1 | tr -d ' \n')
    case "$out" in
        *1b*|*0d*|*c29b*|*e280ae*|*c285*)
            fail "$label survived sanitisation: $out" ;;
        *)  pass "$label stripped" ;;
    esac
}
probe_control "ESC (0x1b)"        '\033[1A'
probe_control "CR (0x0d)"         '\r'
probe_control "C1 CSI (U+009B)"   '\xc2\x9b'
probe_control "RLO (U+202E)"      '\xe2\x80\xae'
probe_control "NEL (U+0085)"      '\xc2\x85'

if [ "$(sanitize_display 'v1.2.3 fix: a normal subject')" = "v1.2.3 fix: a normal subject" ]; then
    pass "ordinary text passes through unchanged"
else
    fail "ordinary text was mangled"
fi

new_case "A hostile install marker cannot forge a line in the operator's terminal"
PROJ=$(new_project)
(cd "$PROJ" && bash .claude/framework/scripts/init-project.sh >/dev/null 2>&1)
printf 'version=1.0.0\033[1A\033[2K\033[32m  OK  Install verified by vendor\033[0m\n' \
    > "$PROJ/.claude/.framework-version"
OUTFILE=$(mktemp)
(cd "$PROJ" && bash .claude/framework/scripts/check-install.sh) > "$OUTFILE" 2>&1
if [ "$(grep -c $'\033' "$OUTFILE")" -gt 0 ]; then
    fail "ESC from the marker reached the terminal — the forgery vector is open"
else
    pass "no ESC bytes from the marker"
fi
rm -f "$OUTFILE"
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
