use std.collections.HashMap
// CiIR — IR for the C-to-With migrator (`with migrate`).
//
// Pipeline:
//
//     libclang AST  →  CiExpr / CiStmt / CiDecl  →  CiPrint  →  With source
//
// This module replaces the string-based `ci_trans_expr` / `ci_trans_stmt`
// lowering in CImport.w. Structural correctness (if/else: nesting,
// array-to-pointer decay, operator precedence, temp uniqueness,
// sequenced side effects) moves out of string concatenation and into
// tree construction.
//
// Storage follows the SoA idiom used throughout the compiler (see
// src/Ast.w): parallel List[i32] arrays keyed by a stable id handle.
// Node 0 is the null sentinel in every pool. Variable-length payloads
// (init list items, call args, fn param lists) live in a single flat
// `extra: List[i32]` per pool, referenced by (start, count).
//
// Every CiExpr carries its resolved CiType (an index into the shared
// CiTypePool). The printer must not re-query libclang at print time —
// sessions may be disposed by then.
//
// The migrator now lowers expressions and statements structurally.
// Unsupported constructs fail by returning the null sentinel from
// lowering, rather than escaping through verbatim raw-string nodes.

extern fn with_eprint(s: &str) -> Unit
extern fn with_vec_free_es(v: *mut u8, es: i64)
extern fn with_str_clone_ref(s: &str) -> str
extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut u8) -> Unit
extern fn abort() -> Never

fn ci_ir_phase_bug(message: &str):
    with_eprint(message)
    abort()

fn ci_ir_owned_text(text: &str) -> str:
    if text.len() == 0:
        return ""
    with_str_clone_ref(text)

// D119: a fixed array's type text is `[T; N]`, nested `[[T; 4]; 8]`; the
// `[N]T` form it had before is still read, and `[]T` is a slice. The one
// parser of that text: the index of the top-level `;` (-1 for the old form
// and a slice) and of the `]` that closes the count, or -1 when `ty` is not
// an array.
fn ci_array_text_split(ty: &str) -> (i64, i64):
    if ty.len() < 3 or ty[0] != '[':
        return (-1, -1)
    var depth = 0
    var i: i64 = 1
    while i < ty.len():
        let c = ty[i]
        if c == '[' or c == '(':
            depth += 1
        else if c == ']' or c == ')':
            if depth == 0:
                return (-1, i)
            depth -= 1
        else if c == ';' and depth == 0:
            var close = ty.len() - 1
            while close > i and ty[close] != ']': close -= 1
            return (i, close)
        i += 1
    (-1, -1)

/// The dimensions text of `[T; 2, 3]` ("2, 3"); the count of the old `[N]T`;
/// "" for a slice or a non-array.
fn ci_array_text_dims(ty: &str) -> str:
    let (semi, close) = ci_array_text_split(ty)
    if semi > 0: ty.slice(semi + 1, close).trim()
    else if close > 0: ty.slice(1, close).trim()
    else: ""

// The index of the first top-level `,` in a dimensions text, -1 for one.
fn ci_array_dims_comma(dims: &str) -> i64:
    var depth = 0
    for i in 0..dims.len():
        let c = dims[i]
        if c == '(' or c == '[': depth += 1
        else if c == ')' or c == ']': depth -= 1
        else if c == ',' and depth == 0: return i
    -1

/// The element type text of an array type text, "" when it is not one: the
/// row `[T; 3]` of `[T; 2, 3]` (D119), `T` of `[T; 3]` and of `[3]T`.
fn ci_array_text_elem(ty: &str) -> str:
    let (semi, close) = ci_array_text_split(ty)
    if semi <= 0:
        return if close > 0: ty.slice(close + 1, ty.len()).trim() else: ""
    let base: str = ty.slice(1, semi).trim()
    let dims: str = ty.slice(semi + 1, close).trim()
    let comma = ci_array_dims_comma(dims)
    if comma < 0: base else: "[" ++ base ++ "; " ++ dims.slice(comma + 1, dims.len()).trim() ++ "]"

/// The outer count text of an array type text, "" for a slice or a
/// non-array: 2 for `[T; 2, 3]`.
fn ci_array_text_count(ty: &str) -> str:
    let dims = ci_array_text_dims(ty)
    let comma = ci_array_dims_comma(dims)
    if comma < 0: dims else: dims.slice(0, comma).trim()

/// `[elem; count]`, `[]elem` for a slice (no count); an array element joins
/// the dimensions in index order (D119): `[c_int; 3]` counted 2 is
/// `[c_int; 2, 3]`.
fn ci_array_text(elem: &str, count: &str) -> str:
    if count.len() == 0:
        return "[]" ++ elem
    let (semi, close) = ci_array_text_split(elem)
    if semi > 0: "[" ++ elem.slice(1, semi).trim() ++ "; " ++ count ++ ", " ++ elem.slice(semi + 1, close).trim() ++ "]"
    else: "[" ++ elem ++ "; " ++ count ++ "]"

