-- Review mode: while it is on, typing `{` straight after one of the review-markup macros
-- (\ad added, \dl deleted, \rp replaced, \cm comment, \hlt highlight) inserts the author
-- option first, so `\rp{` becomes `\rp[id=MGC]{`. It fires on the `{` rather than on the
-- macro name itself, so longer commands that share a prefix (`\addplot`, `\cmidrule`)
-- are left alone, and `\ad[...]{` with options typed by hand is not touched either.
local REVIEW_ID = "MGC"
local REVIEW_MACROS = { "ad", "dl", "rp", "cm", "hlt" }

vim.b.tex_review = vim.b.tex_review or false

local group = vim.api.nvim_create_augroup("TexReviewMode", { clear = false })
-- The ftplugin re-runs on `:e` and when the filetype is set again, so drop this
-- buffer's previous autocmd instead of stacking a second one.
vim.api.nvim_clear_autocmds({ group = group, buffer = 0 })

vim.api.nvim_create_autocmd("InsertCharPre", {
  group = group,
  buffer = 0,
  callback = function()
    if not vim.b.tex_review or vim.v.char ~= "{" then
      return
    end
    local col = vim.api.nvim_win_get_cursor(0)[2]
    local before = vim.api.nvim_get_current_line():sub(1, col)
    for _, macro in ipairs(REVIEW_MACROS) do
      local cmd = "\\" .. macro
      -- `\\` before the macro is a line break followed by plain text, not the macro.
      if before:sub(-#cmd) == cmd and before:sub(-#cmd - 1, -#cmd - 1) ~= "\\" then
        -- InsertCharPre may replace the typed character with a longer string; this
        -- also works when autopairs is the one inserting the `{` (and its `}`).
        vim.v.char = "[id=" .. REVIEW_ID .. "]{"
        return
      end
    end
  end,
})

vim.keymap.set("n", "<leader>lR", function()
  vim.b.tex_review = not vim.b.tex_review
  vim.notify("Review mode " .. (vim.b.tex_review and ("on (id=" .. REVIEW_ID .. ")") or "off"))
end, { buffer = true, desc = "Toggle review mode (auto [id=" .. REVIEW_ID .. "])" })
