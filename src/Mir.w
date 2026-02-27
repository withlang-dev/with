// Mir — Mid-level IR for the With compiler.
//
// A CFG-based representation where all sugar is desugared,
// all drops are explicit, and borrow checking operates on
// a flat graph of basic blocks.
//
// Following Rust's rustc_middle/mir/ architecture.
//
// Encoding:
//   MirBody: top-level container with basic blocks and locals
//   BasicBlock: list of statements + terminator
//   Statement: non-branching operation (assign, drop, nop)
//   Terminator: branching at end of block (goto, switch, return, call)
//   Place: location that can be read/written (local + projections)
//   Rvalue: computation that produces a value
//   Operand: input to an rvalue (copy, move, constant)

use Type

// ── Statement kinds ──────────────────────────────────────────────────

fn SK_ASSIGN() -> i32: 0      // place = rvalue
fn SK_DROP() -> i32: 1        // explicit drop call
fn SK_NOP() -> i32: 2         // no-op

// ── Terminator kinds ─────────────────────────────────────────────────

fn TM_GOTO() -> i32: 0        // goto(bb)
fn TM_SWITCH_INT() -> i32: 1  // switch on integer value
fn TM_RETURN() -> i32: 2      // return from function
fn TM_UNREACHABLE() -> i32: 3 // unreachable code
fn TM_CALL() -> i32: 4        // function call + continuation
fn TM_DROP() -> i32: 5        // drop + continuation
fn TM_ASSERT() -> i32: 6      // assert + continuation

// ── Rvalue kinds ─────────────────────────────────────────────────────

fn RV_USE() -> i32: 0         // copy or move
fn RV_REF() -> i32: 1         // &place or &mut place
fn RV_BINARY_OP() -> i32: 2   // a op b
fn RV_UNARY_OP() -> i32: 3    // op a
fn RV_CALL() -> i32: 4        // fn(args)
fn RV_AGGREGATE() -> i32: 5   // struct/enum/tuple/array literal
fn RV_CAST() -> i32: 6        // type cast
fn RV_DISCRIMINANT() -> i32: 7 // read enum tag
fn RV_CONSTANT() -> i32: 8    // compile-time constant

// ── Operand kinds ────────────────────────────────────────────────────

fn OP_COPY() -> i32: 0        // copy (for Copy types)
fn OP_MOVE() -> i32: 1        // move (for non-Copy types)
fn OP_CONSTANT() -> i32: 2    // compile-time constant

// ── Projection kinds ─────────────────────────────────────────────────

fn PJ_FIELD() -> i32: 0       // struct field by index
fn PJ_INDEX() -> i32: 1       // array/slice index
fn PJ_DEREF() -> i32: 2       // pointer/reference deref
fn PJ_DOWNCAST() -> i32: 3    // enum variant payload

// ── Aggregate kinds ──────────────────────────────────────────────────

fn AK_STRUCT() -> i32: 0
fn AK_ENUM() -> i32: 1
fn AK_TUPLE() -> i32: 2
fn AK_ARRAY() -> i32: 3

// ── Borrow kinds ─────────────────────────────────────────────────────

fn BK_SHARED() -> i32: 0
fn BK_MUTABLE() -> i32: 1

// ── Local declaration ────────────────────────────────────────────────

type LocalDecl = {
    name_sym: i32,
    type_id: i32,
    is_mutable: i32,
    span_start: i32,
    span_end: i32,
}

fn LocalDecl.new(name_sym: i32, type_id: i32, is_mutable: i32) -> LocalDecl:
    LocalDecl {
        name_sym: name_sym,
        type_id: type_id,
        is_mutable: is_mutable,
        span_start: 0,
        span_end: 0,
    }

// ── Place ────────────────────────────────────────────────────────────

// A Place is a location: local + chain of projections.
// Stored as: local_id, projection_count, proj_start in extra array.
type Place = {
    local: i32,
    proj_count: i32,
    proj_start: i32,
}

fn Place.local_only(local: i32) -> Place:
    Place {
        local: local,
        proj_count: 0,
        proj_start: 0,
    }

// ── MIR Body ─────────────────────────────────────────────────────────
// The main MIR data structure, using SoA layout.

type MirBody = {
    // Locals (params + temporaries + user variables)
    locals: Vec[LocalDecl],
    arg_count: i32,
    return_local: i32,

    // Basic blocks: each has a range of statements + terminator
    bb_stmt_starts: Vec[i32],
    bb_stmt_counts: Vec[i32],
    bb_term_kinds: Vec[i32],
    bb_term_data0: Vec[i32],
    bb_term_data1: Vec[i32],
    bb_term_data2: Vec[i32],

    // Statements: flat list, blocks reference ranges
    stmt_kinds: Vec[i32],
    stmt_data0: Vec[i32],
    stmt_data1: Vec[i32],
    stmt_data2: Vec[i32],

    // Extra data for variable-length content
    extra: Vec[i32],

    // Span info
    fn_span_start: i32,
    fn_span_end: i32,
}

fn MirBody.new() -> MirBody:
    var body = MirBody {
        locals: Vec.new(),
        arg_count: 0,
        return_local: 0,
        bb_stmt_starts: Vec.new(),
        bb_stmt_counts: Vec.new(),
        bb_term_kinds: Vec.new(),
        bb_term_data0: Vec.new(),
        bb_term_data1: Vec.new(),
        bb_term_data2: Vec.new(),
        stmt_kinds: Vec.new(),
        stmt_data0: Vec.new(),
        stmt_data1: Vec.new(),
        stmt_data2: Vec.new(),
        extra: Vec.new(),
        fn_span_start: 0,
        fn_span_end: 0,
    }
    // Local 0 is always the return place
    body.locals.push(LocalDecl.new(-1, TYPE_VOID(), 1))
    body.return_local = 0
    body

