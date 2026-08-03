-- End to end tests: given a buffer and a cursor position, what virtual text
-- does the plugin render?
--
-- Only the treesitter parsers bundled with Neovim may be used here, which is
-- why every fixture is lua, c or markdown.
local nvim_context_vt = require('nvim_context_vt')
local utils = require('nvim_context_vt.utils')
local t = require('tests.harness')

local LUA = {
    'local M = {}',
    '',
    'function M.run(items)',
    '    for _, item in ipairs(items) do',
    '        if item.done then',
    '            print(item.label)',
    '        end',
    '    end',
    'end',
    '',
    'return M',
}

-- Inside the innermost block, so every enclosing node is a candidate
local CURSOR = { 6, 12 }

local C = {
    'int main(int argc, char **argv)',
    '{',
    '    if (argc > 1) {',
    '        printf("%s", argv[1]);',
    '    }',
    '',
    '    return 0;',
    '}',
}

t.test('renders the whole enclosing context', function()
    local inline = t.context({ lines = LUA, filetype = 'lua', cursor = CURSOR })

    t.eq({
        '--> for _, item in ipairs(items) do',
        '--> function M.run(items)',
        '--> if item.done then',
    }, inline)
end)

t.test('renders one extmark per enclosing block, at the line it ends on', function()
    t.context({ lines = LUA, filetype = 'lua', cursor = CURSOR })

    local lines = {}
    for _, mark in ipairs(t.extmarks()) do
        table.insert(lines, mark.virt_text[1][1])
    end

    -- `if` ends on line 7, `for` on line 8 and the function on line 9
    t.eq({ '--> if item.done then', '--> for _, item in ipairs(items) do', '--> function M.run(items)' }, lines)
end)

t.test('is not lua specific', function()
    local inline = t.context({ lines = C, filetype = 'c', cursor = { 4, 8 } })

    t.eq({ '--> if (argc > 1) {', '--> int main(int argc, char **argv)' }, inline)
end)

t.test('uses the configured prefix', function()
    local inline = t.context({ lines = LUA, filetype = 'lua', cursor = CURSOR, opts = { prefix = '<<' } })

    t.eq('<< if item.done then', inline[3])
end)

t.test('uses the configured highlight and priority', function()
    t.context({
        lines = LUA,
        filetype = 'lua',
        cursor = CURSOR,
        opts = { highlight = 'CustomContextVt', priority = 42 },
    })

    local mark = t.extmarks()[1]
    t.eq('CustomContextVt', mark.virt_text[1][2])
    t.eq(42, mark.priority)
end)

t.test('skips blocks shorter than min_rows', function()
    local inline = t.context({ lines = LUA, filetype = 'lua', cursor = CURSOR, opts = { min_rows = 4 } })

    t.eq({ '--> function M.run(items)' }, inline)
end)

t.test('min_rows_ft overrides min_rows for one filetype', function()
    local opts = { min_rows = 1, min_rows_ft = { lua = 4 } }
    local inline = t.context({ lines = LUA, filetype = 'lua', cursor = CURSOR, opts = opts })

    t.eq({ '--> function M.run(items)' }, inline)

    local other = t.context({ lines = C, filetype = 'c', cursor = { 4, 8 }, opts = opts })

    t.eq({ '--> if (argc > 1) {', '--> int main(int argc, char **argv)' }, other)
end)

t.test('renders nothing for a disabled filetype', function()
    local lines = { '# Title', '', 'Some paragraph', 'across two lines', '' }
    local inline = t.context({ lines = lines, filetype = 'markdown', cursor = { 4, 0 } })

    t.eq({}, inline)
end)

