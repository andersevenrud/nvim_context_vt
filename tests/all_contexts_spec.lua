-- Tests for the `show_all_contexts` option, which renders every context
-- visible in the window instead of only the ones around the cursor.
local nvim_context_vt = require('nvim_context_vt')
local utils = require('nvim_context_vt.utils')
local t = require('tests.harness')

local TWO_FUNCTIONS = {
    'local M = {}',
    '',
    'function M.first(items)',
    '    for _, item in ipairs(items) do',
    '        print(item)',
    '    end',
    'end',
    '',
    'function M.second(a)',
    '    if a then',
    '        return 1',
    '    end',
    'end',
}

-- Inside the first function, so the second one is only ever reached by
-- looking at the whole window
local CURSOR = { 5, 8 }

--- Repeats a block so the buffer is taller than any window used here
---@param count number
---@return string[]
local function many_functions(count)
    local lines = {}
    for index = 1, count do
        vim.list_extend(lines, {
            ('function f%d()'):format(index),
            '    if true then',
            '        return ' .. index,
            '    end',
            'end',
        })
    end
    return lines
end

--- Renders with a known window height and the given line at the top
---@param spec table `{ lines, opts, top }`
---@return string[]
local function rendered_window(spec)
    local height = vim.api.nvim_win_get_height(0)

    nvim_context_vt.setup(spec.opts)
    t.buffer(spec.lines, 'lua')
    vim.api.nvim_win_set_height(0, 10)
    vim.api.nvim_win_set_cursor(0, { spec.top, 0 })
    vim.cmd('normal! zt')
    nvim_context_vt.show_context()

    local inline = t.rendered()
    vim.api.nvim_win_set_height(0, height)

    return inline
end

t.test('show_all_contexts renders contexts the cursor is not inside', function()
    local cursor_only = t.context({ lines = TWO_FUNCTIONS, filetype = 'lua', cursor = CURSOR })

    t.eq({ '--> for _, item in ipairs(items) do', '--> function M.first(items)' }, cursor_only)

    local everything = t.context({
        lines = TWO_FUNCTIONS,
        filetype = 'lua',
        cursor = CURSOR,
        opts = { show_all_contexts = true },
    })

    t.eq({
        '--> for _, item in ipairs(items) do',
        '--> function M.first(items)',
        '--> function M.second(a)',
        '--> if a then',
    }, everything)
end)

t.test('show_all_contexts only looks at what the window shows', function()
    local lines = many_functions(12)
    local opts = { show_all_contexts = true }

    local top = rendered_window({ lines = lines, opts = opts, top = 1 })

    t.eq({ '--> function f1()', '--> function f2()', '--> if true then', '--> if true then' }, top)

    -- The same buffer scrolled further down renders a different set entirely
    local scrolled = rendered_window({ lines = lines, opts = opts, top = 41 })

    t.eq({ '--> function f10()', '--> function f9()', '--> if true then', '--> if true then' }, scrolled)
end)

