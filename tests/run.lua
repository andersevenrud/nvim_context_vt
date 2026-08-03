-- Test suite entry point:
--
--     nvim --clean --headless -l tests/run.lua
--
-- Only the treesitter parsers bundled with Neovim are used, so this needs no
-- plugin manager, no parser installation and no third party libraries.
local root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h')

vim.opt.runtimepath:prepend(root)

-- Load the commands, autocommands and default highlight the same way Neovim
-- would for an installed plugin
vim.cmd.runtime('plugin/nvim_context_vt.lua')

-- The runtimepath only makes `lua/` requirable and the tests deliberately live
-- outside of it, so the harness is registered by hand for the spec files
local harness = dofile(root .. '/tests/harness.lua')
package.loaded['tests.harness'] = harness

for _, file in ipairs(vim.fn.glob(root .. '/tests/*_spec.lua', false, true)) do
    local ok, err = xpcall(dofile, debug.traceback, file)
    if not ok then
        harness.fail(vim.fs.basename(file) .. ' (could not be loaded)', err)
    end
end

harness.finish()
