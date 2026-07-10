#!/usr/bin/env bash
# Small, independent Claude sessions for questions about the Neovim setup.
#
# Opened by <leader>cln (lua/config/claude.lua) in a short tmux pane, always cwd'd in
# ~/.config/nvim so Claude reads the config and its CLAUDE.md files. An fzf picker lists
# the questions asked before, one row per session:
#
#   enter, on a row           resume that session
#   enter, nothing matched    start a new session; the query is the first question
#   alt-enter                 start a new session from the query, even if rows matched
#   ctrl-x                    forget the row (registry only; the transcript survives)
#   esc                       close the pane
#
# Each question gets its own session id, so none of them pays input tokens to re-send
# another's history. Exiting Claude (Ctrl-D) comes back here rather than closing the pane.
#
# ctrl-x, not ctrl-d, forgets a row: Ctrl-D already means "exit Claude", and a destructive
# second meaning one keystroke away invites muscle-memory mistakes.
set -euo pipefail

CONFIG_DIR="$HOME/.config/nvim"

# The questions are personal state, not configuration, so the registry lives outside the
# config repo and can never be committed. One row per session, `<uuid>,<question>`, most
# recently used first. Parsed by splitting on the *first* comma: a uuid contains no comma,
# so a question may hold commas, quotes and apostrophes without any escaping. It must not
# hold a tab, which is fzf's column delimiter -- see sanitise().
REGISTRY_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/claude-nvim-helper"
REGISTRY="$REGISTRY_DIR/sessions.csv"

# Claude stores each session at ~/.claude/projects/<slug>/<id>.jsonl, where <slug> is the
# absolute cwd with '/' and '.' replaced by '-' (verified: -Users-mattgc--config-nvim).
slug=$(printf '%s' "$CONFIG_DIR" | sed 's/[/.]/-/g')
TRANSCRIPTS="$HOME/.claude/projects/$slug"

# The pane is only ~15 lines tall, so answers have to be short. Claude re-applies
# --append-system-prompt on every resume, so this holds for the life of each thread.
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

if ! command -v fzf >/dev/null 2>&1; then
  echo "claude-nvim-helper: fzf is required for the session picker." >&2
  echo "Install it with:  brew install fzf" >&2
  # Hold the pane open, or the message scrolls away with it.
  echo "Press enter to close." >&2
  read -r _ || true
  exit 1
fi

# The registry is a list of things the user has asked; keep it to their own eyes.
mkdir -p "$REGISTRY_DIR"
chmod 700 "$REGISTRY_DIR"

# Trim, collapse the tab that would split an fzf column, and cap the width of a row.
sanitise() {
  printf '%s' "$1" | tr '\t' ' ' | sed 's/^ *//; s/ *$//' | cut -c1-120
}

# Claude deletes transcripts once they pass `cleanupPeriodDays`, and `--resume` on a
# missing id errors out, so drop rows whose session file has gone.
registry_prune() {
  if [ ! -f "$REGISTRY" ]; then
    return 0
  fi
  local tmp row id
  tmp=$(mktemp "$REGISTRY_DIR/.sessions.XXXXXX")
  # `|| [ -n "$row" ]` so a final line without a trailing newline is not dropped.
  while IFS= read -r row || [ -n "$row" ]; do
    if [ -n "$row" ]; then
      id=${row%%,*}
      if [ -f "$TRANSCRIPTS/$id.jsonl" ]; then
        printf '%s\n' "$row" >>"$tmp"
      fi
    fi
  done <"$REGISTRY"
  mv "$tmp" "$REGISTRY"
}

# Move a row to the top, adding it if new: the picker is most-recently-used first.
# `grep -v` exits 1 when it filters everything out, which is not an error here.
registry_touch() {
  local id=$1 title=$2 tmp
  tmp=$(mktemp "$REGISTRY_DIR/.sessions.XXXXXX")
  printf '%s,%s\n' "$id" "$title" >"$tmp"
  if [ -f "$REGISTRY" ]; then
    grep -v "^$id," "$REGISTRY" >>"$tmp" || true
  fi
  mv "$tmp" "$REGISTRY"
}

registry_forget() {
  local id=$1 tmp
  if [ ! -f "$REGISTRY" ]; then
    return 0
  fi
  tmp=$(mktemp "$REGISTRY_DIR/.sessions.XXXXXX")
  grep -v "^$id," "$REGISTRY" >"$tmp" || true
  mv "$tmp" "$REGISTRY"
}

# `--` so a question opening with '-' is not parsed as a flag. `|| true` so quitting Claude
# with Ctrl-C (exit 130) does not take the picker down with it under `set -e`.
claude_new() {
  claude --model opus --append-system-prompt "$SYSTEM_PROMPT" --session-id "$1" -- "$2" || true
}

claude_resume() {
  claude --model opus --append-system-prompt "$SYSTEM_PROMPT" --resume "$1" || true
}

cd "$CONFIG_DIR"

while true; do
  registry_prune

  # BSD sed does not expand '\t' in a replacement, so substitute a literal tab. Only the
  # first comma is replaced, which is exactly the id/title split.
  rows=""
  if [ -s "$REGISTRY" ]; then
    rows=$(sed $'s/,/\t/' "$REGISTRY")
  fi

  # `printf '%s'` rather than '%s\n': an empty registry must feed fzf zero lines, not one
  # blank one. fzf reads a final line that has no trailing newline.
  #
  # fzf prints the query first (--print-query), then the key that closed it (--expect,
  # blank for a plain enter), then the selected line. It exits 0 on a selection, 1 when
  # the query matched nothing, and 130 when aborted.
  rc=0
  out=$(printf '%s' "$rows" | fzf \
    --delimiter=$'\t' --with-nth=2.. \
    --print-query --expect=alt-enter,ctrl-x \
    --layout=reverse --height=100% --info=inline \
    --prompt='ask> ' \
    --header='enter open · alt-enter new · ctrl-x forget · esc quit') || rc=$?

  if [ "$rc" -eq 130 ]; then
    exit 0
  elif [ "$rc" -gt 1 ]; then
    echo "claude-nvim-helper: fzf exited $rc" >&2
    exit "$rc"
  fi

  query=$(printf '%s' "$out" | sed -n '1p')
  key=$(printf '%s' "$out" | sed -n '2p')
  choice=$(printf '%s' "$out" | sed -n '3p')

  id=""
  title=""
  if [ -n "$choice" ]; then
    id=${choice%%$'\t'*}
    title=${choice#*$'\t'}
  fi

  case "$key" in
    ctrl-x)
      if [ -n "$id" ]; then
        registry_forget "$id"
      fi
      continue
      ;;
    alt-enter)
      # Ignore whatever the query happened to match; the query *is* the new question.
      id=""
      ;;
  esac

  if [ -n "$id" ]; then
    registry_touch "$id" "$title"
    claude_resume "$id"
  elif [ -n "$query" ]; then
    # macOS uuidgen emits uppercase; the transcript filenames prune() checks are lowercase.
    new_id=$(uuidgen | tr 'A-Z' 'a-z')
    registry_touch "$new_id" "$(sanitise "$query")"
    claude_new "$new_id" "$query"
  fi
done
