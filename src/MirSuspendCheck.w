use Ast
use Diagnostic
use Mir
use Sema
use Span
use std.collections.HashMap
use MirCore
use SemaTypes
extern fn with_getenv_str(name: &str) -> str
extern fn with_eprint(s: &str)

fn suspend_bit_index(local_count: i32, bb: i32, local: i32) -> i32:
    bb * local_count + local

fn suspend_list_fill(count: i32, value: i32) -> List[i32]:
    let out: List[i32] = List.new()
    for _ in 0..count:
        out.push(value)
    out

// Dataflow bit-vector handle: copies share state by design (AstPool
// pattern, truthfully Copy) so the transfer kernels can mutate vectors
// passed through plain parameters under spec §3.8.
type SuspendBitsState {
    w: List[i32],
}

type SuspendBits {
    state: *mut SuspendBitsState,
}
impl Copy for SuspendBits

extern fn with_str_clone_ref(s: &str) -> str
extern fn with_alloc(size: i64) -> *mut u8

impl SuspendBits:
    fn vget(idx: i64) -> i32:
        let st = self.state
        unsafe { st.w[idx] }

    fn vset(idx: i32, value: i32):
        let st = self.state
        unsafe { st.w[idx] = value }

    fn vlen() -> i64:
        let st = self.state
        unsafe { st.w.len() }

    fn vpush(value: i32):
        let st = self.state
        unsafe { st.w.push(value) }

fn suspend_bits_fill(count: i32, value: i32) -> SuspendBits:
    // List header is larger than a pointer; allocate generously like the
    // other handle states (InternPool uses 256 for a 7-field state).
    let ptr = with_alloc(64) as *mut SuspendBitsState
    unsafe *ptr = SuspendBitsState { w: suspend_list_fill(count, value) }
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
    var changed: i32 = 0
    for li in 0..local_count:
        let idx = suspend_bit_index(local_count, bb, li)
        let old = dst.vget(idx as i64)
        let next = src.vget(li as i64)
        if old != next:
            dst.vset(idx, next)
            changed = 1
    changed

fn suspend_place_root_local(body: &MirBody, place_id: i32) -> i32:
    if place_id < 0 or place_id >= body.place_locals.len():
        return -1
    body.place_locals[place_id]

fn suspend_direct_place_local(body: &MirBody, place_id: i32) -> i32:
    if place_id < 0 or place_id >= body.place_locals.len():
        return -1
    if body.place_proj_counts[place_id] != 0:
        return -1
    body.place_locals[place_id]

fn suspend_gen_place(bits: SuspendBits, body: &MirBody, place_id: i32):
    suspend_set_bit(bits, suspend_place_root_local(body, place_id), 1)

fn suspend_kill_place(bits: SuspendBits, body: &MirBody, place_id: i32):
    suspend_set_bit(bits, suspend_place_root_local(body, place_id), 0)

fn suspend_gen_operand(bits: SuspendBits, body: &MirBody, operand_id: i32):
    if operand_id < 0 or operand_id >= body.operand_kinds.len():
        return
    let kind = body.operand_kinds[operand_id]
    if kind == OperandKind.OK_COPY or kind == OperandKind.OK_MOVE:
        suspend_gen_place(bits, body, body.operand_d0[operand_id])

fn suspend_gen_call_args(bits: SuspendBits, body: &MirBody, call_id: i32):
    if call_id < 0 or call_id >= body.call_arg_starts.len():
        return
    let start = body.call_arg_starts[call_id]
    let count = body.call_arg_counts[call_id]
    for ai in 0..count:
        suspend_gen_operand(bits, body, body.call_arg_operands[(start + ai)])

fn suspend_gen_agg_fields(bits: SuspendBits, body: &MirBody, field_id: i32):
    if field_id < 0 or field_id >= body.agg_field_starts.len():
        return
    let start = body.agg_field_starts[field_id]
    let count = body.agg_field_counts[field_id]
    for fi in 0..count:
        suspend_gen_operand(bits, body, body.agg_field_operands[(start + fi)])

fn suspend_gen_rvalue(bits: SuspendBits, body: &MirBody, rval_id: i32):
    if rval_id < 0 or rval_id >= body.rval_kinds.len():
        return
    let kind = body.rval_kinds[rval_id]
    let d0 = body.rval_d0[rval_id]
    let d1 = body.rval_d1[rval_id]
    let d2 = body.rval_d2[rval_id]

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
    if local < 0 or local >= body.local_type_ids.len():
        return 0
    suspend_type_has_semantic_drop(sema, body.local_type_ids[local])

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

    let stmt_start = body.bb_stmt_starts[bb]
    let stmt_count = body.bb_stmt_counts[bb]
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
        if d1 >= 0 and d1 < body.switch_table_starts.len():
            let start = body.switch_table_starts[d1]
            let count = body.switch_table_counts[d1]
            for ti in 0..count:
                suspend_add_successor_live(body, live_in, local_count, body.switch_table_targets[(start + ti)], out_bits)
        suspend_add_successor_live(body, live_in, local_count, d2, out_bits)
    out_bits

fn suspend_is_scheduler_yield_intrinsic(intrinsic: MirIntrinsic) -> i32:
    // Closed current-fiber suspension set. Update this helper whenever a
    // runtime intrinsic can park/yield the caller instead of returning a Task.
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
    if intrinsic == MirIntrinsic.CHAN_SEND:
        return 1
    if intrinsic == MirIntrinsic.CHAN_RECV:
        return 1
    0

fn suspend_callee_sym(body: &MirBody, operand_id: i32) -> i32:
    if operand_id < 0 or operand_id >= body.operand_kinds.len():
        return 0
    if body.operand_kinds[operand_id] != OperandKind.OK_CONSTANT:
        return 0
    let const_id = body.operand_d0[operand_id]
    if const_id < 0 or const_id >= body.const_kinds.len():
        return 0
    if body.const_kinds[const_id] != ConstKind.CK_FN:
        return 0
    body.const_d0[const_id]

fn suspend_term_directly_yields(body: &MirBody, bb: i32) -> i32:
    if body.term_kind(bb) != TermKind.TK_CALL:
        return 0
    let call_id = body.term_data1(bb)
    suspend_is_scheduler_yield_intrinsic(body.call_intrinsic(call_id))

fn suspend_build_body_index(mir_mod: &MirModule) -> HashMap[i32, i32]:
    let body_by_fn: HashMap[i32, i32] = HashMap.new()
    for bi in 0..mir_mod.bodies.len():
        let body = &mir_mod.bodies[bi]
        if body.fn_sym != 0:
            body_by_fn.insert(body.fn_sym, bi as i32)
    body_by_fn

