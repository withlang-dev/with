// render — AST pretty-printer for deterministic dump output.
//
// This mirrors Stage0's render surface, adapted to AstPool indices.

use Ast
use Token
use InternPool


extern fn str_from_byte(b: i32) -> str

fn render_module(pool: AstPool, intern: InternPool) -> str:
    var out = ""
    for i in 0..pool.decl_count():
        let decl = pool.get_decl(i)
        out = out ++ render_decl(pool, intern, (decl) as NodeId, 0) ++ "\n"
    out

fn render_decl(pool: AstPool, intern: InternPool, node: NodeId, indent: i32) -> str:
    let kind = pool.kind(node)
    let prefix = make_indent(indent)

    if kind == NodeKind.NK_FN_DECL:
        let name = intern.resolve(pool.get_data0(node))
        let flags = pool.get_data2(node)
        let body = pool.get_data1(node)
        var out = prefix
        if has_flag(flags, FnFlags.PUB):
            out = out ++ "pub "
        if has_flag(flags, FnFlags.ASYNC):
            out = out ++ "async "
        if has_flag(flags, FnFlags.GEN):
            out = out ++ "gen "
        out = out ++ "fn " ++ name

        let meta = pool.find_fn_meta(node)
        if meta >= 0:
            let tp_start = pool.fn_meta_tp_start(meta)
            let tp_count = pool.fn_meta_tp_count(meta)
            if tp_count > 0:
                out = out ++ render_type_params(pool, intern, tp_start, tp_count)

            let param_start = pool.fn_meta_param_start(meta)
            let param_count = pool.fn_meta_param_count(meta)
            if param_count > 0:
                out = out ++ "(" ++ render_params(pool, intern, param_start, param_count) ++ ")"

            let ret_ty = pool.fn_meta_ret(meta)
            if ret_ty != 0:
                out = out ++ " -> " ++ render_type_expr(pool, intern, (ret_ty) as NodeId)

        out = out ++ ":\n"
        out = out ++ render_expr(pool, intern, (body) as NodeId, indent + 2)
        return out

    if kind == NodeKind.NK_TYPE_DECL:
        let name = intern.resolve(pool.get_data0(node))
        let extra_start = pool.get_data1(node)
        let packed_kind = pool.get_data2(node)
        let sub_kind = type_decl_sub_kind(packed_kind)
        let is_ephemeral = type_decl_is_ephemeral(packed_kind)
        var out = prefix

        if type_decl_is_pub(pool, extra_start, sub_kind):
            out = out ++ "pub "
        if is_ephemeral != 0:
            out = out ++ "type " ++ name ++ " ephemeral "
        else if sub_kind == TypeDeclKind.Enum or sub_kind == TypeDeclKind.DiscEnum:
            out = out ++ "enum " ++ name
        else:
            out = out ++ "type " ++ name

        if sub_kind == TypeDeclKind.Struct:
            let field_count = pool.get_extra(extra_start)
            var ep = extra_start + 1
            out = out ++ " " ++ render_lbrace() ++ " "
            for fi in 0..field_count:
                if fi > 0:
                    out = out ++ ", "
                let field_name = intern.resolve(pool.get_extra(ep))
                let field_type = pool.get_extra(ep + 1)
                let field_default = pool.get_extra(ep + 2)
                ep = ep + 3
                out = out ++ field_name ++ ": " ++ render_type_expr(pool, intern, (field_type) as NodeId)
                if field_default != 0:
                    out = out ++ " = " ++ render_expr(pool, intern, (field_default) as NodeId, 0)
            out = out ++ " " ++ render_rbrace()
            return out

        if sub_kind == TypeDeclKind.Alias:
            let aliased = pool.get_extra(extra_start)
            out = out ++ " = " ++ render_type_expr(pool, intern, (aliased) as NodeId)
            return out

        if sub_kind == TypeDeclKind.Distinct:
            let aliased = pool.get_extra(extra_start)
            out = out ++ " = distinct " ++ render_type_expr(pool, intern, (aliased) as NodeId)
            return out

        if sub_kind == TypeDeclKind.Enum:
            let variant_count = pool.get_extra(extra_start)
            var ep = extra_start + 1
            out = out ++ ":\n"
            for vi in 0..variant_count:
                out = out ++ make_indent(indent + 2)
                let vname = intern.resolve(pool.get_extra(ep))
                ep = ep + 1
                let payload_count = pool.get_extra(ep)
                ep = ep + 1
                out = out ++ vname
                if payload_count > 0:
                    out = out ++ "("
                    for pi in 0..payload_count:
                        if pi > 0:
                            out = out ++ ", "
                        out = out ++ render_type_expr(pool, intern, (pool.get_extra(ep)) as NodeId)
                        ep = ep + 1
                    out = out ++ ")"
                out = out ++ "\n"
            return out

        if sub_kind == TypeDeclKind.DiscEnum:
            let repr_node = pool.get_extra(extra_start)
            let variant_count = pool.get_extra(extra_start + 1)
            var ep = extra_start + 2
            out = out ++ ": " ++ render_type_expr(pool, intern, (repr_node) as NodeId) ++ ":\n"
            for vi in 0..variant_count:
                out = out ++ make_indent(indent + 2)
                let vname = intern.resolve(pool.get_extra(ep))
                ep = ep + 1
                let disc_val = pool.get_extra(ep)
                ep = ep + 1
                let payload_count = pool.get_extra(ep)
                ep = ep + 1
                out = out ++ f"{vname} = {disc_val}"
                if payload_count > 0:
                    out = out ++ "("
                    for pi in 0..payload_count:
                        if pi > 0:
                            out = out ++ ", "
                        out = out ++ render_type_expr(pool, intern, (pool.get_extra(ep)) as NodeId)
                        ep = ep + 1
                    out = out ++ ")"
                out = out ++ "\n"
            return out

        return out ++ "<unknown type decl>"

    if kind == NodeKind.NK_USE_DECL:
        let extra_start = pool.get_data0(node)
        let path_count = pool.get_data1(node)
        var out = prefix ++ "use "
        for pi in 0..path_count:
            if pi > 0:
                out = out ++ "."
            out = out ++ intern.resolve(pool.get_extra(extra_start + pi))
        return out

    if kind == NodeKind.NK_LET_DECL:
        let name = intern.resolve(pool.get_data0(node))
        let value = pool.get_data1(node)
        let flags = pool.get_data2(node)
        var out = prefix
        if (flags / 2) % 2 == 1:
            out = out ++ "pub "
        if flags % 2 == 1:
            out = out ++ "var "
        else:
            out = out ++ "let "
        out = out ++ name
        let type_ann = top_level_let_type_ann(pool, flags)
        if type_ann != 0:
            out = out ++ ": " ++ render_type_expr(pool, intern, (type_ann) as NodeId)
        out = out ++ " = " ++ render_expr(pool, intern, (value) as NodeId, 0)
        return out

    if kind == NodeKind.NK_EXTERN_FN:
        let name = intern.resolve(pool.get_data0(node))
        let variadic = pool.get_data2(node) % 2
        var out = prefix ++ "extern fn " ++ name ++ "("
        let meta = pool.find_fn_meta(node)
        var param_count = 0
        if meta >= 0:
            let param_start = pool.fn_meta_param_start(meta)
            param_count = pool.fn_meta_param_count(meta)
            out = out ++ render_params(pool, intern, param_start, param_count)
            if variadic != 0:
                if param_count > 0:
                    out = out ++ ", "
                out = out ++ "..."
            out = out ++ ")"
            let ret_ty = pool.fn_meta_ret(meta)
            if ret_ty != 0:
                out = out ++ " -> " ++ render_type_expr(pool, intern, (ret_ty) as NodeId)
            return out
        if variadic != 0:
            out = out ++ "..."
        return out ++ ")"

    if kind == NodeKind.NK_C_IMPORT:
        let header = intern.resolve(pool.get_data0(node))
        let extra_start = pool.get_data1(node)
        let link_count = pool.get_data2(node)
        var out = prefix ++ "use c_import(\"" ++ header ++ "\""
        if link_count > 0:
            out = out ++ ", link: "
            for li in 0..link_count:
                if li > 0:
                    out = out ++ ", "
                out = out ++ "\"" ++ intern.resolve(pool.get_extra(extra_start + li)) ++ "\""
        return out ++ ")"

    if kind == NodeKind.NK_TRAIT_DECL:
        let name = intern.resolve(pool.get_data0(node))
        let vis = pool.get_data2(node)
        let extra_start = pool.get_data1(node)
        var out = prefix
        if vis == Visibility.Public:
            out = out ++ "pub "
        out = out ++ "trait " ++ name ++ " =\n"

        // Layout:
        // [assoc_count, (name, bound_count, bounds..., default_type)*, method_count, (name, flags, param_start, param_count, ret_type, default_body)*]
        let assoc_count = pool.get_extra(extra_start)
        var ep = extra_start + 1
        for ai in 0..assoc_count:
            out = out ++ make_indent(indent + 4)
            out = out ++ "type " ++ intern.resolve(pool.get_extra(ep))
            ep = ep + 1
            let bound_count = pool.get_extra(ep)
            ep = ep + 1
            if bound_count > 0:
                out = out ++ ": "
                for bi in 0..bound_count:
                    if bi > 0:
                        out = out ++ " + "
                    out = out ++ intern.resolve(pool.get_extra(ep + bi))
                ep = ep + bound_count
            let default_ty = pool.get_extra(ep)
            ep = ep + 1
            if default_ty != 0:
                out = out ++ " = " ++ render_type_expr(pool, intern, (default_ty) as NodeId)
            out = out ++ "\n"

        let method_count = pool.get_extra(ep)
        ep = ep + 1
        for mi in 0..method_count:
            let mname = intern.resolve(pool.get_extra(ep))
            ep = ep + 1
            ep = ep + 1  // flags (currently not rendered)
            let param_start = pool.get_extra(ep)
            ep = ep + 1
            let param_count = pool.get_extra(ep)
            ep = ep + 1
            let ret_ty = pool.get_extra(ep)
            ep = ep + 1
            let default_body = pool.get_extra(ep)
            ep = ep + 1

            out = out ++ make_indent(indent + 4)
            out = out ++ "fn " ++ mname ++ "("
            out = out ++ render_params(pool, intern, param_start, param_count)
            out = out ++ ")"
            if ret_ty != 0:
                out = out ++ " -> " ++ render_type_expr(pool, intern, (ret_ty) as NodeId)
            if default_body != 0:
                out = out ++ ": <default>"
            out = out ++ "\n"

        return out

    if kind == NodeKind.NK_IMPL_DECL:
        let type_name = intern.resolve(pool.get_data0(node))
        let trait_sym = pool.get_data2(node)
        if trait_sym != 0:
            return prefix ++ "impl " ++ intern.resolve(trait_sym) ++ " for " ++ type_name
        return prefix ++ "extend " ++ type_name

    if kind == NodeKind.NK_POISONED_DECL:
        return prefix ++ "<poisoned>"

    prefix ++ "<unknown decl>"