/// D119 (with-migrate-spec.md "Arrays"): the `List` a C local or file-scope
/// array declares: `[T; N]` is `List[T]`, `[T; M, N]` is `List[[T; N]]` (its
/// rows stay inline values); "" for a slice or a non-array.
fn ci_array_list_text(ty: &str) -> str:
    let elem = ci_array_text_elem(ty)
    if elem.len() == 0 or ci_array_text_count(ty).len() == 0: return ""
    "List[" ++ elem ++ "]"

fn ci_ir_free_list_i32(v: &List[i32]): with_vec_free_es(v as *const List[i32] as *mut u8, sizeof[i32]())

fn ci_ir_free_list_str(v: &List[str]): with_vec_free_es(v as *const List[str] as *mut u8, sizeof[str]())

// ── CiType ────────────────────────────────────────────────────

type CiTypeId = distinct i32
impl Copy for CiTypeId

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

pub const CI_SIZE_INCOMPLETE: i32 = -1

type CiTypePoolState {
    kinds: List[i32],
    data0: List[i32],
    data1: List[i32],
    data2: List[i32],
    extra: List[i32],
    strings: List[str],
    frozen: i32,
}

type CiTypePool {
    state: *mut CiTypePoolState,
}
impl Copy for CiTypePool

fn CiTypePool.new -> CiTypePool:
    let ptr = with_alloc(sizeof[CiTypePoolState]()) as *mut CiTypePoolState
    unsafe *ptr = CiTypePoolState {
        kinds: List.new(),
        data0: List.new(),
        data1: List.new(),
        data2: List.new(),
        extra: List.new(),
        strings: List.new(),
        frozen: 0,
    }
    ptr.kinds.push(0)
    ptr.data0.push(0)
    ptr.data1.push(0)
    ptr.data2.push(0)
    CiTypePool { state: ptr }

impl CiTypePool:
    fn deinit():
        if self.state as i64 == 0:
            return
        let st = self.state
        ci_ir_free_list_i32(st.kinds)
        ci_ir_free_list_i32(st.data0)
        ci_ir_free_list_i32(st.data1)
        ci_ir_free_list_i32(st.data2)
        ci_ir_free_list_i32(st.extra)
        ci_ir_free_list_str(st.strings)
        with_free(st as *mut u8)

    fn add(kind: i32, d0: i32, d1: i32, d2: i32) -> CiTypeId:
        let st = self.state
        if st.frozen != 0:
            ci_ir_phase_bug("BUG: CiTypePool.add called after freeze")
        let id = st.kinds.len()
        st.kinds.push(kind)
        st.data0.push(d0)
        st.data1.push(d1)
        st.data2.push(d2)
        id as CiTypeId

    fn add_extra(value: i32) -> i32:
        let st = self.state
        if st.frozen != 0:
            ci_ir_phase_bug("BUG: CiTypePool.add_extra called after freeze")
        let idx = st.extra.len() as i32
        st.extra.push(value)
        idx

    fn add_string(s: &str) -> i32:
        let st = self.state
        if st.frozen != 0:
            ci_ir_phase_bug("BUG: CiTypePool.add_string called after freeze")
        let idx = st.strings.len() as i32
        st.strings.push(ci_ir_owned_text(s))
        idx

    mut fn freeze():
        self.state.frozen = 1

    fn kind(id: CiTypeId) -> i32:
        self.state.kinds[(id as i32)]

    fn get_d0(id: CiTypeId) -> i32:
        self.state.data0[(id as i32)]

    fn get_d1(id: CiTypeId) -> i32:
        self.state.data1[(id as i32)]

    fn get_d2(id: CiTypeId) -> i32:
        self.state.data2[(id as i32)]

    fn get_extra(idx: isize) -> i32:
        self.state.extra[idx]

    fn get_string(idx: i32) -> &str:
        self.state.strings[idx]

    // Type constructor helpers.
    fn ty_void() -> CiTypeId:
        self.add(CiTypeKind.CT_VOID, 0, 0, 0)

    fn ty_bool() -> CiTypeId:
        self.add(CiTypeKind.CT_BOOL, 0, 0, 0)

    fn ty_int(bits: i32, is_unsigned: i32) -> CiTypeId:
        self.add(CiTypeKind.CT_INT, bits, is_unsigned, 0)

    fn ty_float(bits: i32) -> CiTypeId:
        self.add(CiTypeKind.CT_FLOAT, bits, 0, 0)

    fn ty_pointer(pointee: CiTypeId, is_const: i32) -> CiTypeId:
        self.add(CiTypeKind.CT_POINTER, pointee as i32, is_const, 0)

    fn ty_array(elem: CiTypeId, size: i32) -> CiTypeId:
        self.add(CiTypeKind.CT_ARRAY, elem as i32, size, 0)

    fn ty_struct(name_sym: i32) -> CiTypeId:
        self.add(CiTypeKind.CT_STRUCT, name_sym, 0, 0)

    fn ty_enum(name_sym: i32) -> CiTypeId:
        self.add(CiTypeKind.CT_ENUM, name_sym, 0, 0)

    fn ty_named(name_sym: i32) -> CiTypeId:
        self.add(CiTypeKind.CT_NAMED, name_sym, 0, 0)

    fn ty_fn_ptr(ret: CiTypeId, params_start: i32, param_count: i32) -> CiTypeId:
        self.add(CiTypeKind.CT_FN_PTR, ret as i32, params_start, param_count)


