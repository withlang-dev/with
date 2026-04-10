// MirLower — Wave 7 MIR lowering from typed AST sidecars.
//
// This pass builds explicit control-flow MIR from the semantic result.

use Ast
use InternPool
use Mir
use Sema

// ── Builder state ────────────────────────────────────────────────

type ScopeEntry {
    local_id: i32,
    drop_kind: i32,
}

type DropScope {
    drops: Vec[ScopeEntry],
}

type LoopInfo {
    continue_bb: i32,
    break_bb: i32,
    break_drop_depth: i32,
}

type MirBuilder {
    body: MirBody,
    cur_bb: BlockId,

    // Drop scope stack (flat storage + per-scope start offsets).
    drop_local_ids: Vec[i32],
    drop_kinds: Vec[i32],
    drop_scope_starts: Vec[i32],

    // Lexical local bindings (sym -> local id), scoped.
    bind_syms: Vec[i32],
    bind_local_ids: Vec[i32],
    bind_scope_starts: Vec[i32],
    // Non-owning lexical aliases (sym -> place), scoped.
    alias_syms: Vec[i32],
    alias_places: Vec[i32],
    alias_types: Vec[i32],
    alias_scope_starts: Vec[i32],

    // Defer/errdefer stacks (body AST nodes).
    defer_nodes: Vec[i32],
    defer_scope_starts: Vec[i32],
    errdefer_nodes: Vec[i32],
    errdefer_scope_starts: Vec[i32],

    // Loop stack.
    loop_continue_bbs: Vec[i32],
    loop_break_bbs: Vec[i32],
    loop_break_drop_depths: Vec[i32],

    next_temp: i32,
    cur_node: i32,
    expected_type: i32,

    sema: Sema,
    ast: AstPool,
    pool: InternPool,
}

fn MirBuilder.init(sema: Sema, ast: AstPool, pool: InternPool, fn_sym: i32) -> MirBuilder:
    var body = MirBody.init(fn_sym, sema)
    let entry = body.new_block()
    MirBuilder {
        body,
        cur_bb: entry,
        drop_local_ids: Vec.new(),
        drop_kinds: Vec.new(),
        drop_scope_starts: Vec.new(),
        bind_syms: Vec.new(),
        bind_local_ids: Vec.new(),
        bind_scope_starts: Vec.new(),
        alias_syms: Vec.new(),
        alias_places: Vec.new(),
        alias_types: Vec.new(),
        alias_scope_starts: Vec.new(),
        defer_nodes: Vec.new(),
        defer_scope_starts: Vec.new(),
        errdefer_nodes: Vec.new(),
        errdefer_scope_starts: Vec.new(),
        loop_continue_bbs: Vec.new(),
        loop_break_bbs: Vec.new(),
        loop_break_drop_depths: Vec.new(),
        next_temp: 0,
        cur_node: 0,
        expected_type: 0,
        sema,
        ast,
        pool,
    }

fn MirBuilder.new_block(self: MirBuilder) -> BlockId:
    self.body.new_block()

fn MirBuilder.switch_to(self: MirBuilder, bb: BlockId):
    self.cur_bb = bb

fn MirBuilder.terminate(self: MirBuilder, kind: i32, d0: i32, d1: i32, d2: i32, d3: i32):
    let span = if self.cur_node > 0: self.ast.get_start(self.cur_node) else: 0
    self.body.set_terminator(self.cur_bb, kind, d0, d1, d2, d3, span)

fn MirBuilder.terminate_with_span(self: MirBuilder, kind: i32, d0: i32, d1: i32, d2: i32, d3: i32, span: i32):
    self.body.set_terminator(self.cur_bb, kind, d0, d1, d2, d3, span)

fn MirBuilder.push_scope(self: MirBuilder):
    self.drop_scope_starts.push(self.drop_local_ids.len() as i32)
    self.bind_scope_starts.push(self.bind_syms.len() as i32)
    self.alias_scope_starts.push(self.alias_syms.len() as i32)

fn MirBuilder.schedule_drop(self: MirBuilder, local_id: i32, drop_kind: i32):
    self.drop_local_ids.push(local_id)
    self.drop_kinds.push(drop_kind)

fn MirBuilder.emit_drop_entry(self: MirBuilder, local_id: i32, drop_kind: i32):
    if drop_kind == DropKind.DK_STORAGE:
        self.body.push_stmt(self.cur_bb, StmtKind.StorageDead, local_id, 0, 0)
        return
    let place = self.body.new_place(local_id)
    self.body.push_stmt(self.cur_bb, StmtKind.Drop, place, 0, 0)

fn MirBuilder.pop_scope_with_goto(self: MirBuilder, target_bb: i32):
    if self.drop_scope_starts.len() as i32 == 0:
        self.terminate(TermKind.TK_GOTO, target_bb, 0, 0, 0)
        return

    let scope_idx = self.drop_scope_starts.len() as i32 - 1
    let drop_start = self.drop_scope_starts.get(scope_idx as i64)
    var i = self.drop_local_ids.len() as i32 - 1
    while i >= drop_start:
        self.emit_drop_entry(self.drop_local_ids.get(i as i64), self.drop_kinds.get(i as i64))
        i = i - 1

    while self.drop_local_ids.len() as i32 > drop_start:
        self.drop_local_ids.pop()
        self.drop_kinds.pop()
    self.drop_scope_starts.pop()

    let bind_start = self.bind_scope_starts.get(scope_idx as i64)
    while self.bind_syms.len() as i32 > bind_start:
        self.bind_syms.pop()
        self.bind_local_ids.pop()
    self.bind_scope_starts.pop()

    let alias_start = self.alias_scope_starts.get(scope_idx as i64)
    while self.alias_syms.len() as i32 > alias_start:
        self.alias_syms.pop()
        self.alias_places.pop()
        self.alias_types.pop()
    self.alias_scope_starts.pop()

    self.terminate(TermKind.TK_GOTO, target_bb, 0, 0, 0)

fn MirBuilder.pop_scope_inline(self: MirBuilder):
    if self.drop_scope_starts.len() as i32 == 0:
        return

    let scope_idx = self.drop_scope_starts.len() as i32 - 1
    let drop_start = self.drop_scope_starts.get(scope_idx as i64)
    var i = self.drop_local_ids.len() as i32 - 1
    while i >= drop_start:
        self.emit_drop_entry(self.drop_local_ids.get(i as i64), self.drop_kinds.get(i as i64))
        i = i - 1

    while self.drop_local_ids.len() as i32 > drop_start:
        self.drop_local_ids.pop()
        self.drop_kinds.pop()
    self.drop_scope_starts.pop()

    let bind_start = self.bind_scope_starts.get(scope_idx as i64)
    while self.bind_syms.len() as i32 > bind_start:
        self.bind_syms.pop()
        self.bind_local_ids.pop()
    self.bind_scope_starts.pop()

    let alias_start = self.alias_scope_starts.get(scope_idx as i64)
    while self.alias_syms.len() as i32 > alias_start:
        self.alias_syms.pop()
        self.alias_places.pop()
        self.alias_types.pop()
    self.alias_scope_starts.pop()

fn MirBuilder.emit_drops_for_break(self: MirBuilder, loop_info: LoopInfo):
    var i = self.drop_local_ids.len() as i32 - 1
    while i >= loop_info.break_drop_depth:
        self.emit_drop_entry(self.drop_local_ids.get(i as i64), self.drop_kinds.get(i as i64))
        i = i - 1

fn MirBuilder.emit_drops_for_return(self: MirBuilder):
    var i = self.drop_local_ids.len() as i32 - 1
    while i >= 0:
        self.emit_drop_entry(self.drop_local_ids.get(i as i64), self.drop_kinds.get(i as i64))
        i = i - 1

fn MirBuilder.emit_defers_for_return(self: MirBuilder):
    var i = self.defer_nodes.len() as i32 - 1
    while i >= 0:
        let defer_body = self.defer_nodes.get(i as i64)
        let _ = self.lower_expr(defer_body)
        i = i - 1

fn MirBuilder.emit_errdefers_for_return(self: MirBuilder):
    var i = self.errdefer_nodes.len() as i32 - 1
    while i >= 0:
        let errdefer_body = self.errdefer_nodes.get(i as i64)
        let _ = self.lower_expr(errdefer_body)
        i = i - 1

fn MirBuilder.emit_auto_defers(self: MirBuilder):
    // For each binding in the current scope that has a registered auto-defer
    // destructor, emit a destructor call if the binding is still live (not moved).
    if self.sema.ci_auto_defer_bindings.len() == 0:
        return
    let scope_start = if self.bind_scope_starts.len() > 0: self.bind_scope_starts.get(self.bind_scope_starts.len() - 1) else: 0
    var bi = scope_start
    while bi < self.bind_syms.len() as i32:
        let bind_sym = self.bind_syms.get(bi as i64)
        if self.sema.ci_auto_defer_bindings.contains(bind_sym):
            let local = self.bind_local_ids.get(bi as i64)
            if local >= 0:
                let dtor_sym = self.sema.ci_auto_defer_bindings.get(bind_sym).unwrap()
                let fn_op = self.const_operand(ConstKind.CK_FN, dtor_sym, 0)
                let self_place = self.place_for_local(local)
                let self_op = self.body.new_operand(OperandKind.OK_COPY, self_place)
                var args: Vec[i32] = Vec.new()
                args.push(self_op)
                let args_id = self.body.new_call_args(args)
                let void_local = self.new_temp(self.sema.ty_void)
                let void_place = self.place_for_local(void_local)
                let next_bb = self.new_block()
                self.terminate(TermKind.TK_CALL, fn_op, args_id, void_place, next_bb)
                self.switch_to(next_bb)
        bi = bi + 1

fn MirBuilder.push_loop(self: MirBuilder, continue_bb: i32, break_bb: i32):
    self.loop_continue_bbs.push(continue_bb)
    self.loop_break_bbs.push(break_bb)
    self.loop_break_drop_depths.push(self.drop_local_ids.len() as i32)

fn MirBuilder.pop_loop(self: MirBuilder):
    if self.loop_continue_bbs.len() as i32 == 0:
        return
    self.loop_continue_bbs.pop()
    self.loop_break_bbs.pop()
    self.loop_break_drop_depths.pop()

fn MirBuilder.current_loop(self: MirBuilder) -> LoopInfo:
    if self.loop_continue_bbs.len() as i32 == 0:
        return LoopInfo { continue_bb: 0 - 1, break_bb: 0 - 1, break_drop_depth: 0 }

    let i = self.loop_continue_bbs.len() as i32 - 1
    LoopInfo {
        continue_bb: self.loop_continue_bbs.get(i as i64),
        break_bb: self.loop_break_bbs.get(i as i64),
        break_drop_depth: self.loop_break_drop_depths.get(i as i64),
    }

fn MirBuilder.bind_local(self: MirBuilder, sym: i32, local_id: i32):
    self.bind_syms.push(sym)
    self.bind_local_ids.push(local_id)

fn MirBuilder.bind_alias_place(self: MirBuilder, sym: i32, place: i32, ty: i32):
    self.alias_syms.push(sym)
    self.alias_places.push(place)
    self.alias_types.push(ty)

fn MirBuilder.lookup_local(self: MirBuilder, sym: i32) -> i32:
    var i = self.bind_syms.len() as i32 - 1
    while i >= 0:
        if self.bind_syms.get(i as i64) == sym:
            return self.bind_local_ids.get(i as i64)
        i = i - 1
    0 - 1

fn MirBuilder.lookup_alias_place(self: MirBuilder, sym: i32) -> i32:
    var i = self.alias_syms.len() as i32 - 1
    while i >= 0:
        if self.alias_syms.get(i as i64) == sym:
            return self.alias_places.get(i as i64)
        i = i - 1
    0 - 1

fn MirBuilder.lookup_alias_type(self: MirBuilder, sym: i32) -> i32:
    var i = self.alias_syms.len() as i32 - 1
    while i >= 0:
        if self.alias_syms.get(i as i64) == sym:
            return self.alias_types.get(i as i64)
        i = i - 1
    0

fn MirBuilder.expr_type(self: MirBuilder, node: i32) -> i32:
    if node == 0:
        return self.sema.ty_void as i32
    if self.sema.typed_expr_types.contains(node):
        let typed = self.sema.typed_expr_types.get(node).unwrap()
        if typed != 0:
            return typed as i32
    self.fallback_expr_type(node)

fn MirBuilder.binding_type(self: MirBuilder, node: i32) -> i32:
    if self.sema.typed_binding_types.contains(node):
        let typed = self.sema.typed_binding_types.get(node).unwrap()
        if typed != 0:
            return typed as i32
    let flags = self.ast.get_data2(node)
    let ann_extra = self.sema.local_let_type_ann_extra(flags)
    if ann_extra >= 0:
        let ann_node = self.ast.get_extra(ann_extra)
        let ann_type = self.sema.resolve_type_expr(ann_node)
        if ann_type != 0:
            return ann_type as i32
    let rhs = self.ast.get_data1(node)
    let rhs_ty = self.expr_type(rhs)
    if rhs_ty != 0:
        return rhs_ty
    self.sema.ty_void as i32

fn MirBuilder.local_type(self: MirBuilder, local_id: i32) -> i32:
    if local_id < 0 or local_id >= self.body.local_type_ids.len() as i32:
        return self.sema.ty_void as i32
    self.body.local_type_ids.get(local_id as i64) as i32

fn MirBuilder.ident_type(self: MirBuilder, sym: i32) -> i32:
    let local = self.lookup_local(sym)
    if local >= 0:
        return self.local_type(local)
    let alias_ty = self.lookup_alias_type(sym)
    if alias_ty != 0:
        return alias_ty
    let sig_idx = self.sema.get_sig(sym)
    if sig_idx >= 0:
        return self.sema.sig_type_ids.get(sig_idx as i64) as i32
    if self.sema.named_types.contains(sym):
        return self.sema.named_types.get(sym).unwrap() as i32
    if self.sema.variant_lookup.contains(sym):
        return self.sema.variant_type_ids.get(sym).unwrap() as i32
    self.sema.ty_void as i32

fn MirBuilder.resolve_index_generic_inst(self: MirBuilder, node: i32) -> i32:
    // Resolve NodeKind.NK_INDEX(NodeKind.NK_IDENT("Vec"), type_arg) to a TypeKind.TY_GENERIC_INST.
    // Used for Vec[i32].new() and HashMap[str, i32].new().
    // Sema.check_index creates these during the check pass; we only look up here.
    let base = self.ast.get_data0(node)
    if self.ast.kind(base) != NodeKind.NK_IDENT:
        return 0
    let base_sym = self.ast.get_data0(base)
    if not self.sema.named_types.contains(base_sym):
        return 0
    // Resolve the first type argument (d1 of NodeKind.NK_INDEX)
    let type_arg_node = self.ast.get_data1(node)
    if type_arg_node == 0:
        return 0
    var arg_type = self.resolve_type_arg_node(type_arg_node)
    if arg_type == 0:
        return 0
    // Check for second type argument (d2 of NodeKind.NK_INDEX) — HashMap[K, V]
    let type_arg2_node = self.ast.get_data2(node)
    var arg2_type = 0
    if type_arg2_node != 0:
        arg2_type = self.resolve_type_arg_node(type_arg2_node)
    // Look up TypeKind.TY_GENERIC_INST from sema cache (created by Sema.check_index)
    var cache_key: i64 = base_sym as i64 * 31 + arg_type as i64
    if arg2_type > 0:
        cache_key = cache_key * 31 + arg2_type as i64
    if self.sema.generic_inst_cache.contains(cache_key):
        return self.sema.generic_inst_cache.get(cache_key).unwrap()
    0

fn MirBuilder.resolve_type_arg_node(self: MirBuilder, type_arg_node: i32) -> i32:
    let arg_kind = self.ast.kind(type_arg_node)
    if arg_kind == NodeKind.NK_IDENT or arg_kind == NodeKind.NK_TYPE_NAMED:
        let arg_sym = self.ast.get_data0(type_arg_node)
        let prim = self.sema.primitive_type_by_sym(arg_sym)
        if prim != 0:
            return prim
        if self.sema.named_types.contains(arg_sym):
            return self.sema.named_types.get(arg_sym).unwrap()
    0

fn MirBuilder.type_receiver_type(self: MirBuilder, node: i32) -> i32:
    // Resolve a type-level receiver expression to its base sema type.
    // Used for intrinsic classification (Vec, HashMap, etc.)
    // Handles: Vec (NodeKind.NK_IDENT), Vec[i32] (NodeKind.NK_INDEX of NodeKind.NK_IDENT)
    let kind = self.ast.kind(node)
    if kind == NodeKind.NK_TYPE_NAMED or kind == NodeKind.NK_TYPE_GENERIC or kind == NodeKind.NK_TYPE_PTR or kind == NodeKind.NK_TYPE_REF or kind == NodeKind.NK_TYPE_ARRAY or kind == NodeKind.NK_TYPE_SLICE or kind == NodeKind.NK_TYPE_TUPLE or kind == NodeKind.NK_TYPE_FN or kind == NodeKind.NK_TYPE_TRAIT_OBJ:
        return self.sema.resolve_type_expr(node) as i32
    if self.ast.kind(node) == NodeKind.NK_IDENT:
        let sym = self.ast.get_data0(node)
        if self.sema.named_types.contains(sym):
            return self.sema.named_types.get(sym).unwrap()
    if self.ast.kind(node) == NodeKind.NK_INDEX:
        let base = self.ast.get_data0(node)
        if self.ast.kind(base) == NodeKind.NK_IDENT:
            let sym = self.ast.get_data0(base)
            if self.sema.named_types.contains(sym):
                return self.sema.named_types.get(sym).unwrap()
    0

fn MirBuilder.index_expr_is_type_level(self: MirBuilder, expr: i32) -> bool:
    if expr == 0:
        return false
    let kind = self.ast.kind(expr)
    if kind == NodeKind.NK_IDENT:
        let sym = self.ast.get_data0(expr)
        return self.sema.named_types.contains(sym)
    if kind == NodeKind.NK_INDEX or kind == NodeKind.NK_GROUPED:
        return self.index_expr_is_type_level(self.ast.get_data0(expr))
    false

fn MirBuilder.vec_literal_type(self: MirBuilder, node: i32) -> i32:
    if node == 0 or self.ast.kind(node) != NodeKind.NK_INDEX:
        return 0
    let base_expr = self.ast.get_data0(node)
    if not self.index_expr_is_type_level(base_expr):
        return 0
    let vec_ty = self.expr_type(node)
    if vec_ty == 0 or vec_ty == self.sema.ty_void:
        return 0
    let resolved = self.sema.resolve_alias(vec_ty) as i32
    if self.sema.get_type_kind(resolved) != TypeKind.TY_GENERIC_INST:
        return 0
    let base_sym = self.sema.get_type_d0(resolved)
    if base_sym == 0:
        return 0
    if self.pool.resolve_symbol(base_sym) != "Vec":
        return 0
    resolved

fn MirBuilder.call_return_type(self: MirBuilder, callee: i32) -> i32:
    if callee == 0:
        return self.sema.ty_void as i32
    let kind = self.ast.kind(callee)
    if kind == NodeKind.NK_IDENT:
        let sym = self.ast.get_data0(callee)
        let sig_idx = self.sema.get_sig(sym)
        if sig_idx >= 0:
            return self.sema.sig_return_type(sig_idx) as i32
        return self.sema.ty_void as i32
    if kind == NodeKind.NK_FIELD_ACCESS:
        let base = self.ast.get_data0(callee)
        let method_sym = self.ast.get_data1(callee)
        let resolved = self.resolve_method_callee_sym(base, method_sym)
        let resolved_sig = self.sema.get_sig(resolved)
        if resolved_sig >= 0:
            return self.sema.sig_return_type(resolved_sig) as i32
        let bare_sig = self.sema.get_sig(method_sym)
        if bare_sig >= 0:
            return self.sema.sig_return_type(bare_sig) as i32
        // Intrinsic methods (Vec/HashMap/Option/str) have no sema sigs.
        // Resolve their return types from the receiver type + method name.
        var base_ty = self.expr_type(base)
        if base_ty == 0 or base_ty == self.sema.ty_void as i32:
            base_ty = self.type_receiver_type(base)
        if base_ty != 0 and base_ty != self.sema.ty_void as i32:
            let method_name = self.pool.resolve_symbol(method_sym)
            let iret = self.intrinsic_return_type(base_ty, method_name)
            if iret != 0 and iret != self.sema.ty_void as i32:
                return iret
            // Sema reports raw value types for Option-returning intrinsics
            // (e.g. HashMap.get returns str, not Option[str]). When .unwrap()
            // is chained, intrinsic_return_type can't match "unwrap" on str.
            // The unwrap just returns the same type sema already reports.
            if method_name == "unwrap":
                return base_ty
            if method_name == "is_some" or method_name == "is_none":
                return self.sema.ty_bool as i32
        // Qualified enum variant constructor: EnumType.Variant(...)
        let recv_ty = if base_ty != 0 and base_ty != self.sema.ty_void as i32: base_ty else: self.type_receiver_type(base)
        if recv_ty != 0 and recv_ty != self.sema.ty_void as i32 and self.sema.enum_has_variant(recv_ty, method_sym) != 0:
            return recv_ty
    self.sema.ty_void as i32

fn MirBuilder.intrinsic_return_type(self: MirBuilder, recv_type: i32, method_name: str) -> i32:
    // Return known return types for intrinsic (builtin) methods.
    // These methods have no sema signatures, so call_return_type can't resolve them.
    let resolved = self.sema.resolve_alias(recv_type) as i32
    let tk = self.sema.get_type_kind(resolved)
    let type_name_sym = self.sema.get_type_name(resolved)
    if type_name_sym != 0:
        let type_name = self.pool.resolve_symbol(type_name_sym)
        if type_name == "Vec":
            if method_name == "len": return self.sema.ty_i64 as i32
            if method_name == "new": return recv_type
            if method_name == "push" or method_name == "set_i32" or method_name == "remove" or method_name == "clear":
                return self.sema.ty_void as i32
            if method_name == "get" or method_name == "pop":
                if tk == TypeKind.TY_GENERIC_INST:
                    return self.sema.get_generic_inst_arg(resolved, 0)
            if method_name == "join": return self.sema.ty_str as i32
            if method_name == "filter": return recv_type
            if method_name == "map": return self.expr_type(self.cur_node)
            if method_name == "iter":
                // Vec.iter() returns VecIter[T] with same T as Vec[T].
                let vi_sym = self.sema.pool_lookup_symbol("VecIter")
                if self.sema.named_types.contains(vi_sym):
                    if tk == TypeKind.TY_GENERIC_INST:
                        let elem_ty = self.sema.get_generic_inst_arg(resolved, 0)
                        if elem_ty > 0:
                            let found = self.sema.find_generic_inst(vi_sym, elem_ty)
                            if found != 0:
                                return found
                    return self.sema.named_types.get(vi_sym).unwrap() as i32
                return self.sema.ty_void as i32
            return self.sema.ty_void as i32
        if type_name == "VecIter":
            if method_name == "next":
                // VecIter[T].next() returns Option[T].
                if tk == TypeKind.TY_GENERIC_INST:
                    let elem_ty = self.sema.get_generic_inst_arg(resolved, 0)
                    let opt_sym = self.sema.pool_lookup_symbol("Option")
                    let opt_tid = self.sema.find_generic_inst(opt_sym, elem_ty)
                    if opt_tid != 0:
                        return opt_tid
                    return elem_ty
            return self.sema.ty_void as i32
        if type_name == "HashMap":
            if method_name == "len": return self.sema.ty_i64 as i32
            if method_name == "contains": return self.sema.ty_bool as i32
            if method_name == "new": return recv_type
            if method_name == "insert" or method_name == "clear":
                return self.sema.ty_void as i32
            if method_name == "get" or method_name == "remove":
                if tk == TypeKind.TY_GENERIC_INST:
                    return self.sema.get_generic_inst_arg(resolved, 1)
            return self.sema.ty_void as i32
        if type_name == "HashSet":
            if method_name == "len": return self.sema.ty_i64 as i32
            if method_name == "contains" or method_name == "remove": return self.sema.ty_bool as i32
            if method_name == "new": return recv_type
            if method_name == "insert" or method_name == "clear":
                return self.sema.ty_void as i32
            return self.sema.ty_void as i32
        if type_name == "Option":
            if method_name == "is_some" or method_name == "is_none": return self.sema.ty_bool as i32
            if method_name == "unwrap":
                if tk == TypeKind.TY_GENERIC_INST:
                    return self.sema.get_generic_inst_arg(resolved, 0)
            if method_name == "filter":
                return recv_type
            if method_name == "map" or method_name == "and_then":
                return recv_type
            if method_name == "unwrap_or":
                if tk == TypeKind.TY_GENERIC_INST:
                    return self.sema.get_generic_inst_arg(resolved, 0)
            if method_name == "unwrap_or_else":
                if tk == TypeKind.TY_GENERIC_INST:
                    return self.sema.get_generic_inst_arg(resolved, 0)
            return self.sema.ty_void as i32
        if type_name == "Result":
            if method_name == "is_ok": return self.sema.ty_bool as i32
            if method_name == "unwrap":
                if tk == TypeKind.TY_GENERIC_INST:
                    return self.sema.get_generic_inst_arg(resolved, 0)
            return self.sema.ty_void as i32
        if type_name == "Atomic":
            if method_name == "new": return recv_type
            if method_name == "store": return self.sema.ty_void as i32
            if method_name == "load" or method_name == "swap" or method_name == "fetch_add" or method_name == "fetch_sub" or method_name == "fetch_and" or method_name == "fetch_or" or method_name == "fetch_xor" or method_name == "fetch_min" or method_name == "fetch_max":
                if tk == TypeKind.TY_GENERIC_INST:
                    return self.sema.get_generic_inst_arg(resolved, 0)
            if method_name == "compare_exchange" or method_name == "compare_exchange_weak":
                if tk == TypeKind.TY_GENERIC_INST:
                    return self.sema.get_generic_inst_arg(resolved, 0)
            return self.sema.ty_void as i32
    if tk == TypeKind.TY_STR:
        if method_name == "len": return self.sema.ty_i64 as i32
        if method_name == "byte_at": return self.sema.ty_i32 as i32
        if method_name == "slice": return self.sema.ty_str as i32
        if method_name == "contains" or method_name == "starts_with" or method_name == "ends_with":
            return self.sema.ty_bool as i32
        if method_name == "find": return self.sema.ty_i64 as i32
        if method_name == "repeat": return self.sema.ty_str as i32
        if method_name == "trim" or method_name == "to_upper" or method_name == "to_lower" or method_name == "replace":
            return self.sema.ty_str as i32
        if method_name == "index_of": return self.sema.ty_i64 as i32
        if method_name == "split":
            // str.split() returns Vec[str]
            let vec_sym = self.sema.pool_lookup_symbol("Vec")
            let found = self.sema.find_generic_inst(vec_sym, self.sema.ty_str as i32)
            if found != 0:
                return found
            return self.sema.ty_void as i32
        return self.sema.ty_void as i32
    if tk == TypeKind.TY_ARRAY:
        if method_name == "len": return self.sema.ty_i32 as i32
        return self.sema.ty_void as i32
    if tk == TypeKind.TY_INT:
        if method_name == "rotate_left" or method_name == "rotate_right" or method_name == "swap_bytes" or method_name == "bitreverse":
            return recv_type
        if method_name == "popcount" or method_name == "clz" or method_name == "ctz":
            return self.sema.ty_i32 as i32
        if method_name == "min" or method_name == "max":
            return recv_type
        if method_name == "abs":
            return self.sema.unsigned_counterpart(recv_type)
    if tk == TypeKind.TY_FLOAT:
        if method_name == "min" or method_name == "max" or method_name == "abs" or method_name == "mul_add":
            return recv_type
    self.sema.ty_void as i32

fn MirBuilder.struct_field_type(self: MirBuilder, struct_tid: i32, field_sym: i32) -> i32:
    let resolved = self.sema.resolve_alias(struct_tid)
    let tk = self.sema.get_type_kind(resolved)
    if tk == TypeKind.TY_REF or tk == TypeKind.TY_PTR:
        let inner = self.sema.get_type_d0(resolved)
        return self.struct_field_type(inner, field_sym)
    self.sema.struct_field_type(resolved as i32, field_sym)

fn MirBuilder.tuple_elem_type(self: MirBuilder, tuple_tid: i32, field_idx: i32) -> i32:
    let resolved = self.sema.resolve_alias(tuple_tid)
    let tk = self.sema.get_type_kind(resolved)
    if tk != TypeKind.TY_TUPLE:
        return 0
    let elem_start = self.sema.get_type_d0(resolved)
    let elem_count = self.sema.get_type_d1(resolved)
    if field_idx < 0 or field_idx >= elem_count:
        return 0
    self.sema.type_extra.get((elem_start + field_idx) as i64)

fn MirBuilder.indexed_element_type(self: MirBuilder, collection_tid: i32) -> i32:
    let resolved = self.sema.resolve_alias(collection_tid) as i32
    let tk = self.sema.get_type_kind(resolved)
    if tk == TypeKind.TY_ARRAY or tk == TypeKind.TY_SLICE:
        return self.sema.get_type_d0(resolved)
    if tk == TypeKind.TY_STR:
        return self.sema.ty_i32 as i32
    if tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF:
        return self.sema.get_type_d0(resolved)
    if tk == TypeKind.TY_GENERIC_INST:
        let base_sym = self.sema.get_generic_inst_base(resolved)
        if self.pool.resolve_symbol(base_sym) == "Vec" and self.sema.get_generic_inst_arg_count(resolved) > 0:
            return self.sema.get_generic_inst_arg(resolved, 0)
    0

fn MirBuilder.enum_payload_type(self: MirBuilder, enum_tid: i32, variant_idx: i32, field_idx: i32) -> i32:
    let resolved = self.sema.resolve_alias(enum_tid)
    let tk = self.sema.get_type_kind(resolved)
    if variant_idx < 0 or field_idx < 0:
        return 0

    if tk == TypeKind.TY_ENUM:
        let te_start = self.sema.get_type_d1(resolved)
        let variant_count = self.sema.get_type_d2(resolved)
        var pos = te_start
        for vi in 0..variant_count:
            let payload_count = self.sema.type_extra.get((pos + 1) as i64)
            if vi == variant_idx:
                if field_idx < payload_count:
                    return self.sema.type_extra.get((pos + 2 + field_idx) as i64)
                return 0
            pos = pos + 2 + payload_count
        return 0

    if tk == TypeKind.TY_GENERIC_INST:
        let base_sym = self.sema.get_generic_inst_base(resolved)
        if not self.sema.named_types.contains(base_sym):
            return 0
        let base_tid = self.sema.named_types.get(base_sym).unwrap()
        if self.sema.get_type_kind(base_tid) != TypeKind.TY_ENUM:
            return 0
        let te_start = self.sema.get_type_d1(base_tid)
        let variant_count = self.sema.get_type_d2(base_tid)
        var pos = te_start
        for vi in 0..variant_count:
            let variant_name = self.sema.type_extra.get(pos as i64)
            let payload_count = self.sema.type_extra.get((pos + 1) as i64)
            if vi == variant_idx:
                let payload_types = self.sema.resolve_generic_enum_payload(resolved, base_sym, variant_name, payload_count)
                if field_idx < payload_types.len() as i32:
                    let payload_ty = payload_types.get(field_idx as i64)
                    if payload_ty != 0:
                        return payload_ty
                if field_idx < payload_count:
                    return self.sema.type_extra.get((pos + 2 + field_idx) as i64)
                return 0
            pos = pos + 2 + payload_count
    0

