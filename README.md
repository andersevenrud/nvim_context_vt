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
  -- Override default virtual text prefix
  -- Default: '-->'
  prefix = '',

  -- Override the internal highlight group name
  -- Default: 'ContextVt'
  highlight = 'CustomContextVt',

  -- Disable virtual text for given filetypes
  -- Default: {}
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

  -- Custom virtual text node parser callback
  -- Default: nil
  custom_parser = function(node, ft, ts_utils)
    -- If you return `nil`, no virtual text will be displayed.
    if node:type() == 'function' then
      return nil
    end

    -- This is the standard text
    return '--> ' .. ts_utils.get_node_text(node)[1]
  end,

  -- Custom node validator callback
  -- Default: nil
  custom_validator = function(node, ft)
    -- Internally a node is matched against min_rows and configured targets
    local default_validator = require('nvim_context_vt').default_validator
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
  custom_resolver = function(nodes, ft)
    -- By default the last node is used
    return nodes[#nodes]
  end,
})
```

## Debug

If you don't see the expected context vitual text, run `:NvimContextVtDebug` to print out the
context tree. Use this information to open a pull-request or an issue to add support.

## License

MIT
