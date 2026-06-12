// Mir — Wave 7 MIR data model, builders, and deterministic dump rendering.
//
// This module owns the MIR in-memory representation used after semantic
// analysis. MIR is intentionally explicit and deterministic.

use Ast
use InternPool
use Sema

type BlockId = distinct i32
impl Copy for BlockId

extern fn with_i64_to_str(n: i64) -> str
extern fn str_from_byte(b: i32) -> str
extern fn with_write(s: str) -> Unit

fn lbrace -> str:
    str_from_byte(123)

fn rbrace -> str:
    str_from_byte(125)

// ── Statement kinds ──────────────────────────────────────────────

enum StmtKind: i32:
    Assign = 0
    StorageLive = 1
    StorageDead = 2
    Drop = 3
    Nop = 4

// ── Terminator kinds ─────────────────────────────────────────────

enum TermKind: i32:
    TK_GOTO = 0
    TK_RETURN = 1
    TK_UNREACHABLE = 2
    TK_SWITCH_INT = 3
    TK_CALL = 4
    TK_DROP_AND_GOTO = 5
    // Temporary terminator used only before generator lowering. Backends must
    // not receive MIR containing TK_YIELD.
    TK_YIELD = 6

// ── Rvalue kinds ─────────────────────────────────────────────────

enum RvalueKind: i32:
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

enum OperandKind: i32:
    OK_COPY = 0
    OK_MOVE = 1
    OK_CONSTANT = 2

// ── Constant kinds ───────────────────────────────────────────────

enum ConstKind: i32:
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

// ── Call intrinsic kinds ─────────────────────────────────────────
// Attached to TermKind.TK_CALL terminators to mark known container/builtin
// operations. Both LLVM and C backends read these instead of
// inferring builtin kind from method names at codegen time.

enum MirIntrinsic: i32:
    NONE
    VEC_NEW
    VEC_PUSH
    VEC_GET
    VEC_LEN
    VEC_SET
    VEC_REMOVE
    VEC_CLEAR
    VEC_POP
    MAP_NEW
    MAP_INSERT
    MAP_GET
    MAP_CONTAINS
    MAP_LEN
    MAP_REMOVE
    OPT_IS_SOME
    OPT_UNWRAP
    OPT_EXPECT
    STR_LEN
    STR_BYTE_AT
    STR_SLICE
    STR_CONTAINS
    STR_CONTAINS_CHAR
    STR_STARTS_WITH
    STR_ENDS_WITH
    STR_FIND
    MAP_CLEAR
    VECITER_NEXT
    VEC_ITER
    OPT_IS_NONE
    STR_SPLIT
    STR_TRIM
    STR_TO_UPPER
    STR_TO_LOWER
    STR_REPLACE
    STR_INDEX_OF
    MAP_INCREMENT
    MAP_DECREMENT
    MAP_UPDATE
    VEC_MAP
    VEC_FILTER
    VEC_FOLD
    ITER_MAP
    ITER_FILTER
    ITER_TAKE
    ITER_ZIP
    ITER_FLAT_MAP
    ITER_FOLD
    ITER_REDUCE
    ITER_SUM
    ITER_COUNT
    ITER_COLLECT_VEC
    ITER_PARTITION
    MAPITER_NEXT
    FILTERITER_NEXT
    TAKEITER_NEXT
    ZIPITER_NEXT
    FLATMAPITER_NEXT
    VEC_CONTAINS
    STR_REPEAT
    ARR_LEN
    GENERIC_CALL
    VEC_JOIN
    DYN_VTABLE_CMP
    DYN_DOWNCAST
    OPT_FILTER
    ROTATE_LEFT
    ROTATE_RIGHT
    VEC_WITH_CAPACITY
    FMT_TO_STR
    FMT_DEBUG_STR
    FMT_DEBUG
    FMT_SPEC
    INT_SWAP_BYTES
    MAP_KEYS
    POPCOUNT
    CLZ
    CTZ
    BITREVERSE
    MIN
    MAX
    ABS
    FMA
    ASM
    MULTI_INDEX
    MULTI_INDEX_SET
    FIBER_SPAWN
    FIBER_AWAIT
    FIBER_SELECT
    FIBER_CANCEL
    CHAN_CREATE
    CHAN_SEND
    CHAN_RECV
    CHAN_CLOSE
    ASYNC_BLOCK_SPAWN
    FIBER_IS_CANCELLED
    FIBER_WAS_CANCELLED_RETURN
    FIBER_SET_CANCELLED_RETURN
    FIBER_CLEANUP_AWAIT
    SCOPE_CREATE
    SCOPE_AWAIT_ALL
    SCOPE_DESTROY
    THREAD_SCOPE_CREATE
    THREAD_SCOPE_JOIN_ALL
    THREAD_SCOPE_DESTROY
    ATOMIC_LOAD
    ATOMIC_STORE
    ATOMIC_SWAP
    ATOMIC_FETCH_ADD
    ATOMIC_FETCH_SUB
    ATOMIC_FETCH_AND
    ATOMIC_FETCH_OR
    ATOMIC_FETCH_XOR
    ATOMIC_FETCH_MIN
    ATOMIC_FETCH_MAX
    ATOMIC_CAS
    ATOMIC_CAS_WEAK
    ATOMIC_FENCE
    FMT_BUF_NEW
    FMT_BUF_WRITE_STR
    FMT_BUF_WRITE_FMT
    FMT_BUF_FINISH
    VEC_SLOT
    VECSLOT_GET
    VECSLOT_SET
    VEC_ITER_PLACE
    VECITERPLACE_NEXT
    MAP_ENTRY
    ENTRY_OR_INSERT
    ENTRY_GET
    ENTRY_SET
    VEC_GET_DISJOINT
    VEC_RANGE
    VECRANGE_GET
    VECRANGE_SET
    VECRANGE_LEN
    VEC_ITER_REF
    VECITERREF_NEXT
    VEC_GET_REF
    DYN_CALL
    SLOTMAP_NEW
    SLOTMAP_INSERT
    SLOTMAP_GET
    SLOTMAP_SLOT
    SLOTMAP_REMOVE
    SLOTMAP_REPLACE
    SLOTMAP_CONTAINS
    SLOTMAP_LEN
    SLOTMAP_GET_DISJOINT
    SLOTMAPSLOT_GET
    SLOTMAPSLOT_SET
    FIBER_SELECT_BIASED
    FIBER_DETACH_CANCEL
    VEC_LEN32
    VEC_LEN64
    VEC_ULEN32
    MAP_LEN32
    MAP_LEN64
    MAP_ULEN32
    STR_LEN32
    STR_LEN64
    STR_ULEN32
    ARR_LEN32
    ARR_LEN64
    ARR_ULEN32
    VECRANGE_LEN32
    VECRANGE_LEN64
    VECRANGE_ULEN32
    SLOTMAP_LEN32
    SLOTMAP_LEN64
    SLOTMAP_ULEN32

// Copy: MirIntrinsic is a lightweight integer tag passed by value, stored in
// Vec/HashMap, and compared throughout MIR lowering and codegen.
impl Copy for MirIntrinsic

