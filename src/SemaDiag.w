// SemaDiag — error reporting, diagnostics, typed dump rendering, type name formatting.

use Sema
use Ast
use Span
use Diagnostic
use InternPool
use render

extern fn with_eprintln(s: str) -> void
extern fn int_to_string(n: i32) -> str

// ── Diagnostics ──────────────────────────────────────────────────

fn Sema.call_param_name(self: Sema, fn_sym: i32, param_i: i32) -> str:
    if fn_sym <= 0 or param_i < 0:
        return ""
    if not self.fn_decl_nodes.contains(fn_sym):
        return ""
    let fn_node = self.fn_decl_nodes.get(fn_sym).unwrap()
    let meta = self.ast.find_fn_meta(fn_node)
    if meta < 0:
        return ""
    let param_start = self.ast.fn_meta_param_start(meta)
    let param_count = self.ast.fn_meta_param_count(meta)
    if param_i >= param_count:
        return ""
    let param_sym = self.ast.fn_param_name(param_start, param_i)
    self.safe_symbol_text(param_sym)

fn Sema.argument_literal_default_help(self: Sema, arg_node: i32, expr_text: str, expected_ty: i32, actual_ty: i32) -> str:
    if arg_node == 0 or expr_text.len() == 0:
        return ""
    let kind = self.ast.kind(arg_node)
    let expected_name = self.type_name(expected_ty)
    if kind == NodeKind.NK_INT_LIT and actual_ty == self.ty_i32 and expected_ty != 0 and expected_ty != actual_ty:
        return "integer literal '" ++ expr_text ++ "' defaults to i32; cast with '" ++ expr_text ++ " as " ++ expected_name ++ "'"
    if kind == NodeKind.NK_FLOAT_LIT and actual_ty == self.ty_f64 and expected_ty != 0 and expected_ty != actual_ty:
        return "float literal '" ++ expr_text ++ "' defaults to f64; cast with '" ++ expr_text ++ " as " ++ expected_name ++ "'"
    ""

fn Sema.try_ci_coercion(self: Sema, arg_ty: i32, param_ty: i32) -> i32:
    // c_import auto-coercion: allow bool → integer at ABI boundary
    let arg_k = self.get_type_kind(self.resolve_alias(arg_ty))
    let par_k = self.get_type_kind(self.resolve_alias(param_ty))
    if arg_k == TypeKind.TY_BOOL and par_k == TypeKind.TY_INT:
        return 1
    0

fn Sema.emit_argument_type_mismatch(self: Sema, call_name: str, fn_sym: i32, arg_index: i32, param_i: i32, expected_ty: i32, actual_ty: i32, arg_node: i32):
    if self.suppress_errors != 0:
        return
    let start = self.ast.get_start(arg_node)
    let end = self.ast.get_end(arg_node)
    let primary = Span { file: self.local_file_id, start: start, end: end }
    let expected_name = self.type_name(expected_ty)
    let actual_name = self.type_name(actual_ty)
    let expr_text = render_expr(self.ast, self.pool, (arg_node) as NodeId, 0)
    var msg = "wrong argument type"
    if call_name.len() > 0:
        msg = msg ++ " in call to '" ++ call_name ++ "'"
    var diag = Diagnostic.err(msg, primary)
    if expr_text.len() > 0 and sema_str_contains_char(expr_text, 10) == 0:
        diag.add_label(primary, "argument expression '" ++ expr_text ++ "' has type " ++ actual_name)
    else:
        diag.add_label(primary, "argument has type " ++ actual_name)

    let param_name = self.call_param_name(fn_sym, param_i)
    if param_name.len() > 0:
        diag.add_note("parameter '" ++ param_name ++ "' expects " ++ expected_name)
    else if arg_index >= 0:
        diag.add_note(f"argument {arg_index + 1} expects {expected_name}")
    else:
        diag.add_note("expected type: " ++ expected_name)
    diag.add_note("actual type: " ++ actual_name)

    let help = self.argument_literal_default_help(arg_node, expr_text, expected_ty, actual_ty)
    if help.len() > 0:
        diag.add_help(help)
    self.diags.emit(diag)

fn Sema.unknown_type_message(self: Sema, sym: i32) -> str:
    let name = self.pool_resolve(sym)
    if name.len() == 0:
        return "unknown type"
    if name == "string":
        return "unknown type 'string'; use 'str' or 'String'"
    "unknown type '" ++ name ++ "'"

fn Sema.emit_unknown_type_error(self: Sema, sym: i32, node: i32):
    let target_name = self.pool_resolve(sym)
    let suggestion = self.suggest_type_name(target_name, node)
    self.emit_error_with_suggestion(self.unknown_type_message(sym), node, suggestion)

fn Sema.emit_error(self: Sema, msg: str, node: i32):
    if self.suppress_errors != 0:
        return
    let start = self.ast.get_start(node)
    let end = self.ast.get_end(node)
    self.diags.emit(Diagnostic.err(msg, Span { file: self.local_file_id, start: start, end: end }))

fn Sema.emit_warning(self: Sema, msg: str, node: i32):
    let start = self.ast.get_start(node)
    let end = self.ast.get_end(node)
    self.diags.emit(Diagnostic.warn(msg, Span { file: self.local_file_id, start: start, end: end }))

// ── Typed dump rendering ────────────────────────────────────────

fn typed_decl_kind_name(kind: i32) -> str:
    if kind == NodeKind.NK_FN_DECL: return "function"
    if kind == NodeKind.NK_TYPE_DECL: return "type_decl"
    if kind == NodeKind.NK_USE_DECL: return "use_decl"
    if kind == NodeKind.NK_LET_DECL: return "let_decl"
    if kind == NodeKind.NK_EXTERN_FN: return "extern_fn"
    if kind == NodeKind.NK_C_IMPORT: return "c_import"
    if kind == NodeKind.NK_TRAIT_DECL: return "trait_decl"
    if kind == NodeKind.NK_IMPL_DECL: return "impl_decl"
    if kind == NodeKind.NK_POISONED_DECL: return "poisoned"
    "unknown"

