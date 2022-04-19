local ts_query = require('nvim-treesitter.query')
local config = require('nvim_context_vt.config')
local M = {}

M.default_parser = function(node, _, opts)
    return opts.prefix .. ' ' .. ts_query.get_node_text(node, 0)[1]
end

M.default_validator = function(node, ft, opts)
    local min_rows = opts.min_rows_ft[ft] or opts.min_rows
    if vim.tbl_contains(config.targets, node:type()) then
        return node:end_() > node:start() + min_rows
    end
    return false
end

M.default_resolver = function(nodes)
    return nodes[#nodes]
end

M.find_virtual_text_nodes = function(validator, ft, opts)
    local result = {}
    local node = ts_query.get_node_at_cursor()

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

M.create_virtual_text_factory = function(parser, ft, opts)
    local is_line_ft = vim.tbl_contains(config.line_ft, ft)
    local skip_line_ft = opts.disable_virtual_lines or vim.tbl_contains(opts.disable_virtual_lines_ft, ft)

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

    local function text_from_node(node)
        local vt = parser(node, ft, opts)
        if vt then
            return { virt_text = { { vt, opts.highlight } } }
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
                return { virt_lines = lines }
            end
        end

        return text_from_node(node)
    end
end

return M
