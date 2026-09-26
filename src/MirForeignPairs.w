// D66 retained variadic pairs (#1652, spec §16.2b.9 "Pairs configured across
// calls", "Retained borrows"): where a resource's callback pair is proven
// compatible.
//
// Sema decides what each call means to the pair (Sema.w FacadePairOp, keyed
// by the concrete signature MIR records on the call: a setter and the `U`
// its specialization installs, the abandonment path as the reset, a
// destroyer, every other operation as callback-capable unless `callbacks
// none`). This pass decides where: it runs the ForeignPairState.w place flow
// over each lowered body's real CFG — setters, the branches on their status,
// moves, borrows, drops, returns — and reports every operation that could
// invoke an incomplete or incompatible pair, every retained userdata that
// dies or moves while the resource still holds it, and every retaining
// resource that escapes its frame (it is ephemeral until reset or
// destroyed). A helper call that receives the resource is not modeled: it
// is checked as callback-capable and leaves the pair unknown until a reset.
// Nothing here reads a name or an AST spelling; the facts are Sema's tables
// and the MIR itself.

use Ast
use Diagnostic
use Mir
use Sema
use Span
use ForeignPairState
use std.collections.HashMap
use std.builtins.eprint

extern fn with_getenv_str(name: &str) -> str

// One report per violating step: the step's block and span source, and
// what to say.
const PAIRS_SITE_INVOKE: i32 = 1
const PAIRS_SITE_HELPER: i32 = 2
const PAIRS_SITE_EXPIRE: i32 = 3
const PAIRS_SITE_MOVED: i32 = 4
const PAIRS_SITE_ESCAPE: i32 = 5

type PairsStepSite {
    kind: i32,
    bb: i32,
    stmt: i32,       // the statement, or -1 for the block's terminator
    key: i32,        // the place key the report names
    op: i32,         // the FacadePairOp index, or -1
}
impl Copy for PairsStepSite

fn pairs_place_key(keys: &MirDropStateKeys, place_id: i32) -> i32:
    if place_id < 0 or place_id >= keys.place_key.len() as i32:
        return -1
    keys.place_key[place_id]

fn pairs_operand_place(body: &MirBody, operand_id: i32) -> i32:
    if operand_id < 0 or operand_id >= body.operand_kinds.len() as i32:
        return -1
    let kind = body.operand_kinds[operand_id]
    if kind == OperandKind.OK_COPY or kind == OperandKind.OK_MOVE:
        return body.operand_d0[operand_id]
    -1

fn pairs_operand_is_move(body: &MirBody, operand_id: i32) -> bool:
    operand_id >= 0 and operand_id < body.operand_kinds.len() as i32 and body.operand_kinds[operand_id] == OperandKind.OK_MOVE

// The integer a constant operand carries.
fn pairs_operand_const(body: &MirBody, operand_id: i32) -> (bool, i64):
    if operand_id < 0 or operand_id >= body.operand_kinds.len() as i32 or body.operand_kinds[operand_id] != OperandKind.OK_CONSTANT:
        return (false, -1)
    let cid = body.operand_d0[operand_id]
    if cid < 0 or cid >= body.const_kinds.len() as i32 or body.const_kinds[cid] != ConstKind.CK_INT:
        return (false, -1)
    var value: i64 = body.const_d0[cid]
    value = value + (body.const_d1[cid] as i64) * 4294967296
    (true, value)

// A place that leaves the frame when written: the return place, or any
// projection (a field of a struct that may outlive the frame; the flow does
// not know, so the conservative answer holds).
fn pairs_place_escapes(body: &MirBody, place_id: i32) -> bool:
    if place_id < 0 or place_id >= body.place_locals.len() as i32:
        return false
    body.place_locals[place_id] == 0 or body.place_proj_counts[place_id] != 0

fn pairs_block(action: i32, ty: i32, origin: i32, guard: i32, can_fail: bool, invokes: bool) -> ForeignPairBlock:
    ForeignPairBlock { action, ty, origin, guard, can_fail, preserves_on_failure: false, invokes }

fn pairs_keep() -> ForeignPairBlock: pairs_block(FOREIGN_PAIR_KEEP, 0, -1, -1, false, false)

fn pairs_step(action: i32, place: i32, source: i32, block: ForeignPairBlock) -> ForeignPairStep:
    ForeignPairStep { action, place, source, contract: block }

fn pairs_site(kind: i32, bb: i32, stmt: i32, key: i32, op: i32) -> PairsStepSite:
    PairsStepSite { kind, bb, stmt, key, op }

