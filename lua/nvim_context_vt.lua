-- This is a pretty simple function that gets the context and up the
-- tree for the current position.

local ts_utils = require 'nvim-treesitter.ts_utils';

local targets = {
    'function',
    'method_declaration',
    'function_declaration',
    'function_defintion',
    'local_function',

    'if_statement',
    'if_expression',

    'class_declaration',

    'while_expression',

    'for_expression',
    'foreach_statement',

    -- ruby target
    'class',
    'module',
    'method',
    'do_block',
    'if',
    'while',
    'for'
}
local M = {}

local function setVirtualText(node)
    if vim.tbl_contains(targets, node:type()) then
        local targetLineNumber = node:end_();

        local nodeText = ts_utils.get_node_text(node, 0);

        vim.api.nvim_buf_set_virtual_text(0, vim.g.context_vt_namespace, targetLineNumber, {{ "--> " .. nodeText[1], 'Comment' }}, {});
    end

end
function M.showContext(node)
    if node == nil then
        -- Clear the existing.
        vim.api.nvim_buf_clear_namespace(0, vim.g.context_vt_namespace, 0, -1);
        -- Get the node at the current position.
        node = ts_utils.get_node_at_cursor();
    end

    if  not node then
        return
    end

    local parentNode = node:parent();

    setVirtualText(node)
    if not parentNode then
        return
    end
    setVirtualText(parentNode)

    if parentNode and not (parentNode:type() == 'program') then
        M.showContext(parentNode);
    end
end

return M