fn render_expr(pool: AstPool, intern: InternPool, node: NodeId, indent: i32) -> str:
    if node == 0:
        return "<null>"

    let kind = pool.kind(node)
    let prefix = if kind == NodeKind.NK_BLOCK: "" else: make_indent(indent)

    if kind == NodeKind.NK_INT_LIT:
        if pool.has_int_literal_exact(node):
            let digits = pool.int_literal_digits(node)
            let radix = pool.int_literal_radix(node)
            if radix == 16:
                return prefix ++ "0x" ++ digits
            if radix == 8:
                return prefix ++ "0o" ++ digits
            if radix == 2:
                return prefix ++ "0b" ++ digits
            return prefix ++ digits
        return f"{prefix}{pool.int_lit_value(node)}"

    if kind == NodeKind.NK_FLOAT_LIT:
        let float_idx = pool.get_data0(node)
        return prefix ++ pool.get_string(float_idx)

    if kind == NodeKind.NK_STRING_LIT:
        return prefix ++ "\"" ++ intern.resolve(pool.get_data0(node)) ++ "\""

    if kind == NodeKind.NK_C_STRING_LIT:
        return prefix ++ "c\"" ++ intern.resolve(pool.get_data0(node)) ++ "\""

    if kind == NodeKind.NK_BOOL_LIT:
        if pool.get_data0(node) != 0:
            return prefix ++ "true"
        return prefix ++ "false"

    if kind == NodeKind.NK_IDENT:
        return prefix ++ intern.resolve(pool.get_data0(node))

    if kind == NodeKind.NK_BINARY:
        let op = pool.get_data0(node)
        let lhs = pool.get_data1(node)
        let rhs = pool.get_data2(node)
        return prefix ++ "(" ++ render_expr(pool, intern, (lhs) as NodeId, 0) ++ " " ++ bin_op_str(op) ++ " " ++ render_expr(pool, intern, (rhs) as NodeId, 0) ++ ")"

    if kind == NodeKind.NK_UNARY:
        let op = pool.get_data0(node)
        let operand = pool.get_data1(node)
        return prefix ++ "(" ++ unary_op_str(op) ++ render_expr(pool, intern, (operand) as NodeId, 0) ++ ")"

    if kind == NodeKind.NK_CALL:
        let callee = pool.get_data0(node)
        let extra_start = pool.get_data1(node)
        let arg_count = pool.get_data2(node)
        var out = prefix ++ render_expr(pool, intern, (callee) as NodeId, 0) ++ "("
        for i in 0..arg_count:
            if i > 0:
                out = out ++ ", "
            out = out ++ render_expr(pool, intern, (pool.get_extra(extra_start + i)) as NodeId, 0)
        return out ++ ")"

    if kind == NodeKind.NK_FIELD_ACCESS:
        let expr = pool.get_data0(node)
        let field = intern.resolve(pool.get_data1(node))
        return prefix ++ render_expr(pool, intern, (expr) as NodeId, 0) ++ "." ++ field

    if kind == NodeKind.NK_COMPUTED_FIELD_ACCESS:
        let expr = pool.get_data0(node)
        let field_expr = pool.get_data1(node)
        return prefix ++ render_expr(pool, intern, (expr) as NodeId, 0) ++ ".{" ++ render_expr(pool, intern, (field_expr) as NodeId, 0) ++ "}"

    if kind == NodeKind.NK_OPTIONAL_CHAIN:
        let expr = pool.get_data0(node)
        let member = intern.resolve(pool.get_data1(node))
        let extra_start = pool.get_data2(node)
        var out = prefix ++ render_expr(pool, intern, (expr) as NodeId, 0) ++ "?." ++ member
        let arg_count = pool.get_extra(extra_start)
        if arg_count > 0:
            out = out ++ "("
            for ai in 0..arg_count:
                if ai > 0:
                    out = out ++ ", "
                out = out ++ render_expr(pool, intern, (pool.get_extra(extra_start + 1 + ai)) as NodeId, 0)
            out = out ++ ")"
        return out

    if kind == NodeKind.NK_INDEX:
        let expr = pool.get_data0(node)
        let idx = pool.get_data1(node)
        return prefix ++ render_expr(pool, intern, (expr) as NodeId, 0) ++ "[" ++ render_expr(pool, intern, (idx) as NodeId, 0) ++ "]"

    if kind == NodeKind.NK_SLICE:
        let expr = pool.get_data0(node)
        let start_expr = pool.get_data1(node)
        let end_expr = pool.get_data2(node)
        var out = prefix ++ render_expr(pool, intern, (expr) as NodeId, 0) ++ "["
        if start_expr != 0:
            out = out ++ render_expr(pool, intern, (start_expr) as NodeId, 0)
        out = out ++ ".."
        if end_expr != 0:
            out = out ++ render_expr(pool, intern, (end_expr) as NodeId, 0)
        return out ++ "]"

    if kind == NodeKind.NK_BLOCK:
        let extra_start = pool.get_data0(node)
        let stmt_count = pool.get_data1(node)
        let tail = pool.get_data2(node)
        var out = ""
        let block_meta = pool.find_block_meta(node)
        let block_label = if block_meta >= 0: pool.block_meta_label(block_meta) else: 0
        var body_indent = indent
        if block_label != 0:
            out = out ++ make_indent(indent) ++ "'" ++ intern.resolve(block_label) ++ ":\n"
            body_indent = indent + 2
        for i in 0..stmt_count:
            out = out ++ render_expr(pool, intern, (pool.get_extra(extra_start + i)) as NodeId, body_indent) ++ "\n"
        if tail != 0:
            out = out ++ render_expr(pool, intern, (tail) as NodeId, body_indent)
        return out

    if kind == NodeKind.NK_LABEL:
        let label = pool.get_data0(node)
        let stmt = pool.get_data1(node)
        if stmt != 0:
            let sk = pool.kind(stmt)
            if sk == NodeKind.NK_WHILE and pool.get_data2(stmt) == label:
                return render_expr(pool, intern, (stmt) as NodeId, indent)
            if sk == NodeKind.NK_LOOP and pool.get_data1(stmt) == label:
                return render_expr(pool, intern, (stmt) as NodeId, indent)
            if sk == NodeKind.NK_FOR:
                let fm = pool.find_for_meta(stmt as NodeId)
                if fm >= 0 and pool.for_meta_label(fm) == label:
                    return render_expr(pool, intern, (stmt) as NodeId, indent)
            if sk == NodeKind.NK_BLOCK:
                let bm = pool.find_block_meta(stmt as NodeId)
                if bm >= 0 and pool.block_meta_label(bm) == label:
                    return render_expr(pool, intern, (stmt) as NodeId, indent)
        return prefix ++ "'" ++ intern.resolve(label) ++ " " ++ render_expr(pool, intern, (stmt) as NodeId, 0)

    if kind == NodeKind.NK_GOTO:
        return prefix ++ "goto '" ++ intern.resolve(pool.get_data0(node))

    if kind == NodeKind.NK_IF_EXPR:
        let cond = pool.get_data0(node)
        let then_body = pool.get_data1(node)
        let else_body = pool.get_data2(node)
        var out = prefix ++ "if " ++ render_expr(pool, intern, (cond) as NodeId, 0) ++ " then " ++ render_expr(pool, intern, (then_body) as NodeId, 0)
        if else_body != 0:
            out = out ++ " else " ++ render_expr(pool, intern, (else_body) as NodeId, 0)
        return out

    if kind == NodeKind.NK_RETURN:
        let value = pool.get_data0(node)
        if value != 0:
            return prefix ++ "return " ++ render_expr(pool, intern, (value) as NodeId, 0)
        return prefix ++ "return"

    if kind == NodeKind.NK_LET_BINDING:
        let name = intern.resolve(pool.get_data0(node))
        let value = pool.get_data1(node)
        let flags = pool.get_data2(node)
        var out = prefix
        if flags % 2 == 1:
            out = out ++ "var "
        else:
            out = out ++ "let "
        out = out ++ name
        let type_ann = local_let_type_ann(pool, flags)
        if type_ann != 0:
            out = out ++ ": " ++ render_type_expr(pool, intern, (type_ann) as NodeId)
        out = out ++ " = " ++ render_expr(pool, intern, (value) as NodeId, 0)
        return out

    if kind == NodeKind.NK_SELECT_AWAIT:
        let extra_start = pool.get_data0(node)
        let arm_count = pool.get_data1(node)
        var out = prefix ++ "select await:\n"
        for ai in 0..arm_count:
            let name_sym = pool.get_extra(extra_start + ai * 3)
            let task = pool.get_extra(extra_start + ai * 3 + 1)
            let body = pool.get_extra(extra_start + ai * 3 + 2)
            out = out ++ "    " ++ intern.resolve(name_sym) ++ " = " ++ render_expr(pool, intern, (task) as NodeId, 0) ++ " -> " ++ render_expr(pool, intern, (body) as NodeId, 0) ++ "\n"
        return out

    if kind == NodeKind.NK_LET_ELSE:
        let pattern = pool.get_data0(node)
        let value = pool.get_data1(node)
        let else_body = pool.get_data2(node)
        return prefix ++ "let " ++ render_pattern(pool, intern, (pattern) as NodeId) ++ " = " ++ render_expr(pool, intern, (value) as NodeId, 0) ++ " else " ++ render_expr(pool, intern, (else_body) as NodeId, 0)

    if kind == NodeKind.NK_TUPLE_DESTRUCTURE:
        let extra_start = pool.get_data0(node)
        let binding_count = pool.get_data1(node)
        let value = pool.get_data2(node)
        var out = prefix ++ "let "
        if binding_count > 0:
            out = out ++ "("
            for bi in 0..binding_count:
                if bi > 0:
                    out = out ++ ", "
                out = out ++ intern.resolve(pool.get_extra(extra_start + bi))
            out = out ++ ")"
        else:
            out = out ++ "(...)"
        out = out ++ " = " ++ render_expr(pool, intern, (value) as NodeId, 0)
        return out

    if kind == NodeKind.NK_ASSIGN:
        let target = pool.get_data0(node)
        let value = pool.get_data1(node)
        return prefix ++ render_expr(pool, intern, (target) as NodeId, 0) ++ " = " ++ render_expr(pool, intern, (value) as NodeId, 0)

    if kind == NodeKind.NK_TUPLE:
        let extra_start = pool.get_data0(node)
        let count = pool.get_data1(node)
        var out = prefix ++ "("
        for i in 0..count:
            if i > 0:
                out = out ++ ", "
            out = out ++ render_expr(pool, intern, (pool.get_extra(extra_start + i)) as NodeId, 0)
        return out ++ ")"

    if kind == NodeKind.NK_RANGE:
        let start_expr = pool.get_data0(node)
        let end_expr = pool.get_data1(node)
        let inclusive = pool.get_data2(node)
        var out = prefix
        if start_expr != 0:
            out = out ++ render_expr(pool, intern, (start_expr) as NodeId, 0)
        if inclusive != 0:
            out = out ++ "..="
        else:
            out = out ++ ".."
        if end_expr != 0:
            out = out ++ render_expr(pool, intern, (end_expr) as NodeId, 0)
        return out

    if kind == NodeKind.NK_VARIANT_SHORTHAND:
        let name = intern.resolve(pool.get_data0(node))
        let extra_start = pool.get_data1(node)
        let arg_count = pool.get_data2(node)
        var out = prefix ++ "." ++ name
        if arg_count > 0:
            out = out ++ "("
            for ai in 0..arg_count:
                if ai > 0:
                    out = out ++ ", "
                out = out ++ render_expr(pool, intern, (pool.get_extra(extra_start + ai)) as NodeId, 0)
            out = out ++ ")"
        return out

    if kind == NodeKind.NK_AWAIT:
        let inner = pool.get_data0(node)
        return prefix ++ render_expr(pool, intern, (inner) as NodeId, 0) ++ ".await"

    if kind == NodeKind.NK_ASYNC_BLOCK:
        let body = pool.get_data0(node)
        return prefix ++ "async:\n" ++ render_expr(pool, intern, (body) as NodeId, indent + 2)

    if kind == NodeKind.NK_SPAWN:
        let inner = pool.get_data0(node)
        return prefix ++ "spawn " ++ render_expr(pool, intern, (inner) as NodeId, 0)

    if kind == NodeKind.NK_COMPTIME:
        let inner = pool.get_data0(node)
        return prefix ++ "comptime " ++ render_expr(pool, intern, (inner) as NodeId, 0)

    if kind == NodeKind.NK_ASYNC_SCOPE:
        let name = intern.resolve(pool.get_data0(node))
        let body = pool.get_data1(node)
        return prefix ++ "async scope |" ++ name ++ "|:\n" ++ render_expr(pool, intern, (body) as NodeId, indent + 2)

    if kind == NodeKind.NK_PIPELINE:
        let lhs = pool.get_data0(node)
        let rhs = pool.get_data1(node)
        return prefix ++ render_expr(pool, intern, (lhs) as NodeId, 0) ++ " |> " ++ render_expr(pool, intern, (rhs) as NodeId, 0)

    if kind == NodeKind.NK_BREAK:
        let value = pool.get_data0(node)
        let label = pool.get_data1(node)
        var out = prefix ++ "break"
        if label != 0:
            out = out ++ " '" ++ intern.resolve(label)
        if value != 0:
            out = out ++ " " ++ render_expr(pool, intern, (value) as NodeId, 0)
        return out

    if kind == NodeKind.NK_CONTINUE:
        let label = pool.get_data0(node)
        var out = prefix ++ "continue"
        if label != 0:
            out = out ++ " '" ++ intern.resolve(label)
        return out

    if kind == NodeKind.NK_LOOP:
        let body = pool.get_data0(node)
        let label = pool.get_data1(node)
        var out = prefix
        if label != 0:
            out = out ++ "'" ++ intern.resolve(label) ++ " "
        return out ++ "loop:\n" ++ render_expr(pool, intern, (body) as NodeId, indent + 2)

    if kind == NodeKind.NK_FOR:
        let binding = pool.get_data0(node)
        let iterable = pool.get_data1(node)
        let body = pool.get_data2(node)
        let for_meta = pool.find_for_meta(node)
        let label = if for_meta >= 0: pool.for_meta_label(for_meta) else: 0
        var out = prefix
        if label != 0:
            out = out ++ "'" ++ intern.resolve(label) ++ " "
        out = out ++ "for "
        if pool.for_binding_is_pattern(node):
            out = out ++ render_pattern(pool, intern, (binding) as NodeId)
        else:
            out = out ++ intern.resolve(binding)
        out = out ++ " in " ++ render_expr(pool, intern, (iterable) as NodeId, 0) ++ ":\n"
        out = out ++ render_expr(pool, intern, (body) as NodeId, indent + 2)
        return out

    if kind == NodeKind.NK_WHILE:
        let cond = pool.get_data0(node)
        let body = pool.get_data1(node)
        let label = pool.get_data2(node)
        var out = prefix
        if label != 0:
            out = out ++ "'" ++ intern.resolve(label) ++ " "
        return out ++ "while " ++ render_expr(pool, intern, (cond) as NodeId, 0) ++ ":\n" ++ render_expr(pool, intern, (body) as NodeId, indent + 2)

    if kind == NodeKind.NK_ARRAY_LIT:
        let extra_start = pool.get_data0(node)
        let count = pool.get_data1(node)
        var out = prefix ++ "["
        for i in 0..count:
            if i > 0:
                out = out ++ ", "
            out = out ++ render_expr(pool, intern, (pool.get_extra(extra_start + i)) as NodeId, 0)
        return out ++ "]"

    if kind == NodeKind.NK_ARRAY_COMPREHENSION:
        let expr = pool.get_data0(node)
        let binding = pool.get_data1(node)
        let iterable = pool.get_data2(node)
        var out = prefix ++ "[" ++ render_expr(pool, intern, (expr) as NodeId, 0)
        out = out ++ " for " ++ intern.resolve(binding) ++ " in " ++ render_expr(pool, intern, (iterable) as NodeId, 0)
        return out ++ "]"

    if kind == NodeKind.NK_STRUCT_LIT:
        let name = intern.resolve(pool.get_data0(node))
        let extra_start = pool.get_data1(node)
        let field_count = pool.get_data2(node)
        var out = prefix ++ name ++ " " ++ render_lbrace() ++ " "
        for fi in 0..field_count:
            if fi > 0:
                out = out ++ ", "
            let field_name = intern.resolve(pool.get_extra(extra_start + fi * 2))
            let field_val = pool.get_extra(extra_start + fi * 2 + 1)
            out = out ++ field_name ++ ": " ++ render_expr(pool, intern, (field_val) as NodeId, 0)
        return out ++ " " ++ render_rbrace()

    if kind == NodeKind.NK_GROUPED:
        let inner = pool.get_data0(node)
        return prefix ++ "(" ++ render_expr(pool, intern, (inner) as NodeId, 0) ++ ")"

    if kind == NodeKind.NK_MATCH:
        let subject = pool.get_data0(node)
        let extra_start = pool.get_data1(node)
        let arm_count = pool.get_data2(node)
        var out = prefix ++ "match " ++ render_expr(pool, intern, (subject) as NodeId, 0) ++ ":\n"
        for ai in 0..arm_count:
            let arm = pool.get_extra(extra_start + ai)
            let pattern = pool.get_data0(arm)
            let body = pool.get_data1(arm)
            let guard = pool.get_data2(arm)
            out = out ++ make_indent(indent + 2)
            out = out ++ render_pattern(pool, intern, (pattern) as NodeId)
            if guard != 0:
                out = out ++ " if " ++ render_expr(pool, intern, (guard) as NodeId, 0)
            out = out ++ " -> " ++ render_expr(pool, intern, (body) as NodeId, 0) ++ "\n"
        return out

    if kind == NodeKind.NK_CAST:
        let expr = pool.get_data0(node)
        let target = pool.get_data1(node)
        return prefix ++ render_expr(pool, intern, (expr) as NodeId, 0) ++ " as " ++ render_type_expr(pool, intern, (target) as NodeId)

    if kind == NodeKind.NK_DEFER:
        let body = pool.get_data0(node)
        return prefix ++ "defer " ++ render_expr(pool, intern, (body) as NodeId, 0)

    if kind == NodeKind.NK_ERRDEFER:
        let body = pool.get_data0(node)
        return prefix ++ "errdefer " ++ render_expr(pool, intern, (body) as NodeId, 0)

    if kind == NodeKind.NK_CLOSURE:
        let body = pool.get_data0(node)
        let extra_start = pool.get_data1(node)
        let param_count = pool.get_data2(node)
        var out = prefix ++ "|"
        for pi in 0..param_count:
            if pi > 0:
                out = out ++ ", "
            let p_name = pool.get_extra(extra_start + pi * 2)
            let p_type = pool.get_extra(extra_start + pi * 2 + 1)
            out = out ++ intern.resolve(p_name)
            if p_type != 0:
                out = out ++ ": " ++ render_type_expr(pool, intern, (p_type) as NodeId)
        out = out ++ "| " ++ render_expr(pool, intern, (body) as NodeId, 0)
        return out

    if kind == NodeKind.NK_ENUM_VARIANT:
        let type_name = intern.resolve(pool.get_data0(node))
        let variant_name = intern.resolve(pool.get_data1(node))
        let extra_start = pool.get_data2(node)
        var out = prefix ++ type_name ++ "." ++ variant_name
        if extra_start != 0:
            let arg_count = pool.get_extra(extra_start)
            if arg_count > 0:
                out = out ++ "("
                for ai in 0..arg_count:
                    if ai > 0:
                        out = out ++ ", "
                    out = out ++ render_expr(pool, intern, (pool.get_extra(extra_start + 1 + ai)) as NodeId, 0)
                out = out ++ ")"
        return out

    if kind == NodeKind.NK_WITH_EXPR:
        let source = pool.get_data0(node)
        let body = pool.get_data1(node)
        let encoded = pool.get_data2(node)
        let name = intern.resolve(decode_with_binding_sym(encoded))
        let is_mut = decode_with_binding_is_mut(encoded)
        var out = prefix ++ "with " ++ render_expr(pool, intern, (source) as NodeId, 0)
        if is_mut != 0:
            out = out ++ " as mut " ++ name ++ ":\n"
        else:
            out = out ++ " as " ++ name ++ ":\n"
        out = out ++ render_expr(pool, intern, (body) as NodeId, indent + 2)
        return out

    if kind == NodeKind.NK_WITH_IMPLICIT:
        let wi_source = pool.get_data0(node)
        let wi_body = pool.get_data1(node)
        let wi_name = intern.resolve(pool.get_data2(node))
        var wi_out = prefix ++ "with " ++ render_expr(pool, intern, (wi_source) as NodeId, 0)
        wi_out = wi_out ++ " as " ++ wi_name ++ ":\n"
        wi_out = wi_out ++ render_expr(pool, intern, (wi_body) as NodeId, indent + 2)
        return wi_out

    if kind == NodeKind.NK_RECORD_UPDATE:
        let source = pool.get_data0(node)
        let extra_start = pool.get_data1(node)
        let field_count = pool.get_data2(node)
        var out = prefix ++ render_lbrace() ++ " " ++ render_expr(pool, intern, (source) as NodeId, 0) ++ " with "
        for fi in 0..field_count:
            if fi > 0:
                out = out ++ ", "
            let fname = intern.resolve(pool.get_extra(extra_start + fi * 2))
            let fval = pool.get_extra(extra_start + fi * 2 + 1)
            out = out ++ fname ++ ": " ++ render_expr(pool, intern, (fval) as NodeId, 0)
        return out ++ " " ++ render_rbrace()

    if kind == NodeKind.NK_YIELD:
        let value = pool.get_data0(node)
        return prefix ++ "yield " ++ render_expr(pool, intern, (value) as NodeId, 0)

    if kind == NodeKind.NK_POISONED_EXPR:
        return prefix ++ "<poisoned>"

    f"{prefix}<expr:{kind}>"

