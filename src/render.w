// render — AST pretty-printer for deterministic dump output.
//
// This mirrors Stage0's render surface, adapted to AstPool indices.

use Ast
use Token
use InternPool
use std.string.StringBuilder


extern fn str_from_byte(b: i32) -> str
extern fn with_str_clone_ref(s: &str) -> str

fn render_module(pool: AstPool, intern: InternPool) -> str:
    var out = StringBuilder.new()
    for i in 0..pool.decl_count():
        let decl = pool.get_decl(i)
        out.push_str(render_decl(pool, intern, (decl) as NodeId, 0))
        out.push_str("\n")
    out.to_str()

fn render_decl(pool: AstPool, intern: InternPool, node: NodeId, indent: i32) -> str:
    let kind = pool.kind(node)
    let prefix = make_indent(indent)

    if kind == NodeKind.NK_FN_DECL:
        let name = intern.resolve(pool.get_data0(node))
        let flags = pool.get_data2(node)
        let body = pool.get_data1(node)
        var out = StringBuilder.new()
        out.push_str(prefix)
        if has_flag(flags, FnFlags.PUB):
            out.push_str("pub ")
        if has_flag(flags, FnFlags.ASYNC):
            out.push_str("async ")
        if has_flag(flags, FnFlags.GEN):
            out.push_str("gen ")
        out.push_str("fn " ++ name)

        let meta = pool.find_fn_meta(node)
        if meta >= 0:
            let tp_start = pool.fn_meta_tp_start(meta)
            let tp_count = pool.fn_meta_tp_count(meta)
            if tp_count > 0:
                out.push_str(render_type_params(pool, intern, tp_start, tp_count))

            let param_start = pool.fn_meta_param_start(meta)
            let param_count = pool.fn_meta_param_count(meta)
            if param_count > 0:
                out.push_str("(" ++ render_params(pool, intern, param_start, param_count) ++ ")")

            let ret_ty = pool.fn_meta_ret(meta)
            if ret_ty != 0:
                out.push_str(" -> " ++ render_type_expr(pool, intern, (ret_ty) as NodeId))

        out.push_str(":\n")
        out.push_str(render_expr(pool, intern, (body) as NodeId, indent + 2))
        return out.to_str()

    if kind == NodeKind.NK_TYPE_DECL:
        let name = intern.resolve(pool.get_data0(node))
        let extra_start = pool.get_data1(node)
        let packed_kind = pool.get_data2(node)
        let sub_kind = type_decl_sub_kind(packed_kind)
        let is_ephemeral = type_decl_is_ephemeral(packed_kind)
        var out = StringBuilder.new()
        out.push_str(with_str_clone_ref(prefix))

        if type_decl_is_specified(packed_kind) != 0:
            out.push_str("@[specified]\n" ++ prefix)
        if type_decl_is_pub(pool, extra_start, sub_kind):
            out.push_str("pub ")
        if is_ephemeral != 0:
            out.push_str("type " ++ name ++ " ephemeral ")
        else if sub_kind == TypeDeclKind.Enum or sub_kind == TypeDeclKind.DiscEnum:
            out.push_str("enum " ++ name)
        else:
            out.push_str("type " ++ name)

        if sub_kind == TypeDeclKind.Struct:
            let field_count = pool.get_extra(extra_start)
            var ep = extra_start + 1
            out.push_str(" " ++ render_lbrace() ++ " ")
            for fi in 0..field_count:
                if fi > 0:
                    out.push_str(", ")
                let field_name = intern.resolve(pool.get_extra(ep))
                let field_type = pool.get_extra(ep + 1)
                let field_default = pool.get_extra(ep + 2)
                ep = ep + 3
                out.push_str(field_name ++ ": " ++ render_type_expr(pool, intern, (field_type) as NodeId))
                if field_default != 0:
                    out.push_str(" = " ++ render_expr(pool, intern, (field_default) as NodeId, 0))
            out.push_str(" " ++ render_rbrace())
            return out.to_str()

        if sub_kind == TypeDeclKind.Alias:
            let aliased = pool.get_extra(extra_start)
            out.push_str(" = " ++ render_type_expr(pool, intern, (aliased) as NodeId))
            return out.to_str()

        if sub_kind == TypeDeclKind.Distinct:
            let aliased = pool.get_extra(extra_start)
            out.push_str(" = distinct " ++ render_type_expr(pool, intern, (aliased) as NodeId))
            return out.to_str()

        if sub_kind == TypeDeclKind.Enum:
            let variant_count = pool.get_extra(extra_start)
            var ep = extra_start + 1
            out.push_str(":\n")
            for vi in 0..variant_count:
                out.push_str(make_indent(indent + 2))
                let vname = intern.resolve(pool.get_extra(ep))
                ep = ep + 1
                let payload_count = pool.get_extra(ep)
                ep = ep + 1
                out.push_str(vname)
                if payload_count > 0:
                    out.push_str("(")
                    for pi in 0..payload_count:
                        if pi > 0:
                            out.push_str(", ")
                        out.push_str(render_type_expr(pool, intern, (pool.get_extra(ep)) as NodeId))
                        ep = ep + 1
                    out.push_str(")")
                out.push_str("\n")
            return out.to_str()

        if sub_kind == TypeDeclKind.DiscEnum:
            let repr_node = pool.get_extra(extra_start)
            let variant_count = pool.get_extra(extra_start + 1)
            var ep = extra_start + 2
            out.push_str(": " ++ render_type_expr(pool, intern, (repr_node) as NodeId) ++ ":\n")
            for vi in 0..variant_count:
                out.push_str(make_indent(indent + 2))
                let vname = intern.resolve(pool.get_extra(ep))
                ep = ep + 1
                // The explicit `= N` node, 0 when the value is auto-incremented.
                let disc_node = pool.get_extra(ep)
                ep = ep + 1
                let payload_count = pool.get_extra(ep)
                ep = ep + 1
                out.push_str(vname)
                if disc_node != 0:
                    out.push_str(" = " ++ render_expr(pool, intern, disc_node as NodeId, 0))
                if payload_count > 0:
                    out.push_str("(")
                    for pi in 0..payload_count:
                        if pi > 0:
                            out.push_str(", ")
                        out.push_str(render_type_expr(pool, intern, (pool.get_extra(ep)) as NodeId))
                        ep = ep + 1
                    out.push_str(")")
                out.push_str("\n")
            return out.to_str()

        return out.to_str() ++ "<unknown type decl>"

    if kind == NodeKind.NK_USE_DECL:
        let extra_start = pool.get_data0(node)
        let path_count = pool.get_data1(node)
        var out = StringBuilder.new()
        out.push_str(prefix ++ "use ")
        for pi in 0..path_count:
            if pi > 0:
                out.push_str(".")
            out.push_str(intern.resolve(pool.get_extra(extra_start + pi)))
        return out.to_str()

    if kind == NodeKind.NK_LET_DECL:
        let name = intern.resolve(pool.get_data0(node))
        let value = pool.get_data1(node)
        let flags = pool.get_data2(node)
        var out = StringBuilder.new()
        out.push_str(prefix)
        if (flags / 2) % 2 == 1:
            out.push_str("pub ")
        if flags % 2 == 1:
            out.push_str("var ")
        else:
            out.push_str("let ")
        out.push_str(name)
        let type_ann = top_level_let_type_ann(pool, flags)
        if type_ann != 0:
            out.push_str(": " ++ render_type_expr(pool, intern, (type_ann) as NodeId))
        out.push_str(" = " ++ render_expr(pool, intern, (value) as NodeId, 0))
        return out.to_str()

    if kind == NodeKind.NK_EXTERN_FN:
        let name = intern.resolve(pool.get_data0(node))
        let variadic = pool.get_data2(node) % 2
        var out = StringBuilder.new()
        out.push_str(prefix ++ "extern fn " ++ name ++ "(")
        let meta = pool.find_fn_meta(node)
        var param_count = 0
        if meta >= 0:
            let param_start = pool.fn_meta_param_start(meta)
            param_count = pool.fn_meta_param_count(meta)
            out.push_str(render_params(pool, intern, param_start, param_count))
            if variadic != 0:
                if param_count > 0:
                    out.push_str(", ")
                out.push_str("...")
            out.push_str(")")
            let ret_ty = pool.fn_meta_ret(meta)
            if ret_ty != 0:
                out.push_str(" -> " ++ render_type_expr(pool, intern, (ret_ty) as NodeId))
            return out.to_str()
        if variadic != 0:
            out.push_str("...")
        return out.to_str() ++ ")"

    if kind == NodeKind.NK_C_IMPORT:
        let header = intern.resolve(pool.get_data0(node))
        let extra_start = pool.get_data1(node)
        let packed_counts = pool.get_data2(node)
        let link_count = c_import_link_count(packed_counts)
        let allow_count = c_import_allow_count(packed_counts)
        var out = StringBuilder.new()
        out.push_str(prefix ++ "use c_import(\"" ++ header ++ "\"")
        if link_count > 0:
            out.push_str(", link: ")
            for li in 0..link_count:
                if li > 0:
                    out.push_str(", ")
                out.push_str("\"" ++ intern.resolve(pool.get_extra(extra_start + li)) ++ "\"")
        if allow_count > 0:
            out.push_str(", allow_untranslated: [")
            for ai in 0..allow_count:
                if ai > 0:
                    out.push_str(", ")
                out.push_str("\"" ++ intern.resolve(pool.get_extra(extra_start + link_count + ai)) ++ "\"")
            out.push_str("]")
        if c_import_no_methods_all(packed_counts) != 0:
            out.push_str(", no_methods: true")
        else:
            let nm_count = c_import_no_methods_count(packed_counts)
            if nm_count > 0:
                out.push_str(", no_methods: [")
                for ni in 0..nm_count:
                    if ni > 0:
                        out.push_str(", ")
                    out.push_str("\"" ++ intern.resolve(pool.get_extra(extra_start + link_count + allow_count + ni)) ++ "\"")
                out.push_str("]")
        return out.to_str() ++ ")"

    if kind == NodeKind.NK_TRAIT_DECL:
        let name = intern.resolve(pool.get_data0(node))
        let vis = pool.get_data2(node)
        let extra_start = pool.get_data1(node)
        var out = StringBuilder.new()
        out.push_str(prefix)
        if vis == Visibility.Public:
            out.push_str("pub ")
        out.push_str("trait " ++ name)

        let tp_count = pool.get_extra(extra_start)
        let tp_start = pool.get_extra(extra_start + 1)
        if tp_count > 0:
            out.push_str("[")
            var tp_pos = tp_start
            for ti in 0..tp_count:
                if ti > 0: out.push_str(", ")
                out.push_str(intern.resolve(pool.get_extra(tp_pos)))
                let bound_count = pool.get_extra(tp_pos + 1)
                if bound_count > 0:
                    out.push_str(": ")
                    for bi in 0..bound_count:
                        if bi > 0: out.push_str(" + ")
                        out.push_str(intern.resolve(pool.get_extra(tp_pos + 2 + bi)))
                tp_pos = tp_pos + 2 + bound_count
            out.push_str("]")
        out.push_str(":\n")

        let assoc_count = pool.trait_assoc_count(node)
        var ep = pool.trait_assoc_start(node)
        for ai in 0..assoc_count:
            out.push_str(make_indent(indent + 4))
            out.push_str("type " ++ intern.resolve(pool.get_extra(ep)))
            ep = ep + 1
            let bound_count = pool.get_extra(ep)
            ep = ep + 1
            if bound_count > 0:
                out.push_str(": ")
                for bi in 0..bound_count:
                    if bi > 0:
                        out.push_str(" + ")
                    out.push_str(intern.resolve(pool.get_extra(ep + bi)))
                ep = ep + bound_count
            let default_ty = pool.get_extra(ep)
            ep = ep + 1
            if default_ty != 0:
                out.push_str(" = " ++ render_type_expr(pool, intern, (default_ty) as NodeId))
            out.push_str("\n")

        let method_count = pool.trait_method_count(node)
        for mi in 0..method_count:
            let mname = intern.resolve(pool.trait_method_field(node, mi, TRAIT_METHOD_NAME))
            let param_start = pool.trait_method_field(node, mi, TRAIT_METHOD_PARAM_START)
            let param_count = pool.trait_method_field(node, mi, TRAIT_METHOD_PARAM_COUNT)
            let ret_ty = pool.trait_method_field(node, mi, TRAIT_METHOD_RETURN_TYPE)
            let default_body = pool.trait_method_field(node, mi, TRAIT_METHOD_DEFAULT_BODY)

            out.push_str(make_indent(indent + 4))
            out.push_str("fn " ++ mname ++ "(")
            out.push_str(render_params(pool, intern, param_start, param_count))
            out.push_str(")")
            if ret_ty != 0:
                out.push_str(" -> " ++ render_type_expr(pool, intern, (ret_ty) as NodeId))
            if default_body != 0:
                out.push_str(": <default>")
            out.push_str("\n")

        return out.to_str()

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

    if kind == NodeKind.NK_MATCH_OP or kind == NodeKind.NK_NEG_MATCH_OP:
        let lhs = pool.get_data0(node)
        let rhs = pool.get_data1(node)
        let op = if kind == NodeKind.NK_MATCH_OP: " =~ " else: " !~ "
        return prefix ++ "(" ++ render_expr(pool, intern, (lhs) as NodeId, 0) ++ op ++ render_expr(pool, intern, (rhs) as NodeId, 0) ++ ")"

    if kind == NodeKind.NK_UNARY:
        let op = pool.get_data0(node)
        let operand = pool.get_data1(node)
        return prefix ++ "(" ++ unary_op_str(op) ++ render_expr(pool, intern, (operand) as NodeId, 0) ++ ")"

    if kind == NodeKind.NK_CALL:
        let callee = pool.get_data0(node)
        let extra_start = pool.get_data1(node)
        let arg_count = pool.get_data2(node)
        var out = StringBuilder.new()
        out.push_str(prefix ++ render_expr(pool, intern, (callee) as NodeId, 0) ++ "(")
        for i in 0..arg_count:
            if i > 0:
                out.push_str(", ")
            out.push_str(render_expr(pool, intern, (pool.get_extra(extra_start + i)) as NodeId, 0))
        return out.to_str() ++ ")"

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
        var out = StringBuilder.new()
        out.push_str(prefix ++ render_expr(pool, intern, (expr) as NodeId, 0) ++ "?." ++ member)
        if pool.optional_chain_is_call(extra_start) != 0:
            let arg_count = pool.optional_chain_arg_count(extra_start)
            let arg_start = pool.optional_chain_arg_start(extra_start)
            out.push_str("(")
            for ai in 0..arg_count:
                if ai > 0:
                    out.push_str(", ")
                out.push_str(render_expr(pool, intern, (pool.get_extra(arg_start + ai)) as NodeId, 0))
            out.push_str(")")
        return out.to_str()

    if kind == NodeKind.NK_INDEX:
        let expr = pool.get_data0(node)
        let idx = pool.get_data1(node)
        return prefix ++ render_expr(pool, intern, (expr) as NodeId, 0) ++ "[" ++ render_expr(pool, intern, (idx) as NodeId, 0) ++ "]"

    if kind == NodeKind.NK_SLICE:
        let expr = pool.get_data0(node)
        let start_expr = pool.get_data1(node)
        let end_expr = pool.get_data2(node)
        var out = StringBuilder.new()
        out.push_str(prefix ++ render_expr(pool, intern, (expr) as NodeId, 0) ++ "[")
        if start_expr != 0:
            out.push_str(render_expr(pool, intern, (start_expr) as NodeId, 0))
        out.push_str("..")
        if end_expr != 0:
            out.push_str(render_expr(pool, intern, (end_expr) as NodeId, 0))
        return out.to_str() ++ "]"

    if kind == NodeKind.NK_BLOCK:
        let extra_start = pool.get_data0(node)
        let stmt_count = pool.get_data1(node)
        let tail = pool.get_data2(node)
        var out = StringBuilder.new()
        let block_meta = pool.find_block_meta(node)
        let block_label = if block_meta >= 0: pool.block_meta_label(block_meta) else: 0
        var body_indent = indent
        if block_label != 0:
            out.push_str(make_indent(indent))
            out.push_str("'")
            out.push_str(intern.resolve(block_label))
            out.push_str(":\n")
            body_indent = indent + 2
        for i in 0..stmt_count:
            out.push_str(render_expr(pool, intern, (pool.get_extra(extra_start + i)) as NodeId, body_indent))
            out.push_str("\n")
        if tail != 0:
            out.push_str(render_expr(pool, intern, (tail) as NodeId, body_indent))
        return out.to_str()

    if kind == NodeKind.NK_LABEL:
        let label = pool.get_data0(node)
        let stmt = pool.get_data1(node)
        if stmt != 0:
            let sk = pool.kind(stmt)
            if sk == NodeKind.NK_WHILE and pool.get_data2(stmt) == label:
                return render_expr(pool, intern, (stmt) as NodeId, indent)
            if sk == NodeKind.NK_DO_WHILE and pool.get_data2(stmt) == label:
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
        var out = StringBuilder.new()
        out.push_str(prefix ++ "if " ++ render_expr(pool, intern, (cond) as NodeId, 0) ++ ": " ++ render_expr(pool, intern, (then_body) as NodeId, 0))
        if else_body != 0:
            out.push_str(" else: " ++ render_expr(pool, intern, (else_body) as NodeId, 0))
        return out.to_str()

    if kind == NodeKind.NK_RETURN:
        let value = pool.get_data0(node)
        if value != 0:
            return prefix ++ "return " ++ render_expr(pool, intern, (value) as NodeId, 0)
        return prefix ++ "return"

    if kind == NodeKind.NK_LET_BINDING:
        let name = intern.resolve(pool.get_data0(node))
        let value = pool.get_data1(node)
        let flags = pool.get_data2(node)
        var out = StringBuilder.new()
        out.push_str(prefix)
        if flags % 2 == 1:
            out.push_str("var ")
        else:
            out.push_str("let ")
        out.push_str(name)
        let type_ann = local_let_type_ann(pool, flags)
        if type_ann != 0:
            out.push_str(": " ++ render_type_expr(pool, intern, (type_ann) as NodeId))
        out.push_str(" = " ++ render_expr(pool, intern, (value) as NodeId, 0))
        return out.to_str()

    if kind == NodeKind.NK_SELECT_AWAIT:
        let extra_start = pool.get_data0(node)
        let arm_count = pool.get_data1(node)
        let biased = pool.get_data2(node)
        var out = StringBuilder.new()
        out.push_str(prefix)
        if biased != 0:
            out.push_str("select await biased:\n")
        else:
            out.push_str("select await:\n")
        for ai in 0..arm_count:
            let name_sym = pool.get_extra(extra_start + ai * 3)
            let task = pool.get_extra(extra_start + ai * 3 + 1)
            let body = pool.get_extra(extra_start + ai * 3 + 2)
            out.push_str("    ")
            out.push_str(intern.resolve(name_sym))
            out.push_str(" = ")
            out.push_str(render_expr(pool, intern, (task) as NodeId, 0))
            out.push_str(" -> ")
            out.push_str(render_expr(pool, intern, (body) as NodeId, 0))
            out.push_str("\n")
        return out.to_str()

    if kind == NodeKind.NK_LET_ELSE:
        let value = pool.get_data1(node)
        let else_body = pool.get_data2(node)
        var out = StringBuilder.new()
        out.push_str(prefix ++ (if pool.let_pattern_is_mut(node) != 0: "var " else: "let ") ++ render_pattern(pool, intern, pool.let_pattern(node)))
        let type_ann = pool.let_pattern_type_ann(node)
        if type_ann != 0:
            out.push_str(": " ++ render_type_expr(pool, intern, type_ann))
        out.push_str(" = " ++ render_expr(pool, intern, value, 0))
        if else_body != 0:
            out.push_str(" else: " ++ render_expr(pool, intern, else_body, 0))
        return out.to_str()

    if kind == NodeKind.NK_TUPLE_DESTRUCTURE:
        let extra_start = pool.get_data0(node)
        let binding_count = pool.get_data1(node)
        let value = pool.get_data2(node)
        var out = StringBuilder.new()
        out.push_str(prefix ++ "let ")
        if binding_count > 0:
            out.push_str("(")
            for bi in 0..binding_count:
                if bi > 0:
                    out.push_str(", ")
                out.push_str(intern.resolve(pool.get_extra(extra_start + bi)))
            out.push_str(")")
        else:
            out.push_str("(...)")
        out.push_str(" = " ++ render_expr(pool, intern, (value) as NodeId, 0))
        return out.to_str()

    if kind == NodeKind.NK_ASSIGN:
        let target = pool.get_data0(node)
        let value = pool.get_data1(node)
        return prefix ++ render_expr(pool, intern, (target) as NodeId, 0) ++ " = " ++ render_expr(pool, intern, (value) as NodeId, 0)

    if kind == NodeKind.NK_TUPLE:
        let extra_start = pool.get_data0(node)
        let count = pool.get_data1(node)
        var out = StringBuilder.new()
        out.push_str(prefix)
        out.push_str("(")
        for i in 0..count:
            if i > 0:
                out.push_str(", ")
            out.push_str(render_expr(pool, intern, (pool.get_extra(extra_start + i)) as NodeId, 0))
        out.push_str(")")
        return out.to_str()

    if kind == NodeKind.NK_RANGE:
        let start_expr = pool.get_data0(node)
        let end_expr = pool.get_data1(node)
        let inclusive = pool.get_data2(node)
        var out = StringBuilder.new()
        out.push_str(prefix)
        if start_expr != 0:
            out.push_str(render_expr(pool, intern, (start_expr) as NodeId, 0))
        if inclusive != 0:
            out.push_str("..=")
        else:
            out.push_str("..")
        if end_expr != 0:
            out.push_str(render_expr(pool, intern, (end_expr) as NodeId, 0))
        return out.to_str()

    if kind == NodeKind.NK_VARIANT_SHORTHAND:
        let name = intern.resolve(pool.get_data0(node))
        let extra_start = pool.get_data1(node)
        let arg_count = pool.get_data2(node)
        var out = StringBuilder.new()
        out.push_str(prefix ++ "." ++ name)
        if arg_count > 0:
            out.push_str("(")
            for ai in 0..arg_count:
                if ai > 0:
                    out.push_str(", ")
                out.push_str(render_expr(pool, intern, (pool.get_extra(extra_start + ai)) as NodeId, 0))
            out.push_str(")")
        return out.to_str()

    if kind == NodeKind.NK_AWAIT:
        let inner = pool.get_data0(node)
        return prefix ++ render_expr(pool, intern, (inner) as NodeId, 0) ++ ".await"

    if kind == NodeKind.NK_ASYNC_BLOCK:
        let body = pool.get_data0(node)
        return prefix ++ "async:\n" ++ render_expr(pool, intern, (body) as NodeId, indent + 2)

    if kind == NodeKind.NK_COMPTIME:
        let inner = pool.get_data0(node)
        return prefix ++ "comptime " ++ render_expr(pool, intern, (inner) as NodeId, 0)

    if kind == NodeKind.NK_ASYNC_SCOPE:
        let name = intern.resolve(pool.get_data0(node))
        let body = pool.get_data1(node)
        return prefix ++ "async scope |" ++ name ++ "|:\n" ++ render_expr(pool, intern, (body) as NodeId, indent + 2)

    if kind == NodeKind.NK_SCOPE:
        let name = intern.resolve(pool.get_data0(node))
        let body = pool.get_data1(node)
        return prefix ++ "scope " ++ name ++ ":\n" ++ render_expr(pool, intern, (body) as NodeId, indent + 2)

    if kind == NodeKind.NK_PIPELINE:
        let lhs = pool.get_data0(node)
        let rhs = pool.get_data1(node)
        return prefix ++ render_expr(pool, intern, (lhs) as NodeId, 0) ++ " |> " ++ render_expr(pool, intern, (rhs) as NodeId, 0)

    if kind == NodeKind.NK_BREAK:
        let value = pool.get_data0(node)
        let label = pool.get_data1(node)
        var out = StringBuilder.new()
        out.push_str(prefix ++ "break")
        if label != 0:
            out.push_str(" '" ++ intern.resolve(label))
        if value != 0:
            out.push_str(" " ++ render_expr(pool, intern, (value) as NodeId, 0))
        return out.to_str()

    if kind == NodeKind.NK_CONTINUE:
        let label = pool.get_data0(node)
        var out = StringBuilder.new()
        out.push_str(prefix ++ "continue")
        if label != 0:
            out.push_str(" '" ++ intern.resolve(label))
        return out.to_str()

    if kind == NodeKind.NK_LOOP:
        let body = pool.get_data0(node)
        let label = pool.get_data1(node)
        var out = StringBuilder.new()
        out.push_str(prefix)
        if label != 0:
            out.push_str("'" ++ intern.resolve(label) ++ " ")
        return out.to_str() ++ "loop:\n" ++ render_expr(pool, intern, (body) as NodeId, indent + 2)

    if kind == NodeKind.NK_FOR:
        let binding = pool.get_data0(node)
        let iterable = pool.get_data1(node)
        let body = pool.get_data2(node)
        let for_meta = pool.find_for_meta(node)
        let label = if for_meta >= 0: pool.for_meta_label(for_meta) else: 0
        var out = StringBuilder.new()
        out.push_str(prefix)
        if label != 0:
            out.push_str("'" ++ intern.resolve(label) ++ " ")
        out.push_str("for ")
        if pool.for_binding_is_pattern(node):
            out.push_str(render_pattern(pool, intern, (binding) as NodeId))
        else:
            out.push_str(intern.resolve(binding))
        out.push_str(" in " ++ render_expr(pool, intern, (iterable) as NodeId, 0) ++ ":\n")
        out.push_str(render_expr(pool, intern, (body) as NodeId, indent + 2))
        return out.to_str()

    if kind == NodeKind.NK_WHILE:
        let cond = pool.get_data0(node)
        let body = pool.get_data1(node)
        let label = pool.get_data2(node)
        var out = StringBuilder.new()
        out.push_str(prefix)
        if label != 0:
            out.push_str("'" ++ intern.resolve(label) ++ " ")
        return out.to_str() ++ "while " ++ render_expr(pool, intern, (cond) as NodeId, 0) ++ ":\n" ++ render_expr(pool, intern, (body) as NodeId, indent + 2)

    if kind == NodeKind.NK_DO_WHILE:
        let body = pool.get_data0(node)
        let cond = pool.get_data1(node)
        let label = pool.get_data2(node)
        var out = StringBuilder.new()
        out.push_str(with_str_clone_ref(prefix))
        if label != 0:
            out.push_str("'" ++ intern.resolve(label) ++ " ")
        out.push_str("do:\n" ++ render_expr(pool, intern, (body) as NodeId, indent + 2))
        out.push_str("\n" ++ prefix ++ "while " ++ render_expr(pool, intern, (cond) as NodeId, 0))
        return out.to_str()

    if kind == NodeKind.NK_ARRAY_LIT:
        let extra_start = pool.get_data0(node)
        let count = pool.get_data1(node)
        // The parser desugars `[v; N]` into N copies of v's one node; written
        // elements are distinct nodes. Printing the copies made the dump of
        // `[0 as u8; 16777216]` 150 MB (#1358).
        if count > 1 and array_lit_is_fill(pool, extra_start, count):
            return prefix ++ "[" ++ render_expr(pool, intern, (pool.get_extra(extra_start)) as NodeId, 0) ++ f"; {count}]"
        var out = StringBuilder.new()
        out.push_str(prefix ++ "[")
        for i in 0..count:
            if i > 0:
                out.push_str(", ")
            out.push_str(render_expr(pool, intern, (pool.get_extra(extra_start + i)) as NodeId, 0))
        return out.to_str() ++ "]"

    if kind == NodeKind.NK_MAP_LIT:
        let extra_start = pool.get_data0(node)
        let count = pool.get_data1(node)
        if count == 0:
            return prefix ++ "[:]"
        var out = StringBuilder.new()
        out.push_str(prefix ++ "[")
        for i in 0..count:
            if i > 0:
                out.push_str(", ")
            let key = pool.get_extra(extra_start + i * 2)
            let value = pool.get_extra(extra_start + i * 2 + 1)
            out.push_str(render_expr(pool, intern, (key) as NodeId, 0))
            out.push_str(": ")
            out.push_str(render_expr(pool, intern, (value) as NodeId, 0))
        return out.to_str() ++ "]"

    if kind == NodeKind.NK_ARRAY_COMPREHENSION:
        let expr = pool.get_data0(node)
        let comp_start = pool.get_data1(node)
        let clause_count = pool.get_data2(node)
        let rendered_expr = render_expr(pool, intern, (expr) as NodeId, 0)
        var out = StringBuilder.new()
        out.push_str(f"{prefix}[{rendered_expr}")
        for ci in 0..clause_count:
            let base = comp_start + ci * 3
            let binding = pool.get_extra(base)
            let iterable = pool.get_extra(base + 1)
            var binding_text = ""
            if pool.comprehension_binding_is_pattern(node, binding):
                binding_text = render_pattern(pool, intern, (binding) as NodeId)
            else:
                binding_text = with_str_clone_ref(intern.resolve(binding))
            let iterable_text = render_expr(pool, intern, (iterable) as NodeId, 0)
            out.push_str(f" for {binding_text} in {iterable_text}")
            let filter = pool.get_extra(base + 2)
            if filter != 0:
                let filter_text = render_expr(pool, intern, (filter) as NodeId, 0)
                out.push_str(f" if {filter_text}")
        return out.to_str() ++ "]"

    if kind == NodeKind.NK_MAP_COMPREHENSION:
        let comp_start = pool.get_data0(node)
        let clause_count = pool.get_data1(node)
        let key_expr = pool.get_extra(comp_start)
        let value_expr = pool.get_extra(comp_start + 1)
        let rendered_key = render_expr(pool, intern, (key_expr) as NodeId, 0)
        let rendered_value = render_expr(pool, intern, (value_expr) as NodeId, 0)
        var out = StringBuilder.new()
        out.push_str(f"{prefix}[{rendered_key}: {rendered_value}")
        for ci in 0..clause_count:
            let base = comp_start + 2 + ci * 3
            let binding = pool.get_extra(base)
            let iterable = pool.get_extra(base + 1)
            var binding_text = ""
            if pool.comprehension_binding_is_pattern(node, binding):
                binding_text = render_pattern(pool, intern, (binding) as NodeId)
            else:
                binding_text = with_str_clone_ref(intern.resolve(binding))
            let iterable_text = render_expr(pool, intern, (iterable) as NodeId, 0)
            out.push_str(f" for {binding_text} in {iterable_text}")
            let filter = pool.get_extra(base + 2)
            if filter != 0:
                let filter_text = render_expr(pool, intern, (filter) as NodeId, 0)
                out.push_str(f" if {filter_text}")
        return out.to_str() ++ "]"

    if kind == NodeKind.NK_STRUCT_LIT:
        let name = intern.resolve(pool.get_data0(node))
        let extra_start = pool.get_data1(node)
        let field_count = pool.get_data2(node)
        var out = StringBuilder.new()
        out.push_str(prefix ++ name ++ " " ++ render_lbrace() ++ " ")
        for fi in 0..field_count:
            if fi > 0:
                out.push_str(", ")
            let field_name = intern.resolve(pool.get_extra(extra_start + fi * 2))
            let field_val = pool.get_extra(extra_start + fi * 2 + 1)
            out.push_str(field_name ++ ": " ++ render_expr(pool, intern, (field_val) as NodeId, 0))
        return out.to_str() ++ " " ++ render_rbrace()

    if kind == NodeKind.NK_GROUPED:
        let inner = pool.get_data0(node)
        return prefix ++ "(" ++ render_expr(pool, intern, (inner) as NodeId, 0) ++ ")"

    if kind == NodeKind.NK_MATCH:
        let subject = pool.get_data0(node)
        let extra_start = pool.get_data1(node)
        let arm_count = pool.get_data2(node)
        var out = StringBuilder.new()
        out.push_str(prefix ++ "match " ++ render_expr(pool, intern, (subject) as NodeId, 0) ++ ":\n")
        for ai in 0..arm_count:
            let arm = pool.get_extra(extra_start + ai)
            let pattern = pool.get_data0(arm)
            let body = pool.get_data1(arm)
            let guard = pool.get_data2(arm)
            out.push_str(make_indent(indent + 2))
            out.push_str(render_pattern(pool, intern, (pattern) as NodeId))
            if guard != 0:
                out.push_str(" if " ++ render_expr(pool, intern, (guard) as NodeId, 0))
            out.push_str(" -> " ++ render_expr(pool, intern, (body) as NodeId, 0) ++ "\n")
        return out.to_str()

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
        var out = StringBuilder.new()
        out.push_str(prefix ++ "|")
        for pi in 0..param_count:
            if pi > 0:
                out.push_str(", ")
            let p_name = pool.get_extra(extra_start + pi * 2)
            let p_type = pool.get_extra(extra_start + pi * 2 + 1)
            out.push_str(intern.resolve(p_name))
            if p_type != 0:
                out.push_str(": " ++ render_type_expr(pool, intern, (p_type) as NodeId))
        out.push_str("| " ++ render_expr(pool, intern, (body) as NodeId, 0))
        return out.to_str()

    if kind == NodeKind.NK_ENUM_VARIANT:
        let type_name = intern.resolve(pool.get_data0(node))
        let variant_name = intern.resolve(pool.get_data1(node))
        let extra_start = pool.get_data2(node)
        var out = StringBuilder.new()
        out.push_str(prefix ++ type_name ++ "." ++ variant_name)
        if extra_start != 0:
            let arg_count = pool.get_extra(extra_start)
            if arg_count > 0:
                out.push_str("(")
                for ai in 0..arg_count:
                    if ai > 0:
                        out.push_str(", ")
                    out.push_str(render_expr(pool, intern, (pool.get_extra(extra_start + 1 + ai)) as NodeId, 0))
                out.push_str(")")
        return out.to_str()

    if kind == NodeKind.NK_WITH_EXPR:
        let source = pool.get_data0(node)
        let body = pool.get_data1(node)
        let encoded = pool.get_data2(node)
        let name = intern.resolve(decode_with_binding_sym(encoded))
        let is_mut = decode_with_binding_is_mut(encoded)
        var out = StringBuilder.new()
        out.push_str(prefix ++ "with " ++ render_expr(pool, intern, (source) as NodeId, 0))
        if is_mut != 0:
            out.push_str(" as mut " ++ name ++ ":\n")
        else:
            out.push_str(" as " ++ name ++ ":\n")
        out.push_str(render_expr(pool, intern, (body) as NodeId, indent + 2))
        return out.to_str()

    if kind == NodeKind.NK_WITH_TUPLE:
        let wt_source = pool.get_data0(node)
        let wt_body = pool.get_data1(node)
        let wt_extra = pool.get_data2(node)
        let wt_count = pool.get_extra(wt_extra)
        let wt_mut = pool.get_extra(wt_extra + 1)
        var wt_out = StringBuilder.new()
        wt_out.push_str(prefix ++ "with " ++ render_expr(pool, intern, (wt_source) as NodeId, 0))
        if wt_mut != 0:
            wt_out.push_str(" as mut (")
        else:
            wt_out.push_str(" as (")
        for wti in 0..wt_count:
            if wti > 0:
                wt_out.push_str(", ")
            let wt_sym = pool.get_extra(wt_extra + 2 + wti)
            if wt_sym == 0:
                wt_out.push_str("_")
            else:
                wt_out.push_str(intern.resolve(wt_sym))
        wt_out.push_str("):\n")
        wt_out.push_str(render_expr(pool, intern, (wt_body) as NodeId, indent + 2))
        return wt_out.to_str()

    if kind == NodeKind.NK_WITH_IMPLICIT:
        let wi_source = pool.get_data0(node)
        let wi_body = pool.get_data1(node)
        let wi_name = intern.resolve(pool.get_data2(node))
        var wi_out = StringBuilder.new()
        wi_out.push_str(prefix ++ "with " ++ render_expr(pool, intern, (wi_source) as NodeId, 0))
        wi_out.push_str(" as " ++ wi_name ++ ":\n")
        wi_out.push_str(render_expr(pool, intern, (wi_body) as NodeId, indent + 2))
        return wi_out.to_str()

    if kind == NodeKind.NK_RECORD_UPDATE:
        let source = pool.get_data0(node)
        let extra_start = pool.get_data1(node)
        let field_count = pool.get_data2(node)
        var out = StringBuilder.new()
        out.push_str(prefix ++ render_lbrace() ++ " " ++ render_expr(pool, intern, (source) as NodeId, 0) ++ " with ")
        for fi in 0..field_count:
            if fi > 0:
                out.push_str(", ")
            let fname = intern.resolve(pool.get_extra(extra_start + fi * 2))
            let fval = pool.get_extra(extra_start + fi * 2 + 1)
            out.push_str(fname ++ ": " ++ render_expr(pool, intern, (fval) as NodeId, 0))
        return out.to_str() ++ " " ++ render_rbrace()

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
        return with_str_clone_ref(intern.resolve(pool.get_data0(node)))

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
        var out = StringBuilder.new()
        out.push_str(if qualifier != 0: intern.resolve(qualifier) ++ "." ++ name else: with_str_clone_ref(name))
        if binding_count > 0:
            out.push_str("(")
            for bi in 0..binding_count:
                if bi > 0:
                    out.push_str(", ")
                let item = pool.get_extra(extra_start + bi)
                if is_pattern_node(pool, (item) as NodeId):
                    out.push_str(render_pattern(pool, intern, (item) as NodeId))
                else:
                    out.push_str(intern.resolve(item))
            out.push_str(")")
        return out.to_str()

    if kind == NodeKind.NK_PAT_ENUM_SHORTHAND:
        let name = intern.resolve(pool.get_data0(node))
        let extra_start = pool.get_data1(node)
        let binding_count = pool.get_data2(node)
        var out = StringBuilder.new()
        out.push_str("." ++ name)
        if binding_count > 0:
            out.push_str("(")
            for bi in 0..binding_count:
                if bi > 0:
                    out.push_str(", ")
                let item = pool.get_extra(extra_start + bi)
                if is_pattern_node(pool, (item) as NodeId):
                    out.push_str(render_pattern(pool, intern, (item) as NodeId))
                else:
                    out.push_str(intern.resolve(item))
            out.push_str(")")
        return out.to_str()

    if kind == NodeKind.NK_PAT_TUPLE:
        let extra_start = pool.get_data0(node)
        let count = pool.get_data1(node)
        var out = StringBuilder.new()
        out.push_str("(")
        for i in 0..count:
            if i > 0:
                out.push_str(", ")
            out.push_str(render_pattern(pool, intern, (pool.get_extra(extra_start + i)) as NodeId))
        return out.to_str() ++ ")"

    if kind == NodeKind.NK_PAT_RANGE:
        let start_val = pool.get_data0(node)
        let end_val = pool.get_data1(node)
        if pool.get_data2(node) != 0:
            return f"{start_val}..={end_val}"
        return f"{start_val}..{end_val}"

    if kind == NodeKind.NK_PAT_OR:
        let extra_start = pool.get_data0(node)
        let count = pool.get_data1(node)
        var out = StringBuilder.new()
        for i in 0..count:
            if i > 0:
                out.push_str(" | ")
            out.push_str(render_pattern(pool, intern, (pool.get_extra(extra_start + i)) as NodeId))
        return out.to_str()

    if kind == NodeKind.NK_PAT_AT_BINDING:
        let name = intern.resolve(pool.get_data0(node))
        let inner = pool.get_data1(node)
        return name ++ " @ " ++ render_pattern(pool, intern, (inner) as NodeId)

    if kind == NodeKind.NK_PAT_SLICE:
        let extra_start = pool.get_data0(node)
        let head_count = pool.get_data1(node)
        let rest_sym = pool.get_data2(node)
        let has_rest = pool.get_extra(extra_start)
        var out = StringBuilder.new()
        out.push_str("[")
        for hi in 0..head_count:
            if hi > 0:
                out.push_str(", ")
            out.push_str(intern.resolve(pool.get_extra(extra_start + 1 + hi)))
        if has_rest != 0:
            if head_count > 0:
                out.push_str(", ")
            out.push_str("..")
            if rest_sym != 0:
                out.push_str(intern.resolve(rest_sym))
        return out.to_str() ++ "]"

    if kind == NodeKind.NK_PAT_STRUCT:
        let type_name = pool.get_data0(node)
        let extra_start = pool.get_data1(node)
        let field_count = pool.get_data2(node)
        let has_rest = pool.get_extra(extra_start + field_count * 2)
        var out = StringBuilder.new()
        if type_name != 0:
            out.push_str(intern.resolve(type_name) ++ " ")
        out.push_str(render_lbrace() ++ " ")
        for fi in 0..field_count:
            if fi > 0:
                out.push_str(", ")
            let fname = intern.resolve(pool.get_extra(extra_start + fi * 2))
            let fpat = pool.get_extra(extra_start + fi * 2 + 1)
            out.push_str(fname)
            if fpat != 0:
                out.push_str(": " ++ render_pattern(pool, intern, (fpat) as NodeId))
        if has_rest != 0:
            if field_count > 0:
                out.push_str(", ")
            out.push_str("..")
        return out.to_str() ++ " " ++ render_rbrace()

    f"<pat:{kind}>"

