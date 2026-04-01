use Ast
use ComptimeEval
use ComptimeValue
use Diagnostic
use InternPool
use Sema
use SemaCheck
use Span

fn ct_emit_error(sema: &mut Sema, diags: &mut DiagnosticList, ast: AstPool, node: i32, msg: str):
    let start = ast.get_start(node)
    let end = ast.get_end(node)
    diags.emit(Diagnostic.err(msg, Span { file: sema.local_file_id, start, end }))

fn astpool_clone_deep(src: AstPool) -> AstPool:
    var out = AstPool.new()

    for si in 0..src.strings.len() as i32:
        out.add_string(src.get_string(si))

    for ei in 0..src.extra_len():
        out.add_extra(src.get_extra(ei))

    for ni in 1..src.node_count():
        let src_node = ni as NodeId
        let node = out.add_node(
            src.kind(src_node),
            src.get_start(src_node),
            src.get_end(src_node),
            src.get_data0(src_node),
            src.get_data1(src_node),
            src.get_data2(src_node)
        )
        out.set_literal_suffix(node, src.literal_suffix(src_node))

    for di in 0..src.decl_count():
        out.add_decl(src.get_decl(di))
    out.set_local_decl_count(src.local_decl_count())
    out.set_prelude_decl_count(src.prelude_decl_count())

    var fn_meta = 0
    while fn_meta < src.fn_meta.len() as i32:
        out.add_fn_meta(
            (src.fn_meta.get(fn_meta as i64)) as NodeId,
            src.fn_meta_flags(fn_meta),
            src.fn_meta_ret(fn_meta),
            src.fn_meta_param_start(fn_meta),
            src.fn_meta_param_count(fn_meta),
            src.fn_meta_tp_start(fn_meta),
            src.fn_meta_tp_count(fn_meta)
        )
        let param_start = src.fn_meta_param_start(fn_meta)
        let param_count = src.fn_meta_param_count(fn_meta)
        for pi in 0..param_count:
            let default_node = src.get_fn_param_default(param_start, pi)
            if default_node != 0:
                out.set_fn_param_default(param_start, pi, default_node)
        fn_meta = fn_meta + 7

    var type_meta = 0
    while type_meta < src.type_meta.len() as i32:
        out.add_type_meta(
            (src.type_meta.get(type_meta as i64)) as NodeId,
            src.type_meta_derive_start(type_meta),
            src.type_meta_derive_count(type_meta)
        )
        type_meta = type_meta + 3

    var patq = 0
    while patq < src.pattern_qualifiers.len() as i32:
        out.add_pattern_qualifier(
            (src.pattern_qualifiers.get(patq as i64)) as NodeId,
            src.pattern_qualifiers.get((patq + 1) as i64)
        )
        patq = patq + 2

    for pi in 0..src.fn_param_patterns_len():
        out.add_fn_param_pattern_value(src.fn_param_pattern_value(pi))

    var pmeta = 0
    while pmeta < src.fn_param_pattern_meta.len() as i32:
        out.add_fn_param_pattern_meta(
            (src.fn_param_pattern_meta.get(pmeta as i64)) as NodeId,
            src.fn_param_pattern_meta_start(pmeta),
            src.fn_param_pattern_meta_count(pmeta)
        )
        pmeta = pmeta + 3

    var for_meta = 0
    while for_meta < src.for_meta.len() as i32:
        out.add_for_meta(
            (src.for_meta.get(for_meta as i64)) as NodeId,
            src.for_meta_index_binding(for_meta),
            src.for_meta_label(for_meta)
        )
        for_meta = for_meta + 3

    for mi in 0..src.must_use_type_nodes.len() as i32:
        out.mark_must_use_type((src.must_use_type_nodes.get(mi as i64)) as NodeId)
    for si in 0..src.sealed_trait_nodes.len() as i32:
        out.mark_sealed_trait((src.sealed_trait_nodes.get(si as i64)) as NodeId)
    for ci in 0..src.comptime_decl_nodes.len() as i32:
        out.mark_comptime_decl((src.comptime_decl_nodes.get(ci as i64)) as NodeId)
    for mi in 0..src.move_closure_nodes.len() as i32:
        out.mark_move_closure((src.move_closure_nodes.get(mi as i64)) as NodeId)
    for ni in 0..src.non_escaping_closure_nodes.len() as i32:
        out.mark_non_escaping_closure((src.non_escaping_closure_nodes.get(ni as i64)) as NodeId)

    var where_meta = 0
    while where_meta < src.where_meta.len() as i32:
        out.add_where_meta(
            (src.where_meta.get(where_meta as i64)) as NodeId,
            src.where_meta.get((where_meta + 1) as i64),
            src.where_meta.get((where_meta + 2) as i64)
        )
        where_meta = where_meta + 3

    var impl_tp = 0
    while impl_tp < src.impl_type_params.len() as i32:
        out.add_impl_type_params(
            (src.impl_type_params.get(impl_tp as i64)) as NodeId,
            src.impl_type_params.get((impl_tp + 1) as i64),
            src.impl_type_params.get((impl_tp + 2) as i64)
        )
        impl_tp = impl_tp + 3

    var impl_target = 0
    while impl_target < src.impl_target_type_nodes.len() as i32:
        out.add_impl_target_type_node(
            (src.impl_target_type_nodes.get(impl_target as i64)) as NodeId,
            (src.impl_target_type_nodes.get((impl_target + 1) as i64)) as NodeId
        )
        impl_target = impl_target + 2

    var impl_trait_args = 0
    while impl_trait_args < src.impl_trait_type_args.len() as i32:
        out.add_impl_trait_type_args(
            (src.impl_trait_type_args.get(impl_trait_args as i64)) as NodeId,
            src.impl_trait_type_args.get((impl_trait_args + 1) as i64),
            src.impl_trait_type_args.get((impl_trait_args + 2) as i64)
        )
        impl_trait_args = impl_trait_args + 3

    out

fn ct_new_node_copy(pool: &mut AstPool, kind: i32, start: i32, end: i32, d0: i32, d1: i32, d2: i32, suffix: i32) -> i32:
    let node = pool.add_node(kind, start, end, d0, d1, d2)
    pool.set_literal_suffix(node, suffix)
    node as i32

fn ct_clone_leaf(pool: &mut AstPool, node: i32) -> i32:
    ct_new_node_copy(
        pool,
        pool.kind(node),
        pool.get_start(node),
        pool.get_end(node),
        pool.get_data0(node),
        pool.get_data1(node),
        pool.get_data2(node),
        pool.literal_suffix(node)
    )

fn ct_empty_block(pool: &mut AstPool, node: i32) -> i32:
    pool.add_node(NodeKind.NK_BLOCK, pool.get_start(node), pool.get_end(node), pool.extra_len(), 0, 0) as i32

fn ct_fresh_sym(intern: &mut InternPool, prefix: str, seed: i32) -> i32:
    intern.intern(prefix ++ f"{seed}" ++ "_" ++ f"{intern.symbol_texts.len() as i32}")

