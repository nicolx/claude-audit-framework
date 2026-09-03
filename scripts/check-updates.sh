#!/bin/bash
# check-updates.sh — is this project's framework install current?
#
# Answers the question at both levels it can be stale at:
#
#   1. LOCAL   — the commands in .claude/commands/ are copies. They go stale when
#                the submodule moves ahead and init-project.sh is not re-run.
#   2. UPSTREAM — the submodule is pinned. Nothing tells you upstream released
#                since, which is exactly the drift 6.9 asks about.
#
# Run from anywhere in the project:
#   bash .claude/framework/scripts/check-updates.sh [--offline]
#
#   --offline   do not contact the remote; report from refs already fetched
#
# Exit codes:  0 nothing to do · 1 an action is recommended · 2 cannot tell

set -uo pipefail

OFFLINE=0
for arg in "$@"; do
    case "$arg" in
        --offline) OFFLINE=1 ;;
        *) echo "❌ Unknown option: $arg"; echo "   Usage: check-updates.sh [--offline]"; exit 2 ;;
    esac
done

# pwd -P: on macOS a path through a symlink (/tmp, /var/folders) keeps its logical
# form here while `git rev-parse` returns the physical one, and the two would not
# compare equal — the scripts then refused to work in a perfectly valid checkout.
SCRIPT_DIR=$(cd -P "$(dirname "$0")" && pwd -P)
FRAMEWORK_DIR=$(dirname "$SCRIPT_DIR")

# This script answers a consumer's question, so it needs a consumer install:
# <project>/.claude/framework. Run inside the framework's own repo there is no
# install to check, and deriving a project root from here lands outside it.
if [ "$(basename "$FRAMEWORK_DIR")" != "framework" ] ||
   [ "$(basename "$(dirname "$FRAMEWORK_DIR")")" != ".claude" ]; then
    echo "ℹ  This is the framework's own repository, not a project that installs it."
    echo "   Run this from a consumer project:"
    echo "     bash .claude/framework/scripts/check-updates.sh"
    exit 2
fi

PROJECT_ROOT=$(cd -P "$FRAMEWORK_DIR/../.." && pwd -P)
VERSION_MARKER="$PROJECT_ROOT/.claude/.framework-version"

ACTION=0

echo "────────────────────────────────────────────────"
echo "🔎 claude-audit-framework — update check"
echo "────────────────────────────────────────────────"
echo ""

# ── 1. Local drift: copied commands vs the pinned submodule ──────────────────

PINNED_VERSION="unknown"
if [ -f "$FRAMEWORK_DIR/VERSION" ]; then
    PINNED_VERSION=$(tr -d '[:space:]' < "$FRAMEWORK_DIR/VERSION")
fi

echo "[1] Installed commands vs pinned submodule"

if [ ! -f "$VERSION_MARKER" ]; then
    echo "  ⚠  No .claude/.framework-version — installed before version tracking, or"
    echo "     init-project.sh was never run."
    echo "     → bash .claude/framework/scripts/init-project.sh"
    ACTION=1
else
    INSTALLED_VERSION=$(grep '^version=' "$VERSION_MARKER" | cut -d= -f2)
    if [ "$INSTALLED_VERSION" = "$PINNED_VERSION" ]; then
        echo "  ✓  Commands are from $INSTALLED_VERSION, matching the submodule"
    else
        echo "  ⚠  Commands are from $INSTALLED_VERSION, submodule is at $PINNED_VERSION"
        echo "     → bash .claude/framework/scripts/init-project.sh"
        ACTION=1
    fi
fi

echo ""

# ── 2. Upstream drift: the pinned submodule vs the latest release ────────────

echo "[2] Pinned submodule vs upstream"

# `git -C <dir>` walks up to a parent repository, so a framework that was copied
# rather than added as a submodule would answer with the *project's* tags and
# produce confident nonsense. Require the repository found to be its own.
FW_TOPLEVEL=$(git -C "$FRAMEWORK_DIR" rev-parse --show-toplevel 2>/dev/null || true)
if [ -n "$FW_TOPLEVEL" ]; then
    FW_TOPLEVEL=$(cd -P "$FW_TOPLEVEL" 2>/dev/null && pwd -P) || FW_TOPLEVEL=""
fi

if [ "$FW_TOPLEVEL" != "$FRAMEWORK_DIR" ]; then
    echo "  ⚠  Not a git checkout of the framework — cannot compare with upstream"
    if [ -n "$FW_TOPLEVEL" ]; then
        echo "     (the framework was copied rather than added as a submodule; git here"
        echo "      resolves to $FW_TOPLEVEL, whose tags are not the framework's)"
    else
        echo "     (the framework was copied rather than added as a submodule)"
    fi
    echo ""
    echo "────────────────────────────────────────────────"
    [ "$ACTION" -eq 1 ] && exit 1
    exit 2
fi

if [ "$OFFLINE" -eq 1 ]; then
    echo "  ℹ  Offline mode — comparing against tags already fetched"
