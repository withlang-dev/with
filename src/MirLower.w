// MirLower — Wave 7 MIR lowering from typed AST sidecars.
//
// This pass builds explicit control-flow MIR from the semantic result.

use Ast
use InternPool
use Mir
use Sema

// ── Builder state ────────────────────────────────────────────────

type ScopeEntry = {
    local_id: i32,
    drop_kind: i32,
}

type DropScope = {
    drops: Vec[ScopeEntry],
}

type LoopInfo = {
    continue_bb: i32,
    break_bb: i32,
    break_drop_depth: i32,
}

type MirBuilder = {
    body: MirBody,
    cur_bb: i32,

    // Drop scope stack (flat storage + per-scope start offsets).
    drop_local_ids: Vec[i32],
    drop_kinds: Vec[i32],
    drop_scope_starts: Vec[i32],

    // Lexical local bindings (sym -> local id), scoped.
    bind_syms: Vec[i32],
    bind_local_ids: Vec[i32],
    bind_scope_starts: Vec[i32],

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

fn MirBuilder.new_block(self: MirBuilder) -> i32:
    self.body.new_block()

fn MirBuilder.switch_to(self: MirBuilder, bb: i32):
    self.cur_bb = bb

fn MirBuilder.terminate(self: MirBuilder, kind: i32, d0: i32, d1: i32, d2: i32, d3: i32):
    let span = if self.cur_node > 0: self.ast.get_start(self.cur_node) else: 0
    self.body.set_terminator(self.cur_bb, kind, d0, d1, d2, d3, span)

fn MirBuilder.terminate_with_span(self: MirBuilder, kind: i32, d0: i32, d1: i32, d2: i32, d3: i32, span: i32):
    self.body.set_terminator(self.cur_bb, kind, d0, d1, d2, d3, span)

fn MirBuilder.push_scope(self: MirBuilder):
    self.drop_scope_starts.push(self.drop_local_ids.len() as i32)
    self.bind_scope_starts.push(self.bind_syms.len() as i32)

fn MirBuilder.schedule_drop(self: MirBuilder, local_id: i32, drop_kind: i32):
    self.drop_local_ids.push(local_id)
    self.drop_kinds.push(drop_kind)

fn MirBuilder.emit_drop_entry(self: MirBuilder, local_id: i32, drop_kind: i32):
    if drop_kind == DK_STORAGE:
        self.body.push_stmt(self.cur_bb, SK_STORAGE_DEAD, local_id, 0, 0)
        return
    let place = self.body.new_place(local_id)
    self.body.push_stmt(self.cur_bb, SK_DROP, place, 0, 0)

fn MirBuilder.pop_scope_with_goto(self: MirBuilder, target_bb: i32):
    if self.drop_scope_starts.len() as i32 == 0:
        self.terminate(TK_GOTO, target_bb, 0, 0, 0)
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

    self.terminate(TK_GOTO, target_bb, 0, 0, 0)

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
                let fn_op = self.const_operand(CK_FN, dtor_sym, 0)
                let self_place = self.place_for_local(local)
                let self_op = self.body.new_operand(OK_COPY, self_place)
                var args: Vec[i32] = Vec.new()
                args.push(self_op)
                let args_id = self.body.new_call_args(args)
                let void_local = self.new_temp(self.sema.ty_void)
                let void_place = self.place_for_local(void_local)
                let next_bb = self.new_block()
                self.terminate(TK_CALL, fn_op, args_id, void_place, next_bb)
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

fn MirBuilder.lookup_local(self: MirBuilder, sym: i32) -> i32:
    var i = self.bind_syms.len() as i32 - 1
    while i >= 0:
        if self.bind_syms.get(i as i64) == sym:
            return self.bind_local_ids.get(i as i64)
        i = i - 1
    0 - 1

fn MirBuilder.expr_type(self: MirBuilder, node: i32) -> i32:
    if node == 0:
        return self.sema.ty_void
    if self.sema.typed_expr_types.contains(node):
        let typed = self.sema.typed_expr_types.get(node).unwrap()
        if typed != 0:
            return typed
    self.fallback_expr_type(node)

fn MirBuilder.binding_type(self: MirBuilder, node: i32) -> i32:
    if self.sema.typed_binding_types.contains(node):
        let typed = self.sema.typed_binding_types.get(node).unwrap()
        if typed != 0:
            return typed
    let rhs = self.ast.get_data1(node)
    let rhs_ty = self.expr_type(rhs)
    if rhs_ty != 0:
        return rhs_ty
    self.sema.ty_void

fn MirBuilder.local_type(self: MirBuilder, local_id: i32) -> i32:
    if local_id < 0 or local_id >= self.body.local_type_ids.len() as i32:
        return self.sema.ty_void
    self.body.local_type_ids.get(local_id as i64)

fn MirBuilder.ident_type(self: MirBuilder, sym: i32) -> i32:
    let local = self.lookup_local(sym)
    if local >= 0:
        return self.local_type(local)
    let sig_idx = self.sema.get_sig(sym)
    if sig_idx >= 0:
        return self.sema.sig_type_ids.get(sig_idx as i64)
    if self.sema.named_types.contains(sym):
        return self.sema.named_types.get(sym).unwrap()
    if self.sema.variant_lookup.contains(sym):
        return self.sema.variant_type_ids.get(sym).unwrap()
    self.sema.ty_void

fn MirBuilder.resolve_index_generic_inst(self: MirBuilder, node: i32) -> i32:
    // Resolve NK_INDEX(NK_IDENT("Vec"), type_arg) to a TY_GENERIC_INST.
    // Used for Vec[i32].new() and HashMap[str, i32].new().
    // Sema.check_index creates these during the check pass; we only look up here.
    let base = self.ast.get_data0(node)
    if self.ast.kind(base) != NK_IDENT:
        return 0
    let base_sym = self.ast.get_data0(base)
    if not self.sema.named_types.contains(base_sym):
        return 0
    // Resolve the first type argument (d1 of NK_INDEX)
    let type_arg_node = self.ast.get_data1(node)
    if type_arg_node == 0:
        return 0
    var arg_type = self.resolve_type_arg_node(type_arg_node)
    if arg_type == 0:
        return 0
    // Check for second type argument (d2 of NK_INDEX) — HashMap[K, V]
    let type_arg2_node = self.ast.get_data2(node)
    var arg2_type = 0
    if type_arg2_node != 0:
        arg2_type = self.resolve_type_arg_node(type_arg2_node)
    // Look up TY_GENERIC_INST from sema cache (created by Sema.check_index)
    var cache_key = int_to_string(base_sym) ++ ":" ++ int_to_string(arg_type)
    if arg2_type > 0:
        cache_key = cache_key ++ ":" ++ int_to_string(arg2_type)
    if self.sema.generic_inst_cache.contains(cache_key):
        return self.sema.generic_inst_cache.get(cache_key).unwrap()
    0

fn MirBuilder.resolve_type_arg_node(self: MirBuilder, type_arg_node: i32) -> i32:
    let arg_kind = self.ast.kind(type_arg_node)
    if arg_kind == NK_IDENT or arg_kind == NK_TYPE_NAMED:
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
    // Handles: Vec (NK_IDENT), Vec[i32] (NK_INDEX of NK_IDENT)
    if self.ast.kind(node) == NK_IDENT:
        let sym = self.ast.get_data0(node)
        if self.sema.named_types.contains(sym):
            return self.sema.named_types.get(sym).unwrap()
    if self.ast.kind(node) == NK_INDEX:
        let base = self.ast.get_data0(node)
        if self.ast.kind(base) == NK_IDENT:
            let sym = self.ast.get_data0(base)
            if self.sema.named_types.contains(sym):
                return self.sema.named_types.get(sym).unwrap()
    0

fn MirBuilder.index_expr_is_type_level(self: MirBuilder, expr: i32) -> bool:
    if expr == 0:
        return false
    let kind = self.ast.kind(expr)
    if kind == NK_IDENT:
        let sym = self.ast.get_data0(expr)
        return self.sema.named_types.contains(sym)
    if kind == NK_INDEX or kind == NK_GROUPED:
        return self.index_expr_is_type_level(self.ast.get_data0(expr))
    false

fn MirBuilder.vec_literal_type(self: MirBuilder, node: i32) -> i32:
    if node == 0 or self.ast.kind(node) != NK_INDEX:
        return 0
    let base_expr = self.ast.get_data0(node)
    if not self.index_expr_is_type_level(base_expr):
        return 0
    let vec_ty = self.expr_type(node)
    if vec_ty == 0 or vec_ty == self.sema.ty_void:
        return 0
    let resolved = self.sema.resolve_alias(vec_ty)
    if self.sema.get_type_kind(resolved) != TY_GENERIC_INST:
        return 0
    let base_sym = self.sema.get_type_d0(resolved)
    if base_sym == 0:
        return 0
    if self.pool.resolve_symbol(base_sym) != "Vec":
        return 0
    resolved

fn MirBuilder.call_return_type(self: MirBuilder, callee: i32) -> i32:
    if callee == 0:
        return self.sema.ty_void
    let kind = self.ast.kind(callee)
    if kind == NK_IDENT:
        let sym = self.ast.get_data0(callee)
        let sig_idx = self.sema.get_sig(sym)
        if sig_idx >= 0:
            return self.sema.sig_return_type(sig_idx)
        return self.sema.ty_void
    if kind == NK_FIELD_ACCESS:
        let base = self.ast.get_data0(callee)
        let method_sym = self.ast.get_data1(callee)
        let resolved = self.resolve_method_callee_sym(base, method_sym)
        let resolved_sig = self.sema.get_sig(resolved)
        if resolved_sig >= 0:
            return self.sema.sig_return_type(resolved_sig)
        let bare_sig = self.sema.get_sig(method_sym)
        if bare_sig >= 0:
            return self.sema.sig_return_type(bare_sig)
        // Intrinsic methods (Vec/HashMap/Option/str) have no sema sigs.
        // Resolve their return types from the receiver type + method name.
        var base_ty = self.expr_type(base)
        if base_ty == 0 or base_ty == self.sema.ty_void:
            base_ty = self.type_receiver_type(base)
        if base_ty != 0 and base_ty != self.sema.ty_void:
            let method_name = self.pool.resolve_symbol(method_sym)
            let iret = self.intrinsic_return_type(base_ty, method_name)
            if iret != 0 and iret != self.sema.ty_void:
                return iret
            // Sema reports raw value types for Option-returning intrinsics
            // (e.g. HashMap.get returns str, not Option[str]). When .unwrap()
            // is chained, intrinsic_return_type can't match "unwrap" on str.
            // The unwrap just returns the same type sema already reports.
            if method_name == "unwrap":
                return base_ty
            if method_name == "is_some" or method_name == "is_none":
                return self.sema.ty_bool
    self.sema.ty_void

fn MirBuilder.intrinsic_return_type(self: MirBuilder, recv_type: i32, method_name: str) -> i32:
    // Return known return types for intrinsic (builtin) methods.
    // These methods have no sema signatures, so call_return_type can't resolve them.
    let resolved = self.sema.resolve_alias(recv_type)
    let tk = self.sema.get_type_kind(resolved)
    let type_name_sym = self.sema.get_type_name(resolved)
    if type_name_sym != 0:
        let type_name = self.pool.resolve_symbol(type_name_sym)
        if type_name == "Vec":
            if method_name == "len": return self.sema.ty_i64
            if method_name == "new": return recv_type
            if method_name == "push" or method_name == "set_i32" or method_name == "remove" or method_name == "clear":
                return self.sema.ty_void
            if method_name == "get" or method_name == "pop":
                if tk == TY_GENERIC_INST:
                    return self.sema.get_generic_inst_arg(resolved, 0)
            if method_name == "join": return self.sema.ty_str
            if method_name == "filter": return recv_type
            if method_name == "map": return self.expr_type(self.cur_node)
            if method_name == "iter":
                // Vec.iter() returns VecIter[T] with same T as Vec[T].
                let vi_sym = self.sema.pool_intern("VecIter")
                if self.sema.named_types.contains(vi_sym):
                    if tk == TY_GENERIC_INST:
                        let elem_ty = self.sema.get_generic_inst_arg(resolved, 0)
                        if elem_ty > 0:
                            let found = self.sema.find_generic_inst(vi_sym, elem_ty)
                            if found != 0:
                                return found
                    return self.sema.named_types.get(vi_sym).unwrap()
                return self.sema.ty_void
            return self.sema.ty_void
        if type_name == "VecIter":
            if method_name == "next":
                // VecIter[T].next() returns Option[T].
                if tk == TY_GENERIC_INST:
                    let elem_ty = self.sema.get_generic_inst_arg(resolved, 0)
                    let opt_sym = self.sema.pool_intern("Option")
                    let opt_tid = self.sema.find_generic_inst(opt_sym, elem_ty)
                    if opt_tid != 0:
                        return opt_tid
                    return elem_ty
            return self.sema.ty_void
        if type_name == "HashMap":
            if method_name == "len": return self.sema.ty_i64
            if method_name == "contains": return self.sema.ty_bool
            if method_name == "new": return recv_type
            if method_name == "insert" or method_name == "clear":
                return self.sema.ty_void
            if method_name == "get" or method_name == "remove":
                if tk == TY_GENERIC_INST:
                    return self.sema.get_generic_inst_arg(resolved, 1)
            return self.sema.ty_void
        if type_name == "HashSet":
            if method_name == "len": return self.sema.ty_i64
            if method_name == "contains" or method_name == "remove": return self.sema.ty_bool
            if method_name == "new": return recv_type
            if method_name == "insert" or method_name == "clear":
                return self.sema.ty_void
            return self.sema.ty_void
        if type_name == "Option":
            if method_name == "is_some" or method_name == "is_none": return self.sema.ty_bool
            if method_name == "unwrap":
                if tk == TY_GENERIC_INST:
                    return self.sema.get_generic_inst_arg(resolved, 0)
            if method_name == "filter":
                return recv_type
            if method_name == "map" or method_name == "and_then":
                return recv_type
            if method_name == "unwrap_or":
                if tk == TY_GENERIC_INST:
                    return self.sema.get_generic_inst_arg(resolved, 0)
            if method_name == "unwrap_or_else":
                if tk == TY_GENERIC_INST:
                    return self.sema.get_generic_inst_arg(resolved, 0)
            return self.sema.ty_void
        if type_name == "Result":
            if method_name == "is_ok": return self.sema.ty_bool
            if method_name == "unwrap":
                if tk == TY_GENERIC_INST:
                    return self.sema.get_generic_inst_arg(resolved, 0)
            return self.sema.ty_void
    if tk == TY_STR:
        if method_name == "len": return self.sema.ty_i64
        if method_name == "byte_at": return self.sema.ty_i32
        if method_name == "slice": return self.sema.ty_str
        if method_name == "contains" or method_name == "starts_with" or method_name == "ends_with":
            return self.sema.ty_bool
        if method_name == "find": return self.sema.ty_i64
        if method_name == "repeat": return self.sema.ty_str
        if method_name == "trim" or method_name == "to_upper" or method_name == "to_lower" or method_name == "replace":
            return self.sema.ty_str
        if method_name == "index_of": return self.sema.ty_i64
        if method_name == "split":
            // str.split() returns Vec[str]
            let vec_sym = self.sema.pool_intern("Vec")
            let found = self.sema.find_generic_inst(vec_sym, self.sema.ty_str)
            if found != 0:
                return found
            return self.sema.ty_void
        return self.sema.ty_void
    if tk == TY_ARRAY:
        if method_name == "len": return self.sema.ty_i32
        return self.sema.ty_void
    self.sema.ty_void

fn MirBuilder.struct_field_type(self: MirBuilder, struct_tid: i32, field_sym: i32) -> i32:
    let resolved = self.sema.resolve_alias(struct_tid)
    let tk = self.sema.get_type_kind(resolved)
    if tk == TY_REF or tk == TY_PTR:
        let inner = self.sema.get_type_d0(resolved)
        return self.struct_field_type(inner, field_sym)
    if tk == TY_GENERIC_INST:
        let base_sym = self.sema.get_type_d0(resolved)
        if self.sema.named_types.contains(base_sym):
            let base_tid = self.sema.named_types.get(base_sym).unwrap()
            return self.struct_field_type(base_tid, field_sym)
        return 0
    if tk != TY_STRUCT:
        return 0
    let extra_start = self.sema.get_type_d1(resolved)
    let field_count = self.sema.get_type_d2(resolved)
    for fi in 0..field_count:
        let f_name = self.sema.type_extra.get((extra_start + fi * 3) as i64)
        if f_name == field_sym:
            let f_type = self.sema.type_extra.get((extra_start + fi * 3 + 1) as i64)
            if f_type != 0:
                return f_type
            // Forward-referenced field type stored as 0 during collect_type_decl.
            // Re-resolve from the AST type declaration node.
            let struct_name_sym = self.sema.get_type_d0(resolved)
            if self.sema.type_decl_nodes.contains(struct_name_sym):
                let td_node = self.sema.type_decl_nodes.get(struct_name_sym).unwrap()
                let td_extra = self.ast.get_data1(td_node)
                let td_fc = self.ast.get_extra(td_extra)
                if fi < td_fc:
                    let ast_base = td_extra + 1 + fi * 3
                    let f_type_node = self.ast.get_extra(ast_base + 1)
                    return self.sema.resolve_type_expr(f_type_node)
            return 0
    0

fn MirBuilder.tuple_elem_type(self: MirBuilder, tuple_tid: i32, field_idx: i32) -> i32:
    let resolved = self.sema.resolve_alias(tuple_tid)
    if self.sema.get_type_kind(resolved) != TY_TUPLE:
        return 0
    let elem_start = self.sema.get_type_d0(resolved)
    let elem_count = self.sema.get_type_d1(resolved)
    if field_idx < 0 or field_idx >= elem_count:
        return 0
    self.sema.type_extra.get((elem_start + field_idx) as i64)

fn MirBuilder.indexed_element_type(self: MirBuilder, collection_tid: i32) -> i32:
    let resolved = self.sema.resolve_alias(collection_tid)
    let tk = self.sema.get_type_kind(resolved)
    if tk == TY_ARRAY or tk == TY_SLICE:
        return self.sema.get_type_d0(resolved)
    if tk == TY_STR:
        return self.sema.ty_i32
    if tk == TY_GENERIC_INST:
        let base_sym = self.sema.get_generic_inst_base(resolved)
        if self.pool.resolve_symbol(base_sym) == "Vec" and self.sema.get_generic_inst_arg_count(resolved) > 0:
            return self.sema.get_generic_inst_arg(resolved, 0)
    0

fn MirBuilder.enum_payload_type(self: MirBuilder, enum_tid: i32, variant_idx: i32, field_idx: i32) -> i32:
    let resolved = self.sema.resolve_alias(enum_tid)
    let tk = self.sema.get_type_kind(resolved)
    if variant_idx < 0 or field_idx < 0:
        return 0

    if tk == TY_ENUM:
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

    if tk == TY_GENERIC_INST:
        let base_sym = self.sema.get_generic_inst_base(resolved)
        if not self.sema.named_types.contains(base_sym):
            return 0
        let base_tid = self.sema.named_types.get(base_sym).unwrap()
        if self.sema.get_type_kind(base_tid) != TY_ENUM:
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
        return self.sema.ty_void
    let kind = self.ast.kind(node)
    if kind == NK_IDENT:
        return self.ident_type(self.ast.get_data0(node))
    if kind == NK_GROUPED:
        return self.expr_type(self.ast.get_data0(node))
    if kind == NK_FIELD_ACCESS:
        let base_node = self.ast.get_data0(node)
        let field_sym = self.ast.get_data1(node)
        let base_ty = self.expr_type(base_node)
        if base_ty != 0 and base_ty != self.sema.ty_void:
            let ft = self.struct_field_type(base_ty, field_sym)
            if ft != 0:
                return ft
        return self.sema.ty_void
    if kind == NK_INT_LIT:
        let value = self.ast.int_lit_value(node)
        if value < -2147483648 or value > 2147483647:
            return self.sema.ty_i64
        return self.sema.ty_i32
    if kind == NK_BOOL_LIT:
        return self.sema.ty_bool
    if kind == NK_STRING_LIT or kind == NK_C_STRING_LIT:
        return self.sema.ty_str
    if kind == NK_NULL_LIT:
        return self.sema.ty_i32
    if kind == NK_UNSAFE_BLOCK:
        return self.expr_type(self.ast.get_data0(node))
    if kind == NK_CALL:
        return self.call_return_type(self.ast.get_data0(node))
    if kind == NK_STRUCT_LIT:
        let st_name = self.ast.get_data0(node)
        if self.sema.named_types.contains(st_name):
            return self.sema.named_types.get(st_name).unwrap()
        // Self struct literal — resolve via method context
        let st_name_str = self.sema.pool_resolve(st_name)
        if st_name_str == "Self":
            let fn_sym = self.body.fn_sym
            let fn_name_str = self.sema.pool_resolve(fn_sym)
            for ci in 0..fn_name_str.len() as i32:
                if fn_name_str.byte_at(ci as i64) == 46:
                    let owner_name = fn_name_str.slice(0, ci as i64)
                    let owner_sym = self.sema.pool_intern(owner_name)
                    if self.sema.named_types.contains(owner_sym):
                        return self.sema.named_types.get(owner_sym).unwrap()
                    break
    if kind == NK_MATCH:
        // Infer match type from first arm body
        let m_arms_start = self.ast.get_data1(node)
        let m_arms_count = self.ast.get_data2(node)
        if m_arms_count > 0:
            let first_arm = self.ast.get_extra(m_arms_start)
            let arm_body = self.ast.get_data1(first_arm)
            if arm_body != 0:
                return self.expr_type(arm_body)
    if kind == NK_IF_EXPR:
        // Infer if-expression type from then branch
        let then_expr = self.ast.get_data1(node)
        if then_expr != 0:
            return self.expr_type(then_expr)
    if kind == NK_BLOCK:
        // Infer block type from tail expression
        let tail = self.ast.get_data2(node)
        if tail != 0:
            return self.expr_type(tail)
    if kind == NK_INDEX:
        let base_node = self.ast.get_data0(node)
        let base_ty = self.expr_type(base_node)
        if base_ty != 0 and base_ty != self.sema.ty_void:
            let resolved = self.sema.resolve_alias(base_ty)
            let tk = self.sema.get_type_kind(resolved)
            if tk == TY_ARRAY or tk == TY_SLICE:
                return self.sema.get_type_d0(resolved)
    if kind == NK_BINARY:
        let op = self.ast.get_data0(node)
        let lhs_ty = self.expr_type(self.ast.get_data1(node))
        let rhs_ty = self.expr_type(self.ast.get_data2(node))
        if op == OP_EQ or op == OP_NEQ or op == OP_LT or op == OP_GT or op == OP_LTE or op == OP_GTE or op == OP_AND or op == OP_OR:
            return self.sema.ty_bool
        if lhs_ty != 0 and lhs_ty != self.sema.ty_void:
            let lhs_resolved = self.sema.resolve_alias(lhs_ty)
            let lhs_tk = self.sema.get_type_kind(lhs_resolved)
            if (op == OP_ADD or op == OP_SUB) and (lhs_tk == TY_PTR or lhs_tk == TY_REF):
                return lhs_ty
        if rhs_ty != 0 and rhs_ty != self.sema.ty_void:
            let rhs_resolved = self.sema.resolve_alias(rhs_ty)
            let rhs_tk = self.sema.get_type_kind(rhs_resolved)
            if op == OP_ADD and (rhs_tk == TY_PTR or rhs_tk == TY_REF):
                return rhs_ty
        if lhs_ty != 0 and lhs_ty == rhs_ty:
            return lhs_ty
    if kind == NK_UNARY:
        let uop = self.ast.get_data0(node)
        if uop == UOP_DEREF:
            let inner_node = self.ast.get_data1(node)
            let inner_ty = self.expr_type(inner_node)
            if inner_ty != 0 and inner_ty != self.sema.ty_void:
                let resolved = self.sema.resolve_alias(inner_ty)
                let tk = self.sema.get_type_kind(resolved)
                if tk == TY_PTR or tk == TY_REF:
                    return self.sema.get_type_d0(resolved)
    if kind == NK_VARIANT_SHORTHAND:
        let vs_sym = self.ast.get_data0(node)
        if self.sema.variant_lookup.contains(vs_sym):
            return self.sema.variant_type_ids.get(vs_sym).unwrap()
    if kind == NK_RANGE:
        let range_start = self.ast.get_data0(node)
        let range_end = self.ast.get_data1(node)
        let range_inclusive = self.ast.get_data2(node)
        var range_elem = self.sema.ty_i32
        if range_start != 0:
            range_elem = self.expr_type(range_start)
        else if range_end != 0:
            range_elem = self.expr_type(range_end)
        let range_found = self.sema.find_range_type(range_elem, range_inclusive)
        if range_found != 0:
            return range_found
        return self.sema.ty_void
    self.sema.ty_void

fn MirBuilder.place_local_type(self: MirBuilder, place_id: i32) -> i32:
    if place_id < 0 or place_id >= self.body.place_locals.len() as i32:
        return self.sema.ty_void
    let local_id = self.body.place_locals.get(place_id as i64)
    if local_id < 0 or local_id >= self.body.local_type_ids.len() as i32:
        return self.sema.ty_void
    var current_ty = self.body.local_type_ids.get(local_id as i64)
    let proj_start = self.body.place_proj_starts.get(place_id as i64)
    let proj_count = self.body.place_proj_counts.get(place_id as i64)
    var active_variant_idx = -1

    for pi in 0..proj_count:
        let proj_kind = self.body.proj_kinds.get((proj_start + pi) as i64)
        let proj_d0 = self.body.proj_d0.get((proj_start + pi) as i64)
        let resolved = self.sema.resolve_alias(current_ty)
        let tk = self.sema.get_type_kind(resolved)

        if proj_kind == PK_DOWNCAST:
            if tk == TY_ENUM or tk == TY_GENERIC_INST:
                active_variant_idx = proj_d0
                continue
            return self.sema.ty_void

        if proj_kind == PK_FIELD:
            var field_ty = 0
            if active_variant_idx >= 0:
                field_ty = self.enum_payload_type(current_ty, active_variant_idx, proj_d0)
            else if tk == TY_TUPLE:
                field_ty = self.tuple_elem_type(current_ty, proj_d0)
            else:
                field_ty = self.struct_field_type(current_ty, proj_d0)
            if field_ty == 0:
                return self.sema.ty_void
            current_ty = field_ty
            active_variant_idx = -1
            continue

        if proj_kind == PK_INDEX:
            let elem_ty = self.indexed_element_type(current_ty)
            if elem_ty == 0:
                return self.sema.ty_void
            current_ty = elem_ty
            active_variant_idx = -1
            continue

        if proj_kind == PK_DEREF:
            if tk == TY_PTR or tk == TY_REF:
                current_ty = self.sema.get_type_d0(resolved)
                active_variant_idx = -1
                continue
            return self.sema.ty_void

        return self.sema.ty_void

    current_ty

fn MirBuilder.variant_index(self: MirBuilder, variant_sym: i32) -> i32:
    if variant_sym == 0:
        return 0
    if self.sema.variant_lookup.contains(variant_sym):
        return self.sema.variant_lookup.get(variant_sym).unwrap()
    0

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
    self.body.new_operand(OK_CONSTANT, c)

fn MirBuilder.int_const_operand(self: MirBuilder, value: i64, type_id: i32) -> i32:
    let c = self.body.new_const(CK_INT, ast_int_part0(value), ast_int_part1(value), ast_int_part2(value), type_id)
    self.body.new_operand(OK_CONSTANT, c)

fn MirBuilder.unit_operand(self: MirBuilder) -> i32:
    self.const_operand(CK_UNIT, 0, self.sema.ty_void)

fn MirBuilder.try_eval_const(self: MirBuilder, node: i32) -> i64:
    let kind = self.ast.kind(node)
    if kind == NK_INT_LIT:
        return self.ast.int_lit_value(node)
    if kind == NK_COMPTIME:
        return self.try_eval_const(self.ast.get_data0(node))
    if kind == NK_GROUPED:
        return self.try_eval_const(self.ast.get_data0(node))
    if kind == NK_BOOL_LIT:
        return self.ast.get_data0(node) as i64
    if kind == NK_UNARY:
        let op = self.ast.get_data0(node)
        let inner = self.try_eval_const(self.ast.get_data1(node))
        if inner == -9223372036854775807: return -9223372036854775807
        if op == UOP_NEGATE: return -inner
        if op == UOP_NOT:
            if inner == 0: return 1
            return 0
        return -9223372036854775807
    if kind == NK_BINARY:
        let op = self.ast.get_data0(node)
        let lv = self.try_eval_const(self.ast.get_data1(node))
        if lv == -9223372036854775807: return -9223372036854775807
        let rv = self.try_eval_const(self.ast.get_data2(node))
        if rv == -9223372036854775807: return -9223372036854775807
        if op == OP_ADD: return lv + rv
        if op == OP_SUB: return lv - rv
        if op == OP_MUL: return lv * rv
        if op == OP_DIV:
            if rv == 0: return -9223372036854775807
            return lv / rv
        if op == OP_MOD:
            if rv == 0: return -9223372036854775807
            return lv % rv
        return -9223372036854775807
    if kind == NK_IDENT:
        // Cross-reference to another constant
        let ref_sym = self.ast.get_data0(node)
        return self.try_resolve_module_const_val(ref_sym)
    -9223372036854775807

fn MirBuilder.try_resolve_module_const_val(self: MirBuilder, sym: i32) -> i64:
    for di in 0..self.ast.decl_count():
        let decl = self.ast.get_decl(di)
        if self.ast.kind(decl) != NK_LET_DECL:
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
        if self.ast.kind(decl) != NK_LET_DECL:
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
        if self.ast.kind(value_node) == NK_COMPTIME:
            value_node = self.ast.get_data0(value_node)
        if self.ast.kind(value_node) == NK_FLOAT_LIT:
            return self.ast.get_data0(value_node)
    -1

fn MirBuilder.mark_unsupported(self: MirBuilder):
    if with_getenv_str("WITH_MIR_AUDIT").len() > 0:
        let node_kind = if self.cur_node != 0: self.ast.kind(self.cur_node) else: 0
        let fn_name = self.pool.resolve(self.body.fn_sym)
        with_eprintln("[mir-lower-fail] kind=" ++ int_to_string(node_kind) ++ " fn=" ++ fn_name)
    var b = self.body
    b.lowering_failed = 1
    self.body = b

fn MirBuilder.lower_int_lit(self: MirBuilder, value: i64, type_id: i32) -> i32:
    let ty = if type_id == 0 or self.sema.get_type_kind(type_id) == TY_VOID: self.sema.ty_i32 else: type_id
    self.int_const_operand(value, ty)

fn MirBuilder.lower_bool_lit(self: MirBuilder, value: i32) -> i32:
    self.const_operand(CK_BOOL, value, self.sema.ty_bool)

fn MirBuilder.lower_str_lit(self: MirBuilder, sym: i32) -> i32:
    self.const_operand(CK_STR, sym, self.sema.ty_str)

fn MirBuilder.lower_float_lit(self: MirBuilder, sym: i32) -> i32:
    self.const_operand(CK_FLOAT, sym, self.sema.ty_f64)

fn MirBuilder.lower_unit(self: MirBuilder) -> i32:
    self.unit_operand()

fn MirBuilder.is_bare_none(self: MirBuilder, node: i32) -> bool:
    if node == 0 or self.ast.kind(node) != NK_IDENT:
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
        if dk == NK_EXTERN_VAR:
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
        if dk != NK_LET_DECL:
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
            let annotated = self.sema.resolve_type_expr(type_node)
            if annotated > 0:
                gty = annotated
        let val_node = self.ast.get_data1(decl)
        var typed_value = val_node
        while typed_value != 0:
            let typed_kind = self.ast.kind(typed_value)
            if typed_kind != NK_COMPTIME and typed_kind != NK_GROUPED:
                break
            typed_value = self.ast.get_data0(typed_value)
        if gty == 0 and typed_value != 0:
            let inferred = self.expr_type(typed_value)
            if inferred != 0:
                gty = inferred
        if gty == 0:
            gty = self.sema.ty_i32
        let local_id = self.body.new_local(gty, is_mut, sym, 1)
        self.bind_local(sym, local_id)
        return local_id
    0 - 1

fn MirBuilder.lower_var(self: MirBuilder, sym: i32, type_id: i32) -> i32:
    let hinted_ty = if self.expected_type != 0: self.expected_type else: type_id
    if self.pool.resolve(sym) == "None" and hinted_ty != 0:
        let hinted_resolved = self.sema.resolve_alias(hinted_ty)
        let hinted_tk = self.sema.get_type_kind(hinted_resolved)
        if hinted_tk == TY_PTR or hinted_tk == TY_REF:
            return self.const_operand(CK_INT, 0, self.sema.ty_i32)

    let local = self.lookup_local(sym)
    if local >= 0:
        let place = self.body.new_place(local)
        if self.sema.is_copy(type_id) != 0:
            return self.body.new_operand(OK_COPY, place)
        return self.body.new_operand(OK_MOVE, place)

    let sig_idx = self.sema.get_sig(sym)
    if sig_idx >= 0:
        let fn_ty = if type_id != 0: type_id else: self.sema.sig_type_ids.get(sig_idx as i64)
        return self.const_operand(CK_FN, sym, fn_ty)

    // Generic function reference (monomorphized at codegen time)
    if self.sema.generic_fn_nodes.contains(sym):
        return self.const_operand(CK_FN, sym, type_id)

    // Try module-level constant (const X = 42)
    let const_val = self.try_resolve_module_const_val(sym)
    if const_val != -9223372036854775807:
        let ty = if const_val < -2147483648 or const_val > 2147483647: self.sema.ty_i64 else: self.sema.ty_i32
        return self.int_const_operand(const_val, ty)

    // Try module-level float constant (let PI: f64 = 3.14)
    let float_str_idx = self.try_resolve_module_float_const(sym)
    if float_str_idx >= 0:
        return self.const_operand(CK_FLOAT, float_str_idx, self.sema.ty_f64)

    // Check for enum variant without payload (None, etc.)
    if self.sema.variant_lookup.contains(sym):
        let vl_variant_idx = self.sema.variant_lookup.get(sym).unwrap()
        var vl_result_ty = if self.expected_type != 0: self.expected_type else: type_id
        if vl_result_ty == 0:
            vl_result_ty = self.sema.variant_type_ids.get(sym).unwrap()
        let vl_fields: Vec[i32] = Vec.new()
        let vl_names: Vec[i32] = Vec.new()
        let vl_fid = self.body.new_agg_fields(vl_fields, vl_names)
        let vl_rv = self.body.new_rvalue(RK_AGGREGATE, 1, vl_fid, vl_variant_idx)
        let vl_tmp = self.new_temp(vl_result_ty)
        let vl_place = self.place_for_local(vl_tmp)
        self.body.push_stmt(self.cur_bb, SK_ASSIGN, vl_place, vl_rv, 0)
        return self.body.new_operand(OK_COPY, vl_place)

    // Try module-level mutable variable (var X = ...)
    let gv_local = self.ensure_global_local(sym)
    if gv_local >= 0:
        let gv_place = self.body.new_place(gv_local)
        return self.body.new_operand(OK_COPY, gv_place)

    if with_getenv_str("WITH_MIR_AUDIT").len() > 0:
        let var_name = self.pool.resolve(sym)
        let fn_name = self.pool.resolve(self.body.fn_sym)
        with_eprintln("[mir-var-miss] sym=" ++ var_name ++ " fn=" ++ fn_name)
    self.mark_unsupported()
    self.unit_operand()

fn MirBuilder.assign_operand_to_place(self: MirBuilder, place: i32, operand_id: i32, span: i32):
    let rval = self.body.new_rvalue(RK_USE, operand_id, 0, 0)
    self.body.push_stmt(self.cur_bb, SK_ASSIGN, place, rval, span)

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
        if lhs_tk == TY_STRUCT:
            let method_name = mir_op_method_name(op)
            if method_name.len() > 0:
                let type_name_sym = self.sema.get_type_d0(lhs_resolved)
                if type_name_sym != 0:
                    let method_sym = self.sema.pool_intern(self.sema.pool_resolve(type_name_sym) ++ "." ++ method_name)
                    let sig = self.sema.get_sig(method_sym)
                    if sig >= 0:
                        return self.lower_method_bin_op(lhs_expr, rhs_expr, method_sym, node)
    let saved_expected = self.expected_type
    if self.is_bare_none(lhs_expr) and (rhs_tk == TY_PTR or rhs_tk == TY_REF):
        self.expected_type = rhs_ty
    else:
        self.expected_type = saved_expected
    let lhs = self.lower_expr(lhs_expr)
    if self.is_bare_none(rhs_expr) and (lhs_tk == TY_PTR or lhs_tk == TY_REF):
        self.expected_type = lhs_ty
    else:
        self.expected_type = saved_expected
    let rhs = self.lower_expr(rhs_expr)
    self.expected_type = saved_expected
    let rv = self.body.new_rvalue(RK_BIN_OP, op, lhs, rhs)
    let ty = self.expr_type(node)
    let temp = self.new_temp(ty)
    let place = self.place_for_local(temp)
    self.body.push_stmt(self.cur_bb, SK_ASSIGN, place, rv, self.ast.get_start(node))
    if self.sema.is_copy(ty) != 0:
        return self.body.new_operand(OK_COPY, place)
    self.body.new_operand(OK_MOVE, place)

fn MirBuilder.lower_short_circuit(self: MirBuilder, op: i32, lhs_expr: i32, rhs_expr: i32, node: i32) -> i32:
    // Short-circuit: for `a or b`, evaluate a; if true, result is true, else evaluate b.
    // For `a and b`, evaluate a; if false, result is false, else evaluate b.
    let result = self.new_temp(self.sema.ty_bool)
    let result_place = self.place_for_local(result)
    let lhs = self.lower_expr(lhs_expr)
    let lhs_rv = self.body.new_rvalue(RK_USE, lhs, 0, 0)
    self.body.push_stmt(self.cur_bb, SK_ASSIGN, result_place, lhs_rv, self.ast.get_start(node))
    let rhs_bb = self.new_block()
    let end_bb = self.new_block()
    let lhs_read = self.body.new_operand(OK_COPY, result_place)
    // Use switch_int: value 1 (true) goes to one target, default goes to other
    let vals: Vec[i32] = Vec.new()
    vals.push(1)
    let targets: Vec[i32] = Vec.new()
    if op == 12:
        // or: if lhs is true (1), skip to end; default (false) → evaluate rhs
        targets.push(end_bb)
        let table = self.body.new_switch_table(vals, targets)
        self.terminate(TK_SWITCH_INT, lhs_read, table, rhs_bb, 0)
    else:
        // and: if lhs is true (1), evaluate rhs; default (false) → skip to end
        targets.push(rhs_bb)
        let table = self.body.new_switch_table(vals, targets)
        self.terminate(TK_SWITCH_INT, lhs_read, table, end_bb, 0)
    self.switch_to(rhs_bb)
    let rhs = self.lower_expr(rhs_expr)
    let rhs_rv = self.body.new_rvalue(RK_USE, rhs, 0, 0)
    let result_place2 = self.place_for_local(result)
    self.body.push_stmt(self.cur_bb, SK_ASSIGN, result_place2, rhs_rv, self.ast.get_start(node))
    self.terminate(TK_GOTO, end_bb, 0, 0, 0)
    self.switch_to(end_bb)
    self.body.new_operand(OK_COPY, self.place_for_local(result))

fn mir_op_method_name(op: i32) -> str:
    if op == 0: return "add"    // OP_ADD
    if op == 1: return "sub"    // OP_SUB
    if op == 2: return "mul"    // OP_MUL
    if op == 3: return "div"    // OP_DIV
    if op == 4: return "mod"    // OP_MOD
    if op == 5: return "eq"     // OP_EQ
    if op == 6: return "ne"     // OP_NEQ
    if op == 7: return "lt"     // OP_LT
    if op == 8: return "gt"     // OP_GT
    if op == 9: return "le"     // OP_LTE
    if op == 10: return "ge"    // OP_GTE
    ""

fn MirBuilder.lower_method_bin_op(self: MirBuilder, lhs_expr: i32, rhs_expr: i32, method_sym: i32, node: i32) -> i32:
    // Lower as: method_sym(lhs, rhs)
    let fn_op = self.lower_var(method_sym, 0)
    let arg_nodes: Vec[i32] = Vec.new()
    arg_nodes.push(lhs_expr)
    arg_nodes.push(rhs_expr)
    self.lower_call_with_arg_nodes(fn_op, method_sym, arg_nodes, self.expr_type(node), node)

fn MirBuilder.lower_un_op(self: MirBuilder, op: i32, expr: i32, node: i32) -> i32:
    if op == UOP_REF or op == UOP_MUT_REF:
        let place = self.lower_expr_place(expr)
        let rv = self.body.new_rvalue(RK_REF, if op == UOP_MUT_REF: BK_EXCLUSIVE else: BK_SHARED, place, 0)
        let ty = self.expr_type(node)
        let temp = self.new_temp(ty)
        let temp_place = self.place_for_local(temp)
        self.body.push_stmt(self.cur_bb, SK_ASSIGN, temp_place, rv, self.ast.get_start(node))
        return self.body.new_operand(OK_COPY, temp_place)

    if op == UOP_DEREF:
        let place = self.lower_expr_place(expr)
        let deref_place = self.body.new_deref_place(place)
        return self.body.new_operand(OK_COPY, deref_place)

    let arg = self.lower_expr(expr)
    let rv = self.body.new_rvalue(RK_UN_OP, op, arg, 0)
    let ty = self.expr_type(node)
    let temp = self.new_temp(ty)
    let place = self.place_for_local(temp)
    self.body.push_stmt(self.cur_bb, SK_ASSIGN, place, rv, self.ast.get_start(node))
    self.body.new_operand(OK_COPY, place)

fn MirBuilder.lower_cast(self: MirBuilder, expr: i32, target_type_id: i32, node: i32) -> i32:
    let op = self.lower_expr(expr)
    let rv = self.body.new_rvalue(RK_CAST, op, target_type_id, 0)
    let temp = self.new_temp(target_type_id)
    let place = self.place_for_local(temp)
    self.body.push_stmt(self.cur_bb, SK_ASSIGN, place, rv, self.ast.get_start(node))
    self.body.new_operand(OK_COPY, place)

fn MirBuilder.lower_field_access(self: MirBuilder, base_expr: i32, field_idx: i32) -> i32:
    let base = self.lower_field_base_place(base_expr)
    self.body.new_field_place(base, field_idx)

fn MirBuilder.lower_field_base_place(self: MirBuilder, base_expr: i32) -> i32:
    var base = self.lower_expr_place(base_expr)
    var base_ty = self.expr_type(base_expr)
    while base_ty > 0:
        let resolved = self.sema.resolve_alias(base_ty)
        let tk = self.sema.get_type_kind(resolved)
        if tk != TY_PTR and tk != TY_REF:
            break
        base = self.body.new_deref_place(base)
        base_ty = self.sema.get_type_d0(resolved)
    base

fn MirBuilder.lower_index(self: MirBuilder, base_expr: i32, index_expr: i32) -> i32:
    let base = self.lower_expr_place(base_expr)
    let idx_op = self.lower_expr(index_expr)
    let idx_ty = self.expr_type(index_expr)
    let idx_local = self.new_temp(idx_ty)
    let idx_place = self.place_for_local(idx_local)
    self.assign_operand_to_place(idx_place, idx_op, self.ast.get_start(index_expr))
    self.body.new_index_place(base, idx_local)

fn MirBuilder.lower_vec_literal_push(self: MirBuilder, vec_place: i32, elem_node: i32, elem_ty: i32):
    if elem_node == 0:
        return
    let push_sym = self.pool.intern("push")
    let fn_op = self.const_operand(CK_FN, push_sym, self.sema.ty_void)
    let saved_expected = self.expected_type
    if elem_ty > 0 and elem_ty != self.sema.ty_void:
        self.expected_type = elem_ty
    let elem_op = self.lower_expr(elem_node)
    self.expected_type = saved_expected
    let args: Vec[i32] = Vec.new()
    args.push(self.body.new_operand(OK_COPY, vec_place))
    args.push(elem_op)
    let args_id = self.body.new_call_args(args)
    let result_local = self.new_temp(self.sema.ty_void)
    let result_place = self.place_for_local(result_local)
    let next_bb = self.new_block()
    self.terminate(TK_CALL, fn_op, args_id, result_place, next_bb)
    self.switch_to(next_bb)
    self.body.set_call_intrinsic(args_id, MIR_INTRINSIC_VEC_PUSH)

fn MirBuilder.lower_vec_literal(self: MirBuilder, node: i32, vec_ty: i32) -> i32:
    let base_expr = self.ast.get_data0(node)
    let first_elem = self.ast.get_data1(node)
    let second_elem = self.ast.get_data2(node)
    let new_sym = self.pool.intern("new")
    let new_op = self.lower_intrinsic_call(MIR_INTRINSIC_VEC_NEW, base_expr, new_sym, 0, 0, node)
    let vec_place = self.materialize_operand(new_op, vec_ty, self.ast.get_start(node))
    let resolved = self.sema.resolve_alias(vec_ty)
    let elem_ty = if self.sema.get_type_kind(resolved) == TY_GENERIC_INST: self.sema.get_generic_inst_arg(resolved, 0) else: 0
    self.lower_vec_literal_push(vec_place, first_elem, elem_ty)
    if second_elem != 0:
        self.lower_vec_literal_push(vec_place, second_elem, elem_ty)
    if self.sema.is_copy(vec_ty) != 0:
        return self.body.new_operand(OK_COPY, vec_place)
    self.body.new_operand(OK_MOVE, vec_place)

fn MirBuilder.lower_deref(self: MirBuilder, expr: i32) -> i32:
    let base = self.lower_expr_place(expr)
    self.body.new_deref_place(base)

fn MirBuilder.lower_ref(self: MirBuilder, expr: i32, borrow_kind: i32, node: i32) -> i32:
    let place = self.lower_expr_place(expr)
    let rv = self.body.new_rvalue(RK_REF, borrow_kind, place, 0)
    let ty = self.expr_type(node)
    let temp = self.new_temp(ty)
    let temp_place = self.place_for_local(temp)
    self.body.push_stmt(self.cur_bb, SK_ASSIGN, temp_place, rv, self.ast.get_start(node))
    self.body.new_operand(OK_COPY, temp_place)

fn MirBuilder.lower_assign(self: MirBuilder, place_expr: i32, rhs_expr: i32):
    let place = self.lower_expr_place(place_expr)
    let saved_expected = self.expected_type
    let dest_ty = self.expr_type(place_expr)
    if dest_ty != 0 and dest_ty != self.sema.ty_void:
        self.expected_type = dest_ty
    let rhs = self.lower_expr(rhs_expr)
    self.expected_type = saved_expected
    self.assign_operand_to_place(place, rhs, self.ast.get_start(place_expr))

fn MirBuilder.lower_expr_place(self: MirBuilder, node: i32) -> i32:
    if node == 0:
        return self.place_for_local(0)

    let kind = self.ast.kind(node)

    if kind == NK_IDENT:
        let sym = self.ast.get_data0(node)
        let local = self.lookup_local(sym)
        if local >= 0:
            return self.place_for_local(local)
        // Try module-level mutable variable
        let gv_local = self.ensure_global_local(sym)
        if gv_local >= 0:
            return self.place_for_local(gv_local)
        self.mark_unsupported()
        return self.place_for_local(0)

    if kind == NK_FIELD_ACCESS:
        let base = self.lower_field_base_place(self.ast.get_data0(node))
        let field_sym = self.ast.get_data1(node)
        // Field symbol is mapped deterministically to a projection index by symbol value.
        return self.body.new_field_place(base, field_sym)

    if kind == NK_INDEX:
        if self.vec_literal_type(node) != 0:
            let op = self.lower_expr(node)
            let ty = self.expr_type(node)
            let tmp = self.new_temp(ty)
            let p = self.place_for_local(tmp)
            self.assign_operand_to_place(p, op, self.ast.get_start(node))
            return p
        return self.lower_index(self.ast.get_data0(node), self.ast.get_data1(node))

    if kind == NK_UNARY and self.ast.get_data0(node) == UOP_DEREF:
        return self.lower_deref(self.ast.get_data1(node))

    if kind == NK_GROUPED:
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
    let local_id = self.body.new_local(bind_ty, mutable, name_sym, 1)
    self.bind_local(name_sym, local_id)

    self.body.push_stmt(self.cur_bb, SK_STORAGE_LIVE, local_id, 0, self.ast.get_start(node))
    if self.sema.is_copy(bind_ty) == 0:
        self.schedule_drop(local_id, DK_VALUE)

    let saved_expected = self.expected_type
    self.expected_type = bind_ty
    let rhs_op = self.lower_expr(rhs_expr)
    self.expected_type = saved_expected
    let place = self.place_for_local(local_id)
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
        self.body.push_stmt(self.cur_bb, SK_STORAGE_LIVE, local_id, 0, self.ast.get_start(node))
        let field_place = self.body.new_field_place(rhs_place, ni)
        let field_op = self.body.new_operand(OK_COPY, field_place)
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
    self.terminate(TK_GOTO, cont_bb, 0, 0, 0)

    self.switch_to(fail_bb)
    let _ = self.lower_expr(else_body)
    if self.body.term_kind(self.cur_bb) == TK_UNREACHABLE:
        self.terminate(TK_UNREACHABLE, 0, 0, 0, 0)

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
        if sk == NK_LET_BINDING:
            self.lower_let_binding(stmt)
            continue
        if sk == NK_LET_ELSE:
            self.lower_let_else(stmt)
            continue
        if sk == NK_ASSIGN:
            self.lower_assign(self.ast.get_data0(stmt), self.ast.get_data1(stmt))
            continue
        if sk == NK_RETURN:
            let _ = self.lower_return(stmt)
            continue
        if sk == NK_BREAK:
            let _ = self.lower_break(stmt)
            continue
        if sk == NK_CONTINUE:
            let _ = self.lower_continue(stmt)
            continue
        if sk == NK_DEFER:
            let defer_body = self.ast.get_data0(stmt)
            if defer_body != 0:
                self.defer_nodes.push(defer_body)
            continue
        if sk == NK_ERRDEFER:
            let errdefer_body = self.ast.get_data0(stmt)
            if errdefer_body != 0:
                self.errdefer_nodes.push(errdefer_body)
            continue
        if sk == NK_TUPLE_DESTRUCTURE:
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
    targets.push(then_bb)
    let table = self.body.new_switch_table(vals, targets)
    self.terminate(TK_SWITCH_INT, cond_op, table, else_bb, 0)

    let result_ty = self.expr_type(node)
    let result_local = self.new_temp(result_ty)
    let result_place = self.place_for_local(result_local)

    self.switch_to(then_bb)
    let then_op = self.lower_expr(then_expr)
    self.assign_operand_to_place(result_place, then_op, self.ast.get_start(then_expr))
    self.terminate(TK_GOTO, join_bb, 0, 0, 0)

    self.switch_to(else_bb)
    let else_op = if else_expr_opt != 0: self.lower_expr(else_expr_opt) else: self.unit_operand()
    self.assign_operand_to_place(result_place, else_op, self.ast.get_start(node))
    self.terminate(TK_GOTO, join_bb, 0, 0, 0)

    self.switch_to(join_bb)
    if self.sema.is_copy(result_ty) != 0:
        return self.body.new_operand(OK_COPY, result_place)
    self.body.new_operand(OK_MOVE, result_place)

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
    self.terminate(TK_GOTO, join_bb, 0, 0, 0)

    self.switch_to(else_bb)
    let else_op = if else_expr_opt != 0: self.lower_expr(else_expr_opt) else: self.unit_operand()
    self.assign_operand_to_place(result_place, else_op, self.ast.get_start(node))
    self.terminate(TK_GOTO, join_bb, 0, 0, 0)

    self.switch_to(join_bb)
    if self.sema.is_copy(result_ty) != 0:
        return self.body.new_operand(OK_COPY, result_place)
    self.body.new_operand(OK_MOVE, result_place)

fn MirBuilder.lower_loop(self: MirBuilder, body_expr: i32, node: i32) -> i32:
    let header_bb = self.new_block()
    let body_bb = self.new_block()
    let break_bb = self.new_block()

    self.terminate(TK_GOTO, header_bb, 0, 0, 0)

    self.switch_to(header_bb)
    self.terminate(TK_GOTO, body_bb, 0, 0, 0)

    self.push_loop(header_bb, break_bb)

    self.switch_to(body_bb)
    let _ = self.lower_expr(body_expr)
    // Back-edge when body does not diverge.
    self.terminate(TK_GOTO, header_bb, 0, 0, 0)

    self.pop_loop()
    self.switch_to(break_bb)
    self.unit_operand()

fn MirBuilder.lower_while(self: MirBuilder, cond_expr: i32, body_expr: i32) -> i32:
    let cond_bb = self.new_block()
    let body_bb = self.new_block()
    let exit_bb = self.new_block()

    self.terminate(TK_GOTO, cond_bb, 0, 0, 0)

    self.push_loop(cond_bb, exit_bb)

    self.switch_to(cond_bb)
    let cond_op = self.lower_expr(cond_expr)
    let vals: Vec[i32] = Vec.new()
    vals.push(1)
    let targets: Vec[i32] = Vec.new()
    targets.push(body_bb)
    let table = self.body.new_switch_table(vals, targets)
    self.terminate(TK_SWITCH_INT, cond_op, table, exit_bb, 0)

    self.switch_to(body_bb)
    let _ = self.lower_expr(body_expr)
    self.terminate(TK_GOTO, cond_bb, 0, 0, 0)

    self.pop_loop()
    self.switch_to(exit_bb)
    self.unit_operand()

fn MirBuilder.lower_for(self: MirBuilder, pat_or_sym: i32, iter_expr: i32, body_expr: i32) -> i32:
    // Check for range-based for: for i in start..end
    if self.ast.kind(iter_expr) == NK_RANGE:
        return self.lower_for_range(pat_or_sym, iter_expr, body_expr)

    // Check for slice/vec-based for
    let iter_ty = self.expr_type(iter_expr)
    if iter_ty != 0:
        let resolved = self.sema.resolve_alias(iter_ty)
        let tk = self.sema.get_type_kind(resolved)
        if tk == TY_SLICE or tk == TY_ARRAY:
            return self.lower_for_slice(pat_or_sym, iter_expr, body_expr)
        // Vec[T] — use counter-based loop with VEC_LEN / VEC_GET intrinsics
        if tk == TY_GENERIC_INST:
            let type_name_sym = self.sema.get_type_name(resolved)
            if type_name_sym != 0:
                let type_name = self.pool.resolve(type_name_sym)
                if type_name == "Vec":
                    return self.lower_for_vec(pat_or_sym, iter_expr, body_expr)

    // Handle for x in vec.iter() — redirect to lower_for_vec with the Vec receiver.
    if self.ast.kind(iter_expr) == NK_CALL:
        let call_callee = self.ast.get_data0(iter_expr)
        if self.ast.kind(call_callee) == NK_FIELD_ACCESS:
            let recv = self.ast.get_data0(call_callee)
            let msym = self.ast.get_data1(call_callee)
            let mname = self.pool.resolve(msym)
            if mname == "iter":
                let recv_ty = self.expr_type(recv)
                if recv_ty != 0:
                    let recv_resolved = self.sema.resolve_alias(recv_ty)
                    let recv_tk = self.sema.get_type_kind(recv_resolved)
                    if recv_tk == TY_GENERIC_INST:
                        let recv_name_sym = self.sema.get_type_name(recv_resolved)
                        if recv_name_sym != 0:
                            let recv_name = self.pool.resolve(recv_name_sym)
                            if recv_name == "Vec":
                                return self.lower_for_vec(pat_or_sym, recv, body_expr)

    // Iterator protocol: not yet fully implemented in MIR.
    // Fall back to AST codegen for functions using iterator-based for loops.
    self.mark_unsupported()
    let iter_op = self.lower_expr(iter_expr)
    let iter_place = self.materialize_operand(iter_op, iter_ty, self.ast.get_start(iter_expr))
    let elem_ty = self.sema.infer_for_element_type(iter_ty)

    let header_bb = self.new_block()
    let body_bb = self.new_block()
    let exit_bb = self.new_block()

    self.terminate(TK_GOTO, header_bb, 0, 0, 0)
    self.push_loop(header_bb, exit_bb)

    self.switch_to(header_bb)
    let next_args: Vec[i32] = Vec.new()
    next_args.push(self.body.new_operand(OK_COPY, iter_place))
    let args_id = self.body.new_call_args(next_args)
    let next_local = self.new_temp(iter_ty)
    let next_place = self.place_for_local(next_local)
    let after_next_bb = self.new_block()
    self.terminate(TK_CALL, self.unit_operand(), args_id, next_place, after_next_bb)

    self.switch_to(after_next_bb)
    let disc = self.lower_enum_discriminant(next_place)
    let vals: Vec[i32] = Vec.new()
    vals.push(1)
    let targets: Vec[i32] = Vec.new()
    targets.push(body_bb)
    let table = self.body.new_switch_table(vals, targets)
    self.terminate(TK_SWITCH_INT, disc, table, exit_bb, 0)

    self.switch_to(body_bb)
    let item_local = self.new_temp(elem_ty)
    let item_place = self.place_for_local(item_local)
    let next_payload = self.body.new_operand(OK_COPY, next_place)
    self.assign_operand_to_place(item_place, next_payload, self.ast.get_start(iter_expr))

    if pat_or_sym > 0 and pat_or_sym < self.ast.node_count():
        let pk = self.ast.kind(pat_or_sym)
        if pk >= NK_PAT_WILDCARD and pk <= NK_PAT_SLICE:
            let _ = self.lower_pattern(pat_or_sym, item_place)
        else:
            let bind_local = self.body.new_local(elem_ty, 0, pat_or_sym, 1)
            self.bind_local(pat_or_sym, bind_local)
            self.body.push_stmt(self.cur_bb, SK_STORAGE_LIVE, bind_local, 0, self.ast.get_start(body_expr))
            if self.sema.is_copy(elem_ty) == 0:
                self.schedule_drop(bind_local, DK_VALUE)
            let bind_place = self.place_for_local(bind_local)
            let item_op = self.body.new_operand(OK_COPY, item_place)
            self.assign_operand_to_place(bind_place, item_op, self.ast.get_start(body_expr))
    else:
        if pat_or_sym != 0:
            let bind_local = self.body.new_local(elem_ty, 0, pat_or_sym, 1)
            self.bind_local(pat_or_sym, bind_local)
            self.body.push_stmt(self.cur_bb, SK_STORAGE_LIVE, bind_local, 0, self.ast.get_start(body_expr))
            if self.sema.is_copy(elem_ty) == 0:
                self.schedule_drop(bind_local, DK_VALUE)
            let bind_place = self.place_for_local(bind_local)
            let item_op = self.body.new_operand(OK_COPY, item_place)
            self.assign_operand_to_place(bind_place, item_op, self.ast.get_start(body_expr))

    let _ = self.lower_expr(body_expr)
    self.terminate(TK_GOTO, header_bb, 0, 0, 0)

    self.pop_loop()
    self.switch_to(exit_bb)
    self.unit_operand()

fn MirBuilder.lower_for_range(self: MirBuilder, pat_or_sym: i32, range_node: i32, body_expr: i32) -> i32:
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
    let start_rv = self.body.new_rvalue(RK_USE, start_op, 0, 0)
    self.body.push_stmt(self.cur_bb, SK_ASSIGN, counter_place, start_rv, self.ast.get_start(range_node))

    // Store end value in a temp
    let end_local = self.new_temp(elem_ty)
    let end_place = self.place_for_local(end_local)
    let end_rv = self.body.new_rvalue(RK_USE, end_op, 0, 0)
    self.body.push_stmt(self.cur_bb, SK_ASSIGN, end_place, end_rv, self.ast.get_start(range_node))

    let header_bb = self.new_block()
    let body_bb = self.new_block()
    let inc_bb = self.new_block()
    let exit_bb = self.new_block()

    self.terminate(TK_GOTO, header_bb, 0, 0, 0)
    self.push_loop(inc_bb, exit_bb)

    // Header: compare counter < end (or <=)
    self.switch_to(header_bb)
    let counter_op = self.body.new_operand(OK_COPY, counter_place)
    let end_read_op = self.body.new_operand(OK_COPY, end_place)
    let cmp_op = if inclusive != 0: OP_LTE else: OP_LT
    let cmp_rv = self.body.new_rvalue(RK_BIN_OP, cmp_op, counter_op, end_read_op)
    let cmp_local = self.new_temp(self.sema.ty_bool)
    let cmp_place = self.place_for_local(cmp_local)
    self.body.push_stmt(self.cur_bb, SK_ASSIGN, cmp_place, cmp_rv, self.ast.get_start(range_node))
    let cmp_result = self.body.new_operand(OK_COPY, cmp_place)
    let vals: Vec[i32] = Vec.new()
    vals.push(1)
    let targets: Vec[i32] = Vec.new()
    targets.push(body_bb)
    let table = self.body.new_switch_table(vals, targets)
    self.terminate(TK_SWITCH_INT, cmp_result, table, exit_bb, 0)

    // Body: bind loop variable = counter, execute body
    self.switch_to(body_bb)
    if pat_or_sym != 0:
        let bind_local = self.body.new_local(elem_ty, 0, pat_or_sym, 1)
        self.bind_local(pat_or_sym, bind_local)
        self.body.push_stmt(self.cur_bb, SK_STORAGE_LIVE, bind_local, 0, self.ast.get_start(body_expr))
        let bind_place = self.place_for_local(bind_local)
        let cur_op = self.body.new_operand(OK_COPY, counter_place)
        self.assign_operand_to_place(bind_place, cur_op, self.ast.get_start(body_expr))

    let _ = self.lower_expr(body_expr)
    self.terminate(TK_GOTO, inc_bb, 0, 0, 0)

    // Increment: counter = counter + 1, goto header
    self.switch_to(inc_bb)
    let cur_op2 = self.body.new_operand(OK_COPY, counter_place)
    let one_op = self.int_const_operand(1, elem_ty)
    let add_rv = self.body.new_rvalue(RK_BIN_OP, OP_ADD, cur_op2, one_op)
    self.body.push_stmt(self.cur_bb, SK_ASSIGN, counter_place, add_rv, self.ast.get_start(range_node))
    self.terminate(TK_GOTO, header_bb, 0, 0, 0)

    self.pop_loop()
    self.switch_to(exit_bb)
    self.unit_operand()

fn MirBuilder.lower_for_slice(self: MirBuilder, pat_or_sym: i32, iter_expr: i32, body_expr: i32) -> i32:
    // for x in slice → index from 0 to len
    let iter_op = self.lower_expr(iter_expr)
    let iter_ty = self.expr_type(iter_expr)
    let elem_ty = self.sema.infer_for_element_type(iter_ty)

    // Materialize slice into a local
    let slice_place = self.materialize_operand(iter_op, iter_ty, self.ast.get_start(iter_expr))

    // Get length: len_local = RK_LEN(slice_place)
    let len_local = self.new_temp(self.sema.ty_i64)
    let len_place = self.place_for_local(len_local)
    let len_rv = self.body.new_rvalue(RK_LEN, slice_place, 0, 0)
    self.body.push_stmt(self.cur_bb, SK_ASSIGN, len_place, len_rv, self.ast.get_start(iter_expr))

    // Counter: i64 starting at 0
    let counter_local = self.new_temp(self.sema.ty_i64)
    let counter_place = self.place_for_local(counter_local)
    let zero_op = self.int_const_operand(0, self.sema.ty_i64)
    let zero_rv = self.body.new_rvalue(RK_USE, zero_op, 0, 0)
    self.body.push_stmt(self.cur_bb, SK_ASSIGN, counter_place, zero_rv, self.ast.get_start(iter_expr))

    let header_bb = self.new_block()
    let body_bb = self.new_block()
    let inc_bb = self.new_block()
    let exit_bb = self.new_block()

    self.terminate(TK_GOTO, header_bb, 0, 0, 0)
    self.push_loop(inc_bb, exit_bb)

    // Header: counter < len
    self.switch_to(header_bb)
    let counter_op = self.body.new_operand(OK_COPY, counter_place)
    let len_op = self.body.new_operand(OK_COPY, len_place)
    let cmp_rv = self.body.new_rvalue(RK_BIN_OP, OP_LT, counter_op, len_op)
    let cmp_local = self.new_temp(self.sema.ty_bool)
    let cmp_place = self.place_for_local(cmp_local)
    self.body.push_stmt(self.cur_bb, SK_ASSIGN, cmp_place, cmp_rv, self.ast.get_start(iter_expr))
    let cmp_read = self.body.new_operand(OK_COPY, cmp_place)
    let vals: Vec[i32] = Vec.new()
    vals.push(1)
    let targets: Vec[i32] = Vec.new()
    targets.push(body_bb)
    let table = self.body.new_switch_table(vals, targets)
    self.terminate(TK_SWITCH_INT, cmp_read, table, exit_bb, 0)

    // Body: bind element = slice[counter]
    self.switch_to(body_bb)
    let idx_place = self.body.new_index_place(slice_place, counter_local)
    let elem_op = self.body.new_operand(OK_COPY, idx_place)

    if pat_or_sym != 0:
        let bind_local = self.body.new_local(elem_ty, 0, pat_or_sym, 1)
        self.bind_local(pat_or_sym, bind_local)
        self.body.push_stmt(self.cur_bb, SK_STORAGE_LIVE, bind_local, 0, self.ast.get_start(body_expr))
        let bind_place = self.place_for_local(bind_local)
        self.assign_operand_to_place(bind_place, elem_op, self.ast.get_start(body_expr))

    let _ = self.lower_expr(body_expr)
    self.terminate(TK_GOTO, inc_bb, 0, 0, 0)

    // Increment: counter += 1
    self.switch_to(inc_bb)
    let cur_op2 = self.body.new_operand(OK_COPY, counter_place)
    let one_op = self.int_const_operand(1, self.sema.ty_i64)
    let add_rv = self.body.new_rvalue(RK_BIN_OP, OP_ADD, cur_op2, one_op)
    self.body.push_stmt(self.cur_bb, SK_ASSIGN, counter_place, add_rv, self.ast.get_start(iter_expr))
    self.terminate(TK_GOTO, header_bb, 0, 0, 0)

    self.pop_loop()
    self.switch_to(exit_bb)
    self.unit_operand()

fn MirBuilder.lower_for_vec(self: MirBuilder, pat_or_sym: i32, iter_expr: i32, body_expr: i32) -> i32:
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
    len_args.push(self.body.new_operand(OK_COPY, vec_place))
    let len_args_id = self.body.new_call_args(len_args)
    self.body.set_call_intrinsic(len_args_id, MIR_INTRINSIC_VEC_LEN)
    let len_after_bb = self.new_block()
    self.terminate(TK_CALL, self.unit_operand(), len_args_id, len_place, len_after_bb)
    self.switch_to(len_after_bb)

    // Counter: i64 starting at 0
    let counter_local = self.new_temp(self.sema.ty_i64)
    let counter_place = self.place_for_local(counter_local)
    let zero_op = self.int_const_operand(0, self.sema.ty_i64)
    let zero_rv = self.body.new_rvalue(RK_USE, zero_op, 0, 0)
    self.body.push_stmt(self.cur_bb, SK_ASSIGN, counter_place, zero_rv, self.ast.get_start(iter_expr))

    let header_bb = self.new_block()
    let body_bb = self.new_block()
    let inc_bb = self.new_block()
    let exit_bb = self.new_block()

    self.terminate(TK_GOTO, header_bb, 0, 0, 0)
    self.push_loop(inc_bb, exit_bb)

    // Header: counter < len
    self.switch_to(header_bb)
    let counter_op = self.body.new_operand(OK_COPY, counter_place)
    let len_op = self.body.new_operand(OK_COPY, len_place)
    let cmp_rv = self.body.new_rvalue(RK_BIN_OP, OP_LT, counter_op, len_op)
    let cmp_local = self.new_temp(self.sema.ty_bool)
    let cmp_place = self.place_for_local(cmp_local)
    self.body.push_stmt(self.cur_bb, SK_ASSIGN, cmp_place, cmp_rv, self.ast.get_start(iter_expr))
    let cmp_read = self.body.new_operand(OK_COPY, cmp_place)
    let vals: Vec[i32] = Vec.new()
    vals.push(1)
    let targets: Vec[i32] = Vec.new()
    targets.push(body_bb)
    let table = self.body.new_switch_table(vals, targets)
    self.terminate(TK_SWITCH_INT, cmp_read, table, exit_bb, 0)

    // Body: elem = vec.get(counter) via VEC_GET intrinsic
    self.switch_to(body_bb)
    let elem_local = self.new_temp(elem_ty)
    let elem_place = self.place_for_local(elem_local)
    let get_args: Vec[i32] = Vec.new()
    get_args.push(self.body.new_operand(OK_COPY, vec_place))
    get_args.push(self.body.new_operand(OK_COPY, counter_place))
    let get_args_id = self.body.new_call_args(get_args)
    self.body.set_call_intrinsic(get_args_id, MIR_INTRINSIC_VEC_GET)
    let get_after_bb = self.new_block()
    self.terminate(TK_CALL, self.unit_operand(), get_args_id, elem_place, get_after_bb)
    self.switch_to(get_after_bb)

    // Bind loop variable
    if pat_or_sym != 0:
        let bind_local = self.body.new_local(elem_ty, 0, pat_or_sym, 1)
        self.bind_local(pat_or_sym, bind_local)
        self.body.push_stmt(self.cur_bb, SK_STORAGE_LIVE, bind_local, 0, self.ast.get_start(body_expr))
        let bind_place = self.place_for_local(bind_local)
        let elem_op = self.body.new_operand(OK_COPY, elem_place)
        self.assign_operand_to_place(bind_place, elem_op, self.ast.get_start(body_expr))

    let _ = self.lower_expr(body_expr)
    self.terminate(TK_GOTO, inc_bb, 0, 0, 0)

    // Increment: counter += 1
    self.switch_to(inc_bb)
    let cur_op2 = self.body.new_operand(OK_COPY, counter_place)
    let one_op = self.int_const_operand(1, self.sema.ty_i64)
    let add_rv = self.body.new_rvalue(RK_BIN_OP, OP_ADD, cur_op2, one_op)
    self.body.push_stmt(self.cur_bb, SK_ASSIGN, counter_place, add_rv, self.ast.get_start(iter_expr))
    self.terminate(TK_GOTO, header_bb, 0, 0, 0)

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
    self.terminate(TK_GOTO, loop_info.break_bb, 0, 0, 0)

    // Continue lowering in a fresh detached block to keep pass total.
    self.switch_to(self.new_block())
    self.unit_operand()

fn MirBuilder.lower_continue(self: MirBuilder, _node: i32) -> i32:
    let loop_info = self.current_loop()
    if loop_info.continue_bb < 0:
        return self.unit_operand()

    self.emit_drops_for_break(loop_info)
    self.terminate(TK_GOTO, loop_info.continue_bb, 0, 0, 0)
    self.switch_to(self.new_block())
    self.unit_operand()

fn MirBuilder.lower_return(self: MirBuilder, node: i32) -> i32:
    let value_expr = self.ast.get_data0(node)
    let ret_op = if value_expr != 0: self.lower_expr(value_expr) else: self.unit_operand()
    let ret_place = self.place_for_local(0)
    self.assign_operand_to_place(ret_place, ret_op, self.ast.get_start(node))

    self.emit_defers_for_return()
    self.emit_drops_for_return()
    self.terminate(TK_RETURN, 0, 0, 0, 0)

    // Keep lowering total by switching to an unreachable continuation block.
    self.switch_to(self.new_block())
    self.unit_operand()

fn MirBuilder.lower_unreachable(self: MirBuilder) -> i32:
    self.terminate(TK_UNREACHABLE, 0, 0, 0, 0)
    self.switch_to(self.new_block())
    self.unit_operand()

fn MirBuilder.lower_enum_discriminant(self: MirBuilder, place: i32) -> i32:
    let rv = self.body.new_rvalue(RK_DISCRIMINANT, place, 0, 0)
    let disc_local = self.new_temp(self.sema.ty_i32)
    let disc_place = self.place_for_local(disc_local)
    self.body.push_stmt(self.cur_bb, SK_ASSIGN, disc_place, rv, 0)
    self.body.new_operand(OK_COPY, disc_place)

fn MirBuilder.lower_pattern_match(self: MirBuilder, scrutinee_place: i32, pat_node: i32, arm_bb: i32, fail_bb: i32):
    if pat_node == 0:
        self.terminate(TK_GOTO, arm_bb, 0, 0, 0)
        return

    let pk = self.ast.kind(pat_node)
    if pk == NK_PAT_WILDCARD or pk == NK_PAT_IDENT:
        self.terminate(TK_GOTO, arm_bb, 0, 0, 0)
        return

    if pk == NK_PAT_AT_BINDING:
        let inner_pat = self.ast.get_data1(pat_node)
        if inner_pat != 0:
            self.lower_pattern_match(scrutinee_place, inner_pat, arm_bb, fail_bb)
        else:
            self.terminate(TK_GOTO, arm_bb, 0, 0, 0)
        return

    if pk == NK_PAT_OR:
        let p_start = self.ast.get_data0(pat_node)
        let p_count = self.ast.get_data1(pat_node)
        if p_count <= 0:
            self.terminate(TK_GOTO, fail_bb, 0, 0, 0)
            return
        var next_test_bb = self.cur_bb
        for pi in 0..p_count:
            let alt_pat = self.ast.get_extra(p_start + pi)
            let alt_fail = if pi + 1 < p_count: self.new_block() else: fail_bb
            self.switch_to(next_test_bb)
            self.lower_pattern_match(scrutinee_place, alt_pat, arm_bb, alt_fail)
            next_test_bb = alt_fail
        return

    if pk == NK_PAT_VARIANT or pk == NK_PAT_ENUM_SHORTHAND:
        let variant_sym = self.ast.get_data0(pat_node)
        var idx = self.variant_index(variant_sym)
        // For disc enums, use the actual discriminant value
        if self.sema.variant_lookup.contains(variant_sym):
            if self.sema.disc_values.contains(variant_sym):
                idx = self.sema.disc_values.get(variant_sym).unwrap()
        let disc = self.lower_enum_discriminant(scrutinee_place)
        let vals: Vec[i32] = Vec.new()
        vals.push(idx)
        let targets: Vec[i32] = Vec.new()
        targets.push(arm_bb)
        let table = self.body.new_switch_table(vals, targets)
        self.terminate(TK_SWITCH_INT, disc, table, fail_bb, 0)
        return

    let scrutinee_op = self.body.new_operand(OK_COPY, scrutinee_place)
    if pk == NK_PAT_INT or pk == NK_PAT_BOOL or pk == NK_PAT_STRING:
        let lit = if pk == NK_PAT_INT:
            self.lower_int_lit(self.ast.int_lit_value(pat_node), self.sema.ty_i32)
        else if pk == NK_PAT_BOOL:
            self.lower_bool_lit(self.ast.get_data0(pat_node))
        else:
            self.lower_str_lit(self.ast.get_data0(pat_node))
        let cmp_rv = self.body.new_rvalue(RK_BIN_OP, OP_EQ, scrutinee_op, lit)
        let cmp_tmp = self.new_temp(self.sema.ty_bool)
        let cmp_place = self.place_for_local(cmp_tmp)
        self.body.push_stmt(self.cur_bb, SK_ASSIGN, cmp_place, cmp_rv, self.ast.get_start(pat_node))
        let cmp_op = self.body.new_operand(OK_COPY, cmp_place)
        let vals: Vec[i32] = Vec.new()
        vals.push(1)
        let targets: Vec[i32] = Vec.new()
        targets.push(arm_bb)
        let table = self.body.new_switch_table(vals, targets)
        self.terminate(TK_SWITCH_INT, cmp_op, table, fail_bb, 0)
        return

    if pk == NK_PAT_RANGE:
        let range_lo = self.ast.get_data0(pat_node)
        let range_hi = self.ast.get_data1(pat_node)
        let inclusive = self.ast.get_data2(pat_node)
        let lo_lit = self.lower_int_lit(range_lo as i64, self.sema.ty_i32)
        let hi_lit = self.lower_int_lit(range_hi as i64, self.sema.ty_i32)
        let ge_rv = self.body.new_rvalue(RK_BIN_OP, OP_GTE, scrutinee_op, lo_lit)
        let ge_tmp = self.new_temp(self.sema.ty_bool)
        let ge_place = self.place_for_local(ge_tmp)
        self.body.push_stmt(self.cur_bb, SK_ASSIGN, ge_place, ge_rv, self.ast.get_start(pat_node))
        let ge_op = self.body.new_operand(OK_COPY, ge_place)
        let range_hi_bb = self.new_block()
        let ge_vals: Vec[i32] = Vec.new()
        ge_vals.push(1)
        let ge_targets: Vec[i32] = Vec.new()
        ge_targets.push(range_hi_bb)
        let ge_table = self.body.new_switch_table(ge_vals, ge_targets)
        self.terminate(TK_SWITCH_INT, ge_op, ge_table, fail_bb, 0)
        self.switch_to(range_hi_bb)
        let scrutinee_op2 = self.body.new_operand(OK_COPY, scrutinee_place)
        let hi_cmp_op = if inclusive != 0: OP_LTE else: OP_LT
        let le_rv = self.body.new_rvalue(RK_BIN_OP, hi_cmp_op, scrutinee_op2, hi_lit)
        let le_tmp = self.new_temp(self.sema.ty_bool)
        let le_place = self.place_for_local(le_tmp)
        self.body.push_stmt(self.cur_bb, SK_ASSIGN, le_place, le_rv, self.ast.get_start(pat_node))
        let le_op = self.body.new_operand(OK_COPY, le_place)
        let le_vals: Vec[i32] = Vec.new()
        le_vals.push(1)
        let le_targets: Vec[i32] = Vec.new()
        le_targets.push(arm_bb)
        let le_table = self.body.new_switch_table(le_vals, le_targets)
        self.terminate(TK_SWITCH_INT, le_op, le_table, fail_bb, 0)
        return

    if pk == NK_PAT_TUPLE:
        let tup_start = self.ast.get_data0(pat_node)
        let tup_count = self.ast.get_data1(pat_node)
        var cur_test_bb = self.cur_bb
        for ti in 0..tup_count:
            let elem_pat = self.ast.get_extra(tup_start + ti)
            let elem_pk = self.ast.kind(elem_pat)
            if elem_pk == NK_PAT_WILDCARD or elem_pk == NK_PAT_IDENT:
                continue
            let elem_place = self.body.new_field_place(scrutinee_place, ti)
            let next_test = self.new_block()
            self.switch_to(cur_test_bb)
            self.lower_pattern_match(elem_place, elem_pat, next_test, fail_bb)
            cur_test_bb = next_test
        // cur_test_bb is the block reached after all concrete checks pass.
        // Emit a goto to the arm block.
        self.switch_to(cur_test_bb)
        self.terminate(TK_GOTO, arm_bb, 0, 0, 0)
        return

    // Dyn trait typed-bind pattern: vtable comparison via intrinsic.
    if pk == NK_PAT_TYPED_BIND:
        let tb_type_sym = self.ast.get_data1(pat_node)
        // Get trait_sym from scrutinee's sema type (TY_TRAIT_OBJ.d0)
        let tb_scrutinee_ty = self.place_local_type(scrutinee_place)
        var tb_trait_sym: i32 = 0
        if self.sema.get_type_kind(tb_scrutinee_ty) == TY_TRAIT_OBJ:
            tb_trait_sym = self.sema.get_type_d0(tb_scrutinee_ty)
        // Emit MIR_INTRINSIC_DYN_VTABLE_CMP(scrutinee, type_sym, trait_sym) → bool
        let tb_fn_op = self.const_operand(CK_FN, 0, self.sema.ty_void)
        let tb_scrutinee_op = self.body.new_operand(OK_COPY, scrutinee_place)
        let tb_type_const = self.int_const_operand(tb_type_sym as i64, self.sema.ty_i32)
        let tb_trait_const = self.int_const_operand(tb_trait_sym as i64, self.sema.ty_i32)
        let tb_args: Vec[i32] = Vec.new()
        tb_args.push(tb_scrutinee_op)
        tb_args.push(tb_type_const)
        tb_args.push(tb_trait_const)
        let tb_args_id = self.body.new_call_args(tb_args)
        self.body.set_call_intrinsic(tb_args_id, MIR_INTRINSIC_DYN_VTABLE_CMP)
        let tb_result = self.new_temp(self.sema.ty_bool)
        let tb_result_place = self.place_for_local(tb_result)
        let tb_switch_bb = self.new_block()
        self.terminate(TK_CALL, tb_fn_op, tb_args_id, tb_result_place, tb_switch_bb)
        self.switch_to(tb_switch_bb)
        let tb_cmp_op = self.body.new_operand(OK_COPY, tb_result_place)
        let tb_vals: Vec[i32] = Vec.new()
        tb_vals.push(1)
        let tb_targets: Vec[i32] = Vec.new()
        tb_targets.push(arm_bb)
        let tb_table = self.body.new_switch_table(tb_vals, tb_targets)
        self.terminate(TK_SWITCH_INT, tb_cmp_op, tb_table, fail_bb, 0)
        return

    // NK_PAT_SLICE: check array length against pattern count
    if pk == NK_PAT_SLICE:
        let sp_head = self.ast.get_data1(pat_node)
        let sp_extra = self.ast.get_data0(pat_node)
        let sp_has_rest = self.ast.get_extra(sp_extra)
        // Get array length from scrutinee sema type
        let sp_arr_ty = self.place_local_type(scrutinee_place)
        let sp_arr_tk = self.sema.get_type_kind(sp_arr_ty)
        if sp_arr_tk == TY_ARRAY:
            let sp_arr_len = self.sema.get_type_d1(sp_arr_ty)
            if sp_has_rest != 0:
                // [a, b, ..rest] matches if arr_len >= head_count
                if sp_arr_len >= sp_head:
                    self.terminate(TK_GOTO, arm_bb, 0, 0, 0)
                else:
                    self.terminate(TK_GOTO, fail_bb, 0, 0, 0)
            else:
                // [a, b, c] matches only if arr_len == head_count
                if sp_arr_len == sp_head:
                    self.terminate(TK_GOTO, arm_bb, 0, 0, 0)
                else:
                    self.terminate(TK_GOTO, fail_bb, 0, 0, 0)
            return

    // Other patterns (struct) are conservatively accepted here.
    self.terminate(TK_GOTO, arm_bb, 0, 0, 0)

fn MirBuilder.lower_pattern(self: MirBuilder, pat_node: i32, scrutinee_place: i32) -> Vec[i32]:
    let out: Vec[i32] = Vec.new()
    if pat_node == 0:
        return out

    let pk = self.ast.kind(pat_node)
    if pk == NK_PAT_WILDCARD:
        return out

    if pk == NK_PAT_IDENT:
        let sym = self.ast.get_data0(pat_node)
        let bind_ty = self.place_local_type(scrutinee_place)
        let local_id = self.body.new_local(bind_ty, 0, sym, 1)
        self.bind_local(sym, local_id)
        self.body.push_stmt(self.cur_bb, SK_STORAGE_LIVE, local_id, 0, self.ast.get_start(pat_node))
        if self.sema.is_copy(bind_ty) == 0:
            self.schedule_drop(local_id, DK_VALUE)
        let src_op = self.body.new_operand(if self.sema.is_copy(bind_ty) != 0: OK_COPY else: OK_MOVE, scrutinee_place)
        self.assign_operand_to_place(self.place_for_local(local_id), src_op, self.ast.get_start(pat_node))
        out.push(local_id)
        out.push(scrutinee_place)
        return out

    if pk == NK_PAT_AT_BINDING:
        let outer_sym = self.ast.get_data0(pat_node)
        let outer_ty = self.place_local_type(scrutinee_place)
        let outer_local = self.body.new_local(outer_ty, 0, outer_sym, 1)
        self.bind_local(outer_sym, outer_local)
        self.body.push_stmt(self.cur_bb, SK_STORAGE_LIVE, outer_local, 0, self.ast.get_start(pat_node))
        if self.sema.is_copy(outer_ty) == 0:
            self.schedule_drop(outer_local, DK_VALUE)
        let outer_op = self.body.new_operand(if self.sema.is_copy(outer_ty) != 0: OK_COPY else: OK_MOVE, scrutinee_place)
        self.assign_operand_to_place(self.place_for_local(outer_local), outer_op, self.ast.get_start(pat_node))
        out.push(outer_local)
        out.push(scrutinee_place)
        let inner = self.lower_pattern(self.ast.get_data1(pat_node), scrutinee_place)
        for i in 0..inner.len() as i32:
            out.push(inner.get(i as i64))
        return out

    if pk == NK_PAT_VARIANT or pk == NK_PAT_ENUM_SHORTHAND:
        let variant_sym = self.ast.get_data0(pat_node)
        let bind_start = self.ast.get_data1(pat_node)
        let bind_count = self.ast.get_data2(pat_node)
        let variant_place = self.body.new_downcast_place(scrutinee_place, self.variant_index(variant_sym))
        for bi in 0..bind_count:
            let raw = self.ast.get_extra(bind_start + bi)
            // Let-else parser stores NK_PAT_IDENT nodes; match parser stores raw symbols
            let sym = if self.ast.kind(raw) == NK_PAT_IDENT: self.ast.get_data0(raw) else: raw
            let field_place = self.body.new_field_place(variant_place, bi)
            let bind_ty = self.place_local_type(field_place)
            let local_id = self.body.new_local(bind_ty, 0, sym, 1)
            self.bind_local(sym, local_id)
            self.body.push_stmt(self.cur_bb, SK_STORAGE_LIVE, local_id, 0, self.ast.get_start(pat_node))
            if self.sema.is_copy(bind_ty) == 0:
                self.schedule_drop(local_id, DK_VALUE)
            let src_op = self.body.new_operand(if self.sema.is_copy(bind_ty) != 0: OK_COPY else: OK_MOVE, field_place)
            self.assign_operand_to_place(self.place_for_local(local_id), src_op, self.ast.get_start(pat_node))
            out.push(local_id)
            out.push(field_place)
        return out

    if pk == NK_PAT_TUPLE:
        let t_start = self.ast.get_data0(pat_node)
        let t_count = self.ast.get_data1(pat_node)
        for ti in 0..t_count:
            let elem_pat = self.ast.get_extra(t_start + ti)
            let field_place = self.body.new_field_place(scrutinee_place, ti)
            let inner = self.lower_pattern(elem_pat, field_place)
            for i in 0..inner.len() as i32:
                out.push(inner.get(i as i64))
        return out

    if pk == NK_PAT_STRUCT:
        let s_start = self.ast.get_data1(pat_node)
        let s_count = self.ast.get_data2(pat_node)
        for si in 0..s_count:
            let field_name = self.ast.get_extra(s_start + 1 + si * 2)
            let field_pat = self.ast.get_extra(s_start + 1 + si * 2 + 1)
            let field_place = self.body.new_field_place(scrutinee_place, field_name)
            if field_pat != 0:
                let inner = self.lower_pattern(field_pat, field_place)
                for i in 0..inner.len() as i32:
                    out.push(inner.get(i as i64))
            else:
                let bind_ty = self.place_local_type(field_place)
                let local_id = self.body.new_local(bind_ty, 0, field_name, 1)
                self.bind_local(field_name, local_id)
                self.body.push_stmt(self.cur_bb, SK_STORAGE_LIVE, local_id, 0, self.ast.get_start(pat_node))
                if self.sema.is_copy(bind_ty) == 0:
                    self.schedule_drop(local_id, DK_VALUE)
                let src_op = self.body.new_operand(if self.sema.is_copy(bind_ty) != 0: OK_COPY else: OK_MOVE, field_place)
                self.assign_operand_to_place(self.place_for_local(local_id), src_op, self.ast.get_start(pat_node))
                out.push(local_id)
                out.push(field_place)
        return out

    if pk == NK_PAT_OR:
        let p_start = self.ast.get_data0(pat_node)
        if self.ast.get_data1(pat_node) > 0:
            return self.lower_pattern(self.ast.get_extra(p_start), scrutinee_place)
        return out

    if pk == NK_PAT_TYPED_BIND:
        let tb_bind_sym = self.ast.get_data0(pat_node)
        let tb_type_sym = self.ast.get_data1(pat_node)
        // Look up concrete sema type for the type symbol
        let tb_sema_sym = self.sema.pool_intern(self.pool.resolve_symbol(tb_type_sym))
        var tb_concrete_ty = self.sema.ty_i32
        if self.sema.named_types.contains(tb_sema_sym):
            tb_concrete_ty = self.sema.named_types.get(tb_sema_sym).unwrap()
        // Emit MIR_INTRINSIC_DYN_DOWNCAST(scrutinee, type_sym) → concrete value
        let dc_fn_op = self.const_operand(CK_FN, 0, self.sema.ty_void)
        let dc_scrutinee_op = self.body.new_operand(OK_COPY, scrutinee_place)
        let dc_type_const = self.int_const_operand(tb_type_sym as i64, self.sema.ty_i32)
        let dc_args: Vec[i32] = Vec.new()
        dc_args.push(dc_scrutinee_op)
        dc_args.push(dc_type_const)
        let dc_args_id = self.body.new_call_args(dc_args)
        self.body.set_call_intrinsic(dc_args_id, MIR_INTRINSIC_DYN_DOWNCAST)
        let local_id = self.body.new_local(tb_concrete_ty, 0, tb_bind_sym, 1)
        self.bind_local(tb_bind_sym, local_id)
        let dc_result_place = self.place_for_local(local_id)
        let dc_next_bb = self.new_block()
        self.terminate(TK_CALL, dc_fn_op, dc_args_id, dc_result_place, dc_next_bb)
        self.switch_to(dc_next_bb)
        out.push(local_id)
        out.push(scrutinee_place)
        return out

    if pk == NK_PAT_SLICE:
        let sp_extra = self.ast.get_data0(pat_node)
        let sp_head_count = self.ast.get_data1(pat_node)
        // Get element type from scrutinee's array type
        let sp_arr_ty = self.place_local_type(scrutinee_place)
        var sp_elem_ty = self.sema.ty_i32
        let sp_arr_tk = self.sema.get_type_kind(sp_arr_ty)
        if sp_arr_tk == TY_ARRAY:
            let ety = self.sema.get_type_d0(sp_arr_ty)
            if ety != 0:
                sp_elem_ty = ety
        // extras: [has_rest, head_sym0, head_sym1, ..., tail_count, tail_sym0, ...]
        let sp_arr_len = if sp_arr_tk == TY_ARRAY: self.sema.get_type_d1(sp_arr_ty) else: 0
        // Bind head variables
        for si in 0..sp_head_count:
            let sym = self.ast.get_extra(sp_extra + 1 + si)
            if sym == 0:
                continue
            let field_place = self.body.new_field_place(scrutinee_place, si)
            let local_id = self.body.new_local(sp_elem_ty, 0, sym, 1)
            self.bind_local(sym, local_id)
            self.body.push_stmt(self.cur_bb, SK_STORAGE_LIVE, local_id, 0, self.ast.get_start(pat_node))
            let src_op = self.body.new_operand(if self.sema.is_copy(sp_elem_ty) != 0: OK_COPY else: OK_MOVE, field_place)
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
            let field_place = self.body.new_field_place(scrutinee_place, field_idx)
            let local_id = self.body.new_local(sp_elem_ty, 0, sym, 1)
            self.bind_local(sym, local_id)
            self.body.push_stmt(self.cur_bb, SK_STORAGE_LIVE, local_id, 0, self.ast.get_start(pat_node))
            let src_op = self.body.new_operand(if self.sema.is_copy(sp_elem_ty) != 0: OK_COPY else: OK_MOVE, field_place)
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
            targets.push(guard_pass_bb)
            let table = self.body.new_switch_table(vals, targets)
            self.terminate(TK_SWITCH_INT, guard_op, table, fail_bb, 0)
            self.switch_to(guard_pass_bb)

        let arm_value = self.lower_expr(body_node)
        self.assign_operand_to_place(result_place, arm_value, self.ast.get_start(body_node))
        self.terminate(TK_GOTO, join_bb, 0, 0, 0)

        dispatch_bb = fail_bb

    self.switch_to(join_bb)
    if self.sema.is_copy(result_ty) != 0:
        return self.body.new_operand(OK_COPY, result_place)
    self.body.new_operand(OK_MOVE, result_place)

fn MirBuilder.lower_call(self: MirBuilder, fn_expr: i32, arg_exprs_start: i32, arg_exprs_count: i32, ret_type_id: i32, node: i32) -> i32:
    let fn_op = self.lower_expr(fn_expr)
    let sig_idx = self.call_sig_for_expr(fn_expr)

    let args: Vec[i32] = Vec.new()
    for i in 0..arg_exprs_count:
        let arg_node = self.ast.get_extra(arg_exprs_start + i)
        args.push(self.lower_call_arg(arg_node, sig_idx, i))

    let args_id = self.body.new_call_args(args)
    let result_local = self.new_temp(ret_type_id)
    let result_place = self.place_for_local(result_local)
    let next_bb = self.new_block()

    self.terminate(TK_CALL, fn_op, args_id, result_place, next_bb)
    self.switch_to(next_bb)

    if self.sema.is_copy(ret_type_id) != 0:
        return self.body.new_operand(OK_COPY, result_place)
    self.body.new_operand(OK_MOVE, result_place)

// Callable type redirect: like lower_call but uses a pre-resolved fn operand and symbol.
fn MirBuilder.lower_call_redirected(self: MirBuilder, fn_op: i32, fn_sym: i32, arg_exprs_start: i32, arg_exprs_count: i32, ret_type_id: i32, node: i32) -> i32:
    let sig_idx = self.call_sig_for_sym(fn_sym)
    let args: Vec[i32] = Vec.new()
    for i in 0..arg_exprs_count:
        let arg_node = self.ast.get_extra(arg_exprs_start + i)
        args.push(self.lower_call_arg(arg_node, sig_idx, i))
    let args_id = self.body.new_call_args(args)
    let result_local = self.new_temp(ret_type_id)
    let result_place = self.place_for_local(result_local)
    let next_bb = self.new_block()
    self.terminate(TK_CALL, fn_op, args_id, result_place, next_bb)
    self.switch_to(next_bb)
    if self.sema.is_copy(ret_type_id) != 0:
        return self.body.new_operand(OK_COPY, result_place)
    self.body.new_operand(OK_MOVE, result_place)

// Like lower_call but takes arg node indices in a Vec instead of reading from
// pool.extra. This avoids mutating the shared AstPool (which would trigger
// Vec realloc and invalidate other copies' pointers — use-after-free).
fn MirBuilder.lower_call_with_arg_nodes(self: MirBuilder, fn_op: i32, callee_sym: i32, arg_node_vec: Vec[i32], ret_type_id: i32, node: i32) -> i32:
    let sig_idx = self.call_sig_for_sym(callee_sym)
    let args: Vec[i32] = Vec.new()
    for i in 0..arg_node_vec.len() as i32:
        args.push(self.lower_call_arg(arg_node_vec.get(i as i64), sig_idx, i))
    let args_id = self.body.new_call_args(args)
    let result_local = self.new_temp(ret_type_id)
    let result_place = self.place_for_local(result_local)
    let next_bb = self.new_block()
    self.terminate(TK_CALL, fn_op, args_id, result_place, next_bb)
    self.switch_to(next_bb)
    if self.sema.is_copy(ret_type_id) != 0:
        return self.body.new_operand(OK_COPY, result_place)
    self.body.new_operand(OK_MOVE, result_place)

fn MirBuilder.call_sig_for_sym(self: MirBuilder, sym: i32) -> i32:
    if sym == 0:
        return -1
    let direct = self.sema.get_sig(sym)
    if direct >= 0:
        return direct
    let name = self.pool.resolve_symbol(sym)
    if name.len() == 0:
        return -1
    let sema_sym = self.sema.pool_intern(name)
    self.sema.get_sig(sema_sym)

fn MirBuilder.call_sig_for_expr(self: MirBuilder, fn_expr: i32) -> i32:
    if fn_expr == 0:
        return -1
    if self.ast.kind(fn_expr) != NK_IDENT:
        return -1
    self.call_sig_for_sym(self.ast.get_data0(fn_expr))

fn MirBuilder.lower_call_arg(self: MirBuilder, arg_node: i32, sig_idx: i32, arg_i: i32) -> i32:
    let saved_expected = self.expected_type
    if sig_idx >= 0 and arg_i >= 0 and arg_i < self.sema.sig_get_param_count(sig_idx):
        let expected_ty = self.sema.sig_param_type(sig_idx, arg_i)
        if expected_ty != 0 and expected_ty != self.sema.ty_void:
            self.expected_type = expected_ty
    let lowered = self.lower_expr(arg_node)
    self.expected_type = saved_expected
    lowered

fn MirBuilder.resolve_method_callee_sym(self: MirBuilder, self_expr: i32, method_sym: i32) -> i32:
    // Translate method_sym from AST pool to sema pool for method_key lookups
    let sema_method_sym = self.sema.pool_intern(self.pool.resolve_symbol(method_sym))
    let obj_type = self.expr_type(self_expr)
    if obj_type != 0 and obj_type != self.sema.ty_void:
        let resolved = self.sema.resolve_alias(obj_type)
        let type_name_sym = self.sema.get_type_name(resolved)
        if type_name_sym != 0:
            let method_key = self.sema.method_key(type_name_sym, sema_method_sym)
            if self.sema.get_sig(method_key) >= 0:
                return method_key
        // For builtin types (i32, str, bool, etc.), try the type kind name
        let tk = self.sema.get_type_kind(resolved)
        if tk == TY_INT:
            let int_sym = self.sema.pool_intern("i32")
            let method_key = self.sema.method_key(int_sym, sema_method_sym)
            if self.sema.get_sig(method_key) >= 0:
                return method_key
        if tk == TY_STR:
            let str_sym = self.sema.pool_intern("str")
            let method_key = self.sema.method_key(str_sym, sema_method_sym)
            if self.sema.get_sig(method_key) >= 0:
                return method_key
        if tk == TY_BOOL:
            let bool_sym = self.sema.pool_intern("bool")
            let method_key = self.sema.method_key(bool_sym, sema_method_sym)
            if self.sema.get_sig(method_key) >= 0:
                return method_key
        if tk == TY_FLOAT:
            let float_sym = self.sema.pool_intern("f64")
            let method_key = self.sema.method_key(float_sym, sema_method_sym)
            if self.sema.get_sig(method_key) >= 0:
                return method_key

    if self.ast.kind(self_expr) == NK_IDENT:
        let type_sym = self.ast.get_data0(self_expr)
        let method_key = self.sema.method_key(type_sym, method_sym)
        if self.sema.get_sig(method_key) >= 0:
            return method_key

    // Handle Vec[i32].method() — receiver is NK_INDEX of a type name
    if self.ast.kind(self_expr) == NK_INDEX:
        let base = self.ast.get_data0(self_expr)
        if self.ast.kind(base) == NK_IDENT:
            let type_sym = self.ast.get_data0(base)
            let method_key = self.sema.method_key(type_sym, method_sym)
            if self.sema.get_sig(method_key) >= 0:
                return method_key

    method_sym

fn MirBuilder.classify_intrinsic(self: MirBuilder, recv_type: i32, method_name: str) -> i32:
    if recv_type == 0 or method_name.len() == 0:
        return MIR_INTRINSIC_NONE
    let resolved = self.sema.resolve_alias(recv_type)
    // Check primitive types first (no type_name_sym for TY_STR, TY_INT, etc.)
    let tk = self.sema.get_type_kind(resolved)
    if tk == TY_STR:
        if method_name == "len": return MIR_INTRINSIC_STR_LEN
        if method_name == "byte_at": return MIR_INTRINSIC_STR_BYTE_AT
        if method_name == "slice": return MIR_INTRINSIC_STR_SLICE
        if method_name == "contains": return MIR_INTRINSIC_STR_CONTAINS
        if method_name == "starts_with": return MIR_INTRINSIC_STR_STARTS_WITH
        if method_name == "ends_with": return MIR_INTRINSIC_STR_ENDS_WITH
        if method_name == "find": return MIR_INTRINSIC_STR_FIND
        if method_name == "split": return MIR_INTRINSIC_STR_SPLIT
        if method_name == "trim": return MIR_INTRINSIC_STR_TRIM
        if method_name == "to_upper": return MIR_INTRINSIC_STR_TO_UPPER
        if method_name == "to_lower": return MIR_INTRINSIC_STR_TO_LOWER
        if method_name == "replace": return MIR_INTRINSIC_STR_REPLACE
        if method_name == "index_of": return MIR_INTRINSIC_STR_INDEX_OF
        if method_name == "repeat": return MIR_INTRINSIC_STR_REPEAT
        return MIR_INTRINSIC_NONE
    if tk == TY_ARRAY:
        if method_name == "len": return MIR_INTRINSIC_ARR_LEN
        return MIR_INTRINSIC_NONE
    let type_name_sym = self.sema.get_type_name(resolved)
    if type_name_sym == 0:
        return MIR_INTRINSIC_NONE
    let type_name = self.pool.resolve_symbol(type_name_sym)
    if type_name == "Vec":
        if method_name == "new": return MIR_INTRINSIC_VEC_NEW
        if method_name == "push": return MIR_INTRINSIC_VEC_PUSH
        if method_name == "get": return MIR_INTRINSIC_VEC_GET
        if method_name == "len": return MIR_INTRINSIC_VEC_LEN
        if method_name == "set_i32": return MIR_INTRINSIC_VEC_SET
        if method_name == "remove": return MIR_INTRINSIC_VEC_REMOVE
        if method_name == "clear": return MIR_INTRINSIC_VEC_CLEAR
        if method_name == "pop": return MIR_INTRINSIC_VEC_POP
        if method_name == "iter": return MIR_INTRINSIC_VEC_ITER
        if method_name == "map": return MIR_INTRINSIC_VEC_MAP
        if method_name == "filter": return MIR_INTRINSIC_VEC_FILTER
        if method_name == "fold": return MIR_INTRINSIC_VEC_FOLD
        if method_name == "contains": return MIR_INTRINSIC_VEC_CONTAINS
        if method_name == "join": return MIR_INTRINSIC_VEC_JOIN
        return MIR_INTRINSIC_NONE
    if type_name == "VecIter":
        if method_name == "next": return MIR_INTRINSIC_VECITER_NEXT
        return MIR_INTRINSIC_NONE
    if type_name == "HashMap":
        if method_name == "new": return MIR_INTRINSIC_MAP_NEW
        if method_name == "insert": return MIR_INTRINSIC_MAP_INSERT
        if method_name == "get": return MIR_INTRINSIC_MAP_GET
        if method_name == "contains": return MIR_INTRINSIC_MAP_CONTAINS
        if method_name == "len": return MIR_INTRINSIC_MAP_LEN
        if method_name == "remove": return MIR_INTRINSIC_MAP_REMOVE
        if method_name == "clear": return MIR_INTRINSIC_MAP_CLEAR
        if method_name == "increment": return MIR_INTRINSIC_MAP_INCREMENT
        return MIR_INTRINSIC_NONE
    if type_name == "HashSet":
        if method_name == "new": return MIR_INTRINSIC_MAP_NEW
        if method_name == "insert": return MIR_INTRINSIC_MAP_INSERT
        if method_name == "contains": return MIR_INTRINSIC_MAP_CONTAINS
        if method_name == "len": return MIR_INTRINSIC_MAP_LEN
        if method_name == "remove": return MIR_INTRINSIC_MAP_REMOVE
        if method_name == "clear": return MIR_INTRINSIC_MAP_CLEAR
        return MIR_INTRINSIC_NONE
    if type_name == "Option":
        if method_name == "is_some": return MIR_INTRINSIC_OPT_IS_SOME
        if method_name == "is_none": return MIR_INTRINSIC_OPT_IS_NONE
        if method_name == "unwrap": return MIR_INTRINSIC_OPT_UNWRAP
        if method_name == "filter": return MIR_INTRINSIC_OPT_FILTER
        return MIR_INTRINSIC_NONE
    if type_name == "Result":
        if method_name == "is_ok": return MIR_INTRINSIC_OPT_IS_SOME
        if method_name == "unwrap": return MIR_INTRINSIC_OPT_UNWRAP
        return MIR_INTRINSIC_NONE
    MIR_INTRINSIC_NONE

fn MirBuilder.receiver_option_intrinsic(self: MirBuilder, recv_expr: i32) -> i32:
    // Check if recv_expr is a call to an intrinsic method that returns Option.
    // Used to classify chained .unwrap()/.is_some() when the receiver type is void.
    if self.ast.kind(recv_expr) != NK_CALL:
        return MIR_INTRINSIC_NONE
    let callee = self.ast.get_data0(recv_expr)
    if self.ast.kind(callee) != NK_FIELD_ACCESS:
        return MIR_INTRINSIC_NONE
    let base = self.ast.get_data0(callee)
    let method_sym = self.ast.get_data1(callee)
    let base_ty = self.expr_type(base)
    if base_ty == 0 or base_ty == self.sema.ty_void:
        return MIR_INTRINSIC_NONE
    let method_name = self.pool.resolve_symbol(method_sym)
    let resolved = self.sema.resolve_alias(base_ty)
    let type_name_sym = self.sema.get_type_name(resolved)
    if type_name_sym == 0:
        return MIR_INTRINSIC_NONE
    let type_name = self.pool.resolve_symbol(type_name_sym)
    // HashMap.get and HashMap.contains return Option-wrapped values
    if type_name == "HashMap":
        if method_name == "get": return MIR_INTRINSIC_MAP_GET
    if type_name == "HashSet":
        if method_name == "contains": return MIR_INTRINSIC_MAP_CONTAINS
    MIR_INTRINSIC_NONE

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
        if self.ast.kind(self_expr) == NK_IDENT:
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
    if intrinsic == MIR_INTRINSIC_NONE:
        if method_name == "unwrap" or method_name == "is_some" or method_name == "is_none":
            var is_option_method = false
            let recv_intr = self.receiver_option_intrinsic(self_expr)
            if recv_intr != MIR_INTRINSIC_NONE:
                is_option_method = true
            else if callee_sym == method_sym:
                // Unresolved method — no sig found for unwrap/is_some/is_none on the receiver type.
                // User-defined types with these names would have a sig. This is an Option intrinsic.
                is_option_method = true
            if is_option_method:
                if method_name == "unwrap":
                    intrinsic = MIR_INTRINSIC_OPT_UNWRAP
                else if method_name == "is_none":
                    intrinsic = MIR_INTRINSIC_OPT_IS_NONE
                else:
                    intrinsic = MIR_INTRINSIC_OPT_IS_SOME

    // For intrinsic calls (Vec/HashMap/Option), bypass lower_call entirely.
    // lower_call → lower_var would mark_unsupported on the bare method sym.
    // Instead, emit the call terminator directly with an intrinsic tag.
    if intrinsic != MIR_INTRINSIC_NONE:
        return self.lower_intrinsic_call(intrinsic, self_expr, method_sym, arg_start, arg_count, node)

    // If resolution returned bare method_sym, the method is unresolved.
    // Route through MIR_INTRINSIC_GENERIC_CALL so codegen's gen_call handles it
    // (disc enums, from_int, Option methods, concrete/generic struct methods, etc.).
    if callee_sym == method_sym:
            let gc_fn_op = self.const_operand(CK_FN, callee_sym, 0)
            let gc_args: Vec[i32] = Vec.new()
            // Lower self + method args so the handler can eval them.
            // Skip receiver for static calls (type name, not value expression).
            var gc_is_static = false
            if self.ast.kind(self_expr) == NK_IDENT:
                let gc_id_sym = self.ast.get_data0(self_expr)
                if self.sema.named_types.contains(gc_id_sym):
                    gc_is_static = true
            if self.ast.kind(self_expr) == NK_INDEX:
                let gc_idx_base = self.ast.get_data0(self_expr)
                if self.ast.kind(gc_idx_base) == NK_IDENT:
                    let gc_idx_sym = self.ast.get_data0(gc_idx_base)
                    if self.sema.named_types.contains(gc_idx_sym):
                        gc_is_static = true
            if not gc_is_static:
                gc_args.push(self.lower_expr(self_expr))
            for gc_mai in 0..arg_count:
                let gc_ma_node = self.ast.get_extra(arg_start + gc_mai)
                if self.ast.kind(gc_ma_node) != NK_CLOSURE:
                    gc_args.push(self.lower_expr(gc_ma_node))
                else:
                    gc_args.push(self.const_operand(CK_INT, 0, self.sema.ty_i32))
            let gc_args_id = self.body.new_call_args(gc_args)
            self.body.set_call_intrinsic(gc_args_id, MIR_INTRINSIC_GENERIC_CALL)
            self.body.set_call_ast_node(gc_args_id, node)
            var gc_ret_ty = self.expr_type(node)
            if gc_ret_ty == 0:
                gc_ret_ty = self.sema.ty_i32
            let gc_result = self.new_temp(gc_ret_ty)
            let gc_place = self.place_for_local(gc_result)
            let gc_next = self.new_block()
            self.terminate(TK_CALL, gc_fn_op, gc_args_id, gc_place, gc_next)
            self.switch_to(gc_next)
            return self.body.new_operand(OK_COPY, gc_place)

    let fn_op = self.lower_var(callee_sym, 0)
    let arg_nodes: Vec[i32] = Vec.new()
    // For static method calls (receiver is a type name, not a value),
    // don't pass the receiver as an argument.
    var is_static_call = false
    if self.ast.kind(self_expr) == NK_IDENT:
        let recv_sym = self.ast.get_data0(self_expr)
        if self.sema.named_types.contains(recv_sym):
            is_static_call = true
    // Also detect Vec[i32].method() as static
    if self.ast.kind(self_expr) == NK_INDEX:
        let idx_base = self.ast.get_data0(self_expr)
        if self.ast.kind(idx_base) == NK_IDENT:
            let recv_sym = self.ast.get_data0(idx_base)
            if self.sema.named_types.contains(recv_sym):
                is_static_call = true
    if not is_static_call:
        arg_nodes.push(self_expr)
    for i in 0..arg_count:
        arg_nodes.push(self.ast.get_extra(arg_start + i))

    self.lower_call_with_arg_nodes(fn_op, callee_sym, arg_nodes, self.expr_type(node), node)

fn MirBuilder.lower_intrinsic_call(self: MirBuilder, intrinsic: i32, self_expr: i32, method_sym: i32, arg_start: i32, arg_count: i32, node: i32) -> i32:
    // Emit a call terminator with a CK_FN operand and intrinsic tag.
    // The CK_FN sym is meaningless — codegen dispatches by intrinsic kind.
    let fn_op = self.const_operand(CK_FN, method_sym, self.sema.ty_void)

    // Build argument operands. For static calls (Vec.new, HashMap.new),
    // the receiver is a type ident — skip it. For instance methods, include it.
    let is_static = intrinsic == MIR_INTRINSIC_VEC_NEW or intrinsic == MIR_INTRINSIC_MAP_NEW
    let call_args: Vec[i32] = Vec.new()
    if not is_static:
        call_args.push(self.lower_expr(self_expr))
    for i in 0..arg_count:
        let arg_node = self.ast.get_extra(arg_start + i)
        call_args.push(self.lower_expr(arg_node))

    let args_id = self.body.new_call_args(call_args)
    var ret_type = self.expr_type(node)
    // For static constructors (Vec.new, HashMap.new), expr_type often returns
    // the bare struct type (TY_STRUCT) instead of the generic instance
    // (TY_GENERIC_INST). Use the expected type from the let binding if available.
    if self.expected_type > 0:
        let et_tk = self.sema.get_type_kind(self.expected_type)
        if et_tk == TY_GENERIC_INST:
            ret_type = self.expected_type
    // If ret_type is still a base struct (not generic instance) for a static
    // constructor, try to resolve from the NK_INDEX receiver (Vec[i32]).
    if is_static:
        let ret_tk = self.sema.get_type_kind(ret_type)
        if ret_type == 0 or ret_type == self.sema.ty_void or ret_tk == TY_STRUCT:
            // Try resolving generic instance from NK_INDEX receiver (e.g. Vec[i32])
            if self.ast.kind(self_expr) == NK_INDEX:
                let gi_type = self.resolve_index_generic_inst(self_expr)
                if gi_type > 0:
                    ret_type = gi_type
        // Re-check after NK_INDEX resolution
        let ret_tk2 = self.sema.get_type_kind(ret_type)
        if ret_type == 0 or ret_type == self.sema.ty_void or ret_tk2 == TY_STRUCT:
            self.mark_unsupported()
    let result_local = self.new_temp(ret_type)
    let result_place = self.place_for_local(result_local)
    let next_bb = self.new_block()

    self.terminate(TK_CALL, fn_op, args_id, result_place, next_bb)
    self.switch_to(next_bb)

    // Tag call with intrinsic kind for codegen dispatch.
    let call_id = self.body.call_arg_starts.len() as i32 - 1
    self.body.set_call_intrinsic(call_id, intrinsic)

    if self.sema.is_copy(ret_type) != 0:
        return self.body.new_operand(OK_COPY, result_place)
    self.body.new_operand(OK_MOVE, result_place)

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
    targets.push(pass_bb)
    let table = self.body.new_switch_table(vals, targets)
    self.terminate(TK_SWITCH_INT, disc, table, fail_bb, 0)

    self.switch_to(fail_bb)
    let ret_place = self.place_for_local(0)
    let fail_op = self.body.new_operand(OK_MOVE, value_place)
    self.assign_operand_to_place(ret_place, fail_op, self.ast.get_start(expr))
    self.emit_errdefers_for_return()
    self.emit_defers_for_return()
    self.emit_drops_for_return()
    self.terminate(TK_RETURN, 0, 0, 0, 0)

    // Extract Ok payload via PK_DOWNCAST + field access
    var result_ty = self.expr_type(node)
    if result_ty == 0 or result_ty == self.sema.ty_void:
        result_ty = value_ty
    self.switch_to(pass_bb)
    let result_local = self.new_temp(result_ty)
    let result_place = self.place_for_local(result_local)
    let downcast_place = self.body.new_downcast_place(value_place, self.success_variant_index())
    let payload_place = self.body.new_field_place(downcast_place, 0)
    let pass_op = self.body.new_operand(if self.sema.is_copy(result_ty) != 0: OK_COPY else: OK_MOVE, payload_place)
    self.assign_operand_to_place(result_place, pass_op, self.ast.get_start(expr))
    self.terminate(TK_GOTO, join_bb, 0, 0, 0)

    self.switch_to(join_bb)
    if self.sema.is_copy(result_ty) != 0:
        return self.body.new_operand(OK_COPY, result_place)
    self.body.new_operand(OK_MOVE, result_place)

fn MirBuilder.lower_double_question(self: MirBuilder, expr: i32, default_expr: i32) -> i32:
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
    targets.push(some_bb)
    let table = self.body.new_switch_table(vals, targets)
    self.terminate(TK_SWITCH_INT, disc, table, none_bb, 0)

    let result_local = self.new_temp(value_ty)
    let result_place = self.place_for_local(result_local)

    self.switch_to(some_bb)
    let some_op = self.body.new_operand(if self.sema.is_copy(value_ty) != 0: OK_COPY else: OK_MOVE, value_place)
    self.assign_operand_to_place(result_place, some_op, self.ast.get_start(expr))
    self.terminate(TK_GOTO, join_bb, 0, 0, 0)

    self.switch_to(none_bb)
    let default_op = self.lower_expr(default_expr)
    self.assign_operand_to_place(result_place, default_op, self.ast.get_start(default_expr))
    self.terminate(TK_GOTO, join_bb, 0, 0, 0)

    self.switch_to(join_bb)
    if self.sema.is_copy(value_ty) != 0:
        return self.body.new_operand(OK_COPY, result_place)
    self.body.new_operand(OK_MOVE, result_place)

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
    self.body.push_stmt(self.cur_bb, SK_STORAGE_LIVE, local, 0, span)
    if self.sema.is_copy(ty) == 0:
        self.schedule_drop(local, DK_VALUE)
    let rhs = self.lower_expr(rhs_expr)
    self.assign_operand_to_place(self.place_for_local(local), rhs, self.ast.get_start(rhs_expr))
    let result = self.lower_expr(body_expr)
    // Form 2 builder rule: when mut and body is unit, return the binding
    let body_ty = self.expr_type(body_expr)
    if is_mut != 0 and (body_ty == 0 or body_ty == self.sema.ty_void):
        let local_place = self.place_for_local(local)
        self.pop_scope_inline()
        return self.body.new_operand(OK_COPY, local_place)
    self.pop_scope_inline()
    result

fn MirBuilder.lower_with_form2_3(self: MirBuilder, pat_or_name: i32, rhs_expr: i32, body_expr: i32) -> i32:
    self.push_scope()
    if self.ast.kind(pat_or_name) == NK_IDENT:
        let sym = self.ast.get_data0(pat_or_name)
        let ty = self.expr_type(rhs_expr)
        let local = self.body.new_local(ty, 0, sym, 1)
        self.bind_local(sym, local)
        self.body.push_stmt(self.cur_bb, SK_STORAGE_LIVE, local, 0, self.ast.get_start(pat_or_name))
        if self.sema.is_copy(ty) == 0:
            self.schedule_drop(local, DK_VALUE)
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
    let use_rv = self.body.new_rvalue(RK_USE, base, 0, 0)
    self.body.push_stmt(self.cur_bb, SK_ASSIGN, base_place, use_rv, self.ast.get_start(node))
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
            let field_place = self.body.new_field_place(base_place, f_name_sym)
            let field_rv = self.body.new_rvalue(RK_USE, f_val, 0, 0)
            self.body.push_stmt(self.cur_bb, SK_ASSIGN, field_place, field_rv, self.ast.get_start(node))
    self.body.new_operand(OK_COPY, base_place)

fn MirBuilder.lower_implicit_ok(self: MirBuilder, expr: i32, ok_type_id: i32) -> i32:
    let op = self.lower_expr(expr)
    let fields: Vec[i32] = Vec.new()
    fields.push(op)
    let no_names: Vec[i32] = Vec.new()
    no_names.push(0)
    let fid = self.body.new_agg_fields(fields, no_names)
    let rv = self.body.new_rvalue(RK_AGGREGATE, 1, fid, 0)
    let tmp = self.new_temp(ok_type_id)
    let place = self.place_for_local(tmp)
    self.body.push_stmt(self.cur_bb, SK_ASSIGN, place, rv, self.ast.get_start(expr))
    self.body.new_operand(OK_COPY, place)

fn MirBuilder.lower_implicit_default_return(self: MirBuilder, type_id: i32) -> i32:
    if type_id == self.sema.ty_void:
        return self.unit_operand()
    if self.sema.get_type_kind(type_id) == TY_BOOL:
        return self.lower_bool_lit(0)
    self.lower_int_lit(0, type_id)

fn MirBuilder.lower_pipeline(self: MirBuilder, lhs_expr: i32, fn_expr: i32, args_start: i32, args_count: i32, node: i32) -> i32:
    let fn_op = self.lower_expr(fn_expr)
    let callee_sym =
        if fn_expr != 0 and self.ast.kind(fn_expr) == NK_IDENT:
            self.ast.get_data0(fn_expr)
        else:
            0
    let arg_nodes: Vec[i32] = Vec.new()
    arg_nodes.push(lhs_expr)
    for i in 0..args_count:
        arg_nodes.push(self.ast.get_extra(args_start + i))
    self.lower_call_with_arg_nodes(fn_op, callee_sym, arg_nodes, self.expr_type(node), node)

fn MirBuilder.lower_closure(self: MirBuilder, _captured_start: i32, _captured_count: i32, _params_start: i32, _params_count: i32, node: i32) -> i32:
    // Emit CK_CLOSURE so MIR codegen can delegate to gen_closure.
    // The closure body is compiled as a separate function by AST codegen.
    let ty = self.expr_type(node)
    if ty == 0:
        return self.unit_operand()
    let tmp = self.new_temp(ty)
    let place = self.place_for_local(tmp)
    let closure_const = self.body.new_const(CK_CLOSURE, node, 0, 0, ty)
    let op = self.body.new_operand(OK_CONSTANT, closure_const)
    let rv = self.body.new_rvalue(RK_USE, op, 0, 0)
    self.body.push_stmt(self.cur_bb, SK_ASSIGN, place, rv, self.ast.get_start(node))
    self.body.new_operand(OK_COPY, place)

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
    targets.push(some_bb)
    let table = self.body.new_switch_table(vals, targets)
    self.terminate(TK_SWITCH_INT, disc, table, none_bb, 0)

    let result_ty = self.expr_type(node)
    let result_local = self.new_temp(result_ty)
    let result_place = self.place_for_local(result_local)

    self.switch_to(some_bb)
    if arg_count > 0:
        let args: Vec[i32] = Vec.new()
        args.push(self.body.new_operand(OK_COPY, base_place))
        for ai in 0..arg_count:
            args.push(self.lower_expr(self.ast.get_extra(extra_start + 1 + ai)))
        let args_id = self.body.new_call_args(args)
        let call_next_bb = self.new_block()
        self.terminate(TK_CALL, self.unit_operand(), args_id, result_place, call_next_bb)
        self.switch_to(call_next_bb)
    else:
        let field_place = self.body.new_field_place(base_place, member_sym)
        let field_op = self.body.new_operand(OK_COPY, field_place)
        self.assign_operand_to_place(result_place, field_op, self.ast.get_start(node))
    self.terminate(TK_GOTO, join_bb, 0, 0, 0)

    self.switch_to(none_bb)
    let default_op = self.lower_implicit_default_return(result_ty)
    self.assign_operand_to_place(result_place, default_op, self.ast.get_start(node))
    self.terminate(TK_GOTO, join_bb, 0, 0, 0)

    self.switch_to(join_bb)
    if self.sema.is_copy(result_ty) != 0:
        return self.body.new_operand(OK_COPY, result_place)
    self.body.new_operand(OK_MOVE, result_place)

fn MirBuilder.lower_expr(self: MirBuilder, node: i32) -> i32:
    if node == 0:
        return self.unit_operand()

    self.cur_node = node
    let kind = self.ast.kind(node)

    if kind == NK_INT_LIT:
        return self.lower_int_lit(self.ast.int_lit_value(node), self.expr_type(node))

    if kind == NK_BOOL_LIT:
        return self.lower_bool_lit(self.ast.get_data0(node))

    if kind == NK_STRING_LIT or kind == NK_C_STRING_LIT:
        return self.lower_str_lit(self.ast.get_data0(node))

    if kind == NK_FLOAT_LIT:
        return self.lower_float_lit(self.ast.get_data0(node))

    if kind == NK_NULL_LIT:
        // Null pointer literal: lower as integer 0 (codegen emits wl_const_null for ptr targets)
        return self.const_operand(CK_INT, 0, self.sema.ty_i32)

    if kind == NK_UNSAFE_BLOCK:
        // Transparent pass-through: just lower the inner body
        return self.lower_expr(self.ast.get_data0(node))

    if kind == NK_COMPTIME_ERROR:
        // Emit unreachable — if this code is ever reached, it's a compile error
        self.terminate(TK_UNREACHABLE, 0, 0, 0, 0)
        let dead_bb = self.new_block()
        self.switch_to(dead_bb)
        return self.unit_operand()

    if kind == NK_IDENT:
        return self.lower_var(self.ast.get_data0(node), self.expr_type(node))

    if kind == NK_BINARY:
        let op = self.ast.get_data0(node)
        let lhs = self.ast.get_data1(node)
        let rhs = self.ast.get_data2(node)
        if op == OP_DEFAULT:
            return self.lower_double_question(lhs, rhs)
        return self.lower_bin_op(op, lhs, rhs, node)

    if kind == NK_UNARY:
        let op = self.ast.get_data0(node)
        let operand = self.ast.get_data1(node)
        if op == UOP_TRY:
            return self.lower_question_mark(operand, node)
        return self.lower_un_op(op, operand, node)

    if kind == NK_CAST:
        // Read pre-resolved cast type from sema sidecar (avoids add_type on
        // shallow-copied Sema — see resolve_type_expr aliasing bug).
        var cast_tid = 0
        if self.sema.typed_expr_types.contains(node):
            cast_tid = self.sema.typed_expr_types.get(node).unwrap()
        else:
            cast_tid = self.sema.resolve_type_expr(self.ast.get_data1(node))
        return self.lower_cast(self.ast.get_data0(node), cast_tid, node)

    if kind == NK_FIELD_ACCESS:
        let fa_base = self.ast.get_data0(node)
        let fa_field = self.ast.get_data1(node)
        // Enum variant access: Color.Red → discriminant value constant
        if self.ast.kind(fa_base) == NK_IDENT:
            let fa_base_sym = self.ast.get_data0(fa_base)
            if self.sema.named_types.contains(fa_base_sym):
                let fa_base_ty = self.sema.named_types.get(fa_base_sym).unwrap()
                let fa_resolved = self.sema.resolve_alias(fa_base_ty)
                let fa_tk = self.sema.get_type_kind(fa_resolved)
                if fa_tk == TY_ENUM:
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
                        let fa_is_disc_enum = self.sema.disc_repr_types.contains(fa_resolved)
                        if not fa_is_disc_enum or self.sema.disc_has_payload.contains(fa_resolved):
                            let fa_fields: Vec[i32] = Vec.new()
                            let fa_names: Vec[i32] = Vec.new()
                            let fa_fid = self.body.new_agg_fields(fa_fields, fa_names)
                            let fa_rv = self.body.new_rvalue(RK_AGGREGATE, 1, fa_fid, fa_disc_tag)
                            let fa_tmp = self.new_temp(fa_base_ty)
                            let fa_place = self.place_for_local(fa_tmp)
                            self.body.push_stmt(self.cur_bb, SK_ASSIGN, fa_place, fa_rv, self.ast.get_start(node))
                            return self.body.new_operand(OK_COPY, fa_place)
                        return self.int_const_operand(fa_disc_tag as i64, fa_base_ty)
                    // Also try bare variant sym (some enums register just "Red")
                    if self.sema.variant_lookup.contains(fa_field):
                        let fa_var_tid = self.sema.variant_type_ids.get(fa_field).unwrap()
                        if fa_var_tid == fa_resolved:
                            let fa_var_idx2 = self.sema.variant_lookup.get(fa_field).unwrap()
                            let fa_disc_tag2 = if self.sema.disc_values.contains(fa_field): self.sema.disc_values.get(fa_field).unwrap() else: fa_var_idx2
                            let fa_is_disc_enum2 = self.sema.disc_repr_types.contains(fa_resolved)
                            if not fa_is_disc_enum2 or self.sema.disc_has_payload.contains(fa_resolved):
                                let fa_fields2: Vec[i32] = Vec.new()
                                let fa_names2: Vec[i32] = Vec.new()
                                let fa_fid2 = self.body.new_agg_fields(fa_fields2, fa_names2)
                                let fa_rv2 = self.body.new_rvalue(RK_AGGREGATE, 1, fa_fid2, fa_disc_tag2)
                                let fa_tmp2 = self.new_temp(fa_base_ty)
                                let fa_place2 = self.place_for_local(fa_tmp2)
                                self.body.push_stmt(self.cur_bb, SK_ASSIGN, fa_place2, fa_rv2, self.ast.get_start(node))
                                return self.body.new_operand(OK_COPY, fa_place2)
                            return self.int_const_operand(fa_disc_tag2 as i64, fa_base_ty)
        let place = self.lower_field_access(fa_base, fa_field)
        return self.body.new_operand(OK_COPY, place)

    if kind == NK_INDEX:
        let vec_ty = self.vec_literal_type(node)
        if vec_ty != 0:
            return self.lower_vec_literal(node, vec_ty)
        let place = self.lower_index(self.ast.get_data0(node), self.ast.get_data1(node))
        return self.body.new_operand(OK_COPY, place)

    if kind == NK_BLOCK:
        return self.lower_block(node)

    if kind == NK_LET_BINDING:
        self.lower_let_binding(node)
        return self.unit_operand()

    if kind == NK_LET_ELSE:
        self.lower_let_else(node)
        return self.unit_operand()

    if kind == NK_TUPLE_DESTRUCTURE:
        self.lower_tuple_destructure(node)
        return self.unit_operand()

    if kind == NK_ASSIGN:
        self.lower_assign(self.ast.get_data0(node), self.ast.get_data1(node))
        return self.unit_operand()

    if kind == NK_IF_EXPR:
        return self.lower_if(self.ast.get_data0(node), self.ast.get_data1(node), self.ast.get_data2(node), node)

    if kind == NK_WHILE:
        return self.lower_while(self.ast.get_data0(node), self.ast.get_data1(node))

    if kind == NK_LOOP:
        return self.lower_loop(self.ast.get_data0(node), node)

    if kind == NK_FOR:
        return self.lower_for(self.ast.get_data0(node), self.ast.get_data1(node), self.ast.get_data2(node))

    if kind == NK_BREAK:
        return self.lower_break(node)

    if kind == NK_CONTINUE:
        return self.lower_continue(node)

    if kind == NK_RETURN:
        return self.lower_return(node)

    if kind == NK_MATCH:
        return self.lower_match(self.ast.get_data0(node), self.ast.get_data1(node), self.ast.get_data2(node), node)

    if kind == NK_CALL:
        let callee = self.ast.get_data0(node)
        if self.ast.kind(callee) == NK_FIELD_ACCESS:
            return self.lower_method_call(self.ast.get_data0(callee), self.ast.get_data1(callee), self.ast.get_data1(node), self.ast.get_data2(node), node)
        var generic_builtin_sym = 0
        if self.ast.kind(callee) == NK_INDEX or self.ast.kind(callee) == NK_TYPE_GENERIC:
            let gb_base = self.ast.get_data0(callee)
            if self.ast.kind(gb_base) == NK_IDENT:
                let gb_sym = self.ast.get_data0(gb_base)
                let gb_name = self.pool.resolve(gb_sym)
                if gb_name == "transmute" or gb_name == "sizeof" or gb_name == "size_of" or gb_name == "alignof" or gb_name == "align_of" or gb_name == "nameof" or gb_name == "type_name":
                    generic_builtin_sym = gb_sym
        if generic_builtin_sym > 0:
            let gc_fn_op = self.const_operand(CK_FN, generic_builtin_sym, 0)
            let gc_args: Vec[i32] = Vec.new()
            let gc_as = self.ast.get_data1(node)
            let gc_ac = self.ast.get_data2(node)
            for gc_ai in 0..gc_ac:
                let gc_arg_node = self.ast.get_extra(gc_as + gc_ai)
                gc_args.push(self.lower_expr(gc_arg_node))
            let gc_args_id = self.body.new_call_args(gc_args)
            self.body.set_call_intrinsic(gc_args_id, MIR_INTRINSIC_GENERIC_CALL)
            self.body.set_call_ast_node(gc_args_id, node)
            var gc_ret_ty = self.expr_type(node)
            if gc_ret_ty == 0:
                gc_ret_ty = self.sema.ty_i32
            let gc_result = self.new_temp(gc_ret_ty)
            let gc_place = self.place_for_local(gc_result)
            let gc_next = self.new_block()
            self.terminate(TK_CALL, gc_fn_op, gc_args_id, gc_place, gc_next)
            self.switch_to(gc_next)
            return self.body.new_operand(OK_COPY, gc_place)
        // Check for enum variant constructor call: Some(v), Ok(v), Err(e), etc.
        if self.ast.kind(callee) == NK_IDENT:
            let vc_sym = self.ast.get_data0(callee)
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
                let vc_rv = self.body.new_rvalue(RK_AGGREGATE, 1, vc_fid, vc_variant_idx)
                let vc_tmp = self.new_temp(vc_result_ty)
                let vc_place = self.place_for_local(vc_tmp)
                self.body.push_stmt(self.cur_bb, SK_ASSIGN, vc_place, vc_rv, self.ast.get_start(node))
                return self.body.new_operand(OK_COPY, vc_place)
        // Distinct type constructor: Meters(42) → single-field struct aggregate
        if self.ast.kind(callee) == NK_IDENT:
            let dt_sym = self.ast.get_data0(callee)
            if self.sema.distinct_type_names.contains(dt_sym):
                let dt_tid = self.sema.distinct_type_names.get(dt_sym).unwrap()
                let dt_args_start = self.ast.get_data1(node)
                let dt_args_count = self.ast.get_data2(node)
                if dt_args_count == 1:
                    let dt_arg = self.ast.get_extra(dt_args_start)
                    let dt_val = self.lower_expr(dt_arg)
                    let dt_fields: Vec[i32] = Vec.new()
                    let dt_names: Vec[i32] = Vec.new()
                    dt_fields.push(dt_val)
                    let val_sym = self.sema.pool_intern("value")
                    dt_names.push(val_sym)
                    let dt_fid = self.body.new_agg_fields(dt_fields, dt_names)
                    let dt_rv = self.body.new_rvalue(RK_AGGREGATE, 0, dt_fid, 0)
                    let dt_tmp = self.new_temp(dt_tid)
                    let dt_place = self.place_for_local(dt_tmp)
                    self.body.push_stmt(self.cur_bb, SK_ASSIGN, dt_place, dt_rv, self.ast.get_start(node))
                    return self.body.new_operand(OK_COPY, dt_place)
        // Callable type syntax: TypeName(args) → TypeName.new(args)
        if self.ast.kind(callee) == NK_IDENT:
            let ct_sym = self.ast.get_data0(callee)
            if self.sema.type_decl_nodes.contains(ct_sym):
                let ct_new_name = self.pool.resolve(ct_sym) ++ ".new"
                let ct_new_sym = self.pool.intern(ct_new_name)
                let ct_new_sig = self.sema.get_sig(ct_new_sym)
                if ct_new_sig >= 0:
                    let ct_fn_op = self.const_operand(CK_FN, ct_new_sym, 0)
                    let ct_ret_ty = self.expr_type(node)
                    return self.lower_call_redirected(ct_fn_op, ct_new_sym, self.ast.get_data1(node), self.ast.get_data2(node), ct_ret_ty, node)
        // Generic function call — delegate to codegen's monomorphize_generic_call
        if self.ast.kind(callee) == NK_IDENT:
            let gc_sym = self.ast.get_data0(callee)
            if self.sema.generic_fn_nodes.contains(gc_sym):
                // Lower args and emit call. Codegen intercepts via MIR_INTRINSIC_GENERIC_CALL
                // and routes to monomorphize_generic_call_core with pre-evaluated MIR args.
                let gc_fn_op = self.const_operand(CK_FN, gc_sym, 0)
                let gc_args: Vec[i32] = Vec.new()
                let gc_as = self.ast.get_data1(node)
                let gc_ac = self.ast.get_data2(node)
                for gc_ai in 0..gc_ac:
                    let gc_arg_node = self.ast.get_extra(gc_as + gc_ai)
                    gc_args.push(self.lower_expr(gc_arg_node))
                let gc_args_id = self.body.new_call_args(gc_args)
                self.body.set_call_intrinsic(gc_args_id, MIR_INTRINSIC_GENERIC_CALL)
                self.body.set_call_ast_node(gc_args_id, node)
                var gc_ret_ty = self.expr_type(node)
                if gc_ret_ty == 0:
                    gc_ret_ty = self.sema.ty_i32
                let gc_result = self.new_temp(gc_ret_ty)
                let gc_place = self.place_for_local(gc_result)
                let gc_next = self.new_block()
                self.terminate(TK_CALL, gc_fn_op, gc_args_id, gc_place, gc_next)
                self.switch_to(gc_next)
                return self.body.new_operand(OK_COPY, gc_place)
        // Check for builtin calls (embed_file, src, etc.) — no sig, not a local
        if self.ast.kind(callee) == NK_IDENT:
            let bu_sym = self.ast.get_data0(callee)
            let bu_sig = self.sema.get_sig(bu_sym)
            let bu_local = self.lookup_local(bu_sym)
            if bu_sig < 0 and bu_local < 0:
                // Unresolved bare function — route through gen_call
                let bu_fn_op = self.const_operand(CK_FN, bu_sym, 0)
                let bu_args: Vec[i32] = Vec.new()
                let bu_args_id = self.body.new_call_args(bu_args)
                self.body.set_call_intrinsic(bu_args_id, MIR_INTRINSIC_GENERIC_CALL)
                self.body.set_call_ast_node(bu_args_id, node)
                var bu_ret_ty = self.expr_type(node)
                if bu_ret_ty == 0:
                    bu_ret_ty = self.sema.ty_i32
                let bu_result = self.new_temp(bu_ret_ty)
                let bu_place = self.place_for_local(bu_result)
                let bu_next = self.new_block()
                self.terminate(TK_CALL, bu_fn_op, bu_args_id, bu_place, bu_next)
                self.switch_to(bu_next)
                return self.body.new_operand(OK_COPY, bu_place)
        return self.lower_call(callee, self.ast.get_data1(node), self.ast.get_data2(node), self.expr_type(node), node)

    if kind == NK_PIPELINE:
        let rhs = self.ast.get_data1(node)
        if self.ast.kind(rhs) == NK_CALL:
            return self.lower_pipeline(self.ast.get_data0(node), self.ast.get_data0(rhs), self.ast.get_data1(rhs), self.ast.get_data2(rhs), node)
        return self.lower_pipeline(self.ast.get_data0(node), rhs, 0, 0, node)

    if kind == NK_WITH_EXPR:
        let source = self.ast.get_data0(node)
        let body = self.ast.get_data1(node)
        let name = decode_with_binding_sym(self.ast.get_data2(node))
        if name != 0:
            return self.lower_with_binding(name, source, body, self.ast.get_start(node))
        return self.lower_with_form1(source, body)

    if kind == NK_STRUCT_LIT:
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
        let sl_rv = self.body.new_rvalue(RK_AGGREGATE, 0, sl_fid, 0)
        let sl_ty = self.expr_type(node)
        let sl_tmp = self.new_temp(sl_ty)
        let sl_place = self.place_for_local(sl_tmp)
        self.body.push_stmt(self.cur_bb, SK_ASSIGN, sl_place, sl_rv, self.ast.get_start(node))
        return self.body.new_operand(OK_COPY, sl_place)

    if kind == NK_RECORD_UPDATE:
        return self.lower_record_update(self.ast.get_data0(node), self.ast.get_data1(node), self.ast.get_data2(node), node)

    if kind == NK_TUPLE:
        let extra_start = self.ast.get_data0(node)
        let elem_count = self.ast.get_data1(node)
        let tup_fields: Vec[i32] = Vec.new()
        let tup_names: Vec[i32] = Vec.new()
        for i in 0..elem_count:
            let elem_node = self.ast.get_extra(extra_start + i)
            tup_fields.push(self.lower_expr(elem_node))
            tup_names.push(0)
        let tup_fid = self.body.new_agg_fields(tup_fields, tup_names)
        let tup_rv = self.body.new_rvalue(RK_AGGREGATE, 0, tup_fid, 0)
        let tup_ty = self.expr_type(node)
        let tup_tmp = self.new_temp(tup_ty)
        let tup_place = self.place_for_local(tup_tmp)
        self.body.push_stmt(self.cur_bb, SK_ASSIGN, tup_place, tup_rv, self.ast.get_start(node))
        return self.body.new_operand(OK_COPY, tup_place)

    if kind == NK_ARRAY_LIT:
        let extra_start = self.ast.get_data0(node)
        let elem_count = self.ast.get_data1(node)
        let arr_fields: Vec[i32] = Vec.new()
        let arr_names: Vec[i32] = Vec.new()
        for i in 0..elem_count:
            let elem_node = self.ast.get_extra(extra_start + i)
            arr_fields.push(self.lower_expr(elem_node))
            arr_names.push(0)
        let arr_fid = self.body.new_agg_fields(arr_fields, arr_names)
        let arr_rv = self.body.new_rvalue(RK_AGGREGATE, 0, arr_fid, 0)
        let arr_ty = self.expr_type(node)
        let arr_tmp = self.new_temp(arr_ty)
        let arr_place = self.place_for_local(arr_tmp)
        self.body.push_stmt(self.cur_bb, SK_ASSIGN, arr_place, arr_rv, self.ast.get_start(node))
        return self.body.new_operand(OK_COPY, arr_place)

    if kind == NK_VARIANT_SHORTHAND:
        let vs_name_sym = self.ast.get_data0(node)
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
                    let vs_is_disc_enum = self.sema.disc_repr_types.contains(vs_resolved)
                    if not vs_is_disc_enum or self.sema.disc_has_payload.contains(vs_resolved):
                        let vs_de_fields: Vec[i32] = Vec.new()
                        let vs_de_names: Vec[i32] = Vec.new()
                        let vs_de_fid = self.body.new_agg_fields(vs_de_fields, vs_de_names)
                        let vs_de_rv = self.body.new_rvalue(RK_AGGREGATE, 1, vs_de_fid, vs_disc_val)
                        let vs_de_tmp = self.new_temp(vs_result_ty)
                        let vs_de_place = self.place_for_local(vs_de_tmp)
                        self.body.push_stmt(self.cur_bb, SK_ASSIGN, vs_de_place, vs_de_rv, self.ast.get_start(node))
                        return self.body.new_operand(OK_COPY, vs_de_place)
                    return self.int_const_operand(vs_disc_val, vs_result_ty)
        let vs_fields: Vec[i32] = Vec.new()
        let vs_names: Vec[i32] = Vec.new()
        for vsi in 0..vs_arg_count:
            let vs_arg = self.ast.get_extra(vs_args_start + vsi)
            vs_fields.push(self.lower_expr(vs_arg))
            vs_names.push(0)
        let vs_fid = self.body.new_agg_fields(vs_fields, vs_names)
        let vs_rv = self.body.new_rvalue(RK_AGGREGATE, 1, vs_fid, vs_variant_idx)
        let vs_tmp = self.new_temp(vs_result_ty)
        let vs_place = self.place_for_local(vs_tmp)
        self.body.push_stmt(self.cur_bb, SK_ASSIGN, vs_place, vs_rv, self.ast.get_start(node))
        return self.body.new_operand(OK_COPY, vs_place)

    if kind == NK_CLOSURE:
        return self.lower_closure(0, 0, self.ast.get_data1(node), self.ast.get_data2(node), node)

    if kind == NK_GROUPED:
        return self.lower_expr(self.ast.get_data0(node))

    if kind == NK_OPTIONAL_CHAIN:
        return self.lower_optional_chain(node)

    if kind == NK_COMPTIME:
        // Comptime: unwrap and lower the inner expression.
        let inner = self.ast.get_data0(node)
        if inner != 0:
            // comptime if: evaluate condition at compile time, only lower taken branch
            if self.ast.kind(inner) == NK_IF_EXPR:
                let ct_cond = self.ast.get_data0(inner)
                let ct_then = self.ast.get_data1(inner)
                let ct_else = self.ast.get_data2(inner)
                let ct_val = self.try_eval_const(ct_cond)
                if ct_val != -9223372036854775807:
                    if ct_val != 0:
                        return self.lower_expr(ct_then)
                    if ct_else != 0:
                        return self.lower_expr(ct_else)
                    return self.unit_operand()
            return self.lower_expr(inner)
        return self.unit_operand()

    // spawn expr → with_fiber_spawn(fn_ptr, arg) → returns task_id (i32)
    if kind == NK_SPAWN:
        let inner = self.ast.get_data0(node)
        let inner_op = self.lower_expr(inner)
        // The spawn result is the inner call's result for now
        // (proper fiber spawn requires packaging fn+args as a fiber entry)
        return inner_op

    // expr.await → with_fiber_await(task_id) → returns result
    if kind == NK_AWAIT:
        let inner = self.ast.get_data0(node)
        return self.lower_expr(inner)

    // yield expr → for now, just evaluate the expression (state machine transform is future work)
    if kind == NK_YIELD:
        let inner = self.ast.get_data0(node)
        if inner != 0:
            return self.lower_expr(inner)
        return self.unit_operand()

    if kind == NK_ASYNC_BLOCK or kind == NK_ASYNC_SCOPE or kind == NK_SELECT_AWAIT:
        // Async lowering is deferred to later waves.
        self.mark_unsupported()
        if self.ast.get_data0(node) != 0:
            let _ = self.lower_expr(self.ast.get_data0(node))
        if self.ast.get_data1(node) != 0:
            let _ = self.lower_expr(self.ast.get_data1(node))
        if self.ast.get_data2(node) != 0:
            let _ = self.lower_expr(self.ast.get_data2(node))
        return self.unit_operand()

    self.mark_unsupported()
    self.unit_operand()

fn lower_fn(builder: MirBuilder, fn_node: i32) -> MirBody:
    let fn_sym = builder.ast.get_data0(fn_node)
    var sig_idx = builder.sema.get_sig(fn_sym)
    // If sig not found, try translating fn_sym from AST pool to sema pool.
    // Sema registers sigs under sema pool symbols, not AST pool symbols.
    if sig_idx < 0:
        let sema_fn_sym = builder.sema.pool_intern(builder.pool.resolve_symbol(fn_sym))
        sig_idx = builder.sema.get_sig(sema_fn_sym)
    // Also try method_key for methods: "Type.method" → method_key(type_sym, method_sym)
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
            let sema_type_sym = builder.sema.pool_intern(type_part)
            let sema_method_sym = builder.sema.pool_intern(method_part)
            let mk = builder.sema.method_key(sema_type_sym, sema_method_sym)
            sig_idx = builder.sema.get_sig(mk)
    lower_fn_with_sig(builder, fn_node, sig_idx)

fn lower_fn_with_sig(builder: MirBuilder, fn_node: i32, sig_idx: i32) -> MirBody:
    if sig_idx >= 0:
        builder.body.local_type_ids.set_i32(0, builder.sema.sig_return_type(sig_idx))
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
                    p_ty = builder.sema.ty_i32
            let local_id = builder.body.new_local(p_ty, 0, p_name, 1)
            builder.bind_local(p_name, local_id)
            builder.body.push_stmt(builder.cur_bb, SK_STORAGE_LIVE, local_id, 0, builder.ast.get_start(fn_node))
            if builder.sema.is_copy(p_ty) == 0:
                builder.schedule_drop(local_id, DK_VALUE)

    // Set expected_type to the function's return type so that intrinsic calls
    // (Vec.new, HashMap.new) in tail position can resolve their generic inst type.
    let ret_ty = builder.body.local_type_ids.get(0)
    builder.expected_type = ret_ty

    let body_expr = builder.ast.get_data1(fn_node)
    var result = builder.lower_expr(body_expr)

    // Implicit Ok wrapping: if return type is Result[T, E] and body type is T,
    // wrap the result in Ok(value) — an enum variant construction with tag 0.
    let ret_resolved = builder.sema.resolve_alias(ret_ty)
    if builder.sema.get_type_kind(ret_resolved) == TY_GENERIC_INST:
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
                    let ok_rv = builder.body.new_rvalue(RK_AGGREGATE, 1, ok_fid, 0)
                    let ok_tmp = builder.new_temp(ret_ty)
                    let ok_place = builder.place_for_local(ok_tmp)
                    builder.body.push_stmt(builder.cur_bb, SK_ASSIGN, ok_place, ok_rv, builder.ast.get_end(fn_node))
                    result = builder.body.new_operand(OK_COPY, ok_place)

    // Implicit return value assignment for non-diverging tail expressions.
    let ret_place = builder.place_for_local(0)
    builder.assign_operand_to_place(ret_place, result, builder.ast.get_end(fn_node))

    builder.emit_defers_for_return()
    builder.pop_scope_inline()
    builder.terminate(TK_RETURN, 0, 0, 0, 0)

    builder.body

fn lower_module(sema: Sema, ast_pool: AstPool, pool: InternPool) -> MirModule:
    var mir_mod = MirModule.init()
    // Snapshot sema type tables before any MirBuilder copy can realloc/free the buffer
    mir_mod.snapshot_sema_types(sema)

    for di in 0..ast_pool.decl_count():
        let decl = ast_pool.get_decl(di)
        if ast_pool.kind(decl) != NK_FN_DECL:
            continue

        let fn_sym = ast_pool.get_data0(decl)
        let meta = ast_pool.find_fn_meta(decl)
        if meta >= 0 and ast_pool.fn_meta_tp_count(meta) > 0:
            // Skip generic fn bodies in this wave.
            continue
        // Don't skip generic_fn_nodes functions — let MirLower try them.
        // Concrete methods on generic types (e.g. Wrapper.get(self: Wrapper[i32]))
        // will lower successfully. Truly generic methods will fail naturally
        // with lowering_failed=1 and fall back to AST codegen.

        var builder = MirBuilder.init(sema, ast_pool, pool, fn_sym)
        let body = lower_fn(builder, decl)
        mir_mod.add_body(body)

    mir_mod