fn ct_build_type_expr(pool: &mut AstPool, intern: &mut InternPool, sema: &mut Sema, type_id: i32, node: i32) -> i32:
    let resolved = sema.resolve_alias(type_id)
    let start = pool.get_start(node)
    let end = pool.get_end(node)
    let tk = sema.get_type_kind(resolved)

    if tk == TypeKind.TY_GENERIC_INST:
        let base_sym = intern.intern(sema.pool_resolve(sema.get_type_d0(resolved)))
        let extra_start = sema.get_type_d1(resolved)
        let arg_count = sema.get_type_d2(resolved)
        let arg_nodes: Vec[i32] = Vec.new()
        for ai in 0..arg_count:
            let arg_tid = sema.type_extra.get((extra_start + ai) as i64)
            let arg_node = ct_build_type_expr(pool, intern, sema, arg_tid, node)
            if arg_node == 0:
                return 0
            arg_nodes.push(arg_node)
        let new_extra = pool.extra_len()
        for ai in 0..arg_nodes.len() as i32:
            pool.add_extra(arg_nodes.get(ai as i64))
        return pool.add_node(NodeKind.NK_TYPE_GENERIC, start, end, base_sym, new_extra, arg_count) as i32

    if tk == TypeKind.TY_ARRAY:
        let elem_node = ct_build_type_expr(pool, intern, sema, sema.get_type_d0(resolved), node)
        if elem_node == 0:
            return 0
        return pool.add_node(NodeKind.NK_TYPE_ARRAY, start, end, elem_node, sema.get_type_d1(resolved), 0) as i32

    if tk == TypeKind.TY_SLICE:
        let elem_node = ct_build_type_expr(pool, intern, sema, sema.get_type_d0(resolved), node)
        if elem_node == 0:
            return 0
        return pool.add_node(NodeKind.NK_TYPE_SLICE, start, end, elem_node, 0, 0) as i32

    if tk == TypeKind.TY_TUPLE:
        let extra_start = sema.get_type_d0(resolved)
        let elem_count = sema.get_type_d1(resolved)
        let elem_nodes: Vec[i32] = Vec.new()
        for ei in 0..elem_count:
            let elem_tid = sema.type_extra.get((extra_start + ei) as i64)
            let elem_node = ct_build_type_expr(pool, intern, sema, elem_tid, node)
            if elem_node == 0:
                return 0
            elem_nodes.push(elem_node)
        let new_extra = pool.extra_len()
        for ei in 0..elem_nodes.len() as i32:
            pool.add_extra(elem_nodes.get(ei as i64))
        return pool.add_node(NodeKind.NK_TYPE_TUPLE, start, end, new_extra, elem_count, 0) as i32

    if tk == TypeKind.TY_PTR:
        let pointee = ct_build_type_expr(pool, intern, sema, sema.get_type_d0(resolved), node)
        if pointee == 0:
            return 0
        return pool.add_node(NodeKind.NK_TYPE_PTR, start, end, pointee, sema.get_type_d1(resolved), sema.get_type_d2(resolved)) as i32

    if tk == TypeKind.TY_REF:
        let pointee = ct_build_type_expr(pool, intern, sema, sema.get_type_d0(resolved), node)
        if pointee == 0:
            return 0
        return pool.add_node(NodeKind.NK_TYPE_REF, start, end, pointee, sema.get_type_d1(resolved), 0) as i32

    if tk == TypeKind.TY_FN:
        let param_start = sema.get_type_d0(resolved)
        let param_count = sema.get_type_d1(resolved)
        let param_nodes: Vec[i32] = Vec.new()
        for pi in 0..param_count:
            let param_tid = sema.type_extra.get((param_start + pi) as i64)
            let param_node = ct_build_type_expr(pool, intern, sema, param_tid, node)
            if param_node == 0:
                return 0
            param_nodes.push(param_node)
        let new_extra = pool.extra_len()
        for pi in 0..param_nodes.len() as i32:
            pool.add_extra(param_nodes.get(pi as i64))
        let ret_node = ct_build_type_expr(pool, intern, sema, sema.get_type_d2(resolved), node)
        if ret_node == 0:
            return 0
        return pool.add_node(NodeKind.NK_TYPE_FN, start, end, new_extra, param_count, ret_node) as i32

    if tk == TypeKind.TY_TRAIT_OBJ:
        let trait_sym = intern.intern(sema.pool_resolve(sema.get_type_d0(resolved)))
        return pool.add_node(NodeKind.NK_TYPE_TRAIT_OBJ, start, end, trait_sym, 0, 0) as i32

    let type_sym = intern.intern(sema.type_name(type_id))
    pool.add_node(NodeKind.NK_TYPE_NAMED, start, end, type_sym, 0, 0) as i32

fn ct_build_call(pool: &mut AstPool, node: i32, callee: i32, args: Vec[i32]) -> i32:
    let extra_start = pool.extra_len()
    for ai in 0..args.len() as i32:
        pool.add_extra(args.get(ai as i64))
    pool.add_node(NodeKind.NK_CALL, pool.get_start(node), pool.get_end(node), callee, extra_start, args.len() as i32) as i32

fn ct_build_collection_ctor(pool: &mut AstPool, intern: &mut InternPool, sema: &mut Sema, type_id: i32, node: i32) -> i32:
    let type_node = ct_build_type_expr(pool, intern, sema, type_id, node)
    if type_node == 0:
        return 0
    let new_sym = intern.intern("new")
    let callee = pool.add_node(NodeKind.NK_FIELD_ACCESS, pool.get_start(node), pool.get_end(node), type_node, new_sym, 0)
    let no_args: Vec[i32] = Vec.new()
    ct_build_call(pool, node, callee as i32, no_args)

fn ct_build_typed_binding(pool: &mut AstPool, intern: &mut InternPool, sema: &mut Sema, name_sym: i32, value: i32, type_id: i32, node: i32, is_mut: i32) -> i32:
    let type_node = ct_build_type_expr(pool, intern, sema, type_id, node)
    if type_node == 0:
        return 0
    let type_extra = pool.extra_len()
    pool.add_extra(type_node)
    let flags = (if is_mut != 0: 1 else: 0) + (type_extra + 1) * 2
    pool.add_node(NodeKind.NK_LET_BINDING, pool.get_start(node), pool.get_end(node), name_sym, value, flags) as i32

fn ct_build_vec_value_tree(pool: &mut AstPool, intern: &mut InternPool, sema: &mut Sema, value: ComptimeValue, node: i32, extras: Vec[ComptimeValue]) -> i32:
    let tmp_sym = ct_fresh_sym(intern, "__ct_vec_", node)
    let ctor = ct_build_collection_ctor(pool, intern, sema, value.type_id, node)
    if ctor == 0:
        return 0
    let stmts: Vec[i32] = Vec.new()
    let tmp_binding = ct_build_typed_binding(pool, intern, sema, tmp_sym, ctor, value.type_id, node, 1)
    if tmp_binding == 0:
        return 0
    stmts.push(tmp_binding)
    let push_sym = intern.intern("push")
    for i in 0..value.extra_count:
        let elem = extras.get((value.extra_start + i) as i64)
        let elem_node = ct_build_value_tree(pool, intern, sema, elem, node, extras)
        if elem_node == 0:
            return 0
        let recv_ident = pool.add_node(NodeKind.NK_IDENT, pool.get_start(node), pool.get_end(node), tmp_sym, 0, 0)
        let callee = pool.add_node(NodeKind.NK_FIELD_ACCESS, pool.get_start(node), pool.get_end(node), recv_ident as i32, push_sym, 0)
        let args: Vec[i32] = Vec.new()
        args.push(elem_node)
        stmts.push(ct_build_call(pool, node, callee as i32, args))
    let stmt_extra = pool.extra_len()
    for si in 0..stmts.len() as i32:
        pool.add_extra(stmts.get(si as i64))
    let tail = pool.add_node(NodeKind.NK_IDENT, pool.get_start(node), pool.get_end(node), tmp_sym, 0, 0)
    pool.add_node(NodeKind.NK_BLOCK, pool.get_start(node), pool.get_end(node), stmt_extra, stmts.len() as i32, tail as i32) as i32

fn ct_build_map_value_tree(pool: &mut AstPool, intern: &mut InternPool, sema: &mut Sema, value: ComptimeValue, node: i32, extras: Vec[ComptimeValue]) -> i32:
    let tmp_sym = ct_fresh_sym(intern, "__ct_map_", node)
    let ctor = ct_build_collection_ctor(pool, intern, sema, value.type_id, node)
    if ctor == 0:
        return 0
    let stmts: Vec[i32] = Vec.new()
    let tmp_binding = ct_build_typed_binding(pool, intern, sema, tmp_sym, ctor, value.type_id, node, 1)
    if tmp_binding == 0:
        return 0
    stmts.push(tmp_binding)
    let insert_sym = intern.intern("insert")
    for i in 0..value.extra_count:
        let base = value.extra_start + i * 2
        let key_node = ct_build_value_tree(pool, intern, sema, extras.get(base as i64), node, extras)
        let item_node = ct_build_value_tree(pool, intern, sema, extras.get((base + 1) as i64), node, extras)
        if key_node == 0 or item_node == 0:
            return 0
        let recv_ident = pool.add_node(NodeKind.NK_IDENT, pool.get_start(node), pool.get_end(node), tmp_sym, 0, 0)
        let callee = pool.add_node(NodeKind.NK_FIELD_ACCESS, pool.get_start(node), pool.get_end(node), recv_ident as i32, insert_sym, 0)
        let args: Vec[i32] = Vec.new()
        args.push(key_node)
        args.push(item_node)
        stmts.push(ct_build_call(pool, node, callee as i32, args))
    let stmt_extra = pool.extra_len()
    for si in 0..stmts.len() as i32:
        pool.add_extra(stmts.get(si as i64))
    let tail = pool.add_node(NodeKind.NK_IDENT, pool.get_start(node), pool.get_end(node), tmp_sym, 0, 0)
    pool.add_node(NodeKind.NK_BLOCK, pool.get_start(node), pool.get_end(node), stmt_extra, stmts.len() as i32, tail as i32) as i32