fn mir_len_method_intrinsic(base: MirIntrinsic, method_name: str) -> MirIntrinsic:
    if method_name == "len":
        return base
    if base == MirIntrinsic.VEC_LEN:
        if method_name == "len32": return MirIntrinsic.VEC_LEN32
        if method_name == "len64": return MirIntrinsic.VEC_LEN64
        if method_name == "ulen32": return MirIntrinsic.VEC_ULEN32
    if base == MirIntrinsic.MAP_LEN:
        if method_name == "len32": return MirIntrinsic.MAP_LEN32
        if method_name == "len64": return MirIntrinsic.MAP_LEN64
        if method_name == "ulen32": return MirIntrinsic.MAP_ULEN32
    if base == MirIntrinsic.STR_LEN:
        if method_name == "len32": return MirIntrinsic.STR_LEN32
        if method_name == "len64": return MirIntrinsic.STR_LEN64
        if method_name == "ulen32": return MirIntrinsic.STR_ULEN32
    if base == MirIntrinsic.ARR_LEN:
        if method_name == "len32": return MirIntrinsic.ARR_LEN32
        if method_name == "len64": return MirIntrinsic.ARR_LEN64
        if method_name == "ulen32": return MirIntrinsic.ARR_ULEN32
    if base == MirIntrinsic.VECRANGE_LEN:
        if method_name == "len32": return MirIntrinsic.VECRANGE_LEN32
        if method_name == "len64": return MirIntrinsic.VECRANGE_LEN64
        if method_name == "ulen32": return MirIntrinsic.VECRANGE_ULEN32
    if base == MirIntrinsic.SLOTMAP_LEN:
        if method_name == "len32": return MirIntrinsic.SLOTMAP_LEN32
        if method_name == "len64": return MirIntrinsic.SLOTMAP_LEN64
        if method_name == "ulen32": return MirIntrinsic.SLOTMAP_ULEN32
    MirIntrinsic.NONE

fn mir_intrinsic_is_len32(intrinsic: MirIntrinsic) -> bool:
    intrinsic == MirIntrinsic.VEC_LEN32 or intrinsic == MirIntrinsic.MAP_LEN32 or intrinsic == MirIntrinsic.STR_LEN32 or intrinsic == MirIntrinsic.ARR_LEN32 or intrinsic == MirIntrinsic.VECRANGE_LEN32 or intrinsic == MirIntrinsic.SLOTMAP_LEN32

fn mir_intrinsic_is_len64(intrinsic: MirIntrinsic) -> bool:
    intrinsic == MirIntrinsic.VEC_LEN64 or intrinsic == MirIntrinsic.MAP_LEN64 or intrinsic == MirIntrinsic.STR_LEN64 or intrinsic == MirIntrinsic.ARR_LEN64 or intrinsic == MirIntrinsic.VECRANGE_LEN64 or intrinsic == MirIntrinsic.SLOTMAP_LEN64

fn mir_intrinsic_is_ulen32(intrinsic: MirIntrinsic) -> bool:
    intrinsic == MirIntrinsic.VEC_ULEN32 or intrinsic == MirIntrinsic.MAP_ULEN32 or intrinsic == MirIntrinsic.STR_ULEN32 or intrinsic == MirIntrinsic.ARR_ULEN32 or intrinsic == MirIntrinsic.VECRANGE_ULEN32 or intrinsic == MirIntrinsic.SLOTMAP_ULEN32

// ── Projection kinds ─────────────────────────────────────────────

enum ProjKind: i32:
    PK_FIELD = 0
    PK_INDEX = 1
    PK_DEREF = 2
    PK_DOWNCAST = 3

// ── Drop kind tags for scope scheduling ──────────────────────────

enum DropKind: i32:
    DK_VALUE = 0
    DK_STORAGE = 1
    DK_TASK_DETACHED = 2
    DK_TASK_EPHEMERAL = 3
    DK_WITH_GUARD = 4
    DK_WITH_GUARD_MUT = 5
    DK_ASYNC_SCOPE = 6
    DK_THREAD_SCOPE = 7

// ── Data records ─────────────────────────────────────────────────

type MirLocalInfo {
    type_id: i32,
    is_mutable: i32,
    name_sym: i32,
    is_user_var: i32,
}

type MirBody {
    fn_sym: i32,
    lowering_failed: i32,

    // Locals
    local_type_ids: Vec[i32],
    local_mutables: Vec[i32],
    local_names: Vec[i32],
    local_is_user_var: Vec[i32],
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
    switch_table_vals: Vec[i32],
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
    // AST call node for generic calls (parallel to call_arg_starts, 0 if N/A)
    call_ast_nodes: Vec[i32],
}

type MirModule {
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
}

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
    }

fn MirModule.snapshot_sema_types(self: MirModule, sema: &Sema):
    for i in 0..sema.type_kinds.len() as i32:
        self.sema_type_kinds.push(sema.type_kinds.get(i as i64))
    for i in 0..sema.type_d0.len() as i32:
        self.sema_type_d0.push(sema.type_d0.get(i as i64))
    for i in 0..sema.type_d1.len() as i32:
        self.sema_type_d1.push(sema.type_d1.get(i as i64))
    for i in 0..sema.type_d2.len() as i32:
        self.sema_type_d2.push(sema.type_d2.get(i as i64))
    for i in 0..sema.type_extra.len() as i32:
        self.sema_type_extra.push(sema.type_extra.get(i as i64))
    self.sema_bitpacked_types = sema.bitpacked_types

fn MirModule.mir_is_bitpacked(self: MirModule, tid: i32) -> bool:
    self.sema_bitpacked_types.contains(tid)

fn MirModule.mir_get_type_kind(self: MirModule, tid: i32) -> i32:
    if tid < 0 or tid >= self.sema_type_kinds.len() as i32:
        return 0
    self.sema_type_kinds.get(tid as i64)

fn MirModule.mir_get_type_d0(self: MirModule, tid: i32) -> i32:
    if tid < 0 or tid >= self.sema_type_d0.len() as i32:
        return 0
    self.sema_type_d0.get(tid as i64)

fn MirModule.mir_get_type_d1(self: MirModule, tid: i32) -> i32:
    if tid < 0 or tid >= self.sema_type_d1.len() as i32:
        return 0
    self.sema_type_d1.get(tid as i64)

fn MirModule.mir_get_type_d2(self: MirModule, tid: i32) -> i32:
    if tid < 0 or tid >= self.sema_type_d2.len() as i32:
        return 0
    self.sema_type_d2.get(tid as i64)

fn MirModule.mir_get_type_extra(self: MirModule, idx: i32) -> i32:
    if idx < 0 or idx >= self.sema_type_extra.len() as i32:
        return 0
    self.sema_type_extra.get(idx as i64)

fn MirModule.mir_resolve_alias(self: MirModule, tid: i32) -> i32:
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

fn MirModule.mir_get_type_name(self: MirModule, tid: i32) -> i32:
    let resolved = self.mir_resolve_alias(tid)
    let tk = self.mir_get_type_kind(resolved)
    if tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF:
        return self.mir_get_type_name(self.mir_get_type_d0(resolved))
    if tk == TypeKind.TY_STRUCT or tk == TypeKind.TY_ENUM or tk == TypeKind.TY_GENERIC_INST:
        return self.mir_get_type_d0(resolved)
    0

// No-op: reserved for future manual memory management.
fn MirModule.deinit(mut self: MirModule):
    return

fn MirModule.add_body(mut self: MirModule, body: MirBody):
    let body_idx = self.bodies.len() as i32
    self.bodies.push(body)
    self.body_fn_syms.push(body.fn_sym)
    if body.fn_sym != 0:
        self.body_index_by_fn_sym.insert(body.fn_sym, body_idx)

fn MirModule.body_count(self: &MirModule) -> i32:
    self.bodies.len() as i32

fn MirModule.find_body(self: &MirModule, fn_sym: i32) -> i32:
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
        local_type_ids: Vec.new(),
        local_mutables: Vec.new(),
        local_names: Vec.new(),
        local_is_user_var: Vec.new(),
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
        call_ast_nodes: Vec.new(),
    }

    // Local 0 is always the return place.
    body.new_local(0, 1, 0, 0)
    body

fn MirBody.init(fn_sym: i32, sema: &Sema) -> MirBody:
    var body = MirBody.init_for_fn(fn_sym)
    if sema.ty_void != 0:
        body.local_type_ids.set_i32(0, sema.ty_void)
    body

fn MirBody.new_block(mut self: MirBody) -> BlockId:
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

fn MirBody.push_stmt(mut self: MirBody, bb: i32, kind: i32, d0: i32, d1: i32, span: i32):
    let stmt_id = self.stmt_kinds.len() as i32
    self.stmt_kinds.push(kind)
    self.stmt_d0.push(d0)
    self.stmt_d1.push(d1)
    self.stmt_spans.push(span)

    if bb >= 0 and bb < self.bb_stmt_counts.len() as i32:
        let old_count = self.bb_stmt_counts.get(bb as i64)
        if old_count == 0:
            self.bb_stmt_starts.set_i32(bb, stmt_id)
        self.bb_stmt_counts.set_i32(bb, old_count + 1)