fn MirBuilder.fallback_expr_type(self: MirBuilder, node: i32) -> i32:
    if node == 0:
        return self.sema.ty_void as i32
    let kind = self.ast.kind(node)
    if kind == NodeKind.NK_IDENT:
        return self.ident_type(self.ast.get_data0(node))
    if kind == NodeKind.NK_GROUPED:
        return self.expr_type(self.ast.get_data0(node))
    if kind == NodeKind.NK_FIELD_ACCESS:
        let base_node = self.ast.get_data0(node)
        let field_sym = self.ast.get_data1(node)
        let base_ty = self.expr_type(base_node)
        if base_ty != 0 and base_ty != self.sema.ty_void as i32:
            let ft = self.struct_field_type(base_ty, field_sym)
            if ft != 0:
                return ft
            if self.sema.enum_has_variant(base_ty, field_sym) != 0:
                return base_ty
        let recv_ty = self.type_receiver_type(base_node)
        if recv_ty != 0 and recv_ty != self.sema.ty_void as i32 and self.sema.enum_has_variant(recv_ty, field_sym) != 0:
            return recv_ty
        return self.sema.ty_void as i32
    if kind == NodeKind.NK_INT_LIT:
        let suffix_ty = self.sema.literal_suffix_type(self.ast.literal_suffix(node as NodeId))
        if suffix_ty != 0:
            return suffix_ty
        let fast = self.ast.int_literal_fast_i64(node as NodeId)
        if fast.ok == 0:
            return self.sema.ty_i64 as i32
        let value = fast.value
        if value < -2147483648 or value > 2147483647:
            return self.sema.ty_i64 as i32
        return self.sema.ty_i32 as i32
    if kind == NodeKind.NK_BOOL_LIT:
        return self.sema.ty_bool as i32
    if kind == NodeKind.NK_STRING_LIT or kind == NodeKind.NK_C_STRING_LIT:
        return self.sema.ty_str as i32
    if kind == NodeKind.NK_FSTRING:
        return self.sema.ty_str as i32
    if kind == NodeKind.NK_NULL_LIT:
        return self.sema.ty_i32 as i32
    if kind == NodeKind.NK_UNSAFE_BLOCK:
        return self.expr_type(self.ast.get_data0(node))
    if kind == NodeKind.NK_ASM_EXPR:
        let asm_d2 = self.ast.get_data2(node)
        if (asm_d2 & 2) != 0:  // has_output flag
            let asm_es = asm_d2 >> 8
            if asm_es > 0:
                let asm_ot = self.ast.get_extra(asm_es)
                if asm_ot != 0:
                    let asm_rt = self.sema.resolve_type_expr(asm_ot)
                    if asm_rt != 0:
                        return asm_rt as i32
        return self.sema.ty_void as i32
    if kind == NodeKind.NK_CALL:
        return self.call_return_type(self.ast.get_data0(node))
    if kind == NodeKind.NK_ASSIGN:
        let target_ty = self.expr_type(self.ast.get_data0(node))
        if target_ty != 0:
            return target_ty
        return self.sema.ty_void as i32
    if kind == NodeKind.NK_STRUCT_LIT:
        let st_name = self.ast.get_data0(node)
        if self.sema.named_types.contains(st_name):
            return self.sema.named_types.get(st_name).unwrap() as i32
        // Self struct literal — resolve via method context
        let st_name_str = self.sema.pool_resolve(st_name)
        if st_name_str == "Self":
            let fn_sym = self.body.fn_sym
            let fn_name_str = self.sema.pool_resolve(fn_sym)
            for ci in 0..fn_name_str.len() as i32:
                if fn_name_str.byte_at(ci as i64) == 46:
                    let owner_name = fn_name_str.slice(0, ci as i64)
                    let owner_sym = self.sema.pool_lookup_symbol(owner_name)
                    if self.sema.named_types.contains(owner_sym):
                        return self.sema.named_types.get(owner_sym).unwrap() as i32
                    break
    if kind == NodeKind.NK_MATCH:
        // Merge arm body types so payloadless first arms do not collapse the
        // whole expression to void when sema metadata is missing.
        let m_arms_start = self.ast.get_data1(node)
        let m_arms_count = self.ast.get_data2(node)
        var match_ty = 0
        if m_arms_count > 0:
            for mi in 0..m_arms_count:
                let arm_node = self.ast.get_extra(m_arms_start + mi)
                let arm_body = self.ast.get_data1(arm_node)
                if arm_body == 0:
                    continue
                let arm_ty = self.expr_type(arm_body)
                if arm_ty == 0 or arm_ty == self.sema.ty_void as i32:
                    continue
                if match_ty == 0 or match_ty == self.sema.ty_void as i32:
                    match_ty = arm_ty
                    continue
                if self.sema.types_compatible(match_ty, arm_ty) != 0:
                    match_ty = self.sema.preferred_compatible_type(match_ty as TypeId, arm_ty as TypeId) as i32
            if match_ty != 0 and match_ty != self.sema.ty_void as i32:
                return match_ty
    if kind == NodeKind.NK_IF_EXPR:
        // Infer if-expression type from then branch
        let then_expr = self.ast.get_data1(node)
        if then_expr != 0:
            return self.expr_type(then_expr)
    if kind == NodeKind.NK_BLOCK:
        // Infer block type from tail expression
        let tail = self.ast.get_data2(node)
        if tail != 0:
            return self.expr_type(tail)
    if kind == NodeKind.NK_INDEX:
        let base_node = self.ast.get_data0(node)
        let base_ty = self.expr_type(base_node)
        if base_ty != 0 and base_ty != self.sema.ty_void as i32:
            let resolved = self.sema.resolve_alias(base_ty) as i32
            let tk = self.sema.get_type_kind(resolved)
            if tk == TypeKind.TY_ARRAY or tk == TypeKind.TY_SLICE:
                return self.sema.get_type_d0(resolved)
    if kind == NodeKind.NK_BINARY:
        let op = self.ast.get_data0(node)
        let lhs_ty = self.expr_type(self.ast.get_data1(node))
        let rhs_ty = self.expr_type(self.ast.get_data2(node))
        if op == BinaryOp.OP_EQ or op == BinaryOp.OP_NEQ or op == BinaryOp.OP_LT or op == BinaryOp.OP_GT or op == BinaryOp.OP_LTE or op == BinaryOp.OP_GTE or op == BinaryOp.OP_AND or op == BinaryOp.OP_OR:
            return self.sema.ty_bool as i32
        if lhs_ty != 0 and lhs_ty != self.sema.ty_void as i32:
            let lhs_resolved = self.sema.resolve_alias(lhs_ty) as i32
            let lhs_tk = self.sema.get_type_kind(lhs_resolved)
            if (op == BinaryOp.OP_ADD or op == BinaryOp.OP_SUB) and (lhs_tk == TypeKind.TY_PTR or lhs_tk == TypeKind.TY_REF):
                return lhs_ty
        if rhs_ty != 0 and rhs_ty != self.sema.ty_void as i32:
            let rhs_resolved = self.sema.resolve_alias(rhs_ty) as i32
            let rhs_tk = self.sema.get_type_kind(rhs_resolved)
            if op == BinaryOp.OP_ADD and (rhs_tk == TypeKind.TY_PTR or rhs_tk == TypeKind.TY_REF):
                return rhs_ty
        if lhs_ty != 0 and lhs_ty == rhs_ty:
            return lhs_ty
    if kind == NodeKind.NK_UNARY:
        let uop = self.ast.get_data0(node)
        if uop == UnaryOp.UOP_TRY:
            let inner_node = self.ast.get_data1(node)
            let inner_ty = self.expr_type(inner_node)
            let unwrapped = self.sema.try_unwrapped_type(inner_ty) as i32
            if unwrapped != 0:
                return unwrapped
            return inner_ty
        if uop == UnaryOp.UOP_DEREF:
            let inner_node = self.ast.get_data1(node)
            let inner_ty = self.expr_type(inner_node)
            if inner_ty != 0 and inner_ty != self.sema.ty_void as i32:
                let resolved = self.sema.resolve_alias(inner_ty) as i32
                let tk = self.sema.get_type_kind(resolved)
                if tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF:
                    return self.sema.get_type_d0(resolved)
    if kind == NodeKind.NK_VARIANT_SHORTHAND:
        let vs_sym = self.ast.get_data0(node)
        if self.sema.variant_lookup.contains(vs_sym):
            return self.sema.variant_type_ids.get(vs_sym).unwrap() as i32
    if kind == NodeKind.NK_RANGE:
        let range_start = self.ast.get_data0(node)
        let range_end = self.ast.get_data1(node)
        let range_inclusive = self.ast.get_data2(node)
        var range_elem = self.sema.ty_i32 as i32
        if range_start != 0:
            range_elem = self.expr_type(range_start)
        else if range_end != 0:
            range_elem = self.expr_type(range_end)
        let range_found = self.sema.find_range_type(range_elem, range_inclusive) as i32
        if range_found != 0:
            return range_found
        return self.sema.ty_void as i32
    self.sema.ty_void as i32

fn MirBuilder.place_local_type(self: MirBuilder, place_id: i32) -> i32:
    if place_id < 0 or place_id >= self.body.place_locals.len() as i32:
        return self.sema.ty_void as i32
    let local_id = self.body.place_locals.get(place_id as i64)
    if local_id < 0 or local_id >= self.body.local_type_ids.len() as i32:
        return self.sema.ty_void as i32
    var current_ty = self.body.local_type_ids.get(local_id as i64) as i32
    let proj_start = self.body.place_proj_starts.get(place_id as i64)
    let proj_count = self.body.place_proj_counts.get(place_id as i64)
    var active_variant_idx = -1

    for pi in 0..proj_count:
        let proj_kind = self.body.proj_kinds.get((proj_start + pi) as i64)
        let proj_d0 = self.body.proj_d0.get((proj_start + pi) as i64)
        let resolved = self.sema.resolve_alias(current_ty) as i32
        let tk = self.sema.get_type_kind(resolved)

        if proj_kind == ProjKind.PK_DOWNCAST:
            if tk == TypeKind.TY_ENUM or tk == TypeKind.TY_GENERIC_INST:
                active_variant_idx = proj_d0
                continue
            return self.sema.ty_void as i32

        if proj_kind == ProjKind.PK_FIELD:
            var field_ty = 0
            if active_variant_idx >= 0:
                field_ty = self.enum_payload_type(current_ty, active_variant_idx, proj_d0)
            else if tk == TypeKind.TY_TUPLE:
                field_ty = self.tuple_elem_type(current_ty, proj_d0)
            else:
                field_ty = self.struct_field_type(current_ty, proj_d0)
            if field_ty == 0:
                return self.sema.ty_void as i32
            current_ty = field_ty
            active_variant_idx = -1
            continue

        if proj_kind == ProjKind.PK_INDEX:
            let elem_ty = self.indexed_element_type(current_ty)
            if elem_ty == 0:
                return self.sema.ty_void as i32
            current_ty = elem_ty
            active_variant_idx = -1
            continue

        if proj_kind == ProjKind.PK_DEREF:
            if tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF:
                current_ty = self.sema.get_type_d0(resolved)
                active_variant_idx = -1
                continue
            return self.sema.ty_void as i32

        return self.sema.ty_void as i32

    current_ty

fn MirBuilder.variant_index(self: MirBuilder, variant_sym: i32) -> i32:
    if variant_sym == 0:
        return 0
    if self.sema.variant_lookup.contains(variant_sym):
        return self.sema.variant_lookup.get(variant_sym).unwrap()
    0

// Resolve variant sym from an AST node, checking sema's comprehension sidecar first.
fn MirBuilder.resolve_variant_sym(self: MirBuilder, node: i32) -> i32:
    let sym = self.ast.get_data0(node)
    if self.sema.comp_resolved.contains(node):
        return self.sema.comp_resolved.get(node).unwrap()
    sym

fn MirBuilder.success_variant_index(self: MirBuilder) -> i32:
    let some_sym = self.pool.intern("Some")
    if self.sema.variant_lookup.contains(some_sym):
        return self.variant_index(some_sym)
    let ok_sym = self.pool.intern("Ok")
    if self.sema.variant_lookup.contains(ok_sym):
        return self.variant_index(ok_sym)
    1

fn MirBuilder.materialize_operand(self: MirBuilder, operand_id: i32, type_id: i32, span: i32) -> i32:
    let temp = self.new_temp(type_id)
    let place = self.place_for_local(temp)
    self.assign_operand_to_place(place, operand_id, span)
    place

fn MirBuilder.new_temp(self: MirBuilder, type_id: i32) -> i32:
    self.next_temp = self.next_temp + 1
    self.body.new_temp(type_id)

fn MirBuilder.place_for_local(self: MirBuilder, local_id: i32) -> i32:
    self.body.new_place(local_id)

fn MirBuilder.const_operand(self: MirBuilder, kind: i32, d0: i32, type_id: i32) -> i32:
    let c = self.body.new_const(kind, d0, 0, 0, type_id)
    self.body.new_operand(OperandKind.OK_CONSTANT, c)

fn MirBuilder.int_const_operand(self: MirBuilder, value: i64, type_id: i32) -> i32:
    let c = self.body.new_const(ConstKind.CK_INT, ast_int_part0(value), ast_int_part1(value), ast_int_part2(value), type_id)
    self.body.new_operand(OperandKind.OK_CONSTANT, c)

fn MirBuilder.exact_int_const_operand(self: MirBuilder, node: i32, type_id: i32) -> i32:
    let c = self.body.new_const(ConstKind.CK_INT_EXACT, node, 0, 0, type_id)
    self.body.new_operand(OperandKind.OK_CONSTANT, c)

fn MirBuilder.unit_operand(self: MirBuilder) -> i32:
    self.const_operand(ConstKind.CK_UNIT, 0, self.sema.ty_void)

fn MirBuilder.try_eval_const(self: MirBuilder, node: i32) -> i64:
    let kind = self.ast.kind(node)
    if kind == NodeKind.NK_INT_LIT:
        let fast = self.ast.int_literal_fast_i64(node as NodeId)
        if fast.ok == 0:
            return -9223372036854775807
        return fast.value
    if kind == NodeKind.NK_COMPTIME:
        return self.try_eval_const(self.ast.get_data0(node))
    if kind == NodeKind.NK_GROUPED:
        return self.try_eval_const(self.ast.get_data0(node))
    if kind == NodeKind.NK_BOOL_LIT:
        return self.ast.get_data0(node) as i64
    if kind == NodeKind.NK_UNARY:
        let op = self.ast.get_data0(node)
        let inner = self.try_eval_const(self.ast.get_data1(node))
        if inner == -9223372036854775807: return -9223372036854775807
        if op == UnaryOp.UOP_NEGATE: return -inner
        if op == UnaryOp.UOP_BIT_NOT: return 0 - inner - 1
        if op == UnaryOp.UOP_NOT:
            if inner == 0: return 1
            return 0
        return -9223372036854775807
    if kind == NodeKind.NK_BINARY:
        let op = self.ast.get_data0(node)
        let lv = self.try_eval_const(self.ast.get_data1(node))
        if lv == -9223372036854775807: return -9223372036854775807
        let rv = self.try_eval_const(self.ast.get_data2(node))
        if rv == -9223372036854775807: return -9223372036854775807
        if op == BinaryOp.OP_ADD: return lv + rv
        if op == BinaryOp.OP_SUB: return lv - rv
        if op == BinaryOp.OP_MUL: return lv * rv
        if op == BinaryOp.OP_DIV:
            if rv == 0: return -9223372036854775807
            return lv / rv
        if op == BinaryOp.OP_MOD:
            if rv == 0: return -9223372036854775807
            return lv % rv
        return -9223372036854775807
    if kind == NodeKind.NK_IDENT:
        // Cross-reference to another constant
        let ref_sym = self.ast.get_data0(node)
        return self.try_resolve_module_const_val(ref_sym)
    -9223372036854775807

fn MirBuilder.try_resolve_module_const_node(self: MirBuilder, sym: i32) -> i32:
    for di in 0..self.ast.decl_count():
        let decl = self.ast.get_decl(di)
        if self.ast.kind(decl) != NodeKind.NK_LET_DECL:
            continue
        if self.ast.get_data0(decl) != sym:
            continue
        let flags = self.ast.get_data2(decl)
        let is_mut = flags % 2
        if is_mut != 0:
            continue
        var value_node = self.ast.get_data1(decl)
        if value_node == 0:
            continue
        if self.ast.kind(value_node) == NodeKind.NK_COMPTIME:
            value_node = self.ast.get_data0(value_node)
        if self.ast.kind(value_node) == NodeKind.NK_IDENT:
            let target = self.try_resolve_module_const_node(self.ast.get_data0(value_node))
            if target != 0:
                return target
        return value_node
    0

fn MirBuilder.try_resolve_module_const_val(self: MirBuilder, sym: i32) -> i64:
    for di in 0..self.ast.decl_count():
        let decl = self.ast.get_decl(di)
        if self.ast.kind(decl) != NodeKind.NK_LET_DECL:
            continue
        if self.ast.get_data0(decl) != sym:
            continue
        let flags = self.ast.get_data2(decl)
        let is_mut = flags % 2
        if is_mut != 0:
            continue
        var value_node = self.ast.get_data1(decl)
        if value_node == 0:
            continue
        return self.try_eval_const(value_node)
    -9223372036854775807

fn MirBuilder.try_resolve_module_float_const(self: MirBuilder, sym: i32) -> i32:
    for di in 0..self.ast.decl_count():
        let decl = self.ast.get_decl(di)
        if self.ast.kind(decl) != NodeKind.NK_LET_DECL:
            continue
        if self.ast.get_data0(decl) != sym:
            continue
        let flags = self.ast.get_data2(decl)
        let is_mut = flags % 2
        if is_mut != 0:
            continue
        var value_node = self.ast.get_data1(decl)
        if value_node == 0:
            continue
        if self.ast.kind(value_node) == NodeKind.NK_COMPTIME:
            value_node = self.ast.get_data0(value_node)
        if self.ast.kind(value_node) == NodeKind.NK_FLOAT_LIT:
            return self.ast.get_data0(value_node)
    -1

fn MirBuilder.try_resolve_module_const_type(self: MirBuilder, sym: i32) -> i32:
    for di in 0..self.ast.decl_count():
        let decl = self.ast.get_decl(di)
        if self.ast.kind(decl) != NodeKind.NK_LET_DECL:
            continue
        if self.ast.get_data0(decl) != sym:
            continue
        if self.sema.typed_binding_types.contains(decl as i32):
            return self.sema.typed_binding_types.get(decl as i32).unwrap() as i32
        let flags = self.ast.get_data2(decl)
        let type_extra_packed = flags / 4
        if type_extra_packed > 0:
            let type_ann_node = self.ast.get_extra(type_extra_packed - 1)
            let resolved = self.sema.resolve_type_expr(type_ann_node) as i32
            if resolved != 0:
                return resolved
    0

fn MirBuilder.mark_unsupported(self: MirBuilder):
    if with_getenv_str("WITH_MIR_AUDIT").len() > 0:
        let node_kind = if self.cur_node != 0: self.ast.kind(self.cur_node) else: 0
        let fn_name = self.pool.resolve(self.body.fn_sym)
        with_eprint(f"[mir-lower-fail] kind={node_kind} fn={fn_name}")
    var b = self.body
    b.lowering_failed = 1
    self.body = b

fn MirBuilder.lower_int_lit(self: MirBuilder, value: i64, type_id: i32) -> i32:
    let ty = if type_id == 0 or self.sema.get_type_kind(type_id) == TypeKind.TY_VOID: self.sema.ty_i32 else: type_id
    self.int_const_operand(value, ty)

fn MirBuilder.lower_int_lit_node(self: MirBuilder, node: i32, type_id: i32) -> i32:
    let ty = if type_id == 0 or self.sema.get_type_kind(type_id) == TypeKind.TY_VOID: self.sema.ty_i32 else: type_id
    let exact = self.ast.int_literal_exact_expr(node)
    if exact.ok != 0:
        let fast = exact_int_try_i64(exact_int_expr_magnitude(exact))
        if exact.negative != 0 or fast.ok == 0:
            return self.exact_int_const_operand(node, ty)
    let fast = self.ast.int_literal_fast_i64(node as NodeId)
    if fast.ok != 0:
        return self.int_const_operand(fast.value, ty)
    self.exact_int_const_operand(node, ty)

fn MirBuilder.lower_bool_lit(self: MirBuilder, value: i32) -> i32:
    self.const_operand(ConstKind.CK_BOOL, value, self.sema.ty_bool)

fn MirBuilder.lower_str_lit(self: MirBuilder, sym: i32) -> i32:
    self.const_operand(ConstKind.CK_STR, sym, self.sema.ty_str)

fn MirBuilder.lower_fmt_to_str(self: MirBuilder, operand: i32, node: i32) -> i32:
    // Emit MirIntrinsic.MIR_INTRINSIC_FMT_TO_STR call to format a non-str value to str.
    let fn_op = self.const_operand(ConstKind.CK_FN, self.pool.intern("fmt_to_str"), self.sema.ty_str)
    let call_args: Vec[i32] = Vec.new()
    call_args.push(operand)
    let args_id = self.body.new_call_args(call_args)
    let result_local = self.new_temp(self.sema.ty_str)
    let result_place = self.place_for_local(result_local)
    let next_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, fn_op, args_id, result_place, next_bb)
    self.switch_to(next_bb)
    self.body.set_call_intrinsic(args_id, MirIntrinsic.MIR_INTRINSIC_FMT_TO_STR)
    self.body.new_operand(OperandKind.OK_COPY, result_place)

fn MirBuilder.lower_fmt_debug_str(self: MirBuilder, operand: i32, node: i32) -> i32:
    // Emit MirIntrinsic.MIR_INTRINSIC_FMT_DEBUG_STR call to wrap a str value in quotes.
    let fn_op = self.const_operand(ConstKind.CK_FN, self.pool.intern("fmt_debug_str"), self.sema.ty_str)
    let call_args: Vec[i32] = Vec.new()
    call_args.push(operand)
    let args_id = self.body.new_call_args(call_args)
    let result_local = self.new_temp(self.sema.ty_str)
    let result_place = self.place_for_local(result_local)
    let next_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, fn_op, args_id, result_place, next_bb)
    self.switch_to(next_bb)
    self.body.set_call_intrinsic(args_id, MirIntrinsic.MIR_INTRINSIC_FMT_DEBUG_STR)
    self.body.new_operand(OperandKind.OK_COPY, result_place)

fn MirBuilder.lower_fmt_debug(self: MirBuilder, operand: i32, sema_ty: i32, node: i32) -> i32:
    // Emit MirIntrinsic.MIR_INTRINSIC_FMT_DEBUG with value + sema type ID.
    // Codegen dispatches based on type: str→quoted, struct→fields, etc.
    let fn_op = self.const_operand(ConstKind.CK_FN, self.pool.intern("fmt_debug"), self.sema.ty_str)
    let type_const = self.const_operand(ConstKind.CK_INT, sema_ty, self.sema.ty_i32)
    let call_args: Vec[i32] = Vec.new()
    call_args.push(operand)
    call_args.push(type_const)
    let args_id = self.body.new_call_args(call_args)
    let result_local = self.new_temp(self.sema.ty_str)
    let result_place = self.place_for_local(result_local)
    let next_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, fn_op, args_id, result_place, next_bb)
    self.switch_to(next_bb)
    self.body.set_call_intrinsic(args_id, MirIntrinsic.MIR_INTRINSIC_FMT_DEBUG)
    self.body.new_operand(OperandKind.OK_COPY, result_place)

fn MirBuilder.lower_fmt_with_spec(self: MirBuilder, operand: i32, flags: i32, width: i32, precision: i32, sema_ty: i32, node: i32) -> i32:
    // Emit MirIntrinsic.MIR_INTRINSIC_FMT_SPEC with value + spec parameters.
    // args: [value, flags, width, precision, sema_type_id]
    let fn_op = self.const_operand(ConstKind.CK_FN, self.pool.intern("fmt_spec"), self.sema.ty_str)
    let flags_const = self.const_operand(ConstKind.CK_INT, flags, self.sema.ty_i32)
    let width_const = self.const_operand(ConstKind.CK_INT, width, self.sema.ty_i32)
    let prec_const = self.const_operand(ConstKind.CK_INT, precision, self.sema.ty_i32)
    let type_const = self.const_operand(ConstKind.CK_INT, sema_ty, self.sema.ty_i32)
    let call_args: Vec[i32] = Vec.new()
    call_args.push(operand)
    call_args.push(flags_const)
    call_args.push(width_const)
    call_args.push(prec_const)
    call_args.push(type_const)
    let args_id = self.body.new_call_args(call_args)
    let result_local = self.new_temp(self.sema.ty_str)
    let result_place = self.place_for_local(result_local)
    let next_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, fn_op, args_id, result_place, next_bb)
    self.switch_to(next_bb)
    self.body.set_call_intrinsic(args_id, MirIntrinsic.MIR_INTRINSIC_FMT_SPEC)
    self.body.new_operand(OperandKind.OK_COPY, result_place)

fn MirBuilder.lower_fstring(self: MirBuilder, node: i32) -> i32:
    // Lower f-string to FmtBuffer approach:
    //   buf = fmt_buf_new()
    //   for each segment: fmt_buf_write_*(buf, value, ...)
    //   result = fmt_buf_finish(buf)
    let seg_count = self.ast.get_data0(node)
    let extra_start = self.ast.get_data1(node)

    if seg_count == 0:
        return self.lower_str_lit(self.pool.intern(""))

    // Step 1: Create FmtBuffer via MIR_INTRINSIC_FMT_BUF_NEW
    let buf_op = self.lower_fstring_buf_new(node)

    // Step 2: For each segment, emit a write call
    var pos = extra_start
    var i = 0
    while i < seg_count:
        let seg_kind = self.ast.get_extra(pos)
        if seg_kind == FStringSegmentKind.LITERAL:
            let sym = self.ast.get_extra(pos + 1)
            let str_op = self.lower_str_lit(sym)
            self.lower_fstring_buf_write_str(buf_op, str_op, node)
            pos = pos + 2
        else if seg_kind == FStringSegmentKind.EXPR:
            let expr_node = self.ast.get_extra(pos + 1)
            let spec_node = self.ast.get_extra(pos + 2)
            let expr_op = self.lower_expr(expr_node)
            let expr_ty = self.expr_type(expr_node)
            let resolved_ty = if expr_ty > 0: self.sema.resolve_alias(expr_ty) else: 0

            var handled = false
            if spec_node != 0:
                let spec_flags = self.ast.get_data0(spec_node)
                let spec_mode = spec_flags & 255
                let spec_width = self.ast.get_data1(spec_node)
                let spec_precision = self.ast.get_data2(spec_node)
                if spec_mode == 63:
                    // Debug mode: format to str then write
                    let debug_str = self.lower_fmt_debug(expr_op, resolved_ty, node)
                    self.lower_fstring_buf_write_str(buf_op, debug_str, node)
                    handled = true
                else if spec_mode != 0 or spec_width > 0 or spec_precision >= 0 or (spec_flags & 0x1C0000) != 0:
                    // Spec formatting: emit FMT_BUF_WRITE_FMT intrinsic
                    self.lower_fstring_buf_write_fmt(buf_op, expr_op, spec_flags, spec_width, spec_precision, resolved_ty, node)
                    handled = true
            if not handled:
                if resolved_ty == self.sema.ty_str:
                    // String: write directly
                    self.lower_fstring_buf_write_str(buf_op, expr_op, node)
                else:
                    // Non-str: format to str then write
                    let formatted = self.lower_fmt_to_str(expr_op, node)
                    self.lower_fstring_buf_write_str(buf_op, formatted, node)
            pos = pos + 3
        else:
            pos = pos + 1
            i = i + 1
            continue
        i = i + 1

    // Step 3: Finalize buffer to str
    self.lower_fstring_buf_finish(buf_op, node)

fn MirBuilder.lower_fstring_buf_new(self: MirBuilder, node: i32) -> i32:
    let fn_op = self.const_operand(ConstKind.CK_FN, self.pool.intern("fmt_buf_new"), self.sema.ty_i32)
    let call_args: Vec[i32] = Vec.new()
    let args_id = self.body.new_call_args(call_args)
    // Result is a pointer (use i32 as placeholder sema type, codegen knows it's ptr)
    let result_local = self.new_temp(self.sema.ty_i32)
    let result_place = self.place_for_local(result_local)
    let next_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, fn_op, args_id, result_place, next_bb)
    self.switch_to(next_bb)
    self.body.set_call_intrinsic(args_id, MirIntrinsic.MIR_INTRINSIC_FMT_BUF_NEW)
    self.body.new_operand(OperandKind.OK_COPY, result_place)

fn MirBuilder.lower_fstring_buf_write_str(self: MirBuilder, buf_op: i32, str_op: i32, node: i32):
    let fn_op = self.const_operand(ConstKind.CK_FN, self.pool.intern("fmt_buf_write_str"), self.sema.ty_void)
    let call_args: Vec[i32] = Vec.new()
    call_args.push(buf_op)
    call_args.push(str_op)
    let args_id = self.body.new_call_args(call_args)
    let result_local = self.new_temp(self.sema.ty_void)
    let result_place = self.place_for_local(result_local)
    let next_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, fn_op, args_id, result_place, next_bb)
    self.switch_to(next_bb)
    self.body.set_call_intrinsic(args_id, MirIntrinsic.MIR_INTRINSIC_FMT_BUF_WRITE_STR)

fn MirBuilder.lower_fstring_buf_write_fmt(self: MirBuilder, buf_op: i32, val_op: i32, flags: i32, width: i32, precision: i32, sema_ty: i32, node: i32):
    let fn_op = self.const_operand(ConstKind.CK_FN, self.pool.intern("fmt_buf_write_fmt"), self.sema.ty_void)
    let flags_const = self.const_operand(ConstKind.CK_INT, flags, self.sema.ty_i32)
    let width_const = self.const_operand(ConstKind.CK_INT, width, self.sema.ty_i32)
    let prec_const = self.const_operand(ConstKind.CK_INT, precision, self.sema.ty_i32)
    let type_const = self.const_operand(ConstKind.CK_INT, sema_ty, self.sema.ty_i32)
    let call_args: Vec[i32] = Vec.new()
    call_args.push(buf_op)
    call_args.push(val_op)
    call_args.push(flags_const)
    call_args.push(width_const)
    call_args.push(prec_const)
    call_args.push(type_const)
    let args_id = self.body.new_call_args(call_args)
    let result_local = self.new_temp(self.sema.ty_void)
    let result_place = self.place_for_local(result_local)
    let next_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, fn_op, args_id, result_place, next_bb)
    self.switch_to(next_bb)
    self.body.set_call_intrinsic(args_id, MirIntrinsic.MIR_INTRINSIC_FMT_BUF_WRITE_FMT)

fn MirBuilder.lower_fstring_buf_finish(self: MirBuilder, buf_op: i32, node: i32) -> i32:
    let fn_op = self.const_operand(ConstKind.CK_FN, self.pool.intern("fmt_buf_finish"), self.sema.ty_str)
    let call_args: Vec[i32] = Vec.new()
    call_args.push(buf_op)
    let args_id = self.body.new_call_args(call_args)
    let result_local = self.new_temp(self.sema.ty_str)
    let result_place = self.place_for_local(result_local)
    let next_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, fn_op, args_id, result_place, next_bb)
    self.switch_to(next_bb)
    self.body.set_call_intrinsic(args_id, MirIntrinsic.MIR_INTRINSIC_FMT_BUF_FINISH)
    self.body.new_operand(OperandKind.OK_COPY, result_place)

fn MirBuilder.lower_float_lit(self: MirBuilder, sym: i32, type_id: i32) -> i32:
    let ty = if type_id == 0 or self.sema.get_type_kind(type_id) == TypeKind.TY_VOID: self.sema.ty_f64 else: type_id
    self.const_operand(ConstKind.CK_FLOAT, sym, ty)

fn MirBuilder.lower_unit(self: MirBuilder) -> i32:
    self.unit_operand()

fn MirBuilder.is_bare_none(self: MirBuilder, node: i32) -> bool:
    if node == 0 or self.ast.kind(node) != NodeKind.NK_IDENT:
        return false
    self.pool.resolve(self.ast.get_data0(node)) == "None"

fn MirBuilder.ensure_global_local(self: MirBuilder, sym: i32) -> i32:
    // Check if we already created a proxy local for this global
    let existing = self.lookup_local(sym)
    if existing >= 0:
        return existing
    // Scan module declarations for a mutable let (var) or extern var
    for di in 0..self.ast.decl_count():
        let decl = self.ast.get_decl(di)
        let dk = self.ast.kind(decl)
        if dk == NodeKind.NK_EXTERN_VAR:
            if self.ast.get_data0(decl) != sym:
                continue
            let ev_flags = self.ast.get_data2(decl)
            let ev_is_mut = ev_flags % 2
            let ev_type_node = self.ast.get_data1(decl)
            var ev_ty = self.sema.resolve_type_expr(ev_type_node)
            if ev_ty <= 0:
                ev_ty = self.sema.ty_i32
            let local_id = self.body.new_local(ev_ty, ev_is_mut, sym, 1)
            self.bind_local(sym, local_id)
            return local_id
        if dk != NodeKind.NK_LET_DECL:
            continue
        if self.ast.get_data0(decl) != sym:
            continue
        let flags = self.ast.get_data2(decl)
        let is_mut = flags % 2
        // Prefer an explicit type annotation. Otherwise infer from the
        // unwrapped initializer expression instead of the raw comptime wrapper.
        var gty = 0
        let type_extra_packed = flags / 4
        if type_extra_packed > 0:
            let type_node = self.ast.get_extra(type_extra_packed - 1)
            let annotated = self.sema.resolve_type_expr(type_node) as i32
            if annotated > 0:
                gty = annotated
        let val_node = self.ast.get_data1(decl)
        var typed_value = val_node
        while typed_value != 0:
            let typed_kind = self.ast.kind(typed_value)
            if typed_kind != NodeKind.NK_COMPTIME and typed_kind != NodeKind.NK_GROUPED:
                break
            typed_value = self.ast.get_data0(typed_value)
        if gty == 0 and typed_value != 0:
            let inferred = self.expr_type(typed_value)
            if inferred != 0:
                gty = inferred
        if gty == 0:
            gty = self.sema.ty_i32 as i32
        let local_id = self.body.new_local(gty, is_mut, sym, 1)
        self.bind_local(sym, local_id)
        return local_id
    0 - 1