fn typed_expr_kind_name(kind: i32) -> str:
    if kind == NodeKind.NK_INT_LIT: return "int_literal"
    if kind == NodeKind.NK_FLOAT_LIT: return "float_literal"
    if kind == NodeKind.NK_STRING_LIT: return "string_literal"
    if kind == NodeKind.NK_C_STRING_LIT: return "c_string_literal"
    if kind == NodeKind.NK_BOOL_LIT: return "bool_literal"
    if kind == NodeKind.NK_IDENT: return "ident"
    if kind == NodeKind.NK_BINARY: return "binary"
    if kind == NodeKind.NK_UNARY: return "unary"
    if kind == NodeKind.NK_CALL: return "call"
    if kind == NodeKind.NK_FIELD_ACCESS: return "field_access"
    if kind == NodeKind.NK_INDEX: return "index"
    if kind == NodeKind.NK_SLICE: return "slice"
    if kind == NodeKind.NK_BLOCK: return "block"
    if kind == NodeKind.NK_IF_EXPR: return "if_expr"
    if kind == NodeKind.NK_RETURN: return "return_expr"
    if kind == NodeKind.NK_LET_BINDING: return "let_binding"
    if kind == NodeKind.NK_LET_ELSE: return "let_else"
    if kind == NodeKind.NK_TUPLE_DESTRUCTURE: return "tuple_destructure"
    if kind == NodeKind.NK_ASSIGN: return "assign"
    if kind == NodeKind.NK_TUPLE: return "tuple"
    if kind == NodeKind.NK_RANGE: return "range"
    if kind == NodeKind.NK_VARIANT_SHORTHAND: return "variant_shorthand"
    if kind == NodeKind.NK_AWAIT: return "await_expr"
    if kind == NodeKind.NK_ASYNC_BLOCK: return "async_block"
    if kind == NodeKind.NK_SPAWN: return "spawn_expr"
    if kind == NodeKind.NK_PIPELINE: return "pipeline"
    if kind == NodeKind.NK_GROUPED: return "grouped"
    if kind == NodeKind.NK_WHILE: return "while_expr"
    if kind == NodeKind.NK_LOOP: return "loop_expr"
    if kind == NodeKind.NK_FOR: return "for_expr"
    if kind == NodeKind.NK_BREAK: return "break_expr"
    if kind == NodeKind.NK_CONTINUE: return "continue_expr"
    if kind == NodeKind.NK_ARRAY_LIT: return "array_literal"
    if kind == NodeKind.NK_ARRAY_COMPREHENSION: return "array_comprehension"
    if kind == NodeKind.NK_STRUCT_LIT: return "struct_literal"
    if kind == NodeKind.NK_MATCH: return "match_expr"
    if kind == NodeKind.NK_ENUM_VARIANT: return "enum_variant"
    if kind == NodeKind.NK_CLOSURE: return "closure"
    if kind == NodeKind.NK_CAST: return "cast"
    if kind == NodeKind.NK_DEFER: return "defer_expr"
    if kind == NodeKind.NK_ERRDEFER: return "errdefer_expr"
    if kind == NodeKind.NK_WITH_EXPR: return "with_expr"
    if kind == NodeKind.NK_RECORD_UPDATE: return "record_update"
    if kind == NodeKind.NK_YIELD: return "yield_expr"
    if kind == NodeKind.NK_COMPTIME: return "comptime_expr"
    if kind == NodeKind.NK_ASYNC_SCOPE: return "async_scope"
    if kind == NodeKind.NK_SELECT_AWAIT: return "select_await"
    if kind == NodeKind.NK_OPTIONAL_CHAIN: return "optional_chain"
    if kind == NodeKind.NK_POISONED_EXPR: return "poisoned"
    if kind == NodeKind.NK_FSTRING: return "fstring"
    if kind == NodeKind.NK_FSTRING_SPEC: return "fstring_spec"
    "unknown"

fn typed_indent(indent: i32) -> str:
    var out = ""
    for i in 0..indent:
        out = out ++ "  "
    out

fn emit_typed_indent(indent: i32):
    for i in 0..indent:
        print("  ")

fn Sema.safe_symbol_text(self: Sema, sym: i32) -> str:
    if sym <= 0:
        return ""
    if self.pretty_symbol_names.contains(sym):
        let pretty = self.pretty_symbol_names.get(sym).unwrap()
        if pretty.len() > 0:
            return pretty
    let pooled = self.pool_resolve(sym)
    if pooled.len() > 0:
        return pooled
    f"sym{sym}"

fn Sema.impl_owner_type_name_for_decl(self: Sema, decl: i32) -> str:
    let start = self.ast.get_start(decl)
    let end = self.ast.get_end(decl)
    var best_span = 0
    var best_name = ""
    for di in 0..self.ast.decl_count():
        let cand = self.ast.get_decl(di)
        if self.ast.kind(cand) != NodeKind.NK_IMPL_DECL:
            continue
        let impl_start = self.ast.get_start(cand)
        let impl_end = self.ast.get_end(cand)
        if impl_start <= start and end <= impl_end:
            let span = impl_end - impl_start
            if best_name.len() == 0 or span < best_span:
                best_span = span
                best_name = self.safe_symbol_text(self.ast.get_data0(cand))
    best_name

fn Sema.reset_typed_dump_safety(self: Sema):
    self.typed_dump_seen_nodes = sema_new_map_i32_i32()
    self.typed_dump_visit_budget = 1000

fn Sema.mark_typed_dump_visit(self: Sema, node: i32) -> i32:
    if self.typed_dump_visit_budget <= 0:
        return 0
    if self.typed_dump_seen_nodes.contains(node):
        return 0
    self.typed_dump_visit_budget = self.typed_dump_visit_budget - 1
    self.typed_dump_seen_nodes.insert(node, 1)
    1

fn Sema.clamp_extra_span_count(self: Sema, extra_start: i32, raw_count: i32, stride: i32, hard_cap: i32) -> i32:
    if raw_count <= 0:
        return 0
    if extra_start < 0 or extra_start >= self.ast.extra_len():
        return 0
    if stride <= 0:
        return 0
    let available = self.ast.extra_len() - extra_start
    if available <= 0:
        return 0
    var max_count = available / stride
    if max_count < 0:
        max_count = 0
    var count = raw_count
    if count > max_count:
        count = max_count
    if hard_cap > 0 and count > hard_cap:
        count = hard_cap
    if count < 0:
        count = 0
    count

