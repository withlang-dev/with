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

// Dataflow bit-vector handle: copies share state by design (AstPool
// pattern, truthfully Copy) so the transfer kernels can mutate vectors
// passed through plain parameters under spec §3.8.
type SuspendBitsState {
    w: Vec[i32],
}

type SuspendBits {
    state: *mut SuspendBitsState,
}
impl Copy for SuspendBits

extern fn with_alloc(size: i64) -> *mut u8

fn SuspendBits.vget(self: SuspendBits, idx: i64) -> i32:
    let st = self.state
    unsafe { st.w.get(idx) }

fn SuspendBits.vset(self: SuspendBits, idx: i32, value: i32):
    let st = self.state
    unsafe { st.w.set_i32(idx, value) }

fn SuspendBits.vlen(self: SuspendBits) -> i64:
    let st = self.state
    unsafe { st.w.len() }

fn SuspendBits.vpush(self: SuspendBits, value: i32):
    let st = self.state
    unsafe { st.w.push(value) }

fn suspend_bits_fill(count: i32, value: i32) -> SuspendBits:
    // Vec header is larger than a pointer; allocate generously like the
    // other handle states (InternPool uses 256 for a 7-field state).
    let ptr = with_alloc(64) as *mut SuspendBitsState
    unsafe *ptr = SuspendBitsState { w: suspend_vec_fill(count, value) }
    SuspendBits { state: ptr }

fn suspend_set_bit(bits: SuspendBits, local: i32, value: i32):
    if local < 0 or local >= bits.vlen() as i32:
        return
    bits.vset(local, value)

fn suspend_get_bit(bits: SuspendBits, local: i32) -> i32:
    if local < 0 or local >= bits.vlen() as i32:
        return 0
    bits.vget(local as i64)

fn suspend_copy_block_bits(src: SuspendBits, local_count: i32, bb: i32) -> SuspendBits:
    let out = suspend_bits_fill(0, 0)
    for li in 0..local_count:
        out.vpush(src.vget(suspend_bit_index(local_count, bb, li) as i64))
    out

fn suspend_store_block_bits(dst: SuspendBits, local_count: i32, bb: i32, src: SuspendBits) -> i32:
    var changed = 0
    for li in 0..local_count:
        let idx = suspend_bit_index(local_count, bb, li)
        let old = dst.vget(idx as i64)
        let next = src.vget(li as i64)
        if old != next:
            dst.vset(idx, next)
            changed = 1
    changed

fn suspend_place_root_local(body: &MirBody, place_id: i32) -> i32:
    if place_id < 0 or place_id >= body.place_locals.len() as i32:
        return -1
    body.place_locals.get(place_id as i64)

fn suspend_direct_place_local(body: &MirBody, place_id: i32) -> i32:
    if place_id < 0 or place_id >= body.place_locals.len() as i32:
        return -1
    if body.place_proj_counts.get(place_id as i64) != 0:
        return -1
    body.place_locals.get(place_id as i64)

fn suspend_gen_place(bits: SuspendBits, body: &MirBody, place_id: i32):
    suspend_set_bit(bits, suspend_place_root_local(body, place_id), 1)

fn suspend_kill_place(bits: SuspendBits, body: &MirBody, place_id: i32):
    suspend_set_bit(bits, suspend_place_root_local(body, place_id), 0)

fn suspend_gen_operand(bits: SuspendBits, body: &MirBody, operand_id: i32):
    if operand_id < 0 or operand_id >= body.operand_kinds.len() as i32:
        return
    let kind = body.operand_kinds.get(operand_id as i64)
    if kind == OperandKind.OK_COPY or kind == OperandKind.OK_MOVE:
        suspend_gen_place(bits, body, body.operand_d0.get(operand_id as i64))

fn suspend_gen_call_args(bits: SuspendBits, body: &MirBody, call_id: i32):
    if call_id < 0 or call_id >= body.call_arg_starts.len() as i32:
        return
    let start = body.call_arg_starts.get(call_id as i64)
    let count = body.call_arg_counts.get(call_id as i64)
    for ai in 0..count:
        suspend_gen_operand(bits, body, body.call_arg_operands.get((start + ai) as i64))

fn suspend_gen_agg_fields(bits: SuspendBits, body: &MirBody, field_id: i32):
    if field_id < 0 or field_id >= body.agg_field_starts.len() as i32:
        return
    let start = body.agg_field_starts.get(field_id as i64)
    let count = body.agg_field_counts.get(field_id as i64)
    for fi in 0..count:
        suspend_gen_operand(bits, body, body.agg_field_operands.get((start + fi) as i64))

