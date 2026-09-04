return {
    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        config = function()
            local npairs = require("nvim-autopairs")
            npairs.setup({
                check_ts = true,
                ts_config = {
                    lua = { "string", "source", "string_content" },
                    javascript = { "string", "template_string" },
                    markdown = {},
                },
            })

            -- LaTeX's own math delimiters. The markdown_math module handles
            -- `$...$` / `$$...$$` itself (single `$` escalates to display math
            -- on a second `$`, which isn't a plain pair), but `\(` and `\[`
            -- are ordinary pairs, so autopairs can own them. Rules are sorted
            -- longest-start-pair first, so these win over the built-in `(`/`[`.
            local Rule = require("nvim-autopairs.rule")
            npairs.add_rules({
                Rule("\\(", "\\)", "tex"),
                Rule("\\[", "\\]", "tex"),
            })
        end,
    },
}
