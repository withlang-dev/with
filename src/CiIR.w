// CiIR — IR for the C-to-With migrator (`with migrate`).
//
// Pipeline:
//
//     libclang AST  →  CiExpr / CiStmt / CiDecl  →  CiPrint  →  With source
//
// This module replaces the string-based `ci_trans_expr` / `ci_trans_stmt`
// lowering in CImport.w. Structural correctness (if/else nesting,
// array-to-pointer decay, operator precedence, temp uniqueness,
// sequenced side effects) moves out of string concatenation and into
// tree construction.
//
// Storage follows the SoA idiom used throughout the compiler (see
// src/Ast.w): parallel Vec[i32] arrays keyed by a stable id handle.
// Node 0 is the null sentinel in every pool. Variable-length payloads
// (init list items, call args, fn param lists) live in a single flat
// `extra: Vec[i32]` per pool, referenced by (start, count).
//
// Every CiExpr carries its resolved CiType (an index into the shared
// CiTypePool). The printer must not re-query libclang at print time —
// sessions may be disposed by then.
//
// The migrator now lowers expressions and statements structurally.
// Unsupported constructs fail by returning the null sentinel from
// lowering, rather than escaping through verbatim raw-string nodes.

extern fn with_eprint(s: str) -> void
extern fn with_str_clone(s: str) -> str
extern fn with_alloc(size: i64) -> *mut u8

fn ci_ir_owned_text(text: str) -> str:
    if text.len() == 0:
        return ""
    with_str_clone(text)

// ── CiType ────────────────────────────────────────────────────

type CiTypeId = distinct i32

enum CiTypeKind: i32:
    CT_VOID = 1
    CT_BOOL = 2
    CT_INT = 3       // d0 = bits, d1 = is_unsigned (0 or 1)
    CT_FLOAT = 4     // d0 = bits
    CT_POINTER = 5   // d0 = pointee_ty_id, d1 = is_const
    CT_ARRAY = 6     // d0 = elem_ty_id, d1 = size (CI_SIZE_INCOMPLETE for [])
    CT_STRUCT = 7    // d0 = name_sym_idx
    CT_ENUM = 8      // d0 = name_sym_idx
    CT_FN_PTR = 9    // d0 = ret_ty_id, d1 = params_extra_start, d2 = param_count
    CT_NAMED = 10    // d0 = name_sym_idx  (typedef reference)

const CI_SIZE_INCOMPLETE: i32 = 0 - 1

type CiTypePoolState {
    kinds: Vec[i32],
    data0: Vec[i32],
    data1: Vec[i32],
    data2: Vec[i32],
    extra: Vec[i32],
    strings: Vec[str],
    frozen: i32,
}

type CiTypePool {
    state: *mut CiTypePoolState,
}

fn CiTypePool.new -> CiTypePool:
    let ptr = with_alloc(256) as *mut CiTypePoolState
    unsafe: *ptr = CiTypePoolState {
        kinds: Vec.new(),
        data0: Vec.new(),
        data1: Vec.new(),
        data2: Vec.new(),
        extra: Vec.new(),
        strings: Vec.new(),
        frozen: 0,
    }
    ptr.kinds.push(0)
    ptr.data0.push(0)
    ptr.data1.push(0)
    ptr.data2.push(0)
    CiTypePool { state: ptr }

fn CiTypePool.add(self: CiTypePool, kind: i32, d0: i32, d1: i32, d2: i32) -> CiTypeId:
    let st = self.state
    if st.frozen != 0:
        with_eprint("BUG: CiTypePool.add called after freeze")
    let id = st.kinds.len() as i32
    st.kinds.push(kind)
    st.data0.push(d0)
    st.data1.push(d1)
    st.data2.push(d2)
    id as CiTypeId

fn CiTypePool.add_extra(self: CiTypePool, value: i32) -> i32:
    let st = self.state
    if st.frozen != 0:
        with_eprint("BUG: CiTypePool.add_extra called after freeze")
    let idx = st.extra.len() as i32
    st.extra.push(value)
    idx

fn CiTypePool.add_string(self: CiTypePool, s: str) -> i32:
    let st = self.state
    if st.frozen != 0:
        with_eprint("BUG: CiTypePool.add_string called after freeze")
    let idx = st.strings.len() as i32
    st.strings.push(s)
    idx

fn CiTypePool.freeze(self: CiTypePool):
    self.state.frozen = 1

fn CiTypePool.kind(self: CiTypePool, id: CiTypeId) -> i32:
    self.state.kinds.get((id as i32) as i64)

fn CiTypePool.get_d0(self: CiTypePool, id: CiTypeId) -> i32:
    self.state.data0.get((id as i32) as i64)

fn CiTypePool.get_d1(self: CiTypePool, id: CiTypeId) -> i32:
    self.state.data1.get((id as i32) as i64)

