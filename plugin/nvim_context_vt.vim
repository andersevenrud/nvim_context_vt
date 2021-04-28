let context_vt_namespace = nvim_create_namespace('context_vt')

" Todo: Cache this per line instead of recalculating every move?
autocmd CursorMoved   * lua require 'nvim_context_vt'.showContext()
autocmd CursorMovedI   * lua require 'nvim_context_vt'.showContext()
