// MIR data model, builders, ownership dataflow, and validators.
//
// This module owns the MIR in-memory representation used after semantic
// analysis. MIR is intentionally explicit and deterministic.

use Ast
use InternPool
use SemaTypes
use std.collections.HashMap
use std.string.StringBuilder

pub type BlockId = distinct i32
impl Copy for BlockId
impl Copy for TermKind

extern fn with_str_clone_ref(s: &str) -> str
extern fn with_i64_to_str(n: i64) -> str
extern fn with_getenv_str(name: &str) -> str
extern fn with_eprint(s: &str) -> Unit
extern fn str_from_byte(b: i32) -> str
extern fn with_write(s: &str) -> Unit
extern fn with_alloc(size: i64) -> *mut u8

pub fn lbrace -> str:
    str_from_byte(123)

pub fn rbrace -> str:
    str_from_byte(125)

// ── Statement kinds ──────────────────────────────────────────────

pub enum StmtKind: i32:
    Assign = 0
    StorageLive = 1
    StorageDead = 2
    Drop = 3
    Nop = 4

// ── Terminator kinds ─────────────────────────────────────────────

pub enum TermKind: i32:
    TK_GOTO = 0
    TK_RETURN = 1
    TK_UNREACHABLE = 2
    TK_SWITCH_INT = 3
    TK_CALL = 4
    TK_DROP_AND_GOTO = 5

// ── Rvalue kinds ─────────────────────────────────────────────────

pub enum RvalueKind: i32:
    RK_USE = 0
    RK_BIN_OP = 1
    RK_UN_OP = 2
    RK_REF = 3
    RK_ADDR_OF = 4
    RK_AGGREGATE = 5
    RK_DISCRIMINANT = 6
    RK_CAST = 7
    RK_LEN = 8
    RK_ARRAY_FILL = 9
    RK_STR_CONCAT_N = 10
    RK_SLICE = 11

// ── Operand kinds ────────────────────────────────────────────────

pub enum OperandKind: i32:
    OK_COPY = 0
    OK_MOVE = 1
    OK_CONSTANT = 2

// ── Constant kinds ───────────────────────────────────────────────

pub enum ConstKind: i32:
    CK_INT = 0
    CK_BOOL = 1
    CK_STR = 2
    CK_UNIT = 3
    CK_FLOAT = 4
    CK_ZERO_SIZED = 5
    CK_FN = 6
    CK_CLOSURE = 7
    CK_ASYNC_BLOCK = 8
    CK_INT_EXACT = 9
    CK_REGEX_LIT = 10
    CK_C_STR = 11


pub fn mir_intrinsic_is_len32(intrinsic: MirIntrinsic) -> bool:
    intrinsic == MirIntrinsic.VEC_LEN32 or intrinsic == MirIntrinsic.MAP_LEN32 or intrinsic == MirIntrinsic.STR_LEN32 or intrinsic == MirIntrinsic.ARR_LEN32 or intrinsic == MirIntrinsic.VECRANGE_LEN32 or intrinsic == MirIntrinsic.SLOTMAP_LEN32

pub fn mir_intrinsic_is_len64(intrinsic: MirIntrinsic) -> bool:
    intrinsic == MirIntrinsic.VEC_LEN64 or intrinsic == MirIntrinsic.MAP_LEN64 or intrinsic == MirIntrinsic.STR_LEN64 or intrinsic == MirIntrinsic.ARR_LEN64 or intrinsic == MirIntrinsic.VECRANGE_LEN64 or intrinsic == MirIntrinsic.SLOTMAP_LEN64

pub fn mir_intrinsic_is_ulen32(intrinsic: MirIntrinsic) -> bool:
    intrinsic == MirIntrinsic.VEC_ULEN32 or intrinsic == MirIntrinsic.MAP_ULEN32 or intrinsic == MirIntrinsic.STR_ULEN32 or intrinsic == MirIntrinsic.ARR_ULEN32 or intrinsic == MirIntrinsic.VECRANGE_ULEN32 or intrinsic == MirIntrinsic.SLOTMAP_ULEN32

// ── Projection kinds ─────────────────────────────────────────────

pub enum ProjKind: i32:
    PK_FIELD = 0
    PK_INDEX = 1
    PK_DEREF = 2
    PK_DOWNCAST = 3
    PK_TUPLE_INDEX = 4

// ── Drop kind tags for scope scheduling ──────────────────────────

pub enum DropKind: i32:
    DK_VALUE = 0
    DK_STORAGE = 1
    DK_TASK_DETACHED = 2
    DK_TASK_EPHEMERAL = 3
    DK_WITH_GUARD = 4
    DK_WITH_GUARD_MUT = 5
    DK_ASYNC_SCOPE = 6
    DK_THREAD_SCOPE = 7
    // D75: the binding holds a list `va_start()` started; its scope end is
    // the list's end (llvm.va_end / C's va_end), not a drop of the value.
    DK_VA_END = 8

// Copy: DropKind is a lightweight integer tag passed by value.
impl Copy for DropKind

// ── Data records ─────────────────────────────────────────────────

type MirLocalInfo {
    type_id: i32,
    is_mutable: i32,
    name_sym: i32,
    is_user_var: i32,
}

pub type MirBody {
    fn_sym: i32,
    lowering_failed: i32,
    anonymous_type: i32,
    anonymous_capture_count: i32,
    // The creating body's local each capture (locals 1..count) is taken
    // from, by id (codegen builds the environment from these).
    anonymous_capture_sources: Vec[i32],
    // ... and how MIR materialized each (MIR_CAPTURE_*): the local itself,
    // a snapshot copy, a reference to an alias place, or a protocol capture
    // MIR adds by place (a gen-loop's flag, return slot and producer).
    // audit:resolution judges the first three against Sema's capture mode
    // (D62); a protocol capture is MIR's own and follows Sema's record.
    anonymous_capture_kinds: Vec[i32],

    // Locals
    local_type_ids: Vec[i32],
    local_mutables: Vec[i32],
    local_names: Vec[i32],
    local_is_user_var: Vec[i32],
    local_is_global: Vec[i32],   // 1: MirLower's proxy for module-level storage, never a user local that shares the name
    // 1: a parameter naming the caller's place (a `mut self`/`&self` receiver,
    // a share-place parameter, a Drop body's self). The callee writes through
    // it and the caller drops it: MirLower schedules no drop for it (#1822).
    local_is_caller_place: Vec[i32],
    // MirLower scheduled owned-value cleanup, even if every emitted drop was
    // later cancelled. The validator must not infer ownership from surviving
    // Drop statements: that misses a compiler that omits all of them (#1944).
    owned_cleanup_locals: Vec[i32],
    n_params: i32,
    // Blocks ending in mutual tail calls (marked by mutual TCO pass).
    mutual_tail_bbs: Vec[i32],

    // Basic blocks
    bb_stmt_starts: Vec[i32],
    bb_stmt_counts: Vec[i32],
    bb_term_kinds: Vec[i32],
    bb_term_d0: Vec[i32],
    bb_term_d1: Vec[i32],
    bb_term_d2: Vec[i32],
    bb_term_d3: Vec[i32],
    bb_is_cleanup: Vec[i32],
    bb_term_spans: Vec[i32],
    bb_no_suspend_nodes: Vec[i32],

    // Statements
    stmt_kinds: Vec[i32],
    stmt_d0: Vec[i32],
    stmt_d1: Vec[i32],
    stmt_spans: Vec[i32],

    // Places
    place_locals: Vec[i32],
    place_sema_types: Vec[i32],
    place_proj_starts: Vec[i32],
    place_proj_counts: Vec[i32],
    proj_kinds: Vec[i32],
    proj_d0: Vec[i32],
    // A PK_FIELD projection of a named struct field: the field's position in
    // the struct declaration Sema resolved its owner to (D65, #1647); -1 for
    // every other projection (a tuple element, a variant payload, a
    // compiler-laid-out record's positional field), whose proj_d0 is the
    // position.
    proj_decl: Vec[i32],

    // Rvalues
    rval_kinds: Vec[i32],
    rval_d0: Vec[i32],
    rval_d1: Vec[i32],
    rval_d2: Vec[i32],

    // Operands
    operand_kinds: Vec[i32],
    operand_d0: Vec[i32],

    // Constants
    const_kinds: Vec[i32],
    const_d0: Vec[i32],
    const_d1: Vec[i32],
    const_d2: Vec[i32],
    const_types: Vec[i32],

    // Switch tables
    switch_table_starts: Vec[i32],
    switch_table_counts: Vec[i32],
    switch_table_vals: Vec[i64],
    switch_table_targets: Vec[i32],

    // Aggregate field tables
    agg_field_starts: Vec[i32],
    agg_field_counts: Vec[i32],
    agg_field_operands: Vec[i32],
    agg_field_name_syms: Vec[i32],

    // Call argument tables
    call_arg_starts: Vec[i32],
    call_arg_counts: Vec[i32],
    call_arg_operands: Vec[i32],

    // Call intrinsic markers (parallel to call_arg_starts)
    call_intrinsic_kinds: Vec[MirIntrinsic],
    // MathBuiltins row id for MATH_FN calls (parallel; -1 otherwise)
    call_math_fn_ids: Vec[i32],
    // AST call node for generic calls (parallel to call_arg_starts, 0 if N/A)
    call_ast_nodes: Vec[i32],
    // Concrete semantic contract captured at lowering time. AST call nodes are
    // shared by every generic specialization and their Sema sidecars are
    // overwritten; MIR must retain its own specialization-specific values.
    call_sig_indices: Vec[i32],
    call_mono_syms: Vec[i32],
    // User-defined generic calls must carry the concrete contract above.
    // Builtin generic dispatch shares MirIntrinsic.GENERIC_CALL but does not.
    call_contract_required: Vec[i32],
    // D21: for a Unit-returning `mut self` pipeline stage, the exact receiver
    // place carried after this call. -1 for ordinary return-value calls.
    call_pipeline_receiver_places: Vec[i32],
    // D65 (#1647, interim until phase 5): 1 on a GENERIC_CALL that carries no
    // contract because MirLower's single decision point
    // (require_generic_call_contract) classified it as language machinery
    // codegen dispatches by name and receiver (a Task, ScopedTask, channel
    // endpoint or Atomic method, `track`, `spawn`, `join`). The typed
    // validator and audit:resolution recognize the call by this mark; the
    // unresolved-bare-function branch that produced #1635 never sets it.
    call_machinery_dispatch: Vec[i32],
    // #2019: an intrinsic call that invokes a closure Sema says may suspend
    // (call_site_may_suspend): codegen leaves its loop when an invocation
    // left by a cancellation unwind, and MirLower checks after the call.
    call_may_cancel: Vec[i32],
    // D65 (#1647): call nodes Sema resolved that this body materializes
    // without a call — `for x in v.iter()` and a comprehension over it are
    // the index loop (`.iter()` is the implicit form, §13). MIR states the
    // elision instead of staying silent; audit:resolution joins Sema's
    // resolved call to it.
    elided_call_nodes: Vec[i32],
    // D65 phase 3 (#1647): each place lowered from a source field access,
    // with its AST node and the base place it projects from. audit:
    // resolution joins Sema's facts for the node to the place.
    field_place_nodes: Vec[i32],
    field_place_places: Vec[i32],
    field_place_bases: Vec[i32],
    // ... and each `let` binding with MIR's materialization: 1 when the
    // name aliases a place, 0 when it owns a local.
    let_binding_nodes: Vec[i32],
    let_binding_aliases: Vec[i32],
    // ... the place an aliasing `let` names (-1 for an owning local), whose
    // root audit:resolution joins to Sema's view origins for the value.
    let_binding_places: Vec[i32],
    // ... and each place lowered from a source index expression, with the
    // base place it indexes.
    index_place_nodes: Vec[i32],
    index_place_places: Vec[i32],
    index_place_bases: Vec[i32],
    // The Sema symbol of the specialization whose body this is, or that
    // encloses it (a closure, a gen loop body, a generator's producer); 0
    // outside a specialization. Sema keys the facts it records per instance
    // (index_element_in_body, type_level_arg_in_body) by it (#1647, D65).
    instance_sym: i32,

    // Stage 4 (spec §2.5.2): locals that are ever moved — and therefore
    // reset-on-move (§2.5.1) — recorded at the single pending_reset_locals.push
    // site during lowering. A drop of a local NOT in this set can never observe
    // the reset sentinel, so codegen elides its null guard and emits an
    // unconditional drop (the zero-cost common case).
    ever_moved_locals: Vec[i32],
}

pub type MirModule {
    bodies: Vec[MirBody],
    body_fn_syms: Vec[i32],
    body_index_by_fn_sym: HashMap[i32, i32],
    // Snapshot of sema type tables at lowering time.
    // MirLower takes sema by value; its Vec reallocs can free
    // the shared buffer that the caller's sema copy points to.
    // Codegen reads these instead of sema.type_kinds/d0/d1.
    sema_type_kinds: Vec[i32],
    sema_type_d0: Vec[i32],
    sema_type_d1: Vec[i32],
    sema_type_d2: Vec[i32],
    sema_type_extra: Vec[i32],
    sema_bitpacked_types: HashMap[i32, i32],
    sema_disc_repr_types: HashMap[i32, i32],
    sema_distinct_type_names: HashMap[i32, i32],
    // std Box's name sym when the std-box module verdict holds (else 0) —
    // lets the typed validator mirror sema's Box[Concrete] -> Box[dyn Trait]
    // coercion arm exactly instead of approximating it.
    sema_box_sym: i32,
    sema_option_sym: i32,
    // Result's symbol: the one two-argument enum whose variants carry its
    // arguments in declaration order (Ok(T), Err(E)).
    sema_result_sym: i32,
    // Task and ScopedTask: the handle types the fiber intrinsics take (#1464).
    sema_task_sym: i32,
    sema_scoped_task_sym: i32,
    // #1394: every type a body moves out of a sub-place (a field, a tuple
    // element, a variant payload) that has drop glue. The ownership
    // validator asks it whether a vacated sub-place is one the whole
    // value's drop would free again; MirCore has no Sema to ask.
    sema_moved_drop_types: HashMap[i32, i32],
    // #1559: the drop-glue types of every place a body drops (a Drop
    // statement or a drop terminator): a place need not be moved for a
    // drop of it on a path where it holds no value to free garbage.
    sema_dropped_types: HashMap[i32, i32],
    // #1814 (§2.3): the element types of every `array_fill` that are not
    // Copy. A fill evaluates its operand once and copies it N times, so a
    // non-Copy element is N owners of one value: invalid MIR.
    sema_non_copy_fill_types: HashMap[i32, i32],
    // #2108: the local types that are a generic struct or enum declaration
    // with no type arguments (`Option`, not `Option[i32]`).
    sema_uninstantiated_generic_types: HashMap[i32, i32],
    // D65 (#1647, #1639): every symbol Sema accepts as a direct call target,
    // keyed by this module's pool: MirCallableClass.Signature for a declared
    // signature, Generic for a generic template, Intrinsic for a builtin
    // Sema lowers itself. Propagated from Sema at lowering; the typed-MIR
    // validator refuses a `const fn` callee outside it that has no body in
    // the module and no intrinsic mark, so a callee re-derived from an AST
    // spelling (#1635's `r(21)`) can never reach codegen silently.
    sema_callable_syms: HashMap[i32, i32],
    // #1735, #1742: each function's Sema signature, by this module's symbol
    // (the canonical signature of its name, get_sig): the offset of
    // [param count, then (type, consumes) per parameter] in
    // sema_sig_param_data. `consumes` is 1 for a parameter that takes
    // ownership of its argument — a plain `T` that is no in-place receiver
    // (value_ref_abi), not a `&T` or a raw pointer.
    sema_sig_param_starts: HashMap[i32, i32],
    sema_sig_param_data: Vec[i32],
    // #1742: every function whose signature returns Never (with_panic): a
    // call to it has no continuation for the caller's drops to run on.
    sema_never_returning_syms: HashMap[i32, i32],
}

pub enum MirCallableClass: i32:
    Signature = 1
    Generic = 2
    Intrinsic = 3

impl Copy for MirCallableClass

// ── MirModule helpers ────────────────────────────────────────────

fn MirModule.init -> MirModule:
    MirModule {
        bodies: Vec.new(),
        body_fn_syms: Vec.new(),
        body_index_by_fn_sym: HashMap.new(),
        sema_type_kinds: Vec.new(),
        sema_type_d0: Vec.new(),
        sema_type_d1: Vec.new(),
        sema_type_d2: Vec.new(),
        sema_type_extra: Vec.new(),
        sema_bitpacked_types: HashMap.new(),
        sema_disc_repr_types: HashMap.new(),
        sema_distinct_type_names: HashMap.new(),
        sema_box_sym: 0,
        sema_option_sym: 0,
        sema_result_sym: 0,
        sema_task_sym: 0,
        sema_scoped_task_sym: 0,
        sema_moved_drop_types: HashMap.new(),
        sema_dropped_types: HashMap.new(),
        sema_non_copy_fill_types: HashMap.new(),
        sema_uninstantiated_generic_types: HashMap.new(),
        sema_callable_syms: HashMap.new(),
        sema_sig_param_starts: HashMap.new(),
        sema_sig_param_data: Vec.new(),
        sema_never_returning_syms: HashMap.new(),
    }

impl MirModule:
    fn mir_is_bitpacked(tid: i32) -> bool:
        self.sema_bitpacked_types.contains(tid)

    fn mir_get_type_kind(tid: i32) -> i32:
        if tid < 0 or tid >= self.sema_type_kinds.len():
            return 0
        self.sema_type_kinds[tid]

    fn mir_get_type_d0(tid: i32) -> i32:
        if tid < 0 or tid >= self.sema_type_d0.len():
            return 0
        self.sema_type_d0[tid]

    fn mir_get_type_d1(tid: i32) -> i32:
        if tid < 0 or tid >= self.sema_type_d1.len():
            return 0
        self.sema_type_d1[tid]

    fn mir_get_type_d2(tid: i32) -> i32:
        if tid < 0 or tid >= self.sema_type_d2.len():
            return 0
        self.sema_type_d2[tid]

    fn mir_get_type_extra(idx: i32) -> i32:
        if idx < 0 or idx >= self.sema_type_extra.len():
            return 0
        self.sema_type_extra[idx]

    fn mir_resolve_alias(tid: i32) -> i32:
        var cur = tid
        var depth = 0
        while depth < 20:
            let k = self.mir_get_type_kind(cur)
            if k != TypeKind.TY_ALIAS:
                return cur
            let target = self.mir_get_type_d0(cur)
            if target <= 0 or target == cur:
                return cur
            cur = target
            depth = depth + 1
        cur

    fn mir_get_type_name(tid: i32) -> i32:
        let resolved = self.mir_resolve_alias(tid)
        let tk = self.mir_get_type_kind(resolved)
        if tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF:
            return self.mir_get_type_name(self.mir_get_type_d0(resolved))
        if tk == TypeKind.TY_STRUCT or tk == TypeKind.TY_ENUM or tk == TypeKind.TY_GENERIC_INST:
            return self.mir_get_type_d0(resolved)
        0

    // No-op: reserved for future manual memory management.
    mut fn deinit():
        return

    mut fn add_body(body: MirBody):
        let body_idx = self.bodies.len() as i32
        let fn_sym: i32 = body.fn_sym
        self.bodies.push(move body)
        self.body_fn_syms.push(fn_sym)
        if fn_sym != 0:
            self.body_index_by_fn_sym.insert(fn_sym, body_idx)

    fn body_count() -> i32:
        self.bodies.len() as i32

    fn find_body(fn_sym: i32) -> i32:
        if fn_sym == 0:
            return -1
        let body_idx = self.body_index_by_fn_sym.get(fn_sym)
        if body_idx.is_some():
            return body_idx.unwrap()
        -1

// ── MirBody builders ─────────────────────────────────────────────

fn MirBody.init_for_fn(fn_sym: i32) -> MirBody:
    var body = MirBody {
        fn_sym,
        lowering_failed: 0,
        anonymous_type: 0,
        anonymous_capture_count: 0,
        anonymous_capture_sources: Vec.new(),
        anonymous_capture_kinds: Vec.new(),
        local_type_ids: Vec.new(),
        local_mutables: Vec.new(),
        local_names: Vec.new(),
        local_is_user_var: Vec.new(),
        local_is_global: Vec.new(),
        local_is_caller_place: Vec.new(),
        owned_cleanup_locals: Vec.new(),
        n_params: 0,
        mutual_tail_bbs: Vec.new(),
        bb_stmt_starts: Vec.new(),
        bb_stmt_counts: Vec.new(),
        bb_term_kinds: Vec.new(),
        bb_term_d0: Vec.new(),
        bb_term_d1: Vec.new(),
        bb_term_d2: Vec.new(),
        bb_term_d3: Vec.new(),
        bb_is_cleanup: Vec.new(),
        bb_term_spans: Vec.new(),
        bb_no_suspend_nodes: Vec.new(),
        stmt_kinds: Vec.new(),
        stmt_d0: Vec.new(),
        stmt_d1: Vec.new(),
        stmt_spans: Vec.new(),
        place_locals: Vec.new(),
        place_sema_types: Vec.new(),
        place_proj_starts: Vec.new(),
        place_proj_counts: Vec.new(),
        proj_kinds: Vec.new(),
        proj_d0: Vec.new(),
        proj_decl: Vec.new(),
        rval_kinds: Vec.new(),
        rval_d0: Vec.new(),
        rval_d1: Vec.new(),
        rval_d2: Vec.new(),
        operand_kinds: Vec.new(),
        operand_d0: Vec.new(),
        const_kinds: Vec.new(),
        const_d0: Vec.new(),
        const_d1: Vec.new(),
        const_d2: Vec.new(),
        const_types: Vec.new(),
        switch_table_starts: Vec.new(),
        switch_table_counts: Vec.new(),
        switch_table_vals: Vec.new(),
        switch_table_targets: Vec.new(),
        agg_field_starts: Vec.new(),
        agg_field_counts: Vec.new(),
        agg_field_operands: Vec.new(),
        agg_field_name_syms: Vec.new(),
        call_arg_starts: Vec.new(),
        call_arg_counts: Vec.new(),
        call_arg_operands: Vec.new(),
        call_intrinsic_kinds: Vec.new(),
        call_math_fn_ids: Vec.new(),
        call_ast_nodes: Vec.new(),
        call_sig_indices: Vec.new(),
        call_mono_syms: Vec.new(),
        call_contract_required: Vec.new(),
        call_pipeline_receiver_places: Vec.new(),
        call_machinery_dispatch: Vec.new(),
        call_may_cancel: Vec.new(),
        elided_call_nodes: Vec.new(),
        field_place_nodes: Vec.new(),
        field_place_places: Vec.new(),
        field_place_bases: Vec.new(),
        let_binding_nodes: Vec.new(),
        let_binding_aliases: Vec.new(),
        let_binding_places: Vec.new(),
        index_place_nodes: Vec.new(),
        index_place_places: Vec.new(),
        index_place_bases: Vec.new(),
        instance_sym: 0,
        ever_moved_locals: Vec.new(),
    }

    // Local 0 is always the return place.
    body.new_local(0, 1, 0, 0)
    body

// Stage 4 (spec §2.5.2): record/query whether a local is ever moved (and thus
// reset-on-move). Recorded at the single pending_reset_locals.push site during
// lowering; read by codegen to decide whether a drop needs its null guard.
impl MirBody:
    mut fn mark_local_ever_moved(local_id: i32) -> Unit:
        var i = 0
        while i < self.ever_moved_locals.len():
            if self.ever_moved_locals[i] == local_id:
                return
            i = i + 1
        self.ever_moved_locals.push(local_id)

    fn local_ever_moved(local_id: i32) -> bool:
        var i = 0
        while i < self.ever_moved_locals.len():
            if self.ever_moved_locals[i] == local_id:
                return true
            i = i + 1
        false

impl MirBody:
    mut fn new_block() -> BlockId:
        let id = self.bb_stmt_starts.len() as i32
        self.bb_stmt_starts.push(self.stmt_kinds.len() as i32)
        self.bb_stmt_counts.push(0)
        self.bb_term_kinds.push(TermKind.TK_UNREACHABLE)
        self.bb_term_d0.push(0)
        self.bb_term_d1.push(0)
        self.bb_term_d2.push(0)
        self.bb_term_d3.push(0)
        self.bb_is_cleanup.push(0)
        self.bb_term_spans.push(0)
        self.bb_no_suspend_nodes.push(0)
        BlockId(id)

    mut fn push_stmt(bb: i32, kind: i32, d0: i32, d1: i32, span: i32):
        let stmt_id = self.stmt_kinds.len() as i32
        self.stmt_kinds.push(kind)
        self.stmt_d0.push(d0)
        self.stmt_d1.push(d1)
        self.stmt_spans.push(span)

        if bb >= 0 and bb < self.bb_stmt_counts.len():
            let old_count: i32 = self.bb_stmt_counts[bb]
            if old_count == 0:
                self.bb_stmt_starts[bb] = stmt_id
            self.bb_stmt_counts[bb] = old_count + 1

    mut fn set_terminator(bb: i32, kind: i32, d0: i32, d1: i32, d2: i32, d3: i32, span: i32):
        if bb < 0 or bb >= self.bb_term_kinds.len():
            return
        self.bb_term_kinds[bb] = kind
        self.bb_term_d0[bb] = d0
        self.bb_term_d1[bb] = d1
        self.bb_term_d2[bb] = d2
        self.bb_term_d3[bb] = d3
        self.bb_term_spans[bb] = span

    mut fn set_term_no_suspend_node(bb: i32, node: i32):
        if bb < 0 or bb >= self.bb_no_suspend_nodes.len():
            return
        self.bb_no_suspend_nodes[bb] = node

    mut fn new_local(type_id: i32, mutable: i32, name: i32, is_user_var: i32) -> i32:
        let id = self.local_type_ids.len() as i32
        self.local_type_ids.push(type_id)
        self.local_mutables.push(mutable)
        self.local_names.push(name)
        self.local_is_user_var.push(is_user_var)
        self.local_is_global.push(0)
        self.local_is_caller_place.push(0)
        id

    // A local that stands for module-level storage (ensure_global_local).
    // Both backends bind it to the global's address by this mark, never by
    // its name: a function's local may share a global's name (§18.1, the
    // unseen-global shadow), and that local is its own storage.
    mut fn mark_global_local(local_id: i32):
        self.local_is_global[local_id] = 1

    mut fn mark_caller_place_local(local_id: i32):
        self.local_is_caller_place[local_id] = 1

    mut fn new_temp(type_id: i32) -> i32:
        self.new_local(type_id, 1, 0, 0)

    mut fn new_place(local_id: i32) -> i32:
        let id = self.place_locals.len() as i32
        self.place_locals.push(local_id)
        // Sema type defaults to the local's type (overridden by projected places)
        let sema_ty = if local_id >= 0 and local_id < self.local_type_ids.len(): self.local_type_ids[local_id] else: 0
        self.place_sema_types.push(sema_ty)
        self.place_proj_starts.push(self.proj_kinds.len() as i32)
        self.place_proj_counts.push(0)
        id

    mut fn new_place_typed(local_id: i32, sema_ty: i32) -> i32:
        let id = self.place_locals.len() as i32
        self.place_locals.push(local_id)
        self.place_sema_types.push(sema_ty)
        self.place_proj_starts.push(self.proj_kinds.len() as i32)
        self.place_proj_counts.push(0)
        id

    mut fn new_place_with_projection(base: i32, proj_kind: i32, proj_data: i32, sema_ty: i32) -> i32:
        self.new_place_with_projection_decl(base, proj_kind, proj_data, -1, sema_ty)

    mut fn new_place_with_projection_decl(base: i32, proj_kind: i32, proj_data: i32, decl: i32, sema_ty: i32) -> i32:
        if base < 0 or base >= self.place_locals.len():
            return self.new_place(0)

        let base_local: i32 = self.place_locals[base]
        let base_proj_start: i32 = self.place_proj_starts[base]
        let base_proj_count: i32 = self.place_proj_counts[base]

        let new_proj_start = self.proj_kinds.len() as i32
        for i in 0..base_proj_count:
            self.proj_kinds.push(self.proj_kinds[(base_proj_start + i)])
            self.proj_d0.push(self.proj_d0[(base_proj_start + i)])
            self.proj_decl.push(self.proj_decl[(base_proj_start + i)])

        self.proj_kinds.push(proj_kind)
        self.proj_d0.push(proj_data)
        self.proj_decl.push(decl)

        let id = self.place_locals.len() as i32
        self.place_locals.push(base_local)
        self.place_sema_types.push(sema_ty)
        self.place_proj_starts.push(new_proj_start)
        self.place_proj_counts.push(base_proj_count + 1)
        id

    // A positional field: a variant payload, a tuple-like record's slot.
    mut fn new_field_place(base: i32, field_idx: i32, sema_ty: i32) -> i32:
        self.new_place_with_projection(base, ProjKind.PK_FIELD, field_idx, sema_ty)

    // A named struct field: its symbol, and its declaration index from Sema
    // (-1 when the owner has no struct declaration with it).
    mut fn new_named_field_place(base: i32, field_sym: i32, decl: i32, sema_ty: i32) -> i32:
        self.new_place_with_projection_decl(base, ProjKind.PK_FIELD, field_sym, decl, sema_ty)

    fn proj_decl_index(proj_idx: i32) -> i32:
        if proj_idx < 0 or proj_idx >= self.proj_decl.len() as i32: return -1
        self.proj_decl[proj_idx]

    mut fn new_tuple_index_place(base: i32, elem_idx: i32, sema_ty: i32) -> i32:
        self.new_place_with_projection(base, ProjKind.PK_TUPLE_INDEX, elem_idx, sema_ty)

    mut fn new_index_place(base: i32, idx_local: i32, sema_ty: i32) -> i32:
        self.new_place_with_projection(base, ProjKind.PK_INDEX, idx_local, sema_ty)

    mut fn new_deref_place(base: i32, sema_ty: i32): self.new_place_with_projection(base, ProjKind.PK_DEREF, 0, sema_ty)

    // #1381: a downcast place has no type of its own. It names a variant's
    // payload layout — the variant struct codegen projects through — and
    // is only ever the base of a payload field place, which carries the
    // payload's type. Typing it as the enum (as most producers did) made
    // MIR and codegen disagree on every `??`/`unwrap_or`.
    mut fn new_downcast_place(base: i32, variant_idx: i32) -> i32:
        self.new_place_with_projection(base, ProjKind.PK_DOWNCAST, variant_idx, 0)

    mut fn new_rvalue(kind: i32, d0: i32, d1: i32, d2: i32) -> i32:
        let id = self.rval_kinds.len() as i32
        self.rval_kinds.push(kind)
        self.rval_d0.push(d0)
        self.rval_d1.push(d1)
        self.rval_d2.push(d2)
        id

    mut fn new_operand(kind: i32, d0: i32) -> i32:
        let id = self.operand_kinds.len() as i32
        if kind == 1 and with_getenv_str("WITH_TRACE_RESETS").len() > 0:
            with_eprint(f"[new-move-op] id={id} place={d0}")
        self.operand_kinds.push(kind)
        self.operand_d0.push(d0)
        id

    mut fn new_const(kind: i32, d0: i32, d1: i32, d2: i32, type_id: i32) -> i32:
        let id = self.const_kinds.len() as i32
        self.const_kinds.push(kind)
        self.const_d0.push(d0)
        self.const_d1.push(d1)
        self.const_d2.push(d2)
        self.const_types.push(type_id)
        id