fn CiTypePool.get_d2(self: CiTypePool, id: CiTypeId) -> i32:
    self.state.data2.get((id as i32) as i64)

fn CiTypePool.get_extra(self: CiTypePool, idx: i32) -> i32:
    self.state.extra.get(idx as i64)

fn CiTypePool.get_string(self: CiTypePool, idx: i32) -> str:
    self.state.strings.get(idx as i64)

// Type constructor helpers.
fn CiTypePool.ty_void(self: CiTypePool) -> CiTypeId:
    self.add(CiTypeKind.CT_VOID, 0, 0, 0)

fn CiTypePool.ty_bool(self: CiTypePool) -> CiTypeId:
    self.add(CiTypeKind.CT_BOOL, 0, 0, 0)

fn CiTypePool.ty_int(self: CiTypePool, bits: i32, is_unsigned: i32) -> CiTypeId:
    self.add(CiTypeKind.CT_INT, bits, is_unsigned, 0)

fn CiTypePool.ty_float(self: CiTypePool, bits: i32) -> CiTypeId:
    self.add(CiTypeKind.CT_FLOAT, bits, 0, 0)

fn CiTypePool.ty_pointer(self: CiTypePool, pointee: CiTypeId, is_const: i32) -> CiTypeId:
    self.add(CiTypeKind.CT_POINTER, pointee as i32, is_const, 0)

fn CiTypePool.ty_array(self: CiTypePool, elem: CiTypeId, size: i32) -> CiTypeId:
    self.add(CiTypeKind.CT_ARRAY, elem as i32, size, 0)

fn CiTypePool.ty_struct(self: CiTypePool, name_sym: i32) -> CiTypeId:
    self.add(CiTypeKind.CT_STRUCT, name_sym, 0, 0)

fn CiTypePool.ty_enum(self: CiTypePool, name_sym: i32) -> CiTypeId:
    self.add(CiTypeKind.CT_ENUM, name_sym, 0, 0)

fn CiTypePool.ty_named(self: CiTypePool, name_sym: i32) -> CiTypeId:
    self.add(CiTypeKind.CT_NAMED, name_sym, 0, 0)

fn CiTypePool.ty_fn_ptr(self: CiTypePool, ret: CiTypeId, params_start: i32, param_count: i32) -> CiTypeId:
    self.add(CiTypeKind.CT_FN_PTR, ret as i32, params_start, param_count)


// ── CiExpr ────────────────────────────────────────────────────

type CiExprId = distinct i32

enum CiExprKind: i32:
    // Literals — d0 = string_idx of the already-formatted literal
    // text (decimal digits for ints/chars, suffix-stripped float
    // text, full quoted form for string literals). Printer is
    // verbatim; the lowering pass owns formatting decisions so the
    // result matches the legacy migrator byte-for-byte.
    CIE_INT_LIT = 1          // d0 = string_idx
    CIE_FLOAT_LIT = 2        // d0 = string_idx
    CIE_CHAR_LIT = 3         // d0 = string_idx (decimal codepoint as text)
    CIE_STRING_LIT = 4       // d0 = string_idx (full quoted form)
    CIE_BOOL_LIT = 5         // d0 = 0 or 1
    CIE_NULL_PTR = 6         // no data — represents C NULL / With null

    // References
    CIE_IDENT = 10           // d0 = name_sym_idx

    // Arithmetic / logical
    CIE_BINARY = 20          // d0 = CiBinOp, d1 = lhs, d2 = rhs
    CIE_UNARY = 21           // d0 = CiUnaryOp, d1 = operand
    CIE_PAREN = 22           // d0 = inner — preserves parenthesization for debug

    // Postfix / lvalue
    CIE_CALL = 30            // d0 = callee, d1 = args_start, d2 = args_count
    CIE_FIELD = 31           // d0 = base, d1 = field_sym_idx, d2 = is_arrow
    CIE_INDEX = 32           // d0 = base, d1 = index, d2 = raw pointer index
    CIE_CAST = 33            // d0 = target_ty_id, d1 = operand
    CIE_DEREF = 34           // d0 = operand
    CIE_ADDR_OF = 35         // d0 = operand, d1 = is_mut (0 = `&`, 1 = `&mut`)
    CIE_ARRAY_DECAY = 36     // d0 = operand, d1 = elem_ty_id

    // Side-effecting
    CIE_PRE_INC = 40         // d0 = operand
    CIE_PRE_DEC = 41         // d0 = operand
    CIE_POST_INC = 42        // d0 = operand
    CIE_POST_DEC = 43        // d0 = operand
    CIE_COMPOUND_ASSIGN = 44 // d0 = CiBinOp, d1 = lhs, d2 = rhs
    CIE_ASSIGN = 45          // d0 = lhs, d1 = rhs

    // Control-expr-shaped
    CIE_TERNARY = 50         // d0 = cond, d1 = then_expr, d2 = else_expr
    CIE_COMMA = 51           // d0 = extra_start, d1 = count

    // Compile-time
    CIE_SIZEOF_TYPE = 60     // d0 = target_ty_id
    CIE_SIZEOF_EXPR = 61     // d0 = operand

    // Initializers
    CIE_INIT_LIST = 70         // d0 = extra_start, d1 = count
    CIE_DESIGNATED_INIT = 71   // d0 = extra_start (alt [field_sym_idx, expr_id]), d1 = field_count


