// Mir — Wave 7 MIR data model, builders, and deterministic dump rendering.
//
// This module owns the MIR in-memory representation used after semantic
// analysis. MIR is intentionally explicit and deterministic.

use Ast
use InternPool
use Sema

extern fn int_to_string(n: i32) -> str
extern fn str_from_byte(b: i32) -> str

fn lbrace -> str:
    str_from_byte(123)

fn rbrace -> str:
    str_from_byte(125)

// ── Statement kinds ──────────────────────────────────────────────

fn SK_ASSIGN -> i32: 0
fn SK_STORAGE_LIVE -> i32: 1
fn SK_STORAGE_DEAD -> i32: 2
fn SK_DROP -> i32: 3
fn SK_NOP -> i32: 4

// ── Terminator kinds ─────────────────────────────────────────────

fn TK_GOTO -> i32: 0
fn TK_RETURN -> i32: 1
fn TK_UNREACHABLE -> i32: 2
fn TK_SWITCH_INT -> i32: 3
fn TK_CALL -> i32: 4
fn TK_DROP_AND_GOTO -> i32: 5

// ── Rvalue kinds ─────────────────────────────────────────────────

fn RK_USE -> i32: 0
fn RK_BIN_OP -> i32: 1
fn RK_UN_OP -> i32: 2
fn RK_REF -> i32: 3
fn RK_ADDR_OF -> i32: 4
fn RK_AGGREGATE -> i32: 5
fn RK_DISCRIMINANT -> i32: 6
fn RK_CAST -> i32: 7
fn RK_LEN -> i32: 8

// ── Operand kinds ────────────────────────────────────────────────

fn OK_COPY -> i32: 0
fn OK_MOVE -> i32: 1
fn OK_CONSTANT -> i32: 2

// ── Constant kinds ───────────────────────────────────────────────

fn CK_INT -> i32: 0
fn CK_BOOL -> i32: 1
fn CK_STR -> i32: 2
fn CK_UNIT -> i32: 3
fn CK_FLOAT -> i32: 4
fn CK_ZERO_SIZED -> i32: 5

// ── Projection kinds ─────────────────────────────────────────────

fn PK_FIELD -> i32: 0
fn PK_INDEX -> i32: 1
fn PK_DEREF -> i32: 2
fn PK_DOWNCAST -> i32: 3

// ── Drop kind tags for scope scheduling ──────────────────────────

fn DK_VALUE -> i32: 0
fn DK_STORAGE -> i32: 1

// ── Data records ─────────────────────────────────────────────────

type MirLocalInfo = {
    type_id: i32,
    is_mutable: i32,
    name_sym: i32,
    is_user_var: i32,
}

type MirBody = {
    fn_sym: i32,

    // Locals
    local_type_ids: Vec[i32],
    local_mutables: Vec[i32],
    local_names: Vec[i32],
    local_is_user_var: Vec[i32],
    n_params: i32,

    // Basic blocks
    bb_stmt_starts: Vec[i32],
    bb_stmt_counts: Vec[i32],
    bb_term_kinds: Vec[i32],
    bb_term_d0: Vec[i32],
    bb_term_d1: Vec[i32],
    bb_term_d2: Vec[i32],
    bb_term_d3: Vec[i32],
    bb_is_cleanup: Vec[i32],

    // Statements
    stmt_kinds: Vec[i32],
    stmt_d0: Vec[i32],
    stmt_d1: Vec[i32],
    stmt_spans: Vec[i32],

    // Places
    place_locals: Vec[i32],
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

    // Call argument tables
    call_arg_starts: Vec[i32],
    call_arg_counts: Vec[i32],
    call_arg_operands: Vec[i32],
}

type MirModule = {
    bodies: Vec[MirBody],
    body_fn_syms: Vec[i32],
}

// ── MirModule helpers ────────────────────────────────────────────

fn MirModule.init -> MirModule:
    MirModule {
        bodies: Vec.new(),
        body_fn_syms: Vec.new(),
    }