fn render_pattern(pool: AstPool, intern: InternPool, node: NodeId) -> str:
    if node == 0:
        return "_"
    let kind = pool.kind(node)

    if kind == NodeKind.NK_PAT_WILDCARD:
        return "_"

    if kind == NodeKind.NK_PAT_IDENT:
        return intern.resolve(pool.get_data0(node))

    if kind == NodeKind.NK_PAT_INT:
        return f"{pool.int_lit_value(node)}"

    if kind == NodeKind.NK_PAT_BOOL:
        if pool.get_data0(node) != 0:
            return "true"
        return "false"

    if kind == NodeKind.NK_PAT_STRING:
        return "\"" ++ intern.resolve(pool.get_data0(node)) ++ "\""

    if kind == NodeKind.NK_PAT_VARIANT:
        let name = intern.resolve(pool.get_data0(node))
        let qualifier = pool.pattern_qualifier(node)
        let extra_start = pool.get_data1(node)
        let binding_count = pool.get_data2(node)
        var out = if qualifier != 0: intern.resolve(qualifier) ++ "." ++ name else: name
        if binding_count > 0:
            out = out ++ "("
            for bi in 0..binding_count:
                if bi > 0:
                    out = out ++ ", "
                let item = pool.get_extra(extra_start + bi)
                if is_pattern_node(pool, (item) as NodeId):
                    out = out ++ render_pattern(pool, intern, (item) as NodeId)
                else:
                    out = out ++ intern.resolve(item)
            out = out ++ ")"
        return out

    if kind == NodeKind.NK_PAT_ENUM_SHORTHAND:
        let name = intern.resolve(pool.get_data0(node))
        let extra_start = pool.get_data1(node)
        let binding_count = pool.get_data2(node)
        var out = "." ++ name
        if binding_count > 0:
            out = out ++ "("
            for bi in 0..binding_count:
                if bi > 0:
                    out = out ++ ", "
                let item = pool.get_extra(extra_start + bi)
                if is_pattern_node(pool, (item) as NodeId):
                    out = out ++ render_pattern(pool, intern, (item) as NodeId)
                else:
                    out = out ++ intern.resolve(item)
            out = out ++ ")"
        return out

    if kind == NodeKind.NK_PAT_TUPLE:
        let extra_start = pool.get_data0(node)
        let count = pool.get_data1(node)
        var out = "("
        for i in 0..count:
            if i > 0:
                out = out ++ ", "
            out = out ++ render_pattern(pool, intern, (pool.get_extra(extra_start + i)) as NodeId)
        return out ++ ")"

    if kind == NodeKind.NK_PAT_RANGE:
        let start_val = pool.get_data0(node)
        let end_val = pool.get_data1(node)
        if pool.get_data2(node) != 0:
            return f"{start_val}..={end_val}"
        return f"{start_val}..{end_val}"

    if kind == NodeKind.NK_PAT_OR:
        let extra_start = pool.get_data0(node)
        let count = pool.get_data1(node)
        var out = ""
        for i in 0..count:
            if i > 0:
                out = out ++ " | "
            out = out ++ render_pattern(pool, intern, (pool.get_extra(extra_start + i)) as NodeId)
        return out

    if kind == NodeKind.NK_PAT_AT_BINDING:
        let name = intern.resolve(pool.get_data0(node))
        let inner = pool.get_data1(node)
        return name ++ " @ " ++ render_pattern(pool, intern, (inner) as NodeId)

    if kind == NodeKind.NK_PAT_SLICE:
        let extra_start = pool.get_data0(node)
        let head_count = pool.get_data1(node)
        let rest_sym = pool.get_data2(node)
        let has_rest = pool.get_extra(extra_start)
        var out = "["
        for hi in 0..head_count:
            if hi > 0:
                out = out ++ ", "
            out = out ++ intern.resolve(pool.get_extra(extra_start + 1 + hi))
        if has_rest != 0:
            if head_count > 0:
                out = out ++ ", "
            out = out ++ ".."
            if rest_sym != 0:
                out = out ++ intern.resolve(rest_sym)
        return out ++ "]"

    if kind == NodeKind.NK_PAT_STRUCT:
        let type_name = pool.get_data0(node)
        let extra_start = pool.get_data1(node)
        let field_count = pool.get_data2(node)
        let has_rest = pool.get_extra(extra_start + field_count * 2)
        var out = ""
        if type_name != 0:
            out = out ++ intern.resolve(type_name) ++ " "
        out = out ++ render_lbrace() ++ " "
        for fi in 0..field_count:
            if fi > 0:
                out = out ++ ", "
            let fname = intern.resolve(pool.get_extra(extra_start + fi * 2))
            let fpat = pool.get_extra(extra_start + fi * 2 + 1)
            out = out ++ fname
            if fpat != 0:
                out = out ++ ": " ++ render_pattern(pool, intern, (fpat) as NodeId)
        if has_rest != 0:
            if field_count > 0:
                out = out ++ ", "
            out = out ++ ".."
        return out ++ " " ++ render_rbrace()

    f"<pat:{kind}>"