enum CiBinOp: i32:
    CIBO_ADD = 0
    CIBO_SUB = 1
    CIBO_MUL = 2
    CIBO_DIV = 3
    CIBO_MOD = 4
    CIBO_EQ = 5
    CIBO_NEQ = 6
    CIBO_LT = 7
    CIBO_LTE = 8
    CIBO_GT = 9
    CIBO_GTE = 10
    CIBO_LOGICAL_AND = 11
    CIBO_LOGICAL_OR = 12
    CIBO_BIT_AND = 13
    CIBO_BIT_OR = 14
    CIBO_BIT_XOR = 15
    CIBO_SHL = 16
    CIBO_SHR = 17
    // Wrap-on-overflow arithmetic for unsigned operands. With's
    // regular +/-/* trap on overflow; the legacy migrator emits
    // +% / -% / *% for unsigned arithmetic to preserve C
    // wraparound semantics.
    CIBO_ADD_WRAP = 18
    CIBO_SUB_WRAP = 19
    CIBO_MUL_WRAP = 20
    // Plain assignment — maps C's `=` (as a binary op returning a
    // value). Used for expressions like `(x = y)`.
    CIBO_ASSIGN = 21

enum CiUnaryOp: i32:
    CIUO_NEG = 0
    CIUO_PLUS = 1
    CIUO_LOGICAL_NOT = 2
    CIUO_BIT_NOT = 3

type CiExprPoolState {
    kinds: Vec[i32],
    data0: Vec[i32],
    data1: Vec[i32],
    data2: Vec[i32],
    types: Vec[i32],
    extra: Vec[i32],
    strings: Vec[str],
    frozen: i32,
}

type CiExprPool {
    state: *mut CiExprPoolState,
}

fn CiExprPool.new -> CiExprPool:
    let ptr = with_alloc(256) as *mut CiExprPoolState
    unsafe: *ptr = CiExprPoolState {
        kinds: Vec.new(),
        data0: Vec.new(),
        data1: Vec.new(),
        data2: Vec.new(),
        types: Vec.new(),
        extra: Vec.new(),
        strings: Vec.new(),
        frozen: 0,
    }
    ptr.kinds.push(0)
    ptr.data0.push(0)
    ptr.data1.push(0)
    ptr.data2.push(0)
    ptr.types.push(0)
    CiExprPool { state: ptr }

fn CiExprPool.add(self: CiExprPool, kind: i32, d0: i32, d1: i32, d2: i32, ty: CiTypeId) -> CiExprId:
    let st = self.state
    if st.frozen != 0:
        with_eprint("BUG: CiExprPool.add called after freeze")
    let id = st.kinds.len() as i32
    st.kinds.push(kind)
    st.data0.push(d0)
    st.data1.push(d1)
    st.data2.push(d2)
    st.types.push(ty as i32)
    id as CiExprId

fn CiExprPool.add_extra(self: CiExprPool, value: i32) -> i32:
    let st = self.state
    if st.frozen != 0:
        with_eprint("BUG: CiExprPool.add_extra called after freeze")
    let idx = st.extra.len() as i32
    st.extra.push(value)
    idx

fn CiExprPool.add_string(self: CiExprPool, s: str) -> i32:
    let st = self.state
    if st.frozen != 0:
        with_eprint("BUG: CiExprPool.add_string called after freeze")
    let idx = st.strings.len() as i32
    st.strings.push(s)
    idx

fn CiExprPool.freeze(self: CiExprPool):
    self.state.frozen = 1

fn CiExprPool.kind(self: CiExprPool, id: CiExprId) -> i32:
    self.state.kinds.get((id as i32) as i64)

fn CiExprPool.get_d0(self: CiExprPool, id: CiExprId) -> i32:
    self.state.data0.get((id as i32) as i64)

fn CiExprPool.get_d1(self: CiExprPool, id: CiExprId) -> i32:
    self.state.data1.get((id as i32) as i64)

fn CiExprPool.get_d2(self: CiExprPool, id: CiExprId) -> i32:
    self.state.data2.get((id as i32) as i64)

fn CiExprPool.get_type(self: CiExprPool, id: CiExprId) -> CiTypeId:
    (self.state.types.get((id as i32) as i64)) as CiTypeId

