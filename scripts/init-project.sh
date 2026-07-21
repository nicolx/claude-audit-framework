#!/bin/bash
# init-project.sh — Initialize claude-audit-framework in a project
# Run from the project root after adding the submodule:
#   git submodule add git@github.com:nicolx/claude-audit-framework.git .claude/framework
#   bash .claude/framework/scripts/init-project.sh

set -e

PROJECT_ROOT="$(git rev-parse --show-toplevel)"
FRAMEWORK_DIR="$PROJECT_ROOT/.claude/framework"
COMMANDS_DIR="$PROJECT_ROOT/.claude/commands"

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
    if grep -q "@.claude/framework/CLAUDE.md" "$PROJECT_ROOT/CLAUDE.md"; then
        echo "  ↩  CLAUDE.md already includes @.claude/framework/CLAUDE.md (skipped)"
    else
        TEMP=$(mktemp)
        printf '@.claude/framework/CLAUDE.md\n\n' > "$TEMP"
        cat "$PROJECT_ROOT/CLAUDE.md" >> "$TEMP"
        mv "$TEMP" "$PROJECT_ROOT/CLAUDE.md"
        echo "  ✓  Prepended @.claude/framework/CLAUDE.md to existing CLAUDE.md"
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

# ── Step 4 — Verification ─────────────────────────────────────────────────────

echo "────────────────────────────────────────────────"
echo "🔍 Verification"
echo "────────────────────────────────────────────────"
echo ""

ERRORS=0
WARNINGS=0

# Skills
for skill in "$FRAMEWORK_DIR"/commands/*.md; do
    filename=$(basename "$skill")
    target="$COMMANDS_DIR/$filename"
    skillname="/$( basename "$filename" .md )"
    if [ -f "$target" ]; then
        echo "  ✓  Skill available: $skillname"
    else
        echo "  ✗  Skill missing: $skillname"
        ERRORS=$((ERRORS + 1))
    fi
done

echo ""

# CLAUDE.md @-include
if grep -q "@.claude/framework/CLAUDE.md" "$PROJECT_ROOT/CLAUDE.md" 2>/dev/null; then
    echo "  ✓  CLAUDE.md includes @.claude/framework/CLAUDE.md"
else
    echo "  ✗  CLAUDE.md does NOT include '@.claude/framework/CLAUDE.md'"
    echo "     Add it as the first line of CLAUDE.md"
    ERRORS=$((ERRORS + 1))
fi

# Project specialization files
if [ -f "$PROJECT_ROOT/.claude/PROJECT_AUDIT_FRAMEWORK.md" ]; then
    echo "  ✓  .claude/PROJECT_AUDIT_FRAMEWORK.md present"
else
    echo "  ⚠  .claude/PROJECT_AUDIT_FRAMEWORK.md missing — /project-audit will use global framework only"
    WARNINGS=$((WARNINGS + 1))
fi

if [ -f "$PROJECT_ROOT/.claude/CODING_STANDARDS.md" ]; then
    echo "  ✓  .claude/CODING_STANDARDS.md present"
else
    echo "  ⚠  .claude/CODING_STANDARDS.md missing — global coding standards apply without stack grounding"
    WARNINGS=$((WARNINGS + 1))
fi

# .claudeignore
if [ -f "$PROJECT_ROOT/.claudeignore" ]; then
    echo "  ✓  .claudeignore present"
else
    echo "  ⚠  .claudeignore missing — create it before running /project-audit"
    WARNINGS=$((WARNINGS + 1))
fi

# .gitattributes export-ignore
if grep -qF ".claude/ export-ignore" "$PROJECT_ROOT/.gitattributes" 2>/dev/null; then
    echo "  ✓  .claude/ excluded from git archive (.gitattributes)"
else
    echo "  ✗  .claude/ NOT excluded from git archive — deploy tools may include it"
    ERRORS=$((ERRORS + 1))
fi

echo ""

# Developer profile
if [ -f "$HOME/.claude/context/user_profile.md" ]; then
    echo "  ✓  Developer profile found (~/.claude/context/user_profile.md)"
    PROFILE_MISSING=0
else
    echo "  ⚠  Developer profile NOT found (~/.claude/context/user_profile.md)"
    echo "     Run /init-profile in Claude Code to calibrate recommendations to your skill level."
    WARNINGS=$((WARNINGS + 1))
    PROFILE_MISSING=1
fi

echo ""
echo "────────────────────────────────────────────────"
echo ""

# ── Step 4 — Summary and next steps ──────────────────────────────────────────

if [ "$ERRORS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
    echo "✅ claude-audit-framework ready — no issues found."
elif [ "$ERRORS" -eq 0 ]; then
    echo "✅ claude-audit-framework initialized with $WARNINGS warning(s)."
else
    echo "❌ Setup completed with $ERRORS error(s) and $WARNINGS warning(s)."
    echo "   Fix the errors above before opening Claude Code."
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
STEP=$((STEP + 1))
echo "  $STEP. Edit CODING_STANDARDS.md        — add language-specific conventions"
STEP=$((STEP + 1))

if [ -f "$PROJECT_ROOT/.claudeignore" ]; then
    echo "  $STEP. Once the above are done, open Claude Code and run /project-audit"
else
    echo "  $STEP. Create .claudeignore to exclude vendor/, node_modules/, build artefacts"
    STEP=$((STEP + 1))
    echo "  $STEP. Once the above are done, open Claude Code and run /project-audit"
fi

echo ""
echo "To update the framework later:"
echo "  cd .claude/framework && git pull origin main && cd ../.."
echo "  bash .claude/framework/scripts/init-project.sh    # refreshes command copies"
echo "  git add .claude/ && git commit -m 'chore: update claude-audit-framework'"
echo ""