fn MirBuilder.lower_var(self: MirBuilder, sym: i32, type_id: i32) -> i32:
    let hinted_ty = if self.expected_type != 0: self.expected_type else: type_id
    if self.pool.resolve(sym) == "None" and hinted_ty != 0:
        let hinted_resolved = self.sema.resolve_alias(hinted_ty)
        let hinted_tk = self.sema.get_type_kind(hinted_resolved)
        if hinted_tk == TypeKind.TY_PTR or hinted_tk == TypeKind.TY_REF:
            return self.const_operand(ConstKind.CK_INT, 0, self.sema.ty_i32)

    let local = self.lookup_local(sym)
    if local >= 0:
        let place = self.body.new_place(local)
        if self.sema.is_copy(type_id) != 0:
            return self.body.new_operand(OperandKind.OK_COPY, place)
        return self.body.new_operand(OperandKind.OK_MOVE, place)
    let alias_place = self.lookup_alias_place(sym)
    if alias_place >= 0:
        return self.body.new_operand(OperandKind.OK_COPY, alias_place)

    let sig_idx = self.sema.get_sig(sym)
    if sig_idx >= 0:
        let fn_ty = if type_id != 0: type_id else: self.sema.sig_type_ids.get(sig_idx as i64)
        return self.const_operand(ConstKind.CK_FN, sym, fn_ty)

    // Generic function reference (monomorphized at codegen time)
    if self.sema.generic_fn_nodes.contains(sym):
        return self.const_operand(ConstKind.CK_FN, sym, type_id)

    let const_node = self.try_resolve_module_const_node(sym)
    if const_node != 0:
        let inferred_ty = self.try_resolve_module_const_type(sym)
        let ty = if inferred_ty != 0:
            inferred_ty
        else:
            if type_id != 0: type_id else: self.sema.ty_i32 as i32
        let exact = self.ast.int_literal_exact_expr(const_node)
        if exact.ok != 0:
            let fast = exact_int_try_i64(exact_int_expr_magnitude(exact))
            if exact.negative != 0 or fast.ok == 0:
                return self.exact_int_const_operand(const_node, ty)

    // Try module-level constant (const X = 42)
    let const_val = self.try_resolve_module_const_val(sym)
    if const_val != -9223372036854775807:
        let inferred_ty = self.try_resolve_module_const_type(sym)
        let ty = if inferred_ty != 0:
            inferred_ty
        else:
            if const_val < -2147483648 or const_val > 2147483647: self.sema.ty_i64 else: self.sema.ty_i32
        return self.int_const_operand(const_val, ty)

    // Try module-level float constant (let PI: f64 = 3.14)
    let float_str_idx = self.try_resolve_module_float_const(sym)
    if float_str_idx >= 0:
        let inferred_ty = self.try_resolve_module_const_type(sym)
        let ty = if inferred_ty != 0: inferred_ty else: self.sema.ty_f64
        return self.const_operand(ConstKind.CK_FLOAT, float_str_idx, ty)

    // Check for enum variant without payload (None, etc.)
    if self.sema.variant_lookup.contains(sym):
        let vl_variant_idx = self.sema.variant_lookup.get(sym).unwrap()
        let vl_decl_ty = self.sema.variant_type_ids.get(sym).unwrap()
        var vl_result_ty = if self.expected_type != 0: self.expected_type else: type_id
        if vl_result_ty == 0:
            vl_result_ty = vl_decl_ty
        // Match the qualified and shorthand variant lowering paths:
        // payloadless discriminant enums materialize as repr-backed int constants.
        let vl_resolved = self.sema.resolve_alias(vl_decl_ty)
        let vl_is_disc_enum = self.sema.disc_repr_types.contains(vl_resolved as i32)
        if vl_is_disc_enum and not self.sema.disc_has_payload.contains(vl_resolved as i32):
            let vl_disc_val = if self.sema.disc_values.contains(sym): self.sema.disc_values.get(sym).unwrap() else: vl_variant_idx
            return self.int_const_operand(vl_disc_val as i64, vl_result_ty)
        let vl_fields: Vec[i32] = Vec.new()
        let vl_names: Vec[i32] = Vec.new()
        let vl_fid = self.body.new_agg_fields(vl_fields, vl_names)
        let vl_rv = self.body.new_rvalue(RvalueKind.RK_AGGREGATE, 1, vl_fid, vl_variant_idx)
        let vl_tmp = self.new_temp(vl_result_ty)
        let vl_place = self.place_for_local(vl_tmp)
        self.body.push_stmt(self.cur_bb, StmtKind.Assign, vl_place, vl_rv, 0)
        return self.body.new_operand(OperandKind.OK_COPY, vl_place)

    // Try module-level mutable variable (var X = ...)
    let gv_local = self.ensure_global_local(sym)
    if gv_local >= 0:
        let gv_place = self.body.new_place(gv_local)
        return self.body.new_operand(OperandKind.OK_COPY, gv_place)

    if with_getenv_str("WITH_MIR_AUDIT").len() > 0:
        let var_name = self.pool.resolve(sym)
        let fn_name = self.pool.resolve(self.body.fn_sym)
        with_eprint("[mir-var-miss] sym=" ++ var_name ++ " fn=" ++ fn_name)
    self.mark_unsupported()
    self.unit_operand()

fn MirBuilder.assign_operand_to_place(self: MirBuilder, place: i32, operand_id: i32, span: i32):
    let rval = self.body.new_rvalue(RvalueKind.RK_USE, operand_id, 0, 0)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, place, rval, span)

fn MirBuilder.lower_bin_op(self: MirBuilder, op: i32, lhs_expr: i32, rhs_expr: i32, node: i32) -> i32:
    // Short-circuit evaluation for logical and/or
    if op == 11 or op == 12:
        return self.lower_short_circuit(op, lhs_expr, rhs_expr, node)
    // Check for operator overloading: if LHS is a struct with an operator method, lower as call
    let lhs_ty = self.expr_type(lhs_expr)
    let rhs_ty = self.expr_type(rhs_expr)
    let lhs_resolved = if lhs_ty != 0: self.sema.resolve_alias(lhs_ty) else: 0
    let rhs_resolved = if rhs_ty != 0: self.sema.resolve_alias(rhs_ty) else: 0
    let lhs_tk = if lhs_resolved != 0: self.sema.get_type_kind(lhs_resolved) else: 0
    let rhs_tk = if rhs_resolved != 0: self.sema.get_type_kind(rhs_resolved) else: 0
    if lhs_ty != 0:
        if lhs_tk == TypeKind.TY_STRUCT:
            let method_name = mir_op_method_name(op)
            if method_name.len() > 0:
                let type_name_sym = self.sema.get_type_d0(lhs_resolved)
                if type_name_sym != 0:
                    let method_sym = self.sema.pool_lookup_symbol(self.sema.pool_resolve(type_name_sym) ++ "." ++ method_name)
                    let sig = self.sema.get_sig(method_sym)
                    if sig >= 0:
                        return self.lower_method_bin_op(lhs_expr, rhs_expr, method_sym, node)
    // Reversed-operand dispatch: try RHS type
    if rhs_ty != 0:
        if rhs_tk == TypeKind.TY_STRUCT:
            let rhs_method_name = mir_op_method_name(op)
            if rhs_method_name.len() > 0:
                let rhs_type_name_sym = self.sema.get_type_d0(rhs_resolved)
                if rhs_type_name_sym != 0:
                    let rhs_method_sym = self.sema.pool_lookup_symbol(self.sema.pool_resolve(rhs_type_name_sym) ++ "." ++ rhs_method_name)
                    let rhs_sig = self.sema.get_sig(rhs_method_sym)
                    if rhs_sig >= 0:
                        return self.lower_method_bin_op(lhs_expr, rhs_expr, rhs_method_sym, node)
    let saved_expected = self.expected_type
    if self.is_bare_none(lhs_expr) and (rhs_tk == TypeKind.TY_PTR or rhs_tk == TypeKind.TY_REF):
        self.expected_type = rhs_ty
    else:
        self.expected_type = saved_expected
    let lhs = self.lower_expr(lhs_expr)
    if self.is_bare_none(rhs_expr) and (lhs_tk == TypeKind.TY_PTR or lhs_tk == TypeKind.TY_REF):
        self.expected_type = lhs_ty
    else:
        self.expected_type = saved_expected
    let rhs = self.lower_expr(rhs_expr)
    self.expected_type = saved_expected
    let rv = self.body.new_rvalue(RvalueKind.RK_BIN_OP, op, lhs, rhs)
    let ty = self.expr_type(node)
    let temp = self.new_temp(ty)
    let place = self.place_for_local(temp)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, place, rv, self.ast.get_start(node))
    if self.sema.is_copy(ty) != 0:
        return self.body.new_operand(OperandKind.OK_COPY, place)
    self.body.new_operand(OperandKind.OK_MOVE, place)

fn MirBuilder.lower_short_circuit(self: MirBuilder, op: i32, lhs_expr: i32, rhs_expr: i32, node: i32) -> i32:
    // Short-circuit: for `a or b`, evaluate a; if true, result is true, else evaluate b.
    // For `a and b`, evaluate a; if false, result is false, else evaluate b.
    let result = self.new_temp(self.sema.ty_bool)
    let result_place = self.place_for_local(result)
    let lhs = self.lower_expr(lhs_expr)
    let lhs_rv = self.body.new_rvalue(RvalueKind.RK_USE, lhs, 0, 0)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, result_place, lhs_rv, self.ast.get_start(node))
    let rhs_bb = self.new_block()
    let end_bb = self.new_block()
    let lhs_read = self.body.new_operand(OperandKind.OK_COPY, result_place)
    // Use switch_int: value 1 (true) goes to one target, default goes to other
    let vals: Vec[i32] = Vec.new()
    vals.push(1)
    let targets: Vec[i32] = Vec.new()
    if op == 12:
        // or: if lhs is true (1), skip to end; default (false) → evaluate rhs
        targets.push(end_bb as i32)
        let table = self.body.new_switch_table(vals, targets)
        self.terminate(TermKind.TK_SWITCH_INT, lhs_read, table, rhs_bb, 0)
    else:
        // and: if lhs is true (1), evaluate rhs; default (false) → skip to end
        targets.push(rhs_bb as i32)
        let table = self.body.new_switch_table(vals, targets)
        self.terminate(TermKind.TK_SWITCH_INT, lhs_read, table, end_bb, 0)
    self.switch_to(rhs_bb)
    let rhs = self.lower_expr(rhs_expr)
    let rhs_rv = self.body.new_rvalue(RvalueKind.RK_USE, rhs, 0, 0)
    let result_place2 = self.place_for_local(result)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, result_place2, rhs_rv, self.ast.get_start(node))
    self.terminate(TermKind.TK_GOTO, end_bb, 0, 0, 0)
    self.switch_to(end_bb)
    self.body.new_operand(OperandKind.OK_COPY, self.place_for_local(result))

fn mir_op_method_name(op: i32) -> str:
    if op == 0: return "add"    // BinaryOp.OP_ADD
    if op == 1: return "sub"    // BinaryOp.OP_SUB
    if op == 2: return "mul"    // BinaryOp.OP_MUL
    if op == 3: return "div"    // BinaryOp.OP_DIV
    if op == 4: return "mod"    // BinaryOp.OP_MOD
    if op == 5: return "eq"     // BinaryOp.OP_EQ
    if op == 6: return "ne"     // BinaryOp.OP_NEQ
    if op == 7: return "lt"     // BinaryOp.OP_LT
    if op == 8: return "gt"     // BinaryOp.OP_GT
    if op == 9: return "le"     // BinaryOp.OP_LTE
    if op == 10: return "ge"    // BinaryOp.OP_GTE
    if op == 28: return "matmul" // BinaryOp.OP_MATMUL
    ""

fn MirBuilder.lower_method_bin_op(self: MirBuilder, lhs_expr: i32, rhs_expr: i32, method_sym: i32, node: i32) -> i32:
    // Lower as: method_sym(lhs, rhs)
    let fn_op = self.lower_var(method_sym, 0)
    let arg_nodes: Vec[i32] = Vec.new()
    arg_nodes.push(lhs_expr)
    arg_nodes.push(rhs_expr)
    self.lower_call_with_arg_nodes(fn_op, method_sym, arg_nodes, self.expr_type(node), node)

fn MirBuilder.lower_fn_address(self: MirBuilder, expr: i32, type_id: i32) -> i32:
    if expr == 0:
        return 0 - 1
    let kind = self.ast.kind(expr)
    if kind == NodeKind.NK_GROUPED:
        return self.lower_fn_address(self.ast.get_data0(expr), type_id)
    if kind != NodeKind.NK_IDENT:
        return 0 - 1
    let sym = self.ast.get_data0(expr)
    if self.lookup_local(sym) >= 0:
        return 0 - 1
    if self.lookup_alias_place(sym) >= 0:
        return 0 - 1
    if self.sema.get_sig(sym) >= 0 or self.sema.generic_fn_nodes.contains(sym):
        return self.lower_var(sym, type_id)
    0 - 1

fn MirBuilder.lower_un_op(self: MirBuilder, op: i32, expr: i32, node: i32) -> i32:
    if op == UnaryOp.UOP_REF or op == UnaryOp.UOP_MUT_REF:
        let fn_addr = self.lower_fn_address(expr, self.expr_type(node))
        if fn_addr >= 0:
            return fn_addr
        let place = self.lower_expr_place(expr)
        let rv = self.body.new_rvalue(RvalueKind.RK_REF, if op == UnaryOp.UOP_MUT_REF: BorrowKind.EXCLUSIVE else: BorrowKind.SHARED, place, 0)
        let ty = self.expr_type(node)
        let temp = self.new_temp(ty)
        let temp_place = self.place_for_local(temp)
        self.body.push_stmt(self.cur_bb, StmtKind.Assign, temp_place, rv, self.ast.get_start(node))
        return self.body.new_operand(OperandKind.OK_COPY, temp_place)

    if op == UnaryOp.UOP_DEREF:
        let place = self.lower_expr_place(expr)
        let deref_place = self.body.new_deref_place(place)
        return self.body.new_operand(OperandKind.OK_COPY, deref_place)

    let arg = self.lower_expr(expr)
    let rv = self.body.new_rvalue(RvalueKind.RK_UN_OP, op, arg, 0)
    let ty = self.expr_type(node)
    let temp = self.new_temp(ty)
    let place = self.place_for_local(temp)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, place, rv, self.ast.get_start(node))
    self.body.new_operand(OperandKind.OK_COPY, place)

fn MirBuilder.lower_cast(self: MirBuilder, expr: i32, target_type_id: i32, node: i32) -> i32:
    let op = self.lower_expr(expr)
    let src_sema_ty = self.expr_type(expr)
    let rv = self.body.new_rvalue(RvalueKind.RK_CAST, op, target_type_id, src_sema_ty)
    let temp = self.new_temp(target_type_id)
    let place = self.place_for_local(temp)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, place, rv, self.ast.get_start(node))
    self.body.new_operand(OperandKind.OK_COPY, place)

fn MirBuilder.lower_field_access(self: MirBuilder, node: i32) -> i32:
    let base_expr = self.ast.get_data0(node)
    let field_idx = self.ast.get_data1(node)
    let field_ty = self.expr_type(node)
    if field_ty == 0 or field_ty == self.sema.ty_void as i32:
        self.mark_unsupported()
        return self.place_for_local(0)
    let base = self.lower_field_base_place(base_expr)
    self.body.new_field_place(base, field_idx, field_ty)

fn MirBuilder.lower_field_base_place(self: MirBuilder, base_expr: i32) -> i32:
    var base = self.lower_expr_place(base_expr)
    var base_ty = self.expr_type(base_expr)
    while base_ty > 0:
        let resolved = self.sema.resolve_alias(base_ty)
        let tk = self.sema.get_type_kind(resolved)
        if tk != TypeKind.TY_PTR and tk != TypeKind.TY_REF:
            break
        base = self.body.new_deref_place(base)
        base_ty = self.sema.get_type_d0(resolved)
    base

fn MirBuilder.lower_index(self: MirBuilder, base_expr: i32, index_expr: i32) -> i32:
    var base = self.lower_expr_place(base_expr)
    // Indexing through `&Vec[T]` / `&mut Vec[T]` should index the container,
    // not treat the reference itself like a raw pointer.
    var base_ty = self.expr_type(base_expr)
    while base_ty > 0:
        let resolved = self.sema.resolve_alias(base_ty)
        if self.sema.get_type_kind(resolved) != TypeKind.TY_REF:
            break
        base = self.body.new_deref_place(base)
        base_ty = self.sema.get_type_d0(resolved)
    let elem_ty = self.indexed_element_type(base_ty)
    let idx_op = self.lower_expr(index_expr)
    let idx_ty = self.expr_type(index_expr)
    let idx_local = self.new_temp(idx_ty)
    let idx_place = self.place_for_local(idx_local)
    self.assign_operand_to_place(idx_place, idx_op, self.ast.get_start(index_expr))
    self.body.new_index_place(base, idx_local, elem_ty)

fn MirBuilder.lower_call_place(self: MirBuilder, node: i32) -> i32:
    if node == 0 or self.ast.kind(node) != NodeKind.NK_CALL:
        return -1
    let callee = self.ast.get_data0(node)
    if self.ast.kind(callee) != NodeKind.NK_FIELD_ACCESS:
        return -1
    let recv_expr = self.ast.get_data0(callee)
    let method_sym = self.ast.get_data1(callee)
    var recv_type = self.expr_type(recv_expr)
    if recv_type == 0 or recv_type == self.sema.ty_void:
        recv_type = self.type_receiver_type(recv_expr)
    if recv_type == 0 or recv_type == self.sema.ty_void:
        return -1
    let method_name = self.pool.resolve_symbol(method_sym)
    let intrinsic = self.classify_intrinsic(recv_type, method_name)
    // Preserve lvalue identity for vec element projections used as a place
    // (for example `items.get(0).tags.push(...)`).
    if intrinsic != MirIntrinsic.MIR_INTRINSIC_VEC_GET:
        return -1
    let arg_count = self.ast.get_data2(node)
    if arg_count != 1:
        return -1
    let arg_start = self.ast.get_data1(node)
    let index_expr = self.ast.get_extra(arg_start)
    self.lower_index(recv_expr, index_expr)

fn MirBuilder.lower_binding_alias_place(self: MirBuilder, node: i32) -> i32:
    if node == 0:
        return -1
    let kind = self.ast.kind(node)
    if kind == NodeKind.NK_GROUPED:
        return self.lower_binding_alias_place(self.ast.get_data0(node))
    if kind == NodeKind.NK_CALL:
        return self.lower_call_place(node)
    if kind == NodeKind.NK_FIELD_ACCESS:
        let base_expr = self.ast.get_data0(node)
        let base_place = self.lower_binding_alias_place(base_expr)
        if base_place < 0:
            return -1
        let field_sym = self.ast.get_data1(node)
        var field_base = base_place
        var base_ty = self.expr_type(base_expr)
        while base_ty > 0:
            let resolved = self.sema.resolve_alias(base_ty)
            let tk = self.sema.get_type_kind(resolved)
            if tk != TypeKind.TY_PTR and tk != TypeKind.TY_REF:
                break
            field_base = self.body.new_deref_place(field_base)
            base_ty = self.sema.get_type_d0(resolved)
        return self.body.new_field_place(field_base, field_sym, self.expr_type(node))
    -1

fn MirBuilder.lower_vec_literal_push(self: MirBuilder, vec_place: i32, elem_node: i32, elem_ty: i32):
    if elem_node == 0:
        return
    let push_sym = self.pool.intern("push")
    let fn_op = self.const_operand(ConstKind.CK_FN, push_sym, self.sema.ty_void)
    let saved_expected = self.expected_type
    if elem_ty > 0 and elem_ty != self.sema.ty_void:
        self.expected_type = elem_ty
    let elem_op = self.lower_expr(elem_node)
    self.expected_type = saved_expected
    let args: Vec[i32] = Vec.new()
    args.push(self.body.new_operand(OperandKind.OK_COPY, vec_place))
    args.push(elem_op)
    let args_id = self.body.new_call_args(args)
    let result_local = self.new_temp(self.sema.ty_void)
    let result_place = self.place_for_local(result_local)
    let next_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, fn_op, args_id, result_place, next_bb)
    self.switch_to(next_bb)
    self.body.set_call_intrinsic(args_id, MirIntrinsic.MIR_INTRINSIC_VEC_PUSH)

fn MirBuilder.lower_vec_literal(self: MirBuilder, node: i32, vec_ty: i32) -> i32:
    let base_expr = self.ast.get_data0(node)
    let first_elem = self.ast.get_data1(node)
    let second_elem = self.ast.get_data2(node)
    let new_sym = self.pool.intern("new")
    let new_op = self.lower_intrinsic_call(MirIntrinsic.MIR_INTRINSIC_VEC_NEW, base_expr, new_sym, 0, 0, node)
    let vec_place = self.materialize_operand(new_op, vec_ty, self.ast.get_start(node))
    let resolved = self.sema.resolve_alias(vec_ty)
    let elem_ty = if self.sema.get_type_kind(resolved) == TypeKind.TY_GENERIC_INST: self.sema.get_generic_inst_arg(resolved, 0) else: 0
    self.lower_vec_literal_push(vec_place, first_elem, elem_ty)
    if second_elem != 0:
        self.lower_vec_literal_push(vec_place, second_elem, elem_ty)
    if self.sema.is_copy(vec_ty) != 0:
        return self.body.new_operand(OperandKind.OK_COPY, vec_place)
    self.body.new_operand(OperandKind.OK_MOVE, vec_place)

fn MirBuilder.lower_deref(self: MirBuilder, expr: i32) -> i32:
    let base = self.lower_expr_place(expr)
    self.body.new_deref_place(base)

fn MirBuilder.lower_ref(self: MirBuilder, expr: i32, borrow_kind: i32, node: i32) -> i32:
    let place = self.lower_expr_place(expr)
    let rv = self.body.new_rvalue(RvalueKind.RK_REF, borrow_kind, place, 0)
    let ty = self.expr_type(node)
    let temp = self.new_temp(ty)
    let temp_place = self.place_for_local(temp)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, temp_place, rv, self.ast.get_start(node))
    self.body.new_operand(OperandKind.OK_COPY, temp_place)

fn MirBuilder.lower_assign(self: MirBuilder, place_expr: i32, rhs_expr: i32):
    // Multi-index assignment: a[i, j] = value → call multi_index_set
    if self.ast.kind(place_expr) == NodeKind.NK_MULTI_INDEX:
        let mi_base_op = self.lower_expr(self.ast.get_data0(place_expr))
        let mi_rhs_op = self.lower_expr(rhs_expr)
        let mi_args: Vec[i32] = Vec.new()
        mi_args.push(mi_base_op)
        mi_args.push(mi_rhs_op)
        let mi_args_id = self.body.new_call_args(mi_args)
        self.body.set_call_intrinsic(mi_args_id, MirIntrinsic.MIR_INTRINSIC_MULTI_INDEX_SET)
        self.body.set_call_ast_node(mi_args_id, place_expr)
        let mi_next_bb = self.new_block()
        self.terminate(TermKind.TK_CALL, self.unit_operand(), mi_args_id, self.place_for_local(0), mi_next_bb)
        self.switch_to(mi_next_bb)
        return
    let place = self.lower_expr_place(place_expr)
    let saved_expected = self.expected_type
    let dest_ty = self.expr_type(place_expr)
    if dest_ty != 0 and dest_ty != self.sema.ty_void:
        self.expected_type = dest_ty
    let rhs = self.lower_expr(rhs_expr)
    self.expected_type = saved_expected
    // Drop the old value before reassignment if the type implements Drop.
    if dest_ty != 0 and self.sema.is_copy(dest_ty) == 0:
        let resolved_ty = self.sema.resolve_alias(dest_ty)
        let tk = self.sema.get_type_kind(resolved_ty)
        if tk == TypeKind.TY_STRUCT:
            let type_name = self.sema.get_type_d0(resolved_ty)
            if self.sema.has_drop_method(type_name) != 0:
                self.body.push_stmt(self.cur_bb, StmtKind.Drop, place, 0, self.ast.get_start(place_expr))
    self.assign_operand_to_place(place, rhs, self.ast.get_start(place_expr))

fn MirBuilder.lower_expr_place(self: MirBuilder, node: i32) -> i32:
    if node == 0:
        return self.place_for_local(0)

    let kind = self.ast.kind(node)

    if kind == NodeKind.NK_IDENT:
        let sym = self.ast.get_data0(node)
        let local = self.lookup_local(sym)
        if local >= 0:
            return self.place_for_local(local)
        let alias_place = self.lookup_alias_place(sym)
        if alias_place >= 0:
            return alias_place
        // Try module-level mutable variable
        let gv_local = self.ensure_global_local(sym)
        if gv_local >= 0:
            return self.place_for_local(gv_local)
        self.mark_unsupported()
        return self.place_for_local(0)

    if kind == NodeKind.NK_FIELD_ACCESS:
        let base = self.lower_field_base_place(self.ast.get_data0(node))
        let field_sym = self.ast.get_data1(node)
        let field_ty = self.expr_type(node)
        if field_ty == 0 or field_ty == self.sema.ty_void as i32:
            self.mark_unsupported()
            return self.place_for_local(0)
        // Field symbol is mapped deterministically to a projection index by symbol value.
        return self.body.new_field_place(base, field_sym, field_ty)

    if kind == NodeKind.NK_INDEX:
        if self.vec_literal_type(node) != 0:
            let op = self.lower_expr(node)
            let ty = self.expr_type(node)
            let tmp = self.new_temp(ty)
            let p = self.place_for_local(tmp)
            self.assign_operand_to_place(p, op, self.ast.get_start(node))
            return p
        return self.lower_index(self.ast.get_data0(node), self.ast.get_data1(node))

    if kind == NodeKind.NK_MULTI_INDEX:
        // Multi-dimensional indexing via MIR_INTRINSIC_MULTI_INDEX.
        // Lower base + all spec expressions as MIR args.
        // Arg layout: [base, spec0_start, spec0_stop, spec0_step, spec1_start, ...]
        // Each spec contributes 3 args (0 if absent). The AST node carries
        // kind/has_* metadata that codegen reads directly.
        let base_op = self.lower_expr(self.ast.get_data0(node))
        let mi_args: Vec[i32] = Vec.new()
        mi_args.push(base_op)
        let specs_start = self.ast.get_data1(node)
        let specs_count = self.ast.get_data2(node)
        for si in 0..specs_count:
            let spec = self.ast.get_extra(specs_start + si)
            let d0 = self.ast.get_data0(spec)
            let d1 = self.ast.get_data1(spec)
            let d2 = self.ast.get_data2(spec)
            let step_node = d2 - (d2 / INDEX_KIND_SHIFT) * INDEX_KIND_SHIFT
            // Lower each expression or emit 0
            mi_args.push(if d0 != 0: self.lower_expr(d0) else: self.int_const_operand(0, self.sema.ty_i64))
            mi_args.push(if d1 != 0: self.lower_expr(d1) else: self.int_const_operand(0, self.sema.ty_i64))
            mi_args.push(if step_node != 0: self.lower_expr(step_node) else: self.int_const_operand(0, self.sema.ty_i64))
        let mi_args_id = self.body.new_call_args(mi_args)
        self.body.set_call_intrinsic(mi_args_id, MirIntrinsic.MIR_INTRINSIC_MULTI_INDEX)
        self.body.set_call_ast_node(mi_args_id, node)
        let mi_ret_ty = self.expr_type(node)
        let mi_result = self.new_temp(mi_ret_ty)
        let mi_result_place = self.place_for_local(mi_result)
        let mi_next_bb = self.new_block()
        self.terminate(TermKind.TK_CALL, self.unit_operand(), mi_args_id, mi_result_place, mi_next_bb)
        self.switch_to(mi_next_bb)
        return mi_result_place

    if kind == NodeKind.NK_ASSIGN:
        let target = self.ast.get_data0(node)
        self.lower_assign(target, self.ast.get_data1(node))
        return self.lower_expr_place(target)

    if kind == NodeKind.NK_CALL:
        let call_place = self.lower_call_place(node)
        if call_place >= 0:
            return call_place

    if kind == NodeKind.NK_UNARY and self.ast.get_data0(node) == UnaryOp.UOP_DEREF:
        return self.lower_deref(self.ast.get_data1(node))

    if kind == NodeKind.NK_GROUPED:
        return self.lower_expr_place(self.ast.get_data0(node))

    // Fallback: materialize value into temp local and return its place.
    let op = self.lower_expr(node)
    let ty = self.expr_type(node)
    let tmp = self.new_temp(ty)
    let p = self.place_for_local(tmp)
    self.assign_operand_to_place(p, op, self.ast.get_start(node))
    p

fn MirBuilder.lower_let_binding(self: MirBuilder, node: i32):
    let name_sym = self.ast.get_data0(node)
    let rhs_expr = self.ast.get_data1(node)
    let flags = self.ast.get_data2(node)
    let mutable = flags % 2

    let bind_ty = self.binding_type(node)
    if mutable == 0:
        let alias_place = self.lower_binding_alias_place(rhs_expr)
        if alias_place >= 0:
            self.bind_alias_place(name_sym, alias_place, bind_ty)
            return
    let local_id = self.body.new_local(bind_ty, mutable, name_sym, 1)
    self.bind_local(name_sym, local_id)

    // d1 = 0 for normal storage, bind_ty for zero-init (no initializer)
    let storage_d1 = if rhs_expr == 0: bind_ty else: 0
    self.body.push_stmt(self.cur_bb, StmtKind.StorageLive, local_id, storage_d1, self.ast.get_start(node))
    if self.sema.is_copy(bind_ty) == 0:
        self.schedule_drop(local_id, DropKind.DK_VALUE)

    if rhs_expr != 0:
        let place = self.place_for_local(local_id)
        let saved_expected = self.expected_type
        self.expected_type = bind_ty
        let rhs_op = self.lower_expr(rhs_expr)
        self.expected_type = saved_expected
        self.assign_operand_to_place(place, rhs_op, self.ast.get_start(node))

fn MirBuilder.lower_tuple_destructure(self: MirBuilder, node: i32):
    let extra_start = self.ast.get_data0(node)
    let name_count = self.ast.get_data1(node)
    let rhs_expr = self.ast.get_data2(node)
    let rhs_ty = self.expr_type(rhs_expr)
    let rhs_op = self.lower_expr(rhs_expr)
    let rhs_place = self.materialize_operand(rhs_op, rhs_ty, self.ast.get_start(node))
    // Bind each name to the corresponding tuple field
    for ni in 0..name_count:
        let n_sym = self.ast.get_extra(extra_start + ni)
        if n_sym == 0:
            continue
        // Negative sym means ..rest pattern — skip for now
        if n_sym < 0:
            continue
        let elem_ty = self.tuple_elem_type(rhs_ty, ni)
        let local_id = self.body.new_local(elem_ty, 0, n_sym, 1)
        self.bind_local(n_sym, local_id)
        self.body.push_stmt(self.cur_bb, StmtKind.StorageLive, local_id, 0, self.ast.get_start(node))
        let field_place = self.body.new_field_place(rhs_place, ni, elem_ty)
        let field_op = self.body.new_operand(OperandKind.OK_COPY, field_place)
        let dst_place = self.place_for_local(local_id)
        self.assign_operand_to_place(dst_place, field_op, self.ast.get_start(node))

fn MirBuilder.lower_let_else(self: MirBuilder, node: i32):
    let pat = self.ast.get_data0(node)
    let rhs = self.ast.get_data1(node)
    let else_body = self.ast.get_data2(node)
    let rhs_op = self.lower_expr(rhs)
    let rhs_ty = self.expr_type(rhs)
    let rhs_place = self.materialize_operand(rhs_op, rhs_ty, self.ast.get_start(rhs))

    let success_bb = self.new_block()
    let fail_bb = self.new_block()
    let cont_bb = self.new_block()

    self.lower_pattern_match(rhs_place, pat, success_bb, fail_bb)

    self.switch_to(success_bb)
    let _ = self.lower_pattern(pat, rhs_place)
    self.terminate(TermKind.TK_GOTO, cont_bb, 0, 0, 0)

    self.switch_to(fail_bb)
    let _ = self.lower_expr(else_body)
    if self.body.term_kind(self.cur_bb) == TermKind.TK_UNREACHABLE:
        self.terminate(TermKind.TK_UNREACHABLE, 0, 0, 0, 0)

    self.switch_to(cont_bb)

fn MirBuilder.lower_block(self: MirBuilder, node: i32) -> i32:
    let stmt_start = self.ast.get_data0(node)
    let stmt_count = self.ast.get_data1(node)
    let tail_expr = self.ast.get_data2(node)

    self.push_scope()
    let defer_start = self.defer_nodes.len() as i32

    for i in 0..stmt_count:
        let stmt = self.ast.get_extra(stmt_start + i)
        let sk = self.ast.kind(stmt)
        if sk == NodeKind.NK_LET_BINDING:
            self.lower_let_binding(stmt)
            continue
        if sk == NodeKind.NK_LET_ELSE:
            self.lower_let_else(stmt)
            continue
        if sk == NodeKind.NK_ASSIGN:
            self.lower_assign(self.ast.get_data0(stmt), self.ast.get_data1(stmt))
            continue
        if sk == NodeKind.NK_RETURN:
            let _ = self.lower_return(stmt)
            continue
        if sk == NodeKind.NK_BREAK:
            let _ = self.lower_break(stmt)
            continue
        if sk == NodeKind.NK_CONTINUE:
            let _ = self.lower_continue(stmt)
            continue
        if sk == NodeKind.NK_DEFER:
            let defer_body = self.ast.get_data0(stmt)
            if defer_body != 0:
                self.defer_nodes.push(defer_body)
            continue
        if sk == NodeKind.NK_ERRDEFER:
            let errdefer_body = self.ast.get_data0(stmt)
            if errdefer_body != 0:
                self.errdefer_nodes.push(errdefer_body)
            continue
        if sk == NodeKind.NK_TUPLE_DESTRUCTURE:
            self.lower_tuple_destructure(stmt)
            continue
        let _ = self.lower_expr(stmt)

    let result = if tail_expr != 0: self.lower_expr(tail_expr) else: self.unit_operand()

    // Emit defers added in this block scope (LIFO order), before popping scope
    let defer_end = self.defer_nodes.len() as i32
    if defer_end > defer_start:
        var di = defer_end - 1
        while di >= defer_start:
            let defer_body = self.defer_nodes.get(di as i64)
            let _ = self.lower_expr(defer_body)
            di = di - 1
        // Remove the block's defers from the stack
        while self.defer_nodes.len() as i32 > defer_start:
            self.defer_nodes.pop()

    // Auto-defer: emit destructor calls for c_import bindings that are still
    // live (not moved) and have registered destructors. Runs after user defers.
    self.emit_auto_defers()

    self.pop_scope_inline()
    result

fn MirBuilder.lower_if(self: MirBuilder, cond_expr: i32, then_expr: i32, else_expr_opt: i32, node: i32) -> i32:
    let cond_op = self.lower_expr(cond_expr)

    let then_bb = self.new_block()
    let else_bb = self.new_block()
    let join_bb = self.new_block()

    let vals: Vec[i32] = Vec.new()
    vals.push(1)
    let targets: Vec[i32] = Vec.new()
    targets.push(then_bb as i32)
    let table = self.body.new_switch_table(vals, targets)
    self.terminate(TermKind.TK_SWITCH_INT, cond_op, table, else_bb, 0)

    let result_ty = self.expr_type(node)
    let result_local = self.new_temp(result_ty)
    let result_place = self.place_for_local(result_local)

    let saved_expected = self.expected_type
    if result_ty != 0:
        self.expected_type = result_ty

    self.switch_to(then_bb)
    let then_op = self.lower_expr(then_expr)
    self.assign_operand_to_place(result_place, then_op, self.ast.get_start(then_expr))
    self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

    self.switch_to(else_bb)
    let else_op = if else_expr_opt != 0: self.lower_expr(else_expr_opt) else: self.unit_operand()
    self.assign_operand_to_place(result_place, else_op, self.ast.get_start(node))
    self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

    self.expected_type = saved_expected

    self.switch_to(join_bb)
    if self.sema.is_copy(result_ty) != 0:
        return self.body.new_operand(OperandKind.OK_COPY, result_place)
    self.body.new_operand(OperandKind.OK_MOVE, result_place)

