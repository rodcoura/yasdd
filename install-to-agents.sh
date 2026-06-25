#!/usr/bin/env bash
# yasdd installer — copies skills and agents to the locations each tool
# actually scans:
#   ~/.agents/              cross-tool mirror (opencode loads skills via skills.paths)
#   ~/.config/opencode/     opencode native  (agents)
#   ~/.claude/              Claude Code native (agents, skills)
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/rodcoura/yasdd/master/install-to-agents.sh | bash
#   YASDD_REF=<tag> curl -fsSL https://raw.githubusercontent.com/rodcoura/yasdd/master/install-to-agents.sh | bash
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
if [ -d "$(pwd)/skills" ] && [ -f "$(pwd)/install-to-agents.sh" ]; then
  SRC_DIR="$(pwd)"
else
  TMP="$(mktemp -d)"
  echo "→ Downloading yasdd@${REF}..."
  curl -fsSL "$TARBALL_URL" -o "$TMP/yasdd.tar.gz"
  tar -xzf "$TMP/yasdd.tar.gz" -C "$TMP" --strip-components=1
  rm -f "$TMP/yasdd.tar.gz"
  SRC_DIR="$TMP"
fi

[ -d "$SRC_DIR/skills" ] || {
  echo "✗ source incomplete (skills missing)" >&2
  exit 1
}

# --- target directories -----------------------------------------------------
AGENTS_MIRROR="$HOME/.agents/agents"
SKILLS_MIRROR="$HOME/.agents/skills"

OPENCODE_DIR="$HOME/.config/opencode"
OPENCODE_AGENTS="$OPENCODE_DIR/agents"

CLAUDE_DIR="$HOME/.claude"
CLAUDE_AGENTS="$CLAUDE_DIR/agents"
CLAUDE_SKILLS="$CLAUDE_DIR/skills"

mkdir -p \
  "$AGENTS_MIRROR" "$SKILLS_MIRROR" \
  "$OPENCODE_AGENTS" \
  "$CLAUDE_AGENTS" "$CLAUDE_SKILLS"

# --- remove obsolete skill folders -----------------------------------------
STALE_SKILLS=(yasdd yasdd-orchestrator yasdd-designer yasdd-discuss yasdd-specs yasdd-test-design yasdd-quick-discuss yasdd-quick-spec yasdd-quick-win yasdd-quick-architect yasdd-quick-elicitation yasdd-elicitation yasdd-architect yasdd-continue yasdd-clear yasdd-status yasdd-init)
for s in "${STALE_SKILLS[@]}"; do
  for d in "$SKILLS_MIRROR" "$CLAUDE_SKILLS" "$HOME/.config/opencode/skills" "$HOME/.opencode/skills"; do
    [ -d "$d/$s" ] && { rm -rf "$d/$s"; echo "  removed obsolete skill: $s"; }
  done
done

# --- remove stale yasdd commands/prompts from prior installs ----------------
for d in "$HOME/.agents/commands" "$HOME/.agents/prompts" "$OPENCODE_DIR/commands" "$CLAUDE_DIR/commands"; do
  if [ -d "$d" ]; then
    rm -f "$d"/yasdd*.md 2>/dev/null || true
  fi
done
echo "  cleaned stale yasdd commands/prompts from prior installs"

# --- clean yasdd agents from ~/.opencode/ path ------------------------------
if [ -d "$HOME/.opencode" ]; then
  rm -f "$HOME/.opencode/agents"/yasdd*.md 2>/dev/null || true
  echo "  cleaned yasdd files from ~/.opencode/"
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

# --- copy agents (optional; dir may be absent) -----------------------------
agents_count=0
if [ -d "$SRC_DIR/agents" ]; then
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
fi

# --- summary ----------------------------------------------------------------
cat <<EOF

=== yasdd installed (ref: ${REF}) ===
skills:    $skills_count  →  ~/.agents/skills/, ~/.claude/skills/
agents:    $agents_count

Restart opencode and Claude Code so the new agents/skills are picked up.
EOF