pub fn mir_const_int_value(body: &MirBody, const_id: i32) -> i64:
    ast_int_from_parts(
        body.const_d0[const_id],
        body.const_d1[const_id],
        body.const_d2[const_id],
    )

impl MirBody:
    mut fn new_switch_table(vals: &Vec[i64], targets: &Vec[i32]) -> i32:
        let id = self.switch_table_starts.len() as i32
        let start = self.switch_table_vals.len() as i32
        let count = vals.len() as i32
        self.switch_table_starts.push(start)
        self.switch_table_counts.push(count)

        for i in 0..count:
            self.switch_table_vals.push(vals[i])
            if i < targets.len():
                self.switch_table_targets.push(targets[i])
            else:
                self.switch_table_targets.push(0)

        id

    mut fn new_agg_fields(operands: &Vec[i32], name_syms: &Vec[i32]) -> i32:
        let id = self.agg_field_starts.len() as i32
        let start = self.agg_field_operands.len() as i32
        let count = operands.len() as i32
        self.agg_field_starts.push(start)
        self.agg_field_counts.push(count)
        for i in 0..count:
            self.agg_field_operands.push(operands[i])
            self.agg_field_name_syms.push(name_syms[i])
        id

    mut fn new_call_args(operands: &Vec[i32]) -> i32:
        if with_getenv_str("WITH_TRACE_RESETS").len() > 0:
            for __i in 0..operands.len():
                let __op = operands[__i]
                with_eprint(f"[call-arg] op={__op} kind={self.operand_kinds[__op]} place={self.operand_d0[__op]}")
        let id = self.call_arg_starts.len() as i32
        let start = self.call_arg_operands.len() as i32
        let count = operands.len() as i32
        self.call_arg_starts.push(start)
        self.call_arg_counts.push(count)
        self.call_intrinsic_kinds.push(MirIntrinsic.NONE)
        self.call_math_fn_ids.push(-1)
        self.call_ast_nodes.push(0)
        self.call_sig_indices.push(-1)
        self.call_mono_syms.push(0)
        self.call_contract_required.push(0)
        self.call_pipeline_receiver_places.push(-1)
        self.call_machinery_dispatch.push(0)
        self.call_may_cancel.push(0)
        for i in 0..count:
            self.call_arg_operands.push(operands[i])
        id

    mut fn set_call_intrinsic(call_id: i32, kind: MirIntrinsic):
        if call_id >= 0 and call_id < self.call_intrinsic_kinds.len():
            with self.call_intrinsic_kinds.slot(call_id) as mut slot:
                slot.set(kind)

    fn call_intrinsic(call_id: i32) -> MirIntrinsic:
        if call_id < 0 or call_id >= self.call_intrinsic_kinds.len():
            return MirIntrinsic.NONE
        self.call_intrinsic_kinds[call_id]

    mut fn set_call_math_fn_id(call_id: i32, math_id: i32):
        if call_id >= 0 and call_id < self.call_math_fn_ids.len():
            self.call_math_fn_ids[call_id] = math_id

    /// The MathBuiltins row id of a MirIntrinsic.MATH_FN call, else -1.
    fn call_math_fn_id(call_id: i32) -> i32:
        if call_id < 0 or call_id >= self.call_math_fn_ids.len():
            return -1
        self.call_math_fn_ids[call_id]

    mut fn set_call_ast_node(call_id: i32, node: i32):
        if call_id >= 0 and call_id < self.call_ast_nodes.len():
            self.call_ast_nodes[call_id] = node

    fn call_ast_node(call_id: i32) -> i32:
        if call_id < 0 or call_id >= self.call_ast_nodes.len():
            return 0
        self.call_ast_nodes[call_id]

    mut fn set_call_contract(call_id: i32, sig_idx: i32, mono_sym: i32):
        if call_id < 0 or call_id >= self.call_sig_indices.len():
            return
        self.call_sig_indices[call_id] = sig_idx
        self.call_mono_syms[call_id] = mono_sym

    mut fn require_call_contract(call_id: i32):
        if call_id < 0 or call_id >= self.call_contract_required.len():
            return
        self.call_contract_required[call_id] = 1

    fn call_requires_contract(call_id: i32) -> bool:
        if call_id < 0 or call_id >= self.call_contract_required.len():
            return false
        self.call_contract_required[call_id] != 0

    mut fn note_elided_call_node(node: i32):
        if node > 0: self.elided_call_nodes.push(node)

    mut fn note_let_binding(node: i32, alias_place: i32):
        if node <= 0: return
        self.let_binding_nodes.push(node)
        self.let_binding_aliases.push(if alias_place >= 0: 1 else: 0)
        self.let_binding_places.push(alias_place)

    mut fn note_index_place(node: i32, place: i32, base: i32):
        if node <= 0: return
        self.index_place_nodes.push(node)
        self.index_place_places.push(place)
        self.index_place_bases.push(base)

    mut fn note_field_place(node: i32, place: i32, base: i32):
        if node <= 0: return
        self.field_place_nodes.push(node)
        self.field_place_places.push(place)
        self.field_place_bases.push(base)

    mut fn set_call_may_cancel(call_id: i32):
        if call_id >= 0 and call_id < self.call_may_cancel.len():
            self.call_may_cancel[call_id] = 1

    fn call_is_may_cancel(call_id: i32) -> bool:
        call_id >= 0 and call_id < self.call_may_cancel.len() and self.call_may_cancel[call_id] != 0

    mut fn set_call_machinery_dispatch(call_id: i32):
        if call_id >= 0 and call_id < self.call_machinery_dispatch.len():
            self.call_machinery_dispatch[call_id] = 1

    fn call_is_machinery_dispatch(call_id: i32) -> bool:
        if call_id < 0 or call_id >= self.call_machinery_dispatch.len():
            return false
        self.call_machinery_dispatch[call_id] != 0

    mut fn set_call_pipeline_receiver_place(call_id: i32, place_id: i32):
        if call_id < 0 or call_id >= self.call_pipeline_receiver_places.len():
            return
        self.call_pipeline_receiver_places[call_id] = place_id

    fn call_pipeline_receiver_place(call_id: i32) -> i32:
        if call_id < 0 or call_id >= self.call_pipeline_receiver_places.len():
            return -1
        self.call_pipeline_receiver_places[call_id]

    fn call_sig_index(call_id: i32) -> i32:
        if call_id < 0 or call_id >= self.call_sig_indices.len():
            return -1
        self.call_sig_indices[call_id]

    fn call_mono_sym(call_id: i32) -> i32:
        if call_id < 0 or call_id >= self.call_mono_syms.len():
            return 0
        self.call_mono_syms[call_id]

    // ── Query helpers ────────────────────────────────────────────────

    fn local_count() -> i32:
        self.local_type_ids.len() as i32

    fn block_count() -> i32:
        self.bb_stmt_starts.len() as i32

    fn stmt_count() -> i32:
        self.stmt_kinds.len() as i32

    fn get_local(idx: i32) -> MirLocalInfo:
        if idx < 0 or idx >= self.local_type_ids.len():
            return MirLocalInfo { type_id: 0, is_mutable: 0, name_sym: 0, is_user_var: 0 }
        MirLocalInfo {
            type_id: self.local_type_ids[idx],
            is_mutable: self.local_mutables[idx],
            name_sym: self.local_names[idx],
            is_user_var: self.local_is_user_var[idx],
        }

    fn stmt_kind(idx: i32) -> i32:
        if idx < 0 or idx >= self.stmt_kinds.len():
            return StmtKind.Nop
        self.stmt_kinds[idx]

    fn stmt_data0(idx: i32) -> i32:
        if idx < 0 or idx >= self.stmt_d0.len():
            return 0
        self.stmt_d0[idx]

    fn stmt_data1(idx: i32) -> i32:
        if idx < 0 or idx >= self.stmt_d1.len():
            return 0
        self.stmt_d1[idx]

    fn term_kind(bb: i32) -> i32:
        if bb < 0 or bb >= self.bb_term_kinds.len():
            return TermKind.TK_UNREACHABLE
        self.bb_term_kinds[bb]

    fn term_data0(bb: i32) -> i32:
        if bb < 0 or bb >= self.bb_term_d0.len():
            return 0
        self.bb_term_d0[bb]

    fn term_data1(bb: i32) -> i32:
        if bb < 0 or bb >= self.bb_term_d1.len():
            return 0
        self.bb_term_d1[bb]

    fn term_data2(bb: i32) -> i32:
        if bb < 0 or bb >= self.bb_term_d2.len():
            return 0
        self.bb_term_d2[bb]

    fn term_data3(bb: i32) -> i32:
        if bb < 0 or bb >= self.bb_term_d3.len():
            return 0
        self.bb_term_d3[bb]

    fn term_no_suspend_node(bb: i32) -> i32:
        if bb < 0 or bb >= self.bb_no_suspend_nodes.len():
            return 0
        self.bb_no_suspend_nodes[bb]

// ── Deterministic dump rendering ─────────────────────────────────

fn mir_clip_text(s: &str, max_len: i32) -> str:
    if max_len <= 0:
        return ""
    if s.len() <= max_len:
        return with_str_clone_ref(s)
    if max_len <= 3:
        return s.slice(0, max_len)
    s.slice(0, max_len - 3) ++ "..."

pub fn mir_place_text(body: &MirBody, place_id: i32) -> str:
    if place_id < 0 or place_id >= body.place_locals.len():
        return "_?"

    let p_start = body.place_proj_starts[place_id]
    let p_count = body.place_proj_counts[place_id]

    // Whole-local place (the common case): reuse the memoized local key instead of
    // building a fresh "_{local}" string on every call (#614 drop-state hot path).
    if p_count == 0:
        return mir_drop_state_local_key(body.place_locals[place_id] as i32)

    var out = mir_drop_state_local_key(body.place_locals[place_id] as i32)

    for i in 0..p_count:
        let pk = body.proj_kinds[(p_start + i)]
        let pd = body.proj_d0[(p_start + i)]

        if pk == ProjKind.PK_FIELD:
            out = out ++ f".f{pd}"
            continue
        if pk == ProjKind.PK_TUPLE_INDEX:
            out = out ++ f".{pd}"
            continue
        if pk == ProjKind.PK_INDEX:
            out = out ++ f"[_{pd}]"
            continue
        if pk == ProjKind.PK_DEREF:
            out = out ++ ".*"
            continue
        if pk == ProjKind.PK_DOWNCAST:
            out = out ++ f"<as v{pd}>"
            continue

        out = out ++ f"<p{pk}:{pd}>"

    out

pub fn mir_exact_int_text(ast: &AstPool, node: i32) -> str:
    if node == 0:
        return "<exact-int>"
    let kind = ast.kind(node)
    if kind == NodeKind.NK_GROUPED or kind == NodeKind.NK_COMPTIME or kind == NodeKind.NK_CAST:
        return mir_exact_int_text(ast, ast.get_data0(node))
    if kind == NodeKind.NK_UNARY and ast.get_data0(node) == UnaryOp.UOP_NEGATE:
        return "-" ++ mir_exact_int_text(ast, ast.get_data1(node))
    if kind == NodeKind.NK_INT_LIT and ast.has_int_literal_exact(node as NodeId):
        let digits = ast.int_literal_digits(node as NodeId)
        let radix = ast.int_literal_radix(node as NodeId)
        if radix == 16:
            return "0x" ++ digits
        if radix == 8:
            return "0o" ++ digits
        if radix == 2:
            return "0b" ++ digits
        return digits
    if kind == NodeKind.NK_INT_LIT:
        return with_i64_to_str(ast.int_lit_value(node as NodeId))
    "<exact-int>"

pub enum MirDropState: i32:
    Uninit = 0
    Init = 1
    Moved = 2
    // Paths disagree and none of them moved the place out: initialized on
    // some, uninitialized on others (a match result temp whose no-arm path
    // never wrote it).
    Maybe = 3
    // Some path reaching here never touched the place at all — not even the
    // reset-on-move blank — so its memory is stack garbage there. A drop of
    // a MaybeGarbage place is the #729 class (join-block temp drop).
    MaybeGarbage = 4
    // A projection key no path has touched yet. Never printed; joins as
    // Uninit against Uninit and as MaybeGarbage against anything else.
    Absent = 5
    // Paths disagree and at least one of them moved the place out. Kept
    // apart from Maybe so a move reaching it is a use after move, while a
    // move of a Maybe place is not judged (its uninitialized paths are the
    // lowering's unreachable ones as often as real ones, #1414).
    MaybeMoved = 6
    // Blanked after a move or drop: the place holds the reset-on-move
    // sentinel and owns nothing (§2.5.1). A drop of it is the guarded no-op;
    // a move of it is a use after move; at a return it is not a leak.
    Reset = 7

// Drop-state dataflow over one body. Every place the transfer functions can
// mention is interned once per body into a dense key table (locals first, so
// a local's key id is its local id; then each distinct projected place text),
// and a state is indexed by key id. Joins, equality, copies, and marks are
// then integer loops with no string work: the string-keyed map this replaces
// cloned every key on every lookup, and the validator on the compiler went
// from 13s to 464s the moment its states were kept exact across blocks (#729
// fixpoint). Absence — a path that never touched a place — is an explicit
// state (`Absent`) rather than a missing key, with the same join rule.
//
// A state is stored in chunks of at most MIR_DROP_STATE_CHUNK keys (a body
// with fewer keys has one chunk of exactly its width), and the stored
// chunks are hash-consed in the key table's chunk store (#1343). A dense
// state per block made every body cost blocks × keys cells and blocks × keys
// work per sweep: pcre2's `match_` (41,818 blocks, 43,194 keys) needed 1.8 G
// cells, 7 GB, and never finished — and every stage1 compile reaches it,
// because a stage1 has no embedded bundles and lowers std.re from source. A
// block touches a handful of keys, so its row shares every other chunk with
// its input by id, and a join or equality test on two equal chunks is one
// id comparison.
const MIR_DROP_STATE_CHUNK = 128

pub type MirDropStateKeys {
    names: Vec[str],
    // Scope-owned values remain ownership obligations after StorageDead;
    // a block tail can transfer them immediately after that marker.
    owned_cleanup: Vec[i32],
    // Base local of each key (a local's own key has itself).
    base_local: Vec[i32],
    // Projection keys grouped by base local (CSR over local id): the
    // descendants a whole-local mark also sets.
    child_starts: Vec[i32],
    children: Vec[i32],
    // Key id of every MIR place id, so a transfer never renders place text.
    place_key: Vec[i32],
    index: HashMap[str, i32],
    // Keys per chunk, and the chunk store: chunk `id` is
    // `chunk_data[id * chunk ..]`, padded with Absent past the last key.
    // Content-hashed (`chunk_heads` maps a hash to its first id,
    // `chunk_next` chains the rest), so two stored chunks with equal content
    // always have one id.
    chunk: i32,
    chunk_data: Vec[i32],
    chunk_heads: HashMap[i64, i32],
    chunk_next: Vec[i32],
    // join_chunks memo: (a << 32 | b) → the stored join of chunks a and b.
    chunk_joins: HashMap[i64, i32],
}

impl MirDropStateKeys:
    fn len(): self.names.len() as i32

    fn chunk_count(): (self.len() + self.chunk - 1) / self.chunk

    fn find(name: &str) -> i32:
        match self.index.get(name):
            Some(id) => *id
            None => -1

    fn initial(body: &MirBody) -> MirDropStateMap:
        var own: Vec[i32] = Vec.new()
        var refs: Vec[i32] = Vec.new()
        for c in 0..self.chunk_count():
            refs.push(-(c + 1))
        for id in 0..self.chunk_count() * self.chunk:
            if id >= self.len() or id >= body.local_count():
                own.push(MirDropState.Absent)
            else if id > 0 and id <= body.n_params:
                own.push(MirDropState.Init)
            else if body.local_is_global[id] != 0:
                // A proxy addresses initialized module storage, not a fresh
                // stack slot. Replacing it must drop the existing value.
                own.push(MirDropState.Init)
            else:
                own.push(MirDropState.Uninit)
        MirDropStateMap { refs, own }

    // The id of the stored chunk equal to `src[start .. start + CHUNK]`,
    // storing it first if no stored chunk has that content.
    mut fn intern_chunk(src: &Vec[i32], start: i32) -> i32:
        var hash: i64 = 0
        for r in 0..self.chunk:
            hash = hash *% 31 +% src[start + r]
        let head = match self.chunk_heads.get(hash):
            Some(first) => *first
            None => -1
        var id = head
        while id >= 0:
            let base = id * self.chunk
            var same = true
            for r in 0..self.chunk:
                if self.chunk_data[base + r] != src[start + r]:
                    same = false
                    break
            if same:
                return id
            id = self.chunk_next[id]
        let fresh = self.chunk_next.len() as i32
        for r in 0..self.chunk:
            self.chunk_data.push(src[start + r])
        self.chunk_next.push(head)
        self.chunk_heads.insert(hash, fresh)
        fresh

    // The stored chunk that is the key-by-key join of stored chunks `a` and
    // `b` (in that order: the join is not associative, and input() folds the
    // predecessors in CSR order exactly as the dense join did). Memoized on
    // the id pair — ids are content, so the memo is exact.
    mut fn join_chunks(a: i32, b: i32) -> i32:
        if a == b:
            return a
        var pair: i64 = a
        pair = pair * 4294967296 + b
        let memo = match self.chunk_joins.get(pair):
            Some(joined) => *joined
            None => -1
        if memo >= 0:
            return memo
        var out: Vec[i32] = Vec.new()
        let a_base = a * self.chunk
        let b_base = b * self.chunk
        for k in 0..self.chunk:
            out.push(mir_drop_state_join(self.chunk_data[a_base + k], self.chunk_data[b_base + k]))
        let joined = self.intern_chunk(out, 0)
        self.chunk_joins.insert(pair, joined)
        joined

pub fn mir_drop_state_keys_new(body: &MirBody) -> MirDropStateKeys:
    var names: Vec[str] = Vec.new()
    var base_local: Vec[i32] = Vec.new()
    var index: HashMap[str, i32] = HashMap.new()
    let local_count = body.local_count()
    var owned_cleanup: Vec[i32] = Vec.new()
    for li in 0..local_count:
        let name = mir_drop_state_local_key(li)
        index.insert(name ++ "", li)
        names.push(name)
        base_local.push(li)
        owned_cleanup.push(0)
    for li in body.owned_cleanup_locals:
        if li >= 0 and li < local_count:
            owned_cleanup[li] = 1
    var place_key: Vec[i32] = Vec.new()
    for p in 0..body.place_locals.len() as i32:
        let base: i32 = body.place_locals[p]
        if body.place_proj_counts[p] == 0:
            place_key.push(base)
            continue
        let text = mir_place_text(body, p)
        var id = match index.get(text):
            Some(found) => *found
            None => -1
        if id < 0:
            id = names.len() as i32
            index.insert(text ++ "", id)
            names.push(text)
            base_local.push(base)
        place_key.push(id)
    var child_counts: Vec[i32] = Vec.new()
    for _ in 0..local_count:
        child_counts.push(0)
    for id in local_count..names.len() as i32:
        let base: i32 = base_local[id]
        child_counts[base] = child_counts[base] + 1
    var child_starts: Vec[i32] = Vec.new()
    var fill: Vec[i32] = Vec.new()
    var total = 0
    for li in 0..local_count:
        child_starts.push(total)
        fill.push(total)
        total = total + child_counts[li]
    child_starts.push(total)
    var children: Vec[i32] = Vec.new()
    for _ in 0..total:
        children.push(0)
    for id in local_count..names.len() as i32:
        let base: i32 = base_local[id]
        let slot: i32 = fill[base]
        children[slot] = id
        fill[base] = slot + 1
    let key_count = names.len() as i32
    let chunk = if key_count >= MIR_DROP_STATE_CHUNK: MIR_DROP_STATE_CHUNK else if key_count > 0: key_count else: 1
    MirDropStateKeys { names, owned_cleanup, base_local, child_starts, children, place_key, index, chunk, chunk_data: Vec.new(), chunk_heads: HashMap.new(), chunk_next: Vec.new(), chunk_joins: HashMap.new() }

// One chunk ref per chunk of keys: `id >= 0` is a stored chunk of the key
// table, `-(slot + 1)` a chunk private to this map in `own`. The first write
// that changes a stored chunk copies it into `own`; storing the map interns
// its private chunks back.
type MirDropStateMap {
    refs: Vec[i32],
    own: Vec[i32],
}

fn mir_drop_state_join(a: i32, b: i32) -> i32:
    if a == b:
        return a
    // A blanked place beside a live one is the live one: the drop glue frees
    // nothing on the blanked path, so the join drops and moves as the live
    // path does. Beside a moved one the moved path is the unsafe one
    // (MaybeMoved); beside untouched memory the sentinel is not there
    // (MaybeGarbage).
    if a == MirDropState.Reset or b == MirDropState.Reset:
        let other = if a == MirDropState.Reset: b else: a
        if other == MirDropState.Init or other == MirDropState.Maybe:
            return other
        if other == MirDropState.Moved or other == MirDropState.MaybeMoved:
            return MirDropState.MaybeMoved
        return MirDropState.MaybeGarbage
    // A place one path never touched: joining with Uninit is still Uninit
    // (nothing to drop either way); joining with anything else is garbage on
    // the untouched path.
    if a == MirDropState.Absent:
        return if b == MirDropState.Uninit: MirDropState.Uninit else: MirDropState.MaybeGarbage
    if b == MirDropState.Absent:
        return if a == MirDropState.Uninit: MirDropState.Uninit else: MirDropState.MaybeGarbage
    if a == MirDropState.MaybeGarbage or b == MirDropState.MaybeGarbage:
        return MirDropState.MaybeGarbage
    if a == MirDropState.Moved or a == MirDropState.MaybeMoved or b == MirDropState.Moved or b == MirDropState.MaybeMoved:
        return MirDropState.MaybeMoved
    MirDropState.Maybe

impl MirDropStateMap:
    // The state of key `id`.
    fn get(keys: &MirDropStateKeys, id: i32) -> i32:
        let r: i32 = self.refs[id / keys.chunk]
        let offset = id % keys.chunk
        if r >= 0: keys.chunk_data[r * keys.chunk + offset] else: self.own[(-r - 1) * keys.chunk + offset]

    // Chunk `c` as a private chunk (copied out of the store on first use);
    // returns the offset of its first key in `own`.
    mut fn own_chunk(keys: &MirDropStateKeys, c: i32) -> i32:
        let r: i32 = self.refs[c]
        if r < 0:
            return (-r - 1) * keys.chunk
        let slot = self.own.len() as i32 / keys.chunk
        let base = r * keys.chunk
        for k in 0..keys.chunk:
            self.own.push(keys.chunk_data[base + k])
        self.refs[c] = -(slot + 1)
        slot * keys.chunk

    mut fn set(keys: &MirDropStateKeys, id: i32, state: i32):
        if self.get(keys, id) == state:
            return
        let start = self.own_chunk(keys, id / keys.chunk)
        self.own[start + id % keys.chunk] = state

    // The state of a MIR place; a never-touched projection reads as Uninit,
    // as a missing key did before.
    fn place(keys: &MirDropStateKeys, place_id: i32) -> i32:
        if place_id < 0 or place_id >= keys.place_key.len():
            return MirDropState.Uninit
        let state = self.get(keys, keys.place_key[place_id])
        if state == MirDropState.Absent: MirDropState.Uninit else: state

    fn key(keys: &MirDropStateKeys, name: &str) -> i32:
        let id = keys.find(name)
        if id < 0:
            return MirDropState.Uninit
        let state = self.get(keys, id)
        if state == MirDropState.Absent: MirDropState.Uninit else: state

    mut fn mark_local(keys: &MirDropStateKeys, local_id: i32, state: i32):
        if local_id < 0 or local_id >= keys.child_starts.len() - 1:
            return
        self.set(keys, local_id, state)
        let start: i32 = keys.child_starts[local_id]
        let end: i32 = keys.child_starts[local_id + 1]
        for i in start..end:
            self.set(keys, keys.children[i], state)

    mut fn mark_place(keys: &MirDropStateKeys, body: &MirBody, place_id: i32, state: i32) -> Unit:
        if place_id < 0 or place_id >= keys.place_key.len():
            return
        let id: i32 = keys.place_key[place_id]
        self.set(keys, id, state)
        let base: i32 = keys.base_local[id]
        // A move out of a sub-place vacates only that sub-place: the whole
        // value is still there and its drop still runs over it, so the base
        // keeps its state. Joining Moved into the base made a partial move
        // read as a conditional whole move (`_4=Maybe`), and the vacated
        // payload a whole-enum drop freed again read as the same Maybe as
        // its parent (#1394). A sub-place drop (Uninit) is the same: the
        // drop-before-overwrite of a field (`drop(_4.f); _4.f = move _6`)
        // leaves the whole value there, and joining Uninit into the base
        // made it Maybe — "holds no value on a path" (#1559) for a struct
        // that holds one on every path. The dropped field stays Uninit in
        // its own key, which the vacated-sub-place rule reads.
        if body.place_proj_counts[place_id] == 0:
            self.mark_local(keys, base, state)
        else if state != MirDropState.Moved and state != MirDropState.Uninit:
            self.set(keys, base, mir_drop_state_join(self.get(keys, base), state))

    mut fn note_operand(keys: &MirDropStateKeys, body: &MirBody, operand_id: i32):
        if operand_id < 0 or operand_id >= body.operand_kinds.len():
            return
        if body.operand_kinds[operand_id] != OperandKind.OK_MOVE:
            return
        self.mark_place(keys, body, body.operand_d0[operand_id], MirDropState.Moved)

    mut fn note_call_args(keys: &MirDropStateKeys, body: &MirBody, args_id: i32):
        if args_id < 0 or args_id >= body.call_arg_starts.len():
            return
        let start: i32 = body.call_arg_starts[args_id]
        let count: i32 = body.call_arg_counts[args_id]
        for i in 0..count:
            self.note_operand(keys, body, body.call_arg_operands[start + i])

    mut fn note_agg_fields(keys: &MirDropStateKeys, body: &MirBody, fields_id: i32):
        if fields_id < 0 or fields_id >= body.agg_field_starts.len():
            return
        let start: i32 = body.agg_field_starts[fields_id]
        let count: i32 = body.agg_field_counts[fields_id]
        for i in 0..count:
            self.note_operand(keys, body, body.agg_field_operands[start + i])

    mut fn note_rvalue(keys: &MirDropStateKeys, body: &MirBody, rval_id: i32):
        if rval_id < 0 or rval_id >= body.rval_kinds.len():
            return
        let kind: i32 = body.rval_kinds[rval_id]
        let d0: i32 = body.rval_d0[rval_id]
        let d1: i32 = body.rval_d1[rval_id]
        let d2: i32 = body.rval_d2[rval_id]
        if kind == RvalueKind.RK_USE:
            self.note_operand(keys, body, d0)
        else if kind == RvalueKind.RK_BIN_OP:
            self.note_operand(keys, body, d1)
            self.note_operand(keys, body, d2)
        else if kind == RvalueKind.RK_UN_OP:
            self.note_operand(keys, body, d1)
        else if kind == RvalueKind.RK_CAST:
            self.note_operand(keys, body, d0)
        else if kind == RvalueKind.RK_AGGREGATE:
            self.note_agg_fields(keys, body, d1)
        else if kind == RvalueKind.RK_STR_CONCAT_N:
            self.note_call_args(keys, body, d0)
        else if kind == RvalueKind.RK_SLICE:
            self.note_operand(keys, body, d1)
            self.note_operand(keys, body, d2)

    mut fn transfer_stmt(keys: &MirDropStateKeys, body: &MirBody, stmt_id: i32):
        let kind = body.stmt_kind(stmt_id)
        let d0 = body.stmt_data0(stmt_id)
        let d1 = body.stmt_data1(stmt_id)
        if kind == StmtKind.StorageLive:
            // Parameters contain the caller's value. A nonzero d1 explicitly
            // initializes ordinary storage to zero in both backends.
            let initial = if d1 != 0 or (d0 > 0 and d0 <= body.n_params): MirDropState.Init else: MirDropState.Uninit
            self.mark_local(keys, d0, initial)
        else if kind == StmtKind.StorageDead:
            // Ending a storage scope cannot discharge an owned value. Keep
            // tracking it until an explicit move or drop, including the tail
            // move that lowering can emit after the scope's marker (#1944).
            if d0 < 0 or d0 >= keys.owned_cleanup.len() or keys.owned_cleanup[d0] == 0:
                self.mark_local(keys, d0, MirDropState.Uninit)
        else if kind == StmtKind.Assign:
            self.note_rvalue(keys, body, d1)
            // The reset-on-move blank (`x = const zst(T)`) stores the sentinel,
            // not a value: a moved or dropped place becomes Reset; reading the
            // blank as re-initialization made every moved-out local `Init` at
            // the return and hid the leaks from the validator (#1384, #1488).
            // Every lowering site blanks a place it has moved from, some after
            // its StorageDead (`_11 = agg(move _4); StorageDead(_4); _4 = zst`),
            // so an Uninit place blanks to Reset too.
            if mir_rvalue_is_zero_fill(body, d1) != 0 and self.place(keys, d0) != MirDropState.Init:
                self.mark_place(keys, body, d0, MirDropState.Reset)
            else:
                self.mark_place(keys, body, d0, MirDropState.Init)
        else if kind == StmtKind.Drop:
            self.mark_place(keys, body, d0, MirDropState.Uninit)

    mut fn transfer_term(keys: &MirDropStateKeys, body: &MirBody, bb: i32):
        let kind = body.term_kind(bb)
        let d0 = body.term_data0(bb)
        let d1 = body.term_data1(bb)
        let d2 = body.term_data2(bb)
        if kind == TermKind.TK_SWITCH_INT:
            self.note_operand(keys, body, d0)
        else if kind == TermKind.TK_CALL:
            self.note_operand(keys, body, d0)
            self.note_call_args(keys, body, d1)
            self.mark_place(keys, body, d2, MirDropState.Init)
        else if kind == TermKind.TK_DROP_AND_GOTO:
            self.mark_place(keys, body, d0, MirDropState.Uninit)

    // Every present key as `name=State`, capped like the old dump.
    fn format(keys: &MirDropStateKeys) -> str:
        var present = 0
        for i in 0..keys.len():
            if self.get(keys, i) != MirDropState.Absent:
                present = present + 1
        var out = ""
        var emitted = 0
        for i in 0..keys.len():
            let state = self.get(keys, i)
            if state == MirDropState.Absent:
                continue
            if emitted > 0:
                out = out ++ ", "
            out = out ++ keys.names[i] ++ "=" ++ mir_drop_state_name(state)
            emitted = emitted + 1
            if emitted >= 96 and present > emitted:
                out = out ++ ", ..."
                break
        if out.len() == 0:
            return "<empty>"
        out

    fn selected_format(keys: &MirDropStateKeys, target: &str) -> str:
        if target.len() == 0:
            return self.format(keys)
        var out = ""
        var emitted = 0
        for i in 0..keys.len():
            let state = self.get(keys, i)
            if state == MirDropState.Absent:
                continue
            if not mir_ownership_key_matches(keys.names[i], target):
                continue
            if emitted > 0:
                out = out ++ ", "
            out = out ++ keys.names[i] ++ "=" ++ mir_drop_state_name(state)
            emitted = emitted + 1
        if emitted == 0:
            return target ++ "=" ++ mir_drop_state_name(MirDropState.Uninit)
        out

