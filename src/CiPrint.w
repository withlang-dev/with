// CiPrint — pretty-printer for the CiIR migrator IR.
//
// This is the sole owner of indentation, parenthesization, array
// decay, `unsafe:` wrapping, cast rendering, and semicolons. It
// never queries libclang and never makes semantic decisions — those
// happened in the lowering pass that produced the IR.
//
// Phase-A skeleton: exhaustive switches over every CiExpr /
// CiStmt / CiDecl kind. A handful of core kinds are implemented
// (literals, identifiers, binary, unary, cast, block, if, return,
// var decl, etc.) so Phase-A's round-trip harness can hand-build
// nontrivial IR and assert on the output. Every other arm returns
// a bracketed `<ci:unimpl:KIND>` placeholder so the structure is
// observable during development. Subsequent B-phase commits replace
// the placeholders one kind at a time.
use CiIR

extern fn with_write(s: str) -> void
extern fn with_eprint(s: str) -> void

// ── Helpers ────────────────────────────────────────────────────

fn ci_make_indent(n: i32) -> str:
    var out = ""
    var i: i32 = 0
    while i < n:
        out = out ++ " "
        i = i + 1
    out

// Prepend `spaces` spaces to every line of `text`, matching
// ci_indent_block's convention: empty lines get the prefix applied
// too (so they become whitespace-only lines at the new indent
// level).
//
// The bare `\n` separators that CIS_BLOCK inserts between children
// get prefixed too when a container above the block re-indents —
// each container level adds another prefix, matching the legacy
// per-level ci_indent_block layering. The outermost result has no
// outer container to re-indent, so its own CIS_BLOCK separators
// stay bare (matching ci_try_translate_fn_body's top-level bare
// blanks between statements).
fn ci_reindent_spaces(text: str, spaces: i32) -> str:
    if text.len() == 0:
        return ""
    var prefix = ""
    var k: i32 = 0
    while k < spaces:
        prefix = prefix ++ " "
        k = k + 1
    // Always loop through lines, even at spaces=0, so reindent_spaces
    // matches ci_indent_block's normalization: every line ends with
    // a trailing newline, including the last. This is crucial for
    // CIS_BLOCK's child-separator convention — the legacy
    // `ci_indent_block(s, indent) ++ push("\n")` pattern produces
    // two trailing newlines after each child, and we need the same.
    var parts: Vec[str] = Vec.new()
    var start = 0
    let tlen = text.len() as i32
    while start < tlen:
        var end = start
        while end < tlen and text.byte_at(end as i64) != 10:
            end = end + 1
        parts.push(prefix)
        parts.push(text.slice(start as i64, end as i64))
        parts.push("\n")
        start = end + 1
    parts.join("")

// Pure decimal literal predicate. Used by the unsigned-wrap
// binary printer to decide whether to wrap an operand in
// `(L as c_uint)` so With's literal type inference picks the
// unsigned type that matches `+%`/`-%`/`*%`.
fn ci_is_decimal_literal_str(s: str) -> bool:
    if s.len() == 0: return false
    var i = 0
    while i as i64 < s.len():
        let c = s.byte_at(i as i64)
        if c < 48 or c > 57: return false
        i = i + 1
    true

fn ci_starts_with_str(s: str, prefix: str) -> bool:
    if prefix.len() > s.len():
        return false
    s.slice(0, prefix.len()) == prefix

fn ci_strip_one_outer_paren(s: str) -> str:
    if s.len() < 2:
        return s
    if s.byte_at(0) != 40 or s.byte_at(s.len() - 1) != 41:
        return s
    var depth = 0
    var i = 0
    while i as i64 < s.len():
        let c = s.byte_at(i as i64)
        if c == 40:
            depth = depth + 1
        else if c == 41:
            depth = depth - 1
            if depth == 0 and i as i64 != s.len() - 1:
                return s
        i = i + 1
    if depth != 0:
        return s
    s.slice(1, s.len() - 1)

// Operator precedence table. Larger = binds tighter. Used by Phase-B
// B3 to decide when to drop redundant parens; Phase A always wraps
// binary / unary expressions in explicit parentheses.
fn ci_bin_op_prec(op: i32) -> i32:
    if op == CiBinOp.CIBO_LOGICAL_OR: return 1
    if op == CiBinOp.CIBO_LOGICAL_AND: return 2
    if op == CiBinOp.CIBO_BIT_OR: return 3
    if op == CiBinOp.CIBO_BIT_XOR: return 4
    if op == CiBinOp.CIBO_BIT_AND: return 5
    if op == CiBinOp.CIBO_EQ: return 6
    if op == CiBinOp.CIBO_NEQ: return 6
    if op == CiBinOp.CIBO_LT: return 7
    if op == CiBinOp.CIBO_LTE: return 7
    if op == CiBinOp.CIBO_GT: return 7
    if op == CiBinOp.CIBO_GTE: return 7
    if op == CiBinOp.CIBO_SHL: return 8
    if op == CiBinOp.CIBO_SHR: return 8
    if op == CiBinOp.CIBO_ADD: return 9
    if op == CiBinOp.CIBO_SUB: return 9
    if op == CiBinOp.CIBO_ADD_WRAP: return 9
    if op == CiBinOp.CIBO_SUB_WRAP: return 9
    if op == CiBinOp.CIBO_MUL: return 10
    if op == CiBinOp.CIBO_DIV: return 10
    if op == CiBinOp.CIBO_MOD: return 10
    if op == CiBinOp.CIBO_MUL_WRAP: return 10
    0

