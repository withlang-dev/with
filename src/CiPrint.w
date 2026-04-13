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
    if spaces <= 0:
        return text
    var prefix = ""
    var k: i32 = 0
    while k < spaces:
        prefix = prefix ++ " "
        k = k + 1
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
        // Block composition convention matches the legacy
        // compound_stmt arm: each child is rendered at depth 0
        // (so the child produces level-0-relative text), then
        // re-indented by this block's depth, then followed by a
        // bare "\n" separator. Blank lines between children stay
        // bare; blank lines *within* a child get re-indented by
        // ci_reindent_spaces, matching ci_indent_block's behavior.
        let start = stmts.get_d0(id)
        let count = stmts.get_d1(id)
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
        // The legacy if arm calls ci_trans_stmt(body, 0, scope)
        // and then ci_indent_block(body, indent + 1). We match
        // that by printing body at depth=0 (so the body produces
        // level-0-relative text) and re-indenting by 4. The
        // per-level re-indent is what lets inner CIS_BLOCK bare
        // separators accumulate spaces correctly at each
        // enclosing container.
        let cond = (stmts.get_d0(id)) as CiExprId
        let then_b = (stmts.get_d1(id)) as CiStmtId
        let else_b = (stmts.get_d2(id)) as CiStmtId
        var out = indent ++ "if " ++ ci_print_expr(exprs, types, cond, 0, 0) ++ ":\n"
        let then_text = ci_print_stmt(stmts, exprs, types, then_b, 0)
        out = out ++ ci_reindent_spaces(then_text, 4)
        if (else_b as i32) != 0:
            out = out ++ indent ++ "else:\n"
            let else_text = ci_print_stmt(stmts, exprs, types, else_b, 0)
            out = out ++ ci_reindent_spaces(else_text, 4)
        return out

    if kind == CiStmtKind.CIS_WHILE:
        // Same convention as CIS_IF: body printed at depth=0,
        // then re-indented by 4 at the while's container level.
        let cond = (stmts.get_d0(id)) as CiExprId
        let body = (stmts.get_d1(id)) as CiStmtId
        var out = indent ++ "while " ++ ci_print_expr(exprs, types, cond, 0, 0) ++ ":\n"
        let body_text = ci_print_stmt(stmts, exprs, types, body, 0)
        out = out ++ ci_reindent_spaces(body_text, 4)
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
        // The stashed text is always level-0-relative (the
        // ci_lower_stmt_ir legacy fallback passes indent=0 to the
        // bypass). Re-indent by depth at print time so the
        // content lands at the right column for its enclosing
        // container.
        let text = stmts.get_string(stmts.get_d0(id))
        if depth <= 0:
            return text
        return ci_reindent_spaces(text, depth)

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

fn ci_roundtrip_raw_string -> i32:
    // The Phase-B escape hatch: a raw-string expr prints its interned
    // text verbatim, and a raw-string stmt does the same.
    var types = CiTypePool.new()
    var exprs = CiExprPool.new()
    var stmts = CiStmtPool.new()
    let i32_ty = types.ty_int(32, 0)
    let raw_e = exprs.raw_string("legacy_expr()", i32_ty)
    let raw_s = stmts.raw_string("    legacy_stmt()\n")
    var fails: i32 = 0
    fails = fails + ci_expect_eq("raw_expr", ci_print_expr(&exprs, &types, raw_e, 0, 0), "legacy_expr()")
    fails = fails + ci_expect_eq("raw_stmt", ci_print_stmt(&stmts, &exprs, &types, raw_s, 0), "    legacy_stmt()\n")
    fails

pub fn ci_ir_roundtrip_test -> i32:
    var fails: i32 = 0
    fails = fails + ci_roundtrip_types()
    fails = fails + ci_roundtrip_exprs()
    fails = fails + ci_roundtrip_fn_decl()
    fails = fails + ci_roundtrip_raw_string()
    if fails == 0:
        with_write("ci-roundtrip: PASS\n")
        return 0
    with_eprint("ci-roundtrip: FAIL (" ++ i32_to_string(fails) ++ " case(s))\n")
    1

let _ci_print_eof_guard = 0
