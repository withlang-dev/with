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

    // Loop stack.
    loop_continue_bbs: Vec[i32],
    loop_break_bbs: Vec[i32],
    loop_break_drop_depths: Vec[i32],

    next_temp: i32,

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
        loop_continue_bbs: Vec.new(),
        loop_break_bbs: Vec.new(),
        loop_break_drop_depths: Vec.new(),
        next_temp: 0,
        sema,
        ast,
        pool,
    }

fn MirBuilder.new_block(self: MirBuilder) -> i32:
    self.body.new_block()

fn MirBuilder.switch_to(self: MirBuilder, bb: i32):
    self.cur_bb = bb

fn MirBuilder.terminate(self: MirBuilder, kind: i32, d0: i32, d1: i32, d2: i32, d3: i32):
    self.body.set_terminator(self.cur_bb, kind, d0, d1, d2, d3)

fn MirBuilder.push_scope(self: MirBuilder):
    self.drop_scope_starts.push(self.drop_local_ids.len() as i32)
    self.bind_scope_starts.push(self.bind_syms.len() as i32)

fn MirBuilder.schedule_drop(self: MirBuilder, local_id: i32, drop_kind: i32):
    self.drop_local_ids.push(local_id)
    self.drop_kinds.push(drop_kind)

fn MirBuilder.emit_drop_entry(self: MirBuilder, local_id: i32, drop_kind: i32):
    if drop_kind == DK_STORAGE():
        self.body.push_stmt(self.cur_bb, SK_STORAGE_DEAD(), local_id, 0, 0)
        return
    let place = self.body.new_place(local_id)
    self.body.push_stmt(self.cur_bb, SK_DROP(), place, 0, 0)

fn MirBuilder.pop_scope_with_goto(self: MirBuilder, target_bb: i32):
    if self.drop_scope_starts.len() as i32 == 0:
        self.terminate(TK_GOTO(), target_bb, 0, 0, 0)
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

    self.terminate(TK_GOTO(), target_bb, 0, 0, 0)

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
    let start = self.ast.get_start(node)
    if self.sema.typed_expr_types.contains(start):
        let typed = self.sema.typed_expr_types.get(start).unwrap()
        if typed != 0:
            return typed
    self.fallback_expr_type(node)

fn MirBuilder.binding_type(self: MirBuilder, node: i32) -> i32:
    let start = self.ast.get_start(node)
    if self.sema.typed_binding_types.contains(start):
        let typed = self.sema.typed_binding_types.get(start).unwrap()
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
        return self.sema.variant_lookup.get(sym).unwrap() / 65536
    self.sema.ty_void

fn MirBuilder.call_return_type(self: MirBuilder, callee: i32) -> i32:
    if callee == 0:
        return self.sema.ty_void
    let kind = self.ast.kind(callee)
    if kind == NK_IDENT():
        let sym = self.ast.get_data0(callee)
        let sig_idx = self.sema.get_sig(sym)
        if sig_idx >= 0:
            return self.sema.sig_return_type(sig_idx)
        return self.sema.ty_void
    if kind == NK_FIELD_ACCESS():
        let base = self.ast.get_data0(callee)
        let method_sym = self.ast.get_data1(callee)
        let resolved = self.resolve_method_callee_sym(base, method_sym)
        let resolved_sig = self.sema.get_sig(resolved)
        if resolved_sig >= 0:
            return self.sema.sig_return_type(resolved_sig)
        let bare_sig = self.sema.get_sig(method_sym)
        if bare_sig >= 0:
            return self.sema.sig_return_type(bare_sig)
    self.sema.ty_void

fn MirBuilder.fallback_expr_type(self: MirBuilder, node: i32) -> i32:
    if node == 0:
        return self.sema.ty_void
    let kind = self.ast.kind(node)
    if kind == NK_IDENT():
        return self.ident_type(self.ast.get_data0(node))
    if kind == NK_GROUPED():
        return self.expr_type(self.ast.get_data0(node))
    if kind == NK_INT_LIT():
        let value = self.ast.int_lit_value(node)
        if value < -2147483648 or value > 2147483647:
            return self.sema.ty_i64
        return self.sema.ty_i32
    if kind == NK_BOOL_LIT():
        return self.sema.ty_bool
    if kind == NK_STRING_LIT() or kind == NK_C_STRING_LIT():
        return self.sema.ty_str
    if kind == NK_CALL():
        return self.call_return_type(self.ast.get_data0(node))
    self.sema.ty_void

fn MirBuilder.place_local_type(self: MirBuilder, place_id: i32) -> i32:
    if place_id < 0 or place_id >= self.body.place_locals.len() as i32:
        return self.sema.ty_void
    let local_id = self.body.place_locals.get(place_id as i64)
    if local_id < 0 or local_id >= self.body.local_type_ids.len() as i32:
        return self.sema.ty_void
    self.body.local_type_ids.get(local_id as i64)

fn MirBuilder.variant_index(self: MirBuilder, variant_sym: i32) -> i32:
    if variant_sym == 0:
        return 0
    if self.sema.variant_lookup.contains(variant_sym):
        let enc = self.sema.variant_lookup.get(variant_sym).unwrap()
        return enc % 65536
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
    self.body.new_operand(OK_CONSTANT(), c)

fn MirBuilder.int_const_operand(self: MirBuilder, value: i64, type_id: i32) -> i32:
    let c = self.body.new_const(CK_INT(), ast_int_part0(value), ast_int_part1(value), ast_int_part2(value), type_id)
    self.body.new_operand(OK_CONSTANT(), c)

fn MirBuilder.unit_operand(self: MirBuilder) -> i32:
    self.const_operand(CK_UNIT(), 0, self.sema.ty_void)

fn MirBuilder.mark_unsupported(self: MirBuilder):
    var b = self.body
    b.lowering_failed = 1
    self.body = b

fn MirBuilder.lower_int_lit(self: MirBuilder, value: i64, type_id: i32) -> i32:
    let ty = if type_id == 0 or self.sema.get_type_kind(type_id) == TY_VOID(): self.sema.ty_i32 else: type_id
    self.int_const_operand(value, ty)

fn MirBuilder.lower_bool_lit(self: MirBuilder, value: i32) -> i32:
    self.const_operand(CK_BOOL(), value, self.sema.ty_bool)

fn MirBuilder.lower_str_lit(self: MirBuilder, sym: i32) -> i32:
    self.const_operand(CK_STR(), sym, self.sema.ty_str)

fn MirBuilder.lower_float_lit(self: MirBuilder, sym: i32) -> i32:
    self.const_operand(CK_FLOAT(), sym, self.sema.ty_f64)

fn MirBuilder.lower_unit(self: MirBuilder) -> i32:
    self.unit_operand()