// The value a switch's `otherwise` arm stands for when the switch is on a
// boolean condition: the one value the table does not list.
fn pairs_switch_otherwise_value(body: &MirBody, table: i32) -> i64:
    let start = body.switch_table_starts[table]
    let count = body.switch_table_counts[table]
    var has_zero = false
    for i in 0..count:
        if body.switch_table_vals[(start + i)] == 0: has_zero = true
    if has_zero: 1 else: 0

fn pairs_vec_i32(count: i32, value: i32) -> Vec[i32]:
    let out: Vec[i32] = Vec.new()
    for _ in 0..count: out.push(value)
    out

fn pairs_vec_i64(count: i32, value: i64) -> Vec[i64]:
    let out: Vec[i64] = Vec.new()
    for _ in 0..count: out.push(value)
    out

// Whether the body can touch a pair at all: some place is a pair resource
// or a reference to one. Everything else is skipped without building keys.
fn pairs_body_relevant(sema: &Sema, body: &MirBody) -> bool:
    for p in 0..body.place_sema_types.len() as i32:
        if sema.facade_pair_resource_for_type(body.place_sema_types[p]) >= 0:
            return true
    false

// The per-body facts and the steps built from them, over the drop-state
// place keys (one per local and per projected place MIR named).
type PairsBody {
    keys: MirDropStateKeys,
    // Per key: the pair resource an owned place is, or -1; 1 when the key
    // is a reference to one.
    key_resource: Vec[i32],
    // A projection through a reference local (`(*h).x`, the receiver of a
    // call on `h: &Handle`) is that local: its key, or -1.
    key_alias: Vec[i32],
    key_is_ref: Vec[i32],
    // A reference key's referent key (RK_REF), -2 before any is seen, -1
    // when it is assigned from two places.
    ref_origin: Vec[i32],
    // 1 for keys a userdata setter retains (the referent of its `&U`
    // argument): their moves and deaths are steps.
    origin_key: Vec[i32],
    // The block of the setter call that retained each origin: where a
    // dying or moving origin is reported.
    origin_bb: Vec[i32],
    // A local a setter's status was copied into: the status key it stands
    // for in a comparison (-1: none).
    guard_alias: Vec[i32],
    // Keys holding a setter's status, and the success value each compares
    // against (-1: none).
    guard_ok: Vec[i64],
    // Keys holding `status == OK` / `status != OK`: the guard and the sense.
    cond_guard: Vec[i32],
    cond_is_eq: Vec[i32],
    steps: Vec[ForeignPairStep],
    sites: Vec[PairsStepSite],
    starts: Vec[i32],
    counts: Vec[i32],
    edges: Vec[ForeignPairEdge],
}

fn pairs_body_new(body: &MirBody) -> PairsBody:
    let keys = mir_drop_state_keys_new(body)
    let width = keys.len()
    PairsBody { keys: move keys, key_resource: pairs_vec_i32(width, -1), key_alias: pairs_vec_i32(width, -1), key_is_ref: pairs_vec_i32(width, 0), ref_origin: pairs_vec_i32(width, -2), origin_key: pairs_vec_i32(width, 0), origin_bb: pairs_vec_i32(width, -1), guard_alias: pairs_vec_i32(width, -1), guard_ok: pairs_vec_i64(width, -1), cond_guard: pairs_vec_i32(width, -1), cond_is_eq: pairs_vec_i32(width, 1), steps: Vec.new(), sites: Vec.new(), starts: Vec.new(), counts: Vec.new(), edges: Vec.new() }