pub fn mir_drop_state_name(state: i32) -> str:
    if state == MirDropState.Init:
        return "Init"
    if state == MirDropState.Moved:
        return "Moved"
    if state == MirDropState.Maybe:
        return "Maybe"
    if state == MirDropState.MaybeMoved:
        return "MaybeMoved"
    if state == MirDropState.Reset:
        return "Reset"
    if state == MirDropState.MaybeGarbage:
        return "MaybeGarbage"
    if state == MirDropState.Absent:
        return "Absent"
    "Uninit"

// Memoized: "_{local_id}" is a pure function of local_id (body-independent), so
// cache it globally to avoid reconstructing the same key string on every body.
// Pure memo of a deterministic function → no effect on compiler output/fixpoint.
var mir_local_key_cache: Vec[str] = Vec.new()
var mir_local_key_cache_lock: Atomic[i32]

pub fn mir_drop_state_local_key(local_id: i32) -> str:
    if local_id < 0:
        return f"_{local_id}"
    // Comptime parallel() lowers MIR on concurrent threads that share this global
    // cache; an unguarded push races vec_grow (double free of the old buffer,
    // #617), and a get during another thread's grow reads a freed buffer, so the
    // lock must bracket both. The returned str stays valid across grows — the Vec
    // buffer holds handles, not the string bytes.
    while mir_local_key_cache_lock.swap(1, .Acquire) != 0:
        let _ = 0
    while mir_local_key_cache.len() <= local_id:
        let n = mir_local_key_cache.len() as i32
        mir_local_key_cache.push(f"_{n}")
    let key = mir_local_key_cache[local_id] ++ ""
    mir_local_key_cache_lock.store(0, .Release)
    key

fn mir_drop_state_key_is_descendant(key: &str, local_key: &str) -> bool:
    if key == local_key:
        return true
    if not key.starts_with(local_key):
        return false
    if key.len() <= local_key.len():
        return false
    let ch = key[local_key.len()]
    ch == '.' or ch == '[' or ch == '<'

// A literal switch has one executable edge. In particular, the exit edge
// of `while true` cannot carry an ownership obligation to a return (#1944).
fn mir_drop_state_constant_switch_target(body: &MirBody, bb: i32) -> i32:
    if body.term_kind(bb) != TermKind.TK_SWITCH_INT:
        return -1
    let operand = body.term_data0(bb)
    if operand < 0 or operand >= body.operand_kinds.len() or body.operand_kinds[operand] != OperandKind.OK_CONSTANT:
        return -1
    let cid = body.operand_d0[operand]
    if cid < 0 or cid >= body.const_kinds.len():
        return -1
    let kind = body.const_kinds[cid]
    if kind != ConstKind.CK_BOOL and kind != ConstKind.CK_INT:
        return -1
    let value = if kind == ConstKind.CK_BOOL: body.const_d0[cid] as i64 else: mir_const_int_value(body, cid)
    let table = body.term_data1(bb)
    if table >= 0 and table < body.switch_table_starts.len():
        let start: i32 = body.switch_table_starts[table]
        let count: i32 = body.switch_table_counts[table]
        for i in 0..count:
            if body.switch_table_vals[start + i] == value:
                return body.switch_table_targets[start + i]
    body.term_data2(bb)

pub fn mir_drop_state_block_has_successor(body: &MirBody, pred: i32, target: i32) -> bool:
    let kind = body.term_kind(pred)
    let d0 = body.term_data0(pred)
    let d1 = body.term_data1(pred)
    let d2 = body.term_data2(pred)
    let d3 = body.term_data3(pred)
    if kind == TermKind.TK_GOTO:
        return d0 == target
    if kind == TermKind.TK_SWITCH_INT:
        let chosen = mir_drop_state_constant_switch_target(body, pred)
        if chosen >= 0:
            return chosen == target
        if d2 == target:
            return true
        if d1 >= 0 and d1 < body.switch_table_starts.len():
            let start: i32 = body.switch_table_starts[d1]
            let count: i32 = body.switch_table_counts[d1]
            for i in 0..count:
                if body.switch_table_targets[start + i] == target:
                    return true
        return false
    if kind == TermKind.TK_CALL:
        return d3 == target
    if kind == TermKind.TK_DROP_AND_GOTO:
        return d1 == target
    false

// The successors a terminator can transfer to, in the same order
// mir_drop_state_block_has_successor recognizes them.
fn mir_drop_state_block_successors(body: &MirBody, bb: i32) -> Vec[i32]:
    var out: Vec[i32] = Vec.new()
    let kind = body.term_kind(bb)
    let d0 = body.term_data0(bb)
    let d1 = body.term_data1(bb)
    let d2 = body.term_data2(bb)
    let d3 = body.term_data3(bb)
    if kind == TermKind.TK_GOTO:
        out.push(d0)
    else if kind == TermKind.TK_SWITCH_INT:
        let chosen = mir_drop_state_constant_switch_target(body, bb)
        if chosen >= 0:
            out.push(chosen)
            return out
        if d1 >= 0 and d1 < body.switch_table_starts.len():
            let start: i32 = body.switch_table_starts[d1]
            let count: i32 = body.switch_table_counts[d1]
            for i in 0..count:
                out.push(body.switch_table_targets[start + i])
        out.push(d2)
    else if kind == TermKind.TK_CALL:
        out.push(d3)
    else if kind == TermKind.TK_DROP_AND_GOTO:
        out.push(d1)
    out

// Per-body dataflow storage: the key table (with its chunk store), one
// out-state row per block (`rows` is blocks × chunks of stored chunk ids,
// rewritten in place on every store), and the CFG in CSR form so a block's
// predecessors are a slice, not a terminator scan.
pub type MirDropStateBlocks {
    keys: MirDropStateKeys,
    rows: Vec[i32],
    // The entry state's stored chunk ids (keys.initial, interned once: an
    // unreachable block reads it too, and rebuilding it per read cost a
    // full key-width pass each time).
    entry: Vec[i32],
    // The state being computed: load_input fills it in place, so a visit
    // allocates only the chunks its statements change.
    scratch: MirDropStateMap,
    // 1 once a block's out-state has been stored at least once. A predecessor
    // that has never been computed contributes nothing to a join (it is not
    // "all Uninit" — that was the single-pass driver's blind spot: a join block
    // numbered before its arm blocks, as lower_match allocates them, saw no
    // computed predecessor and took the entry state instead).
    computed: Vec[i32],
    pred_starts: Vec[i32],
    preds: Vec[i32],
    succ_starts: Vec[i32],
    succs: Vec[i32],
}

impl MirDropStateBlocks:
    fn width(): self.keys.chunk_count()

    // The stored out-state of `bb`, sharing the stored chunks.
    fn load_block(bb: i32) -> MirDropStateMap:
        var refs: Vec[i32] = Vec.new()
        let base = bb * self.width()
        for c in 0..self.width():
            refs.push(self.rows[base + c])
        MirDropStateMap { refs, own: Vec.new() }

    // Whether `bb` has an input this sweep: the entry block always does; any
    // other block needs at least one computed predecessor. Feeding an
    // uncomputed block the entry state instead is not a bottom element of this
    // lattice (Uninit and Init are siblings under Maybe), and a loop seeded
    // that way oscillates forever instead of climbing to its fixpoint.
    fn has_input(bb: i32) -> bool:
        if bb == 0:
            return true
        let start: i32 = self.pred_starts[bb]
        let end: i32 = self.pred_starts[bb + 1]
        for i in start..end:
            if self.computed[self.preds[i]] != 0:
                return true
        false

    // Load `scratch` with the input of `bb`: the join of every computed
    // predecessor's out-state — not just the lower-numbered ones: a join
    // block is often numbered before the arms that feed it (lower_match, the
    // loop back-edge). A predecessor not computed yet contributes nothing;
    // the fixpoint driver revisits once it is. The entry block, and a block
    // with no computed predecessor, takes the entry state.
    mut fn load_input(bb: i32):
        self.scratch.own.clear()
        let width = self.width()
        var seen = false
        if bb != 0:
            let start: i32 = self.pred_starts[bb]
            let end: i32 = self.pred_starts[bb + 1]
            for i in start..end:
                let pred: i32 = self.preds[i]
                if self.computed[pred] == 0:
                    continue
                let base = pred * width
                if not seen:
                    for c in 0..width:
                        self.scratch.refs[c] = self.rows[base + c]
                    seen = true
                else:
                    for c in 0..width:
                        self.scratch.refs[c] = self.keys.join_chunks(self.scratch.refs[c], self.rows[base + c])
        if not seen:
            for c in 0..width:
                self.scratch.refs[c] = self.entry[c]

    // The input state of `bb` (see load_input), sharing the stored chunks.
    mut fn input(bb: i32) -> MirDropStateMap:
        self.load_input(bb)
        MirDropStateMap { refs: self.scratch.refs.clone(), own: Vec.new() }

    // Recompute the out-state of `bb` in `scratch`; store it and return true
    // when it differs from the stored one (or none was stored yet).
    mut fn visit(body: &MirBody, bb: i32) -> bool:
        self.load_input(bb)
        let stmt_start: i32 = body.bb_stmt_starts[bb]
        let stmt_count: i32 = body.bb_stmt_counts[bb]
        for si in 0..stmt_count:
            self.scratch.transfer_stmt(self.keys, body, stmt_start + si)
        self.scratch.transfer_term(self.keys, body, bb)
        if self.computed[bb] != 0 and self.scratch_is_stored(bb):
            return false
        self.computed[bb] = 1
        let base = bb * self.width()
        for c in 0..self.width():
            let r: i32 = self.scratch.refs[c]
            self.rows[base + c] = if r >= 0: r else: self.keys.intern_chunk(self.scratch.own, (-r - 1) * self.keys.chunk)
        true

    // Whether the stored out-state of `bb` equals `scratch`.
    fn scratch_is_stored(bb: i32) -> bool:
        let base = bb * self.width()
        for c in 0..self.width():
            let r: i32 = self.scratch.refs[c]
            let stored: i32 = self.rows[base + c]
            if r == stored:
                continue
            // Stored chunks are hash-consed: two different stored ids differ.
            if r >= 0:
                return false
            let own = (-r - 1) * self.keys.chunk
            let data = stored * self.keys.chunk
            for k in 0..self.keys.chunk:
                if self.scratch.own[own + k] != self.keys.chunk_data[data + k]:
                    return false
        true

fn mir_drop_state_blocks_new(body: &MirBody) -> MirDropStateBlocks:
    let bb_count = body.block_count()
    var keys = mir_drop_state_keys_new(body)
    var absent: Vec[i32] = Vec.new()
    for _ in 0..keys.chunk:
        absent.push(MirDropState.Absent)
    let absent_id = keys.intern_chunk(absent, 0)
    var rows: Vec[i32] = Vec.new()
    for _ in 0..bb_count * keys.chunk_count():
        rows.push(absent_id)
    let initial = keys.initial(body)
    var entry: Vec[i32] = Vec.new()
    for c in 0..keys.chunk_count():
        entry.push(keys.intern_chunk(initial.own, c * keys.chunk))
    var computed: Vec[i32] = Vec.new()
    var pred_counts: Vec[i32] = Vec.new()
    for _ in 0..bb_count:
        computed.push(0)
        pred_counts.push(0)
    // Successor CSR straight from the terminators; predecessor CSR by counting
    // then filling (two passes, O(blocks + edges)).
    var succ_starts: Vec[i32] = Vec.new()
    var succs: Vec[i32] = Vec.new()
    for bb in 0..bb_count:
        succ_starts.push(succs.len() as i32)
        let targets = mir_drop_state_block_successors(body, bb)
        for i in 0..targets.len():
            let s: i32 = targets[i]
            if s >= 0 and s < bb_count:
                succs.push(s)
                pred_counts[s] = pred_counts[s] + 1
    succ_starts.push(succs.len() as i32)
    var pred_starts: Vec[i32] = Vec.new()
    var fill: Vec[i32] = Vec.new()
    var total = 0
    for bb in 0..bb_count:
        pred_starts.push(total)
        fill.push(total)
        total = total + pred_counts[bb]
    pred_starts.push(total)
    var preds: Vec[i32] = Vec.new()
    for _ in 0..total:
        preds.push(0)
    for bb in 0..bb_count:
        let start: i32 = succ_starts[bb]
        let end: i32 = succ_starts[bb + 1]
        for i in start..end:
            let s: i32 = succs[i]
            let slot: i32 = fill[s]
            preds[slot] = bb
            fill[s] = slot + 1
    let scratch = MirDropStateMap { refs: entry.clone(), own: Vec.new() }
    MirDropStateBlocks { keys, rows, entry, scratch, computed, pred_starts, preds, succ_starts, succs }

// Every block's out-state at the dataflow fixpoint. One sweep in block order is
// not enough: a block's input joins ALL its predecessors, some of which are
// numbered after it (match arms feeding an earlier join block, loop back
// edges), so sweeps repeat until no stored out-state changes. The lattice is
// finite (each place climbs Uninit/Init/Moved → Maybe → MaybeGarbage at most
// twice), so the bound below is never reached by a converging body; hitting it
// is a driver bug and fails loudly rather than returning a partial answer.
pub fn mir_drop_state_sweep_bound(local_count: i32, block_count: i32) -> i64:
    3 * (local_count as i64 + 1) * (block_count as i64 + 1) + 2

pub fn mir_drop_state_compute_blocks(body: &MirBody) -> MirDropStateBlocks:
    let bb_count = body.block_count()
    var blocks = mir_drop_state_blocks_new(body)
    let sweep_bound = mir_drop_state_sweep_bound(body.local_count(), bb_count)
    // Worklist as a dirty flag per block: a block is recomputed only when one
    // of its predecessors changed (or on the first sweep), so a loop-free body
    // costs one pass plus the blocks that were numbered before their
    // predecessors — not a whole extra sweep of every block.
    var dirty: Vec[i32] = Vec.new()
    for _ in 0..bb_count:
        dirty.push(1)
    var sweeps: i64 = 0
    var changed = true
    while changed:
        changed = false
        sweeps = sweeps + 1
        if sweeps > sweep_bound:
            panic(f"mir drop-state dataflow did not converge for sym{body.fn_sym} after {sweeps} sweeps")
        for bb in 0..bb_count:
            if dirty[bb] == 0:
                continue
            dirty[bb] = 0
            // No computed predecessor yet (or unreachable): nothing to
            // propagate; the predecessor that eventually computes marks this
            // block dirty again through its successor list.
            if not blocks.has_input(bb):
                continue
            if not blocks.visit(body, bb):
                continue
            changed = true
            let s_start: i32 = blocks.succ_starts[bb]
            let s_end: i32 = blocks.succ_starts[bb + 1]
            for i in s_start..s_end:
                dirty[blocks.succs[i]] = 1
    blocks

pub fn dump_drop_state_body(body: &MirBody, pool: &InternPool) -> str:
    var out = StringBuilder.new()
    let fn_name = if body.fn_sym != 0:
        f"sym{body.fn_sym}({pool.resolve(body.fn_sym)})"
    else:
        "<anon>"
    out.push_str("fn " ++ fn_name ++ " " ++ lbrace() ++ "\n")
    var blocks = mir_drop_state_compute_blocks(body)
    for bb in 0..body.block_count():
        var state = blocks.input(bb)
        out.push_str(f"  bb{bb} in: " ++ state.format(blocks.keys) ++ "\n")
        let stmt_start: i32 = body.bb_stmt_starts[bb]
        let stmt_count: i32 = body.bb_stmt_counts[bb]
        for si in 0..stmt_count:
            state.transfer_stmt(blocks.keys, body, stmt_start + si)
        state.transfer_term(blocks.keys, body, bb)
        out.push_str(f"  bb{bb} out: " ++ state.format(blocks.keys) ++ "\n")
    out.push_str(rbrace() ++ "\n")
    out.to_str()

fn mir_ownership_key_matches(key: &str, target: &str) -> bool:
    if target.len() == 0:
        return true
    if key == target:
        return true
    mir_drop_state_key_is_descendant(key, target)

fn mir_ownership_place_matches(body: &MirBody, place_id: i32, target: &str) -> bool:
    if target.len() == 0:
        return true
    mir_ownership_key_matches(mir_place_text(body, place_id), target)

fn mir_ownership_operand_move_matches(body: &MirBody, operand_id: i32, target: &str) -> bool:
    if operand_id < 0 or operand_id >= body.operand_kinds.len():
        return false
    if body.operand_kinds[operand_id] != OperandKind.OK_MOVE:
        return false
    mir_ownership_place_matches(body, body.operand_d0[operand_id], target)

fn mir_ownership_call_args_move_matches(body: &MirBody, args_id: i32, target: &str) -> bool:
    if args_id < 0 or args_id >= body.call_arg_starts.len():
        return false
    let start = body.call_arg_starts[args_id]
    let count = body.call_arg_counts[args_id]
    for i in 0..count:
        if mir_ownership_operand_move_matches(body, body.call_arg_operands[(start + i)], target):
            return true
    false

fn mir_ownership_agg_fields_move_matches(body: &MirBody, fields_id: i32, target: &str) -> bool:
    if fields_id < 0 or fields_id >= body.agg_field_starts.len():
        return false
    let start = body.agg_field_starts[fields_id]
    let count = body.agg_field_counts[fields_id]
    for i in 0..count:
        if mir_ownership_operand_move_matches(body, body.agg_field_operands[(start + i)], target):
            return true
    false

fn mir_ownership_rvalue_move_matches(body: &MirBody, rval_id: i32, target: &str) -> bool:
    if rval_id < 0 or rval_id >= body.rval_kinds.len():
        return false
    let kind = body.rval_kinds[rval_id]
    let d0 = body.rval_d0[rval_id]
    let d1 = body.rval_d1[rval_id]
    let d2 = body.rval_d2[rval_id]
    if kind == RvalueKind.RK_USE:
        return mir_ownership_operand_move_matches(body, d0, target)
    if kind == RvalueKind.RK_BIN_OP:
        return mir_ownership_operand_move_matches(body, d1, target) or mir_ownership_operand_move_matches(body, d2, target)
    if kind == RvalueKind.RK_UN_OP:
        return mir_ownership_operand_move_matches(body, d1, target)
    if kind == RvalueKind.RK_CAST:
        return mir_ownership_operand_move_matches(body, d0, target)
    if kind == RvalueKind.RK_AGGREGATE:
        return mir_ownership_agg_fields_move_matches(body, d1, target)
    if kind == RvalueKind.RK_STR_CONCAT_N:
        return mir_ownership_call_args_move_matches(body, d0, target)
    if kind == RvalueKind.RK_SLICE:
        return mir_ownership_operand_move_matches(body, d1, target) or mir_ownership_operand_move_matches(body, d2, target)
    false

pub fn mir_ownership_stmt_event(body: &MirBody, stmt_id: i32, target: &str) -> str:
    let kind = body.stmt_kind(stmt_id)
    if kind == StmtKind.Assign:
        if mir_ownership_rvalue_move_matches(body, body.stmt_data1(stmt_id), target):
            return "move"
        return "assign"
    if kind == StmtKind.StorageLive:
        return "storage-live"
    if kind == StmtKind.StorageDead:
        return "storage-dead"
    if kind == StmtKind.Drop:
        return "drop"
    "nop"

pub fn mir_ownership_term_event(body: &MirBody, bb: i32, target: &str) -> str:
    let kind = body.term_kind(bb)
    if kind == TermKind.TK_CALL:
        if mir_ownership_operand_move_matches(body, body.term_data0(bb), target) or mir_ownership_call_args_move_matches(body, body.term_data1(bb), target):
            return "move"
        return "call"
    if kind == TermKind.TK_DROP_AND_GOTO:
        return "drop"
    if kind == TermKind.TK_SWITCH_INT:
        if mir_ownership_operand_move_matches(body, body.term_data0(bb), target):
            return "move"
        return "switch"
    if kind == TermKind.TK_RETURN:
        return "return"
    if kind == TermKind.TK_GOTO:
        return "goto"
    "term"

pub fn mir_drop_plan_action(state: i32) -> str:
    if state == MirDropState.Init:
        return "drop"
    if state == MirDropState.Maybe or state == MirDropState.MaybeMoved:
        return "conditional"
    if state == MirDropState.Moved:
        return "skip"
    "invalid"

pub fn mir_elaborate_dead_drops(body: MirBody) -> MirBody:
    // Cheap pre-scan: a body with no Drop statements has nothing to elaborate, so
    // skip the dataflow entirely (#614 perf — avoids the per-body walk for the
    // overwhelming majority of functions, which have no drops).
    var has_drop = false
    var pre = 0
    while pre < body.stmt_kinds.len():
        if body.stmt_kinds[pre] == StmtKind.Drop:
            has_drop = true
            break
        pre = pre + 1
    if not has_drop:
        return body
    var to_nop: Vec[i32] = Vec.new()
    var blocks = mir_drop_state_compute_blocks(body)
    for bb in 0..body.block_count():
        var state = blocks.input(bb)
        let stmt_start = body.bb_stmt_starts[bb]
        let stmt_count = body.bb_stmt_counts[bb]
        for si in 0..stmt_count:
            let stmt_id = stmt_start + si
            if body.stmt_kind(stmt_id) == StmtKind.Drop:
                if state.place(blocks.keys, body.stmt_data0(stmt_id)) == MirDropState.Moved:
                    to_nop.push(stmt_id)
            state.transfer_stmt(blocks.keys, &body, stmt_id)
        state.transfer_term(blocks.keys, &body, bb)
    for i in 0..to_nop.len():
        body.stmt_kinds[to_nop[i]] = StmtKind.Nop
    body

fn mir_projection_debug_name(mir_mod: &MirModule, current_ty: i32, proj_kind: i32, proj_data: i32) -> str:
    if proj_kind == ProjKind.PK_TUPLE_INDEX:
        return f"TupleIndex({proj_data})"
    if proj_kind == ProjKind.PK_FIELD:
        let resolved = mir_mod.mir_resolve_alias(current_ty)
        if mir_mod.mir_get_type_kind(resolved) == TypeKind.TY_TUPLE:
            return f"TupleIndex({proj_data})"
        return f"Field({proj_data})"
    if proj_kind == ProjKind.PK_INDEX:
        return f"Index(_{proj_data})"
    if proj_kind == ProjKind.PK_DEREF:
        return "Deref"
    if proj_kind == ProjKind.PK_DOWNCAST:
        return f"Downcast({proj_data})"
    f"Projection({proj_kind},{proj_data})"

fn mir_projection_next_type(mir_mod: &MirModule, current_ty: i32, proj_kind: i32, proj_data: i32) -> i32:
    let resolved = mir_mod.mir_resolve_alias(current_ty)
    if proj_kind == ProjKind.PK_TUPLE_INDEX:
        return mir_validate_tuple_elem_type(mir_mod, resolved, proj_data)
    if proj_kind == ProjKind.PK_FIELD:
        if mir_mod.mir_get_type_kind(resolved) == TypeKind.TY_TUPLE:
            return mir_validate_tuple_elem_type(mir_mod, resolved, proj_data)
        return mir_validate_struct_field_type(mir_mod, resolved, proj_data)
    if proj_kind == ProjKind.PK_INDEX:
        return mir_validate_indexed_element_type(mir_mod, resolved)
    if proj_kind == ProjKind.PK_DEREF:
        if mir_mod.mir_get_type_kind(resolved) == TypeKind.TY_PTR or mir_mod.mir_get_type_kind(resolved) == TypeKind.TY_REF:
            return mir_mod.mir_get_type_d0(resolved)
    if proj_kind == ProjKind.PK_DOWNCAST:
        return current_ty
    0

fn mir_place_projection_debug_list(mir_mod: &MirModule, body: &MirBody, place_id: i32) -> str:
    if place_id < 0 or place_id >= body.place_locals.len():
        return "[]"
    var out = "["
    let p_start = body.place_proj_starts[place_id]
    let p_count = body.place_proj_counts[place_id]
    let local_id = body.place_locals[place_id]
    var current_ty = if local_id >= 0 and local_id < body.local_type_ids.len(): body.local_type_ids[local_id] else: 0
    for i in 0..p_count:
        if i > 0:
            out = out ++ ", "
        let pk = body.proj_kinds[(p_start + i)]
        let pd = body.proj_d0[(p_start + i)]
        out = out ++ mir_projection_debug_name(mir_mod, current_ty, pk, pd)
        current_ty = mir_projection_next_type(mir_mod, current_ty, pk, pd)
    out ++ "]"

pub fn dump_place_map_body(mir_mod: &MirModule, body: &MirBody, pool: &InternPool) -> str:
    var out = "fn " ++ mir_debug_body_label(body, pool) ++ "\n"
    for place_id in 0..body.place_locals.len() as i32:
        let local_id = body.place_locals[place_id]
        let ty = body.place_sema_types[place_id]
        out = out ++ f"  place#{place_id} path=" ++ mir_place_text(body, place_id) ++ f" base=_{local_id} ty=ty{ty} projections=" ++ mir_place_projection_debug_list(mir_mod, body, place_id) ++ "\n"
    out

fn mir_parse_positive_i32(text: &str) -> i32:
    if text.len() == 0:
        return -1
    var out = 0
    for i in 0..text.len():
        let ch = text[i]
        if ch < '0' or ch > '9':
            return -1
        out = out * 10 + (ch - '0')
    out

fn mir_parse_block_id(text: &str) -> i32:
    if text.starts_with("bb"):
        return mir_parse_positive_i32(text.slice(2, text.len()))
    mir_parse_positive_i32(text)

pub fn mir_cleanup_edge_from(target: &str) -> i32:
    for i in 0..target.len():
        if target[i] == '-' and i + 1 < target.len() and target[i + 1] == '>':
            return mir_parse_block_id(target.slice(0, i))
    -1

pub fn mir_cleanup_edge_to(target: &str) -> i32:
    for i in 0..target.len():
        if target[i] == '-' and i + 1 < target.len() and target[i + 1] == '>':
            return mir_parse_block_id(target.slice(i + 2, target.len()))
    -1

