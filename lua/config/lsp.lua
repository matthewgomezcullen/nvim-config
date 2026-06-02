vim.lsp.config('lua_ls', {
    settings = {
        Lua = {
            runtime = { version = "LuaJIT" },
            workspace = {
                library = vim.api.nvim_get_runtime_file("", true),
                checkThirdParty = false,
            },
            diagnostics = { globals = { "vim" } },
            telemetry = { enable = false },
        },
    },
})

vim.lsp.config('basedpyright', {
    settings = {
        basedpyright = {
            analysis = {
                typeCheckingMode = "standard",
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                diagnosticMode = "openFilesOnly",
            },
        },
    },
})

vim.lsp.config('ruff', {
    on_attach = function(client, _)
        -- Defer hover to basedpyright so the two LSPs don't both reply.
        client.server_capabilities.hoverProvider = false
    end,
})

vim.lsp.enable({ 'texlab', 'lua_ls', 'basedpyright', 'ruff' })
