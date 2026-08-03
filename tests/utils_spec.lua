-- Unit tests for the helpers that do not need any virtual text rendered
local utils = require('nvim_context_vt.utils')
local t = require('tests.harness')

--- The first child of the parsed buffer, which is the whole statement
---@param lines string[]
---@return TSNode
local function first_node(lines)
    local buf = t.buffer(lines, 'lua')
    return vim.treesitter.get_parser(buf):parse(true)[1]:root():child(0)
end

t.test('get_node_text returns the text of a single line node', function()
    t.eq({ 'local answer = 42' }, utils.get_node_text(first_node({ 'local answer = 42' }), 0))
end)

t.test('get_node_text returns every line of a multi line node', function()
    local lines = {
        'local function add(a, b)',
        '    return a + b',
        'end',
    }

    t.eq(lines, utils.get_node_text(first_node(lines), 0))
end)

t.test('get_node_text returns an empty table without a node', function()
    t.eq({}, utils.get_node_text(nil, 0))
end)

t.test('default_resolver picks the last node', function()
    t.eq('third', utils.default_resolver({ 'first', 'second', 'third' }))
end)

t.test('get_buf_lang maps a filetype to its language', function()
    t.buffer({ '' }, 'markdown')
    t.eq('markdown', utils.get_buf_lang())

    t.eq('c', utils.ft_to_lang('c'))
    -- Dotted filetypes fall back to the part before the first dot
    t.eq('c', utils.ft_to_lang('c.doxygen'))
end)
