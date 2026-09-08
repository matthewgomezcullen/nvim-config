return {
    {
        "coder/claudecode.nvim",
        -- The WebSocket server must be listening, and its lock file written, before any
        -- `claude --ide` starts. Loading this lazily on a keymap would race that.
        lazy = false,
        opts = {
            -- Claude runs in a tmux pane, not inside Neovim. This provider opens no
            -- window and no buffer; setup() only starts the server and advertises it
            -- in ~/.claude/ide/<port>.lock for the CLI to discover.
            terminal = { provider = "none" },
            log_level = "warn",
        },
        keys = {
            -- :ClaudeCodeSend / :ClaudeCodeAdd are deliberately unmapped: file references
            -- go to the clipboard instead (<leader>clf / <leader>cls in
            -- lua/config/keymaps.lua), which does not need the socket to be alive.
            { "<leader>cla", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Claude: accept diff" },
            { "<leader>cld", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Claude: reject diff" },
        },
    },
}