fn MirModule.deinit(self: MirModule):
    return

fn MirModule.add_body(self: MirModule, body: MirBody):
    self.bodies.push(body)
    self.body_fn_syms.push(body.fn_sym)

fn MirModule.body_count(self: MirModule) -> i32:
    self.bodies.len() as i32

fn MirModule.find_body(self: MirModule, fn_sym: i32) -> i32:
    for i in 0..self.body_fn_syms.len() as i32:
        if self.body_fn_syms.get(i as i64) == fn_sym:
            return i
    0 - 1

// ── MirBody builders ─────────────────────────────────────────────

fn MirBody.init_for_fn(fn_sym: i32) -> MirBody:
    var body = MirBody {
        fn_sym,
        local_type_ids: Vec.new(),
        local_mutables: Vec.new(),
        local_names: Vec.new(),
        local_is_user_var: Vec.new(),
        n_params: 0,
        bb_stmt_starts: Vec.new(),
        bb_stmt_counts: Vec.new(),
        bb_term_kinds: Vec.new(),
        bb_term_d0: Vec.new(),
        bb_term_d1: Vec.new(),
        bb_term_d2: Vec.new(),
        bb_term_d3: Vec.new(),
        bb_is_cleanup: Vec.new(),
        stmt_kinds: Vec.new(),
        stmt_d0: Vec.new(),
        stmt_d1: Vec.new(),
        stmt_spans: Vec.new(),
        place_locals: Vec.new(),
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
        const_types: Vec.new(),
        switch_table_starts: Vec.new(),
        switch_table_counts: Vec.new(),
        switch_table_vals: Vec.new(),
        switch_table_targets: Vec.new(),
        agg_field_starts: Vec.new(),
        agg_field_counts: Vec.new(),
        agg_field_operands: Vec.new(),
        call_arg_starts: Vec.new(),
        call_arg_counts: Vec.new(),
        call_arg_operands: Vec.new(),
    }

    // Local 0 is always the return place.
    body.new_local(0, 1, 0, 0)
    body

fn MirBody.init(fn_sym: i32, sema: Sema) -> MirBody:
    var body = MirBody.init_for_fn(fn_sym)
    if sema.ty_void != 0:
        body.local_type_ids.set_i32(0, sema.ty_void)
    body

fn MirBody.new_block(self: MirBody) -> i32:
    let id = self.bb_stmt_starts.len() as i32
    self.bb_stmt_starts.push(self.stmt_kinds.len() as i32)
    self.bb_stmt_counts.push(0)
    self.bb_term_kinds.push(TK_UNREACHABLE())
    self.bb_term_d0.push(0)
    self.bb_term_d1.push(0)
    self.bb_term_d2.push(0)
    self.bb_term_d3.push(0)
    self.bb_is_cleanup.push(0)
    id

fn MirBody.push_stmt(self: MirBody, bb: i32, kind: i32, d0: i32, d1: i32, span: i32):
    let stmt_id = self.stmt_kinds.len() as i32
    self.stmt_kinds.push(kind)
    self.stmt_d0.push(d0)
    self.stmt_d1.push(d1)
    self.stmt_spans.push(span)

    if bb >= 0 and bb < self.bb_stmt_counts.len() as i32:
        let old_count = self.bb_stmt_counts.get(bb as i64)
        if old_count == 0:
            self.bb_stmt_starts.set_i32(bb as i64, stmt_id)
        self.bb_stmt_counts.set_i32(bb as i64, old_count + 1)

fn MirBody.set_terminator(self: MirBody, bb: i32, kind: i32, d0: i32, d1: i32, d2: i32, d3: i32):
    if bb < 0 or bb >= self.bb_term_kinds.len() as i32:
        return
    self.bb_term_kinds.set_i32(bb as i64, kind)
    self.bb_term_d0.set_i32(bb as i64, d0)
    self.bb_term_d1.set_i32(bb as i64, d1)
    self.bb_term_d2.set_i32(bb as i64, d2)
    self.bb_term_d3.set_i32(bb as i64, d3)

