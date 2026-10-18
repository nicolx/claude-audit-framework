# shellcheck shell=bash
# framework-paths.sh — where am I, and which project asked?
#
# Sourced by the four consumer-facing scripts. Not executable on its own.
#
#   PROJECT_ROOT   — the project that invoked the script. The only thing MUTATED.
#   FRAMEWORK_DIR  — where the framework's own files live. Only ever READ.
#
# PROJECT_ROOT comes from the logical invocation path (`cd` without -P), because a
# symlinked .claude/framework can be shared by several projects: the physical path
# names the checkout, not the project that asked. The physical forms are used only
# to compare against git, which resolves symlinks.
#
# Nothing here mutates anything. Callers print PROJECT_ROOT before they do.

# framework_paths_init <script-path> — sets SCRIPT_DIR, FRAMEWORK_DIR,
# FRAMEWORK_DIR_PHYS and PROJECT_ROOT, or exits 2 with a diagnosis.
framework_paths_init() {
    local invoked="$1" logical_dir

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

    FRAMEWORK_DIR_PHYS=$(cd -P "$FRAMEWORK_DIR" 2>/dev/null && pwd -P) || FRAMEWORK_DIR_PHYS="$FRAMEWORK_DIR"

    # Every write and delete goes to "$PROJECT_ROOT/.claude/…", and the filesystem
    # follows a symlink anywhere along it. So the target is checked, not the route:
    # .claude must be a real directory whose physical parent is the physical project
    # root, or writes could land in another project's .claude/.
    CLAUDE_DIR="$PROJECT_ROOT/.claude"
    PROJECT_ROOT_PHYS=$(cd -P "$PROJECT_ROOT" 2>/dev/null && pwd -P) || PROJECT_ROOT_PHYS="$PROJECT_ROOT"

    if [ -L "$CLAUDE_DIR" ]; then
        echo "❌ $CLAUDE_DIR is a symlink."
        echo "   Everything this script writes or deletes goes under .claude/, so a symlink"
        echo "   there would redirect it into whatever the link points at — another project,"
        echo "   possibly one you did not mean to touch."
        echo "   → replace the symlink with a real directory, or run this from the project"
        echo "     that owns the .claude/ you intend to change"
        exit 2
    fi

    CLAUDE_DIR_PHYS=$(cd -P "$CLAUDE_DIR" 2>/dev/null && pwd -P) || CLAUDE_DIR_PHYS=""
    if [ -n "$CLAUDE_DIR_PHYS" ] && [ "$(dirname "$CLAUDE_DIR_PHYS")" != "$PROJECT_ROOT_PHYS" ]; then
        echo "❌ $CLAUDE_DIR does not physically live in $PROJECT_ROOT."
        echo "   It resolves to $CLAUDE_DIR_PHYS, so writes would land outside the project"
        echo "   this command was invoked from."
        exit 2
    fi
}

require_git_repo() {
    if ! git -C "$PROJECT_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
        echo "❌ $PROJECT_ROOT is not a git repository."
        echo "   The framework installs as a submodule and excludes itself from deploys"
        echo "   through a .gitattributes entry, so a git repository is required."
        exit 2
    fi
}

# announce_target — name the directories about to be changed, before changing them,
# so the operator can see where the writes resolve to.
announce_target() {
    echo "   Project:   $PROJECT_ROOT"
    if [ "$PROJECT_ROOT_PHYS" != "$PROJECT_ROOT" ]; then
        echo "              → $PROJECT_ROOT_PHYS (resolved)"
    fi
    echo "   Writing:   $CLAUDE_DIR"
    if [ -n "$CLAUDE_DIR_PHYS" ] && [ "$CLAUDE_DIR_PHYS" != "$CLAUDE_DIR" ]; then
        echo "              → $CLAUDE_DIR_PHYS (resolved)"
    fi
    echo "   Framework: $FRAMEWORK_DIR"
    if [ "$FRAMEWORK_DIR_PHYS" != "$FRAMEWORK_DIR" ]; then
        echo "              → $FRAMEWORK_DIR_PHYS (symlinked)"
    fi
    echo ""
}

# sanitize_display <string> — make a string from outside the script safe to print:
# a tag, a commit subject, VERSION, a branch name, the install marker.
#
# An allow-list: tab and printable ASCII survive, everything else is dropped. CR,
# escape sequences, C1 controls encoded as UTF-8 and bidirectional overrides can all
# forge or rewrite terminal output, and a deny-list misses one of them. Non-ASCII
# text prints with those characters missing; CHANGELOG.md remains the authoritative
# text.
sanitize_display() {
    printf '%s' "$1" | LC_ALL=C tr -cd '\011\040-\176'
}

read_framework_version() {
    local v="unknown"
    if [ -f "$FRAMEWORK_DIR/VERSION" ]; then
        v=$(LC_ALL=C tr -d '[:space:]' < "$FRAMEWORK_DIR/VERSION")
        v=$(sanitize_display "$v")
    fi
    printf '%s' "$v"
}

# read_marker_version — the version recorded at install time. The marker is
# repository content, so it is sanitised like any remote string; head -1 keeps a
# marker with two version= lines from yielding a multi-line value.
read_marker_version() {
    local marker="$PROJECT_ROOT/.claude/.framework-version"
    [ -f "$marker" ] || return 0
    sanitize_display "$(grep '^version=' "$marker" | head -1 | cut -d= -f2)"
}

# is_release_tag <string> — a well-formed release tag, and nothing else.
# `case`, not `grep -qE`: grep matches if any line matches, so a multi-line value
# with a valid tag on one line would pass.
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