fn MirBuilder.lower_if_let(self: MirBuilder, pat: i32, scrutinee_expr: i32, then_expr: i32, else_expr_opt: i32, node: i32) -> i32:
    let scrutinee_op = self.lower_expr(scrutinee_expr)
    let scrutinee_ty = self.expr_type(scrutinee_expr)
    let scrutinee_place = self.materialize_operand(scrutinee_op, scrutinee_ty, self.ast.get_start(scrutinee_expr))

    let then_bb = self.new_block()
    let else_bb = self.new_block()
    let join_bb = self.new_block()

    self.lower_pattern_match(scrutinee_place, pat, then_bb, else_bb)

    let result_ty = self.expr_type(node)
    let result_local = self.new_temp(result_ty)
    let result_place = self.place_for_local(result_local)

    self.switch_to(then_bb)
    let _ = self.lower_pattern(pat, scrutinee_place)
    let then_op = self.lower_expr(then_expr)
    self.assign_operand_to_place(result_place, then_op, self.ast.get_start(then_expr))
    self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

    self.switch_to(else_bb)
    let else_op = if else_expr_opt != 0: self.lower_expr(else_expr_opt) else: self.unit_operand()
    self.assign_operand_to_place(result_place, else_op, self.ast.get_start(node))
    self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

    self.switch_to(join_bb)
    if self.sema.is_copy(result_ty) != 0:
        return self.body.new_operand(OperandKind.OK_COPY, result_place)
    self.body.new_operand(OperandKind.OK_MOVE, result_place)

fn MirBuilder.lower_loop(self: MirBuilder, body_expr: i32, node: i32) -> i32:
    let header_bb = self.new_block()
    let body_bb = self.new_block()
    let break_bb = self.new_block()

    self.terminate(TermKind.TK_GOTO, header_bb, 0, 0, 0)

    self.switch_to(header_bb)
    self.terminate(TermKind.TK_GOTO, body_bb, 0, 0, 0)

    self.push_loop(header_bb, break_bb)

    self.switch_to(body_bb)
    let _ = self.lower_expr(body_expr)
    // Back-edge when body does not diverge.
    self.terminate(TermKind.TK_GOTO, header_bb, 0, 0, 0)

    self.pop_loop()
    self.switch_to(break_bb)
    self.unit_operand()

fn MirBuilder.lower_while(self: MirBuilder, cond_expr: i32, body_expr: i32) -> i32:
    let cond_bb = self.new_block()
    let body_bb = self.new_block()
    let exit_bb = self.new_block()

    self.terminate(TermKind.TK_GOTO, cond_bb, 0, 0, 0)

    self.push_loop(cond_bb, exit_bb)

    self.switch_to(cond_bb)
    let cond_op = self.lower_expr(cond_expr)
    let vals: Vec[i32] = Vec.new()
    vals.push(1)
    let targets: Vec[i32] = Vec.new()
    targets.push(body_bb as i32)
    let table = self.body.new_switch_table(vals, targets)
    self.terminate(TermKind.TK_SWITCH_INT, cond_op, table, exit_bb, 0)

    self.switch_to(body_bb)
    let _ = self.lower_expr(body_expr)
    self.terminate(TermKind.TK_GOTO, cond_bb, 0, 0, 0)

    self.pop_loop()
    self.switch_to(exit_bb)
    self.unit_operand()

fn MirBuilder.lower_for(self: MirBuilder, for_node: i32) -> i32:
    let pat_or_sym = self.ast.get_data0(for_node)
    let iter_expr = self.ast.get_data1(for_node)
    let body_expr = self.ast.get_data2(for_node)
    // Check for range-based for: for i in start..end
    if self.ast.kind(iter_expr) == NodeKind.NK_RANGE:
        return self.lower_for_range(for_node, pat_or_sym, iter_expr, body_expr)

    // Range variable: iter_expr is an ident/expr whose type is TY_RANGE
    let iter_ty = self.expr_type(iter_expr)
    if iter_ty != 0:
        let range_resolved = self.sema.resolve_alias(iter_ty)
        if self.sema.get_type_kind(range_resolved) == TypeKind.TY_RANGE:
            return self.lower_for_range_var(for_node, pat_or_sym, iter_expr, body_expr, range_resolved)

    // Check for slice/vec-based for
    if iter_ty != 0:
        let resolved = self.sema.resolve_alias(iter_ty)
        let tk = self.sema.get_type_kind(resolved)
        if tk == TypeKind.TY_SLICE or tk == TypeKind.TY_ARRAY:
            return self.lower_for_slice(for_node, pat_or_sym, iter_expr, body_expr)
        // Vec[T] — use counter-based loop with VEC_LEN / VEC_GET intrinsics
        if tk == TypeKind.TY_GENERIC_INST:
            let type_name_sym = self.sema.get_type_name(resolved)
            if type_name_sym != 0:
                let type_name = self.pool.resolve(type_name_sym)
                if type_name == "Vec":
                    return self.lower_for_vec(for_node, pat_or_sym, iter_expr, body_expr)

    // Handle for x in vec.iter() — redirect to lower_for_vec with the Vec receiver.
    if self.ast.kind(iter_expr) == NodeKind.NK_CALL:
        let call_callee = self.ast.get_data0(iter_expr)
        if self.ast.kind(call_callee) == NodeKind.NK_FIELD_ACCESS:
            let recv = self.ast.get_data0(call_callee)
            let msym = self.ast.get_data1(call_callee)
            let mname = self.pool.resolve(msym)
            if mname == "iter":
                let recv_ty = self.expr_type(recv)
                if recv_ty != 0:
                    let recv_resolved = self.sema.resolve_alias(recv_ty)
                    let recv_tk = self.sema.get_type_kind(recv_resolved)
                    if recv_tk == TypeKind.TY_GENERIC_INST:
                        let recv_name_sym = self.sema.get_type_name(recv_resolved)
                        if recv_name_sym != 0:
                            let recv_name = self.pool.resolve(recv_name_sym)
                            if recv_name == "Vec":
                                return self.lower_for_vec(for_node, pat_or_sym, recv, body_expr)

    // Iterator protocol: not yet fully implemented in MIR.
    // Fall back to AST codegen for functions using iterator-based for loops.
    self.mark_unsupported()
    let iter_op = self.lower_expr(iter_expr)
    let iter_place = self.materialize_operand(iter_op, iter_ty, self.ast.get_start(iter_expr))
    let elem_ty = self.sema.infer_for_element_type(iter_ty)

    let header_bb = self.new_block()
    let body_bb = self.new_block()
    let exit_bb = self.new_block()

    self.terminate(TermKind.TK_GOTO, header_bb, 0, 0, 0)
    self.push_loop(header_bb, exit_bb)

    self.switch_to(header_bb)
    let next_args: Vec[i32] = Vec.new()
    next_args.push(self.body.new_operand(OperandKind.OK_COPY, iter_place))
    let args_id = self.body.new_call_args(next_args)
    let next_local = self.new_temp(iter_ty)
    let next_place = self.place_for_local(next_local)
    let after_next_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, self.unit_operand(), args_id, next_place, after_next_bb)

    self.switch_to(after_next_bb)
    let disc = self.lower_enum_discriminant(next_place)
    let vals: Vec[i32] = Vec.new()
    vals.push(1)
    let targets: Vec[i32] = Vec.new()
    targets.push(body_bb as i32)
    let table = self.body.new_switch_table(vals, targets)
    self.terminate(TermKind.TK_SWITCH_INT, disc, table, exit_bb, 0)

    self.switch_to(body_bb)
    let item_local = self.new_temp(elem_ty)
    let item_place = self.place_for_local(item_local)
    let next_payload = self.body.new_operand(OperandKind.OK_COPY, next_place)
    self.assign_operand_to_place(item_place, next_payload, self.ast.get_start(iter_expr))

    self.bind_for_element(for_node, pat_or_sym, item_place, elem_ty, body_expr)

    let _ = self.lower_expr(body_expr)
    self.terminate(TermKind.TK_GOTO, header_bb, 0, 0, 0)

    self.pop_loop()
    self.switch_to(exit_bb)
    self.unit_operand()

fn MirBuilder.bind_for_element(self: MirBuilder, for_node: i32, pat_or_sym: i32, item_place: i32, elem_ty: i32, body_expr: i32):
    // Bind loop variable: supports both simple identifiers and pattern destructuring
    if self.ast.for_binding_is_pattern(for_node):
        let _ = self.lower_pattern(pat_or_sym, item_place)
        return
    if pat_or_sym != 0:
        let bind_local = self.body.new_local(elem_ty, 0, pat_or_sym, 1)
        self.bind_local(pat_or_sym, bind_local)
        self.body.push_stmt(self.cur_bb, StmtKind.StorageLive, bind_local, 0, self.ast.get_start(body_expr))
        if self.sema.is_copy(elem_ty) == 0:
            self.schedule_drop(bind_local, DropKind.DK_VALUE)
        let bind_place = self.place_for_local(bind_local)
        let item_op = self.body.new_operand(OperandKind.OK_COPY, item_place)
        self.assign_operand_to_place(bind_place, item_op, self.ast.get_start(body_expr))

fn MirBuilder.lower_for_range_var(self: MirBuilder, for_node: i32, pat_or_sym: i32, iter_expr: i32, body_expr: i32, range_ty: i32) -> i32:
    // for i in range_var → extract start/end/inclusive from the range struct,
    // then generate the same counter-based loop as lower_for_range.
    // Range layout: {start: Elem, end: Elem, inclusive: i8}
    let elem_ty = self.sema.get_type_d0(range_ty)
    let range_op = self.lower_expr(iter_expr)
    let range_place = self.materialize_operand(range_op, range_ty, self.ast.get_start(iter_expr))

    // Extract fields via projection
    let start_place = self.body.new_field_place(range_place, 0, elem_ty)
    let end_place_field = self.body.new_field_place(range_place, 1, elem_ty)
    let incl_place = self.body.new_field_place(range_place, 2, self.sema.ty_bool)

    // Read start, end, inclusive into locals
    let start_op = self.body.new_operand(OperandKind.OK_COPY, start_place)
    let end_op = self.body.new_operand(OperandKind.OK_COPY, end_place_field)
    let incl_op = self.body.new_operand(OperandKind.OK_COPY, incl_place)

    // Counter = start
    let counter_local = self.new_temp(elem_ty)
    let counter_place = self.place_for_local(counter_local)
    self.assign_operand_to_place(counter_place, start_op, self.ast.get_start(iter_expr))

    // End value
    let end_local = self.new_temp(elem_ty)
    let end_place = self.place_for_local(end_local)
    self.assign_operand_to_place(end_place, end_op, self.ast.get_start(iter_expr))

    // Inclusive flag
    let incl_local = self.new_temp(self.sema.ty_bool)
    let incl_local_place = self.place_for_local(incl_local)
    self.assign_operand_to_place(incl_local_place, incl_op, self.ast.get_start(iter_expr))

    let header_bb = self.new_block()
    let body_bb = self.new_block()
    let inc_bb = self.new_block()
    let exit_bb = self.new_block()

    self.terminate(TermKind.TK_GOTO, header_bb, 0, 0, 0)
    self.push_loop(inc_bb, exit_bb)

    // Header: compare counter < end (use LTE since we can't branch on inclusive at MIR level;
    // for simplicity, use LTE and rely on the sema-level inclusive flag from the range type)
    self.switch_to(header_bb)
    let counter_read = self.body.new_operand(OperandKind.OK_COPY, counter_place)
    let end_read = self.body.new_operand(OperandKind.OK_COPY, end_place)
    // Use the static inclusive flag from the range type
    let inclusive = self.sema.get_type_d1(range_ty)
    let cmp_op = if inclusive != 0: BinaryOp.OP_LTE else: BinaryOp.OP_LT
    let cmp_rv = self.body.new_rvalue(RvalueKind.RK_BIN_OP, cmp_op, counter_read, end_read)
    let cmp_local = self.new_temp(self.sema.ty_bool)
    let cmp_place = self.place_for_local(cmp_local)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, cmp_place, cmp_rv, self.ast.get_start(iter_expr))
    let cmp_result = self.body.new_operand(OperandKind.OK_COPY, cmp_place)
    let vals: Vec[i32] = Vec.new()
    vals.push(1)
    let targets: Vec[i32] = Vec.new()
    targets.push(body_bb as i32)
    let table = self.body.new_switch_table(vals, targets)
    self.terminate(TermKind.TK_SWITCH_INT, cmp_result, table, exit_bb, 0)

    // Body
    self.switch_to(body_bb)
    self.bind_for_element(for_node, pat_or_sym, counter_place, elem_ty, body_expr)
    let _ = self.lower_expr(body_expr)
    self.terminate(TermKind.TK_GOTO, inc_bb, 0, 0, 0)

    // Increment
    self.switch_to(inc_bb)
    let cur_op = self.body.new_operand(OperandKind.OK_COPY, counter_place)
    let one_op = self.int_const_operand(1, elem_ty)
    let add_rv = self.body.new_rvalue(RvalueKind.RK_BIN_OP, BinaryOp.OP_ADD, cur_op, one_op)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, counter_place, add_rv, self.ast.get_start(iter_expr))
    self.terminate(TermKind.TK_GOTO, header_bb, 0, 0, 0)

    self.pop_loop()
    self.switch_to(exit_bb)
    self.unit_operand()

fn MirBuilder.lower_for_range(self: MirBuilder, for_node: i32, pat_or_sym: i32, range_node: i32, body_expr: i32) -> i32:
    // for i in start..end  →  counter = start; while counter < end: body; counter += 1
    let start_node = self.ast.get_data0(range_node)
    let end_node = self.ast.get_data1(range_node)
    let inclusive = self.ast.get_data2(range_node)
    let elem_ty = self.sema.infer_for_element_type(self.expr_type(range_node))

    // Evaluate start and end
    let start_op = if start_node != 0: self.lower_expr(start_node) else: self.int_const_operand(0, elem_ty)
    let end_op = self.lower_expr(end_node)

    // Create counter local
    let counter_local = self.new_temp(elem_ty)
    let counter_place = self.place_for_local(counter_local)
    let start_rv = self.body.new_rvalue(RvalueKind.RK_USE, start_op, 0, 0)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, counter_place, start_rv, self.ast.get_start(range_node))

    // Store end value in a temp
    let end_local = self.new_temp(elem_ty)
    let end_place = self.place_for_local(end_local)
    let end_rv = self.body.new_rvalue(RvalueKind.RK_USE, end_op, 0, 0)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, end_place, end_rv, self.ast.get_start(range_node))

    let header_bb = self.new_block()
    let body_bb = self.new_block()
    let inc_bb = self.new_block()
    let exit_bb = self.new_block()

    self.terminate(TermKind.TK_GOTO, header_bb, 0, 0, 0)
    self.push_loop(inc_bb, exit_bb)

    // Header: compare counter < end (or <=)
    self.switch_to(header_bb)
    let counter_op = self.body.new_operand(OperandKind.OK_COPY, counter_place)
    let end_read_op = self.body.new_operand(OperandKind.OK_COPY, end_place)
    let cmp_op = if inclusive != 0: BinaryOp.OP_LTE else: BinaryOp.OP_LT
    let cmp_rv = self.body.new_rvalue(RvalueKind.RK_BIN_OP, cmp_op, counter_op, end_read_op)
    let cmp_local = self.new_temp(self.sema.ty_bool)
    let cmp_place = self.place_for_local(cmp_local)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, cmp_place, cmp_rv, self.ast.get_start(range_node))
    let cmp_result = self.body.new_operand(OperandKind.OK_COPY, cmp_place)
    let vals: Vec[i32] = Vec.new()
    vals.push(1)
    let targets: Vec[i32] = Vec.new()
    targets.push(body_bb as i32)
    let table = self.body.new_switch_table(vals, targets)
    self.terminate(TermKind.TK_SWITCH_INT, cmp_result, table, exit_bb, 0)

    // Body: bind loop variable = counter, execute body
    self.switch_to(body_bb)
    self.bind_for_element(for_node, pat_or_sym, counter_place, elem_ty, body_expr)

    let _ = self.lower_expr(body_expr)
    self.terminate(TermKind.TK_GOTO, inc_bb, 0, 0, 0)

    // Increment: counter = counter + 1, goto header
    self.switch_to(inc_bb)
    let cur_op2 = self.body.new_operand(OperandKind.OK_COPY, counter_place)
    let one_op = self.int_const_operand(1, elem_ty)
    let add_rv = self.body.new_rvalue(RvalueKind.RK_BIN_OP, BinaryOp.OP_ADD, cur_op2, one_op)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, counter_place, add_rv, self.ast.get_start(range_node))
    self.terminate(TermKind.TK_GOTO, header_bb, 0, 0, 0)

    self.pop_loop()
    self.switch_to(exit_bb)
    self.unit_operand()

fn MirBuilder.lower_for_slice(self: MirBuilder, for_node: i32, pat_or_sym: i32, iter_expr: i32, body_expr: i32) -> i32:
    // for x in slice → index from 0 to len
    let iter_op = self.lower_expr(iter_expr)
    let iter_ty = self.expr_type(iter_expr)
    let elem_ty = self.sema.infer_for_element_type(iter_ty)

    // Materialize slice into a local
    let slice_place = self.materialize_operand(iter_op, iter_ty, self.ast.get_start(iter_expr))

    // Get length: len_local = RvalueKind.RK_LEN(slice_place)
    let len_local = self.new_temp(self.sema.ty_i64)
    let len_place = self.place_for_local(len_local)
    let len_rv = self.body.new_rvalue(RvalueKind.RK_LEN, slice_place, 0, 0)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, len_place, len_rv, self.ast.get_start(iter_expr))

    // Counter: i64 starting at 0
    let counter_local = self.new_temp(self.sema.ty_i64)
    let counter_place = self.place_for_local(counter_local)
    let zero_op = self.int_const_operand(0, self.sema.ty_i64)
    let zero_rv = self.body.new_rvalue(RvalueKind.RK_USE, zero_op, 0, 0)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, counter_place, zero_rv, self.ast.get_start(iter_expr))

    let header_bb = self.new_block()
    let body_bb = self.new_block()
    let inc_bb = self.new_block()
    let exit_bb = self.new_block()

    self.terminate(TermKind.TK_GOTO, header_bb, 0, 0, 0)
    self.push_loop(inc_bb, exit_bb)

    // Header: counter < len
    self.switch_to(header_bb)
    let counter_op = self.body.new_operand(OperandKind.OK_COPY, counter_place)
    let len_op = self.body.new_operand(OperandKind.OK_COPY, len_place)
    let cmp_rv = self.body.new_rvalue(RvalueKind.RK_BIN_OP, BinaryOp.OP_LT, counter_op, len_op)
    let cmp_local = self.new_temp(self.sema.ty_bool)
    let cmp_place = self.place_for_local(cmp_local)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, cmp_place, cmp_rv, self.ast.get_start(iter_expr))
    let cmp_read = self.body.new_operand(OperandKind.OK_COPY, cmp_place)
    let vals: Vec[i32] = Vec.new()
    vals.push(1)
    let targets: Vec[i32] = Vec.new()
    targets.push(body_bb as i32)
    let table = self.body.new_switch_table(vals, targets)
    self.terminate(TermKind.TK_SWITCH_INT, cmp_read, table, exit_bb, 0)

    // Body: bind element = slice[counter]
    self.switch_to(body_bb)
    let idx_place = self.body.new_index_place(slice_place, counter_local, 0)
    let elem_op = self.body.new_operand(OperandKind.OK_COPY, idx_place)

    // Materialize element into a temp so pattern destructuring has a place to read from
    let elem_local = self.new_temp(elem_ty)
    let elem_place = self.place_for_local(elem_local)
    self.assign_operand_to_place(elem_place, elem_op, self.ast.get_start(body_expr))
    self.bind_for_element(for_node, pat_or_sym, elem_place, elem_ty, body_expr)

    let _ = self.lower_expr(body_expr)
    self.terminate(TermKind.TK_GOTO, inc_bb, 0, 0, 0)

    // Increment: counter += 1
    self.switch_to(inc_bb)
    let cur_op2 = self.body.new_operand(OperandKind.OK_COPY, counter_place)
    let one_op = self.int_const_operand(1, self.sema.ty_i64)
    let add_rv = self.body.new_rvalue(RvalueKind.RK_BIN_OP, BinaryOp.OP_ADD, cur_op2, one_op)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, counter_place, add_rv, self.ast.get_start(iter_expr))
    self.terminate(TermKind.TK_GOTO, header_bb, 0, 0, 0)

    self.pop_loop()
    self.switch_to(exit_bb)
    self.unit_operand()

fn MirBuilder.lower_for_vec(self: MirBuilder, for_node: i32, pat_or_sym: i32, iter_expr: i32, body_expr: i32) -> i32:
    // for x in vec → counter loop using VEC_LEN / VEC_GET intrinsics
    let iter_op = self.lower_expr(iter_expr)
    let iter_ty = self.expr_type(iter_expr)
    let elem_ty = self.sema.infer_for_element_type(iter_ty)

    // Materialize vec into a local
    let vec_place = self.materialize_operand(iter_op, iter_ty, self.ast.get_start(iter_expr))

    // Get length via VEC_LEN intrinsic (returns i64)
    let len_local = self.new_temp(self.sema.ty_i64)
    let len_place = self.place_for_local(len_local)
    let len_args: Vec[i32] = Vec.new()
    len_args.push(self.body.new_operand(OperandKind.OK_COPY, vec_place))
    let len_args_id = self.body.new_call_args(len_args)
    self.body.set_call_intrinsic(len_args_id, MirIntrinsic.MIR_INTRINSIC_VEC_LEN)
    let len_after_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, self.unit_operand(), len_args_id, len_place, len_after_bb)
    self.switch_to(len_after_bb)

    // Counter: i64 starting at 0
    let counter_local = self.new_temp(self.sema.ty_i64)
    let counter_place = self.place_for_local(counter_local)
    let zero_op = self.int_const_operand(0, self.sema.ty_i64)
    let zero_rv = self.body.new_rvalue(RvalueKind.RK_USE, zero_op, 0, 0)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, counter_place, zero_rv, self.ast.get_start(iter_expr))

    let header_bb = self.new_block()
    let body_bb = self.new_block()
    let inc_bb = self.new_block()
    let exit_bb = self.new_block()

    self.terminate(TermKind.TK_GOTO, header_bb, 0, 0, 0)
    self.push_loop(inc_bb, exit_bb)

    // Header: counter < len
    self.switch_to(header_bb)
    let counter_op = self.body.new_operand(OperandKind.OK_COPY, counter_place)
    let len_op = self.body.new_operand(OperandKind.OK_COPY, len_place)
    let cmp_rv = self.body.new_rvalue(RvalueKind.RK_BIN_OP, BinaryOp.OP_LT, counter_op, len_op)
    let cmp_local = self.new_temp(self.sema.ty_bool)
    let cmp_place = self.place_for_local(cmp_local)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, cmp_place, cmp_rv, self.ast.get_start(iter_expr))
    let cmp_read = self.body.new_operand(OperandKind.OK_COPY, cmp_place)
    let vals: Vec[i32] = Vec.new()
    vals.push(1)
    let targets: Vec[i32] = Vec.new()
    targets.push(body_bb as i32)
    let table = self.body.new_switch_table(vals, targets)
    self.terminate(TermKind.TK_SWITCH_INT, cmp_read, table, exit_bb, 0)

    // Body: elem = vec.get(counter) via VEC_GET intrinsic
    self.switch_to(body_bb)
    let elem_local = self.new_temp(elem_ty)
    let elem_place = self.place_for_local(elem_local)
    let get_args: Vec[i32] = Vec.new()
    get_args.push(self.body.new_operand(OperandKind.OK_COPY, vec_place))
    get_args.push(self.body.new_operand(OperandKind.OK_COPY, counter_place))
    let get_args_id = self.body.new_call_args(get_args)
    self.body.set_call_intrinsic(get_args_id, MirIntrinsic.MIR_INTRINSIC_VEC_GET)
    let get_after_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, self.unit_operand(), get_args_id, elem_place, get_after_bb)
    self.switch_to(get_after_bb)

    // Bind loop variable
    self.bind_for_element(for_node, pat_or_sym, elem_place, elem_ty, body_expr)

    let _ = self.lower_expr(body_expr)
    self.terminate(TermKind.TK_GOTO, inc_bb, 0, 0, 0)

    // Increment: counter += 1
    self.switch_to(inc_bb)
    let cur_op2 = self.body.new_operand(OperandKind.OK_COPY, counter_place)
    let one_op = self.int_const_operand(1, self.sema.ty_i64)
    let add_rv = self.body.new_rvalue(RvalueKind.RK_BIN_OP, BinaryOp.OP_ADD, cur_op2, one_op)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, counter_place, add_rv, self.ast.get_start(iter_expr))
    self.terminate(TermKind.TK_GOTO, header_bb, 0, 0, 0)

    self.pop_loop()
    self.switch_to(exit_bb)
    self.unit_operand()

fn MirBuilder.lower_break(self: MirBuilder, node: i32) -> i32:
    let loop_info = self.current_loop()
    if loop_info.break_bb < 0:
        return self.unit_operand()

    let value_expr = self.ast.get_data0(node)
    if value_expr != 0:
        let _ = self.lower_expr(value_expr)

    self.emit_drops_for_break(loop_info)
    self.terminate(TermKind.TK_GOTO, loop_info.break_bb, 0, 0, 0)

    // Continue lowering in a fresh detached block to keep pass total.
    self.switch_to(self.new_block())
    self.unit_operand()

fn MirBuilder.lower_continue(self: MirBuilder, _node: i32) -> i32:
    let loop_info = self.current_loop()
    if loop_info.continue_bb < 0:
        return self.unit_operand()

    self.emit_drops_for_break(loop_info)
    self.terminate(TermKind.TK_GOTO, loop_info.continue_bb, 0, 0, 0)
    self.switch_to(self.new_block())
    self.unit_operand()

fn MirBuilder.lower_return(self: MirBuilder, node: i32) -> i32:
    let value_expr = self.ast.get_data0(node)
    let saved_expected = self.expected_type
    let ret_ty = self.body.local_type_ids.get(0)
    if ret_ty > 0:
        self.expected_type = ret_ty
    let ret_op = if value_expr != 0: self.lower_expr(value_expr) else: self.unit_operand()
    self.expected_type = saved_expected
    let ret_place = self.place_for_local(0)
    self.assign_operand_to_place(ret_place, ret_op, self.ast.get_start(node))

    self.emit_defers_for_return()
    self.emit_drops_for_return()
    self.terminate(TermKind.TK_RETURN, 0, 0, 0, 0)

    // Keep lowering total by switching to an unreachable continuation block.
    self.switch_to(self.new_block())
    self.unit_operand()

// Await a single Task with cancellation checks and unwind-with-defers.
// Returns the operand for the unwrapped result value.
// task_op: MIR operand for the Task value
// result_ty: sema type of the unwrapped result (T from Task[T])
// task_ty: sema type of the Task value (Task[T])
// node: AST node for the await expression (for span/ast_node)
fn MirBuilder.lower_single_await(self: MirBuilder, task_op: i32, result_ty: i32, task_ty: i32, node: i32) -> i32:
    let span = self.ast.get_start(node)

    // 1. Emit FIBER_AWAIT intrinsic call
    let await_args: Vec[i32] = Vec.new()
    await_args.push(task_op)
    let await_args_id = self.body.new_call_args(await_args)
    self.body.set_call_intrinsic(await_args_id, MirIntrinsic.MIR_INTRINSIC_FIBER_AWAIT)
    self.body.set_call_ast_node(await_args_id, node)
    let result_local = self.new_temp(result_ty)
    let result_place = self.place_for_local(result_local)
    let after_await = self.new_block()
    self.terminate(TermKind.TK_CALL, self.unit_operand(), await_args_id, result_place, after_await)
    self.switch_to(after_await)

    // 2. Check self-cancellation: IS_CANCELLED() → i32
    let ic_args: Vec[i32] = Vec.new()
    let ic_args_id = self.body.new_call_args(ic_args)
    self.body.set_call_intrinsic(ic_args_id, MirIntrinsic.MIR_INTRINSIC_FIBER_IS_CANCELLED)
    let ic_result = self.new_temp(self.sema.ty_i32 as i32)
    let ic_place = self.place_for_local(ic_result)
    let check_self_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, self.unit_operand(), ic_args_id, ic_place, check_self_bb)
    self.switch_to(check_self_bb)

    // Branch: 0 → check child, else → self-cancel cleanup
    let check_child_bb = self.new_block()
    let self_cancel_bb = self.new_block()
    let unwind_bb = self.new_block()
    let normal_bb = self.new_block()
    let sw_vals1: Vec[i32] = Vec.new()
    sw_vals1.push(0)
    let sw_tgts1: Vec[i32] = Vec.new()
    sw_tgts1.push(check_child_bb)
    let sw1 = self.body.new_switch_table(sw_vals1, sw_tgts1)
    let ic_op = self.body.new_operand(OperandKind.OK_COPY, ic_place)
    self.terminate(TermKind.TK_SWITCH_INT, ic_op, sw1, self_cancel_bb, 0)

    // 3. Self-cancel BB: cancel child, join it for cleanup, then unwind.
    self.switch_to(self_cancel_bb)
    let cancel_args: Vec[i32] = Vec.new()
    cancel_args.push(task_op)
    let cancel_call_id = self.body.new_call_args(cancel_args)
    self.body.set_call_intrinsic(cancel_call_id, MirIntrinsic.MIR_INTRINSIC_FIBER_CANCEL)
    self.body.set_call_ast_node(cancel_call_id, node)
    let cancel_result_local = self.new_temp(self.sema.ty_i32)
    let cancel_result_place = self.place_for_local(cancel_result_local)
    let after_cancel_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, self.unit_operand(), cancel_call_id, cancel_result_place, after_cancel_bb)
    self.switch_to(after_cancel_bb)
    self.lower_cleanup_await(task_op, node)
    self.terminate(TermKind.TK_GOTO, unwind_bb, 0, 0, 0)

    // 4. Check child-cancellation: extract fiber_id from task
    self.switch_to(check_child_bb)
    let task_place = self.materialize_operand(task_op, task_ty, span)
    let fid_place = self.body.new_field_place(task_place, 0, self.sema.ty_i32 as i32)
    let fid_op = self.body.new_operand(OperandKind.OK_COPY, fid_place)
    let wcr_args: Vec[i32] = Vec.new()
    wcr_args.push(fid_op)
    let wcr_args_id = self.body.new_call_args(wcr_args)
    self.body.set_call_intrinsic(wcr_args_id, MirIntrinsic.MIR_INTRINSIC_FIBER_WAS_CANCELLED_RETURN)
    let wcr_result = self.new_temp(self.sema.ty_i32 as i32)
    let wcr_place = self.place_for_local(wcr_result)
    let check_child_cont = self.new_block()
    self.terminate(TermKind.TK_CALL, self.unit_operand(), wcr_args_id, wcr_place, check_child_cont)
    self.switch_to(check_child_cont)

    // Branch: 0 → normal, else → unwind
    let sw_vals2: Vec[i32] = Vec.new()
    sw_vals2.push(0)
    let sw_tgts2: Vec[i32] = Vec.new()
    sw_tgts2.push(normal_bb)
    let sw2 = self.body.new_switch_table(sw_vals2, sw_tgts2)
    let wcr_op = self.body.new_operand(OperandKind.OK_COPY, wcr_place)
    self.terminate(TermKind.TK_SWITCH_INT, wcr_op, sw2, unwind_bb, 0)

    // 5. Unwind BB: set cancelled_return, emit defers+drops, return
    self.switch_to(unwind_bb)
    let scr_args: Vec[i32] = Vec.new()
    let scr_args_id = self.body.new_call_args(scr_args)
    self.body.set_call_intrinsic(scr_args_id, MirIntrinsic.MIR_INTRINSIC_FIBER_SET_CANCELLED_RETURN)
    let scr_result = self.new_temp(self.sema.ty_i32 as i32)
    let scr_place = self.place_for_local(scr_result)
    let after_scr = self.new_block()
    self.terminate(TermKind.TK_CALL, self.unit_operand(), scr_args_id, scr_place, after_scr)
    self.switch_to(after_scr)
    self.emit_defers_for_return()
    self.emit_drops_for_return()
    self.terminate(TermKind.TK_RETURN, 0, 0, 0, 0)

    // 6. Normal BB: continue with result
    self.switch_to(normal_bb)
    self.body.new_operand(OperandKind.OK_COPY, result_place)

// Join a Task purely for cleanup: await completion and free its result buffer,
// but do not propagate child-cancel status into the current fiber.
fn MirBuilder.lower_cleanup_await(self: MirBuilder, task_op: i32, node: i32):
    let await_args: Vec[i32] = Vec.new()
    await_args.push(task_op)
    let await_args_id = self.body.new_call_args(await_args)
    self.body.set_call_intrinsic(await_args_id, MirIntrinsic.MIR_INTRINSIC_FIBER_CLEANUP_AWAIT)
    self.body.set_call_ast_node(await_args_id, node)
    let ignored_local = self.new_temp(self.sema.ty_void as i32)
    let ignored_place = self.place_for_local(ignored_local)
    let after_await_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, self.unit_operand(), await_args_id, ignored_place, after_await_bb)
    self.switch_to(after_await_bb)

fn MirBuilder.lower_unreachable(self: MirBuilder) -> i32:
    self.terminate(TermKind.TK_UNREACHABLE, 0, 0, 0, 0)
    self.switch_to(self.new_block())
    self.unit_operand()

fn MirBuilder.lower_enum_discriminant(self: MirBuilder, place: i32) -> i32:
    let rv = self.body.new_rvalue(RvalueKind.RK_DISCRIMINANT, place, 0, 0)
    let disc_local = self.new_temp(self.sema.ty_i32)
    let disc_place = self.place_for_local(disc_local)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, disc_place, rv, 0)
    self.body.new_operand(OperandKind.OK_COPY, disc_place)

