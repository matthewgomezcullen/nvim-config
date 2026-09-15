return {
    {
        "hat0uma/csvview.nvim",
        ft = { "csv", "tsv" },
        cmd = { "CsvViewEnable", "CsvViewDisable", "CsvViewToggle", "CsvViewInfo" },
        ---@module "csvview"
        ---@type CsvView.Options
        opts = {
            view = {
                display_mode = "border", -- draw │ between columns, like a spreadsheet grid
            },
            keymaps = {
                -- Field text objects: dif, caf, vif, ...
                textobject_field_inner = { "if", mode = { "o", "x" } },
                textobject_field_outer = { "af", mode = { "o", "x" } },
                -- Spreadsheet-style navigation. Buffer-local, and only while the view is on.
                -- <S-Tab> / <S-Enter> need a terminal that sends distinct codes for them (CSI-u).
                jump_next_field_end = { "<Tab>", mode = { "n", "v" } },
                jump_prev_field_end = { "<S-Tab>", mode = { "n", "v" } },
                jump_next_row = { "<Enter>", mode = { "n", "v" } },
                jump_prev_row = { "<S-Enter>", mode = { "n", "v" } },
            },
        },
        config = function(_, opts)
            local csvview = require("csvview")
            csvview.setup(opts)

            -- Open CSV / TSV files as a table straight away; :CsvViewToggle shows the raw text.
            -- A named augroup, so lazy.nvim replays the FileType event that loaded the plugin.
            vim.api.nvim_create_autocmd("FileType", {
                group = vim.api.nvim_create_augroup("csvview_auto_enable", { clear = true }),
                pattern = { "csv", "tsv" },
                callback = function(args)
                    if not csvview.is_enabled(args.buf) then
                        csvview.enable(args.buf)
                    end
                end,
            })
        end,
    },
}
