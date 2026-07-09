-- Quick "ask Claude about my Neovim setup" helper.
-- Opens a small tmux pane below Neovim running a dedicated, persistent Claude session
-- that is always cwd'd in ~/.config/nvim (see scripts/claude-nvim-helper.sh).
-- Focus it with <C-j> (vim-tmux-navigator); it closes when you exit Claude (Ctrl-D).

local script = vim.fn.expand("~/.config/nvim/scripts/claude-nvim-helper.sh")

local function open_helper()
  if vim.env.TMUX == nil then
    vim.notify("Claude helper needs Neovim running inside tmux.", vim.log.levels.WARN)
    return
  end

  -- Reuse the existing helper pane if it's still open (avoid stacking panes).
  local pane = vim.trim(vim.fn.system({ "tmux", "show-options", "-wqv", "@claude_helper_pane" }))
  if pane ~= "" and vim.tbl_contains(
    vim.fn.systemlist({ "tmux", "list-panes", "-F", "#{pane_id}" }), pane) then
    vim.fn.system({ "tmux", "select-pane", "-t", pane })
    return
  end

  -- Otherwise open a small (15-line) pane below and remember its id on the window.
  pane = vim.trim(vim.fn.system({
    "tmux", "split-window", "-v", "-l", "15", "-P", "-F", "#{pane_id}", script }))
  vim.fn.system({ "tmux", "set-option", "-w", "@claude_helper_pane", pane })
end

vim.api.nvim_create_user_command("Claude", open_helper, { desc = "Ask Claude about the NV setup" })
vim.keymap.set("n", "<leader>cln", open_helper, { desc = "Ask Claude about the NV setup" })

-- Allow lowercase `:claude` -> `:Claude` (user commands must be capitalized; this only
-- expands when `claude` is the entire command line).
vim.cmd([[cnoreabbrev <expr> claude (getcmdtype() == ':' && getcmdline() ==# 'claude') ? 'Claude' : 'claude']])