// #760: the CLI validates the spec BEFORE compiling, so a typo'd edge is
// a hard error instead of a five-minute compile ending in marker text
// and rc=0. One parser: this reuses the exact from/to readers below.
pub fn mir_cleanup_edge_spec_ok(spec: &str) -> i32:
    let target = mir_debug_spec_target(spec)
    if mir_cleanup_edge_from(target) < 0 or mir_cleanup_edge_to(target) < 0:
        return 0
    1

// Moved-ness of a drop state for the vacated-sub-place rule: Init < Maybe,
// MaybeMoved < Moved; -1 for a state that holds no value to compare (never
// initialized, dropped, garbage). Maybe keeps the rank it had before
// MaybeMoved split from it (#1414), so this rule's verdicts do not move.
fn mir_drop_state_moved_rank(state: i32) -> i32:
    if state == MirDropState.Init:
        return 0
    if state == MirDropState.Maybe or state == MirDropState.MaybeMoved:
        return 1
    if state == MirDropState.Moved:
        return 2
    -1

// The first MIR place naming each drop-state key, -1 for none.
fn mir_drop_state_key_places(keys: &MirDropStateKeys) -> Vec[i32]:
    var out: Vec[i32] = Vec.new()
    for _ in 0..keys.len():
        out.push(-1)
    for p in 0..keys.place_key.len() as i32:
        let k: i32 = keys.place_key[p]
        if out[k] < 0:
            out[k] = p
    out

// #1394: the key of a sub-place of `place_id` that the drop of `place_id`
// would free although a path reaching the drop moved it out and nothing
// re-initialized it (reset-on-move blanks a moved sub-place, §2.5.1, and the
// blank re-initializes it), or -1. The defect shape is a sub-place more moved
// than the place being dropped: a whole conditional move marks the place and
// every sub-place alike, and a Moved place's drop is elided. #1363 was this:
// `_8 = move _6<as v0>.f0` on the success arm, then `drop(_6)` at the join —
// the enum drop glue freed the payload the result owned.
fn mir_drop_vacated_subplace(mir_mod: &MirModule, body: &MirBody, keys: &MirDropStateKeys, state: &MirDropStateMap, key_places: &Vec[i32], place_id: i32) -> i32:
    let place_rank = mir_drop_state_moved_rank(state.place(keys, place_id))
    if place_rank < 0 or place_rank == 2:
        return -1
    let place_key: i32 = keys.place_key[place_id]
    let base: i32 = keys.base_local[place_key]
    let whole = body.place_proj_counts[place_id] == 0
    let start: i32 = keys.child_starts[base]
    let end: i32 = keys.child_starts[base + 1]
    for i in start..end:
        let child: i32 = keys.children[i]
        if child == place_key:
            continue
        if not whole and not mir_drop_state_key_is_descendant(keys.names[child], keys.names[place_key]):
            continue
        if mir_drop_state_moved_rank(state.get(keys, child)) <= place_rank:
            continue
        let child_place: i32 = key_places[child]
        if child_place < 0:
            continue
        if mir_mod.sema_moved_drop_types.contains(mir_validate_place_type(mir_mod, body, child_place)):
            return child
    -1

fn mir_drop_vacated_message(keys: &MirDropStateKeys, state: &MirDropStateMap, body: &MirBody, place_id: i32, child: i32) -> str:
    let child_state = mir_drop_state_name(state.get(keys, child))
    "drop of " ++ mir_place_text(body, place_id) ++ " frees " ++ keys.names[child] ++ f", which a path reaching it moved out ({child_state}) and nothing reset (§2.5.1)"

// #1559: the key of a sub-place of the whole local `place_id` that a path
// reaching its drop already dropped and nothing wrote again (Uninit, or
// Maybe at a join), or -1. A sub-place drop no longer turns the whole
// place Maybe (mark_place): the drop-before-overwrite of a field keeps the
// whole value. A field dropped and not rewritten is freed again by the
// whole value's drop glue; this is where that shows.
fn mir_drop_redropped_subplace(mir_mod: &MirModule, body: &MirBody, keys: &MirDropStateKeys, state: &MirDropStateMap, key_places: &Vec[i32], place_id: i32) -> i32:
    if body.place_proj_counts[place_id] != 0:
        return -1
    let place_key: i32 = keys.place_key[place_id]
    let whole_state = state.get(keys, place_key)
    if whole_state != MirDropState.Init and whole_state != MirDropState.Maybe:
        return -1
    let base: i32 = keys.base_local[place_key]
    for i in keys.child_starts[base]..keys.child_starts[base + 1]:
        let child: i32 = keys.children[i]
        let child_state = state.get(keys, child)
        if child_state != MirDropState.Uninit and child_state != MirDropState.Maybe:
            continue
        let child_place: i32 = key_places[child]
        if child_place < 0:
            continue
        if mir_mod.sema_dropped_types.contains(mir_validate_place_type(mir_mod, body, child_place)):
            return child
    -1

fn mir_drop_redropped_message(keys: &MirDropStateKeys, state: &MirDropStateMap, body: &MirBody, place_id: i32, child: i32) -> str:
    let child_state = mir_drop_state_name(state.get(keys, child))
    "drop of " ++ mir_place_text(body, place_id) ++ " frees " ++ keys.names[child] ++ f" again: a path reaching it dropped that part and nothing wrote it since ({child_state}) (§2.5.1)"

// #1415: a move out of a drop-bearing place projected through a reference
// (`_4 = move _1.*.p` through `&self`). A reference never owns its pointee,
// so the frame can neither own the moved value nor reset its source: both
// the referent's owner and the destination free it. That is never valid MIR
// (§2.2 D32: a field vacates only through a `var` base or a `mut fn`
// receiver, whose place carries no deref; D22: a view never becomes an
// owner). A raw pointer's pointee (the unsafe tier) and a Box's are owned
// through the pointer and stay legal.
fn mir_move_through_reference(mir_mod: &MirModule, body: &MirBody, operand_id: i32) -> str:
    if operand_id < 0 or operand_id >= body.operand_kinds.len() or body.operand_kinds[operand_id] != OperandKind.OK_MOVE:
        return ""
    let place = body.operand_d0[operand_id]
    if place < 0 or place >= body.place_locals.len():
        return ""
    let proj_start = body.place_proj_starts[place]
    let proj_count = body.place_proj_counts[place]
    for pi in 0..proj_count:
        if body.proj_kinds[(proj_start + pi)] != ProjKind.PK_DEREF:
            continue
        let pointer_ty = mir_mod.mir_resolve_alias(mir_validate_place_prefix_type(mir_mod, body, place, proj_count - pi))
        if mir_mod.mir_get_type_kind(pointer_ty) != TypeKind.TY_REF:
            continue
        if not mir_mod.sema_moved_drop_types.contains(mir_validate_place_type(mir_mod, body, place)):
            return ""
        return "moves out of " ++ mir_place_text(body, place) ++ " through a reference, which does not own it (§2.2 D32, D22)"
    ""

// The operands a statement's rvalue reads, decoded as note_rvalue does.
fn mir_rvalue_operands(body: &MirBody, rval_id: i32) -> Vec[i32]:
    var ops: Vec[i32] = Vec.new()
    if rval_id < 0 or rval_id >= body.rval_kinds.len():
        return ops
    let kind: i32 = body.rval_kinds[rval_id]
    let d0: i32 = body.rval_d0[rval_id]
    let d1: i32 = body.rval_d1[rval_id]
    let d2: i32 = body.rval_d2[rval_id]
    if kind == RvalueKind.RK_USE or kind == RvalueKind.RK_CAST:
        ops.push(d0)
    else if kind == RvalueKind.RK_BIN_OP or kind == RvalueKind.RK_SLICE:
        ops.push(d1)
        ops.push(d2)
    else if kind == RvalueKind.RK_UN_OP:
        ops.push(d1)
    else if kind == RvalueKind.RK_AGGREGATE and d1 >= 0 and d1 < body.agg_field_starts.len():
        for i in 0..body.agg_field_counts[d1]:
            ops.push(body.agg_field_operands[body.agg_field_starts[d1] + i])
    else if kind == RvalueKind.RK_STR_CONCAT_N and d0 >= 0 and d0 < body.call_arg_starts.len():
        for i in 0..body.call_arg_counts[d0]:
            ops.push(body.call_arg_operands[body.call_arg_starts[d0] + i])
    ops

// The operands a terminator reads, decoded as transfer_term does.
fn mir_term_operands(body: &MirBody, bb: i32) -> Vec[i32]:
    let tk = body.term_kind(bb)
    var term_ops: Vec[i32] = Vec.new()
    if tk == TermKind.TK_SWITCH_INT:
        term_ops.push(body.term_data0(bb))
    else if tk == TermKind.TK_CALL:
        term_ops.push(body.term_data0(bb))
        let args_id = body.term_data1(bb)
        if args_id >= 0 and args_id < body.call_arg_starts.len():
            for ai in 0..body.call_arg_counts[args_id]:
                term_ops.push(body.call_arg_operands[body.call_arg_starts[args_id] + ai])
    term_ops

// #1414: a move out of a drop-bearing place that a path reaching it already
// moved out (Moved, or MaybeMoved at a join) with nothing re-initializing
// it. Both destinations then own the one value and each frees it: a failed
// match guard's arm bound `move _3<as v0>.f0`, and the next arm bound it
// again (the #1394 double free, validate-all: ok). A place Maybe
// initialized is not judged here: MaybeMoved is exactly "moved on a path".
// Statement moves and call arguments alike (#1505): a receiver the callee
// borrows (`ch in s`, IndexPlace get/set) is lowered as the read it is, so
// an OK_MOVE argument is a move.
fn mir_move_of_moved_place(mir_mod: &MirModule, body: &MirBody, keys: &MirDropStateKeys, state: &MirDropStateMap, ops: &Vec[i32]) -> str:
    for oi in 0..ops.len():
        let op = ops[oi]
        if op < 0 or op >= body.operand_kinds.len() or body.operand_kinds[op] != OperandKind.OK_MOVE:
            continue
        let place = body.operand_d0[op]
        let moved = state.place(keys, place)
        if moved != MirDropState.Moved and moved != MirDropState.MaybeMoved and moved != MirDropState.Reset:
            continue
        if not mir_mod.sema_moved_drop_types.contains(mir_validate_place_type(mir_mod, body, place)):
            continue
        let moved_name = mir_drop_state_name(moved)
        return "move of " ++ mir_place_text(body, place) ++ f", which a path reaching it already moved out ({moved_name}) and nothing re-initialized: two owners free one value (§2.5.1)"
    ""

// What is wrong with a drop of the whole place `place_id` whose state is
// `drop_state`, or "". Codegen emits every drop (drop flags are retired,
// and mir_elaborate_dead_drops has no caller); the null guard skips only a
// reset blank, so the drop must reach a place every path left owning a
// value or blanked.
// - #729 class: MaybeGarbage means some predecessor never touched the
//   place at all — the join-block temp drop that freed uninitialized stack
//   passed this validator before the absence-aware join existed. Uninit
//   means every reachable predecessor missed initialization, as an off-path
//   defer temp does.
// - #1539: Moved (or MaybeMoved at a join) means a path moved the value out
//   and nothing reset the place: the drop frees what the new owner holds.
//   A generator's next body did `_5 = move _10; drop(_10); _10 = const
//   zst` — the reset after the drop — and `run --debug-alloc` reported a
//   DOUBLE FREE that validate-ownership passed. Only a type with drop glue
//   (sema_moved_drop_types: the place was moved, so its type is there when
//   it has glue) frees anything: `Some(move _5); drop(_5)` of a CStr view
//   is a no-op.
// - #1559: Maybe is Init on one path and Uninit on another — storage never
//   written, dead, or already dropped. None of those holds the reset blank
//   (a StorageLive is not zeroed; a drop does not blank), so the guard does
//   not protect it: a synthesized enum formatter's per-arm temp, dropped at
//   the join, freed stack garbage on the arm that never wrote it ("invalid
//   free"), and validate-all said ok.
fn mir_whole_drop_verdict(mir_mod: &MirModule, body: &MirBody, place_id: i32, drop_state: i32) -> str:
    let drop_key = mir_place_text(body, place_id)
    let state_name = mir_drop_state_name(drop_state)
    if drop_state == MirDropState.MaybeGarbage or drop_state == MirDropState.Uninit:
        return f"drop of {drop_key} reaches a path that never initialized it ({state_name})"
    let has_glue = mir_mod.sema_moved_drop_types.contains(mir_validate_place_type(mir_mod, body, place_id))
    if (drop_state == MirDropState.Moved or drop_state == MirDropState.MaybeMoved) and has_glue:
        return f"drop of {drop_key} after a path reaching it moved it out and before its reset ({state_name}): this frees the value its new owner holds (§2.5.1)"
    if drop_state == MirDropState.Maybe and mir_mod.sema_dropped_types.contains(mir_validate_place_type(mir_mod, body, place_id)):
        return f"drop of {drop_key} reaches a path where it holds no value — written on one path, never written, dead or already dropped on another ({state_name}); only a reset blank is safe to drop (§2.5.1)"
    ""

// A read (a copy or move operand) of a whole local that some path reaching
// it never initialized (Maybe, MaybeGarbage), or "". #1860: a
// value-position match's join read the result temp its no-arm path never
// wrote, and validate-all said ok. Uninit is not judged: StorageDead resets
// a local to Uninit and the lowering moves a block's tail local out after
// its scope's StorageDead by contract (`_23 = move _27` after
// `StorageDead(_27)`; materialize_tail_field_move keeps whole-local moves
// lazy). A projection is not judged: its key is Absent until touched.
fn mir_read_of_uninit_place(body: &MirBody, keys: &MirDropStateKeys, state: &MirDropStateMap, ops: &Vec[i32]) -> str:
    for oi in 0..ops.len():
        let op: i32 = ops[oi]
        if op < 0 or op >= body.operand_kinds.len():
            continue
        let k = body.operand_kinds[op]
        if k != OperandKind.OK_COPY and k != OperandKind.OK_MOVE:
            continue
        let place = body.operand_d0[op]
        if place < 0 or place >= body.place_locals.len() or body.place_proj_counts[place] != 0:
            continue
        let local = body.place_locals[place]
        if local == 0 or body.local_is_global[local] != 0:
            continue
        let s = state.place(keys, place)
        if s == MirDropState.MaybeGarbage or s == MirDropState.Maybe:
            return f"read of {mir_place_text(body, place)} reaches a path that never initialized it ({mir_drop_state_name(s)})"
    ""

// #1993: a read (copy or move) of an owned local — a value or handle the
// lowering recorded as owned cleanup — that every path reaching it moved
// out, or "". The value now belongs to its new owner (a task handle to the
// join_cleanup that released it); the read sees released storage.
// `owned` marks body.owned_cleanup_locals. Only a value that is not Copy is
// judged — one with drop glue, or a Task/ScopedTask handle: a Copy value is
// transported by `move` and read again legally (a loop's enum passed twice).
// MaybeMoved is not judged here (a conditional move's join), nor a
// projection (its key is Absent until touched).
fn mir_read_of_moved_owned_local(mir_mod: &MirModule, body: &MirBody, keys: &MirDropStateKeys, state: &MirDropStateMap, ops: &Vec[i32], owned: &Vec[i32]) -> str:
    for oi in 0..ops.len():
        let op: i32 = ops[oi]
        if op < 0 or op >= body.operand_kinds.len():
            continue
        let k = body.operand_kinds[op]
        if k != OperandKind.OK_COPY and k != OperandKind.OK_MOVE:
            continue
        let place = body.operand_d0[op]
        if place < 0 or place >= body.place_locals.len() or body.place_proj_counts[place] != 0:
            continue
        let local = body.place_locals[place]
        if local <= 0 or local >= owned.len() or owned[local] == 0:
            continue
        if state.place(keys, place) == MirDropState.Moved and mir_place_holds_non_copy_owner(mir_mod, body, place):
            return f"read of {mir_place_text(body, place)}, which every path reaching it already moved out: the value belongs to its new owner (§2.5.1)"
    ""

fn mir_place_holds_non_copy_owner(mir_mod: &MirModule, body: &MirBody, place: i32) -> bool:
    let ty = mir_validate_place_type(mir_mod, body, place)
    if ty <= 0:
        return false
    if mir_mod.sema_dropped_types.contains(ty) or mir_mod.sema_moved_drop_types.contains(ty):
        return true
    let resolved = mir_mod.mir_resolve_alias(ty)
    if mir_mod.sema_task_sym == 0 or mir_mod.mir_get_type_kind(resolved) != TypeKind.TY_GENERIC_INST:
        return false
    let base = mir_mod.mir_get_type_d0(resolved)
    base == mir_mod.sema_task_sym or base == mir_mod.sema_scoped_task_sym

// The Sema signature snapshot of `sym` (sema_sig_param_starts): its
// parameter count, or -1 when Sema has no signature by that name.
pub fn mir_sig_param_count(mir_mod: &MirModule, sym: i32) -> i32:
    let start: i32 = mir_mod.sema_sig_param_starts.get(sym) ?? -1
    if start < 0: -1 else: mir_mod.sema_sig_param_data[start]

// Parameter `pi`'s type in the signature snapshot of `sym`, 0 when absent.
pub fn mir_sig_param_type(mir_mod: &MirModule, sym: i32, pi: i32) -> i32:
    let start: i32 = mir_mod.sema_sig_param_starts.get(sym) ?? -1
    if start < 0 or pi < 0 or pi >= mir_mod.sema_sig_param_data[start]: 0 else: mir_mod.sema_sig_param_data[start + 1 + pi * 2]

// Whether parameter `pi` of `sym` takes ownership of its argument.
pub fn mir_sig_param_consumes(mir_mod: &MirModule, sym: i32, pi: i32) -> bool:
    let start: i32 = mir_mod.sema_sig_param_starts.get(sym) ?? -1
    start >= 0 and pi >= 0 and pi < mir_mod.sema_sig_param_data[start] and mir_mod.sema_sig_param_data[start + 2 + pi * 2] != 0

// Whether a whole drop of `local` is reachable from block `from` before
// any statement writes it (a re-initialization or a reset blank).
fn mir_drop_reachable_before_write(body: &MirBody, from: i32, local: i32) -> bool:
    var seen: Vec[i32] = Vec.new()
    for _ in 0..body.block_count():
        seen.push(0)
    var work: Vec[i32] = Vec.new()
    work.push(from)
    while work.len() > 0:
        let bb: i32 = work.pop().unwrap()
        if bb < 0 or bb >= body.block_count() or seen[bb] != 0:
            continue
        seen[bb] = 1
        var written = false
        for si in body.bb_stmt_starts[bb]..body.bb_stmt_starts[bb] + body.bb_stmt_counts[bb]:
            let kind = body.stmt_kind(si)
            let place = body.stmt_data0(si)
            if place < 0 or place >= body.place_locals.len() or body.place_locals[place] != local or body.place_proj_counts[place] != 0:
                continue
            if kind == StmtKind.Drop:
                return true
            if kind == StmtKind.Assign:
                written = true
                break
        if written:
            continue
        if body.term_kind(bb) == TermKind.TK_DROP_AND_GOTO:
            let place = body.term_data0(bb)
            if place >= 0 and place < body.place_locals.len() and body.place_locals[place] == local and body.place_proj_counts[place] == 0:
                return true
        for next in mir_drop_state_block_successors(body, bb):
            work.push(next)
    false

// #1742: a call argument that is a COPY of a whole local this body drops,
// at a parameter that takes ownership (a plain `T`, not `&T`, not an
// in-place receiver): the callee owns the value and the caller frees it
// too — a drop of the local is reachable after the call returns, before
// anything writes it. A callee that returns Never (with_panic) has no
// such path. `g.pull()` lowered its receiver as a method receiver (`copy` of the
// generator temp) into `gen_pull(g: impl Gen[T])`, the caller's scope-exit
// drop freed the generator's Vec again — DOUBLE FREE — and validate-all
// and audit:all both passed. The callee is a direct `const fn`, or a
// generic call's specialization; machinery dispatch and templates are not
// judged (their callee name is no signature).
fn mir_copy_into_consuming_param(mir_mod: &MirModule, body: &MirBody, bb: i32, dropped_local: &Vec[i32]) -> str:
    let call_id = body.term_data1(bb)
    if call_id < 0 or call_id >= body.call_arg_starts.len():
        return ""
    let intrinsic = body.call_intrinsic(call_id)
    var sym = 0
    if intrinsic == MirIntrinsic.NONE:
        sym = mir_call_const_fn_sym(body, body.term_data0(bb))
    else if intrinsic == MirIntrinsic.GENERIC_CALL and not body.call_is_machinery_dispatch(call_id):
        sym = body.call_mono_sym(call_id)
    if sym == 0 or mir_mod.sema_never_returning_syms.contains(sym):
        return ""
    let start = body.call_arg_starts[call_id]
    for ai in 0..body.call_arg_counts[call_id]:
        let op = body.call_arg_operands[start + ai]
        if op < 0 or op >= body.operand_kinds.len() or body.operand_kinds[op] != OperandKind.OK_COPY:
            continue
        let place = body.operand_d0[op]
        if place < 0 or place >= body.place_locals.len() or body.place_proj_counts[place] != 0:
            continue
        let local = body.place_locals[place]
        if local < 0 or local >= dropped_local.len() or dropped_local[local] == 0:
            continue
        if not mir_sig_param_consumes(mir_mod, sym, ai):
            continue
        if not mir_drop_reachable_before_write(body, body.term_data3(bb), local):
            continue
        let place_text = mir_place_text(body, place)
        return f"copy of {place_text} into parameter {ai} of fn sym{sym}, which takes ownership of it, while this body drops {place_text} too: two owners free one value (§2.5.1)"
    ""

// Whether whole-local place `place_id` still holds its value only as a shell:
// some tracked sub-place was moved out, blanked or dropped (not Init). A
// projection place is never judged a shell.
fn mir_local_partially_vacated(body: &MirBody, keys: &MirDropStateKeys, state: &MirDropStateMap, place_id: i32) -> bool:
    if place_id < 0 or place_id >= body.place_locals.len() or body.place_proj_counts[place_id] != 0:
        return false
    let local_id = body.place_locals[place_id]
    if local_id < 0 or local_id + 1 >= keys.child_starts.len() as i32:
        return false
    for ci in keys.child_starts[local_id]..keys.child_starts[local_id + 1]:
        if state.get(keys, keys.children[ci]) != MirDropState.Init:
            return true
    false

// Every move of a statement or terminator checked by the #1415 rule.
fn validate_moves_through_references(mir_mod: &MirModule, body: &MirBody) -> str:
    for bb in 0..body.block_count():
        let stmt_start = body.bb_stmt_starts[bb]
        for si in 0..body.bb_stmt_counts[bb]:
            let stmt_id = stmt_start + si
            if body.stmt_kind(stmt_id) != StmtKind.Assign:
                continue
            let ops = mir_rvalue_operands(body, body.stmt_data1(stmt_id))
            for oi in 0..ops.len():
                let err = mir_move_through_reference(mir_mod, body, ops[oi])
                if err.len() > 0:
                    return f"fn sym{body.fn_sym} stmt{stmt_id} span={body.stmt_spans[stmt_id]}: " ++ err
        let term_ops = mir_term_operands(body, bb)
        for oi in 0..term_ops.len():
            let err = mir_move_through_reference(mir_mod, body, term_ops[oi])
            if err.len() > 0:
                return f"fn sym{body.fn_sym} bb{bb}: " ++ err
    ""

// The whole-local drop a statement or terminator performs, or -1.
fn mir_whole_drop_local(body: &MirBody, place: i32) -> i32:
    if place < 0 or place >= body.place_locals.len() or body.place_proj_counts[place] != 0:
        return -1
    body.place_locals[place]

// The locals every path has dropped, one flag per slot (slot[local] >= 0
// for each local some whole drop targets).
type MirDroppedSet {
    flags: Vec[i32],
}

impl MirDroppedSet:
    fn has(slot: &Vec[i32], local: i32) -> bool:
        local >= 0 and local < slot.len() and slot[local] >= 0 and self.flags[slot[local]] != 0

    mut fn mark(slot: &Vec[i32], local: i32, dropped: i32):
        if local >= 0 and local < slot.len() and slot[local] >= 0:
            self.flags[slot[local]] = dropped

    // One statement's effect; reads are judged before it. A whole write or a
    // StorageLive gives the local a new value (or fresh storage).
    mut fn transfer_stmt(body: &MirBody, slot: &Vec[i32], stmt_id: i32):
        let kind = body.stmt_kind(stmt_id)
        let d0 = body.stmt_data0(stmt_id)
        if kind == StmtKind.StorageLive:
            self.mark(slot, d0, 0)
        else if kind == StmtKind.Drop:
            self.mark(slot, mir_whole_drop_local(body, d0), 1)
        else if kind == StmtKind.Assign:
            self.mark(slot, mir_whole_drop_local(body, d0), 0)

    mut fn transfer_term(body: &MirBody, slot: &Vec[i32], bb: i32):
        let kind = body.term_kind(bb)
        if kind == TermKind.TK_DROP_AND_GOTO:
            self.mark(slot, mir_whole_drop_local(body, body.term_data0(bb)), 1)
        else if kind == TermKind.TK_CALL:
            self.mark(slot, mir_whole_drop_local(body, body.term_data2(bb)), 0)

// #1991: a read of a local — whole, or through a projection (`_2[_4].f`) —
// that every path reaching it has dropped and nothing rewrote. The value is
// gone: the drop freed what the read dereferences. The pre-#1968 lowering
// left a block tail `t[id].arity` a lazy place operand and emitted
// `drop(_2); _0 = copy _2[_4].f`; the Vec's drop cleared its length and the
// read panicked "index out of bounds" (the seed-built stage1's
// math_fn_arity), and validate-all said ok: the drop-state lattice marks a
// dropped place Uninit, as StorageDead does, and judges only whole-local
// reads of Maybe places (mir_read_of_uninit_place), never a projection.
// Must-dropped: a read on a path that dropped only on some paths is not
// judged here.
fn validate_read_after_drop(body: &MirBody) -> str:
    let local_count = body.local_type_ids.len() as i32
    let block_count = body.block_count()
    if local_count <= 0 or block_count <= 0:
        return ""
    // Only locals some whole drop targets can be read after a drop.
    var slot: Vec[i32] = Vec.new()
    for _ in 0..local_count:
        slot.push(-1)
    var width = 0
    for bb in 0..block_count:
        for si in body.bb_stmt_starts[bb]..body.bb_stmt_starts[bb] + body.bb_stmt_counts[bb]:
            if body.stmt_kind(si) == StmtKind.Drop:
                let local = mir_whole_drop_local(body, body.stmt_data0(si))
                if local >= 0 and local < local_count and slot[local] < 0:
                    slot[local] = width
                    width += 1
        if body.term_kind(bb) == TermKind.TK_DROP_AND_GOTO:
            let local = mir_whole_drop_local(body, body.term_data0(bb))
            if local >= 0 and local < local_count and slot[local] < 0:
                slot[local] = width
                width += 1
    if width == 0:
        return ""
    // Forward must-analysis: a block's input is the meet (AND) of its
    // reachable predecessors' outputs; the entry starts with nothing dropped.
    var reached: Vec[i32] = Vec.new()
    for _ in 0..block_count:
        reached.push(0)
    var work: Vec[i32] = Vec.new()
    work.push(0)
    reached[0] = 1
    var edge_from: Vec[i32] = Vec.new()
    var edge_to: Vec[i32] = Vec.new()
    while work.len() > 0:
        let bb: i32 = work.pop().unwrap()
        for next in mir_drop_state_block_successors(body, bb):
            if next < 0 or next >= block_count:
                continue
            edge_from.push(bb)
            edge_to.push(next)
            if reached[next] == 0:
                reached[next] = 1
                work.push(next)
    // Predecessors of block b: pred_list[pred_start[b]..pred_start[b + 1]].
    var pred_start: Vec[i32] = Vec.new()
    for _ in 0..block_count + 1:
        pred_start.push(0)
    for e in 0..edge_to.len():
        pred_start[edge_to[e] + 1] += 1
    for b in 0..block_count:
        pred_start[b + 1] += pred_start[b]
    var fill = pred_start.clone()
    var pred_list: Vec[i32] = Vec.new()
    for _ in 0..edge_to.len():
        pred_list.push(0)
    for e in 0..edge_to.len():
        pred_list[fill[edge_to[e]]] = edge_from[e]
        fill[edge_to[e]] += 1
    // out rows: block_count × width, all-dropped (the meet's top) until computed.
    var out: Vec[i32] = Vec.new()
    for _ in 0..block_count * width:
        out.push(1)
    var changed = true
    while changed:
        changed = false
        for bb in 0..block_count:
            if reached[bb] == 0:
                continue
            var state = mir_dropped_input(&out, &pred_start, &pred_list, bb, width)
            for si in body.bb_stmt_starts[bb]..body.bb_stmt_starts[bb] + body.bb_stmt_counts[bb]:
                state.transfer_stmt(body, &slot, si)
            state.transfer_term(body, &slot, bb)
            for i in 0..width:
                if out[bb * width + i] != state.flags[i]:
                    out[bb * width + i] = state.flags[i]
                    changed = true
    for bb in 0..block_count:
        if reached[bb] == 0:
            continue
        var state = mir_dropped_input(&out, &pred_start, &pred_list, bb, width)
        for si in body.bb_stmt_starts[bb]..body.bb_stmt_starts[bb] + body.bb_stmt_counts[bb]:
            if body.stmt_kind(si) == StmtKind.Assign:
                for local in mir_rvalue_read_locals(body, body.stmt_data1(si)):
                    if state.has(&slot, local):
                        return f"fn sym{body.fn_sym} stmt{si} span={body.stmt_spans[si]}: read of _{local} after every path reaching it dropped _{local}: the value it reads is freed (§2.5.1)"
            state.transfer_stmt(body, &slot, si)
        for op in mir_term_operands(body, bb):
            let local = mir_local_of_operand(body, op)
            if state.has(&slot, local):
                return f"fn sym{body.fn_sym} bb{bb}: read of _{local} after every path reaching it dropped _{local}: the value it reads is freed (§2.5.1)"
    ""

