local ts_utils = require('nvim-treesitter.ts_utils')
local parsers = require('nvim-treesitter.parsers')

local ns = vim.api.nvim_create_namespace('context_vt')

local opts = {
    min_rows = 1,
    custom_text_handler = nil,
    highlight = 'ContextVt',
    disable_ft = {},
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

local function set_virtual_text(node, used_line_numbers)
    if vim.tbl_contains(targets, node:type()) then
        local target_line_number = node:end_()

        if target_line_number < node:start() + opts.min_rows then
            return
        end

        if used_line_numbers[target_line_number] == nil then
            used_line_numbers[target_line_number] = true
        else
            return
        end

        local virtual_text

        if type(opts.custom_text_handler) == 'function' then
            virtual_text = opts.custom_text_handler(node, ts_utils)
        else
            virtual_text = '--> ' .. ts_utils.get_node_text(node, 0)[1]
        end

        if virtual_text then
            vim.api.nvim_buf_set_extmark(0, ns, target_line_number, 0, {
                virt_text = { { virtual_text, opts.highlight } },
            })
        end
    end
end

local M = {}

function M.setup(user_opts)
    opts = vim.tbl_extend('force', opts, user_opts or {})
end

function M.show_debug()
    local node = ts_utils.get_node_at_cursor()
    print(vim.inspect({
        current = node:type(),
        parent = node:parent():type(),
    }))
end

function M.show_context(node, last_used_line_numbers)
    local used_line_numbers = last_used_line_numbers or {}

    if not node then
        local parser_lang = parsers.get_buf_lang()
        if vim.tbl_contains(opts.disable_ft, parser_lang) then
            return
        end

        vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
        node = ts_utils.get_node_at_cursor()
    end

    if node then
        set_virtual_text(node, used_line_numbers)

        local parent_node = node:parent()
        if parent_node and parent_node:type() ~= 'program' then
            M.show_context(parent_node, used_line_numbers)
        end
    end
end

return M