fn ci_bin_op_str(op: i32) -> str:
    if op == CiBinOp.CIBO_ADD: return "+"
    if op == CiBinOp.CIBO_SUB: return "-"
    if op == CiBinOp.CIBO_MUL: return "*"
    if op == CiBinOp.CIBO_DIV: return "/"
    if op == CiBinOp.CIBO_MOD: return "%"
    if op == CiBinOp.CIBO_EQ: return "=="
    if op == CiBinOp.CIBO_NEQ: return "!="
    if op == CiBinOp.CIBO_LT: return "<"
    if op == CiBinOp.CIBO_LTE: return "<="
    if op == CiBinOp.CIBO_GT: return ">"
    if op == CiBinOp.CIBO_GTE: return ">="
    if op == CiBinOp.CIBO_LOGICAL_AND: return "and"
    if op == CiBinOp.CIBO_LOGICAL_OR: return "or"
    if op == CiBinOp.CIBO_BIT_AND: return "&"
    if op == CiBinOp.CIBO_BIT_OR: return "|"
    if op == CiBinOp.CIBO_BIT_XOR: return "^"
    if op == CiBinOp.CIBO_SHL: return "<<"
    if op == CiBinOp.CIBO_SHR: return ">>"
    if op == CiBinOp.CIBO_ADD_WRAP: return "+%"
    if op == CiBinOp.CIBO_SUB_WRAP: return "-%"
    if op == CiBinOp.CIBO_MUL_WRAP: return "*%"
    if op == CiBinOp.CIBO_ASSIGN: return "="
    "?binop?"

fn ci_unary_op_str(op: i32) -> str:
    if op == CiUnaryOp.CIUO_NEG: return "-"
    if op == CiUnaryOp.CIUO_PLUS: return "+"
    if op == CiUnaryOp.CIUO_LOGICAL_NOT: return "not "
    if op == CiUnaryOp.CIUO_BIT_NOT: return "~"
    "?uop?"

fn ci_int_type_name(bits: i32, is_unsigned: i32) -> str:
    if is_unsigned != 0:
        if bits == 8: return "u8"
        if bits == 16: return "u16"
        if bits == 32: return "u32"
        if bits == 64: return "u64"
        return "u32"
    if bits == 8: return "i8"
    if bits == 16: return "i16"
    if bits == 32: return "i32"
    if bits == 64: return "i64"
    "i32"

fn ci_float_type_name(bits: i32) -> str:
    if bits == 32: return "f32"
    if bits == 64: return "f64"
    "f64"

// Wrap an expression source snippet in `(unsafe: ...)` for rendering
// a dereference. Keeping the `unsafe:` wrapping in one place makes
// it cheap to change the convention later.
fn ci_wrap_unsafe(inner: str) -> str:
    "(unsafe: " ++ inner ++ ")"

fn ci_print_compact_stmt_local(stmts: &CiStmtPool, exprs: &CiExprPool, types: &CiTypePool, id: CiStmtId, depth: i32) -> str:
    if (id as i32) == 0:
        return ""
    let kind = stmts.kind(id)
    let indent = ci_make_indent(depth)

    if kind == CiStmtKind.CIS_BLOCK:
        let start = stmts.get_d0(id)
        let count = stmts.get_d1(id)
        var out = ""
        var i: i32 = 0
        while i < count:
            out = out ++ ci_print_compact_stmt_local(stmts, exprs, types, (stmts.get_extra(start + i)) as CiStmtId, depth)
            i = i + 1
        return out

    if kind == CiStmtKind.CIS_EXPR:
        let e = (stmts.get_d0(id)) as CiExprId
        return indent ++ ci_print_expr(exprs, types, e, 0, 0) ++ "\n"

    if kind == CiStmtKind.CIS_RETURN:
        let e = (stmts.get_d0(id)) as CiExprId
        if (e as i32) == 0:
            return indent ++ "return\n"
        var expr_text = ci_print_expr(exprs, types, e, 0, 0)
        if exprs.kind(e) == CiExprKind.CIE_CAST:
            expr_text = "(" ++ expr_text ++ ")"
        return indent ++ "return " ++ expr_text ++ "\n"

    if kind == CiStmtKind.CIS_IF:
        let cond = (stmts.get_d0(id)) as CiExprId
        let then_b = (stmts.get_d1(id)) as CiStmtId
        let else_b = (stmts.get_d2(id)) as CiStmtId
        var out = indent ++ "if " ++ ci_print_expr(exprs, types, cond, 0, 0) ++ ":\n"
        let then_text = ci_print_compact_stmt_local(stmts, exprs, types, then_b, depth + 4)
        if then_text.len() > 0:
            out = out ++ then_text
        else:
            out = out ++ ci_make_indent(depth + 4) ++ "0\n"
        if (else_b as i32) != 0:
            out = out ++ indent ++ "else:\n"
            let else_text = ci_print_compact_stmt_local(stmts, exprs, types, else_b, depth + 4)
            if else_text.len() > 0:
                out = out ++ else_text
            else:
                out = out ++ ci_make_indent(depth + 4) ++ "0\n"
        return out

    if kind == CiStmtKind.CIS_WHILE:
        let cond = (stmts.get_d0(id)) as CiExprId
        let body = (stmts.get_d1(id)) as CiStmtId
        var out = indent ++ "while " ++ ci_print_expr(exprs, types, cond, 0, 0) ++ ":\n"
        let body_text = ci_print_compact_stmt_local(stmts, exprs, types, body, depth + 4)
        if body_text.len() > 0:
            out = out ++ body_text
        else:
            out = out ++ ci_make_indent(depth + 4) ++ "0\n"
        return out

    if kind == CiStmtKind.CIS_VAR_DECL:
        let name_sym = stmts.get_d0(id)
        let ty_id = (stmts.get_d1(id)) as CiTypeId
        let init = (stmts.get_d2(id)) as CiExprId
        let flags = stmts.get_flags(id)
        let is_mut = flags % 2
        let kw = if is_mut != 0: "var " else: "let "
        let name = stmts.get_string(name_sym)
        var out = indent ++ kw ++ name ++ ": " ++ ci_print_type(types, ty_id)
        if (init as i32) != 0:
            var init_text = ci_print_expr(exprs, types, init, 0, 0)
            if exprs.kind(init) == CiExprKind.CIE_CAST:
                init_text = "(" ++ init_text ++ ")"
            out = out ++ " = " ++ init_text
        return out ++ "\n"

    if kind == CiStmtKind.CIS_ASSIGN:
        let lhs = (stmts.get_d0(id)) as CiExprId
        let rhs = (stmts.get_d1(id)) as CiExprId
        var rhs_str = ci_print_expr(exprs, types, rhs, 0, 0)
        if exprs.kind(rhs) == CiExprKind.CIE_CAST:
            rhs_str = "(" ++ rhs_str ++ ")"
        else if exprs.kind(rhs) == CiExprKind.CIE_BINARY:
            let op = exprs.get_d0(rhs)
            if op == CiBinOp.CIBO_ADD or op == CiBinOp.CIBO_SUB or op == CiBinOp.CIBO_MUL or op == CiBinOp.CIBO_DIV or op == CiBinOp.CIBO_MOD or op == CiBinOp.CIBO_BIT_AND or op == CiBinOp.CIBO_BIT_OR or op == CiBinOp.CIBO_BIT_XOR or op == CiBinOp.CIBO_SHL or op == CiBinOp.CIBO_SHR:
                rhs_str = ci_strip_one_outer_paren(rhs_str)
        return indent ++ "(" ++ ci_print_expr(exprs, types, lhs, 0, 0) ++ " = " ++ rhs_str ++ ")\n"

    if kind == CiStmtKind.CIS_BREAK:
        return indent ++ "break\n"
    if kind == CiStmtKind.CIS_CONTINUE:
        return indent ++ "continue\n"

    ci_print_stmt(stmts, exprs, types, id, depth)

