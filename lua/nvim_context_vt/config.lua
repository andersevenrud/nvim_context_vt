local M = {}

M.default_opts = {
    enabled = true,
    min_rows = 1,
    min_rows_ft = {},
    custom_parser = nil,
    custom_validator = nil,
    custom_resolver = nil,
    highlight = 'ContextVt',
    disable_ft = { 'markdown' },
    disable_virtual_lines = false,
    disable_virtual_lines_ft = {},
    prefix = '-->',
    priority = 1000,
}

M.targets = {
    'function',
    'arguments',
    'case',

    'local_function',
    'arrow_function',

    'class_definition',
    'method_definition',
    'function_definition',

    'method_declaration',
    'function_declaration',
    'lexical_declaration',
    'class_declaration',
    'interface_declaration',
    'enum_declaration',
    'type_declaration',
    'field_declaration',

    'catch_clause',
    'finally_clause',

    'if_expression',
    'switch_expression',
    'call_expression',
    'struct_expression',
    'test_expression',
    'while_expression',
    'for_expression',

    'try_statement',
    'if_statement',
    'while_statement',
    'foreach_statement',
    'for_statement',
    'for_in_statement',
    'with_statement',
    'case_statement',
    'switch_statement',

    -- rust
    'match_expression',
    'if_let_expression',
    'tuple_struct_pattern',
    'while_let_expression',
    'loop_expression',
    'function_item',
    'struct_item',
    'unsafe_block',

    -- ruby
    'class',
    'module',
    'method',
    'call',
    'if',
    'while',
    'for',

    -- typescript/javascript
    'export_statement',
    'property_signature',
    'switch_case',

    -- lua,
    'local_variable_declaration',
    'variable_declaration',
    'assignment_statement',
    'function_call',
    'expression_list',
    'field',

    -- go
    'type_spec',
    'short_var_declaration',
    'defer_statement',
    'expression_switch_statement',
    'composite_literal',
    'func_literal',
    'go_statement',
    'select_statement',
    'communication_case',
    'default_case',
    'struct_type',

    -- cpp
    'for_range_loop',

    -- python
    'list',
    'pair',
    'assignment',
    'decorated_definition',

    -- yaml
    'block_mapping_pair',

    -- css / sass
    'rule_set',
    'mixin_statement',

    -- vala
    'class_constructor_definition',
    'class_destructor',

    -- bash
    'case_item',
    'elif_clause',

    -- html / vue / jsx
    'element',
    'template_element',
    'style_element',
    'script_element',
    'jsx_element',
    'jsx_expression',
    'jsx_fragment',

    -- commonlisp
    'list_lit',
    'defun',

    -- elixir
    'anonymous_function',
    'do_block',
    'tuple',
    'map',
}

M.ignore_root_targets = {
    'program',
    'document',
}

M.line_targets = {
    'function_definition',
    'class_definition',
    'if_statement',
    'try_statement',
    'with_statement',
    'for_statement',

    -- haskell
    'function',

    -- python
    'decorated_definition',

    -- yaml
    'block_mapping_pair',
}

M.line_ft = {
    'haskell',
    'python',
    'yaml',
}

return M
