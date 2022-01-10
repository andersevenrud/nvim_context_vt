highlight default link ContextVt Comment

autocmd CursorMoved  * lua require 'nvim_context_vt'.showContext()
autocmd CursorMovedI * lua require 'nvim_context_vt'.showContext()