fn ct_build_value_tree(pool: &mut AstPool, intern: &mut InternPool, sema: &mut Sema, value: ComptimeValue, node: i32, extras: Vec[ComptimeValue]) -> i32:
    if value.kind == ComptimeValueKind.CV_INT:
        return pool.add_node(
            NodeKind.NK_INT_LIT,
            pool.get_start(node),
            pool.get_end(node),
            ast_int_part0(value.data0),
            ast_int_part1(value.data0),
            ast_int_part2(value.data0)
        ) as i32
    if value.kind == ComptimeValueKind.CV_BOOL:
        return pool.add_node(
            NodeKind.NK_BOOL_LIT,
            pool.get_start(node),
            pool.get_end(node),
            if value.data0 != 0: 1 else: 0,
            0,
            0
        ) as i32
    if value.kind == ComptimeValueKind.CV_STR:
        let sym = intern.intern(value.text)
        return pool.add_node(NodeKind.NK_STRING_LIT, pool.get_start(node), pool.get_end(node), sym, 0, 0) as i32
    if value.kind == ComptimeValueKind.CV_VOID:
        return ct_empty_block(pool, node)
    if value.kind == ComptimeValueKind.CV_ARRAY or value.kind == ComptimeValueKind.CV_TUPLE:
        let elem_nodes: Vec[i32] = Vec.new()
        for i in 0..value.extra_count:
            let elem = extras.get((value.extra_start + i) as i64)
            let elem_node = ct_build_value_tree(pool, intern, sema, elem, node, extras)
            if elem_node == 0:
                return 0
            elem_nodes.push(elem_node)
        let extra_start = pool.extra_len()
        for i in 0..elem_nodes.len() as i32:
            pool.add_extra(elem_nodes.get(i as i64))
        let out_kind = if value.kind == ComptimeValueKind.CV_ARRAY: NodeKind.NK_ARRAY_LIT else: NodeKind.NK_TUPLE
        return pool.add_node(out_kind, pool.get_start(node), pool.get_end(node), extra_start, value.extra_count, 0) as i32
    if value.kind == ComptimeValueKind.CV_RANGE:
        let start_node = pool.add_node(
            NodeKind.NK_INT_LIT,
            pool.get_start(node),
            pool.get_end(node),
            ast_int_part0(value.data0),
            ast_int_part1(value.data0),
            ast_int_part2(value.data0)
        )
        let end_node = pool.add_node(
            NodeKind.NK_INT_LIT,
            pool.get_start(node),
            pool.get_end(node),
            ast_int_part0(value.data1),
            ast_int_part1(value.data1),
            ast_int_part2(value.data1)
        )
        return pool.add_node(NodeKind.NK_RANGE, pool.get_start(node), pool.get_end(node), start_node as i32, end_node as i32, value.extra_start) as i32
    if value.kind == ComptimeValueKind.CV_STRUCT:
        let resolved = sema.resolve_alias(value.type_id)
        if sema.get_type_kind(resolved) != TypeKind.TY_STRUCT:
            return 0
        let name_sym = intern.intern(sema.pool_resolve(sema.get_type_d0(resolved)))
        let te_start = sema.get_type_d1(resolved)
        let field_count = sema.get_type_d2(resolved)
        let field_syms: Vec[i32] = Vec.new()
        let field_nodes: Vec[i32] = Vec.new()
        for fi in 0..field_count:
            let field_sym = intern.intern(sema.pool_resolve(sema.type_extra.get((te_start + fi * 3) as i64)))
            let field_value = extras.get((value.extra_start + fi) as i64)
            let field_node = ct_build_value_tree(pool, intern, sema, field_value, node, extras)
            if field_node == 0:
                return 0
            field_syms.push(field_sym)
            field_nodes.push(field_node)
        let struct_extra = pool.extra_len()
        for fi in 0..field_count:
            pool.add_extra(field_syms.get(fi as i64))
            pool.add_extra(field_nodes.get(fi as i64))
        return pool.add_node(NodeKind.NK_STRUCT_LIT, pool.get_start(node), pool.get_end(node), name_sym, struct_extra, field_count) as i32
    if value.kind == ComptimeValueKind.CV_VEC:
        return ct_build_vec_value_tree(pool, intern, sema, value, node, extras)
    if value.kind == ComptimeValueKind.CV_MAP:
        return ct_build_map_value_tree(pool, intern, sema, value, node, extras)
    0

fn ct_eval_truthy(source_ast: AstPool, sema: &mut Sema, diags: &mut DiagnosticList, node: i32) -> i32:
    let value = comptime_force_eval_expr(sema as *mut Sema, diags, source_ast, sema.pool, node)
    if comptime_value_is_valid(value) == 0:
        return 0 - 1
    let truthy = comptime_value_truthy(value)
    if truthy >= 0:
        return truthy
    ct_emit_error(sema, diags, source_ast, node, "comptime condition must be bool or integer")
    0 - 1

fn ct_transform_fstring(source_ast: AstPool, pool: &mut AstPool, sema: &mut Sema, intern: &mut InternPool, diags: &mut DiagnosticList, node: i32):
    let seg_count = pool.get_data0(node)
    let extra_start = pool.get_data1(node)
    var pos = extra_start
    for _ in 0..seg_count:
        let seg_kind = pool.get_extra(pos)
        if seg_kind == FStringSegmentKind.LITERAL:
            pos = pos + 2
            continue
        let expr_node = pool.get_extra(pos + 1)
        let spec_node = pool.get_extra(pos + 2)
        if expr_node != 0:
            pool.extra.set_i32((pos + 1) as i64, ct_transform_expr(source_ast, pool, sema, intern, diags, expr_node))
        if spec_node != 0:
            pool.extra.set_i32((pos + 2) as i64, ct_transform_expr(source_ast, pool, sema, intern, diags, spec_node))
        pos = pos + 3

fn ct_transform_match_arm(source_ast: AstPool, pool: &mut AstPool, sema: &mut Sema, intern: &mut InternPool, diags: &mut DiagnosticList, node: i32):
    let body = pool.get_data1(node)
    let guard = pool.get_data2(node)
    if body != 0:
        pool.set_data1(node, ct_transform_expr(source_ast, pool, sema, intern, diags, body))
    if guard != 0:
        pool.set_data2(node, ct_transform_expr(source_ast, pool, sema, intern, diags, guard))

fn ct_rewrite_comptime_if(source_ast: AstPool, pool: &mut AstPool, sema: &mut Sema, intern: &mut InternPool, diags: &mut DiagnosticList, wrapper: i32, inner: i32) -> i32:
    let cond = pool.get_data0(inner)
    let truthy = ct_eval_truthy(source_ast, sema, diags, cond)
    if truthy < 0:
        return wrapper
    if truthy != 0:
        let then_body = pool.get_data1(inner)
        if then_body != 0:
            return ct_transform_expr(source_ast, pool, sema, intern, diags, then_body)
        return ct_empty_block(pool, wrapper)
    let else_body = pool.get_data2(inner)
    if else_body != 0:
        return ct_transform_expr(source_ast, pool, sema, intern, diags, else_body)
    ct_empty_block(pool, wrapper)

fn ct_iter_count(value: ComptimeValue) -> i32:
    if value.kind == ComptimeValueKind.CV_ARRAY or value.kind == ComptimeValueKind.CV_TUPLE or value.kind == ComptimeValueKind.CV_VEC:
        return value.extra_count
    if value.kind == ComptimeValueKind.CV_RANGE:
        let span = if value.extra_start != 0: value.data1 - value.data0 + 1 else: value.data1 - value.data0
        if span <= 0:
            return 0
        return span as i32
    0 - 1

fn ct_iter_item_node(pool: &mut AstPool, intern: &mut InternPool, sema: &mut Sema, iterable: ComptimeValue, index: i32, node: i32, extras: Vec[ComptimeValue]) -> i32:
    if iterable.kind == ComptimeValueKind.CV_RANGE:
        let item = comptime_value_int(0, iterable.data0 + index as i64)
        return ct_build_value_tree(pool, intern, sema, item, node, extras)
    if iterable.kind == ComptimeValueKind.CV_ARRAY or iterable.kind == ComptimeValueKind.CV_TUPLE or iterable.kind == ComptimeValueKind.CV_VEC:
        let item = extras.get((iterable.extra_start + index) as i64)
        return ct_build_value_tree(pool, intern, sema, item, node, extras)
    0

fn ct_struct_lit_field_value(pool: &mut AstPool, node: i32, field: i32) -> i32:
    if node == 0 or pool.kind(node) != NodeKind.NK_STRUCT_LIT:
        return 0
    let extra_start = pool.get_data1(node)
    let field_count = pool.get_data2(node)
    for fi in 0..field_count:
        let base = extra_start + fi * 2
        if pool.get_extra(base) == field:
            return pool.get_extra(base + 1)
    0

fn ct_try_fold_type_call(pool: &mut AstPool, sema: &mut Sema, intern: &mut InternPool, diags: &mut DiagnosticList, node: i32) -> i32:
    if node == 0 or pool.kind(node) != NodeKind.NK_CALL:
        return node
    let callee = pool.get_data0(node)
    if callee == 0 or pool.kind(callee) != NodeKind.NK_FIELD_ACCESS:
        return node
    if intern.resolve(pool.get_data1(callee)) == "new":
        return node
    let recv = pool.get_data0(callee)
    if sema.static_receiver_type_is_known(recv) == 0:
        return node
    let eval_ast = unsafe: *pool
    let evald = comptime_try_eval_expr_result(sema as *mut Sema, diags, eval_ast, sema.pool, node)
    if comptime_value_is_valid(evald.value) == 0:
        return node
    let folded = ct_build_value_tree(pool, intern, sema, evald.value, node, evald.extras)
    if folded != 0:
        return folded
    node