// ── CiExpr ────────────────────────────────────────────────────

type CiExprId = distinct i32
impl Copy for CiExprId

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
    CIE_FILL = 72              // d0 = string_idx of the fill literal (`[0; 256]`, D119)

    // Safety boundary
    CIE_UNSAFE = 80            // d0 = inner expr


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
    kinds: List[i32],
    data0: List[i32],
    data1: List[i32],
    data2: List[i32],
    types: List[i32],
    extra: List[i32],
    strings: List[str],
    frozen: i32,
}

type CiExprPool {
    state: *mut CiExprPoolState,
}
impl Copy for CiExprPool

fn CiExprPool.new -> CiExprPool:
    let ptr = with_alloc(sizeof[CiExprPoolState]()) as *mut CiExprPoolState
    unsafe *ptr = CiExprPoolState {
        kinds: List.new(),
        data0: List.new(),
        data1: List.new(),
        data2: List.new(),
        types: List.new(),
        extra: List.new(),
        strings: List.new(),
        frozen: 0,
    }
    ptr.kinds.push(0)
    ptr.data0.push(0)
    ptr.data1.push(0)
    ptr.data2.push(0)
    ptr.types.push(0)
    CiExprPool { state: ptr }

impl CiExprPool:
    fn deinit():
        if self.state as i64 == 0:
            return
        let st = self.state
        ci_ir_free_list_i32(st.kinds)
        ci_ir_free_list_i32(st.data0)
        ci_ir_free_list_i32(st.data1)
        ci_ir_free_list_i32(st.data2)
        ci_ir_free_list_i32(st.types)
        ci_ir_free_list_i32(st.extra)
        ci_ir_free_list_str(st.strings)
        with_free(st as *mut u8)

    fn add(kind: i32, d0: i32, d1: i32, d2: i32, ty: CiTypeId) -> CiExprId:
        let st = self.state
        if st.frozen != 0:
            ci_ir_phase_bug("BUG: CiExprPool.add called after freeze")
        let id = st.kinds.len()
        st.kinds.push(kind)
        st.data0.push(d0)
        st.data1.push(d1)
        st.data2.push(d2)
        st.types.push(ty as i32)
        id as CiExprId

    fn add_extra(value: i32) -> i32:
        let st = self.state
        if st.frozen != 0:
            ci_ir_phase_bug("BUG: CiExprPool.add_extra called after freeze")
        let idx = st.extra.len() as i32
        st.extra.push(value)
        idx

    fn add_string(s: &str) -> i32:
        let st = self.state
        if st.frozen != 0:
            ci_ir_phase_bug("BUG: CiExprPool.add_string called after freeze")
        let idx = st.strings.len() as i32
        st.strings.push(ci_ir_owned_text(s))
        idx

    mut fn freeze():
        self.state.frozen = 1

    fn kind(id: CiExprId) -> i32:
        self.state.kinds[(id as i32)]

    fn get_d0(id: CiExprId) -> i32:
        self.state.data0[(id as i32)]

    fn get_d1(id: CiExprId) -> i32:
        self.state.data1[(id as i32)]

    fn get_d2(id: CiExprId) -> i32:
        self.state.data2[(id as i32)]

    fn get_type(id: CiExprId) -> CiTypeId:
        (self.state.types[(id as i32) as i64]) as CiTypeId

    fn set_type(id: CiExprId, ty: CiTypeId):
        let st = self.state
        if st.frozen != 0:
            ci_ir_phase_bug("BUG: CiExprPool.set_type called after freeze")
        let idx = (id as i32) as i64
        var i: i64 = 0
        var out: List[i32] = List.new()
        let n = st.types.len()
        while i < n:
            if i == idx:
                out.push(ty as i32)
            else:
                out.push(st.types[i])
            i = i + 1
        st.types = out

    fn get_extra(idx: isize) -> i32:
        self.state.extra[idx]

    fn get_string(idx: i32) -> &str:
        self.state.strings[idx]

    fn extra_len() -> i32:
        self.state.extra.len() as i32

    fn int_lit(text_idx: i32, ty: CiTypeId) -> CiExprId:
        self.add(CiExprKind.CIE_INT_LIT, text_idx, 0, 0, ty)

    fn bool_lit(value: i32, ty: CiTypeId) -> CiExprId:
        self.add(CiExprKind.CIE_BOOL_LIT, value, 0, 0, ty)

    fn null_ptr(ty: CiTypeId) -> CiExprId:
        self.add(CiExprKind.CIE_NULL_PTR, 0, 0, 0, ty)

    fn ident(name_sym: i32, ty: CiTypeId) -> CiExprId:
        self.add(CiExprKind.CIE_IDENT, name_sym, 0, 0, ty)

    fn binary(op: i32, lhs: CiExprId, rhs: CiExprId, ty: CiTypeId) -> CiExprId:
        self.add(CiExprKind.CIE_BINARY, op, lhs as i32, rhs as i32, ty)

    fn unary(op: i32, operand: CiExprId, ty: CiTypeId) -> CiExprId:
        self.add(CiExprKind.CIE_UNARY, op, operand as i32, 0, ty)

    fn cast(target: CiTypeId, operand: CiExprId) -> CiExprId:
        self.add(CiExprKind.CIE_CAST, target as i32, operand as i32, 0, target)

    fn init_list(items_start: i32, item_count: i32, ty: CiTypeId) -> CiExprId:
        self.add(CiExprKind.CIE_INIT_LIST, items_start, item_count, 0, ty)

    fn designated_init(fields_start: i32, field_count: i32, ty: CiTypeId) -> CiExprId:
        self.add(CiExprKind.CIE_DESIGNATED_INIT, fields_start, field_count, 0, ty)

    fn val() -> CiExprPool:
        CiExprPool { state: self.state }