elif git -C "$FRAMEWORK_DIR" fetch --tags --quiet 2>/dev/null; then
    echo "  ℹ  Fetched tags from origin"
else
    echo "  ⚠  Could not reach origin — comparing against tags already fetched"
fi

# Tag names come from the remote, and git permits / $ ( ) { } ; | # in a refname.
# Those characters are why the previous version of this script could be steered
# into executing a shell through a sed address — but de-fanging that one line left
# the same value reaching `git log` argv, where a tag named `--output=<path>` is
# parsed as an option, and reaching commands the operator is told to paste.
#
# So the fix is at the point of capture, not at each use: a value that is not a
# well-formed release tag is not a release tag, and never enters the script.
# After this filter CURRENT_TAG and LATEST_TAG can only match RELEASE_TAG_RE,
# which makes every downstream use — argv, output, comparison — safe by
# construction rather than by remembering to quote.
RELEASE_TAG_RE='^v[0-9]+\.[0-9]+\.[0-9]+$'

CURRENT_TAG=$(git -C "$FRAMEWORK_DIR" describe --tags --exact-match HEAD 2>/dev/null || true)
if ! printf '%s' "$CURRENT_TAG" | grep -qE "$RELEASE_TAG_RE"; then
    # Not at a release tag — which is also what a malformed or hostile tag means here.
    CURRENT_TAG=""
fi
CURRENT_SHA=$(git -C "$FRAMEWORK_DIR" rev-parse --short HEAD 2>/dev/null || echo "unknown")
BRANCH=$(git -C "$FRAMEWORK_DIR" symbolic-ref --short -q HEAD || true)
LATEST_TAG=$(git -C "$FRAMEWORK_DIR" tag -l 'v*' | grep -E "$RELEASE_TAG_RE" | sort -V | tail -1)

if [ -z "$LATEST_TAG" ]; then
    echo "  ⚠  No release tags available locally — nothing to compare against"
    echo ""
    echo "────────────────────────────────────────────────"
    [ "$ACTION" -eq 1 ] && exit 1
    exit 2
fi

if [ -n "$BRANCH" ]; then
    echo "  ⚠  Submodule follows branch '$BRANCH' rather than a pinned release."
    echo "     Framework changes reach every session as they land. Pin a tag to decide when:"
    echo "     → git -C .claude/framework checkout $LATEST_TAG"
    ACTION=1
elif [ -z "$CURRENT_TAG" ]; then
    echo "  ⚠  Pinned at commit $CURRENT_SHA, which is not a release tag."
    echo "     A pin nobody can name is frozen by accident (see 6.9). Latest is $LATEST_TAG:"
    echo "     → git -C .claude/framework checkout $LATEST_TAG"
    ACTION=1
elif [ "$CURRENT_TAG" = "$LATEST_TAG" ]; then
    echo "  ✓  Pinned at $CURRENT_TAG, the latest release"
else
    # CURRENT_TAG comes from refs just fetched from the remote, and git allows
    # / $ ( ) { } ; \ | # in a ref name. Interpolated into a sed *address* those
    # close the address and can reach GNU sed's `e` command, which runs a shell.
    # Match the tag as a fixed whole line instead: no regex, no interpreter.
    # Same allowlist as the capture above: this list is printed to the operator's
    # terminal, which is the paste vector — a tag name is never echoed unfiltered.
    BEHIND=$(git -C "$FRAMEWORK_DIR" tag -l 'v*' | grep -E "$RELEASE_TAG_RE" | sort -V |
             awk -v t="$CURRENT_TAG" 'seen { print } $0 == t { seen = 1 }' | tr '\n' ' ')
    echo "  ⚠  Pinned at $CURRENT_TAG — upstream is at $LATEST_TAG"
    echo "     Releases since: $BEHIND"
    echo ""
    echo "     What changed (read before upgrading — a major means you must act):"
    git -C "$FRAMEWORK_DIR" log --no-merges --format='       %s' "$CURRENT_TAG..$LATEST_TAG" 2>/dev/null |
        head -15
    echo ""
    echo "     → git -C .claude/framework checkout $LATEST_TAG"
    echo "       bash .claude/framework/scripts/init-project.sh     # refreshes the copies"
    echo "       bash .claude/framework/scripts/check-install.sh    # verify it took"
    echo "       git add .claude/ && git commit -m 'chore: update claude-audit-framework to $LATEST_TAG'"
    ACTION=1
fi

# A dirty submodule means someone edited the framework in place; the next
# checkout would discard it, so say so before recommending one.
if [ -n "$(git -C "$FRAMEWORK_DIR" status --porcelain 2>/dev/null)" ]; then
    echo ""
    echo "  ⚠  The submodule has uncommitted local changes. Upgrading discards them."
    echo "     Framework changes belong upstream, not in a consumer's checkout."
    ACTION=1
fi

echo ""
echo "────────────────────────────────────────────────"

if [ "$ACTION" -eq 0 ]; then
    echo "✅ Up to date — nothing to do."
    exit 0
fi
echo "⚠  Action recommended — see above."
exit 1