fn suspend_gen_rvalue(bits: SuspendBits, body: &MirBody, rval_id: i32):
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

fn suspend_type_owner_sym(sema: &Sema, tid: i32) -> i32:
    if tid <= 0:
        return 0
    sema.get_type_name(tid as TypeId)

fn suspend_type_has_semantic_drop(sema: &Sema, tid: i32) -> i32:
    let owner = suspend_type_owner_sym(sema, tid)
    if owner == 0:
        return 0
    sema.has_drop_method(owner)

fn suspend_drop_is_semantic(sema: &Sema, body: &MirBody, place_id: i32) -> i32:
    let local = suspend_place_root_local(body, place_id)
    if local < 0 or local >= body.local_type_ids.len() as i32:
        return 0
    suspend_type_has_semantic_drop(sema, body.local_type_ids.get(local as i64))

fn suspend_transfer_stmt(bits: SuspendBits, sema: &Sema, body: &MirBody, stmt_id: i32):
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

fn suspend_transfer_term(bits: SuspendBits, sema: &Sema, body: &MirBody, bb: i32):
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

fn suspend_compute_live_in_for_block(body: &MirBody, sema: &Sema, live_out: SuspendBits, local_count: i32, bb: i32) -> SuspendBits:
    let bits = suspend_copy_block_bits(live_out, local_count, bb)
    suspend_transfer_term(bits, sema, body, bb)

    let stmt_start = body.bb_stmt_starts.get(bb as i64)
    let stmt_count = body.bb_stmt_counts.get(bb as i64)
    var si = stmt_count - 1
    while si >= 0:
        suspend_transfer_stmt(bits, sema, body, stmt_start + si)
        si = si - 1
    bits

fn suspend_add_successor_live(body: &MirBody, live_in: SuspendBits, local_count: i32, target_bb: i32, out_bits: SuspendBits):
    if target_bb < 0 or target_bb >= body.block_count():
        return
    for li in 0..local_count:
        if live_in.vget(suspend_bit_index(local_count, target_bb, li) as i64) != 0:
            out_bits.vset(li, 1)

fn suspend_compute_live_out_for_block(body: &MirBody, live_in: SuspendBits, local_count: i32, bb: i32) -> SuspendBits:
    let out_bits = suspend_bits_fill(local_count, 0)
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

fn suspend_body_calls_may_suspend(body: &MirBody, body_by_fn: HashMap[i32, i32], body_may_suspend: SuspendBits) -> i32:
    for bb in 0..body.block_count():
        if body.term_kind(bb) != TermKind.TK_CALL:
            continue
        let callee = suspend_callee_sym(body, body.term_data0(bb))
        let callee_idx = suspend_body_index_for_sym(body_by_fn, callee)
        if callee_idx < 0 or callee_idx >= body_may_suspend.vlen() as i32:
            continue
        if body_may_suspend.vget(callee_idx as i64) != 0:
            return 1
    0

fn suspend_compute_may_suspend(mir_mod: MirModule, body_by_fn: HashMap[i32, i32]) -> SuspendBits:
    let body_count = mir_mod.bodies.len() as i32
    let body_may_suspend = suspend_bits_fill(body_count, 0)
    for bi in 0..body_count:
        let body = mir_mod.bodies.get(bi as i64)
        if suspend_body_has_direct_yield(&body) != 0:
            body_may_suspend.vset(bi, 1)

    var changed = 1
    while changed != 0:
        changed = 0
        for bi2 in 0..body_count:
            if body_may_suspend.vget(bi2 as i64) != 0:
                continue
            let body = mir_mod.bodies.get(bi2 as i64)
            if suspend_body_calls_may_suspend(&body, body_by_fn, body_may_suspend) != 0:
                body_may_suspend.vset(bi2, 1)
                changed = 1
    body_may_suspend

fn suspend_term_may_suspend(body: &MirBody, body_by_fn: HashMap[i32, i32], body_may_suspend: SuspendBits, bb: i32) -> i32:
    if body.term_kind(bb) != TermKind.TK_CALL:
        return 0
    if suspend_term_directly_yields(body, bb) != 0:
        return 1
    let callee = suspend_callee_sym(body, body.term_data0(bb))
    let callee_idx = suspend_body_index_for_sym(body_by_fn, callee)
    if callee_idx < 0 or callee_idx >= body_may_suspend.vlen() as i32:
        return 0
    body_may_suspend.vget(callee_idx as i64)

