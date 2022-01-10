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

local M = {}

function M.setup(user_opts)
    opts = vim.tbl_extend('force', opts, user_opts or {})
end

local function setVirtualText(node, usedLineNumbers)
    if vim.tbl_contains(targets, node:type()) then
        local targetLineNumber = node:end_()

        if targetLineNumber < node:start() + opts.min_rows then
            return
        end

        if usedLineNumbers[targetLineNumber] == nil then
            usedLineNumbers[targetLineNumber] = true
        else
            return
        end

        local virtualText

        if type(opts.custom_text_handler) == 'function' then
            virtualText = opts.custom_text_handler(node, ts_utils)
        else
            virtualText = '--> ' .. ts_utils.get_node_text(node, 0)[1]
        end

        if virtualText then
            vim.api.nvim_buf_set_extmark(0, ns, targetLineNumber, 0, {
                virt_text = { { virtualText, opts.highlight } },
            })
        end
    end
end

function M.showDebug()
    local node = ts_utils.get_node_at_cursor()
    print(vim.inspect({ current = node:type(), parent = node:parent():type() }))
end

-- This is a pretty simple function that gets the context and up the
-- tree for the current position.
function M.showContext(node, lastUsedLineNumbers)
    local usedLineNumbers = lastUsedLineNumbers or {}

    if not node then
        local parser_lang = parsers.get_buf_lang()
        if vim.tbl_contains(opts.disable_ft, parser_lang) then
            return
        end

        vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
        node = ts_utils.get_node_at_cursor()
    end

    if not node then
        return
    end

    setVirtualText(node, usedLineNumbers)

    local parentNode = node:parent()
    if parentNode and parentNode:type() ~= 'program' then
        M.showContext(parentNode, usedLineNumbers)
    end
end

return M
