return {
    {
        "nvim-tree/nvim-tree.lua",
        version = "*",
        lazy = false,
        dependencies = {
            "nvim-tree/nvim-web-devicons",
        },
        config = function()
            local api = require("nvim-tree.api")
            require("nvim-tree").setup {
                on_attach = function(bufnr)
                    api.config.mappings.default_on_attach(bufnr)
                    vim.keymap.del("n", "<C-k>", { buffer = bufnr })
                    vim.keymap.set("n", "<C-i>", api.node.show_info_popup, { buffer = bufnr, noremap = true, silent = true, nowait = true, desc = "nvim-tree: Info" })
                    vim.keymap.set("n", "<C-f>", function() api.tree.find_file({ open = true, focus = true }) end, { noremap = true, silent = true, desc = "nvim-tree: Find File" })
                    vim.keymap.set("n", "<C-o>", function()
                        local node = api.tree.get_node_under_cursor()
                        if node and node.absolute_path then
                            vim.fn.jobstart({ "open", node.absolute_path }, { detach = true })
                        end
                    end, { buffer = bufnr, noremap = true, silent = true, nowait = true, desc = "nvim-tree: Open with default app" })
                    vim.keymap.set("n", "<leader>]", api.tree.change_root_to_node, { buffer = bufnr, noremap = true, silent = true, nowait = true, desc = "nvim-tree: CD into directory" })
                end,
                -- Mark buffers with unwritten changes in the tree (like VS Code's
                -- dirty-tab dot). renderer.icons.show.modified draws the icon.
                modified = {
                    enable = true,
                },
                renderer = {
                    icons = {
                        show = {
                            modified = true,
                        },
                    },
                },
            }
        end,
    },
    {
        'stevearc/conform.nvim',
        opts = {
            formatters_by_ft = {
                python = { "ruff_organize_imports", "ruff_format" },
            },
        },
    },
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        opts = {
            -- your configuration comes here
            -- or leave it empty to use the default settings
            -- refer to the configuration section below
        },
        keys = {
            {
                "<leader>?",
                function()
                    require("which-key").show({ global = false })
                end,
                desc = "Buffer Local Keymaps (which-key)",
            },
        },
    },
    {
        'nvim-telescope/telescope.nvim', version = '*',
        dependencies = {
            'nvim-lua/plenary.nvim',
            -- optional but recommended
            { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
        }
    },
    {
        "neovim/nvim-lspconfig",
        config = function()
            require("config.lsp")
        end,
    },
    {
        "mason-org/mason.nvim",
        opts = {}
    },
    {
        "mason-org/mason-lspconfig.nvim",
        opts = {
            ensure_installed = { "texlab", "lua_ls", "basedpyright", "ruff" },
        },
    },
    {
        "saghen/blink.cmp",
        version = "*",
        dependencies = { "L3MON4D3/LuaSnip" },
        opts = {
            keymap = {
                preset = "default",
                ["<Tab>"] = {
                    "snippet_forward",
                    function()
                        local ok, mm = pcall(require, "snippets.markdown_math")
                        if not ok then
                            return false
                        end
                        -- Gate on the module's own filetype list (markdown, tex)
                        -- so Tab escapes math in every buffer the snippets are
                        -- active in, not just Markdown.
                        if not mm.is_math_filetype() then
                            return false
                        end
                        if not mm.in_mathzone() then
                            return false
                        end
                        -- blink applies this keymap with expr = true, and an
                        -- expr mapping saves and restores the cursor (:h
                        -- :map-expr), so moving it from in here is silently
                        -- reverted. Returning a string makes blink use it as
                        -- the expr result, so hand back a <Cmd> sequence that
                        -- performs the jump outside textlock instead.
                        return vim.keycode(
                            "<Cmd>lua require('snippets.markdown_math').exit_math_node()<CR>"
                        )
                    end,
                    "fallback",
                },
            },
            snippets = { preset = "luasnip" },
            sources = {
                default = { "lsp", "path", "snippets", "buffer" },
            },
        },
    },
}
