local parsers = require('nvim-treesitter.parsers')
local config = require('nvim_context_vt.config')
local utils = require('nvim_context_vt.utils')

local M = {}
local ns = vim.api.nvim_create_namespace('context_vt')
local opts = config.default_opts
local enabled = true

function M.setup(user_opts)
    opts = vim.tbl_extend('force', config.default_opts, user_opts or {})
end

function M.show_debug()
    local ft = parsers.get_buf_lang()
    local result = utils.find_virtual_text_nodes(function()
        return true
    end, ft, opts)

    local values = vim.tbl_values(result)
    local lines = vim.tbl_keys(result)

    for index, nodes in ipairs(values) do
        local prefix = string.rep('   ', #values - index)
        local line = lines[index]

        for _, node in ipairs(nodes) do
            print(prefix .. line .. ':' .. node:type() .. ' ' .. utils.default_parser(node, ft, opts))
        end
    end
end

function M.toggle_context()
    if enabled then
        enabled = false
        vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
    else
        enabled = true
        M.show_context()
    end
end

function M.show_context()
    local ft = parsers.get_buf_lang()
    if not enabled or vim.tbl_contains(opts.disable_ft, ft) then
        return
    end

    local validate = opts.custom_validator or utils.default_validator
    local resolve = opts.custom_resolver or utils.default_resolver
    local parse = opts.custom_parser or utils.default_parser

    vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)

    local result = utils.find_virtual_text_nodes(validate, ft, opts)
    local create_vt = utils.create_virtual_text_factory(parse, ft, opts)

    for line, nodes in pairs(result) do
        local node = resolve(nodes, ft, opts)
        local vt = create_vt(node, nodes)

        if vt then
            vim.api.nvim_buf_set_extmark(0, ns, line, 0, vt)
        end
    end
end

return M
