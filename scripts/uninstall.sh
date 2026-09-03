#!/bin/bash
# uninstall.sh — Remove claude-audit-framework from a project
# Run from the project root BEFORE removing the submodule:
#   bash .claude/framework/scripts/uninstall.sh

set -e

PROJECT_ROOT="$(git rev-parse --show-toplevel)"
FRAMEWORK_DIR="$PROJECT_ROOT/.claude/framework"
COMMANDS_DIR="$PROJECT_ROOT/.claude/commands"

# strip_line <file> <extended-regex> — delete matching lines in place.
# Temp file + mv: portable across BSD (macOS) and GNU sed, unlike `sed -i`.
# -E because BSD sed does not support `\|` alternation in basic regexes.
# Slashes in the pattern must be escaped — `/` is the address delimiter.
strip_line() {
    local file="$1" pattern="$2" tmp
    tmp=$(mktemp)
    sed -E "/$pattern/d" "$file" > "$tmp"
    mv "$tmp" "$file"
}

# strip_leading_blanks <file> — drop blank lines at the top of the file.
strip_leading_blanks() {
    local file="$1" tmp
    tmp=$(mktemp)
    sed '/./,$!d' "$file" > "$tmp"
    mv "$tmp" "$file"
}

echo "🗑  Removing claude-audit-framework..."
echo ""

# ── Installed skills ──────────────────────────────────────────────────────────
# Remove only the command files this framework installed. Commands the project
# owns are left in place, and the directory is removed only if it ends up empty.

if [ -d "$COMMANDS_DIR" ]; then
    REMOVED=0
    if [ -d "$FRAMEWORK_DIR/commands" ]; then
        for skill in "$FRAMEWORK_DIR"/commands/*.md; do
            [ -e "$skill" ] || continue
            target="$COMMANDS_DIR/$(basename "$skill")"
            if [ -f "$target" ]; then
                rm "$target"
                echo "  ✓  Removed skill: /$(basename "$skill" .md)"
                REMOVED=$((REMOVED + 1))
            fi
        done
    else
        # Submodule already gone — fall back to the known command names
        for name in project-audit competency-review init-profile; do
            if [ -f "$COMMANDS_DIR/$name.md" ]; then
                rm "$COMMANDS_DIR/$name.md"
                echo "  ✓  Removed skill: /$name"
                REMOVED=$((REMOVED + 1))
            fi
        done
    fi

    [ "$REMOVED" -eq 0 ] && echo "  ↩  No framework skills found in .claude/commands/ (skipped)"

    if rmdir "$COMMANDS_DIR" 2>/dev/null; then
        echo "  ✓  Removed empty .claude/commands/"
    else
        echo "  ℹ  .claude/commands/ kept — it still contains project-owned commands"
    fi
else
    echo "  ↩  .claude/commands/ not found (skipped)"
fi

# ── Specialization files ──────────────────────────────────────────────────────

for spec in PROJECT_AUDIT_FRAMEWORK.md CODING_STANDARDS.md audit-focus.md; do
    if [ -f "$PROJECT_ROOT/.claude/$spec" ]; then
        rm "$PROJECT_ROOT/.claude/$spec"
        echo "  ✓  Removed .claude/$spec"
    else
        echo "  ↩  .claude/$spec not found (skipped)"
    fi
done

# ── Per-file check hook ───────────────────────────────────────────────────────
# The script goes; the settings.json entry is left alone, because that file may
# hold settings the project owns. A leftover entry is harmless: its command ends
# in `|| true`, so a missing script is a silent no-op rather than an error.

if [ -f "$PROJECT_ROOT/.claude/hooks/on-file-edit.sh" ]; then
    rm "$PROJECT_ROOT/.claude/hooks/on-file-edit.sh"
    echo "  ✓  Removed .claude/hooks/on-file-edit.sh"
    if rmdir "$PROJECT_ROOT/.claude/hooks" 2>/dev/null; then
        echo "  ✓  Removed empty .claude/hooks/"
    fi
    if grep -qF "on-file-edit.sh" "$PROJECT_ROOT/.claude/settings.json" 2>/dev/null; then
        echo "  ℹ  .claude/settings.json still references the hook — harmless, but you can"
        echo "     drop the PostToolUse entry (or run /hooks in Claude Code) to tidy up"
    fi
fi

# ── Version marker ────────────────────────────────────────────────────────────

if [ -f "$PROJECT_ROOT/.claude/.framework-version" ]; then
    rm "$PROJECT_ROOT/.claude/.framework-version"
    echo "  ✓  Removed .claude/.framework-version"
fi

# ── @-include in CLAUDE.md ────────────────────────────────────────────────────
# Both forms are handled: INSTRUCTIONS.md (current) and CLAUDE.md (pre-1.0 installs).

if [ -f "$PROJECT_ROOT/CLAUDE.md" ] &&
   grep -qE '^@\.claude/framework/(INSTRUCTIONS|CLAUDE)\.md$' "$PROJECT_ROOT/CLAUDE.md"; then
    strip_line "$PROJECT_ROOT/CLAUDE.md" '^@\.claude\/framework\/(INSTRUCTIONS|CLAUDE)\.md$'
    strip_leading_blanks "$PROJECT_ROOT/CLAUDE.md"
    echo "  ✓  Removed framework @-include from CLAUDE.md"
else
    echo "  ↩  @-include not found in CLAUDE.md (skipped)"
fi

# ── .gitattributes export-ignore ──────────────────────────────────────────────

if [ -f "$PROJECT_ROOT/.gitattributes" ] && grep -qF ".claude/ export-ignore" "$PROJECT_ROOT/.gitattributes"; then
    strip_line "$PROJECT_ROOT/.gitattributes" '^\.claude\/ export-ignore$'
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
echo "Two things were deliberately kept:"
echo "  • ~/.claude/context/user_profile.md — personal, shared across projects"
echo "  • docs/audits/ — the project's own quality history, valuable without the framework"
echo ""
echo "To reinstall:"
echo "  git submodule add git@github.com:nicolx/claude-audit-framework.git .claude/framework"
echo "  bash .claude/framework/scripts/init-project.sh"
echo ""