// ── CiStmt ────────────────────────────────────────────────────

type CiStmtId = distinct i32
impl Copy for CiStmtId

// CIS_EXPR flag: the C expression's value is `void` (#1838).
pub const CI_STMT_EXPR_VOID: i32 = 1

enum CiStmtKind: i32:
    CIS_EXPR = 1             // d0 = expr_id; flags: CI_STMT_EXPR_VOID
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

type CiStmtPoolState {
    kinds: List[i32],
    data0: List[i32],
    data1: List[i32],
    data2: List[i32],
    extra: List[i32],
    strings: List[str],
    flags: List[i32],
    frozen: i32,
}

type CiStmtPool {
    state: *mut CiStmtPoolState,
}
impl Copy for CiStmtPool

fn CiStmtPool.new -> CiStmtPool:
    let ptr = with_alloc(sizeof[CiStmtPoolState]()) as *mut CiStmtPoolState
    unsafe:
        *ptr = CiStmtPoolState {
            kinds: List.new(),
            data0: List.new(),
            data1: List.new(),
            data2: List.new(),
            extra: List.new(),
            strings: List.new(),
            flags: List.new(),
            frozen: 0,
        }
    let st = ptr
    st.kinds.push(0)
    st.data0.push(0)
    st.data1.push(0)
    st.data2.push(0)
    st.flags.push(0)
    st.strings.push("")
    CiStmtPool { state: ptr }

