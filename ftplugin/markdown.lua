if vim.b.mo_render_command_created then
    return
end

vim.b.mo_render_command_created = true

vim.api.nvim_buf_create_user_command(0, 'MoRender', function()
    local file = vim.api.nvim_buf_get_name(0)
    if file == '' then
        vim.notify('Current buffer does not have a file path.', vim.log.levels.ERROR)
        return
    end

    if vim.bo.modified then
        vim.cmd.update()
    end

    vim.cmd('!mo ' .. vim.fn.shellescape(file))
end, {
    desc = 'Render the current Markdown file with mo',
})