impl PairsBody:
    fn width(): self.key_resource.len() as i32

    fn key_of(place_id: i32) -> i32:
        let raw = pairs_place_key(self.keys, place_id)
        if raw >= 0 and self.key_alias[raw] >= 0: self.key_alias[raw] else: raw

    fn is_resource(key: i32) -> bool: key >= 0 and key < self.width() and self.key_resource[key] >= 0

    fn is_ref(key: i32) -> bool: key >= 0 and key < self.width() and self.key_is_ref[key] != 0

    fn is_origin(key: i32) -> bool: key >= 0 and key < self.width() and self.origin_key[key] != 0

    // The base local of a place key, and its user name when it has one.
    fn key_name(sema: &Sema, body: &MirBody, key: i32) -> str:
        if key < 0 or key >= self.keys.base_local.len() as i32:
            return "this value"
        let local = self.keys.base_local[key]
        let sym = if local >= 0 and local < body.local_names.len() as i32: body.local_names[local] else: 0
        if sym != 0:
            return "'" ++ sema.pool_resolve(sym) ++ "'"
        "this value"

    fn resource_name(sema: &Sema, key: i32) -> str:
        var ri = -1
        if key >= 0 and key < self.width():
            ri = self.key_resource[key]
            if ri < 0 and self.is_ref(key) and self.ref_origin[key] >= 0: ri = self.key_resource[self.ref_origin[key]]
        if ri < 0:
            return "the resource"
        "'" ++ sema.pool_resolve(sema.facade_resources[ri].name) ++ "'"

    // The key a userdata setter's `&U` argument (its last) refers to: the
    // referent of the reference when the body took it, else the reference
    // itself (a parameter: its frame bounds the retention here).
    fn userdata_origin(body: &MirBody, call_id: i32) -> i32:
        let start = body.call_arg_starts[call_id]
        let count = body.call_arg_counts[call_id]
        if count == 0:
            return -1
        let place = pairs_operand_place(body, body.call_arg_operands[(start + count - 1)])
        let key = self.key_of(place)
        if key < 0:
            return -1
        let origin = self.ref_origin[key]
        if origin >= 0: origin else: key

    mut fn push(step: ForeignPairStep, site: PairsStepSite):
        self.steps.push(step)
        self.sites.push(site)

    mut fn classify(sema: &Sema, body: &MirBody):
        // A projection through a reference local names what the local
        // refers to: its key is the local's, whose targets a BORROW set.
        for p in 0..body.place_sema_types.len() as i32:
            let raw = pairs_place_key(self.keys, p)
            if raw < 0 or body.place_proj_counts[p] == 0:
                continue
            let base = body.place_locals[p]
            if base < 0 or base >= body.local_type_ids.len() as i32:
                continue
            let base_ty = sema.resolve_alias(body.local_type_ids[base] as TypeId)
            if sema.get_type_kind(base_ty) == TypeKind.TY_REF and sema.facade_pair_resource_for_type(base_ty as i32) >= 0:
                self.key_alias[raw] = base
        for p in 0..body.place_sema_types.len() as i32:
            let key = self.key_of(p)
            if key < 0 or self.is_resource(key) or self.is_ref(key) or self.key_alias[pairs_place_key(self.keys, p)] >= 0:
                continue
            let ty = body.place_sema_types[p]
            let ri = sema.facade_pair_resource_for_type(ty)
            if ri < 0:
                continue
            let resolved = sema.resolve_alias(ty as TypeId)
            if sema.get_type_kind(resolved) == TypeKind.TY_REF:
                self.key_is_ref[key] = 1
            else:
                self.key_resource[key] = ri

    mut fn note_ref(dest: i32, src: i32):
        if self.ref_origin[dest] == -2: self.ref_origin[dest] = src
        else if self.ref_origin[dest] != src: self.ref_origin[dest] = -1

    // Pass 1 over the body: referents of references, setter status guards
    // and the userdata origins the setters retain — facts the step builder
    // needs before it sees the statements that use them.
    mut fn prepass(sema: &Sema, body: &MirBody):
        for stmt in 0..body.stmt_count():
            if body.stmt_kind(stmt) != StmtKind.Assign:
                continue
            let dest = self.key_of(body.stmt_data0(stmt))
            let rv = body.stmt_data1(stmt)
            if dest < 0 or rv < 0 or rv >= body.rval_kinds.len() as i32:
                continue
            if body.rval_kinds[rv] == RvalueKind.RK_REF:
                self.note_ref(dest, self.key_of(body.rval_d1[rv]))
            else if body.rval_kinds[rv] == RvalueKind.RK_USE:
                // A copied reference names what it copies.
                let op = body.rval_d0[rv]
                let src_place = pairs_operand_place(body, op)
                if src_place >= 0 and not pairs_operand_is_move(body, op):
                    let src = self.key_of(src_place)
                    if src >= 0 and self.ref_origin[src] != -2:
                        self.note_ref(dest, self.ref_origin[src])
        for bb in 0..body.block_count():
            if body.term_kind(bb) != TermKind.TK_CALL:
                continue
            let call_id = body.term_data1(bb)
            if call_id < 0 or call_id >= body.call_sig_indices.len() as i32:
                continue
            let opi = sema.facade_pair_op_for_sig(body.call_sig_indices[call_id])
            if opi < 0:
                continue
            let action = sema.facade_pair_ops[opi].action
            let ok = sema.facade_pair_ops[opi].guard_ok
            let dest = self.key_of(body.term_data2(bb))
            if (action == FOREIGN_PAIR_CALLBACK or action == FOREIGN_PAIR_USERDATA) and ok >= 0 and dest >= 0:
                self.guard_ok[dest] = ok
            if action == FOREIGN_PAIR_USERDATA:
                let origin = self.userdata_origin(body, call_id)
                if origin >= 0:
                    self.origin_key[origin] = 1
                    self.origin_bb[origin] = bb
        // A setter's status bound to a local (`let rc = h.set(…)`) or copied
        // on: the local stands for the call's status in a comparison.
        for stmt in 0..body.stmt_count():
            if body.stmt_kind(stmt) != StmtKind.Assign:
                continue
            let dest = self.key_of(body.stmt_data0(stmt))
            let rv = body.stmt_data1(stmt)
            if dest < 0 or rv < 0 or rv >= body.rval_kinds.len() as i32 or body.rval_kinds[rv] != RvalueKind.RK_USE:
                continue
            let src = self.key_of(pairs_operand_place(body, body.rval_d0[rv]))
            if src < 0:
                continue
            if self.guard_alias[src] >= 0: self.guard_alias[dest] = self.guard_alias[src]
            else if self.guard_ok[src] >= 0: self.guard_alias[dest] = src
        // `status == OK` and `status != OK` (Ast BinaryOp): the branch they
        // decide refines the setter's outcome along its edges.
        for stmt in 0..body.stmt_count():
            if body.stmt_kind(stmt) != StmtKind.Assign:
                continue
            let dest = self.key_of(body.stmt_data0(stmt))
            let rv = body.stmt_data1(stmt)
            if dest < 0 or rv < 0 or rv >= body.rval_kinds.len() as i32 or body.rval_kinds[rv] != RvalueKind.RK_BIN_OP:
                continue
            let bop = body.rval_d0[rv]
            if bop != BinaryOp.OP_EQ and bop != BinaryOp.OP_NEQ:
                continue
            let lhs = body.rval_d1[rv]
            let rhs = body.rval_d2[rv]
            var guard = -1
            var value: i64 = -1
            let (rknown, rvalue) = pairs_operand_const(body, rhs)
            let (lknown, lvalue) = pairs_operand_const(body, lhs)
            let lp = pairs_operand_place(body, lhs)
            let rp = pairs_operand_place(body, rhs)
            if lp >= 0 and rknown:
                guard = self.key_of(lp)
                value = rvalue
            else if rp >= 0 and lknown:
                guard = self.key_of(rp)
                value = lvalue
            if guard >= 0 and self.guard_alias[guard] >= 0: guard = self.guard_alias[guard]
            if guard < 0 or self.guard_ok[guard] < 0 or self.guard_ok[guard] != value:
                continue
            self.cond_guard[dest] = guard
            self.cond_is_eq[dest] = if bop == BinaryOp.OP_EQ: 1 else: 0

    // A moved operand: a resource's state moves with it (and escapes with
    // it into the return place or a projection); a retained origin cannot
    // move.
    mut fn move_operand(body: &MirBody, operand_id: i32, dest_place: i32, bb: i32, stmt: i32):
        if not pairs_operand_is_move(body, operand_id):
            return
        let src = self.key_of(pairs_operand_place(body, operand_id))
        if src < 0:
            return
        if self.is_resource(src):
            if dest_place >= 0 and pairs_place_escapes(body, dest_place):
                self.push(pairs_step(FOREIGN_STEP_ESCAPE, src, -1, pairs_keep()), pairs_site(PAIRS_SITE_ESCAPE, bb, stmt, src, -1))
            let dest = self.key_of(dest_place)
            if dest >= 0:
                self.push(pairs_step(FOREIGN_STEP_MOVE, dest, src, pairs_keep()), pairs_site(PAIRS_SITE_MOVED, bb, stmt, src, -1))
        else if self.is_origin(src):
            self.push(pairs_step(FOREIGN_STEP_EXPIRE, src, -1, pairs_keep()), pairs_site(PAIRS_SITE_MOVED, bb, stmt, src, -1))

    mut fn destroy(sema: &Sema, key: i32, bb: i32, stmt: i32):
        let invokes = sema.facade_pair_drop_invokes(self.key_resource[key])
        self.push(pairs_step(FOREIGN_STEP_APPLY, key, -1, pairs_block(FOREIGN_PAIR_DESTROY, 0, -1, -1, false, invokes)), pairs_site(PAIRS_SITE_INVOKE, bb, stmt, key, -1))

    mut fn build_stmt(sema: &Sema, body: &MirBody, bb: i32, stmt: i32):
        let kind = body.stmt_kind(stmt)
        if kind == StmtKind.Drop:
            let key = self.key_of(body.stmt_data0(stmt))
            if self.is_resource(key): self.destroy(sema, key, bb, stmt)
            // A dropped origin (a capturing callable ends by a drop, not
            // only by its storage dying) dies here.
            else if self.is_origin(key):
                self.push(pairs_step(FOREIGN_STEP_EXPIRE, key, -1, pairs_keep()), pairs_site(PAIRS_SITE_EXPIRE, bb, stmt, key, -1))
            return
        if kind == StmtKind.StorageDead:
            let key = body.stmt_data0(stmt)
            if self.is_origin(key):
                self.push(pairs_step(FOREIGN_STEP_EXPIRE, key, -1, pairs_keep()), pairs_site(PAIRS_SITE_EXPIRE, bb, stmt, key, -1))
            return
        if kind != StmtKind.Assign:
            return
        let dest_place = body.stmt_data0(stmt)
        let dest = self.key_of(dest_place)
        let rv = body.stmt_data1(stmt)
        if dest < 0 or rv < 0 or rv >= body.rval_kinds.len() as i32:
            return
        let rk = body.rval_kinds[rv]
        if rk == RvalueKind.RK_USE:
            let op = body.rval_d0[rv]
            if pairs_operand_is_move(body, op):
                self.move_operand(body, op, dest_place, bb, stmt)
            else:
                let src = self.key_of(pairs_operand_place(body, op))
                if self.is_ref(src) and self.is_ref(dest):
                    self.push(pairs_step(FOREIGN_STEP_BORROW, dest, src, pairs_keep()), pairs_site(PAIRS_SITE_MOVED, bb, stmt, src, -1))
            return
        if rk == RvalueKind.RK_REF:
            let src = self.key_of(body.rval_d1[rv])
            if (self.is_resource(src) or self.is_ref(src)) and self.is_ref(dest):
                self.push(pairs_step(FOREIGN_STEP_BORROW, dest, src, pairs_keep()), pairs_site(PAIRS_SITE_MOVED, bb, stmt, src, -1))
            return
        if rk == RvalueKind.RK_AGGREGATE:
            let fields = body.rval_d1[rv]
            if fields < 0 or fields >= body.agg_field_starts.len() as i32:
                return
            let start = body.agg_field_starts[fields]
            let count = body.agg_field_counts[fields]
            for fi in 0..count:
                // A resource moved into an aggregate leaves its own place;
                // the aggregate's place is the flow's conservative escape.
                let op = body.agg_field_operands[(start + fi)]
                if not pairs_operand_is_move(body, op):
                    continue
                let src = self.key_of(pairs_operand_place(body, op))
                if self.is_resource(src):
                    self.push(pairs_step(FOREIGN_STEP_ESCAPE, src, -1, pairs_keep()), pairs_site(PAIRS_SITE_ESCAPE, bb, stmt, src, -1))
                    self.push(pairs_step(FOREIGN_STEP_MOVE, dest, src, pairs_keep()), pairs_site(PAIRS_SITE_MOVED, bb, stmt, src, -1))
                else if self.is_origin(src):
                    self.push(pairs_step(FOREIGN_STEP_EXPIRE, src, -1, pairs_keep()), pairs_site(PAIRS_SITE_MOVED, bb, stmt, src, -1))

    // A resource born from a call's result (a constructor, `unwrap`, a
    // helper that returns one): the foreign defaults, a compatible pair.
    mut fn create_result(body: &MirBody, bb: i32):
        let dest = self.key_of(body.term_data2(bb))
        if self.is_resource(dest):
            self.push(pairs_step(FOREIGN_STEP_APPLY, dest, -1, pairs_block(FOREIGN_PAIR_CREATE, 0, -1, -1, false, false)), pairs_site(PAIRS_SITE_INVOKE, bb, -1, dest, -1))

    mut fn build_call(sema: &Sema, body: &MirBody, bb: i32):
        self.build_call_args(sema, body, bb)
        self.create_result(body, bb)

    mut fn build_call_args(sema: &Sema, body: &MirBody, bb: i32):
        let call_id = body.term_data1(bb)
        if call_id < 0 or call_id >= body.call_arg_starts.len() as i32:
            return
        let start = body.call_arg_starts[call_id]
        let count = body.call_arg_counts[call_id]
        let sig = if call_id < body.call_sig_indices.len() as i32: body.call_sig_indices[call_id] else: -1
        let opi = sema.facade_pair_op_for_sig(sig)
        if opi >= 0 and count > 0:
            let action = sema.facade_pair_ops[opi].action
            let ok = sema.facade_pair_ops[opi].guard_ok
            let u_tid = sema.facade_pair_ops[opi].userdata_tid
            let invokes = sema.facade_pair_ops[opi].invokes != 0
            let recv = self.key_of(pairs_operand_place(body, body.call_arg_operands[start]))
            if recv < 0:
                return
            let dest = self.key_of(body.term_data2(bb))
            if action == FOREIGN_PAIR_CALLBACK or action == FOREIGN_PAIR_USERDATA:
                let guard = if ok >= 0: dest else: -1
                let origin = if action == FOREIGN_PAIR_USERDATA: self.userdata_origin(body, call_id) else: -1
                self.push(pairs_step(FOREIGN_STEP_APPLY, recv, -1, pairs_block(action, u_tid, origin, guard, true, invokes)), pairs_site(PAIRS_SITE_INVOKE, bb, -1, recv, opi))
            else:
                self.push(pairs_step(FOREIGN_STEP_APPLY, recv, -1, pairs_block(action, 0, -1, -1, false, invokes)), pairs_site(PAIRS_SITE_INVOKE, bb, -1, recv, opi))
            return
        // Not a pair operation: a resource handed to it may be invoked and
        // changed in any way (checked as callback-capable, then unknown
        // until a reset); a resource moved into it is checked and gone; a
        // retained origin moved into it dies here.
        for ai in 0..count:
            let operand = body.call_arg_operands[(start + ai)]
            let key = self.key_of(pairs_operand_place(body, operand))
            if key < 0:
                continue
            if self.is_resource(key) and pairs_operand_is_move(body, operand):
                self.push(pairs_step(FOREIGN_STEP_APPLY, key, -1, pairs_block(FOREIGN_PAIR_DESTROY, 0, -1, -1, false, true)), pairs_site(PAIRS_SITE_HELPER, bb, -1, key, -1))
            else if self.is_resource(key) or self.is_ref(key):
                self.push(pairs_step(FOREIGN_STEP_APPLY, key, -1, pairs_block(FOREIGN_PAIR_UNKNOWN, 0, -1, -1, false, true)), pairs_site(PAIRS_SITE_HELPER, bb, -1, key, -1))
            else if self.is_origin(key) and pairs_operand_is_move(body, operand):
                self.push(pairs_step(FOREIGN_STEP_EXPIRE, key, -1, pairs_keep()), pairs_site(PAIRS_SITE_MOVED, bb, -1, key, -1))

    mut fn build_edges(body: &MirBody, bb: i32):
        let kind = body.term_kind(bb)
        let d0 = body.term_data0(bb)
        let d1 = body.term_data1(bb)
        let d2 = body.term_data2(bb)
        let d3 = body.term_data3(bb)
        if kind == TermKind.TK_GOTO:
            self.edges.push(ForeignPairEdge { from: bb, to: d0, guard: -1, succeeded: true })
        else if kind == TermKind.TK_CALL:
            self.edges.push(ForeignPairEdge { from: bb, to: d3, guard: -1, succeeded: true })
        else if kind == TermKind.TK_DROP_AND_GOTO:
            self.edges.push(ForeignPairEdge { from: bb, to: d1, guard: -1, succeeded: true })
        else if kind == TermKind.TK_SWITCH_INT:
            var guard = -1
            var is_eq = true
            let cond = self.key_of(pairs_operand_place(body, d0))
            if cond >= 0 and self.cond_guard[cond] >= 0:
                guard = self.cond_guard[cond]
                is_eq = self.cond_is_eq[cond] != 0
            if d1 >= 0 and d1 < body.switch_table_starts.len() as i32:
                let start = body.switch_table_starts[d1]
                let count = body.switch_table_counts[d1]
                for i in 0..count:
                    let value = body.switch_table_vals[(start + i)]
                    let succeeded = if guard < 0: true else: (value != 0) == is_eq
                    self.edges.push(ForeignPairEdge { from: bb, to: body.switch_table_targets[(start + i)], guard, succeeded })
                let other = pairs_switch_otherwise_value(body, d1)
                let succeeded = if guard < 0: true else: (other != 0) == is_eq
                self.edges.push(ForeignPairEdge { from: bb, to: d2, guard, succeeded })
            else:
                self.edges.push(ForeignPairEdge { from: bb, to: d2, guard: -1, succeeded: true })

    mut fn build(sema: &Sema, body: &MirBody):
        for bb in 0..body.block_count():
            let first = self.steps.len() as i32
            let stmt_start = body.bb_stmt_starts[bb]
            let stmt_count = body.bb_stmt_counts[bb]
            for si in 0..stmt_count:
                self.build_stmt(sema, body, bb, stmt_start + si)
            let kind = body.term_kind(bb)
            if kind == TermKind.TK_CALL:
                self.build_call(sema, body, bb)
            else if kind == TermKind.TK_DROP_AND_GOTO:
                let key = self.key_of(body.term_data0(bb))
                if self.is_resource(key): self.destroy(sema, key, bb, -1)
                else if self.is_origin(key):
                    self.push(pairs_step(FOREIGN_STEP_EXPIRE, key, -1, pairs_keep()), pairs_site(PAIRS_SITE_EXPIRE, bb, -1, key, -1))
            self.starts.push(first)
            self.counts.push(self.steps.len() as i32 - first)
            self.build_edges(body, bb)