fn suspend_body_index_for_sym(body_by_fn: &HashMap[i32, i32], fn_sym: i32) -> i32:
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

// The closure body a call argument hands over, when the argument is the
// local a closure constant was assigned to; -1 otherwise.
fn suspend_closure_arg_body(body: &MirBody, body_by_fn: &HashMap[i32, i32], operand_id: i32) -> i32:
    if operand_id < 0 or operand_id >= body.operand_kinds.len():
        return -1
    let ok = body.operand_kinds[operand_id]
    if ok != OperandKind.OK_MOVE and ok != OperandKind.OK_COPY:
        return -1
    let place = body.operand_d0[operand_id]
    if place < 0 or place >= body.place_locals.len() or body.place_proj_counts[place] != 0:
        return -1
    let local = body.place_locals[place]
    for si in 0..body.stmt_kinds.len():
        if body.stmt_kinds[si] != StmtKind.Assign:
            continue
        let dst = body.stmt_d0[si]
        if dst < 0 or dst >= body.place_locals.len() or body.place_locals[dst] != local or body.place_proj_counts[dst] != 0:
            continue
        let rv = body.stmt_d1[si]
        if rv < 0 or rv >= body.rval_kinds.len() or body.rval_kinds[rv] != RvalueKind.RK_USE:
            continue
        let src_op = body.rval_d0[rv]
        if src_op < 0 or src_op >= body.operand_kinds.len() or body.operand_kinds[src_op] != OperandKind.OK_CONSTANT:
            continue
        let const_id = body.operand_d0[src_op]
        if const_id >= 0 and const_id < body.const_kinds.len() and body.const_kinds[const_id] == ConstKind.CK_CLOSURE:
            return suspend_body_index_for_sym(body_by_fn, body.const_d1[const_id])
    -1

// §12.3 / D69: a closure handed straight to a call — a `for` body over a
// Gen[T] among them — runs inside that call, so the call suspends when the
// closure's body may.
fn suspend_call_passes_suspending_closure(body: &MirBody, body_by_fn: &HashMap[i32, i32], body_may_suspend: SuspendBits, bb: i32) -> i32:
    let call_id = body.term_data1(bb)
    if call_id < 0 or call_id >= body.call_arg_starts.len():
        return 0
    let start = body.call_arg_starts[call_id]
    for ai in 0..body.call_arg_counts[call_id]:
        let closure_idx = suspend_closure_arg_body(body, body_by_fn, body.call_arg_operands[(start + ai)])
        if closure_idx >= 0 and closure_idx < body_may_suspend.vlen() as i32 and body_may_suspend.vget(closure_idx as i64) != 0:
            return 1
    0

fn suspend_body_calls_may_suspend(body: &MirBody, body_by_fn: &HashMap[i32, i32], body_may_suspend: SuspendBits) -> i32:
    for bb in 0..body.block_count():
        if body.term_kind(bb) != TermKind.TK_CALL:
            continue
        if suspend_call_passes_suspending_closure(body, body_by_fn, body_may_suspend, bb) != 0:
            return 1
        let callee = suspend_callee_sym(body, body.term_data0(bb))
        let callee_idx = suspend_body_index_for_sym(body_by_fn, callee)
        if callee_idx < 0 or callee_idx >= body_may_suspend.vlen() as i32:
            continue
        if body_may_suspend.vget(callee_idx as i64) != 0:
            return 1
    0

fn suspend_compute_may_suspend(mir_mod: &MirModule, body_by_fn: &HashMap[i32, i32]) -> SuspendBits:
    let body_count = mir_mod.bodies.len() as i32
    let body_may_suspend = suspend_bits_fill(body_count, 0)
    for bi in 0..body_count:
        let body = &mir_mod.bodies[bi]
        if suspend_body_has_direct_yield(body) != 0:
            body_may_suspend.vset(bi as i32, 1)

    var changed = 1
    while changed != 0:
        changed = 0
        for bi2 in 0..body_count:
            if body_may_suspend.vget(bi2 as i64) != 0:
                continue
            let body = &mir_mod.bodies[bi2]
            if suspend_body_calls_may_suspend(body, body_by_fn, body_may_suspend) != 0:
                body_may_suspend.vset(bi2 as i32, 1)
                changed = 1
    body_may_suspend

fn suspend_term_may_suspend(body: &MirBody, body_by_fn: &HashMap[i32, i32], body_may_suspend: SuspendBits, bb: i32) -> i32:
    if body.term_kind(bb) != TermKind.TK_CALL:
        return 0
    if suspend_term_directly_yields(body, bb) != 0:
        return 1
    if suspend_call_passes_suspending_closure(body, body_by_fn, body_may_suspend, bb) != 0:
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
    if local < 0 or local >= body.local_type_ids.len():
        return 0
    suspend_type_is_ref_like(sema, body.local_type_ids[local])

fn suspend_body_has_guard_local(sema: &Sema, body: &MirBody) -> i32:
    for li in 0..body.local_count():
        let local_ty = body.local_type_ids[li]
        if suspend_type_is_no_await_guard(sema, local_ty) != 0:
            return 1
    0

fn suspend_body_has_may_suspend_term(body: &MirBody, body_by_fn: &HashMap[i32, i32], body_may_suspend: SuspendBits) -> i32:
    for bb in 0..body.block_count():
        if suspend_term_may_suspend(body, body_by_fn, body_may_suspend, bb) != 0:
            return 1
    0

fn suspend_collect_guard_locals(sema: &Sema, body: &MirBody) -> List[i32]:
    let out: List[i32] = List.new()
    for li in 0..body.local_count():
        let local_ty = body.local_type_ids[li]
        if suspend_type_is_no_await_guard(sema, local_ty) != 0:
            out.push(li)
    out

fn suspend_guard_index(guard_locals: &List[i32], guard_local: i32) -> i32:
    for gi in 0..guard_locals.len():
        if guard_locals[gi] == guard_local:
            return gi as i32
    -1

fn suspend_guard_index_for_sym(body: &MirBody, guard_locals: &List[i32], sym: i32) -> i32:
    if sym == 0:
        return -1
    for gi in 0..guard_locals.len():
        let local = guard_locals[gi]
        if local >= 0 and local < body.local_names.len():
            if body.local_names[local] == sym:
                return gi as i32
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

