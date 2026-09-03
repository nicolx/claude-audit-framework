#!/bin/bash
# init-project.sh — Initialize claude-audit-framework in a project
# Run from the project root after adding the submodule:
#   git submodule add git@github.com:nicolx/claude-audit-framework.git .claude/framework
#   bash .claude/framework/scripts/init-project.sh [--with-hooks]
#
#   --with-hooks   also install the PostToolUse hook that runs fast per-file
#                  checks after every edit. Opt-in: it changes how the harness
#                  behaves, so it is never installed silently.
#
# Exit codes:  0 installed and conformant · 1 installed but not conformant · 2 cannot run

set -euo pipefail

WITH_HOOKS=0
for arg in "$@"; do
    case "$arg" in
        --with-hooks) WITH_HOOKS=1 ;;
        *) echo "❌ Unknown option: $arg"; echo "   Usage: init-project.sh [--with-hooks]"; exit 2 ;;
    esac
done

# Two lines of bootstrap, then the shared logic. The library cannot locate itself,
# so this much must be here — and it is logical (`cd`, not `cd -P`) for the reason
# framework-paths.sh explains at length: the physical path says where the framework
# lives, not which project asked.
SCRIPT_BOOTSTRAP_DIR=$(cd "$(dirname "$0")" && pwd)
if [ ! -f "$SCRIPT_BOOTSTRAP_DIR/lib/framework-paths.sh" ]; then
    echo "❌ $SCRIPT_BOOTSTRAP_DIR/lib/framework-paths.sh is missing."
    echo "   The framework checkout is incomplete — usually a partial or sparse checkout."
    echo "   → git submodule update --init --recursive"
    exit 2
fi
# shellcheck source=scripts/lib/framework-paths.sh
. "$SCRIPT_BOOTSTRAP_DIR/lib/framework-paths.sh"

framework_paths_init "$0"
require_git_repo

COMMANDS_DIR="$PROJECT_ROOT/.claude/commands"
VERSION_MARKER="$PROJECT_ROOT/.claude/.framework-version"
HOOKS_DIR="$PROJECT_ROOT/.claude/hooks"
SETTINGS_FILE="$PROJECT_ROOT/.claude/settings.json"

INCLUDE_LINE="@.claude/framework/INSTRUCTIONS.md"
LEGACY_INCLUDE_LINE="@.claude/framework/CLAUDE.md"   # pre-1.0 installs

