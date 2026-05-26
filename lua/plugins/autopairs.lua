return {
    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        config = function()
            local npairs = require("nvim-autopairs")
            local Rule = require("nvim-autopairs.rule")
            local cond = require("nvim-autopairs.conds")

            npairs.setup({ check_ts = true })

            npairs.add_rules({
                Rule("$", "$", { "markdown" })
                    :with_pair(cond.not_after_text("$")),
            })
        end,
    },
}