fn MirBuilder.lower_var(self: MirBuilder, sym: i32, type_id: i32) -> i32:
    let local = self.lookup_local(sym)
    if local >= 0:
        let place = self.body.new_place(local)
        if self.sema.is_copy(type_id) != 0:
            return self.body.new_operand(OK_COPY(), place)
        return self.body.new_operand(OK_MOVE(), place)

    let sig_idx = self.sema.get_sig(sym)
    if sig_idx >= 0:
        let fn_ty = if type_id != 0: type_id else: self.sema.sig_type_ids.get(sig_idx as i64)
        return self.const_operand(CK_FN(), sym, fn_ty)

    self.mark_unsupported()
    self.unit_operand()

fn MirBuilder.assign_operand_to_place(self: MirBuilder, place: i32, operand_id: i32, span: i32):
    let rval = self.body.new_rvalue(RK_USE(), operand_id, 0, 0)
    self.body.push_stmt(self.cur_bb, SK_ASSIGN(), place, rval, span)

fn MirBuilder.lower_bin_op(self: MirBuilder, op: i32, lhs_expr: i32, rhs_expr: i32, node: i32) -> i32:
    let lhs = self.lower_expr(lhs_expr)
    let rhs = self.lower_expr(rhs_expr)
    let rv = self.body.new_rvalue(RK_BIN_OP(), op, lhs, rhs)
    let ty = self.expr_type(node)
    let temp = self.new_temp(ty)
    let place = self.place_for_local(temp)
    self.body.push_stmt(self.cur_bb, SK_ASSIGN(), place, rv, self.ast.get_start(node))
    if self.sema.is_copy(ty) != 0:
        return self.body.new_operand(OK_COPY(), place)
    self.body.new_operand(OK_MOVE(), place)

fn MirBuilder.lower_un_op(self: MirBuilder, op: i32, expr: i32, node: i32) -> i32:
    if op == UOP_REF() or op == UOP_MUT_REF():
        let place = self.lower_expr_place(expr)
        let rv = self.body.new_rvalue(RK_REF(), if op == UOP_MUT_REF(): BK_EXCLUSIVE() else: BK_SHARED(), place, 0)
        let ty = self.expr_type(node)
        let temp = self.new_temp(ty)
        let temp_place = self.place_for_local(temp)
        self.body.push_stmt(self.cur_bb, SK_ASSIGN(), temp_place, rv, self.ast.get_start(node))
        return self.body.new_operand(OK_COPY(), temp_place)

    if op == UOP_DEREF():
        let place = self.lower_expr_place(expr)
        let deref_place = self.body.new_deref_place(place)
        return self.body.new_operand(OK_COPY(), deref_place)

    let arg = self.lower_expr(expr)
    let rv = self.body.new_rvalue(RK_UN_OP(), op, arg, 0)
    let ty = self.expr_type(node)
    let temp = self.new_temp(ty)
    let place = self.place_for_local(temp)
    self.body.push_stmt(self.cur_bb, SK_ASSIGN(), place, rv, self.ast.get_start(node))
    self.body.new_operand(OK_COPY(), place)

fn MirBuilder.lower_cast(self: MirBuilder, expr: i32, target_type_id: i32, node: i32) -> i32:
    let op = self.lower_expr(expr)
    let rv = self.body.new_rvalue(RK_CAST(), op, target_type_id, 0)
    let temp = self.new_temp(target_type_id)
    let place = self.place_for_local(temp)
    self.body.push_stmt(self.cur_bb, SK_ASSIGN(), place, rv, self.ast.get_start(node))
    self.body.new_operand(OK_COPY(), place)

fn MirBuilder.lower_field_access(self: MirBuilder, base_expr: i32, field_idx: i32) -> i32:
    let base = self.lower_expr_place(base_expr)
    self.body.new_field_place(base, field_idx)

fn MirBuilder.lower_index(self: MirBuilder, base_expr: i32, index_expr: i32) -> i32:
    let base = self.lower_expr_place(base_expr)
    let idx_op = self.lower_expr(index_expr)
    let idx_ty = self.expr_type(index_expr)
    let idx_local = self.new_temp(idx_ty)
    let idx_place = self.place_for_local(idx_local)
    self.assign_operand_to_place(idx_place, idx_op, self.ast.get_start(index_expr))
    self.body.new_index_place(base, idx_local)

fn MirBuilder.lower_deref(self: MirBuilder, expr: i32) -> i32:
    let base = self.lower_expr_place(expr)
    self.body.new_deref_place(base)

fn MirBuilder.lower_ref(self: MirBuilder, expr: i32, borrow_kind: i32, node: i32) -> i32:
    let place = self.lower_expr_place(expr)
    let rv = self.body.new_rvalue(RK_REF(), borrow_kind, place, 0)
    let ty = self.expr_type(node)
    let temp = self.new_temp(ty)
    let temp_place = self.place_for_local(temp)
    self.body.push_stmt(self.cur_bb, SK_ASSIGN(), temp_place, rv, self.ast.get_start(node))
    self.body.new_operand(OK_COPY(), temp_place)

fn MirBuilder.lower_assign(self: MirBuilder, place_expr: i32, rhs_expr: i32):
    let place = self.lower_expr_place(place_expr)
    let rhs = self.lower_expr(rhs_expr)
    self.assign_operand_to_place(place, rhs, self.ast.get_start(place_expr))

fn MirBuilder.lower_expr_place(self: MirBuilder, node: i32) -> i32:
    if node == 0:
        return self.place_for_local(0)

    let kind = self.ast.kind(node)

    if kind == NK_IDENT():
        let sym = self.ast.get_data0(node)
        let local = self.lookup_local(sym)
        if local >= 0:
            return self.place_for_local(local)
        return self.place_for_local(0)

    if kind == NK_FIELD_ACCESS():
        let base = self.lower_expr_place(self.ast.get_data0(node))
        let field_sym = self.ast.get_data1(node)
        // Field symbol is mapped deterministically to a projection index by symbol value.
        return self.body.new_field_place(base, field_sym)

    if kind == NK_INDEX():
        return self.lower_index(self.ast.get_data0(node), self.ast.get_data1(node))

    if kind == NK_UNARY() and self.ast.get_data0(node) == UOP_DEREF():
        return self.lower_deref(self.ast.get_data1(node))

    if kind == NK_GROUPED():
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

    self.body.push_stmt(self.cur_bb, SK_STORAGE_LIVE(), local_id, 0, self.ast.get_start(node))
    if self.sema.is_copy(bind_ty) == 0:
        self.schedule_drop(local_id, DK_VALUE())

    let rhs_op = self.lower_expr(rhs_expr)
    let place = self.place_for_local(local_id)
    self.assign_operand_to_place(place, rhs_op, self.ast.get_start(node))

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
    self.terminate(TK_GOTO(), cont_bb, 0, 0, 0)

    self.switch_to(fail_bb)
    let _ = self.lower_expr(else_body)
    if self.body.term_kind(self.cur_bb) == TK_UNREACHABLE():
        self.terminate(TK_UNREACHABLE(), 0, 0, 0, 0)

    self.switch_to(cont_bb)