fn MirBuilder.lower_pattern_eq_operand(self: MirBuilder, scrutinee_place: i32, value_op: i32, pat_node: i32, arm_bb: i32, fail_bb: i32):
    let scrutinee_op = self.body.new_operand(OperandKind.OK_COPY, scrutinee_place)
    let cmp_rv = self.body.new_rvalue(RvalueKind.RK_BIN_OP, BinaryOp.OP_EQ, scrutinee_op, value_op)
    let cmp_tmp = self.new_temp(self.sema.ty_bool)
    let cmp_place = self.place_for_local(cmp_tmp)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, cmp_place, cmp_rv, self.ast.get_start(pat_node))
    let cmp_op = self.body.new_operand(OperandKind.OK_COPY, cmp_place)
    let vals: Vec[i32] = Vec.new()
    vals.push(1)
    let targets: Vec[i32] = Vec.new()
    targets.push(arm_bb)
    let table = self.body.new_switch_table(vals, targets)
    self.terminate(TermKind.TK_SWITCH_INT, cmp_op, table, fail_bb, 0)

fn MirBuilder.pattern_payload_node(self: MirBuilder, owner_pat: i32, payload_entry: i32) -> i32:
    if payload_entry <= 0 or payload_entry >= self.ast.node_count():
        return 0
    let pk = self.ast.kind(payload_entry)
    if pk < NodeKind.NK_PAT_WILDCARD or pk > NodeKind.NK_PAT_SLICE:
        return 0
    if payload_entry == owner_pat:
        return 0
    let owner_start = self.ast.get_start(owner_pat)
    let owner_end = self.ast.get_end(owner_pat)
    let payload_start = self.ast.get_start(payload_entry)
    let payload_end = self.ast.get_end(payload_entry)
    if payload_start < owner_start or payload_end > owner_end:
        return 0
    payload_entry

fn MirBuilder.lower_pattern_match(self: MirBuilder, scrutinee_place: i32, pat_node: i32, arm_bb: i32, fail_bb: i32):
    if pat_node == 0:
        self.terminate(TermKind.TK_GOTO, arm_bb, 0, 0, 0)
        return

    let pk = self.ast.kind(pat_node)
    if pk == NodeKind.NK_PAT_WILDCARD or pk == NodeKind.NK_PAT_IDENT:
        self.terminate(TermKind.TK_GOTO, arm_bb, 0, 0, 0)
        return

    if pk == NodeKind.NK_PAT_AT_BINDING:
        let inner_pat = self.ast.get_data1(pat_node)
        if inner_pat != 0:
            self.lower_pattern_match(scrutinee_place, inner_pat, arm_bb, fail_bb)
        else:
            self.terminate(TermKind.TK_GOTO, arm_bb, 0, 0, 0)
        return

    if pk == NodeKind.NK_PAT_OR:
        let p_start = self.ast.get_data0(pat_node)
        let p_count = self.ast.get_data1(pat_node)
        if p_count <= 0:
            self.terminate(TermKind.TK_GOTO, fail_bb, 0, 0, 0)
            return
        var next_test_bb = self.cur_bb
        for pi in 0..p_count:
            let alt_pat = self.ast.get_extra(p_start + pi)
            let alt_fail = if pi + 1 < p_count: self.new_block() else: fail_bb
            self.switch_to(next_test_bb)
            self.lower_pattern_match(scrutinee_place, alt_pat, arm_bb, alt_fail)
            next_test_bb = alt_fail
        return

    if pk == NodeKind.NK_PAT_VARIANT or pk == NodeKind.NK_PAT_ENUM_SHORTHAND:
        if self.sema.pattern_value_syms.contains(pat_node):
            let value_sym = self.sema.pattern_value_syms.get(pat_node).unwrap()
            let scrutinee_ty = self.place_local_type(scrutinee_place)
            let saved_expected = self.expected_type
            self.expected_type = scrutinee_ty
            let value_op = self.lower_var(value_sym, scrutinee_ty)
            self.expected_type = saved_expected
            self.lower_pattern_eq_operand(scrutinee_place, value_op, pat_node, arm_bb, fail_bb)
            return
        let variant_sym = self.resolve_variant_sym(pat_node)
        let payload_start = self.ast.get_data1(pat_node)
        let payload_count = self.ast.get_data2(pat_node)
        let variant_idx = self.variant_index(variant_sym)
        var disc_idx = variant_idx
        // For disc enums, use the actual discriminant value
        if self.sema.variant_lookup.contains(variant_sym):
            if self.sema.disc_values.contains(variant_sym):
                disc_idx = self.sema.disc_values.get(variant_sym).unwrap()
        var success_bb = arm_bb
        var needs_payload_checks = false
        let variant_place = self.body.new_downcast_place(scrutinee_place, variant_idx, 0)
        for bi in 0..payload_count:
            let inner_pat = self.pattern_payload_node(pat_node, self.ast.get_extra(payload_start + bi))
            if inner_pat == 0:
                continue
            let inner_pk = self.ast.kind(inner_pat)
            if inner_pk == NodeKind.NK_PAT_WILDCARD or inner_pk == NodeKind.NK_PAT_IDENT:
                continue
            needs_payload_checks = true
            break
        if needs_payload_checks:
            success_bb = self.new_block() as i32
        let disc = self.lower_enum_discriminant(scrutinee_place)
        let vals: Vec[i32] = Vec.new()
        vals.push(disc_idx)
        let targets: Vec[i32] = Vec.new()
        targets.push(success_bb)
        let table = self.body.new_switch_table(vals, targets)
        self.terminate(TermKind.TK_SWITCH_INT, disc, table, fail_bb, 0)
        if not needs_payload_checks:
            return
        var cur_test_bb = success_bb
        for bi in 0..payload_count:
            let inner_pat = self.pattern_payload_node(pat_node, self.ast.get_extra(payload_start + bi))
            if inner_pat == 0:
                continue
            let inner_pk = self.ast.kind(inner_pat)
            if inner_pk == NodeKind.NK_PAT_WILDCARD or inner_pk == NodeKind.NK_PAT_IDENT:
                continue
            let field_place = self.body.new_field_place(variant_place, bi, 0)
            let next_test_bb = self.new_block()
            self.switch_to(cur_test_bb)
            self.lower_pattern_match(field_place, inner_pat, next_test_bb, fail_bb)
            cur_test_bb = next_test_bb as i32
        self.switch_to(cur_test_bb)
        self.terminate(TermKind.TK_GOTO, arm_bb, 0, 0, 0)
        return

    let scrutinee_op = self.body.new_operand(OperandKind.OK_COPY, scrutinee_place)
    if pk == NodeKind.NK_PAT_INT or pk == NodeKind.NK_PAT_BOOL or pk == NodeKind.NK_PAT_STRING:
        let lit = if pk == NodeKind.NK_PAT_INT:
            self.lower_int_lit(self.ast.int_lit_value(pat_node), self.sema.ty_i32)
        else if pk == NodeKind.NK_PAT_BOOL:
            self.lower_bool_lit(self.ast.get_data0(pat_node))
        else:
            self.lower_str_lit(self.ast.get_data0(pat_node))
        self.lower_pattern_eq_operand(scrutinee_place, lit, pat_node, arm_bb, fail_bb)
        return

    if pk == NodeKind.NK_PAT_RANGE:
        let range_lo = self.ast.get_data0(pat_node)
        let range_hi = self.ast.get_data1(pat_node)
        let inclusive = self.ast.get_data2(pat_node)
        let lo_lit = self.lower_int_lit(range_lo as i64, self.sema.ty_i32)
        let hi_lit = self.lower_int_lit(range_hi as i64, self.sema.ty_i32)
        let ge_rv = self.body.new_rvalue(RvalueKind.RK_BIN_OP, BinaryOp.OP_GTE, scrutinee_op, lo_lit)
        let ge_tmp = self.new_temp(self.sema.ty_bool)
        let ge_place = self.place_for_local(ge_tmp)
        self.body.push_stmt(self.cur_bb, StmtKind.Assign, ge_place, ge_rv, self.ast.get_start(pat_node))
        let ge_op = self.body.new_operand(OperandKind.OK_COPY, ge_place)
        let range_hi_bb = self.new_block()
        let ge_vals: Vec[i32] = Vec.new()
        ge_vals.push(1)
        let ge_targets: Vec[i32] = Vec.new()
        ge_targets.push(range_hi_bb as i32)
        let ge_table = self.body.new_switch_table(ge_vals, ge_targets)
        self.terminate(TermKind.TK_SWITCH_INT, ge_op, ge_table, fail_bb, 0)
        self.switch_to(range_hi_bb)
        let scrutinee_op2 = self.body.new_operand(OperandKind.OK_COPY, scrutinee_place)
        let hi_cmp_op = if inclusive != 0: BinaryOp.OP_LTE else: BinaryOp.OP_LT
        let le_rv = self.body.new_rvalue(RvalueKind.RK_BIN_OP, hi_cmp_op, scrutinee_op2, hi_lit)
        let le_tmp = self.new_temp(self.sema.ty_bool)
        let le_place = self.place_for_local(le_tmp)
        self.body.push_stmt(self.cur_bb, StmtKind.Assign, le_place, le_rv, self.ast.get_start(pat_node))
        let le_op = self.body.new_operand(OperandKind.OK_COPY, le_place)
        let le_vals: Vec[i32] = Vec.new()
        le_vals.push(1)
        let le_targets: Vec[i32] = Vec.new()
        le_targets.push(arm_bb)
        let le_table = self.body.new_switch_table(le_vals, le_targets)
        self.terminate(TermKind.TK_SWITCH_INT, le_op, le_table, fail_bb, 0)
        return

    if pk == NodeKind.NK_PAT_TUPLE:
        let tup_start = self.ast.get_data0(pat_node)
        let tup_count = self.ast.get_data1(pat_node)
        var cur_test_bb = self.cur_bb
        for ti in 0..tup_count:
            let elem_pat = self.ast.get_extra(tup_start + ti)
            let elem_pk = self.ast.kind(elem_pat)
            if elem_pk == NodeKind.NK_PAT_WILDCARD or elem_pk == NodeKind.NK_PAT_IDENT:
                continue
            let elem_place = self.body.new_field_place(scrutinee_place, ti, 0)
            let next_test = self.new_block()
            self.switch_to(cur_test_bb)
            self.lower_pattern_match(elem_place, elem_pat, next_test, fail_bb)
            cur_test_bb = next_test
        // cur_test_bb is the block reached after all concrete checks pass.
        // Emit a goto to the arm block.
        self.switch_to(cur_test_bb)
        self.terminate(TermKind.TK_GOTO, arm_bb, 0, 0, 0)
        return

    // Dyn trait typed-bind pattern: vtable comparison via intrinsic.
    if pk == NodeKind.NK_PAT_TYPED_BIND:
        let tb_type_sym = self.ast.get_data1(pat_node)
        // Get trait_sym from scrutinee's sema type (TypeKind.TY_TRAIT_OBJ.d0)
        let tb_scrutinee_ty = self.place_local_type(scrutinee_place)
        var tb_trait_sym: i32 = 0
        if self.sema.get_type_kind(tb_scrutinee_ty) == TypeKind.TY_TRAIT_OBJ:
            tb_trait_sym = self.sema.get_type_d0(tb_scrutinee_ty)
        // Emit MirIntrinsic.MIR_INTRINSIC_DYN_VTABLE_CMP(scrutinee, type_sym, trait_sym) → bool
        let tb_fn_op = self.const_operand(ConstKind.CK_FN, 0, self.sema.ty_void)
        let tb_scrutinee_op = self.body.new_operand(OperandKind.OK_COPY, scrutinee_place)
        let tb_type_const = self.int_const_operand(tb_type_sym as i64, self.sema.ty_i32)
        let tb_trait_const = self.int_const_operand(tb_trait_sym as i64, self.sema.ty_i32)
        let tb_args: Vec[i32] = Vec.new()
        tb_args.push(tb_scrutinee_op)
        tb_args.push(tb_type_const)
        tb_args.push(tb_trait_const)
        let tb_args_id = self.body.new_call_args(tb_args)
        self.body.set_call_intrinsic(tb_args_id, MirIntrinsic.MIR_INTRINSIC_DYN_VTABLE_CMP)
        let tb_result = self.new_temp(self.sema.ty_bool)
        let tb_result_place = self.place_for_local(tb_result)
        let tb_switch_bb = self.new_block()
        self.terminate(TermKind.TK_CALL, tb_fn_op, tb_args_id, tb_result_place, tb_switch_bb)
        self.switch_to(tb_switch_bb)
        let tb_cmp_op = self.body.new_operand(OperandKind.OK_COPY, tb_result_place)
        let tb_vals: Vec[i32] = Vec.new()
        tb_vals.push(1)
        let tb_targets: Vec[i32] = Vec.new()
        tb_targets.push(arm_bb)
        let tb_table = self.body.new_switch_table(tb_vals, tb_targets)
        self.terminate(TermKind.TK_SWITCH_INT, tb_cmp_op, tb_table, fail_bb, 0)
        return

    // NodeKind.NK_PAT_SLICE: check array length against pattern count
    if pk == NodeKind.NK_PAT_SLICE:
        let sp_head = self.ast.get_data1(pat_node)
        let sp_extra = self.ast.get_data0(pat_node)
        let sp_has_rest = self.ast.get_extra(sp_extra)
        // Get array length from scrutinee sema type
        let sp_arr_ty = self.place_local_type(scrutinee_place)
        let sp_arr_tk = self.sema.get_type_kind(sp_arr_ty)
        if sp_arr_tk == TypeKind.TY_ARRAY:
            let sp_arr_len = self.sema.get_type_d1(sp_arr_ty)
            if sp_has_rest != 0:
                // [a, b, ..rest] matches if arr_len >= head_count
                if sp_arr_len >= sp_head:
                    self.terminate(TermKind.TK_GOTO, arm_bb, 0, 0, 0)
                else:
                    self.terminate(TermKind.TK_GOTO, fail_bb, 0, 0, 0)
            else:
                // [a, b, c] matches only if arr_len == head_count
                if sp_arr_len == sp_head:
                    self.terminate(TermKind.TK_GOTO, arm_bb, 0, 0, 0)
                else:
                    self.terminate(TermKind.TK_GOTO, fail_bb, 0, 0, 0)
            return

    // Other patterns (struct) are conservatively accepted here.
    self.terminate(TermKind.TK_GOTO, arm_bb, 0, 0, 0)

fn MirBuilder.lower_pattern(self: MirBuilder, pat_node: i32, scrutinee_place: i32) -> Vec[i32]:
    let out: Vec[i32] = Vec.new()
    if pat_node == 0:
        return out

    let pk = self.ast.kind(pat_node)
    if pk == NodeKind.NK_PAT_WILDCARD:
        return out

    if pk == NodeKind.NK_PAT_IDENT:
        let sym = self.ast.get_data0(pat_node)
        let bind_ty = self.place_local_type(scrutinee_place)
        let local_id = self.body.new_local(bind_ty, 0, sym, 1)
        self.bind_local(sym, local_id)
        self.body.push_stmt(self.cur_bb, StmtKind.StorageLive, local_id, 0, self.ast.get_start(pat_node))
        if self.sema.is_copy(bind_ty) == 0:
            self.schedule_drop(local_id, DropKind.DK_VALUE)
        let src_op = self.body.new_operand(if self.sema.is_copy(bind_ty) != 0: OperandKind.OK_COPY else: OperandKind.OK_MOVE, scrutinee_place)
        self.assign_operand_to_place(self.place_for_local(local_id), src_op, self.ast.get_start(pat_node))
        out.push(local_id)
        out.push(scrutinee_place)
        return out

    if pk == NodeKind.NK_PAT_AT_BINDING:
        let outer_sym = self.ast.get_data0(pat_node)
        let outer_ty = self.place_local_type(scrutinee_place)
        let outer_local = self.body.new_local(outer_ty, 0, outer_sym, 1)
        self.bind_local(outer_sym, outer_local)
        self.body.push_stmt(self.cur_bb, StmtKind.StorageLive, outer_local, 0, self.ast.get_start(pat_node))
        if self.sema.is_copy(outer_ty) == 0:
            self.schedule_drop(outer_local, DropKind.DK_VALUE)
        let outer_op = self.body.new_operand(if self.sema.is_copy(outer_ty) != 0: OperandKind.OK_COPY else: OperandKind.OK_MOVE, scrutinee_place)
        self.assign_operand_to_place(self.place_for_local(outer_local), outer_op, self.ast.get_start(pat_node))
        out.push(outer_local)
        out.push(scrutinee_place)
        let inner = self.lower_pattern(self.ast.get_data1(pat_node), scrutinee_place)
        for i in 0..inner.len() as i32:
            out.push(inner.get(i as i64))
        return out

    if pk == NodeKind.NK_PAT_VARIANT or pk == NodeKind.NK_PAT_ENUM_SHORTHAND:
        if self.sema.pattern_value_syms.contains(pat_node):
            return out
        let variant_sym = self.ast.get_data0(pat_node)
        let bind_start = self.ast.get_data1(pat_node)
        let bind_count = self.ast.get_data2(pat_node)
        let variant_place = self.body.new_downcast_place(scrutinee_place, self.variant_index(variant_sym), 0)
        for bi in 0..bind_count:
            let raw = self.ast.get_extra(bind_start + bi)
            let field_place = self.body.new_field_place(variant_place, bi, 0)
            let inner_pat = self.pattern_payload_node(pat_node, raw)
            if inner_pat != 0:
                let inner = self.lower_pattern(inner_pat, field_place)
                for i in 0..inner.len() as i32:
                    out.push(inner.get(i as i64))
                continue
            let bind_ty = self.place_local_type(field_place)
            let local_id = self.body.new_local(bind_ty, 0, raw, 1)
            self.bind_local(raw, local_id)
            self.body.push_stmt(self.cur_bb, StmtKind.StorageLive, local_id, 0, self.ast.get_start(pat_node))
            if self.sema.is_copy(bind_ty) == 0:
                self.schedule_drop(local_id, DropKind.DK_VALUE)
            let src_op = self.body.new_operand(if self.sema.is_copy(bind_ty) != 0: OperandKind.OK_COPY else: OperandKind.OK_MOVE, field_place)
            self.assign_operand_to_place(self.place_for_local(local_id), src_op, self.ast.get_start(pat_node))
            out.push(local_id)
            out.push(field_place)
        return out

    if pk == NodeKind.NK_PAT_TUPLE:
        let t_start = self.ast.get_data0(pat_node)
        let t_count = self.ast.get_data1(pat_node)
        for ti in 0..t_count:
            let elem_pat = self.ast.get_extra(t_start + ti)
            let field_place = self.body.new_field_place(scrutinee_place, ti, 0)
            let inner = self.lower_pattern(elem_pat, field_place)
            for i in 0..inner.len() as i32:
                out.push(inner.get(i as i64))
        return out

    if pk == NodeKind.NK_PAT_STRUCT:
        let s_start = self.ast.get_data1(pat_node)
        let s_count = self.ast.get_data2(pat_node)
        for si in 0..s_count:
            let field_name = self.ast.get_extra(s_start + 1 + si * 2)
            let field_pat = self.ast.get_extra(s_start + 1 + si * 2 + 1)
            let field_place = self.body.new_field_place(scrutinee_place, field_name, 0)
            if field_pat != 0:
                let inner = self.lower_pattern(field_pat, field_place)
                for i in 0..inner.len() as i32:
                    out.push(inner.get(i as i64))
            else:
                let bind_ty = self.place_local_type(field_place)
                let local_id = self.body.new_local(bind_ty, 0, field_name, 1)
                self.bind_local(field_name, local_id)
                self.body.push_stmt(self.cur_bb, StmtKind.StorageLive, local_id, 0, self.ast.get_start(pat_node))
                if self.sema.is_copy(bind_ty) == 0:
                    self.schedule_drop(local_id, DropKind.DK_VALUE)
                let src_op = self.body.new_operand(if self.sema.is_copy(bind_ty) != 0: OperandKind.OK_COPY else: OperandKind.OK_MOVE, field_place)
                self.assign_operand_to_place(self.place_for_local(local_id), src_op, self.ast.get_start(pat_node))
                out.push(local_id)
                out.push(field_place)
        return out

    if pk == NodeKind.NK_PAT_OR:
        let p_start = self.ast.get_data0(pat_node)
        if self.ast.get_data1(pat_node) > 0:
            return self.lower_pattern(self.ast.get_extra(p_start), scrutinee_place)
        return out

    if pk == NodeKind.NK_PAT_TYPED_BIND:
        let tb_bind_sym = self.ast.get_data0(pat_node)
        let tb_type_sym = self.ast.get_data1(pat_node)
        // Look up concrete sema type for the type symbol
        let tb_sema_sym = self.sema.pool_lookup_symbol(self.pool.resolve_symbol(tb_type_sym))
        var tb_concrete_ty = self.sema.ty_i32
        if self.sema.named_types.contains(tb_sema_sym):
            tb_concrete_ty = self.sema.named_types.get(tb_sema_sym).unwrap()
        // Emit MirIntrinsic.MIR_INTRINSIC_DYN_DOWNCAST(scrutinee, type_sym) → concrete value
        let dc_fn_op = self.const_operand(ConstKind.CK_FN, 0, self.sema.ty_void)
        let dc_scrutinee_op = self.body.new_operand(OperandKind.OK_COPY, scrutinee_place)
        let dc_type_const = self.int_const_operand(tb_type_sym as i64, self.sema.ty_i32)
        let dc_args: Vec[i32] = Vec.new()
        dc_args.push(dc_scrutinee_op)
        dc_args.push(dc_type_const)
        let dc_args_id = self.body.new_call_args(dc_args)
        self.body.set_call_intrinsic(dc_args_id, MirIntrinsic.MIR_INTRINSIC_DYN_DOWNCAST)
        let local_id = self.body.new_local(tb_concrete_ty, 0, tb_bind_sym, 1)
        self.bind_local(tb_bind_sym, local_id)
        let dc_result_place = self.place_for_local(local_id)
        let dc_next_bb = self.new_block()
        self.terminate(TermKind.TK_CALL, dc_fn_op, dc_args_id, dc_result_place, dc_next_bb)
        self.switch_to(dc_next_bb)
        out.push(local_id)
        out.push(scrutinee_place)
        return out

    if pk == NodeKind.NK_PAT_SLICE:
        let sp_extra = self.ast.get_data0(pat_node)
        let sp_head_count = self.ast.get_data1(pat_node)
        // Get element type from scrutinee's array type
        let sp_arr_ty = self.place_local_type(scrutinee_place)
        var sp_elem_ty = self.sema.ty_i32 as i32
        let sp_arr_tk = self.sema.get_type_kind(sp_arr_ty)
        if sp_arr_tk == TypeKind.TY_ARRAY:
            let ety = self.sema.get_type_d0(sp_arr_ty)
            if ety != 0:
                sp_elem_ty = ety
        // extras: [has_rest, head_sym0, head_sym1, ..., tail_count, tail_sym0, ...]
        let sp_arr_len = if sp_arr_tk == TypeKind.TY_ARRAY: self.sema.get_type_d1(sp_arr_ty) else: 0
        // Bind head variables
        for si in 0..sp_head_count:
            let sym = self.ast.get_extra(sp_extra + 1 + si)
            if sym == 0:
                continue
            let field_place = self.body.new_field_place(scrutinee_place, si, 0)
            let local_id = self.body.new_local(sp_elem_ty, 0, sym, 1)
            self.bind_local(sym, local_id)
            self.body.push_stmt(self.cur_bb, StmtKind.StorageLive, local_id, 0, self.ast.get_start(pat_node))
            let src_op = self.body.new_operand(if self.sema.is_copy(sp_elem_ty) != 0: OperandKind.OK_COPY else: OperandKind.OK_MOVE, field_place)
            self.assign_operand_to_place(self.place_for_local(local_id), src_op, self.ast.get_start(pat_node))
            out.push(local_id)
            out.push(field_place)
        // Bind tail variables (from the end of the array)
        let sp_tail_count = self.ast.get_extra(sp_extra + 1 + sp_head_count)
        for ti in 0..sp_tail_count:
            let sym = self.ast.get_extra(sp_extra + 2 + sp_head_count + ti)
            if sym == 0:
                continue
            let field_idx = sp_arr_len - sp_tail_count + ti
            let field_place = self.body.new_field_place(scrutinee_place, field_idx, 0)
            let local_id = self.body.new_local(sp_elem_ty, 0, sym, 1)
            self.bind_local(sym, local_id)
            self.body.push_stmt(self.cur_bb, StmtKind.StorageLive, local_id, 0, self.ast.get_start(pat_node))
            let src_op = self.body.new_operand(if self.sema.is_copy(sp_elem_ty) != 0: OperandKind.OK_COPY else: OperandKind.OK_MOVE, field_place)
            self.assign_operand_to_place(self.place_for_local(local_id), src_op, self.ast.get_start(pat_node))
            out.push(local_id)
            out.push(field_place)
        return out

    out

fn MirBuilder.lower_match(self: MirBuilder, scrutinee_expr: i32, arms_start: i32, arms_count: i32, node: i32) -> i32:
    if arms_count == 0:
        return self.unit_operand()

    let scrutinee_op = self.lower_expr(scrutinee_expr)
    let scrutinee_ty = self.expr_type(scrutinee_expr)
    let scrutinee_place = self.materialize_operand(scrutinee_op, scrutinee_ty, self.ast.get_start(scrutinee_expr))

    let result_ty = self.expr_type(node)
    let result_local = self.new_temp(result_ty)
    let result_place = self.place_for_local(result_local)
    let join_bb = self.new_block()

    var dispatch_bb = self.cur_bb
    for ai in 0..arms_count:
        let arm_node = self.ast.get_extra(arms_start + ai)
        let pat_node = self.ast.get_data0(arm_node)
        let body_node = self.ast.get_data1(arm_node)
        let guard_node = self.ast.get_data2(arm_node)

        let arm_bb = self.new_block()
        let fail_bb = if ai + 1 < arms_count: self.new_block() else: join_bb

        self.switch_to(dispatch_bb)
        self.lower_pattern_match(scrutinee_place, pat_node, arm_bb, fail_bb)

        self.switch_to(arm_bb)
        let _ = self.lower_pattern(pat_node, scrutinee_place)

        if guard_node != 0:
            let guard_op = self.lower_expr(guard_node)
            let guard_pass_bb = self.new_block()
            let vals: Vec[i32] = Vec.new()
            vals.push(1)
            let targets: Vec[i32] = Vec.new()
            targets.push(guard_pass_bb as i32)
            let table = self.body.new_switch_table(vals, targets)
            self.terminate(TermKind.TK_SWITCH_INT, guard_op, table, fail_bb, 0)
            self.switch_to(guard_pass_bb)

        let arm_value = self.lower_expr(body_node)
        self.assign_operand_to_place(result_place, arm_value, self.ast.get_start(body_node))
        self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

        dispatch_bb = fail_bb

    self.switch_to(join_bb)
    if self.sema.is_copy(result_ty) != 0:
        return self.body.new_operand(OperandKind.OK_COPY, result_place)
    self.body.new_operand(OperandKind.OK_MOVE, result_place)

fn MirBuilder.lower_call(self: MirBuilder, fn_expr: i32, arg_exprs_start: i32, arg_exprs_count: i32, ret_type_id: i32, node: i32) -> i32:
    let fn_op = self.lower_expr(fn_expr)
    let sig_idx = self.call_sig_for_expr(fn_expr)
    let callable_fn_tid = if sig_idx >= 0: 0 else: self.callable_fn_type_for_expr(fn_expr)

    let args: Vec[i32] = Vec.new()
    // Use sema-resolved arg order for named-arg and implicit-arg calls
    if self.sema.has_resolved_call_args(node) != 0:
        let resolved_count = self.sema.get_resolved_call_arg_count(node)
        for i in 0..resolved_count:
            let arg_node = self.sema.get_resolved_call_arg(node, i)
            if arg_node < 0:
                // Negative value = implicit parameter marker: 0 - bind_sym
                let impl_sym = 0 - arg_node
                args.push(self.lower_var(impl_sym, 0))
            else if arg_node != 0:
                args.push(self.lower_call_arg(arg_node, sig_idx, callable_fn_tid, i))
            else:
                args.push(self.unit_operand())
    else:
        for i in 0..arg_exprs_count:
            let arg_node = self.ast.get_extra(arg_exprs_start + i)
            args.push(self.lower_call_arg(arg_node, sig_idx, callable_fn_tid, i))

        // Fill in default parameter values for missing arguments
        if fn_expr != 0 and self.ast.kind(fn_expr) == NodeKind.NK_IDENT:
            let callee_sym = self.ast.get_data0(fn_expr)
            if self.sema.fn_decl_nodes.contains(callee_sym):
                let fn_node = self.sema.fn_decl_nodes.get(callee_sym).unwrap()
                let meta = self.ast.find_fn_meta(fn_node)
                if meta >= 0:
                    let param_start = self.ast.fn_meta_param_start(meta)
                    let param_count = self.ast.fn_meta_param_count(meta)
                    for di in arg_exprs_count..param_count:
                        let def_node = self.ast.get_fn_param_default(param_start, di)
                        if def_node != 0:
                            args.push(self.lower_call_arg(def_node, sig_idx, callable_fn_tid, di))

    let args_id = self.body.new_call_args(args)
    let result_local = self.new_temp(ret_type_id)
    let result_place = self.place_for_local(result_local)
    let next_bb = self.new_block()

    self.terminate(TermKind.TK_CALL, fn_op, args_id, result_place, next_bb)
    self.switch_to(next_bb)

    if self.sema.is_copy(ret_type_id) != 0:
        return self.body.new_operand(OperandKind.OK_COPY, result_place)
    self.body.new_operand(OperandKind.OK_MOVE, result_place)

// Callable type redirect: like lower_call but uses a pre-resolved fn operand and symbol.
fn MirBuilder.lower_call_redirected(self: MirBuilder, fn_op: i32, fn_sym: i32, arg_exprs_start: i32, arg_exprs_count: i32, ret_type_id: i32, node: i32) -> i32:
    let sig_idx = self.call_sig_for_sym(fn_sym)
    let args: Vec[i32] = Vec.new()
    for i in 0..arg_exprs_count:
        let arg_node = self.ast.get_extra(arg_exprs_start + i)
        args.push(self.lower_call_arg(arg_node, sig_idx, 0, i))
    let args_id = self.body.new_call_args(args)
    let result_local = self.new_temp(ret_type_id)
    let result_place = self.place_for_local(result_local)
    let next_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, fn_op, args_id, result_place, next_bb)
    self.switch_to(next_bb)
    if self.sema.is_copy(ret_type_id) != 0:
        return self.body.new_operand(OperandKind.OK_COPY, result_place)
    self.body.new_operand(OperandKind.OK_MOVE, result_place)

// Like lower_call but takes arg node indices in a Vec instead of reading from
// pool.extra. This avoids mutating the shared AstPool (which would trigger
// Vec realloc and invalidate other copies' pointers — use-after-free).
fn MirBuilder.lower_call_with_arg_nodes(self: MirBuilder, fn_op: i32, callee_sym: i32, arg_node_vec: Vec[i32], ret_type_id: i32, node: i32) -> i32:
    let sig_idx = self.call_sig_for_sym(callee_sym)
    let args: Vec[i32] = Vec.new()
    for i in 0..arg_node_vec.len() as i32:
        args.push(self.lower_call_arg(arg_node_vec.get(i as i64), sig_idx, 0, i))
    let args_id = self.body.new_call_args(args)
    let result_local = self.new_temp(ret_type_id)
    let result_place = self.place_for_local(result_local)
    let next_bb = self.new_block()
    self.terminate(TermKind.TK_CALL, fn_op, args_id, result_place, next_bb)
    self.switch_to(next_bb)
    if self.sema.is_copy(ret_type_id) != 0:
        return self.body.new_operand(OperandKind.OK_COPY, result_place)
    self.body.new_operand(OperandKind.OK_MOVE, result_place)

fn MirBuilder.call_sig_for_sym(self: MirBuilder, sym: i32) -> i32:
    if sym == 0:
        return -1
    let direct = self.sema.get_sig(sym)
    if direct >= 0:
        return direct
    let name = self.pool.resolve_symbol(sym)
    if name.len() == 0:
        return -1
    let sema_sym = self.sema.pool_lookup_symbol(name)
    self.sema.get_sig(sema_sym)

fn MirBuilder.call_sig_for_expr(self: MirBuilder, fn_expr: i32) -> i32:
    if fn_expr == 0:
        return -1
    if self.ast.kind(fn_expr) != NodeKind.NK_IDENT:
        return -1
    self.call_sig_for_sym(self.ast.get_data0(fn_expr))

fn MirBuilder.callable_fn_type_for_expr(self: MirBuilder, fn_expr: i32) -> i32:
    if fn_expr == 0:
        return 0
    let expr_tid = self.expr_type(fn_expr)
    if expr_tid == 0:
        return 0
    self.sema.callable_fn_type(expr_tid as TypeId)

fn MirBuilder.lower_call_arg(self: MirBuilder, arg_node: i32, sig_idx: i32, callable_fn_tid: i32, arg_i: i32) -> i32:
    let saved_expected = self.expected_type
    if sig_idx >= 0 and arg_i >= 0 and arg_i < self.sema.sig_get_param_count(sig_idx):
        let expected_ty = self.sema.sig_param_type(sig_idx, arg_i)
        if expected_ty != 0 and expected_ty != self.sema.ty_void:
            self.expected_type = expected_ty
    else if callable_fn_tid != 0:
        let expected_ty = self.sema.callable_fn_param_type(callable_fn_tid as TypeId, arg_i)
        if expected_ty != 0 and expected_ty != self.sema.ty_void:
            self.expected_type = expected_ty
    let lowered = self.lower_expr(arg_node)
    self.expected_type = saved_expected
    lowered