t.test('renders nothing while disabled, and everything again after toggling', function()
    local inline = t.context({ lines = LUA, filetype = 'lua', cursor = CURSOR, opts = { enabled = false } })

    t.eq({}, inline)

    nvim_context_vt.toggle_context()

    t.eq(3, #t.rendered())
end)

t.test('custom_parser can drop a single node', function()
    local inline = t.context({
        lines = LUA,
        filetype = 'lua',
        cursor = CURSOR,
        opts = {
            custom_parser = function(node, _, opts)
                if node:type() == 'if_statement' then
                    return nil
                end
                return opts.prefix .. ' ' .. utils.get_node_text(node, 0)[1]
            end,
        },
    })

    t.eq({ '--> for _, item in ipairs(items) do', '--> function M.run(items)' }, inline)
end)

t.test('custom_validator replaces the default node matching', function()
    local inline = t.context({
        lines = LUA,
        filetype = 'lua',
        cursor = CURSOR,
        opts = {
            custom_validator = function(node)
                return node:type() == 'function_declaration'
            end,
        },
    })

    t.eq({ '--> function M.run(items)' }, inline)
end)

t.test('custom_resolver picks which node of a line wins', function()
    -- Both the function call and the expression statement around it end on the
    -- same line, so the resolver decides which one is rendered
    local lines = {
        'local ok = pcall(function()',
        '    return 1',
        'end)',
    }

    local last = t.context({ lines = lines, filetype = 'lua', cursor = { 2, 4 } })
    local first = t.context({
        lines = lines,
        filetype = 'lua',
        cursor = { 2, 4 },
        opts = {
            custom_resolver = function(nodes)
                return nodes[1]
            end,
        },
    })

    t.eq(1, #last)
    t.eq(1, #first)
    if last[1] == first[1] then
        error('expected the resolver to change which node is rendered, got ' .. last[1] .. ' for both')
    end
end)

t.test('renders nothing for a buffer without a parser', function()
    local lines = { 'plain text', 'more of it', 'and more' }
    local inline = t.context({ lines = lines, filetype = 'text', cursor = { 2, 0 } })

    t.eq({}, inline)
end)

t.test('renders virtual lines below the block for line based filetypes', function()
    -- None of the indentation based languages in `config.line_ft` have a parser
    -- bundled with Neovim, so lua stands in for one
    local as_line_ft = { line_ft = { 'lua' }, line_targets = { 'function_declaration' } }

    local inline, lines = t.context({
        lines = LUA,
        filetype = 'lua',
        cursor = CURSOR,
        config = as_line_ft,
    })

    t.eq({ '--> for _, item in ipairs(items) do', '--> if item.done then' }, inline)
    t.eq({ '--> function M.run(items)' }, lines)

    local _, disabled = t.context({
        lines = LUA,
        filetype = 'lua',
        cursor = CURSOR,
        config = as_line_ft,
        opts = { disable_virtual_lines = true },
    })

    t.eq({}, disabled)

    local _, disabled_ft = t.context({
        lines = LUA,
        filetype = 'lua',
        cursor = CURSOR,
        config = as_line_ft,
        opts = { disable_virtual_lines_ft = { 'lua' } },
    })

    t.eq({}, disabled_ft)
end)

t.test('indents virtual lines to the column the node starts on', function()
    local _, lines = t.context({
        lines = LUA,
        filetype = 'lua',
        cursor = CURSOR,
        config = { line_ft = { 'lua' }, line_targets = { 'if_statement' } },
    })

    -- `if item.done then` starts in column 8
    t.eq({ '        --> if item.done then' }, lines)
end)

t.test('registers its user commands', function()
    t.eq(2, vim.fn.exists(':NvimContextVtToggle'))
    t.eq(2, vim.fn.exists(':NvimContextVtDebug'))
end)

t.test('renders on cursor movement', function()
    nvim_context_vt.setup({})
    t.buffer(LUA, 'lua')
    vim.api.nvim_win_set_cursor(0, CURSOR)

    -- Nothing has called show_context(), so this only passes if the plugin's
    -- own autocommand is wired up
    vim.api.nvim_exec_autocmds('CursorMoved', {})

    t.eq(3, #t.rendered())
end)

t.test('clears the virtual text when toggled off', function()
    t.eq(3, #t.context({ lines = LUA, filetype = 'lua', cursor = CURSOR }))

    nvim_context_vt.toggle_context()

    t.eq(0, #t.rendered())
end)

t.test('prints the context tree for debugging', function()
    nvim_context_vt.setup({})
    t.buffer(LUA, 'lua')
    vim.api.nvim_win_set_cursor(0, CURSOR)

    local output = vim.api.nvim_exec2('NvimContextVtDebug', { output = true }).output

    -- Every node on the way up is listed, including the ones the default
    -- validator rejects
    t.eq(true, output:find('if_statement --> if item.done then', 1, true) ~= nil)
    t.eq(true, output:find('function_call --> print(item.label)', 1, true) ~= nil)
end)
