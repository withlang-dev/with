// render — AST pretty-printer for debugging and snapshot tests.
//
// Renders AST nodes from the AstPool back to human-readable text.
// This is NOT a formatter — it's a debug dump that shows tree structure.

use Ast
use Token
use InternPool

extern fn with_print(s: str) -> void
extern fn int_to_string(n: i32) -> str

// Render an entire module (all top-level decls).
fn render_module(pool: AstPool, intern: InternPool) -> str:
    var out = ""
    for i in 0..pool.decl_count():
        let decl = pool.get_decl(i)
        out = out ++ render_decl(pool, intern, decl, 0) ++ "\n"
    out

// Render a single declaration.
fn render_decl(pool: AstPool, intern: InternPool, node: i32, indent: i32) -> str:
    let kind = pool.kind(node)
    let prefix = make_indent(indent)

    if kind == NK_FN_DECL():
        let name = intern.resolve(pool.get_data0(node))
        let body = pool.get_data1(node)
        let flags = pool.get_data2(node)
        var out = prefix
        if (flags / FN_FLAG_PUB()) % 2 == 1:
            out = out ++ "pub "
        if (flags / FN_FLAG_ASYNC()) % 2 == 1:
            out = out ++ "async "
        if (flags / FN_FLAG_GEN()) % 2 == 1:
            out = out ++ "gen "
        out = out ++ "fn " ++ name ++ ":\n"
        out = out ++ render_expr(pool, intern, body, indent + 2)
        return out

    if kind == NK_TYPE_DECL():
        let name = intern.resolve(pool.get_data0(node))
        let sub_kind = pool.get_data2(node)
        var out = prefix
        out = out ++ "type " ++ name ++ " = ..."
        return out

    if kind == NK_USE_DECL():
        let extra_start = pool.get_data0(node)
        let path_count = pool.get_data1(node)
        var out = prefix ++ "use "
        for pi in 0..path_count:
            if pi > 0:
                out = out ++ "."
            out = out ++ intern.resolve(pool.get_extra(extra_start + pi))
        return out

    if kind == NK_LET_DECL():
        let name = intern.resolve(pool.get_data0(node))
        let value = pool.get_data1(node)
        let flags = pool.get_data2(node)
        var out = prefix
        if flags % 2 == 1:
            out = out ++ "var "
        else:
            out = out ++ "let "
        out = out ++ name ++ " = " ++ render_expr(pool, intern, value, 0)
        return out

    if kind == NK_EXTERN_FN():
        let name = intern.resolve(pool.get_data0(node))
        return prefix ++ "extern fn " ++ name

    if kind == NK_TRAIT_DECL():
        let name = intern.resolve(pool.get_data0(node))
        return prefix ++ "trait " ++ name

    if kind == NK_IMPL_DECL():
        let type_name = intern.resolve(pool.get_data0(node))
        let trait_sym = pool.get_data2(node)
        if trait_sym != 0:
            return prefix ++ "impl " ++ intern.resolve(trait_sym) ++ " for " ++ type_name
        return prefix ++ "extend " ++ type_name

    if kind == NK_POISONED_DECL():
        return prefix ++ "<poisoned>"

    prefix ++ "<unknown decl>"

