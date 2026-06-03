use Ast
use Diagnostic
use Mir
use Sema
use Span

fn suspend_bit_index(local_count: i32, bb: i32, local: i32) -> i32:
    bb * local_count + local

fn suspend_vec_fill(count: i32, value: i32) -> Vec[i32]:
    let out: Vec[i32] = Vec.new()
    for _ in 0..count:
        out.push(value)
    out

fn suspend_set_bit(bits: Vec[i32], local: i32, value: i32):
    if local < 0 or local >= bits.len() as i32:
        return
    bits.set_i32(local, value)

fn suspend_get_bit(bits: Vec[i32], local: i32) -> i32:
    if local < 0 or local >= bits.len() as i32:
        return 0
    bits.get(local as i64)

fn suspend_copy_block_bits(src: Vec[i32], local_count: i32, bb: i32) -> Vec[i32]:
    let out: Vec[i32] = Vec.new()
    for li in 0..local_count:
        out.push(src.get(suspend_bit_index(local_count, bb, li) as i64))
    out

fn suspend_store_block_bits(dst: Vec[i32], local_count: i32, bb: i32, src: Vec[i32]) -> i32:
    var changed = 0
    for li in 0..local_count:
        let idx = suspend_bit_index(local_count, bb, li)
        let old = dst.get(idx as i64)
        let next = src.get(li as i64)
        if old != next:
            dst.set_i32(idx, next)
            changed = 1
    changed

fn suspend_place_root_local(body: &MirBody, place_id: i32) -> i32:
    if place_id < 0 or place_id >= body.place_locals.len() as i32:
        return -1
    body.place_locals.get(place_id as i64)

fn suspend_gen_place(bits: Vec[i32], body: &MirBody, place_id: i32):
    suspend_set_bit(bits, suspend_place_root_local(body, place_id), 1)

fn suspend_kill_place(bits: Vec[i32], body: &MirBody, place_id: i32):
    suspend_set_bit(bits, suspend_place_root_local(body, place_id), 0)

fn suspend_gen_operand(bits: Vec[i32], body: &MirBody, operand_id: i32):
    if operand_id < 0 or operand_id >= body.operand_kinds.len() as i32:
        return
    let kind = body.operand_kinds.get(operand_id as i64)
    if kind == OperandKind.OK_COPY or kind == OperandKind.OK_MOVE:
        suspend_gen_place(bits, body, body.operand_d0.get(operand_id as i64))

fn suspend_gen_call_args(bits: Vec[i32], body: &MirBody, call_id: i32):
    if call_id < 0 or call_id >= body.call_arg_starts.len() as i32:
        return
    let start = body.call_arg_starts.get(call_id as i64)
    let count = body.call_arg_counts.get(call_id as i64)
    for ai in 0..count:
        suspend_gen_operand(bits, body, body.call_arg_operands.get((start + ai) as i64))

fn suspend_gen_agg_fields(bits: Vec[i32], body: &MirBody, field_id: i32):
    if field_id < 0 or field_id >= body.agg_field_starts.len() as i32:
        return
    let start = body.agg_field_starts.get(field_id as i64)
    let count = body.agg_field_counts.get(field_id as i64)
    for fi in 0..count:
        suspend_gen_operand(bits, body, body.agg_field_operands.get((start + fi) as i64))