fn CiExprPool.set_type(self: CiExprPool, id: CiExprId, ty: CiTypeId):
    let st = self.state
    if st.frozen != 0:
        with_eprint("BUG: CiExprPool.set_type called after freeze")
    let idx = (id as i32) as i64
    var i: i64 = 0
    var out: Vec[i32] = Vec.new()
    let n = st.types.len()
    while i < n:
        if i == idx:
            out.push(ty as i32)
        else:
            out.push(st.types.get(i))
        i = i + 1
    st.types = out

fn CiExprPool.get_extra(self: CiExprPool, idx: i32) -> i32:
    self.state.extra.get(idx as i64)

fn CiExprPool.get_string(self: CiExprPool, idx: i32) -> str:
    self.state.strings.get(idx as i64)

fn CiExprPool.extra_len(self: CiExprPool) -> i32:
    self.state.extra.len() as i32

fn CiExprPool.int_lit(self: CiExprPool, text_idx: i32, ty: CiTypeId) -> CiExprId:
    self.add(CiExprKind.CIE_INT_LIT, text_idx, 0, 0, ty)

fn CiExprPool.bool_lit(self: CiExprPool, value: i32, ty: CiTypeId) -> CiExprId:
    self.add(CiExprKind.CIE_BOOL_LIT, value, 0, 0, ty)

fn CiExprPool.null_ptr(self: CiExprPool, ty: CiTypeId) -> CiExprId:
    self.add(CiExprKind.CIE_NULL_PTR, 0, 0, 0, ty)

fn CiExprPool.ident(self: CiExprPool, name_sym: i32, ty: CiTypeId) -> CiExprId:
    self.add(CiExprKind.CIE_IDENT, name_sym, 0, 0, ty)

fn CiExprPool.binary(self: CiExprPool, op: i32, lhs: CiExprId, rhs: CiExprId, ty: CiTypeId) -> CiExprId:
    self.add(CiExprKind.CIE_BINARY, op, lhs as i32, rhs as i32, ty)

fn CiExprPool.unary(self: CiExprPool, op: i32, operand: CiExprId, ty: CiTypeId) -> CiExprId:
    self.add(CiExprKind.CIE_UNARY, op, operand as i32, 0, ty)

fn CiExprPool.cast(self: CiExprPool, target: CiTypeId, operand: CiExprId) -> CiExprId:
    self.add(CiExprKind.CIE_CAST, target as i32, operand as i32, 0, target)

fn CiExprPool.init_list(self: CiExprPool, items_start: i32, item_count: i32, ty: CiTypeId) -> CiExprId:
    self.add(CiExprKind.CIE_INIT_LIST, items_start, item_count, 0, ty)

fn CiExprPool.designated_init(self: CiExprPool, fields_start: i32, field_count: i32, ty: CiTypeId) -> CiExprId:
    self.add(CiExprKind.CIE_DESIGNATED_INIT, fields_start, field_count, 0, ty)

fn CiExprPool.val(self: CiExprPool) -> CiExprPool:
    CiExprPool { state: self.state }


// ── CiStmt ────────────────────────────────────────────────────

type CiStmtId = distinct i32

enum CiStmtKind: i32:
    CIS_EXPR = 1             // d0 = expr_id
    CIS_RETURN = 2           // d0 = expr_id (0 = bare return)
    CIS_BLOCK = 3            // d0 = stmts_extra_start, d1 = stmts_count, d2 = label_sym (0 if none)
    CIS_IF = 4               // d0 = cond_expr, d1 = then_block, d2 = else_block (0 if none)
    CIS_WHILE = 5            // d0 = cond_expr, d1 = body_block, d2 = label_sym (0 if none)
    CIS_DO_WHILE = 6         // d0 = body_block, d1 = cond_expr
    CIS_FOR = 7              // d0 = extra_start holding [init_stmt, cond_expr, inc_expr], d1 = body_block
    CIS_MATCH = 8            // d0 = subject_expr, d1 = arms_extra_start, d2 = arm_count
    CIS_BREAK = 9            // d0 = label_sym (0 if none)
    CIS_CONTINUE = 10        // d0 = label_sym (0 if none)
    CIS_VAR_DECL = 11        // d0 = name_sym, d1 = type_id, d2 = init_expr (0 if none); flags in extra
    CIS_ASSIGN = 12          // d0 = lhs_expr, d1 = rhs_expr
    CIS_LABEL = 13           // d0 = label_sym
    CIS_GOTO = 14            // d0 = label_sym

// A match arm is stored in the stmt pool's `extra` as:
//   [value_count, value0_expr, value1_expr, ..., body_block_stmt_id]
// For _ / default arms, value_count == 0.

type CiStmtPool {
    kinds: Vec[i32],
    data0: Vec[i32],
    data1: Vec[i32],
    data2: Vec[i32],
    extra: Vec[i32],
    strings: Vec[str],
    // Per-stmt flags (bit0 = var_decl is_mut, bit1 = var_decl has_init).
    flags: Vec[i32],
    frozen: i32,
}