// A block's dropped set on entry: nothing at the entry block, else the AND
// of its predecessors' outputs.
fn mir_dropped_input(out: &Vec[i32], pred_start: &Vec[i32], pred_list: &Vec[i32], bb: i32, width: i32) -> MirDroppedSet:
    var flags: Vec[i32] = Vec.new()
    for _ in 0..width:
        flags.push(if bb == 0: 0 else: 1)
    if bb != 0:
        for pi in pred_start[bb]..pred_start[bb + 1]:
            let p = pred_list[pi]
            for i in 0..width:
                if out[p * width + i] == 0:
                    flags[i] = 0
    MirDroppedSet { flags }

pub fn validate_ownership_body(mir_mod: &MirModule, body: &MirBody) -> str:
    let through_reference = validate_moves_through_references(mir_mod, body)
    if through_reference.len() > 0:
        return through_reference
    let read_after_drop = validate_read_after_drop(body)
    if read_after_drop.len() > 0:
        return read_after_drop
    var blocks = mir_drop_state_compute_blocks(body)
    let key_places = mir_drop_state_key_places(blocks.keys)
    var dropped_local: Vec[i32] = Vec.new()
    for _ in 0..body.local_type_ids.len():
        dropped_local.push(0)
    for li in body.owned_cleanup_locals:
        if li < 0 or li >= dropped_local.len():
            return f"fn sym{body.fn_sym}: owned cleanup local _{li} is out of range"
        dropped_local[li] = 1
    var owned_local: Vec[i32] = Vec.new()
    for _ in 0..body.local_type_ids.len():
        owned_local.push(0)
    for li in body.owned_cleanup_locals:
        owned_local[li] = 1
    for bb in 0..body.block_count():
        let stmt_start = body.bb_stmt_starts[bb]
        let stmt_count = body.bb_stmt_counts[bb]
        for si in 0..stmt_count:
            let stmt_id = stmt_start + si
            if body.stmt_kind(stmt_id) == StmtKind.Drop:
                let place_id = body.stmt_data0(stmt_id)
                if place_id >= 0 and place_id < body.place_locals.len() and body.place_proj_counts[place_id] == 0:
                    dropped_local[body.place_locals[place_id]] = 1
        if body.term_kind(bb) == TermKind.TK_DROP_AND_GOTO:
            let place_id = body.term_data0(bb)
            if place_id >= 0 and place_id < body.place_locals.len() and body.place_proj_counts[place_id] == 0:
                dropped_local[body.place_locals[place_id]] = 1
    for bb in 0..body.block_count():
        var state = blocks.input(bb)
        let stmt_start = body.bb_stmt_starts[bb]
        let stmt_count = body.bb_stmt_counts[bb]
        for si in 0..stmt_count:
            let stmt_id = stmt_start + si
            let kind = body.stmt_kind(stmt_id)
            let d0 = body.stmt_data0(stmt_id)
            let span = body.stmt_spans[stmt_id]
            if kind == StmtKind.Assign or kind == StmtKind.Drop:
                if d0 < 0 or d0 >= body.place_locals.len():
                    return f"fn sym{body.fn_sym} stmt{stmt_id} span={span}: ownership target place out of range"
                if mir_validate_place_type(mir_mod, body, d0) == 0:
                    return f"fn sym{body.fn_sym} stmt{stmt_id} span={span}: ownership target has no concrete MIR type"
            if kind == StmtKind.Drop and body.place_proj_counts[d0] == 0 and blocks.computed[bb] != 0:
                let bad_drop = mir_whole_drop_verdict(mir_mod, body, d0, state.place(blocks.keys, d0))
                if bad_drop.len() > 0:
                    return f"fn sym{body.fn_sym} stmt{stmt_id} span={span}: " ++ bad_drop
            if kind == StmtKind.Drop and blocks.computed[bb] != 0:
                let vacated = mir_drop_vacated_subplace(mir_mod, body, blocks.keys, state, key_places, d0)
                if vacated >= 0:
                    return f"fn sym{body.fn_sym} stmt{stmt_id} span={span}: " ++ mir_drop_vacated_message(blocks.keys, state, body, d0, vacated)
                let redropped = mir_drop_redropped_subplace(mir_mod, body, blocks.keys, state, key_places, d0)
                if redropped >= 0:
                    return f"fn sym{body.fn_sym} stmt{stmt_id} span={span}: " ++ mir_drop_redropped_message(blocks.keys, state, body, d0, redropped)
            if kind == StmtKind.Assign and blocks.computed[bb] != 0:
                let twice = mir_move_of_moved_place(mir_mod, body, blocks.keys, state, mir_rvalue_operands(body, body.stmt_data1(stmt_id)))
                if twice.len() > 0:
                    return f"fn sym{body.fn_sym} stmt{stmt_id} span={span}: " ++ twice
                let uninit_read = mir_read_of_uninit_place(body, blocks.keys, state, mir_rvalue_operands(body, body.stmt_data1(stmt_id)))
                if uninit_read.len() > 0:
                    return f"fn sym{body.fn_sym} stmt{stmt_id} span={span}: " ++ uninit_read
                let moved_read = mir_read_of_moved_owned_local(mir_mod, body, blocks.keys, state, mir_rvalue_operands(body, body.stmt_data1(stmt_id)), owned_local)
                if moved_read.len() > 0:
                    return f"fn sym{body.fn_sym} stmt{stmt_id} span={span}: " ++ moved_read
                // #1487: a reset-on-move blank stores the sentinel over a
                // place a move left behind. Over a place still Init — no path
                // moved it — it overwrites a live value without a drop: the
                // value is lost (a leak) and every later read sees the blank.
                // Moved, MaybeMoved, Reset, Uninit, Maybe and MaybeGarbage
                // stay legal (a reset after a move, at a conditional-move
                // join, a zero-init).
                // A shell a sub-place move vacated is not a lost value either:
                // `?`'s pass path and a record update move the payload or
                // fields out and blank the carrier — the same partial-move
                // judgment the leak-at-return rule below makes (#2049).
                if mir_rvalue_is_zero_fill(body, body.stmt_data1(stmt_id)) != 0 and state.place(blocks.keys, d0) == MirDropState.Init and mir_mod.sema_moved_drop_types.contains(mir_validate_place_type(mir_mod, body, d0)) and not mir_local_partially_vacated(body, blocks.keys, state, d0):
                    return f"fn sym{body.fn_sym} stmt{stmt_id} span={span}: reset of {mir_place_text(body, d0)} on a path where it was never moved: the value it holds is lost (§2.5.1)"
            state.transfer_stmt(blocks.keys, body, stmt_id)
        if body.term_kind(bb) == TermKind.TK_CALL and blocks.computed[bb] != 0:
            let twice = mir_move_of_moved_place(mir_mod, body, blocks.keys, state, mir_term_operands(body, bb))
            if twice.len() > 0:
                return f"fn sym{body.fn_sym} bb{bb}: " ++ twice
            let copied = mir_copy_into_consuming_param(mir_mod, body, bb, dropped_local)
            if copied.len() > 0:
                return f"fn sym{body.fn_sym} bb{bb}: " ++ copied
        if blocks.computed[bb] != 0:
            let uninit_term = mir_read_of_uninit_place(body, blocks.keys, state, mir_term_operands(body, bb))
            if uninit_term.len() > 0:
                return f"fn sym{body.fn_sym} bb{bb}: " ++ uninit_term
            let moved_term = mir_read_of_moved_owned_local(mir_mod, body, blocks.keys, state, mir_term_operands(body, bb), owned_local)
            if moved_term.len() > 0:
                return f"fn sym{body.fn_sym} bb{bb}: " ++ moved_term
        if body.term_kind(bb) == TermKind.TK_CALL or body.term_kind(bb) == TermKind.TK_DROP_AND_GOTO:
            let place_id = if body.term_kind(bb) == TermKind.TK_CALL: body.term_data2(bb) else: body.term_data0(bb)
            if place_id < 0 or place_id >= body.place_locals.len():
                return f"fn sym{body.fn_sym} bb{bb}: ownership terminator place out of range"
            if mir_validate_place_type(mir_mod, body, place_id) == 0:
                return f"fn sym{body.fn_sym} bb{bb}: ownership terminator place has no concrete MIR type"
            if body.term_kind(bb) == TermKind.TK_DROP_AND_GOTO and body.place_proj_counts[place_id] == 0 and blocks.computed[bb] != 0:
                let bad_drop = mir_whole_drop_verdict(mir_mod, body, place_id, state.place(blocks.keys, place_id))
                if bad_drop.len() > 0:
                    return f"fn sym{body.fn_sym} bb{bb}: " ++ bad_drop
            if body.term_kind(bb) == TermKind.TK_DROP_AND_GOTO and blocks.computed[bb] != 0:
                let vacated = mir_drop_vacated_subplace(mir_mod, body, blocks.keys, state, key_places, place_id)
                if vacated >= 0:
                    return f"fn sym{body.fn_sym} bb{bb}: " ++ mir_drop_vacated_message(blocks.keys, state, body, place_id, vacated)
                let redropped = mir_drop_redropped_subplace(mir_mod, body, blocks.keys, state, key_places, place_id)
                if redropped >= 0:
                    return f"fn sym{body.fn_sym} bb{bb}: " ++ mir_drop_redropped_message(blocks.keys, state, body, place_id, redropped)
        // #1384 / #1488: a local some `drop` targets is owned storage the lowering
        // scheduled a drop for. Still Init at a `return`, with no sub-place moved
        // out or blanked (a partial move leaves a shell nothing needs to free),
        // it is a leak: no path dropped or moved it.
        if body.term_kind(bb) == TermKind.TK_RETURN and blocks.computed[bb] != 0:
            for k in 0..key_places.len():
                let place_id: i32 = key_places[k]
                if place_id < 0 or body.place_proj_counts[place_id] != 0:
                    continue
                let local_id = body.place_locals[place_id]
                if local_id == 0 or dropped_local[local_id] == 0 or body.local_is_global[local_id] != 0:
                    continue
                // A closure's capture (locals 1..capture count) is a place of
                // the creating frame (§12.4) — or, for `move ||`, of the
                // closure's environment — which drops it: a body that
                // overwrites it drops the old value first and leaves the new
                // one to that owner.
                if local_id <= body.anonymous_capture_count:
                    continue
                // #1822: a parameter naming the caller's place (MirLower's
                // decision, not re-derived here) is the caller's to drop. A
                // body that replaces it whole — `mut fn bang(): self = self
                // ++ "!"` — drops the old value and leaves it Init: the contract.
                if body.local_is_caller_place[local_id] != 0:
                    continue
                if state.place(blocks.keys, place_id) != MirDropState.Init:
                    continue
                if mir_local_partially_vacated(body, blocks.keys, state, place_id):
                    continue
                return f"fn sym{body.fn_sym} bb{bb}: owned local {mir_place_text(body, place_id)} is still Init at return — no path drops or moves it (a leak)"
        state.transfer_term(blocks.keys, body, bb)
    ""

pub fn validate_ownership_mir_module(mir_mod: &MirModule) -> str:
    let shape = validate_mir_module(mir_mod)
    if shape.len() > 0:
        return "MIR shape: " ++ shape
    var errors = ""
    for bi in 0..mir_mod.bodies.len():
        let body = &mir_mod.bodies[bi]
        if body.lowering_failed != 0:
            continue
        let err = validate_ownership_body(mir_mod, body)
        if err.len() > 0:
            if errors.len() > 0: errors = errors ++ "\n"
            errors = errors ++ err
    errors

pub fn mir_debug_spec_fn(spec: &str) -> str:
    for i in 0..spec.len():
        if spec[i] == ':':
            return spec.slice(0, i)
    ""

pub fn mir_debug_spec_target(spec: &str) -> str:
    for i in 0..spec.len():
        if spec[i] == ':':
            return spec.slice(i + 1, spec.len())
    with_str_clone_ref(spec)

fn mir_debug_body_name(body: &MirBody, pool: &InternPool) -> str:
    if body.fn_sym != 0:
        return with_str_clone_ref(pool.resolve(body.fn_sym))
    "<anon>"

pub fn mir_debug_body_label(body: &MirBody, pool: &InternPool) -> str:
    if body.fn_sym != 0:
        return f"sym{body.fn_sym}(" ++ pool.resolve(body.fn_sym) ++ ")"
    "<anon>"

pub fn mir_debug_body_matches(body: &MirBody, pool: &InternPool, wanted_fn: &str) -> bool:
    if wanted_fn.len() == 0:
        return true
    let name = mir_debug_body_name(body, pool)
    if name == wanted_fn:
        return true
    if body.fn_sym != 0 and f"sym{body.fn_sym}" == wanted_fn:
        return true
    false

pub fn mir_debug_mentions(text: &str, target: &str) -> bool:
    target.len() == 0 or text.contains(target)

fn mir_local_of_operand(body: &MirBody, operand: i32) -> i32:
    if operand < 0 or operand >= body.operand_kinds.len():
        return -1
    let k = body.operand_kinds[operand]
    if k != OperandKind.OK_COPY and k != OperandKind.OK_MOVE:
        return -1
    let place = body.operand_d0[operand]
    if place < 0 or place >= body.place_locals.len():
        return -1
    body.place_locals[place]

fn mir_rvalue_is_zero_fill(body: &MirBody, rv: i32) -> i32:
    if rv < 0 or rv >= body.rval_kinds.len():
        return 0
    if body.rval_kinds[rv] != RvalueKind.RK_USE:
        return 0
    let op = body.rval_d0[rv]
    if op < 0 or op >= body.operand_kinds.len():
        return 0
    if body.operand_kinds[op] != OperandKind.OK_CONSTANT:
        return 0
    let cid = body.operand_d0[op]
    if cid < 0 or cid >= body.const_kinds.len():
        return 0
    if body.const_kinds[cid] == ConstKind.CK_ZERO_SIZED: 1 else: 0

// The only successor of `bb`, or -1 when it branches / ends. A chain of
// single-successor blocks is the one case where "the blank happens before the
// read" is provable without a dominator tree — and it is exactly the shape a
// synthesized straight-line body has. Anything with a branch or a loop is left
// alone rather than guessed at (a blank in one arm is not a blank on the path
// that reaches the join).
fn mir_block_single_successor(body: &MirBody, bb: i32) -> i32:
    let tk = body.term_kind(bb)
    if tk == TermKind.TK_GOTO:
        return body.term_data0(bb)
    if tk == TermKind.TK_CALL:
        return body.term_data3(bb)
    -1

fn mir_block_reaches_linearly(body: &MirBody, from_bb: i32, to_bb: i32) -> i32:
    if from_bb == to_bb:
        return 1
    var cur = from_bb
    var hops = 0
    while hops < 4096:
        let nxt = mir_block_single_successor(body, cur)
        if nxt < 0 or nxt >= body.block_count():
            return 0
        if nxt == to_bb:
            return 1
        if nxt <= cur:
            return 0
        cur = nxt
        hops = hops + 1
    0

fn mir_local_of_place(body: &MirBody, place: i32) -> i32:
    if place < 0 or place >= body.place_locals.len():
        return -1
    body.place_locals[place]

// The locals whose VALUE an rvalue reads, decoded per kind with the same
// d0/d1/d2 layout the MIR printer uses (mir_rvalue_text is the contract).
// Address-takes (ref, addr_of) are not value reads. #927: the use-after-kill
// validator read `rval_d0` as an operand for every kind — for an aggregate
// that is the aggregate kind, for a binop the operator, for a ref the borrow
// kind — so operand 0 of the body (a move-self function's `self`) was
// "read" after its reset blank, and every D32 rebind builder audited red.
fn mir_rvalue_read_locals(body: &MirBody, rv: i32) -> Vec[i32]:
    let out: Vec[i32] = Vec.new()
    if rv < 0 or rv >= body.rval_kinds.len():
        return out
    let k = body.rval_kinds[rv]
    let d0 = body.rval_d0[rv]
    let d1 = body.rval_d1[rv]
    let d2 = body.rval_d2[rv]
    // Collect candidate locals (-1 = none), then keep the real ones.
    let cands: Vec[i32] = Vec.new()
    if k == RvalueKind.RK_USE or k == RvalueKind.RK_CAST or k == RvalueKind.RK_ARRAY_FILL:
        cands.push(mir_local_of_operand(body, d0))
    else if k == RvalueKind.RK_BIN_OP:
        cands.push(mir_local_of_operand(body, d1))
        cands.push(mir_local_of_operand(body, d2))
    else if k == RvalueKind.RK_UN_OP:
        cands.push(mir_local_of_operand(body, d1))
    else if k == RvalueKind.RK_DISCRIMINANT or k == RvalueKind.RK_LEN:
        cands.push(mir_local_of_place(body, d0))
    else if k == RvalueKind.RK_SLICE:
        cands.push(mir_local_of_place(body, d0))
        cands.push(mir_local_of_operand(body, d1))
        cands.push(mir_local_of_operand(body, d2))
    else if k == RvalueKind.RK_AGGREGATE:
        if d1 >= 0 and d1 < body.agg_field_starts.len():
            let fstart = body.agg_field_starts[d1]
            let fcount = body.agg_field_counts[d1]
            for fi in 0..fcount:
                let opi = fstart + fi
                if opi >= 0 and opi < body.agg_field_operands.len():
                    cands.push(mir_local_of_operand(body, body.agg_field_operands[opi]))
    else if k == RvalueKind.RK_STR_CONCAT_N:
        if d0 >= 0 and d0 < body.call_arg_starts.len():
            let start = body.call_arg_starts[d0]
            let count = body.call_arg_counts[d0]
            for ai in 0..count:
                let opi = start + ai
                if opi >= 0 and opi < body.call_arg_operands.len():
                    cands.push(mir_local_of_operand(body, body.call_arg_operands[opi]))
    for ci in 0..cands.len():
        let local = cands[ci]
        if local >= 0:
            out.push(local)
    out

// Use-after-kill (#719 class): a local that has been killed — StorageDead, or
// blanked by a reset-on-move `_x = <zero>` — must not be read again before it is
// re-initialized. A body that does read it computes from zeroed storage; #719 is
// exactly this (a binding killed by an inner scope pop, then consumed by a later
// aggregate). Scanning blocks in index order only reports a kill that DOMINATES
// the use in the emitted order, which is the shape lowering bugs produce; a use
// reached only by a back edge is never flagged.
fn validate_use_after_kill_body(body: &MirBody, pool: &InternPool) -> str:
    let local_count = body.local_type_ids.len() as i32
    if local_count <= 0 or local_count > 20000:
        return ""
    let killed: Vec[i32] = Vec.new()
    let killed_bb: Vec[i32] = Vec.new()
    for _i in 0..local_count:
        killed.push(0)
        killed_bb.push(-1)
    let fn_name = if body.fn_sym != 0: with_str_clone_ref(pool.resolve(body.fn_sym)) else: "<anon>"
    for bb in 0..body.block_count():
        let stmt_start = body.bb_stmt_starts[bb]
        let stmt_count = body.bb_stmt_counts[bb]
        for si in 0..stmt_count:
            let sid = stmt_start + si
            if sid < 0 or sid >= body.stmt_kinds.len():
                continue
            let sk = body.stmt_kinds[sid]
            let d0 = body.stmt_d0[sid]
            let d1 = body.stmt_d1[sid]
            if sk == StmtKind.StorageLive:
                if d0 >= 0 and d0 < local_count:
                    killed[d0] = 0
                continue
            if sk == StmtKind.StorageDead:
                // A marker, not a write: the storage still holds the value and a
                // later read is valid (proven by the single-container control,
                // which has StorageDead before its aggregate read and runs fine).
                // Only an actual zero-fill blank destroys the value.
                continue
            if sk != StmtKind.Assign:
                continue
            // Reads first: no value operand of the rvalue may be a killed local.
            let reads = mir_rvalue_read_locals(body, d1)
            for ri in 0..reads.len():
                let used = reads[ri]
                if used >= 0 and used < local_count and killed[used] != 0 and mir_block_reaches_linearly(body, killed_bb[used], bb) != 0:
                    return f"{fn_name}: local _{used} is read at bb{bb} after its reset-on-move blank zeroed it"
            // Then the write: a zero fill kills, any other write revives.
            if d0 >= 0 and d0 < body.place_locals.len() and body.place_proj_counts[d0] == 0:
                let dst = body.place_locals[d0]
                if dst >= 0 and dst < local_count:
                    let is_blank = mir_rvalue_is_zero_fill(body, d1)
                    killed[dst] = is_blank
                    killed_bb[dst] = if is_blank != 0: bb else: -1
    ""

pub fn validate_use_after_kill(body: &MirBody, pool: &InternPool) -> str:
    validate_use_after_kill_body(body, pool)

// A validator verdict names bodies `fn sym<N>`; the reader needs the
// function. Each `fn sym<N>` gains its name, as --dump-mir prints it.
pub fn mir_name_fn_syms(text: &str, pool: &InternPool) -> str:
    var out = StringBuilder.new()
    var i = 0
    let n = text.len() as i32
    while i < n:
        if i + 6 <= n and text.slice(i as i64, (i + 6) as i64) == "fn sym":
            var j = i + 6
            var sym = 0
            while j < n and text[j] >= '0' and text[j] <= '9':
                sym = sym * 10 + (text[j] - '0') as i32
                j += 1
            out.push_str(text.slice(i as i64, j as i64))
            if j > i + 6:
                out.push_str(f"({pool.resolve(sym)})")
            i = j
            continue
        out.push_byte(text[i])
        i += 1
    out.to_str()

pub fn validate_all_mir_module(mir_mod: &MirModule) -> str:
    let shape = validate_mir_module(mir_mod)
    if shape.len() > 0:
        return "MIR shape: " ++ shape
    // #1736: a body whose lowering failed has no MIR to validate, and codegen
    // refuses to compile it ("MIR lowering failed for function ..."). The
    // typed and ownership validators skip such a body, so validate-all said
    // ok over a comprehension the build could not compile.
    for bi in 0..mir_mod.bodies.len():
        if mir_mod.bodies[bi].lowering_failed != 0:
            return f"fn sym{mir_mod.bodies[bi].fn_sym}: MIR lowering failed; the body was not validated and codegen cannot compile it (WITH_MIR_AUDIT=1 names the unsupported node)"
    let typed = validate_typed_mir_module(mir_mod)
    if mir_validation_has_error(typed):
        return "typed MIR: " ++ typed.message
    let ownership = validate_ownership_mir_module(mir_mod)
    if ownership.len() > 0:
        return "ownership MIR: " ++ ownership
    ""

pub fn mir_binop_name(op: i32) -> str:
    if op == BinaryOp.OP_ADD: return "add"
    if op == BinaryOp.OP_SUB: return "sub"
    if op == BinaryOp.OP_MUL: return "mul"
    if op == BinaryOp.OP_DIV: return "div"
    if op == BinaryOp.OP_MOD: return "mod"
    if op == BinaryOp.OP_EQ: return "eq"
    if op == BinaryOp.OP_NEQ: return "neq"
    if op == BinaryOp.OP_LT: return "lt"
    if op == BinaryOp.OP_GT: return "gt"
    if op == BinaryOp.OP_LTE: return "lte"
    if op == BinaryOp.OP_GTE: return "gte"
    if op == BinaryOp.OP_AND: return "and"
    if op == BinaryOp.OP_OR: return "or"
    if op == BinaryOp.OP_BIT_AND: return "bit_and"
    if op == BinaryOp.OP_BIT_OR: return "bit_or"
    if op == BinaryOp.OP_BIT_XOR: return "bit_xor"
    if op == BinaryOp.OP_SHL: return "shl"
    if op == BinaryOp.OP_SHR: return "shr"
    if op == BinaryOp.OP_DEFAULT: return "default"
    if op == BinaryOp.OP_CONCAT: return "concat"
    if op == BinaryOp.OP_ADD_WRAP: return "add_wrap"
    if op == BinaryOp.OP_SUB_WRAP: return "sub_wrap"
    if op == BinaryOp.OP_MUL_WRAP: return "mul_wrap"
    if op == BinaryOp.OP_IN: return "in"
    if op == BinaryOp.OP_NOT_IN: return "not_in"
    f"op{op}"

pub fn mir_unop_name(op: i32) -> str:
    if op == UnaryOp.UOP_NEGATE: return "neg"
    if op == UnaryOp.UOP_NOT: return "not"
    if op == UnaryOp.UOP_REF: return "ref"
    if op == UnaryOp.UOP_RAW_REF_CONST: return "raw_const_ref"
    if op == UnaryOp.UOP_RAW_REF_MUT: return "raw_mut_ref"
    if op == UnaryOp.UOP_DEREF: return "deref"
    if op == UnaryOp.UOP_TRY: return "try"
    f"uop{op}"

// ── MIR validation (Wave 10 backend contract) ───────────────────

fn mir_index_in_range(idx: i32, len: i32) -> bool:
    idx >= 0 and idx < len

fn mir_span_in_range(start: i32, count: i32, len: i32) -> bool:
    start >= 0 and count >= 0 and start + count <= len

pub fn validate_mir_module(mir_mod: &MirModule) -> str:
    let body_count = mir_mod.bodies.len() as i32
    if body_count != mir_mod.body_fn_syms.len():
        return "bodies/body_fn_syms length mismatch"

    let seen_fn_syms: HashMap[i32, i32] = HashMap.new()
    for bi in 0..body_count:
        let body = &mir_mod.bodies[bi]
        let fn_sym = mir_mod.body_fn_syms[bi]
        if body.fn_sym != fn_sym:
            return f"body_fn_syms mismatch at body index {bi}"
        if fn_sym != 0 and seen_fn_syms.contains(fn_sym):
            return f"duplicate MIR body for fn symbol {fn_sym}"
        if fn_sym != 0:
            seen_fn_syms.insert(fn_sym, 1)
            if not mir_mod.body_index_by_fn_sym.contains(fn_sym):
                return f"missing body index for fn symbol {fn_sym}"
            if mir_mod.body_index_by_fn_sym.get(fn_sym).unwrap() != bi:
                return f"body index map mismatch for fn symbol {fn_sym}"

        let body_err = validate_mir_body(body)
        if body_err.len() > 0:
            let body_label = if fn_sym != 0: f"{fn_sym}" else: f"{bi}"
            return "body[" ++ body_label ++ "]: " ++ body_err

    ""