// ── CiType printing ──────────────────────────────────────────

fn ci_print_type(types: &CiTypePool, id: CiTypeId) -> str:
    if (id as i32) == 0:
        return "<ci:ty:0>"
    let kind = types.kind(id)
    if kind == CiTypeKind.CT_VOID:
        return "void"
    if kind == CiTypeKind.CT_BOOL:
        return "bool"
    if kind == CiTypeKind.CT_INT:
        let bits = types.get_d0(id)
        let uns = types.get_d1(id)
        return ci_int_type_name(bits, uns)
    if kind == CiTypeKind.CT_FLOAT:
        return ci_float_type_name(types.get_d0(id))
    if kind == CiTypeKind.CT_POINTER:
        let pointee = (types.get_d0(id)) as CiTypeId
        let is_const = types.get_d1(id)
        let kw = if is_const != 0: "*const " else: "*mut "
        return kw ++ ci_print_type(types, pointee)
    if kind == CiTypeKind.CT_ARRAY:
        let elem = (types.get_d0(id)) as CiTypeId
        let size = types.get_d1(id)
        if size == CI_SIZE_INCOMPLETE:
            return "[]" ++ ci_print_type(types, elem)
        return "[" ++ i32_to_string(size) ++ "]" ++ ci_print_type(types, elem)
    if kind == CiTypeKind.CT_STRUCT:
        return types.get_string(types.get_d0(id))
    if kind == CiTypeKind.CT_ENUM:
        return types.get_string(types.get_d0(id))
    if kind == CiTypeKind.CT_NAMED:
        return types.get_string(types.get_d0(id))
    if kind == CiTypeKind.CT_FN_PTR:
        let ret = (types.get_d0(id)) as CiTypeId
        let ps = types.get_d1(id)
        let pc = types.get_d2(id)
        var out = "fn("
        var i: i32 = 0
        while i < pc:
            if i > 0:
                out = out ++ ", "
            let pty = (types.get_extra(ps + i)) as CiTypeId
            out = out ++ ci_print_type(types, pty)
            i = i + 1
        return out ++ ") -> " ++ ci_print_type(types, ret)
    "<ci:ty:unimpl>"

fn i32_to_string(n: i32) -> str:
    i64_to_string(n as i64)

extern fn i64_to_string(n: i64) -> str

// ── CiExpr printing ──────────────────────────────────────────
//
// `parent_prec` is the precedence of the enclosing operator; when
// zero, no enclosing context needs parenthesization help. Phase-A
// always wraps binary/unary in explicit parens, so this parameter
// is read but not yet used for dropping parens. `wants_ptr` is the
// Phase-B array-decay hook: when true, an array-typed expression in
// this position must be emitted as `&base[0] as *mut T`. Also
// unused in A2; B4 turns it on.