# An uninitialised submodule leaves the directory present but empty, which used to
# surface as a raw `cp: ... No such file or directory` with no explanation.
FRAMEWORK_HAS_COMMANDS=0
for f in "$FRAMEWORK_DIR"/commands/*.md; do
    [ -e "$f" ] && FRAMEWORK_HAS_COMMANDS=1 && break
done

if [ "$FRAMEWORK_HAS_COMMANDS" -eq 0 ]; then
    echo "❌ The framework submodule is not checked out — $FRAMEWORK_DIR has no commands."
    echo "   Usually a clone without --recurse-submodules."
    echo "   → git submodule update --init --recursive"
    exit 1
fi

echo "🔧 Initializing claude-audit-framework..."
echo ""
# Name the directory before writing to it. Without this, a redirected PROJECT_ROOT
# is invisible: ten green checkmarks in one terminal while the writes land in
# another project.
announce_target

# ── Step 1 — Install commands ───────────────────────────────────────────────────
# Commands are copied (not symlinked) — Claude Code does not follow symlinks.
# Always overwrite: command files belong to the framework, not the project.

mkdir -p "$COMMANDS_DIR"
for command_file in "$FRAMEWORK_DIR"/commands/*.md; do
    filename=$(basename "$command_file")
    target="$COMMANDS_DIR/$filename"
    cp "$command_file" "$target"
    echo "  ✓  Installed command: /$( basename "$filename" .md )"
done

echo ""

# ── Step 2 — Scaffold project files ──────────────────────────────────────────

if [ -f "$PROJECT_ROOT/CLAUDE.md" ]; then
    if grep -qF "$INCLUDE_LINE" "$PROJECT_ROOT/CLAUDE.md"; then
        echo "  ↩  CLAUDE.md already includes $INCLUDE_LINE (skipped)"
    elif grep -qF "$LEGACY_INCLUDE_LINE" "$PROJECT_ROOT/CLAUDE.md"; then
        # Pre-1.0 installs point at CLAUDE.md, which is now the framework's own
        # development file. Rewrite the line in place — never add a second one.
        # The branch is chosen on a substring match while the rewrite is anchored, so a
        # legacy line with trailing whitespace took this path and matched nothing. The
        # result is now verified rather than announced.
        TEMP=$(mktemp)
        sed -E "s|^[[:space:]]*@\.claude/framework/CLAUDE\.md[[:space:]]*$|$INCLUDE_LINE|" \
            "$PROJECT_ROOT/CLAUDE.md" > "$TEMP"
        mv "$TEMP" "$PROJECT_ROOT/CLAUDE.md"
        if grep -qF "$INCLUDE_LINE" "$PROJECT_ROOT/CLAUDE.md"; then
            echo "  ✓  Migrated @-include: $LEGACY_INCLUDE_LINE → $INCLUDE_LINE"
        else
            echo "  ✗  Could not migrate the @-include automatically."
            echo "     CLAUDE.md mentions $LEGACY_INCLUDE_LINE but not on a line of its own."
            echo "     Replace it by hand with: $INCLUDE_LINE"
        fi
    else
        TEMP=$(mktemp)
        printf '%s\n\n' "$INCLUDE_LINE" > "$TEMP"
        cat "$PROJECT_ROOT/CLAUDE.md" >> "$TEMP"
        mv "$TEMP" "$PROJECT_ROOT/CLAUDE.md"
        echo "  ✓  Prepended $INCLUDE_LINE to existing CLAUDE.md"
    fi
else
    cp "$FRAMEWORK_DIR/templates/project-CLAUDE.md" "$PROJECT_ROOT/CLAUDE.md"
    echo "  ✓  Created CLAUDE.md from template"
fi

if [ -f "$PROJECT_ROOT/.claude/PROJECT_AUDIT_FRAMEWORK.md" ]; then
    echo "  ↩  .claude/PROJECT_AUDIT_FRAMEWORK.md already exists (skipped)"
else
    cp "$FRAMEWORK_DIR/templates/PROJECT_AUDIT_FRAMEWORK.md" "$PROJECT_ROOT/.claude/PROJECT_AUDIT_FRAMEWORK.md"
    echo "  ✓  Created .claude/PROJECT_AUDIT_FRAMEWORK.md from template"
fi

if [ -f "$PROJECT_ROOT/.claude/CODING_STANDARDS.md" ]; then
    echo "  ↩  .claude/CODING_STANDARDS.md already exists (skipped)"
else
    cp "$FRAMEWORK_DIR/templates/CODING_STANDARDS.md" "$PROJECT_ROOT/.claude/CODING_STANDARDS.md"
    echo "  ✓  Created .claude/CODING_STANDARDS.md from template"
fi

echo ""

# ── Step 3 — Exclude .claude/ from git archive (deploy) ──────────────────────

GITATTRIBUTES="$PROJECT_ROOT/.gitattributes"
EXPORT_IGNORE_ENTRY=".claude/ export-ignore"

if [ -f "$GITATTRIBUTES" ] && grep -qF "$EXPORT_IGNORE_ENTRY" "$GITATTRIBUTES"; then
    echo "  ↩  .gitattributes already excludes .claude/ from git archive (skipped)"
else
    echo "$EXPORT_IGNORE_ENTRY" >> "$GITATTRIBUTES"
    echo "  ✓  Added '.claude/ export-ignore' to .gitattributes"
    echo "     .claude/ will be excluded by Deployer, Capistrano and any tool using git archive"
fi

echo ""

# ── Step 3b — Install the per-file check hook (opt-in) ───────────────────────
# The coding standards are instructions Claude can overlook. A checker cannot.
# This is the only mechanical enforcement the framework offers, which is also
# why it is never installed without being asked for.

if [ "$WITH_HOOKS" -eq 1 ]; then
    mkdir -p "$HOOKS_DIR"

    if [ -f "$HOOKS_DIR/on-file-edit.sh" ]; then
        echo "  ↩  .claude/hooks/on-file-edit.sh already exists (skipped — your edits are kept)"
    else
        cp "$FRAMEWORK_DIR/templates/hooks/on-file-edit.sh" "$HOOKS_DIR/on-file-edit.sh"
        chmod +x "$HOOKS_DIR/on-file-edit.sh"
        echo "  ✓  Created .claude/hooks/on-file-edit.sh (no checks enabled yet — edit it)"
    fi

    if [ ! -f "$SETTINGS_FILE" ]; then
        cp "$FRAMEWORK_DIR/templates/settings.hooks.json" "$SETTINGS_FILE"
        echo "  ✓  Created .claude/settings.json with the PostToolUse hook"
    elif grep -qF "on-file-edit.sh" "$SETTINGS_FILE"; then
        echo "  ↩  .claude/settings.json already wires the hook (skipped)"
    else
        echo "  ⚠  .claude/settings.json exists — not modified, to avoid clobbering your settings."
        echo "     Merge this into its \"hooks\" key (or run /hooks in Claude Code):"
        echo ""
        sed 's/^/       /' "$FRAMEWORK_DIR/templates/settings.hooks.json"
        echo ""
    fi

    echo ""
fi

# ── Step 4 — Record the installed version ────────────────────────────────────
# Commands are copies, so they go stale when the submodule moves ahead. This
# marker is what lets Claude detect the drift and tell the developer to re-run.

# The version this install was last run against, captured before the marker is
# overwritten — it is what makes the breaking-change report reachable in step 5.
PREVIOUS_VERSION=$(read_marker_version)

FRAMEWORK_VERSION=$(read_framework_version)
FRAMEWORK_SHA=$(sanitize_display "$(git -C "$FRAMEWORK_DIR" rev-parse --short HEAD 2>/dev/null || echo "unknown")")

cat > "$VERSION_MARKER" <<EOF
# Written by init-project.sh — do not edit.
# Claude compares this against .claude/framework/VERSION to detect stale command copies.
version=$FRAMEWORK_VERSION
commit=$FRAMEWORK_SHA
installed=$(date +%Y-%m-%d)
EOF
echo "  ✓  Recorded installed version: $FRAMEWORK_VERSION ($FRAMEWORK_SHA)"

echo ""

# ── Step 5 — Verification ─────────────────────────────────────────────────────
# Delegated to check-install.sh, which is also what a developer runs on its own
# after an upgrade. One set of conformance rules, one place they live.

set +e
if [ -n "$PREVIOUS_VERSION" ]; then
    bash "$SCRIPT_DIR/check-install.sh" --compare-from "$PREVIOUS_VERSION"
else
    bash "$SCRIPT_DIR/check-install.sh"
fi
CONFORMANCE=$?
set -e

# Advice rather than conformance, so it stays here.
PROFILE_MISSING=0
if [ ! -f "$HOME/.claude/context/user_profile.md" ]; then
    PROFILE_MISSING=1
    echo ""
    echo "  ⚠  Developer profile NOT found (~/.claude/context/user_profile.md)"
    echo "     Run /init-profile in Claude Code to calibrate recommendations to your skill level."
fi

echo ""

# ── Step 6 — Summary and next steps ──────────────────────────────────────────

if [ "$CONFORMANCE" -eq 0 ]; then
    echo "✅ claude-audit-framework installed."
else
    echo "❌ Install is not conformant — fix the errors above before opening Claude Code."
    echo "   Re-check any time with:"
    echo "     bash .claude/framework/scripts/check-install.sh"
fi

echo ""
echo "Next steps:"
echo ""

STEP=1
if [ "$PROFILE_MISSING" -eq 1 ]; then
    echo "  $STEP. (optional) Open Claude Code and run /init-profile to create your developer profile"
    echo "         Enables calibration of recommendations to your skill level."
    STEP=$((STEP + 1))
    echo ""
fi

echo "  $STEP. Edit CLAUDE.md               — fill in project name, stack, architecture, quality gate command"
STEP=$((STEP + 1))
echo "  $STEP. Edit PROJECT_AUDIT_FRAMEWORK.md — add stack-specific quality criteria"
echo "         Includes declaring a read-only database for query analysis (7.9, 9.8), or that none exists"
STEP=$((STEP + 1))
echo "  $STEP. Edit CODING_STANDARDS.md        — add language-specific conventions"
STEP=$((STEP + 1))

if [ ! -f "$PROJECT_ROOT/.claudeignore" ]; then
    echo "  $STEP. Create .claudeignore to exclude vendor/, node_modules/, build artefacts"
    STEP=$((STEP + 1))
fi

if [ "$WITH_HOOKS" -eq 1 ]; then
    echo "  $STEP. Edit .claude/hooks/on-file-edit.sh — enable the per-file checks for this stack"
    echo "         Verify the plumbing first: bash .claude/hooks/on-file-edit.sh --selftest"
    STEP=$((STEP + 1))
fi

echo "  $STEP. Once the above are done, open Claude Code and run /project-audit"
echo "         It writes docs/audits/ and .claude/audit-focus.md, which then steers every"
echo "         later session toward this project's actual weak spots."

if [ "$WITH_HOOKS" -eq 0 ]; then
    echo ""
    echo "  Optional: re-run with --with-hooks to install a PostToolUse hook that runs fast"
    echo "  per-file checks (formatter, type check) after each edit and reports failures back"
    echo "  to Claude in the same turn."
fi

echo ""
echo "Three scripts, three questions:"
echo "  check-updates.sh    is a newer version available?   (contacts the remote)"
echo "  check-install.sh    is this install conformant?      (read-only)"
echo "  init-project.sh     make it conformant.              (this one)"
echo ""
echo "To upgrade later — all four steps, in this order:"
echo "  bash .claude/framework/scripts/check-updates.sh                 # what is new"
echo "  cd .claude/framework && git fetch --tags && git checkout <tag> && cd ../.."
echo "  bash .claude/framework/scripts/init-project.sh                  # migrate + refresh copies"
echo "  bash .claude/framework/scripts/check-install.sh                 # verify it took"
echo "  git add .claude/ CLAUDE.md && git commit -m 'chore: update claude-audit-framework to <tag>'"
echo ""
echo "  Updating the submodule alone is not enough: the @-include in CLAUDE.md and the"
echo "  command copies live outside it, and a bump without them loads nothing at all."
echo ""

# The installer must be able to fail: it sits in the middle of a documented `&&`
# chain, and printing an error while exiting 0 makes that chain unbreakable.
exit "$CONFORMANCE"