fn MirBody.set_terminator(mut self: MirBody, bb: i32, kind: i32, d0: i32, d1: i32, d2: i32, d3: i32, span: i32):
    if bb < 0 or bb >= self.bb_term_kinds.len() as i32:
        return
    self.bb_term_kinds.set_i32(bb, kind)
    self.bb_term_d0.set_i32(bb, d0)
    self.bb_term_d1.set_i32(bb, d1)
    self.bb_term_d2.set_i32(bb, d2)
    self.bb_term_d3.set_i32(bb, d3)
    self.bb_term_spans.set_i32(bb, span)

fn MirBody.set_term_no_suspend_node(mut self: MirBody, bb: i32, node: i32):
    if bb < 0 or bb >= self.bb_no_suspend_nodes.len() as i32:
        return
    self.bb_no_suspend_nodes.set_i32(bb, node)

fn MirBody.new_local(mut self: MirBody, type_id: i32, mutable: i32, name: i32, is_user_var: i32) -> i32:
    let id = self.local_type_ids.len() as i32
    self.local_type_ids.push(type_id)
    self.local_mutables.push(mutable)
    self.local_names.push(name)
    self.local_is_user_var.push(is_user_var)
    id

fn MirBody.new_temp(mut self: MirBody, type_id: i32) -> i32:
    self.new_local(type_id, 1, 0, 0)

fn MirBody.new_place(mut self: MirBody, local_id: i32) -> i32:
    let id = self.place_locals.len() as i32
    self.place_locals.push(local_id)
    // Sema type defaults to the local's type (overridden by projected places)
    let sema_ty = if local_id >= 0 and local_id < self.local_type_ids.len() as i32: self.local_type_ids.get(local_id as i64) else: 0
    self.place_sema_types.push(sema_ty)
    self.place_proj_starts.push(self.proj_kinds.len() as i32)
    self.place_proj_counts.push(0)
    id

fn MirBody.new_place_typed(mut self: MirBody, local_id: i32, sema_ty: i32) -> i32:
    let id = self.place_locals.len() as i32
    self.place_locals.push(local_id)
    self.place_sema_types.push(sema_ty)
    self.place_proj_starts.push(self.proj_kinds.len() as i32)
    self.place_proj_counts.push(0)
    id

fn MirBody.new_place_with_projection(mut self: MirBody, base: i32, proj_kind: i32, proj_data: i32, sema_ty: i32) -> i32:
    if base < 0 or base >= self.place_locals.len() as i32:
        return self.new_place(0)

    let base_local = self.place_locals.get(base as i64)
    let base_proj_start = self.place_proj_starts.get(base as i64)
    let base_proj_count = self.place_proj_counts.get(base as i64)

    let new_proj_start = self.proj_kinds.len() as i32
    for i in 0..base_proj_count:
        self.proj_kinds.push(self.proj_kinds.get((base_proj_start + i) as i64))
        self.proj_d0.push(self.proj_d0.get((base_proj_start + i) as i64))

    self.proj_kinds.push(proj_kind)
    self.proj_d0.push(proj_data)

    let id = self.place_locals.len() as i32
    self.place_locals.push(base_local)
    self.place_sema_types.push(sema_ty)
    self.place_proj_starts.push(new_proj_start)
    self.place_proj_counts.push(base_proj_count + 1)
    id

fn MirBody.new_field_place(mut self: MirBody, base: i32, field_idx: i32, sema_ty: i32) -> i32:
    self.new_place_with_projection(base, ProjKind.PK_FIELD, field_idx, sema_ty)

fn MirBody.new_index_place(mut self: MirBody, base: i32, idx_local: i32, sema_ty: i32) -> i32:
    self.new_place_with_projection(base, ProjKind.PK_INDEX, idx_local, sema_ty)

fn MirBody.new_deref_place(mut self: MirBody, base: i32) -> i32:
    self.new_place_with_projection(base, ProjKind.PK_DEREF, 0, 0)

fn MirBody.new_downcast_place(mut self: MirBody, base: i32, variant_idx: i32, sema_ty: i32) -> i32:
    self.new_place_with_projection(base, ProjKind.PK_DOWNCAST, variant_idx, sema_ty)

fn MirBody.new_rvalue(mut self: MirBody, kind: i32, d0: i32, d1: i32, d2: i32) -> i32:
    let id = self.rval_kinds.len() as i32
    self.rval_kinds.push(kind)
    self.rval_d0.push(d0)
    self.rval_d1.push(d1)
    self.rval_d2.push(d2)
    id

fn MirBody.new_operand(mut self: MirBody, kind: i32, d0: i32) -> i32:
    let id = self.operand_kinds.len() as i32
    self.operand_kinds.push(kind)
    self.operand_d0.push(d0)
    id

fn MirBody.new_const(mut self: MirBody, kind: i32, d0: i32, d1: i32, d2: i32, type_id: i32) -> i32:
    let id = self.const_kinds.len() as i32
    self.const_kinds.push(kind)
    self.const_d0.push(d0)
    self.const_d1.push(d1)
    self.const_d2.push(d2)
    self.const_types.push(type_id)
    id

fn mir_const_int_value(body: &MirBody, const_id: i32) -> i64:
    ast_int_from_parts(
        body.const_d0.get(const_id as i64),
        body.const_d1.get(const_id as i64),
        body.const_d2.get(const_id as i64),
    )

fn MirBody.new_switch_table(mut self: MirBody, vals: Vec[i32], targets: Vec[i32]) -> i32:
    let id = self.switch_table_starts.len() as i32
    let start = self.switch_table_vals.len() as i32
    let count = vals.len() as i32
    self.switch_table_starts.push(start)
    self.switch_table_counts.push(count)

    for i in 0..count:
        self.switch_table_vals.push(vals.get(i as i64))
        if i < targets.len() as i32:
            self.switch_table_targets.push(targets.get(i as i64))
        else:
            self.switch_table_targets.push(0)

    id

fn MirBody.new_agg_fields(mut self: MirBody, operands: Vec[i32], name_syms: Vec[i32]) -> i32:
    let id = self.agg_field_starts.len() as i32
    let start = self.agg_field_operands.len() as i32
    let count = operands.len() as i32
    self.agg_field_starts.push(start)
    self.agg_field_counts.push(count)
    for i in 0..count:
        self.agg_field_operands.push(operands.get(i as i64))
        self.agg_field_name_syms.push(name_syms.get(i as i64))
    id

fn MirBody.new_call_args(mut self: MirBody, operands: Vec[i32]) -> i32:
    let id = self.call_arg_starts.len() as i32
    let start = self.call_arg_operands.len() as i32
    let count = operands.len() as i32
    self.call_arg_starts.push(start)
    self.call_arg_counts.push(count)
    self.call_intrinsic_kinds.push(MirIntrinsic.NONE)
    self.call_ast_nodes.push(0)
    for i in 0..count:
        self.call_arg_operands.push(operands.get(i as i64))
    id

fn MirBody.set_call_intrinsic(mut self: MirBody, call_id: i32, kind: MirIntrinsic):
    if call_id >= 0 and call_id < self.call_intrinsic_kinds.len() as i32:
        let call_idx = call_id as i64
        with self.call_intrinsic_kinds.slot(call_idx) as mut slot:
            slot.set(kind)

fn MirBody.call_intrinsic(self: &MirBody, call_id: i32) -> MirIntrinsic:
    if call_id < 0 or call_id >= self.call_intrinsic_kinds.len() as i32:
        return MirIntrinsic.NONE
    self.call_intrinsic_kinds.get(call_id as i64)