fn pairs_site_span(ast: AstPool, body: &MirBody, pb: &PairsBody, site: PairsStepSite) -> (i32, i32):
    // A retained origin that dies or moves is reported at the setter that
    // retained it: the death is a generated drop with no source of its own.
    if (site.kind == PAIRS_SITE_EXPIRE or site.kind == PAIRS_SITE_MOVED) and site.key >= 0 and site.key < pb.origin_bb.len() as i32 and pb.origin_bb[site.key] >= 0:
        let retained_at = pb.origin_bb[site.key]
        if body.term_kind(retained_at) == TermKind.TK_CALL:
            let node = body.call_ast_node(body.term_data1(retained_at))
            if node != 0:
                let s = ast.get_start(node)
                let e = ast.get_end(node)
                if e > s: return (s, e)
    var start = 0
    if site.stmt >= 0 and site.stmt < body.stmt_spans.len() as i32:
        start = body.stmt_spans[site.stmt]
    else if site.bb >= 0 and site.bb < body.bb_term_spans.len() as i32:
        start = body.bb_term_spans[site.bb]
        if body.term_kind(site.bb) == TermKind.TK_CALL:
            let node = body.call_ast_node(body.term_data1(site.bb))
            if node != 0:
                let s = ast.get_start(node)
                let e = ast.get_end(node)
                if e > s: return (s, e)
    if start < 0: start = 0
    (start, start + 1)

