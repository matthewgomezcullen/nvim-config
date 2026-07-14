return {
    {
        "lewis6991/gitsigns.nvim",
        opts = {},
    },
    {
        "sindrets/diffview.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        opts = {},
        keys = {
            { "<leader>go", "<cmd>DiffviewOpen<cr>", desc = "Diffview: open" },
            { "<leader>gc", "<cmd>DiffviewClose<cr>", desc = "Diffview: close" },
        },
    },
}