fn MirBody.set_call_ast_node(mut self: MirBody, call_id: i32, node: i32):
    if call_id >= 0 and call_id < self.call_ast_nodes.len() as i32:
        self.call_ast_nodes.set_i32(call_id, node)

fn MirBody.call_ast_node(self: &MirBody, call_id: i32) -> i32:
    if call_id < 0 or call_id >= self.call_ast_nodes.len() as i32:
        return 0
    self.call_ast_nodes.get(call_id as i64)

// ── Query helpers ────────────────────────────────────────────────

fn MirBody.local_count(self: &MirBody) -> i32:
    self.local_type_ids.len() as i32

fn MirBody.block_count(self: &MirBody) -> i32:
    self.bb_stmt_starts.len() as i32

fn MirBody.stmt_count(self: &MirBody) -> i32:
    self.stmt_kinds.len() as i32

fn MirBody.get_local(self: &MirBody, idx: i32) -> MirLocalInfo:
    if idx < 0 or idx >= self.local_type_ids.len() as i32:
        return MirLocalInfo { type_id: 0, is_mutable: 0, name_sym: 0, is_user_var: 0 }
    MirLocalInfo {
        type_id: self.local_type_ids.get(idx as i64),
        is_mutable: self.local_mutables.get(idx as i64),
        name_sym: self.local_names.get(idx as i64),
        is_user_var: self.local_is_user_var.get(idx as i64),
    }

fn MirBody.stmt_kind(self: &MirBody, idx: i32) -> i32:
    if idx < 0 or idx >= self.stmt_kinds.len() as i32:
        return StmtKind.Nop
    self.stmt_kinds.get(idx as i64)

fn MirBody.stmt_data0(self: &MirBody, idx: i32) -> i32:
    if idx < 0 or idx >= self.stmt_d0.len() as i32:
        return 0
    self.stmt_d0.get(idx as i64)

fn MirBody.stmt_data1(self: &MirBody, idx: i32) -> i32:
    if idx < 0 or idx >= self.stmt_d1.len() as i32:
        return 0
    self.stmt_d1.get(idx as i64)

fn MirBody.term_kind(self: &MirBody, bb: i32) -> i32:
    if bb < 0 or bb >= self.bb_term_kinds.len() as i32:
        return TermKind.TK_UNREACHABLE
    self.bb_term_kinds.get(bb as i64)

fn MirBody.term_data0(self: &MirBody, bb: i32) -> i32:
    if bb < 0 or bb >= self.bb_term_d0.len() as i32:
        return 0
    self.bb_term_d0.get(bb as i64)

fn MirBody.term_data1(self: &MirBody, bb: i32) -> i32:
    if bb < 0 or bb >= self.bb_term_d1.len() as i32:
        return 0
    self.bb_term_d1.get(bb as i64)

fn MirBody.term_data2(self: &MirBody, bb: i32) -> i32:
    if bb < 0 or bb >= self.bb_term_d2.len() as i32:
        return 0
    self.bb_term_d2.get(bb as i64)

fn MirBody.term_data3(self: &MirBody, bb: i32) -> i32:
    if bb < 0 or bb >= self.bb_term_d3.len() as i32:
        return 0
    self.bb_term_d3.get(bb as i64)

fn MirBody.term_no_suspend_node(self: &MirBody, bb: i32) -> i32:
    if bb < 0 or bb >= self.bb_no_suspend_nodes.len() as i32:
        return 0
    self.bb_no_suspend_nodes.get(bb as i64)

// ── Deterministic dump rendering ─────────────────────────────────

fn dump_mir_module(mir_mod: MirModule, pool: InternPool, sema: Sema) -> str:
    var out = ""
    out = out ++ f"mir module functions={mir_mod.bodies.len() as i32}\n"
    for i in 0..mir_mod.bodies.len() as i32:
        if i > 0:
            out = out ++ "\n"
        let body: MirBody = mir_mod.bodies.get(i as i64)
        out = out ++ dump_mir_body(body, pool, sema)
    out

// Streaming variant of dump_mir_module to avoid quadratic whole-module
// concatenation when dumping large MIR corpora.
fn print_mir_module(mir_mod: MirModule, pool: InternPool, sema: Sema):
    with_write(f"mir module functions={mir_mod.bodies.len() as i32}\n")
    for i in 0..mir_mod.bodies.len() as i32:
        if i > 0:
            with_write("\n")
        let body: MirBody = mir_mod.bodies.get(i as i64)
        with_write(dump_mir_body(body, pool, sema))

fn mir_clip_text(s: str, max_len: i32) -> str:
    if max_len <= 0:
        return ""
    if s.len() as i32 <= max_len:
        return s
    if max_len <= 3:
        return s.slice(0, max_len as i64)
    s.slice(0, (max_len - 3) as i64) ++ "..."

fn dump_mir_body(body: MirBody, pool: InternPool, sema: Sema) -> str:
    var out = ""
    let fn_name = if body.fn_sym != 0:
        f"sym{body.fn_sym}({pool.resolve(body.fn_sym)})"
    else:
        "<anon>"
    out = out ++ "fn " ++ fn_name ++ " " ++ lbrace() ++ "\n"
    out = out ++ "  locals:\n"

    let local_total = body.local_type_ids.len() as i32
    let bb_total = body.bb_stmt_starts.len() as i32
    let stmt_total = body.stmt_kinds.len() as i32
    if local_total > 50000 or bb_total > 20000 or stmt_total > 500000:
        out = out ++ f"    <mir dump omitted: body too large locals={local_total} bbs={bb_total} stmts={stmt_total}>\n"
        out = out ++ rbrace() ++ "\n"
        return out

    var local_count = local_total
    if local_count > 1024:
        local_count = 1024
    for li in 0..local_count:
        let tid = body.local_type_ids.get(li as i64)
        let ty_name = if tid != 0: f"ty{tid}" else: "<inferred>"
        var line = f"    _{li}: " ++ ty_name
        if li == 0:
            line = line ++ "  // return"
        let name_sym = body.local_names.get(li as i64)
        if body.local_is_user_var.get(li as i64) != 0 and name_sym != 0:
            line = line ++ f"  // sym{name_sym}"
        if body.local_mutables.get(li as i64) != 0:
            line = line ++ " [mut]"
        out = out ++ line ++ "\n"
    if local_total > local_count:
        out = out ++ f"    ... locals truncated ({local_total - local_count} more)\n"

    var bb_count = bb_total
    if bb_count > 512:
        bb_count = 512
    for bb in 0..bb_count:
        out = out ++ "\n"
        out = out ++ f"  bb{bb}: " ++ lbrace() ++ "\n"

        let stmt_start = body.bb_stmt_starts.get(bb as i64)
        let raw_stmt_count = body.bb_stmt_counts.get(bb as i64)
        var stmt_count = raw_stmt_count
        if stmt_start < 0 or raw_stmt_count < 0 or stmt_start > stmt_total:
            out = out ++ "    <invalid statement span>\n"
            stmt_count = 0
        else if stmt_start + raw_stmt_count > stmt_total:
            stmt_count = stmt_total - stmt_start
            out = out ++ "    <statement span truncated>\n"
        if stmt_count > 2048:
            stmt_count = 2048
            out = out ++ "    <statement dump capped>\n"
        for si in 0..stmt_count:
            let stmt_id = stmt_start + si
            out = out ++ "    " ++ mir_stmt_text(body, stmt_id, pool, sema) ++ "\n"

        out = out ++ "    " ++ mir_term_text(body, bb, pool, sema) ++ "\n"
        out = out ++ "  " ++ rbrace() ++ "\n"
    if bb_total > bb_count:
        out = out ++ f"\n  ... blocks truncated ({bb_total - bb_count} more)\n"

    out = out ++ rbrace() ++ "\n"
    out