fn suspend_prov_origins_from_borrowed_place(bits: SuspendBits, body: &MirBody, guard_locals: &List[i32], guard_count: i32, place_id: i32) -> SuspendBits:
    let origins = suspend_prov_origins_from_value_place(bits, body, guard_count, place_id)
    let root = suspend_place_root_local(body, place_id)
    let root_guard_idx = suspend_guard_index(guard_locals, root)
    if root_guard_idx >= 0:
        origins.vset(root_guard_idx, 1)
    origins

fn suspend_prov_origins_from_operand(bits: SuspendBits, body: &MirBody, guard_count: i32, operand_id: i32) -> SuspendBits:
    let origins = suspend_prov_origins_empty(guard_count)
    if operand_id < 0 or operand_id >= body.operand_kinds.len():
        return origins
    let kind = body.operand_kinds[operand_id]
    if kind == OperandKind.OK_COPY or kind == OperandKind.OK_MOVE:
        return suspend_prov_origins_from_value_place(bits, body, guard_count, body.operand_d0[operand_id])
    origins

fn suspend_prov_origins_from_rvalue(bits: SuspendBits, body: &MirBody, guard_locals: &List[i32], guard_count: i32, rval_id: i32) -> SuspendBits:
    let origins = suspend_prov_origins_empty(guard_count)
    if rval_id < 0 or rval_id >= body.rval_kinds.len():
        return origins
    let kind = body.rval_kinds[rval_id]
    let d0 = body.rval_d0[rval_id]
    let d1 = body.rval_d1[rval_id]

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

fn suspend_prov_origins_from_call(bits: SuspendBits, sema: &Sema, body: &MirBody, guard_locals: &List[i32], guard_count: i32, callee_operand: i32, call_id: i32) -> SuspendBits:
    let origins = suspend_prov_origins_empty(guard_count)
    if call_id < 0 or call_id >= body.call_arg_starts.len():
        return origins

    let sig_idx = suspend_sig_for_callee(sema, body, callee_operand)
    if sig_idx >= 0:
        let arg_start = body.call_arg_starts[call_id]
        let arg_count = body.call_arg_counts[call_id]
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
                let arg_operand = body.call_arg_operands[(arg_start + origin_pi)]
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

fn suspend_prov_transfer_stmt(bits: SuspendBits, sema: &Sema, body: &MirBody, guard_locals: &List[i32], guard_count: i32, stmt_id: i32):
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

fn suspend_prov_transfer_term(bits: SuspendBits, sema: &Sema, body: &MirBody, guard_locals: &List[i32], guard_count: i32, bb: i32):
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

fn suspend_prov_transfer_stmts(bits: SuspendBits, sema: &Sema, body: &MirBody, guard_locals: &List[i32], guard_count: i32, bb: i32):
    let stmt_start = body.bb_stmt_starts[bb]
    let stmt_count = body.bb_stmt_counts[bb]
    for si in 0..stmt_count:
        suspend_prov_transfer_stmt(bits, sema, body, guard_locals, guard_count, stmt_start + si)

fn suspend_prov_or_block_into(dst: SuspendBits, local_count: i32, guard_count: i32, target_bb: i32, src: SuspendBits) -> i32:
    if target_bb < 0:
        return 0
    var changed: i32 = 0
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
    var changed: i32 = 0

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
        if d1 >= 0 and d1 < body.switch_table_starts.len():
            let start = body.switch_table_starts[d1]
            let count = body.switch_table_counts[d1]
            for ti in 0..count:
                if suspend_prov_add_successor(body, prov_in, local_count, guard_count, body.switch_table_targets[(start + ti)], out_bits) != 0:
                    changed = 1
        if suspend_prov_add_successor(body, prov_in, local_count, guard_count, d2, out_bits) != 0:
            changed = 1
    changed

fn suspend_compute_prov_in_for_body(sema: &Sema, body: &MirBody, guard_locals: &List[i32]) -> SuspendBits:
    let local_count = body.local_count()
    let bb_count = body.block_count()
    let guard_count = guard_locals.len() as i32
    let prov_in = suspend_bits_fill((local_count * guard_count * bb_count) as i32, 0)
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

fn suspend_prov_before_term_for_block(prov_in: SuspendBits, sema: &Sema, body: &MirBody, guard_locals: &List[i32], local_count: i32, guard_count: i32, bb: i32) -> SuspendBits:
    let bits = suspend_prov_copy_block_bits(prov_in, local_count, guard_count, bb)
    suspend_prov_transfer_stmts(bits, sema, body, guard_locals, guard_count, bb)
    bits

type SuspendSiteSpan {
    start: i32,
    end: i32,
}
impl Copy for SuspendSiteSpan

fn suspend_site_span(ast: &AstPool, body: &MirBody, bb: i32) -> SuspendSiteSpan:
    let call_id = body.term_data1(bb)
    let node = body.call_ast_node(call_id)
    var start: i32 = body.bb_term_spans[bb]
    var end = start + 1
    if node != 0:
        start = ast.get_start(node)
        end = ast.get_end(node)
    if end <= start:
        end = start + 1
    SuspendSiteSpan { start, end }

fn suspend_reported_site(reported_starts: &List[i32], reported_ends: &List[i32], reported_locals: &List[i32], reported_origins: &List[i32], site: SuspendSiteSpan, live_local: i32, origin_local: i32) -> bool:
    let count = reported_starts.len()
    for i in 0..count:
        if reported_starts[i] == site.start and reported_ends[i] == site.end and reported_locals[i] == live_local and reported_origins[i] == origin_local:
            return true
    false

fn suspend_no_suspend_site_span(ast: &AstPool, body: &MirBody, bb: i32, no_suspend_node: i32) -> SuspendSiteSpan:
    var site = suspend_site_span(ast, body, bb)
    if site.start <= 0 and no_suspend_node != 0:
        site.start = ast.get_start(no_suspend_node)
        site.end = ast.get_end(no_suspend_node)
        if site.end <= site.start:
            site.end = site.start + 1
    site

fn suspend_reported_no_suspend_site(reported_starts: &List[i32], reported_ends: &List[i32], reported_nodes: &List[i32], site: SuspendSiteSpan, no_suspend_node: i32) -> bool:
    let count = reported_starts.len()
    for i in 0..count:
        if reported_starts[i] == site.start and reported_ends[i] == site.end and reported_nodes[i] == no_suspend_node:
            return true
    false