fn suspend_gen_rvalue(bits: Vec[i32], body: &MirBody, rval_id: i32):
    if rval_id < 0 or rval_id >= body.rval_kinds.len() as i32:
        return
    let kind = body.rval_kinds.get(rval_id as i64)
    let d0 = body.rval_d0.get(rval_id as i64)
    let d1 = body.rval_d1.get(rval_id as i64)
    let d2 = body.rval_d2.get(rval_id as i64)

    if kind == RvalueKind.RK_USE:
        suspend_gen_operand(bits, body, d0)
        return
    if kind == RvalueKind.RK_BIN_OP:
        suspend_gen_operand(bits, body, d1)
        suspend_gen_operand(bits, body, d2)
        return
    if kind == RvalueKind.RK_UN_OP:
        suspend_gen_operand(bits, body, d1)
        return
    if kind == RvalueKind.RK_REF:
        suspend_gen_place(bits, body, d1)
        return
    if kind == RvalueKind.RK_ADDR_OF:
        suspend_gen_place(bits, body, d0)
        return
    if kind == RvalueKind.RK_AGGREGATE:
        suspend_gen_agg_fields(bits, body, d1)
        return
    if kind == RvalueKind.RK_DISCRIMINANT:
        suspend_gen_place(bits, body, d0)
        return
    if kind == RvalueKind.RK_CAST:
        suspend_gen_operand(bits, body, d0)
        return
    if kind == RvalueKind.RK_LEN:
        suspend_gen_place(bits, body, d0)
        return
    if kind == RvalueKind.RK_ARRAY_FILL:
        suspend_gen_operand(bits, body, d0)
        return
    if kind == RvalueKind.RK_STR_CONCAT_N:
        suspend_gen_call_args(bits, body, d0)

fn suspend_type_owner_sym(sema: Sema, tid: i32) -> i32:
    if tid <= 0:
        return 0
    sema.get_type_name(tid as TypeId)

fn suspend_type_has_semantic_drop(sema: Sema, tid: i32) -> i32:
    let owner = suspend_type_owner_sym(sema, tid)
    if owner == 0:
        return 0
    sema.has_drop_method(owner)

fn suspend_drop_is_semantic(sema: Sema, body: &MirBody, place_id: i32) -> i32:
    let local = suspend_place_root_local(body, place_id)
    if local < 0 or local >= body.local_type_ids.len() as i32:
        return 0
    suspend_type_has_semantic_drop(sema, body.local_type_ids.get(local as i64))

fn suspend_transfer_stmt(bits: Vec[i32], sema: Sema, body: &MirBody, stmt_id: i32):
    let kind = body.stmt_kind(stmt_id)
    let d0 = body.stmt_data0(stmt_id)
    let d1 = body.stmt_data1(stmt_id)

    if kind == StmtKind.Assign:
        suspend_kill_place(bits, body, d0)
        suspend_gen_rvalue(bits, body, d1)
        return
    if kind == StmtKind.StorageLive or kind == StmtKind.StorageDead:
        suspend_set_bit(bits, d0, 0)
        return
    if kind == StmtKind.Drop:
        suspend_kill_place(bits, body, d0)
        if suspend_drop_is_semantic(sema, body, d0) != 0:
            suspend_gen_place(bits, body, d0)

fn suspend_transfer_term(bits: Vec[i32], sema: Sema, body: &MirBody, bb: i32):
    let kind = body.term_kind(bb)
    let d0 = body.term_data0(bb)
    let d1 = body.term_data1(bb)
    let d2 = body.term_data2(bb)

    if kind == TermKind.TK_SWITCH_INT:
        suspend_gen_operand(bits, body, d0)
        return
    if kind == TermKind.TK_CALL:
        suspend_kill_place(bits, body, d2)
        suspend_gen_operand(bits, body, d0)
        suspend_gen_call_args(bits, body, d1)
        return
    if kind == TermKind.TK_DROP_AND_GOTO:
        suspend_kill_place(bits, body, d0)
        if suspend_drop_is_semantic(sema, body, d0) != 0:
            suspend_gen_place(bits, body, d0)

fn suspend_compute_live_in_for_block(body: &MirBody, sema: Sema, live_out: Vec[i32], local_count: i32, bb: i32) -> Vec[i32]:
    let bits = suspend_copy_block_bits(live_out, local_count, bb)
    suspend_transfer_term(bits, sema, body, bb)

    let stmt_start = body.bb_stmt_starts.get(bb as i64)
    let stmt_count = body.bb_stmt_counts.get(bb as i64)
    var si = stmt_count - 1
    while si >= 0:
        suspend_transfer_stmt(bits, sema, body, stmt_start + si)
        si = si - 1
    bits