fn mir_stmt_text(body: MirBody, stmt_id: i32, pool: InternPool, sema: Sema) -> str:
    let kind = body.stmt_kind(stmt_id)
    let d0 = body.stmt_data0(stmt_id)
    let d1 = body.stmt_data1(stmt_id)

    if kind == StmtKind.Assign:
        return mir_place_text(body, d0) ++ " = " ++ mir_rvalue_text(body, d1, pool, sema) ++ ";"
    if kind == StmtKind.StorageLive:
        return f"StorageLive(_{d0});"
    if kind == StmtKind.StorageDead:
        return f"StorageDead(_{d0});"
    if kind == StmtKind.Drop:
        return "drop(" ++ mir_place_text(body, d0) ++ ");"
    if kind == StmtKind.Nop:
        return "nop;"

    f"stmt<{kind}>({d0}, {d1});"

fn mir_term_text(body: MirBody, bb: i32, pool: InternPool, sema: Sema) -> str:
    let kind = body.term_kind(bb)
    let d0 = body.term_data0(bb)
    let d1 = body.term_data1(bb)
    let d2 = body.term_data2(bb)
    let d3 = body.term_data3(bb)

    if kind == TermKind.TK_GOTO:
        return f"goto -> bb{d0};"

    if kind == TermKind.TK_RETURN:
        return "return;"

    if kind == TermKind.TK_UNREACHABLE:
        return "unreachable;"

    if kind == TermKind.TK_SWITCH_INT:
        let op_text = mir_operand_text(body, d0, pool, sema)
        var table_text = ""
        if d1 >= 0 and d1 < body.switch_table_starts.len() as i32:
            let start = body.switch_table_starts.get(d1 as i64)
            let raw_count = body.switch_table_counts.get(d1 as i64)
            var count = raw_count
            let vals_len = body.switch_table_vals.len() as i32
            let tgts_len = body.switch_table_targets.len() as i32
            if start < 0 or raw_count < 0 or start > vals_len or start > tgts_len:
                count = 0
                table_text = "<invalid switch table>"
            else:
                let max_len = if vals_len < tgts_len: vals_len else: tgts_len
                if start + raw_count > max_len:
                    count = max_len - start
            if count > 256:
                count = 256
            for i in 0..count:
                if i > 0:
                    table_text = table_text ++ ", "
                table_text = table_text ++ f"{body.switch_table_vals.get((start + i) as i64)}"
                table_text = table_text ++ f": bb{body.switch_table_targets.get((start + i) as i64)}"
            if raw_count > count:
                if table_text.len() > 0:
                    table_text = table_text ++ ", "
                table_text = table_text ++ "..."
        if d2 != 0 or table_text.len() == 0:
            if table_text.len() > 0:
                table_text = table_text ++ ", "
            table_text = table_text ++ f"otherwise: bb{d2}"
        return "switchInt(" ++ op_text ++ ") -> [" ++ table_text ++ "];"

    if kind == TermKind.TK_CALL:
        let fn_text = mir_operand_text(body, d0, pool, sema)
        let args_text = mir_call_args_text(body, d1, pool, sema)
        let dest_text = mir_place_text(body, d2)
        return f"call {fn_text}({args_text}) -> [return: {dest_text}, next: bb{d3}];"

    if kind == TermKind.TK_DROP_AND_GOTO:
        return f"drop({mir_place_text(body, d0)}) -> bb{d1};"

    f"term<{kind}>({d0}, {d1}, {d2}, {d3});"

fn mir_place_text(body: MirBody, place_id: i32) -> str:
    if place_id < 0 or place_id >= body.place_locals.len() as i32:
        return "_?"

    var out = f"_{body.place_locals.get(place_id as i64)}"
    let p_start = body.place_proj_starts.get(place_id as i64)
    let p_count = body.place_proj_counts.get(place_id as i64)

    for i in 0..p_count:
        let pk = body.proj_kinds.get((p_start + i) as i64)
        let pd = body.proj_d0.get((p_start + i) as i64)

        if pk == ProjKind.PK_FIELD:
            out = out ++ f".f{pd}"
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

fn mir_rvalue_text(body: MirBody, rval_id: i32, pool: InternPool, sema: Sema) -> str:
    if rval_id < 0 or rval_id >= body.rval_kinds.len() as i32:
        return "<rvalue?>"

    let k = body.rval_kinds.get(rval_id as i64)
    let d0 = body.rval_d0.get(rval_id as i64)
    let d1 = body.rval_d1.get(rval_id as i64)
    let d2 = body.rval_d2.get(rval_id as i64)

    if k == RvalueKind.RK_USE:
        return mir_operand_text(body, d0, pool, sema)

    if k == RvalueKind.RK_BIN_OP:
        return "binop(" ++ mir_binop_name(d0) ++ ", " ++ mir_operand_text(body, d1, pool, sema) ++ ", " ++ mir_operand_text(body, d2, pool, sema) ++ ")"

    if k == RvalueKind.RK_UN_OP:
        return "unop(" ++ mir_unop_name(d0) ++ ", " ++ mir_operand_text(body, d1, pool, sema) ++ ")"

    if k == RvalueKind.RK_REF:
        let borrow = if d0 == BorrowKind.EXCLUSIVE: "mut" else: "shared"
        return "ref(" ++ borrow ++ ", " ++ mir_place_text(body, d1) ++ ")"

    if k == RvalueKind.RK_ADDR_OF:
        return "addr_of(" ++ mir_place_text(body, d0) ++ ")"

    if k == RvalueKind.RK_AGGREGATE:
        return f"aggregate(kind={d0}, tag={d2}, fields=[{mir_agg_fields_text(body, d1, pool, sema)}])"

    if k == RvalueKind.RK_DISCRIMINANT:
        return "discriminant(" ++ mir_place_text(body, d0) ++ ")"

    if k == RvalueKind.RK_CAST:
        let ty = if d1 != 0: f"ty{d1}" else: "<inferred>"
        return "cast(" ++ mir_operand_text(body, d0, pool, sema) ++ " as " ++ ty ++ ")"

    if k == RvalueKind.RK_LEN:
        return "len(" ++ mir_place_text(body, d0) ++ ")"

    if k == RvalueKind.RK_ARRAY_FILL:
        return f"array_fill({mir_operand_text(body, d0, pool, sema)}, count={d1})"

    if k == RvalueKind.RK_STR_CONCAT_N:
        return f"str_concat_n([{mir_call_args_text(body, d0, pool, sema)}])"

    if k == RvalueKind.RK_SLICE:
        return "slice(" ++ mir_place_text(body, d0) ++ ", " ++ mir_operand_text(body, d1, pool, sema) ++ ", " ++ mir_operand_text(body, d2, pool, sema) ++ ")"

    return f"rvalue<{k}>({d0}, {d1}, {d2})"

fn mir_operand_text(body: MirBody, operand_id: i32, pool: InternPool, sema: Sema) -> str:
    if operand_id < 0 or operand_id >= body.operand_kinds.len() as i32:
        return "<op?>"

    let k = body.operand_kinds.get(operand_id as i64)
    let d0 = body.operand_d0.get(operand_id as i64)

    if k == OperandKind.OK_COPY:
        return "copy " ++ mir_place_text(body, d0)
    if k == OperandKind.OK_MOVE:
        return "move " ++ mir_place_text(body, d0)
    if k == OperandKind.OK_CONSTANT:
        return mir_const_text(body, d0, pool, sema)

    f"op<{k}>({d0})"

fn mir_exact_int_text(ast: AstPool, node: i32) -> str:
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