fn MirBody.new_local(self: MirBody, type_id: i32, mutable: i32, name: i32, is_user_var: i32) -> i32:
    let id = self.local_type_ids.len() as i32
    self.local_type_ids.push(type_id)
    self.local_mutables.push(mutable)
    self.local_names.push(name)
    self.local_is_user_var.push(is_user_var)
    id

fn MirBody.new_temp(self: MirBody, type_id: i32) -> i32:
    self.new_local(type_id, 1, 0, 0)

fn MirBody.new_place(self: MirBody, local_id: i32) -> i32:
    let id = self.place_locals.len() as i32
    self.place_locals.push(local_id)
    self.place_proj_starts.push(self.proj_kinds.len() as i32)
    self.place_proj_counts.push(0)
    id

fn MirBody.new_place_with_projection(self: MirBody, base: i32, proj_kind: i32, proj_data: i32) -> i32:
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
    self.place_proj_starts.push(new_proj_start)
    self.place_proj_counts.push(base_proj_count + 1)
    id

fn MirBody.new_field_place(self: MirBody, base: i32, field_idx: i32) -> i32:
    self.new_place_with_projection(base, PK_FIELD(), field_idx)

fn MirBody.new_index_place(self: MirBody, base: i32, idx_local: i32) -> i32:
    self.new_place_with_projection(base, PK_INDEX(), idx_local)

fn MirBody.new_deref_place(self: MirBody, base: i32) -> i32:
    self.new_place_with_projection(base, PK_DEREF(), 0)

fn MirBody.new_downcast_place(self: MirBody, base: i32, variant_idx: i32) -> i32:
    self.new_place_with_projection(base, PK_DOWNCAST(), variant_idx)

fn MirBody.new_rvalue(self: MirBody, kind: i32, d0: i32, d1: i32, d2: i32) -> i32:
    let id = self.rval_kinds.len() as i32
    self.rval_kinds.push(kind)
    self.rval_d0.push(d0)
    self.rval_d1.push(d1)
    self.rval_d2.push(d2)
    id

fn MirBody.new_operand(self: MirBody, kind: i32, d0: i32) -> i32:
    let id = self.operand_kinds.len() as i32
    self.operand_kinds.push(kind)
    self.operand_d0.push(d0)
    id

fn MirBody.new_const(self: MirBody, kind: i32, d0: i32, type_id: i32) -> i32:
    let id = self.const_kinds.len() as i32
    self.const_kinds.push(kind)
    self.const_d0.push(d0)
    self.const_types.push(type_id)
    id

fn MirBody.new_switch_table(self: MirBody, vals: Vec[i32], targets: Vec[i32]) -> i32:
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

fn MirBody.new_agg_fields(self: MirBody, operands: Vec[i32]) -> i32:
    let id = self.agg_field_starts.len() as i32
    let start = self.agg_field_operands.len() as i32
    let count = operands.len() as i32
    self.agg_field_starts.push(start)
    self.agg_field_counts.push(count)
    for i in 0..count:
        self.agg_field_operands.push(operands.get(i as i64))
    id

fn MirBody.new_call_args(self: MirBody, operands: Vec[i32]) -> i32:
    let id = self.call_arg_starts.len() as i32
    let start = self.call_arg_operands.len() as i32
    let count = operands.len() as i32
    self.call_arg_starts.push(start)
    self.call_arg_counts.push(count)
    for i in 0..count:
        self.call_arg_operands.push(operands.get(i as i64))
    id

// ── Query helpers ────────────────────────────────────────────────

fn MirBody.local_count(self: MirBody) -> i32:
    self.local_type_ids.len() as i32

fn MirBody.block_count(self: MirBody) -> i32:
    self.bb_stmt_starts.len() as i32

fn MirBody.stmt_count(self: MirBody) -> i32:
    self.stmt_kinds.len() as i32