fn MirBuilder.resolve_method_callee_sym(self: MirBuilder, self_expr: i32, method_sym: i32) -> i32:
    // Translate method_sym from AST pool to sema pool for method lookups.
    let sema_method_sym = self.sema.pool_lookup_symbol(self.pool.resolve_symbol(method_sym))
    let obj_type = self.expr_type(self_expr)
    if obj_type != 0 and obj_type != self.sema.ty_void:
        let resolved = self.sema.resolve_alias(obj_type)
        let type_name_sym = self.sema.get_type_name(resolved)
        if type_name_sym != 0:
            let method_fn = self.sema.lookup_method_fn(type_name_sym, sema_method_sym)
            if method_fn != 0 and self.sema.lookup_method_sig(type_name_sym, sema_method_sym) >= 0:
                return method_fn
        // For builtin types (i32, str, bool, etc.), try the type kind name
        let tk = self.sema.get_type_kind(resolved)
        if tk == TypeKind.TY_INT:
            let int_sym = self.sema.pool_lookup_symbol("i32")
            let method_fn = self.sema.lookup_method_fn(int_sym, sema_method_sym)
            if method_fn != 0 and self.sema.lookup_method_sig(int_sym, sema_method_sym) >= 0:
                return method_fn
        if tk == TypeKind.TY_STR:
            let str_sym = self.sema.pool_lookup_symbol("str")
            let method_fn = self.sema.lookup_method_fn(str_sym, sema_method_sym)
            if method_fn != 0 and self.sema.lookup_method_sig(str_sym, sema_method_sym) >= 0:
                return method_fn
        if tk == TypeKind.TY_BOOL:
            let bool_sym = self.sema.pool_lookup_symbol("bool")
            let method_fn = self.sema.lookup_method_fn(bool_sym, sema_method_sym)
            if method_fn != 0 and self.sema.lookup_method_sig(bool_sym, sema_method_sym) >= 0:
                return method_fn
        if tk == TypeKind.TY_FLOAT:
            let float_sym = self.sema.pool_lookup_symbol("f64")
            let method_fn = self.sema.lookup_method_fn(float_sym, sema_method_sym)
            if method_fn != 0 and self.sema.lookup_method_sig(float_sym, sema_method_sym) >= 0:
                return method_fn

    if self.ast.kind(self_expr) == NodeKind.NK_IDENT:
        let type_sym = self.ast.get_data0(self_expr)
        let method_fn = self.sema.lookup_method_fn(type_sym, method_sym)
        if method_fn != 0 and self.sema.lookup_method_sig(type_sym, method_sym) >= 0:
            return method_fn

    // Handle Vec[i32].method() — receiver is NodeKind.NK_INDEX of a type name
    if self.ast.kind(self_expr) == NodeKind.NK_INDEX:
        let base = self.ast.get_data0(self_expr)
        if self.ast.kind(base) == NodeKind.NK_IDENT:
            let type_sym = self.ast.get_data0(base)
            let method_fn = self.sema.lookup_method_fn(type_sym, method_sym)
            if method_fn != 0 and self.sema.lookup_method_sig(type_sym, method_sym) >= 0:
                return method_fn

    method_sym

fn MirBuilder.classify_intrinsic(self: MirBuilder, recv_type: i32, method_name: str) -> i32:
    if recv_type == 0 or method_name.len() == 0:
        return MirIntrinsic.MIR_INTRINSIC_NONE
    let resolved = self.sema.resolve_alias(recv_type)
    // Check primitive types first (no type_name_sym for TypeKind.TY_STR, TypeKind.TY_INT, etc.)
    let tk = self.sema.get_type_kind(resolved)
    if tk == TypeKind.TY_STR:
        if method_name == "len": return MirIntrinsic.MIR_INTRINSIC_STR_LEN
        if method_name == "byte_at": return MirIntrinsic.MIR_INTRINSIC_STR_BYTE_AT
        if method_name == "slice": return MirIntrinsic.MIR_INTRINSIC_STR_SLICE
        if method_name == "contains": return MirIntrinsic.MIR_INTRINSIC_STR_CONTAINS
        if method_name == "starts_with": return MirIntrinsic.MIR_INTRINSIC_STR_STARTS_WITH
        if method_name == "ends_with": return MirIntrinsic.MIR_INTRINSIC_STR_ENDS_WITH
        if method_name == "find": return MirIntrinsic.MIR_INTRINSIC_STR_FIND
        if method_name == "split": return MirIntrinsic.MIR_INTRINSIC_STR_SPLIT
        if method_name == "trim": return MirIntrinsic.MIR_INTRINSIC_STR_TRIM
        if method_name == "to_upper": return MirIntrinsic.MIR_INTRINSIC_STR_TO_UPPER
        if method_name == "to_lower": return MirIntrinsic.MIR_INTRINSIC_STR_TO_LOWER
        if method_name == "replace": return MirIntrinsic.MIR_INTRINSIC_STR_REPLACE
        if method_name == "index_of": return MirIntrinsic.MIR_INTRINSIC_STR_INDEX_OF
        if method_name == "repeat": return MirIntrinsic.MIR_INTRINSIC_STR_REPEAT
        return MirIntrinsic.MIR_INTRINSIC_NONE
    if tk == TypeKind.TY_ARRAY:
        if method_name == "len": return MirIntrinsic.MIR_INTRINSIC_ARR_LEN
        return MirIntrinsic.MIR_INTRINSIC_NONE
    if tk == TypeKind.TY_INT:
        if method_name == "rotate_left": return MirIntrinsic.MIR_INTRINSIC_ROTATE_LEFT
        if method_name == "rotate_right": return MirIntrinsic.MIR_INTRINSIC_ROTATE_RIGHT
        if method_name == "swap_bytes": return MirIntrinsic.MIR_INTRINSIC_INT_SWAP_BYTES
        if method_name == "popcount": return MirIntrinsic.MIR_INTRINSIC_POPCOUNT
        if method_name == "clz": return MirIntrinsic.MIR_INTRINSIC_CLZ
        if method_name == "ctz": return MirIntrinsic.MIR_INTRINSIC_CTZ
        if method_name == "bitreverse": return MirIntrinsic.MIR_INTRINSIC_BITREVERSE
        if method_name == "min": return MirIntrinsic.MIR_INTRINSIC_MIN
        if method_name == "max": return MirIntrinsic.MIR_INTRINSIC_MAX
        if method_name == "abs": return MirIntrinsic.MIR_INTRINSIC_ABS
    if tk == TypeKind.TY_FLOAT:
        if method_name == "min": return MirIntrinsic.MIR_INTRINSIC_MIN
        if method_name == "max": return MirIntrinsic.MIR_INTRINSIC_MAX
        if method_name == "abs": return MirIntrinsic.MIR_INTRINSIC_ABS
        if method_name == "mul_add": return MirIntrinsic.MIR_INTRINSIC_FMA
    let type_name_sym = self.sema.get_type_name(resolved)
    if type_name_sym == 0:
        return MirIntrinsic.MIR_INTRINSIC_NONE
    let type_name = self.pool.resolve_symbol(type_name_sym)
    if type_name == "Vec":
        if method_name == "new": return MirIntrinsic.MIR_INTRINSIC_VEC_NEW
        if method_name == "with_capacity": return MirIntrinsic.MIR_INTRINSIC_VEC_WITH_CAPACITY
        if method_name == "push": return MirIntrinsic.MIR_INTRINSIC_VEC_PUSH
        if method_name == "get": return MirIntrinsic.MIR_INTRINSIC_VEC_GET
        if method_name == "len": return MirIntrinsic.MIR_INTRINSIC_VEC_LEN
        if method_name == "set_i32": return MirIntrinsic.MIR_INTRINSIC_VEC_SET
        if method_name == "remove": return MirIntrinsic.MIR_INTRINSIC_VEC_REMOVE
        if method_name == "clear": return MirIntrinsic.MIR_INTRINSIC_VEC_CLEAR
        if method_name == "pop": return MirIntrinsic.MIR_INTRINSIC_VEC_POP
        if method_name == "iter": return MirIntrinsic.MIR_INTRINSIC_VEC_ITER
        if method_name == "map": return MirIntrinsic.MIR_INTRINSIC_VEC_MAP
        if method_name == "filter": return MirIntrinsic.MIR_INTRINSIC_VEC_FILTER
        if method_name == "fold": return MirIntrinsic.MIR_INTRINSIC_VEC_FOLD
        if method_name == "contains": return MirIntrinsic.MIR_INTRINSIC_VEC_CONTAINS
        if method_name == "join": return MirIntrinsic.MIR_INTRINSIC_VEC_JOIN
        return MirIntrinsic.MIR_INTRINSIC_NONE
    if type_name == "VecIter":
        if method_name == "next": return MirIntrinsic.MIR_INTRINSIC_VECITER_NEXT
        return MirIntrinsic.MIR_INTRINSIC_NONE
    if type_name == "HashMap":
        if method_name == "new": return MirIntrinsic.MIR_INTRINSIC_MAP_NEW
        if method_name == "insert": return MirIntrinsic.MIR_INTRINSIC_MAP_INSERT
        if method_name == "get": return MirIntrinsic.MIR_INTRINSIC_MAP_GET
        if method_name == "contains": return MirIntrinsic.MIR_INTRINSIC_MAP_CONTAINS
        if method_name == "len": return MirIntrinsic.MIR_INTRINSIC_MAP_LEN
        if method_name == "remove": return MirIntrinsic.MIR_INTRINSIC_MAP_REMOVE
        if method_name == "clear": return MirIntrinsic.MIR_INTRINSIC_MAP_CLEAR
        if method_name == "increment": return MirIntrinsic.MIR_INTRINSIC_MAP_INCREMENT
        if method_name == "keys": return MirIntrinsic.MIR_INTRINSIC_MAP_KEYS
        return MirIntrinsic.MIR_INTRINSIC_NONE
    if type_name == "HashSet":
        if method_name == "new": return MirIntrinsic.MIR_INTRINSIC_MAP_NEW
        if method_name == "insert": return MirIntrinsic.MIR_INTRINSIC_MAP_INSERT
        if method_name == "contains": return MirIntrinsic.MIR_INTRINSIC_MAP_CONTAINS
        if method_name == "len": return MirIntrinsic.MIR_INTRINSIC_MAP_LEN
        if method_name == "remove": return MirIntrinsic.MIR_INTRINSIC_MAP_REMOVE
        if method_name == "clear": return MirIntrinsic.MIR_INTRINSIC_MAP_CLEAR
        return MirIntrinsic.MIR_INTRINSIC_NONE
    if type_name == "Option":
        if method_name == "is_some": return MirIntrinsic.MIR_INTRINSIC_OPT_IS_SOME
        if method_name == "is_none": return MirIntrinsic.MIR_INTRINSIC_OPT_IS_NONE
        if method_name == "unwrap": return MirIntrinsic.MIR_INTRINSIC_OPT_UNWRAP
        if method_name == "filter": return MirIntrinsic.MIR_INTRINSIC_OPT_FILTER
        return MirIntrinsic.MIR_INTRINSIC_NONE
    if type_name == "Result":
        if method_name == "is_ok": return MirIntrinsic.MIR_INTRINSIC_OPT_IS_SOME
        if method_name == "unwrap": return MirIntrinsic.MIR_INTRINSIC_OPT_UNWRAP
        return MirIntrinsic.MIR_INTRINSIC_NONE
    if type_name == "Atomic":
        if method_name == "load": return MirIntrinsic.MIR_INTRINSIC_ATOMIC_LOAD
        if method_name == "store": return MirIntrinsic.MIR_INTRINSIC_ATOMIC_STORE
        if method_name == "swap": return MirIntrinsic.MIR_INTRINSIC_ATOMIC_SWAP
        if method_name == "fetch_add": return MirIntrinsic.MIR_INTRINSIC_ATOMIC_FETCH_ADD
        if method_name == "fetch_sub": return MirIntrinsic.MIR_INTRINSIC_ATOMIC_FETCH_SUB
        if method_name == "fetch_and": return MirIntrinsic.MIR_INTRINSIC_ATOMIC_FETCH_AND
        if method_name == "fetch_or": return MirIntrinsic.MIR_INTRINSIC_ATOMIC_FETCH_OR
        if method_name == "fetch_xor": return MirIntrinsic.MIR_INTRINSIC_ATOMIC_FETCH_XOR
        if method_name == "fetch_min": return MirIntrinsic.MIR_INTRINSIC_ATOMIC_FETCH_MIN
        if method_name == "fetch_max": return MirIntrinsic.MIR_INTRINSIC_ATOMIC_FETCH_MAX
        if method_name == "compare_exchange": return MirIntrinsic.MIR_INTRINSIC_ATOMIC_CAS
        if method_name == "compare_exchange_weak": return MirIntrinsic.MIR_INTRINSIC_ATOMIC_CAS_WEAK
        return MirIntrinsic.MIR_INTRINSIC_NONE
    MirIntrinsic.MIR_INTRINSIC_NONE

fn MirBuilder.receiver_option_intrinsic(self: MirBuilder, recv_expr: i32) -> i32:
    // Check if recv_expr is a call to an intrinsic method that returns Option.
    // Used to classify chained .unwrap()/.is_some() when the receiver type is void.
    if self.ast.kind(recv_expr) != NodeKind.NK_CALL:
        return MirIntrinsic.MIR_INTRINSIC_NONE
    let callee = self.ast.get_data0(recv_expr)
    if self.ast.kind(callee) != NodeKind.NK_FIELD_ACCESS:
        return MirIntrinsic.MIR_INTRINSIC_NONE
    let base = self.ast.get_data0(callee)
    let method_sym = self.ast.get_data1(callee)
    let base_ty = self.expr_type(base)
    if base_ty == 0 or base_ty == self.sema.ty_void:
        return MirIntrinsic.MIR_INTRINSIC_NONE
    let method_name = self.pool.resolve_symbol(method_sym)
    let resolved = self.sema.resolve_alias(base_ty)
    let type_name_sym = self.sema.get_type_name(resolved)
    if type_name_sym == 0:
        return MirIntrinsic.MIR_INTRINSIC_NONE
    let type_name = self.pool.resolve_symbol(type_name_sym)
    // HashMap.get and HashMap.contains return Option-wrapped values
    if type_name == "HashMap":
        if method_name == "get": return MirIntrinsic.MIR_INTRINSIC_MAP_GET
    if type_name == "HashSet":
        if method_name == "contains": return MirIntrinsic.MIR_INTRINSIC_MAP_CONTAINS
    MirIntrinsic.MIR_INTRINSIC_NONE

fn MirBuilder.lower_method_call(self: MirBuilder, self_expr: i32, method_sym: i32, arg_start: i32, arg_count: i32, node: i32) -> i32:
    // Lower method calls as normal calls with receiver inserted as first arg.
    let callee_sym = self.resolve_method_callee_sym(self_expr, method_sym)

    // Classify intrinsic early — needed to decide whether to mark_unsupported.
    // For instance methods (vec.push), recv_type comes from the receiver expression.
    // For static calls (Vec.new), the receiver is a type ident — use its symbol to
    // look up the type name, and fall back to the call's return type.
    var recv_type = self.expr_type(self_expr)
    if recv_type == 0 or recv_type == self.sema.ty_void:
        recv_type = self.type_receiver_type(self_expr)
    if recv_type == 0 or recv_type == self.sema.ty_void:
        // Fall back to call's return type for static constructors (Vec.new())
        let ret_type = self.expr_type(node)
        let ret_name_sym = self.sema.get_type_name(ret_type)
        if self.ast.kind(self_expr) == NodeKind.NK_IDENT:
            let type_sym = self.ast.get_data0(self_expr)
            if ret_name_sym == type_sym:
                recv_type = ret_type
    let method_name = self.pool.resolve_symbol(method_sym)
    var intrinsic = self.classify_intrinsic(recv_type, method_name)

    // When classify_intrinsic fails for "unwrap"/"is_some", handle as Option
    // intrinsic. Sema's type system returns the raw value type for HashMap.get
    // (e.g., i32 instead of Option[i32]), so classify_intrinsic can't match Option.
    // Two fallbacks:
    // 1. Receiver is a direct call to HashMap.get/Vec.get (chained: map.get(k).unwrap())
    // 2. No sig exists for this method on the receiver type (let x = map.get(k); x.unwrap())
    if intrinsic == MirIntrinsic.MIR_INTRINSIC_NONE:
        if method_name == "unwrap" or method_name == "is_some" or method_name == "is_none":
            var is_option_method = false
            let recv_intr = self.receiver_option_intrinsic(self_expr)
            if recv_intr != MirIntrinsic.MIR_INTRINSIC_NONE:
                is_option_method = true
            else if callee_sym == method_sym:
                // Unresolved method — no sig found for unwrap/is_some/is_none on the receiver type.
                // User-defined types with these names would have a sig. This is an Option intrinsic.
                is_option_method = true
            if is_option_method:
                if method_name == "unwrap":
                    intrinsic = MirIntrinsic.MIR_INTRINSIC_OPT_UNWRAP
                else if method_name == "is_none":
                    intrinsic = MirIntrinsic.MIR_INTRINSIC_OPT_IS_NONE
                else:
                    intrinsic = MirIntrinsic.MIR_INTRINSIC_OPT_IS_SOME

    // For intrinsic calls (Vec/HashMap/Option), bypass lower_call entirely.
    // lower_call → lower_var would mark_unsupported on the bare method sym.
    // Instead, emit the call terminator directly with an intrinsic tag.
    if intrinsic != MirIntrinsic.MIR_INTRINSIC_NONE:
        return self.lower_intrinsic_call(intrinsic, self_expr, method_sym, arg_start, arg_count, node)

    // If resolution returned bare method_sym, the method is unresolved.
    // Route through MirIntrinsic.MIR_INTRINSIC_GENERIC_CALL so codegen's gen_call handles it
    // (disc enums, from_int, Option methods, concrete/generic struct methods, etc.).
    if callee_sym == method_sym:
            let gc_fn_op = self.const_operand(ConstKind.CK_FN, callee_sym, 0)
            let gc_args: Vec[i32] = Vec.new()
            // Lower self + method args so the handler can eval them.
            // Skip receiver for static calls (type name, not value expression).
            var gc_is_static = false
            if self.ast.kind(self_expr) == NodeKind.NK_IDENT:
                let gc_id_sym = self.ast.get_data0(self_expr)
                if self.lookup_local(gc_id_sym) < 0 and self.sema.named_types.contains(gc_id_sym):
                    gc_is_static = true
            if self.ast.kind(self_expr) == NodeKind.NK_TYPE_NAMED or self.ast.kind(self_expr) == NodeKind.NK_TYPE_GENERIC or self.ast.kind(self_expr) == NodeKind.NK_TYPE_PTR or self.ast.kind(self_expr) == NodeKind.NK_TYPE_REF or self.ast.kind(self_expr) == NodeKind.NK_TYPE_ARRAY or self.ast.kind(self_expr) == NodeKind.NK_TYPE_SLICE or self.ast.kind(self_expr) == NodeKind.NK_TYPE_TUPLE or self.ast.kind(self_expr) == NodeKind.NK_TYPE_FN or self.ast.kind(self_expr) == NodeKind.NK_TYPE_TRAIT_OBJ:
                gc_is_static = true
            if self.ast.kind(self_expr) == NodeKind.NK_INDEX:
                let gc_idx_base = self.ast.get_data0(self_expr)
                if self.ast.kind(gc_idx_base) == NodeKind.NK_IDENT:
                    let gc_idx_sym = self.ast.get_data0(gc_idx_base)
                    if self.lookup_local(gc_idx_sym) < 0 and self.sema.named_types.contains(gc_idx_sym):
                        gc_is_static = true
            if not gc_is_static:
                gc_args.push(self.lower_expr(self_expr))
            for gc_mai in 0..arg_count:
                let gc_ma_node = self.ast.get_extra(arg_start + gc_mai)
                if self.ast.kind(gc_ma_node) != NodeKind.NK_CLOSURE:
                    gc_args.push(self.lower_expr(gc_ma_node))
                else:
                    gc_args.push(self.const_operand(ConstKind.CK_INT, 0, self.sema.ty_i32))
            let gc_args_id = self.body.new_call_args(gc_args)
            self.body.set_call_intrinsic(gc_args_id, MirIntrinsic.MIR_INTRINSIC_GENERIC_CALL)
            self.body.set_call_ast_node(gc_args_id, node)
            var gc_ret_ty = self.expr_type(node)
            if gc_ret_ty == 0:
                gc_ret_ty = self.sema.ty_i32 as i32
            let gc_result = self.new_temp(gc_ret_ty)
            let gc_place = self.place_for_local(gc_result)
            let gc_next = self.new_block()
            self.terminate(TermKind.TK_CALL, gc_fn_op, gc_args_id, gc_place, gc_next)
            self.switch_to(gc_next)
            return self.body.new_operand(OperandKind.OK_COPY, gc_place)

    let fn_op = self.lower_var(callee_sym, 0)
    let arg_nodes: Vec[i32] = Vec.new()
    // For static method calls (receiver is a type name, not a value),
    // don't pass the receiver as an argument.
    var is_static_call = false
    if self.ast.kind(self_expr) == NodeKind.NK_IDENT:
        let recv_sym = self.ast.get_data0(self_expr)
        if self.lookup_local(recv_sym) < 0 and self.sema.named_types.contains(recv_sym):
            is_static_call = true
    if self.ast.kind(self_expr) == NodeKind.NK_TYPE_NAMED or self.ast.kind(self_expr) == NodeKind.NK_TYPE_GENERIC or self.ast.kind(self_expr) == NodeKind.NK_TYPE_PTR or self.ast.kind(self_expr) == NodeKind.NK_TYPE_REF or self.ast.kind(self_expr) == NodeKind.NK_TYPE_ARRAY or self.ast.kind(self_expr) == NodeKind.NK_TYPE_SLICE or self.ast.kind(self_expr) == NodeKind.NK_TYPE_TUPLE or self.ast.kind(self_expr) == NodeKind.NK_TYPE_FN or self.ast.kind(self_expr) == NodeKind.NK_TYPE_TRAIT_OBJ:
        is_static_call = true
    // Also detect Vec[i32].method() as static
    if self.ast.kind(self_expr) == NodeKind.NK_INDEX:
        let idx_base = self.ast.get_data0(self_expr)
        if self.ast.kind(idx_base) == NodeKind.NK_IDENT:
            let recv_sym = self.ast.get_data0(idx_base)
            if self.lookup_local(recv_sym) < 0 and self.sema.named_types.contains(recv_sym):
                is_static_call = true
    if not is_static_call:
        arg_nodes.push(self_expr)
    for i in 0..arg_count:
        arg_nodes.push(self.ast.get_extra(arg_start + i))

    self.lower_call_with_arg_nodes(fn_op, callee_sym, arg_nodes, self.expr_type(node), node)

fn MirBuilder.lower_intrinsic_call(self: MirBuilder, intrinsic: i32, self_expr: i32, method_sym: i32, arg_start: i32, arg_count: i32, node: i32) -> i32:
    // Emit a call terminator with a ConstKind.CK_FN operand and intrinsic tag.
    // The ConstKind.CK_FN sym is meaningless — codegen dispatches by intrinsic kind.
    let fn_op = self.const_operand(ConstKind.CK_FN, method_sym, self.sema.ty_void)

    // Build argument operands. For static calls (Vec.new, HashMap.new),
    // the receiver is a type ident — skip it. For instance methods, include it.
    let is_static = intrinsic == MirIntrinsic.MIR_INTRINSIC_VEC_NEW or intrinsic == MirIntrinsic.MIR_INTRINSIC_VEC_WITH_CAPACITY or intrinsic == MirIntrinsic.MIR_INTRINSIC_MAP_NEW
    let call_args: Vec[i32] = Vec.new()
    if not is_static:
        call_args.push(self.lower_expr(self_expr))
    for i in 0..arg_count:
        let arg_node = self.ast.get_extra(arg_start + i)
        call_args.push(self.lower_expr(arg_node))

    let args_id = self.body.new_call_args(call_args)
    var ret_type = self.expr_type(node)
    // For static constructors (Vec.new, HashMap.new), expr_type often returns
    // the bare struct type (TypeKind.TY_STRUCT) instead of the generic instance
    // (TypeKind.TY_GENERIC_INST). Use the expected type from the let binding if available.
    // Only apply to static constructors — instance methods (str.slice, vec.len) must
    // keep their own return type, not inherit the function's generic return type.
    if is_static and self.expected_type > 0:
        let expected_resolved = self.sema.resolve_alias(self.expected_type)
        let et_tk = self.sema.get_type_kind(expected_resolved)
        if et_tk == TypeKind.TY_GENERIC_INST:
            ret_type = expected_resolved as i32
    // If ret_type is still a base struct (not generic instance) for a static
    // constructor, try to resolve from the NodeKind.NK_INDEX receiver (Vec[i32]).
    if is_static:
        let ret_resolved = if ret_type != 0: self.sema.resolve_alias(ret_type) else: 0
        let ret_tk = self.sema.get_type_kind(ret_resolved)
        if ret_type == 0 or ret_type == self.sema.ty_void or ret_tk == TypeKind.TY_STRUCT:
            // Try resolving generic instance from NodeKind.NK_INDEX receiver (e.g. Vec[i32])
            if self.ast.kind(self_expr) == NodeKind.NK_INDEX:
                let gi_type = self.resolve_index_generic_inst(self_expr)
                if gi_type > 0:
                    ret_type = gi_type
        // Re-check after NodeKind.NK_INDEX resolution
        let ret_resolved2 = if ret_type != 0: self.sema.resolve_alias(ret_type) else: 0
        let ret_tk2 = self.sema.get_type_kind(ret_resolved2)
        if ret_type == 0 or ret_type == self.sema.ty_void or ret_tk2 == TypeKind.TY_STRUCT:
            self.mark_unsupported()
    let result_local = self.new_temp(ret_type)
    let result_place = self.place_for_local(result_local)
    let next_bb = self.new_block()

    self.terminate(TermKind.TK_CALL, fn_op, args_id, result_place, next_bb)
    self.switch_to(next_bb)

    // Tag call with intrinsic kind for codegen dispatch.
    let call_id = self.body.call_arg_starts.len() as i32 - 1
    self.body.set_call_intrinsic(call_id, intrinsic)

    if self.sema.is_copy(ret_type) != 0:
        return self.body.new_operand(OperandKind.OK_COPY, result_place)
    self.body.new_operand(OperandKind.OK_MOVE, result_place)

fn MirBuilder.lower_vtable_call(self: MirBuilder, dyn_expr: i32, _trait_sym: i32, method_sym: i32, args_start: i32, args_count: i32, node: i32) -> i32:
    // Conservative lowering: treat as method call on dynamic receiver.
    self.lower_method_call(dyn_expr, method_sym, args_start, args_count, node)

fn MirBuilder.lower_question_mark(self: MirBuilder, expr: i32, node: i32) -> i32:
    let value_op = self.lower_expr(expr)
    let value_ty = self.expr_type(expr)
    let value_place = self.materialize_operand(value_op, value_ty, self.ast.get_start(expr))

    let pass_bb = self.new_block()
    let fail_bb = self.new_block()
    let join_bb = self.new_block()

    let disc = self.lower_enum_discriminant(value_place)
    let vals: Vec[i32] = Vec.new()
    vals.push(self.success_variant_index())
    let targets: Vec[i32] = Vec.new()
    targets.push(pass_bb as i32)
    let table = self.body.new_switch_table(vals, targets)
    self.terminate(TermKind.TK_SWITCH_INT, disc, table, fail_bb, 0)

    self.switch_to(fail_bb)
    let ret_place = self.place_for_local(0)
    let fail_op = self.body.new_operand(OperandKind.OK_MOVE, value_place)
    self.assign_operand_to_place(ret_place, fail_op, self.ast.get_start(expr))
    self.emit_errdefers_for_return()
    self.emit_defers_for_return()
    self.emit_drops_for_return()
    self.terminate(TermKind.TK_RETURN, 0, 0, 0, 0)

    // Extract Ok payload via ProjKind.PK_DOWNCAST + field access
    var result_ty = self.expr_type(node)
    if result_ty == 0 or result_ty == self.sema.ty_void:
        result_ty = value_ty
    self.switch_to(pass_bb)
    let result_local = self.new_temp(result_ty)
    let result_place = self.place_for_local(result_local)
    let downcast_place = self.body.new_downcast_place(value_place, self.success_variant_index(), value_ty)
    let payload_place = self.body.new_field_place(downcast_place, 0, result_ty)
    let pass_op = self.body.new_operand(if self.sema.is_copy(result_ty) != 0: OperandKind.OK_COPY else: OperandKind.OK_MOVE, payload_place)
    self.assign_operand_to_place(result_place, pass_op, self.ast.get_start(expr))
    self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

    self.switch_to(join_bb)
    if self.sema.is_copy(result_ty) != 0:
        return self.body.new_operand(OperandKind.OK_COPY, result_place)
    self.body.new_operand(OperandKind.OK_MOVE, result_place)

fn MirBuilder.lower_double_question(self: MirBuilder, expr: i32, default_expr: i32, node: i32) -> i32:
    let value_op = self.lower_expr(expr)
    let value_ty = self.expr_type(expr)
    let value_place = self.materialize_operand(value_op, value_ty, self.ast.get_start(expr))

    let some_bb = self.new_block()
    let none_bb = self.new_block()
    let join_bb = self.new_block()

    let disc = self.lower_enum_discriminant(value_place)
    let vals: Vec[i32] = Vec.new()
    vals.push(self.success_variant_index())
    let targets: Vec[i32] = Vec.new()
    targets.push(some_bb as i32)
    let table = self.body.new_switch_table(vals, targets)
    self.terminate(TermKind.TK_SWITCH_INT, disc, table, none_bb, 0)

    var result_ty = self.expr_type(node)
    if result_ty == 0 or result_ty == self.sema.ty_void:
        result_ty = self.sema.try_unwrapped_type(value_ty)
    if result_ty == 0 or result_ty == self.sema.ty_void:
        result_ty = value_ty
    let result_local = self.new_temp(result_ty)
    let result_place = self.place_for_local(result_local)

    self.switch_to(some_bb)
    let downcast_place = self.body.new_downcast_place(value_place, self.success_variant_index(), value_ty)
    let payload_place = self.body.new_field_place(downcast_place, 0, result_ty)
    let some_op = self.body.new_operand(if self.sema.is_copy(result_ty) != 0: OperandKind.OK_COPY else: OperandKind.OK_MOVE, payload_place)
    self.assign_operand_to_place(result_place, some_op, self.ast.get_start(expr))
    self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

    self.switch_to(none_bb)
    let default_op = self.lower_expr(default_expr)
    self.assign_operand_to_place(result_place, default_op, self.ast.get_start(default_expr))
    self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

    self.switch_to(join_bb)
    if self.sema.is_copy(result_ty) != 0:
        return self.body.new_operand(OperandKind.OK_COPY, result_place)
    self.body.new_operand(OperandKind.OK_MOVE, result_place)

fn MirBuilder.lower_with_form1(self: MirBuilder, guard_expr: i32, body_expr: i32) -> i32:
    let _ = self.lower_expr(guard_expr)
    self.push_scope()
    let result = self.lower_expr(body_expr)
    self.pop_scope_inline()
    result

fn MirBuilder.lower_with_binding(self: MirBuilder, sym: i32, rhs_expr: i32, body_expr: i32, span: i32) -> i32:
    // Recover mutability from the encoded d2 value passed via the caller.
    // The caller extracts sym via decode_with_binding_sym, but we need
    // the original encoded value to check is_mut. Re-derive from the
    // with-expr node being lowered.
    let with_node = self.cur_node
    let encoded = self.ast.get_data2(with_node)
    let is_mut = decode_with_binding_is_mut(encoded)
    self.push_scope()
    let ty = self.expr_type(rhs_expr)
    let local = self.body.new_local(ty, is_mut, sym, 1)
    self.bind_local(sym, local)
    self.body.push_stmt(self.cur_bb, StmtKind.StorageLive, local, 0, span)
    if self.sema.is_copy(ty) == 0:
        self.schedule_drop(local, DropKind.DK_VALUE)
    let rhs = self.lower_expr(rhs_expr)
    self.assign_operand_to_place(self.place_for_local(local), rhs, self.ast.get_start(rhs_expr))
    let result = self.lower_expr(body_expr)
    // Form 2 builder rule: when mut and body is unit, return the binding
    let body_ty = self.expr_type(body_expr)
    if is_mut != 0 and (body_ty == 0 or body_ty == self.sema.ty_void):
        let local_place = self.place_for_local(local)
        self.pop_scope_inline()
        return self.body.new_operand(OperandKind.OK_COPY, local_place)
    self.pop_scope_inline()
    result

fn MirBuilder.lower_with_form2_3(self: MirBuilder, pat_or_name: i32, rhs_expr: i32, body_expr: i32) -> i32:
    self.push_scope()
    if self.ast.kind(pat_or_name) == NodeKind.NK_IDENT:
        let sym = self.ast.get_data0(pat_or_name)
        let ty = self.expr_type(rhs_expr)
        let local = self.body.new_local(ty, 0, sym, 1)
        self.bind_local(sym, local)
        self.body.push_stmt(self.cur_bb, StmtKind.StorageLive, local, 0, self.ast.get_start(pat_or_name))
        if self.sema.is_copy(ty) == 0:
            self.schedule_drop(local, DropKind.DK_VALUE)
        let rhs = self.lower_expr(rhs_expr)
        self.assign_operand_to_place(self.place_for_local(local), rhs, self.ast.get_start(rhs_expr))
    else:
        let _ = self.lower_expr(rhs_expr)
    let result = self.lower_expr(body_expr)
    self.pop_scope_inline()
    result

fn MirBuilder.lower_record_update(self: MirBuilder, base_expr: i32, field_updates_start: i32, field_updates_count: i32, node: i32) -> i32:
    // Copy base struct to a temp, then overwrite specified fields
    let base = self.lower_expr(base_expr)
    let ty = self.expr_type(node)
    let tmp = self.new_temp(ty)
    let base_place = self.place_for_local(tmp)
    // Assign base to temp
    let use_rv = self.body.new_rvalue(RvalueKind.RK_USE, base, 0, 0)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, base_place, use_rv, self.ast.get_start(node))
    // Overwrite each updated field
    let resolved_ty = self.sema.resolve_alias(ty)
    let struct_extra = self.sema.get_type_d1(resolved_ty)
    let struct_fc = self.sema.get_type_d2(resolved_ty)
    for i in 0..field_updates_count:
        let f_name_sym = self.ast.get_extra(field_updates_start + i * 2)
        let f_val_node = self.ast.get_extra(field_updates_start + i * 2 + 1)
        // Find field index by name
        var fi = -1
        for j in 0..struct_fc:
            let sf_name = self.sema.type_extra.get((struct_extra + j * 3) as i64)
            if sf_name == f_name_sym:
                fi = j
                break
        if fi >= 0:
            let field_ty = self.struct_field_type(ty, f_name_sym)
            let saved_expected = self.expected_type
            if field_ty != 0:
                self.expected_type = field_ty
            let f_val = self.lower_expr(f_val_node)
            self.expected_type = saved_expected
            let field_place = self.body.new_field_place(base_place, f_name_sym, field_ty)
            let field_rv = self.body.new_rvalue(RvalueKind.RK_USE, f_val, 0, 0)
            self.body.push_stmt(self.cur_bb, StmtKind.Assign, field_place, field_rv, self.ast.get_start(node))
    self.body.new_operand(OperandKind.OK_COPY, base_place)