fn validate_mir_body(body: &MirBody) -> str:
    let local_count = body.local_type_ids.len() as i32
    if local_count <= 0:
        return "missing return local"
    if local_count != body.local_mutables.len():
        return "locals/local_mutables length mismatch"
    if local_count != body.local_names.len():
        return "locals/local_names length mismatch"
    if local_count != body.local_is_user_var.len():
        return "locals/local_is_user_var length mismatch"
    if local_count != body.local_is_global.len():
        return "locals/local_is_global length mismatch"
    if local_count != body.local_is_caller_place.len():
        return "locals/local_is_caller_place length mismatch"
    if body.n_params < 0 or body.n_params > local_count:
        return "invalid n_params"

    let bb_count = body.bb_stmt_starts.len() as i32
    if bb_count <= 0:
        return "missing basic blocks"
    if bb_count != body.bb_stmt_counts.len():
        return "bb_stmt_starts/bb_stmt_counts length mismatch"
    if bb_count != body.bb_term_kinds.len():
        return "bb_stmt_starts/bb_term_kinds length mismatch"
    if bb_count != body.bb_term_d0.len() or
       bb_count != body.bb_term_d1.len() or
       bb_count != body.bb_term_d2.len() or
       bb_count != body.bb_term_d3.len():
        return "bb terminator payload length mismatch"
    if bb_count != body.bb_is_cleanup.len():
        return "bb cleanup flag length mismatch"
    if bb_count != body.bb_term_spans.len():
        return "bb_term_spans length mismatch"
    if bb_count != body.bb_no_suspend_nodes.len():
        return "bb_no_suspend_nodes length mismatch"

    let stmt_count = body.stmt_kinds.len() as i32
    if stmt_count != body.stmt_d0.len() or
       stmt_count != body.stmt_d1.len() or
       stmt_count != body.stmt_spans.len():
        return "statement table length mismatch"

    let place_count = body.place_locals.len() as i32
    if place_count != body.place_proj_starts.len() or
       place_count != body.place_proj_counts.len():
        return "place table length mismatch"

    let proj_count = body.proj_kinds.len() as i32
    if proj_count != body.proj_d0.len():
        return "projection table length mismatch"

    let rval_count = body.rval_kinds.len() as i32
    if rval_count != body.rval_d0.len() or
       rval_count != body.rval_d1.len() or
       rval_count != body.rval_d2.len():
        return "rvalue table length mismatch"

    let operand_count = body.operand_kinds.len() as i32
    if operand_count != body.operand_d0.len():
        return "operand table length mismatch"

    let const_count = body.const_kinds.len() as i32
    if const_count != body.const_d0.len() or
       const_count != body.const_d1.len() or
       const_count != body.const_d2.len() or
       const_count != body.const_types.len():
        return "constant table length mismatch"

    let switch_count = body.switch_table_starts.len() as i32
    if switch_count != body.switch_table_counts.len():
        return "switch table length mismatch"
    if body.switch_table_vals.len() != body.switch_table_targets.len():
        return "switch value/target table length mismatch"

    let agg_count = body.agg_field_starts.len() as i32
    if agg_count != body.agg_field_counts.len():
        return "aggregate field table length mismatch"

    let call_args_count = body.call_arg_starts.len() as i32
    if call_args_count != body.call_arg_counts.len():
        return "call args table length mismatch"
    if call_args_count != body.call_pipeline_receiver_places.len():
        return "call args/pipeline receiver place length mismatch"

    for bb in 0..bb_count:
        let stmt_start = body.bb_stmt_starts[bb]
        let stmt_span_count = body.bb_stmt_counts[bb]
        if not mir_span_in_range(stmt_start, stmt_span_count, stmt_count):
            return f"bb{bb}: statement span out of range (start={stmt_start}, count={stmt_span_count}, total={stmt_count})"

        let term_kind = body.bb_term_kinds[bb]
        let d0 = body.bb_term_d0[bb]
        let d1 = body.bb_term_d1[bb]
        let d2 = body.bb_term_d2[bb]
        let d3 = body.bb_term_d3[bb]

        if term_kind == TermKind.TK_GOTO:
            if not mir_index_in_range(d0, bb_count):
                return f"bb{bb}: goto target out of range"
            continue
        if term_kind == TermKind.TK_RETURN or term_kind == TermKind.TK_UNREACHABLE:
            continue
        if term_kind == TermKind.TK_SWITCH_INT:
            if not mir_index_in_range(d0, operand_count):
                return f"bb{bb}: switch operand out of range"
            if not mir_index_in_range(d1, switch_count):
                return f"bb{bb}: switch table id out of range"
            if d2 != 0 and not mir_index_in_range(d2, bb_count):
                return f"bb{bb}: switch default target out of range"
            continue
        if term_kind == TermKind.TK_CALL:
            if not mir_index_in_range(d0, operand_count):
                return f"bb{bb}: call callee operand out of range"
            if not mir_index_in_range(d1, call_args_count):
                return f"bb{bb}: call arg table id out of range"
            if not mir_index_in_range(d2, place_count):
                return f"bb{bb}: call destination place out of range"
            if not mir_index_in_range(d3, bb_count):
                return f"bb{bb}: call next block out of range"
            continue
        if term_kind == TermKind.TK_DROP_AND_GOTO:
            if not mir_index_in_range(d0, place_count):
                return f"bb{bb}: drop place out of range"
            if not mir_index_in_range(d1, bb_count):
                return f"bb{bb}: drop target out of range"
            continue

        return f"bb{bb}: unknown terminator kind {term_kind}"

    for si in 0..stmt_count:
        let stmt_kind = body.stmt_kinds[si]
        let d0 = body.stmt_d0[si]
        let d1 = body.stmt_d1[si]

        if stmt_kind == StmtKind.Assign:
            if not mir_index_in_range(d0, place_count):
                return f"stmt{si}: assign destination out of range"
            if not mir_index_in_range(d1, rval_count):
                return f"stmt{si}: assign rvalue out of range"
            continue
        if stmt_kind == StmtKind.StorageLive or stmt_kind == StmtKind.StorageDead:
            if not mir_index_in_range(d0, local_count):
                return f"stmt{si}: storage local out of range"
            continue
        if stmt_kind == StmtKind.Drop:
            if not mir_index_in_range(d0, place_count):
                return f"stmt{si}: drop place out of range"
            continue
        if stmt_kind == StmtKind.Nop:
            continue
        return f"stmt{si}: unknown statement kind {stmt_kind}"

    for pi in 0..place_count:
        let local_id = body.place_locals[pi]
        if not mir_index_in_range(local_id, local_count):
            return f"place{pi}: base local out of range"

        let proj_start = body.place_proj_starts[pi]
        let proj_span_count = body.place_proj_counts[pi]
        if not mir_span_in_range(proj_start, proj_span_count, proj_count):
            return f"place{pi}: projection span out of range"

        for ji in 0..proj_span_count:
            let proj_idx = proj_start + ji
            let proj_kind = body.proj_kinds[proj_idx]
            let proj_d0 = body.proj_d0[proj_idx]

            if proj_kind == ProjKind.PK_FIELD:
                if proj_d0 < 0:
                    return f"place{pi}: field projection has negative index"
                continue
            if proj_kind == ProjKind.PK_TUPLE_INDEX:
                if proj_d0 < 0:
                    return f"place{pi}: tuple projection has negative index"
                continue
            if proj_kind == ProjKind.PK_INDEX:
                if not mir_index_in_range(proj_d0, local_count):
                    return f"place{pi}: index projection local out of range"
                continue
            if proj_kind == ProjKind.PK_DEREF:
                continue
            if proj_kind == ProjKind.PK_DOWNCAST:
                if proj_d0 < 0:
                    return f"place{pi}: downcast projection has negative variant index"
                continue

            return f"place{pi}: unknown projection kind {proj_kind}"

    for oi in 0..operand_count:
        let op_kind = body.operand_kinds[oi]
        let d0 = body.operand_d0[oi]
        if op_kind == OperandKind.OK_COPY or op_kind == OperandKind.OK_MOVE:
            if not mir_index_in_range(d0, place_count):
                return f"operand{oi}: place out of range"
            continue
        if op_kind == OperandKind.OK_CONSTANT:
            if not mir_index_in_range(d0, const_count):
                return f"operand{oi}: const out of range"
            continue
        return f"operand{oi}: unknown operand kind {op_kind}"

    for ri in 0..rval_count:
        let rv_kind = body.rval_kinds[ri]
        let d0 = body.rval_d0[ri]
        let d1 = body.rval_d1[ri]
        let d2 = body.rval_d2[ri]

        if rv_kind == RvalueKind.RK_USE:
            if not mir_index_in_range(d0, operand_count):
                return f"rvalue{ri}: use operand out of range (idx={d0}, total={operand_count})"
            continue
        if rv_kind == RvalueKind.RK_BIN_OP:
            if not mir_index_in_range(d1, operand_count) or not mir_index_in_range(d2, operand_count):
                return f"rvalue{ri}: binop operand out of range"
            continue
        if rv_kind == RvalueKind.RK_UN_OP:
            if not mir_index_in_range(d1, operand_count):
                return f"rvalue{ri}: unop operand out of range"
            continue
        if rv_kind == RvalueKind.RK_REF:
            if d0 != BorrowKind.SHARED and d0 != BorrowKind.EXCLUSIVE:
                return f"rvalue{ri}: invalid borrow kind"
            if not mir_index_in_range(d1, place_count):
                return f"rvalue{ri}: ref place out of range"
            continue
        if rv_kind == RvalueKind.RK_ADDR_OF:
            if not mir_index_in_range(d0, place_count):
                return f"rvalue{ri}: addr_of place out of range"
            continue
        if rv_kind == RvalueKind.RK_AGGREGATE:
            if not mir_index_in_range(d1, agg_count):
                return f"rvalue{ri}: aggregate field table out of range"
            continue
        if rv_kind == RvalueKind.RK_DISCRIMINANT:
            if not mir_index_in_range(d0, place_count):
                return f"rvalue{ri}: discriminant place out of range"
            continue
        if rv_kind == RvalueKind.RK_CAST:
            if not mir_index_in_range(d0, operand_count):
                return f"rvalue{ri}: cast operand out of range"
            continue
        if rv_kind == RvalueKind.RK_LEN:
            if not mir_index_in_range(d0, place_count):
                return f"rvalue{ri}: len place out of range"
            continue
        if rv_kind == RvalueKind.RK_ARRAY_FILL:
            if not mir_index_in_range(d0, operand_count):
                return f"rvalue{ri}: array_fill operand out of range"
            continue
        if rv_kind == RvalueKind.RK_STR_CONCAT_N:
            if not mir_index_in_range(d0, call_args_count):
                return f"rvalue{ri}: str_concat_n args out of range"
            continue
        if rv_kind == RvalueKind.RK_SLICE:
            if not mir_index_in_range(d0, place_count):
                return f"rvalue{ri}: slice base place out of range"
            if not mir_index_in_range(d1, operand_count) or not mir_index_in_range(d2, operand_count):
                return f"rvalue{ri}: slice bounds operand out of range"
            continue

        return f"rvalue{ri}: unknown rvalue kind {rv_kind}"

    for ci in 0..const_count:
        let ck = body.const_kinds[ci]
        if ck == ConstKind.CK_INT or ck == ConstKind.CK_BOOL or ck == ConstKind.CK_STR or ck == ConstKind.CK_C_STR or ck == ConstKind.CK_UNIT or ck == ConstKind.CK_FLOAT or ck == ConstKind.CK_ZERO_SIZED or ck == ConstKind.CK_FN or ck == ConstKind.CK_CLOSURE or ck == ConstKind.CK_ASYNC_BLOCK or ck == ConstKind.CK_INT_EXACT or ck == ConstKind.CK_REGEX_LIT:
            continue
        return f"const{ci}: unknown const kind {ck}"

    for ti in 0..switch_count:
        let start = body.switch_table_starts[ti]
        let count = body.switch_table_counts[ti]
        let total = body.switch_table_vals.len() as i32
        if not mir_span_in_range(start, count, total):
            return f"switch table{ti}: span out of range"
        for i in 0..count:
            let target = body.switch_table_targets[(start + i)]
            if not mir_index_in_range(target, bb_count):
                return f"switch table{ti}: target out of range"

    for ai in 0..agg_count:
        let start = body.agg_field_starts[ai]
        let count = body.agg_field_counts[ai]
        let total = body.agg_field_operands.len() as i32
        if not mir_span_in_range(start, count, total):
            return f"aggregate table{ai}: span out of range"
        for i in 0..count:
            let op_idx = body.agg_field_operands[(start + i)]
            if not mir_index_in_range(op_idx, operand_count):
                return f"aggregate table{ai}: operand out of range"

    for ai in 0..call_args_count:
        let start = body.call_arg_starts[ai]
        let count = body.call_arg_counts[ai]
        let total = body.call_arg_operands.len() as i32
        if not mir_span_in_range(start, count, total):
            return f"call args table{ai}: span out of range"
        for i in 0..count:
            let op_idx = body.call_arg_operands[(start + i)]
            if not mir_index_in_range(op_idx, operand_count):
                return f"call args table{ai}: operand out of range"

    ""

pub type MirValidationError {
    fn_sym: i32,
    span: i32,
    message: str,
}

fn mir_validation_ok -> MirValidationError:
    MirValidationError {
        fn_sym: 0,
        span: 0,
        message: "",
    }

fn mir_validation_fail(fn_sym: i32, span: i32, message: &str) -> MirValidationError:
    MirValidationError {
        fn_sym: fn_sym,
        span: span,
        message: with_str_clone_ref(message),
    }

pub fn mir_validation_has_error(err: &MirValidationError) -> bool:
    err.message.len() > 0

fn mir_validate_find_named_type(mir_mod: &MirModule, type_sym: i32) -> i32:
    for ti in 0..mir_mod.sema_type_kinds.len() as i32:
        let tk = mir_mod.sema_type_kinds[ti]
        // Only match TY_STRUCT and TY_ENUM — their d0 stores the name symbol.
        // TY_ALIAS d0 stores the alias TARGET, not the name.
        if tk != TypeKind.TY_STRUCT and tk != TypeKind.TY_ENUM:
            continue
        if mir_mod.sema_type_d0[ti] == type_sym:
            return ti
    0

fn mir_validate_find_int_type(mir_mod: &MirModule, bits: i32, signed: i32) -> i32:
    for ti in 0..mir_mod.sema_type_kinds.len() as i32:
        if mir_mod.sema_type_kinds[ti] != TypeKind.TY_INT:
            continue
        if mir_mod.sema_type_d0[ti] == bits and mir_mod.sema_type_d1[ti] == signed:
            return ti
    0

fn mir_validate_get_generic_inst_arg_count(mir_mod: &MirModule, tid: i32) -> i32:
    mir_mod.mir_get_type_d2(tid)

fn mir_validate_get_generic_inst_arg(mir_mod: &MirModule, tid: i32, index: i32) -> i32:
    let extra_start = mir_mod.mir_get_type_d1(tid)
    mir_mod.mir_get_type_extra(extra_start + index)

fn mir_validate_struct_field_type(mir_mod: &MirModule, struct_tid: i32, field_sym: i32) -> i32:
    let resolved = mir_mod.mir_resolve_alias(struct_tid)
    let tk = mir_mod.mir_get_type_kind(resolved)
    if tk == TypeKind.TY_REF or tk == TypeKind.TY_PTR:
        let inner = mir_mod.mir_get_type_d0(resolved)
        return mir_validate_struct_field_type(mir_mod, inner, field_sym)
    if tk == TypeKind.TY_GENERIC_INST:
        let base_sym = mir_mod.mir_get_type_d0(resolved)
        let base_tid = mir_validate_find_named_type(mir_mod, base_sym)
        if base_tid > 0:
            return mir_validate_struct_field_type(mir_mod, base_tid, field_sym)
        return 0
    if tk != TypeKind.TY_STRUCT:
        return 0
    let extra_start = mir_mod.mir_get_type_d1(resolved)
    let field_count = mir_mod.mir_get_type_d2(resolved)
    for fi in 0..field_count:
        let f_name = mir_mod.mir_get_type_extra(extra_start + fi * 3)
        if f_name == field_sym:
            return mir_mod.mir_get_type_extra(extra_start + fi * 3 + 1)
    0

fn mir_validate_tuple_elem_type(mir_mod: &MirModule, tuple_tid: i32, field_idx: i32) -> i32:
    let resolved = mir_mod.mir_resolve_alias(tuple_tid)
    if mir_mod.mir_get_type_kind(resolved) != TypeKind.TY_TUPLE:
        return 0
    let elem_start = mir_mod.mir_get_type_d0(resolved)
    let elem_count = mir_mod.mir_get_type_d1(resolved)
    if field_idx < 0 or field_idx >= elem_count:
        return 0
    mir_mod.mir_get_type_extra(elem_start + field_idx)

fn mir_validate_indexed_element_type(mir_mod: &MirModule, collection_tid: i32) -> i32:
    let resolved = mir_mod.mir_resolve_alias(collection_tid)
    let tk = mir_mod.mir_get_type_kind(resolved)
    if tk == TypeKind.TY_ARRAY or tk == TypeKind.TY_SLICE:
        return mir_mod.mir_get_type_d0(resolved)
    if tk == TypeKind.TY_STR:
        return mir_validate_find_int_type(mir_mod, 32, 1)
    if tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF:
        return mir_mod.mir_get_type_d0(resolved)
    if tk == TypeKind.TY_GENERIC_INST:
        let base_sym = mir_mod.mir_get_type_d0(resolved)
        if base_sym != 0 and mir_validate_get_generic_inst_arg_count(mir_mod, resolved) > 0:
            return mir_validate_get_generic_inst_arg(mir_mod, resolved, 0)
    0

fn mir_validate_variant_exists(mir_mod: &MirModule, enum_tid: i32, variant_idx: i32) -> bool:
    if variant_idx < 0:
        return false
    let resolved = mir_mod.mir_resolve_alias(enum_tid)
    let tk = mir_mod.mir_get_type_kind(resolved)
    if tk == TypeKind.TY_ENUM:
        return variant_idx < mir_mod.mir_get_type_d2(resolved)
    if tk == TypeKind.TY_GENERIC_INST:
        let base_sym = mir_mod.mir_get_type_d0(resolved)
        let base_tid = mir_validate_find_named_type(mir_mod, base_sym)
        if base_tid > 0 and mir_mod.mir_get_type_kind(base_tid) == TypeKind.TY_ENUM:
            return variant_idx < mir_mod.mir_get_type_d2(base_tid)
    false

fn mir_validate_enum_payload_type(mir_mod: &MirModule, enum_tid: i32, variant_idx: i32, field_idx: i32) -> i32:
    let resolved = mir_mod.mir_resolve_alias(enum_tid)
    let tk = mir_mod.mir_get_type_kind(resolved)
    if variant_idx < 0 or field_idx < 0:
        return 0

    if tk == TypeKind.TY_ENUM:
        let te_start = mir_mod.mir_get_type_d1(resolved)
        let variant_count = mir_mod.mir_get_type_d2(resolved)
        var pos = te_start
        for vi in 0..variant_count:
            let payload_count = mir_mod.mir_get_type_extra(pos + 1)
            if vi == variant_idx:
                if field_idx < payload_count:
                    return mir_mod.mir_get_type_extra(pos + 2 + field_idx)
                return 0
            pos = pos + 2 + payload_count
        return 0

    if tk == TypeKind.TY_GENERIC_INST:
        let base_sym = mir_mod.mir_get_type_d0(resolved)
        let base_tid = mir_validate_find_named_type(mir_mod, base_sym)
        if base_tid <= 0 or mir_mod.mir_get_type_kind(base_tid) != TypeKind.TY_ENUM:
            return 0
        let arg_count = mir_validate_get_generic_inst_arg_count(mir_mod, resolved)
        let te_start = mir_mod.mir_get_type_d1(base_tid)
        let variant_count = mir_mod.mir_get_type_d2(base_tid)

        // Option[T]: one generic arg, exactly one payload-bearing variant.
        // Only Option: a user `G[T]: A(h: H[T])` has the same shape, and
        // the guess named `T` (i64) as the payload `H[T]` (#1442).
        if arg_count == 1 and field_idx == 0 and base_sym == mir_mod.sema_option_sym:
            var pos = te_start
            var payload_variant = -1
            for vi in 0..variant_count:
                let payload_count = mir_mod.mir_get_type_extra(pos + 1)
                if payload_count == 1:
                    payload_variant = vi
                    break
                pos = pos + 2 + payload_count
            if payload_variant == variant_idx:
                return mir_validate_get_generic_inst_arg(mir_mod, resolved, 0)
        // Result[T, E]: two generic args, both variants carry one payload in
        // declaration order. Only Result: ControlFlow[B, C] declares
        // Continue(C) before Break(B), and the positional guess named the
        // wrong argument for it.
        if arg_count == 2 and variant_count == 2 and field_idx == 0 and base_sym == mir_mod.sema_result_sym:
            return mir_validate_get_generic_inst_arg(mir_mod, resolved, variant_idx)

        // Fallback to the erased base payload type for non-substituted generic enums.
        return mir_validate_enum_payload_type(mir_mod, base_tid, variant_idx, field_idx)
    0

fn mir_validate_type_compatible_fast(mir_mod: &MirModule, expected: i32, actual: i32) -> i32:
    if expected <= 0 or actual <= 0:
        return 0
    if expected == actual:
        return 1
    let exp_r = mir_mod.mir_resolve_alias(expected)
    let act_r = mir_mod.mir_resolve_alias(actual)
    if exp_r == act_r:
        return 1
    let exp_k = mir_mod.mir_get_type_kind(exp_r)
    let act_k = mir_mod.mir_get_type_kind(act_r)
    if act_k == TypeKind.TY_NEVER:
        return 1
    if exp_k == TypeKind.TY_STRUCT and act_k == TypeKind.TY_STRUCT:
        return if mir_mod.mir_get_type_d0(exp_r) == mir_mod.mir_get_type_d0(act_r): 1 else: 0
    if exp_k == TypeKind.TY_ENUM and act_k == TypeKind.TY_ENUM:
        return if mir_mod.mir_get_type_d0(exp_r) == mir_mod.mir_get_type_d0(act_r): 1 else: 0
    if (exp_k == TypeKind.TY_FN and act_k == TypeKind.TY_FN) or (exp_k == TypeKind.TY_EXTERN_FN and act_k == TypeKind.TY_EXTERN_FN) or (exp_k == TypeKind.TY_FN and act_k == TypeKind.TY_EXTERN_FN) or (exp_k == TypeKind.TY_EXTERN_FN and act_k == TypeKind.TY_FN):
        // Sema does not intern fn types canonically; mirror its structural
        // fn_types_compatible rule (d0=params extra, d1=count, d2=ret).
        if mir_mod.mir_get_type_d1(exp_r) != mir_mod.mir_get_type_d1(act_r):
            return 0
        let fn_param_count = mir_mod.mir_get_type_d1(exp_r)
        let exp_ps = mir_mod.mir_get_type_d0(exp_r)
        let act_ps = mir_mod.mir_get_type_d0(act_r)
        for fpi in 0..fn_param_count:
            if mir_validate_type_compatible_fast(mir_mod, mir_mod.mir_get_type_extra(exp_ps + fpi), mir_mod.mir_get_type_extra(act_ps + fpi)) == 0:
                return 0
        return mir_validate_type_compatible_fast(mir_mod, mir_mod.mir_get_type_d2(exp_r), mir_mod.mir_get_type_d2(act_r))
    if exp_k == TypeKind.TY_GENERIC_INST and act_k == TypeKind.TY_GENERIC_INST:
        if mir_mod.mir_get_type_d0(exp_r) == mir_mod.mir_get_type_d0(act_r):
            let arg_count = mir_validate_get_generic_inst_arg_count(mir_mod, exp_r)
            if arg_count == mir_validate_get_generic_inst_arg_count(mir_mod, act_r):
                for ai in 0..arg_count:
                    let exp_arg = mir_validate_get_generic_inst_arg(mir_mod, exp_r, ai)
                    let act_arg = mir_validate_get_generic_inst_arg(mir_mod, act_r, ai)
                    if mir_validate_type_compatible_fast(mir_mod, exp_arg, act_arg) == 0:
                        return 0
                return 1
        return 0
    if exp_k == TypeKind.TY_GENERIC_INST and (act_k == TypeKind.TY_STRUCT or act_k == TypeKind.TY_ENUM):
        return if mir_mod.mir_get_type_d0(exp_r) == mir_mod.mir_get_type_d0(act_r): 1 else: 0
    if (exp_k == TypeKind.TY_STRUCT or exp_k == TypeKind.TY_ENUM) and act_k == TypeKind.TY_GENERIC_INST:
        return if mir_mod.mir_get_type_d0(exp_r) == mir_mod.mir_get_type_d0(act_r): 1 else: 0
    if exp_k == TypeKind.TY_PTR and act_k == TypeKind.TY_PTR:
        return mir_validate_type_compatible_fast(mir_mod, mir_mod.mir_get_type_d0(exp_r), mir_mod.mir_get_type_d0(act_r))
    if exp_k == TypeKind.TY_PTR and act_k == TypeKind.TY_REF:
        return mir_validate_type_compatible_fast(mir_mod, mir_mod.mir_get_type_d0(exp_r), mir_mod.mir_get_type_d0(act_r))
    if exp_k == TypeKind.TY_REF and act_k == TypeKind.TY_REF:
        return mir_validate_type_compatible_fast(mir_mod, mir_mod.mir_get_type_d0(exp_r), mir_mod.mir_get_type_d0(act_r))
    if exp_k == TypeKind.TY_REF and act_k == TypeKind.TY_PTR:
        return mir_validate_type_compatible_fast(mir_mod, mir_mod.mir_get_type_d0(exp_r), mir_mod.mir_get_type_d0(act_r))
    if exp_k == TypeKind.TY_SLICE and act_k == TypeKind.TY_SLICE:
        return mir_validate_type_compatible_fast(mir_mod, mir_mod.mir_get_type_d0(exp_r), mir_mod.mir_get_type_d0(act_r))
    if exp_k == TypeKind.TY_ARRAY and act_k == TypeKind.TY_ARRAY:
        if mir_mod.mir_get_type_d1(exp_r) != mir_mod.mir_get_type_d1(act_r):
            return 0
        return mir_validate_type_compatible_fast(mir_mod, mir_mod.mir_get_type_d0(exp_r), mir_mod.mir_get_type_d0(act_r))
    if exp_k == TypeKind.TY_TUPLE and act_k == TypeKind.TY_TUPLE:
        let exp_count = mir_mod.mir_get_type_d1(exp_r)
        let act_count = mir_mod.mir_get_type_d1(act_r)
        if exp_count != act_count:
            return 0
        let exp_start = mir_mod.mir_get_type_d0(exp_r)
        let act_start = mir_mod.mir_get_type_d0(act_r)
        for ei in 0..exp_count:
            if mir_validate_type_compatible_fast(mir_mod, mir_mod.mir_get_type_extra(exp_start + ei), mir_mod.mir_get_type_extra(act_start + ei)) == 0:
                return 0
        return 1
    // Primitive types: same kind means compatible (str, int, bool, float, void)
    if exp_k == act_k:
        if exp_k == TypeKind.TY_STR or exp_k == TypeKind.TY_BOOL or exp_k == TypeKind.TY_VOID:
            return 1
        if exp_k == TypeKind.TY_INT:
            // Same width and signedness
            return if mir_mod.mir_get_type_d0(exp_r) == mir_mod.mir_get_type_d0(act_r) and mir_mod.mir_get_type_d1(exp_r) == mir_mod.mir_get_type_d1(act_r): 1 else: 0
        if exp_k == TypeKind.TY_FLOAT:
            return if mir_mod.mir_get_type_d0(exp_r) == mir_mod.mir_get_type_d0(act_r): 1 else: 0
    0

fn mir_validate_use_assign_compatible(mir_mod: &MirModule, expected: i32, actual: i32) -> bool:
    if mir_validate_type_compatible_fast(mir_mod, expected, actual) != 0:
        return true
    let expected_inner = mir_validate_distinct_inner(mir_mod, expected)
    if expected_inner > 0 and expected_inner != expected:
        if mir_validate_use_assign_compatible(mir_mod, expected_inner, actual):
            return true
    let actual_inner = mir_validate_distinct_inner(mir_mod, actual)
    if actual_inner > 0 and actual_inner != actual:
        if mir_validate_use_assign_compatible(mir_mod, expected, actual_inner):
            return true
    let expected_kind = mir_mod.mir_get_type_kind(mir_mod.mir_resolve_alias(expected))
    let actual_kind = mir_mod.mir_get_type_kind(mir_mod.mir_resolve_alias(actual))
    if expected_kind == TypeKind.TY_INT and actual_kind == TypeKind.TY_ENUM:
        let actual_repr = mir_validate_enum_repr_type(mir_mod, actual)
        return actual_repr > 0 and mir_validate_type_compatible_fast(mir_mod, expected, actual_repr) != 0
    if expected_kind == TypeKind.TY_ENUM and actual_kind == TypeKind.TY_INT:
        let expected_repr = mir_validate_enum_repr_type(mir_mod, expected)
        return expected_repr > 0 and mir_validate_type_compatible_fast(mir_mod, expected_repr, actual) != 0
    // §10.6/§10.8: a shared ref to a CONCRETE type may assign into a
    // ref-to-dyn destination — the RK_REF/use of `&x` in ref-to-dyn position
    // is the fat-pointer build (codegen keys on the DESTINATION type; sema
    // vetted the impl). The validator undermodeled the documented coercion
    // and rejected `accept(&eng)` for `fn accept(g: &dyn Greet)`.
    if expected_kind == TypeKind.TY_REF and actual_kind == TypeKind.TY_REF:
        let expected_pointee = mir_mod.mir_resolve_alias(mir_mod.mir_get_type_d0(mir_mod.mir_resolve_alias(expected)))
        if mir_mod.mir_get_type_kind(expected_pointee) == TypeKind.TY_TRAIT_OBJ:
            return true
    // §3.9: Box[Concrete] use into a Box[dyn Trait] destination — the vetted
    // box-dyn coercion (sema's std-box arm in types_compatible; codegen keys
    // the fat build on the destination type). Mirror sema's rule: std-Box
    // base on both sides, one argument, destination argument a trait object.
    if expected_kind == TypeKind.TY_GENERIC_INST and actual_kind == TypeKind.TY_GENERIC_INST and mir_mod.sema_box_sym != 0:
        let box_exp_r = mir_mod.mir_resolve_alias(expected)
        let box_act_r = mir_mod.mir_resolve_alias(actual)
        if mir_mod.mir_get_type_d0(box_exp_r) == mir_mod.sema_box_sym and mir_mod.mir_get_type_d0(box_act_r) == mir_mod.sema_box_sym:
            if mir_validate_get_generic_inst_arg_count(mir_mod, box_exp_r) == 1 and mir_validate_get_generic_inst_arg_count(mir_mod, box_act_r) == 1:
                let box_exp_arg = mir_mod.mir_resolve_alias(mir_validate_get_generic_inst_arg(mir_mod, box_exp_r, 0))
                if mir_mod.mir_get_type_kind(box_exp_arg) == TypeKind.TY_TRAIT_OBJ:
                    return true
    // §16.10: a raw pointer (or extern-fn pointer) use into an
    // Option[pointer] destination — the vetted option-pointer coercion
    // (sema's is_option_pointer_type arm; niche-encoded, codegen stores the
    // pointer bits directly). Mirror sema's rule.
    if expected_kind == TypeKind.TY_GENERIC_INST and (actual_kind == TypeKind.TY_PTR or actual_kind == TypeKind.TY_EXTERN_FN) and mir_mod.sema_option_sym != 0:
        let opt_exp_r = mir_mod.mir_resolve_alias(expected)
        if mir_mod.mir_get_type_d0(opt_exp_r) == mir_mod.sema_option_sym and mir_validate_get_generic_inst_arg_count(mir_mod, opt_exp_r) == 1:
            let opt_payload = mir_mod.mir_resolve_alias(mir_validate_get_generic_inst_arg(mir_mod, opt_exp_r, 0))
            let opt_pk = mir_mod.mir_get_type_kind(opt_payload)
            if opt_pk == TypeKind.TY_PTR or opt_pk == TypeKind.TY_EXTERN_FN:
                return true
    let expected_numeric = expected_kind == TypeKind.TY_INT or expected_kind == TypeKind.TY_FLOAT
    let actual_numeric = actual_kind == TypeKind.TY_INT or actual_kind == TypeKind.TY_FLOAT
    expected_numeric and actual_numeric

