if vim.g.loaded_nvim_context_vt then
    return
end
vim.g.loaded_nvim_context_vt = true

vim.api.nvim_set_hl(0, 'ContextVt', { link = 'Comment', default = true })

vim.api.nvim_create_user_command('NvimContextVtDebug', function()
    require('nvim_context_vt').show_debug()
end, {})

vim.api.nvim_create_user_command('NvimContextVtToggle', function()
    require('nvim_context_vt').toggle_context()
end, {})

vim.api.nvim_create_user_command('NvimContextVtToggleAllContexts', function()
    require('nvim_context_vt').toggle_all_contexts()
end, {})

local group = vim.api.nvim_create_augroup('nvim_context_vt', { clear = true })

vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
    group = group,
    pattern = '*',
    callback = function()
        require('nvim_context_vt').show_context()
    end,
})

-- Only relevant when the `show_all_contexts` option is enabled, as the
-- rendered text then depends on the visible area and not the cursor
vim.api.nvim_create_autocmd({ 'BufWinEnter', 'WinScrolled', 'TextChanged' }, {
    group = group,
    pattern = '*',
    callback = function()
        require('nvim_context_vt').refresh_context()
    end,
})