fn Sema.clamp_sig_param_count(self: Sema, sig_idx: i32, meta_param_count: i32) -> i32:
    var count = self.sig_get_param_count(sig_idx)
    if meta_param_count >= 0 and meta_param_count < count:
        count = meta_param_count
    if count < 0:
        return 0
    if count > 64:
        return 64
    count

fn Sema.dump_typed_module(self: Sema) -> str:
    self.reset_typed_dump_safety()
    var out = ""
    let total_decl_count = self.ast.decl_count()
    let dump_decl_count = total_decl_count
    out = out ++ f"typed module decls={dump_decl_count}\n"

    for di in 0..dump_decl_count:
        let decl = self.ast.get_decl(di)
        let kind = self.ast.kind(decl)
        let start = self.ast.get_start(decl)
        let end = self.ast.get_end(decl)

        out = out ++ f"decl[{di}] kind={typed_decl_kind_name(kind)} span={start}..{end}\n"

        if kind == NodeKind.NK_FN_DECL:
            let fn_name_sym = self.ast.get_data0(decl)
            var fn_name = self.safe_symbol_text(fn_name_sym)
            let owner_type_name = self.impl_owner_type_name_for_decl(decl)
            let parsed_fn_name = self.extract_decl_name_after(decl, "fn")
            if owner_type_name.len() > 0:
                if parsed_fn_name.len() > 0:
                    fn_name = owner_type_name ++ "." ++ parsed_fn_name
                else if sema_str_contains_char(fn_name, 46) == 0:
                    fn_name = owner_type_name ++ "." ++ fn_name
            let sig_idx = self.get_sig(fn_name_sym)
            if fn_name_sym > 0 and self.sig_idx_valid(sig_idx) != 0:
                out = out ++ "  fn " ++ fn_name ++ "("
                let meta = self.ast.find_fn_meta(decl)
                var param_start = 0
                var meta_param_count = 0
                if meta >= 0:
                    param_start = self.ast.fn_meta_param_start(meta)
                    meta_param_count = self.ast.fn_meta_param_count(meta)
                let param_count = self.clamp_sig_param_count(sig_idx, meta_param_count)
                for pi in 0..param_count:
                    if pi > 0:
                        out = out ++ ", "
                    let p_name_sym = if meta >= 0: self.ast.fn_param_name(param_start, pi) else: 0
                    let p_name = if p_name_sym != 0: self.safe_symbol_text(p_name_sym) else: "_"
                    out = out ++ p_name ++ ": " ++ self.type_name(self.sig_param_type(sig_idx, pi))
                out = out ++ ") -> " ++ self.type_name(self.sig_return_type(sig_idx)) ++ "\n"
                let inferred_ret = if meta >= 0 and self.ast.fn_meta_ret(meta) == 0: self.sig_return_type(sig_idx) else: 0
                out = out ++ (if inferred_ret != 0 and inferred_ret != self.ty_void: "  inferred_return: " ++ self.type_name(inferred_ret) ++ "\n" else: "")
            else:
                out = out ++ "  fn " ++ fn_name ++ "(<unknown>)\n"
            out = out ++ self.dump_typed_expr_tree(self.ast.get_data1(decl), 2)
            continue

        if kind == NodeKind.NK_EXTERN_FN:
            let ext_name_sym = self.ast.get_data0(decl)
            let ext_name = self.safe_symbol_text(ext_name_sym)
            let sig_idx = self.get_sig(ext_name_sym)
            if ext_name_sym > 0 and self.sig_idx_valid(sig_idx) != 0:
                out = out ++ "  extern fn " ++ ext_name ++ "("
                let meta = self.ast.find_fn_meta(decl)
                var param_start = 0
                var meta_param_count = 0
                if meta >= 0:
                    param_start = self.ast.fn_meta_param_start(meta)
                    meta_param_count = self.ast.fn_meta_param_count(meta)
                let param_count = self.clamp_sig_param_count(sig_idx, meta_param_count)
                for pi in 0..param_count:
                    if pi > 0:
                        out = out ++ ", "
                    let p_name_sym = if meta >= 0: self.ast.fn_param_name(param_start, pi) else: 0
                    let p_name = if p_name_sym != 0: self.safe_symbol_text(p_name_sym) else: "_"
                    out = out ++ p_name ++ ": " ++ self.type_name(self.sig_param_type(sig_idx, pi))
                out = out ++ ") -> " ++ self.type_name(self.sig_return_type(sig_idx)) ++ "\n"
            else:
                out = out ++ "  extern fn (<unknown>)\n"
            continue

        if kind == NodeKind.NK_LET_DECL:
            let name = self.safe_symbol_text(self.ast.get_data0(decl))
            let has_resolved = self.typed_binding_types.contains(decl) and self.typed_binding_types.get(decl).unwrap() != 0
            if has_resolved:
                let ty = self.typed_binding_types.get(decl).unwrap()
                let is_mut = if self.typed_binding_muts.contains(decl): self.typed_binding_muts.get(decl).unwrap() else: 0
                out = out ++ "  let " ++ name
                if is_mut != 0:
                    out = out ++ " (mut)"
                out = out ++ ": " ++ self.type_name(ty) ++ "\n"
            else:
                // Stage0 parity: emit <annotated> when type expr present but unresolved,
                // <inferred> when no annotation at all.
                let flags = self.ast.get_data2(decl)
                let has_ann = self.top_level_let_type_ann_extra(flags) >= 0
                out = out ++ "  let " ++ name ++ ": " ++ (if has_ann: "<annotated>" else: "<inferred>") ++ "\n"
            continue

        if kind == NodeKind.NK_TYPE_DECL:
            out = out ++ "  type " ++ self.safe_symbol_text(self.ast.get_data0(decl)) ++ "\n"
            continue

        if kind == NodeKind.NK_TRAIT_DECL:
            out = out ++ "  trait " ++ self.safe_symbol_text(self.ast.get_data0(decl)) ++ "\n"
            continue

        if kind == NodeKind.NK_IMPL_DECL:
            let type_name = self.safe_symbol_text(self.ast.get_data0(decl))
            let trait_sym = self.ast.get_data2(decl)
            if trait_sym != 0:
                out = out ++ "  impl " ++ self.safe_symbol_text(trait_sym) ++ " for " ++ type_name ++ "\n"
            else:
                out = out ++ "  impl " ++ type_name ++ "\n"
            continue

        if kind == NodeKind.NK_USE_DECL:
            let extra_start = self.ast.get_data0(decl)
            let path_count = self.ast.get_data1(decl)
            out = out ++ "  use "
            for pi in 0..path_count:
                if pi > 0:
                    out = out ++ "."
                out = out ++ self.safe_symbol_text(self.ast.get_extra(extra_start + pi))
            out = out ++ "\n"
            continue

        if kind == NodeKind.NK_C_IMPORT:
            out = out ++ "  c_import \"" ++ self.safe_symbol_text(self.ast.get_data0(decl)) ++ "\"\n"
            continue

        if kind == NodeKind.NK_POISONED_DECL:
            out = out ++ "  <poisoned>\n"

    out

