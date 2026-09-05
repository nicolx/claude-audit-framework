#!/bin/bash
# on-stop.sh — the project's quality gate, run once when Claude finishes a turn.
#
# Wired as a Stop hook. Its companion on-file-edit.sh checks one file at a time and
# must stay fast; this one runs the gate that cannot be fast — the type checker over
# the whole diff, the test suite — exactly once, and only when the turn actually
# touched source.
#
# ── Why this one is allowed to be fatal ──────────────────────────────────────
#
# on-file-edit.sh states the rule: NEVER FATAL, always exit 0. A per-file hook runs
# after every edit, it is advisory, and a broken one must never stand between the
# developer and their work.
#
# A Stop hook is a different event with different economics. It runs once, at the
# point where Claude is about to hand the work back and say it is done. If the gate
# is red there, "done" is false. Reporting it as context would be filed away and the
# turn would end anyway; exit 2 sends the failure back and the turn continues until
# the diff is green. That is the whole purpose, so this hook exits 2 on a red gate
# — deliberately, and only there.
#
# Everything else follows on-file-edit.sh: a hook that cannot do its job says so
# rather than failing silently, and it never exits non-zero for its own defects.
#
# ── The anti-loop rule ───────────────────────────────────────────────────────
#
# Blocking a Stop can loop: Claude tries again, the gate is still red, it blocks
# again. The payload carries `stop_hook_active`, true when this hook already blocked
# and Claude is continuing because of it. On that second pass the turn is allowed to
# end — but the marker is NOT cleared, so the gate returns at the end of the next
# turn. One block per turn, and it keeps coming back until the diff is green.
#
# Verify the plumbing before enabling anything:
#     bash .claude/hooks/on-stop.sh --selftest
#
# Nothing is enabled by default. Set GATE below to your project's gate command.

set -uo pipefail

# ── The gate ─────────────────────────────────────────────────────────────────
# The one line to edit. Empty means the hook does nothing at all.
#
# It should be the command a developer would run before committing — scoped to the
# diff if the project offers that, because this runs at the end of every turn that
# touched source:
#
#   GATE="bin/qa"                                   a project gate script
#   GATE="composer qa"                              a composer script
#   GATE="npm run --silent check"                   package.json
#   GATE="make check"
#
# Run from the project root. Anything it prints on failure goes back to Claude, so
# prefer a gate whose output names files and lines.

GATE=""

# ── report <message> — send text back into Claude's context ──────────────────
# Same envelope as on-file-edit.sh, with this hook's event name. Used for the
# hook's own defects, never for a red gate: that goes to stderr with exit 2.