fn ci_print_expr(exprs: &CiExprPool, types: &CiTypePool, id: CiExprId, parent_prec: i32, wants_ptr: i32) -> str:
    if (id as i32) == 0:
        return "<ci:expr:0>"
    let kind = exprs.kind(id)

    // Literals — d0 indexes into the expr-pool string table, which
    // holds the already-formatted text (decimal digits, suffix-
    // stripped float, full quoted string, etc.). The lowering pass
    // is responsible for producing identical bytes to the legacy
    // path; the printer is verbatim.
    if kind == CiExprKind.CIE_INT_LIT:
        return exprs.get_string(exprs.get_d0(id))
    if kind == CiExprKind.CIE_FLOAT_LIT:
        return exprs.get_string(exprs.get_d0(id))
    if kind == CiExprKind.CIE_CHAR_LIT:
        return exprs.get_string(exprs.get_d0(id))
    if kind == CiExprKind.CIE_STRING_LIT:
        return exprs.get_string(exprs.get_d0(id))
    if kind == CiExprKind.CIE_BOOL_LIT:
        if exprs.get_d0(id) != 0:
            return "true"
        return "false"
    if kind == CiExprKind.CIE_NULL_PTR:
        return "null"

    // References
    if kind == CiExprKind.CIE_IDENT:
        return exprs.get_string(exprs.get_d0(id))

    // Arithmetic / logical. For unsigned wrap arithmetic
    // (+%, -%, *%) where BOTH operands are bare decimal literals,
    // wrap the LHS in `(L as c_uint)` so With's literal-type
    // inference picks unsigned. When at least one operand is a
    // typed expression, the typed side anchors inference and a
    // bare literal adopts its type.
    if kind == CiExprKind.CIE_BINARY:
        let op = exprs.get_d0(id)
        let lhs = (exprs.get_d1(id)) as CiExprId
        let rhs = (exprs.get_d2(id)) as CiExprId
        var lhs_str = ci_print_expr(exprs, types, lhs, 0, 0)
        let rhs_str = ci_print_expr(exprs, types, rhs, 0, 0)
        if op == CiBinOp.CIBO_ADD_WRAP or op == CiBinOp.CIBO_SUB_WRAP or op == CiBinOp.CIBO_MUL_WRAP:
            if ci_is_decimal_literal_str(lhs_str) and ci_is_decimal_literal_str(rhs_str):
                lhs_str = "(" ++ lhs_str ++ " as c_uint)"
        return "(" ++ lhs_str ++ " " ++ ci_bin_op_str(op) ++ " " ++ rhs_str ++ ")"
    if kind == CiExprKind.CIE_UNARY:
        let op = exprs.get_d0(id)
        let operand = (exprs.get_d1(id)) as CiExprId
        return "(" ++ ci_unary_op_str(op) ++ ci_print_expr(exprs, types, operand, 0, 0) ++ ")"
    if kind == CiExprKind.CIE_PAREN:
        let inner = (exprs.get_d0(id)) as CiExprId
        return "(" ++ ci_print_expr(exprs, types, inner, 0, 0) ++ ")"

    // Postfix / lvalue
    if kind == CiExprKind.CIE_CALL:
        let callee = (exprs.get_d0(id)) as CiExprId
        let args_start = exprs.get_d1(id)
        let arg_count = exprs.get_d2(id)
        var out = ci_print_expr(exprs, types, callee, 0, 0) ++ "("
        var i: i32 = 0
        while i < arg_count:
            if i > 0:
                out = out ++ ", "
            let arg = (exprs.get_extra(args_start + i)) as CiExprId
            out = out ++ ci_print_expr(exprs, types, arg, 0, 0)
            i = i + 1
        return out ++ ")"
    if kind == CiExprKind.CIE_FIELD:
        let base = (exprs.get_d0(id)) as CiExprId
        let field = exprs.get_string(exprs.get_d1(id))
        return ci_print_expr(exprs, types, base, 0, 0) ++ "." ++ field
    if kind == CiExprKind.CIE_INDEX:
        let base = (exprs.get_d0(id)) as CiExprId
        let idx = (exprs.get_d1(id)) as CiExprId
        return ci_print_expr(exprs, types, base, 0, 0) ++ "[" ++ ci_print_expr(exprs, types, idx, 0, 0) ++ "]"
    if kind == CiExprKind.CIE_CAST:
        let target = (exprs.get_d0(id)) as CiTypeId
        let operand = (exprs.get_d1(id)) as CiExprId
        return "(" ++ ci_print_expr(exprs, types, operand, 0, 0) ++ " as " ++ ci_print_type(types, target) ++ ")"
    if kind == CiExprKind.CIE_DEREF:
        let operand = (exprs.get_d0(id)) as CiExprId
        return ci_wrap_unsafe("*" ++ ci_print_expr(exprs, types, operand, 0, 0))
    if kind == CiExprKind.CIE_ADDR_OF:
        let operand = (exprs.get_d0(id)) as CiExprId
        let is_mut = exprs.get_d1(id)
        let kw = if is_mut != 0: "&mut " else: "&"
        return kw ++ ci_print_expr(exprs, types, operand, 0, 0)
    if kind == CiExprKind.CIE_ARRAY_DECAY:
        let operand = (exprs.get_d0(id)) as CiExprId
        let target_ty = exprs.get_type(id)
        if (target_ty as i32) != 0 and types.kind(target_ty) == CiTypeKind.CT_POINTER:
            let pointee_ty = (types.get_d0(target_ty)) as CiTypeId
            let is_const = types.get_d1(target_ty)
            let ptr_kw = if is_const != 0: "*const " else: "*mut "
            return "(&" ++ ci_print_expr(exprs, types, operand, 0, 0) ++ "[0] as " ++ ptr_kw ++ ci_print_type(types, pointee_ty) ++ ")"
        let elem_ty = (exprs.get_d1(id)) as CiTypeId
        return "(&" ++ ci_print_expr(exprs, types, operand, 0, 0) ++ "[0] as *mut " ++ ci_print_type(types, elem_ty) ++ ")"

    // Side-effecting
    if kind == CiExprKind.CIE_PRE_INC:
        return "<ci:unimpl:PRE_INC>"
    if kind == CiExprKind.CIE_PRE_DEC:
        return "<ci:unimpl:PRE_DEC>"
    if kind == CiExprKind.CIE_POST_INC:
        return "<ci:unimpl:POST_INC>"
    if kind == CiExprKind.CIE_POST_DEC:
        return "<ci:unimpl:POST_DEC>"
    if kind == CiExprKind.CIE_COMPOUND_ASSIGN:
        let op = exprs.get_d0(id)
        let lhs = (exprs.get_d1(id)) as CiExprId
        let rhs = (exprs.get_d2(id)) as CiExprId
        let lhs_str = ci_print_expr(exprs, types, lhs, 0, 0)
        let rhs_str = ci_print_expr(exprs, types, rhs, 0, 0)
        return lhs_str ++ " = " ++ lhs_str ++ " " ++ ci_bin_op_str(op) ++ " " ++ rhs_str
    if kind == CiExprKind.CIE_ASSIGN:
        let lhs = (exprs.get_d0(id)) as CiExprId
        let rhs = (exprs.get_d1(id)) as CiExprId
        return ci_print_expr(exprs, types, lhs, 0, 0) ++ " = " ++ ci_print_expr(exprs, types, rhs, 0, 0)

    // Control-expr-shaped
    if kind == CiExprKind.CIE_TERNARY:
        let cond = (exprs.get_d0(id)) as CiExprId
        let then_e = (exprs.get_d1(id)) as CiExprId
        let else_e = (exprs.get_d2(id)) as CiExprId
        var cond_str = ci_print_expr(exprs, types, cond, 0, 0)
        let cond_kind = exprs.kind(cond)
        if cond_kind == CiExprKind.CIE_BINARY or cond_kind == CiExprKind.CIE_UNARY or cond_kind == CiExprKind.CIE_PAREN:
            cond_str = ci_strip_one_outer_paren(cond_str)
        return "(if " ++ cond_str ++ ": " ++ ci_print_expr(exprs, types, then_e, 0, 0) ++ " else: " ++ ci_print_expr(exprs, types, else_e, 0, 0) ++ ")"
    if kind == CiExprKind.CIE_COMMA:
        return "<ci:unimpl:COMMA>"

    // Compile-time. With generic-call syntax `sizeof[T]()`;
    // the C-style `sizeof(T)` would be a plain call.
    if kind == CiExprKind.CIE_SIZEOF_TYPE:
        let t = (exprs.get_d0(id)) as CiTypeId
        return "sizeof[" ++ ci_print_type(types, t) ++ "]()"
    if kind == CiExprKind.CIE_SIZEOF_EXPR:
        return "<ci:unimpl:SIZEOF_EXPR>"

    // Initializers
    if kind == CiExprKind.CIE_INIT_LIST:
        let start = exprs.get_d0(id)
        let count = exprs.get_d1(id)
        let ty_id = exprs.get_type(id)
        var items = ""
        var i: i32 = 0
        while i < count:
            if i > 0:
                items = items ++ ", "
            let item = (exprs.get_extra(start + i)) as CiExprId
            items = items ++ ci_print_expr(exprs, types, item, 0, 0)
            i = i + 1
        if (ty_id as i32) != 0 and types.kind(ty_id) == CiTypeKind.CT_ARRAY:
            return "[" ++ items ++ "]"
        let ty_text = ci_print_type(types, ty_id)
        if ty_text.len() > 0 and ty_text != "i32" and not ci_starts_with_str(ty_text, "__UNSUPPORTED"):
            return ty_text ++ " { " ++ items ++ " }"
        return "{ " ++ items ++ " }"
    if kind == CiExprKind.CIE_DESIGNATED_INIT:
        let start = exprs.get_d0(id)
        let count = exprs.get_d1(id)
        let ty_id = exprs.get_type(id)
        var fields = ""
        var i: i32 = 0
        while i < count:
            if i > 0:
                fields = fields ++ ", "
            let name_idx = exprs.get_extra(start + i * 2)
            let value_id = (exprs.get_extra(start + i * 2 + 1)) as CiExprId
            fields = fields ++ exprs.get_string(name_idx) ++ ": " ++ ci_print_expr(exprs, types, value_id, 0, 0)
            i = i + 1
        let ty_text = ci_print_type(types, ty_id)
        if ty_text.len() > 0 and ty_text != "i32" and not ci_starts_with_str(ty_text, "__UNSUPPORTED"):
            return ty_text ++ " { " ++ fields ++ " }"
        return "{ " ++ fields ++ " }"

    "<ci:expr:unknown>"

