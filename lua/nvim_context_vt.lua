local ts_utils = require('nvim-treesitter.ts_utils')
local parsers = require('nvim-treesitter.parsers')

local opts = {
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
    'for_expression',
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

        -- default min_rows == 1, meaning needs at least one other line
        -- (total 2 lines) to trigger context show.
        local min_rows = opts.min_rows or 1
        if targetLineNumber < node:start() + min_rows then
            return
        end

        if usedLineNumbers[targetLineNumber] == nil then
            usedLineNumbers[targetLineNumber] = true
        else
            return
        end

        local virtualText

        if opts.custom_text_handler then
            virtualText = opts.custom_text_handler(node, ts_utils)
        else
            virtualText = '--> ' .. ts_utils.get_node_text(node, 0)[1]
        end

        -- Add a guard here to allow users to filter which node to show virtual text
        if not virtualText then
            return
        end

        vim.api.nvim_buf_set_extmark(0, vim.g.context_vt_namespace, targetLineNumber, 0, {
            virt_text = { { virtualText, opts.highlight or 'ContextVt' } },
        })
    end
end

function M.showDebug()
    local node = ts_utils.get_node_at_cursor()
    print('current type')
    print(node:type())
    print('parent type')
    print(node:parent():type())
end

-- This is a pretty simple function that gets the context and up the
-- tree for the current position.
function M.showContext(node, lastUsedLineNumbers)
    local parser_lang = parsers.get_buf_lang()
    if vim.tbl_contains(opts.disable_ft, parser_lang) then
        return
    end

    local usedLineNumbers = lastUsedLineNumbers or {}

    if node == nil then
        vim.api.nvim_buf_clear_namespace(0, vim.g.context_vt_namespace, 0, -1)
        node = ts_utils.get_node_at_cursor()
    end

    if not node then
        return
    end

    local parentNode = node:parent()

    setVirtualText(node, usedLineNumbers)
    if not parentNode then
        return
    end
    setVirtualText(parentNode, usedLineNumbers)

    if parentNode and not (parentNode:type() == 'program') then
        M.showContext(parentNode, usedLineNumbers)
    end
end

return M