fn suspend_type_is_no_await_guard(sema: &Sema, tid: i32) -> i32:
    sema.type_is_no_await_guard(tid)

fn suspend_type_is_ref_like(sema: &Sema, tid: i32) -> i32:
    if tid <= 0:
        return 0
    let kind = sema.get_type_kind(sema.resolve_alias(tid as TypeId))
    if kind == TypeKind.TY_REF or kind == TypeKind.TY_PTR:
        return 1
    0

fn suspend_local_is_ref_like(sema: &Sema, body: &MirBody, local: i32) -> i32:
    if local < 0 or local >= body.local_type_ids.len() as i32:
        return 0
    suspend_type_is_ref_like(sema, body.local_type_ids.get(local as i64))

fn suspend_body_has_guard_local(sema: &Sema, body: &MirBody) -> i32:
    for li in 0..body.local_count():
        let local_ty = body.local_type_ids.get(li as i64)
        if suspend_type_is_no_await_guard(sema, local_ty) != 0:
            return 1
    0

fn suspend_body_has_may_suspend_term(body: &MirBody, body_by_fn: HashMap[i32, i32], body_may_suspend: SuspendBits) -> i32:
    for bb in 0..body.block_count():
        if suspend_term_may_suspend(body, body_by_fn, body_may_suspend, bb) != 0:
            return 1
    0

fn suspend_collect_guard_locals(sema: &Sema, body: &MirBody) -> Vec[i32]:
    let out: Vec[i32] = Vec.new()
    for li in 0..body.local_count():
        let local_ty = body.local_type_ids.get(li as i64)
        if suspend_type_is_no_await_guard(sema, local_ty) != 0:
            out.push(li)
    out

fn suspend_guard_index(guard_locals: &Vec[i32], guard_local: i32) -> i32:
    for gi in 0..guard_locals.len() as i32:
        if guard_locals.get(gi as i64) == guard_local:
            return gi
    -1

fn suspend_guard_index_for_sym(body: &MirBody, guard_locals: &Vec[i32], sym: i32) -> i32:
    if sym == 0:
        return -1
    for gi in 0..guard_locals.len() as i32:
        let local = guard_locals.get(gi as i64)
        if local >= 0 and local < body.local_names.len() as i32:
            if body.local_names.get(local as i64) == sym:
                return gi
    -1

fn suspend_prov_index(local_count: i32, guard_count: i32, bb: i32, local: i32, guard_idx: i32) -> i32:
    ((bb * local_count) + local) * guard_count + guard_idx

fn suspend_prov_local_index(guard_count: i32, local: i32, guard_idx: i32) -> i32:
    local * guard_count + guard_idx

fn suspend_prov_copy_block_bits(src: SuspendBits, local_count: i32, guard_count: i32, bb: i32) -> SuspendBits:
    let out = suspend_bits_fill(0, 0)
    for li in 0..local_count:
        for gi in 0..guard_count:
            out.vpush(src.vget(suspend_prov_index(local_count, guard_count, bb, li, gi) as i64))
    out

fn suspend_prov_get_local_origin(bits: SuspendBits, guard_count: i32, local: i32, guard_idx: i32) -> i32:
    if local < 0 or guard_idx < 0:
        return 0
    let idx = suspend_prov_local_index(guard_count, local, guard_idx)
    if idx < 0 or idx >= bits.vlen() as i32:
        return 0
    bits.vget(idx as i64)

fn suspend_prov_set_local_origin(bits: SuspendBits, guard_count: i32, local: i32, guard_idx: i32, value: i32):
    if local < 0 or guard_idx < 0:
        return
    let idx = suspend_prov_local_index(guard_count, local, guard_idx)
    if idx < 0 or idx >= bits.vlen() as i32:
        return
    bits.vset(idx, value)

fn suspend_prov_clear_local(bits: SuspendBits, local_count: i32, guard_count: i32, local: i32):
    if local < 0 or local >= local_count:
        return
    for gi in 0..guard_count:
        suspend_prov_set_local_origin(bits, guard_count, local, gi, 0)

