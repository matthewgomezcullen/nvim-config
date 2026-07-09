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
            -- ClaudeCodeSend is declared `range = true`, so one mapping covers both modes.
            { "<leader>cls", "<cmd>ClaudeCodeSend<cr>", mode = { "n", "v" }, desc = "Claude: send selection as @-mention" },
            { "<leader>cla", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Claude: accept diff" },
            { "<leader>cld", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Claude: reject diff" },
        },
    },
}