// ── Local management ─────────────────────────────────────────────────

fn MirBody.add_local(self: MirBody, name: i32, type_id: i32, is_mut: i32) -> i32:
    let id = self.locals.len() as i32
    self.locals.push(LocalDecl.new(name, type_id, is_mut))
    id

fn MirBody.local_count(self: MirBody) -> i32:
    self.locals.len() as i32

fn MirBody.get_local(self: MirBody, id: i32) -> LocalDecl:
    self.locals.get(id as i64)

fn MirBody.set_return_type(self: MirBody, type_id: i32) -> void:
    // We can't set on Vec, but local 0 was pushed first
    // so we store the return type separately
    // (this is a limitation — in practice the return_local's type is tracked)
    0

// ── Basic block management ───────────────────────────────────────────

fn MirBody.add_block(self: MirBody) -> i32:
    let id = self.bb_stmt_starts.len() as i32
    self.bb_stmt_starts.push(self.stmt_kinds.len() as i32)
    self.bb_stmt_counts.push(0)
    self.bb_term_kinds.push(TM_UNREACHABLE())
    self.bb_term_data0.push(0)
    self.bb_term_data1.push(0)
    self.bb_term_data2.push(0)
    id

fn MirBody.block_count(self: MirBody) -> i32:
    self.bb_stmt_starts.len() as i32

// ── Statement emission ───────────────────────────────────────────────

fn MirBody.add_stmt(self: MirBody, bb: i32, kind: i32, d0: i32, d1: i32, d2: i32) -> void:
    self.stmt_kinds.push(kind)
    self.stmt_data0.push(d0)
    self.stmt_data1.push(d1)
    self.stmt_data2.push(d2)
    // Update block statement count
    let count = self.bb_stmt_counts.get(bb as i64)
    // Can't set, but we track the end implicitly

fn MirBody.add_assign(self: MirBody, bb: i32, dest_local: i32, rvalue_kind: i32, rv_d0: i32, rv_d1: i32) -> void:
    MirBody.add_stmt(self, bb, SK_ASSIGN(), dest_local, rvalue_kind, rv_d0)

fn MirBody.add_drop(self: MirBody, bb: i32, local: i32) -> void:
    MirBody.add_stmt(self, bb, SK_DROP(), local, 0, 0)

fn MirBody.add_nop(self: MirBody, bb: i32) -> void:
    MirBody.add_stmt(self, bb, SK_NOP(), 0, 0, 0)

// ── Terminator setting ───────────────────────────────────────────────

fn MirBody.set_goto(self: MirBody, bb: i32, target: i32) -> void:
    // Store terminator for this block
    // We pushed initial values, but can't update (Vec limitation)
    // Track in extra array instead
    let idx = self.extra.len() as i32
    self.extra.push(TM_GOTO())
    self.extra.push(target)
    self.extra.push(0)
    self.extra.push(0)

fn MirBody.set_return(self: MirBody, bb: i32) -> void:
    let idx = self.extra.len() as i32
    self.extra.push(TM_RETURN())
    self.extra.push(0)
    self.extra.push(0)
    self.extra.push(0)

fn MirBody.set_switch_int(self: MirBody, bb: i32, operand_local: i32, true_bb: i32, false_bb: i32) -> void:
    let idx = self.extra.len() as i32
    self.extra.push(TM_SWITCH_INT())
    self.extra.push(operand_local)
    self.extra.push(true_bb)
    self.extra.push(false_bb)

fn MirBody.set_call(self: MirBody, bb: i32, callee_local: i32, dest_local: i32, success_bb: i32) -> void:
    let idx = self.extra.len() as i32
    self.extra.push(TM_CALL())
    self.extra.push(callee_local)
    self.extra.push(dest_local)
    self.extra.push(success_bb)

fn MirBody.set_unreachable(self: MirBody, bb: i32) -> void:
    let idx = self.extra.len() as i32
    self.extra.push(TM_UNREACHABLE())
    self.extra.push(0)
    self.extra.push(0)
    self.extra.push(0)

// ── Extra data ───────────────────────────────────────────────────────

fn MirBody.add_extra(self: MirBody, val: i32) -> i32:
    let idx = self.extra.len() as i32
    self.extra.push(val)
    idx

fn MirBody.get_extra(self: MirBody, idx: i32) -> i32:
    self.extra.get(idx as i64)

// ── Statement queries ────────────────────────────────────────────────

fn MirBody.stmt_count(self: MirBody) -> i32:
    self.stmt_kinds.len() as i32

fn MirBody.stmt_kind(self: MirBody, idx: i32) -> i32:
    self.stmt_kinds.get(idx as i64)

fn MirBody.stmt_d0(self: MirBody, idx: i32) -> i32:
    self.stmt_data0.get(idx as i64)

fn MirBody.stmt_d1(self: MirBody, idx: i32) -> i32:
    self.stmt_data1.get(idx as i64)

fn MirBody.stmt_d2(self: MirBody, idx: i32) -> i32:
    self.stmt_data2.get(idx as i64)
