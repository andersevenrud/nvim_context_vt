local ts_utils = require('nvim-treesitter.ts_utils')
local parsers = require('nvim-treesitter.parsers')

local ns = vim.api.nvim_create_namespace('context_vt')

local opts = {
    min_rows = 1,
    custom_parser = nil,
    custom_validator = nil,
    custom_resolver = nil,
    highlight = 'ContextVt',
    disable_ft = {},
    prefix = '-->',
}

local targets = {
    'function',
    'method_declaration',
    'function_declaration',
    'function_definition',
    'lexical_declaration',
    'local_function',
    'arrow_function',
    'method_definition',
    'arguments',

    'try_statement',
    'catch_clause',
    'finally_clause',

    'if_statement',
    'if_expression',

    'switch_expression',

    'class_declaration',
    'struct_expression',

    'test_expression',

    'while_expression',
    'while_statement',

    'for_expression',
    'foreach_statement',
    'for_statement',
    'for_in_statement',

    -- rust
    'match_expression',
    'if_let_expression',
    'tuple_struct_pattern',
    'while_let_expression',
    'loop_expression',
    'function_item',
    'struct_item',
    'unsafe_block',

    -- ruby target
    'class',
    'module',
    'method',
    'do_block',
    'if',
    'while',
    'for',

    -- typescript
    'interface_declaration',
    'enum_declaration',

    -- lua,
    'local_variable_declaration',
    'variable_declaration',

    -- go
    'type_declaration',
    'type_spec',
    'short_var_declaration',
    'defer_statement',
    'expression_switch_statement',
    'composite_literal',
    'element',
    'func_literal',
    'go_statement',
    'select_statement',
    'communication_case',
    'default_case',

    -- cpp
    'case_statement',
    'for_range_loop',
}

local ignore_root_targets = {
    'program',
    'document',
}

local function default_parser(node)
    return opts.prefix .. ' ' .. ts_utils.get_node_text(node, 0)[1]
end

local function default_validator(node)
    if vim.tbl_contains(targets, node:type()) then
        return node:end_() > node:start() + opts.min_rows
    end
    return false
end

local function default_resolver(nodes)
    return nodes[#nodes]
end

local function find_virtual_text_nodes(validator, ft)
    local result = {}
    local node = ts_utils.get_node_at_cursor()

    while node ~= nil and not vim.tbl_contains(ignore_root_targets, node:type()) do
        if validator(node, ft, targets) then
            local target_line = node:end_()
            if not result[target_line] then
                result[target_line] = {}
            end
            table.insert(result[target_line], node)
        end

        node = node:parent()
    end

    return result
end

local M = {}

function M.setup(user_opts)
    opts = vim.tbl_extend('force', opts, user_opts or {})
end

function M.show_debug()
    local ft = parsers.get_buf_lang()
    local result = find_virtual_text_nodes(function()
        return true
    end, ft)

    local values = vim.tbl_values(result)
    local lines = vim.tbl_keys(result)

    for index, nodes in ipairs(values) do
        local prefix = string.rep('   ', #values - index)
        local line = lines[index]

        for _, node in ipairs(nodes) do
            print(prefix .. line .. ':' .. node:type() .. ' ' .. default_parser(node))
        end
    end
end

function M.show_context()
    local ft = parsers.get_buf_lang()
    if vim.tbl_contains(opts.disable_ft, ft) then
        return
    end

    vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)

    local validate = opts.custom_validator or default_validator
    local resolve = opts.custom_resolver or default_resolver
    local parse = opts.custom_parser or default_parser
    local result = find_virtual_text_nodes(validate, ft)

    for line, nodes in pairs(result) do
        local node = resolve(nodes, ft)
        local vt = parse(node, ft, ts_utils)

        if vt then
            vim.api.nvim_buf_set_extmark(0, ns, line, 0, {
                virt_text = { { vt, opts.highlight } },
            })
        end
    end
end

return M