fn mir_validate_enum_repr_type(mir_mod: &MirModule, tid: i32) -> i32:
    let resolved = mir_mod.mir_resolve_alias(tid)
    if mir_mod.mir_get_type_kind(resolved) != TypeKind.TY_ENUM:
        return 0
    let repr = mir_mod.sema_disc_repr_types.get(resolved)
    if repr.is_some(): repr.unwrap() else: 0

fn mir_validate_distinct_inner(mir_mod: &MirModule, tid: i32) -> i32:
    let resolved = mir_mod.mir_resolve_alias(tid)
    if mir_mod.mir_get_type_kind(resolved) != TypeKind.TY_STRUCT:
        return 0
    let name_sym = mir_mod.mir_get_type_d0(resolved)
    if name_sym == 0 or not mir_mod.sema_distinct_type_names.contains(name_sym):
        return 0
    if mir_mod.mir_get_type_d2(resolved) != 1:
        return 0
    let extra_start = mir_mod.mir_get_type_d1(resolved)
    mir_mod.mir_get_type_extra(extra_start + 1)

fn mir_validate_single_field_inner(mir_mod: &MirModule, tid: i32) -> i32:
    let resolved = mir_mod.mir_resolve_alias(tid)
    if mir_mod.mir_get_type_kind(resolved) != TypeKind.TY_STRUCT:
        return 0
    if mir_mod.mir_get_type_d2(resolved) != 1:
        return 0
    let extra_start = mir_mod.mir_get_type_d1(resolved)
    mir_mod.mir_get_type_extra(extra_start + 1)

// The variant payload type when operand `operand_id` reads an enum payload
// (a field under a downcast) whose declared type disagrees with it; else 0.
fn mir_validate_payload_read_mismatch(mir_mod: &MirModule, body: &MirBody, operand_id: i32, declared_ty: i32) -> i32:
    if operand_id < 0 or operand_id >= body.operand_kinds.len(): return 0
    let op_kind = body.operand_kinds[operand_id]
    if op_kind != OperandKind.OK_COPY and op_kind != OperandKind.OK_MOVE: return 0
    let place_id = body.operand_d0[operand_id]
    if place_id < 0 or place_id >= body.place_locals.len(): return 0
    let proj_count = body.place_proj_counts[place_id]
    if proj_count < 2: return 0
    let last = body.place_proj_starts[place_id] + proj_count - 1
    if body.proj_kinds[last] != ProjKind.PK_FIELD or body.proj_kinds[last - 1] != ProjKind.PK_DOWNCAST: return 0
    // Only where the variant's payload type is exact: a plain enum, or an
    // Option or Result instance. Another generic enum's payload is a type
    // parameter this module cannot substitute.
    let enum_ty = mir_mod.mir_resolve_alias(mir_validate_place_prefix_type(mir_mod, body, place_id, 2))
    let enum_kind = mir_mod.mir_get_type_kind(enum_ty)
    if enum_kind == TypeKind.TY_GENERIC_INST:
        let base_sym = mir_mod.mir_get_type_d0(enum_ty)
        if base_sym == 0 or (base_sym != mir_mod.sema_result_sym and base_sym != mir_mod.sema_option_sym): return 0
    else if enum_kind != TypeKind.TY_ENUM:
        return 0
    let derived = mir_validate_place_derived_type(mir_mod, body, place_id)
    if derived <= 0 or mir_validate_use_assign_compatible(mir_mod, declared_ty, derived) or mir_validate_use_assign_compatible(mir_mod, derived, declared_ty): return 0
    derived

pub fn mir_validate_place_type(mir_mod: &MirModule, body: &MirBody, place_id: i32) -> i32:
    if place_id < 0 or place_id >= body.place_locals.len():
        return 0
    if place_id < body.place_sema_types.len():
        let stored = body.place_sema_types[place_id]
        if stored > 0:
            return stored
    mir_validate_place_derived_type(mir_mod, body, place_id)

// The type a place's projections yield from its local's type, ignoring the
// type the lowering declared for it; 0 when the walk cannot resolve one.
pub fn mir_validate_place_derived_type(mir_mod: &MirModule, body: &MirBody, place_id: i32) -> i32:
    mir_validate_place_prefix_type(mir_mod, body, place_id, 0)

// The same walk stopped `trailing` projections short of the place's end.
fn mir_validate_place_prefix_type(mir_mod: &MirModule, body: &MirBody, place_id: i32, trailing: i32) -> i32:
    if place_id < 0 or place_id >= body.place_locals.len():
        return 0
    let local_id = body.place_locals[place_id]
    if local_id < 0 or local_id >= body.local_type_ids.len():
        return 0
    var current_ty: i32 = body.local_type_ids[local_id]
    let proj_start = body.place_proj_starts[place_id]
    let proj_count = body.place_proj_counts[place_id] - trailing
    if proj_count <= 0:
        return current_ty
    var active_variant_idx = -1

    for pi in 0..proj_count:
        let proj_kind = body.proj_kinds[(proj_start + pi)]
        let proj_d0 = body.proj_d0[(proj_start + pi)]
        let resolved = mir_mod.mir_resolve_alias(current_ty)
        let tk = mir_mod.mir_get_type_kind(resolved)

        if proj_kind == ProjKind.PK_DOWNCAST:
            if not mir_validate_variant_exists(mir_mod, current_ty, proj_d0):
                return 0
            // A place that ends in a downcast is not a value (#1381).
            if pi == proj_count - 1:
                return 0
            active_variant_idx = proj_d0
            continue

        if proj_kind == ProjKind.PK_FIELD:
            var field_ty = 0
            if active_variant_idx >= 0:
                field_ty = mir_validate_enum_payload_type(mir_mod, current_ty, active_variant_idx, proj_d0)
            else if tk == TypeKind.TY_TUPLE:
                field_ty = mir_validate_tuple_elem_type(mir_mod, current_ty, proj_d0)
            else if tk == TypeKind.TY_ARRAY or tk == TypeKind.TY_SLICE:
                // Constant-index element projection: slice-pattern lowering
                // spells array elements as field places (proj_d0 = index).
                field_ty = mir_mod.mir_get_type_d0(resolved)
            else:
                field_ty = mir_validate_struct_field_type(mir_mod, current_ty, proj_d0)
            if field_ty == 0:
                return 0
            current_ty = field_ty
            active_variant_idx = -1
            continue

        if proj_kind == ProjKind.PK_TUPLE_INDEX:
            let field_ty = mir_validate_tuple_elem_type(mir_mod, current_ty, proj_d0)
            if field_ty == 0:
                return 0
            current_ty = field_ty
            active_variant_idx = -1
            continue

        if proj_kind == ProjKind.PK_INDEX:
            let elem_ty = mir_validate_indexed_element_type(mir_mod, current_ty)
            if elem_ty == 0:
                return 0
            current_ty = elem_ty
            active_variant_idx = -1
            continue

        if proj_kind == ProjKind.PK_DEREF:
            if tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF:
                current_ty = mir_mod.mir_get_type_d0(resolved)
                active_variant_idx = -1
                continue
            return 0

        return 0

    current_ty

pub fn mir_validate_operand_type(mir_mod: &MirModule, body: &MirBody, operand_id: i32) -> i32:
    if operand_id < 0 or operand_id >= body.operand_kinds.len():
        return 0
    let op_kind = body.operand_kinds[operand_id]
    let d0 = body.operand_d0[operand_id]
    if op_kind == OperandKind.OK_CONSTANT:
        if d0 >= 0 and d0 < body.const_types.len():
            return body.const_types[d0]
        return 0
    if op_kind == OperandKind.OK_COPY or op_kind == OperandKind.OK_MOVE:
        return mir_validate_place_type(mir_mod, body, d0)
    0

// #1180: nothing coerces to or from Unit, so a Unit operand is a valid call
// argument only when the callee's own parameter is Unit. A named callee with
// a body in the module states its parameter types; one without a body is a
// runtime or extern function, which never takes Unit (an f-string once handed
// `fmt_to_str` a Unit call result and printed the register). Intrinsics and
// indirect callees are not judged. Returns the offending argument index or -1.
fn mir_validate_call_unit_argument(mir_mod: &MirModule, body: &MirBody, callee_operand: i32, call_id: i32) -> i32:
    if call_id < 0 or call_id >= body.call_arg_starts.len() or body.call_intrinsic(call_id) != MirIntrinsic.NONE: return -1
    if callee_operand < 0 or callee_operand >= body.operand_kinds.len() or body.operand_kinds[callee_operand] != OperandKind.OK_CONSTANT: return -1
    let callee_const = body.operand_d0[callee_operand]
    if callee_const < 0 or callee_const >= body.const_kinds.len() or body.const_kinds[callee_const] != ConstKind.CK_FN: return -1
    let callee_idx = mir_mod.find_body(body.const_d0[callee_const])
    let arg_start = body.call_arg_starts[call_id]
    for ai in 0..body.call_arg_counts[call_id]:
        let arg_ty = mir_validate_operand_type(mir_mod, body, body.call_arg_operands[arg_start + ai])
        if arg_ty <= 0 or mir_mod.mir_get_type_kind(mir_mod.mir_resolve_alias(arg_ty)) != TypeKind.TY_VOID: continue
        if callee_idx < 0: return ai
        let callee = &mir_mod.bodies[callee_idx]
        if ai >= callee.n_params: continue
        let param_ty = callee.local_type_ids[ai + 1]
        if param_ty > 0 and mir_mod.mir_get_type_kind(mir_mod.mir_resolve_alias(param_ty)) != TypeKind.TY_VOID: return ai
    -1

// #1443: a monomorphized generic call whose argument is the value `T` where
// the callee's parameter is `&T` lost a borrow. A direct call may pass the
// place value and let codegen take its address (a struct's LLVM type is not a
// pointer), but a generic receiver's `&Self` must be the reference itself: a
// std Box and `&Box` both lower to `ptr`, so codegen passed the Box as the
// reference and the callee read through the wrong pointer (the contract
// lower_generic_receiver_arg states). Returns the argument index, else -1.
fn mir_validate_call_missing_borrow(mir_mod: &MirModule, body: &MirBody, callee_operand: i32, call_id: i32) -> i32:
    if call_id < 0 or call_id >= body.call_arg_starts.len(): return -1
    if body.call_intrinsic(call_id) != MirIntrinsic.GENERIC_CALL: return -1
    if callee_operand < 0 or callee_operand >= body.operand_kinds.len() or body.operand_kinds[callee_operand] != OperandKind.OK_CONSTANT: return -1
    let callee_const = body.operand_d0[callee_operand]
    if callee_const < 0 or callee_const >= body.const_kinds.len() or body.const_kinds[callee_const] != ConstKind.CK_FN: return -1
    let mono = body.call_mono_sym(call_id)
    let callee_idx = mir_mod.find_body(if mono != 0: mono else: body.const_d0[callee_const])
    if callee_idx < 0: return -1
    let callee = &mir_mod.bodies[callee_idx]
    let arg_start = body.call_arg_starts[call_id]
    for ai in 0..body.call_arg_counts[call_id]:
        if ai >= callee.n_params: break
        let param_ty = mir_mod.mir_resolve_alias(callee.local_type_ids[ai + 1])
        if mir_mod.mir_get_type_kind(param_ty) != TypeKind.TY_REF: continue
        let arg_ty = mir_validate_operand_type(mir_mod, body, body.call_arg_operands[arg_start + ai])
        if arg_ty <= 0: continue
        let arg_resolved = mir_mod.mir_resolve_alias(arg_ty)
        let arg_kind = mir_mod.mir_get_type_kind(arg_resolved)
        if arg_kind == TypeKind.TY_REF or arg_kind == TypeKind.TY_PTR: continue
        if arg_resolved == mir_mod.mir_resolve_alias(mir_mod.mir_get_type_d0(param_ty)): return ai
    -1

// #2023 (D22/D27): a Copy view (`&T`, T scalar) passed where the callee's
// parameter is the owned scalar `T` was never materialized: Sema records the
// owned demand and MIR reads the pointee (`copy _n.*`). `"ab".slice(0, xs[0])`
// passed the element view itself, the validators said ok, and codegen failed
// ("wrong argument type actual=ptr expected=i64"). A str intrinsic's index or
// count parameters are i64 (with_str_slice_ref, with_str_byte_at_ref,
// with_str_repeat_ref); a direct call's parameters are its callee body's.
// Returns the argument index, else -1.
fn mir_validate_call_unmaterialized_view(mir_mod: &MirModule, body: &MirBody, callee_operand: i32, call_id: i32) -> i32:
    if call_id < 0 or call_id >= body.call_arg_starts.len(): return -1
    let arg_start = body.call_arg_starts[call_id]
    let arg_count = body.call_arg_counts[call_id]
    let intrinsic = body.call_intrinsic(call_id)
    let str_index_args = if intrinsic == MirIntrinsic.STR_SLICE: 2 else if intrinsic == MirIntrinsic.STR_BYTE_AT or intrinsic == MirIntrinsic.STR_REPEAT: 1 else: 0
    if str_index_args > 0:
        for ai in 1..(str_index_args + 1):
            if ai >= arg_count: break
            if mir_validate_is_scalar_view(mir_mod, mir_validate_operand_type(mir_mod, body, body.call_arg_operands[arg_start + ai])): return ai
        return -1
    if intrinsic != MirIntrinsic.NONE: return -1
    if callee_operand < 0 or callee_operand >= body.operand_kinds.len() or body.operand_kinds[callee_operand] != OperandKind.OK_CONSTANT: return -1
    let callee_const = body.operand_d0[callee_operand]
    if callee_const < 0 or callee_const >= body.const_kinds.len() or body.const_kinds[callee_const] != ConstKind.CK_FN: return -1
    let callee_idx = mir_mod.find_body(body.const_d0[callee_const])
    if callee_idx < 0: return -1
    let callee = &mir_mod.bodies[callee_idx]
    for ai in 0..arg_count:
        if ai >= callee.n_params: break
        let param_kind = mir_mod.mir_get_type_kind(mir_mod.mir_resolve_alias(callee.local_type_ids[ai + 1]))
        if param_kind != TypeKind.TY_INT and param_kind != TypeKind.TY_FLOAT and param_kind != TypeKind.TY_BOOL: continue
        if mir_validate_is_scalar_view(mir_mod, mir_validate_operand_type(mir_mod, body, body.call_arg_operands[arg_start + ai])): return ai
    -1

// A `&T` whose pointee is an int, float or bool.
fn mir_validate_is_scalar_view(mir_mod: &MirModule, ty: i32) -> bool:
    if ty <= 0: return false
    let resolved = mir_mod.mir_resolve_alias(ty)
    if mir_mod.mir_get_type_kind(resolved) != TypeKind.TY_REF: return false
    let pointee_kind = mir_mod.mir_get_type_kind(mir_mod.mir_resolve_alias(mir_mod.mir_get_type_d0(resolved)))
    pointee_kind == TypeKind.TY_INT or pointee_kind == TypeKind.TY_FLOAT or pointee_kind == TypeKind.TY_BOOL

// #1627: the enum aggregate's form of a missing borrow — a payload operand
// that is a value where the variant's payload is a reference to it.
// `Option[&Ctx].Some(ctx)` stored `move ctx` into the `&Ctx` slot and every
// validator passed it; only analyze's use-after-kill saw the blanked `ctx`.
// Returns the payload index, or -1.
fn mir_validate_aggregate_missing_borrow(mir_mod: &MirModule, body: &MirBody, enum_ty: i32, variant_idx: i32, fields_id: i32) -> i32:
    if fields_id < 0 or fields_id >= body.agg_field_starts.len(): return -1
    let start = body.agg_field_starts[fields_id]
    for fi in 0..body.agg_field_counts[fields_id]:
        let payload_ty = mir_mod.mir_resolve_alias(mir_validate_enum_payload_type(mir_mod, enum_ty, variant_idx, fi))
        if payload_ty <= 0 or mir_mod.mir_get_type_kind(payload_ty) != TypeKind.TY_REF: continue
        let arg_ty = mir_validate_operand_type(mir_mod, body, body.agg_field_operands[start + fi])
        if arg_ty <= 0: continue
        let arg_resolved = mir_mod.mir_resolve_alias(arg_ty)
        let arg_kind = mir_mod.mir_get_type_kind(arg_resolved)
        if arg_kind == TypeKind.TY_REF or arg_kind == TypeKind.TY_PTR: continue
        if arg_resolved == mir_mod.mir_resolve_alias(mir_mod.mir_get_type_d0(payload_ty)): return fi
    -1

// #2019: the eager intrinsics whose codegen loop invokes a closure argument
// on the calling fiber once per element (and stops at an invocation that
// left by a cancellation unwind, when MIR marks the call).
// The terminals and `next` calls that drive a lazy adapter chain are the
// same: the chain's closures run inside them.
pub fn mir_intrinsic_invokes_closure(intrinsic: MirIntrinsic) -> bool:
    if intrinsic == MirIntrinsic.VEC_MAP or intrinsic == MirIntrinsic.VEC_FILTER or intrinsic == MirIntrinsic.VEC_FOLD:
        return true
    if intrinsic == MirIntrinsic.ITER_FOLD or intrinsic == MirIntrinsic.ITER_REDUCE or intrinsic == MirIntrinsic.ITER_SUM or intrinsic == MirIntrinsic.ITER_PRODUCT or intrinsic == MirIntrinsic.ITER_MIN or intrinsic == MirIntrinsic.ITER_MAX or intrinsic == MirIntrinsic.ITER_MIN_BY or intrinsic == MirIntrinsic.ITER_MAX_BY or intrinsic == MirIntrinsic.ITER_FIND or intrinsic == MirIntrinsic.ITER_POSITION or intrinsic == MirIntrinsic.ITER_ANY or intrinsic == MirIntrinsic.ITER_ALL or intrinsic == MirIntrinsic.ITER_NONE or intrinsic == MirIntrinsic.ITER_FOR_EACH or intrinsic == MirIntrinsic.ITER_COUNT or intrinsic == MirIntrinsic.ITER_COLLECT or intrinsic == MirIntrinsic.ITER_PARTITION or intrinsic == MirIntrinsic.ITER_UNZIP:
        return true
    intrinsic == MirIntrinsic.MAPITER_NEXT or intrinsic == MirIntrinsic.FILTERITER_NEXT or intrinsic == MirIntrinsic.FILTERMAPITER_NEXT or intrinsic == MirIntrinsic.TAKEITER_NEXT or intrinsic == MirIntrinsic.DROPITER_NEXT or intrinsic == MirIntrinsic.TAKEWHILEITER_NEXT or intrinsic == MirIntrinsic.DROPWHILEITER_NEXT or intrinsic == MirIntrinsic.ZIPITER_NEXT or intrinsic == MirIntrinsic.ENUMERATEITER_NEXT or intrinsic == MirIntrinsic.CHAINITER_NEXT or intrinsic == MirIntrinsic.ZIPWITHITER_NEXT or intrinsic == MirIntrinsic.STEPBYITER_NEXT or intrinsic == MirIntrinsic.FLATMAPITER_NEXT

// The `const fn` symbol a call terminator invokes, or 0 when the callee is
// a place (an indirect call) or a unit operand (an intrinsic with no callee).
pub fn mir_call_const_fn_sym(body: &MirBody, callee_operand: i32) -> i32:
    if callee_operand < 0 or callee_operand >= body.operand_kinds.len() or body.operand_kinds[callee_operand] != OperandKind.OK_CONSTANT: return 0
    let callee_const = body.operand_d0[callee_operand]
    if callee_const < 0 or callee_const >= body.const_kinds.len() or body.const_kinds[callee_const] != ConstKind.CK_FN: return 0
    body.const_d0[callee_const]

// D65 / #1639: a `const fn` callee names a function Sema accepts as a call
// target, or a body of this module, or the call carries an intrinsic mark
// codegen dispatches on. Nothing else reaches codegen: #1635's `r(21)` —
// a GENERIC_CALL to a symbol named after a callable binding, with the
// argument dropped — passed every validator and died in codegen. The
// snapshot (`sema_callable_syms`) is Sema's fact, propagated at lowering;
// this check names no builtin itself. A NONE-marked direct call needs a
// signature or a body: a generic template cannot be called without the
// concrete contract a GENERIC_CALL carries. Returns "" when the callee is
// accounted for.
fn mir_validate_call_callee_known(mir_mod: &MirModule, body: &MirBody, callee_operand: i32, call_id: i32) -> str:
    if call_id < 0 or call_id >= body.call_arg_starts.len(): return ""
    let intrinsic = body.call_intrinsic(call_id)
    if intrinsic != MirIntrinsic.NONE and intrinsic != MirIntrinsic.GENERIC_CALL: return ""
    let sym = mir_call_const_fn_sym(body, callee_operand)
    if sym == 0:
        if callee_operand < 0 or callee_operand >= body.operand_kinds.len() or body.operand_kinds[callee_operand] != OperandKind.OK_CONSTANT: return ""
        return f"call has a constant callee that is no function symbol and no intrinsic mark (intrinsic={intrinsic as i32})"
    if intrinsic == MirIntrinsic.GENERIC_CALL and (body.call_is_machinery_dispatch(call_id) or body.call_sig_index(call_id) >= 0 or body.call_mono_sym(call_id) != 0): return ""
    if mir_mod.find_body(sym) >= 0: return ""
    let class = mir_mod.sema_callable_syms.get(sym)
    if class.is_none():
        return f"call to symbol {sym} names no function Sema knows: no signature, no generic template, no intrinsic, and no body in the module (intrinsic={intrinsic as i32}, args={body.call_arg_counts[call_id]}); the callee was re-derived from a spelling, not read from Sema (D65, #1639)"
    if intrinsic == MirIntrinsic.NONE and class.unwrap() != MirCallableClass.Signature as i32:
        return f"direct call to symbol {sym} (callable class {class.unwrap()}) without a GENERIC_CALL mark: a generic template or builtin needs the concrete contract that mark carries"
    ""

// D65 / #1647 phase 1 (audit:resolution): Sema's answer for one MIR call.
// AnalysisResolution gathers it from Sema; mir_resolution_check_call
// compares it with the MIR without Sema, so a planted body and a planted
// answer exercise the comparison alone (test/internals).
pub enum CalleeResolutionKind: i32:
    Unknown = 0
    Signature = 1
    Generic = 2
    Intrinsic = 3
    Callable = 4
    Body = 5

impl Copy for CalleeResolutionKind

pub type CalleeResolution {
    kind: CalleeResolutionKind,
    // Sema's name for the callee (for the report), "" when it has none.
    name: str,
    // The parameter count Sema states, or -1 when it states no fixed count
    // (a variadic signature, an extern fn type).
    param_count: i32,
    // Sema's signature index for a Signature answer, else -1.
    sig: i32,
    // Sema's symbol for the callee (its own pool), else 0.
    sym: i32,
    // The signature Sema resolved the call's own AST node to
    // (resolved_call_sigs), else -1: a call node Sema resolved to one
    // function must not lower to another.
    node_sig: i32,
}

pub fn callee_resolution_unknown() -> CalleeResolution:
    CalleeResolution { kind: CalleeResolutionKind.Unknown, name: "", param_count: -1, sig: -1, sym: 0, node_sig: -1 }

fn callee_resolution_kind_name(kind: CalleeResolutionKind) -> str:
    if kind == CalleeResolutionKind.Signature: return "signature"
    if kind == CalleeResolutionKind.Generic: return "generic template"
    if kind == CalleeResolutionKind.Intrinsic: return "builtin"
    if kind == CalleeResolutionKind.Callable: return "callable value"
    if kind == CalleeResolutionKind.Body: return "module body"
    "unresolved"

// The D65 rule broken, named for the report: what MIR resolved, what Sema
// resolved, and the rule. "" when the call agrees with Sema. `bb` is the
// block whose terminator is the call.
// D65 phase 3 (#1647): a place lowered from a source field access against
// Sema's facts for the node. Types arrive alias-resolved; bases with their
// references and raw pointers peeled. "" when they agree.
pub fn mir_field_place_verdict(proj_kind: i32, proj_field: i32, node_field: i32, mir_ty: i32, sema_ty: i32, mir_base: i32, sema_base: i32) -> str:
    if proj_kind != ProjKind.PK_FIELD and proj_kind != ProjKind.PK_TUPLE_INDEX:
        return f"field access lowered to a place whose last projection is not a field (kind {proj_kind})"
    if proj_kind == ProjKind.PK_FIELD and proj_field != node_field:
        return "MIR projects a different field than the node names"
    if sema_ty > 0 and mir_ty > 0 and sema_ty != mir_ty:
        return f"field place type (ty {mir_ty}) disagrees with Sema's type for the node (ty {sema_ty})"
    if sema_base > 0 and mir_base > 0 and sema_base != mir_base:
        return f"field base is ty {mir_base} in MIR, ty {sema_base} after Sema's autoderef"
    ""

// D65 phase 4 (#1647): one call argument's transfer against Sema's
// ownership of the parameter. `named_owned_place`: the operand reads a
// named binding's place of a non-Copy type (a statement temporary — an
// explicit `move x` into a borrowing parameter, a `copy x` clone — is the
// form that exists to differ). "" when they agree.
pub fn mir_call_arg_transfer_verdict(operand_kind: i32, named_owned_place: bool, sema_borrows: bool, sema_consumes: bool) -> str:
    if not named_owned_place:
        return ""
    if operand_kind == OperandKind.OK_MOVE and sema_borrows:
        return "MIR moves an argument into a parameter Sema borrows: the caller's binding is reset while it still owns the value"
    if operand_kind == OperandKind.OK_COPY and sema_consumes:
        return "MIR copies an owned argument into a parameter Sema consumes: two owners of one value"
    ""

// D65 phase 3 (#1647): an immutable non-Copy `let` against Sema's binding
// category. "" when MIR materializes what Sema bound.
pub fn mir_let_binding_verdict(mir_alias: bool, sema_place_view: bool) -> str:
    if mir_alias and not sema_place_view:
        return "MIR binds the name as an alias of a place; Sema bound it as an owner"
    if sema_place_view and not mir_alias:
        return "Sema bound the name as a view of a place; MIR gives it an owning local"
    ""

// #1647 (D65): a place lowered from a source index expression against
// Sema's facts for the node. Types arrive alias-resolved: `sema_ty` is
// Sema's type of the node and `sema_view_target` its referent when Sema
// typed the element read as a view (D27: `xs[i]` denotes the element
// place, typed `&T` where a view is demanded); bases with references and
// raw pointers peeled. "" when they agree.
pub fn mir_index_place_verdict(proj_kind: i32, mir_ty: i32, sema_ty: i32, sema_view_target: i32, mir_base: i32, sema_base: i32) -> str:
    if proj_kind != ProjKind.PK_INDEX:
        return f"index expression lowered to a place whose last projection is not an index (kind {proj_kind})"
    if sema_ty > 0 and mir_ty > 0 and mir_ty != sema_ty and mir_ty != sema_view_target:
        return f"element place type (ty {mir_ty}) disagrees with Sema's type for the node (ty {sema_ty})"
    if sema_base > 0 and mir_base > 0 and sema_base != mir_base:
        return f"indexed base is ty {mir_base} in MIR, ty {sema_base} in Sema"
    ""

// #1647 (D65): a named field projection's declaration index against the
// index Sema resolved the source field access to. "" when they agree.
pub fn mir_field_decl_verdict(mir_decl: i32, sema_decl: i32) -> str:
    if mir_decl < 0:
        return f"field projection carries no declaration index; Sema resolved the field to declaration index {sema_decl}"
    if mir_decl != sema_decl:
        return f"field projection carries declaration index {mir_decl}; Sema resolved the field to {sema_decl}"
    ""

// #1647 (D65): the place an aliasing `let` names against Sema's view
// origins for its value — the bindings Sema recorded the view depends on.
// `root_name_in_origins`: the alias place's root local is one of them.
pub fn mir_view_origin_verdict(sema_has_origins: bool, root_named: bool, root_name_in_origins: bool) -> str:
    if sema_has_origins and root_named and not root_name_in_origins:
        return "MIR aliases a place rooted at a binding Sema did not record as the view's origin"
    ""

// MirBody.anonymous_capture_kinds.
pub const MIR_CAPTURE_LOCAL: i32 = 0
pub const MIR_CAPTURE_SNAPSHOT: i32 = 1
pub const MIR_CAPTURE_PLACE_REF: i32 = 2
pub const MIR_CAPTURE_PROTOCOL: i32 = 3

// #1647 (D62/D65): one closure capture's MIR materialization against
// Sema's capture mode. "" when they agree.
pub fn mir_capture_verdict(mir_kind: i32, sema_by_place: bool) -> str:
    if mir_kind == MIR_CAPTURE_SNAPSHOT and sema_by_place:
        return "MIR snapshots a capture Sema holds by place: the closure reads a copy the creating frame never sees written"
    if mir_kind == MIR_CAPTURE_PLACE_REF and not sema_by_place:
        return "MIR captures a reference to a place Sema has the closure take by value"
    ""

// D65 phase 5 (#2043): a direct call lowered from a source call against
// the function Sema resolved the call to (comp_resolved): a facade's C
// name is its bridge or its variadic case (D64, D66), and a call MIR
// lowered by its own reading of the spelling calls the raw declaration.
// `mir_sym` is MIR's callee in Sema's pool; "" when they agree.
pub fn mir_resolved_callee_verdict(mir_sym: i32, sema_sym: i32, spelled_sym: i32) -> str:
    if sema_sym == 0 or mir_sym == sema_sym:
        return ""
    if mir_sym == spelled_sym:
        return "MIR calls the function the call spells; Sema resolved the call to another (D65: AST spelling -> resolved callee after Sema)"
    "MIR calls a function Sema did not resolve the call to (D65: one call target per call)"