fn MirBuilder.lower_block(self: MirBuilder, node: i32) -> i32:
    let stmt_start = self.ast.get_data0(node)
    let stmt_count = self.ast.get_data1(node)
    let tail_expr = self.ast.get_data2(node)

    self.push_scope()

    for i in 0..stmt_count:
        let stmt = self.ast.get_extra(stmt_start + i)
        let sk = self.ast.kind(stmt)
        if sk == NK_LET_BINDING():
            self.lower_let_binding(stmt)
            continue
        if sk == NK_LET_ELSE():
            self.lower_let_else(stmt)
            continue
        if sk == NK_ASSIGN():
            self.lower_assign(self.ast.get_data0(stmt), self.ast.get_data1(stmt))
            continue
        if sk == NK_RETURN():
            let _ = self.lower_return(stmt)
            continue
        if sk == NK_BREAK():
            let _ = self.lower_break(stmt)
            continue
        if sk == NK_CONTINUE():
            let _ = self.lower_continue(stmt)
            continue
        let _ = self.lower_expr(stmt)

    let result = if tail_expr != 0: self.lower_expr(tail_expr) else: self.unit_operand()

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
    self.terminate(TK_SWITCH_INT(), cond_op, table, else_bb, 0)

    let result_ty = self.expr_type(node)
    let result_local = self.new_temp(result_ty)
    let result_place = self.place_for_local(result_local)

    self.switch_to(then_bb)
    let then_op = self.lower_expr(then_expr)
    self.assign_operand_to_place(result_place, then_op, self.ast.get_start(then_expr))
    self.terminate(TK_GOTO(), join_bb, 0, 0, 0)

    self.switch_to(else_bb)
    let else_op = if else_expr_opt != 0: self.lower_expr(else_expr_opt) else: self.unit_operand()
    self.assign_operand_to_place(result_place, else_op, self.ast.get_start(node))
    self.terminate(TK_GOTO(), join_bb, 0, 0, 0)

    self.switch_to(join_bb)
    if self.sema.is_copy(result_ty) != 0:
        return self.body.new_operand(OK_COPY(), result_place)
    self.body.new_operand(OK_MOVE(), result_place)

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
    self.terminate(TK_GOTO(), join_bb, 0, 0, 0)

    self.switch_to(else_bb)
    let else_op = if else_expr_opt != 0: self.lower_expr(else_expr_opt) else: self.unit_operand()
    self.assign_operand_to_place(result_place, else_op, self.ast.get_start(node))
    self.terminate(TK_GOTO(), join_bb, 0, 0, 0)

    self.switch_to(join_bb)
    if self.sema.is_copy(result_ty) != 0:
        return self.body.new_operand(OK_COPY(), result_place)
    self.body.new_operand(OK_MOVE(), result_place)

fn MirBuilder.lower_loop(self: MirBuilder, body_expr: i32, node: i32) -> i32:
    let header_bb = self.new_block()
    let body_bb = self.new_block()
    let break_bb = self.new_block()

    self.terminate(TK_GOTO(), header_bb, 0, 0, 0)

    self.switch_to(header_bb)
    self.terminate(TK_GOTO(), body_bb, 0, 0, 0)

    self.push_loop(header_bb, break_bb)

    self.switch_to(body_bb)
    let _ = self.lower_expr(body_expr)
    // Back-edge when body does not diverge.
    self.terminate(TK_GOTO(), header_bb, 0, 0, 0)

    self.pop_loop()
    self.switch_to(break_bb)
    self.unit_operand()

fn MirBuilder.lower_while(self: MirBuilder, cond_expr: i32, body_expr: i32) -> i32:
    let cond_bb = self.new_block()
    let body_bb = self.new_block()
    let exit_bb = self.new_block()

    self.terminate(TK_GOTO(), cond_bb, 0, 0, 0)

    self.push_loop(cond_bb, exit_bb)

    self.switch_to(cond_bb)
    let cond_op = self.lower_expr(cond_expr)
    let vals: Vec[i32] = Vec.new()
    vals.push(1)
    let targets: Vec[i32] = Vec.new()
    targets.push(body_bb)
    let table = self.body.new_switch_table(vals, targets)
    self.terminate(TK_SWITCH_INT(), cond_op, table, exit_bb, 0)

    self.switch_to(body_bb)
    let _ = self.lower_expr(body_expr)
    self.terminate(TK_GOTO(), cond_bb, 0, 0, 0)

    self.pop_loop()
    self.switch_to(exit_bb)
    self.unit_operand()

fn MirBuilder.lower_for(self: MirBuilder, pat_or_sym: i32, iter_expr: i32, body_expr: i32) -> i32:
    // Iterator protocol lowering shape:
    //   loop { if iter.next() is Some(x) { body } else { break } }
    let iter_op = self.lower_expr(iter_expr)
    let iter_ty = self.expr_type(iter_expr)
    let iter_place = self.materialize_operand(iter_op, iter_ty, self.ast.get_start(iter_expr))
    let elem_ty = self.sema.infer_for_element_type(iter_ty)

    let header_bb = self.new_block()
    let body_bb = self.new_block()
    let exit_bb = self.new_block()

    self.terminate(TK_GOTO(), header_bb, 0, 0, 0)
    self.push_loop(header_bb, exit_bb)

    self.switch_to(header_bb)
    let next_args: Vec[i32] = Vec.new()
    next_args.push(self.body.new_operand(OK_COPY(), iter_place))
    let args_id = self.body.new_call_args(next_args)
    let next_local = self.new_temp(iter_ty)
    let next_place = self.place_for_local(next_local)
    let after_next_bb = self.new_block()
    self.terminate(TK_CALL(), self.unit_operand(), args_id, next_place, after_next_bb)

    self.switch_to(after_next_bb)
    let disc = self.lower_enum_discriminant(next_place)
    let vals: Vec[i32] = Vec.new()
    vals.push(1)
    let targets: Vec[i32] = Vec.new()
    targets.push(body_bb)
    let table = self.body.new_switch_table(vals, targets)
    self.terminate(TK_SWITCH_INT(), disc, table, exit_bb, 0)

    self.switch_to(body_bb)
    let item_local = self.new_temp(elem_ty)
    let item_place = self.place_for_local(item_local)
    let next_payload = self.body.new_operand(OK_COPY(), next_place)
    self.assign_operand_to_place(item_place, next_payload, self.ast.get_start(iter_expr))

    if pat_or_sym > 0 and pat_or_sym < self.ast.node_count():
        let pk = self.ast.kind(pat_or_sym)
        if pk >= NK_PAT_WILDCARD() and pk <= NK_PAT_SLICE():
            let _ = self.lower_pattern(pat_or_sym, item_place)
        else:
            let bind_local = self.body.new_local(elem_ty, 0, pat_or_sym, 1)
            self.bind_local(pat_or_sym, bind_local)
            self.body.push_stmt(self.cur_bb, SK_STORAGE_LIVE(), bind_local, 0, self.ast.get_start(body_expr))
            if self.sema.is_copy(elem_ty) == 0:
                self.schedule_drop(bind_local, DK_VALUE())
            let bind_place = self.place_for_local(bind_local)
            let item_op = self.body.new_operand(OK_COPY(), item_place)
            self.assign_operand_to_place(bind_place, item_op, self.ast.get_start(body_expr))
    else:
        if pat_or_sym != 0:
            let bind_local = self.body.new_local(elem_ty, 0, pat_or_sym, 1)
            self.bind_local(pat_or_sym, bind_local)
            self.body.push_stmt(self.cur_bb, SK_STORAGE_LIVE(), bind_local, 0, self.ast.get_start(body_expr))
            if self.sema.is_copy(elem_ty) == 0:
                self.schedule_drop(bind_local, DK_VALUE())
            let bind_place = self.place_for_local(bind_local)
            let item_op = self.body.new_operand(OK_COPY(), item_place)
            self.assign_operand_to_place(bind_place, item_op, self.ast.get_start(body_expr))

    let _ = self.lower_expr(body_expr)
    self.terminate(TK_GOTO(), header_bb, 0, 0, 0)

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
    self.terminate(TK_GOTO(), loop_info.break_bb, 0, 0, 0)

    // Continue lowering in a fresh detached block to keep pass total.
    self.switch_to(self.new_block())
    self.unit_operand()