// ── CiStmt printing ──────────────────────────────────────────

fn ci_print_stmt(stmts: &CiStmtPool, exprs: &CiExprPool, types: &CiTypePool, id: CiStmtId, depth: i32) -> str:
    if (id as i32) == 0:
        return ci_make_indent(depth) ++ "<ci:stmt:0>\n"
    let kind = stmts.kind(id)
    let indent = ci_make_indent(depth)

    if kind == CiStmtKind.CIS_EXPR:
        let e = (stmts.get_d0(id)) as CiExprId
        return indent ++ ci_print_expr(exprs, types, e, 0, 0) ++ "\n"

    if kind == CiStmtKind.CIS_RETURN:
        let e = (stmts.get_d0(id)) as CiExprId
        if (e as i32) == 0:
            return indent ++ "return\n"
        var expr_text = ci_print_expr(exprs, types, e, 0, 0)
        if exprs.kind(e) == CiExprKind.CIE_CAST:
            expr_text = "(" ++ expr_text ++ ")"
        return indent ++ "return " ++ expr_text ++ "\n"

    if kind == CiStmtKind.CIS_BLOCK:
        let start = stmts.get_d0(id)
        let count = stmts.get_d1(id)
        if count >= 3:
            let first = (stmts.get_extra(start)) as CiStmtId
            let last = (stmts.get_extra(start + count - 1)) as CiStmtId
            if stmts.kind(first) == CiStmtKind.CIS_VAR_DECL and stmts.kind(last) == CiStmtKind.CIS_ASSIGN:
                let init = (stmts.get_d2(first)) as CiExprId
                let lhs = (stmts.get_d0(last)) as CiExprId
                let rhs = (stmts.get_d1(last)) as CiExprId
                if (init as i32) == 0 and exprs.kind(lhs) == CiExprKind.CIE_IDENT:
                    let decl_name = stmts.get_string(stmts.get_d0(first))
                    let lhs_name = exprs.get_string(exprs.get_d0(lhs))
                    if decl_name == lhs_name:
                        let flags = stmts.get_flags(first)
                        let is_mut = flags % 2
                        let kw = if is_mut != 0: "var " else: "let "
                        let ty_id = (stmts.get_d1(first)) as CiTypeId
                        var out = indent ++ kw ++ decl_name ++ ": " ++ ci_print_type(types, ty_id)
                        out = out ++ " = with 0 as __ci_expr_seq_" ++ i32_to_string(id as i32) ++ ":\n"
                        var si: i32 = 1
                        while si < count - 1:
                            out = out ++ ci_print_compact_stmt_local(stmts, exprs, types, (stmts.get_extra(start + si)) as CiStmtId, depth + 4)
                            si = si + 1
                        out = out ++ ci_make_indent(depth + 4) ++ ci_print_expr(exprs, types, rhs, 0, 0) ++ "\n"
                        return out
        // Block composition convention matches the legacy
        // compound_stmt arm: each child is rendered at depth 0
        // (so the child produces level-0-relative text), then
        // re-indented by this block's depth, then followed by a
        // bare "\n" separator. Blank lines between children stay
        // bare; blank lines *within* a child get re-indented by
        // ci_reindent_spaces, matching ci_indent_block's behavior.
        var out = ""
        var i: i32 = 0
        while i < count:
            let child = (stmts.get_extra(start + i)) as CiStmtId
            let child_text = ci_print_stmt(stmts, exprs, types, child, 0)
            out = out ++ ci_reindent_spaces(child_text, depth)
            out = out ++ "\n"
            i = i + 1
        return out

    if kind == CiStmtKind.CIS_IF:
        // Print body at depth=0 so it produces level-0-relative
        // text, then re-indent by 4 spaces. The per-level
        // re-indent is what lets inner CIS_BLOCK bare separators
        // accumulate spaces correctly at each enclosing container.
        let cond = (stmts.get_d0(id)) as CiExprId
        let then_b = (stmts.get_d1(id)) as CiStmtId
        let else_b = (stmts.get_d2(id)) as CiStmtId
        var out = indent ++ "if " ++ ci_print_expr(exprs, types, cond, 0, 0) ++ ":\n"
        let then_text = ci_print_stmt(stmts, exprs, types, then_b, 0)
        if then_text.len() > 0:
            out = out ++ ci_reindent_spaces(then_text, 4)
        else:
            out = out ++ ci_make_indent(depth + 4) ++ "0\n"
        if (else_b as i32) != 0:
            out = out ++ indent ++ "else:\n"
            let else_text = ci_print_stmt(stmts, exprs, types, else_b, 0)
            if else_text.len() > 0:
                out = out ++ ci_reindent_spaces(else_text, 4)
            else:
                out = out ++ ci_make_indent(depth + 4) ++ "0\n"
        return out

    if kind == CiStmtKind.CIS_WHILE:
        // Same convention as CIS_IF: body printed at depth=0,
        // then re-indented by 4 at the while's container level.
        let cond = (stmts.get_d0(id)) as CiExprId
        let body = (stmts.get_d1(id)) as CiStmtId
        var out = indent ++ "while " ++ ci_print_expr(exprs, types, cond, 0, 0) ++ ":\n"
        let body_text = ci_print_stmt(stmts, exprs, types, body, 0)
        if body_text.len() > 0:
            out = out ++ ci_reindent_spaces(body_text, 4)
        else:
            out = out ++ ci_make_indent(depth + 4) ++ "0\n"
        return out

    if kind == CiStmtKind.CIS_DO_WHILE:
        return indent ++ "<ci:unimpl:DO_WHILE>\n"

    if kind == CiStmtKind.CIS_FOR:
        return indent ++ "<ci:unimpl:FOR>\n"

    if kind == CiStmtKind.CIS_MATCH:
        // Legacy match emission format:
        //     match SUBJECT
        //         VALUE =>
        //             BODY
        //         _ => DEFAULT_BODY
        //
        // The goto state machine uses this kind with
        // SUBJECT = raw ident "__pc" and arms keyed on
        // state numbers, plus a default `_ => break` arm.
        //
        // Arm layout in stmts.extra (from CiIR.w comment):
        //     [value_count, value0_expr, value1_expr, ...,
        //      body_stmt_id]
        // Default arms have value_count == 0.
        let subject = (stmts.get_d0(id)) as CiExprId
        let arms_start = stmts.get_d1(id)
        let arm_count = stmts.get_d2(id)
        var out = indent ++ "match " ++ ci_print_expr(exprs, types, subject, 0, 0) ++ "\n"
        var cursor: i32 = arms_start
        var ai: i32 = 0
        while ai < arm_count:
            let value_count = stmts.get_extra(cursor)
            cursor = cursor + 1
            // Compose the arm header (value patterns or `_`)
            var arm_head = ""
            if value_count == 0:
                arm_head = "_"
            else:
                var vi: i32 = 0
                while vi < value_count:
                    if vi > 0:
                        arm_head = arm_head ++ " | "
                    let v_id = (stmts.get_extra(cursor)) as CiExprId
                    arm_head = arm_head ++ ci_print_expr(exprs, types, v_id, 0, 0)
                    cursor = cursor + 1
                    vi = vi + 1
            let body_id = (stmts.get_extra(cursor)) as CiStmtId
            cursor = cursor + 1
            out = out ++ ci_make_indent(depth + 4) ++ arm_head ++ " =>\n"
            if (body_id as i32) == 0:
                out = out ++ ci_make_indent(depth + 8) ++ "0\n"
            else:
                let body_text = ci_print_stmt(stmts, exprs, types, body_id, 0)
                if body_text.len() > 0:
                    out = out ++ ci_reindent_spaces(body_text, depth + 8)
                else:
                    out = out ++ ci_make_indent(depth + 8) ++ "0\n"
            ai = ai + 1
        return out

    if kind == CiStmtKind.CIS_BREAK:
        return indent ++ "break\n"
    if kind == CiStmtKind.CIS_CONTINUE:
        return indent ++ "continue\n"

    if kind == CiStmtKind.CIS_VAR_DECL:
        let name_sym = stmts.get_d0(id)
        let ty_id = (stmts.get_d1(id)) as CiTypeId
        let init = (stmts.get_d2(id)) as CiExprId
        let flags = stmts.get_flags(id)
        let is_mut = flags % 2
        let kw = if is_mut != 0: "var " else: "let "
        let name = stmts.get_string(name_sym)
        var out = indent ++ kw ++ name ++ ": " ++ ci_print_type(types, ty_id)
        if (init as i32) != 0:
            var init_text = ci_print_expr(exprs, types, init, 0, 0)
            if exprs.kind(init) == CiExprKind.CIE_CAST:
                init_text = "(" ++ init_text ++ ")"
            out = out ++ " = " ++ init_text
        return out ++ "\n"

    if kind == CiStmtKind.CIS_ASSIGN:
        let lhs = (stmts.get_d0(id)) as CiExprId
        let rhs = (stmts.get_d1(id)) as CiExprId
        var rhs_str = ci_print_expr(exprs, types, rhs, 0, 0)
        if exprs.kind(rhs) == CiExprKind.CIE_CAST:
            rhs_str = "(" ++ rhs_str ++ ")"
        else if exprs.kind(rhs) == CiExprKind.CIE_BINARY:
            let op = exprs.get_d0(rhs)
            if op == CiBinOp.CIBO_ADD or op == CiBinOp.CIBO_SUB or op == CiBinOp.CIBO_MUL or op == CiBinOp.CIBO_DIV or op == CiBinOp.CIBO_MOD or op == CiBinOp.CIBO_BIT_AND or op == CiBinOp.CIBO_BIT_OR or op == CiBinOp.CIBO_BIT_XOR or op == CiBinOp.CIBO_SHL or op == CiBinOp.CIBO_SHR:
                rhs_str = ci_strip_one_outer_paren(rhs_str)
        return indent ++ "(" ++ ci_print_expr(exprs, types, lhs, 0, 0) ++ " = " ++ rhs_str ++ ")\n"

    if kind == CiStmtKind.CIS_LABEL:
        let sym = stmts.get_d0(id)
        return indent ++ "// label: " ++ stmts.get_string(sym) ++ "\n"
    if kind == CiStmtKind.CIS_GOTO_SYM:
        let sym = stmts.get_d0(id)
        return indent ++ "// goto: " ++ stmts.get_string(sym) ++ "\n"
    if kind == CiStmtKind.CIS_GOTO_STATE:
        let n = stmts.get_d0(id)
        return indent ++ "__pc = " ++ i32_to_string(n) ++ "\n" ++ indent ++ "__goto_pending = 1\n"

    if kind == CiStmtKind.CIS_GOTO_BODY:
        // Full goto state-machine body. Layout matches the
        // legacy ci_lower_goto_body byte-for-byte so pcre2
        // diffs stay at zero.
        //
        // Output shape (at depth=0):
        //     <hoisted decls>
        //     var __pc: i32 = 0
        //     var __goto_pending: i32 = 0
        //     while true:
        //         match __pc
        //             0 =>
        //                 <arm 0 body>
        //             N =>  // label_name
        //                 <arm N body>
        //             _ => break
        //
        // Depths: var/while at `depth`, match at depth+4, arm
        // header at depth+8, arm body at depth+12. Arm child
        // statements are concatenated inline (no blank line
        // separators) — the goto state machine compacts
        // consecutive statements.
        let meta_start = stmts.get_d0(id)
        let hoisted_count = stmts.get_d1(id)
        let arm_count = stmts.get_d2(id)
        var out = ""

        // Hoisted decl stmts.
        var hi: i32 = 0
        while hi < hoisted_count:
            let decl_id = (stmts.get_extra(meta_start + hi)) as CiStmtId
            let decl_text = ci_print_stmt(stmts, exprs, types, decl_id, depth)
            out = out ++ decl_text
            hi = hi + 1

        // State-machine frame.
        let ds = ci_make_indent(depth)
        let ds1 = ci_make_indent(depth + 4)
        let ds2 = ci_make_indent(depth + 8)
        out = out ++ ds ++ "var __pc: i32 = 0\n"
        out = out ++ ds ++ "var __goto_pending: i32 = 0\n"
        out = out ++ ds ++ "while true:\n"
        out = out ++ ds1 ++ "match __pc\n"

        // Each arm: variable-length meta [state, label_str_idx,
        // child_count, child_stmt_0, ..., child_stmt_(K-1)].
        // Arm children are compact-printed inline.
        var ai: i32 = 0
        var arm_cursor = meta_start + hoisted_count
        while ai < arm_count:
            let state_num = stmts.get_extra(arm_cursor)
            let label_str_idx = stmts.get_extra(arm_cursor + 1)
            let child_count = stmts.get_extra(arm_cursor + 2)
            arm_cursor = arm_cursor + 3

            out = out ++ ds2 ++ i32_to_string(state_num) ++ " =>"
            if label_str_idx != 0:
                out = out ++ "  // " ++ stmts.get_string(label_str_idx)
            out = out ++ "\n"

            var ci: i32 = 0
            while ci < child_count:
                let child_id = (stmts.get_extra(arm_cursor + ci)) as CiStmtId
                out = out ++ ci_print_compact_stmt_local(stmts, exprs, types, child_id, depth + 12)
                ci = ci + 1
            arm_cursor = arm_cursor + child_count
            ai = ai + 1

        out = out ++ ds2 ++ "_ => break\n"
        return out

    indent ++ "<ci:stmt:unknown>\n"

