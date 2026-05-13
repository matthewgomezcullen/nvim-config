return {
    {
        "jake-stewart/multicursor.nvim",
        branch = "1.0",
        keys = {
            {
                "<leader>ma",
                function()
                    require("multicursor-nvim").matchAllAddCursors()
                end,
                mode = { "n", "x" },
                desc = "Multi-cursor: Add cursors for all matches",
            },
            {
                "<leader>mn",
                function()
                    require("multicursor-nvim").matchAddCursor(1)
                end,
                mode = { "n", "x" },
                desc = "Multi-cursor: Add next match",
            },
            {
                "<leader>mN",
                function()
                    require("multicursor-nvim").matchAddCursor(-1)
                end,
                mode = { "n", "x" },
                desc = "Multi-cursor: Add previous match",
            },
            {
                "<leader>ms",
                function()
                    require("multicursor-nvim").matchSkipCursor(1)
                end,
                mode = { "n", "x" },
                desc = "Multi-cursor: Skip next match",
            },
            {
                "<leader>mS",
                function()
                    require("multicursor-nvim").matchSkipCursor(-1)
                end,
                mode = { "n", "x" },
                desc = "Multi-cursor: Skip previous match",
            },
            {
                "<leader>mr",
                function()
                    require("multicursor-nvim").restoreCursors()
                end,
                mode = "n",
                desc = "Multi-cursor: Restore cursors",
            },
        },
        config = function()
            local mc = require("multicursor-nvim")

            mc.setup()

            mc.addKeymapLayer(function(layer_set)
                layer_set({ "n", "x" }, "<left>", mc.prevCursor)
                layer_set({ "n", "x" }, "<right>", mc.nextCursor)
                layer_set({ "n", "x" }, "<leader>mx", mc.deleteCursor)

                layer_set("n", "<esc>", function()
                    if not mc.cursorsEnabled() then
                        mc.enableCursors()
                    else
                        mc.clearCursors()
                    end
                end)
            end)

            local hl = vim.api.nvim_set_hl
            hl(0, "MultiCursorCursor", { reverse = true })
            hl(0, "MultiCursorVisual", { link = "Visual" })
            hl(0, "MultiCursorSign", { link = "SignColumn" })
            hl(0, "MultiCursorMatchPreview", { link = "Search" })
            hl(0, "MultiCursorDisabledCursor", { reverse = true })
            hl(0, "MultiCursorDisabledVisual", { link = "Visual" })
            hl(0, "MultiCursorDisabledSign", { link = "SignColumn" })
        end,
    },
}