fn suspend_emit_no_suspend_error(diags: DiagnosticList, sema: &Sema, body: &MirBody, body_by_fn: &HashMap[i32, i32], body_may_suspend: SuspendBits, site: SuspendSiteSpan, bb: i32) -> DiagnosticList:
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
            // D69: the loop over a generator runs the generator's body.
            if sema.generator_mir_only_fns.contains(callee):
                let gen_fn: i32 = sema.generator_mir_only_fns.get(callee).unwrap()
                // A generic gen fn's specialization is named by its declaration.
                var gen_name = sema.pool_resolve(gen_fn)
                if sema.concrete_specialization_by_sym.contains(gen_fn):
                    let spec_idx: i32 = sema.concrete_specialization_by_sym.get(gen_fn).unwrap()
                    gen_name = sema.pool_resolve(sema.ast.get_data0(sema.concrete_specialization_nodes[spec_idx]))
                diag.add_note("generator `" ++ gen_name ++ "` may suspend, and its body runs inside this loop")
            else:
                diag.add_note("call to may_suspend function `" ++ sema.pool_resolve(callee) ++ "` occurs here")
        else if suspend_call_passes_suspending_closure(body, body_by_fn, body_may_suspend, bb) != 0:
            diag.add_note("a closure passed to this call — or this loop's body — may suspend, and runs inside the call")
        else:
            diag.add_note("this call may yield the current fiber")
    diag.add_help("move the suspension outside the no_suspend block, or remove the no_suspend assertion")
    out.emit(move diag)
    out

fn suspend_emit_guard_error(diags: DiagnosticList, sema: &Sema, body: &MirBody, site: SuspendSiteSpan, guard_local: i32) -> DiagnosticList:
    var out = diags
    let guard_ty = if guard_local >= 0 and guard_local < body.local_type_ids.len(): body.local_type_ids[guard_local] else: 0
    let guard_name_sym = if guard_local >= 0 and guard_local < body.local_names.len(): body.local_names[guard_local] else: 0
    let guard_name = if guard_name_sym != 0: with_str_clone_ref(sema.pool_resolve(guard_name_sym)) else: "guard"
    let guard_type_name = sema.type_name(guard_ty)
    var diag = Diagnostic.err("E0701: " ++ guard_type_name ++ " value is live across a suspension point", Span { file: sema.local_file_id, start: site.start, end: site.end })
    if guard_name.len() > 0:
        diag.add_note("`" ++ guard_name ++ "` is still live here")
    diag.add_help("move, copy, or clone the needed data before awaiting, or drop the guard before the suspension point")
    out.emit(move diag)
    out

fn suspend_emit_derived_guard_error(diags: DiagnosticList, sema: &Sema, body: &MirBody, site: SuspendSiteSpan, view_local: i32, guard_local: i32) -> DiagnosticList:
    var out = diags
    let guard_ty = if guard_local >= 0 and guard_local < body.local_type_ids.len(): body.local_type_ids[guard_local] else: 0
    let guard_name_sym = if guard_local >= 0 and guard_local < body.local_names.len(): body.local_names[guard_local] else: 0
    let view_name_sym = if view_local >= 0 and view_local < body.local_names.len(): body.local_names[view_local] else: 0
    let guard_name = if guard_name_sym != 0: with_str_clone_ref(sema.pool_resolve(guard_name_sym)) else: "guard"
    let view_name = if view_name_sym != 0: with_str_clone_ref(sema.pool_resolve(view_name_sym)) else: "derived view"
    let guard_type_name = sema.type_name(guard_ty)
    var diag = Diagnostic.err("E0701: view derived from " ++ guard_type_name ++ " value is live across a suspension point", Span { file: sema.local_file_id, start: site.start, end: site.end })
    if view_name.len() > 0:
        diag.add_note("`" ++ view_name ++ "` keeps access to guarded state here")
    if guard_name.len() > 0:
        diag.add_note("`" ++ guard_name ++ "` is the no_await_guard origin")
    diag.add_help("move, copy, or clone the needed data before awaiting, or drop the derived view before the suspension point")
    out.emit(move diag)
    out

fn suspend_check_body(ast: &AstPool, sema: &Sema, body_by_fn: &HashMap[i32, i32], body_may_suspend: SuspendBits, body: &MirBody, diags: DiagnosticList) -> DiagnosticList:
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

    let liveness = suspend_liveness(sema, body)
    let live_out = liveness.live_out
    let prov_in = suspend_compute_prov_in_for_body(sema, body, guard_locals)
    let reported_starts: List[i32] = List.new()
    let reported_ends: List[i32] = List.new()
    let reported_locals: List[i32] = List.new()
    let reported_origins: List[i32] = List.new()

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
            let local_ty = body.local_type_ids[li]
            if suspend_type_is_no_await_guard(sema, local_ty) != 0:
                let site = suspend_site_span(ast, body, bb)
                if not suspend_reported_site(&reported_starts, &reported_ends, &reported_locals, &reported_origins, site, li, li):
                    reported_starts.push(site.start)
                    reported_ends.push(site.end)
                    reported_locals.push(li)
                    reported_origins.push(li)
                    out = suspend_emit_guard_error(move out, sema, body, site, li)
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
            let view_ty = body.local_type_ids[vi]
            if suspend_type_is_no_await_guard(sema, view_ty) != 0:
                continue
            for gi in 0..guard_count:
                if suspend_prov_get_local_origin(prov_bits, guard_count, vi, gi as i32) == 0:
                    continue
                let guard_local = guard_locals[gi]
                let site2 = suspend_site_span(ast, body, bb)
                if not suspend_reported_site(&reported_starts, &reported_ends, &reported_locals, &reported_origins, site2, vi, guard_local):
                    reported_starts.push(site2.start)
                    reported_ends.push(site2.end)
                    reported_locals.push(vi)
                    reported_origins.push(guard_local)
                    out = suspend_emit_derived_guard_error(move out, sema, body, site2, vi, guard_local)
                reported_derived = 1
                break
    out

fn suspend_check_no_suspend_body(ast: &AstPool, sema: &Sema, body_by_fn: &HashMap[i32, i32], body_may_suspend: SuspendBits, body: &MirBody, diags: DiagnosticList) -> DiagnosticList:
    var out = diags
    let reported_starts: List[i32] = List.new()
    let reported_ends: List[i32] = List.new()
    let reported_nodes: List[i32] = List.new()
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
        out = suspend_emit_no_suspend_error(move out, sema, body, body_by_fn, body_may_suspend, site, bb)
    out

// Backward liveness of a body's locals to a fixed point: live_in holds, per
// block, the locals some later statement on some path reads before the block
// starts; live_out the same at its end. A drop of a value with no user Drop
// is not a read. One analysis for the suspend check below and for MirLower's
// last-use copies (D111).
type SuspendLiveness { live_in: SuspendBits, live_out: SuspendBits }

