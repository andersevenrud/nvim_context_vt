-- Minimal test harness. No dependencies: everything here only uses what
-- Neovim itself ships with, so the suite runs with `nvim --clean`.
local config = require('nvim_context_vt.config')
local nvim_context_vt = require('nvim_context_vt')

local M = { total = 0, failures = 0 }

local function format(value)
    return type(value) == 'string' and value or vim.inspect(value)
end

--- Records a failure that happened outside of a test, such as a spec file that
--- could not be loaded at all
---@param name string
---@param err string
function M.fail(name, err)
    M.total = M.total + 1
    M.failures = M.failures + 1
    io.write('FAIL ' .. name .. '\n' .. err .. '\n')
end

---@param name string
---@param fn fun()
function M.test(name, fn)
    M.total = M.total + 1

    local ok, err = xpcall(fn, debug.traceback)
    if ok then
        io.write('ok   ' .. name .. '\n')
    else
        M.failures = M.failures + 1
        io.write('FAIL ' .. name .. '\n' .. err .. '\n')
    end
end

--- Fails the current test unless both values are deeply equal
---@param expected any
---@param actual any
function M.eq(expected, actual)
    if not vim.deep_equal(expected, actual) then
        error('expected ' .. format(expected) .. '\n     got ' .. format(actual), 2)
    end
end

--- Opens a parsed scratch buffer with the given contents
---@param lines string[]
---@param filetype string
---@return number
function M.buffer(lines, filetype)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(0, buf)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].filetype = filetype

    -- Nothing ever redraws while headless, so the tree has to be built by hand
    -- before the plugin can find any nodes in it
    local parser = vim.treesitter.get_parser(buf, nil, { error = false })
    if parser then
        parser:parse(true)
    end

    return buf
end

--- Temporarily replaces fields in the config module for the duration of `fn`,
--- restoring them even when it fails
---@param overrides table
---@param fn fun(): string[], string[]
---@return string[], string[]
local function with_config(overrides, fn)
    local previous = {}
    for key, value in pairs(overrides) do
        previous[key] = config[key]
        config[key] = value
    end

    local ok, inline, lines = pcall(fn)

    for key, value in pairs(previous) do
        config[key] = value
    end

    if not ok then
        error(inline, 0)
    end

    return inline, lines
end

--- Creates a buffer from the given lines and returns the virtual text the
--- plugin renders with the cursor at the given position
---@param spec table `{ lines, filetype, cursor, opts?, config? }`
---@return string[] inline, string[] virtual_lines
function M.context(spec)
    return with_config(spec.config or {}, function()
        nvim_context_vt.setup(spec.opts or {})

        M.buffer(spec.lines, spec.filetype)
        vim.api.nvim_win_set_cursor(0, spec.cursor)
        nvim_context_vt.show_context()

        return M.rendered()
    end)
end

--- Reads back the virtual text the plugin has placed in a buffer
---@param buf number? or the current buffer
---@return string[] inline, string[] virtual_lines
function M.rendered(buf)
    local inline, lines = {}, {}

    for _, mark in ipairs(M.extmarks(buf)) do
        for _, chunk in ipairs(mark.virt_text or {}) do
            table.insert(inline, chunk[1])
        end
        for _, virt_line in ipairs(mark.virt_lines or {}) do
            table.insert(lines, virt_line[1][1])
        end
    end

    table.sort(inline)
    table.sort(lines)

    return inline, lines
end

--- The details of every extmark the plugin owns in a buffer
---@param buf number? or the current buffer
---@return table[]
function M.extmarks(buf)
    local ns = vim.api.nvim_get_namespaces()['context_vt']
    local details = {}

    for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(buf or 0, ns, 0, -1, { details = true })) do
        table.insert(details, mark[4])
    end

    return details
end

--- Prints the summary and exits with a status code suitable for CI
function M.finish()
    io.write(('\n%d tests, %d failed\n'):format(M.total, M.failures))
    os.exit(M.failures == 0 and 0 or 1)
end

return M