fn Sema.emit_typed_module(self: Sema, requested_limit: i32):
    self.reset_typed_dump_safety()
    let total_decl_count = self.ast.decl_count()
    var dump_decl_count = total_decl_count
    if requested_limit > 0 and requested_limit <= total_decl_count:
        dump_decl_count = requested_limit
    print(f"typed module decls={dump_decl_count}\n")

    for di in 0..dump_decl_count:
        let decl = self.ast.get_decl(di)
        let kind = self.ast.kind(decl)
        let start = self.ast.get_start(decl)
        let end = self.ast.get_end(decl)

        print(f"decl[{di}] kind={typed_decl_kind_name(kind)} span={start}..{end}\n")

        if kind == NodeKind.NK_FN_DECL:
            let fn_name_sym = self.ast.get_data0(decl)
            var fn_name = self.safe_symbol_text(fn_name_sym)
            let owner_type_name = self.impl_owner_type_name_for_decl(decl)
            let parsed_fn_name = self.extract_decl_name_after(decl, "fn")
            if owner_type_name.len() > 0:
                if parsed_fn_name.len() > 0:
                    fn_name = owner_type_name ++ "." ++ parsed_fn_name
                else if sema_str_contains_char(fn_name, 46) == 0:
                    fn_name = owner_type_name ++ "." ++ fn_name
            let sig_idx = self.get_sig(fn_name_sym)
            if fn_name_sym > 0 and self.sig_idx_valid(sig_idx) != 0:
                print("  fn ")
                print(fn_name)
                print("(")
                let meta = self.ast.find_fn_meta(decl)
                var param_start = 0
                var meta_param_count = 0
                if meta >= 0:
                    param_start = self.ast.fn_meta_param_start(meta)
                    meta_param_count = self.ast.fn_meta_param_count(meta)
                let param_count = self.clamp_sig_param_count(sig_idx, meta_param_count)
                for pi in 0..param_count:
                    if pi > 0:
                        print(", ")
                    let p_name_sym = if meta >= 0: self.ast.fn_param_name(param_start, pi) else: 0
                    let p_name = if p_name_sym != 0: self.safe_symbol_text(p_name_sym) else: "_"
                    print(p_name)
                    print(": ")
                    print(self.type_name(self.sig_param_type(sig_idx, pi)))
                print(") -> ")
                print(self.type_name(self.sig_return_type(sig_idx)))
                print("\n")
                let inferred_ret = if meta >= 0 and self.ast.fn_meta_ret(meta) == 0: self.sig_return_type(sig_idx) else: 0
                print(if inferred_ret != 0 and inferred_ret != self.ty_void: "  inferred_return: " ++ self.type_name(inferred_ret) ++ "\n" else: "")
            else:
                print("  fn ")
                print(fn_name)
                print("(<unknown>)\n")
            self.emit_typed_expr_tree(self.ast.get_data1(decl), 2)
            continue

        if kind == NodeKind.NK_EXTERN_FN:
            let ext_name_sym = self.ast.get_data0(decl)
            let ext_name = self.safe_symbol_text(ext_name_sym)
            let sig_idx = self.get_sig(ext_name_sym)
            if ext_name_sym > 0 and self.sig_idx_valid(sig_idx) != 0:
                print("  extern fn ")
                print(ext_name)
                print("(")
                let meta = self.ast.find_fn_meta(decl)
                var param_start = 0
                var meta_param_count = 0
                if meta >= 0:
                    param_start = self.ast.fn_meta_param_start(meta)
                    meta_param_count = self.ast.fn_meta_param_count(meta)
                let param_count = self.clamp_sig_param_count(sig_idx, meta_param_count)
                for pi in 0..param_count:
                    if pi > 0:
                        print(", ")
                    let p_name_sym = if meta >= 0: self.ast.fn_param_name(param_start, pi) else: 0
                    let p_name = if p_name_sym != 0: self.safe_symbol_text(p_name_sym) else: "_"
                    print(p_name)
                    print(": ")
                    print(self.type_name(self.sig_param_type(sig_idx, pi)))
                print(") -> ")
                print(self.type_name(self.sig_return_type(sig_idx)))
                print("\n")
            else:
                print("  extern fn (<unknown>)\n")
            continue

        if kind == NodeKind.NK_LET_DECL:
            let name = self.safe_symbol_text(self.ast.get_data0(decl))
            let has_resolved = self.typed_binding_types.contains(decl) and self.typed_binding_types.get(decl).unwrap() != 0
            if has_resolved:
                let ty = self.typed_binding_types.get(decl).unwrap()
                let is_mut = if self.typed_binding_muts.contains(decl): self.typed_binding_muts.get(decl).unwrap() else: 0
                print("  let ")
                print(name)
                if is_mut != 0:
                    print(" (mut)")
                print(": ")
                print(self.type_name(ty))
                print("\n")
            else:
                let flags = self.ast.get_data2(decl)
                let has_ann = self.top_level_let_type_ann_extra(flags) >= 0
                print("  let ")
                print(name)
                print(": ")
                print(if has_ann: "<annotated>" else: "<inferred>")
                print("\n")
            continue

        if kind == NodeKind.NK_TYPE_DECL:
            print("  type ")
            print(self.safe_symbol_text(self.ast.get_data0(decl)))
            print("\n")
            continue

        if kind == NodeKind.NK_TRAIT_DECL:
            print("  trait ")
            print(self.safe_symbol_text(self.ast.get_data0(decl)))
            print("\n")
            continue

        if kind == NodeKind.NK_IMPL_DECL:
            let type_name = self.safe_symbol_text(self.ast.get_data0(decl))
            let trait_sym = self.ast.get_data2(decl)
            if trait_sym != 0:
                print("  impl ")
                print(self.safe_symbol_text(trait_sym))
                print(" for ")
                print(type_name)
                print("\n")
            else:
                print("  impl ")
                print(type_name)
                print("\n")
            continue

        if kind == NodeKind.NK_USE_DECL:
            let extra_start = self.ast.get_data0(decl)
            let path_count = self.ast.get_data1(decl)
            print("  use ")
            for pi in 0..path_count:
                if pi > 0:
                    print(".")
                print(self.safe_symbol_text(self.ast.get_extra(extra_start + pi)))
            print("\n")
            continue

        if kind == NodeKind.NK_C_IMPORT:
            print("  c_import \"")
            print(self.safe_symbol_text(self.ast.get_data0(decl)))
            print("\"\n")
            continue

        if kind == NodeKind.NK_POISONED_DECL:
            print("  <poisoned>\n")

