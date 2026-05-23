#!/usr/bin/env bash
# .agents/scripts/sync.sh — LOCAL-ONLY project agent synchronization.
# This script is strictly for workspace-level setup and MUST NOT touch global directories.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROJECT_AGENTS="$REPO_ROOT/.agents"
LOCAL_CLAUDE="$REPO_ROOT/.claude"

echo "Running LOCAL-ONLY project agent sync..."

# 1. Wire LOCAL Claude symlinks (AGENTS.md -> CLAUDE.md)
# This ensures Claude reads project AGENTS.md files for local context and @ refs.
bash "$PROJECT_AGENTS/scripts/wire-claude.sh" "$REPO_ROOT"

# 2. Wire LOCAL .claude directory (mimics global ~/.claude structure)
if [ -d "$LOCAL_CLAUDE" ]; then
    echo "Populating local .claude directory..."
    
    # Symlink CLAUDE.md inside .claude
    ln -sf "$REPO_ROOT/AGENTS.md" "$LOCAL_CLAUDE/CLAUDE.md"
    echo "  ✓ Linked: $LOCAL_CLAUDE/CLAUDE.md -> AGENTS.md"
    
    # Symlink skills inside .claude
    if [ -d "$PROJECT_AGENTS/skills" ]; then
        ln -snf "$PROJECT_AGENTS/skills" "$LOCAL_CLAUDE/skills"
        echo "  ✓ Linked: $LOCAL_CLAUDE/skills -> .agents/skills"
    fi
fi

# 3. Link Gemini Skills (WORKSPACE SCOPE ONLY)
echo "Linking Gemini skills to WORKSPACE scope..."
if [ -d "$PROJECT_AGENTS/skills" ]; then
    for skill_dir in "$PROJECT_AGENTS/skills"/*/; do
        if [ -d "$skill_dir" ]; then
            # --scope workspace keeps the skill local-only; --consent skips the interactive prompt.
            gemini skills link "$skill_dir" --scope workspace --consent
            echo "  ✓ Linked Gemini skill: $(basename "$skill_dir") (local-only)"
        fi
    done
fi

echo "Local-only sync complete. Workspace agent configuration is now self-contained."