impl CiStmtPool:
    fn deinit():
        if self.state as i64 == 0:
            return
        let st = self.state
        ci_ir_free_list_i32(st.kinds)
        ci_ir_free_list_i32(st.data0)
        ci_ir_free_list_i32(st.data1)
        ci_ir_free_list_i32(st.data2)
        ci_ir_free_list_i32(st.extra)
        ci_ir_free_list_str(st.strings)
        ci_ir_free_list_i32(st.flags)
        with_free(st as *mut u8)

    fn add(kind: i32, d0: i32, d1: i32, d2: i32, flags: i32) -> CiStmtId:
        let st = self.state
        if st.frozen != 0:
            ci_ir_phase_bug("BUG: CiStmtPool.add called after freeze")
        let id = st.kinds.len()
        st.kinds.push(kind)
        st.data0.push(d0)
        st.data1.push(d1)
        st.data2.push(d2)
        st.flags.push(flags)
        id as CiStmtId

    fn add_extra(value: i32) -> i32:
        let st = self.state
        if st.frozen != 0:
            ci_ir_phase_bug("BUG: CiStmtPool.add_extra called after freeze")
        let idx = st.extra.len() as i32
        st.extra.push(value)
        idx

    fn add_string(s: &str) -> i32:
        let st = self.state
        if st.frozen != 0:
            ci_ir_phase_bug("BUG: CiStmtPool.add_string called after freeze")
        let idx = st.strings.len() as i32
        st.strings.push(ci_ir_owned_text(s))
        idx

    mut fn freeze():
        self.state.frozen = 1

    fn extra_len() -> i32:
        self.state.extra.len() as i32

    fn val() -> CiStmtPool:
        CiStmtPool { state: self.state }

    fn kind(id: CiStmtId) -> i32:
        self.state.kinds[(id as i32)]

    fn get_d0(id: CiStmtId) -> i32:
        self.state.data0[(id as i32)]

    fn get_d1(id: CiStmtId) -> i32:
        self.state.data1[(id as i32)]

    fn get_d2(id: CiStmtId) -> i32:
        self.state.data2[(id as i32)]

    fn get_flags(id: CiStmtId) -> i32:
        self.state.flags[(id as i32)]

    fn get_extra(idx: isize) -> i32:
        self.state.extra[idx]

    fn get_string(idx: i32) -> &str:
        self.state.strings[idx]

    // Statement constructor helpers.
    fn expr_stmt(expr: CiExprId) -> CiStmtId:
        self.add(CiStmtKind.CIS_EXPR, expr as i32, 0, 0, 0)

    // An expression statement whose C expression is `void` (a call of a void
    // function): its rendering, as a body's tail, infers Unit (#1838).
    fn expr_stmt_void(expr: CiExprId) -> CiStmtId:
        self.add(CiStmtKind.CIS_EXPR, expr as i32, 0, 0, CI_STMT_EXPR_VOID)

    fn return_(expr: CiExprId) -> CiStmtId:
        self.add(CiStmtKind.CIS_RETURN, expr as i32, 0, 0, 0)

    fn break_() -> CiStmtId:
        self.add(CiStmtKind.CIS_BREAK, 0, 0, 0, 0)

    fn continue_() -> CiStmtId:
        self.add(CiStmtKind.CIS_CONTINUE, 0, 0, 0, 0)

    fn break_label(label_sym: i32) -> CiStmtId:
        self.add(CiStmtKind.CIS_BREAK, label_sym, 0, 0, 0)

    fn continue_label(label_sym: i32) -> CiStmtId:
        self.add(CiStmtKind.CIS_CONTINUE, label_sym, 0, 0, 0)

    fn assign(lhs: CiExprId, rhs: CiExprId) -> CiStmtId:
        self.add(CiStmtKind.CIS_ASSIGN, lhs as i32, rhs as i32, 0, 0)

    // Block: caller has already pushed `count` stmt ids into pool.extra and
    // knows the start index.
    fn block(stmts_start: i32, stmts_count: i32) -> CiStmtId:
        self.add(CiStmtKind.CIS_BLOCK, stmts_start, stmts_count, 0, 0)

    fn block_labeled(stmts_start: i32, stmts_count: i32, label_sym: i32) -> CiStmtId:
        self.add(CiStmtKind.CIS_BLOCK, stmts_start, stmts_count, label_sym, 0)

    fn if_stmt(cond: CiExprId, then_block: CiStmtId, else_block: CiStmtId) -> CiStmtId:
        self.add(CiStmtKind.CIS_IF, cond as i32, then_block as i32, else_block as i32, 0)

    fn while_stmt(cond: CiExprId, body: CiStmtId) -> CiStmtId:
        self.add(CiStmtKind.CIS_WHILE, cond as i32, body as i32, 0, 0)

    fn while_labeled(cond: CiExprId, body: CiStmtId, label_sym: i32) -> CiStmtId:
        self.add(CiStmtKind.CIS_WHILE, cond as i32, body as i32, label_sym, 0)

    fn do_while_stmt(body: CiStmtId, cond: CiExprId, cond_setup: CiStmtId) -> CiStmtId:
        self.add(CiStmtKind.CIS_DO_WHILE, body as i32, cond as i32, cond_setup as i32, 0)

    // Variable decl. flags bit0 = is_mut, bit1 = has_init.
    fn var_decl(name_sym: i32, ty: CiTypeId, init: CiExprId, is_mut: i32) -> CiStmtId:
        var f: i32 = 0
        if is_mut != 0:
            f = f + 1
        if (init as i32) != 0:
            f = f + 2
        self.add(CiStmtKind.CIS_VAR_DECL, name_sym, ty as i32, init as i32, f)

    fn label(label_sym: i32) -> CiStmtId:
        self.add(CiStmtKind.CIS_LABEL, label_sym, 0, 0, 0)

    fn goto_label(label_sym: i32) -> CiStmtId:
        self.add(CiStmtKind.CIS_GOTO, label_sym, 0, 0, 0)

// ── CiDecl ────────────────────────────────────────────────────

type CiDeclId = distinct i32
impl Copy for CiDeclId

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
pub const CID_FLAG_C_EXPORT: i32 = 8
const CID_FLAG_CONST: i32 = 1          // (same bit as EXTERN, but on CID_VAR_GLOBAL)
pub const CID_FLAG_VAR_EXTERN: i32 = 2     // (on CID_VAR_GLOBAL)
const CID_FLAG_DEFINITION: i32 = 4
const CID_FLAG_VAR_STATIC: i32 = 8

