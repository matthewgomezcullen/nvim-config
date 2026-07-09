#!/usr/bin/env bash
# Dedicated, persistent Claude session for quick questions about the Neovim setup.
# - Always cwd'd in ~/.config/nvim so Claude reads the config + CLAUDE.md files.
# - Always targets one fixed session id, so it stays separate from ad-hoc config-dev
#   sessions in the same dir and adds only a single `claude --resume` entry.
set -euo pipefail

CONFIG_DIR="$HOME/.config/nvim"

# Fixed, not secret, and generated fresh for this helper. It must never collide with a
# session you started by hand in ~/.config/nvim, or `<leader>cl` would silently resume
# that conversation instead. Before changing it, check the id is unused:
#   ls ~/.claude/projects/*/<new-id>.jsonl
SESSION_ID="a4528f11-1ed5-4d41-9cf3-356d874a2600"

# The pane is only ~15 lines tall, so answers have to be short. Claude re-applies
# --append-system-prompt on every resume, so this holds for the life of the thread.
# It lives here rather than in CLAUDE.md because it should shape *only* this helper,
# not the config-dev sessions that share ~/.config/nvim as their cwd.
#
# `read -d ''` rather than `$(cat <<EOF)`: macOS ships bash 3.2, which cannot parse an
# apostrophe inside a quoted heredoc nested in command substitution. `read` exits 1 at
# EOF, hence the `|| true` under `set -e`.
read -r -d '' SYSTEM_PROMPT <<'EOF' || true
You are answering quick questions about this Neovim configuration, from a small
(~15 line) tmux pane docked beneath the user's editor. Optimise for how fast the
answer can be read, not how complete it is.

- Lead with the answer: the exact keystroke, command, or option. Then at most a
  sentence or two of context. No preamble, no restatement of the question.
- Stay under about five lines unless the user explicitly asks you to go deeper.
- Answer from THIS config, not generic Neovim advice. Check the relevant file before
  answering, and say when a mapping is a Neovim default rather than something set here.
- This is a read-only Q&A pane. Explain and quote the config, but do not edit files
  unless the user explicitly asks you to.
- The user is coming from VS Code, so name the VS Code equivalent when it clarifies.
EOF

cd "$CONFIG_DIR"

# Claude stores each session at ~/.claude/projects/<slug>/<id>.jsonl, where <slug> is
# the absolute cwd with '/' and '.' replaced by '-' (verified: -Users-mattgc--config-nvim).
slug=$(printf '%s' "$CONFIG_DIR" | sed 's/[/.]/-/g')
session_file="$HOME/.claude/projects/$slug/$SESSION_ID.jsonl"

if [ -f "$session_file" ]; then
  # Continue the one helper thread in place.
  exec claude --model sonnet --append-system-prompt "$SYSTEM_PROMPT" --resume "$SESSION_ID"
else
  # First run: create it with the fixed id.
  exec claude --model sonnet --append-system-prompt "$SYSTEM_PROMPT" --session-id "$SESSION_ID"
fi