fn MirBuilder.lower_continue(self: MirBuilder, _node: i32) -> i32:
    let loop_info = self.current_loop()
    if loop_info.continue_bb < 0:
        return self.unit_operand()

    self.emit_drops_for_break(loop_info)
    self.terminate(TK_GOTO(), loop_info.continue_bb, 0, 0, 0)
    self.switch_to(self.new_block())
    self.unit_operand()

fn MirBuilder.lower_return(self: MirBuilder, node: i32) -> i32:
    let value_expr = self.ast.get_data0(node)
    let ret_op = if value_expr != 0: self.lower_expr(value_expr) else: self.unit_operand()
    let ret_place = self.place_for_local(0)
    self.assign_operand_to_place(ret_place, ret_op, self.ast.get_start(node))

    self.emit_drops_for_return()
    self.terminate(TK_RETURN(), 0, 0, 0, 0)

    // Keep lowering total by switching to an unreachable continuation block.
    self.switch_to(self.new_block())
    self.unit_operand()

fn MirBuilder.lower_unreachable(self: MirBuilder) -> i32:
    self.terminate(TK_UNREACHABLE(), 0, 0, 0, 0)
    self.switch_to(self.new_block())
    self.unit_operand()

fn MirBuilder.lower_enum_discriminant(self: MirBuilder, place: i32) -> i32:
    let rv = self.body.new_rvalue(RK_DISCRIMINANT(), place, 0, 0)
    let disc_local = self.new_temp(self.sema.ty_i32)
    let disc_place = self.place_for_local(disc_local)
    self.body.push_stmt(self.cur_bb, SK_ASSIGN(), disc_place, rv, 0)
    self.body.new_operand(OK_COPY(), disc_place)

fn MirBuilder.lower_pattern_match(self: MirBuilder, scrutinee_place: i32, pat_node: i32, arm_bb: i32, fail_bb: i32):
    if pat_node == 0:
        self.terminate(TK_GOTO(), arm_bb, 0, 0, 0)
        return

    let pk = self.ast.kind(pat_node)
    if pk == NK_PAT_WILDCARD() or pk == NK_PAT_IDENT() or pk == NK_PAT_AT_BINDING():
        self.terminate(TK_GOTO(), arm_bb, 0, 0, 0)
        return

    if pk == NK_PAT_OR():
        let p_start = self.ast.get_data0(pat_node)
        let p_count = self.ast.get_data1(pat_node)
        if p_count <= 0:
            self.terminate(TK_GOTO(), fail_bb, 0, 0, 0)
            return
        var next_test_bb = self.cur_bb
        for pi in 0..p_count:
            let alt_pat = self.ast.get_extra(p_start + pi)
            let alt_fail = if pi + 1 < p_count: self.new_block() else: fail_bb
            self.switch_to(next_test_bb)
            self.lower_pattern_match(scrutinee_place, alt_pat, arm_bb, alt_fail)
            next_test_bb = alt_fail
        return

    if pk == NK_PAT_VARIANT() or pk == NK_PAT_ENUM_SHORTHAND():
        let variant_sym = self.ast.get_data0(pat_node)
        let idx = self.variant_index(variant_sym)
        let disc = self.lower_enum_discriminant(scrutinee_place)
        let vals: Vec[i32] = Vec.new()
        vals.push(idx)
        let targets: Vec[i32] = Vec.new()
        targets.push(arm_bb)
        let table = self.body.new_switch_table(vals, targets)
        self.terminate(TK_SWITCH_INT(), disc, table, fail_bb, 0)
        return

    let scrutinee_op = self.body.new_operand(OK_COPY(), scrutinee_place)
    if pk == NK_PAT_INT() or pk == NK_PAT_BOOL() or pk == NK_PAT_STRING():
        let lit = if pk == NK_PAT_INT():
            self.lower_int_lit(self.ast.int_lit_value(pat_node), self.sema.ty_i32)
        else if pk == NK_PAT_BOOL():
            self.lower_bool_lit(self.ast.get_data0(pat_node))
        else:
            self.lower_str_lit(self.ast.get_data0(pat_node))
        let cmp_rv = self.body.new_rvalue(RK_BIN_OP(), OP_EQ(), scrutinee_op, lit)
        let cmp_tmp = self.new_temp(self.sema.ty_bool)
        let cmp_place = self.place_for_local(cmp_tmp)
        self.body.push_stmt(self.cur_bb, SK_ASSIGN(), cmp_place, cmp_rv, self.ast.get_start(pat_node))
        let cmp_op = self.body.new_operand(OK_COPY(), cmp_place)
        let vals: Vec[i32] = Vec.new()
        vals.push(1)
        let targets: Vec[i32] = Vec.new()
        targets.push(arm_bb)
        let table = self.body.new_switch_table(vals, targets)
        self.terminate(TK_SWITCH_INT(), cmp_op, table, fail_bb, 0)
        return

    // Tuple/struct/slice/range patterns are conservatively accepted here.
    self.terminate(TK_GOTO(), arm_bb, 0, 0, 0)