fn ct_clone_tree_with_subst(pool: &mut AstPool, node: i32, subst_sym: i32, subst_node: i32, index_sym: i32, index_node: i32) -> i32:
    if node == 0:
        return 0
    let kind = pool.kind(node)

    if kind == NodeKind.NK_IDENT:
        let sym = pool.get_data0(node)
        if subst_sym != 0 and sym == subst_sym:
            return ct_clone_tree_with_subst(pool, subst_node, 0, 0, 0, 0)
        if index_sym != 0 and sym == index_sym:
            return ct_clone_tree_with_subst(pool, index_node, 0, 0, 0, 0)
        return ct_clone_leaf(pool, node)

    if kind == NodeKind.NK_INT_LIT or kind == NodeKind.NK_FLOAT_LIT or kind == NodeKind.NK_STRING_LIT or kind == NodeKind.NK_C_STRING_LIT or kind == NodeKind.NK_BOOL_LIT or kind == NodeKind.NK_NULL_LIT or kind == NodeKind.NK_TYPE_NAMED or kind == NodeKind.NK_TYPE_INFERRED or kind == NodeKind.NK_COMPTIME_ERROR or kind == NodeKind.NK_PAT_WILDCARD or kind == NodeKind.NK_PAT_IDENT or kind == NodeKind.NK_PAT_INT or kind == NodeKind.NK_PAT_BOOL or kind == NodeKind.NK_PAT_STRING or kind == NodeKind.NK_PAT_TYPED_BIND:
        return ct_clone_leaf(pool, node)

    if kind == NodeKind.NK_GROUPED or kind == NodeKind.NK_RETURN or kind == NodeKind.NK_DEFER or kind == NodeKind.NK_ERRDEFER or kind == NodeKind.NK_AWAIT or kind == NodeKind.NK_ASYNC_BLOCK or kind == NodeKind.NK_SPAWN or kind == NodeKind.NK_YIELD:
        let child = ct_clone_tree_with_subst(pool, pool.get_data0(node), subst_sym, subst_node, index_sym, index_node)
        return ct_new_node_copy(pool, kind, pool.get_start(node), pool.get_end(node), child, pool.get_data1(node), pool.get_data2(node), pool.literal_suffix(node))

    if kind == NodeKind.NK_UNARY:
        let operand = ct_clone_tree_with_subst(pool, pool.get_data1(node), subst_sym, subst_node, index_sym, index_node)
        return ct_new_node_copy(pool, kind, pool.get_start(node), pool.get_end(node), pool.get_data0(node), operand, pool.get_data2(node), pool.literal_suffix(node))

    if kind == NodeKind.NK_BINARY:
        let lhs = ct_clone_tree_with_subst(pool, pool.get_data1(node), subst_sym, subst_node, index_sym, index_node)
        let rhs = ct_clone_tree_with_subst(pool, pool.get_data2(node), subst_sym, subst_node, index_sym, index_node)
        return ct_new_node_copy(pool, kind, pool.get_start(node), pool.get_end(node), pool.get_data0(node), lhs, rhs, pool.literal_suffix(node))

    if kind == NodeKind.NK_ASSIGN or kind == NodeKind.NK_PIPELINE:
        let lhs = ct_clone_tree_with_subst(pool, pool.get_data0(node), subst_sym, subst_node, index_sym, index_node)
        let rhs = ct_clone_tree_with_subst(pool, pool.get_data1(node), subst_sym, subst_node, index_sym, index_node)
        return ct_new_node_copy(pool, kind, pool.get_start(node), pool.get_end(node), lhs, rhs, pool.get_data2(node), pool.literal_suffix(node))

    if kind == NodeKind.NK_FIELD_ACCESS:
        let base = ct_clone_tree_with_subst(pool, pool.get_data0(node), subst_sym, subst_node, index_sym, index_node)
        let folded_value = ct_struct_lit_field_value(pool, base, pool.get_data1(node))
        if folded_value != 0:
            return ct_clone_tree_with_subst(pool, folded_value, 0, 0, 0, 0)
        return ct_new_node_copy(pool, kind, pool.get_start(node), pool.get_end(node), base, pool.get_data1(node), 0, pool.literal_suffix(node))

    if kind == NodeKind.NK_COMPUTED_FIELD_ACCESS:
        let base = ct_clone_tree_with_subst(pool, pool.get_data0(node), subst_sym, subst_node, index_sym, index_node)
        let field_expr = ct_clone_tree_with_subst(pool, pool.get_data1(node), subst_sym, subst_node, index_sym, index_node)
        return ct_new_node_copy(pool, kind, pool.get_start(node), pool.get_end(node), base, field_expr, 0, pool.literal_suffix(node))

    if kind == NodeKind.NK_INDEX:
        let base = ct_clone_tree_with_subst(pool, pool.get_data0(node), subst_sym, subst_node, index_sym, index_node)
        let index_expr = ct_clone_tree_with_subst(pool, pool.get_data1(node), subst_sym, subst_node, index_sym, index_node)
        return ct_new_node_copy(pool, kind, pool.get_start(node), pool.get_end(node), base, index_expr, 0, pool.literal_suffix(node))

    if kind == NodeKind.NK_SLICE:
        let base = ct_clone_tree_with_subst(pool, pool.get_data0(node), subst_sym, subst_node, index_sym, index_node)
        let start_node = ct_clone_tree_with_subst(pool, pool.get_data1(node), subst_sym, subst_node, index_sym, index_node)
        let end_node = ct_clone_tree_with_subst(pool, pool.get_data2(node), subst_sym, subst_node, index_sym, index_node)
        return ct_new_node_copy(pool, kind, pool.get_start(node), pool.get_end(node), base, start_node, end_node, pool.literal_suffix(node))

    if kind == NodeKind.NK_IF_EXPR:
        let cond = ct_clone_tree_with_subst(pool, pool.get_data0(node), subst_sym, subst_node, index_sym, index_node)
        let then_body = ct_clone_tree_with_subst(pool, pool.get_data1(node), subst_sym, subst_node, index_sym, index_node)
        let else_body = ct_clone_tree_with_subst(pool, pool.get_data2(node), subst_sym, subst_node, index_sym, index_node)
        return ct_new_node_copy(pool, kind, pool.get_start(node), pool.get_end(node), cond, then_body, else_body, pool.literal_suffix(node))

    if kind == NodeKind.NK_CALL or kind == NodeKind.NK_TUPLE or kind == NodeKind.NK_ARRAY_LIT or kind == NodeKind.NK_PAT_TUPLE or kind == NodeKind.NK_PAT_OR:
        let extra_start = if kind == NodeKind.NK_CALL: pool.get_data1(node) else: pool.get_data0(node)
        let count = if kind == NodeKind.NK_CALL: pool.get_data2(node) else: pool.get_data1(node)
        let cloned_items: Vec[i32] = Vec.new()
        for i in 0..count:
            let child = ct_clone_tree_with_subst(pool, pool.get_extra(extra_start + i), subst_sym, subst_node, index_sym, index_node)
            cloned_items.push(child)
        let new_extra = pool.extra_len()
        for i in 0..cloned_items.len() as i32:
            pool.add_extra(cloned_items.get(i as i64))
        if kind == NodeKind.NK_CALL:
            let callee = ct_clone_tree_with_subst(pool, pool.get_data0(node), subst_sym, subst_node, index_sym, index_node)
            return ct_new_node_copy(pool, kind, pool.get_start(node), pool.get_end(node), callee, new_extra, count, pool.literal_suffix(node))
        return ct_new_node_copy(pool, kind, pool.get_start(node), pool.get_end(node), new_extra, count, 0, pool.literal_suffix(node))

    if kind == NodeKind.NK_BLOCK:
        let extra_start = pool.get_data0(node)
        let stmt_count = pool.get_data1(node)
        let stmt_nodes: Vec[i32] = Vec.new()
        for i in 0..stmt_count:
            let stmt = ct_clone_tree_with_subst(pool, pool.get_extra(extra_start + i), subst_sym, subst_node, index_sym, index_node)
            stmt_nodes.push(stmt)
        let stmt_extra = pool.extra_len()
        for i in 0..stmt_nodes.len() as i32:
            pool.add_extra(stmt_nodes.get(i as i64))
        let tail = ct_clone_tree_with_subst(pool, pool.get_data2(node), subst_sym, subst_node, index_sym, index_node)
        return ct_new_node_copy(pool, kind, pool.get_start(node), pool.get_end(node), stmt_extra, stmt_count, tail, pool.literal_suffix(node))

    if kind == NodeKind.NK_LET_BINDING:
        let value = ct_clone_tree_with_subst(pool, pool.get_data1(node), subst_sym, subst_node, index_sym, index_node)
        let cloned = ct_new_node_copy(pool, kind, pool.get_start(node), pool.get_end(node), pool.get_data0(node), value, pool.get_data2(node), pool.literal_suffix(node))
        let ann_extra = pool.get_data2(node) / 2
        if ann_extra > 0:
            let new_ann_extra = pool.extra_len()
            pool.add_extra(pool.get_extra(ann_extra - 1))
            pool.set_data2(cloned, pool.get_data2(node) % 2 + (new_ann_extra + 1) * 2)
        return cloned

    if kind == NodeKind.NK_WHILE:
        let cond = ct_clone_tree_with_subst(pool, pool.get_data0(node), subst_sym, subst_node, index_sym, index_node)
        let body = ct_clone_tree_with_subst(pool, pool.get_data1(node), subst_sym, subst_node, index_sym, index_node)
        return ct_new_node_copy(pool, kind, pool.get_start(node), pool.get_end(node), cond, body, pool.get_data2(node), pool.literal_suffix(node))

    if kind == NodeKind.NK_LOOP:
        let body = ct_clone_tree_with_subst(pool, pool.get_data0(node), subst_sym, subst_node, index_sym, index_node)
        return ct_new_node_copy(pool, kind, pool.get_start(node), pool.get_end(node), body, pool.get_data1(node), 0, pool.literal_suffix(node))

    if kind == NodeKind.NK_FOR:
        let iterable = ct_clone_tree_with_subst(pool, pool.get_data1(node), subst_sym, subst_node, index_sym, index_node)
        let body = ct_clone_tree_with_subst(pool, pool.get_data2(node), subst_sym, subst_node, index_sym, index_node)
        let cloned = ct_new_node_copy(pool, kind, pool.get_start(node), pool.get_end(node), pool.get_data0(node), iterable, body, pool.literal_suffix(node))
        let for_meta = pool.find_for_meta(node)
        if for_meta >= 0:
            pool.add_for_meta(cloned as NodeId, pool.for_meta_index_binding(for_meta), pool.for_meta_label(for_meta))
        return cloned

    if kind == NodeKind.NK_BREAK:
        let value = ct_clone_tree_with_subst(pool, pool.get_data0(node), subst_sym, subst_node, index_sym, index_node)
        return ct_new_node_copy(pool, kind, pool.get_start(node), pool.get_end(node), value, pool.get_data1(node), 0, pool.literal_suffix(node))

    if kind == NodeKind.NK_MATCH:
        let extra_start = pool.get_data1(node)
        let arm_count = pool.get_data2(node)
        let arm_nodes: Vec[i32] = Vec.new()
        for i in 0..arm_count:
            let arm = ct_clone_tree_with_subst(pool, pool.get_extra(extra_start + i), subst_sym, subst_node, index_sym, index_node)
            arm_nodes.push(arm)
        let new_extra = pool.extra_len()
        for i in 0..arm_nodes.len() as i32:
            pool.add_extra(arm_nodes.get(i as i64))
        let subject = ct_clone_tree_with_subst(pool, pool.get_data0(node), subst_sym, subst_node, index_sym, index_node)
        return ct_new_node_copy(pool, kind, pool.get_start(node), pool.get_end(node), subject, new_extra, arm_count, pool.literal_suffix(node))

    if kind == NodeKind.NK_MATCH_ARM:
        let pat = ct_clone_tree_with_subst(pool, pool.get_data0(node), subst_sym, subst_node, index_sym, index_node)
        let body = ct_clone_tree_with_subst(pool, pool.get_data1(node), subst_sym, subst_node, index_sym, index_node)
        let guard = ct_clone_tree_with_subst(pool, pool.get_data2(node), subst_sym, subst_node, index_sym, index_node)
        return ct_new_node_copy(pool, kind, pool.get_start(node), pool.get_end(node), pat, body, guard, pool.literal_suffix(node))

    if kind == NodeKind.NK_STRUCT_LIT or kind == NodeKind.NK_RECORD_UPDATE:
        let extra_start = pool.get_data1(node)
        let field_count = pool.get_data2(node)
        let field_extras: Vec[i32] = Vec.new()
        for i in 0..field_count:
            let base = extra_start + i * 2
            field_extras.push(pool.get_extra(base))
            let value = ct_clone_tree_with_subst(pool, pool.get_extra(base + 1), subst_sym, subst_node, index_sym, index_node)
            field_extras.push(value)
        let new_extra = pool.extra_len()
        for i in 0..field_extras.len() as i32:
            pool.add_extra(field_extras.get(i as i64))
        let source = if kind == NodeKind.NK_RECORD_UPDATE: ct_clone_tree_with_subst(pool, pool.get_data0(node), subst_sym, subst_node, index_sym, index_node) else: pool.get_data0(node)
        return ct_new_node_copy(pool, kind, pool.get_start(node), pool.get_end(node), source, new_extra, field_count, pool.literal_suffix(node))

    if kind == NodeKind.NK_CAST:
        let expr = ct_clone_tree_with_subst(pool, pool.get_data0(node), subst_sym, subst_node, index_sym, index_node)
        return ct_new_node_copy(pool, kind, pool.get_start(node), pool.get_end(node), expr, pool.get_data1(node), 0, pool.literal_suffix(node))

    if kind == NodeKind.NK_RANGE:
        let start_node = ct_clone_tree_with_subst(pool, pool.get_data0(node), subst_sym, subst_node, index_sym, index_node)
        let end_node = ct_clone_tree_with_subst(pool, pool.get_data1(node), subst_sym, subst_node, index_sym, index_node)
        return ct_new_node_copy(pool, kind, pool.get_start(node), pool.get_end(node), start_node, end_node, pool.get_data2(node), pool.literal_suffix(node))

    if kind == NodeKind.NK_VARIANT_SHORTHAND:
        let arg_count = pool.get_data2(node)
        let extra_start = pool.get_data1(node)
        let arg_nodes: Vec[i32] = Vec.new()
        for i in 0..arg_count:
            let arg = ct_clone_tree_with_subst(pool, pool.get_extra(extra_start + i), subst_sym, subst_node, index_sym, index_node)
            arg_nodes.push(arg)
        let new_extra = pool.extra_len()
        for i in 0..arg_nodes.len() as i32:
            pool.add_extra(arg_nodes.get(i as i64))
        return ct_new_node_copy(pool, kind, pool.get_start(node), pool.get_end(node), pool.get_data0(node), new_extra, arg_count, pool.literal_suffix(node))

    if kind == NodeKind.NK_ENUM_VARIANT:
        let old_extra = pool.get_data2(node)
        let arg_count = pool.get_extra(old_extra)
        let arg_nodes: Vec[i32] = Vec.new()
        for i in 0..arg_count:
            let arg = ct_clone_tree_with_subst(pool, pool.get_extra(old_extra + 1 + i), subst_sym, subst_node, index_sym, index_node)
            arg_nodes.push(arg)
        let new_extra = pool.extra_len()
        pool.add_extra(arg_count)
        for i in 0..arg_nodes.len() as i32:
            pool.add_extra(arg_nodes.get(i as i64))
        return ct_new_node_copy(pool, kind, pool.get_start(node), pool.get_end(node), pool.get_data0(node), pool.get_data1(node), new_extra, pool.literal_suffix(node))

    if kind == NodeKind.NK_OPTIONAL_CHAIN:
        let old_extra = pool.get_data2(node)
        let has_args = pool.get_extra(old_extra)
        let arg_nodes: Vec[i32] = Vec.new()
        let arg_count = if has_args != 0: pool.get_extra(old_extra + 1) else: 0
        if has_args != 0:
            for i in 0..arg_count:
                let arg = ct_clone_tree_with_subst(pool, pool.get_extra(old_extra + 2 + i), subst_sym, subst_node, index_sym, index_node)
                arg_nodes.push(arg)
        let new_extra = pool.extra_len()
        pool.add_extra(has_args)
        if has_args != 0:
            pool.add_extra(arg_count)
            for i in 0..arg_nodes.len() as i32:
                pool.add_extra(arg_nodes.get(i as i64))
        let base = ct_clone_tree_with_subst(pool, pool.get_data0(node), subst_sym, subst_node, index_sym, index_node)
        return ct_new_node_copy(pool, kind, pool.get_start(node), pool.get_end(node), base, pool.get_data1(node), new_extra, pool.literal_suffix(node))

    if kind == NodeKind.NK_WITH_EXPR:
        let source = ct_clone_tree_with_subst(pool, pool.get_data0(node), subst_sym, subst_node, index_sym, index_node)
        let body = ct_clone_tree_with_subst(pool, pool.get_data1(node), subst_sym, subst_node, index_sym, index_node)
        return ct_new_node_copy(pool, kind, pool.get_start(node), pool.get_end(node), source, body, pool.get_data2(node), pool.literal_suffix(node))

    if kind == NodeKind.NK_WITH_IMPLICIT:
        let wi_source = ct_clone_tree_with_subst(pool, pool.get_data0(node), subst_sym, subst_node, index_sym, index_node)
        let wi_body = ct_clone_tree_with_subst(pool, pool.get_data1(node), subst_sym, subst_node, index_sym, index_node)
        return ct_new_node_copy(pool, kind, pool.get_start(node), pool.get_end(node), wi_source, wi_body, pool.get_data2(node), pool.literal_suffix(node))

    if kind == NodeKind.NK_LET_ELSE:
        let value = ct_clone_tree_with_subst(pool, pool.get_data1(node), subst_sym, subst_node, index_sym, index_node)
        let else_body = ct_clone_tree_with_subst(pool, pool.get_data2(node), subst_sym, subst_node, index_sym, index_node)
        return ct_new_node_copy(pool, kind, pool.get_start(node), pool.get_end(node), pool.get_data0(node), value, else_body, pool.literal_suffix(node))

    if kind == NodeKind.NK_TUPLE_DESTRUCTURE:
        let value = ct_clone_tree_with_subst(pool, pool.get_data2(node), subst_sym, subst_node, index_sym, index_node)
        let new_extra = pool.extra_len()
        let extra_start = pool.get_data0(node)
        let name_count = pool.get_data1(node)
        for i in 0..name_count:
            pool.add_extra(pool.get_extra(extra_start + i))
        return ct_new_node_copy(pool, kind, pool.get_start(node), pool.get_end(node), new_extra, name_count, value, pool.literal_suffix(node))

    if kind == NodeKind.NK_ARRAY_COMPREHENSION:
        let expr = ct_clone_tree_with_subst(pool, pool.get_data0(node), subst_sym, subst_node, index_sym, index_node)
        let iterable = ct_clone_tree_with_subst(pool, pool.get_data2(node), subst_sym, subst_node, index_sym, index_node)
        return ct_new_node_copy(pool, kind, pool.get_start(node), pool.get_end(node), expr, pool.get_data1(node), iterable, pool.literal_suffix(node))

    if kind == NodeKind.NK_ASYNC_SCOPE:
        let body = ct_clone_tree_with_subst(pool, pool.get_data1(node), subst_sym, subst_node, index_sym, index_node)
        return ct_new_node_copy(pool, kind, pool.get_start(node), pool.get_end(node), pool.get_data0(node), body, 0, pool.literal_suffix(node))

    if kind == NodeKind.NK_SELECT_AWAIT:
        let extra_start = pool.get_data0(node)
        let arm_count = pool.get_data1(node)
        let arm_extras: Vec[i32] = Vec.new()
        for i in 0..arm_count:
            let base = extra_start + i * 3
            arm_extras.push(pool.get_extra(base))
            let task_expr = ct_clone_tree_with_subst(pool, pool.get_extra(base + 1), subst_sym, subst_node, index_sym, index_node)
            let body = ct_clone_tree_with_subst(pool, pool.get_extra(base + 2), subst_sym, subst_node, index_sym, index_node)
            arm_extras.push(task_expr)
            arm_extras.push(body)
        let new_extra = pool.extra_len()
        for i in 0..arm_extras.len() as i32:
            pool.add_extra(arm_extras.get(i as i64))
        return ct_new_node_copy(pool, kind, pool.get_start(node), pool.get_end(node), new_extra, arm_count, 0, pool.literal_suffix(node))

    if kind == NodeKind.NK_FSTRING:
        let seg_count = pool.get_data0(node)
        let old_extra = pool.get_data1(node)
        let seg_extras: Vec[i32] = Vec.new()
        var pos = old_extra
        for _ in 0..seg_count:
            let seg_kind = pool.get_extra(pos)
            seg_extras.push(seg_kind)
            if seg_kind == FStringSegmentKind.EXPR:
                let expr_node = ct_clone_tree_with_subst(pool, pool.get_extra(pos + 1), subst_sym, subst_node, index_sym, index_node)
                let spec_node = ct_clone_tree_with_subst(pool, pool.get_extra(pos + 2), subst_sym, subst_node, index_sym, index_node)
                seg_extras.push(expr_node)
                seg_extras.push(spec_node)
                pos = pos + 3
            else:
                seg_extras.push(pool.get_extra(pos + 1))
                pos = pos + 2
        let new_extra = pool.extra_len()
        for i in 0..seg_extras.len() as i32:
            pool.add_extra(seg_extras.get(i as i64))
        return ct_new_node_copy(pool, kind, pool.get_start(node), pool.get_end(node), seg_count, new_extra, 0, pool.literal_suffix(node))

    if kind == NodeKind.NK_CLOSURE:
        let param_count = pool.get_data2(node)
        let old_extra = pool.get_data1(node)
        let new_extra = pool.extra_len()
        for i in 0..param_count:
            let base = old_extra + i * 2
            pool.add_extra(pool.get_extra(base))
            pool.add_extra(pool.get_extra(base + 1))
        let body = ct_clone_tree_with_subst(pool, pool.get_data0(node), subst_sym, subst_node, index_sym, index_node)
        let cloned = ct_new_node_copy(pool, kind, pool.get_start(node), pool.get_end(node), body, new_extra, param_count, pool.literal_suffix(node))
        if pool.is_move_closure(node) != 0:
            pool.mark_move_closure(cloned as NodeId)
        if pool.is_non_escaping_closure(node) != 0:
            pool.mark_non_escaping_closure(cloned as NodeId)
        return cloned

    ct_clone_leaf(pool, node)

