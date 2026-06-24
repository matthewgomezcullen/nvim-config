return {
    {
        "L3MON4D3/LuaSnip",
        version = "v2.*",
        build = "make install_jsregexp",
        event = { "InsertEnter" },
        config = function()
            local ls = require("luasnip")
            ls.config.set_config({
                store_selection_keys = "<Tab>",
                update_events = "TextChanged,TextChangedI",
            })
            require("snippets.markdown_math").setup()
        end,
    },
}
