return {
    {
        "nvim-treesitter/nvim-treesitter",
        branch = "main",
        lazy = false,
        build = ":TSUpdate",
        config = function()
            require("nvim-treesitter").install({
                "markdown", "markdown_inline", "lua", "latex", "python",
            })

            vim.api.nvim_create_autocmd("FileType", {
                pattern = { "markdown", "lua", "latex", "python" },
                callback = function()
                    pcall(vim.treesitter.start)
                end,
            })
        end,
    },
}