fn MirBody.get_local(self: MirBody, idx: i32) -> MirLocalInfo:
    if idx < 0 or idx >= self.local_type_ids.len() as i32:
        return MirLocalInfo { type_id: 0, is_mutable: 0, name_sym: 0, is_user_var: 0 }
    MirLocalInfo {
        type_id: self.local_type_ids.get(idx as i64),
        is_mutable: self.local_mutables.get(idx as i64),
        name_sym: self.local_names.get(idx as i64),
        is_user_var: self.local_is_user_var.get(idx as i64),
    }

fn MirBody.stmt_kind(self: MirBody, idx: i32) -> i32:
    if idx < 0 or idx >= self.stmt_kinds.len() as i32:
        return SK_NOP()
    self.stmt_kinds.get(idx as i64)

fn MirBody.stmt_data0(self: MirBody, idx: i32) -> i32:
    if idx < 0 or idx >= self.stmt_d0.len() as i32:
        return 0
    self.stmt_d0.get(idx as i64)

fn MirBody.stmt_data1(self: MirBody, idx: i32) -> i32:
    if idx < 0 or idx >= self.stmt_d1.len() as i32:
        return 0
    self.stmt_d1.get(idx as i64)

fn MirBody.term_kind(self: MirBody, bb: i32) -> i32:
    if bb < 0 or bb >= self.bb_term_kinds.len() as i32:
        return TK_UNREACHABLE()
    self.bb_term_kinds.get(bb as i64)

fn MirBody.term_data0(self: MirBody, bb: i32) -> i32:
    if bb < 0 or bb >= self.bb_term_d0.len() as i32:
        return 0
    self.bb_term_d0.get(bb as i64)

fn MirBody.term_data1(self: MirBody, bb: i32) -> i32:
    if bb < 0 or bb >= self.bb_term_d1.len() as i32:
        return 0
    self.bb_term_d1.get(bb as i64)

fn MirBody.term_data2(self: MirBody, bb: i32) -> i32:
    if bb < 0 or bb >= self.bb_term_d2.len() as i32:
        return 0
    self.bb_term_d2.get(bb as i64)

fn MirBody.term_data3(self: MirBody, bb: i32) -> i32:
    if bb < 0 or bb >= self.bb_term_d3.len() as i32:
        return 0
    self.bb_term_d3.get(bb as i64)

// ── Deterministic dump rendering ─────────────────────────────────

fn dump_mir_module(mir_mod: MirModule, pool: InternPool, sema: Sema) -> str:
    var out = ""
    out = out ++ "mir module functions=" ++ int_to_string(mir_mod.bodies.len() as i32) ++ "\n"
    for i in 0..mir_mod.bodies.len() as i32:
        if i > 0:
            out = out ++ "\n"
        out = out ++ dump_mir_body(mir_mod.bodies.get(i as i64), pool, sema)
    out

fn dump_mir_body(body: MirBody, pool: InternPool, sema: Sema) -> str:
    var out = ""
    let fn_name = if body.fn_sym != 0: pool.resolve(body.fn_sym) else: "<anon>"
    out = out ++ "fn " ++ fn_name ++ " " ++ lbrace() ++ "\n"
    out = out ++ "  locals:\n"

    for li in 0..body.local_type_ids.len() as i32:
        let tid = body.local_type_ids.get(li as i64)
        let ty_name = if tid != 0: sema.type_name(tid) else: "<inferred>"
        var line = "    _" ++ int_to_string(li) ++ ": " ++ ty_name
        if li == 0:
            line = line ++ "  // return"
        let name_sym = body.local_names.get(li as i64)
        if body.local_is_user_var.get(li as i64) != 0 and name_sym != 0:
            line = line ++ "  // " ++ pool.resolve(name_sym)
        if body.local_mutables.get(li as i64) != 0:
            line = line ++ " [mut]"
        out = out ++ line ++ "\n"

    for bb in 0..body.bb_stmt_starts.len() as i32:
        out = out ++ "\n"
        out = out ++ "  bb" ++ int_to_string(bb) ++ ": " ++ lbrace() ++ "\n"

        let stmt_start = body.bb_stmt_starts.get(bb as i64)
        let stmt_count = body.bb_stmt_counts.get(bb as i64)
        for si in 0..stmt_count:
            let stmt_id = stmt_start + si
            out = out ++ "    " ++ mir_stmt_text(body, stmt_id, pool, sema) ++ "\n"

        out = out ++ "    " ++ mir_term_text(body, bb, pool, sema) ++ "\n"
        out = out ++ "  " ++ rbrace() ++ "\n"

    out = out ++ rbrace() ++ "\n"
    out

