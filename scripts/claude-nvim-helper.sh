#!/usr/bin/env bash
# Dedicated, persistent Claude session for quick questions about the Neovim setup.
# - Always cwd'd in ~/.config/nvim so Claude reads the config + CLAUDE.md files.
# - Always targets one fixed session id, so it stays separate from ad-hoc config-dev
#   sessions in the same dir and adds only a single `claude --resume` entry.
set -euo pipefail

CONFIG_DIR="$HOME/.config/nvim"
SESSION_ID="5b5c8c55-3786-47c3-9fbd-030464277abc"   # fixed; not secret

cd "$CONFIG_DIR"

# Claude stores each session at ~/.claude/projects/<slug>/<id>.jsonl, where <slug> is
# the absolute cwd with '/' and '.' replaced by '-' (verified: -Users-mattgc--config-nvim).
slug=$(printf '%s' "$CONFIG_DIR" | sed 's/[/.]/-/g')
session_file="$HOME/.claude/projects/$slug/$SESSION_ID.jsonl"

if [ -f "$session_file" ]; then
  exec claude --resume "$SESSION_ID"      # continue the one helper thread in place
else
  exec claude --session-id "$SESSION_ID"  # first run: create it with the fixed id
fi
