#!/bin/bash
# on-file-edit.sh — fast per-file checks after Claude edits a file.
#
# Wired as a PostToolUse hook on Write|Edit. Claude Code sends the tool payload as
# JSON on stdin; this script extracts the edited path and runs the checks for its
# language.
#
# ── Rules for what belongs in here ───────────────────────────────────────────
#
#   FAST      — under ~2 seconds. It runs after every single edit.
#   PER-FILE  — check the file that changed, never the whole tree.
#   NOT TESTS — the full suite belongs in the quality gate, not here.
#   NEVER FATAL — always exit 0. A broken hook must not block work.
#
# Two things a check can do:
#
#   1. Fix silently — a formatter that rewrites the file needs no output.
#   2. Report back — call `report "<message>"` and the text is injected into
#      Claude's context, so a type error gets fixed in the same turn instead of
#      surfacing in CI an hour later. This is the point of the hook: the
#      standards are instructions Claude can overlook, a checker is not.
#
# Verify the plumbing before enabling anything:
#     bash .claude/hooks/on-file-edit.sh --selftest
#
# Nothing is enabled by default. Uncomment and adapt the block for your stack.

set -uo pipefail

# ── report <message> — send text back into Claude's context ──────────────────

report() {
    local msg="$1" json=""
    if command -v jq >/dev/null 2>&1; then
        json=$(jq -nc --arg m "$msg" \
            '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: $m}}')
    elif command -v python3 >/dev/null 2>&1; then
        json=$(MSG="$msg" python3 -c '
import json, os
print(json.dumps({"hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": os.environ["MSG"],
}}))
')
    fi
    [ -n "$json" ] && printf '%s\n' "$json"
}

# ── no_parser — the one failure report() itself cannot deliver ───────────────
# Without jq or python3 there is nothing to build JSON with, so the envelope is
# written by hand. Its message is a literal we control and needs no escaping.
# Silence here would be worse than useless: the hook would look healthy while
# every check it was wired for quietly did not run.

no_parser() {
    printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"on-file-edit.sh could not read the tool payload: neither jq nor python3 is installed, so NO per-file checks ran. Install jq, or remove the PostToolUse hook from .claude/settings.json so it does not appear to be working."}}'
}

# ── extract_file_path <payload> — the edited path, or empty ─────────────────
# One implementation, used by the hook and by --selftest, so the path that runs
# in production is the path the self-test exercises.

extract_file_path() {
    local payload="$1"
    if command -v jq >/dev/null 2>&1; then
        printf '%s' "$payload" | jq -r '.tool_response.filePath // .tool_input.file_path // empty' 2>/dev/null
    elif command -v python3 >/dev/null 2>&1; then
        printf '%s' "$payload" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    r = d.get("tool_response") if isinstance(d.get("tool_response"), dict) else {}
    i = d.get("tool_input") if isinstance(d.get("tool_input"), dict) else {}
    print(r.get("filePath") or i.get("file_path") or "")
except Exception:
    print("")
' 2>/dev/null
    fi
}

# ── Self-test ────────────────────────────────────────────────────────────────
# Exercises the reporting path AND the extraction path, because a hook that
# cannot parse its input is the failure most likely to go unnoticed.

if [ "${1:-}" = "--selftest" ]; then
    if ! command -v jq >/dev/null 2>&1 && ! command -v python3 >/dev/null 2>&1; then
        no_parser
        exit 0
    fi
    probe=$(extract_file_path "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$0\"}}")
    if [ "$probe" = "$0" ]; then
        report "on-file-edit.sh self-test: reporting works, and the payload parser returned the expected path. The hook is wired correctly."
    else
        report "on-file-edit.sh self-test: reporting works, but payload extraction returned '$probe' instead of '$0'. The hook would run no checks."
    fi
    exit 0
fi

# ── Extract the edited file path from the hook payload ───────────────────────

PAYLOAD=$(cat)

if ! command -v jq >/dev/null 2>&1 && ! command -v python3 >/dev/null 2>&1; then
    no_parser
    exit 0
fi

FILE=$(extract_file_path "$PAYLOAD")

# No path, or a path that is not a regular file: nothing to do.
[ -n "$FILE" ] && [ -f "$FILE" ] || exit 0

# Confine to the project. A payload naming ~/.ssh/config or /etc/hosts is not
# ours to hand to a formatter, and `-f` alone does not exclude it.
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
FILE_DIR=$(cd "$(dirname "$FILE")" 2>/dev/null && pwd) || exit 0
case "$FILE_DIR/" in
    "$PROJECT_ROOT"/*) ;;
    *) exit 0 ;;
esac

# ── Checks by file type ──────────────────────────────────────────────────────
# Replace the examples with the commands this project actually uses. Prefer the
# project's own binaries (vendor/bin, node_modules/.bin) over global installs.
#
# Note the `--` before "$FILE" in every example: without it a file named
# `-x.php` reaches the tool as an option rather than as a path.

case "$FILE" in

    *.php)
        # vendor/bin/php-cs-fixer fix -- "$FILE" --quiet 2>/dev/null
        #
        # if ! OUT=$(vendor/bin/phpstan analyse --no-progress --error-format=raw -- "$FILE" 2>&1); then
        #     report "PHPStan on $FILE:"$'\n'"$OUT"
        # fi
        ;;

    *.ts | *.tsx | *.js | *.jsx)
        # node_modules/.bin/prettier --write -- "$FILE" 2>/dev/null
        #
        # if ! OUT=$(node_modules/.bin/eslint --format unix -- "$FILE" 2>&1); then
        #     report "ESLint on $FILE:"$'\n'"$OUT"
        # fi
        ;;

    *.py)
        # ruff format -- "$FILE" 2>/dev/null
        #
        # if ! OUT=$(ruff check -- "$FILE" 2>&1); then
        #     report "Ruff on $FILE:"$'\n'"$OUT"
        # fi
        ;;

esac

# ── Language of identifiers (any file type) ──────────────────────────────────
# Subcriteria 2.8 is mostly a judgement call, but one part of it is mechanical:
# accented characters in identifiers are never intentional and break greps and
# tooling. Uncomment to catch them at the moment they are written.
#
# if OUT=$(grep -nP '^(?![[:space:]]*(//|#|\*)).*\b\w*[À-ÿ]\w*\b' -- "$FILE" 2>/dev/null); then
#     report "Non-ASCII characters in identifiers in $FILE (subcriteria 2.8):"$'\n'"$OUT"
# fi
#
# `grep -P` is GNU-only. On macOS: brew install grep, then use ggrep.

exit 0
