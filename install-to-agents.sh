#!/usr/bin/env bash
set -euo pipefail

SRC="/Users/rodcoura/Projects/yasdd"
DST="$HOME/.agents"

mkdir -p "$DST/skills" "$DST/commands" "$DST/prompts"

# Copy skills, overwriting any existing ones
for skill_path in "$SRC/skills"/*; do
  [ -d "$skill_path" ] || continue
  skill_name=$(basename "$skill_path")
  rm -rf "$DST/skills/$skill_name"
  cp -R "$skill_path" "$DST/skills/$skill_name"
  echo "copied skill: $skill_name"
done

# Copy commands, overwriting any existing ones
for cmd_path in "$SRC/commands"/*.md; do
  [ -f "$cmd_path" ] || continue
  cmd_name=$(basename "$cmd_path")
  rm -f "$DST/commands/$cmd_name"
  cp "$cmd_path" "$DST/commands/$cmd_name"
  echo "copied command: $cmd_name"
done

# Copy prompts, overwriting any existing ones
for prompt_path in "$SRC/prompts"/*.md; do
  [ -f "$prompt_path" ] || continue
  prompt_name=$(basename "$prompt_path")
  rm -f "$DST/prompts/$prompt_name"
  cp "$prompt_path" "$DST/prompts/$prompt_name"
  echo "copied prompt: $prompt_name"
done

echo "done. installed/updated yasdd assets in $DST"