fn suspend_add_successor_live(body: &MirBody, live_in: Vec[i32], local_count: i32, target_bb: i32, out_bits: Vec[i32]):
    if target_bb < 0 or target_bb >= body.block_count():
        return
    for li in 0..local_count:
        if live_in.get(suspend_bit_index(local_count, target_bb, li) as i64) != 0:
            out_bits.set_i32(li, 1)

fn suspend_compute_live_out_for_block(body: &MirBody, live_in: Vec[i32], local_count: i32, bb: i32) -> Vec[i32]:
    let out_bits = suspend_vec_fill(local_count, 0)
    let kind = body.term_kind(bb)
    let d0 = body.term_data0(bb)
    let d1 = body.term_data1(bb)
    let d2 = body.term_data2(bb)
    let d3 = body.term_data3(bb)

    if kind == TermKind.TK_GOTO:
        suspend_add_successor_live(body, live_in, local_count, d0, out_bits)
    else if kind == TermKind.TK_CALL:
        suspend_add_successor_live(body, live_in, local_count, d3, out_bits)
    else if kind == TermKind.TK_DROP_AND_GOTO:
        suspend_add_successor_live(body, live_in, local_count, d1, out_bits)
    else if kind == TermKind.TK_SWITCH_INT:
        if d1 >= 0 and d1 < body.switch_table_starts.len() as i32:
            let start = body.switch_table_starts.get(d1 as i64)
            let count = body.switch_table_counts.get(d1 as i64)
            for ti in 0..count:
                suspend_add_successor_live(body, live_in, local_count, body.switch_table_targets.get((start + ti) as i64), out_bits)
        suspend_add_successor_live(body, live_in, local_count, d2, out_bits)
    out_bits

fn suspend_is_scheduler_yield_intrinsic(intrinsic: MirIntrinsic) -> i32:
    if intrinsic == MirIntrinsic.FIBER_AWAIT:
        return 1
    if intrinsic == MirIntrinsic.FIBER_CLEANUP_AWAIT:
        return 1
    if intrinsic == MirIntrinsic.FIBER_SELECT:
        return 1
    if intrinsic == MirIntrinsic.FIBER_SELECT_BIASED:
        return 1
    if intrinsic == MirIntrinsic.SCOPE_AWAIT_ALL:
        return 1
    0

fn suspend_callee_sym(body: &MirBody, operand_id: i32) -> i32:
    if operand_id < 0 or operand_id >= body.operand_kinds.len() as i32:
        return 0
    if body.operand_kinds.get(operand_id as i64) != OperandKind.OK_CONSTANT:
        return 0
    let const_id = body.operand_d0.get(operand_id as i64)
    if const_id < 0 or const_id >= body.const_kinds.len() as i32:
        return 0
    if body.const_kinds.get(const_id as i64) != ConstKind.CK_FN:
        return 0
    body.const_d0.get(const_id as i64)

fn suspend_term_directly_yields(body: &MirBody, bb: i32) -> i32:
    if body.term_kind(bb) != TermKind.TK_CALL:
        return 0
    let call_id = body.term_data1(bb)
    suspend_is_scheduler_yield_intrinsic(body.call_intrinsic(call_id))

fn suspend_build_body_index(mir_mod: MirModule) -> HashMap[i32, i32]:
    let body_by_fn: HashMap[i32, i32] = HashMap.new()
    for bi in 0..mir_mod.bodies.len() as i32:
        let body = mir_mod.bodies.get(bi as i64)
        if body.fn_sym != 0:
            body_by_fn.insert(body.fn_sym, bi)
    body_by_fn

fn suspend_body_index_for_sym(body_by_fn: HashMap[i32, i32], fn_sym: i32) -> i32:
    if fn_sym == 0:
        return -1
    if not body_by_fn.contains(fn_sym):
        return -1
    body_by_fn.get(fn_sym).unwrap()

