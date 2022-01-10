highlight default link ContextVt Comment

autocmd CursorMoved  * lua require 'nvim_context_vt'.show_context()
autocmd CursorMovedI * lua require 'nvim_context_vt'.show_context()