fn ct_rewrite_comptime_for(source_ast: AstPool, pool: &mut AstPool, sema: &mut Sema, intern: &mut InternPool, diags: &mut DiagnosticList, wrapper: i32, inner: i32) -> i32:
    let iterable_node = pool.get_data1(inner)
    let evald = comptime_force_eval_expr_result(sema as *mut Sema, diags, source_ast, sema.pool, iterable_node)
    let iterable = evald.value
    if comptime_value_is_valid(iterable) == 0:
        return wrapper

    let iter_count = ct_iter_count(iterable)
    if iter_count < 0:
        ct_emit_error(sema, diags, source_ast, iterable_node, "comptime for requires an array, tuple, or range")
        return wrapper

    let template_body = ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_data2(inner))
    let stmt_nodes: Vec[i32] = Vec.new()
    let binding = pool.get_data0(inner)
    let for_meta = pool.find_for_meta(inner)
    let index_binding = if for_meta >= 0: pool.for_meta_index_binding(for_meta) else: 0
    for i in 0..iter_count:
        let item_node = ct_iter_item_node(pool, intern, sema, iterable, i, wrapper, evald.extras)
        if item_node == 0:
            ct_emit_error(sema, diags, source_ast, inner, "failed to materialize comptime for item")
            return wrapper
        var index_node = 0
        if index_binding != 0:
            let index_value = comptime_value_int(sema.ty_i64 as i32, i as i64)
            let empty_values: Vec[ComptimeValue] = Vec.new()
            index_node = ct_build_value_tree(pool, intern, sema, index_value, wrapper, empty_values)
        let cloned_body = ct_clone_tree_with_subst(pool, template_body, binding, item_node, index_binding, index_node)
        let eval_ast = unsafe: *pool
        stmt_nodes.push(ct_transform_expr(eval_ast, pool, sema, intern, diags, cloned_body))
    let stmt_extra = pool.extra_len()
    for i in 0..stmt_nodes.len() as i32:
        pool.add_extra(stmt_nodes.get(i as i64))
    pool.add_node(NodeKind.NK_BLOCK, pool.get_start(wrapper), pool.get_end(wrapper), stmt_extra, iter_count, 0) as i32

