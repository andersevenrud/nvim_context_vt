# nvim_context_vt

Shows virtual text of the current context after functions, methods, statements, etc.

![nvim_context_vt](https://user-images.githubusercontent.com/866743/128077347-051430c4-2c89-4161-aa48-5a5793ec8499.gif)

## How to install

Use your favourite package manager and install [treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
alongside this plugin. No configuration is required out of the box.

## Advanced usage

To customize the behavior use the setup function:

```lua
require('nvim_context_vt').setup({
  -- Enable by default. You can disable and use :NvimContextVtToggle to maually enable.
  -- Default: true
  enabled = true,

  -- Override default virtual text prefix
  -- Default: '-->'
  prefix = '',

  -- Override default virtual text priority
  -- Default: 1000
  priority = 1000,

  -- Override the internal highlight group name
  -- Default: 'ContextVt'
  highlight = 'CustomContextVt',

  -- Disable virtual text for given filetypes
  -- Default: { 'markdown' }
  disable_ft = { 'markdown' },

  -- Disable display of virtual text below blocks for indentation based languages like Python
  -- Default: false
  disable_virtual_lines = false,

  -- Same as above but only for spesific filetypes
  -- Default: {}
  disable_virtual_lines_ft = { 'yaml' },

  -- How many lines required after starting position to show virtual text
  -- Default: 1 (equals two lines total)
  min_rows = 1,

  -- Same as above but only for spesific filetypes
  -- Default: {}
  min_rows_ft = {},

  -- Custom virtual text node parser callback
  -- Default: nil
  custom_parser = function(node, ft, opts)
    local utils = require('nvim_context_vt.utils')

    -- If you return `nil`, no virtual text will be displayed.
    if node:type() == 'function' then
      return nil
    end

    -- This is the standard text
    return opts.prefix .. ' ' .. utils.get_node_text(node)[1]
  end,

  -- Custom node validator callback
  -- Default: nil
  custom_validator = function(node, ft, opts)
    -- Internally a node is matched against min_rows and configured targets
    local default_validator = require('nvim_context_vt.utils').default_validator
    if default_validator(node, ft) then
      -- Custom behaviour after using the internal validator
      if node:type() == 'function' then
        return false
      end
    end

    return true
  end,

  -- Custom node virtual text resolver callback
  -- Default: nil
  custom_resolver = function(nodes, ft, opts)
    -- By default the last node is used
    return nodes[#nodes]
  end,
})
```

## Commands

* `:NvimContextVtToggle` - Enable/disable context virtual text

## Debug

If you don't see the expected context vitual text, run `:NvimContextVtDebug` to print out the
context tree. Use this information to open a pull-request or an issue to add support.

## License

MIT