fn render_type_expr(pool: AstPool, intern: InternPool, node: NodeId) -> str:
    if node == 0:
        return "_"
    let kind = pool.kind(node)

    if kind == NodeKind.NK_TYPE_NAMED:
        return intern.resolve(pool.get_data0(node))

    if kind == NodeKind.NK_TYPE_GENERIC:
        let name = intern.resolve(pool.get_data0(node))
        let extra_start = pool.get_data1(node)
        let arg_count = pool.get_data2(node)
        var out = name ++ "["
        for i in 0..arg_count:
            if i > 0:
                out = out ++ ", "
            out = out ++ render_type_expr(pool, intern, (pool.get_extra(extra_start + i)) as NodeId)
        return out ++ "]"

    if kind == NodeKind.NK_TYPE_REF:
        let pointee = pool.get_data0(node)
        let is_mut = pool.get_data1(node)
        if is_mut != 0:
            return "&mut " ++ render_type_expr(pool, intern, (pointee) as NodeId)
        return "&" ++ render_type_expr(pool, intern, (pointee) as NodeId)

    if kind == NodeKind.NK_TYPE_PTR:
        let pointee = pool.get_data0(node)
        let is_mut = pool.get_data1(node)
        if is_mut != 0:
            return "*mut " ++ render_type_expr(pool, intern, (pointee) as NodeId)
        return "*const " ++ render_type_expr(pool, intern, (pointee) as NodeId)

    if kind == NodeKind.NK_TYPE_FN:
        let extra_start = pool.get_data0(node)
        let param_count = pool.get_data1(node)
        let ret = pool.get_data2(node)
        var out = "fn("
        for pi in 0..param_count:
            if pi > 0:
                out = out ++ ", "
            out = out ++ render_type_expr(pool, intern, (pool.get_extra(extra_start + pi)) as NodeId)
        out = out ++ ") -> " ++ render_type_expr(pool, intern, (ret) as NodeId)
        return out

    if kind == NodeKind.NK_TYPE_TUPLE:
        let extra_start = pool.get_data0(node)
        let count = pool.get_data1(node)
        var out = "("
        for ti in 0..count:
            if ti > 0:
                out = out ++ ", "
            out = out ++ render_type_expr(pool, intern, (pool.get_extra(extra_start + ti)) as NodeId)
        return out ++ ")"

    if kind == NodeKind.NK_TYPE_OPTIONAL:
        let inner = pool.get_data0(node)
        return "?" ++ render_type_expr(pool, intern, (inner) as NodeId)

    if kind == NodeKind.NK_TYPE_ARRAY:
        let elem = pool.get_data0(node)
        let size = pool.get_data1(node)
        return f"[{size}]{render_type_expr(pool, intern, (elem) as NodeId)}"

    if kind == NodeKind.NK_TYPE_SLICE:
        let elem = pool.get_data0(node)
        return "[]" ++ render_type_expr(pool, intern, (elem) as NodeId)

    if kind == NodeKind.NK_TYPE_TRAIT_OBJ:
        return "dyn " ++ intern.resolve(pool.get_data0(node))

    if kind == NodeKind.NK_TYPE_INFERRED:
        return "_"

    f"<type:{kind}>"