type CiDeclPoolState {
    kinds: List[i32],
    data0: List[i32],
    data1: List[i32],
    data2: List[i32],
    extra: List[i32],
    strings: List[str],
    flags: List[i32],
    owner_module: List[i32],
    frozen: i32,
}

type CiDeclPool {
    state: *mut CiDeclPoolState,
}
impl Copy for CiDeclPool

fn CiDeclPool.new -> CiDeclPool:
    let ptr = with_alloc(sizeof[CiDeclPoolState]()) as *mut CiDeclPoolState
    unsafe:
        *ptr = CiDeclPoolState {
            kinds: List.new(),
            data0: List.new(),
            data1: List.new(),
            data2: List.new(),
            extra: List.new(),
            strings: List.new(),
            flags: List.new(),
            owner_module: List.new(),
            frozen: 0,
        }
    let st = ptr
    st.kinds.push(0)
    st.data0.push(0)
    st.data1.push(0)
    st.data2.push(0)
    st.flags.push(0)
    st.owner_module.push(-1)
    CiDeclPool { state: ptr }

impl CiDeclPool:
    fn add(kind: i32, d0: i32, d1: i32, d2: i32, flags: i32) -> CiDeclId:
        let st = self.state
        if st.frozen != 0:
            ci_ir_phase_bug("BUG: CiDeclPool.add called after freeze")
        let id = st.kinds.len()
        st.kinds.push(kind)
        st.data0.push(d0)
        st.data1.push(d1)
        st.data2.push(d2)
        st.flags.push(flags)
        st.owner_module.push(-1)
        id as CiDeclId

    fn add_extra(value: i32) -> i32:
        let st = self.state
        if st.frozen != 0:
            ci_ir_phase_bug("BUG: CiDeclPool.add_extra called after freeze")
        let idx = st.extra.len() as i32
        st.extra.push(value)
        idx

    fn add_string(s: &str) -> i32:
        let st = self.state
        if st.frozen != 0:
            ci_ir_phase_bug("BUG: CiDeclPool.add_string called after freeze")
        let idx = st.strings.len() as i32
        st.strings.push(ci_ir_owned_text(s))
        idx

    mut fn freeze():
        self.state.frozen = 1

    fn kind(id: CiDeclId) -> i32:
        self.state.kinds[(id as i32)]

    fn get_d0(id: CiDeclId) -> i32:
        self.state.data0[(id as i32)]

    fn get_d1(id: CiDeclId) -> i32:
        self.state.data1[(id as i32)]

    fn get_d2(id: CiDeclId) -> i32:
        self.state.data2[(id as i32)]

    fn get_flags(id: CiDeclId) -> i32:
        self.state.flags[(id as i32)]

    fn get_extra(idx: isize) -> i32:
        self.state.extra[idx]

    fn get_string(idx: i32) -> &str:
        self.state.strings[idx]

    // Decl constructor helpers.
    fn fn_decl(name_sym: i32, ret_ty: CiTypeId, body: CiStmtId, flags: i32) -> CiDeclId:
        self.add(CiDeclKind.CID_FN_DECL, name_sym, ret_ty as i32, body as i32, flags)

    fn var_global(name_sym: i32, ty: CiTypeId, init: CiExprId, flags: i32) -> CiDeclId:
        self.add(CiDeclKind.CID_VAR_GLOBAL, name_sym, ty as i32, init as i32, flags)

    fn typedef(name_sym: i32, target: CiTypeId) -> CiDeclId:
        self.add(CiDeclKind.CID_TYPEDEF, name_sym, target as i32, 0, 0)

    fn struct_def(name_sym: i32, fields_start: i32, field_count: i32) -> CiDeclId:
        self.add(CiDeclKind.CID_STRUCT_DEF, name_sym, fields_start, field_count, 0)

    fn enum_def(name_sym: i32, variants_start: i32, variant_count: i32) -> CiDeclId:
        self.add(CiDeclKind.CID_ENUM_DEF, name_sym, variants_start, variant_count, 0)

    fn extern_fn(name_sym: i32, ret_ty: CiTypeId, flags: i32) -> CiDeclId:
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
    top_level_decls: List[i32],
    imports: List[str],
}

fn CiModule.new(name: &str, source_path: &str) -> CiModule:
    CiModule {
        name: with_str_clone_ref(name),
        source_path: with_str_clone_ref(source_path),
        types: CiTypePool.new(),
        exprs: CiExprPool.new(),
        stmts: CiStmtPool.new(),
        decls: CiDeclPool.new(),
        top_level_decls: List.new(),
        imports: List.new(),
    }