fn suspend_prov_set_local_origins(bits: SuspendBits, local_count: i32, guard_count: i32, local: i32, origins: SuspendBits):
    if local < 0 or local >= local_count:
        return
    for gi in 0..guard_count:
        if gi < origins.vlen() as i32 and origins.vget(gi as i64) != 0:
            suspend_prov_set_local_origin(bits, guard_count, local, gi, 1)

fn suspend_prov_origins_empty(guard_count: i32) -> SuspendBits:
    suspend_bits_fill(guard_count, 0)

fn suspend_prov_copy_origins_from_local(bits: SuspendBits, guard_count: i32, local: i32) -> SuspendBits:
    let origins = suspend_prov_origins_empty(guard_count)
    for gi in 0..guard_count:
        if suspend_prov_get_local_origin(bits, guard_count, local, gi) != 0:
            origins.vset(gi, 1)
    origins

fn suspend_prov_or_origins(dst: SuspendBits, src: SuspendBits, guard_count: i32):
    for gi in 0..guard_count:
        if gi < src.vlen() as i32 and src.vget(gi as i64) != 0:
            dst.vset(gi, 1)

fn suspend_prov_origins_from_value_place(bits: SuspendBits, body: &MirBody, guard_count: i32, place_id: i32) -> SuspendBits:
    let root = suspend_place_root_local(body, place_id)
    suspend_prov_copy_origins_from_local(bits, guard_count, root)

fn suspend_prov_origins_from_borrowed_place(bits: SuspendBits, body: &MirBody, guard_locals: &Vec[i32], guard_count: i32, place_id: i32) -> SuspendBits:
    let origins = suspend_prov_origins_from_value_place(bits, body, guard_count, place_id)
    let root = suspend_place_root_local(body, place_id)
    let root_guard_idx = suspend_guard_index(guard_locals, root)
    if root_guard_idx >= 0:
        origins.vset(root_guard_idx, 1)
    origins

fn suspend_prov_origins_from_operand(bits: SuspendBits, body: &MirBody, guard_count: i32, operand_id: i32) -> SuspendBits:
    let origins = suspend_prov_origins_empty(guard_count)
    if operand_id < 0 or operand_id >= body.operand_kinds.len() as i32:
        return origins
    let kind = body.operand_kinds.get(operand_id as i64)
    if kind == OperandKind.OK_COPY or kind == OperandKind.OK_MOVE:
        return suspend_prov_origins_from_value_place(bits, body, guard_count, body.operand_d0.get(operand_id as i64))
    origins

fn suspend_prov_origins_from_rvalue(bits: SuspendBits, body: &MirBody, guard_locals: &Vec[i32], guard_count: i32, rval_id: i32) -> SuspendBits:
    let origins = suspend_prov_origins_empty(guard_count)
    if rval_id < 0 or rval_id >= body.rval_kinds.len() as i32:
        return origins
    let kind = body.rval_kinds.get(rval_id as i64)
    let d0 = body.rval_d0.get(rval_id as i64)
    let d1 = body.rval_d1.get(rval_id as i64)

    if kind == RvalueKind.RK_REF:
        return suspend_prov_origins_from_borrowed_place(bits, body, guard_locals, guard_count, d1)
    if kind == RvalueKind.RK_ADDR_OF:
        return suspend_prov_origins_from_borrowed_place(bits, body, guard_locals, guard_count, d0)
    if kind == RvalueKind.RK_USE:
        return suspend_prov_origins_from_operand(bits, body, guard_count, d0)
    if kind == RvalueKind.RK_CAST:
        return suspend_prov_origins_from_operand(bits, body, guard_count, d0)
    origins

fn suspend_sig_for_callee(sema: &Sema, body: &MirBody, callee_operand: i32) -> i32:
    let fn_sym = suspend_callee_sym(body, callee_operand)
    if fn_sym == 0:
        return -1
    let direct = sema.get_sig(fn_sym)
    if direct >= 0:
        return direct
    let sema_sym = sema.pool_lookup_symbol(sema.pool_resolve(fn_sym))
    if sema_sym != 0:
        return sema.get_sig(sema_sym)
    -1