fn MirBuilder.lower_pattern(self: MirBuilder, pat_node: i32, scrutinee_place: i32) -> Vec[i32]:
    let out: Vec[i32] = Vec.new()
    if pat_node == 0:
        return out

    let pk = self.ast.kind(pat_node)
    if pk == NK_PAT_WILDCARD():
        return out

    if pk == NK_PAT_IDENT():
        let sym = self.ast.get_data0(pat_node)
        let bind_ty = self.place_local_type(scrutinee_place)
        let local_id = self.body.new_local(bind_ty, 0, sym, 1)
        self.bind_local(sym, local_id)
        self.body.push_stmt(self.cur_bb, SK_STORAGE_LIVE(), local_id, 0, self.ast.get_start(pat_node))
        if self.sema.is_copy(bind_ty) == 0:
            self.schedule_drop(local_id, DK_VALUE())
        let src_op = self.body.new_operand(if self.sema.is_copy(bind_ty) != 0: OK_COPY() else: OK_MOVE(), scrutinee_place)
        self.assign_operand_to_place(self.place_for_local(local_id), src_op, self.ast.get_start(pat_node))
        out.push(local_id)
        out.push(scrutinee_place)
        return out

    if pk == NK_PAT_AT_BINDING():
        let outer_sym = self.ast.get_data0(pat_node)
        let outer_ty = self.place_local_type(scrutinee_place)
        let outer_local = self.body.new_local(outer_ty, 0, outer_sym, 1)
        self.bind_local(outer_sym, outer_local)
        self.body.push_stmt(self.cur_bb, SK_STORAGE_LIVE(), outer_local, 0, self.ast.get_start(pat_node))
        if self.sema.is_copy(outer_ty) == 0:
            self.schedule_drop(outer_local, DK_VALUE())
        let outer_op = self.body.new_operand(if self.sema.is_copy(outer_ty) != 0: OK_COPY() else: OK_MOVE(), scrutinee_place)
        self.assign_operand_to_place(self.place_for_local(outer_local), outer_op, self.ast.get_start(pat_node))
        out.push(outer_local)
        out.push(scrutinee_place)
        let inner = self.lower_pattern(self.ast.get_data1(pat_node), scrutinee_place)
        for i in 0..inner.len() as i32:
            out.push(inner.get(i as i64))
        return out

    if pk == NK_PAT_VARIANT() or pk == NK_PAT_ENUM_SHORTHAND():
        let variant_sym = self.ast.get_data0(pat_node)
        let bind_start = self.ast.get_data1(pat_node)
        let bind_count = self.ast.get_data2(pat_node)
        let variant_place = self.body.new_downcast_place(scrutinee_place, self.variant_index(variant_sym))
        for bi in 0..bind_count:
            let sym = self.ast.get_extra(bind_start + bi)
            let bind_ty = self.place_local_type(scrutinee_place)
            let local_id = self.body.new_local(bind_ty, 0, sym, 1)
            self.bind_local(sym, local_id)
            self.body.push_stmt(self.cur_bb, SK_STORAGE_LIVE(), local_id, 0, self.ast.get_start(pat_node))
            if self.sema.is_copy(bind_ty) == 0:
                self.schedule_drop(local_id, DK_VALUE())
            let field_place = self.body.new_field_place(variant_place, bi)
            let src_op = self.body.new_operand(if self.sema.is_copy(bind_ty) != 0: OK_COPY() else: OK_MOVE(), field_place)
            self.assign_operand_to_place(self.place_for_local(local_id), src_op, self.ast.get_start(pat_node))
            out.push(local_id)
            out.push(field_place)
        return out

    if pk == NK_PAT_TUPLE():
        let t_start = self.ast.get_data0(pat_node)
        let t_count = self.ast.get_data1(pat_node)
        for ti in 0..t_count:
            let elem_pat = self.ast.get_extra(t_start + ti)
            let field_place = self.body.new_field_place(scrutinee_place, ti)
            let inner = self.lower_pattern(elem_pat, field_place)
            for i in 0..inner.len() as i32:
                out.push(inner.get(i as i64))
        return out

    if pk == NK_PAT_STRUCT():
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
                self.body.push_stmt(self.cur_bb, SK_STORAGE_LIVE(), local_id, 0, self.ast.get_start(pat_node))
                if self.sema.is_copy(bind_ty) == 0:
                    self.schedule_drop(local_id, DK_VALUE())
                let src_op = self.body.new_operand(if self.sema.is_copy(bind_ty) != 0: OK_COPY() else: OK_MOVE(), field_place)
                self.assign_operand_to_place(self.place_for_local(local_id), src_op, self.ast.get_start(pat_node))
                out.push(local_id)
                out.push(field_place)
        return out

    if pk == NK_PAT_OR():
        let p_start = self.ast.get_data0(pat_node)
        if self.ast.get_data1(pat_node) > 0:
            return self.lower_pattern(self.ast.get_extra(p_start), scrutinee_place)
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
            self.terminate(TK_SWITCH_INT(), guard_op, table, fail_bb, 0)
            self.switch_to(guard_pass_bb)

        let arm_value = self.lower_expr(body_node)
        self.assign_operand_to_place(result_place, arm_value, self.ast.get_start(body_node))
        self.terminate(TK_GOTO(), join_bb, 0, 0, 0)

        dispatch_bb = fail_bb

    self.switch_to(join_bb)
    if self.sema.is_copy(result_ty) != 0:
        return self.body.new_operand(OK_COPY(), result_place)
    self.body.new_operand(OK_MOVE(), result_place)

fn MirBuilder.lower_call(self: MirBuilder, fn_expr: i32, arg_exprs_start: i32, arg_exprs_count: i32, ret_type_id: i32, node: i32) -> i32:
    let fn_op = self.lower_expr(fn_expr)

    let args: Vec[i32] = Vec.new()
    for i in 0..arg_exprs_count:
        let arg_node = self.ast.get_extra(arg_exprs_start + i)
        args.push(self.lower_expr(arg_node))

    let args_id = self.body.new_call_args(args)
    let result_local = self.new_temp(ret_type_id)
    let result_place = self.place_for_local(result_local)
    let next_bb = self.new_block()

    self.terminate(TK_CALL(), fn_op, args_id, result_place, next_bb)
    self.switch_to(next_bb)

    if self.sema.is_copy(ret_type_id) != 0:
        return self.body.new_operand(OK_COPY(), result_place)
    self.body.new_operand(OK_MOVE(), result_place)

fn MirBuilder.resolve_method_callee_sym(self: MirBuilder, self_expr: i32, method_sym: i32) -> i32:
    let obj_type = self.expr_type(self_expr)
    if obj_type != 0:
        let resolved = self.sema.resolve_alias(obj_type)
        let type_name_sym = self.sema.get_type_name(resolved)
        if type_name_sym != 0:
            let method_key = self.sema.method_key(type_name_sym, method_sym)
            if self.sema.get_sig(method_key) >= 0:
                return method_key

    if self.ast.kind(self_expr) == NK_IDENT():
        let type_sym = self.ast.get_data0(self_expr)
        let method_key = self.sema.method_key(type_sym, method_sym)
        if self.sema.get_sig(method_key) >= 0:
            return method_key

    method_sym