fn pairs_op_name(sema: &Sema, op: i32) -> str:
    if op < 0:
        return "destroying it"
    let ci = sema.facade_pair_ops[op].contract
    let ri = sema.facade_pair_ops[op].resource
    let fname: str = sema.pool_resolve(sema.foreign_contracts[ci].fn_sym)
    "'" ++ sema.pool_resolve(sema.facade_resources[ri].name) ++ "." ++ sema.facade_presented(ri, fname) ++ "'"

// A finding, reported by compiler/Compilation.w in the body's own file.
pub type PairsFinding {
    fn_sym: i32,
    start: i32,
    end: i32,
    message: str,
    note: str,
    help: str,
}

fn pairs_describe(ast: AstPool, sema: &Sema, body: &MirBody, pb: &PairsBody, site: PairsStepSite) -> PairsFinding:
    let (start, end) = pairs_site_span(ast, body, pb, site)
    // A dying or moving origin names the resource that retained it: the
    // receiver of the setter that did.
    var named = site.key
    if (site.kind == PAIRS_SITE_EXPIRE or site.kind == PAIRS_SITE_MOVED) and site.key >= 0 and site.key < pb.origin_bb.len() as i32 and pb.origin_bb[site.key] >= 0:
        let call_id = body.term_data1(pb.origin_bb[site.key])
        if call_id >= 0 and call_id < body.call_arg_starts.len() as i32 and body.call_arg_counts[call_id] > 0:
            named = pb.key_of(pairs_operand_place(body, body.call_arg_operands[body.call_arg_starts[call_id]]))
    let resource = pb.resource_name(sema, named)
    if site.kind == PAIRS_SITE_INVOKE:
        return PairsFinding { fn_sym: body.fn_sym, start, end, message: pairs_op_name(sema, site.op) ++ " may invoke the callback pair of " ++ resource ++ ", and on this path the pair is not proven compatible (§16.2b.9)", note: "a callback set without its userdata, a setter whose failure was not handled, or a helper call that may have changed the pair leaves it unproven", help: "set both the callback and its userdata, branch on the setter's status against its 'ok' constant, or run the resource's abandonment path first" }
    if site.kind == PAIRS_SITE_HELPER:
        return PairsFinding { fn_sym: body.fn_sym, start, end, message: "passing " ++ resource ++ " to a call the facade does not describe while its callback pair is not proven compatible; the callee may invoke it (§16.2b.9)", note: "", help: "complete the pair or run the abandonment path before the call" }
    if site.kind == PAIRS_SITE_EXPIRE or site.kind == PAIRS_SITE_MOVED:
        let what = if site.kind == PAIRS_SITE_EXPIRE: "dies" else: "moves"
        return PairsFinding { fn_sym: body.fn_sym, start, end, message: pb.key_name(sema, body, site.key) ++ " " ++ what ++ " while " ++ resource ++ " still holds it as callback userdata (§16.2b.9)", note: "", help: "keep it alive until the resource is reset or destroyed, or reset the resource first" }
    PairsFinding { fn_sym: body.fn_sym, start, end, message: resource ++ " holds a retained callback borrow and cannot be returned or stored; it is ephemeral until reset or destroyed (§16.2b.9)", note: "", help: "run the abandonment path first, or keep the resource in this frame" }

