#!/usr/bin/env bash
set -euo pipefail

SRC="/Users/rodcoura/Projects/yasdd"
DST="$HOME/.agents"
OPENCODE_DIR="$HOME/.opencode"
OPENCODE_CMDS_DIR="$OPENCODE_DIR/commands"
OPENCODE_AGENTS_DIR="$OPENCODE_DIR/agents"

skills_count=0
commands_count=0
prompts_count=0
agents_count=0
opencode_commands_count=0
opencode_agents_count=0

mkdir -p "$DST/skills" "$DST/commands" "$DST/prompts" "$DST/agents"

# Copy skills, overwriting any existing ones
for skill_path in "$SRC/skills"/*; do
  [ -d "$skill_path" ] || continue
  skill_name=$(basename "$skill_path")
  rm -rf "$DST/skills/$skill_name"
  cp -R "$skill_path" "$DST/skills/$skill_name"
  echo "copied skill: $skill_name"
  skills_count=$((skills_count + 1))
done

# Copy commands, overwriting any existing ones
for cmd_path in "$SRC/commands"/*.md; do
  [ -f "$cmd_path" ] || continue
  cmd_name=$(basename "$cmd_path")
  rm -f "$DST/commands/$cmd_name"
  cp "$cmd_path" "$DST/commands/$cmd_name"
  echo "copied command: $cmd_name"
  commands_count=$((commands_count + 1))
done

# Copy agents, overwriting any existing ones
for agent_path in "$SRC/agents"/*.md; do
  [ -f "$agent_path" ] || continue
  agent_name=$(basename "$agent_path")
  rm -f "$DST/agents/$agent_name"
  cp "$agent_path" "$DST/agents/$agent_name"
  echo "copied agent: $agent_name"
  agents_count=$((agents_count + 1))
done

# Copy prompts, overwriting any existing ones
for prompt_path in "$SRC/prompts"/*.md; do
  [ -f "$prompt_path" ] || continue
  prompt_name=$(basename "$prompt_path")
  rm -f "$DST/prompts/$prompt_name"
  cp "$prompt_path" "$DST/prompts/$prompt_name"
  echo "copied prompt: $prompt_name"
  prompts_count=$((prompts_count + 1))
done

# Copy commands and agents to ~/.opencode if the folder exists
if [ -d "$OPENCODE_DIR" ]; then
  mkdir -p "$OPENCODE_CMDS_DIR" "$OPENCODE_AGENTS_DIR"
  for cmd_path in "$SRC/commands"/*.md; do
    [ -f "$cmd_path" ] || continue
    cmd_name=$(basename "$cmd_path")
    rm -f "$OPENCODE_CMDS_DIR/$cmd_name"
    cp "$cmd_path" "$OPENCODE_CMDS_DIR/$cmd_name"
    echo "copied opencode command: $cmd_name"
    opencode_commands_count=$((opencode_commands_count + 1))
  done
  for agent_path in "$SRC/agents"/*.md; do
    [ -f "$agent_path" ] || continue
    agent_name=$(basename "$agent_path")
    rm -f "$OPENCODE_AGENTS_DIR/$agent_name"
    cp "$agent_path" "$OPENCODE_AGENTS_DIR/$agent_name"
    echo "copied opencode agent: $agent_name"
    opencode_agents_count=$((opencode_agents_count + 1))
  done
fi

echo
echo "=== summary ==="
echo "skills copied:            $skills_count"
echo "commands copied:          $commands_count"
echo "prompts copied:           $prompts_count"
echo "agents copied:            $agents_count"
if [ -d "$OPENCODE_DIR" ]; then
  echo "opencode commands copied: $opencode_commands_count"
  echo "opencode agents copied:  $opencode_agents_count"
else
  echo "opencode commands copied: 0 (~/.opencode not found, skipped)"
  echo "opencode agents copied:  0 (~/.opencode not found, skipped)"
fi
echo "done. installed/updated yasdd assets in $DST"