// ── CiDecl printing ──────────────────────────────────────────

fn ci_print_decl(decls: &CiDeclPool, stmts: &CiStmtPool, exprs: &CiExprPool, types: &CiTypePool, id: CiDeclId) -> str:
    if (id as i32) == 0:
        return "<ci:decl:0>\n"
    let kind = decls.kind(id)

    if kind == CiDeclKind.CID_FN_DECL:
        let name_sym = decls.get_d0(id)
        let ret_ty = (decls.get_d1(id)) as CiTypeId
        let body = (decls.get_d2(id)) as CiStmtId
        let flags = decls.get_flags(id)
        let name = decls.get_string(name_sym)
        var out = ""
        if (flags / CID_FLAG_C_EXPORT) % 2 == 1:
            out = out ++ "@[c_export(\"" ++ name ++ "\")]\n"
        out = out ++ "fn " ++ name ++ "() -> " ++ ci_print_type(types, ret_ty) ++ ":\n"
        if (body as i32) != 0:
            out = out ++ ci_print_stmt(stmts, exprs, types, body, 4)
        else:
            out = out ++ "    // <ci:decl:fn:no-body>\n"
        return out

    if kind == CiDeclKind.CID_VAR_GLOBAL:
        let name_sym = decls.get_d0(id)
        let ty = (decls.get_d1(id)) as CiTypeId
        let init = (decls.get_d2(id)) as CiExprId
        let flags = decls.get_flags(id)
        let is_extern = (flags / CID_FLAG_VAR_EXTERN) % 2
        let name = decls.get_string(name_sym)
        if is_extern != 0:
            return "extern var " ++ name ++ ": " ++ ci_print_type(types, ty) ++ "\n"
        var out = "var " ++ name ++ ": " ++ ci_print_type(types, ty)
        if (init as i32) != 0:
            out = out ++ " = " ++ ci_print_expr(exprs, types, init, 0, 0)
        return out ++ "\n"

    if kind == CiDeclKind.CID_TYPEDEF:
        let name_sym = decls.get_d0(id)
        let target = (decls.get_d1(id)) as CiTypeId
        return "type " ++ decls.get_string(name_sym) ++ " = " ++ ci_print_type(types, target) ++ "\n"

    if kind == CiDeclKind.CID_STRUCT_DEF:
        return "// <ci:unimpl:STRUCT_DEF>\n"

    if kind == CiDeclKind.CID_ENUM_DEF:
        return "// <ci:unimpl:ENUM_DEF>\n"

    if kind == CiDeclKind.CID_EXTERN_FN:
        let name_sym = decls.get_d0(id)
        let ret_ty = (decls.get_d1(id)) as CiTypeId
        let name = decls.get_string(name_sym)
        return "extern fn " ++ name ++ "() -> " ++ ci_print_type(types, ret_ty) ++ "\n"

    "<ci:decl:unknown>\n"

