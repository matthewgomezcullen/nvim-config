local M = {}

local math_zone_node_types = {
    latex_block = true,
    inline_formula = true,
    displayed_equation = true,
    math_environment = true,
    pseudo_environment = true,
}

function M.in_mathzone()
    local ok, node = pcall(vim.treesitter.get_node)
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
    local s, i, t, f = ls.snippet, ls.insert_node, ls.text_node, ls.function_node

    local out = {}

    for _, entry in ipairs(parse_file(path)) do
        table.insert(out, s({
            trig = entry.trigger,
            wordTrig = true,
            snippetType = "autosnippet",
        }, body_to_nodes(entry.body), { condition = M.in_mathzone }))
    end

    -- {a}/{b} -> \frac{a}{b}
    -- Trigger fires when the user types the *opening* brace of the denominator.
    -- The autopair-inserted `}` to the right of the cursor becomes the closing
    -- brace of \frac, so we deliberately don't emit a trailing `}` here.
    table.insert(out, s({
        trig = "{([^{}]+)}/{",
        regTrig = true,
        wordTrig = false,
        snippetType = "autosnippet",
    }, {
        f(function(_, snip)
            return "\\frac{" .. snip.captures[1] .. "}{"
        end),
        i(1),
    }, { condition = M.in_mathzone }))

    table.insert(out, s({
        trig = "^",
        wordTrig = false,
        snippetType = "autosnippet",
    }, { t("^{"), i(1), t("}") }, { condition = M.in_mathzone }))

    table.insert(out, s({
        trig = "_",
        wordTrig = false,
        snippetType = "autosnippet",
    }, { t("_{"), i(1), t("}") }, { condition = M.in_mathzone }))

    return out
end

function M.setup()
    local ls = require("luasnip")
    local path = vim.fn.stdpath("config") .. "/snippets.txt"
    ls.add_snippets("markdown", M.build_snippets(path), { key = "markdown_math" })
end

return M