fn suspend_prov_origins_from_call(bits: SuspendBits, sema: &Sema, body: &MirBody, guard_locals: &Vec[i32], guard_count: i32, callee_operand: i32, call_id: i32) -> SuspendBits:
    let origins = suspend_prov_origins_empty(guard_count)
    if call_id < 0 or call_id >= body.call_arg_starts.len() as i32:
        return origins

    let sig_idx = suspend_sig_for_callee(sema, body, callee_operand)
    if sig_idx >= 0:
        let arg_start = body.call_arg_starts.get(call_id as i64)
        let arg_count = body.call_arg_counts.get(call_id as i64)
        let param_count = sema.sig_get_param_count(sig_idx)
        for pi in 0..param_count:
            let origin_mask = sema.sig_param_view_origin(sig_idx, pi)
            if origin_mask == 0:
                continue
            for origin_pi in 0..param_count:
                if (origin_mask & (((1 as i64) << (origin_pi as u32)) as i32)) == 0:
                    continue
                if origin_pi < 0 or origin_pi >= arg_count:
                    continue
                let arg_operand = body.call_arg_operands.get((arg_start + origin_pi) as i64)
                suspend_prov_or_origins(origins, suspend_prov_origins_from_operand(bits, body, guard_count, arg_operand), guard_count)

    let call_node = body.call_ast_node(call_id)
    if call_node == 0:
        return origins
    let dep_count = sema.expr_view_dep_count(call_node)
    for di in 0..dep_count:
        let dep_sym = sema.expr_view_dep_at(call_node, di)
        let guard_idx = suspend_guard_index_for_sym(body, guard_locals, dep_sym)
        if guard_idx >= 0:
            origins.vset(guard_idx, 1)
    origins

fn suspend_prov_transfer_stmt(bits: SuspendBits, sema: &Sema, body: &MirBody, guard_locals: &Vec[i32], guard_count: i32, stmt_id: i32):
    let kind = body.stmt_kind(stmt_id)
    let d0 = body.stmt_data0(stmt_id)
    let d1 = body.stmt_data1(stmt_id)
    let local_count = body.local_count()

    if kind == StmtKind.Assign:
        let dest_local = suspend_direct_place_local(body, d0)
        let origins = suspend_prov_origins_from_rvalue(bits, body, guard_locals, guard_count, d1)
        suspend_prov_clear_local(bits, local_count, guard_count, dest_local)
        suspend_prov_set_local_origins(bits, local_count, guard_count, dest_local, origins)
        return
    if kind == StmtKind.StorageLive or kind == StmtKind.StorageDead:
        suspend_prov_clear_local(bits, local_count, guard_count, d0)
        return
    if kind == StmtKind.Drop:
        suspend_prov_clear_local(bits, local_count, guard_count, suspend_direct_place_local(body, d0))

fn suspend_prov_transfer_term(bits: SuspendBits, sema: &Sema, body: &MirBody, guard_locals: &Vec[i32], guard_count: i32, bb: i32):
    let kind = body.term_kind(bb)
    let d0 = body.term_data0(bb)
    let d1 = body.term_data1(bb)
    let d2 = body.term_data2(bb)
    let local_count = body.local_count()

    if kind == TermKind.TK_CALL:
        let dest_local = suspend_direct_place_local(body, d2)
        if suspend_local_is_ref_like(sema, body, dest_local) == 0:
            suspend_prov_clear_local(bits, local_count, guard_count, dest_local)
            return
        let origins = suspend_prov_origins_from_call(bits, sema, body, guard_locals, guard_count, d0, d1)
        suspend_prov_clear_local(bits, local_count, guard_count, dest_local)
        suspend_prov_set_local_origins(bits, local_count, guard_count, dest_local, origins)
        return
    if kind == TermKind.TK_DROP_AND_GOTO:
        suspend_prov_clear_local(bits, local_count, guard_count, suspend_direct_place_local(body, d0))

fn suspend_prov_transfer_stmts(bits: SuspendBits, sema: &Sema, body: &MirBody, guard_locals: &Vec[i32], guard_count: i32, bb: i32):
    let stmt_start = body.bb_stmt_starts.get(bb as i64)
    let stmt_count = body.bb_stmt_counts.get(bb as i64)
    for si in 0..stmt_count:
        suspend_prov_transfer_stmt(bits, sema, body, guard_locals, guard_count, stmt_start + si)

fn suspend_prov_or_block_into(dst: SuspendBits, local_count: i32, guard_count: i32, target_bb: i32, src: SuspendBits) -> i32:
    if target_bb < 0:
        return 0
    var changed = 0
    for li in 0..local_count:
        for gi in 0..guard_count:
            if src.vget(suspend_prov_local_index(guard_count, li, gi) as i64) == 0:
                continue
            let idx = suspend_prov_index(local_count, guard_count, target_bb, li, gi)
            if idx < 0 or idx >= dst.vlen() as i32:
                continue
            if dst.vget(idx as i64) == 0:
                dst.vset(idx, 1)
                changed = 1
    changed

