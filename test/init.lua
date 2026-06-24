-- Minimal init for headless test runs.
-- Mirrors just enough of the real config to load LuaSnip + our module.

local lazy_root = vim.fn.stdpath("data") .. "/lazy"
for _, plugin in ipairs({ "plenary.nvim", "LuaSnip", "nvim-treesitter" }) do
    vim.opt.rtp:prepend(lazy_root .. "/" .. plugin)
end

vim.opt.rtp:prepend(vim.fn.stdpath("config"))

require("luasnip").config.set_config({
    store_selection_keys = "<Tab>",
})

require("snippets.markdown_math").setup()

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "markdown", "lua", "latex" },
    callback = function()
        pcall(vim.treesitter.start)
    end,
})