fn ct_rewrite_comptime(source_ast: AstPool, pool: &mut AstPool, sema: &mut Sema, intern: &mut InternPool, diags: &mut DiagnosticList, node: i32) -> i32:
    let inner = pool.get_data0(node)
    if inner == 0:
        return ct_empty_block(pool, node)
    let inner_kind = pool.kind(inner)
    if inner_kind == NodeKind.NK_IF_EXPR:
        return ct_rewrite_comptime_if(source_ast, pool, sema, intern, diags, node, inner)
    if inner_kind == NodeKind.NK_FOR:
        return ct_rewrite_comptime_for(source_ast, pool, sema, intern, diags, node, inner)

    let diag_count_before = diags.count()
    let evald = comptime_force_eval_expr_result(sema as *mut Sema, diags, source_ast, sema.pool, inner)
    let value = evald.value
    if comptime_value_is_valid(value) == 0:
        if evald.error_msg.len() > 0 and diags.count() == diag_count_before:
            ct_emit_error(sema, diags, source_ast, inner, evald.error_msg)
        return node
    let folded = ct_build_value_tree(pool, intern, sema, value, node, evald.extras)
    if folded == 0:
        ct_emit_error(sema, diags, source_ast, inner, "comptime value cannot be embedded yet")
        return node
    folded