report() {
    local msg="$1" json=""
    if command -v jq >/dev/null 2>&1; then
        json=$(jq -nc --arg m "$msg" \
            '{hookSpecificOutput: {hookEventName: "Stop", additionalContext: $m}}')
    elif command -v python3 >/dev/null 2>&1; then
        json=$(MSG="$msg" python3 -c '
import json, os
print(json.dumps({"hookSpecificOutput": {
    "hookEventName": "Stop",
    "additionalContext": os.environ["MSG"],
}}))
')
    fi
    [ -n "$json" ] && printf '%s\n' "$json"
}

# ── stop_hook_active — is this the second pass of a block we caused? ─────────
# Absent, unreadable, or no parser available all answer "no". Being wrong here
# costs one extra gate run; assuming "yes" would silently disable the gate, which
# is the failure that must not happen quietly.

stop_hook_active() {
    local payload="$1"
    if command -v jq >/dev/null 2>&1; then
        printf '%s' "$payload" |
            jq -r 'if (. | objects | .stop_hook_active) == true then "1" else "0" end' 2>/dev/null
    elif command -v python3 >/dev/null 2>&1; then
        printf '%s' "$payload" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    print("1" if isinstance(d, dict) and d.get("stop_hook_active") is True else "0")
except Exception:
    print("0")
' 2>/dev/null
    else
        printf '0'
    fi
}

# ── Where the marker lives ───────────────────────────────────────────────────
# on-file-edit.sh writes it when a source file is edited; this hook consumes it.
# Both derive the path the same way, and the definition is duplicated in the two
# files on purpose: a hook is copied into a project as a single self-contained
# file, so a shared library would be one more thing that can be missing.
#
# It lives in the temp directory, not in the project: a marker inside the tree
# would need a .gitignore entry in every consumer, and would eventually be
# committed by someone's `git add -A`. Keyed by project path so two checkouts of
# the same repo do not share one.

marker_path() {
    local key
    key=$(printf '%s' "$1" | cksum | cut -d' ' -f1)
    printf '%s/claude-gate-%s' "${TMPDIR:-/tmp}" "$key"
}

# ── Project root, established the same way as on-file-edit.sh ───────────────
# From this script's own location, never `git rev-parse --show-toplevel`: that
# obeys GIT_WORK_TREE and GIT_DIR, so an environment variable could move the root
# and this hook would run a gate command in a directory the developer never chose.
# A symlinked .claude/hooks is refused for the same reason it is there.

resolve_root() {
    [ -L "$(dirname "$0")" ] && return 1
    local hook_dir
    hook_dir=$(cd -P "$(dirname "$0")" 2>/dev/null && pwd -P) || return 1
    cd -P "$hook_dir/../.." 2>/dev/null && pwd -P
}

# ── Self-test ────────────────────────────────────────────────────────────────

if [ "${1:-}" = "--selftest" ]; then
    if ! command -v jq >/dev/null 2>&1 && ! command -v python3 >/dev/null 2>&1; then
        report "on-stop.sh self-test: neither jq nor python3 is installed, so the payload cannot be read. The hook would treat every pass as a first pass and could block the same turn repeatedly. Install jq, or remove the Stop hook from .claude/settings.json."
        exit 0
    fi
    probe_root=$(resolve_root) || {
        report "on-stop.sh self-test: .claude/hooks is a symlink, so the project boundary cannot be established. The gate will never run. Install the hook as a real file under <project>/.claude/hooks/."
        exit 0
    }
    probe_active=$(stop_hook_active '{"stop_hook_active":true}')
    probe_inactive=$(stop_hook_active '{"stop_hook_active":false}')
    if [ "$probe_active" = "1" ] && [ "$probe_inactive" = "0" ]; then
        if [ -z "$GATE" ]; then
            report "on-stop.sh self-test: plumbing works (root $probe_root, payload parsed, marker $(marker_path "$probe_root")). No gate is configured — set GATE in .claude/hooks/on-stop.sh to enable it."
        else
            report "on-stop.sh self-test: plumbing works (root $probe_root, marker $(marker_path "$probe_root")). Gate command: $GATE"
        fi
    else
        report "on-stop.sh self-test: the payload parser returned '$probe_active'/'$probe_inactive' instead of '1'/'0'. The anti-loop guard would not work — the gate could block the same turn repeatedly. Do not enable it until this is fixed."
    fi
    exit 0
fi

# ── Run ──────────────────────────────────────────────────────────────────────

[ -n "$GATE" ] || exit 0

PROJECT_ROOT=$(resolve_root) || exit 0
MARKER=$(marker_path "$PROJECT_ROOT")

# No marker: this turn touched no source. A conversational turn does not pay for
# the gate — this is what makes an end-of-turn gate affordable at all.
[ -f "$MARKER" ] || exit 0

PAYLOAD=$(cat)

# Second pass of a block we caused: let the turn end, keep the marker so the gate
# returns next turn.
[ "$(stop_hook_active "$PAYLOAD")" = "1" ] && exit 0

cd "$PROJECT_ROOT" || exit 0

if OUT=$(eval "$GATE" 2>&1); then
    rm -f "$MARKER"
    exit 0
fi

# Red. Everything the gate printed goes back to Claude, which continues the turn.
# Trust boundary, as in on-file-edit.sh: a gate quotes the source it read, so this
# sends file content into the conversation. That is the point here — it is the
# project's own gate over the project's own files — but it is why GATE must name a
# command the developer chose, and never anything derived from a payload.
printf '%s\n\n%s\n' "The quality gate is red, so this turn's work is not done. Fix it, do not stop here." "$OUT" >&2
exit 2