fn CiStmtPool.new -> CiStmtPool:
    var pool = CiStmtPool {
        kinds: Vec.new(),
        data0: Vec.new(),
        data1: Vec.new(),
        data2: Vec.new(),
        extra: Vec.new(),
        strings: Vec.new(),
        flags: Vec.new(),
        frozen: 0,
    }
    pool.kinds.push(0)
    pool.data0.push(0)
    pool.data1.push(0)
    pool.data2.push(0)
    pool.flags.push(0)
    pool.strings.push("")
    pool

fn CiStmtPool.add(mut self: CiStmtPool, kind: i32, d0: i32, d1: i32, d2: i32, flags: i32) -> CiStmtId:
    if self.frozen != 0:
        with_eprint("BUG: CiStmtPool.add called after freeze")
    let id = self.kinds.len() as i32
    self.kinds.push(kind)
    self.data0.push(d0)
    self.data1.push(d1)
    self.data2.push(d2)
    self.flags.push(flags)
    id as CiStmtId

fn CiStmtPool.add_extra(mut self: CiStmtPool, value: i32) -> i32:
    if self.frozen != 0:
        with_eprint("BUG: CiStmtPool.add_extra called after freeze")
    let idx = self.extra.len() as i32
    self.extra.push(value)
    idx

fn CiStmtPool.add_string(mut self: CiStmtPool, s: str) -> i32:
    if self.frozen != 0:
        with_eprint("BUG: CiStmtPool.add_string called after freeze")
    let idx = self.strings.len() as i32
    self.strings.push(s)
    idx

fn CiStmtPool.freeze(mut self: CiStmtPool):
    self.frozen = 1

fn CiStmtPool.kind(self: &CiStmtPool, id: CiStmtId) -> i32:
    self.kinds.get((id as i32) as i64)

fn CiStmtPool.get_d0(self: &CiStmtPool, id: CiStmtId) -> i32:
    self.data0.get((id as i32) as i64)

fn CiStmtPool.get_d1(self: &CiStmtPool, id: CiStmtId) -> i32:
    self.data1.get((id as i32) as i64)

fn CiStmtPool.get_d2(self: &CiStmtPool, id: CiStmtId) -> i32:
    self.data2.get((id as i32) as i64)

fn CiStmtPool.get_flags(self: &CiStmtPool, id: CiStmtId) -> i32:
    self.flags.get((id as i32) as i64)

fn CiStmtPool.get_extra(self: &CiStmtPool, idx: i32) -> i32:
    self.extra.get(idx as i64)

fn CiStmtPool.get_string(self: &CiStmtPool, idx: i32) -> str:
    self.strings.get(idx as i64)

// Statement constructor helpers.
fn CiStmtPool.expr_stmt(mut self: CiStmtPool, expr: CiExprId) -> CiStmtId:
    self.add(CiStmtKind.CIS_EXPR, expr as i32, 0, 0, 0)

fn CiStmtPool.return_(mut self: CiStmtPool, expr: CiExprId) -> CiStmtId:
    self.add(CiStmtKind.CIS_RETURN, expr as i32, 0, 0, 0)

fn CiStmtPool.break_(mut self: CiStmtPool) -> CiStmtId:
    self.add(CiStmtKind.CIS_BREAK, 0, 0, 0, 0)

fn CiStmtPool.continue_(mut self: CiStmtPool) -> CiStmtId:
    self.add(CiStmtKind.CIS_CONTINUE, 0, 0, 0, 0)

fn CiStmtPool.break_label(mut self: CiStmtPool, label_sym: i32) -> CiStmtId:
    self.add(CiStmtKind.CIS_BREAK, label_sym, 0, 0, 0)

fn CiStmtPool.continue_label(mut self: CiStmtPool, label_sym: i32) -> CiStmtId:
    self.add(CiStmtKind.CIS_CONTINUE, label_sym, 0, 0, 0)

fn CiStmtPool.assign(mut self: CiStmtPool, lhs: CiExprId, rhs: CiExprId) -> CiStmtId:
    self.add(CiStmtKind.CIS_ASSIGN, lhs as i32, rhs as i32, 0, 0)

// Block: caller has already pushed `count` stmt ids into pool.extra and
// knows the start index.
fn CiStmtPool.block(mut self: CiStmtPool, stmts_start: i32, stmts_count: i32) -> CiStmtId:
    self.add(CiStmtKind.CIS_BLOCK, stmts_start, stmts_count, 0, 0)

fn CiStmtPool.block_labeled(mut self: CiStmtPool, stmts_start: i32, stmts_count: i32, label_sym: i32) -> CiStmtId:
    self.add(CiStmtKind.CIS_BLOCK, stmts_start, stmts_count, label_sym, 0)

