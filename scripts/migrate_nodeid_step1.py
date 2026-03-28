#!/usr/bin/env python3
"""Step 1: Define NodeId in Ast.w and change AstPool API signatures.

This changes:
- add_node() returns NodeId instead of i32
- Functions that take a node index (kind, get_data*, get_start, etc.) take NodeId
- get_decl() returns NodeId
- add_decl() takes NodeId
- poisoned_expr() in Parser.w returns NodeId
- Meta functions that take node params take NodeId

get_data0/d1/d2 still return i32 (data is overloaded — sometimes nodes,
sometimes symbols, sometimes counts).
"""
import re

def patch_ast():
    with open('src/Ast.w', 'r') as f:
        content = f.read()

    # 1. Add NodeId definition after the NodeKind enum (before first fn)
    content = content.replace(
        'enum NodeKind: i32:',
        'type NodeId = distinct i32\n\nenum NodeKind: i32:',
        1
    )

    # 2. add_node returns NodeId
    content = content.replace(
        'fn AstPool.add_node(self: &mut AstPool, kind: i32, start: i32, end: i32, d0: i32, d1: i32, d2: i32) -> i32:',
        'fn AstPool.add_node(self: &mut AstPool, kind: i32, start: i32, end: i32, d0: i32, d1: i32, d2: i32) -> NodeId:'
    )
    # Change the return: idx -> NodeId(idx)
    content = content.replace(
        '    self.literal_suffixes.push(LiteralSuffix.None)\n    idx',
        '    self.literal_suffixes.push(LiteralSuffix.None)\n    NodeId(idx)',
        1
    )

    # 3. Functions that take node index: change idx: i32 to idx: NodeId
    # These all use idx internally as an array index, so need idx as i32
    node_param_fns = [
        ('fn AstPool.kind(self: &AstPool, idx: i32) -> i32:',
         'fn AstPool.kind(self: &AstPool, idx: NodeId) -> i32:'),
        ('fn AstPool.get_data0(self: &AstPool, idx: i32) -> i32:',
         'fn AstPool.get_data0(self: &AstPool, idx: NodeId) -> i32:'),
        ('fn AstPool.get_data1(self: &AstPool, idx: i32) -> i32:',
         'fn AstPool.get_data1(self: &AstPool, idx: NodeId) -> i32:'),
        ('fn AstPool.get_data2(self: &AstPool, idx: i32) -> i32:',
         'fn AstPool.get_data2(self: &AstPool, idx: NodeId) -> i32:'),
        ('fn AstPool.literal_suffix(self: &AstPool, idx: i32) -> i32:',
         'fn AstPool.literal_suffix(self: &AstPool, idx: NodeId) -> i32:'),
        ('fn AstPool.set_literal_suffix(self: &mut AstPool, idx: i32, suffix: i32):',
         'fn AstPool.set_literal_suffix(self: &mut AstPool, idx: NodeId, suffix: i32):'),
        ('fn AstPool.int_lit_value(self: &AstPool, idx: i32) -> i64:',
         'fn AstPool.int_lit_value(self: &AstPool, idx: NodeId) -> i64:'),
        ('fn AstPool.get_start(self: &AstPool, idx: i32) -> i32:',
         'fn AstPool.get_start(self: &AstPool, idx: NodeId) -> i32:'),
        ('fn AstPool.get_end(self: &AstPool, idx: i32) -> i32:',
         'fn AstPool.get_end(self: &AstPool, idx: NodeId) -> i32:'),
        ('fn AstPool.set_data0(self: &mut AstPool, idx: i32, val: i32):',
         'fn AstPool.set_data0(self: &mut AstPool, idx: NodeId, val: i32):'),
        ('fn AstPool.set_data1(self: &mut AstPool, idx: i32, val: i32):',
         'fn AstPool.set_data1(self: &mut AstPool, idx: NodeId, val: i32):'),
        ('fn AstPool.set_data2(self: &mut AstPool, idx: i32, val: i32):',
         'fn AstPool.set_data2(self: &mut AstPool, idx: NodeId, val: i32):'),
        ('fn AstPool.set_start(self: &mut AstPool, idx: i32, val: i32):',
         'fn AstPool.set_start(self: &mut AstPool, idx: NodeId, val: i32):'),
        ('fn AstPool.set_end(self: &mut AstPool, idx: i32, val: i32):',
         'fn AstPool.set_end(self: &mut AstPool, idx: NodeId, val: i32):'),
    ]
    for old, new in node_param_fns:
        content = content.replace(old, new)

    # 4. Inside these functions, convert NodeId to i32 for array access
    # Replace "idx as i64" with "(idx as i32) as i64" in the body
    # Actually, since distinct is transparent at LLVM level, the array
    # access works with NodeId directly. But sema will reject it.
    # We need to add "let i = idx as i32" at the top of each function body.
    # Actually, let's just change the internal access pattern.
    # The bodies use: self.kinds.get(idx as i64)
    # Change to: self.kinds.get((idx as i32) as i64)
    content = content.replace('self.kinds.get(idx as i64)', 'self.kinds.get((idx as i32) as i64)')
    content = content.replace('self.starts.get(idx as i64)', 'self.starts.get((idx as i32) as i64)')
    content = content.replace('self.ends.get(idx as i64)', 'self.ends.get((idx as i32) as i64)')
    content = content.replace('self.data0.get(idx as i64)', 'self.data0.get((idx as i32) as i64)')
    content = content.replace('self.data1.get(idx as i64)', 'self.data1.get((idx as i32) as i64)')
    content = content.replace('self.data2.get(idx as i64)', 'self.data2.get((idx as i32) as i64)')
    content = content.replace('self.literal_suffixes.get(idx as i64)', 'self.literal_suffixes.get((idx as i32) as i64)')
    content = content.replace('self.literal_suffixes.set_i32(idx as i64', 'self.literal_suffixes.set_i32((idx as i32) as i64')
    content = content.replace('self.starts.set_i32(idx as i64', 'self.starts.set_i32((idx as i32) as i64')
    content = content.replace('self.ends.set_i32(idx as i64', 'self.ends.set_i32((idx as i32) as i64')
    content = content.replace('self.data0.set_i32(idx as i64', 'self.data0.set_i32((idx as i32) as i64')
    content = content.replace('self.data1.set_i32(idx as i64', 'self.data1.set_i32((idx as i32) as i64')
    content = content.replace('self.data2.set_i32(idx as i64', 'self.data2.set_i32((idx as i32) as i64')

    # 5. get_decl returns NodeId, add_decl takes NodeId
    content = content.replace(
        'fn AstPool.add_decl(self: &mut AstPool, node_idx: i32):',
        'fn AstPool.add_decl(self: &mut AstPool, node_idx: NodeId):'
    )
    content = content.replace(
        'fn AstPool.get_decl(self: &AstPool, idx: i32) -> i32:',
        'fn AstPool.get_decl(self: &AstPool, idx: i32) -> NodeId:'
    )
    # Fix get_decl body: return NodeId(...)
    content = content.replace(
        '    self.decls.get(idx as i64)',
        '    NodeId(self.decls.get(idx as i64))',
        1
    )
    # Fix add_decl body: convert NodeId to i32 for push
    content = content.replace(
        '    self.decls.push(node_idx)',
        '    self.decls.push(node_idx as i32)',
        1
    )

    # 6. Meta functions that take node: i32 -> node: NodeId
    meta_fns = [
        ('fn AstPool.add_fn_meta(self: &mut AstPool, node: i32,',
         'fn AstPool.add_fn_meta(self: &mut AstPool, node: NodeId,'),
        ('fn AstPool.find_fn_meta(self: &AstPool, node: i32)',
         'fn AstPool.find_fn_meta(self: &AstPool, node: NodeId)'),
        ('fn AstPool.add_type_meta(self: &mut AstPool, node: i32,',
         'fn AstPool.add_type_meta(self: &mut AstPool, node: NodeId,'),
        ('fn AstPool.find_type_meta(self: &AstPool, node: i32)',
         'fn AstPool.find_type_meta(self: &AstPool, node: NodeId)'),
        ('fn AstPool.add_pattern_qualifier(self: &mut AstPool, node: i32,',
         'fn AstPool.add_pattern_qualifier(self: &mut AstPool, node: NodeId,'),
        ('fn AstPool.pattern_qualifier(self: &AstPool, node: i32)',
         'fn AstPool.pattern_qualifier(self: &AstPool, node: NodeId)'),
        ('fn AstPool.mark_must_use_type(self: &mut AstPool, node: i32)',
         'fn AstPool.mark_must_use_type(self: &mut AstPool, node: NodeId)'),
        ('fn AstPool.is_must_use_type_node(self: &AstPool, node: i32)',
         'fn AstPool.is_must_use_type_node(self: &AstPool, node: NodeId)'),
        ('fn AstPool.mark_sealed_trait(self: &mut AstPool, node: i32)',
         'fn AstPool.mark_sealed_trait(self: &mut AstPool, node: NodeId)'),
        ('fn AstPool.is_sealed_trait_node(self: &AstPool, node: i32)',
         'fn AstPool.is_sealed_trait_node(self: &AstPool, node: NodeId)'),
        ('fn AstPool.mark_move_closure(self: &mut AstPool, node: i32)',
         'fn AstPool.mark_move_closure(self: &mut AstPool, node: NodeId)'),
        ('fn AstPool.is_move_closure(self: &AstPool, node: i32)',
         'fn AstPool.is_move_closure(self: &AstPool, node: NodeId)'),
        ('fn AstPool.mark_non_escaping_closure(self: &mut AstPool, node: i32)',
         'fn AstPool.mark_non_escaping_closure(self: &mut AstPool, node: NodeId)'),
        ('fn AstPool.is_non_escaping_closure(self: &AstPool, node: i32)',
         'fn AstPool.is_non_escaping_closure(self: &AstPool, node: NodeId)'),
        ('fn AstPool.add_where_meta(self: &mut AstPool, fn_node: i32,',
         'fn AstPool.add_where_meta(self: &mut AstPool, fn_node: NodeId,'),
        ('fn AstPool.find_where_meta(self: &AstPool, fn_node: i32)',
         'fn AstPool.find_where_meta(self: &AstPool, fn_node: NodeId)'),
        ('fn AstPool.add_impl_type_params(self: &mut AstPool, impl_node: i32,',
         'fn AstPool.add_impl_type_params(self: &mut AstPool, impl_node: NodeId,'),
        ('fn AstPool.find_impl_type_params(self: &AstPool, impl_node: i32)',
         'fn AstPool.find_impl_type_params(self: &AstPool, impl_node: NodeId)'),
        ('fn AstPool.add_fn_param_pattern_value(self: &mut AstPool, node: i32)',
         'fn AstPool.add_fn_param_pattern_value(self: &mut AstPool, node: NodeId)'),
        ('fn AstPool.add_fn_param_pattern_meta(self: &mut AstPool, node: i32,',
         'fn AstPool.add_fn_param_pattern_meta(self: &mut AstPool, node: NodeId,'),
        ('fn AstPool.find_fn_param_pattern_meta(self: &AstPool, node: i32)',
         'fn AstPool.find_fn_param_pattern_meta(self: &AstPool, node: NodeId)'),
        ('fn AstPool.add_for_meta(self: &mut AstPool, node: i32,',
         'fn AstPool.add_for_meta(self: &mut AstPool, node: NodeId,'),
        ('fn AstPool.find_for_meta(self: &AstPool, node: i32)',
         'fn AstPool.find_for_meta(self: &AstPool, node: NodeId)'),
    ]
    for old, new in meta_fns:
        content = content.replace(old, new)

    # 7. impl_target_type_node takes and returns NodeId
    content = content.replace(
        'fn AstPool.add_impl_target_type_node(self: &mut AstPool, impl_node: i32, type_node: i32):',
        'fn AstPool.add_impl_target_type_node(self: &mut AstPool, impl_node: NodeId, type_node: NodeId):'
    )
    content = content.replace(
        'fn AstPool.find_impl_target_type_node(self: &AstPool, impl_node: i32) -> i32:',
        'fn AstPool.find_impl_target_type_node(self: &AstPool, impl_node: NodeId) -> NodeId:'
    )
    content = content.replace(
        'fn AstPool.add_impl_trait_type_args(self: &mut AstPool, impl_node: i32,',
        'fn AstPool.add_impl_trait_type_args(self: &mut AstPool, impl_node: NodeId,'
    )
    content = content.replace(
        'fn AstPool.find_impl_trait_type_args(self: &AstPool, impl_node: i32)',
        'fn AstPool.find_impl_trait_type_args(self: &AstPool, impl_node: NodeId)'
    )

    # 8. Fix HashMap lookups that use node as key - need node as i32
    # fn_meta_map, type_meta_map, etc. are HashMap[i32, i32]
    # When we pass NodeId to .get()/.insert(), need to cast to i32
    content = content.replace(
        '    let opt = self.fn_meta_map.get(node)',
        '    let opt = self.fn_meta_map.get(node as i32)'
    )
    content = content.replace(
        '    self.fn_meta_map.insert(node,',
        '    self.fn_meta_map.insert(node as i32,'
    )
    content = content.replace(
        '    let opt = self.type_meta_map.get(node)',
        '    let opt = self.type_meta_map.get(node as i32)'
    )
    content = content.replace(
        '    self.type_meta_map.insert(node,',
        '    self.type_meta_map.insert(node as i32,'
    )
    content = content.replace(
        '    self.pattern_qualifier_map.insert(node,',
        '    self.pattern_qualifier_map.insert(node as i32,'
    )
    content = content.replace(
        '    let opt = self.pattern_qualifier_map.get(node)',
        '    let opt = self.pattern_qualifier_map.get(node as i32)'
    )
    content = content.replace(
        '    self.must_use_type_set.insert(node,',
        '    self.must_use_type_set.insert(node as i32,'
    )
    content = content.replace(
        '    self.must_use_type_set.contains(node)',
        '    self.must_use_type_set.contains(node as i32)'
    )
    content = content.replace(
        '    self.sealed_trait_set.insert(node,',
        '    self.sealed_trait_set.insert(node as i32,'
    )
    content = content.replace(
        '    self.sealed_trait_set.contains(node)',
        '    self.sealed_trait_set.contains(node as i32)'
    )
    content = content.replace(
        '    self.move_closure_set.insert(node,',
        '    self.move_closure_set.insert(node as i32,'
    )
    content = content.replace(
        '    self.move_closure_set.contains(node)',
        '    self.move_closure_set.contains(node as i32)'
    )
    content = content.replace(
        '    self.non_escaping_closure_set.insert(node,',
        '    self.non_escaping_closure_set.insert(node as i32,'
    )
    content = content.replace(
        '    self.non_escaping_closure_set.contains(node)',
        '    self.non_escaping_closure_set.contains(node as i32)'
    )
    content = content.replace(
        '    let opt = self.where_meta_map.get(fn_node)',
        '    let opt = self.where_meta_map.get(fn_node as i32)'
    )
    content = content.replace(
        '    self.where_meta_map.insert(fn_node,',
        '    self.where_meta_map.insert(fn_node as i32,'
    )
    content = content.replace(
        '    let opt = self.impl_type_params_map.get(impl_node)',
        '    let opt = self.impl_type_params_map.get(impl_node as i32)'
    )
    content = content.replace(
        '    self.impl_type_params_map.insert(impl_node,',
        '    self.impl_type_params_map.insert(impl_node as i32,'
    )
    content = content.replace(
        '    let opt = self.impl_target_type_nodes_map.get(impl_node)',
        '    let opt = self.impl_target_type_nodes_map.get(impl_node as i32)'
    )
    content = content.replace(
        '    self.impl_target_type_nodes_map.insert(impl_node,',
        '    self.impl_target_type_nodes_map.insert(impl_node as i32,'
    )
    content = content.replace(
        '    let opt = self.impl_trait_type_args_map.get(impl_node)',
        '    let opt = self.impl_trait_type_args_map.get(impl_node as i32)'
    )
    content = content.replace(
        '    self.impl_trait_type_args_map.insert(impl_node,',
        '    self.impl_trait_type_args_map.insert(impl_node as i32,'
    )
    content = content.replace(
        '    self.fn_param_pattern_values.push(node)',
        '    self.fn_param_pattern_values.push(node as i32)'
    )
    content = content.replace(
        '    let opt = self.fn_param_pattern_meta_map.get(node)',
        '    let opt = self.fn_param_pattern_meta_map.get(node as i32)'
    )
    content = content.replace(
        '    self.fn_param_pattern_meta_map.insert(node,',
        '    self.fn_param_pattern_meta_map.insert(node as i32,'
    )
    content = content.replace(
        '    let opt = self.for_meta_map.get(node)',
        '    let opt = self.for_meta_map.get(node as i32)'
    )
    content = content.replace(
        '    self.for_meta_map.insert(node,',
        '    self.for_meta_map.insert(node as i32,'
    )

    # 9. Fix find_impl_target_type_node return
    content = content.replace(
        '        return opt.unwrap()\n    0\n\nfn AstPool.add_impl_trait_type_args',
        '        return NodeId(opt.unwrap())\n    NodeId(0)\n\nfn AstPool.add_impl_trait_type_args'
    )

    # 10. fn_param_pattern_value returns NodeId
    content = content.replace(
        'fn AstPool.fn_param_pattern_value(self: &AstPool, idx: i32) -> i32:',
        'fn AstPool.fn_param_pattern_value(self: &AstPool, idx: i32) -> NodeId:'
    )
    content = content.replace(
        '    self.fn_param_pattern_values.get(idx as i64)',
        '    NodeId(self.fn_param_pattern_values.get(idx as i64))',
        1
    )

    with open('src/Ast.w', 'w') as f:
        f.write(content)
    print(f"Patched src/Ast.w")


def patch_parser_poisoned():
    """Change poisoned_expr to return NodeId."""
    with open('src/Parser.w', 'r') as f:
        content = f.read()

    # poisoned_expr calls pool.add_node which now returns NodeId
    # But parse functions return i32. We need poisoned_expr to return i32.
    # Actually, the entire Parser returns i32 for nodes. We should NOT
    # change Parser yet — let the compiler errors guide us.
    # The pool.add_node() return is NodeId, but Parser stores it as i32.
    # This will produce type errors that Script 2 will fix.

    with open('src/Parser.w', 'w') as f:
        f.write(content)


if __name__ == '__main__':
    patch_ast()
    print("Done. Run 'make build' to see errors.")
