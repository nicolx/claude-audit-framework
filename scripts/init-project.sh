#!/bin/bash
# init-project.sh — Initialize claude-audit-framework in a project
# Run from the project root after adding the submodule:
#   git submodule add git@github.com:nicolx/claude-audit-framework.git .claude/framework
#   bash .claude/framework/scripts/init-project.sh [--with-hooks]
#
#   --with-hooks   also install the PostToolUse hook that runs fast per-file
#                  checks after every edit. Opt-in: it changes how the harness
#                  behaves, so it is never installed silently.

set -e

WITH_HOOKS=0
for arg in "$@"; do
    case "$arg" in
        --with-hooks) WITH_HOOKS=1 ;;
        *) echo "❌ Unknown option: $arg"; echo "   Usage: init-project.sh [--with-hooks]"; exit 1 ;;
    esac
done

PROJECT_ROOT="$(git rev-parse --show-toplevel)"
FRAMEWORK_DIR="$PROJECT_ROOT/.claude/framework"
COMMANDS_DIR="$PROJECT_ROOT/.claude/commands"
VERSION_MARKER="$PROJECT_ROOT/.claude/.framework-version"
HOOKS_DIR="$PROJECT_ROOT/.claude/hooks"
SETTINGS_FILE="$PROJECT_ROOT/.claude/settings.json"

INCLUDE_LINE="@.claude/framework/INSTRUCTIONS.md"
LEGACY_INCLUDE_LINE="@.claude/framework/CLAUDE.md"   # pre-1.0 installs

if [ ! -d "$FRAMEWORK_DIR" ]; then
    echo "❌ Framework not found at .claude/framework/"
    echo "   Add it first:"
    echo "   git submodule add git@github.com:nicolx/claude-audit-framework.git .claude/framework"
    exit 1
fi

echo "🔧 Initializing claude-audit-framework..."
echo ""

# ── Step 1 — Install skills ───────────────────────────────────────────────────
# Commands are copied (not symlinked) — Claude Code does not follow symlinks.
# Always overwrite: command files belong to the framework, not the project.

mkdir -p "$COMMANDS_DIR"
for skill in "$FRAMEWORK_DIR"/commands/*.md; do
    filename=$(basename "$skill")
    target="$COMMANDS_DIR/$filename"
    cp "$skill" "$target"
    echo "  ✓  Installed skill: /$( basename "$filename" .md )"
done

echo ""

# ── Step 2 — Scaffold project files ──────────────────────────────────────────

if [ -f "$PROJECT_ROOT/CLAUDE.md" ]; then
    if grep -qF "$INCLUDE_LINE" "$PROJECT_ROOT/CLAUDE.md"; then
        echo "  ↩  CLAUDE.md already includes $INCLUDE_LINE (skipped)"
    elif grep -qF "$LEGACY_INCLUDE_LINE" "$PROJECT_ROOT/CLAUDE.md"; then
        # Pre-1.0 installs point at CLAUDE.md, which is now the framework's own
        # development file. Rewrite the line in place — never add a second one.
        TEMP=$(mktemp)
        sed "s|^@\.claude/framework/CLAUDE\.md$|$INCLUDE_LINE|" "$PROJECT_ROOT/CLAUDE.md" > "$TEMP"
        mv "$TEMP" "$PROJECT_ROOT/CLAUDE.md"
        echo "  ✓  Migrated @-include: $LEGACY_INCLUDE_LINE → $INCLUDE_LINE"
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
PREVIOUS_VERSION=""
if [ -f "$VERSION_MARKER" ]; then
    PREVIOUS_VERSION=$(grep '^version=' "$VERSION_MARKER" | cut -d= -f2)
fi

FRAMEWORK_VERSION="unknown"
if [ -f "$FRAMEWORK_DIR/VERSION" ]; then
    FRAMEWORK_VERSION=$(tr -d '[:space:]' < "$FRAMEWORK_DIR/VERSION")
fi
FRAMEWORK_SHA=$(git -C "$FRAMEWORK_DIR" rev-parse --short HEAD 2>/dev/null || echo "unknown")

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
    bash "$FRAMEWORK_DIR/scripts/check-install.sh" --compare-from "$PREVIOUS_VERSION"
else
    bash "$FRAMEWORK_DIR/scripts/check-install.sh"
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