// WITH_DUMP_PAIR_FLOW=1: every fact the flow ran on, for one body — the
// pair operations Sema registered, each call's recorded signature and the
// operation it matched, the steps per block, the edges with their guard
// refinement, and the violating steps.
fn pairs_dump(sema: &Sema, body: &MirBody, pb: &PairsBody, flow: &ForeignPairPlaceFlow):
    eprint(f"pair-flow fn {sema.pool_resolve(body.fn_sym)} keys={pb.width()} steps={pb.steps.len() as i32} edges={pb.edges.len() as i32}")
    for oi in 0..sema.facade_pair_ops.len() as i32:
        let op = &sema.facade_pair_ops[oi]
        eprint(f"  op{oi} action={op.action} resource={sema.pool_resolve(sema.facade_resources[op.resource].name)} slot={op.slot} u={op.userdata_tid} ok={op.guard_ok} invokes={op.invokes}")
    for bb in 0..body.block_count():
        if body.term_kind(bb) == TermKind.TK_CALL:
            let call_id = body.term_data1(bb)
            let sig = if call_id >= 0 and call_id < body.call_sig_indices.len() as i32: body.call_sig_indices[call_id] else: -1
            eprint(f"  bb{bb} call sig={sig} op={sema.facade_pair_op_for_sig(sig)} dest_key={pb.key_of(body.term_data2(bb))}")
        for si in pb.starts[bb]..pb.starts[bb] + pb.counts[bb]:
            let s = &pb.steps[si]
            let c = &s.contract
            eprint(f"  bb{bb} step{si} kind={s.action} place={s.place}:{pb.key_name(sema, body, s.place)} source={s.source} op={c.action} ty={c.ty} origin={c.origin} guard={c.guard} can_fail={c.can_fail} invokes={c.invokes} site={pb.sites[si].kind} tyname={sema.type_name(c.ty)}")
    for ei in 0..pb.edges.len() as i32:
        let e = &pb.edges[ei]
        eprint(f"  edge bb{e.from}->bb{e.to} guard={e.guard} succeeded={e.succeeded}")
    for vi in 0..flow.violations.len() as i32:
        eprint(f"  violation step{flow.violations[vi]}")