fn suspend_liveness(sema: &Sema, body: &MirBody) -> SuspendLiveness:
    let local_count = body.local_count()
    let bb_count = body.block_count()
    let live_in = suspend_bits_fill(local_count * bb_count, 0)
    let live_out = suspend_bits_fill(local_count * bb_count, 0)
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
    SuspendLiveness { live_in, live_out }

// The operand ids a statement's rvalue reads — the operands
// suspend_gen_rvalue gens.
fn suspend_rvalue_operands(body: &MirBody, rval_id: i32) -> List[i32]:
    var out: List[i32] = List.new()
    if rval_id < 0 or rval_id >= body.rval_kinds.len():
        return out
    let kind = body.rval_kinds[rval_id]
    let d0 = body.rval_d0[rval_id]
    let d1 = body.rval_d1[rval_id]
    if kind == RvalueKind.RK_USE or kind == RvalueKind.RK_CAST or kind == RvalueKind.RK_ARRAY_FILL:
        out.push(d0)
    else if kind == RvalueKind.RK_BIN_OP:
        out.push(d1)
        out.push(body.rval_d2[rval_id])
    else if kind == RvalueKind.RK_UN_OP:
        out.push(d1)
    else if kind == RvalueKind.RK_AGGREGATE and d1 >= 0 and d1 < body.agg_field_starts.len():
        for fi in 0..body.agg_field_counts[d1]:
            out.push(body.agg_field_operands[body.agg_field_starts[d1] + fi])
    else if kind == RvalueKind.RK_STR_CONCAT_N:
        out = suspend_call_operands(body, d0)
    else if kind == RvalueKind.RK_SLICE:
        out.push(d1)
        out.push(body.rval_d2[rval_id])
    out

fn suspend_call_operands(body: &MirBody, call_id: i32) -> List[i32]:
    var out: List[i32] = List.new()
    if call_id < 0 or call_id >= body.call_arg_starts.len():
        return out
    for ai in 0..body.call_arg_counts[call_id]:
        out.push(body.call_arg_operands[body.call_arg_starts[call_id] + ai])
    out

// The whole local a retained copy operand names, or -1.
fn suspend_held_copy_local(body: &MirBody, operand_id: i32) -> i32:
    if operand_id < 0 or operand_id >= body.operand_kinds.len() or body.operand_kinds[operand_id] != OperandKind.OK_COPY or body.operand_hold(operand_id) != MIR_HOLD_RETAIN:
        return -1
    suspend_direct_place_local(body, body.operand_d0[operand_id])

// What a statement does with `local` first: 1 reads it, 2 overwrites or ends
// it whole, 0 neither. A borrow or a partial write counts as a read, and so
// does a drop when `drops_read` (the D111 last-use pass ends a value there).
fn last_use_stmt_event(body: &MirBody, stmt_id: i32, local: i32, drops_read: bool) -> i32:
    let kind = body.stmt_kind(stmt_id)
    let d0 = body.stmt_data0(stmt_id)
    if kind == StmtKind.Assign:
        let rval = body.stmt_data1(stmt_id)
        let operands = suspend_rvalue_operands(body, rval)
        for oi in 0..operands.len():
            let op = operands[oi]
            if op >= 0 and op < body.operand_kinds.len() and (body.operand_kinds[op] == OperandKind.OK_COPY or body.operand_kinds[op] == OperandKind.OK_MOVE) and suspend_place_root_local(body, body.operand_d0[op]) == local:
                return 1
        if rval >= 0 and rval < body.rval_kinds.len():
            let rk = body.rval_kinds[rval]
            let borrowed = if rk == RvalueKind.RK_REF: body.rval_d1[rval] else: if rk == RvalueKind.RK_ADDR_OF or rk == RvalueKind.RK_DISCRIMINANT or rk == RvalueKind.RK_LEN or rk == RvalueKind.RK_SLICE: body.rval_d0[rval] else: -1
            if suspend_place_root_local(body, borrowed) == local:
                return 1
        if suspend_direct_place_local(body, d0) == local:
            return 2
        if suspend_place_root_local(body, d0) == local:
            return 1
        return 0
    if kind == StmtKind.StorageDead:
        return if d0 == local: 2 else: 0
    if kind == StmtKind.Drop:
        if suspend_direct_place_local(body, d0) == local:
            return if drops_read: 1 else: 2
        if suspend_place_root_local(body, d0) == local:
            return 1
    0

// What a block's terminator does with `local`: 1 reads it, 2 defines it, 0
// neither (a drop reads it when `drops_read`).
fn last_use_term_event(body: &MirBody, bb: i32, local: i32, drops_read: bool) -> i32:
    let kind = body.term_kind(bb)
    if kind == TermKind.TK_CALL:
        let operands = suspend_call_operands(body, body.term_data1(bb))
        operands.push(body.term_data0(bb))
        for oi in 0..operands.len():
            let op = operands[oi]
            if op >= 0 and op < body.operand_kinds.len() and (body.operand_kinds[op] == OperandKind.OK_COPY or body.operand_kinds[op] == OperandKind.OK_MOVE) and suspend_place_root_local(body, body.operand_d0[op]) == local:
                return 1
        if suspend_direct_place_local(body, body.term_data2(bb)) == local:
            return 2
        if suspend_place_root_local(body, body.term_data2(bb)) == local:
            return 1
        return 0
    if kind == TermKind.TK_RETURN:
        return if local == 0: 1 else: 0
    if kind == TermKind.TK_SWITCH_INT:
        let op = body.term_data0(bb)
        if op >= 0 and op < body.operand_kinds.len() and (body.operand_kinds[op] == OperandKind.OK_COPY or body.operand_kinds[op] == OperandKind.OK_MOVE) and suspend_place_root_local(body, body.operand_d0[op]) == local:
            return 1
        return 0
    if kind == TermKind.TK_DROP_AND_GOTO:
        if suspend_direct_place_local(body, body.term_data0(bb)) == local:
            return if drops_read: 1 else: 2
        if suspend_place_root_local(body, body.term_data0(bb)) == local:
            return 1
    0

fn last_use_successors(body: &MirBody, bb: i32) -> List[i32]:
    var out: List[i32] = List.new()
    let kind = body.term_kind(bb)
    if kind == TermKind.TK_GOTO:
        out.push(body.term_data0(bb))
    else if kind == TermKind.TK_CALL:
        out.push(body.term_data3(bb))
    else if kind == TermKind.TK_DROP_AND_GOTO:
        out.push(body.term_data1(bb))
    else if kind == TermKind.TK_SWITCH_INT:
        let table = body.term_data1(bb)
        if table >= 0 and table < body.switch_table_starts.len():
            for ti in 0..body.switch_table_counts[table]:
                out.push(body.switch_table_targets[body.switch_table_starts[table] + ti])
        out.push(body.term_data2(bb))
    out