fn CiStmtPool.if_stmt(mut self: CiStmtPool, cond: CiExprId, then_block: CiStmtId, else_block: CiStmtId) -> CiStmtId:
    self.add(CiStmtKind.CIS_IF, cond as i32, then_block as i32, else_block as i32, 0)

fn CiStmtPool.while_stmt(mut self: CiStmtPool, cond: CiExprId, body: CiStmtId) -> CiStmtId:
    self.add(CiStmtKind.CIS_WHILE, cond as i32, body as i32, 0, 0)

fn CiStmtPool.while_labeled(mut self: CiStmtPool, cond: CiExprId, body: CiStmtId, label_sym: i32) -> CiStmtId:
    self.add(CiStmtKind.CIS_WHILE, cond as i32, body as i32, label_sym, 0)

// Variable decl. flags bit0 = is_mut, bit1 = has_init.
fn CiStmtPool.var_decl(mut self: CiStmtPool, name_sym: i32, ty: CiTypeId, init: CiExprId, is_mut: i32) -> CiStmtId:
    var f: i32 = 0
    if is_mut != 0:
        f = f + 1
    if (init as i32) != 0:
        f = f + 2
    self.add(CiStmtKind.CIS_VAR_DECL, name_sym, ty as i32, init as i32, f)

fn CiStmtPool.label(mut self: CiStmtPool, label_sym: i32) -> CiStmtId:
    self.add(CiStmtKind.CIS_LABEL, label_sym, 0, 0, 0)

fn CiStmtPool.goto_label(mut self: CiStmtPool, label_sym: i32) -> CiStmtId:
    self.add(CiStmtKind.CIS_GOTO, label_sym, 0, 0, 0)

// ── CiDecl ────────────────────────────────────────────────────

type CiDeclId = distinct i32

enum CiDeclKind: i32:
    // d0 = name_sym, d1 = ret_ty_id, d2 = body_block_stmt (0 for extern)
    // extra: [param_count, param0_name, param0_ty, param1_name, param1_ty, ...]
    // flags: bit0=is_extern bit1=is_static bit2=is_variadic bit3=is_c_export
    CID_FN_DECL = 1

    // d0 = name_sym, d1 = ty_id, d2 = init_expr (0 if none)
    // flags: bit0=is_const bit1=is_extern bit2=is_definition bit3=is_static
    CID_VAR_GLOBAL = 2

    // d0 = name_sym, d1 = target_ty_id
    CID_TYPEDEF = 3

    // d0 = name_sym, d1 = fields_extra_start, d2 = field_count
    // extra: [field0_name, field0_ty, field1_name, field1_ty, ...]
    CID_STRUCT_DEF = 4

    // d0 = name_sym, d1 = variants_extra_start, d2 = variant_count
    // extra: [variant0_name, variant0_value_lo, variant0_value_hi, ...]
    CID_ENUM_DEF = 5

    // d0 = name_sym, d1 = ret_ty_id, d2 = 0
    // extra: [param_count, param0_name, param0_ty, ...]
    CID_EXTERN_FN = 6

// Decl flag bits.
const CID_FLAG_EXTERN: i32 = 1
const CID_FLAG_STATIC: i32 = 2
const CID_FLAG_VARIADIC: i32 = 4
const CID_FLAG_C_EXPORT: i32 = 8
const CID_FLAG_CONST: i32 = 1          // (same bit as EXTERN, but on CID_VAR_GLOBAL)
const CID_FLAG_VAR_EXTERN: i32 = 2     // (on CID_VAR_GLOBAL)
const CID_FLAG_DEFINITION: i32 = 4
const CID_FLAG_VAR_STATIC: i32 = 8

type CiDeclPool {
    kinds: Vec[i32],
    data0: Vec[i32],
    data1: Vec[i32],
    data2: Vec[i32],
    extra: Vec[i32],
    strings: Vec[str],
    flags: Vec[i32],
    // Owner module id (-1 = unknown / single-file mode). Populated by
    // Pass 3 (project symbol resolution) in Phase C.
    owner_module: Vec[i32],
    frozen: i32,
}

fn CiDeclPool.new -> CiDeclPool:
    var pool = CiDeclPool {
        kinds: Vec.new(),
        data0: Vec.new(),
        data1: Vec.new(),
        data2: Vec.new(),
        extra: Vec.new(),
        strings: Vec.new(),
        flags: Vec.new(),
        owner_module: Vec.new(),
        frozen: 0,
    }
    pool.kinds.push(0)
    pool.data0.push(0)
    pool.data1.push(0)
    pool.data2.push(0)
    pool.flags.push(0)
    pool.owner_module.push(0 - 1)
    pool