fn mir_stmt_text(body: MirBody, stmt_id: i32, pool: InternPool, sema: Sema) -> str:
    let kind = body.stmt_kind(stmt_id)
    let d0 = body.stmt_data0(stmt_id)
    let d1 = body.stmt_data1(stmt_id)

    if kind == SK_ASSIGN():
        return mir_place_text(body, d0) ++ " = " ++ mir_rvalue_text(body, d1, pool, sema) ++ ";"
    if kind == SK_STORAGE_LIVE():
        return "StorageLive(_" ++ int_to_string(d0) ++ ");"
    if kind == SK_STORAGE_DEAD():
        return "StorageDead(_" ++ int_to_string(d0) ++ ");"
    if kind == SK_DROP():
        return "drop(" ++ mir_place_text(body, d0) ++ ");"
    if kind == SK_NOP():
        return "nop;"

    "stmt<" ++ int_to_string(kind) ++ ">(" ++ int_to_string(d0) ++ ", " ++ int_to_string(d1) ++ ");"

fn mir_term_text(body: MirBody, bb: i32, pool: InternPool, sema: Sema) -> str:
    let kind = body.term_kind(bb)
    let d0 = body.term_data0(bb)
    let d1 = body.term_data1(bb)
    let d2 = body.term_data2(bb)
    let d3 = body.term_data3(bb)

    if kind == TK_GOTO():
        return "goto -> bb" ++ int_to_string(d0) ++ ";"

    if kind == TK_RETURN():
        return "return;"

    if kind == TK_UNREACHABLE():
        return "unreachable;"

    if kind == TK_SWITCH_INT():
        let op_text = mir_operand_text(body, d0, pool, sema)
        var table_text = ""
        if d1 >= 0 and d1 < body.switch_table_starts.len() as i32:
            let start = body.switch_table_starts.get(d1 as i64)
            let count = body.switch_table_counts.get(d1 as i64)
            for i in 0..count:
                if i > 0:
                    table_text = table_text ++ ", "
                table_text = table_text ++ int_to_string(body.switch_table_vals.get((start + i) as i64))
                table_text = table_text ++ ": bb" ++ int_to_string(body.switch_table_targets.get((start + i) as i64))
        if d2 != 0 or table_text.len() == 0:
            if table_text.len() > 0:
                table_text = table_text ++ ", "
            table_text = table_text ++ "otherwise: bb" ++ int_to_string(d2)
        return "switchInt(" ++ op_text ++ ") -> [" ++ table_text ++ "];"

    if kind == TK_CALL():
        let fn_text = mir_operand_text(body, d0, pool, sema)
        let args_text = mir_call_args_text(body, d1, pool, sema)
        let dest_text = mir_place_text(body, d2)
        return "call " ++ fn_text ++ "(" ++ args_text ++ ") -> [return: " ++ dest_text ++ ", next: bb" ++ int_to_string(d3) ++ "];"

    if kind == TK_DROP_AND_GOTO():
        return "drop(" ++ mir_place_text(body, d0) ++ ") -> bb" ++ int_to_string(d1) ++ ";"

    "term<" ++ int_to_string(kind) ++ ">(" ++ int_to_string(d0) ++ ", " ++ int_to_string(d1) ++ ", " ++ int_to_string(d2) ++ ", " ++ int_to_string(d3) ++ ");"