// D65 phase 5 (#2043): a call whose value Sema converts
// (call_value_conversions: a presented text view, §16.2b.8) against the
// MIR: its result reaches a call of the conversion. "" when it does.
pub fn mir_value_conversion_verdict(converted: bool) -> str:
    if converted:
        return ""
    "Sema converts the call's value through a function MIR never hands the result to: the program reads the callee's raw result as the call's value"

pub fn mir_resolution_check_call(mir_mod: &MirModule, body: &MirBody, bb: i32, answer: &CalleeResolution) -> str:
    let callee_operand = body.term_data0(bb)
    let call_id = body.term_data1(bb)
    if call_id < 0 or call_id >= body.call_arg_starts.len(): return ""
    let intrinsic = body.call_intrinsic(call_id)
    let argc = body.call_arg_counts[call_id]
    let sym = mir_call_const_fn_sym(body, callee_operand)
    let callee_kind = if callee_operand >= 0 and callee_operand < body.operand_kinds.len(): body.operand_kinds[callee_operand] else: -1
    let is_place = callee_kind == OperandKind.OK_COPY or callee_kind == OperandKind.OK_MOVE
    // An intrinsic call is recognized by its kind; its callee operand is
    // documentation ("the CK_FN sym is meaningless — codegen dispatches by
    // intrinsic kind"). DYN_CALL resolves its method through the vtable.
    if intrinsic != MirIntrinsic.NONE and intrinsic != MirIntrinsic.GENERIC_CALL:
        return ""
    if intrinsic == MirIntrinsic.GENERIC_CALL and body.call_is_machinery_dispatch(call_id):
        return ""
    if is_place:
        if answer.kind != CalleeResolutionKind.Callable:
            return f"MIR calls through a place with {argc} argument(s), Sema resolved this call as " ++ callee_resolution_kind_name(answer.kind) ++ (if answer.name.len() > 0: " `" ++ answer.name ++ "`" else: "") ++ " — an indirect call needs Sema's callable type for the call (call_callable_types); the callee's meaning was re-derived by MIR (D65: MIR local-table lookup -> meaning of a name)"
        if answer.param_count >= 0 and argc != answer.param_count:
            return f"MIR calls through a place with {argc} argument(s), Sema's callable type takes {answer.param_count} (D65: Sema owns the call target; #1639's silent case)"
        return ""
    if sym == 0:
        return f"call with no callee symbol and no intrinsic mark (intrinsic={intrinsic as i32}, args={argc})"
    let mir_name = if answer.name.len() > 0: with_str_clone_ref(answer.name) else: f"symbol {sym}"
    if answer.kind == CalleeResolutionKind.Unknown:
        return "MIR calls `" ++ mir_name ++ f"` directly (intrinsic={intrinsic as i32}, args={argc}), Sema knows no such function: no signature, no generic template, no builtin, no callable binding for this call, no body in the module — the callee was re-derived from the AST spelling after Sema (D65; #1635, #1639)"
    if answer.kind == CalleeResolutionKind.Callable:
        return "MIR calls `" ++ mir_name ++ f"` directly (intrinsic={intrinsic as i32}, args={argc}), Sema resolved this call as an indirect call through a callable value taking {answer.param_count} argument(s) — a function was invented from a binding's name (D65: AST spelling -> resolved callee; #1635)"
    if answer.kind == CalleeResolutionKind.Generic and intrinsic != MirIntrinsic.GENERIC_CALL:
        return "MIR calls generic template `" ++ mir_name ++ f"` directly with no GENERIC_CALL mark (args={argc}); Sema resolved a generic call, which needs the concrete contract that mark carries (D65)"
    if answer.kind == CalleeResolutionKind.Intrinsic and intrinsic != MirIntrinsic.GENERIC_CALL:
        return "MIR calls builtin `" ++ mir_name ++ f"` as an ordinary function (intrinsic=NONE, args={argc}); Sema resolved a builtin, which the builtin branch marks GENERIC_CALL (D65)"
    if answer.kind == CalleeResolutionKind.Signature:
        let sig = body.call_sig_index(call_id)
        let mono = body.call_mono_sym(call_id)
        if sig >= 0 and answer.sig >= 0 and sig != answer.sig and mono == 0:
            return "MIR recorded contract signature " ++ f"{sig}" ++ " for its call to `" ++ mir_name ++ "`, Sema's signature for that symbol is " ++ f"{answer.sig}" ++ " (D65: one contract per call)"
        if answer.node_sig >= 0 and answer.sig >= 0 and answer.node_sig != answer.sig and mono == 0:
            return "Sema resolved this call node to signature " ++ f"{answer.node_sig}" ++ ", MIR calls `" ++ mir_name ++ "` (signature " ++ f"{answer.sig}" ++ ") (D65: AST spelling -> resolved callee after Sema)"
        if answer.param_count >= 0 and argc != answer.param_count:
            return "MIR passes " ++ f"{argc}" ++ " argument(s) to `" ++ mir_name ++ "`, Sema's signature takes " ++ f"{answer.param_count}" ++ " (D65; #1639's silent case)"
    ""

// #1230: a call through a fn-typed VALUE passes exactly the arguments its
// type declares; codegen adds the environment pointer itself. A lowering
// that consulted a same-named module fn appended that fn's `loc = src()`
// default and only LLVM's verifier objected. Extern fn types (variadic)
// and named callees are not judged here. Returns the declared count when
// the call disagrees with it, else -1.
fn mir_validate_indirect_call_arity(mir_mod: &MirModule, body: &MirBody, callee_operand: i32, call_id: i32) -> i32:
    if call_id < 0 or call_id >= body.call_arg_starts.len() or body.call_intrinsic(call_id) != MirIntrinsic.NONE: return -1
    if callee_operand < 0 or callee_operand >= body.operand_kinds.len(): return -1
    let callee_kind = body.operand_kinds[callee_operand]
    if callee_kind != OperandKind.OK_COPY and callee_kind != OperandKind.OK_MOVE: return -1
    let callee_ty = mir_validate_operand_type(mir_mod, body, callee_operand)
    if callee_ty <= 0: return -1
    let resolved = mir_mod.mir_resolve_alias(callee_ty)
    if mir_mod.mir_get_type_kind(resolved) != TypeKind.TY_FN: return -1
    let declared = mir_mod.mir_get_type_d1(resolved)
    if body.call_arg_counts[call_id] == declared: return -1
    declared

fn mir_validate_is_compare_op(op: i32) -> bool:
    op == BinaryOp.OP_EQ or op == BinaryOp.OP_NEQ or op == BinaryOp.OP_LT or op == BinaryOp.OP_GT or op == BinaryOp.OP_LTE or op == BinaryOp.OP_GTE

fn mir_validate_compare_sensitive_type(mir_mod: &MirModule, tid: i32) -> bool:
    if tid <= 0:
        return false
    let resolved = mir_mod.mir_resolve_alias(tid)
    let tk = mir_mod.mir_get_type_kind(resolved)
    tk == TypeKind.TY_STR or tk == TypeKind.TY_STRUCT or tk == TypeKind.TY_ENUM or tk == TypeKind.TY_GENERIC_INST or tk == TypeKind.TY_ARRAY or tk == TypeKind.TY_SLICE or tk == TypeKind.TY_TUPLE

fn mir_validate_cast_supported(mir_mod: &MirModule, src_ty: i32, dst_ty: i32) -> bool:
    if src_ty <= 0 or dst_ty <= 0:
        return true
    let src_inner = mir_validate_single_field_inner(mir_mod, src_ty)
    if src_inner > 0 and src_inner != src_ty:
        if mir_validate_cast_supported(mir_mod, src_inner, dst_ty):
            return true
    let dst_inner = mir_validate_single_field_inner(mir_mod, dst_ty)
    if dst_inner > 0 and dst_inner != dst_ty:
        if mir_validate_cast_supported(mir_mod, src_ty, dst_inner):
            return true
    let src_resolved = mir_mod.mir_resolve_alias(src_ty)
    let dst_resolved = mir_mod.mir_resolve_alias(dst_ty)
    let src_kind = mir_mod.mir_get_type_kind(src_resolved)
    let dst_kind = mir_mod.mir_get_type_kind(dst_resolved)
    // §4.4a (#1770): an enum's number is its discriminant, read by
    // RK_DISCRIMINANT (MirLower.lower_cast); codegen has no arm for a cast
    // from the enum value, and this rule let one through to it.
    if src_kind == TypeKind.TY_ENUM and (dst_kind == TypeKind.TY_INT or dst_kind == TypeKind.TY_FLOAT):
        return false
    if mir_validate_type_compatible_fast(mir_mod, dst_ty, src_ty) != 0 or
       mir_validate_type_compatible_fast(mir_mod, src_ty, dst_ty) != 0:
        return true
    if src_kind == TypeKind.TY_NEVER:
        return true
    if src_kind == TypeKind.TY_INT and dst_kind == TypeKind.TY_ENUM:
        return true
    if src_kind == TypeKind.TY_PTR or src_kind == TypeKind.TY_REF or
       dst_kind == TypeKind.TY_PTR or dst_kind == TypeKind.TY_REF:
        return true
    if src_kind == TypeKind.TY_STR:
        // `s as []u8` (D64 needed it: a str is the bytes a buffer pairing
        // takes): the same {ptr, len} over the same storage, a byte view —
        // codegen coerces the two-field aggregate (coerce_struct_value).
        if dst_kind == TypeKind.TY_SLICE:
            let elem = mir_mod.mir_resolve_alias(mir_mod.mir_get_type_d0(dst_resolved))
            return mir_mod.mir_get_type_kind(elem) == TypeKind.TY_INT and mir_mod.mir_get_type_d0(elem) == 8 and mir_mod.mir_get_type_d1(elem) == 0
        return dst_kind == TypeKind.TY_PTR or dst_kind == TypeKind.TY_REF or dst_kind == TypeKind.TY_STR
    if src_kind == TypeKind.TY_STRUCT or src_kind == TypeKind.TY_ENUM or src_kind == TypeKind.TY_GENERIC_INST or src_kind == TypeKind.TY_ARRAY or src_kind == TypeKind.TY_SLICE or src_kind == TypeKind.TY_TUPLE:
        // Allow bitpacked struct ↔ integer casts
        if src_kind == TypeKind.TY_STRUCT and dst_kind == TypeKind.TY_INT:
            if mir_mod.mir_is_bitpacked(src_resolved as i32):
                return true
        if dst_kind == TypeKind.TY_STRUCT and src_kind == TypeKind.TY_INT:
            if mir_mod.mir_is_bitpacked(dst_resolved as i32):
                return true
        return false
    true

// #1464: a field or tuple projection names a component of an aggregate. A
// scalar has none; the place's declared type hid the error — `copy _7.f0`
// read a Task handle's fiber id out of a local MIR typed as the awaited i32,
// declared as i32, and passed verification.
fn mir_validate_scalar_field_projection(mir_mod: &MirModule, body: &MirBody) -> str:
    for place in 0..body.place_locals.len() as i32:
        let proj_count = body.place_proj_counts[place]
        let proj_start = body.place_proj_starts[place]
        for pi in 0..proj_count:
            let kind = body.proj_kinds[(proj_start + pi)]
            if kind != ProjKind.PK_FIELD and kind != ProjKind.PK_TUPLE_INDEX:
                continue
            let base_ty = mir_validate_place_prefix_type(mir_mod, body, place, proj_count - pi)
            if base_ty <= 0:
                continue
            let base_kind = mir_mod.mir_get_type_kind(mir_mod.mir_resolve_alias(base_ty))
            if base_kind == TypeKind.TY_INT or base_kind == TypeKind.TY_FLOAT or base_kind == TypeKind.TY_BOOL or base_kind == TypeKind.TY_VOID or base_kind == TypeKind.TY_NEVER:
                return f"place {mir_place_text(body, place)} projects component {body.proj_d0[(proj_start + pi)]} of a scalar (ty={base_ty})"
    ""

// #1464: the fiber intrinsics take a task handle. A handle in a local typed
// as the awaited value (`async fn f(): 1` typed its calls `i32`) is a Task
// stored where MIR believes a T lives.
fn mir_validate_task_operand(mir_mod: &MirModule, body: &MirBody, call_id: i32) -> str:
    if call_id < 0 or call_id >= body.call_arg_starts.len():
        return ""
    let intrinsic = body.call_intrinsic(call_id)
    if intrinsic != MirIntrinsic.FIBER_AWAIT and intrinsic != MirIntrinsic.FIBER_CANCEL:
        return ""
    if body.call_arg_counts[call_id] <= 0 or mir_mod.sema_task_sym == 0:
        return ""
    let task_ty = mir_validate_operand_type(mir_mod, body, body.call_arg_operands[body.call_arg_starts[call_id]])
    if task_ty <= 0:
        return ""
    var resolved = mir_mod.mir_resolve_alias(task_ty)
    if mir_mod.mir_get_type_kind(resolved) == TypeKind.TY_REF:
        resolved = mir_mod.mir_resolve_alias(mir_mod.mir_get_type_d0(resolved))
    if mir_mod.mir_get_type_kind(resolved) == TypeKind.TY_GENERIC_INST:
        let base = mir_mod.mir_get_type_d0(resolved)
        if base == mir_mod.sema_task_sym or base == mir_mod.sema_scoped_task_sym:
            return ""
    f"fiber intrinsic's task operand is ty={task_ty}, not a Task or ScopedTask handle"

// #1735: a body's parameter locals are its signature's parameters, in
// order (locals 1..=n_params). The generator constructor for `gen mut fn
// tick(times: i32)` allocated a temporary between them, so `times` was read
// from a `&Counter` slot and the loop ran zero times; validate-all and
// audit:all both passed, since no validator compared a body with its
// signature. The signature is Sema's (sema_sig_param_starts); a closure
// or a body Sema has no signature for is not judged.
fn mir_validate_body_params(mir_mod: &MirModule, body: &MirBody) -> str:
    if body.fn_sym == 0 or body.anonymous_type != 0:
        return ""
    let count = mir_sig_param_count(mir_mod, body.fn_sym)
    if count < 0:
        return ""
    if count != body.n_params:
        return f"the body has {body.n_params} parameter local(s), its signature {count} parameter(s)"
    for pi in 0..count:
        let sig_ty = mir_sig_param_type(mir_mod, body.fn_sym, pi)
        let local_ty = if pi + 1 < body.local_type_ids.len(): body.local_type_ids[pi + 1] else: 0
        if sig_ty <= 0 or local_ty <= 0:
            continue
        if mir_mod.mir_resolve_alias(sig_ty) != mir_mod.mir_resolve_alias(local_ty):
            return f"parameter {pi} is local _{pi + 1} of ty={local_ty}, but the signature's parameter {pi} is ty={sig_ty}"
    ""

pub fn validate_typed_mir_body(mir_mod: &MirModule, body: &MirBody) -> MirValidationError:
    let scalar_projection = mir_validate_scalar_field_projection(mir_mod, body)
    if scalar_projection.len() > 0:
        return mir_validation_fail(body.fn_sym, 0, scalar_projection)
    let params = mir_validate_body_params(mir_mod, body)
    if params.len() > 0:
        return mir_validation_fail(body.fn_sym, 0, params)
    // #2108: after Sema every local has a concrete type. A generic
    // declaration with its type parameters unbound has no layout; codegen
    // failed on one (`var best = None`) while this validator said ok.
    for li in 0..body.local_type_ids.len() as i32:
        if mir_mod.sema_uninstantiated_generic_types.contains(mir_mod.mir_resolve_alias(body.local_type_ids[li])):
            return mir_validation_fail(body.fn_sym, 0, f"local _{li} has ty={body.local_type_ids[li]}, a generic declaration with no type arguments")
    let stmt_count = body.stmt_count()
    for si in 0..stmt_count:
        let stmt_kind = body.stmt_kinds[si]
        let d0 = body.stmt_d0[si]
        let d1 = body.stmt_d1[si]
        let span = body.stmt_spans[si]

        if stmt_kind == StmtKind.Assign:
            let dest_ty = mir_validate_place_type(mir_mod, body, d0)
            if dest_ty == 0:
                return mir_validation_fail(body.fn_sym, span, "assign destination does not resolve to a concrete MIR type")
            if d1 < 0 or d1 >= body.rval_kinds.len():
                return mir_validation_fail(body.fn_sym, span, "assign rvalue is out of range during typed MIR verification")
            let rk = body.rval_kinds[d1]
            let rv_d0 = body.rval_d0[d1]
            let rv_d1 = body.rval_d1[d1]
            let rv_d2 = body.rval_d2[d1]

            if rk == RvalueKind.RK_USE:
                let src_ty = mir_validate_operand_type(mir_mod, body, rv_d0)
                if src_ty == 0:
                    var src_detail = "non-place operand"
                    let src_op_kind = if rv_d0 >= 0 and rv_d0 < body.operand_kinds.len(): body.operand_kinds[rv_d0] else: -1
                    if src_op_kind == OperandKind.OK_COPY or src_op_kind == OperandKind.OK_MOVE:
                        let sp = body.operand_d0[rv_d0]
                        let sl = body.place_locals[sp]
                        let slt = if sl >= 0 and sl < body.local_type_ids.len(): body.local_type_ids[sl] else: -1
                        let spc = body.place_proj_counts[sp]
                        let pk0 = if spc > 0: body.proj_kinds[body.place_proj_starts[sp]] else: -1
                        src_detail = f"place local={sl} local_ty={slt} projs={spc} proj0_kind={pk0}"
                    return mir_validation_fail(body.fn_sym, span, f"use rvalue does not resolve to a concrete MIR type ({src_detail})")
                // A declared place type is a claim, not a proof: an enum payload
                // read must agree with the variant's payload type. `?` over
                // `Result[Unit, E]` declared the Unit payload as the whole Result
                // and this verifier passed it to codegen, which trapped in LLVM.
                let payload_mismatch = mir_validate_payload_read_mismatch(mir_mod, body, rv_d0, src_ty)
                if payload_mismatch != 0:
                    return mir_validation_fail(body.fn_sym, span, f"enum payload read declares ty={src_ty} but the variant's payload is ty={payload_mismatch}")
                if not mir_validate_use_assign_compatible(mir_mod, dest_ty, src_ty):
                    let dk = mir_mod.mir_get_type_kind(mir_mod.mir_resolve_alias(dest_ty)) as i32
                    let sk = mir_mod.mir_get_type_kind(mir_mod.mir_resolve_alias(src_ty)) as i32
                    return mir_validation_fail(body.fn_sym, span, f"use rvalue type is incompatible with assign destination (dest ty={dest_ty} kind={dk}, src ty={src_ty} kind={sk})")
            else if rk == RvalueKind.RK_AGGREGATE:
                // #1229: a slice is a view of storage that already exists; no
                // lowering builds one from fields. An aggregate into a
                // slice-typed place is element data misread as {ptr, len}
                // (`first([5, 6])` reached codegen this way and segfaulted).
                if mir_mod.mir_get_type_kind(mir_mod.mir_resolve_alias(dest_ty)) == TypeKind.TY_SLICE:
                    return mir_validation_fail(body.fn_sym, span, f"aggregate assigned to a slice-typed place (ty={dest_ty}); a slice is produced by `slice`, never built from fields")
                // #1455 (§4.4a): an enum aggregate names its variant by index —
                // the payload layout and the downcast key; codegen writes that
                // variant's discriminant as the tag. A discriminant here
                // (`Move(i32, i32) = 7` built as variant 7 of 2) reached codegen,
                // which found no payload type for variant 7.
                let agg_enum = mir_mod.mir_resolve_alias(dest_ty)
                if rv_d0 == 1 and mir_mod.mir_get_type_kind(agg_enum) == TypeKind.TY_ENUM:
                    let variant_count = mir_mod.mir_get_type_d2(agg_enum)
                    if rv_d2 < 0 or rv_d2 >= variant_count:
                        return mir_validation_fail(body.fn_sym, span, f"enum aggregate names variant {rv_d2} of a ty={dest_ty} enum with {variant_count} variants; an aggregate carries the variant index, not its discriminant")
                if rv_d0 == 1:
                    let unborrowed = mir_validate_aggregate_missing_borrow(mir_mod, body, dest_ty, rv_d2, rv_d1)
                    if unborrowed >= 0:
                        return mir_validation_fail(body.fn_sym, span, f"enum payload {unborrowed} is a value where the variant's payload is a reference to it (a missing borrow)")
            else if rk == RvalueKind.RK_ARRAY_FILL:
                // #1814 (§2.3): a fill copies ONE evaluation into N slots; for a
                // non-Copy element that is N owners of one value. MirLower
                // builds such a fill as a loop of evaluations; this verifier
                // said ok while `[s.clone(); 65]` segfaulted.
                let fill_arr = mir_mod.mir_resolve_alias(dest_ty)
                if mir_mod.mir_get_type_kind(fill_arr) != TypeKind.TY_ARRAY:
                    return mir_validation_fail(body.fn_sym, span, f"array_fill assigned to a non-array place (ty={dest_ty})")
                let fill_elem = mir_mod.mir_get_type_d0(fill_arr)
                if mir_mod.sema_non_copy_fill_types.contains(fill_elem):
                    return mir_validation_fail(body.fn_sym, span, f"array_fill of a non-Copy element (ty={fill_elem}) copies one value into every slot: N owners of one value (§2.3); a non-Copy fill evaluates its value once per element")
            else if rk == RvalueKind.RK_REF:
                if mir_validate_place_type(mir_mod, body, rv_d1) == 0:
                    return mir_validation_fail(body.fn_sym, span, "ref rvalue does not resolve to a concrete place type")
            else if rk == RvalueKind.RK_ADDR_OF or rk == RvalueKind.RK_DISCRIMINANT or rk == RvalueKind.RK_LEN:
                let rv_place_ty = mir_validate_place_type(mir_mod, body, rv_d0)
                if rv_place_ty == 0:
                    return mir_validation_fail(body.fn_sym, span, "place-based rvalue does not resolve to a concrete place type")
                // #1444 (§4.4a): a discriminant enum's discriminant is a value
                // of its repr type; a narrower or wider destination reads or
                // writes the wrong bytes (a u8 discriminant stored into an
                // i32 temp picked the wrong match arm).
                if rk == RvalueKind.RK_DISCRIMINANT:
                    let repr = mir_validate_enum_repr_type(mir_mod, rv_place_ty)
                    if repr != 0 and mir_mod.mir_resolve_alias(dest_ty) != mir_mod.mir_resolve_alias(repr):
                        return mir_validation_fail(body.fn_sym, span, f"discriminant of a ty={rv_place_ty} enum is its repr ty={repr}, assigned to ty={dest_ty}")
            else if rk == RvalueKind.RK_SLICE:
                if mir_validate_place_type(mir_mod, body, rv_d0) == 0:
                    return mir_validation_fail(body.fn_sym, span, "slice base does not resolve to a concrete place type")
                if mir_validate_operand_type(mir_mod, body, rv_d1) == 0 or mir_validate_operand_type(mir_mod, body, rv_d2) == 0:
                    return mir_validation_fail(body.fn_sym, span, "slice bounds do not resolve to concrete MIR types")

            if rk == RvalueKind.RK_BIN_OP and (rv_d0 == BinaryOp.OP_IN or rv_d0 == BinaryOp.OP_NOT_IN):
                return mir_validation_fail(body.fn_sym, span, "membership operator must be lowered before MIR codegen")

            if rk == RvalueKind.RK_BIN_OP and mir_validate_is_compare_op(rv_d0):
                let lhs_ty = mir_validate_operand_type(mir_mod, body, rv_d1)
                let rhs_ty = mir_validate_operand_type(mir_mod, body, rv_d2)
                if lhs_ty > 0 and rhs_ty > 0 and
                   mir_validate_compare_sensitive_type(mir_mod, lhs_ty) and
                   mir_validate_compare_sensitive_type(mir_mod, rhs_ty) and
                   mir_validate_type_compatible_fast(mir_mod, lhs_ty, rhs_ty) == 0 and
                   mir_validate_type_compatible_fast(mir_mod, rhs_ty, lhs_ty) == 0:
                    let lhs_kind = mir_mod.mir_get_type_kind(mir_mod.mir_resolve_alias(lhs_ty)) as i32
                    let rhs_kind = mir_mod.mir_get_type_kind(mir_mod.mir_resolve_alias(rhs_ty)) as i32
                    return mir_validation_fail(body.fn_sym, span, f"comparison operands have incompatible MIR types (lhs ty={lhs_ty} kind={lhs_kind}, rhs ty={rhs_ty} kind={rhs_kind})")

            if rk == RvalueKind.RK_CAST:
                let src_ty = if rv_d2 > 0: rv_d2 else: mir_validate_operand_type(mir_mod, body, rv_d0)
                let cast_ty = if rv_d1 > 0: rv_d1 else: dest_ty
                if src_ty > 0 and cast_ty > 0 and not mir_validate_cast_supported(mir_mod, src_ty, cast_ty):
                    let src_kind = mir_mod.mir_get_type_kind(mir_mod.mir_resolve_alias(src_ty))
                    let cast_kind = mir_mod.mir_get_type_kind(mir_mod.mir_resolve_alias(cast_ty))
                    return mir_validation_fail(body.fn_sym, span, f"unsupported cast in MIR (src ty={src_ty} kind={src_kind}, target ty={cast_ty} kind={cast_kind})")
            continue

        if stmt_kind == StmtKind.Drop:
            if mir_validate_place_type(mir_mod, body, d0) == 0:
                return mir_validation_fail(body.fn_sym, span, "drop target does not resolve to a concrete MIR type")

    let bb_count = body.block_count()
    for bb in 0..bb_count:
        let term_kind = body.bb_term_kinds[bb]
        let d0 = body.bb_term_d0[bb]
        let d1 = body.bb_term_d1[bb]
        let d2 = body.bb_term_d2[bb]
        let span = body.bb_term_spans[bb]

        if term_kind == TermKind.TK_SWITCH_INT:
            if mir_validate_operand_type(mir_mod, body, d0) == 0:
                return mir_validation_fail(body.fn_sym, span, "switch operand does not resolve to a concrete MIR type")
            continue

        if term_kind == TermKind.TK_CALL:
            let dest_ty = mir_validate_place_type(mir_mod, body, d2)
            let resolved_dest = mir_mod.mir_resolve_alias(dest_ty)
            let dest_is_unit = dest_ty > 0 and mir_mod.mir_get_type_kind(resolved_dest) == TypeKind.TY_VOID
            if body.call_intrinsic(d1) == MirIntrinsic.VEC_PUSH and not dest_is_unit:
                return mir_validation_fail(body.fn_sym, span, "Vec.push call destination must be Unit")
            let task_operand = mir_validate_task_operand(mir_mod, body, d1)
            if task_operand.len() > 0:
                return mir_validation_fail(body.fn_sym, span, task_operand)
            let unit_arg = mir_validate_call_unit_argument(mir_mod, body, d0, d1)
            if unit_arg >= 0:
                return mir_validation_fail(body.fn_sym, span, f"call argument {unit_arg} is Unit but the callee parameter is not")
            let declared_arity = mir_validate_indirect_call_arity(mir_mod, body, d0, d1)
            if declared_arity >= 0:
                return mir_validation_fail(body.fn_sym, span, f"indirect call passes {body.call_arg_counts[d1]} argument(s) but the callee's fn type declares {declared_arity}")
            let unborrowed = mir_validate_call_missing_borrow(mir_mod, body, d0, d1)
            if unborrowed >= 0:
                return mir_validation_fail(body.fn_sym, span, f"call argument {unborrowed} is a value where the callee parameter is a reference to it (a missing borrow)")
            let unmaterialized = mir_validate_call_unmaterialized_view(mir_mod, body, d0, d1)
            if unmaterialized >= 0:
                return mir_validation_fail(body.fn_sym, span, f"call argument {unmaterialized} is a Copy view (&T) where the callee parameter is the owned scalar T: the owned demand was not materialized (#2023)")
            let unknown_callee = mir_validate_call_callee_known(mir_mod, body, d0, d1)
            if unknown_callee.len() > 0:
                return mir_validation_fail(body.fn_sym, span, unknown_callee)

            let carrier_place = body.call_pipeline_receiver_place(d1)
            if carrier_place >= 0:
                if not dest_is_unit:
                    return mir_validation_fail(body.fn_sym, span, "D21 receiver-place pipeline call destination must be Unit")
                if carrier_place >= body.place_locals.len():
                    return mir_validation_fail(body.fn_sym, span, "D21 pipeline carrier place is out of range")
                let arg_start = body.call_arg_starts[d1]
                let arg_count = body.call_arg_counts[d1]
                if arg_count <= 0:
                    return mir_validation_fail(body.fn_sym, span, "D21 receiver-place pipeline call has no receiver argument")
                let recv_operand = body.call_arg_operands[arg_start]
                let recv_kind = body.operand_kinds[recv_operand]
                if recv_kind != OperandKind.OK_COPY and recv_kind != OperandKind.OK_MOVE:
                    return mir_validation_fail(body.fn_sym, span, "D21 pipeline receiver argument is not a place operand")
                if body.operand_d0[recv_operand] != carrier_place:
                    return mir_validation_fail(body.fn_sym, span, "D21 pipeline carrier is not the call receiver place")
            continue

    mir_validation_ok()

pub fn validate_typed_mir_module(mir_mod: &MirModule) -> MirValidationError:
    let shape_err = validate_mir_module(mir_mod)
    if shape_err.len() > 0:
        return mir_validation_fail(0, 0, shape_err)
    for bi in 0..mir_mod.bodies.len():
        let body = &mir_mod.bodies[bi]
        if body.lowering_failed != 0:
            continue
        let err = validate_typed_mir_body(mir_mod, body)
        if mir_validation_has_error(err):
            return err
    mir_validation_ok()