fn suspend_body_has_direct_yield(body: &MirBody) -> i32:
    for bb in 0..body.block_count():
        if suspend_term_directly_yields(body, bb) != 0:
            return 1
    0

fn suspend_body_calls_may_suspend(body: &MirBody, body_by_fn: HashMap[i32, i32], body_may_suspend: Vec[i32]) -> i32:
    for bb in 0..body.block_count():
        if body.term_kind(bb) != TermKind.TK_CALL:
            continue
        let callee = suspend_callee_sym(body, body.term_data0(bb))
        let callee_idx = suspend_body_index_for_sym(body_by_fn, callee)
        if callee_idx < 0 or callee_idx >= body_may_suspend.len() as i32:
            continue
        if body_may_suspend.get(callee_idx as i64) != 0:
            return 1
    0

fn suspend_compute_may_suspend(mir_mod: MirModule, body_by_fn: HashMap[i32, i32]) -> Vec[i32]:
    let body_count = mir_mod.bodies.len() as i32
    let body_may_suspend = suspend_vec_fill(body_count, 0)
    for bi in 0..body_count:
        let body = mir_mod.bodies.get(bi as i64)
        if suspend_body_has_direct_yield(&body) != 0:
            body_may_suspend.set_i32(bi, 1)

    var changed = 1
    while changed != 0:
        changed = 0
        for bi2 in 0..body_count:
            if body_may_suspend.get(bi2 as i64) != 0:
                continue
            let body = mir_mod.bodies.get(bi2 as i64)
            if suspend_body_calls_may_suspend(&body, body_by_fn, body_may_suspend) != 0:
                body_may_suspend.set_i32(bi2, 1)
                changed = 1
    body_may_suspend

fn suspend_term_may_suspend(body: &MirBody, body_by_fn: HashMap[i32, i32], body_may_suspend: Vec[i32], bb: i32) -> i32:
    if body.term_kind(bb) != TermKind.TK_CALL:
        return 0
    if suspend_term_directly_yields(body, bb) != 0:
        return 1
    let callee = suspend_callee_sym(body, body.term_data0(bb))
    let callee_idx = suspend_body_index_for_sym(body_by_fn, callee)
    if callee_idx < 0 or callee_idx >= body_may_suspend.len() as i32:
        return 0
    body_may_suspend.get(callee_idx as i64)

fn suspend_type_is_no_await_guard(sema: Sema, tid: i32) -> i32:
    sema.type_is_no_await_guard(tid)

fn suspend_body_has_guard_local(sema: Sema, body: &MirBody) -> i32:
    for li in 0..body.local_count():
        let local_ty = body.local_type_ids.get(li as i64)
        if suspend_type_is_no_await_guard(sema, local_ty) != 0:
            return 1
    0

fn suspend_body_has_may_suspend_term(body: &MirBody, body_by_fn: HashMap[i32, i32], body_may_suspend: Vec[i32]) -> i32:
    for bb in 0..body.block_count():
        if suspend_term_may_suspend(body, body_by_fn, body_may_suspend, bb) != 0:
            return 1
    0

type SuspendSiteSpan {
    start: i32,
    end: i32,
}

fn suspend_site_span(ast: AstPool, body: &MirBody, bb: i32) -> SuspendSiteSpan:
    let call_id = body.term_data1(bb)
    let node = body.call_ast_node(call_id)
    var start = body.bb_term_spans.get(bb as i64)
    var end = start + 1
    if node != 0:
        start = ast.get_start(node)
        end = ast.get_end(node)
    if end <= start:
        end = start + 1
    SuspendSiteSpan { start, end }

fn suspend_reported_site(reported_starts: &Vec[i32], reported_ends: &Vec[i32], reported_locals: &Vec[i32], site: SuspendSiteSpan, guard_local: i32) -> bool:
    let count = reported_starts.len() as i32
    for i in 0..count:
        if reported_starts.get(i as i64) == site.start and reported_ends.get(i as i64) == site.end and reported_locals.get(i as i64) == guard_local:
            return true
    false

