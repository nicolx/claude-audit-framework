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

# ── Self-test ────────────────────────────────────────────────────────────────
# `bash .claude/hooks/on-file-edit.sh --selftest` proves the reporting path
# works before you enable any real check.

if [ "${1:-}" = "--selftest" ]; then
    report "on-file-edit.sh self-test: this text reached Claude, so reporting works."
    exit 0
fi

# ── Extract the edited file path from the hook payload ───────────────────────

PAYLOAD=$(cat)
FILE=""

if command -v jq >/dev/null 2>&1; then
    FILE=$(printf '%s' "$PAYLOAD" | jq -r '.tool_response.filePath // .tool_input.file_path // empty' 2>/dev/null)
elif command -v python3 >/dev/null 2>&1; then
    FILE=$(printf '%s' "$PAYLOAD" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    r = d.get("tool_response") if isinstance(d.get("tool_response"), dict) else {}
    i = d.get("tool_input") if isinstance(d.get("tool_input"), dict) else {}
    print(r.get("filePath") or i.get("file_path") or "")
except Exception:
    print("")
' 2>/dev/null)
fi

# No path, no file, or a path outside the project: nothing to do.
[ -n "$FILE" ] && [ -f "$FILE" ] || exit 0

# ── Checks by file type ──────────────────────────────────────────────────────
# Replace the examples with the commands this project actually uses. Prefer the
# project's own binaries (vendor/bin, node_modules/.bin) over global installs.

case "$FILE" in

    *.php)
        # vendor/bin/php-cs-fixer fix "$FILE" --quiet 2>/dev/null
        #
        # if ! OUT=$(vendor/bin/phpstan analyse "$FILE" --no-progress --error-format=raw 2>&1); then
        #     report "PHPStan on $FILE:"$'\n'"$OUT"
        # fi
        ;;

    *.ts | *.tsx | *.js | *.jsx)
        # node_modules/.bin/prettier --write "$FILE" 2>/dev/null
        #
        # if ! OUT=$(node_modules/.bin/eslint "$FILE" --format unix 2>&1); then
        #     report "ESLint on $FILE:"$'\n'"$OUT"
        # fi
        ;;

    *.py)
        # ruff format "$FILE" 2>/dev/null
        #
        # if ! OUT=$(ruff check "$FILE" 2>&1); then
        #     report "Ruff on $FILE:"$'\n'"$OUT"
        # fi
        ;;

esac

exit 0