fn render_type_params(pool: AstPool, intern: InternPool, tp_start: i32, tp_count: i32) -> str:
    var out = "["
    var cursor = tp_start
    for i in 0..tp_count:
        if i > 0:
            out = out ++ ", "
        let name_sym = pool.get_extra(cursor)
        let bound_count = pool.get_extra(cursor + 1)
        cursor = cursor + 2
        out = out ++ intern.resolve(name_sym)
        if bound_count > 0:
            out = out ++ ": "
            for bi in 0..bound_count:
                if bi > 0:
                    out = out ++ " + "
                out = out ++ intern.resolve(pool.get_extra(cursor + bi))
            cursor = cursor + bound_count
    out ++ "]"

fn render_params(pool: AstPool, intern: InternPool, param_start: i32, param_count: i32) -> str:
    var out = ""
    for i in 0..param_count:
        if i > 0:
            out = out ++ ", "
        let flags = pool.fn_param_flags(param_start, i)
        let name_sym = pool.fn_param_name(param_start, i)
        let type_node = pool.fn_param_type(param_start, i)
        if fn_param_is_noalias(flags) != 0:
            out = out ++ "@[noalias] "
        out = out ++ intern.resolve(name_sym)
        if type_node != 0:
            out = out ++ ": " ++ render_type_expr(pool, intern, (type_node) as NodeId)
    out

