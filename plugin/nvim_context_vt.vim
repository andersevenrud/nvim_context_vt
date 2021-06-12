let context_vt_namespace = nvim_create_namespace('context_vt')

autocmd CursorMoved   * lua require 'nvim_context_vt'.onCursorMoved()
autocmd CursorMovedI  * lua require 'nvim_context_vt'.onCursorMoved()
