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
        end,
    },
}
