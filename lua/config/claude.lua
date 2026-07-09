-- Claude helpers, each in its own tmux pane beside Neovim.
--
--   <leader>cln  Quick questions about this Neovim setup. A pinned, Sonnet-backed session
--                always cwd'd in ~/.config/nvim (see scripts/claude-nvim-helper.sh).
--                Deliberately NOT connected to the IDE server: it is a read-only Q&A pane,
--                and letting it capture diffs for the project you are editing would confuse.
--   <leader>clc  The project session, connected to this Neovim over the Claude Code IDE
--                protocol (see scripts/claude-code.sh), so it opens native diffs and
--                receives the @-mentions that <leader>cls sends.
--
-- Focus a pane with vim-tmux-navigator; it closes when you exit Claude (Ctrl-D).

local scripts = vim.fn.expand("~/.config/nvim/scripts")

local function tmux(args)
  return vim.trim(vim.fn.system(vim.list_extend({ "tmux" }, args)))
end

local function pane_alive(pane)
  return pane ~= "" and vim.tbl_contains(vim.fn.systemlist({ "tmux", "list-panes", "-F", "#{pane_id}" }), pane)
end

-- Open a tmux pane running `cmd`, or refocus it if it is already open. The pane id lives on
-- a tmux window option, so repeated invocations never stack panes. (A pane title marker
-- would not survive Claude's TUI overwriting it.)
local function open_pane(var, split, cmd)
  if vim.env.TMUX == nil then
    vim.notify("Claude helpers need Neovim running inside tmux.", vim.log.levels.WARN)
    return
  end

  local pane = tmux({ "show-options", "-wqv", var })
  if pane_alive(pane) then
    tmux({ "select-pane", "-t", pane })
    return
  end

  local args = vim.list_extend({ "split-window" }, split)
  vim.list_extend(args, { "-P", "-F", "#{pane_id}" })
  vim.list_extend(args, cmd)
  tmux({ "set-option", "-w", var, tmux(args) })
end

local function nvim_helper()
  open_pane("@claude_nvim_pane", { "-v", "-l", "15" }, { scripts .. "/claude-nvim-helper.sh" })
end

local function project_session()
  -- Pin the port so `claude --ide` attaches to *this* Neovim, rather than declining
  -- because another instance is also advertising an IDE.
  local ok, claudecode = pcall(require, "claudecode")
  local port = ok and claudecode.state and claudecode.state.port
  local cmd = { scripts .. "/claude-code.sh" }
  if port then
    table.insert(cmd, tostring(port))
  end
  open_pane("@claude_code_pane", { "-h", "-b", "-l", "80", "-c", vim.fn.getcwd() }, cmd)
end

vim.api.nvim_create_user_command("Claude", nvim_helper, { desc = "Ask Claude about the NV setup" })
vim.api.nvim_create_user_command("ClaudeProject", project_session, { desc = "Open the project Claude Code session" })

vim.keymap.set("n", "<leader>cln", nvim_helper, { desc = "Claude: ask about this Neovim setup" })
vim.keymap.set("n", "<leader>clc", project_session, { desc = "Claude: project session (IDE-connected)" })

-- Allow lowercase `:claude` -> `:Claude` (user commands must be capitalized; this only
-- expands when `claude` is the entire command line).
vim.cmd([[cnoreabbrev <expr> claude (getcmdtype() == ':' && getcmdline() ==# 'claude') ? 'Claude' : 'claude']])
