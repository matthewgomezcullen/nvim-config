if vim.b.mo_render_command_created then
    return
end

vim.b.mo_render_command_created = true

-- Remove a file from mo's running session so it stops lingering in the
-- sidebar. Synchronous so it still runs reliably while nvim is exiting;
-- output (including "not in session" / "no server" errors) is ignored.
local function mo_close(file)
    if file ~= '' then
        vim.fn.system({ 'mo', '--close', file })
    end
end

-- mo is a background server with no notion of the browser being closed, so the
-- closest automatic cleanup is to drop the file when nvim quits. Register the
-- exit handler once, globally; it closes every buffer that was rendered.
if not vim.g.mo_render_autoclose_registered then
    vim.g.mo_render_autoclose_registered = true
    vim.api.nvim_create_autocmd('VimLeavePre', {
        group = vim.api.nvim_create_augroup('MoRenderAutoClose', { clear = true }),
        callback = function()
            for _, b in ipairs(vim.api.nvim_list_bufs()) do
                if vim.b[b].mo_rendered then
                    mo_close(vim.api.nvim_buf_get_name(b))
                end
            end
        end,
    })
end

vim.api.nvim_buf_create_user_command(0, 'MoRender', function()
    local buf = vim.api.nvim_get_current_buf()
    local file = vim.api.nvim_buf_get_name(buf)
    if file == '' then
        vim.notify('Current buffer does not have a file path.', vim.log.levels.ERROR)
        return
    end

    if vim.bo.modified then
        vim.cmd.update()
    end

    vim.cmd('!mo ' .. vim.fn.shellescape(file))

    -- Also close the file when this buffer is deleted (e.g. :bd), not just on
    -- quit. Registered once per buffer, on the first render.
    if not vim.b.mo_rendered then
        vim.b.mo_rendered = true
        vim.api.nvim_create_autocmd('BufDelete', {
            buffer = buf,
            callback = function()
                mo_close(vim.api.nvim_buf_get_name(buf))
            end,
        })
    end
end, {
    desc = 'Render the current Markdown file with mo',
})