fn mir_place_text(body: MirBody, place_id: i32) -> str:
    if place_id < 0 or place_id >= body.place_locals.len() as i32:
        return "_?"

    var out = "_" ++ int_to_string(body.place_locals.get(place_id as i64))
    let p_start = body.place_proj_starts.get(place_id as i64)
    let p_count = body.place_proj_counts.get(place_id as i64)

    for i in 0..p_count:
        let pk = body.proj_kinds.get((p_start + i) as i64)
        let pd = body.proj_d0.get((p_start + i) as i64)

        if pk == PK_FIELD():
            out = out ++ ".f" ++ int_to_string(pd)
            continue
        if pk == PK_INDEX():
            out = out ++ "[_" ++ int_to_string(pd) ++ "]"
            continue
        if pk == PK_DEREF():
            out = out ++ ".*"
            continue
        if pk == PK_DOWNCAST():
            out = out ++ "<as v" ++ int_to_string(pd) ++ ">"
            continue

        out = out ++ "<p" ++ int_to_string(pk) ++ ":" ++ int_to_string(pd) ++ ">"

    out

fn mir_rvalue_text(body: MirBody, rval_id: i32, pool: InternPool, sema: Sema) -> str:
    if rval_id < 0 or rval_id >= body.rval_kinds.len() as i32:
        return "<rvalue?>"

    let k = body.rval_kinds.get(rval_id as i64)
    let d0 = body.rval_d0.get(rval_id as i64)
    let d1 = body.rval_d1.get(rval_id as i64)
    let d2 = body.rval_d2.get(rval_id as i64)

    if k == RK_USE():
        return mir_operand_text(body, d0, pool, sema)

    if k == RK_BIN_OP():
        return "binop(" ++ mir_binop_name(d0) ++ ", " ++ mir_operand_text(body, d1, pool, sema) ++ ", " ++ mir_operand_text(body, d2, pool, sema) ++ ")"

    if k == RK_UN_OP():
        return "unop(" ++ mir_unop_name(d0) ++ ", " ++ mir_operand_text(body, d1, pool, sema) ++ ")"

    if k == RK_REF():
        let borrow = if d0 == BK_EXCLUSIVE(): "mut" else: "shared"
        return "ref(" ++ borrow ++ ", " ++ mir_place_text(body, d1) ++ ")"

    if k == RK_ADDR_OF():
        return "addr_of(" ++ mir_place_text(body, d0) ++ ")"

    if k == RK_AGGREGATE():
        return "aggregate(kind=" ++ int_to_string(d0) ++ ", fields=[" ++ mir_agg_fields_text(body, d1, pool, sema) ++ "])"

    if k == RK_DISCRIMINANT():
        return "discriminant(" ++ mir_place_text(body, d0) ++ ")"

    if k == RK_CAST():
        let ty = if d1 != 0: sema.type_name(d1) else: "<inferred>"
        return "cast(" ++ mir_operand_text(body, d0, pool, sema) ++ " as " ++ ty ++ ")"

    if k == RK_LEN():
        return "len(" ++ mir_place_text(body, d0) ++ ")"

    return "rvalue<" ++ int_to_string(k) ++ ">(" ++ int_to_string(d0) ++ ", " ++ int_to_string(d1) ++ ", " ++ int_to_string(d2) ++ ")"

fn mir_operand_text(body: MirBody, operand_id: i32, pool: InternPool, sema: Sema) -> str:
    if operand_id < 0 or operand_id >= body.operand_kinds.len() as i32:
        return "<op?>"

    let k = body.operand_kinds.get(operand_id as i64)
    let d0 = body.operand_d0.get(operand_id as i64)

    if k == OK_COPY():
        return "copy " ++ mir_place_text(body, d0)
    if k == OK_MOVE():
        return "move " ++ mir_place_text(body, d0)
    if k == OK_CONSTANT():
        return mir_const_text(body, d0, pool, sema)

    "op<" ++ int_to_string(k) ++ ">(" ++ int_to_string(d0) ++ ")"

