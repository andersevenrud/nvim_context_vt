-- This is a pretty simple function that gets the context and up the
-- tree for the current position.
local targets = {
    'function',
    'method_declaration',
    'function_declaration',

    'if_statement',
    'if_expression',

    'class_declaration',

    'while_expression',

    'for_expression',
    'foreach_statement',
}
local M = {}
function M.showContext(node)
    local ts_utils = require 'nvim-treesitter.ts_utils';

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

    if not parentNode then
        return
    end

    local type = parentNode:type()

    if vim.tbl_contains(targets, type) then
        local targetLineNumber = parentNode:end_();

        local parentNodeText = ts_utils.get_node_text(parentNode, 0);

        vim.api.nvim_buf_set_virtual_text(0, vim.g.context_vt_namespace, targetLineNumber, {{ "--> " .. parentNodeText[1], 'Comment' }}, {});
    end

    if not (type == 'program') then
        M.showContext(parentNode);
    end
end

return M