fn render_type_expr(pool: AstPool, intern: InternPool, node: NodeId) -> str:
    if node == 0:
        return "_"
    let kind = pool.kind(node)

    if kind == NodeKind.NK_TYPE_NAMED:
        return with_str_clone_ref(intern.resolve(pool.get_data0(node)))

    if kind == NodeKind.NK_TYPE_GENERIC:
        let name = intern.resolve(pool.get_data0(node))
        let extra_start = pool.get_data1(node)
        let arg_count = pool.get_data2(node)
        var out = StringBuilder.new()
        out.push_str(name ++ "[")
        for i in 0..arg_count:
            if i > 0:
                out.push_str(", ")
            out.push_str(render_type_expr(pool, intern, (pool.get_extra(extra_start + i)) as NodeId))
        return out.to_str() ++ "]"

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
        var out = StringBuilder.new()
        out.push_str("fn(")
        for pi in 0..param_count:
            if pi > 0:
                out.push_str(", ")
            out.push_str(render_type_expr(pool, intern, (pool.get_extra(extra_start + pi)) as NodeId))
        out.push_str(") -> " ++ render_type_expr(pool, intern, (ret) as NodeId))
        return out.to_str()

    if kind == NodeKind.NK_TYPE_EXTERN_FN:
        let extra_start = pool.get_data0(node)
        let param_count = pool.get_data1(node)
        let ret = pool.get_data2(node)
        var out = StringBuilder.new()
        out.push_str("extern \"C\" fn(")
        for pi in 0..param_count:
            if pi > 0:
                out.push_str(", ")
            out.push_str(render_type_expr(pool, intern, (pool.get_extra(extra_start + pi)) as NodeId))
        out.push_str(") -> " ++ render_type_expr(pool, intern, (ret) as NodeId))
        return out.to_str()

    if kind == NodeKind.NK_TYPE_TUPLE:
        let extra_start = pool.get_data0(node)
        let count = pool.get_data1(node)
        var out = StringBuilder.new()
        out.push_str("(")
        for ti in 0..count:
            if ti > 0:
                out.push_str(", ")
            out.push_str(render_type_expr(pool, intern, (pool.get_extra(extra_start + ti)) as NodeId))
        return out.to_str() ++ ")"

    if kind == NodeKind.NK_TYPE_OPTIONAL:
        let inner = pool.get_data0(node)
        return "?" ++ render_type_expr(pool, intern, (inner) as NodeId)

    if kind == NodeKind.NK_TYPE_ARRAY:
        let elem = pool.get_data0(node)
        let size = pool.get_data1(node)
        return f"[{size}]{render_type_expr(pool, intern, (elem) as NodeId)}"

    if kind == NodeKind.NK_TYPE_SLICE:
        let elem = pool.get_data0(node)
        let mut_text = if pool.get_data1(node) != 0: "mut " else: ""
        return "[]" ++ mut_text ++ render_type_expr(pool, intern, (elem) as NodeId)

    if kind == NodeKind.NK_TYPE_TRAIT_OBJ:
        let prefix = if pool.get_data1(node) == TYPE_TRAIT_OBJECT_IMPL: "impl " else: "dyn "
        return prefix ++ intern.resolve(pool.get_data0(node))

    if kind == NodeKind.NK_TYPE_INFERRED:
        return "_"

    f"<type:{kind}>"

