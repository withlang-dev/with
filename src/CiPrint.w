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
//
// The CIE_RAW_STRING / CIS_RAW_STRING kinds print their interned
// text verbatim, matching the Phase-B escape-hatch discipline.

use CiIR

// ── Helpers ────────────────────────────────────────────────────

fn ci_make_indent(n: i32) -> str:
    var out = ""
    var i: i32 = 0
    while i < n:
        out = out ++ " "
        i = i + 1
    out

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
    if op == CiBinOp.CIBO_MUL: return 10
    if op == CiBinOp.CIBO_DIV: return 10
    if op == CiBinOp.CIBO_MOD: return 10
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

// ── CiType printing ──────────────────────────────────────────

fn ci_print_type(types: &CiTypePool, id: CiTypeId) -> str:
    if (id as i32) == 0:
        return "<ci:ty:0>"
    let kind = types.kind(id)
    if kind == CiTypeKind.CT_VOID:
        return "unit"
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

    // Literals
    if kind == CiExprKind.CIE_INT_LIT:
        return exprs.get_string(exprs.get_d0(id))
    if kind == CiExprKind.CIE_FLOAT_LIT:
        return exprs.get_string(exprs.get_d0(id))
    if kind == CiExprKind.CIE_CHAR_LIT:
        return i32_to_string(exprs.get_d0(id))
    if kind == CiExprKind.CIE_STRING_LIT:
        return "\"" ++ exprs.get_string(exprs.get_d0(id)) ++ "\""
    if kind == CiExprKind.CIE_BOOL_LIT:
        if exprs.get_d0(id) != 0:
            return "true"
        return "false"
    if kind == CiExprKind.CIE_NULL_PTR:
        return "null"

    // References
    if kind == CiExprKind.CIE_IDENT:
        return exprs.get_string(exprs.get_d0(id))

    // Arithmetic / logical
    if kind == CiExprKind.CIE_BINARY:
        let op = exprs.get_d0(id)
        let lhs = (exprs.get_d1(id)) as CiExprId
        let rhs = (exprs.get_d2(id)) as CiExprId
        return "(" ++ ci_print_expr(exprs, types, lhs, 0, 0) ++ " " ++ ci_bin_op_str(op) ++ " " ++ ci_print_expr(exprs, types, rhs, 0, 0) ++ ")"
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
        return "&" ++ ci_print_expr(exprs, types, operand, 0, 0)
    if kind == CiExprKind.CIE_ARRAY_DECAY:
        let operand = (exprs.get_d0(id)) as CiExprId
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
        return "<ci:unimpl:COMPOUND_ASSIGN>"
    if kind == CiExprKind.CIE_ASSIGN:
        let lhs = (exprs.get_d0(id)) as CiExprId
        let rhs = (exprs.get_d1(id)) as CiExprId
        return ci_print_expr(exprs, types, lhs, 0, 0) ++ " = " ++ ci_print_expr(exprs, types, rhs, 0, 0)

    // Control-expr-shaped
    if kind == CiExprKind.CIE_TERNARY:
        let cond = (exprs.get_d0(id)) as CiExprId
        let then_e = (exprs.get_d1(id)) as CiExprId
        let else_e = (exprs.get_d2(id)) as CiExprId
        return "(if " ++ ci_print_expr(exprs, types, cond, 0, 0) ++ ": " ++ ci_print_expr(exprs, types, then_e, 0, 0) ++ " else: " ++ ci_print_expr(exprs, types, else_e, 0, 0) ++ ")"
    if kind == CiExprKind.CIE_COMMA:
        return "<ci:unimpl:COMMA>"

    // Compile-time
    if kind == CiExprKind.CIE_SIZEOF_TYPE:
        let t = (exprs.get_d0(id)) as CiTypeId
        return "sizeof(" ++ ci_print_type(types, t) ++ ")"
    if kind == CiExprKind.CIE_SIZEOF_EXPR:
        return "<ci:unimpl:SIZEOF_EXPR>"

    // Initializers
    if kind == CiExprKind.CIE_INIT_LIST:
        return "<ci:unimpl:INIT_LIST>"
    if kind == CiExprKind.CIE_DESIGNATED_INIT:
        return "<ci:unimpl:DESIGNATED_INIT>"

    // Escape hatch
    if kind == CiExprKind.CIE_RAW_STRING:
        return exprs.get_string(exprs.get_d0(id))

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
        return indent ++ "return " ++ ci_print_expr(exprs, types, e, 0, 0) ++ "\n"

    if kind == CiStmtKind.CIS_BLOCK:
        let start = stmts.get_d0(id)
        let count = stmts.get_d1(id)
        var out = ""
        var i: i32 = 0
        while i < count:
            let child = (stmts.get_extra(start + i)) as CiStmtId
            out = out ++ ci_print_stmt(stmts, exprs, types, child, depth)
            i = i + 1
        return out

    if kind == CiStmtKind.CIS_IF:
        let cond = (stmts.get_d0(id)) as CiExprId
        let then_b = (stmts.get_d1(id)) as CiStmtId
        let else_b = (stmts.get_d2(id)) as CiStmtId
        var out = indent ++ "if " ++ ci_print_expr(exprs, types, cond, 0, 0) ++ ":\n"
        out = out ++ ci_print_stmt(stmts, exprs, types, then_b, depth + 4)
        if (else_b as i32) != 0:
            out = out ++ indent ++ "else:\n"
            out = out ++ ci_print_stmt(stmts, exprs, types, else_b, depth + 4)
        return out

    if kind == CiStmtKind.CIS_WHILE:
        let cond = (stmts.get_d0(id)) as CiExprId
        let body = (stmts.get_d1(id)) as CiStmtId
        var out = indent ++ "while " ++ ci_print_expr(exprs, types, cond, 0, 0) ++ ":\n"
        out = out ++ ci_print_stmt(stmts, exprs, types, body, depth + 4)
        return out

    if kind == CiStmtKind.CIS_DO_WHILE:
        return indent ++ "<ci:unimpl:DO_WHILE>\n"

    if kind == CiStmtKind.CIS_FOR:
        return indent ++ "<ci:unimpl:FOR>\n"

    if kind == CiStmtKind.CIS_MATCH:
        return indent ++ "<ci:unimpl:MATCH>\n"

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
            out = out ++ " = " ++ ci_print_expr(exprs, types, init, 0, 0)
        return out ++ "\n"

    if kind == CiStmtKind.CIS_ASSIGN:
        let lhs = (stmts.get_d0(id)) as CiExprId
        let rhs = (stmts.get_d1(id)) as CiExprId
        return indent ++ ci_print_expr(exprs, types, lhs, 0, 0) ++ " = " ++ ci_print_expr(exprs, types, rhs, 0, 0) ++ "\n"

    if kind == CiStmtKind.CIS_LABEL:
        let sym = stmts.get_d0(id)
        return indent ++ "// label: " ++ stmts.get_string(sym) ++ "\n"
    if kind == CiStmtKind.CIS_GOTO_SYM:
        let sym = stmts.get_d0(id)
        return indent ++ "// goto: " ++ stmts.get_string(sym) ++ "\n"
    if kind == CiStmtKind.CIS_GOTO_STATE:
        let n = stmts.get_d0(id)
        return indent ++ "__pc = " ++ i32_to_string(n) ++ "\n" ++ indent ++ "__goto_pending = 1\n"

    if kind == CiStmtKind.CIS_RAW_STRING:
        return stmts.get_string(stmts.get_d0(id))

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

let _ci_print_eof_guard = 0