fn CiDeclPool.add(mut self: CiDeclPool, kind: i32, d0: i32, d1: i32, d2: i32, flags: i32) -> CiDeclId:
    if self.frozen != 0:
        with_eprint("BUG: CiDeclPool.add called after freeze")
    let id = self.kinds.len() as i32
    self.kinds.push(kind)
    self.data0.push(d0)
    self.data1.push(d1)
    self.data2.push(d2)
    self.flags.push(flags)
    self.owner_module.push(0 - 1)
    id as CiDeclId

fn CiDeclPool.add_extra(mut self: CiDeclPool, value: i32) -> i32:
    if self.frozen != 0:
        with_eprint("BUG: CiDeclPool.add_extra called after freeze")
    let idx = self.extra.len() as i32
    self.extra.push(value)
    idx

fn CiDeclPool.add_string(mut self: CiDeclPool, s: str) -> i32:
    if self.frozen != 0:
        with_eprint("BUG: CiDeclPool.add_string called after freeze")
    let idx = self.strings.len() as i32
    self.strings.push(s)
    idx

fn CiDeclPool.freeze(mut self: CiDeclPool):
    self.frozen = 1

fn CiDeclPool.kind(self: &CiDeclPool, id: CiDeclId) -> i32:
    self.kinds.get((id as i32) as i64)

fn CiDeclPool.get_d0(self: &CiDeclPool, id: CiDeclId) -> i32:
    self.data0.get((id as i32) as i64)

fn CiDeclPool.get_d1(self: &CiDeclPool, id: CiDeclId) -> i32:
    self.data1.get((id as i32) as i64)

fn CiDeclPool.get_d2(self: &CiDeclPool, id: CiDeclId) -> i32:
    self.data2.get((id as i32) as i64)

fn CiDeclPool.get_flags(self: &CiDeclPool, id: CiDeclId) -> i32:
    self.flags.get((id as i32) as i64)

fn CiDeclPool.get_extra(self: &CiDeclPool, idx: i32) -> i32:
    self.extra.get(idx as i64)

fn CiDeclPool.get_string(self: &CiDeclPool, idx: i32) -> str:
    self.strings.get(idx as i64)

// Decl constructor helpers.
fn CiDeclPool.fn_decl(mut self: CiDeclPool, name_sym: i32, ret_ty: CiTypeId, body: CiStmtId, flags: i32) -> CiDeclId:
    self.add(CiDeclKind.CID_FN_DECL, name_sym, ret_ty as i32, body as i32, flags)

fn CiDeclPool.var_global(mut self: CiDeclPool, name_sym: i32, ty: CiTypeId, init: CiExprId, flags: i32) -> CiDeclId:
    self.add(CiDeclKind.CID_VAR_GLOBAL, name_sym, ty as i32, init as i32, flags)

fn CiDeclPool.typedef(mut self: CiDeclPool, name_sym: i32, target: CiTypeId) -> CiDeclId:
    self.add(CiDeclKind.CID_TYPEDEF, name_sym, target as i32, 0, 0)

fn CiDeclPool.struct_def(mut self: CiDeclPool, name_sym: i32, fields_start: i32, field_count: i32) -> CiDeclId:
    self.add(CiDeclKind.CID_STRUCT_DEF, name_sym, fields_start, field_count, 0)

fn CiDeclPool.enum_def(mut self: CiDeclPool, name_sym: i32, variants_start: i32, variant_count: i32) -> CiDeclId:
    self.add(CiDeclKind.CID_ENUM_DEF, name_sym, variants_start, variant_count, 0)

fn CiDeclPool.extern_fn(mut self: CiDeclPool, name_sym: i32, ret_ty: CiTypeId, flags: i32) -> CiDeclId:
    self.add(CiDeclKind.CID_EXTERN_FN, name_sym, ret_ty as i32, 0, flags)


// ── CiModule ──────────────────────────────────────────────────
//
// A CiModule is the per-source-file container. It holds the four pools
// plus the ordered list of top-level decl ids. Phase B operates one
// module at a time; Phase C threads CiModules through the project-level
// passes (CiProject) that replace the directory-mode shell scripts.

type CiModule {
    name: str,
    source_path: str,
    types: CiTypePool,
    exprs: CiExprPool,
    stmts: CiStmtPool,
    decls: CiDeclPool,
    top_level_decls: Vec[i32],
    imports: Vec[str],
}

fn CiModule.new(name: str, source_path: str) -> CiModule:
    CiModule {
        name: name,
        source_path: source_path,
        types: CiTypePool.new(),
        exprs: CiExprPool.new(),
        stmts: CiStmtPool.new(),
        decls: CiDeclPool.new(),
        top_level_decls: Vec.new(),
        imports: Vec.new(),
    }

fn CiModule.add_decl(mut self: CiModule, decl: CiDeclId):
    self.top_level_decls.push(decl as i32)

fn CiModule.add_import(mut self: CiModule, path: str):
    self.imports.push(path)