fn mir_const_text(body: MirBody, const_id: i32, pool: InternPool, sema: Sema) -> str:
    if const_id < 0 or const_id >= body.const_kinds.len() as i32:
        return "const<?>"

    let k = body.const_kinds.get(const_id as i64)
    let d0 = body.const_d0.get(const_id as i64)
    let ty = body.const_types.get(const_id as i64)

    if k == CK_INT():
        let ty_name = if ty != 0: sema.type_name(ty) else: "i32"
        return "const " ++ int_to_string(d0) ++ ty_name

    if k == CK_BOOL():
        return if d0 != 0: "const true" else: "const false"

    if k == CK_STR():
        if d0 == 0:
            return "const \"\""
        return "const \"" ++ pool.resolve(d0) ++ "\""

    if k == CK_UNIT():
        return "const ()"

    if k == CK_FLOAT():
        if d0 != 0:
            return "const " ++ pool.resolve(d0)
        return "const 0.0"

    if k == CK_ZERO_SIZED():
        let ty_name = if ty != 0: sema.type_name(ty) else: "<zst>"
        return "const zst(" ++ ty_name ++ ")"

    "const<" ++ int_to_string(k) ++ ">(" ++ int_to_string(d0) ++ ")"

fn mir_agg_fields_text(body: MirBody, fields_id: i32, pool: InternPool, sema: Sema) -> str:
    if fields_id < 0 or fields_id >= body.agg_field_starts.len() as i32:
        return ""

    let start = body.agg_field_starts.get(fields_id as i64)
    let count = body.agg_field_counts.get(fields_id as i64)
    var out = ""
    for i in 0..count:
        if i > 0:
            out = out ++ ", "
        out = out ++ mir_operand_text(body, body.agg_field_operands.get((start + i) as i64), pool, sema)
    out

fn mir_call_args_text(body: MirBody, args_id: i32, pool: InternPool, sema: Sema) -> str:
    if args_id < 0 or args_id >= body.call_arg_starts.len() as i32:
        return ""

    let start = body.call_arg_starts.get(args_id as i64)
    let count = body.call_arg_counts.get(args_id as i64)
    var out = ""
    for i in 0..count:
        if i > 0:
            out = out ++ ", "
        out = out ++ mir_operand_text(body, body.call_arg_operands.get((start + i) as i64), pool, sema)
    out

fn mir_binop_name(op: i32) -> str:
    if op == OP_ADD(): return "add"
    if op == OP_SUB(): return "sub"
    if op == OP_MUL(): return "mul"
    if op == OP_DIV(): return "div"
    if op == OP_MOD(): return "mod"
    if op == OP_EQ(): return "eq"
    if op == OP_NEQ(): return "neq"
    if op == OP_LT(): return "lt"
    if op == OP_GT(): return "gt"
    if op == OP_LTE(): return "lte"
    if op == OP_GTE(): return "gte"
    if op == OP_AND(): return "and"
    if op == OP_OR(): return "or"
    if op == OP_BIT_AND(): return "bit_and"
    if op == OP_BIT_OR(): return "bit_or"
    if op == OP_BIT_XOR(): return "bit_xor"
    if op == OP_SHL(): return "shl"
    if op == OP_SHR(): return "shr"
    if op == OP_DEFAULT(): return "default"
    if op == OP_CONCAT(): return "concat"
    if op == OP_ADD_WRAP(): return "add_wrap"
    if op == OP_SUB_WRAP(): return "sub_wrap"
    if op == OP_MUL_WRAP(): return "mul_wrap"
    if op == OP_IN(): return "in"
    if op == OP_NOT_IN(): return "not_in"
    "op" ++ int_to_string(op)

fn mir_unop_name(op: i32) -> str:
    if op == UOP_NEGATE(): return "neg"
    if op == UOP_NOT(): return "not"
    if op == UOP_REF(): return "ref"
    if op == UOP_MUT_REF(): return "mut_ref"
    if op == UOP_DEREF(): return "deref"
    if op == UOP_TRY(): return "try"
    "uop" ++ int_to_string(op)