fn suspend_prov_add_successor(body: &MirBody, prov_in: SuspendBits, local_count: i32, guard_count: i32, target_bb: i32, out_bits: SuspendBits) -> i32:
    if target_bb < 0 or target_bb >= body.block_count():
        return 0
    suspend_prov_or_block_into(prov_in, local_count, guard_count, target_bb, out_bits)

fn suspend_prov_add_successors(body: &MirBody, prov_in: SuspendBits, local_count: i32, guard_count: i32, bb: i32, out_bits: SuspendBits) -> i32:
    let kind = body.term_kind(bb)
    let d0 = body.term_data0(bb)
    let d1 = body.term_data1(bb)
    let d2 = body.term_data2(bb)
    let d3 = body.term_data3(bb)
    var changed = 0

    if kind == TermKind.TK_GOTO:
        if suspend_prov_add_successor(body, prov_in, local_count, guard_count, d0, out_bits) != 0:
            changed = 1
    else if kind == TermKind.TK_CALL:
        if suspend_prov_add_successor(body, prov_in, local_count, guard_count, d3, out_bits) != 0:
            changed = 1
    else if kind == TermKind.TK_DROP_AND_GOTO:
        if suspend_prov_add_successor(body, prov_in, local_count, guard_count, d1, out_bits) != 0:
            changed = 1
    else if kind == TermKind.TK_SWITCH_INT:
        if d1 >= 0 and d1 < body.switch_table_starts.len() as i32:
            let start = body.switch_table_starts.get(d1 as i64)
            let count = body.switch_table_counts.get(d1 as i64)
            for ti in 0..count:
                if suspend_prov_add_successor(body, prov_in, local_count, guard_count, body.switch_table_targets.get((start + ti) as i64), out_bits) != 0:
                    changed = 1
        if suspend_prov_add_successor(body, prov_in, local_count, guard_count, d2, out_bits) != 0:
            changed = 1
    changed

fn suspend_compute_prov_in_for_body(sema: &Sema, body: &MirBody, guard_locals: &Vec[i32]) -> SuspendBits:
    let local_count = body.local_count()
    let bb_count = body.block_count()
    let guard_count = guard_locals.len() as i32
    let prov_in = suspend_bits_fill(local_count * guard_count * bb_count, 0)
    if local_count <= 0 or bb_count <= 0 or guard_count <= 0:
        return prov_in

    var changed = 1
    while changed != 0:
        changed = 0
        for bb in 0..bb_count:
            let out_bits = suspend_prov_copy_block_bits(prov_in, local_count, guard_count, bb)
            suspend_prov_transfer_stmts(out_bits, sema, body, guard_locals, guard_count, bb)
            suspend_prov_transfer_term(out_bits, sema, body, guard_locals, guard_count, bb)
            if suspend_prov_add_successors(body, prov_in, local_count, guard_count, bb, out_bits) != 0:
                changed = 1
    prov_in

fn suspend_prov_before_term_for_block(prov_in: SuspendBits, sema: &Sema, body: &MirBody, guard_locals: &Vec[i32], local_count: i32, guard_count: i32, bb: i32) -> SuspendBits:
    let bits = suspend_prov_copy_block_bits(prov_in, local_count, guard_count, bb)
    suspend_prov_transfer_stmts(bits, sema, body, guard_locals, guard_count, bb)
    bits

type SuspendSiteSpan {
    start: i32,
    end: i32,
}
impl Copy for SuspendSiteSpan

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

fn suspend_reported_site(reported_starts: &Vec[i32], reported_ends: &Vec[i32], reported_locals: &Vec[i32], reported_origins: &Vec[i32], site: SuspendSiteSpan, live_local: i32, origin_local: i32) -> bool:
    let count = reported_starts.len() as i32
    for i in 0..count:
        if reported_starts.get(i as i64) == site.start and reported_ends.get(i as i64) == site.end and reported_locals.get(i as i64) == live_local and reported_origins.get(i as i64) == origin_local:
            return true
    false