fn MirBuilder.lower_implicit_ok(self: MirBuilder, expr: i32, ok_type_id: i32) -> i32:
    let op = self.lower_expr(expr)
    let fields: Vec[i32] = Vec.new()
    fields.push(op)
    let no_names: Vec[i32] = Vec.new()
    no_names.push(0)
    let fid = self.body.new_agg_fields(fields, no_names)
    let rv = self.body.new_rvalue(RvalueKind.RK_AGGREGATE, 1, fid, 0)
    let tmp = self.new_temp(ok_type_id)
    let place = self.place_for_local(tmp)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, place, rv, self.ast.get_start(expr))
    self.body.new_operand(OperandKind.OK_COPY, place)

fn MirBuilder.lower_implicit_default_return(self: MirBuilder, type_id: i32) -> i32:
    if type_id == self.sema.ty_void:
        return self.unit_operand()
    if self.sema.get_type_kind(type_id) == TypeKind.TY_BOOL:
        return self.lower_bool_lit(0)
    self.lower_int_lit(0, type_id)

fn MirBuilder.lower_pipeline(self: MirBuilder, lhs_expr: i32, fn_expr: i32, args_start: i32, args_count: i32, node: i32) -> i32:
    let fn_op = self.lower_expr(fn_expr)
    let callee_sym =
        if fn_expr != 0 and self.ast.kind(fn_expr) == NodeKind.NK_IDENT:
            self.ast.get_data0(fn_expr)
        else:
            0
    let arg_nodes: Vec[i32] = Vec.new()
    arg_nodes.push(lhs_expr)
    for i in 0..args_count:
        arg_nodes.push(self.ast.get_extra(args_start + i))
    self.lower_call_with_arg_nodes(fn_op, callee_sym, arg_nodes, self.expr_type(node), node)

fn MirBuilder.lower_closure(self: MirBuilder, _captured_start: i32, _captured_count: i32, _params_start: i32, _params_count: i32, node: i32) -> i32:
    // Emit ConstKind.CK_CLOSURE so MIR codegen can delegate to gen_closure.
    // The closure body is compiled as a separate function by AST codegen.
    let ty = self.expr_type(node)
    if ty == 0:
        return self.unit_operand()
    let tmp = self.new_temp(ty)
    let place = self.place_for_local(tmp)
    let closure_const = self.body.new_const(ConstKind.CK_CLOSURE, node, 0, 0, ty)
    let op = self.body.new_operand(OperandKind.OK_CONSTANT, closure_const)
    let rv = self.body.new_rvalue(RvalueKind.RK_USE, op, 0, 0)
    self.body.push_stmt(self.cur_bb, StmtKind.Assign, place, rv, self.ast.get_start(node))
    self.body.new_operand(OperandKind.OK_COPY, place)

fn MirBuilder.lower_optional_chain(self: MirBuilder, node: i32) -> i32:
    let base_expr = self.ast.get_data0(node)
    let member_sym = self.ast.get_data1(node)
    let extra_start = self.ast.get_data2(node)
    let arg_count = if extra_start >= 0 and extra_start < self.ast.extra_len(): self.ast.get_extra(extra_start) else: 0

    let base_op = self.lower_expr(base_expr)
    let base_ty = self.expr_type(base_expr)
    let base_place = self.materialize_operand(base_op, base_ty, self.ast.get_start(base_expr))

    let some_bb = self.new_block()
    let none_bb = self.new_block()
    let join_bb = self.new_block()

    let disc = self.lower_enum_discriminant(base_place)
    let vals: Vec[i32] = Vec.new()
    vals.push(self.success_variant_index())
    let targets: Vec[i32] = Vec.new()
    targets.push(some_bb as i32)
    let table = self.body.new_switch_table(vals, targets)
    self.terminate(TermKind.TK_SWITCH_INT, disc, table, none_bb, 0)

    let result_ty = self.expr_type(node)
    let result_local = self.new_temp(result_ty)
    let result_place = self.place_for_local(result_local)

    self.switch_to(some_bb)
    if arg_count > 0:
        let args: Vec[i32] = Vec.new()
        args.push(self.body.new_operand(OperandKind.OK_COPY, base_place))
        for ai in 0..arg_count:
            args.push(self.lower_expr(self.ast.get_extra(extra_start + 1 + ai)))
        let args_id = self.body.new_call_args(args)
        let call_next_bb = self.new_block()
        self.terminate(TermKind.TK_CALL, self.unit_operand(), args_id, result_place, call_next_bb)
        self.switch_to(call_next_bb)
    else:
        let field_place = self.body.new_field_place(base_place, member_sym, 0)
        let field_op = self.body.new_operand(OperandKind.OK_COPY, field_place)
        self.assign_operand_to_place(result_place, field_op, self.ast.get_start(node))
    self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

    self.switch_to(none_bb)
    let default_op = self.lower_implicit_default_return(result_ty)
    self.assign_operand_to_place(result_place, default_op, self.ast.get_start(node))
    self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

    self.switch_to(join_bb)
    if self.sema.is_copy(result_ty) != 0:
        return self.body.new_operand(OperandKind.OK_COPY, result_place)
    self.body.new_operand(OperandKind.OK_MOVE, result_place)

fn MirBuilder.lower_expr(self: MirBuilder, node: i32) -> i32:
    if node == 0:
        return self.unit_operand()

    self.cur_node = node
    let kind = self.ast.kind(node)

    if kind == NodeKind.NK_INT_LIT:
        return self.lower_int_lit_node(node, self.expr_type(node))

    if kind == NodeKind.NK_BOOL_LIT:
        return self.lower_bool_lit(self.ast.get_data0(node))

    if kind == NodeKind.NK_STRING_LIT or kind == NodeKind.NK_C_STRING_LIT:
        return self.lower_str_lit(self.ast.get_data0(node))

    if kind == NodeKind.NK_FSTRING:
        return self.lower_fstring(node)

    if kind == NodeKind.NK_FLOAT_LIT:
        return self.lower_float_lit(self.ast.get_data0(node), self.expr_type(node))

    if kind == NodeKind.NK_NULL_LIT:
        // Null pointer literal: lower as integer 0 (codegen emits wl_const_null for ptr targets)
        return self.const_operand(ConstKind.CK_INT, 0, self.sema.ty_i32)

    if kind == NodeKind.NK_POISONED_EXPR:
        return self.unit_operand()

    if kind == NodeKind.NK_UNSAFE_BLOCK:
        // Transparent pass-through: just lower the inner body
        return self.lower_expr(self.ast.get_data0(node))

    if kind == NodeKind.NK_ASM_EXPR:
        // Inline assembly — emit as a call with MIR_INTRINSIC_ASM marker
        // Lower input expression values as MIR args
        let asm_packed_d2 = self.ast.get_data2(node)
        let asm_extra_start = asm_packed_d2 >> 8
        let asm_args: Vec[i32] = Vec.new()
        if asm_extra_start > 0:
            let asm_input_count = self.ast.get_extra(asm_extra_start + 1)
            for asm_ii in 0..asm_input_count:
                let asm_in_node = self.ast.get_extra(asm_extra_start + 2 + asm_ii)
                asm_args.push(self.lower_expr(asm_in_node))
        let asm_args_id = self.body.new_call_args(asm_args)
        self.body.set_call_intrinsic(asm_args_id, MirIntrinsic.MIR_INTRINSIC_ASM)
        self.body.set_call_ast_node(asm_args_id, node)
        let asm_ret_ty = self.expr_type(node)
        let asm_result_local = self.new_temp(asm_ret_ty)
        let asm_result_place = self.place_for_local(asm_result_local)
        let asm_callee = self.unit_operand()
        let asm_next_bb = self.new_block()
        self.terminate(TermKind.TK_CALL, asm_callee, asm_args_id, asm_result_place, asm_next_bb)
        self.switch_to(asm_next_bb)
        if asm_ret_ty != self.sema.ty_void as i32:
            return self.body.new_operand(OperandKind.OK_COPY, asm_result_place)
        return self.unit_operand()

    if kind == NodeKind.NK_COMPTIME_ERROR:
        // Emit unreachable — if this code is ever reached, it's a compile error
        self.terminate(TermKind.TK_UNREACHABLE, 0, 0, 0, 0)
        let dead_bb = self.new_block()
        self.switch_to(dead_bb)
        return self.unit_operand()

    if kind == NodeKind.NK_IDENT:
        return self.lower_var(self.ast.get_data0(node), self.expr_type(node))

    if kind == NodeKind.NK_BINARY:
        let op = self.ast.get_data0(node)
        let lhs = self.ast.get_data1(node)
        let rhs = self.ast.get_data2(node)
        if op == BinaryOp.OP_DEFAULT:
            return self.lower_double_question(lhs, rhs, node)
        return self.lower_bin_op(op, lhs, rhs, node)

    if kind == NodeKind.NK_UNARY:
        let op = self.ast.get_data0(node)
        let operand = self.ast.get_data1(node)
        if op == UnaryOp.UOP_TRY:
            return self.lower_question_mark(operand, node)
        return self.lower_un_op(op, operand, node)

    if kind == NodeKind.NK_CAST:
        // Read pre-resolved cast type from sema sidecar (avoids add_type on
        // shallow-copied Sema — see resolve_type_expr aliasing bug).
        var cast_tid = 0
        if self.sema.typed_expr_types.contains(node):
            cast_tid = self.sema.typed_expr_types.get(node).unwrap() as i32
        else:
            cast_tid = self.sema.resolve_type_expr(self.ast.get_data1(node)) as i32
        return self.lower_cast(self.ast.get_data0(node), cast_tid, node)

    if kind == NodeKind.NK_FIELD_ACCESS:
        let fa_base = self.ast.get_data0(node)
        let fa_field = self.ast.get_data1(node)
        // Distinct type .value access: transparent (no-op)
        let fa_base_type = self.expr_type(fa_base)
        if fa_base_type > 0:
            let fa_base_resolved = self.sema.resolve_alias(fa_base_type)
            let fa_base_sym = self.sema.get_type_d0(fa_base_resolved)
            if fa_base_sym > 0 and self.sema.distinct_type_names.contains(fa_base_sym):
                return self.lower_expr(fa_base)
        // Enum variant access: Color.Red → discriminant value constant
        if self.ast.kind(fa_base) == NodeKind.NK_IDENT:
            let fa_base_sym = self.ast.get_data0(fa_base)
            if self.sema.named_types.contains(fa_base_sym):
                let fa_base_ty = self.sema.named_types.get(fa_base_sym).unwrap()
                let fa_resolved = self.sema.resolve_alias(fa_base_ty)
                let fa_tk = self.sema.get_type_kind(fa_resolved)
                if fa_tk == TypeKind.TY_ENUM:
                    // Build qualified variant key: "Color.Red"
                    let fa_type_name = self.pool.resolve(fa_base_sym)
                    let fa_field_name = self.pool.resolve(fa_field)
                    let fa_qual_name = fa_type_name ++ "." ++ fa_field_name
                    let fa_qual_sym = self.pool.intern(fa_qual_name)
                    if self.sema.variant_lookup.contains(fa_qual_sym):
                        let fa_var_idx = self.sema.variant_lookup.get(fa_qual_sym).unwrap()
                        let fa_disc_tag = if self.sema.disc_values.contains(fa_qual_sym): self.sema.disc_values.get(fa_qual_sym).unwrap() else: fa_var_idx
                        // Plain enums are always lowered as full aggregate values.
                        // Only payloadless discriminant enums lower to their repr integer.
                        let fa_is_disc_enum = self.sema.disc_repr_types.contains(fa_resolved as i32)
                        if not fa_is_disc_enum or self.sema.disc_has_payload.contains(fa_resolved as i32):
                            let fa_fields: Vec[i32] = Vec.new()
                            let fa_names: Vec[i32] = Vec.new()
                            let fa_fid = self.body.new_agg_fields(fa_fields, fa_names)
                            let fa_rv = self.body.new_rvalue(RvalueKind.RK_AGGREGATE, 1, fa_fid, fa_disc_tag)
                            let fa_tmp = self.new_temp(fa_base_ty)
                            let fa_place = self.place_for_local(fa_tmp)
                            self.body.push_stmt(self.cur_bb, StmtKind.Assign, fa_place, fa_rv, self.ast.get_start(node))
                            return self.body.new_operand(OperandKind.OK_COPY, fa_place)
                        return self.int_const_operand(fa_disc_tag as i64, fa_base_ty)
                    // Also try bare variant sym (some enums register just "Red")
                    if self.sema.variant_lookup.contains(fa_field):
                        let fa_var_tid = self.sema.variant_type_ids.get(fa_field).unwrap()
                        if fa_var_tid == fa_resolved:
                            let fa_var_idx2 = self.sema.variant_lookup.get(fa_field).unwrap()
                            let fa_disc_tag2 = if self.sema.disc_values.contains(fa_field): self.sema.disc_values.get(fa_field).unwrap() else: fa_var_idx2
                            let fa_is_disc_enum2 = self.sema.disc_repr_types.contains(fa_resolved as i32)
                            if not fa_is_disc_enum2 or self.sema.disc_has_payload.contains(fa_resolved as i32):
                                let fa_fields2: Vec[i32] = Vec.new()
                                let fa_names2: Vec[i32] = Vec.new()
                                let fa_fid2 = self.body.new_agg_fields(fa_fields2, fa_names2)
                                let fa_rv2 = self.body.new_rvalue(RvalueKind.RK_AGGREGATE, 1, fa_fid2, fa_disc_tag2)
                                let fa_tmp2 = self.new_temp(fa_base_ty)
                                let fa_place2 = self.place_for_local(fa_tmp2)
                                self.body.push_stmt(self.cur_bb, StmtKind.Assign, fa_place2, fa_rv2, self.ast.get_start(node))
                                return self.body.new_operand(OperandKind.OK_COPY, fa_place2)
                            return self.int_const_operand(fa_disc_tag2 as i64, fa_base_ty)
        let place = self.lower_field_access(node)
        return self.body.new_operand(OperandKind.OK_COPY, place)

    if kind == NodeKind.NK_INDEX:
        let vec_ty = self.vec_literal_type(node)
        if vec_ty != 0:
            return self.lower_vec_literal(node, vec_ty)
        let place = self.lower_index(self.ast.get_data0(node), self.ast.get_data1(node))
        return self.body.new_operand(OperandKind.OK_COPY, place)

    if kind == NodeKind.NK_BLOCK:
        return self.lower_block(node)

    if kind == NodeKind.NK_LET_BINDING:
        self.lower_let_binding(node)
        return self.unit_operand()

    if kind == NodeKind.NK_LET_ELSE:
        self.lower_let_else(node)
        return self.unit_operand()

    if kind == NodeKind.NK_TUPLE_DESTRUCTURE:
        self.lower_tuple_destructure(node)
        return self.unit_operand()

    if kind == NodeKind.NK_DEFER:
        let defer_body = self.ast.get_data0(node)
        if defer_body != 0:
            self.defer_nodes.push(defer_body)
        return self.unit_operand()

    if kind == NodeKind.NK_ERRDEFER:
        let errdefer_body = self.ast.get_data0(node)
        if errdefer_body != 0:
            self.errdefer_nodes.push(errdefer_body)
        return self.unit_operand()

    if kind == NodeKind.NK_ASSIGN:
        let target = self.ast.get_data0(node)
        self.lower_assign(target, self.ast.get_data1(node))
        let target_place = self.lower_expr_place(target)
        let target_ty = self.expr_type(target)
        if self.sema.is_copy(target_ty) != 0:
            return self.body.new_operand(OperandKind.OK_COPY, target_place)
        return self.body.new_operand(OperandKind.OK_MOVE, target_place)

    if kind == NodeKind.NK_IF_EXPR:
        return self.lower_if(self.ast.get_data0(node), self.ast.get_data1(node), self.ast.get_data2(node), node)

    if kind == NodeKind.NK_WHILE:
        return self.lower_while(self.ast.get_data0(node), self.ast.get_data1(node))

    if kind == NodeKind.NK_LOOP:
        return self.lower_loop(self.ast.get_data0(node), node)

    if kind == NodeKind.NK_FOR:
        return self.lower_for(node)

    if kind == NodeKind.NK_BREAK:
        return self.lower_break(node)

    if kind == NodeKind.NK_CONTINUE:
        return self.lower_continue(node)

    if kind == NodeKind.NK_RETURN:
        return self.lower_return(node)

    if kind == NodeKind.NK_MATCH:
        return self.lower_match(self.ast.get_data0(node), self.ast.get_data1(node), self.ast.get_data2(node), node)

    if kind == NodeKind.NK_CALL:
        let callee = self.ast.get_data0(node)
        if self.ast.kind(callee) == NodeKind.NK_FIELD_ACCESS:
            // Distinguish method syntax from a callable field like
            // `ctx.memctl.free(...)`, which should lower as an indirect call.
            if self.callable_fn_type_for_expr(callee) != 0:
                return self.lower_call(callee, self.ast.get_data1(node), self.ast.get_data2(node), self.expr_type(node), node)
            return self.lower_method_call(self.ast.get_data0(callee), self.ast.get_data1(callee), self.ast.get_data1(node), self.ast.get_data2(node), node)
        var generic_builtin_sym = 0
        if self.ast.kind(callee) == NodeKind.NK_INDEX or self.ast.kind(callee) == NodeKind.NK_TYPE_GENERIC:
            let gb_base = self.ast.get_data0(callee)
            if self.ast.kind(gb_base) == NodeKind.NK_IDENT:
                let gb_sym = self.ast.get_data0(gb_base)
                let gb_name = self.pool.resolve(gb_sym)
                if gb_name == "transmute" or gb_name == "sizeof" or gb_name == "size_of" or gb_name == "alignof" or gb_name == "align_of" or gb_name == "nameof" or gb_name == "type_name" or gb_name == "chan":
                    generic_builtin_sym = gb_sym
        if generic_builtin_sym > 0:
            let gc_fn_op = self.const_operand(ConstKind.CK_FN, generic_builtin_sym, 0)
            let gc_args: Vec[i32] = Vec.new()
            let gc_as = self.ast.get_data1(node)
            let gc_ac = self.ast.get_data2(node)
            for gc_ai in 0..gc_ac:
                let gc_arg_node = self.ast.get_extra(gc_as + gc_ai)
                gc_args.push(self.lower_expr(gc_arg_node))
            let gc_args_id = self.body.new_call_args(gc_args)
            self.body.set_call_intrinsic(gc_args_id, MirIntrinsic.MIR_INTRINSIC_GENERIC_CALL)
            self.body.set_call_ast_node(gc_args_id, node)
            var gc_ret_ty = self.expr_type(node)
            if gc_ret_ty == 0:
                gc_ret_ty = self.sema.ty_i32 as i32
            let gc_result = self.new_temp(gc_ret_ty)
            let gc_place = self.place_for_local(gc_result)
            let gc_next = self.new_block()
            self.terminate(TermKind.TK_CALL, gc_fn_op, gc_args_id, gc_place, gc_next)
            self.switch_to(gc_next)
            return self.body.new_operand(OperandKind.OK_COPY, gc_place)
        // Check for enum variant constructor call: Some(v), Ok(v), Err(e), etc.
        if self.ast.kind(callee) == NodeKind.NK_IDENT:
            var vc_sym = self.ast.get_data0(callee)
            // Resolve for-comprehension _Payload marker
            if self.sema.comp_resolved.contains(node):
                vc_sym = self.sema.comp_resolved.get(node).unwrap()
            if self.sema.variant_lookup.contains(vc_sym):
                let vc_variant_idx = self.sema.variant_lookup.get(vc_sym).unwrap()
                var vc_result_ty = self.expr_type(node)
                if self.expected_type != 0:
                    vc_result_ty = self.expected_type
                if vc_result_ty == 0:
                    vc_result_ty = self.sema.variant_type_ids.get(vc_sym).unwrap()
                let vc_args_start = self.ast.get_data1(node)
                let vc_args_count = self.ast.get_data2(node)
                let vc_fields: Vec[i32] = Vec.new()
                let vc_names: Vec[i32] = Vec.new()
                for vci in 0..vc_args_count:
                    let vc_arg = self.ast.get_extra(vc_args_start + vci)
                    vc_fields.push(self.lower_expr(vc_arg))
                    vc_names.push(0)
                let vc_fid = self.body.new_agg_fields(vc_fields, vc_names)
                let vc_rv = self.body.new_rvalue(RvalueKind.RK_AGGREGATE, 1, vc_fid, vc_variant_idx)
                let vc_tmp = self.new_temp(vc_result_ty)
                let vc_place = self.place_for_local(vc_tmp)
                self.body.push_stmt(self.cur_bb, StmtKind.Assign, vc_place, vc_rv, self.ast.get_start(node))
                return self.body.new_operand(OperandKind.OK_COPY, vc_place)
        // Distinct type constructor: Meters(42) → transparent (just the inner value)
        if self.ast.kind(callee) == NodeKind.NK_IDENT:
            let dt_sym = self.ast.get_data0(callee)
            if self.sema.distinct_type_names.contains(dt_sym):
                let dt_tid = self.sema.distinct_type_names.get(dt_sym).unwrap()
                let dt_args_start = self.ast.get_data1(node)
                let dt_args_count = self.ast.get_data2(node)
                if dt_args_count == 1:
                    let dt_arg = self.ast.get_extra(dt_args_start)
                    let dt_val = self.lower_expr(dt_arg)
                    // Transparent: distinct types have same LLVM type as inner,
                    // so the constructor is just the inner value itself
                    return dt_val
        // Callable type syntax: TypeName(args) → TypeName.new(args)
        if self.ast.kind(callee) == NodeKind.NK_IDENT:
            let ct_sym = self.ast.get_data0(callee)
            if self.sema.type_decl_nodes.contains(ct_sym):
                let ct_new_name = self.pool.resolve(ct_sym) ++ ".new"
                let ct_new_sym = self.pool.intern(ct_new_name)
                let ct_new_sig = self.sema.get_sig(ct_new_sym)
                if ct_new_sig >= 0:
                    let ct_fn_op = self.const_operand(ConstKind.CK_FN, ct_new_sym, 0)
                    let ct_ret_ty = self.expr_type(node)
                    return self.lower_call_redirected(ct_fn_op, ct_new_sym, self.ast.get_data1(node), self.ast.get_data2(node), ct_ret_ty, node)
        // Generic function call — delegate to codegen's monomorphize_generic_call
        if self.ast.kind(callee) == NodeKind.NK_IDENT:
            let gc_sym = self.ast.get_data0(callee)
            if self.sema.generic_fn_nodes.contains(gc_sym):
                // Lower args and emit call. Codegen intercepts via MirIntrinsic.MIR_INTRINSIC_GENERIC_CALL
                // and routes to monomorphize_generic_call_core with pre-evaluated MIR args.
                let gc_fn_op = self.const_operand(ConstKind.CK_FN, gc_sym, 0)
                let gc_args: Vec[i32] = Vec.new()
                let gc_as = self.ast.get_data1(node)
                let gc_ac = self.ast.get_data2(node)
                for gc_ai in 0..gc_ac:
                    let gc_arg_node = self.ast.get_extra(gc_as + gc_ai)
                    gc_args.push(self.lower_expr(gc_arg_node))
                let gc_args_id = self.body.new_call_args(gc_args)
                self.body.set_call_intrinsic(gc_args_id, MirIntrinsic.MIR_INTRINSIC_GENERIC_CALL)
                self.body.set_call_ast_node(gc_args_id, node)
                var gc_ret_ty = self.expr_type(node)
                if gc_ret_ty == 0:
                    gc_ret_ty = self.sema.ty_i32 as i32
                let gc_result = self.new_temp(gc_ret_ty)
                let gc_place = self.place_for_local(gc_result)
                let gc_next = self.new_block()
                self.terminate(TermKind.TK_CALL, gc_fn_op, gc_args_id, gc_place, gc_next)
                self.switch_to(gc_next)
                return self.body.new_operand(OperandKind.OK_COPY, gc_place)
        // Check for builtin calls (embed_file, src, etc.) — no sig, not a local
        if self.ast.kind(callee) == NodeKind.NK_IDENT:
            let bu_sym = self.ast.get_data0(callee)
            let bu_sig = self.sema.get_sig(bu_sym)
            let bu_local = self.lookup_local(bu_sym)
            if bu_sig < 0 and bu_local < 0:
                // Unresolved bare function — route through gen_call
                let bu_fn_op = self.const_operand(ConstKind.CK_FN, bu_sym, 0)
                let bu_args: Vec[i32] = Vec.new()
                let bu_args_id = self.body.new_call_args(bu_args)
                self.body.set_call_intrinsic(bu_args_id, MirIntrinsic.MIR_INTRINSIC_GENERIC_CALL)
                self.body.set_call_ast_node(bu_args_id, node)
                var bu_ret_ty = self.expr_type(node)
                if bu_ret_ty == 0:
                    bu_ret_ty = self.sema.ty_i32 as i32
                let bu_result = self.new_temp(bu_ret_ty)
                let bu_place = self.place_for_local(bu_result)
                let bu_next = self.new_block()
                self.terminate(TermKind.TK_CALL, bu_fn_op, bu_args_id, bu_place, bu_next)
                self.switch_to(bu_next)
                return self.body.new_operand(OperandKind.OK_COPY, bu_place)
        // Intrinsic free functions: fence(order)
        if self.ast.kind(callee) == NodeKind.NK_IDENT:
            let ifn_sym = self.ast.get_data0(callee)
            let ifn_name = self.pool.resolve(ifn_sym)
            if ifn_name == "fence":
                let ifn_args: Vec[i32] = Vec.new()
                let ifn_as = self.ast.get_data1(node)
                let ifn_ac = self.ast.get_data2(node)
                for ifn_ai in 0..ifn_ac:
                    ifn_args.push(self.lower_expr(self.ast.get_extra(ifn_as + ifn_ai)))
                let ifn_args_id = self.body.new_call_args(ifn_args)
                self.body.set_call_intrinsic(ifn_args_id, MirIntrinsic.MIR_INTRINSIC_ATOMIC_FENCE)
                let ifn_callee = self.unit_operand()
                let ifn_result = self.new_temp(self.sema.ty_void as i32)
                let ifn_place = self.place_for_local(ifn_result)
                let ifn_next = self.new_block()
                self.terminate(TermKind.TK_CALL, ifn_callee, ifn_args_id, ifn_place, ifn_next)
                self.switch_to(ifn_next)
                return self.unit_operand()
        return self.lower_call(callee, self.ast.get_data1(node), self.ast.get_data2(node), self.expr_type(node), node)

    if kind == NodeKind.NK_PIPELINE:
        let rhs = self.ast.get_data1(node)
        if self.ast.kind(rhs) == NodeKind.NK_CALL:
            return self.lower_pipeline(self.ast.get_data0(node), self.ast.get_data0(rhs), self.ast.get_data1(rhs), self.ast.get_data2(rhs), node)
        return self.lower_pipeline(self.ast.get_data0(node), rhs, 0, 0, node)

    if kind == NodeKind.NK_WITH_EXPR:
        let source = self.ast.get_data0(node)
        let body = self.ast.get_data1(node)
        let name = decode_with_binding_sym(self.ast.get_data2(node))
        if name != 0:
            return self.lower_with_binding(name, source, body, self.ast.get_start(node))
        return self.lower_with_form1(source, body)

    if kind == NodeKind.NK_WITH_IMPLICIT:
        let wi_source = self.ast.get_data0(node)
        let wi_body = self.ast.get_data1(node)
        let wi_name = self.ast.get_data2(node)
        return self.lower_with_binding(wi_name, wi_source, wi_body, self.ast.get_start(node))

    if kind == NodeKind.NK_STRUCT_LIT:
        let sl_fields_start = self.ast.get_data1(node)
        let sl_field_count = self.ast.get_data2(node)
        let sl_name_sym = self.ast.get_data0(node)
        let sl_struct_ty = self.expr_type(node)
        let sl_fields: Vec[i32] = Vec.new()
        let sl_names: Vec[i32] = Vec.new()
        for i in 0..sl_field_count:
            let f_name_sym = self.ast.get_extra(sl_fields_start + i * 2)
            let f_val_node = self.ast.get_extra(sl_fields_start + i * 2 + 1)
            let saved_expected = self.expected_type
            let f_ty = self.struct_field_type(sl_struct_ty, f_name_sym)
            if f_ty != 0:
                self.expected_type = f_ty
            sl_fields.push(self.lower_expr(f_val_node))
            sl_names.push(f_name_sym)
            self.expected_type = saved_expected
        let sl_fid = self.body.new_agg_fields(sl_fields, sl_names)
        let sl_rv = self.body.new_rvalue(RvalueKind.RK_AGGREGATE, 0, sl_fid, 0)
        var sl_ty = self.expr_type(node)
        if (sl_ty == 0 or sl_ty == self.sema.ty_void) and self.expected_type > 0:
            sl_ty = self.expected_type
        let sl_tmp = self.new_temp(sl_ty)
        let sl_place = self.place_for_local(sl_tmp)
        self.body.push_stmt(self.cur_bb, StmtKind.Assign, sl_place, sl_rv, self.ast.get_start(node))
        return self.body.new_operand(OperandKind.OK_COPY, sl_place)

    if kind == NodeKind.NK_RECORD_UPDATE:
        return self.lower_record_update(self.ast.get_data0(node), self.ast.get_data1(node), self.ast.get_data2(node), node)

    if kind == NodeKind.NK_RANGE:
        let range_start_node = self.ast.get_data0(node)
        let range_end_node = self.ast.get_data1(node)
        let range_inclusive = self.ast.get_data2(node)
        var range_elem = self.sema.ty_i32 as i32
        if range_start_node != 0:
            range_elem = self.expr_type(range_start_node)
        else if range_end_node != 0:
            range_elem = self.expr_type(range_end_node)
        let start_op = if range_start_node != 0: self.lower_expr(range_start_node) else: self.int_const_operand(0, range_elem)
        let end_op = self.lower_expr(range_end_node)
        let incl_op = self.int_const_operand(range_inclusive, self.sema.ty_bool)
        let range_fields: Vec[i32] = Vec.new()
        let range_names: Vec[i32] = Vec.new()
        range_fields.push(start_op)
        range_fields.push(end_op)
        range_fields.push(incl_op)
        range_names.push(0)
        range_names.push(0)
        range_names.push(0)
        let range_fid = self.body.new_agg_fields(range_fields, range_names)
        let range_rv = self.body.new_rvalue(RvalueKind.RK_AGGREGATE, 0, range_fid, 0)
        let range_ty = self.expr_type(node)
        let range_tmp = self.new_temp(range_ty)
        let range_place = self.place_for_local(range_tmp)
        self.body.push_stmt(self.cur_bb, StmtKind.Assign, range_place, range_rv, self.ast.get_start(node))
        return self.body.new_operand(OperandKind.OK_COPY, range_place)

    if kind == NodeKind.NK_TUPLE:
        let extra_start = self.ast.get_data0(node)
        let elem_count = self.ast.get_data1(node)
        let tup_fields: Vec[i32] = Vec.new()
        let tup_names: Vec[i32] = Vec.new()
        let saved_expected = self.expected_type
        var expected_tuple = 0
        var expected_elem_start = 0
        if saved_expected > 0:
            let expected_resolved = self.sema.resolve_alias(saved_expected)
            if self.sema.get_type_kind(expected_resolved) == TypeKind.TY_TUPLE and self.sema.get_type_d1(expected_resolved) == elem_count:
                expected_tuple = expected_resolved as i32
                expected_elem_start = self.sema.get_type_d0(expected_resolved)
        for i in 0..elem_count:
            let elem_node = self.ast.get_extra(extra_start + i)
            if expected_tuple != 0:
                self.expected_type = self.sema.type_extra.get((expected_elem_start + i) as i64)
            tup_fields.push(self.lower_expr(elem_node))
            self.expected_type = saved_expected
            tup_names.push(0)
        let tup_fid = self.body.new_agg_fields(tup_fields, tup_names)
        let tup_rv = self.body.new_rvalue(RvalueKind.RK_AGGREGATE, 0, tup_fid, 0)
        let tup_ty = self.expr_type(node)
        let tup_tmp = self.new_temp(tup_ty)
        let tup_place = self.place_for_local(tup_tmp)
        self.body.push_stmt(self.cur_bb, StmtKind.Assign, tup_place, tup_rv, self.ast.get_start(node))
        return self.body.new_operand(OperandKind.OK_COPY, tup_place)

    if kind == NodeKind.NK_ARRAY_LIT:
        let extra_start = self.ast.get_data0(node)
        let elem_count = self.ast.get_data1(node)
        let arr_fields: Vec[i32] = Vec.new()
        let arr_names: Vec[i32] = Vec.new()
        for i in 0..elem_count:
            let elem_node = self.ast.get_extra(extra_start + i)
            arr_fields.push(self.lower_expr(elem_node))
            arr_names.push(0)
        let arr_fid = self.body.new_agg_fields(arr_fields, arr_names)
        let arr_rv = self.body.new_rvalue(RvalueKind.RK_AGGREGATE, 0, arr_fid, 0)
        let arr_ty = self.expr_type(node)
        let arr_tmp = self.new_temp(arr_ty)
        let arr_place = self.place_for_local(arr_tmp)
        self.body.push_stmt(self.cur_bb, StmtKind.Assign, arr_place, arr_rv, self.ast.get_start(node))
        return self.body.new_operand(OperandKind.OK_COPY, arr_place)

    if kind == NodeKind.NK_VARIANT_SHORTHAND:
        let vs_name_sym = self.resolve_variant_sym(node)
        let vs_args_start = self.ast.get_data1(node)
        let vs_arg_count = self.ast.get_data2(node)
        let vs_variant_idx = self.variant_index(vs_name_sym)
        let vs_result_ty = self.expr_type(node)
        // Plain enums are always lowered as full aggregate values.
        // Only payloadless discriminant enums lower to their repr integer.
        if self.sema.variant_lookup.contains(vs_name_sym):
            if self.sema.disc_values.contains(vs_name_sym):
                let vs_disc_val = self.sema.disc_values.get(vs_name_sym).unwrap()
                if vs_arg_count == 0:
                    let vs_resolved = self.sema.resolve_alias(vs_result_ty)
                    let vs_is_disc_enum = self.sema.disc_repr_types.contains(vs_resolved as i32)
                    if not vs_is_disc_enum or self.sema.disc_has_payload.contains(vs_resolved as i32):
                        let vs_de_fields: Vec[i32] = Vec.new()
                        let vs_de_names: Vec[i32] = Vec.new()
                        let vs_de_fid = self.body.new_agg_fields(vs_de_fields, vs_de_names)
                        let vs_de_rv = self.body.new_rvalue(RvalueKind.RK_AGGREGATE, 1, vs_de_fid, vs_disc_val)
                        let vs_de_tmp = self.new_temp(vs_result_ty)
                        let vs_de_place = self.place_for_local(vs_de_tmp)
                        self.body.push_stmt(self.cur_bb, StmtKind.Assign, vs_de_place, vs_de_rv, self.ast.get_start(node))
                        return self.body.new_operand(OperandKind.OK_COPY, vs_de_place)
                    return self.int_const_operand(vs_disc_val, vs_result_ty)
        let vs_fields: Vec[i32] = Vec.new()
        let vs_names: Vec[i32] = Vec.new()
        for vsi in 0..vs_arg_count:
            let vs_arg = self.ast.get_extra(vs_args_start + vsi)
            vs_fields.push(self.lower_expr(vs_arg))
            vs_names.push(0)
        let vs_fid = self.body.new_agg_fields(vs_fields, vs_names)
        let vs_rv = self.body.new_rvalue(RvalueKind.RK_AGGREGATE, 1, vs_fid, vs_variant_idx)
        let vs_tmp = self.new_temp(vs_result_ty)
        let vs_place = self.place_for_local(vs_tmp)
        self.body.push_stmt(self.cur_bb, StmtKind.Assign, vs_place, vs_rv, self.ast.get_start(node))
        return self.body.new_operand(OperandKind.OK_COPY, vs_place)

    if kind == NodeKind.NK_CLOSURE:
        return self.lower_closure(0, 0, self.ast.get_data1(node), self.ast.get_data2(node), node)

    if kind == NodeKind.NK_GROUPED:
        return self.lower_expr(self.ast.get_data0(node))

    if kind == NodeKind.NK_OPTIONAL_CHAIN:
        return self.lower_optional_chain(node)

    if kind == NodeKind.NK_COMPTIME:
        // Comptime branches are already pruned by ComptimeTransform.
        // Just unwrap and lower the inner expression.
        let inner = self.ast.get_data0(node)
        if inner != 0:
            return self.lower_expr(inner)
        return self.unit_operand()

    // spawn expr → evaluate (the async fn call already spawns a fiber),
    // then discard the Task handle (fire-and-forget)
    if kind == NodeKind.NK_SPAWN:
        let inner = self.ast.get_data0(node)
        let _ = self.lower_expr(inner)
        return self.unit_operand()

    // expr.await → suspend until fiber completes, check cancellation,
    // emit unwind path with defers if cancelled, return result
    //
    // lower_single_await: await one Task, with cancellation checks + unwind.
    // Used by both single await and tuple await (called N times for tuple).
    // Defined inline as a nested scope to keep it near the NK_AWAIT handler.

    if kind == NodeKind.NK_AWAIT:
        let inner = self.ast.get_data0(node)

        // Tuple await: (t1, t2, ...).await → await each, build result tuple
        if self.ast.kind(inner) == NodeKind.NK_TUPLE:
            let ta_extra = self.ast.get_data0(inner)
            let ta_count = self.ast.get_data1(inner)
            let ta_result_ty = self.expr_type(node)
            // Lower all task expressions first (spawns all fibers)
            var ta_task_ops: Vec[i32] = Vec.new()
            for ta_i in 0..ta_count:
                let ta_elem = self.ast.get_extra(ta_extra + ta_i)
                ta_task_ops.push(self.lower_expr(ta_elem))
            // Await each sequentially, collect results
            var ta_awaited_ops: Vec[i32] = Vec.new()
            var ta_awaited_names: Vec[i32] = Vec.new()
            for ta_i in 0..ta_count:
                let ta_elem_ty = self.tuple_elem_type(ta_result_ty, ta_i)
                let ta_elem_node = self.ast.get_extra(ta_extra + ta_i)
                let ta_task_ty = self.expr_type(ta_elem_node)
                let ta_op = self.lower_single_await(ta_task_ops.get(ta_i as i64), ta_elem_ty, ta_task_ty, node)
                ta_awaited_ops.push(ta_op)
                ta_awaited_names.push(0)
            // Build result tuple via RK_AGGREGATE
            let ta_agg_id = self.body.new_agg_fields(ta_awaited_ops, ta_awaited_names)
            let ta_agg_rv = self.body.new_rvalue(RvalueKind.RK_AGGREGATE, 0, ta_agg_id, 0)
            let ta_tmp = self.new_temp(ta_result_ty)
            let ta_place = self.place_for_local(ta_tmp)
            self.body.push_stmt(self.cur_bb, StmtKind.Assign, ta_place, ta_agg_rv, self.ast.get_start(node))
            return self.body.new_operand(OperandKind.OK_COPY, ta_place)

        // Single task await
        let task_op = self.lower_expr(inner)
        let result_ty = self.expr_type(node)
        let task_inner_ty = self.expr_type(inner)
        return self.lower_single_await(task_op, result_ty, task_inner_ty, node)

    // yield expr → for now, just evaluate the expression (state machine transform is future work)
    if kind == NodeKind.NK_YIELD:
        let inner = self.ast.get_data0(node)
        if inner != 0:
            return self.lower_expr(inner)
        return self.unit_operand()

    if kind == NodeKind.NK_ASYNC_SCOPE:
        // async scope: d0=name(sym), d1=body(node)
        // 1. Create scope handle via with_scope_create()
        let scope_sym = self.ast.get_data0(node)
        let span = self.ast.get_start(node)
        let create_args: Vec[i32] = Vec.new()
        let create_call_id = self.body.new_call_args(create_args)
        self.body.set_call_intrinsic(create_call_id, MirIntrinsic.MIR_INTRINSIC_SCOPE_CREATE)
        self.body.set_call_ast_node(create_call_id, node)
        let scope_local = self.new_temp(self.sema.ty_i64)
        let scope_place = self.place_for_local(scope_local)
        let after_create_bb = self.new_block()
        self.terminate(TermKind.TK_CALL, self.unit_operand(), create_call_id, scope_place, after_create_bb)
        self.switch_to(after_create_bb)
        // Bind scope handle to scope variable name
        if scope_sym > 0:
            let bind_local = self.body.new_local(self.sema.ty_i64 as i32, 0, scope_sym, 1)
            self.bind_local(scope_sym, bind_local)
            let bind_place = self.place_for_local(bind_local)
            let scope_op = self.body.new_operand(OperandKind.OK_COPY, scope_place)
            self.assign_operand_to_place(bind_place, scope_op, span)
        // 2. Execute scope body (s.track() calls resolve via existing codegen path)
        let scope_body = self.ast.get_data1(node)
        var body_result = self.unit_operand()
        if scope_body != 0:
            body_result = self.lower_expr(scope_body)
        // 3. Await all tracked tasks: with_scope_await_all(handle)
        let await_all_args: Vec[i32] = Vec.new()
        await_all_args.push(self.body.new_operand(OperandKind.OK_COPY, scope_place))
        let await_all_call_id = self.body.new_call_args(await_all_args)
        self.body.set_call_intrinsic(await_all_call_id, MirIntrinsic.MIR_INTRINSIC_SCOPE_AWAIT_ALL)
        self.body.set_call_ast_node(await_all_call_id, node)
        let await_all_result = self.new_temp(0)
        let await_all_place = self.place_for_local(await_all_result)
        let after_await_all_bb = self.new_block()
        self.terminate(TermKind.TK_CALL, self.unit_operand(), await_all_call_id, await_all_place, after_await_all_bb)
        self.switch_to(after_await_all_bb)
        // 4. Destroy scope: with_scope_destroy(handle)
        let destroy_args: Vec[i32] = Vec.new()
        destroy_args.push(self.body.new_operand(OperandKind.OK_COPY, scope_place))
        let destroy_call_id = self.body.new_call_args(destroy_args)
        self.body.set_call_intrinsic(destroy_call_id, MirIntrinsic.MIR_INTRINSIC_SCOPE_DESTROY)
        self.body.set_call_ast_node(destroy_call_id, node)
        let destroy_result = self.new_temp(0)
        let destroy_place = self.place_for_local(destroy_result)
        let after_destroy_bb = self.new_block()
        self.terminate(TermKind.TK_CALL, self.unit_operand(), destroy_call_id, destroy_place, after_destroy_bb)
        self.switch_to(after_destroy_bb)
        return body_result

    if kind == NodeKind.NK_ASYNC_BLOCK:
        // Emit CK_ASYNC_BLOCK constant — codegen handles the fiber spawn.
        // Same pattern as CK_CLOSURE: MIR just creates a marker, codegen
        // creates the anonymous function, collects captures, and spawns.
        let ab_ty = self.expr_type(node)
        if ab_ty == 0:
            return self.unit_operand()
        let ab_tmp = self.new_temp(ab_ty)
        let ab_place = self.place_for_local(ab_tmp)
        let ab_const = self.body.new_const(ConstKind.CK_ASYNC_BLOCK, node, 0, 0, ab_ty)
        let ab_op = self.body.new_operand(OperandKind.OK_CONSTANT, ab_const)
        let ab_rv = self.body.new_rvalue(RvalueKind.RK_USE, ab_op, 0, 0)
        self.body.push_stmt(self.cur_bb, StmtKind.Assign, ab_place, ab_rv, self.ast.get_start(node))
        return self.body.new_operand(OperandKind.OK_COPY, ab_place)

    if kind == NodeKind.NK_SELECT_AWAIT:
        let extra_start = self.ast.get_data0(node)
        let arm_count = self.ast.get_data1(node)
        if arm_count <= 0:
            return self.unit_operand()
        let span = self.ast.get_start(node)

        // 1. Lower each arm's task expression → task operands
        var task_ops: Vec[i32] = Vec.new()
        for ai in 0..arm_count:
            let task_node = self.ast.get_extra(extra_start + ai * 3 + 1)
            let task_op = self.lower_expr(task_node)
            task_ops.push(task_op)

        // 2. Emit select intrinsic call: passes all task operands, returns winner index
        let select_args: Vec[i32] = Vec.new()
        for ai in 0..arm_count:
            select_args.push(task_ops.get(ai as i64))
        let select_call_id = self.body.new_call_args(select_args)
        self.body.set_call_intrinsic(select_call_id, MirIntrinsic.MIR_INTRINSIC_FIBER_SELECT)
        self.body.set_call_ast_node(select_call_id, node)
        let select_result_local = self.new_temp(self.sema.ty_i32)
        let select_result_place = self.place_for_local(select_result_local)
        let switch_bb = self.new_block()
        self.terminate(TermKind.TK_CALL, self.unit_operand(), select_call_id, select_result_place, switch_bb)
        self.switch_to(switch_bb)

        // 3. Create basic blocks for each arm + join
        var arm_bbs: Vec[i32] = Vec.new()
        var switch_vals: Vec[i32] = Vec.new()
        for ai in 0..arm_count:
            let arm_bb = self.new_block()
            arm_bbs.push(arm_bb)
            switch_vals.push(ai)
        let join_bb = self.new_block()
        let select_expr_type = self.expr_type(node)
        let result_local = self.new_temp(select_expr_type)
        let result_place = self.place_for_local(result_local)

        // 4. Switch on winner index
        let switch_op = self.body.new_operand(OperandKind.OK_COPY, select_result_place)
        let switch_table = self.body.new_switch_table(switch_vals, arm_bbs)
        self.terminate(TermKind.TK_SWITCH_INT, switch_op, switch_table, join_bb, 0)

        // 5. Each arm: await winner, cancel losers, execute body
        for ai in 0..arm_count:
            self.switch_to(arm_bbs.get(ai as i64) as i32)
            let arm_name = self.ast.get_extra(extra_start + ai * 3)
            let arm_body = self.ast.get_extra(extra_start + ai * 3 + 2)

            // Await the winning task to get its result
            let await_args: Vec[i32] = Vec.new()
            await_args.push(task_ops.get(ai as i64))
            let await_call_id = self.body.new_call_args(await_args)
            self.body.set_call_intrinsic(await_call_id, MirIntrinsic.MIR_INTRINSIC_FIBER_AWAIT)
            self.body.set_call_ast_node(await_call_id, node)
            let await_result_ty = self.expr_type(node)
            let await_result_local = self.new_temp(await_result_ty)
            let await_result_place = self.place_for_local(await_result_local)
            let after_await_bb = self.new_block()
            self.terminate(TermKind.TK_CALL, self.unit_operand(), await_call_id, await_result_place, after_await_bb)
            self.switch_to(after_await_bb)

            // Bind result to arm variable
            let bind_local = self.body.new_local(await_result_ty, 0, arm_name, 1)
            self.bind_local(arm_name, bind_local)
            let bind_place = self.place_for_local(bind_local)
            let await_result_op = self.body.new_operand(OperandKind.OK_COPY, await_result_place)
            self.assign_operand_to_place(bind_place, await_result_op, span)

            // Cancel losing tasks
            for li in 0..arm_count:
                if li != ai:
                    let cancel_args: Vec[i32] = Vec.new()
                    let loser_task = task_ops.get(li as i64)
                    cancel_args.push(loser_task)
                    let cancel_call_id = self.body.new_call_args(cancel_args)
                    self.body.set_call_intrinsic(cancel_call_id, MirIntrinsic.MIR_INTRINSIC_FIBER_CANCEL)
                    self.body.set_call_ast_node(cancel_call_id, node)
                    let cancel_result_local = self.new_temp(self.sema.ty_i32)
                    let cancel_result_place = self.place_for_local(cancel_result_local)
                    let after_cancel_bb = self.new_block()
                    self.terminate(TermKind.TK_CALL, self.unit_operand(), cancel_call_id, cancel_result_place, after_cancel_bb)
                    self.switch_to(after_cancel_bb)
                    self.lower_cleanup_await(loser_task, node)

            // Execute arm body
            let body_op = self.lower_expr(arm_body)

            // Store body result and branch to join
            self.assign_operand_to_place(result_place, body_op, span)
            self.terminate(TermKind.TK_GOTO, join_bb, 0, 0, 0)

        self.switch_to(join_bb)
        return self.body.new_operand(OperandKind.OK_COPY, result_place)

    self.mark_unsupported()
    self.unit_operand()