fn Sema.dump_typed_expr_tree(self: Sema, node: i32, indent: i32) -> str:
    if node == 0:
        return ""
    if node < 0 or node >= self.ast.node_count():
        return ""
    if indent > 80:
        return ""

    var out = ""
    let kind = self.ast.kind(node)
    let start = self.ast.get_start(node)
    let end = self.ast.get_end(node)
    let has_typed_expr = self.typed_expr_types.contains(node)

    if has_typed_expr:
        let tid = self.typed_expr_types.get(node).unwrap()
        out = out ++ f"{typed_indent(indent)}expr {typed_expr_kind_name(kind)} span={start}..{end} : {self.type_name(tid)}\n"

    if kind == NodeKind.NK_LET_BINDING:
        if self.typed_binding_types.contains(node):
            let name_sym = if self.typed_binding_names.contains(node): self.typed_binding_names.get(node).unwrap() else: self.ast.get_data0(node)
            let is_mut = if self.typed_binding_muts.contains(node): self.typed_binding_muts.get(node).unwrap() else: (self.ast.get_data2(node) % 2)
            out = out ++ typed_indent(indent + 1) ++ "bind " ++ self.safe_symbol_text(name_sym)
            if is_mut != 0:
                out = out ++ " (mut)"
            out = out ++ ": " ++ self.type_name(self.typed_binding_types.get(node).unwrap()) ++ "\n"

    if kind == NodeKind.NK_BINARY:
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data2(node), indent + 1)
        return out

    if kind == NodeKind.NK_UNARY:
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        return out

    if kind == NodeKind.NK_CALL:
        let extra_start = self.ast.get_data1(node)
        let arg_count = self.ast.get_data2(node)
        let safe_arg_count = self.clamp_extra_span_count(extra_start, arg_count, 1, 64)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        for ai in 0..safe_arg_count:
            out = out ++ self.dump_typed_expr_tree(self.ast.get_extra(extra_start + ai), indent + 1)
        return out

    if kind == NodeKind.NK_FIELD_ACCESS:
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        return out

    if kind == NodeKind.NK_OPTIONAL_CHAIN:
        let extra_start = self.ast.get_data2(node)
        if extra_start < 0 or extra_start >= self.ast.extra_len():
            return out
        let arg_count = self.ast.get_extra(extra_start)
        let safe_arg_count = self.clamp_extra_span_count(extra_start + 1, arg_count, 1, 64)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        for ai in 0..safe_arg_count:
            out = out ++ self.dump_typed_expr_tree(self.ast.get_extra(extra_start + 1 + ai), indent + 1)
        return out

    if kind == NodeKind.NK_INDEX:
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        return out

    if kind == NodeKind.NK_SLICE:
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data2(node), indent + 1)
        return out

    if kind == NodeKind.NK_BLOCK:
        let extra_start = self.ast.get_data0(node)
        let stmt_count = self.ast.get_data1(node)
        let tail = self.ast.get_data2(node)
        let safe_stmt_count = self.clamp_extra_span_count(extra_start, stmt_count, 1, 256)
        for si in 0..safe_stmt_count:
            out = out ++ self.dump_typed_expr_tree(self.ast.get_extra(extra_start + si), indent + 1)
        out = out ++ self.dump_typed_expr_tree(tail, indent + 1)
        return out

    if kind == NodeKind.NK_IF_EXPR:
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data2(node), indent + 1)
        return out

    if kind == NodeKind.NK_RETURN:
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        return out

    if kind == NodeKind.NK_LET_BINDING:
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        return out

    if kind == NodeKind.NK_LET_ELSE:
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data2(node), indent + 1)
        return out

    if kind == NodeKind.NK_TUPLE_DESTRUCTURE:
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data2(node), indent + 1)
        return out

    if kind == NodeKind.NK_ASSIGN:
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        return out

    if kind == NodeKind.NK_TUPLE:
        let extra_start = self.ast.get_data0(node)
        let count = self.ast.get_data1(node)
        let safe_count = self.clamp_extra_span_count(extra_start, count, 1, 64)
        for i in 0..safe_count:
            out = out ++ self.dump_typed_expr_tree(self.ast.get_extra(extra_start + i), indent + 1)
        return out

    if kind == NodeKind.NK_RANGE:
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        return out

    if kind == NodeKind.NK_VARIANT_SHORTHAND:
        let extra_start = self.ast.get_data1(node)
        let arg_count = self.ast.get_data2(node)
        let safe_arg_count = self.clamp_extra_span_count(extra_start, arg_count, 1, 64)
        for i in 0..safe_arg_count:
            out = out ++ self.dump_typed_expr_tree(self.ast.get_extra(extra_start + i), indent + 1)
        return out

    if kind == NodeKind.NK_AWAIT or kind == NodeKind.NK_ASYNC_BLOCK or kind == NodeKind.NK_SPAWN or kind == NodeKind.NK_GROUPED or kind == NodeKind.NK_DEFER or kind == NodeKind.NK_ERRDEFER or kind == NodeKind.NK_YIELD or kind == NodeKind.NK_COMPTIME:
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        return out

    if kind == NodeKind.NK_PIPELINE:
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        return out

    if kind == NodeKind.NK_WHILE:
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        return out

    if kind == NodeKind.NK_LOOP:
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        return out

    if kind == NodeKind.NK_FOR:
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data2(node), indent + 1)
        return out

    if kind == NodeKind.NK_BREAK:
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        return out

    if kind == NodeKind.NK_ARRAY_LIT:
        let extra_start = self.ast.get_data0(node)
        let count = self.ast.get_data1(node)
        let safe_count = self.clamp_extra_span_count(extra_start, count, 1, 128)
        for i in 0..safe_count:
            out = out ++ self.dump_typed_expr_tree(self.ast.get_extra(extra_start + i), indent + 1)
        return out

    if kind == NodeKind.NK_ARRAY_COMPREHENSION:
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data2(node), indent + 1)
        return out

    if kind == NodeKind.NK_STRUCT_LIT:
        let extra_start = self.ast.get_data1(node)
        let field_count = self.ast.get_data2(node)
        let safe_field_count = self.clamp_extra_span_count(extra_start, field_count, 2, 128)
        for i in 0..safe_field_count:
            out = out ++ self.dump_typed_expr_tree(self.ast.get_extra(extra_start + i * 2 + 1), indent + 1)
        return out

    if kind == NodeKind.NK_MATCH:
        let extra_start = self.ast.get_data1(node)
        let arm_count = self.ast.get_data2(node)
        let safe_arm_count = self.clamp_extra_span_count(extra_start, arm_count, 1, 128)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        for i in 0..safe_arm_count:
            let arm = self.ast.get_extra(extra_start + i)
            let guard = self.ast.get_data2(arm)
            if guard != 0:
                out = out ++ self.dump_typed_expr_tree(guard, indent + 1)
            out = out ++ self.dump_typed_expr_tree(self.ast.get_data1(arm), indent + 1)
        return out

    if kind == NodeKind.NK_ENUM_VARIANT:
        let extra_start = self.ast.get_data2(node)
        if extra_start < 0 or extra_start >= self.ast.extra_len():
            return out
        let arg_count = self.ast.get_extra(extra_start)
        let safe_arg_count = self.clamp_extra_span_count(extra_start + 1, arg_count, 1, 64)
        for i in 0..safe_arg_count:
            out = out ++ self.dump_typed_expr_tree(self.ast.get_extra(extra_start + 1 + i), indent + 1)
        return out

    if kind == NodeKind.NK_CLOSURE:
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        return out

    if kind == NodeKind.NK_CAST:
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        return out

    if kind == NodeKind.NK_WITH_EXPR:
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        return out

    if kind == NodeKind.NK_RECORD_UPDATE:
        let extra_start = self.ast.get_data1(node)
        let field_count = self.ast.get_data2(node)
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        let safe_field_count = self.clamp_extra_span_count(extra_start, field_count, 2, 128)
        for i in 0..safe_field_count:
            out = out ++ self.dump_typed_expr_tree(self.ast.get_extra(extra_start + i * 2 + 1), indent + 1)
        return out

    if kind == NodeKind.NK_ASYNC_SCOPE:
        out = out ++ self.dump_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        return out

    if kind == NodeKind.NK_SELECT_AWAIT:
        let extra_start = self.ast.get_data0(node)
        let arm_count = self.ast.get_data1(node)
        let safe_arm_count = self.clamp_extra_span_count(extra_start, arm_count, 3, 32)
        for i in 0..safe_arm_count:
            out = out ++ self.dump_typed_expr_tree(self.ast.get_extra(extra_start + i * 3 + 1), indent + 1)
            out = out ++ self.dump_typed_expr_tree(self.ast.get_extra(extra_start + i * 3 + 2), indent + 1)
        return out

    out

