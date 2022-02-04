local M = {}

M.default_opts = {
    min_rows = 1,
    custom_parser = nil,
    custom_validator = nil,
    custom_resolver = nil,
    highlight = 'ContextVt',
    disable_ft = { 'markdown' },
    disable_virtual_lines = false,
    disable_virtual_lines_ft = {},
    prefix = '-->',
}

M.targets = {
    'function',
    'method_declaration',
    'function_declaration',
    'function_definition',
    'lexical_declaration',
    'local_function',
    'arrow_function',
    'method_definition',
    'arguments',

    'try_statement',
    'catch_clause',
    'finally_clause',

    'if_statement',
    'if_expression',

    'switch_expression',

    'class_definition',
    'class_declaration',
    'struct_expression',

    'test_expression',

    'while_expression',
    'while_statement',

    'for_expression',
    'foreach_statement',
    'for_statement',
    'for_in_statement',

    'with_statement',

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
    'interface_declaration',
    'enum_declaration',
    'call_expression',
    'export_statement',
    'property_signature',

    -- lua,
    'local_variable_declaration',
    'variable_declaration',

    -- go
    'type_declaration',
    'type_spec',
    'short_var_declaration',
    'defer_statement',
    'expression_switch_statement',
    'composite_literal',
    'element',
    'func_literal',
    'go_statement',
    'select_statement',
    'communication_case',
    'default_case',

    -- cpp
    'case_statement',
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

    -- python
    'decorated_definition',

    -- yaml
    'block_mapping_pair',
}

M.line_ft = {
    'python',
    'yaml',
}

return M