impl CiModule:
    mut fn add_decl(decl: CiDeclId) -> Unit:
        self.top_level_decls.push(decl as i32)

    mut fn add_import(path: &str):
        self.imports.push(with_str_clone_ref(path))


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
    // D107 (#2240), CIPS_FN only: per parameter, the evidence the corpus
    // gives about a function-pointer parameter's nullability, and the
    // verdict the fixed point draws from it. `param_fn_ptr[i]` is 1 when
    // parameter i is a function pointer; `param_tested[i]` 1 when the
    // body tests it for NULL and the NULL branch continues;
    // `param_aborting[i]` 1 when every test's NULL branch aborts;
    // `param_null_caller[i]` names the first corpus caller passing NULL;
    // `param_sinks[i]` lists `callee:index`, `field` and `global` sinks
    // the body passes it to; `param_nullable[i]` is the verdict (1 Option)
    // and `param_reason[i]` its one-line reason. `has_definition` is 1 when
    // a corpus unit defines the function; `unanalyzable` 1 when a body
    // could not be walked.
    param_fn_ptr: List[i32],
    param_tested: List[i32],
    param_aborting: List[i32],
    param_null_caller: List[str],
    param_sinks: List[str],
    param_nullable: List[i32],
    param_reason: List[str],
    has_definition: i32,
    unanalyzable: i32,
    // D121 (§16.2b.15), CIPS_FN only: the ownership evidence the body
    // gives and the proofs the fixed point draws. `ret_ty` and
    // `param_ty[i]` are the translated signature types; `own_evidence`
    // the raw `ret:`/`localsrc:`/`localstore:`/`localsink:` records
    // (CImport.w ci_body_ownership_evidence); `param_stores[i]` 1 when the
    // body retains parameter i (a field, a global, or a callee that
    // retains it); `param_destroys[i]` 1 when it frees parameter i or
    // hands it to a destroyer; `owns_return` 1 when every pointer it
    // returns is a fresh allocation it never retained; `borrow_from` the
    // parameter every returned pointer is a part of, else -1;
    // `own_reason` the one-line proof or the reason none was found.
    ret_ty: str,
    param_ty: List[str],
    own_evidence: str,
    param_stores: List[i32],
    param_destroys: List[i32],
    owns_return: i32,
    borrow_from: i32,
    own_reason: str,
    // 1 when a prototype declares the function (a header's API); a
    // definition no prototype declares is internal: its proofs feed its
    // callers' and it is never a facade item (a facade describes imported
    // declarations, §16.2b.13).
    header_declared: i32,
    // D121 step 5: the header the first prototype came from (a cursor
    // location's file), "" for a function no header declares. The facade
    // `with get` writes imports the headers that declare what it presents.
    header_file: str,
    // D121 step 3: the GNU attributes any of its declarations carry
    // (`malloc;nonnull(1);returns_nonnull`), annotation evidence below a
    // proof and above the registry (§16.2b.2).
    attrs: str,
    // D121 step 3: what the package's GObject-introspection files declare
    // about the function (CiGir.w: the return's transfer, nullability and
    // introspected type, the instance parameter, each parameter's
    // transfer), "" when no file names it. The same tier as `attrs`.
    gir: str,
    // D121 step 4: the package registry's fact for the function
    // (CiFacts.w: `kind=…;cite=…`), "" when the file states none. Below
    // `attrs` and `gir`, above a convention profile (§16.2b.2).
    registry: str,
    // D121 step 6: the registry's presentation facts for the function
    // (`nullable:N`, `text_param:N`, `text_return:F`, one `kind|record|cite`
    // per line), beside the one ownership fact in `registry`.
    registry_more: str,
    // D121 step 6: 1 when the function is variadic (never presentable
    // without a `variadic` clause the draft does not write).
    variadic: i32,
}
// #747: str field — owned, non-Copy now; moves/clones spell intent.

fn CiProjectSymbol.new(name: &str, kind: i32) -> CiProjectSymbol:
    CiProjectSymbol {
        name: ci_ir_owned_text(name),
        kind: kind,
        owner_module: -1,
        resolved_ty: 0 as CiTypeId,
        resolved_ty_text: "",
        consumers: "",
        owner_rank: -1,
        owner_definition_kind: 0,
        param_fn_ptr: List.new(),
        param_tested: List.new(),
        param_aborting: List.new(),
        param_null_caller: List.new(),
        param_sinks: List.new(),
        param_nullable: List.new(),
        param_reason: List.new(),
        has_definition: 0,
        unanalyzable: 0,
        ret_ty: "",
        param_ty: List.new(),
        own_evidence: "",
        param_stores: List.new(),
        param_destroys: List.new(),
        owns_return: 0,
        borrow_from: -1,
        own_reason: "",
        gir: "",
        registry: "",
        registry_more: "",
        variadic: 0,
        header_declared: 0,
        header_file: "",
        attrs: "",
    }

