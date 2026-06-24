-- Standalone test runner. Plenary's PlenaryBustedFile spawns a child nvim with
-- --noplugin, so our init never runs there. Instead, run via:
--
--   nvim --headless -u test/init.lua -c "luafile test/markdown_math_spec.lua"

local mm = require("snippets.markdown_math")

local pass, fail = 0, 0

local function feed(keys)
    vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes(keys, true, false, true),
        "tx",
        false
    )
end

local function line(n)
    return vim.api.nvim_buf_get_lines(0, n - 1, n, false)[1] or ""
end

local function cursor()
    return vim.api.nvim_win_get_cursor(0)
end

local function setup(lines, row, col)
    vim.cmd("enew!")
    vim.bo.filetype = "markdown"
    if lines then
        vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    end
    if row and col then
        vim.api.nvim_win_set_cursor(0, { row, col })
    end
end

local function test(name, fn)
    local ok, err = pcall(fn)
    if ok then
        pass = pass + 1
        print(string.format("  PASS  %s", name))
    else
        fail = fail + 1
        print(string.format("  FAIL  %s", name))
        print(string.format("        %s", tostring(err)))
    end
end

local function eq(actual, expected)
    if actual ~= expected then
        error(
            string.format("expected %s, got %s", vim.inspect(expected), vim.inspect(actual)),
            2
        )
    end
end

local function same(actual, expected)
    if not vim.deep_equal(actual, expected) then
        error(
            string.format("expected %s, got %s", vim.inspect(expected), vim.inspect(actual)),
            2
        )
    end
end

print("\n-- in_mathzone --")

test("returns false in prose", function()
    setup({ "plain text" }, 1, 5)
    assert(not mm.in_mathzone(), "expected false")
end)

test("returns true inside $...$", function()
    setup({ "$x+1$" }, 1, 2)
    assert(mm.in_mathzone(), "expected true")
end)

test("returns true inside $$...$$", function()
    setup({ "$$x+1$$" }, 1, 3)
    assert(mm.in_mathzone(), "expected true")
end)

print("\n-- $ autopair --")

-- Cursor assertions skipped: `nvim_feedkeys("tx")` auto-exits insert mode at
-- the end, which shifts the reported cursor by 1 from the in-handler value.
-- The "next typed char" tests below verify cursor position behaviourally.

test("pairs a single $", function()
    setup({ "" }, 1, 0)
    feed("i$")
    eq(line(1), "$$")
end)

test("extends $|$ to $$|$$ on second $", function()
    setup({ "" }, 1, 0)
    feed("i$$")
    eq(line(1), "$$$$")
end)

test("jumps over an existing close $", function()
    setup({ "$x$" }, 1, 2)
    feed("i$X")  -- After $, cursor should land *past* the close; X goes after it.
    eq(line(1), "$x$X")
end)

print("\n-- math autopair ^/_ --")

test("expands ^ to ^{} inside math, cursor between braces", function()
    setup({ "$x$" }, 1, 1)
    feed("a^Y")  -- Y lands between { and } if cursor was placed correctly.
    eq(line(1), "$x^{Y}$")
end)

test("expands _ to _{} inside math, cursor between braces", function()
    setup({ "$x$" }, 1, 1)
    feed("a_Y")
    eq(line(1), "$x_{Y}$")
end)

test("leaves ^ literal outside math", function()
    setup({ "x" }, 1, 0)
    feed("a^")
    eq(line(1), "x^")
end)

print("\n-- space-triggered snippet expansion --")

test("expands 'al' to \\alpha inside math", function()
    setup({ "$al$" }, 1, 2)
    feed("a ")
    eq(line(1), "$\\alpha$")
end)

test("leaves 'al' alone outside math", function()
    setup({ "al" }, 1, 1)
    feed("a ")
    eq(line(1), "al ")
end)

test("expands {3}/{4} to \\frac{3}{4} inside math", function()
    setup({ "${3}/{4}$" }, 1, 7)
    feed("a ")
    eq(line(1), "$\\frac{3}{4}$")
end)

print("\n-- math zone exit --")

-- exit_math_node leaves the cursor past the closing delimiter. We can only
-- observe that position while in insert mode (normal-mode `virtualedit=""`
-- clamps cursor to last char), so trigger the call via a buffer-local <F12>
-- keymap that fires mid-feedkeys.
local function with_exit_keymap()
    vim.keymap.set("i", "<F12>", function()
        assert(mm.exit_math_node(), "expected exit_math_node = true")
    end, { buffer = 0 })
end

test("exit_math_node moves cursor past $...$ (typing 'X' lands after $)", function()
    setup({ "$x+1$" }, 1, 2)
    with_exit_keymap()
    feed("i<F12>X")
    eq(line(1), "$x+1$X")
end)

test("exit_math_node moves cursor past $$...$$ (typing 'X' lands after $$)", function()
    setup({ "$$x+1$$" }, 1, 3)
    with_exit_keymap()
    feed("i<F12>X")
    eq(line(1), "$$x+1$$X")
end)

test("$ at $$|$$ exits past closing $$", function()
    setup({ "$$$$" }, 1, 1)
    feed("a$X")
    eq(line(1), "$$$$X")
end)

print(string.format("\n%d passed, %d failed", pass, fail))
if fail > 0 then
    vim.cmd("cquit! 1")
else
    vim.cmd("qa!")
end