// For one local: per block, whether it is read on some path from the block's
// start before anything overwrites or ends it (one bit per block, to a fixed
// point).
fn last_use_live_in(body: &MirBody, local: i32, drops_read: bool) -> List[i32]:
    let bb_count = body.block_count()
    var first: List[i32] = List.new()
    for bb in 0..bb_count:
        var event: i32 = 0
        var si: i32 = 0
        while si < body.bb_stmt_counts[bb] and event == 0:
            event = last_use_stmt_event(body, body.bb_stmt_starts[bb] + si, local, drops_read)
            si = si + 1
        if event == 0:
            event = last_use_term_event(body, bb, local, drops_read)
        first.push(event)
    var live: List[i32] = List.new()
    for bb in 0..bb_count: live.push(if first[bb] == 1: 1 else: 0)
    var changed = true
    while changed:
        changed = false
        var bb = bb_count - 1
        while bb >= 0:
            if live[bb] == 0 and first[bb] == 0:
                let succs = last_use_successors(body, bb)
                for si in 0..succs.len():
                    if succs[si] >= 0 and succs[si] < bb_count and live[succs[si]] != 0:
                        live[bb] = 1
                        changed = true
                        break
            bb = bb - 1
    live

// Whether `local` is read after point `stmt_index` of `bb` (the terminator
// when stmt_index is the block's statement count), before anything ends it.
fn last_use_live_after(body: &MirBody, live_in: &List[i32], bb: i32, stmt_index: i32, local: i32, drops_read: bool) -> bool:
    var si = stmt_index + 1
    while si < body.bb_stmt_counts[bb]:
        let event = last_use_stmt_event(body, body.bb_stmt_starts[bb] + si, local, drops_read)
        if event != 0:
            return event == 1
        si = si + 1
    if stmt_index < body.bb_stmt_counts[bb]:
        let term_event = last_use_term_event(body, bb, local, drops_read)
        if term_event != 0:
            return term_event == 1
    let succs = last_use_successors(body, bb)
    for i in 0..succs.len():
        if succs[i] >= 0 and succs[i] < live_in.len() and live_in[succs[i]] != 0:
            return true
    false

fn last_use_type_can_hold_view(sema: &Sema, tid: i32, from_normal_call: bool) -> bool:
    if tid <= 0:
        return false
    let resolved = sema.resolve_alias(tid as TypeId)
    let tk = sema.get_type_kind(resolved)
    if tk == TypeKind.TY_VOID or tk == TypeKind.TY_BOOL or tk == TypeKind.TY_INT or tk == TypeKind.TY_FLOAT:
        return false
    if from_normal_call:
        if tk == TypeKind.TY_STR:
            return false
        let sg = sema.std_generic_of(resolved as i32)
        if sg == StdGeneric.List or sg == StdGeneric.HashMap or sg == StdGeneric.HashSet or sg == StdGeneric.BTreeMap or sg == StdGeneric.BTreeSet:
            return false
    true

// Whether the value an operand copies can carry a view into its source's
// buffer: an integer read out of a list (`out[i] = state[l]`) cannot, so it
// makes no edge (it once did, and the copy of a plain element made the
// destination list a "view" of the source, which kept every later handoff
// of the source a retained copy: the stage 4 dataflow copied its state
// vector at every statement of the compiler, 239,743 times per self-check).
fn last_use_operand_can_carry_view(sema: &Sema, body: &MirBody, op: i32) -> bool:
    let place = body.operand_d0[op]
    if place < 0 or place >= body.place_sema_types.len():
        return true
    last_use_type_can_hold_view(sema, body.place_sema_types[place], false)

// Directed edges `src -> dst` where `dst` may receive an unretained view
// (reference, slice, iterator, or projection) into `src`'s buffer.
fn last_use_build_view_edges(sema: &Sema, body: &MirBody) -> List[List[i32]]:
    let local_count = body.local_count()
    var edges: List[List[i32]] = List.new()
    var ref_target: List[i32] = List.new()
    for _ in 0..local_count:
        edges.push(List.new())
        ref_target.push(-1)
    for bb in 0..body.block_count():
        for si in 0..body.bb_stmt_counts[bb]:
            let stmt_id = body.bb_stmt_starts[bb] + si
            if body.stmt_kind(stmt_id) != StmtKind.Assign:
                continue
            let dst = suspend_place_root_local(body, body.stmt_data0(stmt_id))
            let rval = body.stmt_data1(stmt_id)
            if dst <= 0 or dst >= local_count or rval < 0 or rval >= body.rval_kinds.len():
                continue
            let rk = body.rval_kinds[rval]
            let b = if rk == RvalueKind.RK_REF: body.rval_d1[rval] else: if rk == RvalueKind.RK_ADDR_OF or rk == RvalueKind.RK_SLICE: body.rval_d0[rval] else: -1
            let b_root = suspend_place_root_local(body, b)
            if b_root > 0 and b_root < local_count:
                ref_target[dst] = b_root
    for bb in 0..body.block_count():
        for si in 0..body.bb_stmt_counts[bb]:
            let stmt_id = body.bb_stmt_starts[bb] + si
            if body.stmt_kind(stmt_id) != StmtKind.Assign:
                continue
            let dst = suspend_place_root_local(body, body.stmt_data0(stmt_id))
            let rval = body.stmt_data1(stmt_id)
            if dst <= 0 or dst >= local_count or rval < 0 or rval >= body.rval_kinds.len():
                continue
            if not last_use_type_can_hold_view(sema, body.local_type_ids[dst], false):
                continue
            let rk = body.rval_kinds[rval]
            let b = if rk == RvalueKind.RK_REF: body.rval_d1[rval] else: if rk == RvalueKind.RK_ADDR_OF or rk == RvalueKind.RK_SLICE: body.rval_d0[rval] else: -1
            let b_root = suspend_place_root_local(body, b)
            if b_root > 0 and b_root < local_count and b_root != dst:
                edges[b_root].push(dst)
            else if rk == RvalueKind.RK_USE or rk == RvalueKind.RK_CAST or rk == RvalueKind.RK_AGGREGATE or rk == RvalueKind.RK_ARRAY_FILL:
                let ops = suspend_rvalue_operands(body, rval)
                for oi in 0..ops.len():
                    let op = ops[oi]
                    if op < 0 or op >= body.operand_kinds.len():
                        continue
                    let ok = body.operand_kinds[op]
                    if ok != OperandKind.OK_COPY and ok != OperandKind.OK_MOVE:
                        continue
                    let hold = body.operand_hold(op)
                    if hold != MIR_HOLD_RETAIN and hold != MIR_HOLD_TAKE and last_use_operand_can_carry_view(sema, body, op):
                        let src = suspend_place_root_local(body, body.operand_d0[op])
                        if src > 0 and src < local_count and src != dst:
                            edges[src].push(dst)
        if body.term_kind(bb) == TermKind.TK_CALL:
            let call_id = body.term_data1(bb)
            let from_normal_call = body.call_intrinsic(call_id) == MirIntrinsic.NONE
            let ops = suspend_call_operands(body, call_id)
            ops.push(body.term_data0(bb))
            let dst = suspend_place_root_local(body, body.term_data2(bb))
            let dst_ok = dst > 0 and dst < local_count and last_use_type_can_hold_view(sema, body.local_type_ids[dst], from_normal_call)
            for oi in 0..ops.len():
                let op = ops[oi]
                if op < 0 or op >= body.operand_kinds.len():
                    continue
                let ok = body.operand_kinds[op]
                if ok != OperandKind.OK_COPY and ok != OperandKind.OK_MOVE:
                    continue
                let hold = body.operand_hold(op)
                if hold == MIR_HOLD_RETAIN or hold == MIR_HOLD_TAKE:
                    continue
                if not last_use_operand_can_carry_view(sema, body, op):
                    continue
                let src = suspend_place_root_local(body, body.operand_d0[op])
                if src <= 0 or src >= local_count:
                    continue
                if dst_ok and src != dst:
                    edges[src].push(dst)
                for oj in 0..ops.len():
                    let op2 = ops[oj]
                    if op2 >= 0 and op2 < body.operand_kinds.len() and (body.operand_kinds[op2] == OperandKind.OK_COPY or body.operand_kinds[op2] == OperandKind.OK_MOVE):
                        let arg_root = suspend_place_root_local(body, body.operand_d0[op2])
                        let target = if arg_root > 0 and arg_root < local_count: ref_target[arg_root] else: -1
                        if target > 0 and target < local_count and src != target and last_use_type_can_hold_view(sema, body.local_type_ids[target], from_normal_call):
                            edges[src].push(target)
    edges

