#!/bin/bash
# uninstall.sh — Remove claude-audit-framework from a project
# Run from the project root BEFORE removing the submodule:
#   bash .claude/framework/scripts/uninstall.sh

set -e

PROJECT_ROOT="$(git rev-parse --show-toplevel)"

echo "🗑  Removing claude-audit-framework..."
echo ""

# ── Skill symlinks ────────────────────────────────────────────────────────────

if [ -d "$PROJECT_ROOT/.claude/commands" ]; then
    rm -rf "$PROJECT_ROOT/.claude/commands"
    echo "  ✓  Removed .claude/commands/"
else
    echo "  ↩  .claude/commands/ not found (skipped)"
fi

# ── Specialization files ──────────────────────────────────────────────────────

if [ -f "$PROJECT_ROOT/.claude/PROJECT_AUDIT_FRAMEWORK.md" ]; then
    rm "$PROJECT_ROOT/.claude/PROJECT_AUDIT_FRAMEWORK.md"
    echo "  ✓  Removed .claude/PROJECT_AUDIT_FRAMEWORK.md"
else
    echo "  ↩  .claude/PROJECT_AUDIT_FRAMEWORK.md not found (skipped)"
fi

if [ -f "$PROJECT_ROOT/.claude/CODING_STANDARDS.md" ]; then
    rm "$PROJECT_ROOT/.claude/CODING_STANDARDS.md"
    echo "  ✓  Removed .claude/CODING_STANDARDS.md"
else
    echo "  ↩  .claude/CODING_STANDARDS.md not found (skipped)"
fi

# ── @-include in CLAUDE.md ────────────────────────────────────────────────────

if [ -f "$PROJECT_ROOT/CLAUDE.md" ] && grep -q "@.claude/framework/CLAUDE.md" "$PROJECT_ROOT/CLAUDE.md"; then
    # Remove the @-include line, then strip any blank lines left at the top of the file
    sed -i '' '/^@\.claude\/framework\/CLAUDE\.md$/d' "$PROJECT_ROOT/CLAUDE.md"
    sed -i '' '/./,$!d' "$PROJECT_ROOT/CLAUDE.md"
    echo "  ✓  Removed @.claude/framework/CLAUDE.md from CLAUDE.md"
else
    echo "  ↩  @-include not found in CLAUDE.md (skipped)"
fi

# ── .gitattributes export-ignore ──────────────────────────────────────────────

if [ -f "$PROJECT_ROOT/.gitattributes" ] && grep -qF ".claude/ export-ignore" "$PROJECT_ROOT/.gitattributes"; then
    sed -i '' '/^\.claude\/ export-ignore$/d' "$PROJECT_ROOT/.gitattributes"
    echo "  ✓  Removed .claude/ export-ignore from .gitattributes"
    if [ ! -s "$PROJECT_ROOT/.gitattributes" ]; then
        rm "$PROJECT_ROOT/.gitattributes"
        echo "  ✓  Removed empty .gitattributes"
    fi
else
    echo "  ↩  export-ignore entry not found in .gitattributes (skipped)"
fi

# ── Submodule removal (must be done manually — script runs from inside it) ────

echo ""
echo "────────────────────────────────────────────────"
echo ""
echo "⚠  One step remaining — run these commands to remove the submodule:"
echo "   (the script cannot remove the directory it is running from)"
echo ""
echo "   git submodule deinit -f .claude/framework"
echo "   git rm -f .claude/framework"
echo "   rm -rf .git/modules/.claude/framework"
echo ""
echo "────────────────────────────────────────────────"
echo ""
echo "✅ Framework files removed. Run the three commands above to finish."
echo ""
echo "To reinstall:"
echo "  git submodule add git@github.com:nicolx/claude-audit-framework.git .claude/framework"
echo "  bash .claude/framework/scripts/init-project.sh"
echo ""
