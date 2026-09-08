vim.keymap.set("n", "<leader>r", ":e!<CR>", { desc = "Reload file from disk" })
vim.keymap.set("n", "<leader>e", function() require("nvim-tree.api").tree.toggle() end, { noremap = true, silent = true, desc = "nvim-tree: Toggle" })
vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files hidden=true no_ignore=true<cr>", { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", { desc = "Live grep" })
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true, desc = "Move down by screen line" })
vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true, desc = "Move up by screen line" })
vim.keymap.set("n", "<Down>", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true, desc = "Move down by screen line" })
vim.keymap.set("n", "<Up>", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true, desc = "Move up by screen line" })
vim.keymap.set("v", "<leader>y", '"+y', { desc = "Yank selection to system clipboard" })

-- Copy a reference to the current buffer to the system clipboard: `@path` on its own, or
-- with the cursor line / visual selection as `@path#L10-20`. That is the syntax Claude Code
-- resolves when you paste it into a prompt, but nothing here depends on Claude: no plugin,
-- no socket, no pane. It is a plain yank, so it works with nothing else running.
local function yank_file_reference(with_range)
  local path = vim.fn.expand("%:p")
  if path == "" then
    vim.notify("No file in this buffer to reference.", vim.log.levels.WARN)
    return
  end

  -- `:.` is relative to the cwd; a file outside it keeps its absolute path.
  local ref = "@" .. vim.fn.fnamemodify(path, ":.")
  if with_range then
    -- In Visual mode these are the two ends of the selection; outside it both are the
    -- cursor line, which gives a single-line `#L12`.
    local first, last = vim.fn.line("v"), vim.fn.line(".")
    if first > last then
      first, last = last, first
    end
    ref = ref .. "#L" .. first .. (last > first and "-" .. last or "")
  end

  vim.fn.setreg("+", ref)
  -- Leave Visual mode, so the selection does not linger after the yank.
  if vim.fn.mode():find("^[vV\22]") then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
  end
  vim.notify("Copied " .. ref)
end

vim.keymap.set("n", "<leader>clf", function() yank_file_reference(false) end, { desc = "Copy file reference to clipboard" })
-- A function rhs runs like <Cmd>, so Visual mode is still active and line("v") is the start
-- of the selection; in Normal mode it is the cursor line.
vim.keymap.set({ "n", "x" }, "<leader>cls", function() yank_file_reference(true) end, { desc = "Copy file reference with line range to clipboard" })