fn mir_const_text(body: MirBody, const_id: i32, pool: InternPool, sema: Sema) -> str:
    if const_id < 0 or const_id >= body.const_kinds.len() as i32:
        return "const<?>"

    let k = body.const_kinds.get(const_id as i64)
    let d0 = body.const_d0.get(const_id as i64)
    let ty = body.const_types.get(const_id as i64)

    if k == ConstKind.CK_INT:
        let ty_name = if ty != 0: f"ty{ty}" else: "i32"
        return f"const {with_i64_to_str(mir_const_int_value(body, const_id))}{ty_name}"

    if k == ConstKind.CK_INT_EXACT:
        let ty_name = if ty != 0: f"ty{ty}" else: "int"
        return "const " ++ mir_exact_int_text(sema.ast, d0) ++ ty_name

    if k == ConstKind.CK_BOOL:
        return if d0 != 0: "const true" else: "const false"

    if k == ConstKind.CK_STR:
        if d0 == 0:
            return "const \"\""
        return f"const \"sym{d0}\""

    if k == ConstKind.CK_C_STR:
        if d0 == 0:
            return "const c\"\""
        return f"const c\"sym{d0}\""

    if k == ConstKind.CK_UNIT:
        return "const ()"

    if k == ConstKind.CK_FLOAT:
        if d0 != 0:
            return f"const sym{d0}"
        return "const 0.0"

    if k == ConstKind.CK_ZERO_SIZED:
        let ty_name = if ty != 0: f"ty{ty}" else: "<zst>"
        return "const zst(" ++ ty_name ++ ")"

    if k == ConstKind.CK_FN:
        if d0 != 0:
            return f"const fn sym{d0}"
        return "const fn <unknown>"

    if k == ConstKind.CK_CLOSURE:
        return f"const closure(node{d0})"

    if k == ConstKind.CK_ASYNC_BLOCK:
        return f"const async_block(node{d0})"

    if k == ConstKind.CK_REGEX_LIT:
        return f"const regex(sym{d0}, flags=sym{body.const_d1.get(const_id as i64)}, node{body.const_d2.get(const_id as i64)})"

    f"const<{k}>({d0})"

fn mir_agg_fields_text(body: MirBody, fields_id: i32, pool: InternPool, sema: Sema) -> str:
    if fields_id < 0 or fields_id >= body.agg_field_starts.len() as i32:
        return ""

    let start = body.agg_field_starts.get(fields_id as i64)
    let raw_count = body.agg_field_counts.get(fields_id as i64)
    let ops_len = body.agg_field_operands.len() as i32
    if start < 0 or raw_count < 0 or start > ops_len:
        return "<invalid aggregate fields>"
    let count = if start + raw_count > ops_len: ops_len - start else: raw_count
    let capped = if count > 256: 256 else: count
    var out = ""
    for i in 0..capped:
        if i > 0:
            out = out ++ ", "
        out = out ++ mir_operand_text(body, body.agg_field_operands.get((start + i) as i64), pool, sema)
    if raw_count > capped:
        if out.len() > 0:
            out = out ++ ", "
        out = out ++ "..."
    out

fn mir_call_args_text(body: MirBody, args_id: i32, pool: InternPool, sema: Sema) -> str:
    if args_id < 0 or args_id >= body.call_arg_starts.len() as i32:
        return ""

    let start = body.call_arg_starts.get(args_id as i64)
    let raw_count = body.call_arg_counts.get(args_id as i64)
    let ops_len = body.call_arg_operands.len() as i32
    if start < 0 or raw_count < 0 or start > ops_len:
        return "<invalid call args>"
    let count = if start + raw_count > ops_len: ops_len - start else: raw_count
    let capped = if count > 256: 256 else: count
    var out = ""
    for i in 0..capped:
        if i > 0:
            out = out ++ ", "
        out = out ++ mir_operand_text(body, body.call_arg_operands.get((start + i) as i64), pool, sema)
    if raw_count > capped:
        if out.len() > 0:
            out = out ++ ", "
        out = out ++ "..."
    out

fn mir_binop_name(op: i32) -> str:
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

fn mir_unop_name(op: i32) -> str:
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

fn validate_mir_module(mir_mod: MirModule) -> str:
    let body_count = mir_mod.bodies.len() as i32
    if body_count != mir_mod.body_fn_syms.len() as i32:
        return "bodies/body_fn_syms length mismatch"

    let seen_fn_syms: HashMap[i32, i32] = HashMap.new()
    for bi in 0..body_count:
        let body: MirBody = mir_mod.bodies.get(bi as i64)
        let fn_sym = mir_mod.body_fn_syms.get(bi as i64)
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

fn validate_mir_body(body: MirBody) -> str:
    let local_count = body.local_type_ids.len() as i32
    if local_count <= 0:
        return "missing return local"
    if local_count != body.local_mutables.len() as i32:
        return "locals/local_mutables length mismatch"
    if local_count != body.local_names.len() as i32:
        return "locals/local_names length mismatch"
    if local_count != body.local_is_user_var.len() as i32:
        return "locals/local_is_user_var length mismatch"
    if body.n_params < 0 or body.n_params > local_count:
        return "invalid n_params"

    let bb_count = body.bb_stmt_starts.len() as i32
    if bb_count <= 0:
        return "missing basic blocks"
    if bb_count != body.bb_stmt_counts.len() as i32:
        return "bb_stmt_starts/bb_stmt_counts length mismatch"
    if bb_count != body.bb_term_kinds.len() as i32:
        return "bb_stmt_starts/bb_term_kinds length mismatch"
    if bb_count != body.bb_term_d0.len() as i32 or
       bb_count != body.bb_term_d1.len() as i32 or
       bb_count != body.bb_term_d2.len() as i32 or
       bb_count != body.bb_term_d3.len() as i32:
        return "bb terminator payload length mismatch"
    if bb_count != body.bb_is_cleanup.len() as i32:
        return "bb cleanup flag length mismatch"
    if bb_count != body.bb_term_spans.len() as i32:
        return "bb_term_spans length mismatch"
    if bb_count != body.bb_no_suspend_nodes.len() as i32:
        return "bb_no_suspend_nodes length mismatch"

    let stmt_count = body.stmt_kinds.len() as i32
    if stmt_count != body.stmt_d0.len() as i32 or
       stmt_count != body.stmt_d1.len() as i32 or
       stmt_count != body.stmt_spans.len() as i32:
        return "statement table length mismatch"

    let place_count = body.place_locals.len() as i32
    if place_count != body.place_proj_starts.len() as i32 or
       place_count != body.place_proj_counts.len() as i32:
        return "place table length mismatch"

    let proj_count = body.proj_kinds.len() as i32
    if proj_count != body.proj_d0.len() as i32:
        return "projection table length mismatch"

    let rval_count = body.rval_kinds.len() as i32
    if rval_count != body.rval_d0.len() as i32 or
       rval_count != body.rval_d1.len() as i32 or
       rval_count != body.rval_d2.len() as i32:
        return "rvalue table length mismatch"

    let operand_count = body.operand_kinds.len() as i32
    if operand_count != body.operand_d0.len() as i32:
        return "operand table length mismatch"

    let const_count = body.const_kinds.len() as i32
    if const_count != body.const_d0.len() as i32 or
       const_count != body.const_d1.len() as i32 or
       const_count != body.const_d2.len() as i32 or
       const_count != body.const_types.len() as i32:
        return "constant table length mismatch"

    let switch_count = body.switch_table_starts.len() as i32
    if switch_count != body.switch_table_counts.len() as i32:
        return "switch table length mismatch"
    if body.switch_table_vals.len() as i32 != body.switch_table_targets.len() as i32:
        return "switch value/target table length mismatch"

    let agg_count = body.agg_field_starts.len() as i32
    if agg_count != body.agg_field_counts.len() as i32:
        return "aggregate field table length mismatch"

    let call_args_count = body.call_arg_starts.len() as i32
    if call_args_count != body.call_arg_counts.len() as i32:
        return "call args table length mismatch"

    for bb in 0..bb_count:
        let stmt_start = body.bb_stmt_starts.get(bb as i64)
        let stmt_span_count = body.bb_stmt_counts.get(bb as i64)
        if not mir_span_in_range(stmt_start, stmt_span_count, stmt_count):
            return f"bb{bb}: statement span out of range (start={stmt_start}, count={stmt_span_count}, total={stmt_count})"

        let term_kind = body.bb_term_kinds.get(bb as i64)
        let d0 = body.bb_term_d0.get(bb as i64)
        let d1 = body.bb_term_d1.get(bb as i64)
        let d2 = body.bb_term_d2.get(bb as i64)
        let d3 = body.bb_term_d3.get(bb as i64)

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
        let stmt_kind = body.stmt_kinds.get(si as i64)
        let d0 = body.stmt_d0.get(si as i64)
        let d1 = body.stmt_d1.get(si as i64)

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
        let local_id = body.place_locals.get(pi as i64)
        if not mir_index_in_range(local_id, local_count):
            return f"place{pi}: base local out of range"

        let proj_start = body.place_proj_starts.get(pi as i64)
        let proj_span_count = body.place_proj_counts.get(pi as i64)
        if not mir_span_in_range(proj_start, proj_span_count, proj_count):
            return f"place{pi}: projection span out of range"

        for ji in 0..proj_span_count:
            let proj_idx = proj_start + ji
            let proj_kind = body.proj_kinds.get(proj_idx as i64)
            let proj_d0 = body.proj_d0.get(proj_idx as i64)

            if proj_kind == ProjKind.PK_FIELD:
                if proj_d0 < 0:
                    return f"place{pi}: field projection has negative index"
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
        let op_kind = body.operand_kinds.get(oi as i64)
        let d0 = body.operand_d0.get(oi as i64)
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
        let rv_kind = body.rval_kinds.get(ri as i64)
        let d0 = body.rval_d0.get(ri as i64)
        let d1 = body.rval_d1.get(ri as i64)
        let d2 = body.rval_d2.get(ri as i64)

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
        let ck = body.const_kinds.get(ci as i64)
        if ck == ConstKind.CK_INT or ck == ConstKind.CK_BOOL or ck == ConstKind.CK_STR or ck == ConstKind.CK_C_STR or ck == ConstKind.CK_UNIT or ck == ConstKind.CK_FLOAT or ck == ConstKind.CK_ZERO_SIZED or ck == ConstKind.CK_FN or ck == ConstKind.CK_CLOSURE or ck == ConstKind.CK_ASYNC_BLOCK or ck == ConstKind.CK_INT_EXACT or ck == ConstKind.CK_REGEX_LIT:
            continue
        return f"const{ci}: unknown const kind {ck}"

    for ti in 0..switch_count:
        let start = body.switch_table_starts.get(ti as i64)
        let count = body.switch_table_counts.get(ti as i64)
        let total = body.switch_table_vals.len() as i32
        if not mir_span_in_range(start, count, total):
            return f"switch table{ti}: span out of range"
        for i in 0..count:
            let target = body.switch_table_targets.get((start + i) as i64)
            if not mir_index_in_range(target, bb_count):
                return f"switch table{ti}: target out of range"

    for ai in 0..agg_count:
        let start = body.agg_field_starts.get(ai as i64)
        let count = body.agg_field_counts.get(ai as i64)
        let total = body.agg_field_operands.len() as i32
        if not mir_span_in_range(start, count, total):
            return f"aggregate table{ai}: span out of range"
        for i in 0..count:
            let op_idx = body.agg_field_operands.get((start + i) as i64)
            if not mir_index_in_range(op_idx, operand_count):
                return f"aggregate table{ai}: operand out of range"

    for ai in 0..call_args_count:
        let start = body.call_arg_starts.get(ai as i64)
        let count = body.call_arg_counts.get(ai as i64)
        let total = body.call_arg_operands.len() as i32
        if not mir_span_in_range(start, count, total):
            return f"call args table{ai}: span out of range"
        for i in 0..count:
            let op_idx = body.call_arg_operands.get((start + i) as i64)
            if not mir_index_in_range(op_idx, operand_count):
                return f"call args table{ai}: operand out of range"

    ""