fn ct_transform_expr(source_ast: AstPool, pool: &mut AstPool, sema: &mut Sema, intern: &mut InternPool, diags: &mut DiagnosticList, node: i32) -> i32:
    if node == 0:
        return 0
    let kind = pool.kind(node)

    if kind == NodeKind.NK_COMPTIME:
        return ct_rewrite_comptime(source_ast, pool, sema, intern, diags, node)

    if kind == NodeKind.NK_BINARY:
        pool.set_data1(node, ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_data1(node)))
        pool.set_data2(node, ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_data2(node)))
        return node

    if kind == NodeKind.NK_UNARY:
        pool.set_data1(node, ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_data1(node)))
        return node

    if kind == NodeKind.NK_GROUPED or kind == NodeKind.NK_RETURN or kind == NodeKind.NK_DEFER or kind == NodeKind.NK_ERRDEFER or kind == NodeKind.NK_AWAIT or kind == NodeKind.NK_ASYNC_BLOCK or kind == NodeKind.NK_SPAWN or kind == NodeKind.NK_YIELD:
        pool.set_data0(node, ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_data0(node)))
        return node

    if kind == NodeKind.NK_CALL:
        pool.set_data0(node, ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_data0(node)))
        let extra_start = pool.get_data1(node)
        let arg_count = pool.get_data2(node)
        for i in 0..arg_count:
            let arg_idx = extra_start + i
            pool.extra.set_i32(arg_idx as i64, ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_extra(arg_idx)))
        return ct_try_fold_type_call(pool, sema, intern, diags, node)

    if kind == NodeKind.NK_FIELD_ACCESS:
        let base = ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_data0(node))
        pool.set_data0(node, base)
        let folded_value = ct_struct_lit_field_value(pool, base, pool.get_data1(node))
        if folded_value != 0:
            return ct_clone_tree_with_subst(pool, folded_value, 0, 0, 0, 0)
        return node

    if kind == NodeKind.NK_COMPUTED_FIELD_ACCESS:
        let base = ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_data0(node))
        let field_expr = ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_data1(node))
        pool.set_data0(node, base)
        pool.set_data1(node, field_expr)
        let eval_ast = unsafe: *pool
        let evald = comptime_try_eval_expr_result(sema as *mut Sema, diags, eval_ast, sema.pool, field_expr)
        if comptime_value_is_valid(evald.value) == 0:
            return node
        if evald.value.kind != ComptimeValueKind.CV_STR:
            ct_emit_error(sema, diags, source_ast, node, "computed field access requires comptime string field name")
            return node
        let field_sym = intern.intern(evald.value.text)
        return pool.add_node(NodeKind.NK_FIELD_ACCESS, pool.get_start(node), pool.get_end(node), base, field_sym, 0) as i32

    if kind == NodeKind.NK_INDEX:
        pool.set_data0(node, ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_data0(node)))
        pool.set_data1(node, ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_data1(node)))
        return node

    if kind == NodeKind.NK_SLICE:
        pool.set_data0(node, ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_data0(node)))
        if pool.get_data1(node) != 0:
            pool.set_data1(node, ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_data1(node)))
        if pool.get_data2(node) != 0:
            pool.set_data2(node, ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_data2(node)))
        return node

    if kind == NodeKind.NK_BLOCK:
        let extra_start = pool.get_data0(node)
        let stmt_count = pool.get_data1(node)
        for i in 0..stmt_count:
            let stmt_idx = extra_start + i
            pool.extra.set_i32(stmt_idx as i64, ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_extra(stmt_idx)))
        if pool.get_data2(node) != 0:
            pool.set_data2(node, ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_data2(node)))
        return node

    if kind == NodeKind.NK_LET_BINDING:
        pool.set_data1(node, ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_data1(node)))
        return node

    if kind == NodeKind.NK_IF_EXPR:
        pool.set_data0(node, ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_data0(node)))
        pool.set_data1(node, ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_data1(node)))
        if pool.get_data2(node) != 0:
            pool.set_data2(node, ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_data2(node)))
        return node

    if kind == NodeKind.NK_ASSIGN:
        pool.set_data0(node, ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_data0(node)))
        pool.set_data1(node, ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_data1(node)))
        return node

    if kind == NodeKind.NK_WHILE:
        pool.set_data0(node, ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_data0(node)))
        pool.set_data1(node, ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_data1(node)))
        return node

    if kind == NodeKind.NK_LOOP:
        pool.set_data0(node, ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_data0(node)))
        return node

    if kind == NodeKind.NK_FOR:
        pool.set_data1(node, ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_data1(node)))
        pool.set_data2(node, ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_data2(node)))
        return node

    if kind == NodeKind.NK_BREAK:
        if pool.get_data0(node) != 0:
            pool.set_data0(node, ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_data0(node)))
        return node

    if kind == NodeKind.NK_MATCH:
        pool.set_data0(node, ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_data0(node)))
        let extra_start = pool.get_data1(node)
        let arm_count = pool.get_data2(node)
        for i in 0..arm_count:
            let arm_idx = extra_start + i
            let arm = pool.get_extra(arm_idx)
            ct_transform_match_arm(source_ast, pool, sema, intern, diags, arm)
            pool.extra.set_i32(arm_idx as i64, arm)
        return node

    if kind == NodeKind.NK_TUPLE or kind == NodeKind.NK_ARRAY_LIT or kind == NodeKind.NK_PAT_TUPLE or kind == NodeKind.NK_PAT_OR:
        let extra_start = pool.get_data0(node)
        let count = pool.get_data1(node)
        for i in 0..count:
            let idx = extra_start + i
            pool.extra.set_i32(idx as i64, ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_extra(idx)))
        return node

    if kind == NodeKind.NK_STRUCT_LIT or kind == NodeKind.NK_RECORD_UPDATE:
        if kind == NodeKind.NK_RECORD_UPDATE:
            pool.set_data0(node, ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_data0(node)))
        let extra_start = pool.get_data1(node)
        let field_count = pool.get_data2(node)
        for i in 0..field_count:
            let value_idx = extra_start + i * 2 + 1
            pool.extra.set_i32(value_idx as i64, ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_extra(value_idx)))
        return node

    if kind == NodeKind.NK_CLOSURE:
        pool.set_data0(node, ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_data0(node)))
        return node

    if kind == NodeKind.NK_CAST:
        pool.set_data0(node, ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_data0(node)))
        return node

    if kind == NodeKind.NK_PIPELINE:
        pool.set_data0(node, ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_data0(node)))
        pool.set_data1(node, ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_data1(node)))
        return node

    if kind == NodeKind.NK_RANGE:
        if pool.get_data0(node) != 0:
            pool.set_data0(node, ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_data0(node)))
        if pool.get_data1(node) != 0:
            pool.set_data1(node, ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_data1(node)))
        return node

    if kind == NodeKind.NK_FSTRING:
        ct_transform_fstring(source_ast, pool, sema, intern, diags, node)
        return node

    if kind == NodeKind.NK_VARIANT_SHORTHAND:
        let extra_start = pool.get_data1(node)
        let arg_count = pool.get_data2(node)
        for i in 0..arg_count:
            let idx = extra_start + i
            pool.extra.set_i32(idx as i64, ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_extra(idx)))
        return node

    if kind == NodeKind.NK_WITH_EXPR:
        pool.set_data0(node, ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_data0(node)))
        pool.set_data1(node, ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_data1(node)))
        return node

    if kind == NodeKind.NK_WITH_IMPLICIT:
        pool.set_data0(node, ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_data0(node)))
        pool.set_data1(node, ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_data1(node)))
        return node

    if kind == NodeKind.NK_ENUM_VARIANT:
        let old_extra = pool.get_data2(node)
        let arg_count = pool.get_extra(old_extra)
        for i in 0..arg_count:
            let idx = old_extra + 1 + i
            pool.extra.set_i32(idx as i64, ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_extra(idx)))
        return node

    if kind == NodeKind.NK_OPTIONAL_CHAIN:
        pool.set_data0(node, ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_data0(node)))
        let extra_start = pool.get_data2(node)
        if pool.get_extra(extra_start) != 0:
            let arg_count = pool.get_extra(extra_start + 1)
            for i in 0..arg_count:
                let idx = extra_start + 2 + i
                pool.extra.set_i32(idx as i64, ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_extra(idx)))
        return node

    if kind == NodeKind.NK_LET_ELSE:
        pool.set_data1(node, ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_data1(node)))
        pool.set_data2(node, ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_data2(node)))
        return node

    if kind == NodeKind.NK_TUPLE_DESTRUCTURE:
        pool.set_data2(node, ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_data2(node)))
        return node

    if kind == NodeKind.NK_ARRAY_COMPREHENSION:
        pool.set_data0(node, ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_data0(node)))
        pool.set_data2(node, ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_data2(node)))
        return node

    if kind == NodeKind.NK_ASYNC_SCOPE:
        pool.set_data1(node, ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_data1(node)))
        return node

    if kind == NodeKind.NK_SELECT_AWAIT:
        let extra_start = pool.get_data0(node)
        let arm_count = pool.get_data1(node)
        for i in 0..arm_count:
            let base = extra_start + i * 3
            pool.extra.set_i32((base + 1) as i64, ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_extra(base + 1)))
            pool.extra.set_i32((base + 2) as i64, ct_transform_expr(source_ast, pool, sema, intern, diags, pool.get_extra(base + 2)))
        return node

    node

fn ct_transform_fn_param_defaults(source_ast: AstPool, pool: &mut AstPool, sema: &mut Sema, intern: &mut InternPool, diags: &mut DiagnosticList, fn_node: i32):
    let meta = pool.find_fn_meta(fn_node)
    if meta < 0:
        return
    let param_start = pool.fn_meta_param_start(meta)
    let param_count = pool.fn_meta_param_count(meta)
    for pi in 0..param_count:
        let default_node = pool.get_fn_param_default(param_start, pi)
        if default_node == 0:
            continue
        pool.set_fn_param_default(param_start, pi, ct_transform_expr(source_ast, pool, sema, intern, diags, default_node))

