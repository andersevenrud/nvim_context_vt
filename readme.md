# Nvim context vt

Shows virtual text of the current context at the end of:

- functions
- methods
- if statements
- foreach statements
- classes

## Debug

If a context expected is not shown you can try to use

`lua require 'nvim_context_vt'.showDebug()` to get current and parent node info.

## Mandatory jif

![example](https://user-images.githubusercontent.com/866743/128077347-051430c4-2c89-4161-aa48-5a5793ec8499.gif)

## How to install

Install treesitter, then use your favourite package manager.

There are no dependencies.

## Advance usage

You can use a callback to change the virtual text content.

```lua
require('nvim_context_vt').setup({
		custom_text_handler = function (node)
			return "my custom virtual text"
		end
	})
```

If you return `nil`, no virtual text will be displayed. You can use it to filter out node type which you don't to want virtual text to appear.

```lua
	require('nvim_context_vt').setup({
		custom_text_handler = function (node)
            if node:type() == 'function' then
                return nil
            end
			return ts_utils.get_node_text(node)[1]
		end
	})
```