fn suspend_no_suspend_site_span(ast: AstPool, body: &MirBody, bb: i32, no_suspend_node: i32) -> SuspendSiteSpan:
    var site = suspend_site_span(ast, body, bb)
    if site.start <= 0 and no_suspend_node != 0:
        site.start = ast.get_start(no_suspend_node)
        site.end = ast.get_end(no_suspend_node)
        if site.end <= site.start:
            site.end = site.start + 1
    site

fn suspend_reported_no_suspend_site(reported_starts: &Vec[i32], reported_ends: &Vec[i32], reported_nodes: &Vec[i32], site: SuspendSiteSpan, no_suspend_node: i32) -> bool:
    let count = reported_starts.len() as i32
    for i in 0..count:
        if reported_starts.get(i as i64) == site.start and reported_ends.get(i as i64) == site.end and reported_nodes.get(i as i64) == no_suspend_node:
            return true
    false

fn suspend_emit_no_suspend_error(diags: DiagnosticList, sema: &Sema, body: &MirBody, body_by_fn: HashMap[i32, i32], body_may_suspend: SuspendBits, site: SuspendSiteSpan, bb: i32) -> DiagnosticList:
    var out = diags
    var diag = Diagnostic.err("E0702: suspension is not allowed inside no_suspend block", Span { file: sema.local_file_id, start: site.start, end: site.end })
    let call_id = body.term_data1(bb)
    let intrinsic = body.call_intrinsic(call_id)
    if suspend_is_scheduler_yield_intrinsic(intrinsic) != 0:
        if intrinsic == MirIntrinsic.FIBER_CLEANUP_AWAIT:
            diag.add_note("implicit cleanup of an ephemeral Task may yield here")
        else:
            diag.add_note("this operation may yield the current fiber")
    else:
        let callee = suspend_callee_sym(body, body.term_data0(bb))
        let callee_idx = suspend_body_index_for_sym(body_by_fn, callee)
        if callee != 0 and callee_idx >= 0 and callee_idx < body_may_suspend.vlen() as i32 and body_may_suspend.vget(callee_idx as i64) != 0:
            diag.add_note("call to may_suspend function `" ++ sema.pool_resolve(callee) ++ "` occurs here")
        else:
            diag.add_note("this call may yield the current fiber")
    diag.add_help("move the suspension outside the no_suspend block, or remove the no_suspend assertion")
    out.emit(diag)
    out

fn suspend_emit_guard_error(diags: DiagnosticList, sema: &Sema, body: &MirBody, site: SuspendSiteSpan, guard_local: i32) -> DiagnosticList:
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

fn suspend_emit_derived_guard_error(diags: DiagnosticList, sema: &Sema, body: &MirBody, site: SuspendSiteSpan, view_local: i32, guard_local: i32) -> DiagnosticList:
    var out = diags
    let guard_ty = if guard_local >= 0 and guard_local < body.local_type_ids.len() as i32: body.local_type_ids.get(guard_local as i64) else: 0
    let guard_name_sym = if guard_local >= 0 and guard_local < body.local_names.len() as i32: body.local_names.get(guard_local as i64) else: 0
    let view_name_sym = if view_local >= 0 and view_local < body.local_names.len() as i32: body.local_names.get(view_local as i64) else: 0
    let guard_name = if guard_name_sym != 0: sema.pool_resolve(guard_name_sym) else: "guard"
    let view_name = if view_name_sym != 0: sema.pool_resolve(view_name_sym) else: "derived view"
    let guard_type_name = sema.type_name(guard_ty)
    var diag = Diagnostic.err("E0701: view derived from " ++ guard_type_name ++ " value is live across a suspension point", Span { file: sema.local_file_id, start: site.start, end: site.end })
    if view_name.len() > 0:
        diag.add_note("`" ++ view_name ++ "` keeps access to guarded state here")
    if guard_name.len() > 0:
        diag.add_note("`" ++ guard_name ++ "` is the no_await_guard origin")
    diag.add_help("move, copy, or clone the needed data before awaiting, or drop the derived view before the suspension point")
    out.emit(diag)
    out