fn ci_pipe_i32_contains(items: &str, want: i32) -> bool:
    let needle = "|" ++ i64_to_string(want as i64) ++ "|"
    var i = 0
    let ilen = items.len()
    let nlen = needle.len()
    while i <= ilen - nlen:
        if items.slice(i as i64, (i + nlen) as i64) == needle:
            return true
        i = i + 1
    false

impl CiProjectSymbol:
    mut fn add_consumer(module_id: i32):
        if module_id < 0:
            return
        if ci_pipe_i32_contains(self.consumers, module_id):
            return
        self.consumers = self.consumers ++ "|" ++ i64_to_string(module_id as i64) ++ "|"

    // D107: size every per-parameter vector to at least `n` entries.
    mut fn grow_params(n: i32):
        while self.param_fn_ptr.len() < n: self.param_fn_ptr.push(0)
        while self.param_tested.len() < n: self.param_tested.push(0)
        while self.param_aborting.len() < n: self.param_aborting.push(0)
        while self.param_null_caller.len() < n: self.param_null_caller.push("")
        while self.param_sinks.len() < n: self.param_sinks.push("")
        while self.param_nullable.len() < n: self.param_nullable.push(0)
        while self.param_reason.len() < n: self.param_reason.push("")
        while self.param_ty.len() < n: self.param_ty.push("")
        while self.param_stores.len() < n: self.param_stores.push(0)
        while self.param_destroys.len() < n: self.param_destroys.push(0)

fn ci_project_symbol_key(kind: i32, name: &str) -> str:
    if kind == CiProjectSymbolKind.CIPS_VAR:
        return "v:" ++ name
    if kind == CiProjectSymbolKind.CIPS_FN:
        return "f:" ++ name
    if kind == CiProjectSymbolKind.CIPS_TYPE:
        return "t:" ++ name
    "m:" ++ name

type CiProject {
    module_paths: List[str],
    symbols: List[CiProjectSymbol],
    types: CiTypePool,
    // key (ci_project_symbol_key) → index into `symbols`: the lookup every
    // evidence line and sink walk makes, once linear over thousands of
    // symbols (a tommyds migration ran past 20 minutes, #2230).
    symbol_index: HashMap[str, i32],
    // The (symbol, parameter) pairs one sink-chain walk has entered.
    sink_seen: HashMap[str, i32],
    // D121: globals the corpus initializes to an allocator or to `free`
    // (libxml2's `xmlFreeFunc xmlFree = free`): a call through one is a
    // call to what it names. Source evidence, never a name.
    alloc_aliases: List[str],
    free_aliases: List[str],
    // D121 step 6: the registry's facade-level `text utf8` citation, ""
    // when the file states none.
    registry_utf8: str,
    // D121 step 5: the symbols the last facade draft presented (every
    // producer, destroyer, borrow, lend and consumer it named), so the
    // facade `with get` writes can import the headers that declare them.
    presented: List[i32],
    // D121 step 5: the units `with get` could not read, each with the
    // parser's reason; the report names them (a function only an unread
    // unit defines stays raw, and the reader learns why).
    unread: List[str],
    // Why the last migrate_scan_file failed, "" when it did not.
    scan_problem: str,
}

fn CiProject.new -> CiProject:
    CiProject {
        module_paths: List.new(),
        symbols: List.new(),
        types: CiTypePool.new(),
        symbol_index: HashMap.new(),
        sink_seen: HashMap.new(),
        alloc_aliases: List.new(),
        registry_utf8: "",
        free_aliases: List.new(),
        presented: List.new(),
        unread: List.new(),
        scan_problem: "",
    }

impl CiProject:
    fn ensure_module(path: &str) -> i32:
        var i: i32 = 0
        while i < self.module_paths.len():
            if self.module_paths[i] == path:
                return i
            i = i + 1
        let id = self.module_paths.len() as i32
        self.module_paths.push(ci_ir_owned_text(path))
        id

    fn find_symbol(kind: i32, name: &str) -> i32:
        match self.symbol_index.get(ci_project_symbol_key(kind, name)):
            Some(i) => *i
            None => -1

    mut fn ensure_symbol(kind: i32, name: &str) -> i32:
        let existing = self.find_symbol(kind, name)
        if existing >= 0:
            return existing
        let id = self.symbols.len() as i32
        self.symbols.push(CiProjectSymbol.new(name, kind))
        self.symbol_index.insert(ci_project_symbol_key(kind, name), id)
        id

    fn owner_module_path(symbol_id: i32) -> str:
        if symbol_id < 0 or symbol_id >= self.symbols.len():
            return ""
        let owner_module = self.symbols[symbol_id].owner_module
        if owner_module < 0 or owner_module >= self.module_paths.len():
            return ""
        with_str_clone_ref(self.module_paths[owner_module])

const _ci_ir_eof_guard = 0