fn render_type_params(pool: AstPool, intern: InternPool, tp_start: i32, tp_count: i32) -> str:
    var out = StringBuilder.new()
    out.push_str("[")
    var cursor = tp_start
    for i in 0..tp_count:
        if i > 0:
            out.push_str(", ")
        let name_sym = pool.get_extra(cursor)
        let bound_count = pool.get_extra(cursor + 1)
        cursor = cursor + 2
        out.push_str(intern.resolve(name_sym))
        if bound_count > 0:
            out.push_str(": ")
            for bi in 0..bound_count:
                if bi > 0:
                    out.push_str(" + ")
                out.push_str(intern.resolve(pool.get_extra(cursor + bi)))
            cursor = cursor + bound_count
    out.to_str() ++ "]"

fn render_params(pool: AstPool, intern: InternPool, param_start: i32, param_count: i32) -> str:
    var out = StringBuilder.new()
    for i in 0..param_count:
        if i > 0:
            out.push_str(", ")
        let flags = pool.fn_param_flags(param_start, i)
        let name_sym = pool.fn_param_name(param_start, i)
        let type_node = pool.fn_param_type(param_start, i)
        if fn_param_is_noalias(flags) != 0:
            out.push_str("@[noalias] ")
        out.push_str(intern.resolve(name_sym))
        if type_node != 0:
            out.push_str(": " ++ render_type_expr(pool, intern, (type_node) as NodeId))
    out.to_str()

fn array_lit_is_fill(pool: AstPool, extra_start: i32, count: i32) -> bool:
    let first = pool.get_extra(extra_start)
    for i in 1..count:
        if pool.get_extra(extra_start + i) != first: return false
    true

fn has_flag(flags: i32, bit: i32) -> bool:
    (flags / bit) % 2 == 1

fn type_decl_is_pub(pool: AstPool, extra_start: i32, sub_kind: i32) -> bool:
    // A union carries the struct body layout (Parser.parse_struct_body).
    if sub_kind == TypeDeclKind.Struct or sub_kind == TypeDeclKind.Union:
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
            ep = ep + 1  // discriminant node (0 = auto)
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
    if op == UnaryOp.UOP_RAW_REF_CONST: return "&raw const "
    if op == UnaryOp.UOP_RAW_REF_MUT: return "&raw mut "
    if op == UnaryOp.UOP_DEREF: return "*"
    if op == UnaryOp.UOP_TRY: return "?"
    "?uop?"

fn make_indent(n: i32) -> str:
    var out = StringBuilder.new()
    for i in 0..n:
        out.push_str(" ")
    out.to_str()

fn render_lbrace -> str:
    str_from_byte(123)

fn render_rbrace -> str:
    str_from_byte(125)