fn suspend_emit_guard_error(diags: DiagnosticList, sema: Sema, body: &MirBody, site: SuspendSiteSpan, guard_local: i32) -> DiagnosticList:
    var out = diags
    let guard_ty = if guard_local >= 0 and guard_local < body.local_type_ids.len() as i32: body.local_type_ids.get(guard_local as i64) else: 0
    let guard_name_sym = if guard_local >= 0 and guard_local < body.local_names.len() as i32: body.local_names.get(guard_local as i64) else: 0
    let guard_name = if guard_name_sym != 0: sema.pool_resolve(guard_name_sym) else: "guard"
    let guard_type_name = sema.type_name(guard_ty)
    var diag = Diagnostic.err("E0701: " ++ guard_type_name ++ " value is live across a suspension point", Span { file: sema.local_file_id, start: site.start, end: site.end })
    if guard_name.len() > 0:
        diag.add_note("`" ++ guard_name ++ "` is still live here")
    diag.add_help("move, copy, or clone the needed data before awaiting, or drop the guard before the suspension point")
    out.emit(diag)
    out

fn suspend_check_body(ast: AstPool, sema: Sema, body_by_fn: HashMap[i32, i32], body_may_suspend: Vec[i32], body: &MirBody, diags: DiagnosticList) -> DiagnosticList:
    var out = diags
    let local_count = body.local_count()
    let bb_count = body.block_count()
    if local_count <= 0 or bb_count <= 0:
        return out
    if suspend_body_has_guard_local(sema, body) == 0:
        return out
    if suspend_body_has_may_suspend_term(body, body_by_fn, body_may_suspend) == 0:
        return out

    let bit_count = local_count * bb_count
    let live_in = suspend_vec_fill(bit_count, 0)
    let live_out = suspend_vec_fill(bit_count, 0)
    let reported_starts: Vec[i32] = Vec.new()
    let reported_ends: Vec[i32] = Vec.new()
    let reported_locals: Vec[i32] = Vec.new()

    var changed = 1
    while changed != 0:
        changed = 0
        var bb = bb_count - 1
        while bb >= 0:
            let out_bits = suspend_compute_live_out_for_block(body, live_in, local_count, bb)
            if suspend_store_block_bits(live_out, local_count, bb, out_bits) != 0:
                changed = 1
            let in_bits = suspend_compute_live_in_for_block(body, sema, live_out, local_count, bb)
            if suspend_store_block_bits(live_in, local_count, bb, in_bits) != 0:
                changed = 1
            bb = bb - 1

    for bb in 0..bb_count:
        if suspend_term_may_suspend(body, body_by_fn, body_may_suspend, bb) == 0:
            continue
        let bits = suspend_copy_block_bits(live_out, local_count, bb)
        suspend_transfer_term(bits, sema, body, bb)
        for li in 0..local_count:
            if suspend_get_bit(bits, li) == 0:
                continue
            let local_ty = body.local_type_ids.get(li as i64)
            if suspend_type_is_no_await_guard(sema, local_ty) != 0:
                let site = suspend_site_span(ast, body, bb)
                if not suspend_reported_site(&reported_starts, &reported_ends, &reported_locals, site, li):
                    reported_starts.push(site.start)
                    reported_ends.push(site.end)
                    reported_locals.push(li)
                    out = suspend_emit_guard_error(out, sema, body, site, li)
                break
    out

fn check_no_await_guard_suspends(mir_mod: MirModule, ast: AstPool, sema: Sema, diags: DiagnosticList) -> DiagnosticList:
    var out = diags
    let body_by_fn = suspend_build_body_index(mir_mod)
    let body_may_suspend = suspend_compute_may_suspend(mir_mod, body_by_fn)
    for bi in 0..mir_mod.bodies.len() as i32:
        let body = mir_mod.bodies.get(bi as i64)
        out = suspend_check_body(ast, sema, body_by_fn, body_may_suspend, &body, out)
    out
