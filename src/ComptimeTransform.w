use Ast
use ComptimeEval
use ComptimeValue
use Diagnostic
use InternPool
use Sema
use SemaCheck
use Span

fn Sema.ct_emit_error(mut self: Sema, ast: AstPool, node: i32, msg: str):
    let start = ast.get_start(node)
    let end = ast.get_end(node)
    self.diags.emit(Diagnostic.err(msg, Span { file: self.local_file_id, start, end }))

fn astpool_clone_deep(src: AstPool) -> AstPool:
    var out = AstPool.new()

    for si in 0..src.state.strings.len() as i32:
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
        if src.has_int_literal_exact(src_node):
            out.set_int_literal_exact(node, src.int_literal_digit_idx(src_node), src.int_literal_radix(src_node))

    for di in 0..src.decl_count():
        out.add_decl(src.get_decl(di))
    out.set_local_decl_count(src.local_decl_count())
    out.set_prelude_decl_count(src.prelude_decl_count())

    var fn_meta = 0
    while fn_meta < src.state.fn_meta.len() as i32:
        out.add_fn_meta(
            (src.state.fn_meta.get(fn_meta as i64)) as NodeId,
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
    while type_meta < src.state.type_meta.len() as i32:
        out.add_type_meta(
            (src.state.type_meta.get(type_meta as i64)) as NodeId,
            src.type_meta_derive_start(type_meta),
            src.type_meta_derive_count(type_meta)
        )
        type_meta = type_meta + 3

    var patq = 0
    while patq < src.state.pattern_qualifiers.len() as i32:
        out.add_pattern_qualifier(
            (src.state.pattern_qualifiers.get(patq as i64)) as NodeId,
            src.state.pattern_qualifiers.get((patq + 1) as i64)
        )
        patq = patq + 2

    for pi in 0..src.fn_param_patterns_len():
        out.add_fn_param_pattern_value(src.fn_param_pattern_value(pi))

    var pmeta = 0
    while pmeta < src.state.fn_param_pattern_meta.len() as i32:
        out.add_fn_param_pattern_meta(
            (src.state.fn_param_pattern_meta.get(pmeta as i64)) as NodeId,
            src.fn_param_pattern_meta_start(pmeta),
            src.fn_param_pattern_meta_count(pmeta)
        )
        pmeta = pmeta + 3

    var for_meta = 0
    while for_meta < src.state.for_meta.len() as i32:
        out.add_for_meta(
            (src.state.for_meta.get(for_meta as i64)) as NodeId,
            src.for_meta_index_binding(for_meta),
            src.for_meta_label(for_meta)
        )
        for_meta = for_meta + 3

    var block_meta = 0
    while block_meta < src.state.block_meta.len() as i32:
        out.add_block_meta(
            (src.state.block_meta.get(block_meta as i64)) as NodeId,
            src.block_meta_label(block_meta)
        )
        block_meta = block_meta + 2

    for mi in 0..src.state.must_use_type_nodes.len() as i32:
        out.mark_must_use_type((src.state.must_use_type_nodes.get(mi as i64)) as NodeId)
    for si in 0..src.state.sealed_trait_nodes.len() as i32:
        out.mark_sealed_trait((src.state.sealed_trait_nodes.get(si as i64)) as NodeId)
    for ci in 0..src.state.comptime_decl_nodes.len() as i32:
        out.mark_comptime_decl((src.state.comptime_decl_nodes.get(ci as i64)) as NodeId)
    for hi in 0..src.compiler_hook_count():
        out.mark_compiler_hook_fn(src.compiler_hook_node(hi), src.compiler_hook_phase_at(hi))
    for mi in 0..src.state.move_closure_nodes.len() as i32:
        out.mark_move_closure((src.state.move_closure_nodes.get(mi as i64)) as NodeId)
    for ni in 0..src.state.non_escaping_closure_nodes.len() as i32:
        out.mark_non_escaping_closure((src.state.non_escaping_closure_nodes.get(ni as i64)) as NodeId)

    var where_meta = 0
    while where_meta < src.state.where_meta.len() as i32:
        out.add_where_meta(
            (src.state.where_meta.get(where_meta as i64)) as NodeId,
            src.state.where_meta.get((where_meta + 1) as i64),
            src.state.where_meta.get((where_meta + 2) as i64)
        )
        where_meta = where_meta + 3

    var impl_tp = 0
    while impl_tp < src.state.impl_type_params.len() as i32:
        out.add_impl_type_params(
            (src.state.impl_type_params.get(impl_tp as i64)) as NodeId,
            src.state.impl_type_params.get((impl_tp + 1) as i64),
            src.state.impl_type_params.get((impl_tp + 2) as i64)
        )
        impl_tp = impl_tp + 3

    var impl_target = 0
    while impl_target < src.state.impl_target_type_nodes.len() as i32:
        out.add_impl_target_type_node(
            (src.state.impl_target_type_nodes.get(impl_target as i64)) as NodeId,
            (src.state.impl_target_type_nodes.get((impl_target + 1) as i64)) as NodeId
        )
        impl_target = impl_target + 2

    var impl_trait_args = 0
    while impl_trait_args < src.state.impl_trait_type_args.len() as i32:
        out.add_impl_trait_type_args(
            (src.state.impl_trait_type_args.get(impl_trait_args as i64)) as NodeId,
            src.state.impl_trait_type_args.get((impl_trait_args + 1) as i64),
            src.state.impl_trait_type_args.get((impl_trait_args + 2) as i64)
        )
        impl_trait_args = impl_trait_args + 3

    for ni in 1..src.node_count():
        let node = ni as NodeId
        if src.has_call_named_args(node) != 0:
            out.set_call_named_args(node, src.state.call_named_args.get(ni).unwrap())
        if src.state.fn_stack_sizes.contains(ni):
            out.state.fn_stack_sizes.insert(ni, src.state.fn_stack_sizes.get(ni).unwrap())
        if src.state.fn_weak_flags.contains(ni):
            out.state.fn_weak_flags.insert(ni, src.state.fn_weak_flags.get(ni).unwrap())
        if src.state.fn_effect_pin_params.contains(ni):
            out.state.fn_effect_pin_params.insert(ni, src.state.fn_effect_pin_params.get(ni).unwrap())
            out.state.fn_effect_pin_bits.insert(ni, src.state.fn_effect_pin_bits.get(ni).unwrap())

    out

fn AstPool.ct_new_node_copy(self: AstPool, kind: i32, start: i32, end: i32, d0: i32, d1: i32, d2: i32, suffix: i32) -> i32:
    let node = self.add_node(kind, start, end, d0, d1, d2)
    self.set_literal_suffix(node, suffix)
    node as i32

fn AstPool.ct_clone_leaf(self: AstPool, node: i32) -> i32:
    let cloned = self.ct_new_node_copy(
        self.kind(node),
        self.get_start(node),
        self.get_end(node),
        self.get_data0(node),
        self.get_data1(node),
        self.get_data2(node),
        self.literal_suffix(node)
    )
    if self.has_int_literal_exact(node):
        self.set_int_literal_exact(cloned as NodeId, self.int_literal_digit_idx(node), self.int_literal_radix(node))
    cloned

fn AstPool.ct_empty_block(self: AstPool, node: i32) -> i32:
    self.add_node(NodeKind.NK_BLOCK, self.get_start(node), self.get_end(node), self.extra_len(), 0, 0) as i32

fn ct_fresh_sym(intern: InternPool, prefix: str, seed: i32) -> i32:
    intern.intern(prefix ++ f"{seed}" ++ "_" ++ f"{intern.symbol_count() + 1}")

fn Sema.ct_build_type_expr(self: Sema, pool: AstPool, intern: InternPool, type_id: i32, node: i32) -> i32:
    let resolved = self.resolve_alias(type_id)
    let start = pool.get_start(node)
    let end = pool.get_end(node)
    let tk = self.get_type_kind(resolved)

    if tk == TypeKind.TY_GENERIC_INST:
        let base_sym = intern.intern(self.pool_resolve(self.get_type_d0(resolved)))
        let extra_start = self.get_type_d1(resolved)
        let arg_count = self.get_type_d2(resolved)
        let arg_nodes: Vec[i32] = Vec.new()
        for ai in 0..arg_count:
            let arg_tid = self.type_extra.get((extra_start + ai) as i64)
            let arg_node = self.ct_build_type_expr(pool, intern, arg_tid, node)
            if arg_node == 0:
                return 0
            arg_nodes.push(arg_node)
        let new_extra = pool.extra_len()
        for ai in 0..arg_nodes.len() as i32:
            pool.add_extra(arg_nodes.get(ai as i64))
        return pool.add_node(NodeKind.NK_TYPE_GENERIC, start, end, base_sym, new_extra, arg_count) as i32

    if tk == TypeKind.TY_ARRAY:
        let elem_node = self.ct_build_type_expr(pool, intern, self.get_type_d0(resolved), node)
        if elem_node == 0:
            return 0
        return pool.add_node(NodeKind.NK_TYPE_ARRAY, start, end, elem_node, self.get_type_d1(resolved), 0) as i32

    if tk == TypeKind.TY_SLICE:
        let elem_node = self.ct_build_type_expr(pool, intern, self.get_type_d0(resolved), node)
        if elem_node == 0:
            return 0
        return pool.add_node(NodeKind.NK_TYPE_SLICE, start, end, elem_node, 0, 0) as i32

    if tk == TypeKind.TY_TUPLE:
        let extra_start = self.get_type_d0(resolved)
        let elem_count = self.get_type_d1(resolved)
        let elem_nodes: Vec[i32] = Vec.new()
        for ei in 0..elem_count:
            let elem_tid = self.type_extra.get((extra_start + ei) as i64)
            let elem_node = self.ct_build_type_expr(pool, intern, elem_tid, node)
            if elem_node == 0:
                return 0
            elem_nodes.push(elem_node)
        let new_extra = pool.extra_len()
        for ei in 0..elem_nodes.len() as i32:
            pool.add_extra(elem_nodes.get(ei as i64))
        return pool.add_node(NodeKind.NK_TYPE_TUPLE, start, end, new_extra, elem_count, 0) as i32

    if tk == TypeKind.TY_PTR:
        let pointee = self.ct_build_type_expr(pool, intern, self.get_type_d0(resolved), node)
        if pointee == 0:
            return 0
        return pool.add_node(NodeKind.NK_TYPE_PTR, start, end, pointee, self.get_type_d1(resolved), self.get_type_d2(resolved)) as i32

    if tk == TypeKind.TY_REF:
        let pointee = self.ct_build_type_expr(pool, intern, self.get_type_d0(resolved), node)
        if pointee == 0:
            return 0
        return pool.add_node(NodeKind.NK_TYPE_REF, start, end, pointee, self.get_type_d1(resolved), 0) as i32

    if tk == TypeKind.TY_FN:
        let param_start = self.get_type_d0(resolved)
        let param_count = self.get_type_d1(resolved)
        let param_nodes: Vec[i32] = Vec.new()
        for pi in 0..param_count:
            let param_tid = self.type_extra.get((param_start + pi) as i64)
            let param_node = self.ct_build_type_expr(pool, intern, param_tid, node)
            if param_node == 0:
                return 0
            param_nodes.push(param_node)
        let new_extra = pool.extra_len()
        for pi in 0..param_nodes.len() as i32:
            pool.add_extra(param_nodes.get(pi as i64))
        let ret_node = self.ct_build_type_expr(pool, intern, self.get_type_d2(resolved), node)
        if ret_node == 0:
            return 0
        return pool.add_node(NodeKind.NK_TYPE_FN, start, end, new_extra, param_count, ret_node) as i32

    if tk == TypeKind.TY_TRAIT_OBJ:
        let trait_sym = intern.intern(self.pool_resolve(self.get_type_d0(resolved)))
        return pool.add_node(NodeKind.NK_TYPE_TRAIT_OBJ, start, end, trait_sym, TYPE_TRAIT_OBJECT_DYN, 0) as i32

    let type_sym = intern.intern(self.type_name(type_id))
    pool.add_node(NodeKind.NK_TYPE_NAMED, start, end, type_sym, 0, 0) as i32

fn AstPool.ct_build_call(self: AstPool, node: i32, callee: i32, args: Vec[i32]) -> i32:
    let extra_start = self.extra_len()
    for ai in 0..args.len() as i32:
        self.add_extra(args.get(ai as i64))
    self.add_node(NodeKind.NK_CALL, self.get_start(node), self.get_end(node), callee, extra_start, args.len() as i32) as i32

fn Sema.ct_build_collection_ctor(self: Sema, pool: AstPool, intern: InternPool, type_id: i32, node: i32) -> i32:
    let type_node = self.ct_build_type_expr(pool, intern, type_id, node)
    if type_node == 0:
        return 0
    let new_sym = intern.intern("new")
    let callee = pool.add_node(NodeKind.NK_FIELD_ACCESS, pool.get_start(node), pool.get_end(node), type_node, new_sym, 0)
    let no_args: Vec[i32] = Vec.new()
    pool.ct_build_call(node, callee as i32, no_args)

fn Sema.ct_build_typed_binding(self: Sema, pool: AstPool, intern: InternPool, name_sym: i32, value: i32, type_id: i32, node: i32, is_mut: i32) -> i32:
    let type_node = self.ct_build_type_expr(pool, intern, type_id, node)
    if type_node == 0:
        return 0
    let type_extra = pool.extra_len()
    pool.add_extra(type_node)
    let flags = (if is_mut != 0: 1 else: 0) + (type_extra + 1) * 2
    pool.add_node(NodeKind.NK_LET_BINDING, pool.get_start(node), pool.get_end(node), name_sym, value, flags) as i32

fn Sema.ct_build_vec_value_tree(self: Sema, pool: AstPool, intern: InternPool, value: ComptimeValue, node: i32, extras: Vec[ComptimeValue]) -> i32:
    let tmp_sym = ct_fresh_sym(intern, "__ct_vec_", node)
    let ctor = self.ct_build_collection_ctor(pool, intern, value.type_id, node)
    if ctor == 0:
        return 0
    let stmts: Vec[i32] = Vec.new()
    let tmp_binding = self.ct_build_typed_binding(pool, intern, tmp_sym, ctor, value.type_id, node, 1)
    if tmp_binding == 0:
        return 0
    stmts.push(tmp_binding)
    let push_sym = intern.intern("push")
    for i in 0..value.extra_count:
        let elem = extras.get((value.extra_start + i) as i64)
        let elem_node = self.ct_build_value_tree(pool, intern, elem, node, extras)
        if elem_node == 0:
            return 0
        let recv_ident = pool.add_node(NodeKind.NK_IDENT, pool.get_start(node), pool.get_end(node), tmp_sym, 0, 0)
        let callee = pool.add_node(NodeKind.NK_FIELD_ACCESS, pool.get_start(node), pool.get_end(node), recv_ident as i32, push_sym, 0)
        let args: Vec[i32] = Vec.new()
        args.push(elem_node)
        stmts.push(pool.ct_build_call(node, callee as i32, args))
    let stmt_extra = pool.extra_len()
    for si in 0..stmts.len() as i32:
        pool.add_extra(stmts.get(si as i64))
    let tail = pool.add_node(NodeKind.NK_IDENT, pool.get_start(node), pool.get_end(node), tmp_sym, 0, 0)
    pool.add_node(NodeKind.NK_BLOCK, pool.get_start(node), pool.get_end(node), stmt_extra, stmts.len() as i32, tail as i32) as i32

fn Sema.ct_build_map_value_tree(self: Sema, pool: AstPool, intern: InternPool, value: ComptimeValue, node: i32, extras: Vec[ComptimeValue]) -> i32:
    let tmp_sym = ct_fresh_sym(intern, "__ct_map_", node)
    let ctor = self.ct_build_collection_ctor(pool, intern, value.type_id, node)
    if ctor == 0:
        return 0
    let stmts: Vec[i32] = Vec.new()
    let tmp_binding = self.ct_build_typed_binding(pool, intern, tmp_sym, ctor, value.type_id, node, 1)
    if tmp_binding == 0:
        return 0
    stmts.push(tmp_binding)
    let insert_sym = intern.intern("insert")
    for i in 0..value.extra_count:
        let base = value.extra_start + i * 2
        let key_node = self.ct_build_value_tree(pool, intern, extras.get(base as i64), node, extras)
        let item_node = self.ct_build_value_tree(pool, intern, extras.get((base + 1) as i64), node, extras)
        if key_node == 0 or item_node == 0:
            return 0
        let recv_ident = pool.add_node(NodeKind.NK_IDENT, pool.get_start(node), pool.get_end(node), tmp_sym, 0, 0)
        let callee = pool.add_node(NodeKind.NK_FIELD_ACCESS, pool.get_start(node), pool.get_end(node), recv_ident as i32, insert_sym, 0)
        let args: Vec[i32] = Vec.new()
        args.push(key_node)
        args.push(item_node)
        stmts.push(pool.ct_build_call(node, callee as i32, args))
    let stmt_extra = pool.extra_len()
    for si in 0..stmts.len() as i32:
        pool.add_extra(stmts.get(si as i64))
    let tail = pool.add_node(NodeKind.NK_IDENT, pool.get_start(node), pool.get_end(node), tmp_sym, 0, 0)
    pool.add_node(NodeKind.NK_BLOCK, pool.get_start(node), pool.get_end(node), stmt_extra, stmts.len() as i32, tail as i32) as i32

fn Sema.ct_build_value_tree(self: Sema, pool: AstPool, intern: InternPool, value: ComptimeValue, node: i32, extras: Vec[ComptimeValue]) -> i32:
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
        return pool.ct_empty_block(node)
    if value.kind == ComptimeValueKind.CV_ARRAY or value.kind == ComptimeValueKind.CV_TUPLE:
        let elem_nodes: Vec[i32] = Vec.new()
        for i in 0..value.extra_count:
            let elem = extras.get((value.extra_start + i) as i64)
            let elem_node = self.ct_build_value_tree(pool, intern, elem, node, extras)
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
        let resolved = self.resolve_alias(value.type_id)
        if self.get_type_kind(resolved) != TypeKind.TY_STRUCT:
            return 0
        let name_sym = intern.intern(self.pool_resolve(self.get_type_d0(resolved)))
        let te_start = self.get_type_d1(resolved)
        let field_count = self.get_type_d2(resolved)
        let field_syms: Vec[i32] = Vec.new()
        let field_nodes: Vec[i32] = Vec.new()
        for fi in 0..field_count:
            let field_sym = intern.intern(self.pool_resolve(self.type_extra.get((te_start + fi * 3) as i64)))
            let field_value = extras.get((value.extra_start + fi) as i64)
            let field_node = self.ct_build_value_tree(pool, intern, field_value, node, extras)
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
        return self.ct_build_vec_value_tree(pool, intern, value, node, extras)
    if value.kind == ComptimeValueKind.CV_MAP:
        return self.ct_build_map_value_tree(pool, intern, value, node, extras)
    0

fn Sema.ct_eval_truthy(mut self: Sema, source_ast: AstPool, node: i32) -> i32:
    let value = comptime_force_eval_expr(self as *mut Sema, source_ast, self.pool, node)
    if comptime_value_is_valid(value) == 0:
        return -1
    let truthy = comptime_value_truthy(value)
    if truthy >= 0:
        return truthy
    self.ct_emit_error(source_ast, node, "comptime condition must be bool or integer")
    -1

fn Sema.ct_transform_fstring(mut self: Sema, source_ast: AstPool, pool: AstPool, intern: InternPool, node: i32):
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
            pool.state.extra.set_i32((pos + 1) as i64, self.ct_transform_expr(source_ast, pool, intern, expr_node))
        if spec_node != 0:
            pool.state.extra.set_i32((pos + 2) as i64, self.ct_transform_expr(source_ast, pool, intern, spec_node))
        pos = pos + 3

fn Sema.ct_transform_match_arm(mut self: Sema, source_ast: AstPool, pool: AstPool, intern: InternPool, node: i32):
    let body = pool.get_data1(node)
    let guard = pool.get_data2(node)
    if body != 0:
        pool.set_data1(node, self.ct_transform_expr(source_ast, pool, intern, body))
    if guard != 0:
        pool.set_data2(node, self.ct_transform_expr(source_ast, pool, intern, guard))

fn Sema.ct_rewrite_comptime_if(mut self: Sema, source_ast: AstPool, pool: AstPool, intern: InternPool, wrapper: i32, inner: i32) -> i32:
    let cond = pool.get_data0(inner)
    let truthy = self.ct_eval_truthy(source_ast, cond)
    if truthy < 0:
        return wrapper
    if truthy != 0:
        let then_body = pool.get_data1(inner)
        if then_body != 0:
            return self.ct_transform_expr(source_ast, pool, intern, then_body)
        return pool.ct_empty_block(wrapper)
    let else_body = pool.get_data2(inner)
    if else_body != 0:
        return self.ct_transform_expr(source_ast, pool, intern, else_body)
    pool.ct_empty_block(wrapper)

fn ct_iter_count(value: ComptimeValue) -> i32:
    if value.kind == ComptimeValueKind.CV_ARRAY or value.kind == ComptimeValueKind.CV_TUPLE or value.kind == ComptimeValueKind.CV_VEC:
        return value.extra_count
    if value.kind == ComptimeValueKind.CV_RANGE:
        let span = if value.extra_start != 0: value.data1 - value.data0 + 1 else: value.data1 - value.data0
        if span <= 0:
            return 0
        return span as i32
    -1

fn Sema.ct_iter_item_node(self: Sema, pool: AstPool, intern: InternPool, iterable: ComptimeValue, index: i32, node: i32, extras: Vec[ComptimeValue]) -> i32:
    if iterable.kind == ComptimeValueKind.CV_RANGE:
        let item = comptime_value_int(0, iterable.data0 + index as i64)
        return self.ct_build_value_tree(pool, intern, item, node, extras)
    if iterable.kind == ComptimeValueKind.CV_ARRAY or iterable.kind == ComptimeValueKind.CV_TUPLE or iterable.kind == ComptimeValueKind.CV_VEC:
        let item = extras.get((iterable.extra_start + index) as i64)
        return self.ct_build_value_tree(pool, intern, item, node, extras)
    0

fn AstPool.ct_struct_lit_field_value(self: AstPool, node: i32, field: i32) -> i32:
    if node == 0 or self.kind(node) != NodeKind.NK_STRUCT_LIT:
        return 0
    let extra_start = self.get_data1(node)
    let field_count = self.get_data2(node)
    for fi in 0..field_count:
        let base = extra_start + fi * 2
        if self.get_extra(base) == field:
            return self.get_extra(base + 1)
    0

fn Sema.ct_sync_sema_ast(mut self: Sema, pool: AstPool):
    self.ast = pool

fn Sema.ct_try_fold_type_call(mut self: Sema, pool: AstPool, intern: InternPool, node: i32) -> i32:
    if node == 0 or pool.kind(node) != NodeKind.NK_CALL:
        return node
    self.ct_sync_sema_ast(pool)
    let callee = pool.get_data0(node)
    if callee == 0 or pool.kind(callee) != NodeKind.NK_FIELD_ACCESS:
        return node
    if intern.resolve(pool.get_data1(callee)) == "new":
        return node
    let recv = pool.get_data0(callee)
    if self.static_receiver_type_is_known(recv) == 0:
        return node
    let evald = comptime_try_eval_expr_result(self as *mut Sema, pool, self.pool, node)
    if comptime_value_is_valid(evald.value) == 0:
        return node
    let folded = self.ct_build_value_tree(pool, intern, evald.value, node, evald.extras)
    if folded != 0:
        return folded
    node

fn AstPool.ct_clone_tree_with_subst(self: AstPool, node: i32, subst_sym: i32, subst_node: i32, index_sym: i32, index_node: i32) -> i32:
    if node == 0:
        return 0
    let kind = self.kind(node)

    if kind == NodeKind.NK_IDENT:
        let sym = self.get_data0(node)
        if subst_sym != 0 and sym == subst_sym:
            return self.ct_clone_tree_with_subst(subst_node, 0, 0, 0, 0)
        if index_sym != 0 and sym == index_sym:
            return self.ct_clone_tree_with_subst(index_node, 0, 0, 0, 0)
        return self.ct_clone_leaf(node)

    if kind == NodeKind.NK_INT_LIT or kind == NodeKind.NK_FLOAT_LIT or kind == NodeKind.NK_STRING_LIT or kind == NodeKind.NK_C_STRING_LIT or kind == NodeKind.NK_BOOL_LIT or kind == NodeKind.NK_NULL_LIT or kind == NodeKind.NK_TYPE_NAMED or kind == NodeKind.NK_TYPE_INFERRED or kind == NodeKind.NK_COMPTIME_ERROR or kind == NodeKind.NK_PAT_WILDCARD or kind == NodeKind.NK_PAT_IDENT or kind == NodeKind.NK_PAT_INT or kind == NodeKind.NK_PAT_BOOL or kind == NodeKind.NK_PAT_STRING or kind == NodeKind.NK_PAT_TYPED_BIND:
        return self.ct_clone_leaf(node)

    if kind == NodeKind.NK_GROUPED or kind == NodeKind.NK_RETURN or kind == NodeKind.NK_DEFER or kind == NodeKind.NK_ERRDEFER or kind == NodeKind.NK_AWAIT or kind == NodeKind.NK_ASYNC_BLOCK or kind == NodeKind.NK_SPAWN or kind == NodeKind.NK_YIELD:
        let child = self.ct_clone_tree_with_subst(self.get_data0(node), subst_sym, subst_node, index_sym, index_node)
        return self.ct_new_node_copy(kind, self.get_start(node), self.get_end(node), child, self.get_data1(node), self.get_data2(node), self.literal_suffix(node))

    if kind == NodeKind.NK_UNARY:
        let operand = self.ct_clone_tree_with_subst(self.get_data1(node), subst_sym, subst_node, index_sym, index_node)
        return self.ct_new_node_copy(kind, self.get_start(node), self.get_end(node), self.get_data0(node), operand, self.get_data2(node), self.literal_suffix(node))

    if kind == NodeKind.NK_BINARY:
        let lhs = self.ct_clone_tree_with_subst(self.get_data1(node), subst_sym, subst_node, index_sym, index_node)
        let rhs = self.ct_clone_tree_with_subst(self.get_data2(node), subst_sym, subst_node, index_sym, index_node)
        return self.ct_new_node_copy(kind, self.get_start(node), self.get_end(node), self.get_data0(node), lhs, rhs, self.literal_suffix(node))

    if kind == NodeKind.NK_MATCH_OP or kind == NodeKind.NK_NEG_MATCH_OP:
        let lhs = self.ct_clone_tree_with_subst(self.get_data0(node), subst_sym, subst_node, index_sym, index_node)
        let rhs = self.ct_clone_tree_with_subst(self.get_data1(node), subst_sym, subst_node, index_sym, index_node)
        return self.ct_new_node_copy(kind, self.get_start(node), self.get_end(node), lhs, rhs, self.get_data2(node), self.literal_suffix(node))

    if kind == NodeKind.NK_ASSIGN or kind == NodeKind.NK_PIPELINE:
        let lhs = self.ct_clone_tree_with_subst(self.get_data0(node), subst_sym, subst_node, index_sym, index_node)
        let rhs = self.ct_clone_tree_with_subst(self.get_data1(node), subst_sym, subst_node, index_sym, index_node)
        return self.ct_new_node_copy(kind, self.get_start(node), self.get_end(node), lhs, rhs, self.get_data2(node), self.literal_suffix(node))

    if kind == NodeKind.NK_FIELD_ACCESS:
        let base = self.ct_clone_tree_with_subst(self.get_data0(node), subst_sym, subst_node, index_sym, index_node)
        let folded_value = self.ct_struct_lit_field_value(base, self.get_data1(node))
        if folded_value != 0:
            return self.ct_clone_tree_with_subst(folded_value, 0, 0, 0, 0)
        return self.ct_new_node_copy(kind, self.get_start(node), self.get_end(node), base, self.get_data1(node), 0, self.literal_suffix(node))

    if kind == NodeKind.NK_COMPUTED_FIELD_ACCESS:
        let base = self.ct_clone_tree_with_subst(self.get_data0(node), subst_sym, subst_node, index_sym, index_node)
        let field_expr = self.ct_clone_tree_with_subst(self.get_data1(node), subst_sym, subst_node, index_sym, index_node)
        return self.ct_new_node_copy(kind, self.get_start(node), self.get_end(node), base, field_expr, 0, self.literal_suffix(node))

    if kind == NodeKind.NK_INDEX:
        let base = self.ct_clone_tree_with_subst(self.get_data0(node), subst_sym, subst_node, index_sym, index_node)
        let index_expr = self.ct_clone_tree_with_subst(self.get_data1(node), subst_sym, subst_node, index_sym, index_node)
        return self.ct_new_node_copy(kind, self.get_start(node), self.get_end(node), base, index_expr, 0, self.literal_suffix(node))

    if kind == NodeKind.NK_SLICE:
        let base = self.ct_clone_tree_with_subst(self.get_data0(node), subst_sym, subst_node, index_sym, index_node)
        let start_node = self.ct_clone_tree_with_subst(self.get_data1(node), subst_sym, subst_node, index_sym, index_node)
        let end_node = self.ct_clone_tree_with_subst(self.get_data2(node), subst_sym, subst_node, index_sym, index_node)
        return self.ct_new_node_copy(kind, self.get_start(node), self.get_end(node), base, start_node, end_node, self.literal_suffix(node))

    if kind == NodeKind.NK_IF_EXPR:
        let cond = self.ct_clone_tree_with_subst(self.get_data0(node), subst_sym, subst_node, index_sym, index_node)
        let then_body = self.ct_clone_tree_with_subst(self.get_data1(node), subst_sym, subst_node, index_sym, index_node)
        let else_body = self.ct_clone_tree_with_subst(self.get_data2(node), subst_sym, subst_node, index_sym, index_node)
        return self.ct_new_node_copy(kind, self.get_start(node), self.get_end(node), cond, then_body, else_body, self.literal_suffix(node))

    if kind == NodeKind.NK_CALL or kind == NodeKind.NK_TUPLE or kind == NodeKind.NK_ARRAY_LIT or kind == NodeKind.NK_PAT_TUPLE or kind == NodeKind.NK_PAT_OR:
        let extra_start = if kind == NodeKind.NK_CALL: self.get_data1(node) else: self.get_data0(node)
        let count = if kind == NodeKind.NK_CALL: self.get_data2(node) else: self.get_data1(node)
        let cloned_items: Vec[i32] = Vec.new()
        for i in 0..count:
            let child = self.ct_clone_tree_with_subst(self.get_extra(extra_start + i), subst_sym, subst_node, index_sym, index_node)
            cloned_items.push(child)
        let new_extra = self.extra_len()
        for i in 0..cloned_items.len() as i32:
            self.add_extra(cloned_items.get(i as i64))
        if kind == NodeKind.NK_CALL:
            let callee = self.ct_clone_tree_with_subst(self.get_data0(node), subst_sym, subst_node, index_sym, index_node)
            let cloned = self.ct_new_node_copy(kind, self.get_start(node), self.get_end(node), callee, new_extra, count, self.literal_suffix(node))
            if self.has_call_named_args(node as NodeId) != 0:
                let old_names = self.state.call_named_args.get(node).unwrap()
                let new_names = self.extra_len()
                for ni in 0..count:
                    self.add_extra(self.get_extra(old_names + ni))
                self.set_call_named_args(cloned as NodeId, new_names)
            return cloned
        return self.ct_new_node_copy(kind, self.get_start(node), self.get_end(node), new_extra, count, 0, self.literal_suffix(node))

    if kind == NodeKind.NK_BLOCK:
        let extra_start = self.get_data0(node)
        let stmt_count = self.get_data1(node)
        let stmt_nodes: Vec[i32] = Vec.new()
        for i in 0..stmt_count:
            let stmt = self.ct_clone_tree_with_subst(self.get_extra(extra_start + i), subst_sym, subst_node, index_sym, index_node)
            stmt_nodes.push(stmt)
        let stmt_extra = self.extra_len()
        for i in 0..stmt_nodes.len() as i32:
            self.add_extra(stmt_nodes.get(i as i64))
        let tail = self.ct_clone_tree_with_subst(self.get_data2(node), subst_sym, subst_node, index_sym, index_node)
        let cloned = self.ct_new_node_copy(kind, self.get_start(node), self.get_end(node), stmt_extra, stmt_count, tail, self.literal_suffix(node))
        let block_meta = self.find_block_meta(node)
        if block_meta >= 0:
            self.add_block_meta(cloned as NodeId, self.block_meta_label(block_meta))
        return cloned

    if kind == NodeKind.NK_LABEL:
        let stmt = self.ct_clone_tree_with_subst(self.get_data1(node), subst_sym, subst_node, index_sym, index_node)
        return self.ct_new_node_copy(kind, self.get_start(node), self.get_end(node), self.get_data0(node), stmt, 0, self.literal_suffix(node))

    if kind == NodeKind.NK_GOTO:
        return self.ct_new_node_copy(kind, self.get_start(node), self.get_end(node), self.get_data0(node), 0, 0, self.literal_suffix(node))

    if kind == NodeKind.NK_LET_BINDING:
        let value = self.ct_clone_tree_with_subst(self.get_data1(node), subst_sym, subst_node, index_sym, index_node)
        let cloned = self.ct_new_node_copy(kind, self.get_start(node), self.get_end(node), self.get_data0(node), value, self.get_data2(node), self.literal_suffix(node))
        let ann_extra = self.get_data2(node) / 2
        if ann_extra > 0:
            let new_ann_extra = self.extra_len()
            self.add_extra(self.get_extra(ann_extra - 1))
            self.set_data2(cloned, self.get_data2(node) % 2 + (new_ann_extra + 1) * 2)
        return cloned

    if kind == NodeKind.NK_WHILE:
        let cond = self.ct_clone_tree_with_subst(self.get_data0(node), subst_sym, subst_node, index_sym, index_node)
        let body = self.ct_clone_tree_with_subst(self.get_data1(node), subst_sym, subst_node, index_sym, index_node)
        return self.ct_new_node_copy(kind, self.get_start(node), self.get_end(node), cond, body, self.get_data2(node), self.literal_suffix(node))

    if kind == NodeKind.NK_DO_WHILE:
        let body = self.ct_clone_tree_with_subst(self.get_data0(node), subst_sym, subst_node, index_sym, index_node)
        let cond = self.ct_clone_tree_with_subst(self.get_data1(node), subst_sym, subst_node, index_sym, index_node)
        return self.ct_new_node_copy(kind, self.get_start(node), self.get_end(node), body, cond, self.get_data2(node), self.literal_suffix(node))

    if kind == NodeKind.NK_LOOP:
        let body = self.ct_clone_tree_with_subst(self.get_data0(node), subst_sym, subst_node, index_sym, index_node)
        return self.ct_new_node_copy(kind, self.get_start(node), self.get_end(node), body, self.get_data1(node), 0, self.literal_suffix(node))

    if kind == NodeKind.NK_FOR:
        let iterable = self.ct_clone_tree_with_subst(self.get_data1(node), subst_sym, subst_node, index_sym, index_node)
        let body = self.ct_clone_tree_with_subst(self.get_data2(node), subst_sym, subst_node, index_sym, index_node)
        let cloned = self.ct_new_node_copy(kind, self.get_start(node), self.get_end(node), self.get_data0(node), iterable, body, self.literal_suffix(node))
        let for_meta = self.find_for_meta(node)
        if for_meta >= 0:
            self.add_for_meta(cloned as NodeId, self.for_meta_index_binding(for_meta), self.for_meta_label(for_meta))
        return cloned

    if kind == NodeKind.NK_BREAK:
        let value = self.ct_clone_tree_with_subst(self.get_data0(node), subst_sym, subst_node, index_sym, index_node)
        return self.ct_new_node_copy(kind, self.get_start(node), self.get_end(node), value, self.get_data1(node), 0, self.literal_suffix(node))

    if kind == NodeKind.NK_MATCH:
        let extra_start = self.get_data1(node)
        let arm_count = self.get_data2(node)
        let arm_nodes: Vec[i32] = Vec.new()
        for i in 0..arm_count:
            let arm = self.ct_clone_tree_with_subst(self.get_extra(extra_start + i), subst_sym, subst_node, index_sym, index_node)
            arm_nodes.push(arm)
        let new_extra = self.extra_len()
        for i in 0..arm_nodes.len() as i32:
            self.add_extra(arm_nodes.get(i as i64))
        let subject = self.ct_clone_tree_with_subst(self.get_data0(node), subst_sym, subst_node, index_sym, index_node)
        return self.ct_new_node_copy(kind, self.get_start(node), self.get_end(node), subject, new_extra, arm_count, self.literal_suffix(node))

    if kind == NodeKind.NK_MATCH_ARM:
        let pat = self.ct_clone_tree_with_subst(self.get_data0(node), subst_sym, subst_node, index_sym, index_node)
        let body = self.ct_clone_tree_with_subst(self.get_data1(node), subst_sym, subst_node, index_sym, index_node)
        let guard = self.ct_clone_tree_with_subst(self.get_data2(node), subst_sym, subst_node, index_sym, index_node)
        return self.ct_new_node_copy(kind, self.get_start(node), self.get_end(node), pat, body, guard, self.literal_suffix(node))

    if kind == NodeKind.NK_STRUCT_LIT or kind == NodeKind.NK_RECORD_UPDATE:
        let extra_start = self.get_data1(node)
        let field_count = self.get_data2(node)
        let field_extras: Vec[i32] = Vec.new()
        for i in 0..field_count:
            let base = extra_start + i * 2
            field_extras.push(self.get_extra(base))
            let value = self.ct_clone_tree_with_subst(self.get_extra(base + 1), subst_sym, subst_node, index_sym, index_node)
            field_extras.push(value)
        let new_extra = self.extra_len()
        for i in 0..field_extras.len() as i32:
            self.add_extra(field_extras.get(i as i64))
        let source = if kind == NodeKind.NK_RECORD_UPDATE: self.ct_clone_tree_with_subst(self.get_data0(node), subst_sym, subst_node, index_sym, index_node) else: self.get_data0(node)
        return self.ct_new_node_copy(kind, self.get_start(node), self.get_end(node), source, new_extra, field_count, self.literal_suffix(node))

    if kind == NodeKind.NK_CAST:
        let expr = self.ct_clone_tree_with_subst(self.get_data0(node), subst_sym, subst_node, index_sym, index_node)
        return self.ct_new_node_copy(kind, self.get_start(node), self.get_end(node), expr, self.get_data1(node), 0, self.literal_suffix(node))

    if kind == NodeKind.NK_RANGE:
        let start_node = self.ct_clone_tree_with_subst(self.get_data0(node), subst_sym, subst_node, index_sym, index_node)
        let end_node = self.ct_clone_tree_with_subst(self.get_data1(node), subst_sym, subst_node, index_sym, index_node)
        return self.ct_new_node_copy(kind, self.get_start(node), self.get_end(node), start_node, end_node, self.get_data2(node), self.literal_suffix(node))

    if kind == NodeKind.NK_VARIANT_SHORTHAND:
        let arg_count = self.get_data2(node)
        let extra_start = self.get_data1(node)
        let arg_nodes: Vec[i32] = Vec.new()
        for i in 0..arg_count:
            let arg = self.ct_clone_tree_with_subst(self.get_extra(extra_start + i), subst_sym, subst_node, index_sym, index_node)
            arg_nodes.push(arg)
        let new_extra = self.extra_len()
        for i in 0..arg_nodes.len() as i32:
            self.add_extra(arg_nodes.get(i as i64))
        return self.ct_new_node_copy(kind, self.get_start(node), self.get_end(node), self.get_data0(node), new_extra, arg_count, self.literal_suffix(node))

    if kind == NodeKind.NK_ENUM_VARIANT:
        let old_extra = self.get_data2(node)
        let arg_count = self.get_extra(old_extra)
        let arg_nodes: Vec[i32] = Vec.new()
        for i in 0..arg_count:
            let arg = self.ct_clone_tree_with_subst(self.get_extra(old_extra + 1 + i), subst_sym, subst_node, index_sym, index_node)
            arg_nodes.push(arg)
        let new_extra = self.extra_len()
        self.add_extra(arg_count)
        for i in 0..arg_nodes.len() as i32:
            self.add_extra(arg_nodes.get(i as i64))
        return self.ct_new_node_copy(kind, self.get_start(node), self.get_end(node), self.get_data0(node), self.get_data1(node), new_extra, self.literal_suffix(node))

    if kind == NodeKind.NK_OPTIONAL_CHAIN:
        let old_extra = self.get_data2(node)
        let has_args = self.get_extra(old_extra)
        let arg_nodes: Vec[i32] = Vec.new()
        let arg_count = if has_args != 0: self.get_extra(old_extra + 1) else: 0
        if has_args != 0:
            for i in 0..arg_count:
                let arg = self.ct_clone_tree_with_subst(self.get_extra(old_extra + 2 + i), subst_sym, subst_node, index_sym, index_node)
                arg_nodes.push(arg)
        let new_extra = self.extra_len()
        self.add_extra(has_args)
        if has_args != 0:
            self.add_extra(arg_count)
            for i in 0..arg_nodes.len() as i32:
                self.add_extra(arg_nodes.get(i as i64))
        let base = self.ct_clone_tree_with_subst(self.get_data0(node), subst_sym, subst_node, index_sym, index_node)
        return self.ct_new_node_copy(kind, self.get_start(node), self.get_end(node), base, self.get_data1(node), new_extra, self.literal_suffix(node))

    if kind == NodeKind.NK_WITH_EXPR or kind == NodeKind.NK_WITH_TUPLE:
        let source = self.ct_clone_tree_with_subst(self.get_data0(node), subst_sym, subst_node, index_sym, index_node)
        let body = self.ct_clone_tree_with_subst(self.get_data1(node), subst_sym, subst_node, index_sym, index_node)
        return self.ct_new_node_copy(kind, self.get_start(node), self.get_end(node), source, body, self.get_data2(node), self.literal_suffix(node))

    if kind == NodeKind.NK_WITH_IMPLICIT:
        let wi_source = self.ct_clone_tree_with_subst(self.get_data0(node), subst_sym, subst_node, index_sym, index_node)
        let wi_body = self.ct_clone_tree_with_subst(self.get_data1(node), subst_sym, subst_node, index_sym, index_node)
        return self.ct_new_node_copy(kind, self.get_start(node), self.get_end(node), wi_source, wi_body, self.get_data2(node), self.literal_suffix(node))

    if kind == NodeKind.NK_LET_ELSE:
        let value = self.ct_clone_tree_with_subst(self.get_data1(node), subst_sym, subst_node, index_sym, index_node)
        let else_body = self.ct_clone_tree_with_subst(self.get_data2(node), subst_sym, subst_node, index_sym, index_node)
        return self.ct_new_node_copy(kind, self.get_start(node), self.get_end(node), self.get_data0(node), value, else_body, self.literal_suffix(node))

    if kind == NodeKind.NK_TUPLE_DESTRUCTURE:
        let value = self.ct_clone_tree_with_subst(self.get_data2(node), subst_sym, subst_node, index_sym, index_node)
        let new_extra = self.extra_len()
        let extra_start = self.get_data0(node)
        let name_count = self.get_data1(node)
        for i in 0..name_count:
            self.add_extra(self.get_extra(extra_start + i))
        return self.ct_new_node_copy(kind, self.get_start(node), self.get_end(node), new_extra, name_count, value, self.literal_suffix(node))

    if kind == NodeKind.NK_ARRAY_COMPREHENSION:
        let expr = self.ct_clone_tree_with_subst(self.get_data0(node), subst_sym, subst_node, index_sym, index_node)
        let iterable = self.ct_clone_tree_with_subst(self.get_data2(node), subst_sym, subst_node, index_sym, index_node)
        return self.ct_new_node_copy(kind, self.get_start(node), self.get_end(node), expr, self.get_data1(node), iterable, self.literal_suffix(node))

    if kind == NodeKind.NK_ASYNC_SCOPE:
        let body = self.ct_clone_tree_with_subst(self.get_data1(node), subst_sym, subst_node, index_sym, index_node)
        return self.ct_new_node_copy(kind, self.get_start(node), self.get_end(node), self.get_data0(node), body, 0, self.literal_suffix(node))

    if kind == NodeKind.NK_SELECT_AWAIT:
        let extra_start = self.get_data0(node)
        let arm_count = self.get_data1(node)
        let arm_extras: Vec[i32] = Vec.new()
        for i in 0..arm_count:
            let base = extra_start + i * 3
            arm_extras.push(self.get_extra(base))
            let task_expr = self.ct_clone_tree_with_subst(self.get_extra(base + 1), subst_sym, subst_node, index_sym, index_node)
            let body = self.ct_clone_tree_with_subst(self.get_extra(base + 2), subst_sym, subst_node, index_sym, index_node)
            arm_extras.push(task_expr)
            arm_extras.push(body)
        let new_extra = self.extra_len()
        for i in 0..arm_extras.len() as i32:
            self.add_extra(arm_extras.get(i as i64))
        return self.ct_new_node_copy(kind, self.get_start(node), self.get_end(node), new_extra, arm_count, 0, self.literal_suffix(node))

    if kind == NodeKind.NK_FSTRING:
        let seg_count = self.get_data0(node)
        let old_extra = self.get_data1(node)
        let seg_extras: Vec[i32] = Vec.new()
        var pos = old_extra
        for _ in 0..seg_count:
            let seg_kind = self.get_extra(pos)
            seg_extras.push(seg_kind)
            if seg_kind == FStringSegmentKind.EXPR:
                let expr_node = self.ct_clone_tree_with_subst(self.get_extra(pos + 1), subst_sym, subst_node, index_sym, index_node)
                let spec_node = self.ct_clone_tree_with_subst(self.get_extra(pos + 2), subst_sym, subst_node, index_sym, index_node)
                seg_extras.push(expr_node)
                seg_extras.push(spec_node)
                pos = pos + 3
            else:
                seg_extras.push(self.get_extra(pos + 1))
                pos = pos + 2
        let new_extra = self.extra_len()
        for i in 0..seg_extras.len() as i32:
            self.add_extra(seg_extras.get(i as i64))
        return self.ct_new_node_copy(kind, self.get_start(node), self.get_end(node), seg_count, new_extra, 0, self.literal_suffix(node))

    if kind == NodeKind.NK_CLOSURE:
        let param_count = self.get_data2(node)
        let old_extra = self.get_data1(node)
        let new_extra = self.extra_len()
        for i in 0..param_count:
            let base = old_extra + i * 2
            self.add_extra(self.get_extra(base))
            self.add_extra(self.get_extra(base + 1))
        let body = self.ct_clone_tree_with_subst(self.get_data0(node), subst_sym, subst_node, index_sym, index_node)
        let cloned = self.ct_new_node_copy(kind, self.get_start(node), self.get_end(node), body, new_extra, param_count, self.literal_suffix(node))
        if self.is_move_closure(node) != 0:
            self.mark_move_closure(cloned as NodeId)
        if self.is_non_escaping_closure(node) != 0:
            self.mark_non_escaping_closure(cloned as NodeId)
        return cloned

    self.ct_clone_leaf(node)

fn Sema.ct_rewrite_comptime_for(mut self: Sema, source_ast: AstPool, pool: AstPool, intern: InternPool, wrapper: i32, inner: i32) -> i32:
    let iterable_node = pool.get_data1(inner)
    let evald = comptime_force_eval_expr_result(self as *mut Sema, source_ast, self.pool, iterable_node)
    let iterable = evald.value
    if comptime_value_is_valid(iterable) == 0:
        return wrapper

    let iter_count = ct_iter_count(iterable)
    if iter_count < 0:
        self.ct_emit_error(source_ast, iterable_node, "comptime for requires an array, tuple, or range")
        return wrapper

    let template_body = self.ct_transform_expr(source_ast, pool, intern, pool.get_data2(inner))
    let stmt_nodes: Vec[i32] = Vec.new()
    let binding = pool.get_data0(inner)
    let for_meta = pool.find_for_meta(inner)
    let index_binding = if for_meta >= 0: pool.for_meta_index_binding(for_meta) else: 0
    for i in 0..iter_count:
        let item_node = self.ct_iter_item_node(pool, intern, iterable, i, wrapper, evald.extras)
        if item_node == 0:
            self.ct_emit_error(source_ast, inner, "failed to materialize comptime for item")
            return wrapper
        var index_node = 0
        if index_binding != 0:
            let index_value = comptime_value_int(self.ty_i64 as i32, i as i64)
            let empty_values: Vec[ComptimeValue] = Vec.new()
            index_node = self.ct_build_value_tree(pool, intern, index_value, wrapper, empty_values)
        let cloned_body = pool.ct_clone_tree_with_subst(template_body, binding, item_node, index_binding, index_node)
        stmt_nodes.push(self.ct_transform_expr(pool, pool, intern, cloned_body))
    let stmt_extra = pool.extra_len()
    for i in 0..stmt_nodes.len() as i32:
        pool.add_extra(stmt_nodes.get(i as i64))
    pool.add_node(NodeKind.NK_BLOCK, pool.get_start(wrapper), pool.get_end(wrapper), stmt_extra, iter_count, 0) as i32

fn Sema.ct_rewrite_comptime(mut self: Sema, source_ast: AstPool, pool: AstPool, intern: InternPool, node: i32) -> i32:
    let inner = pool.get_data0(node)
    if inner == 0:
        return pool.ct_empty_block(node)
    let inner_kind = pool.kind(inner)
    if inner_kind == NodeKind.NK_INT_LIT:
        return inner
    if inner_kind == NodeKind.NK_IF_EXPR:
        return self.ct_rewrite_comptime_if(source_ast, pool, intern, node, inner)
    if inner_kind == NodeKind.NK_FOR:
        return self.ct_rewrite_comptime_for(source_ast, pool, intern, node, inner)

    let diag_count_before = self.diags.count()
    let evald = comptime_force_eval_expr_result(self as *mut Sema, source_ast, self.pool, inner)
    let value = evald.value
    if comptime_value_is_valid(value) == 0:
        if evald.error_msg.len() > 0 and self.diags.count() == diag_count_before:
            self.ct_emit_error(source_ast, inner, evald.error_msg)
        return node
    let folded = self.ct_build_value_tree(pool, intern, value, node, evald.extras)
    if folded == 0:
        self.ct_emit_error(source_ast, inner, "comptime value cannot be embedded yet")
        return node
    folded

fn Sema.ct_transform_expr(mut self: Sema, source_ast: AstPool, pool: AstPool, intern: InternPool, node: i32) -> i32:
    if node == 0:
        return 0
    self.ct_sync_sema_ast(pool)
    let kind = pool.kind(node)

    if kind == NodeKind.NK_COMPTIME:
        return self.ct_rewrite_comptime(source_ast, pool, intern, node)

    if kind == NodeKind.NK_BINARY:
        pool.set_data1(node, self.ct_transform_expr(source_ast, pool, intern, pool.get_data1(node)))
        pool.set_data2(node, self.ct_transform_expr(source_ast, pool, intern, pool.get_data2(node)))
        return node

    if kind == NodeKind.NK_UNARY:
        pool.set_data1(node, self.ct_transform_expr(source_ast, pool, intern, pool.get_data1(node)))
        return node

    if kind == NodeKind.NK_GROUPED or kind == NodeKind.NK_RETURN or kind == NodeKind.NK_DEFER or kind == NodeKind.NK_ERRDEFER or kind == NodeKind.NK_AWAIT or kind == NodeKind.NK_ASYNC_BLOCK or kind == NodeKind.NK_SPAWN or kind == NodeKind.NK_YIELD:
        pool.set_data0(node, self.ct_transform_expr(source_ast, pool, intern, pool.get_data0(node)))
        return node

    if kind == NodeKind.NK_CALL:
        pool.set_data0(node, self.ct_transform_expr(source_ast, pool, intern, pool.get_data0(node)))
        let extra_start = pool.get_data1(node)
        let arg_count = pool.get_data2(node)
        for i in 0..arg_count:
            let arg_idx = extra_start + i
            pool.state.extra.set_i32(arg_idx as i64, self.ct_transform_expr(source_ast, pool, intern, pool.get_extra(arg_idx)))
        return self.ct_try_fold_type_call(pool, intern, node)

    if kind == NodeKind.NK_FIELD_ACCESS:
        let base = self.ct_transform_expr(source_ast, pool, intern, pool.get_data0(node))
        pool.set_data0(node, base)
        let folded_value = pool.ct_struct_lit_field_value(base, pool.get_data1(node))
        if folded_value != 0:
            return pool.ct_clone_tree_with_subst(folded_value, 0, 0, 0, 0)
        return node

    if kind == NodeKind.NK_COMPUTED_FIELD_ACCESS:
        let base = self.ct_transform_expr(source_ast, pool, intern, pool.get_data0(node))
        let field_expr = self.ct_transform_expr(source_ast, pool, intern, pool.get_data1(node))
        pool.set_data0(node, base)
        pool.set_data1(node, field_expr)
        let evald = comptime_try_eval_expr_result(self as *mut Sema, pool, self.pool, field_expr)
        if comptime_value_is_valid(evald.value) == 0:
            return node
        if evald.value.kind != ComptimeValueKind.CV_STR:
            self.ct_emit_error(source_ast, node, "computed field access requires comptime string field name")
            return node
        let field_sym = intern.intern(evald.value.text)
        return pool.add_node(NodeKind.NK_FIELD_ACCESS, pool.get_start(node), pool.get_end(node), base, field_sym, 0) as i32

    if kind == NodeKind.NK_INDEX:
        pool.set_data0(node, self.ct_transform_expr(source_ast, pool, intern, pool.get_data0(node)))
        pool.set_data1(node, self.ct_transform_expr(source_ast, pool, intern, pool.get_data1(node)))
        return node

    if kind == NodeKind.NK_SLICE:
        pool.set_data0(node, self.ct_transform_expr(source_ast, pool, intern, pool.get_data0(node)))
        if pool.get_data1(node) != 0:
            pool.set_data1(node, self.ct_transform_expr(source_ast, pool, intern, pool.get_data1(node)))
        if pool.get_data2(node) != 0:
            pool.set_data2(node, self.ct_transform_expr(source_ast, pool, intern, pool.get_data2(node)))
        return node

    if kind == NodeKind.NK_BLOCK:
        let extra_start = pool.get_data0(node)
        let stmt_count = pool.get_data1(node)
        for i in 0..stmt_count:
            let stmt_idx = extra_start + i
            pool.state.extra.set_i32(stmt_idx as i64, self.ct_transform_expr(source_ast, pool, intern, pool.get_extra(stmt_idx)))
        if pool.get_data2(node) != 0:
            pool.set_data2(node, self.ct_transform_expr(source_ast, pool, intern, pool.get_data2(node)))
        return node

    if kind == NodeKind.NK_LABEL:
        pool.set_data1(node, self.ct_transform_expr(source_ast, pool, intern, pool.get_data1(node)))
        return node

    if kind == NodeKind.NK_GOTO:
        return node

    if kind == NodeKind.NK_LET_BINDING:
        pool.set_data1(node, self.ct_transform_expr(source_ast, pool, intern, pool.get_data1(node)))
        return node

    if kind == NodeKind.NK_IF_EXPR:
        pool.set_data0(node, self.ct_transform_expr(source_ast, pool, intern, pool.get_data0(node)))
        pool.set_data1(node, self.ct_transform_expr(source_ast, pool, intern, pool.get_data1(node)))
        if pool.get_data2(node) != 0:
            pool.set_data2(node, self.ct_transform_expr(source_ast, pool, intern, pool.get_data2(node)))
        return node

    if kind == NodeKind.NK_ASSIGN:
        pool.set_data0(node, self.ct_transform_expr(source_ast, pool, intern, pool.get_data0(node)))
        pool.set_data1(node, self.ct_transform_expr(source_ast, pool, intern, pool.get_data1(node)))
        return node

    if kind == NodeKind.NK_WHILE:
        pool.set_data0(node, self.ct_transform_expr(source_ast, pool, intern, pool.get_data0(node)))
        pool.set_data1(node, self.ct_transform_expr(source_ast, pool, intern, pool.get_data1(node)))
        return node

    if kind == NodeKind.NK_DO_WHILE:
        pool.set_data0(node, self.ct_transform_expr(source_ast, pool, intern, pool.get_data0(node)))
        pool.set_data1(node, self.ct_transform_expr(source_ast, pool, intern, pool.get_data1(node)))
        return node

    if kind == NodeKind.NK_LOOP:
        pool.set_data0(node, self.ct_transform_expr(source_ast, pool, intern, pool.get_data0(node)))
        return node

    if kind == NodeKind.NK_FOR:
        pool.set_data1(node, self.ct_transform_expr(source_ast, pool, intern, pool.get_data1(node)))
        pool.set_data2(node, self.ct_transform_expr(source_ast, pool, intern, pool.get_data2(node)))
        return node

    if kind == NodeKind.NK_BREAK:
        if pool.get_data0(node) != 0:
            pool.set_data0(node, self.ct_transform_expr(source_ast, pool, intern, pool.get_data0(node)))
        return node

    if kind == NodeKind.NK_MATCH:
        pool.set_data0(node, self.ct_transform_expr(source_ast, pool, intern, pool.get_data0(node)))
        let extra_start = pool.get_data1(node)
        let arm_count = pool.get_data2(node)
        for i in 0..arm_count:
            let arm_idx = extra_start + i
            let arm = pool.get_extra(arm_idx)
            self.ct_transform_match_arm(source_ast, pool, intern, arm)
            pool.state.extra.set_i32(arm_idx as i64, arm)
        return node

    if kind == NodeKind.NK_TUPLE or kind == NodeKind.NK_ARRAY_LIT or kind == NodeKind.NK_PAT_TUPLE or kind == NodeKind.NK_PAT_OR:
        let extra_start = pool.get_data0(node)
        let count = pool.get_data1(node)
        for i in 0..count:
            let idx = extra_start + i
            pool.state.extra.set_i32(idx as i64, self.ct_transform_expr(source_ast, pool, intern, pool.get_extra(idx)))
        return node

    if kind == NodeKind.NK_STRUCT_LIT or kind == NodeKind.NK_RECORD_UPDATE:
        if kind == NodeKind.NK_RECORD_UPDATE:
            pool.set_data0(node, self.ct_transform_expr(source_ast, pool, intern, pool.get_data0(node)))
        let extra_start = pool.get_data1(node)
        let field_count = pool.get_data2(node)
        for i in 0..field_count:
            let value_idx = extra_start + i * 2 + 1
            pool.state.extra.set_i32(value_idx as i64, self.ct_transform_expr(source_ast, pool, intern, pool.get_extra(value_idx)))
        return node

    if kind == NodeKind.NK_CLOSURE:
        pool.set_data0(node, self.ct_transform_expr(source_ast, pool, intern, pool.get_data0(node)))
        return node

    if kind == NodeKind.NK_CAST:
        pool.set_data0(node, self.ct_transform_expr(source_ast, pool, intern, pool.get_data0(node)))
        return node

    if kind == NodeKind.NK_PIPELINE:
        pool.set_data0(node, self.ct_transform_expr(source_ast, pool, intern, pool.get_data0(node)))
        pool.set_data1(node, self.ct_transform_expr(source_ast, pool, intern, pool.get_data1(node)))
        return node

    if kind == NodeKind.NK_RANGE:
        if pool.get_data0(node) != 0:
            pool.set_data0(node, self.ct_transform_expr(source_ast, pool, intern, pool.get_data0(node)))
        if pool.get_data1(node) != 0:
            pool.set_data1(node, self.ct_transform_expr(source_ast, pool, intern, pool.get_data1(node)))
        return node

    if kind == NodeKind.NK_FSTRING:
        self.ct_transform_fstring(source_ast, pool, intern, node)
        return node

    if kind == NodeKind.NK_VARIANT_SHORTHAND:
        let extra_start = pool.get_data1(node)
        let arg_count = pool.get_data2(node)
        for i in 0..arg_count:
            let idx = extra_start + i
            pool.state.extra.set_i32(idx as i64, self.ct_transform_expr(source_ast, pool, intern, pool.get_extra(idx)))
        return node

    if kind == NodeKind.NK_WITH_EXPR or kind == NodeKind.NK_WITH_TUPLE:
        pool.set_data0(node, self.ct_transform_expr(source_ast, pool, intern, pool.get_data0(node)))
        pool.set_data1(node, self.ct_transform_expr(source_ast, pool, intern, pool.get_data1(node)))
        return node

    if kind == NodeKind.NK_WITH_IMPLICIT:
        pool.set_data0(node, self.ct_transform_expr(source_ast, pool, intern, pool.get_data0(node)))
        pool.set_data1(node, self.ct_transform_expr(source_ast, pool, intern, pool.get_data1(node)))
        return node

    if kind == NodeKind.NK_ENUM_VARIANT:
        let old_extra = pool.get_data2(node)
        let arg_count = pool.get_extra(old_extra)
        for i in 0..arg_count:
            let idx = old_extra + 1 + i
            pool.state.extra.set_i32(idx as i64, self.ct_transform_expr(source_ast, pool, intern, pool.get_extra(idx)))
        return node

    if kind == NodeKind.NK_OPTIONAL_CHAIN:
        pool.set_data0(node, self.ct_transform_expr(source_ast, pool, intern, pool.get_data0(node)))
        let extra_start = pool.get_data2(node)
        if pool.get_extra(extra_start) != 0:
            let arg_count = pool.get_extra(extra_start + 1)
            for i in 0..arg_count:
                let idx = extra_start + 2 + i
                pool.state.extra.set_i32(idx as i64, self.ct_transform_expr(source_ast, pool, intern, pool.get_extra(idx)))
        return node

    if kind == NodeKind.NK_LET_ELSE:
        pool.set_data1(node, self.ct_transform_expr(source_ast, pool, intern, pool.get_data1(node)))
        pool.set_data2(node, self.ct_transform_expr(source_ast, pool, intern, pool.get_data2(node)))
        return node

    if kind == NodeKind.NK_TUPLE_DESTRUCTURE:
        pool.set_data2(node, self.ct_transform_expr(source_ast, pool, intern, pool.get_data2(node)))
        return node

    if kind == NodeKind.NK_ARRAY_COMPREHENSION:
        pool.set_data0(node, self.ct_transform_expr(source_ast, pool, intern, pool.get_data0(node)))
        pool.set_data2(node, self.ct_transform_expr(source_ast, pool, intern, pool.get_data2(node)))
        return node

    if kind == NodeKind.NK_ASYNC_SCOPE:
        pool.set_data1(node, self.ct_transform_expr(source_ast, pool, intern, pool.get_data1(node)))
        return node

    if kind == NodeKind.NK_SELECT_AWAIT:
        let extra_start = pool.get_data0(node)
        let arm_count = pool.get_data1(node)
        for i in 0..arm_count:
            let base = extra_start + i * 3
            pool.state.extra.set_i32((base + 1) as i64, self.ct_transform_expr(source_ast, pool, intern, pool.get_extra(base + 1)))
            pool.state.extra.set_i32((base + 2) as i64, self.ct_transform_expr(source_ast, pool, intern, pool.get_extra(base + 2)))
        return node

    node

fn Sema.ct_transform_fn_param_defaults(mut self: Sema, source_ast: AstPool, pool: AstPool, intern: InternPool, fn_node: i32):
    let meta = pool.find_fn_meta(fn_node)
    if meta < 0:
        return
    let param_start = pool.fn_meta_param_start(meta)
    let param_count = pool.fn_meta_param_count(meta)
    for pi in 0..param_count:
        let default_node = pool.get_fn_param_default(param_start, pi)
        if default_node == 0:
            continue
        pool.set_fn_param_default(param_start, pi, self.ct_transform_expr(source_ast, pool, intern, default_node))

fn Sema.ct_transform_trait_decl(mut self: Sema, source_ast: AstPool, pool: AstPool, intern: InternPool, node: i32):
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
            pool.state.extra.set_i32(body_idx as i64, self.ct_transform_expr(source_ast, pool, intern, body))
        for pi in 0..param_count:
            let default_node = pool.get_fn_param_default(param_start, pi)
            if default_node != 0:
                pool.set_fn_param_default(param_start, pi, self.ct_transform_expr(source_ast, pool, intern, default_node))
        pos = pos + 6

fn Sema.ct_transform_type_decl(mut self: Sema, source_ast: AstPool, pool: AstPool, intern: InternPool, node: i32):
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
            pool.state.extra.set_i32(default_idx as i64, self.ct_transform_expr(source_ast, pool, intern, field_default))

fn Sema.ct_decl_source_path(self: Sema, di: i32) -> str:
    if di >= 0 and di < self.decl_source_paths.len() as i32:
        return self.decl_source_paths.get(di as i64)
    ""

fn Sema.ct_decl_source_file_id(self: Sema, di: i32) -> i32:
    if di >= 0 and di < self.decl_source_file_ids.len() as i32:
        return self.decl_source_file_ids.get(di as i64)
    0

fn Sema.ct_decl_is_c_import(self: Sema, di: i32) -> i32:
    if di >= 0 and di < self.decl_is_c_import.len() as i32:
        return self.decl_is_c_import.get(di as i64)
    0

fn ct_source_decl_is_local(ast: AstPool, decl_index: i32) -> i32:
    let limit = ast.local_decl_count()
    if limit < 0:
        return 1
    let total = ast.decl_count()
    if decl_index >= total - limit:
        return 1
    0

fn ct_type_decl_tp_count(ast: AstPool, node: i32) -> i32:
    let extra_start = ast.get_data1(node)
    let sub_kind = type_decl_sub_kind(ast.get_data2(node))
    if sub_kind == TypeDeclKind.Struct:
        let field_count = ast.get_extra(extra_start)
        return ast.get_extra(extra_start + 1 + field_count * 4 + 2)
    0

fn ct_type_decl_tp_start(ast: AstPool, node: i32) -> i32:
    let extra_start = ast.get_data1(node)
    let sub_kind = type_decl_sub_kind(ast.get_data2(node))
    if sub_kind == TypeDeclKind.Struct:
        let field_count = ast.get_extra(extra_start)
        return ast.get_extra(extra_start + 1 + field_count * 4 + 1)
    0

fn ct_struct_type_decl_vis(ast: AstPool, node: i32) -> i32:
    let extra_start = ast.get_data1(node)
    let sub_kind = type_decl_sub_kind(ast.get_data2(node))
    if sub_kind == TypeDeclKind.Struct:
        let field_count = ast.get_extra(extra_start)
        return ast.get_extra(extra_start + 1 + field_count * 4)
    Visibility.Private

fn AstPool.ct_build_ident(self: AstPool, node: i32, sym: i32) -> i32:
    self.add_node(NodeKind.NK_IDENT, self.get_start(node), self.get_end(node), sym, 0, 0) as i32

fn AstPool.ct_build_field_access(self: AstPool, node: i32, base: i32, field: i32) -> i32:
    self.add_node(NodeKind.NK_FIELD_ACCESS, self.get_start(node), self.get_end(node), base, field, 0) as i32

fn AstPool.ct_build_int_lit(self: AstPool, node: i32, value: i64) -> i32:
    self.add_node(NodeKind.NK_INT_LIT, self.get_start(node), self.get_end(node), ast_int_part0(value), ast_int_part1(value), ast_int_part2(value)) as i32

fn AstPool.ct_build_bool_lit(self: AstPool, node: i32, value: bool) -> i32:
    self.add_node(NodeKind.NK_BOOL_LIT, self.get_start(node), self.get_end(node), if value: 1 else: 0, 0, 0) as i32

fn AstPool.ct_build_string_lit(self: AstPool, intern: InternPool, node: i32, value: str) -> i32:
    self.add_node(NodeKind.NK_STRING_LIT, self.get_start(node), self.get_end(node), intern.intern(value), 0, 0) as i32

fn AstPool.ct_build_binary(self: AstPool, node: i32, op: i32, lhs: i32, rhs: i32) -> i32:
    self.add_node(NodeKind.NK_BINARY, self.get_start(node), self.get_end(node), op, lhs, rhs) as i32

fn AstPool.ct_build_block(self: AstPool, node: i32, stmts: Vec[i32], tail: i32) -> i32:
    let stmt_extra = self.extra_len()
    for si in 0..stmts.len() as i32:
        self.add_extra(stmts.get(si as i64))
    self.add_node(NodeKind.NK_BLOCK, self.get_start(node), self.get_end(node), stmt_extra, stmts.len() as i32, tail) as i32

fn AstPool.ct_add_fn_param(self: AstPool, name: i32, type_node: i32, flags: i32):
    self.add_extra(name)
    self.add_extra(type_node)
    self.add_extra(flags)

fn ct_copy_type_params_with_bound(pool: AstPool, src_tp_start: i32, tp_count: i32, bound_sym: i32) -> i32:
    let dst_tp_start = pool.extra_len()
    var src = src_tp_start
    for tpi in 0..tp_count:
        let tp_name = pool.get_extra(src)
        let bound_count = pool.get_extra(src + 1)
        var has_bound = 0
        for bi in 0..bound_count:
            if pool.get_extra(src + 2 + bi) == bound_sym:
                has_bound = 1
        pool.add_extra(tp_name)
        pool.add_extra(bound_count + if has_bound != 0: 0 else: 1)
        for bi2 in 0..bound_count:
            pool.add_extra(pool.get_extra(src + 2 + bi2))
        if has_bound == 0:
            pool.add_extra(bound_sym)
        src = src + 2 + bound_count
    dst_tp_start

fn ct_copy_type_params(pool: AstPool, src_tp_start: i32, tp_count: i32) -> i32:
    let dst_tp_start = pool.extra_len()
    var src = src_tp_start
    for tpi in 0..tp_count:
        let tp_name = pool.get_extra(src)
        let bound_count = pool.get_extra(src + 1)
        pool.add_extra(tp_name)
        pool.add_extra(bound_count)
        for bi in 0..bound_count:
            pool.add_extra(pool.get_extra(src + 2 + bi))
        src = src + 2 + bound_count
    dst_tp_start

fn ct_component_id_value(name: str) -> i64:
    var h: i64 = 5381
    var i: i64 = 0
    while i < name.len():
        h = ((h * 33) + name[i]) % 2147483647
        i = i + 1
    if h == 0:
        return 1
    h

fn ct_build_generic_self_type(pool: AstPool, node: i32, type_sym: i32, tp_start: i32, tp_count: i32) -> i32:
    if tp_count == 0:
        return pool.add_node(NodeKind.NK_TYPE_NAMED, pool.get_start(node), pool.get_end(node), type_sym, 0, 0) as i32
    let arg_start = pool.extra_len()
    var pos = tp_start
    for tpi in 0..tp_count:
        let tp_name = pool.get_extra(pos)
        let arg_node = pool.add_node(NodeKind.NK_TYPE_NAMED, pool.get_start(node), pool.get_end(node), tp_name, 0, 0)
        pool.add_extra(arg_node as i32)
        let bound_count = pool.get_extra(pos + 1)
        pos = pos + 2 + bound_count
    pool.add_node(NodeKind.NK_TYPE_GENERIC, pool.get_start(node), pool.get_end(node), type_sym, arg_start, tp_count) as i32

fn Sema.ct_type_param_sym_for_type_id(self: Sema, pool: AstPool, intern: InternPool, type_id: i32, tp_start: i32, tp_count: i32) -> i32:
    if tp_count <= 0:
        return 0
    let type_name = self.type_name(type_id)
    var pos = tp_start
    for tpi in 0..tp_count:
        let tp_sym = pool.get_extra(pos)
        if intern.resolve(tp_sym) == type_name:
            return tp_sym
        let bound_count = pool.get_extra(pos + 1)
        pos = pos + 2 + bound_count
    0

fn ct_type_param_sym_for_type_node(pool: AstPool, type_node: i32, tp_start: i32, tp_count: i32) -> i32:
    if tp_count <= 0 or type_node == 0:
        return 0
    let kind = pool.kind(type_node)
    if kind != NodeKind.NK_TYPE_NAMED and kind != NodeKind.NK_IDENT:
        return 0
    let type_sym = pool.get_data0(type_node)
    var pos = tp_start
    for tpi in 0..tp_count:
        let tp_sym = pool.get_extra(pos)
        if tp_sym == type_sym:
            return tp_sym
        let bound_count = pool.get_extra(pos + 1)
        pos = pos + 2 + bound_count
    0

fn Sema.ct_build_type_expr_with_hint(self: Sema, pool: AstPool, intern: InternPool, type_id: i32, type_node_hint: i32, node: i32) -> i32:
    if type_node_hint != 0:
        return pool.ct_clone_tree_with_subst(type_node_hint, 0, 0, 0, 0)
    self.ct_build_type_expr(pool, intern, type_id, node)

fn Sema.ct_build_vec_type_expr(self: Sema, pool: AstPool, intern: InternPool, elem_type_id: i32, type_node_hint: i32, node: i32) -> i32:
    let elem_type = self.ct_build_type_expr_with_hint(pool, intern, elem_type_id, type_node_hint, node)
    if elem_type == 0:
        return 0
    let arg_start = pool.extra_len()
    pool.add_extra(elem_type)
    pool.add_node(NodeKind.NK_TYPE_GENERIC, pool.get_start(node), pool.get_end(node), intern.intern("Vec"), arg_start, 1) as i32

fn Sema.ct_generate_soa_derive(self: Sema, out: AstPool, intern: InternPool, decl: i32) -> Vec[i32]:
    let generated: Vec[i32] = Vec.new()
    if type_decl_sub_kind(out.get_data2(decl)) != TypeDeclKind.Struct:
        return generated

    let type_name_sym = out.get_data0(decl)
    let type_name = intern.resolve(type_name_sym)
    let soa_name = type_name ++ "SoA"
    let soa_sym = intern.intern(soa_name)
    if self.lookup_named_type_visible(soa_sym) != 0:
        self.ct_emit_error(out, decl, "derive SoA target type '" ++ soa_name ++ "' already exists")
        return generated
    let tid = self.lookup_named_type_visible(type_name_sym)
    if tid == 0:
        return generated
    let resolved = self.resolve_alias(tid)
    if self.get_type_kind(resolved) != TypeKind.TY_STRUCT:
        return generated

    let start = out.get_start(decl)
    let end = out.get_end(decl)
    let tp_count = ct_type_decl_tp_count(out, decl)
    let tp_start = ct_type_decl_tp_start(out, decl)
    let soa_tp_start = if tp_count > 0: ct_copy_type_params(out, tp_start, tp_count) else: 0
    let te_start = self.get_type_d1(resolved)
    let field_count = self.get_type_d2(resolved)
    let type_extra_start = out.get_data1(decl)
    let soa_field_types: Vec[i32] = Vec.new()
    for fi in 0..field_count:
        let field_tid = self.type_extra.get((te_start + fi * 3 + 1) as i64)
        let field_type_node = out.get_extra(type_extra_start + 1 + fi * 3 + 1)
        let vec_type = self.ct_build_vec_type_expr(out, intern, field_tid, field_type_node, decl)
        if vec_type == 0:
            self.ct_emit_error(out, decl, "could not generate SoA field type")
            return generated
        soa_field_types.push(vec_type)

    let soa_extra = out.extra_len()
    out.add_extra(field_count)
    for fi in 0..field_count:
        let field_sym = out.get_extra(type_extra_start + 1 + fi * 3)
        out.add_extra(field_sym)
        out.add_extra(soa_field_types.get(fi as i64))
        out.add_extra(0)
    for fi in 0..field_count:
        out.add_extra(0)
    out.add_extra(ct_struct_type_decl_vis(out, decl))
    out.add_extra(soa_tp_start)
    out.add_extra(tp_count)
    let soa_type_node = out.add_node(NodeKind.NK_TYPE_DECL, start, end, soa_sym, soa_extra, pack_type_decl_kind(TypeDeclKind.Struct, 0))
    generated.push(soa_type_node as i32)

    let self_sym = intern.intern("self")
    let value_sym = intern.intern("value")
    let idx_sym = intern.intern("idx")
    let new_sym = intern.intern("new")
    let push_sym = intern.intern("push")
    let get_sym = intern.intern("get")
    let len_sym = intern.intern("len")
    let self_type_sym = intern.intern("Self")
    let i64_sym = intern.intern("i64")
    let self_type = out.add_node(NodeKind.NK_TYPE_NAMED, start, end, self_type_sym, 0, 0)
    let soa_self_type = ct_build_generic_self_type(out, decl, soa_sym, tp_start, tp_count)
    let soa_self_ref_type = out.add_node(NodeKind.NK_TYPE_REF, start, end, soa_self_type as i32, 0, 0)
    let source_type = ct_build_generic_self_type(out, decl, type_name_sym, tp_start, tp_count)
    let idx_type = out.add_node(NodeKind.NK_TYPE_NAMED, start, end, i64_sym, 0, 0)

    let new_field_values: Vec[i32] = Vec.new()
    for fi in 0..field_count:
        let new_callee = out.ct_build_field_access(decl, soa_field_types.get(fi as i64), new_sym)
        let new_args: Vec[i32] = Vec.new()
        let new_call = out.ct_build_call(decl, new_callee, new_args)
        new_field_values.push(new_call)
    let new_field_extra = out.extra_len()
    for fi in 0..field_count:
        let field_sym = out.get_extra(type_extra_start + 1 + fi * 3)
        out.add_extra(field_sym)
        out.add_extra(new_field_values.get(fi as i64))
    let new_lit_type = if tp_count > 0: self_type_sym else: soa_sym
    let new_body = out.add_node(NodeKind.NK_STRUCT_LIT, start, end, new_lit_type, new_field_extra, field_count)
    let new_fn_sym = intern.intern(soa_name ++ ".new")
    let new_fn = out.add_node(NodeKind.NK_FN_DECL, start, end, new_fn_sym, new_body as i32, 0)
    out.add_fn_meta(new_fn, 0, soa_self_type as i32, out.extra_len(), 0, 0, 0)
    generated.push(new_fn as i32)

    let push_stmts: Vec[i32] = Vec.new()
    for fi in 0..field_count:
        let field_sym = out.get_extra(type_extra_start + 1 + fi * 3)
        let self_ident = out.ct_build_ident(decl, self_sym)
        let self_field = out.ct_build_field_access(decl, self_ident, field_sym)
        let push_callee = out.ct_build_field_access(decl, self_field, push_sym)
        let value_ident = out.ct_build_ident(decl, value_sym)
        let value_field = out.ct_build_field_access(decl, value_ident, field_sym)
        let push_args: Vec[i32] = Vec.new()
        push_args.push(value_field)
        push_stmts.push(out.ct_build_call(decl, push_callee, push_args))
    let push_tail = out.ct_build_ident(decl, self_sym)
    let push_body = out.ct_build_block(decl, push_stmts, push_tail)
    let push_param_start = out.extra_len()
    out.ct_add_fn_param(self_sym, soa_self_type as i32, FN_PARAM_FLAG_MUT_SELF)
    out.ct_add_fn_param(value_sym, source_type as i32, 0)
    let push_fn_sym = intern.intern(soa_name ++ ".push")
    let push_fn = out.add_node(NodeKind.NK_FN_DECL, start, end, push_fn_sym, push_body as i32, 0)
    out.add_fn_meta(push_fn, 2 * FN_META_REQUIRED_UNIT, soa_self_type as i32, push_param_start, 2, 0, 0)
    generated.push(push_fn as i32)

    let get_field_values: Vec[i32] = Vec.new()
    for fi in 0..field_count:
        let field_sym = out.get_extra(type_extra_start + 1 + fi * 3)
        let self_ident = out.ct_build_ident(decl, self_sym)
        let self_field = out.ct_build_field_access(decl, self_ident, field_sym)
        let get_callee = out.ct_build_field_access(decl, self_field, get_sym)
        let idx_ident = out.ct_build_ident(decl, idx_sym)
        let get_args: Vec[i32] = Vec.new()
        get_args.push(idx_ident)
        let get_call = out.ct_build_call(decl, get_callee, get_args)
        get_field_values.push(get_call)
    let get_field_extra = out.extra_len()
    for fi in 0..field_count:
        let field_sym = out.get_extra(type_extra_start + 1 + fi * 3)
        out.add_extra(field_sym)
        out.add_extra(get_field_values.get(fi as i64))
    let get_body = out.add_node(NodeKind.NK_STRUCT_LIT, start, end, type_name_sym, get_field_extra, field_count)
    let get_param_start = out.extra_len()
    out.ct_add_fn_param(self_sym, soa_self_ref_type as i32, FN_PARAM_FLAG_REF_SELF)
    out.ct_add_fn_param(idx_sym, idx_type as i32, 0)
    let get_fn_sym = intern.intern(soa_name ++ ".get")
    let get_fn = out.add_node(NodeKind.NK_FN_DECL, start, end, get_fn_sym, get_body as i32, 0)
    out.add_fn_meta(get_fn, 2 * FN_META_REQUIRED_UNIT, source_type as i32, get_param_start, 2, 0, 0)
    generated.push(get_fn as i32)

    var len_body = out.ct_build_int_lit(decl, 0)
    if field_count > 0:
        let first_field_sym = out.get_extra(type_extra_start + 1)
        let self_ident = out.ct_build_ident(decl, self_sym)
        let self_field = out.ct_build_field_access(decl, self_ident, first_field_sym)
        let len_callee = out.ct_build_field_access(decl, self_field, len_sym)
        let len_args: Vec[i32] = Vec.new()
        len_body = out.ct_build_call(decl, len_callee, len_args)
    let len_param_start = out.extra_len()
    out.ct_add_fn_param(self_sym, soa_self_ref_type as i32, FN_PARAM_FLAG_REF_SELF)
    let len_ret = out.add_node(NodeKind.NK_TYPE_NAMED, start, end, i64_sym, 0, 0)
    let len_fn_sym = intern.intern(soa_name ++ ".len")
    let len_fn = out.add_node(NodeKind.NK_FN_DECL, start, end, len_fn_sym, len_body as i32, 0)
    out.add_fn_meta(len_fn, FN_META_REQUIRED_UNIT, len_ret as i32, len_param_start, 1, 0, 0)
    generated.push(len_fn as i32)

    let impl_extra = out.extra_len()
    out.add_extra(0)
    out.add_extra(4)
    let impl_node = out.add_node(NodeKind.NK_IMPL_DECL, start, end, soa_sym, impl_extra, 0)
    if tp_count > 0:
        let impl_tp_start = ct_copy_type_params(out, tp_start, tp_count)
        out.add_impl_type_params(impl_node, impl_tp_start, tp_count)
        let target_type = ct_build_generic_self_type(out, decl, soa_sym, impl_tp_start, tp_count)
        out.add_impl_target_type_node(impl_node, target_type as NodeId)
    generated.push(impl_node as i32)
    generated

fn Sema.ct_build_default_value_expr(self: Sema, pool: AstPool, intern: InternPool, type_id: i32, type_node_hint: i32, node: i32, tp_start: i32, tp_count: i32) -> i32:
    var tp_sym = ct_type_param_sym_for_type_node(pool, type_node_hint, tp_start, tp_count)
    if tp_sym == 0:
        tp_sym = self.ct_type_param_sym_for_type_id(pool, intern, type_id, tp_start, tp_count)
    let type_node =
        if tp_sym != 0:
            pool.ct_build_ident(node, tp_sym)
        else:
            self.ct_build_type_expr(pool, intern, type_id, node)
    if type_node == 0:
        return 0
    let default_sym = intern.intern("default")
    let callee = pool.add_node(NodeKind.NK_FIELD_ACCESS, pool.get_start(node), pool.get_end(node), type_node, default_sym, 0)
    let no_args: Vec[i32] = Vec.new()
    pool.ct_build_call(node, callee as i32, no_args)

fn ct_add_generated_impl_target(out: AstPool, decl: i32, impl_node: i32, type_name_sym: i32, tp_start: i32, tp_count: i32, trait_sym: i32):
    if tp_count <= 0:
        return
    let impl_tp_start = ct_copy_type_params_with_bound(out, tp_start, tp_count, trait_sym)
    out.add_impl_type_params(impl_node, impl_tp_start, tp_count)
    let target_type = ct_build_generic_self_type(out, decl, type_name_sym, impl_tp_start, tp_count)
    out.add_impl_target_type_node(impl_node, target_type as NodeId)

fn ct_add_marker_impl(out: AstPool, decl: i32, type_name_sym: i32, trait_sym: i32, tp_start: i32, tp_count: i32) -> i32:
    let impl_extra = out.extra_len()
    out.add_extra(0)
    out.add_extra(0)
    let impl_node = out.add_node(NodeKind.NK_IMPL_DECL, out.get_start(decl), out.get_end(decl), type_name_sym, impl_extra, trait_sym)
    ct_add_generated_impl_target(out, decl, impl_node as i32, type_name_sym, tp_start, tp_count, trait_sym)
    impl_node as i32

fn Sema.ct_type_can_supply_derive_trait(self: Sema, out: AstPool, intern: InternPool, tid: i32, trait_sym: i32, all_sym: i32) -> i32:
    if trait_sym == self.syms.copy_trait:
        return self.is_copy(tid as TypeId)
    if trait_sym == self.syms.clone_trait and self.is_copy(tid as TypeId) != 0:
        return 1
    if self.type_implements_trait(tid, trait_sym) != 0:
        return 1
    let resolved = self.resolve_alias(tid as TypeId)
    let type_sym = self.get_type_name(resolved)
    if type_sym != 0 and self.type_decl_nodes.contains(type_sym):
        let decl = self.type_decl_nodes.get(type_sym).unwrap()
        if self.type_decl_has_derive(decl, trait_sym) != 0:
            return 1
        if self.type_decl_has_derive(decl, all_sym) != 0 and self.ct_type_decl_can_derive_trait(out, intern, decl, trait_sym, all_sym) != 0:
            return 1
    0

fn Sema.ct_type_decl_can_derive_trait(self: Sema, out: AstPool, intern: InternPool, decl: i32, trait_sym: i32, all_sym: i32) -> i32:
    if trait_sym == self.syms.copy_trait:
        return 0
    if type_decl_sub_kind(out.get_data2(decl)) != TypeDeclKind.Struct:
        return 0
    let type_name_sym = out.get_data0(decl)
    let tid = self.lookup_named_type_visible(type_name_sym)
    if tid == 0:
        return 0
    let resolved = self.resolve_alias(tid)
    if self.get_type_kind(resolved) != TypeKind.TY_STRUCT:
        return 0
    let te_start = self.get_type_d1(resolved)
    let field_count = self.get_type_d2(resolved)
    for fi in 0..field_count:
        let field_tid = self.type_extra.get((te_start + fi * 3 + 1) as i64)
        if self.ct_type_can_supply_derive_trait(out, intern, field_tid, trait_sym, all_sym) == 0:
            return 0
    1

fn Sema.ct_type_decl_should_generate_derive(self: Sema, out: AstPool, intern: InternPool, decl: i32, trait_sym: i32, all_sym: i32) -> i32:
    if self.type_decl_has_derive(decl, trait_sym) != 0:
        return 1
    if self.type_decl_has_derive(decl, all_sym) != 0 and self.ct_type_decl_can_derive_trait(out, intern, decl, trait_sym, all_sym) != 0:
        return 1
    0

fn ct_build_self_field(out: AstPool, decl: i32, self_sym: i32, field_sym: i32) -> i32:
    let self_ident = out.ct_build_ident(decl, self_sym)
    out.ct_build_field_access(decl, self_ident, field_sym)

fn ct_build_method_call(out: AstPool, decl: i32, receiver: i32, method_sym: i32, args: Vec[i32]) -> i32:
    let callee = out.ct_build_field_access(decl, receiver, method_sym)
    out.ct_build_call(decl, callee, args)

fn Sema.ct_generate_copy_derive(self: Sema, out: AstPool, intern: InternPool, decl: i32) -> Vec[i32]:
    let generated: Vec[i32] = Vec.new()
    let copy_trait_sym = intern.intern("Copy")
    if self.type_decl_has_derive(decl, copy_trait_sym) == 0:
        return generated
    let type_name_sym = out.get_data0(decl)
    if self.select_trait_impl(type_name_sym, copy_trait_sym) != 0:
        return generated
    let tp_count = ct_type_decl_tp_count(out, decl)
    let tp_start = ct_type_decl_tp_start(out, decl)
    generated.push(ct_add_marker_impl(out, decl, type_name_sym, copy_trait_sym, tp_start, tp_count))
    generated

fn Sema.ct_generate_default_derive(self: Sema, out: AstPool, intern: InternPool, decl: i32) -> Vec[i32]:
    let generated: Vec[i32] = Vec.new()
    if type_decl_sub_kind(out.get_data2(decl)) != TypeDeclKind.Struct:
        return generated

    let default_trait_sym = intern.intern("Default")
    let default_method_sym = intern.intern("default")
    let type_name_sym = out.get_data0(decl)
    if self.lookup_method_sig(type_name_sym, default_method_sym) >= 0:
        return generated
    if self.select_trait_impl(type_name_sym, default_trait_sym) != 0:
        return generated

    let tid = self.lookup_named_type_visible(type_name_sym)
    if tid == 0:
        return generated
    let resolved = self.resolve_alias(tid)
    if self.get_type_kind(resolved) != TypeKind.TY_STRUCT:
        return generated

    let start = out.get_start(decl)
    let end = out.get_end(decl)
    let type_name = intern.resolve(type_name_sym)
    let fn_sym = intern.intern(type_name ++ ".default")
    let tp_count = ct_type_decl_tp_count(out, decl)
    let tp_start = ct_type_decl_tp_start(out, decl)
    let ret_type = out.add_node(NodeKind.NK_TYPE_NAMED, start, end, intern.intern("Self"), 0, 0)
    let struct_lit_type = if tp_count > 0: intern.intern("Self") else: type_name_sym

    let te_start = self.get_type_d1(resolved)
    let field_count = self.get_type_d2(resolved)
    let type_extra_start = out.get_data1(decl)
    let field_syms: Vec[i32] = Vec.new()
    let field_values: Vec[i32] = Vec.new()
    for fi in 0..field_count:
        let field_sym = self.type_extra.get((te_start + fi * 3) as i64)
        let field_tid = self.type_extra.get((te_start + fi * 3 + 1) as i64)
        let field_type_node = out.get_extra(type_extra_start + 1 + fi * 3 + 1)
        let field_default = self.ct_build_default_value_expr(out, intern, field_tid, field_type_node, decl, tp_start, tp_count)
        if field_default == 0:
            self.ct_emit_error(out, decl, "could not generate Default field initializer")
            return generated
        field_syms.push(field_sym)
        field_values.push(field_default)
    let field_extra = out.extra_len()
    for fi2 in 0..field_values.len() as i32:
        out.add_extra(field_syms.get(fi2 as i64))
        out.add_extra(field_values.get(fi2 as i64))
    let body = out.add_node(NodeKind.NK_STRUCT_LIT, start, end, struct_lit_type, field_extra, field_count)
    let fn_node = out.add_node(NodeKind.NK_FN_DECL, start, end, fn_sym, body as i32, 0)
    out.add_fn_meta(fn_node, 0, ret_type as i32, out.extra_len(), 0, 0, 0)

    let impl_extra = out.extra_len()
    out.add_extra(0)
    out.add_extra(1)
    let impl_node = out.add_node(NodeKind.NK_IMPL_DECL, start, end, type_name_sym, impl_extra, default_trait_sym)
    if tp_count > 0:
        let impl_tp_start = ct_copy_type_params_with_bound(out, tp_start, tp_count, default_trait_sym)
        out.add_impl_type_params(impl_node, impl_tp_start, tp_count)
        let target_type = ct_build_generic_self_type(out, decl, type_name_sym, impl_tp_start, tp_count)
        out.add_impl_target_type_node(impl_node, target_type as NodeId)

    generated.push(fn_node as i32)
    generated.push(impl_node as i32)
    generated

fn Sema.ct_generate_eq_derive(self: Sema, out: AstPool, intern: InternPool, decl: i32) -> Vec[i32]:
    let generated: Vec[i32] = Vec.new()
    if type_decl_sub_kind(out.get_data2(decl)) != TypeDeclKind.Struct:
        return generated

    let eq_trait_sym = intern.intern("Eq")
    let eq_method_sym = intern.intern("eq")
    let type_name_sym = out.get_data0(decl)
    if self.lookup_method_sig(type_name_sym, eq_method_sym) >= 0:
        return generated
    if self.select_trait_impl(type_name_sym, eq_trait_sym) != 0:
        return generated

    let tid = self.lookup_named_type_visible(type_name_sym)
    if tid == 0:
        return generated
    let resolved = self.resolve_alias(tid)
    if self.get_type_kind(resolved) != TypeKind.TY_STRUCT:
        return generated

    let type_name = intern.resolve(type_name_sym)
    let start = out.get_start(decl)
    let end = out.get_end(decl)
    let self_sym = intern.intern("self")
    let other_sym = intern.intern("other")
    let bool_sym = intern.intern("bool")
    let tp_count = ct_type_decl_tp_count(out, decl)
    let tp_start = ct_type_decl_tp_start(out, decl)
    let self_type = out.add_node(NodeKind.NK_TYPE_NAMED, start, end, intern.intern("Self"), 0, 0)
    let other_type = out.add_node(NodeKind.NK_TYPE_NAMED, start, end, intern.intern("Self"), 0, 0)
    let ret_type = out.add_node(NodeKind.NK_TYPE_NAMED, start, end, bool_sym, 0, 0)

    let te_start = self.get_type_d1(resolved)
    let field_count = self.get_type_d2(resolved)
    var body = out.ct_build_bool_lit(decl, true)
    var first = true
    for fi in 0..field_count:
        let field_sym = self.type_extra.get((te_start + fi * 3) as i64)
        let lhs_field = ct_build_self_field(out, decl, self_sym, field_sym)
        let other_ident = out.ct_build_ident(decl, other_sym)
        let rhs_field = out.ct_build_field_access(decl, other_ident, field_sym)
        let args: Vec[i32] = Vec.new()
        args.push(rhs_field)
        let eq_call = ct_build_method_call(out, decl, lhs_field, eq_method_sym, args)
        if first:
            body = eq_call
            first = false
        else:
            body = out.ct_build_binary(decl, BinaryOp.OP_AND, body, eq_call)

    let param_start = out.extra_len()
    out.ct_add_fn_param(self_sym, self_type as i32, FN_PARAM_FLAG_MOVE_SELF)
    out.ct_add_fn_param(other_sym, other_type as i32, 0)
    let fn_sym = intern.intern(type_name ++ ".eq")
    let fn_node = out.add_node(NodeKind.NK_FN_DECL, start, end, fn_sym, body as i32, 0)
    out.add_fn_meta(fn_node, 2 * FN_META_REQUIRED_UNIT, ret_type as i32, param_start, 2, 0, 0)

    let impl_extra = out.extra_len()
    out.add_extra(0)
    out.add_extra(1)
    let impl_node = out.add_node(NodeKind.NK_IMPL_DECL, start, end, type_name_sym, impl_extra, eq_trait_sym)
    ct_add_generated_impl_target(out, decl, impl_node as i32, type_name_sym, tp_start, tp_count, eq_trait_sym)

    generated.push(fn_node as i32)
    generated.push(impl_node as i32)
    generated

fn Sema.ct_generate_hash_derive(self: Sema, out: AstPool, intern: InternPool, decl: i32) -> Vec[i32]:
    let generated: Vec[i32] = Vec.new()
    if type_decl_sub_kind(out.get_data2(decl)) != TypeDeclKind.Struct:
        return generated

    let hash_trait_sym = intern.intern("Hash")
    let hash_method_sym = intern.intern("hash_value")
    let type_name_sym = out.get_data0(decl)
    if self.lookup_method_sig(type_name_sym, hash_method_sym) >= 0:
        return generated
    if self.select_trait_impl(type_name_sym, hash_trait_sym) != 0:
        return generated

    let tid = self.lookup_named_type_visible(type_name_sym)
    if tid == 0:
        return generated
    let resolved = self.resolve_alias(tid)
    if self.get_type_kind(resolved) != TypeKind.TY_STRUCT:
        return generated

    let type_name = intern.resolve(type_name_sym)
    let start = out.get_start(decl)
    let end = out.get_end(decl)
    let self_sym = intern.intern("self")
    let i64_sym = intern.intern("i64")
    let tp_count = ct_type_decl_tp_count(out, decl)
    let tp_start = ct_type_decl_tp_start(out, decl)
    let self_type = out.add_node(NodeKind.NK_TYPE_NAMED, start, end, intern.intern("Self"), 0, 0)
    let ret_type = out.add_node(NodeKind.NK_TYPE_NAMED, start, end, i64_sym, 0, 0)

    let te_start = self.get_type_d1(resolved)
    let field_count = self.get_type_d2(resolved)
    var body = out.ct_build_int_lit(decl, 1469598103934665603)
    for fi in 0..field_count:
        let field_sym = self.type_extra.get((te_start + fi * 3) as i64)
        let field_expr = ct_build_self_field(out, decl, self_sym, field_sym)
        let no_args: Vec[i32] = Vec.new()
        let field_hash = ct_build_method_call(out, decl, field_expr, hash_method_sym, no_args)
        let mixed = out.ct_build_binary(decl, BinaryOp.OP_MUL_WRAP, body, out.ct_build_int_lit(decl, 1099511628211))
        body = out.ct_build_binary(decl, BinaryOp.OP_BIT_XOR, mixed, field_hash)

    let param_start = out.extra_len()
    out.ct_add_fn_param(self_sym, self_type as i32, FN_PARAM_FLAG_MOVE_SELF)
    let fn_sym = intern.intern(type_name ++ ".hash_value")
    let fn_node = out.add_node(NodeKind.NK_FN_DECL, start, end, fn_sym, body as i32, 0)
    out.add_fn_meta(fn_node, FN_META_REQUIRED_UNIT, ret_type as i32, param_start, 1, 0, 0)

    let impl_extra = out.extra_len()
    out.add_extra(0)
    out.add_extra(1)
    let impl_node = out.add_node(NodeKind.NK_IMPL_DECL, start, end, type_name_sym, impl_extra, hash_trait_sym)
    ct_add_generated_impl_target(out, decl, impl_node as i32, type_name_sym, tp_start, tp_count, hash_trait_sym)

    generated.push(fn_node as i32)
    generated.push(impl_node as i32)
    generated

fn ct_build_concat(out: AstPool, decl: i32, lhs: i32, rhs: i32) -> i32:
    out.ct_build_binary(decl, BinaryOp.OP_CONCAT, lhs, rhs)

fn Sema.ct_generate_debug_derive(self: Sema, out: AstPool, intern: InternPool, decl: i32) -> Vec[i32]:
    let generated: Vec[i32] = Vec.new()
    if type_decl_sub_kind(out.get_data2(decl)) != TypeDeclKind.Struct:
        return generated

    let debug_trait_sym = intern.intern("Debug")
    let debug_method_sym = intern.intern("debug_str")
    let type_name_sym = out.get_data0(decl)
    if self.lookup_method_sig(type_name_sym, debug_method_sym) >= 0:
        return generated
    if self.select_trait_impl(type_name_sym, debug_trait_sym) != 0:
        return generated

    let tid = self.lookup_named_type_visible(type_name_sym)
    if tid == 0:
        return generated
    let resolved = self.resolve_alias(tid)
    if self.get_type_kind(resolved) != TypeKind.TY_STRUCT:
        return generated

    let type_name = intern.resolve(type_name_sym)
    let start = out.get_start(decl)
    let end = out.get_end(decl)
    let self_sym = intern.intern("self")
    let str_sym = intern.intern("str")
    let tp_count = ct_type_decl_tp_count(out, decl)
    let tp_start = ct_type_decl_tp_start(out, decl)
    let self_type = out.add_node(NodeKind.NK_TYPE_NAMED, start, end, intern.intern("Self"), 0, 0)
    let ret_type = out.add_node(NodeKind.NK_TYPE_NAMED, start, end, str_sym, 0, 0)

    let te_start = self.get_type_d1(resolved)
    let field_count = self.get_type_d2(resolved)
    var body = out.ct_build_string_lit(intern, decl, type_name ++ " {")
    for fi in 0..field_count:
        let field_sym = self.type_extra.get((te_start + fi * 3) as i64)
        let prefix = if fi == 0: " " else: ", "
        body = ct_build_concat(out, decl, body, out.ct_build_string_lit(intern, decl, prefix ++ intern.resolve(field_sym) ++ ": "))
        let field_expr = ct_build_self_field(out, decl, self_sym, field_sym)
        let no_args: Vec[i32] = Vec.new()
        let field_debug = ct_build_method_call(out, decl, field_expr, debug_method_sym, no_args)
        body = ct_build_concat(out, decl, body, field_debug)
    body = ct_build_concat(out, decl, body, out.ct_build_string_lit(intern, decl, " }"))

    let param_start = out.extra_len()
    out.ct_add_fn_param(self_sym, self_type as i32, FN_PARAM_FLAG_MOVE_SELF)
    let fn_sym = intern.intern(type_name ++ ".debug_str")
    let fn_node = out.add_node(NodeKind.NK_FN_DECL, start, end, fn_sym, body as i32, 0)
    out.add_fn_meta(fn_node, FN_META_REQUIRED_UNIT, ret_type as i32, param_start, 1, 0, 0)

    let impl_extra = out.extra_len()
    out.add_extra(0)
    out.add_extra(1)
    let impl_node = out.add_node(NodeKind.NK_IMPL_DECL, start, end, type_name_sym, impl_extra, debug_trait_sym)
    ct_add_generated_impl_target(out, decl, impl_node as i32, type_name_sym, tp_start, tp_count, debug_trait_sym)

    generated.push(fn_node as i32)
    generated.push(impl_node as i32)
    generated

fn Sema.ct_generate_clone_derive(self: Sema, out: AstPool, intern: InternPool, decl: i32) -> Vec[i32]:
    let generated: Vec[i32] = Vec.new()
    if type_decl_sub_kind(out.get_data2(decl)) != TypeDeclKind.Struct:
        return generated

    let clone_trait_sym = intern.intern("Clone")
    let clone_method_sym = intern.intern("clone")
    let type_name_sym = out.get_data0(decl)
    if self.lookup_method_sig(type_name_sym, clone_method_sym) >= 0:
        return generated
    if self.select_trait_impl(type_name_sym, clone_trait_sym) != 0:
        return generated

    let tid = self.lookup_named_type_visible(type_name_sym)
    if tid == 0:
        return generated
    let resolved = self.resolve_alias(tid)
    if self.get_type_kind(resolved) != TypeKind.TY_STRUCT:
        return generated

    let type_name = intern.resolve(type_name_sym)
    let start = out.get_start(decl)
    let end = out.get_end(decl)
    let self_sym = intern.intern("self")
    let self_type_sym = intern.intern("Self")
    let tp_count = ct_type_decl_tp_count(out, decl)
    let tp_start = ct_type_decl_tp_start(out, decl)
    let ret_type = out.add_node(NodeKind.NK_TYPE_NAMED, start, end, self_type_sym, 0, 0)
    let struct_lit_type = if tp_count > 0: self_type_sym else: type_name_sym

    let te_start = self.get_type_d1(resolved)
    let field_count = self.get_type_d2(resolved)
    let field_syms: Vec[i32] = Vec.new()
    let field_values: Vec[i32] = Vec.new()
    for fi in 0..field_count:
        let field_sym = self.type_extra.get((te_start + fi * 3) as i64)
        let field_tid = self.type_extra.get((te_start + fi * 3 + 1) as i64)
        let field_expr = ct_build_self_field(out, decl, self_sym, field_sym)
        let field_value =
            if self.is_copy(field_tid as TypeId) != 0:
                field_expr
            else:
                let no_args: Vec[i32] = Vec.new()
                ct_build_method_call(out, decl, field_expr, clone_method_sym, no_args)
        field_syms.push(field_sym)
        field_values.push(field_value)

    let field_extra = out.extra_len()
    for fi2 in 0..field_values.len() as i32:
        out.add_extra(field_syms.get(fi2 as i64))
        out.add_extra(field_values.get(fi2 as i64))
    let body = out.add_node(NodeKind.NK_STRUCT_LIT, start, end, struct_lit_type, field_extra, field_count)
    let self_pointee_type = out.add_node(NodeKind.NK_TYPE_NAMED, start, end, self_type_sym, 0, 0)
    let self_param_type = out.add_node(NodeKind.NK_TYPE_REF, start, end, self_pointee_type as i32, 0, 0)
    let param_start = out.extra_len()
    out.ct_add_fn_param(self_sym, self_param_type as i32, FN_PARAM_FLAG_REF_SELF)

    let fn_sym = intern.intern(type_name ++ ".clone")
    let fn_node = out.add_node(NodeKind.NK_FN_DECL, start, end, fn_sym, body as i32, 0)
    out.add_fn_meta(fn_node, FN_META_REQUIRED_UNIT, ret_type as i32, param_start, 1, 0, 0)

    let impl_extra = out.extra_len()
    out.add_extra(0)
    out.add_extra(1)
    let impl_node = out.add_node(NodeKind.NK_IMPL_DECL, start, end, type_name_sym, impl_extra, clone_trait_sym)
    ct_add_generated_impl_target(out, decl, impl_node as i32, type_name_sym, tp_start, tp_count, clone_trait_sym)

    generated.push(fn_node as i32)
    generated.push(impl_node as i32)
    generated

fn Sema.ct_generate_serialize_derive(self: Sema, out: AstPool, intern: InternPool, decl: i32) -> Vec[i32]:
    let generated: Vec[i32] = Vec.new()
    if type_decl_sub_kind(out.get_data2(decl)) != TypeDeclKind.Struct:
        return generated

    let serialize_trait_sym = intern.intern("Serialize")
    let serialize_method_sym = intern.intern("serialize")
    let type_name_sym = out.get_data0(decl)
    if self.lookup_method_sig(type_name_sym, serialize_method_sym) >= 0:
        return generated
    if self.select_trait_impl(type_name_sym, serialize_trait_sym) != 0:
        return generated

    let type_name = intern.resolve(type_name_sym)
    let start = out.get_start(decl)
    let end = out.get_end(decl)
    let self_sym = intern.intern("self")
    let self_type_sym = intern.intern("Self")
    let out_sym = intern.intern("out")
    let json_writer_sym = intern.intern("JsonWriter")
    let begin_object_sym = intern.intern("begin_object")
    let end_object_sym = intern.intern("end_object")
    let key_sym = intern.intern("key")

    let tp_count = ct_type_decl_tp_count(out, decl)
    let tp_start = ct_type_decl_tp_start(out, decl)
    let self_type = ct_build_generic_self_type(out, decl, type_name_sym, tp_start, tp_count)
    let self_ref_type = out.add_node(NodeKind.NK_TYPE_REF, start, end, self_type as i32, 0, 0)
    let writer_type = out.add_node(NodeKind.NK_TYPE_NAMED, start, end, json_writer_sym, 0, 0)

    let out_ident = out.ct_build_ident(decl, out_sym)
    let begin_callee = out.ct_build_field_access(decl, out_ident, begin_object_sym)
    let no_args: Vec[i32] = Vec.new()
    var writer_expr = out.ct_build_call(decl, begin_callee, no_args)

    let type_extra_start = out.get_data1(decl)
    let field_count = out.get_extra(type_extra_start)
    for fi in 0..field_count:
        let field_sym = out.get_extra(type_extra_start + 1 + fi * 3)
        let key_callee = out.ct_build_field_access(decl, writer_expr, key_sym)
        let key_args: Vec[i32] = Vec.new()
        key_args.push(out.ct_build_string_lit(intern, decl, intern.resolve(field_sym)))
        writer_expr = out.ct_build_call(decl, key_callee, key_args)

        let self_ident = out.ct_build_ident(decl, self_sym)
        let self_field = out.ct_build_field_access(decl, self_ident, field_sym)
        let serialize_callee = out.ct_build_field_access(decl, self_field, serialize_method_sym)
        let serialize_args: Vec[i32] = Vec.new()
        serialize_args.push(writer_expr)
        writer_expr = out.ct_build_call(decl, serialize_callee, serialize_args)

    let end_callee = out.ct_build_field_access(decl, writer_expr, end_object_sym)
    let body = out.ct_build_call(decl, end_callee, no_args)

    let param_start = out.extra_len()
    out.ct_add_fn_param(self_sym, self_ref_type as i32, FN_PARAM_FLAG_REF_SELF)
    out.ct_add_fn_param(out_sym, writer_type as i32, 0)
    let fn_sym = intern.intern(type_name ++ ".serialize")
    let fn_node = out.add_node(NodeKind.NK_FN_DECL, start, end, fn_sym, body as i32, 0)
    out.add_fn_meta(fn_node, 2 * FN_META_REQUIRED_UNIT, writer_type as i32, param_start, 2, 0, 0)

    let impl_extra = out.extra_len()
    out.add_extra(0)
    out.add_extra(1)
    let impl_node = out.add_node(NodeKind.NK_IMPL_DECL, start, end, type_name_sym, impl_extra, serialize_trait_sym)
    if tp_count > 0:
        let impl_tp_start = ct_copy_type_params_with_bound(out, tp_start, tp_count, serialize_trait_sym)
        out.add_impl_type_params(impl_node, impl_tp_start, tp_count)
        let target_type = ct_build_generic_self_type(out, decl, type_name_sym, impl_tp_start, tp_count)
        out.add_impl_target_type_node(impl_node, target_type as NodeId)

    generated.push(fn_node as i32)
    generated.push(impl_node as i32)
    generated

fn Sema.ct_generate_deserialize_derive(self: Sema, out: AstPool, intern: InternPool, decl: i32) -> Vec[i32]:
    let generated: Vec[i32] = Vec.new()
    if type_decl_sub_kind(out.get_data2(decl)) != TypeDeclKind.Struct:
        return generated

    let deserialize_trait_sym = intern.intern("Deserialize")
    let deserialize_method_sym = intern.intern("deserialize")
    let type_name_sym = out.get_data0(decl)
    if self.lookup_method_sig(type_name_sym, deserialize_method_sym) >= 0:
        return generated
    if self.select_trait_impl(type_name_sym, deserialize_trait_sym) != 0:
        return generated

    let tid = self.lookup_named_type_visible(type_name_sym)
    if tid == 0:
        return generated
    let resolved = self.resolve_alias(tid)
    if self.get_type_kind(resolved) != TypeKind.TY_STRUCT:
        return generated

    let type_name = intern.resolve(type_name_sym)
    let start = out.get_start(decl)
    let end = out.get_end(decl)
    let input_sym = intern.intern("input")
    let self_type_sym = intern.intern("Self")
    let json_view_sym = intern.intern("JsonView")
    let field_method_sym = intern.intern("field")

    let tp_count = ct_type_decl_tp_count(out, decl)
    let tp_start = ct_type_decl_tp_start(out, decl)
    let ret_type = out.add_node(NodeKind.NK_TYPE_NAMED, start, end, self_type_sym, 0, 0)
    let input_type = out.add_node(NodeKind.NK_TYPE_NAMED, start, end, json_view_sym, 0, 0)
    let struct_lit_type = if tp_count > 0: self_type_sym else: type_name_sym

    let te_start = self.get_type_d1(resolved)
    let field_count = self.get_type_d2(resolved)
    let type_extra_start = out.get_data1(decl)
    let field_syms: Vec[i32] = Vec.new()
    let field_values: Vec[i32] = Vec.new()
    for fi in 0..field_count:
        let field_sym = self.type_extra.get((te_start + fi * 3) as i64)
        let field_tid = self.type_extra.get((te_start + fi * 3 + 1) as i64)
        let field_type_node_hint = out.get_extra(type_extra_start + 1 + fi * 3 + 1)
        let field_type = self.ct_build_type_expr_with_hint(out, intern, field_tid, field_type_node_hint, decl)
        if field_type == 0:
            self.ct_emit_error(out, decl, "could not generate Deserialize field type")
            return generated
        let input_ident = out.ct_build_ident(decl, input_sym)
        let field_callee = out.ct_build_field_access(decl, input_ident, field_method_sym)
        let field_args: Vec[i32] = Vec.new()
        field_args.push(out.ct_build_string_lit(intern, decl, intern.resolve(field_sym)))
        let field_view = out.ct_build_call(decl, field_callee, field_args)
        let deserialize_callee = out.ct_build_field_access(decl, field_type, deserialize_method_sym)
        let deserialize_args: Vec[i32] = Vec.new()
        deserialize_args.push(field_view)
        let field_value = out.ct_build_call(decl, deserialize_callee, deserialize_args)
        field_syms.push(field_sym)
        field_values.push(field_value)

    let field_extra = out.extra_len()
    for fi2 in 0..field_values.len() as i32:
        out.add_extra(field_syms.get(fi2 as i64))
        out.add_extra(field_values.get(fi2 as i64))
    let body = out.add_node(NodeKind.NK_STRUCT_LIT, start, end, struct_lit_type, field_extra, field_count)
    let param_start = out.extra_len()
    out.ct_add_fn_param(input_sym, input_type as i32, 0)
    let fn_sym = intern.intern(type_name ++ ".deserialize")
    let fn_node = out.add_node(NodeKind.NK_FN_DECL, start, end, fn_sym, body as i32, 0)
    out.add_fn_meta(fn_node, FN_META_REQUIRED_UNIT, ret_type as i32, param_start, 1, 0, 0)

    let impl_extra = out.extra_len()
    out.add_extra(0)
    out.add_extra(1)
    let impl_node = out.add_node(NodeKind.NK_IMPL_DECL, start, end, type_name_sym, impl_extra, deserialize_trait_sym)
    if tp_count > 0:
        let impl_tp_start = ct_copy_type_params_with_bound(out, tp_start, tp_count, deserialize_trait_sym)
        out.add_impl_type_params(impl_node, impl_tp_start, tp_count)
        let target_type = ct_build_generic_self_type(out, decl, type_name_sym, impl_tp_start, tp_count)
        out.add_impl_target_type_node(impl_node, target_type as NodeId)

    generated.push(fn_node as i32)
    generated.push(impl_node as i32)
    generated

fn Sema.ct_generate_component_id_derive(self: Sema, out: AstPool, intern: InternPool, decl: i32) -> Vec[i32]:
    let generated: Vec[i32] = Vec.new()
    if type_decl_sub_kind(out.get_data2(decl)) != TypeDeclKind.Struct:
        return generated

    let component_trait_sym = intern.intern("ComponentId")
    let component_method_sym = intern.intern("component_id")
    let type_name_sym = out.get_data0(decl)
    if self.lookup_method_sig(type_name_sym, component_method_sym) >= 0:
        return generated
    if self.select_trait_impl(type_name_sym, component_trait_sym) != 0:
        return generated

    let type_name = intern.resolve(type_name_sym)
    let start = out.get_start(decl)
    let end = out.get_end(decl)
    let i64_sym = intern.intern("i64")
    let tp_count = ct_type_decl_tp_count(out, decl)
    if tp_count > 0:
        self.ct_emit_error(out, decl, "derive ComponentId requires a concrete struct")
        return generated

    let body = out.ct_build_int_lit(decl, ct_component_id_value(type_name))
    let ret_type = out.add_node(NodeKind.NK_TYPE_NAMED, start, end, i64_sym, 0, 0)
    let fn_sym = intern.intern(type_name ++ ".component_id")
    let fn_node = out.add_node(NodeKind.NK_FN_DECL, start, end, fn_sym, body as i32, 0)
    out.add_fn_meta(fn_node, 0, ret_type as i32, out.extra_len(), 0, 0, 0)

    let impl_extra = out.extra_len()
    out.add_extra(0)
    out.add_extra(1)
    let impl_node = out.add_node(NodeKind.NK_IMPL_DECL, start, end, type_name_sym, impl_extra, component_trait_sym)

    generated.push(fn_node as i32)
    generated.push(impl_node as i32)
    generated

fn Sema.ct_transform_decl(mut self: Sema, source_ast: AstPool, pool: AstPool, intern: InternPool, node: i32):
    let kind = pool.kind(node)
    if kind == NodeKind.NK_FN_DECL:
        let body = pool.get_data1(node)
        if body != 0:
            pool.set_data1(node, self.ct_transform_expr(source_ast, pool, intern, body))
        self.ct_transform_fn_param_defaults(source_ast, pool, intern, node)
        return
    if kind == NodeKind.NK_LET_DECL:
        let value = pool.get_data1(node)
        if value != 0:
            pool.set_data1(node, self.ct_transform_expr(source_ast, pool, intern, value))
        return
    if kind == NodeKind.NK_TYPE_DECL:
        self.ct_transform_type_decl(source_ast, pool, intern, node)
        return
    if kind == NodeKind.NK_TRAIT_DECL:
        self.ct_transform_trait_decl(source_ast, pool, intern, node)
        return

fn Sema.comptime_transform_module(mut self: Sema, source_ast: AstPool, intern: InternPool) -> AstPool:
    var out = astpool_clone_deep(source_ast)

    let all_sym = intern.intern("all")
    let copy_trait_sym = intern.intern("Copy")
    let clone_trait_sym = intern.intern("Clone")
    let default_trait_sym = intern.intern("Default")
    let eq_trait_sym = intern.intern("Eq")
    let hash_trait_sym = intern.intern("Hash")
    let debug_trait_sym = intern.intern("Debug")
    let soa_trait_sym = intern.intern("SoA")
    let serialize_trait_sym = intern.intern("Serialize")
    let deserialize_trait_sym = intern.intern("Deserialize")
    let component_id_trait_sym = intern.intern("ComponentId")

    let ordered: Vec[i32] = Vec.new()
    let ordered_paths: Vec[str] = Vec.new()
    let ordered_file_ids: Vec[i32] = Vec.new()
    let ordered_ci: Vec[i32] = Vec.new()
    let base_decl_count = out.decl_count()
    var generated_local_count = 0

    for di in 0..base_decl_count:
        let decl = out.get_decl(di)
        let decl_path = self.ct_decl_source_path(di)
        let decl_file_id = self.ct_decl_source_file_id(di)
        let decl_ci = self.ct_decl_is_c_import(di)

        ordered.push(decl as i32)
        ordered_paths.push(decl_path)
        ordered_file_ids.push(decl_file_id)
        ordered_ci.push(decl_ci)

        if out.kind(decl) != NodeKind.NK_TYPE_DECL:
            continue
        if self.type_decl_has_derive(decl as i32, copy_trait_sym) != 0:
            let generated_copy = self.ct_generate_copy_derive(out, intern, decl as i32)
            for gi in 0..generated_copy.len() as i32:
                ordered.push(generated_copy.get(gi as i64))
                ordered_paths.push(decl_path)
                ordered_file_ids.push(decl_file_id)
                ordered_ci.push(decl_ci)
            if ct_source_decl_is_local(source_ast, di) != 0:
                generated_local_count = generated_local_count + generated_copy.len() as i32
        if self.ct_type_decl_should_generate_derive(out, intern, decl as i32, default_trait_sym, all_sym) != 0:
            let generated_defaults = self.ct_generate_default_derive(out, intern, decl as i32)
            for gi in 0..generated_defaults.len() as i32:
                ordered.push(generated_defaults.get(gi as i64))
                ordered_paths.push(decl_path)
                ordered_file_ids.push(decl_file_id)
                ordered_ci.push(decl_ci)
            if ct_source_decl_is_local(source_ast, di) != 0:
                generated_local_count = generated_local_count + generated_defaults.len() as i32
        if self.ct_type_decl_should_generate_derive(out, intern, decl as i32, eq_trait_sym, all_sym) != 0:
            let generated_eq = self.ct_generate_eq_derive(out, intern, decl as i32)
            for gi in 0..generated_eq.len() as i32:
                ordered.push(generated_eq.get(gi as i64))
                ordered_paths.push(decl_path)
                ordered_file_ids.push(decl_file_id)
                ordered_ci.push(decl_ci)
            if ct_source_decl_is_local(source_ast, di) != 0:
                generated_local_count = generated_local_count + generated_eq.len() as i32
        if self.ct_type_decl_should_generate_derive(out, intern, decl as i32, hash_trait_sym, all_sym) != 0:
            let generated_hash = self.ct_generate_hash_derive(out, intern, decl as i32)
            for gi in 0..generated_hash.len() as i32:
                ordered.push(generated_hash.get(gi as i64))
                ordered_paths.push(decl_path)
                ordered_file_ids.push(decl_file_id)
                ordered_ci.push(decl_ci)
            if ct_source_decl_is_local(source_ast, di) != 0:
                generated_local_count = generated_local_count + generated_hash.len() as i32
        if self.ct_type_decl_should_generate_derive(out, intern, decl as i32, debug_trait_sym, all_sym) != 0:
            let generated_debug = self.ct_generate_debug_derive(out, intern, decl as i32)
            for gi in 0..generated_debug.len() as i32:
                ordered.push(generated_debug.get(gi as i64))
                ordered_paths.push(decl_path)
                ordered_file_ids.push(decl_file_id)
                ordered_ci.push(decl_ci)
            if ct_source_decl_is_local(source_ast, di) != 0:
                generated_local_count = generated_local_count + generated_debug.len() as i32
        if self.ct_type_decl_should_generate_derive(out, intern, decl as i32, clone_trait_sym, all_sym) != 0:
            let generated_clone = self.ct_generate_clone_derive(out, intern, decl as i32)
            for gi in 0..generated_clone.len() as i32:
                ordered.push(generated_clone.get(gi as i64))
                ordered_paths.push(decl_path)
                ordered_file_ids.push(decl_file_id)
                ordered_ci.push(decl_ci)
            if ct_source_decl_is_local(source_ast, di) != 0:
                generated_local_count = generated_local_count + generated_clone.len() as i32
        if self.type_decl_has_derive(decl as i32, soa_trait_sym) != 0:
            let generated_soa = self.ct_generate_soa_derive(out, intern, decl as i32)
            for gi in 0..generated_soa.len() as i32:
                ordered.push(generated_soa.get(gi as i64))
                ordered_paths.push(decl_path)
                ordered_file_ids.push(decl_file_id)
                ordered_ci.push(decl_ci)
            if ct_source_decl_is_local(source_ast, di) != 0:
                generated_local_count = generated_local_count + generated_soa.len() as i32
        if self.type_decl_has_derive(decl as i32, serialize_trait_sym) != 0:
            let generated_serialize = self.ct_generate_serialize_derive(out, intern, decl as i32)
            for gi in 0..generated_serialize.len() as i32:
                ordered.push(generated_serialize.get(gi as i64))
                ordered_paths.push(decl_path)
                ordered_file_ids.push(decl_file_id)
                ordered_ci.push(decl_ci)
            if ct_source_decl_is_local(source_ast, di) != 0:
                generated_local_count = generated_local_count + generated_serialize.len() as i32
        if self.type_decl_has_derive(decl as i32, deserialize_trait_sym) != 0:
            let generated_deserialize = self.ct_generate_deserialize_derive(out, intern, decl as i32)
            for gi in 0..generated_deserialize.len() as i32:
                ordered.push(generated_deserialize.get(gi as i64))
                ordered_paths.push(decl_path)
                ordered_file_ids.push(decl_file_id)
                ordered_ci.push(decl_ci)
            if ct_source_decl_is_local(source_ast, di) != 0:
                generated_local_count = generated_local_count + generated_deserialize.len() as i32
        if self.type_decl_has_derive(decl as i32, component_id_trait_sym) != 0:
            let generated_component_id = self.ct_generate_component_id_derive(out, intern, decl as i32)
            for gi in 0..generated_component_id.len() as i32:
                ordered.push(generated_component_id.get(gi as i64))
                ordered_paths.push(decl_path)
                ordered_file_ids.push(decl_file_id)
                ordered_ci.push(decl_ci)
            if ct_source_decl_is_local(source_ast, di) != 0:
                generated_local_count = generated_local_count + generated_component_id.len() as i32
    while out.decl_count() > 0:
        out.state.decls.pop()
    for oi in 0..ordered.len() as i32:
        out.add_decl(ordered.get(oi as i64))

    let local_limit = source_ast.local_decl_count()
    if local_limit >= 0:
        out.set_local_decl_count(local_limit + generated_local_count)

    self.decl_source_paths = ordered_paths
    self.decl_source_file_ids = ordered_file_ids
    self.decl_is_c_import = ordered_ci

    let transform_pool = intern
    var transform_sema = Sema.init(transform_pool, self.diags, out)
    transform_sema.source_text = self.source_text
    transform_sema.decl_source_paths = self.decl_source_paths
    transform_sema.decl_source_file_ids = self.decl_source_file_ids
    transform_sema.decl_is_c_import = self.decl_is_c_import
    transform_sema.module_paths = self.module_paths
    transform_sema.module_import_starts = self.module_import_starts
    transform_sema.module_import_counts = self.module_import_counts
    transform_sema.module_import_targets = self.module_import_targets
    transform_sema.module_index_by_path = self.module_index_by_path
    transform_sema.global_visible_module_paths = self.global_visible_module_paths
    transform_sema.module_visibility_cache = HashMap.new()
    transform_sema.prepare_for_comptime_transform()
    if transform_sema.diags.has_errors():
        self.diags = transform_sema.diags
        return out

    for di in 0..out.decl_count():
        transform_sema.update_decl_source_context(di)
        let decl = out.get_decl(di)
        let live_ast = out
        transform_sema.ct_transform_decl(live_ast, out, intern, decl as i32)
    self.diags = transform_sema.diags
    out
