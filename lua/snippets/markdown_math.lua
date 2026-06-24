local M = {}

local math_zone_node_types = {
    latex_block = true,
    inline_formula = true,
    displayed_equation = true,
    math_environment = true,
    pseudo_environment = true,
}

function M.in_mathzone()
    local ok_p, parser = pcall(vim.treesitter.get_parser, 0)
    if not ok_p or not parser then
        return false
    end
    local pos = vim.api.nvim_win_get_cursor(0)
    local row = pos[1] - 1
    pcall(parser.parse, parser, { row, 0, row + 1, 0 })

    local ok, node = pcall(vim.treesitter.get_node, { ignore_injections = false })
    if not ok or not node then
        return false
    end
    while node do
        if math_zone_node_types[node:type()] then
            return true
        end
        node = node:parent()
    end
    return false
end

function M.exit_math_node()
    local ok_p, parser = pcall(vim.treesitter.get_parser, 0)
    if not ok_p or not parser then
        return false
    end
    local pos = vim.api.nvim_win_get_cursor(0)
    local row = pos[1] - 1
    pcall(parser.parse, parser, { row, 0, row + 1, 0 })

    local node = vim.treesitter.get_node({ ignore_injections = false })
    while node do
        if math_zone_node_types[node:type()] then
            local _, _, end_row, end_col = node:range()
            local line = vim.api.nvim_buf_get_lines(0, end_row, end_row + 1, false)[1] or ""
            end_col = math.min(end_col, #line)
            vim.api.nvim_win_set_cursor(0, { end_row + 1, end_col })
            return true
        end
        node = node:parent()
    end
    return false
end

local function parse_file(path)
    local f = io.open(path, "r")
    if not f then
        vim.notify("markdown_math: cannot open " .. path, vim.log.levels.ERROR)
        return {}
    end

    local entries = {}
    local seen = {}
    local lineno = 0
    for line in f:lines() do
        lineno = lineno + 1
        if not line:match("^%s*$") then
            local s, e = line:find(":::", 1, true)
            if not s then
                vim.notify(
                    ("snippets.txt:%d: missing ':::', skipping"):format(lineno),
                    vim.log.levels.WARN
                )
            else
                local trigger = line:sub(1, s - 1)
                local body = line:sub(e + 1)
                if body:sub(-1) == ";" then
                    body = body:sub(1, -2)
                end
                if trigger == "" then
                    vim.notify(
                        ("snippets.txt:%d: empty trigger, skipping"):format(lineno),
                        vim.log.levels.WARN
                    )
                elseif body == "" then
                    vim.notify(
                        ("snippets.txt:%d: empty body for trigger '%s', skipping"):format(lineno, trigger),
                        vim.log.levels.WARN
                    )
                elseif body:sub(-1) == "\\" then
                    vim.notify(
                        ("snippets.txt:%d: expansion ends with bare backslash, skipping (trigger '%s')"):format(lineno, trigger),
                        vim.log.levels.WARN
                    )
                else
                    if seen[trigger] then
                        vim.notify(
                            ("snippets.txt:%d: duplicate trigger '%s' (overrides line %d)"):format(lineno, trigger, seen[trigger]),
                            vim.log.levels.WARN
                        )
                    end
                    seen[trigger] = lineno
                    table.insert(entries, { trigger = trigger, body = body, line = lineno })
                end
            end
        end
    end
    f:close()
    return entries
end

local function body_to_nodes(body)
    local ls = require("luasnip")
    local i, t = ls.insert_node, ls.text_node

    local nodes = {}
    local idx = 0
    local pos = 1

    while pos <= #body do
        local s_cursor = body:find("#cursor", pos, true)
        local s_tab = body:find("#tab", pos, true)
        local s, len
        if s_cursor and s_tab then
            if s_cursor < s_tab then
                s, len = s_cursor, 7
            else
                s, len = s_tab, 4
            end
        elseif s_cursor then
            s, len = s_cursor, 7
        elseif s_tab then
            s, len = s_tab, 4
        end

        if not s then
            table.insert(nodes, t(body:sub(pos)))
            break
        end

        if s > pos then
            table.insert(nodes, t(body:sub(pos, s - 1)))
        end
        idx = idx + 1
        table.insert(nodes, i(idx))
        pos = s + len
    end

    if #nodes == 0 then
        table.insert(nodes, t(""))
    end

    return nodes
end

function M.build_snippets(path)
    local ls = require("luasnip")
    local s, f = ls.snippet, ls.function_node

    local out = {}

    for _, entry in ipairs(parse_file(path)) do
        table.insert(out, s({
            trig = entry.trigger,
            wordTrig = true,
        }, body_to_nodes(entry.body), { condition = M.in_mathzone }))
    end

    -- {a}/{b} -> \frac{a}{b}, expanded on <Space>.
    table.insert(out, s({
        trig = "{(.-)}/{(.-)}",
        regTrig = true,
        wordTrig = false,
    }, {
        f(function(_, snip)
            return "\\frac{" .. snip.captures[1] .. "}{" .. snip.captures[2] .. "}"
        end),
    }, { condition = M.in_mathzone }))

    return out
end

local function insert_text_at_cursor(text, cursor_advance)
    local pos = vim.api.nvim_win_get_cursor(0)
    local row, col = pos[1] - 1, pos[2]
    vim.api.nvim_buf_set_text(0, row, col, row, col, { text })
    vim.api.nvim_win_set_cursor(0, { row + 1, col + (cursor_advance or #text) })
end

local function math_pair_handler(char)
    return function()
        if M.in_mathzone() then
            insert_text_at_cursor(char .. "{}", 2)
        else
            insert_text_at_cursor(char)
        end
    end
end

local function dollar_handler()
    local pos = vim.api.nvim_win_get_cursor(0)
    local row, col = pos[1] - 1, pos[2]
    local line = vim.api.nvim_buf_get_lines(0, row, row + 1, false)[1] or ""
    local cb = col > 0 and line:sub(col, col) or ""
    local ca = line:sub(col + 1, col + 1)
    local cb2 = col >= 2 and line:sub(col - 1, col - 1) or ""
    local ca2 = line:sub(col + 2, col + 2)

    if cb == "$" and ca == "$" and cb2 == "$" and ca2 == "$" then
        vim.api.nvim_win_set_cursor(0, { row + 1, col + 2 })
    elseif cb == "$" and ca == "$" then
        vim.api.nvim_buf_set_text(0, row, col, row, col, { "$$" })
        vim.api.nvim_win_set_cursor(0, { row + 1, col + 1 })
    elseif ca == "$" then
        vim.api.nvim_win_set_cursor(0, { row + 1, col + 1 })
    else
        vim.api.nvim_buf_set_text(0, row, col, row, col, { "$$" })
        vim.api.nvim_win_set_cursor(0, { row + 1, col + 1 })
    end
end

local function space_handler()
    local ls = require("luasnip")
    if ls.expandable() then
        ls.expand()
        return
    end
    insert_text_at_cursor(" ")
end

local function install_buffer_keymaps(bufnr)
    vim.keymap.set("i", "<Space>", space_handler, {
        buffer = bufnr, desc = "Expand snippet or insert space",
    })
    vim.keymap.set("i", "<S-Space>", " ", {
        buffer = bufnr, desc = "Insert literal space (bypass snippet expansion)",
    })
    vim.keymap.set("i", "^", math_pair_handler("^"), {
        buffer = bufnr, desc = "Superscript autopair in math",
    })
    vim.keymap.set("i", "_", math_pair_handler("_"), {
        buffer = bufnr, desc = "Subscript autopair in math",
    })
    vim.keymap.set("i", "$", dollar_handler, {
        buffer = bufnr, desc = "Display math autopair",
    })
end

function M.setup()
    local ls = require("luasnip")
    local path = vim.fn.stdpath("config") .. "/snippets.txt"
    ls.add_snippets("markdown", M.build_snippets(path), { key = "markdown_math" })

    vim.api.nvim_create_autocmd("FileType", {
        pattern = "markdown",
        callback = function(args)
            install_buffer_keymaps(args.buf)
        end,
    })

    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == "markdown" then
            install_buffer_keymaps(buf)
        end
    end
end

return M