fn last_use_reachable_views(edges: &List[List[i32]], local: i32) -> (List[i32], List[i32]):
    let local_count = edges.len()
    var in_views: List[i32] = List.new()
    for _ in 0..local_count:
        in_views.push(0)
    var view_locals: List[i32] = List.new()
    var work: List[i32] = [local]
    while work.len() > 0:
        let u = work.pop().unwrap()
        for i in 0..edges[u].len():
            let v = edges[u][i]
            if v != local and in_views[v] == 0:
                in_views[v] = 1
                view_locals.push(v)
                work.push(v)
    (in_views, view_locals)

fn last_use_site_operands(body: &MirBody, bb: i32, si: i32) -> List[i32]:
    if si < body.bb_stmt_counts[bb]:
        let stmt_id = body.bb_stmt_starts[bb] + si
        return suspend_rvalue_operands(body, body.stmt_data1(stmt_id))
    var ops = suspend_call_operands(body, body.term_data1(bb))
    ops.push(body.term_data0(bb))
    ops

fn last_use_quick_after_verdict(body: &MirBody, bb: i32, stmt_index: i32, local: i32, drops_read: bool) -> i32:
    var cur_bb = bb
    var start_si = stmt_index + 1
    var check_term = stmt_index < body.bb_stmt_counts[bb]
    var steps = 0
    while steps < 8 and cur_bb >= 0 and cur_bb < body.block_count():
        var si = start_si
        while si < body.bb_stmt_counts[cur_bb]:
            let event = last_use_stmt_event(body, body.bb_stmt_starts[cur_bb] + si, local, drops_read)
            if event != 0:
                return event
            si = si + 1
        if check_term:
            let term_event = last_use_term_event(body, cur_bb, local, drops_read)
            if term_event != 0:
                return term_event
        let tk = body.term_kind(cur_bb)
        if tk == TermKind.TK_RETURN or tk == TermKind.TK_UNREACHABLE:
            return 2
        if tk == TermKind.TK_GOTO:
            cur_bb = body.term_data0(cur_bb)
        else if tk == TermKind.TK_CALL:
            cur_bb = body.term_data3(cur_bb)
        else if tk == TermKind.TK_DROP_AND_GOTO:
            cur_bb = body.term_data1(cur_bb)
        else:
            return 0
        start_si = 0
        check_term = true
        steps = steps + 1
    0