fn has_flag(flags: i32, bit: i32) -> bool:
    (flags / bit) % 2 == 1

fn type_decl_is_pub(pool: AstPool, extra_start: i32, sub_kind: i32) -> bool:
    if sub_kind == TypeDeclKind.Struct:
        let field_count = pool.get_extra(extra_start)
        let vis_idx = extra_start + 1 + field_count * 4
        return pool.get_extra(vis_idx) == Visibility.Public
    if sub_kind == TypeDeclKind.Enum:
        var ep = extra_start + 1
        let variant_count = pool.get_extra(extra_start)
        for vi in 0..variant_count:
            ep = ep + 1  // name
            let payload_count = pool.get_extra(ep)
            ep = ep + 1 + payload_count
        return pool.get_extra(ep) == Visibility.Public
    if sub_kind == TypeDeclKind.DiscEnum:
        var ep = extra_start + 2 // skip repr_type_node, get variant_count
        let variant_count = pool.get_extra(extra_start + 1)
        for vi in 0..variant_count:
            ep = ep + 1  // name
            ep = ep + 1  // disc value
            let payload_count = pool.get_extra(ep)
            ep = ep + 1 + payload_count
        return pool.get_extra(ep) == Visibility.Public
    // Alias / distinct: [aliased_type, vis]
    return pool.get_extra(extra_start + 1) == Visibility.Public