// Render an expression.
fn render_expr(pool: AstPool, intern: InternPool, node: i32, indent: i32) -> str:
    if node == 0:
        return "<null>"

    let kind = pool.kind(node)
    let prefix = make_indent(indent)

    if kind == NK_INT_LIT():
        return prefix ++ int_to_string(pool.get_data0(node))

    if kind == NK_STRING_LIT():
        return prefix ++ "\"" ++ intern.resolve(pool.get_data0(node)) ++ "\""

    if kind == NK_C_STRING_LIT():
        return prefix ++ "c\"" ++ intern.resolve(pool.get_data0(node)) ++ "\""

    if kind == NK_BOOL_LIT():
        if pool.get_data0(node) != 0:
            return prefix ++ "true"
        return prefix ++ "false"

    if kind == NK_IDENT():
        return prefix ++ intern.resolve(pool.get_data0(node))

    if kind == NK_BINARY():
        let op = pool.get_data0(node)
        let lhs = pool.get_data1(node)
        let rhs = pool.get_data2(node)
        return prefix ++ "(" ++ render_expr(pool, intern, lhs, 0) ++ " " ++ bin_op_str(op) ++ " " ++ render_expr(pool, intern, rhs, 0) ++ ")"

    if kind == NK_UNARY():
        let op = pool.get_data0(node)
        let operand = pool.get_data1(node)
        return prefix ++ "(" ++ unary_op_str(op) ++ render_expr(pool, intern, operand, 0) ++ ")"

    if kind == NK_CALL():
        let callee = pool.get_data0(node)
        let extra_start = pool.get_data1(node)
        let arg_count = pool.get_data2(node)
        var out = prefix ++ render_expr(pool, intern, callee, 0) ++ "("
        for i in 0..arg_count:
            if i > 0:
                out = out ++ ", "
            out = out ++ render_expr(pool, intern, pool.get_extra(extra_start + i), 0)
        return out ++ ")"

    if kind == NK_FIELD_ACCESS():
        let expr = pool.get_data0(node)
        let field = intern.resolve(pool.get_data1(node))
        return prefix ++ render_expr(pool, intern, expr, 0) ++ "." ++ field

    if kind == NK_BLOCK():
        let extra_start = pool.get_data0(node)
        let stmt_count = pool.get_data1(node)
        let tail = pool.get_data2(node)
        var out = ""
        for i in 0..stmt_count:
            out = out ++ render_expr(pool, intern, pool.get_extra(extra_start + i), indent) ++ "\n"
        if tail != 0:
            out = out ++ render_expr(pool, intern, tail, indent)
        return out

    if kind == NK_IF_EXPR():
        let cond = pool.get_data0(node)
        let then_body = pool.get_data1(node)
        let else_body = pool.get_data2(node)
        var out = prefix ++ "if " ++ render_expr(pool, intern, cond, 0) ++ " then " ++ render_expr(pool, intern, then_body, 0)
        if else_body != 0:
            out = out ++ " else " ++ render_expr(pool, intern, else_body, 0)
        return out

    if kind == NK_RETURN():
        let value = pool.get_data0(node)
        if value != 0:
            return prefix ++ "return " ++ render_expr(pool, intern, value, 0)
        return prefix ++ "return"

    if kind == NK_LET_BINDING():
        let name = intern.resolve(pool.get_data0(node))
        let value = pool.get_data1(node)
        let flags = pool.get_data2(node)
        if flags % 2 == 1:
            return prefix ++ "var " ++ name ++ " = " ++ render_expr(pool, intern, value, 0)
        return prefix ++ "let " ++ name ++ " = " ++ render_expr(pool, intern, value, 0)

    if kind == NK_ASSIGN():
        let target = pool.get_data0(node)
        let value = pool.get_data1(node)
        return prefix ++ render_expr(pool, intern, target, 0) ++ " = " ++ render_expr(pool, intern, value, 0)

    if kind == NK_WHILE():
        let cond = pool.get_data0(node)
        let body = pool.get_data1(node)
        return prefix ++ "while " ++ render_expr(pool, intern, cond, 0) ++ ":\n" ++ render_expr(pool, intern, body, indent + 2)

    if kind == NK_LOOP():
        let body = pool.get_data0(node)
        return prefix ++ "loop:\n" ++ render_expr(pool, intern, body, indent + 2)

    if kind == NK_FOR():
        let binding = intern.resolve(pool.get_data0(node))
        let iterable = pool.get_data1(node)
        let body = pool.get_data2(node)
        return prefix ++ "for " ++ binding ++ " in " ++ render_expr(pool, intern, iterable, 0) ++ ":\n" ++ render_expr(pool, intern, body, indent + 2)

    if kind == NK_BREAK():
        return prefix ++ "break"

    if kind == NK_CONTINUE():
        return prefix ++ "continue"

    if kind == NK_MATCH():
        let subject = pool.get_data0(node)
        return prefix ++ "match " ++ render_expr(pool, intern, subject, 0)

    if kind == NK_GROUPED():
        let inner = pool.get_data0(node)
        return prefix ++ "(" ++ render_expr(pool, intern, inner, 0) ++ ")"

    if kind == NK_CAST():
        let expr = pool.get_data0(node)
        return prefix ++ render_expr(pool, intern, expr, 0) ++ " as ..."

    if kind == NK_DEFER():
        let body = pool.get_data0(node)
        return prefix ++ "defer " ++ render_expr(pool, intern, body, 0)

    if kind == NK_PIPELINE():
        let lhs = pool.get_data0(node)
        let rhs = pool.get_data1(node)
        return prefix ++ render_expr(pool, intern, lhs, 0) ++ " |> " ++ render_expr(pool, intern, rhs, 0)

    if kind == NK_VARIANT_SHORTHAND():
        let name = intern.resolve(pool.get_data0(node))
        return prefix ++ "." ++ name

    if kind == NK_POISONED_EXPR():
        return prefix ++ "<poisoned>"

    prefix ++ "<expr:" ++ int_to_string(kind) ++ ">"