// ── CiProject ────────────────────────────────────────────────
//
// Phase C threads all directory-mode modules through a project symbol
// table so ownership and cross-module type resolution come from the
// compiler rather than shell-side string rewriting.

enum CiProjectSymbolKind: i32:
    CIPS_VAR = 1
    CIPS_FN = 2
    CIPS_TYPE = 3
    CIPS_MACRO = 4

type CiProjectSymbol {
    name: str,
    kind: i32,
    owner_module: i32,
    resolved_ty: CiTypeId,
    resolved_ty_text: str,
    consumers: str,
    owner_rank: i32,
    owner_definition_kind: i32,
}

fn CiProjectSymbol.new(name: str, kind: i32) -> CiProjectSymbol:
    CiProjectSymbol {
        name: ci_ir_owned_text(name),
        kind: kind,
        owner_module: 0 - 1,
        resolved_ty: 0 as CiTypeId,
        resolved_ty_text: "",
        consumers: "",
        owner_rank: 0 - 1,
        owner_definition_kind: 0,
    }

fn ci_pipe_i32_contains(items: str, want: i32) -> bool:
    let needle = "|" ++ i64_to_string(want as i64) ++ "|"
    var i = 0
    let ilen = items.len() as i32
    let nlen = needle.len() as i32
    while i <= ilen - nlen:
        if items.slice(i as i64, (i + nlen) as i64) == needle:
            return true
        i = i + 1
    false

fn CiProjectSymbol.add_consumer(mut self: CiProjectSymbol, module_id: i32):
    if module_id < 0:
        return
    if ci_pipe_i32_contains(self.consumers, module_id):
        return
    self.consumers = self.consumers ++ "|" ++ i64_to_string(module_id as i64) ++ "|"

fn CiProjectSymbol.owned_copy(self: CiProjectSymbol) -> CiProjectSymbol:
    CiProjectSymbol {
        name: ci_ir_owned_text(self.name),
        kind: self.kind,
        owner_module: self.owner_module,
        resolved_ty: self.resolved_ty,
        resolved_ty_text: ci_ir_owned_text(self.resolved_ty_text),
        consumers: ci_ir_owned_text(self.consumers),
        owner_rank: self.owner_rank,
        owner_definition_kind: self.owner_definition_kind,
    }

fn ci_project_symbol_key(kind: i32, name: str) -> str:
    if kind == CiProjectSymbolKind.CIPS_VAR:
        return "v:" ++ name
    if kind == CiProjectSymbolKind.CIPS_FN:
        return "f:" ++ name
    if kind == CiProjectSymbolKind.CIPS_TYPE:
        return "t:" ++ name
    "m:" ++ name

type CiProject {
    module_paths: Vec[str],
    symbols: Vec[CiProjectSymbol],
    types: CiTypePool,
}

fn CiProject.new -> CiProject:
    CiProject {
        module_paths: Vec.new(),
        symbols: Vec.new(),
        types: CiTypePool.new(),
    }

fn CiProject.ensure_module(mut self: CiProject, path: str) -> i32:
    var i = 0
    while i < self.module_paths.len() as i32:
        if self.module_paths.get(i as i64) == path:
            return i
        i = i + 1
    let id = self.module_paths.len() as i32
    self.module_paths.push(ci_ir_owned_text(path))
    id

fn CiProject.find_symbol(self: &CiProject, kind: i32, name: str) -> i32:
    let key = ci_project_symbol_key(kind, name)
    var i = self.symbols.len() as i32 - 1
    while i >= 0:
        let symbol = self.symbols.get(i as i64)
        if ci_project_symbol_key(symbol.kind, symbol.name) == key:
            return i
        i = i - 1
    0 - 1

fn CiProject.ensure_symbol(mut self: CiProject, kind: i32, name: str) -> i32:
    let existing = self.find_symbol(kind, name)
    if existing >= 0:
        return existing
    let id = self.symbols.len() as i32
    self.symbols.push(CiProjectSymbol.new(name, kind))
    id

fn CiProject.update_symbol(mut self: CiProject, symbol_id: i32, symbol: CiProjectSymbol):
    if symbol_id < 0 or symbol_id >= self.symbols.len() as i32:
        return
    var updated: Vec[CiProjectSymbol] = Vec.new()
    var i = 0
    while i < self.symbols.len() as i32:
        if i == symbol_id:
            updated.push(symbol.owned_copy())
        else:
            updated.push(self.symbols.get(i as i64).owned_copy())
        i = i + 1
    self.symbols = updated

fn CiProject.owner_module_path(self: &CiProject, symbol_id: i32) -> str:
    if symbol_id < 0 or symbol_id >= self.symbols.len() as i32:
        return ""
    let owner_module = self.symbols.get(symbol_id as i64).owner_module
    if owner_module < 0 or owner_module >= self.module_paths.len() as i32:
        return ""
    self.module_paths.get(owner_module as i64)

let _ci_ir_eof_guard = 0
