# shellcheck shell=bash
# framework-paths.sh — where am I, and which project asked?
#
# Sourced by the four consumer-facing scripts. Not executable on its own.
#
# ── Why this file exists, and why it is not `pwd -P` ─────────────────────────
#
# Each script needs two different answers, and an earlier version conflated them:
#
#   PROJECT_ROOT   — which project invoked me. This is what gets MUTATED.
#   FRAMEWORK_DIR  — where the framework's own files live. Only ever READ.
#
# Resolving the script's path physically (`pwd -P`) answers the second question
# and silently substitutes it for the first. With `.claude/framework` as a
# symlink — two projects sharing one checkout, or a repository that ships such a
# link — the guard then passed *for the wrong project*, and `uninstall.sh` run
# from one project deleted the files of another, reporting success in the
# terminal of the untouched one. A repository carrying one committed symlink
# plus the framework's own documented install line was enough to strip a sibling
# project on clone.
#
# So the project is derived from the **logical** invocation path: `cd` without
# -P keeps the path the operator actually typed, symlink and all, which is
# exactly "who asked". The physical form is kept separately, and used only where
# it is the right question — comparing against `git rev-parse`, which resolves.
#
# Nothing here mutates anything. Callers print PROJECT_ROOT before they do.

# framework_paths_init <script-path> — sets SCRIPT_DIR, FRAMEWORK_DIR,
# FRAMEWORK_DIR_PHYS and PROJECT_ROOT, or exits 2 with a diagnosis.
framework_paths_init() {
    local invoked="$1" logical_dir

    # Logical: no -P. This is the invocation, not the installation.
    logical_dir=$(cd "$(dirname "$invoked")" 2>/dev/null && pwd) || {
        echo "❌ Cannot resolve the directory of $invoked"
        exit 2
    }

    SCRIPT_DIR="$logical_dir"
    FRAMEWORK_DIR=$(dirname "$SCRIPT_DIR")

    if [ "$(basename "$FRAMEWORK_DIR")" != "framework" ] ||
       [ "$(basename "$(dirname "$FRAMEWORK_DIR")")" != ".claude" ]; then
        echo "❌ Not a consumer install."
        echo "   Expected to be invoked as <project>/.claude/framework/scripts/$(basename "$invoked")"
        echo "   Invoked as:  $invoked"
        echo "   Which resolves to:  $SCRIPT_DIR"
        echo ""
        echo "   The path is read as typed, so a symlinked .claude/framework is fine —"
        echo "   what matters is that the invocation goes through <project>/.claude/framework/."
        exit 2
    fi

    PROJECT_ROOT=$(cd "$FRAMEWORK_DIR/../.." 2>/dev/null && pwd) || {
        echo "❌ Cannot resolve the project root above $FRAMEWORK_DIR"
        exit 2
    }

    # Physical form, for the one comparison that needs it: git resolves symlinks,
    # so asking git whether the framework is its own checkout requires both sides
    # in the same form.
    FRAMEWORK_DIR_PHYS=$(cd -P "$FRAMEWORK_DIR" 2>/dev/null && pwd -P) || FRAMEWORK_DIR_PHYS="$FRAMEWORK_DIR"
}

# require_git_repo — the project must be a git repository, with a reason given.
require_git_repo() {
    if ! git -C "$PROJECT_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
        echo "❌ $PROJECT_ROOT is not a git repository."
        echo "   The framework installs as a submodule and excludes itself from deploys"
        echo "   through a .gitattributes entry, so a git repository is required."
        exit 2
    fi
}

# announce_target <verb> — name the directory about to be changed, before changing it.
# A redirected PROJECT_ROOT is invisible otherwise: the operator reads success in
# one terminal while the writes land somewhere else.
announce_target() {
    echo "   Project:   $PROJECT_ROOT"
    echo "   Framework: $FRAMEWORK_DIR"
    if [ "$FRAMEWORK_DIR_PHYS" != "$FRAMEWORK_DIR" ]; then
        echo "              → $FRAMEWORK_DIR_PHYS (symlinked)"
    fi
    echo ""
}

# sanitize_display <string> — strip control characters before echoing anything
# that came from a remote: a tag name, a commit subject, a VERSION file, a branch.
#
# Terminal escapes are the gap the release-tag allowlist did not cover. A commit
# subject carrying \033[1A\033[2K moves the cursor up and erases the line the
# script just printed, so an attacker can forge a line directly above the block
# of commands the operator is told to paste. ESC is not in [:space:], so trimming
# whitespace does not remove it.
sanitize_display() {
    printf '%s' "$1" | LC_ALL=C tr -d '\000-\010\013\014\016-\037\177'
}

# read_framework_version — the VERSION the framework ships, sanitised.
read_framework_version() {
    local v="unknown"
    if [ -f "$FRAMEWORK_DIR/VERSION" ]; then
        v=$(LC_ALL=C tr -d '[:space:]' < "$FRAMEWORK_DIR/VERSION")
        v=$(sanitize_display "$v")
    fi
    printf '%s' "$v"
}

# read_marker_version — the version recorded at install time.
# head -1: a hand-edited or half-written marker with two version= lines would
# otherwise yield a multi-line value that is then compared and echoed.
read_marker_version() {
    local marker="$PROJECT_ROOT/.claude/.framework-version"
    [ -f "$marker" ] || return 0
    grep '^version=' "$marker" | head -1 | cut -d= -f2
}

# is_release_tag <string> — a well-formed release tag, and nothing else.
#
# `case` rather than `grep -qE`: grep matches if ANY line matches, so a value
# containing a newline followed by "v1.0.0" passed the previous check. Git's
# refname rules happen to forbid newlines, which meant the old form was safe by
# git's construction rather than its own — and would have become an injection
# primitive the moment the same helper was reused on a value git does not bound,
# such as a VERSION string or an API response.
is_release_tag() {
    case "$1" in
        v[0-9]*.[0-9]*.[0-9]*)
            case "$1" in
                *[!v0-9.]*) return 1 ;;
                *) return 0 ;;
            esac ;;
        *) return 1 ;;
    esac
}