// ── Roundtrip harness ────────────────────────────────────────
//
// Hand-constructs known IR, calls ci_print_*, and asserts the
// output matches a golden string. Invoked by `with migrate
// --ir-roundtrip` for the cli-selfhost-ir-roundtrip test. Grows as
// Phase-B lowering lands new kinds — each new kind picks up a
// case here that exercises its printer arm in isolation.

fn ci_expect_eq(label: str, actual: str, expected: str) -> i32:
    if actual == expected:
        return 0
    with_eprint("ci-roundtrip FAIL: " ++ label ++ "\n")
    with_eprint("  expected: " ++ expected ++ "\n")
    with_eprint("  actual:   " ++ actual ++ "\n")
    1

fn ci_roundtrip_types -> i32:
    var types = CiTypePool.new()
    let i32_ty = types.ty_int(32, 0)
    let u8_ty = types.ty_int(8, 1)
    let bool_ty = types.ty_bool()
    let ptr_i32 = types.ty_pointer(i32_ty, 0)
    let arr_10_i32 = types.ty_array(i32_ty, 10)
    let arr_open_u8 = types.ty_array(u8_ty, CI_SIZE_INCOMPLETE)
    var fails: i32 = 0
    fails = fails + ci_expect_eq("ty_int_32_signed", ci_print_type(&types, i32_ty), "i32")
    fails = fails + ci_expect_eq("ty_int_8_unsigned", ci_print_type(&types, u8_ty), "u8")
    fails = fails + ci_expect_eq("ty_bool", ci_print_type(&types, bool_ty), "bool")
    fails = fails + ci_expect_eq("ty_ptr_mut_i32", ci_print_type(&types, ptr_i32), "*mut i32")
    fails = fails + ci_expect_eq("ty_array_10_i32", ci_print_type(&types, arr_10_i32), "[10]i32")
    fails = fails + ci_expect_eq("ty_array_open_u8", ci_print_type(&types, arr_open_u8), "[]u8")
    fails