// The module's findings, collected body by body.
pub type PairsReport {
    findings: Vec[PairsFinding],
}

impl PairsReport:
    mut fn check_body(ast: AstPool, sema: &Sema, body: &MirBody):
        if body.block_count() <= 0 or not pairs_body_relevant(sema, body):
            return
        var pb = pairs_body_new(body)
        pb.classify(sema, body)
        pb.prepass(sema, body)
        pb.build(sema, body)
        // Entry: parameters carry a pair the caller proved compatible (its
        // own flow checks that at the call); every other place is absent.
        let width = pb.width()
        var entry = foreign_pair_places(width)
        for li in 1..(body.n_params + 1):
            if li < width and (pb.is_resource(li) or pb.is_ref(li)):
                entry.values[li] = foreign_pair_initial(false)
        let flow = foreign_pair_place_flow(pb.starts, pb.counts, pb.steps, pb.edges, entry)
        if pairs_dump_enabled():
            pairs_dump(sema, body, pb, flow)
        let reported_starts: Vec[i32] = Vec.new()
        let reported_kinds: Vec[i32] = Vec.new()
        for vi in 0..flow.violations.len() as i32:
            let si = flow.violations[vi]
            let site = pb.sites[si]
            let (start, _) = pairs_site_span(ast, body, pb, site)
            var seen = false
            for ri in 0..reported_starts.len() as i32:
                if reported_starts[ri] == start and reported_kinds[ri] == site.kind: seen = true
            if seen:
                continue
            reported_starts.push(start)
            reported_kinds.push(site.kind)
            self.findings.push(pairs_describe(ast, sema, body, pb, site))
            if pairs_dump_enabled():
                let last = self.findings.len() as i32 - 1
                eprint(f"  finding {self.findings[last].start}..{self.findings[last].end}: {self.findings[last].message}")

pub fn pairs_dump_enabled() -> bool: with_getenv_str("WITH_DUMP_PAIR_FLOW").len() > 0

// Every body of the module, after lowering and before codegen
// (compiler/Compilation.w run_mir_lower): a module with no callback pair
// costs one table lookup.
pub fn check_foreign_pairs(mir_mod: &MirModule, ast: AstPool, sema: &Sema) -> PairsReport:
    var report = PairsReport { findings: Vec.new() }
    if sema.facade_pair_ops.len() == 0:
        return report
    for bi in 0..mir_mod.bodies.len() as i32:
        report.check_body(ast, sema, &mir_mod.bodies[bi])
    report