fn MirBuilder.classify_intrinsic(self: MirBuilder, recv_type: i32, method_name: str) -> i32:
    if recv_type == 0 or method_name.len() == 0:
        return MIR_INTRINSIC_NONE()
    let resolved = self.sema.resolve_alias(recv_type)
    let type_name_sym = self.sema.get_type_name(resolved)
    if type_name_sym == 0:
        return MIR_INTRINSIC_NONE()
    let type_name = self.pool.resolve_symbol(type_name_sym)
    if type_name == "Vec":
        if method_name == "new": return MIR_INTRINSIC_VEC_NEW()
        if method_name == "push": return MIR_INTRINSIC_VEC_PUSH()
        if method_name == "get": return MIR_INTRINSIC_VEC_GET()
        if method_name == "len": return MIR_INTRINSIC_VEC_LEN()
        if method_name == "set_i32": return MIR_INTRINSIC_VEC_SET()
        if method_name == "remove": return MIR_INTRINSIC_VEC_REMOVE()
        if method_name == "clear": return MIR_INTRINSIC_VEC_CLEAR()
        if method_name == "pop": return MIR_INTRINSIC_VEC_POP()
        return MIR_INTRINSIC_NONE()
    if type_name == "HashMap":
        if method_name == "new": return MIR_INTRINSIC_MAP_NEW()
        if method_name == "insert": return MIR_INTRINSIC_MAP_INSERT()
        if method_name == "get": return MIR_INTRINSIC_MAP_GET()
        if method_name == "contains": return MIR_INTRINSIC_MAP_CONTAINS()
        if method_name == "len": return MIR_INTRINSIC_MAP_LEN()
        if method_name == "remove": return MIR_INTRINSIC_MAP_REMOVE()
        return MIR_INTRINSIC_NONE()
    if type_name == "HashSet":
        if method_name == "new": return MIR_INTRINSIC_MAP_NEW()
        if method_name == "insert": return MIR_INTRINSIC_MAP_INSERT()
        if method_name == "contains": return MIR_INTRINSIC_MAP_CONTAINS()
        if method_name == "len": return MIR_INTRINSIC_MAP_LEN()
        if method_name == "remove": return MIR_INTRINSIC_MAP_REMOVE()
        return MIR_INTRINSIC_NONE()
    if type_name == "Option":
        if method_name == "is_some": return MIR_INTRINSIC_OPT_IS_SOME()
        if method_name == "unwrap": return MIR_INTRINSIC_OPT_UNWRAP()
        return MIR_INTRINSIC_NONE()
    if type_name == "Result":
        if method_name == "is_ok": return MIR_INTRINSIC_OPT_IS_SOME()
        if method_name == "unwrap": return MIR_INTRINSIC_OPT_UNWRAP()
        return MIR_INTRINSIC_NONE()
    MIR_INTRINSIC_NONE()

fn MirBuilder.lower_method_call(self: MirBuilder, self_expr: i32, method_sym: i32, arg_start: i32, arg_count: i32, node: i32) -> i32:
    // Lower method calls as normal calls with receiver inserted as first arg.
    let callee_sym = self.resolve_method_callee_sym(self_expr, method_sym)
    let method_ident = self.ast.add_node(NK_IDENT(), self.ast.get_start(node), self.ast.get_end(node), callee_sym, 0, 0)
    let args: Vec[i32] = Vec.new()
    args.push(self_expr)
    for i in 0..arg_count:
        args.push(self.ast.get_extra(arg_start + i))

    let tmp_start = self.ast.extra_len()
    for i in 0..args.len() as i32:
        self.ast.add_extra(args.get(i as i64))

    // Classify intrinsic before lowering the call.
    // For instance methods (vec.push), recv_type comes from the receiver expression.
    // For static calls (Vec.new), the receiver is a type ident — use its symbol to
    // look up the type name, and fall back to the call's return type.
    var recv_type = self.expr_type(self_expr)
    if recv_type == 0 or recv_type == self.sema.ty_void:
        if self.ast.kind(self_expr) == NK_IDENT():
            let type_sym = self.ast.get_data0(self_expr)
            let ret_type = self.expr_type(node)
            let ret_name_sym = self.sema.get_type_name(ret_type)
            if ret_name_sym == type_sym:
                recv_type = ret_type
    let method_name = self.pool.resolve_symbol(method_sym)
    let intrinsic = self.classify_intrinsic(recv_type, method_name)

    let result = self.lower_call(method_ident, tmp_start, args.len() as i32, self.expr_type(node), node)

    // Tag the call that was just emitted.
    if intrinsic != MIR_INTRINSIC_NONE():
        let last_call_id = self.body.call_arg_starts.len() as i32 - 1
        self.body.set_call_intrinsic(last_call_id, intrinsic)

    result

fn MirBuilder.lower_vtable_call(self: MirBuilder, dyn_expr: i32, _trait_sym: i32, method_sym: i32, args_start: i32, args_count: i32, node: i32) -> i32:
    // Conservative lowering: treat as method call on dynamic receiver.
    self.lower_method_call(dyn_expr, method_sym, args_start, args_count, node)

fn MirBuilder.lower_question_mark(self: MirBuilder, expr: i32) -> i32:
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
    self.terminate(TK_SWITCH_INT(), disc, table, fail_bb, 0)

    self.switch_to(fail_bb)
    let ret_place = self.place_for_local(0)
    let fail_op = self.body.new_operand(OK_MOVE(), value_place)
    self.assign_operand_to_place(ret_place, fail_op, self.ast.get_start(expr))
    self.emit_drops_for_return()
    self.terminate(TK_RETURN(), 0, 0, 0, 0)

    self.switch_to(pass_bb)
    let result_local = self.new_temp(value_ty)
    let result_place = self.place_for_local(result_local)
    let pass_op = self.body.new_operand(if self.sema.is_copy(value_ty) != 0: OK_COPY() else: OK_MOVE(), value_place)
    self.assign_operand_to_place(result_place, pass_op, self.ast.get_start(expr))
    self.terminate(TK_GOTO(), join_bb, 0, 0, 0)

    self.switch_to(join_bb)
    if self.sema.is_copy(value_ty) != 0:
        return self.body.new_operand(OK_COPY(), result_place)
    self.body.new_operand(OK_MOVE(), result_place)

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
    self.terminate(TK_SWITCH_INT(), disc, table, none_bb, 0)

    let result_local = self.new_temp(value_ty)
    let result_place = self.place_for_local(result_local)

    self.switch_to(some_bb)
    let some_op = self.body.new_operand(if self.sema.is_copy(value_ty) != 0: OK_COPY() else: OK_MOVE(), value_place)
    self.assign_operand_to_place(result_place, some_op, self.ast.get_start(expr))
    self.terminate(TK_GOTO(), join_bb, 0, 0, 0)

    self.switch_to(none_bb)
    let default_op = self.lower_expr(default_expr)
    self.assign_operand_to_place(result_place, default_op, self.ast.get_start(default_expr))
    self.terminate(TK_GOTO(), join_bb, 0, 0, 0)

    self.switch_to(join_bb)
    if self.sema.is_copy(value_ty) != 0:
        return self.body.new_operand(OK_COPY(), result_place)
    self.body.new_operand(OK_MOVE(), result_place)