// D111 & D120: at a variable's last use a copy is a move. A retained copy of a
// whole local that nothing reads afterwards on any path (a drop is not a
// read) becomes a take: codegen hands the value over and blanks the local,
// so its later drop releases nothing — no retain, no release, and a CoW
// collection buffer stays unique across the handoff. Earlier borrows, field
// projections, or mutations of the local qualify as long as no view derived
// from the local is read at or after the take point.
pub fn mir_mark_last_use_holds(sema: &Sema, body: MirBody) -> MirBody:
    var out = body
    if out.operand_holds.len() == 0:
        return out
    let local_count = out.local_count()
    var held: List[i32] = List.new()
    var may_have_views: List[i32] = List.new()
    for _ in 0..local_count:
        held.push(0)
        may_have_views.push(0)
    var any_held = false
    for oi in 0..out.operand_kinds.len():
        let ok = out.operand_kinds[oi]
        if ok != OperandKind.OK_COPY and ok != OperandKind.OK_MOVE:
            continue
        let place = out.operand_d0[oi]
        let root = suspend_place_root_local(out, place)
        if root <= 0 or root >= local_count:
            continue
        if out.operand_hold(oi as i32) == MIR_HOLD_RETAIN and out.place_proj_counts[place] == 0:
            if out.local_is_global[root] == 0 and out.local_is_caller_place[root] == 0:
                held[root] = 1
                any_held = true
        else:
            may_have_views[root] = 1
    if not any_held:
        return out
    for ri in 0..out.rval_kinds.len():
        let rk = out.rval_kinds[ri]
        let b = if rk == RvalueKind.RK_REF: out.rval_d1[ri] else: if rk == RvalueKind.RK_ADDR_OF or rk == RvalueKind.RK_SLICE: out.rval_d0[ri] else: -1
        let b_root = suspend_place_root_local(out, b)
        if b_root > 0 and b_root < local_count:
            may_have_views[b_root] = 1
    var local_sites: List[List[i32]] = List.new()
    for _ in 0..local_count:
        local_sites.push(List.new())
    var any_site = false
    for bb in 0..out.block_count():
        for si in 0..out.bb_stmt_counts[bb] + 1:
            var dst_root: i32 = -1
            var operands: List[i32] = List.new()
            if si < out.bb_stmt_counts[bb]:
                let stmt_id = out.bb_stmt_starts[bb] + si
                if out.stmt_kind(stmt_id) != StmtKind.Assign:
                    continue
                let rval = out.stmt_data1(stmt_id)
                if rval < 0 or rval >= out.rval_kinds.len():
                    continue
                let rk = out.rval_kinds[rval]
                if rk == RvalueKind.RK_REF or rk == RvalueKind.RK_ADDR_OF or rk == RvalueKind.RK_DISCRIMINANT or rk == RvalueKind.RK_LEN:
                    continue
                dst_root = suspend_place_root_local(out, out.stmt_data0(stmt_id))
                operands = suspend_rvalue_operands(out, rval)
            else if out.term_kind(bb) == TermKind.TK_CALL:
                dst_root = suspend_place_root_local(out, out.term_data2(bb))
                operands = suspend_call_operands(out, out.term_data1(bb))
                operands.push(out.term_data0(bb))
            else:
                continue
            for oi in 0..operands.len():
                let op = operands[oi]
                let local = suspend_held_copy_local(out, op)
                if local <= 0 or local >= local_count or held[local] == 0 or dst_root == local:
                    continue
                var reads = 0
                for oj in 0..operands.len():
                    let op2 = operands[oj]
                    if op2 >= 0 and op2 < out.operand_kinds.len() and (out.operand_kinds[op2] == OperandKind.OK_COPY or out.operand_kinds[op2] == OperandKind.OK_MOVE):
                        if suspend_place_root_local(out, out.operand_d0[op2]) == local:
                            reads = reads + 1
                if reads == 1:
                    local_sites[local].push(bb)
                    local_sites[local].push(si)
                    local_sites[local].push(op)
                    any_site = true
    if not any_site:
        return out
    let trace = with_getenv_str("WITH_TRACE_COW").len() > 0
    var live_in_cache: List[List[i32]] = List.new()
    for _ in 0..local_count:
        live_in_cache.push(List.new())
    var view_edges_built = false
    var view_edges: List[List[i32]] = List.new()
    for local in 1..local_count:
        let sites = &local_sites[local]
        if sites.len() == 0:
            continue
        var views_computed = false
        var in_views: List[i32] = List.new()
        var view_locals: List[i32] = List.new()
        var idx = 0
        while idx < sites.len():
            let bb = sites[idx]
            let si = sites[idx + 1]
            let held_op = sites[idx + 2]
            idx = idx + 3
            let q = last_use_quick_after_verdict(out, bb, si, local, false)
            if q == 1:
                if trace: with_eprint(f"[cow-last-use] fn_sym={out.fn_sym} _{local} at bb{bb}:{si}: kept, read soon after")
                continue
            if q == 0:
                if live_in_cache[local].len() == 0:
                    live_in_cache[local] = last_use_live_in(out, local, false)
                if last_use_live_after(out, live_in_cache[local], bb, si, local, false):
                    if trace: with_eprint(f"[cow-last-use] fn_sym={out.fn_sym} _{local} at bb{bb}:{si}: kept, live after")
                    continue
            if may_have_views[local] == 0:
                if trace: with_eprint(f"[cow-last-use] fn_sym={out.fn_sym} _{local} at bb{bb}:{si}: taken")
                out.set_operand_hold(held_op, MIR_HOLD_TAKE)
                out.mark_local_ever_moved(local)
                continue
            if not view_edges_built:
                view_edges = last_use_build_view_edges(sema, out)
                view_edges_built = true
            if not views_computed:
                let (iv, vl) = last_use_reachable_views(view_edges, local)
                in_views = iv
                view_locals = vl
                views_computed = true
            var any_view_live = false
            if view_locals.len() > 0:
                let operands = last_use_site_operands(out, bb, si)
                for oi in 0..operands.len():
                    let op = operands[oi]
                    if op >= 0 and op < out.operand_kinds.len() and (out.operand_kinds[op] == OperandKind.OK_COPY or out.operand_kinds[op] == OperandKind.OK_MOVE):
                        let root = suspend_place_root_local(out, out.operand_d0[op])
                        if root > 0 and root < local_count and in_views[root] != 0:
                            if trace: with_eprint(f"[cow-last-use] fn_sym={out.fn_sym} _{local} at bb{bb}:{si}: kept, the site reads view _{root}")
                            any_view_live = true
                            break
                if not any_view_live:
                    for vi in 0..view_locals.len():
                        let v = view_locals[vi]
                        let vq = last_use_quick_after_verdict(out, bb, si, v, false)
                        if vq == 1:
                            if trace: with_eprint(f"[cow-last-use] fn_sym={out.fn_sym} _{local} at bb{bb}:{si}: kept, view _{v} read soon after")
                            any_view_live = true
                            break
                        if vq == 0:
                            if live_in_cache[v].len() == 0:
                                live_in_cache[v] = last_use_live_in(out, v, false)
                            if last_use_live_after(out, live_in_cache[v], bb, si, v, false):
                                if trace: with_eprint(f"[cow-last-use] fn_sym={out.fn_sym} _{local} at bb{bb}:{si}: kept, view _{v} live after")
                                any_view_live = true
                                break
            if not any_view_live:
                if trace: with_eprint(f"[cow-last-use] fn_sym={out.fn_sym} _{local} at bb{bb}:{si}: taken (views dead)")
                out.set_operand_hold(held_op, MIR_HOLD_TAKE)
                out.mark_local_ever_moved(local)
    out

pub fn check_no_await_guard_suspends(mir_mod: &MirModule, ast: &AstPool, sema: &Sema, diags: DiagnosticList) -> DiagnosticList:
    var out = diags
    let body_by_fn = suspend_build_body_index(mir_mod)
    let body_may_suspend = suspend_compute_may_suspend(mir_mod, body_by_fn)
    for bi in 0..mir_mod.bodies.len():
        let body = &mir_mod.bodies[bi]
        out = suspend_check_no_suspend_body(ast, sema, body_by_fn, body_may_suspend, body, move out)
        out = suspend_check_body(ast, sema, body_by_fn, body_may_suspend, body, move out)
    out