type MirValidationError {
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

fn mir_validation_fail(fn_sym: i32, span: i32, message: str) -> MirValidationError:
    MirValidationError {
        fn_sym: fn_sym,
        span: span,
        message: message,
    }

fn mir_validation_has_error(err: MirValidationError) -> bool:
    err.message.len() > 0

fn mir_validate_find_named_type(mir_mod: MirModule, type_sym: i32) -> i32:
    for ti in 0..mir_mod.sema_type_kinds.len() as i32:
        let tk = mir_mod.sema_type_kinds.get(ti as i64)
        // Only match TY_STRUCT and TY_ENUM — their d0 stores the name symbol.
        // TY_ALIAS d0 stores the alias TARGET, not the name.
        if tk != TypeKind.TY_STRUCT and tk != TypeKind.TY_ENUM:
            continue
        if mir_mod.sema_type_d0.get(ti as i64) == type_sym:
            return ti
    0

fn mir_validate_find_int_type(mir_mod: MirModule, bits: i32, signed: i32) -> i32:
    for ti in 0..mir_mod.sema_type_kinds.len() as i32:
        if mir_mod.sema_type_kinds.get(ti as i64) != TypeKind.TY_INT:
            continue
        if mir_mod.sema_type_d0.get(ti as i64) == bits and mir_mod.sema_type_d1.get(ti as i64) == signed:
            return ti
    0

fn mir_validate_get_generic_inst_arg_count(mir_mod: MirModule, tid: i32) -> i32:
    mir_mod.mir_get_type_d2(tid)

fn mir_validate_get_generic_inst_arg(mir_mod: MirModule, tid: i32, index: i32) -> i32:
    let extra_start = mir_mod.mir_get_type_d1(tid)
    mir_mod.mir_get_type_extra(extra_start + index)

fn mir_validate_struct_field_type(mir_mod: MirModule, struct_tid: i32, field_sym: i32) -> i32:
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

fn mir_validate_tuple_elem_type(mir_mod: MirModule, tuple_tid: i32, field_idx: i32) -> i32:
    let resolved = mir_mod.mir_resolve_alias(tuple_tid)
    if mir_mod.mir_get_type_kind(resolved) != TypeKind.TY_TUPLE:
        return 0
    let elem_start = mir_mod.mir_get_type_d0(resolved)
    let elem_count = mir_mod.mir_get_type_d1(resolved)
    if field_idx < 0 or field_idx >= elem_count:
        return 0
    mir_mod.mir_get_type_extra(elem_start + field_idx)

fn mir_validate_indexed_element_type(mir_mod: MirModule, collection_tid: i32) -> i32:
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

fn mir_validate_variant_exists(mir_mod: MirModule, enum_tid: i32, variant_idx: i32) -> bool:
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

fn mir_validate_enum_payload_type(mir_mod: MirModule, enum_tid: i32, variant_idx: i32, field_idx: i32) -> i32:
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
        if arg_count == 1 and field_idx == 0:
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
        // Result[T, E]: two generic args, both variants carry one payload in declaration order.
        if arg_count == 2 and variant_count == 2 and field_idx == 0:
            return mir_validate_get_generic_inst_arg(mir_mod, resolved, variant_idx)

        // Fallback to the erased base payload type for non-substituted generic enums.
        return mir_validate_enum_payload_type(mir_mod, base_tid, variant_idx, field_idx)
    0

fn mir_validate_type_compatible_fast(mir_mod: MirModule, expected: i32, actual: i32) -> i32:
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

fn mir_validate_single_field_inner(mir_mod: MirModule, tid: i32) -> i32:
    let resolved = mir_mod.mir_resolve_alias(tid)
    if mir_mod.mir_get_type_kind(resolved) != TypeKind.TY_STRUCT:
        return 0
    if mir_mod.mir_get_type_d2(resolved) != 1:
        return 0
    let extra_start = mir_mod.mir_get_type_d1(resolved)
    mir_mod.mir_get_type_extra(extra_start + 1)

fn mir_validate_place_type(mir_mod: MirModule, body: MirBody, place_id: i32) -> i32:
    if place_id < 0 or place_id >= body.place_locals.len() as i32:
        return 0
    if place_id < body.place_sema_types.len() as i32:
        let stored = body.place_sema_types.get(place_id as i64)
        if stored > 0:
            return stored
    let local_id = body.place_locals.get(place_id as i64)
    if local_id < 0 or local_id >= body.local_type_ids.len() as i32:
        return 0
    var current_ty = body.local_type_ids.get(local_id as i64)
    let proj_start = body.place_proj_starts.get(place_id as i64)
    let proj_count = body.place_proj_counts.get(place_id as i64)
    if proj_count <= 0:
        return current_ty
    var active_variant_idx = -1

    for pi in 0..proj_count:
        let proj_kind = body.proj_kinds.get((proj_start + pi) as i64)
        let proj_d0 = body.proj_d0.get((proj_start + pi) as i64)
        let resolved = mir_mod.mir_resolve_alias(current_ty)
        let tk = mir_mod.mir_get_type_kind(resolved)

        if proj_kind == ProjKind.PK_DOWNCAST:
            if not mir_validate_variant_exists(mir_mod, current_ty, proj_d0):
                return 0
            active_variant_idx = proj_d0
            continue

        if proj_kind == ProjKind.PK_FIELD:
            var field_ty = 0
            if active_variant_idx >= 0:
                field_ty = mir_validate_enum_payload_type(mir_mod, current_ty, active_variant_idx, proj_d0)
            else if tk == TypeKind.TY_TUPLE:
                field_ty = mir_validate_tuple_elem_type(mir_mod, current_ty, proj_d0)
            else:
                field_ty = mir_validate_struct_field_type(mir_mod, current_ty, proj_d0)
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

fn mir_validate_operand_type(mir_mod: MirModule, body: MirBody, operand_id: i32) -> i32:
    if operand_id < 0 or operand_id >= body.operand_kinds.len() as i32:
        return 0
    let op_kind = body.operand_kinds.get(operand_id as i64)
    let d0 = body.operand_d0.get(operand_id as i64)
    if op_kind == OperandKind.OK_CONSTANT:
        if d0 >= 0 and d0 < body.const_types.len() as i32:
            return body.const_types.get(d0 as i64)
        return 0
    if op_kind == OperandKind.OK_COPY or op_kind == OperandKind.OK_MOVE:
        return mir_validate_place_type(mir_mod, body, d0)
    0

fn mir_validate_is_compare_op(op: i32) -> bool:
    op == BinaryOp.OP_EQ or op == BinaryOp.OP_NEQ or op == BinaryOp.OP_LT or op == BinaryOp.OP_GT or op == BinaryOp.OP_LTE or op == BinaryOp.OP_GTE

fn mir_validate_compare_sensitive_type(mir_mod: MirModule, tid: i32) -> bool:
    if tid <= 0:
        return false
    let resolved = mir_mod.mir_resolve_alias(tid)
    let tk = mir_mod.mir_get_type_kind(resolved)
    tk == TypeKind.TY_STR or tk == TypeKind.TY_STRUCT or tk == TypeKind.TY_ENUM or tk == TypeKind.TY_GENERIC_INST or tk == TypeKind.TY_ARRAY or tk == TypeKind.TY_SLICE or tk == TypeKind.TY_TUPLE

fn mir_validate_cast_supported(mir_mod: MirModule, src_ty: i32, dst_ty: i32) -> bool:
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
    if mir_validate_type_compatible_fast(mir_mod, dst_ty, src_ty) != 0 or
       mir_validate_type_compatible_fast(mir_mod, src_ty, dst_ty) != 0:
        return true
    let src_resolved = mir_mod.mir_resolve_alias(src_ty)
    let dst_resolved = mir_mod.mir_resolve_alias(dst_ty)
    let src_kind = mir_mod.mir_get_type_kind(src_resolved)
    let dst_kind = mir_mod.mir_get_type_kind(dst_resolved)
    if src_kind == TypeKind.TY_NEVER:
        return true
    if (src_kind == TypeKind.TY_ENUM and dst_kind == TypeKind.TY_INT) or
       (src_kind == TypeKind.TY_INT and dst_kind == TypeKind.TY_ENUM):
        return true
    if src_kind == TypeKind.TY_PTR or src_kind == TypeKind.TY_REF or
       dst_kind == TypeKind.TY_PTR or dst_kind == TypeKind.TY_REF:
        return true
    if src_kind == TypeKind.TY_STR:
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

fn validate_typed_mir_body(mir_mod: MirModule, body: MirBody) -> MirValidationError:
    let stmt_count = body.stmt_count()
    for si in 0..stmt_count:
        let stmt_kind = body.stmt_kinds.get(si as i64)
        let d0 = body.stmt_d0.get(si as i64)
        let d1 = body.stmt_d1.get(si as i64)
        let span = body.stmt_spans.get(si as i64)

        if stmt_kind == StmtKind.Assign:
            let dest_ty = mir_validate_place_type(mir_mod, body, d0)
            if dest_ty == 0:
                return mir_validation_fail(body.fn_sym, span, "assign destination does not resolve to a concrete MIR type")
            if d1 < 0 or d1 >= body.rval_kinds.len() as i32:
                return mir_validation_fail(body.fn_sym, span, "assign rvalue is out of range during typed MIR verification")
            let rk = body.rval_kinds.get(d1 as i64)
            let rv_d0 = body.rval_d0.get(d1 as i64)
            let rv_d1 = body.rval_d1.get(d1 as i64)
            let rv_d2 = body.rval_d2.get(d1 as i64)

            if rk == RvalueKind.RK_REF:
                if mir_validate_place_type(mir_mod, body, rv_d1) == 0:
                    return mir_validation_fail(body.fn_sym, span, "ref rvalue does not resolve to a concrete place type")
            else if rk == RvalueKind.RK_ADDR_OF or rk == RvalueKind.RK_DISCRIMINANT or rk == RvalueKind.RK_LEN:
                if mir_validate_place_type(mir_mod, body, rv_d0) == 0:
                    return mir_validation_fail(body.fn_sym, span, "place-based rvalue does not resolve to a concrete place type")
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
                    let __lk = mir_mod.mir_get_type_kind(mir_mod.mir_resolve_alias(lhs_ty)) as i32
                    let __rk = mir_mod.mir_get_type_kind(mir_mod.mir_resolve_alias(rhs_ty)) as i32
                    with_eprint(f"DEBUG cmp fail: lhs_ty={lhs_ty} lhs_kind={__lk} rhs_ty={rhs_ty} rhs_kind={__rk}")
                    return mir_validation_fail(body.fn_sym, span, "comparison operands have incompatible MIR types")

            if rk == RvalueKind.RK_CAST:
                let src_ty = if rv_d2 > 0: rv_d2 else: mir_validate_operand_type(mir_mod, body, rv_d0)
                let cast_ty = if rv_d1 > 0: rv_d1 else: dest_ty
                if src_ty > 0 and cast_ty > 0 and not mir_validate_cast_supported(mir_mod, src_ty, cast_ty):
                    return mir_validation_fail(body.fn_sym, span, "unsupported cast in MIR")
            continue

        if stmt_kind == StmtKind.Drop:
            if mir_validate_place_type(mir_mod, body, d0) == 0:
                return mir_validation_fail(body.fn_sym, span, "drop target does not resolve to a concrete MIR type")

    let bb_count = body.block_count()
    for bb in 0..bb_count:
        let term_kind = body.bb_term_kinds.get(bb as i64)
        let d0 = body.bb_term_d0.get(bb as i64)
        let d2 = body.bb_term_d2.get(bb as i64)
        let span = body.bb_term_spans.get(bb as i64)

        if term_kind == TermKind.TK_SWITCH_INT:
            if mir_validate_operand_type(mir_mod, body, d0) == 0:
                return mir_validation_fail(body.fn_sym, span, "switch operand does not resolve to a concrete MIR type")
            continue

    mir_validation_ok()

fn validate_typed_mir_module(mir_mod: MirModule) -> MirValidationError:
    let shape_err = validate_mir_module(mir_mod)
    if shape_err.len() > 0:
        return mir_validation_fail(0, 0, shape_err)
    for bi in 0..mir_mod.bodies.len() as i32:
        let body = mir_mod.bodies.get(bi as i64)
        if body.lowering_failed != 0:
            continue
        let err = validate_typed_mir_body(mir_mod, body)
        if mir_validation_has_error(err):
            return err
    mir_validation_ok()
