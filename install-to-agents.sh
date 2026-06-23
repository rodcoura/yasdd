#!/usr/bin/env bash
# yasdd installer — copies skills, agents, commands, prompts to the locations
# each tool actually scans:
#   ~/.agents/              cross-tool mirror (opencode loads skills via skills.paths)
#   ~/.config/opencode/     opencode native  (agents, commands)
#   ~/.claude/              Claude Code native (agents, commands, skills)
#
# Also removes stale v1 skill renames and cleans the old buggy ~/.opencode/ path.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/rodcoura/yasdd/master/install-to-agents.sh | bash
#   YASDD_REF=v2.0 curl -fsSL https://raw.githubusercontent.com/rodcoura/yasdd/master/install-to-agents.sh | bash
#   ./install-to-agents.sh            # run from a repo checkout (uses local files)

set -euo pipefail

REPO="rodcoura/yasdd"
REF="${YASDD_REF:-master}"
TARBALL_URL="https://codeload.github.com/${REPO}/tar.gz/${REF}"

TMP=""
SRC_DIR=""

cleanup() {
  [ -n "$TMP" ] && rm -rf "$TMP"
}
trap cleanup EXIT

# --- resolve source: local checkout or download tarball ---------------------
if [ -d "$(pwd)/skills" ] && [ -d "$(pwd)/agents" ] && [ -d "$(pwd)/commands" ] && [ -f "$(pwd)/install-to-agents.sh" ]; then
  SRC_DIR="$(pwd)"
else
  TMP="$(mktemp -d)"
  echo "→ Downloading yasdd@${REF}..."
  curl -fsSL "$TARBALL_URL" -o "$TMP/yasdd.tar.gz"
  tar -xzf "$TMP/yasdd.tar.gz" -C "$TMP" --strip-components=1
  rm -f "$TMP/yasdd.tar.gz"
  SRC_DIR="$TMP"
fi

[ -d "$SRC_DIR/skills" ] && [ -d "$SRC_DIR/agents" ] && [ -d "$SRC_DIR/commands" ] || {
  echo "✗ source incomplete (skills/agents/commands missing)" >&2
  exit 1
}

# --- target directories -----------------------------------------------------
AGENTS_MIRROR="$HOME/.agents/agents"
SKILLS_MIRROR="$HOME/.agents/skills"
COMMANDS_MIRROR="$HOME/.agents/commands"
PROMPTS_MIRROR="$HOME/.agents/prompts"

OPENCODE_DIR="$HOME/.config/opencode"
OPENCODE_AGENTS="$OPENCODE_DIR/agents"
OPENCODE_COMMANDS="$OPENCODE_DIR/commands"

CLAUDE_DIR="$HOME/.claude"
CLAUDE_AGENTS="$CLAUDE_DIR/agents"
CLAUDE_COMMANDS="$CLAUDE_DIR/commands"
CLAUDE_SKILLS="$CLAUDE_DIR/skills"

mkdir -p \
  "$AGENTS_MIRROR" "$SKILLS_MIRROR" "$COMMANDS_MIRROR" "$PROMPTS_MIRROR" \
  "$OPENCODE_AGENTS" "$OPENCODE_COMMANDS" \
  "$CLAUDE_AGENTS" "$CLAUDE_COMMANDS" "$CLAUDE_SKILLS"

# --- remove stale v1 skill renames (renamed in v2) -------------------------
STALE_SKILLS=(yasdd-designer yasdd-discuss yasdd-specs yasdd-test-design yasdd-quick-discuss yasdd-quick-spec)
for s in "${STALE_SKILLS[@]}"; do
  for d in "$SKILLS_MIRROR" "$CLAUDE_SKILLS" "$HOME/.config/opencode/skills" "$HOME/.opencode/skills"; do
    [ -d "$d/$s" ] && { rm -rf "$d/$s"; echo "  removed stale skill: $s"; }
  done
done

# --- clean stale yasdd agents/commands from old buggy ~/.opencode/ path ----
if [ -d "$HOME/.opencode" ]; then
  rm -f "$HOME/.opencode/agents"/yasdd*.md 2>/dev/null || true
  rm -f "$HOME/.opencode/commands"/yasdd*.md 2>/dev/null || true
  echo "  cleaned stale yasdd files from ~/.opencode/ (old buggy path)"
fi

# --- copy skills ------------------------------------------------------------
skills_count=0
for skill_path in "$SRC_DIR/skills"/*; do
  [ -d "$skill_path" ] || continue
  skill_name=$(basename "$skill_path")
  for d in "$SKILLS_MIRROR" "$CLAUDE_SKILLS"; do
    rm -rf "$d/$skill_name"
    cp -R "$skill_path" "$d/$skill_name"
  done
  echo "  skill: $skill_name"
  skills_count=$((skills_count + 1))
done

# --- copy agents ------------------------------------------------------------
agents_count=0
for agent_path in "$SRC_DIR/agents"/*.md; do
  [ -f "$agent_path" ] || continue
  agent_name=$(basename "$agent_path")
  for d in "$AGENTS_MIRROR" "$OPENCODE_AGENTS" "$CLAUDE_AGENTS"; do
    rm -f "$d/$agent_name"
    cp "$agent_path" "$d/$agent_name"
  done
  echo "  agent: $agent_name"
  agents_count=$((agents_count + 1))
done

# --- copy commands ----------------------------------------------------------
commands_count=0
for cmd_path in "$SRC_DIR/commands"/*.md; do
  [ -f "$cmd_path" ] || continue
  cmd_name=$(basename "$cmd_path")
  for d in "$COMMANDS_MIRROR" "$OPENCODE_COMMANDS" "$CLAUDE_COMMANDS"; do
    rm -f "$d/$cmd_name"
    cp "$cmd_path" "$d/$cmd_name"
  done
  echo "  command: $cmd_name"
  commands_count=$((commands_count + 1))
done

# --- copy prompts (mirror only — not loaded as commands) -------------------
prompts_count=0
for prompt_path in "$SRC_DIR/prompts"/*.md; do
  [ -f "$prompt_path" ] || continue
  prompt_name=$(basename "$prompt_path")
  rm -f "$PROMPTS_MIRROR/$prompt_name"
  cp "$prompt_path" "$PROMPTS_MIRROR/$prompt_name"
  prompts_count=$((prompts_count + 1))
done

# --- summary ----------------------------------------------------------------
cat <<EOF

=== yasdd installed (ref: ${REF}) ===
skills:    $skills_count  →  ~/.agents/skills/, ~/.claude/skills/
agents:    $agents_count  →  ~/.agents/agents/, ~/.config/opencode/agents/, ~/.claude/agents/
commands:  $commands_count  →  ~/.agents/commands/, ~/.config/opencode/commands/, ~/.claude/commands/
prompts:   $prompts_count  →  ~/.agents/prompts/

Restart opencode and Claude Code so the new agents/commands are picked up.
EOF
