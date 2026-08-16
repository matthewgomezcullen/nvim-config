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

-- These are per-buffer: the guard at the top of this file means the ftplugin is
-- sourced once per Markdown buffer, so each gets its own copy of these locals.
local pdf_rendering = false
local pdf_queued = false

-- pandoc needs a LaTeX engine for PDF output; xelatex handles UTF-8 and system
-- fonts, unlike the pdflatex default.
local function md_pdf_render(opts)
    local file = vim.api.nvim_buf_get_name(0)
    if file == '' then
        vim.notify('Current buffer does not have a file path.', vim.log.levels.ERROR)
        return
    end

    if vim.fn.executable('pandoc') == 0 then
        vim.notify('pandoc is not installed (brew install pandoc).', vim.log.levels.ERROR)
        return
    end

    if vim.bo.modified then
        vim.cmd.update()
    end

    -- A save landing mid-render would race two pandoc runs writing the same PDF,
    -- so coalesce into a single re-run once the in-flight one finishes.
    if pdf_rendering then
        -- Keep the queued request's own options; the in-flight run's may differ
        -- (e.g. a quiet save landing during a noisy interactive render).
        pdf_queued = { quiet = opts.quiet }
        return
    end
    pdf_rendering = true

    local pdf = vim.fn.fnamemodify(file, ':r') .. '.pdf'
    if not opts.quiet then
        vim.notify('Rendering ' .. vim.fn.fnamemodify(pdf, ':t') .. '…')
    end

    -- Async so a slow LaTeX run doesn't block the editor; --resource-path lets
    -- relative image links resolve against the Markdown file's directory.
    vim.system({
        'pandoc', file,
        '-o', pdf,
        '--pdf-engine=xelatex',
        '--resource-path=' .. vim.fn.fnamemodify(file, ':h'),
        -- LaTeX's article defaults leave ~2in side margins, which squeezes wide
        -- tables until their cells overlap. 0.75in gives tables room to breathe.
        '-V', 'geometry:margin=0.75in',
        -- Latin Modern Mono has no box-drawing or Nerd Font glyphs, so code
        -- blocks silently drop characters. Swap for "Menlo" if this font goes.
        '-V', 'monofont:JetBrainsMono Nerd Font Mono',
    }, { text = true }, function(result)
        vim.schedule(function()
            pdf_rendering = false
            -- Failures always speak up, even in watch mode: a silent stale PDF
            -- is worse than a noisy one.
            if result.code ~= 0 then
                vim.notify('pandoc failed:\n' .. (result.stderr or ''), vim.log.levels.ERROR)
                return
            end
            if not opts.quiet then
                vim.notify('Rendered ' .. pdf)
            end
            if opts.open then
                vim.fn.jobstart({ 'open', pdf }, { detach = true })
            end
            if pdf_queued then
                local queued = pdf_queued
                pdf_queued = nil
                md_pdf_render(queued)
            end
        end)
    end)
end

vim.api.nvim_buf_create_user_command(0, 'MdPdf', function()
    md_pdf_render({ open = true })
end, {
    desc = 'Render the current Markdown file to PDF with pandoc',
})

-- Live compilation is tied to BufWritePost rather than a filesystem watcher:
-- pandoc reads the file from disk, so an unsaved buffer has nothing new to
-- render, and this reuses the existing save to debounce for free.
vim.api.nvim_buf_create_user_command(0, 'MdPdfWatch', function()
    local buf = vim.api.nvim_get_current_buf()
    local group = vim.api.nvim_create_augroup('MdPdfWatch' .. buf, { clear = true })

    if vim.b.md_pdf_watching then
        vim.b.md_pdf_watching = false
        vim.notify('Stopped watching ' .. vim.fn.expand('%:t') .. ' for PDF rendering.')
        return
    end

    vim.b.md_pdf_watching = true
    vim.api.nvim_create_autocmd('BufWritePost', {
        group = group,
        buffer = buf,
        callback = function()
            md_pdf_render({ quiet = true })
        end,
    })

    vim.notify('Watching ' .. vim.fn.expand('%:t') .. ' — rendering PDF on every save.')
    md_pdf_render({ open = true })
end, {
    desc = 'Toggle rendering the current Markdown file to PDF on every save',
})

vim.keymap.set('n', '<leader>mdr', '<cmd>MoRender<cr>', {
    buffer = 0,
    desc = 'Render the current Markdown file with mo',
})

vim.keymap.set('n', '<leader>mdp', '<cmd>MdPdf<cr>', {
    buffer = 0,
    desc = 'Render the current Markdown file to PDF with pandoc',
})

vim.keymap.set('n', '<leader>mdw', '<cmd>MdPdfWatch<cr>', {
    buffer = 0,
    desc = 'Toggle rendering the current Markdown file to PDF on every save',
})

local ok, wk = pcall(require, 'which-key')
if ok then
    wk.add({ '<leader>md', group = 'Keybinds for Markdown', buffer = 0 })
end