fn ci_roundtrip_exprs -> i32:
    var types = CiTypePool.new()
    var exprs = CiExprPool.new()
    let i32_ty = types.ty_int(32, 0)
    let u8_ty = types.ty_int(8, 1)
    let f32_ty = types.ty_float(32)
    let lit_idx = exprs.add_string("42")
    let lit = exprs.int_lit(lit_idx, i32_ty)
    let a_idx = exprs.add_string("a")
    let b_idx = exprs.add_string("b")
    let a = exprs.ident(a_idx, i32_ty)
    let b = exprs.ident(b_idx, i32_ty)
    let add = exprs.binary(CiBinOp.CIBO_ADD, a, b, i32_ty)
    let neg = exprs.unary(CiUnaryOp.CIUO_NEG, lit, i32_ty)
    let cast_u8 = exprs.cast(u8_ty, a)
    // CIE_FLOAT_LIT, CIE_CHAR_LIT, CIE_STRING_LIT all use string-table
    // indirect storage; the lowering pass owns formatting and the
    // printer is verbatim.
    let float_idx = exprs.add_string("3.14")
    let float_lit = exprs.add(CiExprKind.CIE_FLOAT_LIT, float_idx, 0, 0, f32_ty)
    let char_idx = exprs.add_string("65")
    let char_lit = exprs.add(CiExprKind.CIE_CHAR_LIT, char_idx, 0, 0, i32_ty)
    let str_idx = exprs.add_string("\"hello\"")
    let str_lit = exprs.add(CiExprKind.CIE_STRING_LIT, str_idx, 0, 0, 0 as CiTypeId)
    var fails: i32 = 0
    fails = fails + ci_expect_eq("expr_int_lit", ci_print_expr(&exprs, &types, lit, 0, 0), "42")
    fails = fails + ci_expect_eq("expr_ident", ci_print_expr(&exprs, &types, a, 0, 0), "a")
    fails = fails + ci_expect_eq("expr_binary_add", ci_print_expr(&exprs, &types, add, 0, 0), "(a + b)")
    fails = fails + ci_expect_eq("expr_unary_neg", ci_print_expr(&exprs, &types, neg, 0, 0), "(-42)")
    fails = fails + ci_expect_eq("expr_cast_u8", ci_print_expr(&exprs, &types, cast_u8, 0, 0), "(a as u8)")
    fails = fails + ci_expect_eq("expr_float_lit", ci_print_expr(&exprs, &types, float_lit, 0, 0), "3.14")
    fails = fails + ci_expect_eq("expr_char_lit", ci_print_expr(&exprs, &types, char_lit, 0, 0), "65")
    fails = fails + ci_expect_eq("expr_string_lit", ci_print_expr(&exprs, &types, str_lit, 0, 0), "\"hello\"")
    fails

fn ci_roundtrip_fn_decl -> i32:
    // Construct:  fn foo() -> i32:
    //                 return 42
    var types = CiTypePool.new()
    var exprs = CiExprPool.new()
    var stmts = CiStmtPool.new()
    var decls = CiDeclPool.new()
    let i32_ty = types.ty_int(32, 0)
    let lit_idx = exprs.add_string("42")
    let lit = exprs.int_lit(lit_idx, i32_ty)
    let ret = stmts.return_(lit)
    let start = stmts.add_extra(ret as i32)
    let body = stmts.block(start, 1)
    let name_idx = decls.add_string("foo")
    let fn_d = decls.fn_decl(name_idx, i32_ty, body, 0)
    let actual = ci_print_decl(&decls, &stmts, &exprs, &types, fn_d)
    // CIS_BLOCK now appends a bare `\n` separator after each
    // child to match the legacy compound_stmt's blank-line
    // convention.
    let expected = "fn foo() -> i32:\n    return 42\n\n"
    ci_expect_eq("fn_decl_return_literal", actual, expected)

pub fn ci_ir_roundtrip_test -> i32:
    var fails: i32 = 0
    fails = fails + ci_roundtrip_types()
    fails = fails + ci_roundtrip_exprs()
    fails = fails + ci_roundtrip_fn_decl()
    if fails == 0:
        with_write("ci-roundtrip: PASS\n")
        return 0
    with_eprint("ci-roundtrip: FAIL (" ++ i32_to_string(fails) ++ " case(s))\n")
    1

let _ci_print_eof_guard = 0
