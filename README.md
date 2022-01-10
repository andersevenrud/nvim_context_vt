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
  -- Override the internal highlight group name
  -- Default is 'ContextVt'
  highlight = 'CustomContextVt',

  -- Disable virtual text for given filetypes
  -- Default is an empty table
  disable_ft = { 'typescript' },

  -- How many lines required after starting position to show virtual text
  -- Default is 1 (equals two lines total)
  min_rows = 1,

  -- Callback to override the generated virtual text.
  -- You can also use this to filter out node types.
  custom_text_handler = function(node, ts_utils)
    -- If you return `nil`, no virtual text will be displayed.
    if node:type() == 'function' then
      return nil
    end

    -- This is the standard text
    return '--> ' .. ts_utils.get_node_text(node)[1]
  end,
})
```

## Debug

If a context expected is not shown you can try to use `:lua require 'nvim_context_vt'.showDebug()`
to get current and parent node info.

## License

MIT