fn top_level_let_type_ann(pool: AstPool, flags: i32) -> i32:
    let encoded = flags / 16
    if encoded > 0:
        return pool.get_extra(encoded - 1)
    0

fn local_let_type_ann(pool: AstPool, flags: i32) -> i32:
    let encoded = flags / 2
    if encoded > 0:
        return pool.get_extra(encoded - 1)
    0

fn is_pattern_node(pool: AstPool, node: NodeId) -> bool:
    pool.is_pattern_node(node as i32)

fn is_pattern_kind(kind: i32) -> bool:
    ast_is_pattern_kind(kind)

fn bin_op_str(op: i32) -> str:
    if op == BinaryOp.OP_ADD: return "+"
    if op == BinaryOp.OP_SUB: return "-"
    if op == BinaryOp.OP_MUL: return "*"
    if op == BinaryOp.OP_DIV: return "/"
    if op == BinaryOp.OP_MOD: return "%"
    if op == BinaryOp.OP_EQ: return "=="
    if op == BinaryOp.OP_NEQ: return "!="
    if op == BinaryOp.OP_LT: return "<"
    if op == BinaryOp.OP_GT: return ">"
    if op == BinaryOp.OP_LTE: return "<="
    if op == BinaryOp.OP_GTE: return ">="
    if op == BinaryOp.OP_AND: return "and"
    if op == BinaryOp.OP_OR: return "or"
    if op == BinaryOp.OP_BIT_AND: return "&"
    if op == BinaryOp.OP_BIT_OR: return "|"
    if op == BinaryOp.OP_BIT_XOR: return "^"
    if op == BinaryOp.OP_SHL: return "<<"
    if op == BinaryOp.OP_SHR: return ">>"
    if op == BinaryOp.OP_DEFAULT: return "??"
    if op == BinaryOp.OP_CONCAT: return "++"
    if op == BinaryOp.OP_ADD_WRAP: return "+%"
    if op == BinaryOp.OP_SUB_WRAP: return "-%"
    if op == BinaryOp.OP_MUL_WRAP: return "*%"
    if op == BinaryOp.OP_ADD_SAT: return "+|"
    if op == BinaryOp.OP_SUB_SAT: return "-|"
    if op == BinaryOp.OP_MUL_SAT: return "*|"
    if op == BinaryOp.OP_IN: return "in"
    if op == BinaryOp.OP_NOT_IN: return "not in"
    "?op?"

fn unary_op_str(op: i32) -> str:
    if op == UnaryOp.UOP_NEGATE: return "-"
    if op == UnaryOp.UOP_NOT: return "not "
    if op == UnaryOp.UOP_REF: return "&"
    if op == UnaryOp.UOP_MUT_REF: return "&mut "
    if op == UnaryOp.UOP_RAW_REF_CONST: return "&raw const "
    if op == UnaryOp.UOP_RAW_REF_MUT: return "&raw mut "
    if op == UnaryOp.UOP_DEREF: return "*"
    if op == UnaryOp.UOP_TRY: return "?"
    "?uop?"

fn make_indent(n: i32) -> str:
    var out = ""
    for i in 0..n:
        out = out ++ " "
    out

fn render_lbrace -> str:
    str_from_byte(123)

fn render_rbrace -> str:
    str_from_byte(125)
