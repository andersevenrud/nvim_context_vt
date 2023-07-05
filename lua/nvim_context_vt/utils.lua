local config = require('nvim_context_vt.config')
local M = {}

-- This is from nvim-treesitter
function M.get_node_text(node, bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    if not node then
        return {}
    end

    local start_row, start_col, end_row, end_col = vim.treesitter.get_node_range(node)
    if start_row ~= end_row then
        local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)
        lines[1] = string.sub(lines[1], start_col + 1)
        if #lines == end_row - start_row + 1 then
            lines[#lines] = string.sub(lines[#lines], 1, end_col)
        end
        return lines
    else
        local line = vim.api.nvim_buf_get_lines(bufnr, start_row, start_row + 1, false)[1]
        return line and { string.sub(line, start_col + 1, end_col) } or {}
    end
end

M.default_parser = function(node, _, opts)
    return opts.prefix .. ' ' .. M.get_node_text(node, 0)[1]
end

---@param node TSNode
---@param ft string
---@param opts table
---@return boolean
M.default_validator = function(node, ft, opts)
    ---@type integer
    local min_rows = opts.min_rows_ft[ft] or opts.min_rows
    if vim.tbl_contains(config.targets, node:type()) then
        return node:end_() > node:start() + min_rows
    end
    return false
end

---@param nodes TSNode[]
---@return TSNode
M.default_resolver = function(nodes)
    return nodes[#nodes]
end

---@param validator fun(node: TSNode, ft: string, opts: table): boolean
---@param ft string
---@param opts table
---@return table<number, table<number, TSNode>>
M.find_virtual_text_nodes = function(validator, ft, opts)
    local result = {} ---@type table<number, table<number, TSNode>>
    local node = vim.treesitter.get_node()

    while node ~= nil and not vim.tbl_contains(config.ignore_root_targets, node:type()) do
        if validator(node, ft, opts) then
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

---@param parser fun(node: TSNode, ft: string, opts: table): string
---@param ft string
---@param opts table
---@return fun(node: TSNode, nodes: TSNode[]): table?
M.create_virtual_text_factory = function(parser, ft, opts)
    local is_line_ft = vim.tbl_contains(config.line_ft, ft)
    local skip_line_ft = opts.disable_virtual_lines or vim.tbl_contains(opts.disable_virtual_lines_ft, ft)

    ---@param nodes TSNode[]
    ---@return table
    local function lines_from_nodes(nodes)
        local lines = {}
        for _, n in ipairs(nodes) do
            local vt = parser(n, ft, opts)
            if vt then
                local _, col = n:start()
                local prefix = string.rep(' ', col)
                table.insert(lines, { { prefix .. vt, opts.highlight } })
            end
        end
        return lines
    end

    ---@param node TSNode
    ---@return table?
    local function text_from_node(node)
        local vt = parser(node, ft, opts)
        if vt then
            return { virt_text = { { vt, opts.highlight } }, hl_mode = 'combine' }
        end
        return nil
    end

    return function(node, nodes)
        if is_line_ft and vim.tbl_contains(config.line_targets, node:type()) then
            if skip_line_ft then
                return nil
            end

            local lines = lines_from_nodes(nodes)
            if #lines > 0 then
                return { virt_lines = lines, hl_mode = 'combine' }
            end
        end

        return text_from_node(node)
    end
end

return M