fn Sema.emit_typed_expr_tree(self: Sema, node: i32, indent: i32):
    if node == 0:
        return
    if node < 0 or node >= self.ast.node_count():
        return
    if indent > 80:
        return

    let kind = self.ast.kind(node)
    let start = self.ast.get_start(node)
    let end = self.ast.get_end(node)
    let has_typed_expr = self.typed_expr_types.contains(node)

    if has_typed_expr:
        let tid = self.typed_expr_types.get(node).unwrap()
        emit_typed_indent(indent)
        print("expr ")
        print(typed_expr_kind_name(kind))
        print(f" span={start}..{end} : ")
        print(self.type_name(tid))
        print("\n")

    if kind == NodeKind.NK_LET_BINDING:
        if self.typed_binding_types.contains(node):
            let name_sym = if self.typed_binding_names.contains(node): self.typed_binding_names.get(node).unwrap() else: self.ast.get_data0(node)
            let is_mut = if self.typed_binding_muts.contains(node): self.typed_binding_muts.get(node).unwrap() else: (self.ast.get_data2(node) % 2)
            emit_typed_indent(indent + 1)
            print("bind ")
            print(self.safe_symbol_text(name_sym))
            if is_mut != 0:
                print(" (mut)")
            print(": ")
            print(self.type_name(self.typed_binding_types.get(node).unwrap()))
            print("\n")

    if kind == NodeKind.NK_BINARY:
        self.emit_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        self.emit_typed_expr_tree(self.ast.get_data2(node), indent + 1)
        return

    if kind == NodeKind.NK_UNARY:
        self.emit_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        return

    if kind == NodeKind.NK_CALL:
        let extra_start = self.ast.get_data1(node)
        let arg_count = self.ast.get_data2(node)
        let safe_arg_count = self.clamp_extra_span_count(extra_start, arg_count, 1, 64)
        self.emit_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        for ai in 0..safe_arg_count:
            self.emit_typed_expr_tree(self.ast.get_extra(extra_start + ai), indent + 1)
        return

    if kind == NodeKind.NK_FIELD_ACCESS:
        self.emit_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        return

    if kind == NodeKind.NK_OPTIONAL_CHAIN:
        let extra_start = self.ast.get_data2(node)
        if extra_start < 0 or extra_start >= self.ast.extra_len():
            return
        let arg_count = self.ast.get_extra(extra_start)
        let safe_arg_count = self.clamp_extra_span_count(extra_start + 1, arg_count, 1, 64)
        self.emit_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        for ai in 0..safe_arg_count:
            self.emit_typed_expr_tree(self.ast.get_extra(extra_start + 1 + ai), indent + 1)
        return

    if kind == NodeKind.NK_INDEX:
        self.emit_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        self.emit_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        return

    if kind == NodeKind.NK_SLICE:
        self.emit_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        self.emit_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        self.emit_typed_expr_tree(self.ast.get_data2(node), indent + 1)
        return

    if kind == NodeKind.NK_BLOCK:
        let extra_start = self.ast.get_data0(node)
        let stmt_count = self.ast.get_data1(node)
        let tail = self.ast.get_data2(node)
        let safe_stmt_count = self.clamp_extra_span_count(extra_start, stmt_count, 1, 256)
        for si in 0..safe_stmt_count:
            self.emit_typed_expr_tree(self.ast.get_extra(extra_start + si), indent + 1)
        self.emit_typed_expr_tree(tail, indent + 1)
        return

    if kind == NodeKind.NK_IF_EXPR:
        self.emit_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        self.emit_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        self.emit_typed_expr_tree(self.ast.get_data2(node), indent + 1)
        return

    if kind == NodeKind.NK_RETURN:
        self.emit_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        return

    if kind == NodeKind.NK_LET_BINDING:
        self.emit_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        return

    if kind == NodeKind.NK_LET_ELSE:
        self.emit_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        self.emit_typed_expr_tree(self.ast.get_data2(node), indent + 1)
        return

    if kind == NodeKind.NK_TUPLE_DESTRUCTURE:
        self.emit_typed_expr_tree(self.ast.get_data2(node), indent + 1)
        return

    if kind == NodeKind.NK_ASSIGN:
        self.emit_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        self.emit_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        return

    if kind == NodeKind.NK_TUPLE:
        let extra_start = self.ast.get_data0(node)
        let count = self.ast.get_data1(node)
        let safe_count = self.clamp_extra_span_count(extra_start, count, 1, 64)
        for i in 0..safe_count:
            self.emit_typed_expr_tree(self.ast.get_extra(extra_start + i), indent + 1)
        return

    if kind == NodeKind.NK_RANGE:
        self.emit_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        self.emit_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        return

    if kind == NodeKind.NK_VARIANT_SHORTHAND:
        let extra_start = self.ast.get_data1(node)
        let arg_count = self.ast.get_data2(node)
        let safe_arg_count = self.clamp_extra_span_count(extra_start, arg_count, 1, 64)
        for i in 0..safe_arg_count:
            self.emit_typed_expr_tree(self.ast.get_extra(extra_start + i), indent + 1)
        return

    if kind == NodeKind.NK_AWAIT or kind == NodeKind.NK_ASYNC_BLOCK or kind == NodeKind.NK_SPAWN or kind == NodeKind.NK_GROUPED or kind == NodeKind.NK_DEFER or kind == NodeKind.NK_ERRDEFER or kind == NodeKind.NK_YIELD or kind == NodeKind.NK_COMPTIME:
        self.emit_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        return

    if kind == NodeKind.NK_PIPELINE:
        self.emit_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        self.emit_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        return

    if kind == NodeKind.NK_WHILE:
        self.emit_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        self.emit_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        return

    if kind == NodeKind.NK_LOOP:
        self.emit_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        return

    if kind == NodeKind.NK_FOR:
        self.emit_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        self.emit_typed_expr_tree(self.ast.get_data2(node), indent + 1)
        return

    if kind == NodeKind.NK_BREAK:
        self.emit_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        return

    if kind == NodeKind.NK_ARRAY_LIT:
        let extra_start = self.ast.get_data0(node)
        let count = self.ast.get_data1(node)
        let safe_count = self.clamp_extra_span_count(extra_start, count, 1, 128)
        for i in 0..safe_count:
            self.emit_typed_expr_tree(self.ast.get_extra(extra_start + i), indent + 1)
        return

    if kind == NodeKind.NK_ARRAY_COMPREHENSION:
        self.emit_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        self.emit_typed_expr_tree(self.ast.get_data2(node), indent + 1)
        return

    if kind == NodeKind.NK_STRUCT_LIT:
        let extra_start = self.ast.get_data1(node)
        let field_count = self.ast.get_data2(node)
        let safe_field_count = self.clamp_extra_span_count(extra_start, field_count, 2, 128)
        for i in 0..safe_field_count:
            self.emit_typed_expr_tree(self.ast.get_extra(extra_start + i * 2 + 1), indent + 1)
        return

    if kind == NodeKind.NK_MATCH:
        let extra_start = self.ast.get_data1(node)
        let arm_count = self.ast.get_data2(node)
        let safe_arm_count = self.clamp_extra_span_count(extra_start, arm_count, 1, 128)
        self.emit_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        for i in 0..safe_arm_count:
            let arm = self.ast.get_extra(extra_start + i)
            let guard = self.ast.get_data2(arm)
            if guard != 0:
                self.emit_typed_expr_tree(guard, indent + 1)
            self.emit_typed_expr_tree(self.ast.get_data1(arm), indent + 1)
        return

    if kind == NodeKind.NK_ENUM_VARIANT:
        let extra_start = self.ast.get_data2(node)
        if extra_start < 0 or extra_start >= self.ast.extra_len():
            return
        let arg_count = self.ast.get_extra(extra_start)
        let safe_arg_count = self.clamp_extra_span_count(extra_start + 1, arg_count, 1, 64)
        for i in 0..safe_arg_count:
            self.emit_typed_expr_tree(self.ast.get_extra(extra_start + 1 + i), indent + 1)
        return

    if kind == NodeKind.NK_CLOSURE:
        self.emit_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        return

    if kind == NodeKind.NK_CAST:
        self.emit_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        return

    if kind == NodeKind.NK_WITH_EXPR:
        self.emit_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        self.emit_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        return

    if kind == NodeKind.NK_RECORD_UPDATE:
        let extra_start = self.ast.get_data1(node)
        let field_count = self.ast.get_data2(node)
        self.emit_typed_expr_tree(self.ast.get_data0(node), indent + 1)
        let safe_field_count = self.clamp_extra_span_count(extra_start, field_count, 2, 128)
        for i in 0..safe_field_count:
            self.emit_typed_expr_tree(self.ast.get_extra(extra_start + i * 2 + 1), indent + 1)
        return

    if kind == NodeKind.NK_ASYNC_SCOPE:
        self.emit_typed_expr_tree(self.ast.get_data1(node), indent + 1)
        return

    if kind == NodeKind.NK_SELECT_AWAIT:
        let extra_start = self.ast.get_data0(node)
        let arm_count = self.ast.get_data1(node)
        let safe_arm_count = self.clamp_extra_span_count(extra_start, arm_count, 3, 32)
        for i in 0..safe_arm_count:
            self.emit_typed_expr_tree(self.ast.get_extra(extra_start + i * 3 + 1), indent + 1)
            self.emit_typed_expr_tree(self.ast.get_extra(extra_start + i * 3 + 2), indent + 1)
        return