t.test('show_all_contexts resolves a line the same way the cursor walk does', function()
    -- Several nodes end on the last line here, so this pins that both node
    -- searches hand the resolver the same ordering
    local lines = {
        'local ok = pcall(function()',
        '    return 1',
        'end)',
        '',
        'local other = 2',
    }

    local from_cursor = t.context({ lines = lines, filetype = 'lua', cursor = { 2, 4 } })
    local from_window = t.context({
        lines = lines,
        filetype = 'lua',
        cursor = { 5, 0 },
        opts = { show_all_contexts = true },
    })

    t.eq(1, #from_cursor)
    t.eq(from_cursor, from_window)
end)

t.test('show_all_contexts still honours the other options', function()
    local everything = t.context({
        lines = TWO_FUNCTIONS,
        filetype = 'lua',
        cursor = CURSOR,
        opts = { show_all_contexts = true, disable_targets = { 'if_statement' }, min_rows = 2 },
    })

    -- `if a then` is disabled and the `for` loop is too short for min_rows
    t.eq({ '--> function M.first(items)', '--> function M.second(a)' }, everything)
end)

t.test('show_all_contexts renders nothing for a buffer without a parser', function()
    local lines = { 'plain text', 'more of it', 'and more' }
    local inline = t.context({
        lines = lines,
        filetype = 'text',
        cursor = { 2, 0 },
        opts = { show_all_contexts = true },
    })

    t.eq({}, inline)
end)

t.test('toggle_all_contexts switches between both node searches', function()
    t.eq(2, #t.context({ lines = TWO_FUNCTIONS, filetype = 'lua', cursor = CURSOR }))

    nvim_context_vt.toggle_all_contexts()

    t.eq(4, #t.rendered())

    nvim_context_vt.toggle_all_contexts()

    t.eq(2, #t.rendered())
end)

t.test('toggle_all_contexts leaves a disabled plugin alone', function()
    t.eq(0, #t.context({ lines = TWO_FUNCTIONS, filetype = 'lua', cursor = CURSOR, opts = { enabled = false } }))

    nvim_context_vt.toggle_all_contexts()

    t.eq(0, #t.rendered())
end)

t.test('the toggle is also a user command', function()
    t.eq(2, vim.fn.exists(':NvimContextVtToggleAllContexts'))

    t.eq(2, #t.context({ lines = TWO_FUNCTIONS, filetype = 'lua', cursor = CURSOR }))

    vim.cmd('NvimContextVtToggleAllContexts')

    t.eq(4, #t.rendered())
end)

t.test('refresh_context only does something while show_all_contexts is on', function()
    nvim_context_vt.setup({})
    t.buffer(TWO_FUNCTIONS, 'lua')
    vim.api.nvim_win_set_cursor(0, CURSOR)

    nvim_context_vt.refresh_context()

    t.eq(0, #t.rendered())

    nvim_context_vt.setup({ show_all_contexts = true })
    nvim_context_vt.refresh_context()

    t.eq(4, #t.rendered())
end)

--- Counts how often the visible tree is actually walked while `fn` runs
---@param fn fun()
---@return number
local function scans_during(fn)
    local scans = 0
    local real = utils.find_all_virtual_text_nodes

    utils.find_all_virtual_text_nodes = function(...)
        scans = scans + 1
        return real(...)
    end

    local ok, err = pcall(fn)

    utils.find_all_virtual_text_nodes = real

    if not ok then
        error(err, 0)
    end

    return scans
end

t.test('moving the cursor does not walk the visible tree again', function()
    -- Walking every visible node costs orders of magnitude more than the walk
    -- up from the cursor, and CursorMoved fires on every keystroke. The visible
    -- contexts cannot change from cursor movement alone, so they must not be
    -- recomputed for it.
    nvim_context_vt.setup({ show_all_contexts = true })
    t.buffer(TWO_FUNCTIONS, 'lua')

    local scans = scans_during(function()
        for line = 3, 12 do
            vim.api.nvim_win_set_cursor(0, { line, 0 })
            vim.api.nvim_exec_autocmds('CursorMoved', {})
        end
    end)

    t.eq(1, scans)
    t.eq(4, #t.rendered())
end)

t.test('editing, scrolling and toggling do walk it again', function()
    local lines = many_functions(12)
    local height = vim.api.nvim_win_get_height(0)

    nvim_context_vt.setup({ show_all_contexts = true })
    t.buffer(lines, 'lua')
    vim.api.nvim_win_set_height(0, 10)
    vim.api.nvim_win_set_cursor(0, { 1, 0 })

    local first_render = scans_during(function()
        vim.api.nvim_exec_autocmds('CursorMoved', {})
    end)

    local after_scrolling = scans_during(function()
        vim.api.nvim_win_set_cursor(0, { 41, 0 })
        vim.cmd('normal! zt')
        vim.api.nvim_exec_autocmds('WinScrolled', {})
    end)

    local after_editing = scans_during(function()
        vim.api.nvim_buf_set_lines(0, 0, 0, false, { '-- a new line' })
        vim.api.nvim_exec_autocmds('TextChanged', {})
    end)

    -- Toggling off and on again has to render from scratch both times
    local after_toggling = scans_during(function()
        nvim_context_vt.toggle_all_contexts()
        nvim_context_vt.toggle_all_contexts()
    end)

    -- As does reconfiguring, since the options are part of the result
    local after_setup = scans_during(function()
        nvim_context_vt.setup({ show_all_contexts = true, prefix = '>>' })
        vim.api.nvim_exec_autocmds('CursorMoved', {})
    end)

    vim.api.nvim_win_set_height(0, height)

    t.eq(1, first_render)
    t.eq(1, after_scrolling)
    t.eq(1, after_editing)
    t.eq(1, after_toggling)
    t.eq(1, after_setup)
end)

t.test('scrolling and editing re-render without the cursor moving', function()
    for _, event in ipairs({ 'WinScrolled', 'BufWinEnter', 'TextChanged' }) do
        nvim_context_vt.setup({ show_all_contexts = true })
        t.buffer(TWO_FUNCTIONS, 'lua')
        vim.api.nvim_win_set_cursor(0, CURSOR)

        -- Nothing has rendered yet, so this only passes if the plugin's own
        -- autocommand for the event is wired up
        vim.api.nvim_exec_autocmds(event, {})

        t.eq(4, #t.rendered())
    end
end)
