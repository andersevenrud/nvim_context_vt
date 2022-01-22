highlight default link ContextVt Comment

command NvimContextVtDebug lua require'nvim_context_vt'.show_debug()

autocmd CursorMoved  * lua require 'nvim_context_vt'.show_context()
autocmd CursorMovedI * lua require 'nvim_context_vt'.show_context()
