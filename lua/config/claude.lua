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

-- Focus the pane recorded under `var`, falling back to the previously active pane (which is
-- normally the Claude pane you just came from) when nothing was recorded.
local function focus_pane(var)
  if vim.env.TMUX == nil then
    return
  end
  local pane = tmux({ "show-options", "-wqv", var })
  if not pane_alive(pane) then
    pane = "{last}"
  end
  tmux({ "select-pane", "-t", pane })
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

-- Give the CLI up to POLL_MS * POLL_TRIES to write an accepted diff to disk.
local POLL_MS, POLL_TRIES = 100, 20

local function buf_for(path)
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_name(buf) == path then
      return buf
    end
  end
end

-- Re-read from disk in the window showing the buffer, so the cursor survives.
local function reload(buf)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == buf then
      local cursor = vim.api.nvim_win_get_cursor(win)
      vim.api.nvim_win_call(win, function() vim.cmd("silent! edit") end)
      pcall(vim.api.nvim_win_set_cursor, win, cursor) -- the file may have shrunk
      return
    end
  end
  vim.api.nvim_buf_call(buf, function() vim.cmd("silent! edit") end)
end

-- claudecode reloads 100ms after the CLI's `close_tab` call, but the CLI writes the file
-- *after* that call, so a slow write leaves the buffer stale. Wait for the file to actually
-- diverge from the buffer instead of guessing a delay. A rejected diff never diverges, so
-- this quietly does nothing there.
local function reload_when_written(path, buf, tries)
  if not vim.api.nvim_buf_is_loaded(buf) or vim.bo[buf].modified then
    return -- never clobber unsaved work
  end
  local ok, disk = pcall(vim.fn.readfile, path)
  if ok and not vim.deep_equal(disk, vim.api.nvim_buf_get_lines(buf, 0, -1, false)) then
    reload(buf)
    return
  end
  if tries < POLL_TRIES then
    vim.defer_fn(function() reload_when_written(path, buf, tries + 1) end, POLL_MS)
  end
end

local group = vim.api.nvim_create_augroup("ClaudeIde", { clear = true })

-- `focus_after_send` is inert with provider = "none" (Claude runs outside Neovim), so the
-- plugin offers this event instead. It fires once per file and only while Claude is
-- connected; `select-pane` is idempotent, so repeats are harmless.
vim.api.nvim_create_autocmd("User", {
  group = group,
  pattern = "ClaudeCodeSendComplete",
  callback = function()
    focus_pane("@claude_code_pane")
  end,
})

vim.api.nvim_create_autocmd("User", {
  group = group,
  pattern = "ClaudeCodeDiffClosed",
  callback = function(ev)
    local path = ev.data and ev.data.file_path
    if not path or path == "" then
      return
    end
    path = vim.fn.fnamemodify(path, ":p")
    local buf = buf_for(path)
    if buf then
      reload_when_written(path, buf, 0)
    end
  end,
})
