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

            -- Deliberately no "tex": VimTeX brings its own syntax plugin, and
            -- vim.treesitter.start() clears 'syntax' when it attaches, which
            -- takes VimTeX's highlighting with it. The math snippets don't need
            -- the highlighter — nvim-treesitter registers tex -> latex, so
            -- get_parser() builds a parser on demand for in_mathzone().
            -- ("latex" here would be a no-op anyway: it names the parser, not
            -- the filetype.)
            vim.api.nvim_create_autocmd("FileType", {
                pattern = { "markdown", "lua", "python" },
                callback = function()
                    pcall(vim.treesitter.start)
                end,
            })
        end,
    },
    {
        "nvim-treesitter/nvim-treesitter-context",
        event = "BufReadPost",
        opts = {
            max_lines = 3,          -- at most 3 sticky lines, so nested code can't eat the window
            multiline_threshold = 1, -- collapse a multi-line signature to its first line
            trim_scope = "outer",   -- when over max_lines, drop the outermost context first
            separator = "-",        -- underline the sticky region
        },
    },
}