// ── Type name formatting ─────────────────────────────────────────

fn Sema.type_name(self: Sema, tid: i32) -> str:
    let resolved = self.resolve_alias(tid)
    let tk = self.get_type_kind(resolved)
    if tk == TypeKind.TY_ERR:
        return "<error>"
    if tk == TypeKind.TY_INT:
        let bits = self.get_type_d0(resolved)
        let signed = self.get_type_d1(resolved)
        let is_ptr_width = self.get_type_d2(resolved)
        if is_ptr_width != 0:
            return if signed != 0: "isize" else: "usize"
        if bits == 8:
            return if signed != 0: "i8" else: "u8"
        if bits == 16:
            return if signed != 0: "i16" else: "u16"
        if bits == 32:
            return if signed != 0: "i32" else: "u32"
        if bits == 64:
            return if signed != 0: "i64" else: "u64"
        if bits == 128:
            return if signed != 0: "i128" else: "u128"
        return "<int>"
    if tk == TypeKind.TY_FLOAT:
        if self.get_type_d0(resolved) == 32:
            return "f32"
        return "f64"
    if tk == TypeKind.TY_BOOL:
        return "bool"
    if tk == TypeKind.TY_VOID:
        return "void"
    if tk == TypeKind.TY_NEVER:
        return "Never"
    if tk == TypeKind.TY_STR:
        return "str"
    if tk == TypeKind.TY_STRUCT:
        return self.safe_symbol_text(self.get_type_d0(resolved))
    if tk == TypeKind.TY_ENUM:
        return self.safe_symbol_text(self.get_type_d0(resolved))
    if tk == TypeKind.TY_ARRAY:
        let size = self.get_type_d1(resolved)
        return f"[{size}]" ++ self.type_name(self.get_type_d0(resolved))
    if tk == TypeKind.TY_SLICE:
        return "[]" ++ self.type_name(self.get_type_d0(resolved))
    if tk == TypeKind.TY_TUPLE:
        let te_start = self.get_type_d0(resolved)
        let elem_count = self.get_type_d1(resolved)
        var out = "("
        for ei in 0..elem_count:
            if ei > 0:
                out = out ++ ", "
            out = out ++ self.type_name(self.type_extra.get((te_start + ei) as i64))
        if elem_count == 1:
            out = out ++ ","
        return out ++ ")"
    if tk == TypeKind.TY_RANGE:
        let elem_name = self.type_name(self.get_type_d0(resolved))
        if self.get_type_d1(resolved) != 0:
            return "RangeInclusive[" ++ elem_name ++ "]"
        return "Range[" ++ elem_name ++ "]"
    if tk == TypeKind.TY_FN:
        let te_start = self.get_type_d0(resolved)
        let param_count = self.get_type_d1(resolved)
        var out = "fn("
        for pi in 0..param_count:
            if pi > 0:
                out = out ++ ", "
            out = out ++ self.type_name(self.type_extra.get((te_start + pi) as i64))
        return out ++ ") -> " ++ self.type_name(self.get_type_d2(resolved))
    if tk == TypeKind.TY_PTR:
        let pointee = self.type_name(self.get_type_d0(resolved))
        if self.get_type_d1(resolved) != 0:
            return "*mut " ++ pointee
        return "*const " ++ pointee
    if tk == TypeKind.TY_REF:
        let pointee = self.type_name(self.get_type_d0(resolved))
        if self.get_type_d1(resolved) != 0:
            return "&mut " ++ pointee
        return "&" ++ pointee
    if tk == TypeKind.TY_ALIAS:
        return "<alias>"
    if tk == TypeKind.TY_GENERIC_FN:
        return "<generic>"
    if tk == TypeKind.TY_TRAIT_OBJ:
        return "dyn " ++ self.safe_symbol_text(self.get_type_d0(resolved))
    if tk == TypeKind.TY_GENERIC_INST:
        let base_name = self.safe_symbol_text(self.get_type_d0(resolved))
        let arg_count = self.get_type_d2(resolved)
        let extra_start = self.get_type_d1(resolved)
        var out = base_name ++ "["
        for ai in 0..arg_count:
            if ai > 0:
                out = out ++ ", "
            out = out ++ self.type_name(self.type_extra.get((extra_start + ai) as i64))
        return out ++ "]"
    "<unknown>"