fn MirBuilder.lower_with_form1(self: MirBuilder, guard_expr: i32, body_expr: i32) -> i32:
    let _ = self.lower_expr(guard_expr)
    self.push_scope()
    let result = self.lower_expr(body_expr)
    self.pop_scope_inline()
    result

fn MirBuilder.lower_with_form2_3(self: MirBuilder, pat_or_name: i32, rhs_expr: i32, body_expr: i32) -> i32:
    self.push_scope()
    if self.ast.kind(pat_or_name) == NK_IDENT():
        let sym = self.ast.get_data0(pat_or_name)
        let ty = self.expr_type(rhs_expr)
        let local = self.body.new_local(ty, 0, sym, 1)
        self.bind_local(sym, local)
        self.body.push_stmt(self.cur_bb, SK_STORAGE_LIVE(), local, 0, self.ast.get_start(pat_or_name))
        if self.sema.is_copy(ty) == 0:
            self.schedule_drop(local, DK_VALUE())
        let rhs = self.lower_expr(rhs_expr)
        self.assign_operand_to_place(self.place_for_local(local), rhs, self.ast.get_start(rhs_expr))
    else:
        let _ = self.lower_expr(rhs_expr)
    let result = self.lower_expr(body_expr)
    self.pop_scope_inline()
    result

fn MirBuilder.lower_record_update(self: MirBuilder, base_expr: i32, field_updates_start: i32, field_updates_count: i32, node: i32) -> i32:
    let base = self.lower_expr(base_expr)
    let fields: Vec[i32] = Vec.new()
    fields.push(base)
    for i in 0..field_updates_count:
        let v = self.ast.get_extra(field_updates_start + i * 2 + 1)
        fields.push(self.lower_expr(v))
    let fields_id = self.body.new_agg_fields(fields)
    let rv = self.body.new_rvalue(RK_AGGREGATE(), 0, fields_id, 0)
    let ty = self.expr_type(node)
    let tmp = self.new_temp(ty)
    let place = self.place_for_local(tmp)
    self.body.push_stmt(self.cur_bb, SK_ASSIGN(), place, rv, self.ast.get_start(node))
    self.body.new_operand(OK_COPY(), place)

fn MirBuilder.lower_implicit_ok(self: MirBuilder, expr: i32, ok_type_id: i32) -> i32:
    let op = self.lower_expr(expr)
    let fields: Vec[i32] = Vec.new()
    fields.push(op)
    let fid = self.body.new_agg_fields(fields)
    let rv = self.body.new_rvalue(RK_AGGREGATE(), 1, fid, 0)
    let tmp = self.new_temp(ok_type_id)
    let place = self.place_for_local(tmp)
    self.body.push_stmt(self.cur_bb, SK_ASSIGN(), place, rv, self.ast.get_start(expr))
    self.body.new_operand(OK_COPY(), place)

fn MirBuilder.lower_implicit_default_return(self: MirBuilder, type_id: i32) -> i32:
    if type_id == self.sema.ty_void:
        return self.unit_operand()
    if self.sema.get_type_kind(type_id) == TY_BOOL():
        return self.lower_bool_lit(0)
    self.lower_int_lit(0, type_id)

fn MirBuilder.lower_pipeline(self: MirBuilder, lhs_expr: i32, fn_expr: i32, args_start: i32, args_count: i32, node: i32) -> i32:
    let tmp_start = self.ast.extra_len()
    self.ast.add_extra(lhs_expr)
    for i in 0..args_count:
        self.ast.add_extra(self.ast.get_extra(args_start + i))
    self.lower_call(fn_expr, tmp_start, args_count + 1, self.expr_type(node), node)

fn MirBuilder.lower_closure(self: MirBuilder, _captured_start: i32, _captured_count: i32, _params_start: i32, _params_count: i32, node: i32) -> i32:
    // Closure bodies are lowered as normal nested function bodies in later waves.
    let ty = self.expr_type(node)
    if ty == 0:
        return self.unit_operand()
    let tmp = self.new_temp(ty)
    let place = self.place_for_local(tmp)
    let zst = self.body.new_const(CK_ZERO_SIZED(), ty, 0, 0, ty)
    let op = self.body.new_operand(OK_CONSTANT(), zst)
    let rv = self.body.new_rvalue(RK_USE(), op, 0, 0)
    self.body.push_stmt(self.cur_bb, SK_ASSIGN(), place, rv, self.ast.get_start(node))
    self.body.new_operand(OK_COPY(), place)

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
    self.terminate(TK_SWITCH_INT(), disc, table, none_bb, 0)

    let result_ty = self.expr_type(node)
    let result_local = self.new_temp(result_ty)
    let result_place = self.place_for_local(result_local)

    self.switch_to(some_bb)
    if arg_count > 0:
        let args: Vec[i32] = Vec.new()
        args.push(self.body.new_operand(OK_COPY(), base_place))
        for ai in 0..arg_count:
            args.push(self.lower_expr(self.ast.get_extra(extra_start + 1 + ai)))
        let args_id = self.body.new_call_args(args)
        let call_next_bb = self.new_block()
        self.terminate(TK_CALL(), self.unit_operand(), args_id, result_place, call_next_bb)
        self.switch_to(call_next_bb)
    else:
        let field_place = self.body.new_field_place(base_place, member_sym)
        let field_op = self.body.new_operand(OK_COPY(), field_place)
        self.assign_operand_to_place(result_place, field_op, self.ast.get_start(node))
    self.terminate(TK_GOTO(), join_bb, 0, 0, 0)

    self.switch_to(none_bb)
    let default_op = self.lower_implicit_default_return(result_ty)
    self.assign_operand_to_place(result_place, default_op, self.ast.get_start(node))
    self.terminate(TK_GOTO(), join_bb, 0, 0, 0)

    self.switch_to(join_bb)
    if self.sema.is_copy(result_ty) != 0:
        return self.body.new_operand(OK_COPY(), result_place)
    self.body.new_operand(OK_MOVE(), result_place)

