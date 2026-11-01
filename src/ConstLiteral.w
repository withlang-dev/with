// ConstLiteral.w — the literal a module-constant expression denotes, for
// both backends (D65: one owner). A name is its `let`'s initializer, `XS[i]`
// with a literal `i` the element written there, `P.field` the field's value
// (by name, or by position in a positional literal), and `XS.len()` of a
// literal sequence its element count. A global built from these is
// initialized data: a migrated C `sizeof(a) / sizeof(a[0])` (pcre2's
// `_pcre2_utt_size_8 = _pcre2_utt_8.len()`, stc's `nr16: Cc_range16.len()`)
// never becomes a runtime init — which a bundle object refuses (#2219) and
// an emitted C program never released at exit.
use Ast
use Sema
use SemaTypes

// The `let` declaring the immutable module constant `sym`, or 0.
fn module_const_decl_node(pool: &AstPool, sym: i32) -> i32:
    for di in 0..pool.decl_count():
        let decl = pool.get_decl(di)
        if pool.kind(decl) != NodeKind.NK_LET_DECL or pool.get_data0(decl) != sym: continue
        if pool.get_data2(decl) % 2 != 0 or pool.get_data1(decl) == 0: continue
        return decl
    0

// That constant's initializer, its `comptime`/grouping/cast wrappers removed.
fn module_const_value_node(pool: &AstPool, sym: i32) -> i32:
    let decl = module_const_decl_node(pool, sym)
    if decl == 0: return 0
    unwrap_const_expr_node(pool, pool.get_data1(decl))

fn unwrap_const_expr_node(pool: &AstPool, node: i32) -> i32:
    var cur = node
    while cur != 0:
        match pool.kind(cur):
            NodeKind.NK_COMPTIME | NodeKind.NK_GROUPED | NodeKind.NK_CAST => cur = pool.get_data0(cur)
            _ => return cur
    cur

// The value written for `field_name` in a struct literal: by name, or at
// `field_index` when the literal is positional; 0 when absent.
fn struct_literal_field_value_node(pool: &AstPool, sema: &Sema, lit_node: i32, field_name: i32, field_index: i32) -> i32:
    if lit_node == 0 or pool.kind(lit_node) != NodeKind.NK_STRUCT_LIT: return 0
    let field_start = pool.get_data1(lit_node)
    let want_text = sema.pool_resolve(field_name)
    for li in 0..pool.get_data2(lit_node):
        let lit_name = pool.get_extra(field_start + li * 2)
        let lit_value = pool.get_extra(field_start + li * 2 + 1)
        if lit_name == 0:
            if li == field_index: return lit_value
        else if lit_name == field_name or (want_text.len() > 0 and sema.pool_resolve(lit_name) == want_text):
            return lit_value
    0

// The root name of an expression over module constants (`XS[0].lo` → `XS`),
// or 0.
fn const_literal_root_sym(pool: &AstPool, node: i32) -> i32:
    var cur = unwrap_const_expr_node(pool, node)
    while cur != 0:
        match pool.kind(cur):
            NodeKind.NK_IDENT => return pool.get_data0(cur)
            NodeKind.NK_INDEX | NodeKind.NK_FIELD_ACCESS => cur = unwrap_const_expr_node(pool, pool.get_data0(cur))
            _ => return 0
    0

// The declared index of `field_name` in the struct type of `node`, or -1.
fn struct_field_index(sema: &Sema, node: i32, field_name: i32) -> i32:
    let ty: i32 = sema.typed_expr_types.get(node) ?? 0
    if ty <= 0: return -1
    let resolved = sema.resolve_alias(ty)
    if sema.get_type_kind(resolved) != TypeKind.TY_STRUCT: return -1
    let te_start = sema.get_type_d1(resolved)
    for fi in 0..sema.get_type_d2(resolved):
        if sema.type_extra[(te_start + fi * 3)] == field_name: return fi
    -1

// The literal node the expression denotes, or 0 when any step is not one.
fn const_literal_part_node(pool: &AstPool, sema: &Sema, node: i32) -> i32:
    let cur = unwrap_const_expr_node(pool, node)
    if cur == 0: return 0
    match pool.kind(cur):
        NodeKind.NK_IDENT => module_const_value_node(pool, pool.get_data0(cur))
        NodeKind.NK_INDEX =>
            let seq = const_literal_part_node(pool, sema, pool.get_data0(cur))
            if seq == 0 or pool.kind(seq) != NodeKind.NK_ARRAY_LIT or pool.get_data2(seq) != 0: return 0
            let index_node = unwrap_const_expr_node(pool, pool.get_data1(cur))
            if index_node == 0 or pool.kind(index_node) != NodeKind.NK_INT_LIT: return 0
            let index = pool.int_literal_fast_i64(index_node as NodeId)
            if index.ok == 0 or index.value < 0 or index.value >= pool.get_data1(seq) as i64: return 0
            unwrap_const_expr_node(pool, pool.get_extra(pool.get_data0(seq) + index.value as i32))
        NodeKind.NK_FIELD_ACCESS =>
            let receiver = pool.get_data0(cur)
            let lit = const_literal_part_node(pool, sema, receiver)
            if lit == 0 or pool.kind(lit) != NodeKind.NK_STRUCT_LIT: return 0
            let field_name = pool.get_data1(cur)
            unwrap_const_expr_node(pool, struct_literal_field_value_node(pool, sema, lit, field_name, struct_field_index(sema, receiver, field_name)))
        _ => 0

// `XS.len()` of a literal sequence: its element count; -1 otherwise.
fn const_literal_len(pool: &AstPool, sema: &Sema, call_node: i32) -> i64:
    let cur = unwrap_const_expr_node(pool, call_node)
    if cur == 0 or pool.kind(cur) != NodeKind.NK_CALL or pool.get_data2(cur) != 0: return -1
    let callee = pool.get_data0(cur)
    if pool.kind(callee) != NodeKind.NK_FIELD_ACCESS or sema.pool_resolve(pool.get_data1(callee)) != "len": return -1
    let seq = const_literal_part_node(pool, sema, pool.get_data0(callee))
    if seq == 0 or pool.kind(seq) != NodeKind.NK_ARRAY_LIT or pool.get_data2(seq) != 0: return -1
    pool.get_data1(seq) as i64
