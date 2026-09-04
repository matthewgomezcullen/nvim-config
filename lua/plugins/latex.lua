return {
    {
        "lervag/vimtex",
        lazy = false,     -- we don't want to lazy load VimTeX
        -- tag = "v2.15", -- uncomment to pin to a specific release
        init = function()
            -- Without this, Neovim only calls a .tex file "tex" once it already
            -- contains a LaTeX marker (\documentclass, \begin{...}); an empty
            -- or plain-TeX-looking one opens as "plaintex" instead, so ftplugins,
            -- snippets and autopairs rules keyed to "tex" silently miss it.
            vim.g.tex_flavor = "latex"

            vim.g.vimtex_mappings_prefix = "<leader>l"
            vim.g.vimtex_view_method = "skim"
            vim.g.vimtex_view_skim_sync = 1
            vim.g.vimtex_view_skim_activate = 1
        end
    }
}