fn suspend_check_body(ast: AstPool, sema: &Sema, body_by_fn: HashMap[i32, i32], body_may_suspend: SuspendBits, body: &MirBody, diags: DiagnosticList) -> DiagnosticList:
    var out = diags
    let local_count = body.local_count()
    let bb_count = body.block_count()
    if local_count <= 0 or bb_count <= 0:
        return out
    let guard_locals = suspend_collect_guard_locals(sema, body)
    let guard_count = guard_locals.len() as i32
    if guard_count == 0:
        return out
    if suspend_body_has_may_suspend_term(body, body_by_fn, body_may_suspend) == 0:
        return out

    let bit_count = local_count * bb_count
    let live_in = suspend_bits_fill(bit_count, 0)
    let live_out = suspend_bits_fill(bit_count, 0)
    let prov_in = suspend_compute_prov_in_for_body(sema, body, guard_locals)
    let reported_starts: Vec[i32] = Vec.new()
    let reported_ends: Vec[i32] = Vec.new()
    let reported_locals: Vec[i32] = Vec.new()
    let reported_origins: Vec[i32] = Vec.new()

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
        let prov_bits = suspend_prov_before_term_for_block(prov_in, sema, body, guard_locals, local_count, guard_count, bb)
        var reported_direct = 0
        for li in 0..local_count:
            if suspend_get_bit(bits, li) == 0:
                continue
            let local_ty = body.local_type_ids.get(li as i64)
            if suspend_type_is_no_await_guard(sema, local_ty) != 0:
                let site = suspend_site_span(ast, body, bb)
                if not suspend_reported_site(&reported_starts, &reported_ends, &reported_locals, &reported_origins, site, li, li):
                    reported_starts.push(site.start)
                    reported_ends.push(site.end)
                    reported_locals.push(li)
                    reported_origins.push(li)
                    out = suspend_emit_guard_error(out, sema, body, site, li)
                reported_direct = 1
                break
        if reported_direct != 0:
            continue
        var reported_derived = 0
        for vi in 0..local_count:
            if reported_derived != 0:
                break
            if suspend_get_bit(bits, vi) == 0:
                continue
            let view_ty = body.local_type_ids.get(vi as i64)
            if suspend_type_is_no_await_guard(sema, view_ty) != 0:
                continue
            for gi in 0..guard_count:
                if suspend_prov_get_local_origin(prov_bits, guard_count, vi, gi) == 0:
                    continue
                let guard_local = guard_locals.get(gi as i64)
                let site2 = suspend_site_span(ast, body, bb)
                if not suspend_reported_site(&reported_starts, &reported_ends, &reported_locals, &reported_origins, site2, vi, guard_local):
                    reported_starts.push(site2.start)
                    reported_ends.push(site2.end)
                    reported_locals.push(vi)
                    reported_origins.push(guard_local)
                    out = suspend_emit_derived_guard_error(out, sema, body, site2, vi, guard_local)
                reported_derived = 1
                break
    out

fn suspend_check_no_suspend_body(ast: AstPool, sema: &Sema, body_by_fn: HashMap[i32, i32], body_may_suspend: SuspendBits, body: &MirBody, diags: DiagnosticList) -> DiagnosticList:
    var out = diags
    let reported_starts: Vec[i32] = Vec.new()
    let reported_ends: Vec[i32] = Vec.new()
    let reported_nodes: Vec[i32] = Vec.new()
    for bb in 0..body.block_count():
        let no_suspend_node = body.term_no_suspend_node(bb)
        if no_suspend_node == 0:
            continue
        if suspend_term_may_suspend(body, body_by_fn, body_may_suspend, bb) == 0:
            continue
        let site = suspend_no_suspend_site_span(ast, body, bb, no_suspend_node)
        if suspend_reported_no_suspend_site(&reported_starts, &reported_ends, &reported_nodes, site, no_suspend_node):
            continue
        reported_starts.push(site.start)
        reported_ends.push(site.end)
        reported_nodes.push(no_suspend_node)
        out = suspend_emit_no_suspend_error(out, sema, body, body_by_fn, body_may_suspend, site, bb)
    out

fn check_no_await_guard_suspends(mir_mod: MirModule, ast: AstPool, sema: &Sema, diags: DiagnosticList) -> DiagnosticList:
    var out = diags
    let body_by_fn = suspend_build_body_index(mir_mod)
    let body_may_suspend = suspend_compute_may_suspend(mir_mod, body_by_fn)
    for bi in 0..mir_mod.bodies.len() as i32:
        let body = mir_mod.bodies.get(bi as i64)
        out = suspend_check_no_suspend_body(ast, sema, body_by_fn, body_may_suspend, &body, out)
        out = suspend_check_body(ast, sema, body_by_fn, body_may_suspend, &body, out)
    out
