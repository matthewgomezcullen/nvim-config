#!/usr/bin/env bash
# Project Claude Code session, wired to the Neovim that launched it.
#
# Neovim (via claudecode.nvim) runs a WebSocket MCP server and advertises it in
# ~/.claude/ide/<port>.lock. `--ide` only auto-connects when exactly one IDE is
# available, so pin CLAUDE_CODE_SSE_PORT to stay correct with several Neovims open.
# Once connected, edits arrive as native Neovim diffs and selections as @-mentions.
#
# $1 is the port (may be empty); any further args (e.g. --continue) are forwarded to
# `claude`, so the caller can resume the previous session.
set -euo pipefail

port="${1:-}"
shift || true  # tolerate zero args under `set -e`, then forward the rest to claude

# An `if` rather than `[ -n "$port" ] && export ...`: under `set -e` a failing `&&`
# at statement level would exit the script whenever no port was passed.
if [ -n "$port" ]; then
  export CLAUDE_CODE_SSE_PORT="$port"
fi

exec claude --ide "$@"