// Render a type expression node.
fn render_type_expr(pool: AstPool, intern: InternPool, node: i32) -> str:
    if node == 0:
        return "_"

    let kind = pool.kind(node)

    if kind == NK_TYPE_NAMED():
        return intern.resolve(pool.get_data0(node))

    if kind == NK_TYPE_GENERIC():
        let name = intern.resolve(pool.get_data0(node))
        let extra_start = pool.get_data1(node)
        let arg_count = pool.get_data2(node)
        var out = name ++ "["
        for i in 0..arg_count:
            if i > 0:
                out = out ++ ", "
            out = out ++ render_type_expr(pool, intern, pool.get_extra(extra_start + i))
        return out ++ "]"

    if kind == NK_TYPE_REF():
        let pointee = pool.get_data0(node)
        let is_mut = pool.get_data1(node)
        if is_mut != 0:
            return "&mut " ++ render_type_expr(pool, intern, pointee)
        return "&" ++ render_type_expr(pool, intern, pointee)

    if kind == NK_TYPE_OPTIONAL():
        let inner = pool.get_data0(node)
        return "?" ++ render_type_expr(pool, intern, inner)

    if kind == NK_TYPE_INFERRED():
        return "_"

    "<type:" ++ int_to_string(kind) ++ ">"

// Helper: binary operator to string.
fn bin_op_str(op: i32) -> str:
    if op == OP_ADD(): return "+"
    if op == OP_SUB(): return "-"
    if op == OP_MUL(): return "*"
    if op == OP_DIV(): return "/"
    if op == OP_MOD(): return "%"
    if op == OP_EQ(): return "=="
    if op == OP_NEQ(): return "!="
    if op == OP_LT(): return "<"
    if op == OP_GT(): return ">"
    if op == OP_LTE(): return "<="
    if op == OP_GTE(): return ">="
    if op == OP_AND(): return "and"
    if op == OP_OR(): return "or"
    if op == OP_BIT_AND(): return "&"
    if op == OP_BIT_OR(): return "|"
    if op == OP_BIT_XOR(): return "^"
    if op == OP_SHL(): return "<<"
    if op == OP_SHR(): return ">>"
    if op == OP_DEFAULT(): return "??"
    if op == OP_CONCAT(): return "++"
    if op == OP_ADD_WRAP(): return "+%"
    if op == OP_SUB_WRAP(): return "-%"
    if op == OP_MUL_WRAP(): return "*%"
    if op == OP_IN(): return "in"
    if op == OP_NOT_IN(): return "not in"
    "?op?"

// Helper: unary operator to string.
fn unary_op_str(op: i32) -> str:
    if op == UOP_NEGATE(): return "-"
    if op == UOP_NOT(): return "not "
    if op == UOP_REF(): return "&"
    if op == UOP_MUT_REF(): return "&mut "
    if op == UOP_DEREF(): return "*"
    if op == UOP_TRY(): return "?"
    "?uop?"

fn make_indent(n: i32) -> str:
    var out = ""
    for i in 0..n:
        out = out ++ " "
    out