fn ct_transform_trait_decl(source_ast: AstPool, pool: &mut AstPool, sema: &mut Sema, intern: &mut InternPool, diags: &mut DiagnosticList, node: i32):
    var pos = pool.get_data1(node)
    let _tp_count = pool.get_extra(pos)
    pos = pos + 1
    let _tp_start = pool.get_extra(pos)
    pos = pos + 1
    let assoc_count = pool.get_extra(pos)
    pos = pos + 1
    for _ in 0..assoc_count:
        let bound_count = pool.get_extra(pos + 1)
        pos = pos + 3 + bound_count
    let method_count = pool.get_extra(pos)
    pos = pos + 1
    for _ in 0..method_count:
        let param_start = pool.get_extra(pos + 2)
        let param_count = pool.get_extra(pos + 3)
        let body_idx = pos + 5
        let body = pool.get_extra(body_idx)
        if body != 0:
            pool.extra.set_i32(body_idx as i64, ct_transform_expr(source_ast, pool, sema, intern, diags, body))
        for pi in 0..param_count:
            let default_node = pool.get_fn_param_default(param_start, pi)
            if default_node != 0:
                pool.set_fn_param_default(param_start, pi, ct_transform_expr(source_ast, pool, sema, intern, diags, default_node))
        pos = pos + 6

fn ct_transform_type_decl(source_ast: AstPool, pool: &mut AstPool, sema: &mut Sema, intern: &mut InternPool, diags: &mut DiagnosticList, node: i32):
    let packed = pool.get_data2(node)
    let sub_kind = type_decl_sub_kind(packed)
    if sub_kind != TypeDeclKind.Struct and sub_kind != TypeDeclKind.Union:
        return
    let extra_start = pool.get_data1(node)
    let field_count = pool.get_extra(extra_start)
    for fi in 0..field_count:
        let default_idx = extra_start + 1 + fi * 3 + 2
        let field_default = pool.get_extra(default_idx)
        if field_default != 0:
            pool.extra.set_i32(default_idx as i64, ct_transform_expr(source_ast, pool, sema, intern, diags, field_default))

fn ct_decl_source_path(sema: &mut Sema, di: i32) -> str:
    if di >= 0 and di < sema.decl_source_paths.len() as i32:
        return sema.decl_source_paths.get(di as i64)
    ""

fn ct_decl_source_file_id(sema: &mut Sema, di: i32) -> i32:
    if di >= 0 and di < sema.decl_source_file_ids.len() as i32:
        return sema.decl_source_file_ids.get(di as i64)
    0

fn ct_decl_is_c_import(sema: &mut Sema, di: i32) -> i32:
    if di >= 0 and di < sema.decl_is_c_import.len() as i32:
        return sema.decl_is_c_import.get(di as i64)
    0

fn ct_source_decl_is_local(ast: AstPool, decl_index: i32) -> i32:
    let limit = ast.local_decl_count()
    if limit < 0:
        return 1
    let total = ast.decl_count()
    if decl_index >= total - limit:
        return 1
    0

fn ct_transform_decl(source_ast: AstPool, pool: &mut AstPool, sema: &mut Sema, intern: &mut InternPool, diags: &mut DiagnosticList, node: i32):
    let kind = pool.kind(node)
    if kind == NodeKind.NK_FN_DECL:
        let body = pool.get_data1(node)
        if body != 0:
            pool.set_data1(node, ct_transform_expr(source_ast, pool, sema, intern, diags, body))
        ct_transform_fn_param_defaults(source_ast, pool, sema, intern, diags, node)
        return
    if kind == NodeKind.NK_LET_DECL:
        let value = pool.get_data1(node)
        if value != 0:
            pool.set_data1(node, ct_transform_expr(source_ast, pool, sema, intern, diags, value))
        return
    if kind == NodeKind.NK_TYPE_DECL:
        ct_transform_type_decl(source_ast, pool, sema, intern, diags, node)
        return
    if kind == NodeKind.NK_TRAIT_DECL:
        ct_transform_trait_decl(source_ast, pool, sema, intern, diags, node)
        return

fn comptime_transform_module(source_ast: AstPool, sema: &mut Sema, intern: &mut InternPool) -> AstPool:
    var out = astpool_clone_deep(source_ast)

    let clone_trait_sym = intern.intern("Clone")
    let clone_method_sym = intern.intern("clone")
    let self_sym = intern.intern("self")
    let self_type_sym = intern.intern("Self")

    let ordered: Vec[i32] = Vec.new()
    let ordered_paths: Vec[str] = Vec.new()
    let ordered_file_ids: Vec[i32] = Vec.new()
    let ordered_ci: Vec[i32] = Vec.new()
    let base_decl_count = out.decl_count()
    var generated_local_count = 0

    for di in 0..base_decl_count:
        let decl = out.get_decl(di)
        let decl_path = ct_decl_source_path(sema, di)
        let decl_file_id = ct_decl_source_file_id(sema, di)
        let decl_ci = ct_decl_is_c_import(sema, di)

        ordered.push(decl as i32)
        ordered_paths.push(decl_path)
        ordered_file_ids.push(decl_file_id)
        ordered_ci.push(decl_ci)

        if out.kind(decl) != NodeKind.NK_TYPE_DECL:
            continue
        if sema.type_decl_has_derive(decl as i32, clone_trait_sym) == 0:
            continue
        if type_decl_sub_kind(out.get_data2(decl)) != TypeDeclKind.Struct:
            continue

        let type_name_sym = out.get_data0(decl)
        if sema.lookup_method_sig(type_name_sym, clone_method_sym) >= 0:
            continue
        if sema.select_trait_impl(type_name_sym, clone_trait_sym) != 0:
            continue

        let type_name = intern.resolve(type_name_sym)
        let fn_sym = intern.intern(type_name ++ ".clone")
        let start = out.get_start(decl)
        let end = out.get_end(decl)

        let self_ident = out.add_node(NodeKind.NK_IDENT, start, end, self_sym, 0, 0)
        let self_pointee_type = out.add_node(NodeKind.NK_TYPE_NAMED, start, end, self_type_sym, 0, 0)
        let self_param_type = out.add_node(NodeKind.NK_TYPE_REF, start, end, self_pointee_type as i32, 0, 0)
        let ret_type = out.add_node(NodeKind.NK_TYPE_NAMED, start, end, self_type_sym, 0, 0)
        let body = out.add_node(NodeKind.NK_UNARY, start, end, UnaryOp.UOP_DEREF, self_ident as i32, 0)
        let param_start = out.extra_len()
        out.add_extra(self_sym)
        out.add_extra(self_param_type as i32)
        out.add_extra(0)

        let fn_node = out.add_node(NodeKind.NK_FN_DECL, start, end, fn_sym, body as i32, 0)
        out.add_fn_meta(fn_node, 0, ret_type as i32, param_start, 1, 0, 0)

        let impl_extra = out.extra_len()
        out.add_extra(0)
        out.add_extra(1)
        let impl_node = out.add_node(NodeKind.NK_IMPL_DECL, start, end, type_name_sym, impl_extra, clone_trait_sym)

        ordered.push(fn_node as i32)
        ordered_paths.push(decl_path)
        ordered_file_ids.push(decl_file_id)
        ordered_ci.push(decl_ci)
        ordered.push(impl_node as i32)
        ordered_paths.push(decl_path)
        ordered_file_ids.push(decl_file_id)
        ordered_ci.push(decl_ci)

        if ct_source_decl_is_local(source_ast, di) != 0:
            generated_local_count = generated_local_count + 2
    while out.decl_count() > 0:
        out.decls.pop()
    for oi in 0..ordered.len() as i32:
        out.add_decl(ordered.get(oi as i64))

    let local_limit = source_ast.local_decl_count()
    if local_limit >= 0:
        out.set_local_decl_count(local_limit + generated_local_count)

    sema.decl_source_paths = ordered_paths
    sema.decl_source_file_ids = ordered_file_ids
    sema.decl_is_c_import = ordered_ci

    let transform_pool = unsafe: *intern
    var transform_sema = Sema.init(transform_pool, sema.diags, out)
    transform_sema.source_text = sema.source_text
    transform_sema.decl_source_paths = sema.decl_source_paths
    transform_sema.decl_source_file_ids = sema.decl_source_file_ids
    transform_sema.decl_is_c_import = sema.decl_is_c_import
    transform_sema.module_paths = sema.module_paths
    transform_sema.module_import_starts = sema.module_import_starts
    transform_sema.module_import_counts = sema.module_import_counts
    transform_sema.module_import_targets = sema.module_import_targets
    transform_sema.module_index_by_path = sema.module_index_by_path
    transform_sema.global_visible_module_paths = sema.global_visible_module_paths
    transform_sema.module_visibility_cache = HashMap.new()
    transform_sema.prepare_for_comptime_transform()
    if transform_sema.diags.has_errors():
        sema.diags = transform_sema.diags
        return out

    for di in 0..out.decl_count():
        transform_sema.update_decl_source_context(di)
        let decl = out.get_decl(di)
        let live_ast = out
        ct_transform_decl(live_ast, &mut out, &mut transform_sema, intern, &mut transform_sema.diags, decl as i32)
    sema.diags = transform_sema.diags
    out