fn MirBuilder.lower_expr(self: MirBuilder, node: i32) -> i32:
    if node == 0:
        return self.unit_operand()

    let kind = self.ast.kind(node)

    if kind == NK_INT_LIT():
        return self.lower_int_lit(self.ast.int_lit_value(node), self.expr_type(node))

    if kind == NK_BOOL_LIT():
        return self.lower_bool_lit(self.ast.get_data0(node))

    if kind == NK_STRING_LIT() or kind == NK_C_STRING_LIT():
        return self.lower_str_lit(self.ast.get_data0(node))

    if kind == NK_FLOAT_LIT():
        return self.lower_float_lit(self.ast.get_data0(node))

    if kind == NK_IDENT():
        return self.lower_var(self.ast.get_data0(node), self.expr_type(node))

    if kind == NK_BINARY():
        let op = self.ast.get_data0(node)
        let lhs = self.ast.get_data1(node)
        let rhs = self.ast.get_data2(node)
        if op == OP_DEFAULT():
            return self.lower_double_question(lhs, rhs)
        return self.lower_bin_op(op, lhs, rhs, node)

    if kind == NK_UNARY():
        let op = self.ast.get_data0(node)
        let operand = self.ast.get_data1(node)
        if op == UOP_TRY():
            return self.lower_question_mark(operand)
        return self.lower_un_op(op, operand, node)

    if kind == NK_CAST():
        return self.lower_cast(self.ast.get_data0(node), self.sema.resolve_type_expr(self.ast.get_data1(node)), node)

    if kind == NK_FIELD_ACCESS():
        let place = self.lower_field_access(self.ast.get_data0(node), self.ast.get_data1(node))
        return self.body.new_operand(OK_COPY(), place)

    if kind == NK_INDEX():
        let place = self.lower_index(self.ast.get_data0(node), self.ast.get_data1(node))
        return self.body.new_operand(OK_COPY(), place)

    if kind == NK_BLOCK():
        return self.lower_block(node)

    if kind == NK_LET_BINDING():
        self.lower_let_binding(node)
        return self.unit_operand()

    if kind == NK_LET_ELSE():
        self.lower_let_else(node)
        return self.unit_operand()

    if kind == NK_ASSIGN():
        self.lower_assign(self.ast.get_data0(node), self.ast.get_data1(node))
        return self.unit_operand()

    if kind == NK_IF_EXPR():
        return self.lower_if(self.ast.get_data0(node), self.ast.get_data1(node), self.ast.get_data2(node), node)

    if kind == NK_WHILE():
        return self.lower_while(self.ast.get_data0(node), self.ast.get_data1(node))

    if kind == NK_LOOP():
        return self.lower_loop(self.ast.get_data0(node), node)

    if kind == NK_FOR():
        return self.lower_for(self.ast.get_data0(node), self.ast.get_data1(node), self.ast.get_data2(node))

    if kind == NK_BREAK():
        return self.lower_break(node)

    if kind == NK_CONTINUE():
        return self.lower_continue(node)

    if kind == NK_RETURN():
        return self.lower_return(node)

    if kind == NK_MATCH():
        return self.lower_match(self.ast.get_data0(node), self.ast.get_data1(node), self.ast.get_data2(node), node)

    if kind == NK_CALL():
        let callee = self.ast.get_data0(node)
        if self.ast.kind(callee) == NK_FIELD_ACCESS():
            return self.lower_method_call(self.ast.get_data0(callee), self.ast.get_data1(callee), self.ast.get_data1(node), self.ast.get_data2(node), node)
        return self.lower_call(callee, self.ast.get_data1(node), self.ast.get_data2(node), self.expr_type(node), node)

    if kind == NK_PIPELINE():
        let rhs = self.ast.get_data1(node)
        if self.ast.kind(rhs) == NK_CALL():
            return self.lower_pipeline(self.ast.get_data0(node), self.ast.get_data0(rhs), self.ast.get_data1(rhs), self.ast.get_data2(rhs), node)
        return self.lower_pipeline(self.ast.get_data0(node), rhs, 0, 0, node)

    if kind == NK_WITH_EXPR():
        let source = self.ast.get_data0(node)
        let body = self.ast.get_data1(node)
        let name = decode_with_binding_sym(self.ast.get_data2(node))
        if name != 0:
            let fake_ident = self.ast.add_node(NK_IDENT(), self.ast.get_start(node), self.ast.get_end(node), name, 0, 0)
            return self.lower_with_form2_3(fake_ident, source, body)
        return self.lower_with_form1(source, body)

    if kind == NK_RECORD_UPDATE():
        return self.lower_record_update(self.ast.get_data0(node), self.ast.get_data1(node), self.ast.get_data2(node), node)

    if kind == NK_CLOSURE():
        return self.lower_closure(0, 0, self.ast.get_data1(node), self.ast.get_data2(node), node)

    if kind == NK_GROUPED():
        return self.lower_expr(self.ast.get_data0(node))

    if kind == NK_OPTIONAL_CHAIN():
        return self.lower_optional_chain(node)

    if kind == NK_AWAIT() or kind == NK_ASYNC_BLOCK() or kind == NK_ASYNC_SCOPE() or kind == NK_SELECT_AWAIT() or kind == NK_SPAWN() or kind == NK_YIELD() or kind == NK_COMPTIME():
        // Async/comptime lowering is deferred to later waves.
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
    let sig_idx = builder.sema.get_sig(fn_sym)
    if sig_idx >= 0:
        builder.body.local_type_ids.set_i32(0, builder.sema.sig_return_type(sig_idx))
    else:
        builder.body.local_type_ids.set_i32(0, builder.sema.ty_void)

    builder.push_scope()

    // Parameters: locals 1..n
    let meta = builder.ast.find_fn_meta(fn_node)
    if meta >= 0 and sig_idx >= 0:
        let param_start = builder.ast.fn_meta_param_start(meta)
        let param_count = builder.ast.fn_meta_param_count(meta)

        for i in 0..param_count:
            let p_name = builder.ast.get_extra(param_start + i * 2)
            let p_ty = builder.sema.sig_param_type(sig_idx, i)
            let local_id = builder.body.new_local(p_ty, 0, p_name, 1)
            builder.bind_local(p_name, local_id)
            builder.body.push_stmt(builder.cur_bb, SK_STORAGE_LIVE(), local_id, 0, builder.ast.get_start(fn_node))
            if builder.sema.is_copy(p_ty) == 0:
                builder.schedule_drop(local_id, DK_VALUE())

    let body_expr = builder.ast.get_data1(fn_node)
    let result = builder.lower_expr(body_expr)

    // Implicit return value assignment for non-diverging tail expressions.
    let ret_place = builder.place_for_local(0)
    builder.assign_operand_to_place(ret_place, result, builder.ast.get_end(fn_node))

    builder.pop_scope_inline()
    builder.terminate(TK_RETURN(), 0, 0, 0, 0)

    builder.body

fn lower_module(sema: Sema, ast_pool: AstPool, pool: InternPool) -> MirModule:
    var mir_mod = MirModule.init()

    for di in 0..ast_pool.decl_count():
        let decl = ast_pool.get_decl(di)
        if ast_pool.kind(decl) != NK_FN_DECL():
            continue

        let fn_sym = ast_pool.get_data0(decl)
        let meta = ast_pool.find_fn_meta(decl)
        if meta >= 0 and ast_pool.fn_meta_tp_count(meta) > 0:
            // Skip generic fn bodies in this wave.
            continue

        var builder = MirBuilder.init(sema, ast_pool, pool, fn_sym)
        let body = lower_fn(builder, decl)
        mir_mod.add_body(body)

    mir_mod