fn lower_fn(builder: MirBuilder, fn_node: i32) -> MirBody:
    let fn_sym = builder.ast.get_data0(fn_node)
    var sig_idx = builder.sema.get_sig(fn_sym)
    // If sig not found, try translating fn_sym from AST pool to sema pool.
    // Sema registers sigs under sema pool symbols, not AST pool symbols.
    if sig_idx < 0:
        let sema_fn_sym = builder.sema.pool_lookup_symbol(builder.pool.resolve_symbol(fn_sym))
        sig_idx = builder.sema.get_sig(sema_fn_sym)
    // Also try method lookup for methods: "Type.method" → fn_sym for (type_sym, method_sym)
    if sig_idx < 0:
        let fn_name = builder.pool.resolve_symbol(fn_sym)
        // Split "Type.method" on the dot
        var dot_pos = -1
        for ci in 0..fn_name.len() as i32:
            if fn_name.byte_at(ci as i64) == 46:
                dot_pos = ci
                break
        if dot_pos > 0:
            let type_part = fn_name.slice(0, dot_pos as i64)
            let method_part = fn_name.slice((dot_pos + 1) as i64, fn_name.len())
            let sema_type_sym = builder.sema.pool_lookup_symbol(type_part)
            let sema_method_sym = builder.sema.pool_lookup_symbol(method_part)
            sig_idx = builder.sema.lookup_method_sig(sema_type_sym, sema_method_sym)
    lower_fn_with_sig(builder, fn_node, sig_idx)

fn lower_fn_with_sig(builder: MirBuilder, fn_node: i32, sig_idx: i32) -> MirBody:
    let fn_flags = builder.ast.get_data2(fn_node)
    if sig_idx >= 0:
        var body_ret_ty = builder.sema.sig_return_type(sig_idx)
        if (fn_flags / FnFlags.ASYNC) % 2 == 1:
            body_ret_ty = builder.sema.unwrap_task_type(body_ret_ty as TypeId) as i32
        builder.body.local_type_ids.set_i32(0, body_ret_ty)
    else:
        // No sig — try to get return type from typed_expr_types on body expression
        let body_expr = builder.ast.get_data1(fn_node)
        let ret_ty = builder.expr_type(body_expr)
        if ret_ty != 0 and ret_ty != builder.sema.ty_void:
            builder.body.local_type_ids.set_i32(0, ret_ty)
        else:
            builder.body.local_type_ids.set_i32(0, builder.sema.ty_void)

    builder.push_scope()

    // Parameters: locals 1..n
    let meta = builder.ast.find_fn_meta(fn_node)
    if meta >= 0:
        let param_start = builder.ast.fn_meta_param_start(meta)
        let param_count = builder.ast.fn_meta_param_count(meta)

        for i in 0..param_count:
            let p_name = builder.ast.fn_param_name(param_start, i)
            var p_ty = 0
            if sig_idx >= 0:
                p_ty = builder.sema.sig_param_type(sig_idx, i)
            else:
                // No sig — resolve param type from type annotation AST node
                let p_type_node = builder.ast.fn_param_type(param_start, i)
                if p_type_node > 0:
                    p_ty = builder.expr_type(p_type_node)
                if p_ty == 0:
                    p_ty = builder.sema.ty_i32 as i32
            let local_id = builder.body.new_local(p_ty, 0, p_name, 1)
            builder.bind_local(p_name, local_id)
            builder.body.push_stmt(builder.cur_bb, StmtKind.StorageLive, local_id, 0, builder.ast.get_start(fn_node))
            if builder.sema.is_copy(p_ty) == 0:
                builder.schedule_drop(local_id, DropKind.DK_VALUE)
        builder.body.n_params = param_count

    // Set expected_type to the function's return type so that intrinsic calls
    // (Vec.new, HashMap.new) in tail position can resolve their generic inst type.
    let ret_ty = builder.body.local_type_ids.get(0)
    builder.expected_type = ret_ty

    let body_expr = builder.ast.get_data1(fn_node)
    var result = builder.lower_expr(body_expr)

    // Implicit Ok wrapping: if return type is Result[T, E] and body type is T,
    // wrap the result in Ok(value) — an enum variant construction with tag 0.
    let ret_resolved = builder.sema.resolve_alias(ret_ty)
    if builder.sema.get_type_kind(ret_resolved) == TypeKind.TY_GENERIC_INST:
        let ret_base = builder.sema.get_generic_inst_base(ret_resolved)
        if builder.sema.pool_resolve(ret_base) == "Result" and builder.sema.get_generic_inst_arg_count(ret_resolved) == 2:
            let body_ty = builder.expr_type(body_expr)
            let ok_type = builder.sema.get_generic_inst_arg(ret_resolved, 0)
            if body_ty != 0 and body_ty != ret_ty:
                if builder.sema.types_compatible(ok_type, body_ty) != 0 or builder.sema.arithmetic_result_type(ok_type, body_ty) != 0:
                    // Wrap in Ok variant (tag=0)
                    let ok_fields: Vec[i32] = Vec.new()
                    let ok_names: Vec[i32] = Vec.new()
                    ok_fields.push(result)
                    ok_names.push(0)
                    let ok_fid = builder.body.new_agg_fields(ok_fields, ok_names)
                    let ok_rv = builder.body.new_rvalue(RvalueKind.RK_AGGREGATE, 1, ok_fid, 0)
                    let ok_tmp = builder.new_temp(ret_ty)
                    let ok_place = builder.place_for_local(ok_tmp)
                    builder.body.push_stmt(builder.cur_bb, StmtKind.Assign, ok_place, ok_rv, builder.ast.get_end(fn_node))
                    result = builder.body.new_operand(OperandKind.OK_COPY, ok_place)

    // Implicit return value assignment for non-diverging tail expressions.
    let ret_place = builder.place_for_local(0)
    builder.assign_operand_to_place(ret_place, result, builder.ast.get_end(fn_node))

    builder.emit_defers_for_return()
    builder.pop_scope_inline()
    builder.terminate(TermKind.TK_RETURN, 0, 0, 0, 0)

    // Self-tail-call optimization for @[tailrec] functions.
    if (fn_flags / FnFlags.TAILREC) % 2 == 1:
        optimize_self_tail_calls(&mut builder.body)

    builder.body

fn optimize_self_tail_calls(body: &mut MirBody):
    let fn_sym = body.fn_sym
    if fn_sym == 0 or body.n_params == 0:
        return
    let bb_count = body.block_count()
    var bb = 0
    while bb < bb_count:
        if body.term_kind(bb) != TermKind.TK_CALL:
            bb = bb + 1
            continue
        let callee_op_id = body.term_data0(bb)
        let args_id = body.term_data1(bb)
        let result_place = body.term_data2(bb)
        let next_bb = body.term_data3(bb)
        // Check: callee is this function
        if callee_op_id < 0 or callee_op_id >= body.operand_kinds.len() as i32:
            bb = bb + 1
            continue
        let op_kind = body.operand_kinds.get(callee_op_id as i64)
        if op_kind != OperandKind.OK_CONSTANT:
            bb = bb + 1
            continue
        let const_id = body.operand_d0.get(callee_op_id as i64)
        if const_id < 0 or const_id >= body.const_kinds.len() as i32:
            bb = bb + 1
            continue
        if body.const_kinds.get(const_id as i64) != ConstKind.CK_FN:
            bb = bb + 1
            continue
        if body.const_d0.get(const_id as i64) != fn_sym:
            bb = bb + 1
            continue
        // Check: result goes to local 0 (return place)
        if result_place >= 0 and result_place < body.place_locals.len() as i32:
            if body.place_locals.get(result_place as i64) != 0:
                bb = bb + 1
                continue
        // Check: next block is pure TK_RETURN (no statements)
        if next_bb < 0 or next_bb >= bb_count:
            bb = bb + 1
            continue
        if body.term_kind(next_bb) != TermKind.TK_RETURN:
            bb = bb + 1
            continue
        if body.bb_stmt_counts.get(next_bb as i64) != 0:
            bb = bb + 1
            continue
        // This is a self-tail-call. Transform it.
        // Step 1: Read call args into temp locals (aliasing safety)
        let arg_start = body.call_arg_starts.get(args_id as i64)
        let arg_count = body.call_arg_counts.get(args_id as i64)
        let n_params = body.n_params
        let span = body.bb_term_spans.get(bb as i64)
        // Copy args to temps
        for ai in 0..arg_count:
            if ai >= n_params: break
            let arg_op = body.call_arg_operands.get((arg_start + ai) as i64)
            let param_local = ai + 1  // params are locals 1..n_params
            let param_ty = body.local_type_ids.get(param_local as i64)
            let tmp = body.new_temp(param_ty)
            let tmp_place = body.new_place(tmp)
            let rv = body.new_rvalue(RvalueKind.RK_USE, arg_op, 0, 0)
            body.push_stmt(bb, StmtKind.Assign, tmp_place, rv, span)
        // Copy temps back to params
        // We pushed n temps starting at (local_count - n_params) before temps were added
        let first_tmp = body.local_type_ids.len() as i32 - arg_count
        for ai in 0..arg_count:
            if ai >= n_params: break
            let tmp_local = first_tmp + ai
            let param_local = ai + 1
            let param_place = body.new_place(param_local)
            let tmp_place_read = body.new_place(tmp_local)
            let tmp_op = body.new_operand(OperandKind.OK_COPY, tmp_place_read)
            let rv = body.new_rvalue(RvalueKind.RK_USE, tmp_op, 0, 0)
            body.push_stmt(bb, StmtKind.Assign, param_place, rv, span)
        // Replace terminator with GOTO to entry block (bb0)
        body.set_terminator(bb, TermKind.TK_GOTO, 0, 0, 0, 0, span)
        bb = bb + 1

fn lower_module(sema: Sema, ast_pool: AstPool, pool: InternPool) -> MirModule:
    var mir_mod = MirModule.init()
    // Snapshot sema type tables before any MirBuilder copy can realloc/free the buffer
    mir_mod.snapshot_sema_types(sema)

    // Collect @[tailrec] function symbols for mutual TCO detection
    let tailrec_syms: Vec[i32] = Vec.new()

    for di in 0..ast_pool.decl_count():
        let decl = ast_pool.get_decl(di)
        if ast_pool.kind(decl) != NodeKind.NK_FN_DECL:
            continue

        let fn_sym = ast_pool.get_data0(decl)
        let meta = ast_pool.find_fn_meta(decl)
        if meta >= 0 and ast_pool.fn_meta_tp_count(meta) > 0:
            continue

        let fn_flags = ast_pool.get_data2(decl)
        if (fn_flags / FnFlags.TAILREC) % 2 == 1:
            tailrec_syms.push(fn_sym)

        var builder = MirBuilder.init(sema, ast_pool, pool, fn_sym)
        let body = lower_fn(builder, decl as i32)
        mir_mod.add_body(body)

    // Mutual tail-call optimization: for @[tailrec] functions that call
    // other @[tailrec] functions in tail position, transform mutual
    // tail calls into parameter reassignment + tag dispatch (trampoline).
    if tailrec_syms.len() > 1:
        optimize_mutual_tail_calls(&mut mir_mod, tailrec_syms)

    mir_mod

// ── Mutual tail-call optimization ──────────────────────────────

fn mir_body_extract_callee_sym(body: &MirBody, callee_op_id: i32) -> i32:
    // Extract function symbol from a TK_CALL terminator's callee operand.
    if callee_op_id < 0 or callee_op_id >= body.operand_kinds.len() as i32:
        return 0
    if body.operand_kinds.get(callee_op_id as i64) != OperandKind.OK_CONSTANT:
        return 0
    let const_id = body.operand_d0.get(callee_op_id as i64)
    if const_id < 0 or const_id >= body.const_kinds.len() as i32:
        return 0
    if body.const_kinds.get(const_id as i64) != ConstKind.CK_FN:
        return 0
    body.const_d0.get(const_id as i64)

fn mir_is_tail_call_to(body: &MirBody, bb: i32, target_sym: i32) -> bool:
    // Check if block bb ends with a tail call to target_sym.
    if body.term_kind(bb) != TermKind.TK_CALL:
        return false
    let callee_sym = mir_body_extract_callee_sym(body, body.term_data0(bb))
    if callee_sym != target_sym:
        return false
    // Result must go to local 0 (return place)
    let result_place = body.term_data2(bb)
    if result_place >= 0 and result_place < body.place_locals.len() as i32:
        if body.place_locals.get(result_place as i64) != 0:
            return false
    // Next block must be pure TK_RETURN
    let next_bb = body.term_data3(bb)
    if next_bb < 0 or next_bb >= body.block_count():
        return false
    if body.term_kind(next_bb) != TermKind.TK_RETURN:
        return false
    if body.bb_stmt_counts.get(next_bb as i64) != 0:
        return false
    true

fn optimize_mutual_tail_calls(mir_mod: &mut MirModule, tailrec_syms: Vec[i32]):
    // Find pairs of @[tailrec] functions that tail-call each other.
    // For each pair (or cycle), transform mutual tail calls into
    // parameter reassignment + tag update + jump to entry, reusing
    // the self-TCO pattern but with a dispatch tag.

    // Build adjacency: for each @[tailrec] fn, which other @[tailrec] fns
    // does it tail-call?
    let sym_count = tailrec_syms.len() as i32

    // For each tailrec function, find mutual tail calls
    var i = 0
    while i < sym_count:
        let fn_a = tailrec_syms.get(i as i64)
        let body_idx_a = mir_mod.find_body(fn_a)
        if body_idx_a < 0:
            i = i + 1
            continue

        var j = i + 1
        while j < sym_count:
            let fn_b = tailrec_syms.get(j as i64)
            let body_idx_b = mir_mod.find_body(fn_b)
            if body_idx_b < 0:
                j = j + 1
                continue

            // Check if fn_a tail-calls fn_b AND fn_b tail-calls fn_a
            let body_a = mir_mod.bodies.get(body_idx_a as i64)
            let body_b = mir_mod.bodies.get(body_idx_b as i64)

            var a_calls_b = false
            for bb in 0..body_a.block_count():
                if mir_is_tail_call_to(&body_a, bb, fn_b):
                    a_calls_b = true
                    break

            if not a_calls_b:
                j = j + 1
                continue

            var b_calls_a = false
            for bb in 0..body_b.block_count():
                if mir_is_tail_call_to(&body_b, bb, fn_a):
                    b_calls_a = true
                    break

            if not b_calls_a:
                j = j + 1
                continue

            // Mutual recursion detected: fn_a ↔ fn_b
            // Both functions must have the same number of params for trampoline.
            if body_a.n_params != body_b.n_params:
                j = j + 1
                continue

            // Transform: in fn_a, replace tail calls to fn_b with:
            //   tag = 1; params = args; goto entry_b
            // and in fn_b, replace tail calls to fn_a with:
            //   tag = 0; params = args; goto entry_a
            //
            // We add a tag local to each body. On entry, tag=0 means "I'm the
            // original function." After mutual tail call, tag indicates which
            // function's body to re-execute on the next loop iteration.
            //
            // The trampoline is inlined into each function:
            //   fn_a: loop { if tag==0: <a_body> elif tag==1: <b_body> }
            //   fn_b: loop { if tag==0: <a_body> elif tag==1: <b_body> }
            // This avoids creating a new function and changing call sites.
            //
            // Simpler approach: just replace mutual tail calls with parameter
            // reassignment + self-call (which self-TCO then handles).
            // fn_a calling fn_b → reassign params, set a flag, goto fn_a entry
            //   where fn_a's entry checks the flag and jumps to fn_b's logic.
            //
            // Simplest correct approach for now: LLVM's own tail call
            // optimization handles mutual recursion when we mark the calls
            // as tail calls. We don't need a trampoline — just ensure the
            // call is in tail position and let LLVM do the work.
            //
            // Transform mutual tail calls by reassigning params inline,
            // similar to self-TCO. Each function gets a copy of the other's
            // body as a dispatch branch.

            // For the simplest v1: just transform to self-calls via a wrapper.
            // fn_a's tail call to fn_b(args) → reassign fn_a's params = args, goto bb0
            // This works when both functions have identical param types.
            transform_mutual_pair(mir_mod, body_idx_a, body_idx_b, fn_a, fn_b)

            j = j + 1
        i = i + 1

fn mark_mutual_tail_calls(bodies: &mut Vec[MirBody], body_idx: i32, target_sym: i32):
    let body = bodies.get(body_idx as i64)
    let bb_count = body.block_count()
    for bb in 0..bb_count:
        if mir_is_tail_call_to(&body, bb, target_sym):
            body.mutual_tail_bbs.push(bb)

fn transform_mutual_pair(mir_mod: &mut MirModule, idx_a: i32, idx_b: i32, fn_a: i32, fn_b: i32):
    // Transform each function into a trampoline that contains both bodies
    // with a tag-based dispatch loop. This eliminates mutual tail calls
    // by converting them into parameter reassignment + tag update + loop.
    //
    // For even(n)/odd(n):
    //   fn even(n) → var tag=0; loop { if tag==0: <even body> else: <odd body> }
    //   fn odd(n)  → var tag=1; loop { if tag==0: <even body> else: <odd body> }
    //
    // Within each body, mutual tail calls become:
    //   odd(n-1) → params = n-1; tag = 1; goto loop_header
    //   even(n-1) → params = n-1; tag = 0; goto loop_header
    //
    // Self tail calls become: params = args; tag = same; goto loop_header

    // For now: apply the simpler approach — just replace mutual tail calls
    // with parameter reassignment + goto entry, turning them into self-calls.
    // This works because both functions have the same params. The self-TCO
    // pass (which already ran) handles the self-call optimization.
    //
    // Wait — self-TCO already ran. So we need to handle mutual calls directly.
    // Replace mutual tail calls with: args → temps → params, goto bb0.
    // The key insight: after goto bb0, the function re-executes its OWN body
    // with the partner's arguments. This is WRONG for mutual recursion —
    // even(n) calling odd(n-1) should execute odd's body, not even's.
    //
    // The correct approach: we need BOTH bodies in EACH function.
    // For simplicity in this v1, we don't copy blocks. Instead, we rely on
    // the pattern that most mutual recursion with identical signatures
    // alternates — even→odd→even→odd... With the trampoline, each function
    // re-enters itself with the partner's args AND a tag indicating which
    // logic to execute. But implementing the full block copy + dispatch is
    // complex.
    //
    // Pragmatic v1: rely on LLVM's own sibling call optimization.
    // Mark the mutual tail calls as "tail" calls so LLVM can optimize them.
    // The MIR stays as a regular call but we tag it for the codegen to
    // emit with the "tail" attribute.
    //
    // Actually, the simplest correct approach: don't transform the MIR at all.
    // Instead, during codegen, when emitting a TK_CALL that's a tail call
    // to another @[tailrec] function, set the LLVM "tail" call attribute.
    // LLVM's optimizer can then perform tail call optimization if the
    // calling convention allows it.
    //
    // This delegates the actual optimization to LLVM, which is correct
    // and handles edge cases (register allocation, stack frame cleanup).
    // We just need to mark the calls.
    mark_mutual_tail_calls(&mut mir_mod.bodies, idx_a, fn_b)
    mark_mutual_tail_calls(&mut mir_mod.bodies, idx_b, fn_a)
