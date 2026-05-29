// SemaCheck — type expression resolution, expression type checking, generic/trait resolution.

use Sema
use Ast
use BorrowCfg
use ComptimeEval
use ComptimeValue
use CapabilityRegistry
use Span
use Diagnostic
use InternPool
use TypeLayout
use render

extern fn with_write(s: str) -> void
extern fn with_eprint(s: str) -> void
extern fn with_fs_file_exists(path: str) -> i32
extern fn with_str_eq(a: str, b: str) -> i32
extern fn str_from_byte(b: i32) -> str
extern fn with_regex_compile(pattern: str, options: i32, err_code: *mut i32, err_offset: *mut i32) -> *const i8
extern fn with_regex_error_message(code: i32) -> str
extern fn with_regex_code_free(code: *const i8) -> void
extern fn with_regex_capture_count(code: *const i8) -> i32
extern fn with_regex_capture_name_count(code: *const i8) -> i32
extern fn with_regex_capture_name_at(code: *const i8, index: i32) -> str

// docs/mut.md Rev 8 — P12 lockdown active. `&mut T` is rejected.
const STRICT_NO_MUT_REF: i32 = 1

type SemaDynTraitMethodInfo {
    ok: i32,
    param_start: i32,
    param_count: i32,
    ret_node: i32,
}

fn sema_dyn_trait_method_missing -> SemaDynTraitMethodInfo:
    SemaDynTraitMethodInfo {
        ok: 0,
        param_start: 0,
        param_count: 0,
        ret_node: 0,
    }

fn sema_node_is_zero_int_literal(ast: AstPool, node: i32) -> bool:
    if node == 0 or ast.kind(node) != NodeKind.NK_INT_LIT:
        return false
    let fast = ast.int_literal_fast_i64(node as NodeId)
    fast.ok != 0 and fast.value == 0

fn sema_regex_compile_options(flags: str) -> i32:
    var options = 0
    var i: i64 = 0
    while i < flags.len():
        let ch = flags.byte_at(i)
        if ch == 103:
            // g is a With-level iteration/replacement flag, not a PCRE2 compile option.
            options = options
        else if ch == 105:
            options = options | 8
        else if ch == 109:
            options = options | 1024
        else if ch == 115:
            options = options | 32
        else if ch == 120:
            options = options | 128
        else if ch == 85:
            options = options | 262144
        else if ch == 117:
            options = options | 524288 | 131072
        else:
            return -1
        i = i + 1
    options

fn sema_dirname(path: str) -> str:
    var last_slash = -1
    for i in 0..path.len() as i32:
        if path.byte_at(i as i64) == 47:
            last_slash = i
    if last_slash < 0:
        return ""
    path.slice(0, last_slash as i64)

fn sema_resolve_embed_file_path(source_path: str, raw_path: str) -> str:
    if raw_path.len() > 0 and raw_path.byte_at(0) == 47:
        return raw_path
    let dir = sema_dirname(source_path)
    if dir.len() == 0:
        return raw_path
    dir ++ "/" ++ raw_path

fn Sema.can_access_tool_capability_internals(self: Sema) -> bool:
    if capability_registry_is_std_build_path(self.current_module_path) or capability_registry_is_std_compiler_path(self.current_module_path):
        return true
    self.tool_mode_entry_path.len() > 0 and self.current_module_path == self.tool_mode_entry_path

fn Sema.named_type_path_for(self: Sema, sym: i32, tid: i32) -> str:
    var i = self.named_type_candidate_syms.len() as i32 - 1
    while i >= 0:
        if self.named_type_candidate_syms.get(i as i64) == sym and self.named_type_candidate_tids.get(i as i64) == tid:
            return self.named_type_candidate_paths.get(i as i64)
        i = i - 1
    ""

fn Sema.tool_capability_kind_for_type(self: Sema, tid: i32) -> i32:
    if tid == 0:
        return CapabilityKind.CK_NONE
    let resolved = self.resolve_alias(tid as TypeId)
    let tk = self.get_type_kind(resolved)
    if tk != TypeKind.TY_STRUCT:
        return CapabilityKind.CK_NONE
    let type_sym = self.get_type_d0(resolved)
    let type_name = self.pool_resolve(type_sym)
    let type_path = self.named_type_path_for(type_sym, resolved)
    capability_registry_lookup(type_path, type_name)

fn Sema.is_tool_capability_type(self: Sema, tid: i32) -> bool:
    capability_registry_is_capability(self.tool_capability_kind_for_type(tid))

fn Sema.reject_tool_capability_construction_if_needed(self: Sema, type_sym: i32, tid: i32, node: i32) -> bool:
    if not self.is_tool_capability_type(tid):
        return false
    if self.can_access_tool_capability_internals():
        return false
    self.emit_error("tool capability '" ++ self.pool_resolve(type_sym) ++ "' can only be constructed by the compiler driver", node)
    true

fn Sema.unwrap_builtin_arg_distinct(self: Sema, tid: i32) -> i32:
    if tid == 0:
        return 0
    let resolved = self.resolve_alias(tid as TypeId)
    if self.get_type_kind(resolved) != TypeKind.TY_STRUCT:
        return tid
    let name_sym = self.get_type_d0(resolved)
    if name_sym == 0 or not self.distinct_type_names.contains(name_sym):
        return tid
    if self.get_type_d2(resolved) != 1:
        return tid
    let te_start = self.get_type_d1(resolved)
    if te_start < 0:
        return tid
    let inner_tid = self.type_extra.get((te_start + 1) as i64)
    if inner_tid != 0:
        return inner_tid
    tid

fn Sema.builtin_arg_type_compatible(self: Sema, expected: i32, actual: i32) -> i32:
    if expected == 0 or actual == 0:
        return 1
    if self.types_compatible(expected, actual) != 0:
        return 1
    if self.arithmetic_result_type(expected, actual) != 0:
        return 1
    let actual_unwrapped = self.unwrap_builtin_arg_distinct(actual)
    if actual_unwrapped != actual:
        if self.types_compatible(expected, actual_unwrapped) != 0:
            return 1
        if self.arithmetic_result_type(expected, actual_unwrapped) != 0:
            return 1
    0

// ── Type expression resolution ───────────────────────────────────

fn Sema.resolve_type_expr(self: Sema, node: i32) -> TypeId:
    if node == 0:
        return 0 as TypeId

    let kind = self.ast.kind(node)

    if kind == NodeKind.NK_INDEX:
        return self.resolve_type_level_arg_expr(node) as TypeId

    if kind == NodeKind.NK_TYPE_NAMED:
        let sym = self.ast.get_data0(node)
        let prim = self.primitive_type_by_sym(sym)
        if prim != 0:
            return prim as TypeId
        let subst = self.lookup_generic_subst(sym)
        if subst != 0:
            return subst as TypeId
        let named_tid = self.lookup_named_type_visible(sym)
        if named_tid != 0 and (self.collecting_types != 0 or self.is_ci_visible(sym) != 0):
            return named_tid as TypeId
        let sym_text = self.pool_resolve_symbol(sym)
        let canonical_sym = if sym_text.len() > 0: self.pool_lookup_symbol(sym_text) else: 0
        if canonical_sym != 0 and canonical_sym != sym:
            let canonical_prim = self.primitive_type_by_sym(canonical_sym)
            if canonical_prim != 0:
                return canonical_prim as TypeId
            let canonical_subst = self.lookup_generic_subst(canonical_sym)
            if canonical_subst != 0:
                return canonical_subst as TypeId
            let canonical_tid = self.lookup_named_type_visible(canonical_sym)
            if canonical_tid != 0 and (self.collecting_types != 0 or self.is_ci_visible(canonical_sym) != 0):
                return canonical_tid as TypeId
            if canonical_sym == self.syms.self_type:
                return 0 as TypeId
        // Self is resolved at codegen time
        if sym == self.syms.self_type:
            return 0 as TypeId
        if self.collecting_types != 0:
            return 0 as TypeId
        self.debug_unknown_type(sym, node, "resolve_type_expr")
        self.emit_unknown_type_error(sym, node)
        return 0 as TypeId

    if kind == NodeKind.NK_TYPE_ASSOC:
        let base_sym = self.ast.get_data0(node)
        let assoc_sym = self.ast.get_data1(node)
        if base_sym == self.syms.self_type:
            if self.assoc_type_bindings.contains(assoc_sym):
                return self.assoc_type_bindings.get(assoc_sym).unwrap() as TypeId
        // Type parameter: look up concrete type via generic substitution
        let concrete = self.lookup_generic_subst(base_sym)
        if concrete != 0:
            let concrete_sym = self.get_type_d0(concrete as TypeId)
            if concrete_sym != 0:
                // Find which trait provides assoc_sym for concrete_sym
                for ti in 0..self.trait_name_syms.len() as i32:
                    let at_start_t = self.trait_assoc_starts.get(ti as i64)
                    let at_count_t = self.trait_assoc_counts.get(ti as i64)
                    for ai in 0..at_count_t:
                        if self.trait_assoc_names.get((at_start_t + ai) as i64) == assoc_sym:
                            let trait_sym_t = self.trait_name_syms.get(ti as i64)
                            if self.select_trait_impl(concrete_sym, trait_sym_t) != 0:
                                let resolved_at = self.resolve_impl_assoc_type(concrete_sym, trait_sym_t, assoc_sym)
                                if resolved_at != 0:
                                    return resolved_at as TypeId
        return 0 as TypeId

    if kind == NodeKind.NK_TYPE_GENERIC:
        return self.resolve_generic_type(node) as TypeId

    if kind == NodeKind.NK_TYPE_PTR:
        let pointee = self.resolve_type_expr(self.ast.get_data0(node))
        let is_mut = self.ast.get_data1(node)
        let is_volatile = self.ast.get_data2(node)
        return self.ensure_exact_type(TypeKind.TY_PTR, pointee as i32, is_mut, is_volatile)

    if kind == NodeKind.NK_TYPE_REF:
        let pointee = self.resolve_type_expr(self.ast.get_data0(node))
        let is_mut = self.ast.get_data1(node)
        // docs/mut.md Rev 8 §15.1 — at P12 lockdown, reject `&mut T` in
        // type position. Use `mut self: Self`, `*mut T` (FFI), or
        // owned-by-value parameters per the migration guide §16.
        if STRICT_NO_MUT_REF != 0 and is_mut != 0:
            self.emit_error("`&mut T` is not part of safe With (§15.1); use mut self / *mut T (unsafe) / owned-by-value parameter", node)
        return self.ensure_exact_type(TypeKind.TY_REF, pointee as i32, is_mut, 0)

    if kind == NodeKind.NK_TYPE_FN:
        let extra_start = self.ast.get_data0(node)
        let param_count = self.ast.get_data1(node)
        let ret_node = self.ast.get_data2(node)
        let param_types: Vec[i32] = Vec.new()
        for pi in 0..param_count:
            let p_node = self.ast.get_extra(extra_start + pi)
            param_types.push(self.resolve_type_expr(p_node) as i32)
        let ret = self.resolve_type_expr(ret_node)
        return self.ensure_fn_type(param_types, param_count, ret)

    if kind == NodeKind.NK_TYPE_ARRAY:
        let elem = self.resolve_type_expr(self.ast.get_data0(node))
        let size = self.ast.get_data1(node)
        return self.ensure_exact_type(TypeKind.TY_ARRAY, elem as i32, size, 0)

    if kind == NodeKind.NK_TYPE_SLICE:
        let elem = self.resolve_type_expr(self.ast.get_data0(node))
        return self.ensure_exact_type(TypeKind.TY_SLICE, elem as i32, 0, 0)

    if kind == NodeKind.NK_TYPE_TUPLE:
        let extra_start = self.ast.get_data0(node)
        let elem_count = self.ast.get_data1(node)
        if elem_count == 0:
            return self.ty_void
        let tuple_elems: Vec[i32] = Vec.new()
        for ei in 0..elem_count:
            let e_node = self.ast.get_extra(extra_start + ei)
            tuple_elems.push(self.resolve_type_expr(e_node) as i32)
        return self.ensure_tuple_type(tuple_elems, elem_count)

    if kind == NodeKind.NK_TYPE_OPTIONAL:
        let inner = self.resolve_type_expr(self.ast.get_data0(node))
        if inner == 0:
            return 0 as TypeId
        if not self.named_types.contains(self.syms.option):
            return 0 as TypeId
        let opt_args: Vec[i32] = Vec.new()
        opt_args.push(inner as i32)
        return self.ensure_generic_inst_type(self.syms.option, opt_args, 1)

    if kind == NodeKind.NK_TYPE_TRAIT_OBJ:
        let trait_sym = self.ast.get_data0(node)
        if not self.lang_trait_syms.contains(trait_sym) and not self.trait_lookup.contains(trait_sym):
            self.emit_error("unknown trait", node)
            return 0 as TypeId
        if self.ast.get_data1(node) != TYPE_TRAIT_OBJECT_IMPL and self.ensure_trait_object_safe(trait_sym, node) == 0:
            return 0 as TypeId
        return self.ensure_exact_type(TypeKind.TY_TRAIT_OBJ, trait_sym, 0, 0)

    if kind == NodeKind.NK_TYPE_INFERRED:
        return 0 as TypeId

    // @TypeOf(expr) — in generic functions, resolved at monomorphization time
    // via resolve_generic_return_type_node. Return a placeholder here.
    if kind == NodeKind.NK_TYPE_TYPEOF:
        return self.ty_i32

    0 as TypeId

fn Sema.resolve_type_level_arg_expr(self: Sema, node: i32) -> i32:
    if node == 0:
        return 0
    let kind = self.ast.kind(node)
    if kind == NodeKind.NK_IDENT or kind == NodeKind.NK_TYPE_NAMED:
        let sym = self.ast.get_data0(node)
        let prim = self.primitive_type_by_sym(sym)
        if prim != 0:
            return prim as i32
        let subst = self.lookup_generic_subst(sym)
        if subst != 0:
            return subst as i32
        return self.lookup_named_type_visible(sym)
    if kind == NodeKind.NK_TYPE_GENERIC:
        return self.resolve_generic_type(node)
    if kind == NodeKind.NK_INDEX:
        let base = self.ast.get_data0(node)
        if self.ast.kind(base) != NodeKind.NK_IDENT:
            return 0
        var base_sym = self.ast.get_data0(base)
        var base_tid = self.lookup_named_type_visible(base_sym)
        if base_tid == 0:
            let canonical_base = self.canonical_symbol_by_text(base_sym)
            if canonical_base != 0 and canonical_base != base_sym:
                base_sym = canonical_base
                base_tid = self.lookup_named_type_visible(base_sym)
        if base_tid == 0:
            return 0
        let arg1_node = self.ast.get_data1(node)
        let arg1_ty = self.resolve_type_level_arg_expr(arg1_node)
        if arg1_ty == 0:
            return 0
        let args: Vec[i32] = Vec.new()
        args.push(arg1_ty)
        var arg_count = 1
        let arg2_node = self.ast.get_data2(node)
        if arg2_node != 0:
            let arg2_ty = self.resolve_type_level_arg_expr(arg2_node)
            if arg2_ty == 0:
                return 0
            args.push(arg2_ty)
            arg_count = 2
        return self.ensure_generic_inst_type(base_sym, args, arg_count) as i32
    self.resolve_type_expr(node) as i32

// ── Pass 2: Check function bodies ────────────────────────────────

fn Sema.update_module_context(self: Sema, di: i32):
    if di < self.decl_source_paths.len() as i32:
        let path = self.decl_source_paths.get(di as i64)
        if path != self.current_module_path:
            self.current_module_path = path
            if self.scoping_active != 0:
                let path_sym = self.pool_intern(path)
                self.current_module_has_ci = if self.ci_modules.contains(path_sym): 1 else: 0
            else:
                self.current_module_has_ci = 0

fn Sema.update_decl_source_context(self: Sema, di: i32):
    self.local_file_id = 0
    if di >= 0 and di < self.decl_source_file_ids.len() as i32:
        self.local_file_id = self.decl_source_file_ids.get(di as i64)
    self.update_module_context(di)

fn Sema.check_bodies(self: Sema):
    for di in 0..self.ast.decl_count():
        self.update_decl_source_context(di)
        let decl = self.ast.get_decl(di)
        if self.ast.kind(decl) == NodeKind.NK_FN_DECL:
            let fn_name = self.ast.get_data0(decl)
            if self.should_skip_trait_method(di, fn_name) == 0:
                // Skip shadowed functions: if a later decl registered with
                // the same name, this decl's body would be checked against
                // the wrong signature. The shadowed function is unreachable.
                if self.fn_decl_nodes.contains(fn_name):
                    let active_node = self.fn_decl_nodes.get(fn_name).unwrap()
                    if active_node != decl:
                        continue
                // Skip generic functions
                let meta = self.ast.find_fn_meta(decl)
                var tp_count = 0
                if meta >= 0:
                    tp_count = self.ast.fn_meta_tp_count(meta)
                if tp_count == 0:
                    // Skip methods on generic structs (monomorphized lazily)
                    let fn_name_sym = self.ast.get_data0(decl)
                    let fn_name_str = self.pool_resolve_symbol(fn_name_sym)
                    var is_generic_struct_method = false
                    for gsm_i in 0..fn_name_str.len() as i32:
                        if fn_name_str.byte_at(gsm_i as i64) == 46:
                            let owner_name = fn_name_str.slice(0, gsm_i as i64)
                            let owner_sym = self.pool_intern(owner_name)
                            if self.type_decl_nodes.contains(owner_sym):
                                let td_node = self.type_decl_nodes.get(owner_sym).unwrap()
                                if self.type_decl_tp_count(td_node) > 0:
                                    let gsm_p_start = self.ast.fn_meta_param_start(meta)
                                    let gsm_p_count = self.ast.fn_meta_param_count(meta)
                                    if gsm_p_count > 0:
                                        let p0_tn = self.ast.fn_param_type(gsm_p_start, 0)
                                        if p0_tn != 0 and self.ast.kind(p0_tn) == NodeKind.NK_TYPE_GENERIC:
                                            is_generic_struct_method = true
                            break
                    if not is_generic_struct_method:
                        self.update_module_context(di)
                        self.check_fn_body(decl)

fn Sema.check_fn_body_with_sig(self: Sema, node: i32, sig_idx: i32):
    let fn_name = self.ast.get_data0(node)
    let body = self.ast.get_data1(node)
    let flags = self.ast.get_data2(node)
    if sig_idx < 0:
        return

    let ret_type = self.sig_return_type(sig_idx)

    // Active borrows are per-function state.
    while self.borrow_kinds.len() > 0:
        self.borrow_kinds.pop()
        self.borrow_places.pop()
        self.borrow_fields.pop()
        self.borrow_refs.pop()
        self.borrow_path_starts.pop()
        self.borrow_path_counts.pop()

    // Push function scope
    self.push_scope()

    // Set up associated type bindings if inside a trait impl
    self.assoc_type_bindings.clear()
    if self.method_impl_nodes.contains(fn_name):
        let impl_nd = self.method_impl_nodes.get(fn_name).unwrap()
        let impl_ex = self.ast.get_data1(impl_nd)
        let impl_ac = self.ast.get_extra(impl_ex)
        for iai in 0..impl_ac:
            let at_name = self.ast.get_extra(impl_ex + 1 + iai * 2)
            let at_type_nd = self.ast.get_extra(impl_ex + 1 + iai * 2 + 1)
            let at_tid = self.resolve_type_expr(at_type_nd)
            if at_tid != 0:
                self.assoc_type_bindings.insert(at_name, at_tid as i32)

    // Add parameters to scope
    let meta = self.ast.find_fn_meta(node)
    if meta >= 0:
        let param_start = self.ast.fn_meta_param_start(meta)
        let param_count = self.ast.fn_meta_param_count(meta)
        for pi in 0..param_count:
            let p_name = self.ast.fn_param_name(param_start, pi)
            let p_tid = self.sig_param_type(sig_idx, pi)
            self.scope_put(p_name, p_tid, 0)
        let pmeta = self.ast.find_fn_param_pattern_meta(node)
        if pmeta >= 0:
            let ppat_start = self.ast.fn_param_pattern_meta_start(pmeta)
            let ppat_count = self.ast.fn_param_pattern_meta_count(pmeta)
            let apply_count = if ppat_count < param_count: ppat_count else: param_count
            for pi in 0..apply_count:
                let ppat = self.ast.fn_param_pattern_value(ppat_start + pi)
                if ppat != 0:
                    self.check_pattern(ppat, self.sig_param_type(sig_idx, pi))

    // Effect tracking: save outer state and populate for this function
    let saved_eff_sig_idx = self.current_fn_sig_idx
    while self.current_fn_param_syms.len() > 0:
        self.current_fn_param_syms.pop()
        self.current_fn_param_effs.pop()
        self.current_fn_param_origins.pop()
    if meta >= 0:
        let eff_ps = self.ast.fn_meta_param_start(meta)
        let eff_pc = self.ast.fn_meta_param_count(meta)
        for pi in 0..eff_pc:
            self.current_fn_param_syms.push(self.ast.fn_param_name(eff_ps, pi))
            self.current_fn_param_effs.push(0)
            self.current_fn_param_origins.push(0)
    self.current_fn_sig_idx = sig_idx

    // Set current return type
    let saved_ret = self.current_return_type
    let saved_gen_yield_type = self.current_gen_yield_type
    let saved_has_gen_yield_type = self.has_gen_yield_type
    let is_gen = (flags / FnFlags.GEN) % 2
    if is_gen == 1:
        self.current_return_type = self.ty_void
        self.current_gen_yield_type = ret_type as TypeId
        self.has_gen_yield_type = 1
    else:
        // For async functions, the sig return type is Task[T] but the
        // body should type-check against the unwrapped T.
        var body_ret_type = ret_type as TypeId
        if (flags / FnFlags.ASYNC) % 2 == 1:
            let resolved_ret = self.resolve_alias(ret_type as TypeId)
            if self.get_type_kind(resolved_ret) == TypeKind.TY_GENERIC_INST:
                let arg_count = self.get_generic_inst_arg_count(resolved_ret as i32)
                if arg_count > 0:
                    body_ret_type = self.get_generic_inst_arg(resolved_ret as i32, 0) as TypeId
        self.current_return_type = body_ret_type
        self.current_gen_yield_type = 0 as TypeId
        self.has_gen_yield_type = 0
    let saved_comptime = self.in_comptime_fn
    if (flags / FnFlags.COMPTIME) % 2 == 1:
        self.in_comptime_fn = self.in_comptime_fn + 1
    let saved_async = self.in_async_fn
    if (flags / FnFlags.ASYNC) % 2 == 1:
        self.in_async_fn = self.in_async_fn + 1

    // Check body — set expected type to return type for tail expression resolution.
    // For async functions, use the unwrapped body return type (T, not Task[T]).
    let body_expected_ret = self.current_return_type
    let saved_expected_et = self.expected_expr_type
    let saved_has_et = self.has_expected_type
    let saved_loop_depth = self.loop_depth
    self.loop_depth = 0
    let saved_label_registry = self.save_label_registry()
    self.reset_label_registry()
    self.collect_function_labels(body)
    self.validate_function_gotos()
    self.push_label_boundary()
    let saved_drop_type_sym = self.current_drop_type_sym
    let saved_drop_control_flow_depth = self.drop_control_flow_depth
    self.current_drop_type_sym = self.drop_owner_for_fn_symbol(fn_name)
    self.drop_control_flow_depth = 0
    if body_expected_ret != 0 and body_expected_ret != self.ty_void:
        self.expected_expr_type = body_expected_ret
        self.has_expected_type = 1
    let body_ty = self.check_expr(body)
    self.current_drop_type_sym = saved_drop_type_sym
    self.drop_control_flow_depth = saved_drop_control_flow_depth
    self.pop_label_frame()
    self.emit_unused_label_warnings()
    self.restore_label_registry(saved_label_registry)
    self.loop_depth = saved_loop_depth
    self.expected_expr_type = saved_expected_et
    self.has_expected_type = saved_has_et
    self.typed_expr_types.insert(body, body_ty as i32)
    // Tail expression bodies participate in effect inference the same way an
    // explicit `return expr` does. Without this, `fn id(x: T) -> T: x` fails
    // to record escape_value/escape_view on `x`.
    if body_ty != 0 and body_ty != self.ty_void and body_ty != self.ty_never:
        if self.is_copy(body_ty) == 0:
            self.note_place_effect(body, EFF_ESCAPE_VALUE)
        let body_kind = self.get_type_kind(self.resolve_alias(body_ty))
        if body_kind == TypeKind.TY_REF or body_kind == TypeKind.TY_PTR:
            self.note_place_effect(body, EFF_ESCAPE_VIEW)
            let body_root = self.place_root_sym(body)
            if body_root != 0:
                self.note_param_view_origin(body_root, self.compute_expr_view_origin_mask(body))
            if body_kind == TypeKind.TY_REF:
                self.check_returned_view_origins(body, body)
    let has_ret_annotation = meta >= 0 and self.ast.fn_meta_ret(meta) != 0
    if not has_ret_annotation:
        let inferred_ret = if body_ty != 0: body_ty else: self.ty_void
        self.set_sig_return_type(sig_idx, inferred_ret)
    else if body_expected_ret != 0 and body_expected_ret != self.ty_void and body_ty == self.ty_void:
        if self.type_has_default_value(body_expected_ret as i32) == 0:
            self.emit_error("return type does not implement Default", body)
    else if body_expected_ret != 0 and body_ty != 0 and body_ty != self.ty_void and body_expected_ret != self.ty_void:
        // Check tail expression type against body's expected return type
        let compat = self.types_compatible(body_expected_ret as i32, body_ty as i32)
        if compat == 0:
            let arith = self.arithmetic_result_type(body_expected_ret as i32, body_ty as i32)
            if arith == 0:
                // Implicit Ok wrapping: if body_expected_ret is Result[T, E] and body_ty is compatible with T
                var ok_wrapped = false
                let ret_resolved = self.resolve_alias(body_expected_ret)
                if self.get_type_kind(ret_resolved) == TypeKind.TY_GENERIC_INST:
                    let base_sym = self.get_generic_inst_base(ret_resolved)
                    if base_sym == self.syms.result and self.get_generic_inst_arg_count(ret_resolved) == 2:
                        let ok_type = self.get_generic_inst_arg(ret_resolved, 0)
                        if self.types_compatible(ok_type, body_ty) != 0 or self.arithmetic_result_type(ok_type, body_ty) != 0:
                            ok_wrapped = true
                if not ok_wrapped:
                    self.emit_error("return type mismatch", body)

    // @[tailrec] enforcement: verify all recursive calls are in tail position
    if (flags / FnFlags.TAILREC) % 2 == 1:
        self.verify_tail_position(body, fn_name, 1)

    // Write accumulated per-param effects into sig_param_effects.
    // For &T-typed params, clamp to {read, escape_view}: they cannot have
    // consume or escape_value since you cannot own through a reference.
    for pi in 0..self.current_fn_param_effs.len() as i32:
        var eff = self.current_fn_param_effs.get(pi as i64)
        if eff != 0:
            if sig_idx >= 0:
                let p_tid = self.sig_param_type(sig_idx, pi)
                if p_tid > 0:
                    let p_tk = self.get_type_kind(self.resolve_alias(p_tid))
                    if p_tk == TypeKind.TY_REF or p_tk == TypeKind.TY_PTR:
                        eff = eff & (EFF_READ | EFF_ESCAPE_VIEW)
            self.set_sig_param_effect(sig_idx, pi, eff)
            if (eff & EFF_ESCAPE_VIEW) != 0:
                self.set_sig_param_view_origin(sig_idx, pi, self.current_fn_param_origins.get(pi as i64))
            else:
                self.set_sig_param_view_origin(sig_idx, pi, 0)

    // @[effect(param = bits)] pin enforcement: floor and ceiling checks
    if self.ast.state.fn_effect_pin_params.contains(node):
        let pin_param_sym = self.ast.state.fn_effect_pin_params.get(node).unwrap()
        let pin_bits = if self.ast.state.fn_effect_pin_bits.contains(node): self.ast.state.fn_effect_pin_bits.get(node).unwrap() else: 0
        // Find which param index this pin covers
        var pin_pi = -1
        for pi in 0..self.current_fn_param_syms.len() as i32:
            if self.current_fn_param_syms.get(pi as i64) == pin_param_sym:
                pin_pi = pi
                break
        if pin_pi >= 0:
            let inferred = self.sig_param_effect(sig_idx, pin_pi)
            // Floor: exported effect is at least the pinned set (merge pin into stored effect)
            let merged = inferred | pin_bits
            if merged != inferred:
                self.set_sig_param_effect(sig_idx, pin_pi, merged)
            // Ceiling: inferred effects must not exceed pinned set
            let excess = inferred & (pin_bits ^ 0x1f)  // bits inferred but not pinned (among EFF_*)
            if excess != 0:
                let param_name = self.pool_resolve(pin_param_sym)
                self.emit_error(f"function body uses effects on '{param_name}' not permitted by @[effect(...)] pin; remove or expand the pin", node)

    // Restore state
    self.current_fn_sig_idx = saved_eff_sig_idx
    while self.current_fn_param_syms.len() > 0:
        self.current_fn_param_syms.pop()
        self.current_fn_param_effs.pop()
        self.current_fn_param_origins.pop()
    self.current_return_type = saved_ret
    self.current_gen_yield_type = saved_gen_yield_type
    self.has_gen_yield_type = saved_has_gen_yield_type
    self.in_comptime_fn = saved_comptime
    self.in_async_fn = saved_async
    self.pop_scope()

fn Sema.check_fn_body(self: Sema, node: i32):
    let fn_name = self.ast.get_data0(node)
    let sig_idx = self.get_sig(fn_name)
    self.check_fn_body_with_sig(node, sig_idx)

fn Sema.label_name(self: Sema, sym: i32) -> str:
    "'" ++ self.pool_resolve(sym)

fn Sema.save_label_registry(self: Sema) -> LabelRegistryState:
    LabelRegistryState {
        label_syms: self.fn_label_syms,
        label_nodes: self.fn_label_nodes,
        label_paths: self.fn_label_paths,
        label_orders: self.fn_label_orders,
        label_used: self.fn_label_used,
        goto_syms: self.fn_goto_syms,
        goto_nodes: self.fn_goto_nodes,
        goto_paths: self.fn_goto_paths,
        goto_orders: self.fn_goto_orders,
        init_nodes: self.fn_init_nodes,
        init_paths: self.fn_init_paths,
        init_orders: self.fn_init_orders,
        scope_stack: self.fn_label_scope_stack,
        next_scope_id: self.fn_label_next_scope_id,
        order_counter: self.fn_label_order_counter,
    }

fn Sema.restore_label_registry(self: Sema, state: LabelRegistryState):
    self.fn_label_syms = state.label_syms
    self.fn_label_nodes = state.label_nodes
    self.fn_label_paths = state.label_paths
    self.fn_label_orders = state.label_orders
    self.fn_label_used = state.label_used
    self.fn_goto_syms = state.goto_syms
    self.fn_goto_nodes = state.goto_nodes
    self.fn_goto_paths = state.goto_paths
    self.fn_goto_orders = state.goto_orders
    self.fn_init_nodes = state.init_nodes
    self.fn_init_paths = state.init_paths
    self.fn_init_orders = state.init_orders
    self.fn_label_scope_stack = state.scope_stack
    self.fn_label_next_scope_id = state.next_scope_id
    self.fn_label_order_counter = state.order_counter

fn Sema.reset_label_registry(self: Sema) -> void:
    self.fn_label_syms = Vec.new()
    self.fn_label_nodes = Vec.new()
    self.fn_label_paths = Vec.new()
    self.fn_label_orders = Vec.new()
    self.fn_label_used = Vec.new()
    self.fn_goto_syms = Vec.new()
    self.fn_goto_nodes = Vec.new()
    self.fn_goto_paths = Vec.new()
    self.fn_goto_orders = Vec.new()
    self.fn_init_nodes = Vec.new()
    self.fn_init_paths = Vec.new()
    self.fn_init_orders = Vec.new()
    self.fn_label_scope_stack = Vec.new()
    self.fn_label_next_scope_id = 1
    self.fn_label_order_counter = 0
    self.fn_label_scope_stack.push(1)

fn Sema.label_registry_next_order(self: Sema) -> i32:
    self.fn_label_order_counter = self.fn_label_order_counter + 1
    self.fn_label_order_counter

fn Sema.label_registry_path(self: Sema) -> str:
    var out = "|"
    for i in 0..self.fn_label_scope_stack.len() as i32:
        out = out ++ i64_to_string(self.fn_label_scope_stack.get(i as i64) as i64) ++ "|"
    out

fn sema_label_path_is_prefix(prefix: str, path: str) -> bool:
    if prefix.len() > path.len():
        return false
    path.slice(0, prefix.len()) == prefix

fn Sema.label_registry_enter_scope(self: Sema) -> void:
    self.fn_label_next_scope_id = self.fn_label_next_scope_id + 1
    self.fn_label_scope_stack.push(self.fn_label_next_scope_id)

fn Sema.label_registry_exit_scope(self: Sema):
    if self.fn_label_scope_stack.len() as i32 > 0:
        self.fn_label_scope_stack.pop()

fn Sema.find_function_label(self: Sema, sym: i32) -> i32:
    for i in 0..self.fn_label_syms.len() as i32:
        if self.fn_label_syms.get(i as i64) == sym:
            return i
    -1

fn Sema.mark_function_label_used(self: Sema, sym: i32):
    let idx = self.find_function_label(sym)
    if idx >= 0:
        self.fn_label_used.set_i32(idx as i64, 1)

fn Sema.register_function_label(self: Sema, sym: i32, node: i32, order: i32) -> void:
    if sym == 0:
        return
    let existing = self.find_function_label(sym)
    if existing >= 0:
        self.emit_error("duplicate label " ++ self.label_name(sym), node)
        return
    self.fn_label_syms.push(sym)
    self.fn_label_nodes.push(node)
    self.fn_label_paths.push(self.label_registry_path())
    self.fn_label_orders.push(order)
    self.fn_label_used.push(0)

fn Sema.register_goto_site(self: Sema, sym: i32, node: i32, order: i32) -> void:
    self.fn_goto_syms.push(sym)
    self.fn_goto_nodes.push(node)
    self.fn_goto_paths.push(self.label_registry_path())
    self.fn_goto_orders.push(order)

fn Sema.register_init_barrier(self: Sema, node: i32, order: i32) -> void:
    self.fn_init_nodes.push(node)
    self.fn_init_paths.push(self.label_registry_path())
    self.fn_init_orders.push(order)

fn Sema.collect_function_labels(self: Sema, node: i32):
    if node == 0:
        return
    let order = self.label_registry_next_order()
    let kind = self.ast.kind(node)

    if kind == NodeKind.NK_LABEL:
        self.register_function_label(self.ast.get_data0(node), node, order)
        self.collect_function_labels(self.ast.get_data1(node))
        return

    if kind == NodeKind.NK_GOTO:
        self.register_goto_site(self.ast.get_data0(node), node, order)
        return

    if kind == NodeKind.NK_LET_BINDING or kind == NodeKind.NK_LET_ELSE or kind == NodeKind.NK_TUPLE_DESTRUCTURE or kind == NodeKind.NK_DEFER or kind == NodeKind.NK_ERRDEFER:
        self.register_init_barrier(node, order)

    if kind == NodeKind.NK_CLOSURE or kind == NodeKind.NK_ASYNC_BLOCK or kind == NodeKind.NK_ASYNC_SCOPE:
        return

    if kind == NodeKind.NK_LET_BINDING:
        self.collect_function_labels(self.ast.get_data1(node))
        return

    if kind == NodeKind.NK_LET_ELSE:
        self.collect_function_labels(self.ast.get_data1(node))
        self.collect_function_labels(self.ast.get_data2(node))
        return

    if kind == NodeKind.NK_TUPLE_DESTRUCTURE:
        self.collect_function_labels(self.ast.get_data2(node))
        return

    if kind == NodeKind.NK_DEFER or kind == NodeKind.NK_ERRDEFER:
        self.collect_function_labels(self.ast.get_data0(node))
        return

    if kind == NodeKind.NK_BLOCK:
        self.label_registry_enter_scope()
        let extra_start = self.ast.get_data0(node)
        let stmt_count = self.ast.get_data1(node)
        for si in 0..stmt_count:
            self.collect_function_labels(self.ast.get_extra(extra_start + si))
        self.collect_function_labels(self.ast.get_data2(node))
        self.label_registry_exit_scope()
        return

    if kind == NodeKind.NK_IF_EXPR:
        self.collect_function_labels(self.ast.get_data0(node))
        self.label_registry_enter_scope()
        self.collect_function_labels(self.ast.get_data1(node))
        self.label_registry_exit_scope()
        if self.ast.get_data2(node) != 0:
            self.label_registry_enter_scope()
            self.collect_function_labels(self.ast.get_data2(node))
            self.label_registry_exit_scope()
        return

    if kind == NodeKind.NK_WHILE:
        self.collect_function_labels(self.ast.get_data0(node))
        self.label_registry_enter_scope()
        self.collect_function_labels(self.ast.get_data1(node))
        self.label_registry_exit_scope()
        return

    if kind == NodeKind.NK_DO_WHILE:
        self.label_registry_enter_scope()
        self.collect_function_labels(self.ast.get_data0(node))
        self.label_registry_exit_scope()
        self.collect_function_labels(self.ast.get_data1(node))
        return

    if kind == NodeKind.NK_LOOP:
        self.label_registry_enter_scope()
        self.collect_function_labels(self.ast.get_data0(node))
        self.label_registry_exit_scope()
        return

    if kind == NodeKind.NK_FOR:
        self.collect_function_labels(self.ast.get_data1(node))
        self.label_registry_enter_scope()
        self.collect_function_labels(self.ast.get_data2(node))
        self.label_registry_exit_scope()
        return

    if kind == NodeKind.NK_MATCH:
        self.collect_function_labels(self.ast.get_data0(node))
        let arm_start = self.ast.get_data1(node)
        let arm_count = self.ast.get_data2(node)
        for ai in 0..arm_count:
            self.label_registry_enter_scope()
            self.collect_function_labels(self.ast.get_extra(arm_start + ai))
            self.label_registry_exit_scope()
        return

    if kind == NodeKind.NK_MATCH_ARM:
        self.collect_function_labels(self.ast.get_data2(node))
        self.collect_function_labels(self.ast.get_data1(node))
        return

    if kind == NodeKind.NK_RETURN or kind == NodeKind.NK_GROUPED or kind == NodeKind.NK_AWAIT or kind == NodeKind.NK_SPAWN or kind == NodeKind.NK_YIELD or kind == NodeKind.NK_COMPTIME or kind == NodeKind.NK_UNSAFE_BLOCK:
        self.collect_function_labels(self.ast.get_data0(node))
        return

    if kind == NodeKind.NK_BINARY:
        self.collect_function_labels(self.ast.get_data1(node))
        self.collect_function_labels(self.ast.get_data2(node))
        return

    if kind == NodeKind.NK_MATCH_OP or kind == NodeKind.NK_NEG_MATCH_OP:
        self.collect_function_labels(self.ast.get_data0(node))
        self.collect_function_labels(self.ast.get_data1(node))
        return

    if kind == NodeKind.NK_UNARY:
        self.collect_function_labels(self.ast.get_data1(node))
        return

    if kind == NodeKind.NK_ASSIGN or kind == NodeKind.NK_COMPUTED_FIELD_ACCESS or kind == NodeKind.NK_INDEX or kind == NodeKind.NK_PIPELINE or kind == NodeKind.NK_RANGE:
        self.collect_function_labels(self.ast.get_data0(node))
        self.collect_function_labels(self.ast.get_data1(node))
        return

    if kind == NodeKind.NK_FIELD_ACCESS or kind == NodeKind.NK_CAST:
        self.collect_function_labels(self.ast.get_data0(node))
        return

    if kind == NodeKind.NK_SLICE:
        self.collect_function_labels(self.ast.get_data0(node))
        self.collect_function_labels(self.ast.get_data1(node))
        self.collect_function_labels(self.ast.get_data2(node))
        return

    if kind == NodeKind.NK_CALL:
        self.collect_function_labels(self.ast.get_data0(node))
        let extra_start2 = self.ast.get_data1(node)
        let arg_count = self.ast.get_data2(node)
        for ai in 0..arg_count:
            self.collect_function_labels(self.ast.get_extra(extra_start2 + ai))
        return

    if kind == NodeKind.NK_TUPLE or kind == NodeKind.NK_ARRAY_LIT:
        let extra_start3 = self.ast.get_data0(node)
        let count = self.ast.get_data1(node)
        for ei in 0..count:
            self.collect_function_labels(self.ast.get_extra(extra_start3 + ei))
        return

    if kind == NodeKind.NK_STRUCT_LIT:
        let extra_start4 = self.ast.get_data1(node)
        let field_count = self.ast.get_data2(node)
        for fi in 0..field_count:
            self.collect_function_labels(self.ast.get_extra(extra_start4 + fi * 2 + 1))
        return

    if kind == NodeKind.NK_RECORD_UPDATE:
        self.collect_function_labels(self.ast.get_data0(node))
        let extra_start5 = self.ast.get_data1(node)
        let field_count2 = self.ast.get_data2(node)
        for fi2 in 0..field_count2:
            self.collect_function_labels(self.ast.get_extra(extra_start5 + fi2 * 2 + 1))
        return

    if kind == NodeKind.NK_WITH_EXPR or kind == NodeKind.NK_WITH_IMPLICIT or kind == NodeKind.NK_WITH_TUPLE:
        self.collect_function_labels(self.ast.get_data0(node))
        self.label_registry_enter_scope()
        self.collect_function_labels(self.ast.get_data1(node))
        self.label_registry_exit_scope()
        return

    if kind == NodeKind.NK_SELECT_AWAIT:
        let arm_start2 = self.ast.get_data0(node)
        let arm_count2 = self.ast.get_data1(node)
        for sai in 0..arm_count2:
            self.collect_function_labels(self.ast.get_extra(arm_start2 + sai * 3 + 1))
            self.label_registry_enter_scope()
            self.collect_function_labels(self.ast.get_extra(arm_start2 + sai * 3 + 2))
            self.label_registry_exit_scope()
        return

fn Sema.validate_function_gotos(self: Sema):
    for gi in 0..self.fn_goto_syms.len() as i32:
        let target_sym = self.fn_goto_syms.get(gi as i64)
        let target_idx = self.find_function_label(target_sym)
        let goto_node = self.fn_goto_nodes.get(gi as i64)
        if target_idx < 0:
            self.emit_error("undefined goto target " ++ self.label_name(target_sym), goto_node)
            continue
        let target_path = self.fn_label_paths.get(target_idx as i64)
        let goto_path = self.fn_goto_paths.get(gi as i64)
        if not sema_label_path_is_prefix(target_path, goto_path):
            self.emit_error("goto would enter a block from outside", goto_node)
            continue
        let goto_order = self.fn_goto_orders.get(gi as i64)
        let target_order = self.fn_label_orders.get(target_idx as i64)
        if target_order > goto_order:
            for ii in 0..self.fn_init_orders.len() as i32:
                let init_order = self.fn_init_orders.get(ii as i64)
                if init_order > goto_order and init_order < target_order and self.fn_init_paths.get(ii as i64) == target_path:
                    let init_node = self.fn_init_nodes.get(ii as i64)
                    let ik = self.ast.kind(init_node)
                    if ik == NodeKind.NK_DEFER or ik == NodeKind.NK_ERRDEFER:
                        self.emit_error("goto would skip deferred cleanup registration", goto_node)
                    else:
                        self.emit_error("goto would skip variable initialization", goto_node)
                    break

fn Sema.emit_unused_label_warnings(self: Sema):
    for li in 0..self.fn_label_syms.len() as i32:
        if self.fn_label_used.get(li as i64) != 0:
            continue
        let node = self.fn_label_nodes.get(li as i64)
        let start = self.ast.get_start(node)
        let end = self.ast.get_end(node)
        var diag = Diagnostic.warn("unused label " ++ self.label_name(self.fn_label_syms.get(li as i64)), Span { file: self.local_file_id, start, end })
        diag.set_code("unused-label")
        self.diags.emit(diag)

fn Sema.push_label_boundary(self: Sema) -> void:
    self.label_syms.push(0)
    self.label_kinds.push(LabelFrameKind.LFK_BOUNDARY)
    self.label_nodes.push(0)

fn Sema.push_label_frame(self: Sema, sym: i32, kind: i32, node: i32) -> void:
    if sym != 0:
        var i = self.label_syms.len() as i32 - 1
        while i >= 0:
            let frame_kind = self.label_kinds.get(i as i64)
            if frame_kind == LabelFrameKind.LFK_BOUNDARY:
                break
            if self.label_syms.get(i as i64) == sym:
                self.emit_error("nested duplicate active label " ++ self.label_name(sym), node)
                break
            i = i - 1
    self.label_syms.push(sym)
    self.label_kinds.push(kind)
    self.label_nodes.push(node)

fn Sema.pop_label_frame(self: Sema):
    if self.label_syms.len() as i32 == 0:
        return
    self.label_syms.pop()
    self.label_kinds.pop()
    self.label_nodes.pop()

fn Sema.resolve_labeled_control(self: Sema, label: i32, node: i32) -> i32:
    var crossed_boundary = 0
    var i = self.label_syms.len() as i32 - 1
    while i >= 0:
        let frame_kind = self.label_kinds.get(i as i64)
        if frame_kind == LabelFrameKind.LFK_BOUNDARY:
            crossed_boundary = 1
            i = i - 1
            continue
        if self.label_syms.get(i as i64) == label:
            if crossed_boundary != 0:
                self.emit_error("label cannot cross function, closure, or async boundary", node)
                return -1
            return i
        i = i - 1
    self.emit_error("no enclosing loop or block labeled " ++ self.label_name(label), node)
    -1

fn Sema.resolve_innermost_loop_control(self: Sema, node: i32, word: str) -> i32:
    var i = self.label_syms.len() as i32 - 1
    while i >= 0:
        let frame_kind = self.label_kinds.get(i as i64)
        if frame_kind == LabelFrameKind.LFK_BOUNDARY:
            break
        if frame_kind == LabelFrameKind.LFK_WHILE or frame_kind == LabelFrameKind.LFK_FOR:
            return i
        i = i - 1
    self.emit_error(word ++ " outside of loop", node)
    -1

// ── Reachable comptime_error validation ─────────────────────────

fn Sema.fn_decl_has_c_export(self: Sema, fn_node: i32) -> i32:
    let meta = self.ast.find_fn_meta(fn_node)
    if meta < 0:
        return 0
    if self.ast.fn_meta_tp_count(meta) != 0:
        return 0
    let cc_sym = self.ast.fn_meta_tp_start(meta)
    if cc_sym == 0:
        return 0
    let cc_name = self.pool_resolve(cc_sym)
    if cc_name.len() > 9 and cc_name.slice(0, 9) == "c_export:":
        return 1
    0

fn Sema.fn_decl_is_comptime_error_root(self: Sema, fn_node: i32) -> i32:
    let fn_sym = self.ast.get_data0(fn_node)
    let fn_name = self.pool_resolve(fn_sym)
    if fn_name == "main":
        return 1
    let flags = self.ast.get_data2(fn_node)
    if (flags / FnFlags.ENTRY) % 2 == 1:
        return 1
    if self.fn_decl_has_c_export(fn_node) != 0:
        return 1
    0

fn Sema.emit_reachable_comptime_error(self: Sema, node: i32):
    let msg_sym = self.ast.get_data0(node)
    let msg = self.pool_resolve(msg_sym)
    if msg.len() > 0:
        self.emit_error(msg, node)
        return
    self.emit_error("comptime_error", node)

fn Sema.check_reachable_comptime_errors(self: Sema):
    if self.diags.has_errors():
        return

    self.reachable_seen = sema_new_map_i32_i32()
    self.reachable_visiting = sema_new_map_i32_i32()
    self.reachable_decl_indices = sema_new_map_i32_i32()

    for di in 0..self.ast.decl_count():
        let decl = self.ast.get_decl(di)
        if self.ast.kind(decl) == NodeKind.NK_FN_DECL:
            self.reachable_decl_indices.insert(decl, di)

    for di2 in 0..self.ast.decl_count():
        self.update_decl_source_context(di2)
        let decl2 = self.ast.get_decl(di2)
        if self.ast.kind(decl2) != NodeKind.NK_FN_DECL:
            continue
        if self.fn_decl_is_comptime_error_root(decl2) == 0:
            continue
        self.check_fn_reachable_comptime_errors(decl2)

fn Sema.update_reachable_fn_source_context(self: Sema, fn_node: i32):
    if self.reachable_decl_indices.contains(fn_node):
        self.update_decl_source_context(self.reachable_decl_indices.get(fn_node).unwrap())

fn Sema.check_reachable_call_target(self: Sema, fn_sym: i32):
    if fn_sym == 0:
        return
    if self.fn_decl_nodes.contains(fn_sym):
        let callee = self.fn_decl_nodes.get(fn_sym).unwrap()
        self.check_fn_reachable_comptime_errors(callee)
        return
    if self.generic_fn_nodes.contains(fn_sym):
        let callee2 = self.generic_fn_nodes.get(fn_sym).unwrap()
        self.check_fn_reachable_comptime_errors(callee2)

fn Sema.check_fn_reachable_comptime_errors(self: Sema, fn_node: i32):
    if self.reachable_seen.contains(fn_node):
        return
    if self.reachable_visiting.contains(fn_node):
        return
    self.reachable_visiting.insert(fn_node, 1)
    self.update_reachable_fn_source_context(fn_node)
    let body = self.ast.get_data1(fn_node)
    self.check_expr_reachable_comptime_errors(body)
    self.reachable_visiting.remove(fn_node)
    self.reachable_seen.insert(fn_node, 1)

fn Sema.check_call_reachable_comptime_errors(self: Sema, node: i32):
    let callee = self.ast.get_data0(node)
    self.check_expr_reachable_comptime_errors(callee)

    let has_resolved = self.has_resolved_call_args(node)
    if has_resolved != 0:
        let resolved_count = self.get_resolved_call_arg_count(node)
        for rai in 0..resolved_count:
            let arg = self.get_resolved_call_arg(node, rai)
            if arg > 0:
                self.check_expr_reachable_comptime_errors(arg)
    else:
        let extra_start = self.ast.get_data1(node)
        let arg_count = self.ast.get_data2(node)
        for ai in 0..arg_count:
            self.check_expr_reachable_comptime_errors(self.ast.get_extra(extra_start + ai))

    var fn_sym = 0
    if self.comp_resolved.contains(node):
        fn_sym = self.comp_resolved.get(node).unwrap()
    else if self.ast.kind(callee) == NodeKind.NK_IDENT:
        fn_sym = self.ast.get_data0(callee)
    let saved_file_id = self.local_file_id
    let saved_module_path = self.current_module_path
    let saved_module_has_ci = self.current_module_has_ci
    self.check_reachable_call_target(fn_sym)
    self.local_file_id = saved_file_id
    self.current_module_path = saved_module_path
    self.current_module_has_ci = saved_module_has_ci

fn Sema.check_expr_reachable_comptime_errors(self: Sema, node: i32):
    if node == 0:
        return
    let kind = self.ast.kind(node)

    if kind == NodeKind.NK_COMPTIME_ERROR:
        self.emit_reachable_comptime_error(node)
        return

    if kind == NodeKind.NK_CALL:
        self.check_call_reachable_comptime_errors(node)
        return

    if kind == NodeKind.NK_BINARY:
        self.check_expr_reachable_comptime_errors(self.ast.get_data1(node))
        self.check_expr_reachable_comptime_errors(self.ast.get_data2(node))
        return

    if kind == NodeKind.NK_MATCH_OP or kind == NodeKind.NK_NEG_MATCH_OP:
        self.check_expr_reachable_comptime_errors(self.ast.get_data0(node))
        self.check_expr_reachable_comptime_errors(self.ast.get_data1(node))
        return

    if kind == NodeKind.NK_UNARY:
        self.check_expr_reachable_comptime_errors(self.ast.get_data1(node))
        return

    if kind == NodeKind.NK_GROUPED or kind == NodeKind.NK_RETURN or kind == NodeKind.NK_DEFER or kind == NodeKind.NK_ERRDEFER or kind == NodeKind.NK_AWAIT or kind == NodeKind.NK_ASYNC_BLOCK or kind == NodeKind.NK_SPAWN or kind == NodeKind.NK_YIELD or kind == NodeKind.NK_UNSAFE_BLOCK:
        self.check_expr_reachable_comptime_errors(self.ast.get_data0(node))
        return

    if kind == NodeKind.NK_LABEL:
        self.check_expr_reachable_comptime_errors(self.ast.get_data1(node))
        return

    if kind == NodeKind.NK_GOTO:
        return

    if kind == NodeKind.NK_BLOCK:
        let extra_start = self.ast.get_data0(node)
        let stmt_count = self.ast.get_data1(node)
        for si in 0..stmt_count:
            self.check_expr_reachable_comptime_errors(self.ast.get_extra(extra_start + si))
        self.check_expr_reachable_comptime_errors(self.ast.get_data2(node))
        return

    if kind == NodeKind.NK_LET_BINDING:
        self.check_expr_reachable_comptime_errors(self.ast.get_data1(node))
        return

    if kind == NodeKind.NK_LET_ELSE:
        self.check_expr_reachable_comptime_errors(self.ast.get_data1(node))
        self.check_expr_reachable_comptime_errors(self.ast.get_data2(node))
        return

    if kind == NodeKind.NK_TUPLE_DESTRUCTURE:
        self.check_expr_reachable_comptime_errors(self.ast.get_data2(node))
        return

    if kind == NodeKind.NK_IF_EXPR:
        self.check_expr_reachable_comptime_errors(self.ast.get_data0(node))
        self.check_expr_reachable_comptime_errors(self.ast.get_data1(node))
        self.check_expr_reachable_comptime_errors(self.ast.get_data2(node))
        return

    if kind == NodeKind.NK_ASSIGN:
        self.check_expr_reachable_comptime_errors(self.ast.get_data0(node))
        self.check_expr_reachable_comptime_errors(self.ast.get_data1(node))
        return

    if kind == NodeKind.NK_WHILE:
        self.check_expr_reachable_comptime_errors(self.ast.get_data0(node))
        self.check_expr_reachable_comptime_errors(self.ast.get_data1(node))
        return

    if kind == NodeKind.NK_DO_WHILE:
        self.check_expr_reachable_comptime_errors(self.ast.get_data0(node))
        self.check_expr_reachable_comptime_errors(self.ast.get_data1(node))
        return

    if kind == NodeKind.NK_LOOP:
        self.check_expr_reachable_comptime_errors(self.ast.get_data0(node))
        return

    if kind == NodeKind.NK_FOR:
        self.check_expr_reachable_comptime_errors(self.ast.get_data1(node))
        self.check_expr_reachable_comptime_errors(self.ast.get_data2(node))
        return

    if kind == NodeKind.NK_BREAK:
        self.check_expr_reachable_comptime_errors(self.ast.get_data0(node))
        return

    if kind == NodeKind.NK_MATCH:
        self.check_expr_reachable_comptime_errors(self.ast.get_data0(node))
        let extra_start2 = self.ast.get_data1(node)
        let arm_count = self.ast.get_data2(node)
        for mi in 0..arm_count:
            let arm = self.ast.get_extra(extra_start2 + mi)
            self.check_expr_reachable_comptime_errors(self.ast.get_data2(arm))
            self.check_expr_reachable_comptime_errors(self.ast.get_data1(arm))
        return

    if kind == NodeKind.NK_TUPLE or kind == NodeKind.NK_ARRAY_LIT:
        let extra_start3 = self.ast.get_data0(node)
        let elem_count = self.ast.get_data1(node)
        for ei in 0..elem_count:
            self.check_expr_reachable_comptime_errors(self.ast.get_extra(extra_start3 + ei))
        return

    if kind == NodeKind.NK_STRUCT_LIT or kind == NodeKind.NK_RECORD_UPDATE:
        if kind == NodeKind.NK_RECORD_UPDATE:
            self.check_expr_reachable_comptime_errors(self.ast.get_data0(node))
        let extra_start4 = self.ast.get_data1(node)
        let field_count = self.ast.get_data2(node)
        for fi in 0..field_count:
            self.check_expr_reachable_comptime_errors(self.ast.get_extra(extra_start4 + fi * 2 + 1))
        return

    if kind == NodeKind.NK_FIELD_ACCESS:
        self.check_expr_reachable_comptime_errors(self.ast.get_data0(node))
        return

    if kind == NodeKind.NK_COMPUTED_FIELD_ACCESS:
        self.check_expr_reachable_comptime_errors(self.ast.get_data0(node))
        self.check_expr_reachable_comptime_errors(self.ast.get_data1(node))
        return

    if kind == NodeKind.NK_INDEX:
        self.check_expr_reachable_comptime_errors(self.ast.get_data0(node))
        self.check_expr_reachable_comptime_errors(self.ast.get_data1(node))
        return

    if kind == NodeKind.NK_MULTI_INDEX:
        self.check_expr_reachable_comptime_errors(self.ast.get_data0(node))
        let spec_start = self.ast.get_data1(node)
        let spec_count = self.ast.get_data2(node)
        for spi in 0..spec_count:
            let spec = self.ast.get_extra(spec_start + spi)
            self.check_expr_reachable_comptime_errors(self.ast.get_data0(spec))
            self.check_expr_reachable_comptime_errors(self.ast.get_data1(spec))
            let step_node = self.ast.get_data2(spec) % INDEX_KIND_SHIFT
            self.check_expr_reachable_comptime_errors(step_node)
        return

    if kind == NodeKind.NK_SLICE:
        self.check_expr_reachable_comptime_errors(self.ast.get_data0(node))
        self.check_expr_reachable_comptime_errors(self.ast.get_data1(node))
        self.check_expr_reachable_comptime_errors(self.ast.get_data2(node))
        return

    if kind == NodeKind.NK_CLOSURE or kind == NodeKind.NK_CAST:
        self.check_expr_reachable_comptime_errors(self.ast.get_data0(node))
        return

    if kind == NodeKind.NK_PIPELINE or kind == NodeKind.NK_RANGE or kind == NodeKind.NK_WITH_EXPR or kind == NodeKind.NK_WITH_IMPLICIT or kind == NodeKind.NK_WITH_TUPLE:
        self.check_expr_reachable_comptime_errors(self.ast.get_data0(node))
        self.check_expr_reachable_comptime_errors(self.ast.get_data1(node))
        return

    if kind == NodeKind.NK_ENUM_VARIANT:
        let extra_start5 = self.ast.get_data2(node)
        let arg_count2 = self.ast.get_extra(extra_start5)
        for vi in 0..arg_count2:
            self.check_expr_reachable_comptime_errors(self.ast.get_extra(extra_start5 + 1 + vi))
        return

    if kind == NodeKind.NK_VARIANT_SHORTHAND:
        let extra_start6 = self.ast.get_data1(node)
        let arg_count3 = self.ast.get_data2(node)
        for vsi in 0..arg_count3:
            self.check_expr_reachable_comptime_errors(self.ast.get_extra(extra_start6 + vsi))
        return

    if kind == NodeKind.NK_OPTIONAL_CHAIN:
        self.check_expr_reachable_comptime_errors(self.ast.get_data0(node))
        let extra_start7 = self.ast.get_data2(node)
        if extra_start7 != 0:
            let has_args = self.ast.get_extra(extra_start7)
            if has_args != 0:
                let arg_count4 = self.ast.get_extra(extra_start7 + 1)
                for oai in 0..arg_count4:
                    self.check_expr_reachable_comptime_errors(self.ast.get_extra(extra_start7 + 2 + oai))
        return

    if kind == NodeKind.NK_ARRAY_COMPREHENSION:
        self.check_expr_reachable_comptime_errors(self.ast.get_data0(node))
        self.check_expr_reachable_comptime_errors(self.ast.get_data2(node))
        return

    if kind == NodeKind.NK_ASYNC_SCOPE:
        self.check_expr_reachable_comptime_errors(self.ast.get_data1(node))
        return

    if kind == NodeKind.NK_SELECT_AWAIT:
        let extra_start8 = self.ast.get_data0(node)
        let arm_count2 = self.ast.get_data1(node)
        for sai in 0..arm_count2:
            let base = extra_start8 + sai * 3
            self.check_expr_reachable_comptime_errors(self.ast.get_extra(base + 1))
            self.check_expr_reachable_comptime_errors(self.ast.get_extra(base + 2))
        return

    if kind == NodeKind.NK_FSTRING:
        let seg_count = self.ast.get_data0(node)
        let extra_start9 = self.ast.get_data1(node)
        var pos = extra_start9
        for _ in 0..seg_count:
            let seg_kind = self.ast.get_extra(pos)
            if seg_kind == FStringSegmentKind.EXPR:
                self.check_expr_reachable_comptime_errors(self.ast.get_extra(pos + 1))
                self.check_expr_reachable_comptime_errors(self.ast.get_extra(pos + 2))
                pos = pos + 3
            else:
                pos = pos + 2

// ── Concrete type-checking for monomorphized generic functions ───
// Type-checks a generic function body with concrete type substitutions,
// populating typed_expr_types so MirLower has type information.
// Returns the sig index for the concrete signature.

fn Sema.check_fn_body_concrete(self: Sema, fn_node: i32, tp_syms: Vec[i32], tp_sema_tys: Vec[i32], mono_sym: i32) -> i32:
    let fn_name = self.ast.get_data0(fn_node)
    let body = self.ast.get_data1(fn_node)
    let meta = self.ast.find_fn_meta(fn_node)
    if meta < 0:
        return -1

    let tp_count = tp_syms.len() as i32

    let saved_generic_subst_param_syms = self.generic_subst_param_syms
    let saved_generic_subst_type_ids = self.generic_subst_type_ids
    let saved_types_frozen = self.types_frozen
    self.types_frozen = 0
    self.generic_subst_param_syms = Vec.new()
    self.generic_subst_type_ids = Vec.new()

    // Save named_types entries for type params and install concrete types
    let saved_named: Vec[i32] = Vec.new()
    let saved_had: Vec[i32] = Vec.new()
    for ti in 0..tp_count:
        let tp_sym = tp_syms.get(ti as i64)
        if self.named_types.contains(tp_sym):
            saved_had.push(1)
            saved_named.push(self.named_types.get(tp_sym).unwrap())
        else:
            saved_had.push(0)
            saved_named.push(0)
        let tp_sema_ty = tp_sema_tys.get(ti as i64)
        self.named_types.insert(tp_sym, tp_sema_ty)
        self.put_generic_subst(tp_sym, tp_sema_ty, fn_node)
        let tp_text = self.pool_resolve_symbol(tp_sym)
        let canonical_tp_sym = if tp_text.len() > 0: self.pool_lookup_symbol(tp_text) else: 0
        if canonical_tp_sym != 0 and canonical_tp_sym != tp_sym:
            self.put_generic_subst(canonical_tp_sym, tp_sema_ty, fn_node)

    // Resolve param types with concrete substitutions
    let param_start = self.ast.fn_meta_param_start(meta)
    let param_count = self.ast.fn_meta_param_count(meta)
    let ret_type_node = self.ast.fn_meta_ret(meta)

    let ps = self.sig_params.len() as i32
    for pi in 0..param_count:
        let p_type_node = self.ast.fn_param_type(param_start, pi)
        let p_tid = if p_type_node != 0: self.resolve_type_expr(p_type_node) else: 0
        self.sig_params.push(p_tid as i32)

    let ret_tid = if ret_type_node != 0: self.resolve_type_expr(ret_type_node) else: self.ty_void

    var sig_idx = self.get_sig(mono_sym)
    if sig_idx < 0:
        self.add_sig(mono_sym, 0, ret_tid, ps, param_count, 0)
        sig_idx = self.get_sig(mono_sym)

    // Concrete generic validation must run in the callee's own lexical
    // environment, not inside the caller's active local scopes.
    let saved_bind_names = self.bind_names
    let saved_bind_types = self.bind_types
    let saved_bind_muts = self.bind_muts
    let saved_bind_states = self.bind_states
    let saved_bind_is_task = self.bind_is_task
    let saved_bind_is_scoped_task = self.bind_is_scoped_task
    let saved_bind_is_ephemeral_task = self.bind_is_ephemeral_task
    let saved_scope_starts = self.scope_starts
    let saved_scope_name_map = self.scope_name_map
    let saved_pending_generic_binding_base = self.pending_generic_binding_base
    let saved_pending_generic_binding_call = self.pending_generic_binding_call
    let saved_pending_generic_binding_decl = self.pending_generic_binding_decl
    self.bind_names = Vec.new()
    self.bind_types = Vec.new()
    self.bind_muts = Vec.new()
    self.bind_states = Vec.new()
    self.bind_is_task = Vec.new()
    self.bind_is_scoped_task = Vec.new()
    self.bind_is_ephemeral_task = Vec.new()
    self.scope_starts = Vec.new()
    self.scope_starts.push(0)
    self.scope_name_map = HashMap.new()
    self.pending_generic_binding_base = HashMap.new()
    self.pending_generic_binding_call = HashMap.new()
    self.pending_generic_binding_decl = HashMap.new()

    // Type-check body with concrete substitutions installed. Generic bodies
    // may still become invalid after instantiation (for example `T + T`
    // specialized with `str`), so these diagnostics must stay visible.
    self.check_fn_body_with_sig(fn_node, sig_idx)

    self.bind_names = saved_bind_names
    self.bind_types = saved_bind_types
    self.bind_muts = saved_bind_muts
    self.bind_states = saved_bind_states
    self.bind_is_task = saved_bind_is_task
    self.bind_is_scoped_task = saved_bind_is_scoped_task
    self.bind_is_ephemeral_task = saved_bind_is_ephemeral_task
    self.scope_starts = saved_scope_starts
    self.scope_name_map = saved_scope_name_map
    self.pending_generic_binding_base = saved_pending_generic_binding_base
    self.pending_generic_binding_call = saved_pending_generic_binding_call
    self.pending_generic_binding_decl = saved_pending_generic_binding_decl

    // Restore named_types
    for ti in 0..tp_count:
        let tp_sym = tp_syms.get(ti as i64)
        if saved_had.get(ti as i64) == 1:
            self.named_types.insert(tp_sym, saved_named.get(ti as i64))
        else:
            self.named_types.remove(tp_sym)

    self.generic_subst_param_syms = saved_generic_subst_param_syms
    self.generic_subst_type_ids = saved_generic_subst_type_ids
    self.types_frozen = saved_types_frozen

    sig_idx

// ── Expression type checking ─────────────────────────────────────

fn Sema.is_call_expr_task(self: Sema, node: i32) -> i32:
    if node == 0 or self.ast.kind(node) != NodeKind.NK_CALL:
        return 0
    let callee = self.ast.get_data0(node)
    if self.ast.kind(callee) == NodeKind.NK_IDENT:
        let fn_sym = self.ast.get_data0(callee)
        if self.task_fns.contains(fn_sym):
            return 1
    if self.ast.kind(callee) == NodeKind.NK_FIELD_ACCESS:
        let recv = self.ast.get_data0(callee)
        let method = self.ast.get_data1(callee)
        if self.ast.kind(recv) == NodeKind.NK_IDENT and self.is_active_async_scope_symbol(self.ast.get_data0(recv)) != 0 and method == self.syms.track:
            return 1
    0

fn Sema.expr_is_tuple_of_tasks(self: Sema, node: i32) -> i32:
    if node == 0 or self.ast.kind(node) != NodeKind.NK_TUPLE:
        return 0
    let extra_start = self.ast.get_data0(node)
    let elem_count = self.ast.get_data1(node)
    if elem_count < 2 or elem_count > 12:
        return 0
    for ei in 0..elem_count:
        if self.expr_is_task_value(self.ast.get_extra(extra_start + ei)) == 0:
            return 0
    1

fn Sema.expr_is_task_value(self: Sema, node: i32) -> i32:
    if node == 0:
        return 0
    let kind = self.ast.kind(node)
    if kind == NodeKind.NK_GROUPED:
        return self.expr_is_task_value(self.ast.get_data0(node))
    if kind == NodeKind.NK_ASYNC_BLOCK:
        return 1
    if kind == NodeKind.NK_CALL:
        return self.is_call_expr_task(node)
    if kind == NodeKind.NK_IDENT:
        return self.scope_lookup_is_task(self.ast.get_data0(node))
    if kind == NodeKind.NK_INDEX or kind == NodeKind.NK_FIELD_ACCESS or kind == NodeKind.NK_OPTIONAL_CHAIN:
        // Conservative task-container handling.
        return 1
    if kind == NodeKind.NK_TUPLE:
        return self.expr_is_tuple_of_tasks(node)
    0

fn Sema.unwrap_task_type(self: Sema, ty: TypeId) -> TypeId:
    let resolved = self.resolve_alias(ty)
    if self.get_type_kind(resolved) == TypeKind.TY_GENERIC_INST:
        let base_sym = self.get_generic_inst_base(resolved as i32)
        if base_sym == self.syms.task:
            let arg_count = self.get_generic_inst_arg_count(resolved as i32)
            if arg_count > 0:
                return self.get_generic_inst_arg(resolved as i32, 0) as TypeId
    ty

fn Sema.type_is_task(self: Sema, ty: i32) -> i32:
    let resolved = self.resolve_alias(ty as TypeId)
    if self.get_type_kind(resolved) == TypeKind.TY_GENERIC_INST:
        let base_sym = self.get_generic_inst_base(resolved as i32)
        if base_sym == self.syms.task:
            return 1
    0

fn Sema.expr_is_scoped_task_value(self: Sema, node: i32) -> i32:
    if node == 0:
        return 0
    let kind = self.ast.kind(node)
    if kind == NodeKind.NK_GROUPED:
        return self.expr_is_scoped_task_value(self.ast.get_data0(node))
    if kind == NodeKind.NK_IDENT:
        return self.scope_lookup_is_scoped_task(self.ast.get_data0(node))
    if kind == NodeKind.NK_CALL:
        let callee = self.ast.get_data0(node)
        if self.ast.kind(callee) == NodeKind.NK_FIELD_ACCESS:
            let recv = self.ast.get_data0(callee)
            let method = self.ast.get_data1(callee)
            if self.ast.kind(recv) == NodeKind.NK_IDENT and self.is_active_async_scope_symbol(self.ast.get_data0(recv)) != 0 and method == self.syms.track:
                return 1
    0

fn Sema.has_live_await_guard(self: Sema) -> i32:
    var i = self.bind_names.len() as i32 - 1
    while i >= 0:
        if self.bind_states.get(i as i64) == VarState.LIVE:
            let name = self.pool_resolve(self.bind_names.get(i as i64))
            if name.ends_with("_guard"):
                return 1
        i = i - 1
    0

fn Sema.param_is_by_reference(self: Sema, tid: i32) -> i32:
    if tid == 0:
        return 0
    let resolved = self.resolve_alias(tid)
    let tk = self.get_type_kind(resolved)
    if tk == TypeKind.TY_REF or tk == TypeKind.TY_PTR:
        return 1
    0

fn Sema.expr_is_ephemeral_task(self: Sema, node: i32) -> i32:
    if node == 0:
        return 0
    let kind = self.ast.kind(node)
    if kind == NodeKind.NK_GROUPED:
        return self.expr_is_ephemeral_task(self.ast.get_data0(node))
    if kind == NodeKind.NK_IDENT:
        return self.scope_lookup_is_ephemeral_task(self.ast.get_data0(node))
    if kind == NodeKind.NK_ASYNC_BLOCK:
        return self.expr_is_ephemeral_value(self.ast.get_data0(node))
    if kind == NodeKind.NK_CALL:
        let callee = self.ast.get_data0(node)
        if self.ast.kind(callee) == NodeKind.NK_IDENT:
            let fn_sym = self.ast.get_data0(callee)
            if self.task_fns.contains(fn_sym):
                let args_start = self.ast.get_data1(node)
                let arg_count = self.ast.get_data2(node)
                for ai in 0..arg_count:
                    if self.expr_is_ephemeral_value(self.ast.get_extra(args_start + ai)) != 0:
                        return 1
        return 0
    0

fn Sema.expr_is_ephemeral_value(self: Sema, node: i32) -> i32:
    if node == 0:
        return 0
    let kind = self.ast.kind(node)
    if kind == NodeKind.NK_GROUPED:
        return self.expr_is_ephemeral_value(self.ast.get_data0(node))
    if kind == NodeKind.NK_IDENT:
        let sym = self.ast.get_data0(node)
        if self.scope_lookup_is_ephemeral_task(sym) != 0:
            return 1
        let tid = self.scope_lookup(sym)
        if tid >= 0:
            return self.type_is_ephemeral_value(tid)
        return 0
    if kind == NodeKind.NK_UNARY:
        let op = self.ast.get_data0(node)
        if op == UnaryOp.UOP_REF or op == UnaryOp.UOP_RAW_REF_CONST or op == UnaryOp.UOP_RAW_REF_MUT:
            return 1
        return self.expr_is_ephemeral_value(self.ast.get_data1(node))
    if kind == NodeKind.NK_SLICE:
        return 1
    if kind == NodeKind.NK_CALL:
        return self.expr_is_ephemeral_task(node)
    0

fn Sema.cached_or_checked_expr_type(self: Sema, node: i32) -> i32:
    if node == 0:
        return 0
    let cached = self.typed_expr_types.get(node)
    if cached.is_some():
        return cached.unwrap()
    let saved_unsafe = self.in_unsafe
    self.in_unsafe = 1
    let checked = self.check_expr(node) as i32
    self.in_unsafe = saved_unsafe
    checked

fn Sema.type_is_raw_pointer_value(self: Sema, ty: i32) -> i32:
    if ty == 0:
        return 0
    let resolved = self.resolve_alias(ty as TypeId)
    let kind = self.get_type_kind(resolved)
    if kind == TypeKind.TY_PTR:
        return 1
    if kind == TypeKind.TY_REF:
        let inner = self.resolve_alias(self.get_type_d0(resolved) as TypeId)
        if self.get_type_kind(inner) == TypeKind.TY_PTR:
            return 1
    0

fn Sema.unsafe_prefix_has_raw_access(self: Sema, node: i32) -> i32:
    if node == 0:
        return 0
    let kind = self.ast.kind(node)
    if kind == NodeKind.NK_GROUPED:
        return self.unsafe_prefix_has_raw_access(self.ast.get_data0(node))
    if kind == NodeKind.NK_CAST:
        return self.unsafe_prefix_has_raw_access(self.ast.get_data0(node))
    if kind == NodeKind.NK_UNSAFE_BLOCK:
        return self.unsafe_prefix_has_raw_access(self.ast.get_data0(node))
    if kind == NodeKind.NK_UNARY:
        let op = self.ast.get_data0(node)
        if op == UnaryOp.UOP_DEREF:
            let operand = self.ast.get_data1(node)
            if self.type_is_raw_pointer_value(self.cached_or_checked_expr_type(operand)) != 0:
                return 1
            return self.unsafe_prefix_has_raw_access(operand)
        return 0
    if kind == NodeKind.NK_INDEX:
        let base = self.ast.get_data0(node)
        if self.type_is_raw_pointer_value(self.cached_or_checked_expr_type(base)) != 0:
            return 1
        return self.unsafe_prefix_has_raw_access(base)
    if kind == NodeKind.NK_FIELD_ACCESS or kind == NodeKind.NK_COMPUTED_FIELD_ACCESS:
        let base = self.ast.get_data0(node)
        if self.type_is_raw_pointer_value(self.cached_or_checked_expr_type(base)) != 0:
            return 1
        return self.unsafe_prefix_has_raw_access(base)
    0

fn Sema.check_expr(self: Sema, node: i32) -> TypeId:
    if node == 0:
        return 0 as TypeId

    let kind = self.ast.kind(node)

    if kind == NodeKind.NK_INT_LIT:
        let suffix_ty = self.literal_suffix_type(self.ast.literal_suffix(node))
        if suffix_ty != 0:
            if not self.int_literal_fits_type(node, suffix_ty):
                self.emit_error("integer literal does not fit suffix type", node)
            self.typed_expr_types.insert(node, suffix_ty)
            return suffix_ty as TypeId
        let expected_ty = self.numeric_literal_expected_type(node)
        if expected_ty != 0:
            self.typed_expr_types.insert(node, expected_ty)
            return expected_ty as TypeId
        let fast = self.ast.int_literal_fast_i64(node as NodeId)
        if fast.ok == 0:
            self.emit_error("integer literal does not fit default type", node)
            self.typed_expr_types.insert(node, self.ty_i64 as i32)
            return self.ty_i64
        let value = fast.value
        let ty = if value < -2147483648 or value > 2147483647: self.ty_i64 else: self.ty_i32
        self.typed_expr_types.insert(node, ty as i32)
        return ty

    if kind == NodeKind.NK_FLOAT_LIT:
        let suffix = self.ast.literal_suffix(node)
        let suffix_ty = self.literal_suffix_type(suffix)
        if suffix_ty != 0:
            let resolved_suffix = self.resolve_alias(suffix_ty as TypeId)
            if self.get_type_kind(resolved_suffix) != TypeKind.TY_FLOAT:
                self.emit_error("float literal requires an f32 or f64 suffix", node)
            self.typed_expr_types.insert(node, suffix_ty)
            return suffix_ty as TypeId
        let expected_ty = self.float_literal_expected_type()
        if expected_ty != 0:
            self.typed_expr_types.insert(node, expected_ty)
            return expected_ty as TypeId
        self.typed_expr_types.insert(node, self.ty_f64 as i32)
        return self.ty_f64

    if kind == NodeKind.NK_BOOL_LIT:
        return self.ty_bool

    if kind == NodeKind.NK_STRING_LIT:
        if self.has_expected_type != 0 and self.expected_expr_type != 0:
            let expected = self.resolve_alias(self.expected_expr_type)
            if self.get_type_kind(expected) == TypeKind.TY_REF:
                let inner = self.resolve_alias(self.get_type_d0(expected) as TypeId)
                if self.get_type_kind(inner) == TypeKind.TY_STR:
                    self.typed_expr_types.insert(node, self.expected_expr_type as i32)
                    return self.expected_expr_type
        return self.ty_str

    if kind == NodeKind.NK_REGEX_LIT:
        let regex_ty = self.lookup_named_type_visible(self.syms.regex)
        if regex_ty == 0:
            self.emit_error("Regex type is not available; import std.regex", node)
            return 0 as TypeId
        self.validate_regex_literal(node)
        self.typed_expr_types.insert(node, regex_ty)
        return regex_ty as TypeId

    if kind == NodeKind.NK_FSTRING:
        return self.check_fstring(node) as TypeId

    if kind == NodeKind.NK_C_STRING_LIT:
        return self.ty_cstr_view

    if kind == NodeKind.NK_NULL_LIT:
        if self.has_expected_type != 0 and self.expected_expr_type != 0:
            let expected = self.resolve_alias(self.expected_expr_type)
            let expected_kind = self.get_type_kind(expected)
            if expected_kind == TypeKind.TY_PTR or expected_kind == TypeKind.TY_REF or self.is_option_pointer_type(expected) != 0:
                return expected
        return self.ty_const_i8_ptr

    if kind == NodeKind.NK_IDENT:
        return self.check_ident(self.ast.get_data0(node), node) as TypeId

    if kind == NodeKind.NK_MATCH_OP or kind == NodeKind.NK_NEG_MATCH_OP:
        let lhs = self.ast.get_data0(node)
        let rhs = self.ast.get_data1(node)
        let lhs_ty = self.check_expr(lhs)
        let rhs_ty = self.check_expr(rhs)
        if lhs_ty != 0 and self.types_compatible(self.ty_str as i32, lhs_ty as i32) == 0:
            self.emit_error("left side of regex match must be str-compatible", lhs)
        let regex_ty = self.lookup_named_type_visible(self.syms.regex)
        if regex_ty != 0 and rhs_ty != 0 and self.types_compatible(regex_ty, rhs_ty as i32) == 0:
            self.emit_error("right side of regex match must be Regex", rhs)
        self.typed_expr_types.insert(node, self.ty_bool as i32)
        return self.ty_bool

    if kind == NodeKind.NK_BINARY:
        return self.check_binary(node) as TypeId

    if kind == NodeKind.NK_UNARY:
        return self.check_unary(node) as TypeId

    if kind == NodeKind.NK_GROUPED:
        return self.check_expr(self.ast.get_data0(node))

    if kind == NodeKind.NK_BLOCK:
        return self.check_block(node) as TypeId

    if kind == NodeKind.NK_LABEL:
        return self.check_expr(self.ast.get_data1(node))

    if kind == NodeKind.NK_GOTO:
        if self.in_defer != 0:
            self.emit_error("goto not allowed in defer", node)
        let label = self.ast.get_data0(node)
        if self.find_function_label(label) >= 0:
            self.mark_function_label_used(label)
        return self.ty_void

    if kind == NodeKind.NK_LET_BINDING:
        return self.check_let_binding(node) as TypeId

    if kind == NodeKind.NK_IF_EXPR:
        return self.check_if_expr(node) as TypeId

    if kind == NodeKind.NK_CALL:
        return self.check_call(node) as TypeId

    if kind == NodeKind.NK_RETURN:
        return self.check_return(node) as TypeId

    if kind == NodeKind.NK_ASSIGN:
        return self.check_assign(node) as TypeId

    if kind == NodeKind.NK_WHILE:
        let cond = self.ast.get_data0(node)
        let body = self.ast.get_data1(node)
        let label = self.ast.get_data2(node)
        self.check_expr(cond)
        self.loop_depth = self.loop_depth + 1
        self.push_label_frame(label, LabelFrameKind.LFK_WHILE, node)
        var pushed_regex_capture_scope = 0
        if self.ast.kind(cond) == NodeKind.NK_MATCH_OP:
            let rhs = self.ast.get_data1(cond)
            if self.ast.kind(rhs) == NodeKind.NK_REGEX_LIT:
                self.push_scope()
                pushed_regex_capture_scope = 1
                self.regex_bind_capture_scope(rhs)
        let saved_drop_cf = self.drop_control_flow_depth
        if self.current_drop_type_sym != 0:
            self.drop_control_flow_depth = self.drop_control_flow_depth + 1
        self.check_expr(body)
        self.drop_control_flow_depth = saved_drop_cf
        if pushed_regex_capture_scope != 0:
            self.pop_scope()
        self.pop_label_frame()
        self.loop_depth = self.loop_depth - 1
        return self.ty_void

    if kind == NodeKind.NK_DO_WHILE:
        let body = self.ast.get_data0(node)
        let cond = self.ast.get_data1(node)
        let label = self.ast.get_data2(node)
        self.loop_depth = self.loop_depth + 1
        self.push_label_frame(label, LabelFrameKind.LFK_WHILE, node)
        let saved_drop_cf_dw = self.drop_control_flow_depth
        if self.current_drop_type_sym != 0:
            self.drop_control_flow_depth = self.drop_control_flow_depth + 1
        self.check_expr(body)
        self.drop_control_flow_depth = saved_drop_cf_dw
        self.pop_label_frame()
        self.loop_depth = self.loop_depth - 1
        self.check_expr(cond)
        return self.ty_void

    if kind == NodeKind.NK_LOOP:
        self.loop_depth = self.loop_depth + 1
        self.push_label_frame(self.ast.get_data1(node), LabelFrameKind.LFK_WHILE, node)
        let saved_drop_cf_loop = self.drop_control_flow_depth
        if self.current_drop_type_sym != 0:
            self.drop_control_flow_depth = self.drop_control_flow_depth + 1
        self.check_expr(self.ast.get_data0(node))
        self.drop_control_flow_depth = saved_drop_cf_loop
        self.pop_label_frame()
        self.loop_depth = self.loop_depth - 1
        return self.ty_void

    if kind == NodeKind.NK_FOR:
        return self.check_for(node) as TypeId

    if kind == NodeKind.NK_BREAK:
        if self.in_defer != 0:
            self.emit_error("break not allowed in defer", node)
        let val = self.ast.get_data0(node)
        if val != 0:
            self.emit_error("break with a value is not supported", node)
            self.check_expr(val)
        let label = self.ast.get_data1(node)
        if label != 0:
            let _ = self.resolve_labeled_control(label, node)
            self.mark_function_label_used(label)
        else:
            let _ = self.resolve_innermost_loop_control(node, "break")
        return self.ty_never

    if kind == NodeKind.NK_CONTINUE:
        if self.in_defer != 0:
            self.emit_error("continue not allowed in defer", node)
        let label = self.ast.get_data0(node)
        if label != 0:
            let target = self.resolve_labeled_control(label, node)
            if target >= 0 and self.label_kinds.get(target as i64) == LabelFrameKind.LFK_BLOCK:
                self.emit_error("cannot continue a labeled block; only loops support continue", node)
            self.mark_function_label_used(label)
        else:
            let _ = self.resolve_innermost_loop_control(node, "continue")
        return self.ty_never

    if kind == NodeKind.NK_FIELD_ACCESS:
        let result = self.check_field_access(node) as TypeId
        if result != 0:
            self.typed_expr_types.insert(node, result as i32)
        return result

    if kind == NodeKind.NK_COMPUTED_FIELD_ACCESS:
        let result = self.check_computed_field_access(node) as TypeId
        if result != 0:
            self.typed_expr_types.insert(node, result as i32)
        return result

    if kind == NodeKind.NK_INDEX:
        return self.check_index(node) as TypeId

    if kind == NodeKind.NK_MULTI_INDEX:
        return self.check_multi_index(node) as TypeId

    if kind == NodeKind.NK_SLICE:
        return self.check_slice(node) as TypeId

    if kind == NodeKind.NK_ARRAY_LIT:
        return self.check_array_literal(node) as TypeId

    if kind == NodeKind.NK_STRUCT_LIT:
        return self.check_struct_literal(node) as TypeId

    if kind == NodeKind.NK_MATCH:
        return self.check_match_expr(node) as TypeId

    if kind == NodeKind.NK_ENUM_VARIANT:
        return self.check_enum_variant(node) as TypeId

    if kind == NodeKind.NK_CLOSURE:
        return self.check_closure(node) as TypeId

    if kind == NodeKind.NK_CAST:
        let src_tid = self.check_expr_with_expected(self.ast.get_data0(node), 0 as TypeId)
        let cast_tid = self.resolve_type_expr(self.ast.get_data1(node))
        // Store resolved cast type so MIR lowering can read it without
        // calling resolve_type_expr (which would add_type on a shallow-copied Sema).
        self.typed_expr_types.insert(node, cast_tid as i32)
        if src_tid != 0 and cast_tid != 0:
            let src_resolved = self.resolve_alias(src_tid)
            let cast_resolved = self.resolve_alias(cast_tid)
            let src_kind = self.get_type_kind(src_resolved)
            let cast_kind = self.get_type_kind(cast_resolved)
            if src_kind == TypeKind.TY_ARRAY and cast_kind == TypeKind.TY_PTR:
                self.emit_error("arrays do not decay to pointers; use &array[0] as *T", node)
                return 0 as TypeId
        return cast_tid

    if kind == NodeKind.NK_PIPELINE:
        return self.check_pipeline(node) as TypeId

    if kind == NodeKind.NK_UNSAFE_BLOCK:
        if self.in_comptime_fn != 0:
            self.emit_error("unsafe is not allowed in comptime", node)
        let is_prefix = self.ast.get_data1(node) == UNSAFE_KIND_PREFIX
        let saved_unsafe = self.in_unsafe
        if is_prefix and saved_unsafe != 0:
            self.emit_warning("redundant unsafe prefix inside unsafe context", node)
        self.in_unsafe = 1
        let body = self.ast.get_data0(node)
        // Propagate expected type through unsafe block
        let unsafe_result = if self.has_expected_type != 0: self.check_expr_with_expected(body, self.expected_expr_type) else: self.check_expr(body)
        self.in_unsafe = saved_unsafe
        if is_prefix and unsafe_result != 0 and self.unsafe_prefix_has_raw_access(body) == 0:
            self.emit_error("unsafe prefix requires a raw pointer dereference or raw pointer index; use unsafe { ... } for compound unsafe expressions", node)
        return unsafe_result

    if kind == NodeKind.NK_ASM_EXPR:
        if self.in_unsafe == 0:
            self.emit_error("asm requires unsafe context", node)
        return self.ty_void

    if kind == NodeKind.NK_COMPTIME_ERROR:
        return TypeKind.TY_NEVER as TypeId

    if kind == NodeKind.NK_DEFER or kind == NodeKind.NK_ERRDEFER:
        let saved = self.in_defer
        self.in_defer = 1
        self.check_expr(self.ast.get_data0(node))
        self.in_defer = saved
        return self.ty_void

    if kind == NodeKind.NK_TUPLE:
        return self.check_tuple(node) as TypeId

    if kind == NodeKind.NK_RANGE:
        return self.check_range(node) as TypeId

    if kind == NodeKind.NK_VARIANT_SHORTHAND:
        var name = self.ast.get_data0(node)
        // Resolve for-comprehension _Empty marker
        let vs_name_str = self.pool_resolve(name)
        if vs_name_str == "_Empty" and self.has_expected_type != 0:
            let exp_resolved = self.resolve_alias(self.expected_expr_type)
            if self.enum_has_variant(exp_resolved as i32, self.syms.none) != 0:
                name = self.syms.none
            else if self.enum_has_variant(exp_resolved as i32, self.syms.err) != 0:
                name = self.syms.err
            self.comp_resolved.insert(node, name)
        let expected_variant_ty = self.expected_variant_constructor_type(name)
        if expected_variant_ty != 0:
            let resolved_variant_sym = self.qualified_enum_variant_sym(expected_variant_ty, name)
            self.comp_resolved.insert(node, resolved_variant_sym)
            self.typed_expr_types.insert(node, expected_variant_ty)
            return expected_variant_ty as TypeId
        // Fall through to variant_lookup if expected type is not an enum
        // (e.g., function return type leaking through). Only error if the
        // expected type IS an enum that doesn't have this variant.
        if self.has_expected_type != 0 and self.expected_expr_type != 0:
            let exp_resolved = self.resolve_alias(self.expected_expr_type)
            let exp_kind = self.get_type_kind(exp_resolved)
            if exp_kind == TypeKind.TY_ENUM:
                self.emit_error("enum variant shorthand does not match expected enum type", node)
                return 0 as TypeId
        if self.variant_lookup.contains(name):
            let vs_tid = self.variant_type_ids.get(name).unwrap()
            self.typed_expr_types.insert(node, vs_tid)
            return vs_tid as TypeId
        return 0 as TypeId

    if kind == NodeKind.NK_WITH_EXPR:
        return self.check_with_expr(node) as TypeId

    if kind == NodeKind.NK_WITH_TUPLE:
        return self.check_with_tuple(node) as TypeId

    if kind == NodeKind.NK_WITH_IMPLICIT:
        return self.check_with_implicit(node) as TypeId

    if kind == NodeKind.NK_RECORD_UPDATE:
        return self.check_record_update(node) as TypeId

    if kind == NodeKind.NK_LET_ELSE:
        return self.check_let_else(node) as TypeId

    if kind == NodeKind.NK_TUPLE_DESTRUCTURE:
        return self.check_tuple_destructure(node) as TypeId

    if kind == NodeKind.NK_AWAIT:
        if self.in_comptime_fn != 0:
            self.emit_error("await is not allowed in comptime", node)
        if self.has_live_await_guard() != 0:
            self.emit_error("E0701: may_suspend call while no_await_guard value is live", node)
        let inner = self.ast.get_data0(node)
        let inner_ty = self.check_expr(inner)
        if self.ast.kind(inner) == NodeKind.NK_TUPLE:
            let elem_count = self.ast.get_data1(inner)
            if elem_count < 2 or elem_count > 12:
                self.emit_error("await tuple requires between 2 and 12 tasks", node)
                return inner_ty
            if self.expr_is_tuple_of_tasks(inner) == 0:
                self.emit_error("await tuple requires Task values", node)
                return inner_ty
            // Unwrap tuple of Task[T] → tuple of T
            let extra_s = self.ast.get_data0(inner)
            let unwrapped_elems: Vec[i32] = Vec.new()
            for ei in 0..elem_count:
                let elem_node = self.ast.get_extra(extra_s + ei)
                var elem_ty = 0
                if self.typed_expr_types.contains(elem_node):
                    elem_ty = self.typed_expr_types.get(elem_node).unwrap()
                unwrapped_elems.push(self.unwrap_task_type(elem_ty) as i32)
            let te_start = self.type_extra.len() as i32
            for ei in 0..elem_count:
                self.type_extra.push(unwrapped_elems.get(ei as i64))
            let unwrapped_tuple = self.add_type(TypeKind.TY_TUPLE, te_start, elem_count, 0)
            self.typed_expr_types.insert(node, unwrapped_tuple as i32)
            return unwrapped_tuple as TypeId
        if self.expr_is_task_value(inner) == 0:
            self.emit_error("await requires a Task value", node)
        // Unwrap Task[T] → T for the .await expression type
        let await_result_ty = self.unwrap_task_type(inner_ty)
        self.typed_expr_types.insert(node, await_result_ty as i32)
        return await_result_ty


    if kind == NodeKind.NK_ASYNC_BLOCK:
        if self.in_comptime_fn != 0:
            self.emit_error("async is not allowed in comptime", node)
        let ab_saved_label_registry = self.save_label_registry()
        self.reset_label_registry()
        self.collect_function_labels(self.ast.get_data0(node))
        self.validate_function_gotos()
        self.push_label_boundary()
        let ab_body_ty = self.check_expr(self.ast.get_data0(node))
        self.pop_label_frame()
        self.emit_unused_label_warnings()
        self.restore_label_registry(ab_saved_label_registry)
        // Wrap in Task[T] — async blocks spawn a fiber and return a Task
        let ab_task_args: Vec[i32] = Vec.new()
        ab_task_args.push(ab_body_ty as i32)
        let ab_task_ty = self.ensure_generic_inst_type(self.syms.task, ab_task_args, 1)
        if ab_task_ty != 0:
            return ab_task_ty
        return ab_body_ty

    if kind == NodeKind.NK_SPAWN:
        if self.in_comptime_fn != 0:
            self.emit_error("spawn is not allowed in comptime", node)
        let inner = self.ast.get_data0(node)
        self.check_expr(inner)
        if self.expr_is_task_value(inner) == 0:
            self.emit_error("spawn requires a Task value", node)
        return self.ty_void

    if kind == NodeKind.NK_YIELD:
        if self.in_comptime_fn != 0:
            self.emit_error("yield is not allowed in comptime", node)
        let inner = self.check_expr(self.ast.get_data0(node))
        if self.has_gen_yield_type == 0:
            self.emit_error("yield used outside generator function", node)
        return self.ty_void

    if kind == NodeKind.NK_COMPTIME:
        let saved_comptime = self.in_comptime_fn
        self.in_comptime_fn = self.in_comptime_fn + 1
        let result = self.check_expr(self.ast.get_data0(node))
        self.in_comptime_fn = saved_comptime
        return result

    // docs/mutability.md — call-site passing mode annotations.
    if kind == NodeKind.NK_COPY_ARG:
        let inner = self.ast.get_data0(node)
        let ty = self.check_expr(inner)
        if self.is_copy(ty) == 0:
            if self.type_implements_trait(ty as i32, self.syms.clone_trait) == 0:
                self.emit_error("'copy' requires the type to implement Copy or Clone", node)
            else:
                // Clone-only type: MirLower will emit a .clone() call for this node.
                self.ast.state.copy_arg_needs_clone.insert(node, 1)
        self.typed_expr_types.insert(node, ty as i32)
        return ty

    if kind == NodeKind.NK_MOVE_ARG:
        let inner = self.ast.get_data0(node)
        if self.ast.kind(inner) != NodeKind.NK_IDENT:
            self.emit_error("'move' must be applied to a binding identifier", node)
            return self.check_expr(inner)
        let ty = self.check_expr(inner)
        // Explicitly mark the inner binding as moved, even for Copy types.
        let sym = self.ast.get_data0(inner)
        if self.scope_has(sym) != 0:
            self.scope_set_state(sym, VarState.MOVED)
        // If the moved binding is a parameter, record EFF_CONSUME
        self.note_param_effect(sym, EFF_CONSUME)
        self.typed_expr_types.insert(node, ty as i32)
        return ty

    if kind == NodeKind.NK_ASYNC_SCOPE:
        let body = self.ast.get_data1(node)
        let name = self.ast.get_data0(node)
        self.push_scope()
        self.scope_put(name, self.ty_void, 0)
        self.async_scope_names.push(name)
        let as_saved_label_registry = self.save_label_registry()
        self.reset_label_registry()
        self.collect_function_labels(body)
        self.validate_function_gotos()
        self.push_label_boundary()
        let result = self.check_expr(body)
        self.pop_label_frame()
        self.emit_unused_label_warnings()
        self.restore_label_registry(as_saved_label_registry)
        self.async_scope_names.pop()
        self.pop_scope()
        return result

    if kind == NodeKind.NK_SELECT_AWAIT:
        if self.has_live_await_guard() != 0:
            self.emit_error("E0701: may_suspend call while no_await_guard value is live", node)
        let extra_start = self.ast.get_data0(node)
        let arm_count = self.ast.get_data1(node)
        if arm_count <= 0:
            self.emit_error("select await requires at least one arm", node)
            return self.ty_void
        var result = self.ty_void
        for ai in 0..arm_count:
            // Each select arm is encoded as: name_sym, task_node, body_node.
            let arm_name = self.ast.get_extra(extra_start + ai * 3)
            let task = self.ast.get_extra(extra_start + ai * 3 + 1)
            let arm_body = self.ast.get_extra(extra_start + ai * 3 + 2)
            let task_ty = self.check_expr(task)
            if self.expr_is_task_value(task) == 0:
                self.emit_error("select await arm requires a Task value", task)
            let arm_result_ty = self.unwrap_task_type(task_ty)
            self.push_scope()
            self.scope_put(arm_name, arm_result_ty as i32, 0)
            self.scope_set_is_task(arm_name, 0)
            result = self.check_expr(arm_body)
            self.pop_scope()
        return result

    if kind == NodeKind.NK_ARRAY_COMPREHENSION:
        let expr = self.ast.get_data0(node)
        let binding = self.ast.get_data1(node)
        let iterable = self.ast.get_data2(node)
        self.push_scope()
        let iter_ty = self.check_expr(iterable)
        let elem_ty = self.infer_for_element_type(iter_ty as i32)
        self.scope_put(binding, elem_ty, 0)
        let result_elem = self.check_expr(expr)
        self.pop_scope()
        return self.add_type(TypeKind.TY_ARRAY, result_elem as i32, 0, 0)

    if kind == NodeKind.NK_OPTIONAL_CHAIN:
        let base = self.check_expr(self.ast.get_data0(node))
        return base

    if kind == NodeKind.NK_POISONED_EXPR:
        return 0 as TypeId

    0 as TypeId

// ── Expression checking helpers ──────────────────────────────────

fn Sema.check_ident(self: Sema, sym: i32, node: i32) -> i32:
    if sym == self.syms.file_magic:
        self.magic_ident_kinds.insert(node, SemaMagicIdentKind.FILE)
        self.typed_expr_types.insert(node, self.ty_str as i32)
        return self.ty_str as i32
    if sym == self.syms.line_magic:
        self.magic_ident_kinds.insert(node, SemaMagicIdentKind.LINE)
        self.typed_expr_types.insert(node, self.ty_u32 as i32)
        return self.ty_u32 as i32
    if sym == self.syms.fn_magic:
        self.magic_ident_kinds.insert(node, SemaMagicIdentKind.FN)
        self.typed_expr_types.insert(node, self.ty_str as i32)
        return self.ty_str as i32

    // Check local/param scope (always visible — local bindings are never c_import)
    let tid = self.scope_lookup(sym)
    if tid >= 0:
        if self.in_comptime_fn != 0 and self.is_mutable_global(sym) != 0:
            self.emit_error("mutable global access is not allowed in comptime", node)
        let state = self.scope_lookup_state(sym)
        if state == VarState.MOVED:
            if sema_debug_move_enabled() != 0:
                let name = self.pool_resolve(sym)
                with_eprint(
                    f"[moved-use] sym={name} tid={tid} node_kind={self.ast.kind(node)}"
                )
            self.emit_error("use of moved value", node)
        var final_tid = tid
        if self.has_expected_type != 0 and self.expected_expr_type != 0:
            let pending_tid = self.settle_pending_generic_binding_from_expected(sym, self.expected_expr_type as i32, node)
            if pending_tid != 0:
                final_tid = pending_tid
        self.typed_expr_types.insert(node, final_tid)
        return final_tid

    // Check function names
    if self.generic_fn_nodes.contains(sym) and self.is_ci_visible(sym) != 0:
        return 0

    let sig_idx = self.get_sig(sym)
    if sig_idx >= 0 and self.is_ci_visible(sym) != 0:
        let fn_tid = self.sig_type_ids.get(sig_idx as i64)
        self.typed_expr_types.insert(node, fn_tid)
        return fn_tid

    // Check type names
    let prim = self.primitive_type_by_sym(sym)
    if prim != 0:
        self.typed_expr_types.insert(node, prim)
        return prim
    let named_tid = self.lookup_named_type_visible(sym)
    if named_tid != 0 and self.is_ci_visible(sym) != 0:
        self.typed_expr_types.insert(node, named_tid)
        return named_tid

    // Check enum variants
    if self.variant_lookup.contains(sym) and self.is_ci_visible(sym) != 0:
        var variant_expected_tid = self.expected_variant_constructor_type(sym)
        if variant_expected_tid == 0 and self.imported_variant_owners.contains(sym):
            variant_expected_tid = self.imported_variant_owners.get(sym).unwrap()
        if variant_expected_tid != 0:
            let resolved_variant_sym = self.qualified_enum_variant_sym(variant_expected_tid, sym)
            self.comp_resolved.insert(node, resolved_variant_sym)
        let variant_tid = if variant_expected_tid != 0: variant_expected_tid else: self.variant_type_ids.get(sym).unwrap()
        self.typed_expr_types.insert(node, variant_tid)
        return variant_tid

    // Unknown identifier — suggest close matches
    let target_name = self.pool_resolve(sym)
    let suggestion = self.suggest_name(target_name, node)
    self.emit_error_with_suggestion("undefined variable", node, suggestion)
    0

fn Sema.regex_literal_pattern(self: Sema, node: i32) -> str:
    self.pool_resolve(self.ast.get_data0(node))

fn Sema.regex_literal_flags(self: Sema, node: i32) -> str:
    self.pool_resolve(self.ast.get_data1(node))

fn sema_regex_hex_digit_value(ch: i32) -> i32:
    if ch >= 48 and ch <= 57:
        return ch - 48
    if ch >= 97 and ch <= 102:
        return ch - 87
    if ch >= 65 and ch <= 70:
        return ch - 55
    -1

fn sema_regex_decode_literal_escapes(text: str) -> str:
    var out = ""
    let len = text.len() as i32
    var i = 0
    while i < len:
        let ch = text[i]
        if ch == 92 and i + 1 < len:
            i = i + 1
            let esc = text[i]
            if esc == 120 and i + 2 < len:
                let hi = sema_regex_hex_digit_value(text[i + 1])
                let lo = sema_regex_hex_digit_value(text[i + 2])
                if hi >= 0 and lo >= 0:
                    out = out ++ str_from_byte(hi * 16 + lo)
                    i = i + 2
                else:
                    out = out ++ text.slice(i as i64, i as i64 + 1)
            else if esc == 110:
                out = out ++ "\n"
            else if esc == 116:
                out = out ++ "\t"
            else if esc == 114:
                out = out ++ "\r"
            else if esc == 48:
                out = out ++ str_from_byte(0)
            else if esc == 92:
                out = out ++ "\\"
            else if esc == 34:
                out = out ++ "\""
            else:
                out = out ++ text.slice(i as i64, i as i64 + 1)
        else:
            out = out ++ text.slice(i as i64, i as i64 + 1)
        i = i + 1
    out

fn Sema.validate_regex_literal(self: Sema, node: i32):
    if self.regex_capture_counts.contains(node):
        return
    let pattern = sema_regex_decode_literal_escapes(self.regex_literal_pattern(node))
    let flags = sema_regex_decode_literal_escapes(self.regex_literal_flags(node))
    let options = sema_regex_compile_options(flags)
    if options < 0:
        self.emit_error("invalid regex flag", node)
        self.regex_capture_counts.insert(node, 0)
        return
    var err_code: i32 = 0
    var err_offset: i32 = 0
    let code = with_regex_compile(pattern, options, &raw mut err_code, &raw mut err_offset)
    if code as i64 == 0:
        self.emit_error("invalid regex literal: " ++ with_regex_error_message(err_code), node)
        self.regex_capture_counts.insert(node, 0)
        return
    let capture_count = with_regex_capture_count(code)
    self.regex_capture_counts.insert(node, capture_count)
    let name_start = self.regex_capture_name_syms.len() as i32
    let name_count = with_regex_capture_name_count(code)
    var ni = 0
    while ni < name_count:
        let name = with_regex_capture_name_at(code, ni)
        self.regex_capture_name_syms.push(self.pool_lookup_symbol("$" ++ name))
        ni = ni + 1
    self.regex_capture_name_starts.insert(node, name_start)
    self.regex_capture_name_counts.insert(node, name_count)
    with_regex_code_free(code)

fn Sema.regex_bind_capture_scope(self: Sema, regex_node: i32):
    if regex_node == 0:
        return
    let kind = self.ast.kind(regex_node)
    if kind != NodeKind.NK_REGEX_LIT and kind != NodeKind.NK_PAT_REGEX:
        return
    self.validate_regex_literal(regex_node)
    let count = if self.regex_capture_counts.contains(regex_node): self.regex_capture_counts.get(regex_node).unwrap() else: 0
    var i = 0
    while i <= count:
        let sym = self.pool_lookup_symbol("$" ++ i.to_string())
        if sym != 0:
            self.scope_put(sym, self.ty_str as i32, 0)
        i = i + 1
    let name_count = if self.regex_capture_name_counts.contains(regex_node): self.regex_capture_name_counts.get(regex_node).unwrap() else: 0
    let name_start = if self.regex_capture_name_starts.contains(regex_node): self.regex_capture_name_starts.get(regex_node).unwrap() else: 0
    var ni = 0
    while ni < name_count:
        let sym = self.regex_capture_name_syms.get((name_start + ni) as i64)
        if sym != 0:
            self.scope_put(sym, self.ty_str as i32, 0)
        ni = ni + 1

fn Sema.check_fstring(self: Sema, node: i32) -> i32:
    // Type-check each expression segment. Result type is always str.
    let seg_count = self.ast.get_data0(node)
    let extra_start = self.ast.get_data1(node)
    var pos = extra_start
    var i = 0
    while i < seg_count:
        let seg_kind = self.ast.get_extra(pos)
        if seg_kind == FStringSegmentKind.LITERAL:
            pos = pos + 2  // kind + symbol
        else if seg_kind == FStringSegmentKind.EXPR:
            let expr_node = self.ast.get_extra(pos + 1)
            let spec_node = self.ast.get_extra(pos + 2)
            // Type-check the expression
            let expr_ty = self.check_expr(expr_node)
            // Validate format spec against expression type
            if spec_node != 0:
                self.validate_fstring_spec(spec_node, expr_ty as i32, expr_node)
            else:
                // Bare {expr} without spec: reject structs (no default display)
                let resolved = if expr_ty != 0: self.resolve_alias(expr_ty) else: 0 as TypeId
                let tk = if resolved != 0: self.get_type_kind(resolved) else: 0
                if tk == TypeKind.TY_STRUCT:
                    self.emit_error("struct type has no default display; use :? for debug", expr_node)
            pos = pos + 3  // kind + expr + spec
        else:
            pos = pos + 1
        i = i + 1
    self.ty_str as i32

fn Sema.validate_fstring_spec(self: Sema, spec_node: i32, expr_ty: i32, expr_node: i32):
    // Unpack NodeKind.NK_FSTRING_SPEC fields
    let flags = self.ast.get_data0(spec_node)
    let width = self.ast.get_data1(spec_node)
    let precision = self.ast.get_data2(spec_node)
    let mode = flags & 255
    let fill = (flags >> 8) & 255
    let align = (flags >> 16) & 3
    let sign_plus = (flags >> 18) & 1
    let alternate = (flags >> 19) & 1
    let zero_pad = (flags >> 20) & 1
    // Resolve expression type kind
    let resolved = if expr_ty != 0: self.resolve_alias(expr_ty) else: 0
    let tk = if resolved != 0: self.get_type_kind(resolved) else: 0
    let is_int = tk == TypeKind.TY_INT
    let is_float = tk == TypeKind.TY_FLOAT
    let is_str = tk == TypeKind.TY_STR
    let is_bool = tk == TypeKind.TY_BOOL
    let is_struct = tk == TypeKind.TY_STRUCT
    let is_enum = tk == TypeKind.TY_ENUM
    let is_numeric = is_int or is_float
    // Mode/type compatibility (format-design.md §4.1)
    // d, x, X, b, o → integers only
    if mode == 100 or mode == 120 or mode == 88 or mode == 98 or mode == 111:
        if not is_int:
            self.emit_error("format mode requires integer type", spec_node)
    // f, e, g → floats only
    if mode == 102 or mode == 101 or mode == 103:
        if not is_float:
            self.emit_error("format mode requires float type", spec_node)
    // s → strings only
    if mode == 115:
        if not is_str:
            self.emit_error("format mode requires string type", spec_node)
    // ? → any type (always valid)
    // Field/type compatibility (format-design.md §4.2)
    // precision → floats and strings only
    if precision >= 0:
        if not is_float and not is_str:
            self.emit_error("precision requires float or string type", spec_node)
    // # → integers with hex/bin/oct mode only
    if alternate != 0:
        if not is_int:
            self.emit_error("alternate form '#' requires integer type", spec_node)
        else if mode != 120 and mode != 88 and mode != 98 and mode != 111 and mode != 0:
            self.emit_error("alternate form '#' requires hex, binary, or octal mode", spec_node)
    // sign → numbers only
    if sign_plus != 0:
        if not is_numeric:
            self.emit_error("sign '+' requires numeric type", spec_node)

fn Sema.check_binary(self: Sema, node: i32) -> i32:
    let op = self.ast.get_data0(node)
    let lhs_node = self.ast.get_data1(node)
    let rhs_node = self.ast.get_data2(node)
    let lhs_is_num_lit = sema_node_is_numeric_literal(self.ast, lhs_node)
    let rhs_is_num_lit = sema_node_is_numeric_literal(self.ast, rhs_node)
    var lhs: TypeId = 0 as TypeId
    var rhs: TypeId = 0 as TypeId
    if op == BinaryOp.OP_DEFAULT:
        lhs = self.check_expr(lhs_node)
        if lhs == 0:
            return 0
        let unwrapped = self.try_unwrapped_type(lhs as i32)
        if unwrapped == 0:
            self.emit_error("?? operator requires an Option or Result with a single success payload", node)
            return 0
        rhs = self.check_expr_with_expected(rhs_node, unwrapped as TypeId)
        if rhs == 0:
            return 0
        if self.types_compatible(unwrapped, rhs as i32) == 0:
            self.emit_error("?? default value must match the unwrapped payload type", rhs_node)
            return 0
        return unwrapped
    // Variant shorthand in comparisons must be typed against the opposite side,
    // not whatever outer expected type is active (for example `bool` from assert()).
    if op == BinaryOp.OP_EQ or op == BinaryOp.OP_NEQ or op == BinaryOp.OP_LT or op == BinaryOp.OP_GT or op == BinaryOp.OP_LTE or op == BinaryOp.OP_GTE:
        if self.ast.kind(lhs_node) == NodeKind.NK_VARIANT_SHORTHAND:
            rhs = self.check_expr(rhs_node)
            lhs = self.check_expr_with_expected(lhs_node, rhs)
        else:
            if lhs_is_num_lit and rhs_is_num_lit:
                lhs = self.check_expr(lhs_node)
                rhs = self.check_expr(rhs_node)
            else if lhs_is_num_lit and self.ast.kind(rhs_node) != NodeKind.NK_VARIANT_SHORTHAND:
                rhs = self.check_expr(rhs_node)
                lhs = self.check_expr_with_expected(lhs_node, rhs)
            else:
                lhs = self.check_expr(lhs_node)
            if self.ast.kind(rhs_node) == NodeKind.NK_VARIANT_SHORTHAND:
                rhs = self.check_expr_with_expected(rhs_node, lhs)
            else if rhs == 0 and rhs_is_num_lit and not lhs_is_num_lit:
                rhs = self.check_expr_with_expected(rhs_node, lhs)
            else:
                if rhs == 0:
                    rhs = self.check_expr(rhs_node)
    else if op == BinaryOp.OP_SHL or op == BinaryOp.OP_SHR:
        lhs = self.check_expr(lhs_node)
        let shift_count_ty = if rhs_is_num_lit: self.shift_count_literal_type(rhs_node) else: 0
        rhs = self.check_expr_with_expected(rhs_node, shift_count_ty as TypeId)
    else if op == BinaryOp.OP_ADD or op == BinaryOp.OP_SUB or op == BinaryOp.OP_MUL or op == BinaryOp.OP_DIV or op == BinaryOp.OP_MOD or
       op == BinaryOp.OP_ADD_WRAP or op == BinaryOp.OP_SUB_WRAP or op == BinaryOp.OP_MUL_WRAP or
       op == BinaryOp.OP_ADD_SAT or op == BinaryOp.OP_SUB_SAT or op == BinaryOp.OP_MUL_SAT or
       op == BinaryOp.OP_BIT_AND or op == BinaryOp.OP_BIT_OR or op == BinaryOp.OP_BIT_XOR:
        if lhs_is_num_lit and rhs_is_num_lit:
            lhs = self.check_expr(lhs_node)
            rhs = self.check_expr(rhs_node)
        else:
            if lhs_is_num_lit:
                rhs = self.check_expr(rhs_node)
                if self.is_numeric_type(rhs as i32):
                    lhs = self.check_expr_with_expected(lhs_node, rhs)
                else:
                    lhs = self.check_expr(lhs_node)
            else:
                lhs = self.check_expr(lhs_node)
            if rhs == 0:
                if rhs_is_num_lit and self.is_numeric_type(lhs as i32):
                    rhs = self.check_expr_with_expected(rhs_node, lhs)
                else:
                    rhs = self.check_expr(rhs_node)
            if lhs == 0:
                lhs = self.check_expr(lhs_node)
    else:
        lhs = self.check_expr(lhs_node)
        rhs = self.check_expr(rhs_node)

    if lhs == 0 or rhs == 0:
        return 0

    // Comparison operators return bool
    if op == BinaryOp.OP_EQ or op == BinaryOp.OP_NEQ or op == BinaryOp.OP_LT or op == BinaryOp.OP_GT or op == BinaryOp.OP_LTE or op == BinaryOp.OP_GTE or op == BinaryOp.OP_IN or op == BinaryOp.OP_NOT_IN:
        let lhs_cmp_kind = self.get_type_kind(self.resolve_alias(lhs))
        let rhs_cmp_kind = self.get_type_kind(self.resolve_alias(rhs))
        if (lhs_cmp_kind == TypeKind.TY_PTR and rhs_cmp_kind == TypeKind.TY_ARRAY) or (lhs_cmp_kind == TypeKind.TY_ARRAY and rhs_cmp_kind == TypeKind.TY_PTR):
            self.emit_error("cannot compare pointer and array; use explicit &array[0]", node)
            return 0
        if op != BinaryOp.OP_IN and op != BinaryOp.OP_NOT_IN:
            let bool_int_cmp = (lhs_cmp_kind == TypeKind.TY_BOOL and rhs_cmp_kind == TypeKind.TY_INT) or (lhs_cmp_kind == TypeKind.TY_INT and rhs_cmp_kind == TypeKind.TY_BOOL)
            let lhs_option_ptr = self.is_option_pointer_type(lhs as i32) != 0
            let rhs_option_ptr = self.is_option_pointer_type(rhs as i32) != 0
            let lhs_ptr_like = lhs_cmp_kind == TypeKind.TY_PTR or lhs_cmp_kind == TypeKind.TY_REF or lhs_cmp_kind == TypeKind.TY_FN or lhs_cmp_kind == TypeKind.TY_GENERIC_FN or lhs_option_ptr
            let rhs_ptr_like = rhs_cmp_kind == TypeKind.TY_PTR or rhs_cmp_kind == TypeKind.TY_REF or rhs_cmp_kind == TypeKind.TY_FN or rhs_cmp_kind == TypeKind.TY_GENERIC_FN or rhs_option_ptr
            let ptr_like_cmp = lhs_ptr_like and rhs_ptr_like
            let ptr_zero_cmp = (lhs_ptr_like and rhs_cmp_kind == TypeKind.TY_INT and sema_node_is_zero_int_literal(self.ast, rhs_node)) or (rhs_ptr_like and lhs_cmp_kind == TypeKind.TY_INT and sema_node_is_zero_int_literal(self.ast, lhs_node))
            let lhs_none = (self.ast.kind(lhs_node) == NodeKind.NK_VARIANT_SHORTHAND or self.ast.kind(lhs_node) == NodeKind.NK_IDENT) and self.ast.get_data0(lhs_node) == self.syms.none
            let rhs_none = (self.ast.kind(rhs_node) == NodeKind.NK_VARIANT_SHORTHAND or self.ast.kind(rhs_node) == NodeKind.NK_IDENT) and self.ast.get_data0(rhs_node) == self.syms.none
            let ptr_none_cmp = ((lhs_cmp_kind == TypeKind.TY_PTR or lhs_option_ptr) and rhs_none) or ((rhs_cmp_kind == TypeKind.TY_PTR or rhs_option_ptr) and lhs_none)
            if lhs_ptr_like != rhs_ptr_like and ptr_zero_cmp == 0 and ptr_none_cmp == 0:
                self.emit_error("comparison operands must have compatible types", node)
                return 0
            if bool_int_cmp == 0 and ptr_like_cmp == 0 and ptr_zero_cmp == 0 and ptr_none_cmp == 0 and (lhs_ptr_like or rhs_ptr_like) and self.builtin_arg_type_compatible(lhs, rhs) == 0 and self.builtin_arg_type_compatible(rhs, lhs) == 0:
                self.emit_error("comparison operands must have compatible types", node)
                return 0
        return self.ty_bool as i32

    // Logical operators
    if op == BinaryOp.OP_AND or op == BinaryOp.OP_OR:
        if lhs != self.ty_bool:
            self.emit_error("left operand of logical operator must be bool", node)
        if rhs != self.ty_bool:
            self.emit_error("right operand of logical operator must be bool", node)
        return self.ty_bool as i32

    // Arithmetic — unsigned types wrap by default (rewrite to wrapping ops)
    if (op == BinaryOp.OP_ADD or op == BinaryOp.OP_SUB or op == BinaryOp.OP_MUL) and self.is_unsigned_int_type(lhs as i32) and self.is_unsigned_int_type(rhs as i32):
        let wrap_op = if op == BinaryOp.OP_ADD: BinaryOp.OP_ADD_WRAP else if op == BinaryOp.OP_SUB: BinaryOp.OP_SUB_WRAP else: BinaryOp.OP_MUL_WRAP
        self.ast.set_data0(node, wrap_op)
        return self.arithmetic_result_type(lhs, rhs) as i32

    // @ matmul operator — always dispatches to method
    if op == BinaryOp.OP_MATMUL:
        let lhs_resolved = self.resolve_alias(lhs)
        let lhs_name = self.get_type_name(lhs_resolved as i32)
        let matmul_sym = self.pool_intern("matmul")
        if lhs_name != 0:
            let sig = self.lookup_method_sig(lhs_name, matmul_sym)
            if sig >= 0:
                return self.sig_return_type(sig)
        // Reversed-operand lookup
        let rhs_resolved = self.resolve_alias(rhs)
        let rhs_name = self.get_type_name(rhs_resolved as i32)
        if rhs_name != 0:
            let sig = self.lookup_method_sig(rhs_name, matmul_sym)
            if sig >= 0:
                return self.sig_return_type(sig)
        self.emit_error("@ operator requires a type implementing 'matmul'", node)
        return 0

    if op == BinaryOp.OP_ADD or op == BinaryOp.OP_SUB or op == BinaryOp.OP_MUL or op == BinaryOp.OP_DIV or op == BinaryOp.OP_MOD:
        if op == BinaryOp.OP_ADD and lhs == self.ty_str and rhs == self.ty_str:
            self.emit_error("string concatenation uses '++', not '+'", node)
            return 0
        // Pointer arithmetic computes addresses in safe code. Only raw
        // pointer memory access (`*p`, `p[i]`) requires unsafe.
        let lhs_k = self.get_type_kind(self.resolve_alias(lhs))
        let rhs_k = self.get_type_kind(self.resolve_alias(rhs))
        if self.in_comptime_fn != 0 and (lhs_k == TypeKind.TY_PTR or rhs_k == TypeKind.TY_PTR):
            self.emit_error("raw pointer arithmetic is not allowed in comptime", node)
            return 0
        if op == BinaryOp.OP_SUB and lhs_k == TypeKind.TY_PTR and rhs_k == TypeKind.TY_PTR:
            if self.types_compatible(lhs, rhs) == 0 and self.types_compatible(rhs, lhs) == 0:
                self.emit_error("pointer subtraction requires compatible pointer types", node)
                return 0
            return self.ty_isize as i32
        if (op == BinaryOp.OP_ADD or op == BinaryOp.OP_SUB) and lhs_k == TypeKind.TY_PTR and (rhs_k == TypeKind.TY_INT or rhs == self.ty_i32 or rhs == self.ty_i64 or rhs == self.ty_usize or rhs == self.ty_isize):
            return lhs as i32
        let result = self.arithmetic_result_type(lhs, rhs)
        if result != 0:
            return result as i32
        let lhs_resolved = self.resolve_alias(lhs)
        let lhs_name = self.get_type_name(lhs_resolved as i32)
        let method_name = if op == BinaryOp.OP_ADD: "add" else:
            if op == BinaryOp.OP_SUB: "sub" else:
            if op == BinaryOp.OP_MUL: "mul" else:
            if op == BinaryOp.OP_DIV: "div" else:
            "mod"
        let method_sym = self.pool_intern(method_name)
        if lhs_name != 0:
            let method_sig = self.lookup_method_sig(lhs_name, method_sym)
            if method_sig >= 0:
                return self.sig_return_type(method_sig)
        // Reversed-operand lookup: try RHS type
        let rhs_resolved = self.resolve_alias(rhs)
        let rhs_name = self.get_type_name(rhs_resolved as i32)
        if rhs_name != 0:
            let rhs_method_sig = self.lookup_method_sig(rhs_name, method_sym)
            if rhs_method_sig >= 0:
                return self.sig_return_type(rhs_method_sig)
        self.emit_error("arithmetic operator requires numeric operands", node)
        return 0

    // Shifts use the left operand width and require an unsigned count.
    if op == BinaryOp.OP_SHL or op == BinaryOp.OP_SHR:
        let lhs_numeric = self.numeric_operand_type(lhs as i32)
        let lhs_resolved = self.resolve_alias(lhs_numeric as TypeId)
        if self.get_type_kind(lhs_resolved) != TypeKind.TY_INT:
            self.emit_error("shift left operand must be integer", node)
            return 0
        let rhs_numeric = self.numeric_operand_type(rhs as i32)
        let rhs_resolved = self.resolve_alias(rhs_numeric as TypeId)
        if self.get_type_kind(rhs_resolved) != TypeKind.TY_INT or self.get_type_d1(rhs_resolved) != 0:
            self.emit_error("shift count must be unsigned integer", node)
            return 0
        return lhs as i32

    // Bitwise
    if op == BinaryOp.OP_BIT_AND or op == BinaryOp.OP_BIT_OR or op == BinaryOp.OP_BIT_XOR:
        return lhs as i32

    // Wrapping arithmetic
    if op == BinaryOp.OP_ADD_WRAP or op == BinaryOp.OP_SUB_WRAP or op == BinaryOp.OP_MUL_WRAP:
        return lhs as i32

    // Saturating arithmetic — integers only
    if op == BinaryOp.OP_ADD_SAT or op == BinaryOp.OP_SUB_SAT or op == BinaryOp.OP_MUL_SAT:
        let sat_resolved = self.resolve_alias(lhs)
        if self.get_type_kind(sat_resolved) == TypeKind.TY_FLOAT:
            self.emit_error("saturating arithmetic is not defined for floating-point types", node)
            return 0
        return lhs as i32

    // Concat (++) — both operands must be str
    // Only reject known non-str types; allow unresolved/generic types
    // that may be str after monomorphization (Vec[str].get() etc.)
    if op == BinaryOp.OP_CONCAT:
        let lhs_resolved = self.resolve_alias(lhs)
        let rhs_resolved = self.resolve_alias(rhs)
        let lhs_k = self.get_type_kind(lhs_resolved)
        let rhs_k = self.get_type_kind(rhs_resolved)
        if lhs_resolved != self.ty_str and (lhs_k == TypeKind.TY_INT or lhs_k == TypeKind.TY_FLOAT or lhs_k == TypeKind.TY_BOOL or lhs_k == TypeKind.TY_STRUCT or lhs_k == TypeKind.TY_ENUM or lhs_k == TypeKind.TY_ARRAY or lhs_k == TypeKind.TY_TUPLE):
            self.emit_error("left operand of ++ must be str", lhs_node)
        if rhs_resolved != self.ty_str and (rhs_k == TypeKind.TY_INT or rhs_k == TypeKind.TY_FLOAT or rhs_k == TypeKind.TY_BOOL or rhs_k == TypeKind.TY_STRUCT or rhs_k == TypeKind.TY_ENUM or rhs_k == TypeKind.TY_ARRAY or rhs_k == TypeKind.TY_TUPLE):
            self.emit_error("right operand of ++ must be str", rhs_node)
        return self.ty_str as i32

    0

fn Sema.check_unary(self: Sema, node: i32) -> i32:
    let op = self.ast.get_data0(node)
    let operand_node = self.ast.get_data1(node)
    var expected_operand = 0
    if (op == UnaryOp.UOP_REF or op == UnaryOp.UOP_RAW_REF_CONST or op == UnaryOp.UOP_RAW_REF_MUT) and self.has_expected_type != 0 and self.expected_expr_type != 0:
        let expected_ref = self.resolve_alias(self.expected_expr_type)
        let expected_ref_kind = self.get_type_kind(expected_ref)
        if expected_ref_kind == TypeKind.TY_REF or expected_ref_kind == TypeKind.TY_PTR:
            expected_operand = self.get_type_d0(expected_ref)
    let operand = if expected_operand != 0: self.check_expr_with_expected(operand_node, expected_operand as TypeId) else: self.check_expr(operand_node)
    if operand == 0:
        return 0

    if op == UnaryOp.UOP_NEGATE:
        if self.is_unsigned_int_type(operand as i32):
            self.emit_error("cannot negate an unsigned value", node)
        return operand as i32
    if op == UnaryOp.UOP_BIT_NOT:
        return operand as i32
    if op == UnaryOp.UOP_NOT:
        return self.ty_bool as i32
    if op == UnaryOp.UOP_MUT_REF:
        self.emit_error("`&mut` is not part of safe With (§15.1); use `&raw mut` for FFI or mutating receiver methods", node)
        return 0
    if op == UnaryOp.UOP_REF or op == UnaryOp.UOP_RAW_REF_CONST or op == UnaryOp.UOP_RAW_REF_MUT:
        // Reject address-of bitpacked fields — they may not be byte-aligned
        if self.ast.kind(operand_node) == NodeKind.NK_FIELD_ACCESS:
            let ref_recv = self.ast.get_data0(operand_node)
            let ref_recv_ty = self.resolve_alias(self.check_expr(ref_recv))
            if self.bitpacked_types.contains(ref_recv_ty as i32):
                self.emit_error("cannot take address of bitpacked field", node)
                return 0
        // docs/mut.md Rev 8 §13 — raw forms produce TY_PTR (*const T / *mut T)
        // and do not participate in borrow tracking. Forming a raw pointer is
        // safe; dereferencing or writing through it requires unsafe (§13.3).
        // §15.13/15.14 — `&raw mut` requires a mutable place; `&raw const`
        // requires a place.
        let is_raw = op == UnaryOp.UOP_RAW_REF_CONST or op == UnaryOp.UOP_RAW_REF_MUT
        if is_raw:
            let raw_packed = self.classify_place(operand_node)
            let raw_kind = unpack_place_kind(raw_packed)
            let raw_mut_state = unpack_place_mut(raw_packed)
            if raw_kind == PlaceKind.PK_NotPlace:
                if op == UnaryOp.UOP_RAW_REF_MUT:
                    self.emit_error("`&raw mut` requires a place; this expression is not a place (§15.13)", node)
                else:
                    self.emit_warning("`&raw const` requires a place; this expression is not a place", node)
            else if op == UnaryOp.UOP_RAW_REF_MUT and raw_mut_state == PlaceMut.PM_ReadOnly:
                self.emit_error("`&raw mut` requires a mutable place; this place is read-only (e.g., dereferenced &T or *const T) (§15.14)", node)
            let raw_mut = if op == UnaryOp.UOP_RAW_REF_MUT: 1 else: 0
            return self.add_type(TypeKind.TY_PTR, operand as i32, raw_mut, 0) as i32
        self.check_borrow_create(operand_node, BorrowKind.SHARED, node)
        return self.add_type(TypeKind.TY_REF, operand as i32, 0, 0) as i32
    if op == UnaryOp.UOP_DEREF:
        let resolved = self.resolve_alias(operand)
        let tk = self.get_type_kind(resolved)
        if tk == TypeKind.TY_REF:
            return self.get_type_d0(resolved)
        if tk == TypeKind.TY_PTR:
            if self.in_unsafe == 0:
                self.emit_error("raw pointer dereference requires unsafe context", node)
            return self.get_type_d0(resolved)
        // docs/mut.md Rev 8 §15.16 — deref-precedence diagnostic.
        // `*x.field` parses as `*(x.field)`; if the field type is not a
        // pointer/reference, the user almost certainly meant `(*x).field`.
        // Emit a precedence-aware message in that case.
        if self.ast.kind(operand_node) == NodeKind.NK_FIELD_ACCESS:
            self.emit_error("cannot dereference non-pointer value; `*x.field` parses as `*(x.field)` (unary `*` has lower precedence than `.`); write `(*x).field` to dereference x first", node)
        else:
            self.emit_error("cannot dereference non-pointer value", node)
        return 0
    if op == UnaryOp.UOP_TRY:
        if self.in_defer != 0:
            self.emit_error("? operator not allowed in defer", node)
            return 0
        let unwrapped = self.try_unwrapped_type(operand as i32)
        if unwrapped == 0:
            self.emit_error("? operator requires an Option or Result with a single success payload", node)
            return 0
        self.typed_expr_types.insert(node, unwrapped)
        return unwrapped

    0

fn Sema.check_block(self: Sema, node: i32) -> i32:
    let extra_start = self.ast.get_data0(node)
    let stmt_count = self.ast.get_data1(node)
    let tail = self.ast.get_data2(node)
    let block_meta = self.ast.find_block_meta(node)
    let block_label = if block_meta >= 0: self.ast.block_meta_label(block_meta) else: 0

    self.push_scope()
    if block_label != 0:
        self.push_label_frame(block_label, LabelFrameKind.LFK_BLOCK, node)

    let saved_block_extra = self.current_block_extra_start
    let saved_block_count = self.current_block_stmt_count
    let saved_block_index = self.current_block_stmt_index
    let saved_block_tail = self.current_block_tail
    self.current_block_extra_start = extra_start
    self.current_block_stmt_count = stmt_count
    self.current_block_tail = tail

    var last_stmt_ty: TypeId = 0 as TypeId
    for i in 0..stmt_count:
        self.current_block_stmt_index = i
        let stmt = self.ast.get_extra(extra_start + i)
        let saved_stmt_pos = self.match_in_stmt_pos
        let saved_label_stmt_pos = self.stmt_pos_depth
        let saved_expected = self.expected_expr_type
        let saved_has_expected = self.has_expected_type
        self.match_in_stmt_pos = 1
        self.stmt_pos_depth = self.stmt_pos_depth + 1
        self.expected_expr_type = 0 as TypeId
        self.has_expected_type = 0
        let stmt_ty = self.check_expr(stmt)
        self.expected_expr_type = saved_expected
        self.has_expected_type = saved_has_expected
        self.stmt_pos_depth = saved_label_stmt_pos
        self.match_in_stmt_pos = saved_stmt_pos
        self.typed_expr_types.insert(stmt, stmt_ty as i32)
        last_stmt_ty = stmt_ty as TypeId
        let stmt_kind = self.ast.kind(stmt)
        let can_discard_task = stmt_kind == NodeKind.NK_CALL or stmt_kind == NodeKind.NK_IDENT or stmt_kind == NodeKind.NK_GROUPED or stmt_kind == NodeKind.NK_ASYNC_BLOCK or stmt_kind == NodeKind.NK_TUPLE
        let is_discarded_task = can_discard_task and stmt_kind != NodeKind.NK_SPAWN and self.expr_is_task_value(stmt) != 0 and self.expr_is_scoped_task_value(stmt) == 0
        if is_discarded_task:
            self.emit_error("E0801: unused Task value", stmt)
        self.expire_dead_borrows_in_block(extra_start, stmt_count, i + 1, tail)

    var result: TypeId = if tail == 0 and last_stmt_ty == self.ty_never: self.ty_never else: self.ty_void
    if tail != 0:
        // If the tail is a match in a void/unspecified-return context, treat as statement
        // position so partial enum match is allowed (value is not used).
        let saved_stmt_pos = self.match_in_stmt_pos
        let ret_is_void = self.current_return_type == self.ty_void or self.current_return_type == 0
        if ret_is_void and self.ast.kind(tail) == NodeKind.NK_MATCH:
            self.match_in_stmt_pos = 1
        let tail_type = self.check_expr(tail)
        self.match_in_stmt_pos = saved_stmt_pos
        if tail_type as TypeId != self.ty_void and tail_type != 0:
            result = tail_type
        self.typed_expr_types.insert(tail, tail_type as i32)
        let tail_kind = self.get_type_kind(self.resolve_alias(tail_type))
        if tail_kind == TypeKind.TY_REF:
            self.check_returned_view_origins(tail, tail)
    self.expire_dead_borrows_in_block(extra_start, stmt_count, stmt_count, 0)

    self.current_block_extra_start = saved_block_extra
    self.current_block_stmt_count = saved_block_count
    self.current_block_stmt_index = saved_block_index
    self.current_block_tail = saved_block_tail

    if block_label != 0:
        self.pop_label_frame()
    self.pop_scope()
    if result != 0 and result != self.ty_void:
        self.typed_expr_types.insert(node, result as i32)
    result as i32

fn Sema.check_let_binding(self: Sema, node: i32) -> i32:
    let name = self.ast.get_data0(node)
    var bind_name = self.extract_decl_name_after(node, "let")
    if bind_name.len() == 0:
        bind_name = self.extract_decl_name_after(node, "var")
    self.set_pretty_symbol(name, bind_name)
    let value = self.ast.get_data1(node)
    let flags = self.ast.get_data2(node)
    let is_mut = flags % 2
    if value != 0:
        var labeled_value = value
        if self.ast.kind(value) == NodeKind.NK_LABEL:
            labeled_value = self.ast.get_data1(value)
        if labeled_value != 0 and self.ast.kind(labeled_value) == NodeKind.NK_BLOCK:
            let value_block_meta = self.ast.find_block_meta(labeled_value)
            if value_block_meta >= 0 and self.ast.block_meta_label(value_block_meta) != 0:
                self.emit_error("labeled block used as an expression", labeled_value)
    let ann_extra = self.local_let_type_ann_extra(flags)
    var ann_type: TypeId = 0 as TypeId
    var ann_type_node = 0
    if ann_extra >= 0:
        ann_type_node = self.ast.get_extra(ann_extra)
        ann_type = self.resolve_type_expr(ann_type_node)

    // var x: T (no initializer) — zero-initialized
    if value == 0:
        if ann_type == 0:
            self.emit_error("var without initializer requires type annotation", node)
            return self.ty_void as i32
        self.scope_put_at(name, ann_type as i32, is_mut, node)
        self.binding_decl_nodes.insert(name, node)
        self.binding_value_nodes.remove(name)
        self.typed_binding_types.insert(node, ann_type as i32)
        return self.ty_void as i32

    // Let binding value is expression position — match inside must be exhaustive.
    let saved_match_stmt = self.match_in_stmt_pos
    self.match_in_stmt_pos = 0
    let val_type = if ann_type != 0: self.check_expr_with_expected(value, ann_type) else: self.check_expr(value)
    self.match_in_stmt_pos = saved_match_stmt
    var bind_type: TypeId = val_type
    if ann_type != 0:
        bind_type = ann_type
        if val_type != 0:
            if self.types_compatible(ann_type as i32, val_type as i32) == 0:
                if self.arithmetic_result_type(ann_type, val_type) == 0:
                    self.emit_error("type mismatch in binding", node)

    // Move semantics
    self.mark_moved_if_consumed(value)

    if ann_type_node != 0 and self.type_expr_is_collection_with_ref(ann_type_node) != 0:
        self.emit_error("ephemeral references cannot be stored in generic containers", node)
    if self.is_opaque_value_type(bind_type as i32) != 0:
        let opaque_node = if ann_type_node != 0: ann_type_node else: value
        self.emit_error("opaque values cannot be stored by value; use a pointer or reference", opaque_node)

    let had_binding = self.scope_has(name)
    self.scope_put_at(name, bind_type as i32, is_mut, node)
    self.binding_decl_nodes.insert(name, node)
    self.binding_value_nodes.insert(name, value)
    self.typed_binding_types.insert(node, bind_type as i32)
    self.typed_binding_names.insert(node, name)
    self.typed_binding_muts.insert(node, is_mut)
    if ann_type == 0 and had_binding == 0:
        self.register_pending_generic_binding(name, node, value, bind_type as i32)
    var is_task_val = self.expr_is_task_value(value)
    if is_task_val == 0:
        is_task_val = self.type_is_task(bind_type as i32)
    self.scope_set_is_task(name, is_task_val)
    self.scope_set_is_scoped_task(name, self.expr_is_scoped_task_value(value))
    self.scope_set_is_ephemeral_task(name, self.expr_is_ephemeral_task(value))
    if self.ast.kind(value) == NodeKind.NK_CLOSURE:
        self.binding_closure_nodes.insert(name, value)
    else:
        self.binding_closure_nodes.remove(name)
    let bind_kind = self.get_type_kind(self.resolve_alias(bind_type))
    if bind_kind == TypeKind.TY_REF or bind_kind == TypeKind.TY_PTR:
        self.record_view_binding_from_expr(name, value)
    else:
        self.clear_binding_view_deps(name)

    // Auto-defer: if this is an immutable let binding of a c_import type with a
    // destructor (e.g. let v = MyVec.new(...)), record it for auto-defer at scope exit.
    if is_mut == 0 and self.ci_type_destructors.len() > 0:
        let resolved_bt = self.resolve_alias(bind_type)
        let bt_kind = self.get_type_kind(resolved_bt)
        // For pointer types (*mut T), check the pointee type name
        var type_name_sym = 0
        if bt_kind == TypeKind.TY_PTR or bt_kind == TypeKind.TY_REF:
            let pointee = self.get_type_d0(resolved_bt)
            if pointee > 0:
                let pt_resolved = self.resolve_alias(pointee as TypeId)
                type_name_sym = self.get_type_d0(pt_resolved)
        else if bt_kind == TypeKind.TY_STRUCT:
            type_name_sym = self.get_type_d0(resolved_bt)
        if type_name_sym != 0 and self.ci_type_destructors.contains(type_name_sym):
            let dtor_sym = self.ci_type_destructors.get(type_name_sym).unwrap()
            self.ci_auto_defer_bindings.insert(name, dtor_sym)

    // If this let binds a borrow, tie the newest active borrow to this binding.
    if self.ast.kind(value) == NodeKind.NK_UNARY:
        let uop = self.ast.get_data0(value)
        if uop == UnaryOp.UOP_REF or uop == UnaryOp.UOP_RAW_REF_CONST or uop == UnaryOp.UOP_RAW_REF_MUT:
            let blen = self.borrow_refs.len() as i32
            if blen > 0:
                self.borrow_refs.set_i32((blen - 1) as i64, name)

    self.ty_void as i32

fn Sema.check_if_expr(self: Sema, node: i32) -> i32:
    let cond = self.ast.get_data0(node)
    let then_body = self.ast.get_data1(node)
    let else_body = self.ast.get_data2(node)

    let saved_expected = self.expected_expr_type
    let saved_has_expected = self.has_expected_type
    self.expected_expr_type = 0 as TypeId
    self.has_expected_type = 0
    self.check_expr(cond)
    self.expected_expr_type = saved_expected
    self.has_expected_type = saved_has_expected
    let outer_expected: TypeId = if self.has_expected_type != 0: self.expected_expr_type else: 0 as TypeId
    // Save scope states before then branch so early-return branches don't
    // permanently mark outer variables as MOVED when control continues past the if.
    let pre_then_states = self.save_scope_states()
    var pushed_regex_capture_scope = 0
    if self.ast.kind(cond) == NodeKind.NK_MATCH_OP:
        let rhs = self.ast.get_data1(cond)
        if self.ast.kind(rhs) == NodeKind.NK_REGEX_LIT:
            self.push_scope()
            pushed_regex_capture_scope = 1
            self.regex_bind_capture_scope(rhs)
    let saved_drop_cf_then = self.drop_control_flow_depth
    if self.current_drop_type_sym != 0:
        self.drop_control_flow_depth = self.drop_control_flow_depth + 1
    let then_type = if outer_expected != 0: self.check_expr_with_expected(then_body, outer_expected) else: self.check_expr(then_body)
    self.drop_control_flow_depth = saved_drop_cf_then
    if pushed_regex_capture_scope != 0:
        self.pop_scope()
    // If then branch always terminates, restore pre-then states for the continuation.
    if self.get_type_kind(self.resolve_alias(then_type as TypeId)) == TypeKind.TY_NEVER:
        self.restore_scope_states(pre_then_states)

    var result_type: TypeId = self.ty_void
    if else_body != 0:
        // Don't propagate ty_never as else_expected; use outer_expected instead.
        let then_is_never = self.get_type_kind(self.resolve_alias(then_type as TypeId)) == TypeKind.TY_NEVER
        let else_expected: TypeId = if then_type != 0 and then_type != self.ty_void and then_is_never == 0: then_type else: outer_expected
        let pre_else_states = self.save_scope_states()
        let saved_drop_cf_else = self.drop_control_flow_depth
        if self.current_drop_type_sym != 0:
            self.drop_control_flow_depth = self.drop_control_flow_depth + 1
        let else_type = if else_expected != 0: self.check_expr_with_expected(else_body, else_expected) else: self.check_expr(else_body)
        self.drop_control_flow_depth = saved_drop_cf_else
        // If else branch always terminates, restore pre-else states.
        let else_is_never = self.get_type_kind(self.resolve_alias(else_type as TypeId)) == TypeKind.TY_NEVER
        if else_is_never:
            self.restore_scope_states(pre_else_states)
        // When one branch is Never, the result is the other branch's type.
        if then_is_never and else_type != 0:
            result_type = else_type
        else if else_is_never and then_type != 0:
            result_type = then_type
        else if then_type != 0 and else_type != 0:
            if self.types_compatible(then_type as i32, else_type as i32):
                result_type = self.preferred_compatible_type(then_type, else_type)
            else:
                result_type = self.arithmetic_result_type(then_type, else_type)
        else if then_type != 0:
            result_type = then_type
        else:
            result_type = else_type
    if result_type != 0 and result_type != self.ty_void:
        self.typed_expr_types.insert(node, result_type as i32)
    result_type as i32

fn Sema.fn_symbol_is_comptime(self: Sema, fn_sym: i32) -> i32:
    let fn_node = self.fn_symbol_decl_node(fn_sym)
    if fn_node == 0:
        return 0
    if self.ast.is_comptime_decl_node(fn_node) != 0:
        return 1
    let meta = self.ast.find_fn_meta(fn_node)
    if meta < 0:
        return 0
    let flags = self.ast.fn_meta_flags(meta)
    if (flags / FnFlags.COMPTIME) % 2 == 1:
        return 1
    0

fn Sema.fn_symbol_decl_node(self: Sema, fn_sym: i32) -> i32:
    if self.fn_decl_nodes.contains(fn_sym):
        return self.fn_decl_nodes.get(fn_sym).unwrap()
    if self.generic_fn_nodes.contains(fn_sym):
        return self.generic_fn_nodes.get(fn_sym).unwrap()
    0

fn Sema.fn_symbol_source_path(self: Sema, fn_sym: i32) -> str:
    let fn_node = self.fn_symbol_decl_node(fn_sym)
    if fn_node == 0:
        return ""
    let di = self.find_decl_index(fn_node)
    if di >= 0 and di < self.decl_source_paths.len() as i32:
        return self.decl_source_paths.get(di as i64)
    ""

fn Sema.fn_symbol_is_tool_comptime_allowed(self: Sema, fn_sym: i32) -> i32:
    let source_path = self.fn_symbol_source_path(fn_sym)
    if capability_registry_is_std_build_path(source_path):
        return 1
    if capability_registry_is_std_compiler_path(source_path):
        return 1
    0

fn Sema.check_comptime_call_restriction(self: Sema, fn_sym: i32, node: i32) -> i32:
    if self.in_comptime_fn == 0 or fn_sym == 0:
        return 0
    if self.extern_fn_names.contains(fn_sym):
        self.emit_error("comptime call of extern function", node)
        return 1
    if self.is_intrinsic_fn_sym(fn_sym) != 0:
        if fn_sym == self.syms.src or fn_sym == self.syms.embed_file or fn_sym == self.syms.todo or fn_sym == self.syms.unreachable:
            return 0
        self.emit_error("runtime intrinsic is not allowed in comptime", node)
        return 1
    if self.fn_decl_nodes.contains(fn_sym) or self.generic_fn_nodes.contains(fn_sym):
        if self.fn_symbol_is_tool_comptime_allowed(fn_sym) != 0:
            return 0
        if self.fn_symbol_is_comptime(fn_sym) == 0:
            self.emit_error("comptime can only call comptime functions", node)
            return 1
    0

fn Sema.check_comptime_method_restriction(self: Sema, method_sym: i32, node: i32) -> i32:
    if self.in_comptime_fn == 0 or method_sym == 0:
        return 0
    if self.fn_symbol_is_tool_comptime_allowed(method_sym) != 0:
        return 0
    if self.fn_symbol_is_comptime(method_sym) == 0:
        self.emit_error("comptime can only call comptime functions", node)
        return 1
    0

fn Sema.push_unique_i32(self: Sema, xs: Vec[i32], value: i32) -> void:
    if value == 0:
        return
    for i in 0..xs.len() as i32:
        if xs.get(i as i64) == value:
            return
    xs.push(value)

fn Sema.collect_expr_view_deps(self: Sema, node: i32, out: Vec[i32]):
    if node == 0:
        return
    let kind = self.ast.kind(node)
    if kind == NodeKind.NK_IDENT:
        let sym = self.ast.get_data0(node)
        let dep_count = self.binding_view_dep_count(sym)
        if dep_count > 0:
            for i in 0..dep_count:
                self.push_unique_i32(out, self.binding_view_dep_at(sym, i))
            return
        let ty = self.scope_lookup(sym)
        if ty > 0:
            let tk = self.get_type_kind(self.resolve_alias(ty as TypeId))
            if tk == TypeKind.TY_REF or tk == TypeKind.TY_PTR:
                self.push_unique_i32(out, sym)
        return
    if kind == NodeKind.NK_GROUPED or kind == NodeKind.NK_CAST or kind == NodeKind.NK_COMPTIME:
        self.collect_expr_view_deps(self.ast.get_data0(node), out)
        return
    if kind == NodeKind.NK_FIELD_ACCESS or kind == NodeKind.NK_COMPUTED_FIELD_ACCESS or kind == NodeKind.NK_INDEX:
        self.collect_expr_view_deps(self.ast.get_data0(node), out)
        return
    if kind == NodeKind.NK_UNARY:
        let op = self.ast.get_data0(node)
        if op == UnaryOp.UOP_REF:
            self.push_unique_i32(out, self.place_root_sym(self.ast.get_data1(node)))
        else:
            self.collect_expr_view_deps(self.ast.get_data1(node), out)
        return
    if kind == NodeKind.NK_BLOCK:
        self.collect_expr_view_deps(self.ast.get_data2(node), out)
        return
    if kind == NodeKind.NK_IF_EXPR:
        self.collect_expr_view_deps(self.ast.get_data1(node), out)
        self.collect_expr_view_deps(self.ast.get_data2(node), out)
        return
    let dep_count = self.expr_view_dep_count(node)
    if dep_count > 0:
        for i in 0..dep_count:
            self.push_unique_i32(out, self.expr_view_dep_at(node, i))

fn Sema.compute_expr_view_origin_mask(self: Sema, node: i32) -> i32:
    if node == 0:
        return 0
    let kind = self.ast.kind(node)
    if kind == NodeKind.NK_IDENT:
        let sym = self.ast.get_data0(node)
        let direct_pi = self.param_index_for_sym(sym)
        if direct_pi >= 0:
            return ((1 as i64) << (direct_pi as u32)) as i32
        return self.binding_view_origin_mask(sym)
    if kind == NodeKind.NK_GROUPED or kind == NodeKind.NK_CAST or kind == NodeKind.NK_COMPTIME:
        return self.compute_expr_view_origin_mask(self.ast.get_data0(node))
    if kind == NodeKind.NK_FIELD_ACCESS or kind == NodeKind.NK_COMPUTED_FIELD_ACCESS or kind == NodeKind.NK_INDEX:
        return self.compute_expr_view_origin_mask(self.ast.get_data0(node))
    if kind == NodeKind.NK_UNARY:
        return self.compute_expr_view_origin_mask(self.ast.get_data1(node))
    if kind == NodeKind.NK_BLOCK:
        return self.compute_expr_view_origin_mask(self.ast.get_data2(node))
    if kind == NodeKind.NK_IF_EXPR:
        let then_mask = self.compute_expr_view_origin_mask(self.ast.get_data1(node))
        let else_mask = self.compute_expr_view_origin_mask(self.ast.get_data2(node))
        return then_mask | else_mask
    if self.expr_view_param_origins.contains(node):
        return self.expr_view_origin_mask(node)
    0

fn Sema.record_view_binding_from_expr(self: Sema, sym: i32, expr_node: i32):
    if sym == 0 or expr_node == 0:
        return
    let param_mask = self.compute_expr_view_origin_mask(expr_node)
    let deps: Vec[i32] = Vec.new()
    self.collect_expr_view_deps(expr_node, deps)
    self.set_binding_view_deps(sym, param_mask, deps)

fn Sema.view_origin_is_stack_local(self: Sema, sym: i32) -> i32:
    if sym == 0:
        return 0
    if self.param_index_for_sym(sym) >= 0:
        return 0
    if self.global_value_decl_kind(sym) != 0:
        return 0
    if self.scope_has(sym) != 0:
        return 1
    0

fn Sema.check_returned_view_origins(self: Sema, expr_node: i32, report_node: i32):
    if expr_node == 0:
        return
    if self.ast.kind(expr_node) == NodeKind.NK_UNARY and self.ast.get_data0(expr_node) == UnaryOp.UOP_REF:
        let origin_sym = self.place_root_sym(self.ast.get_data1(expr_node))
        if self.view_origin_is_stack_local(origin_sym) != 0:
            let origin_name = self.pool_resolve(origin_sym)
            self.emit_error("returned view may outlive its origin '" ++ origin_name ++ "'", report_node)
            return
    if self.ast.kind(expr_node) == NodeKind.NK_CALL:
        let callee = self.ast.get_data0(expr_node)
        if self.ast.kind(callee) == NodeKind.NK_IDENT:
            let fn_sym = if self.comp_resolved.contains(expr_node): self.comp_resolved.get(expr_node).unwrap() else: self.ast.get_data0(callee)
            var sig_idx = self.get_sig(fn_sym)
            if sig_idx < 0:
                let sema_fn_sym = self.pool_lookup_symbol(self.pool_resolve(fn_sym))
                sig_idx = self.get_sig(sema_fn_sym)
            if sig_idx >= 0:
                let has_resolved = self.has_resolved_call_args(expr_node)
                let extra_start = self.ast.get_data1(expr_node)
                let arg_count = if has_resolved != 0: self.get_resolved_call_arg_count(expr_node) else: self.ast.get_data2(expr_node)
                let param_count = self.sig_get_param_count(sig_idx)
                for pi in 0..param_count:
                    if (self.sig_param_effect(sig_idx, pi) & EFF_ESCAPE_VIEW) == 0:
                        continue
                    let origin_mask = self.sig_param_view_origin(sig_idx, pi)
                    for origin_pi in 0..param_count:
                        if (origin_mask & (((1 as i64) << (origin_pi as u32)) as i32)) == 0:
                            continue
                        if origin_pi >= arg_count:
                            continue
                        let origin_arg = if has_resolved != 0: self.get_resolved_call_arg(expr_node, origin_pi) else: self.ast.get_extra(extra_start + origin_pi)
                        let origin_sym = self.place_root_sym(origin_arg)
                        if self.view_origin_is_stack_local(origin_sym) != 0:
                            let origin_name = self.pool_resolve(origin_sym)
                            self.emit_error("returned view may outlive its origin '" ++ origin_name ++ "'", report_node)
                            return
    if self.ast.kind(expr_node) == NodeKind.NK_IDENT:
        let view_sym = self.ast.get_data0(expr_node)
        let view_ty = self.scope_lookup(view_sym)
        if view_ty > 0:
            let view_tk = self.get_type_kind(self.resolve_alias(view_ty as TypeId))
            if view_tk == TypeKind.TY_REF and self.param_index_for_sym(view_sym) < 0 and self.binding_view_origin_mask(view_sym) == 0 and self.binding_view_dep_count(view_sym) == 0:
                if self.binding_value_nodes.contains(view_sym):
                    let init_node = self.binding_value_nodes.get(view_sym).unwrap()
                    let init_kind = self.ast.kind(init_node)
                    if init_kind == NodeKind.NK_UNARY and self.ast.get_data0(init_node) == UnaryOp.UOP_REF:
                        let origin_sym = self.place_root_sym(self.ast.get_data1(init_node))
                        if self.view_origin_is_stack_local(origin_sym) != 0:
                            let origin_name = self.pool_resolve(origin_sym)
                            self.emit_error("returned view may outlive its origin '" ++ origin_name ++ "'", report_node)
                            return
                    if init_kind == NodeKind.NK_CALL or init_kind == NodeKind.NK_FIELD_ACCESS or init_kind == NodeKind.NK_UNARY:
                        let view_name = self.pool_resolve(view_sym)
                        self.emit_error("returned view may outlive its origin via local binding '" ++ view_name ++ "'", report_node)
                        return
    let deps: Vec[i32] = Vec.new()
    self.collect_expr_view_deps(expr_node, deps)
    for i in 0..deps.len() as i32:
        let origin_sym = deps.get(i as i64)
        if origin_sym == 0:
            continue
        if self.view_origin_is_stack_local(origin_sym) != 0:
            let origin_name = self.pool_resolve(origin_sym)
            self.emit_error("returned view may outlive its origin '" ++ origin_name ++ "'", report_node)
            return

fn Sema.record_call_view_origins(self: Sema, call_node: i32, sig_idx: i32, param_offset: i32, recv_node: i32, extra_start: i32, arg_count: i32, has_resolved: i32):
    if call_node == 0 or sig_idx < 0:
        return
    let param_count = self.sig_get_param_count(sig_idx)
    var union_mask = 0
    let concrete_deps: Vec[i32] = Vec.new()
    for pi in 0..param_count:
        if (self.sig_param_effect(sig_idx, pi) & EFF_ESCAPE_VIEW) == 0:
            continue
        let param_origin_mask = self.sig_param_view_origin(sig_idx, pi)
        for origin_pi in 0..param_count:
            if (param_origin_mask & (((1 as i64) << (origin_pi as u32)) as i32)) == 0:
                continue
            var origin_arg = 0
            if param_offset == 1 and origin_pi == 0:
                origin_arg = recv_node
            else:
                let arg_index = if param_offset == 1: origin_pi - 1 else: origin_pi
                if arg_index >= 0 and arg_index < arg_count:
                    origin_arg = if has_resolved != 0: self.get_resolved_call_arg(call_node, arg_index) else: self.ast.get_extra(extra_start + arg_index)
            if origin_arg > 0:
                union_mask = union_mask | self.compute_expr_view_origin_mask(origin_arg)
                let dep_len_before = concrete_deps.len() as i32
                self.collect_expr_view_deps(origin_arg, concrete_deps)
                if concrete_deps.len() as i32 == dep_len_before:
                    self.push_unique_i32(concrete_deps, self.place_root_sym(origin_arg))
    if union_mask != 0 or concrete_deps.len() > 0:
        self.set_expr_view_deps(call_node, union_mask, concrete_deps)

fn Sema.check_return(self: Sema, node: i32) -> i32:
    if self.in_defer != 0:
        self.emit_error("return not allowed in defer", node)
    let value = self.ast.get_data0(node)
    if value != 0:
        let val_type = if self.current_return_type != 0: self.check_expr_with_expected(value, self.current_return_type) else: self.check_expr(value)
        // If returned value originates from a parameter, record effects:
        // - EFF_ESCAPE_VALUE: a non-Copy owned value escaping via return
        //   (returning a Copy field is a read, not a consumption)
        // - EFF_ESCAPE_VIEW: a reference (&T) escaping via return
        if self.is_copy(val_type) == 0:
            self.note_place_effect(value, EFF_ESCAPE_VALUE)
        let val_kind = self.get_type_kind(self.resolve_alias(val_type))
        if val_kind == TypeKind.TY_REF or val_kind == TypeKind.TY_PTR:
            self.note_place_effect(value, EFF_ESCAPE_VIEW)
            let root = self.place_root_sym(value)
            if root != 0:
                self.note_param_view_origin(root, self.compute_expr_view_origin_mask(value))
            if val_kind == TypeKind.TY_REF:
                self.check_returned_view_origins(value, node)
        if self.current_return_type != 0 and val_type != 0:
            let compat = self.types_compatible(self.current_return_type as i32, val_type as i32)
            let arith = if compat == 0: self.arithmetic_result_type(self.current_return_type, val_type) else: 1 as TypeId
            if compat == 0:
                if arith == 0:
                    self.emit_error("return type mismatch", node)
    self.ty_never as i32

fn Sema.check_assign(self: Sema, node: i32) -> i32:
    let target = self.ast.get_data0(node)
    let value = self.ast.get_data1(node)

    if self.is_runtime_multi_index_node(target) != 0:
        let base_expr = self.multi_index_base_expr(target)
        let base_ty = self.check_multi_index_like_operands(target)
        var expected_value_type = 0

        if base_ty != 0:
            let base_resolved = self.resolve_alias(base_ty)
            let base_name = self.get_type_name(base_resolved as i32)
            if base_name != 0:
                let mis_sym = self.pool_intern("multi_index_set")
                let mis_sig = self.lookup_method_sig(base_name, mis_sym)
                if mis_sig >= 0:
                    if self.validate_multi_index_method_sig(mis_sig, mis_sym, 1, target) != 0:
                        expected_value_type = self.sig_param_type(mis_sig, 3)
                else:
                    self.emit_error("type does not support indexed assignment (no multi_index_set method)", target)
            else:
                self.emit_error("type does not support indexed assignment (no multi_index_set method)", target)

        let value_type = if expected_value_type != 0: self.check_expr_with_expected(value, expected_value_type as TypeId) else: self.check_expr(value)
        self.note_place_effect(base_expr, EFF_WRITE)

        let lhs_packed = self.classify_place(base_expr)
        let lhs_kind = unpack_place_kind(lhs_packed)
        let lhs_mut_state = unpack_place_mut(lhs_packed)
        if lhs_kind == PlaceKind.PK_NotPlace:
            self.emit_warning("cannot assign to a non-place expression", node)
        else if lhs_mut_state == PlaceMut.PM_ReadOnly:
            self.emit_error("cannot assign through a read-only place (e.g., dereferenced &T or *const T) (§15.10)", node)

        let assign_root = self.place_root_sym(base_expr)
        if assign_root != 0 and self.scope_is_view_bound(assign_root) != 0:
            self.emit_error("cannot mutate through read-only view yielded by iterator (§15.17)", node)

        if lhs_kind != PlaceKind.PK_NotPlace and lhs_mut_state != PlaceMut.PM_ReadOnly:
            self.check_mutation_against_views(base_expr, node)

        if expected_value_type != 0 and value_type != 0:
            if self.types_compatible(expected_value_type as TypeId, value_type as TypeId) == 0:
                if self.arithmetic_result_type(expected_value_type as TypeId, value_type as TypeId) == 0:
                    self.emit_error("type mismatch in assignment", node)

        self.mark_moved_if_consumed(value)
        return self.ty_void as i32

    let target_type = self.check_expr(target)
    let value_type = if target_type != 0: self.check_expr_with_expected(value, target_type) else: self.check_expr(value)

    // If assignment target's root is a parameter, record EFF_WRITE
    self.note_place_effect(target, EFF_WRITE)

    // Check mutability
    if self.ast.kind(target) == NodeKind.NK_IDENT:
        let target_sym = self.ast.get_data0(target)
        if self.scope_has(target_sym) != 0:
            if self.scope_lookup_mut(target_sym) == 0:
                // docs/mut.md Rev 8 §15.12 — when the immutable binding is
                // a stable global (`global X = ...`), emit the more
                // specific diagnostic suggesting `global var` for
                // rebindability.
                if self.is_stable_global(target_sym) != 0:
                    let gn = self.pool_resolve(target_sym)
                    self.emit_error("cannot rebind global `" ++ gn ++ "`; declared as `global` (stable). Use `global var " ++ gn ++ " = ...` to allow rebinding, or mutate the existing value (§15.12)", node)
                else:
                    self.emit_error("cannot assign to immutable variable", node)
    else:
        // docs/mut.md Rev 8 §6 — assignment LHS must be a mutable place.
        // Already covered above for plain identifiers via binding-mut. For
        // projection LHS (field, index, deref), consult classify_place.
        // Warnings during P7..P11; promoted to errors at P12 lockdown.
        let lhs_packed = self.classify_place(target)
        let lhs_kind = unpack_place_kind(lhs_packed)
        let lhs_mut_state = unpack_place_mut(lhs_packed)
        if lhs_kind == PlaceKind.PK_NotPlace:
            // docs/mut.md Rev 8 §15.11 — distinguish "type does not support
            // index assignment" (no IndexPlace impl) from generic non-place
            // when the LHS is an index expression on an ordinary place.
            if self.ast.kind(target) == NodeKind.NK_INDEX:
                let idx_base = self.ast.get_data0(target)
                let base_packed = self.classify_place(idx_base)
                if unpack_place_kind(base_packed) != PlaceKind.PK_NotPlace:
                    self.emit_error("type does not support index assignment (no IndexPlace impl) (§15.11)", node)
                else:
                    self.emit_warning("cannot assign to a non-place expression", node)
            else:
                self.emit_warning("cannot assign to a non-place expression", node)
        else if lhs_mut_state == PlaceMut.PM_ReadOnly:
            self.emit_error("cannot assign through a read-only place (e.g., dereferenced &T or *const T) (§15.10)", node)
        // docs/mut.md Rev 8 §15.17 — mutation through a view-bound
        // for-loop variable (e.g., `for u in xs.iter(): u.age += 1`).
        let assign_root = self.place_root_sym(target)
        if assign_root != 0 and self.scope_is_view_bound(assign_root) != 0:
            self.emit_error("cannot mutate through read-only view yielded by iterator (§15.17)", node)

    let mutation_packed = self.classify_place(target)
    if unpack_place_kind(mutation_packed) != PlaceKind.PK_NotPlace and unpack_place_mut(mutation_packed) != PlaceMut.PM_ReadOnly:
        self.check_mutation_against_views(target, node)

    // Check type compatibility
    if target_type != 0 and value_type != 0:
        if self.types_compatible(target_type as i32, value_type as i32) == 0:
            if self.arithmetic_result_type(target_type, value_type) == 0:
                self.emit_error("type mismatch in assignment", node)

    // Move semantics
    self.mark_moved_if_consumed(value)

    // Reinitialize target
    if self.ast.kind(target) == NodeKind.NK_IDENT:
        let target_sym = self.ast.get_data0(target)
        self.scope_set_state(target_sym, VarState.LIVE)
        self.binding_value_nodes.insert(target_sym, value)
        self.scope_set_is_task(target_sym, self.expr_is_task_value(value))
        self.scope_set_is_scoped_task(target_sym, self.expr_is_scoped_task_value(value))
        self.scope_set_is_ephemeral_task(target_sym, self.expr_is_ephemeral_task(value))
        if self.ast.kind(value) == NodeKind.NK_CLOSURE:
            self.binding_closure_nodes.insert(target_sym, value)
        else:
            self.binding_closure_nodes.remove(target_sym)
        let tgt_kind = self.get_type_kind(self.resolve_alias(target_type as TypeId))
        if tgt_kind == TypeKind.TY_REF or tgt_kind == TypeKind.TY_PTR:
            self.record_view_binding_from_expr(target_sym, value)
        else:
            self.clear_binding_view_deps(target_sym)

    if target_type != 0:
        return target_type as i32
    self.ty_void as i32

fn Sema.preferred_compatible_type(self: Sema, lhs: TypeId, rhs: TypeId) -> TypeId:
    if lhs == 0:
        return rhs
    if rhs == 0:
        return lhs

    let lhs_resolved = self.resolve_alias(lhs)
    let rhs_resolved = self.resolve_alias(rhs)
    if lhs_resolved == rhs_resolved:
        return lhs

    let lhs_kind = self.get_type_kind(lhs_resolved)
    let rhs_kind = self.get_type_kind(rhs_resolved)
    if lhs_kind == TypeKind.TY_GENERIC_INST and (rhs_kind == TypeKind.TY_STRUCT or rhs_kind == TypeKind.TY_ENUM):
        if self.get_type_d0(lhs_resolved) == self.get_type_d0(rhs_resolved):
            return lhs
    if rhs_kind == TypeKind.TY_GENERIC_INST and (lhs_kind == TypeKind.TY_STRUCT or lhs_kind == TypeKind.TY_ENUM):
        if self.get_type_d0(lhs_resolved) == self.get_type_d0(rhs_resolved):
            return rhs
    lhs

fn Sema.check_for(self: Sema, node: i32) -> i32:
    let binding = self.ast.get_data0(node)
    let iterable = self.ast.get_data1(node)
    let body = self.ast.get_data2(node)

    let iter_type = self.check_expr(iterable)
    let elem_type = self.infer_for_element_type(iter_type as i32)

    // docs/mut.md Rev 8 §11.4 / §15.17 — when the iterable is a .iter()
    // call (or any iter_of_self method), the iterator yields &T views.
    // Mark the binding as a view-bound variable so check_assign can emit
    // §15.17 when mutation through it is attempted.
    let yields_views = self.for_iterable_yields_views(iterable)

    self.push_scope()
    if self.ast.for_binding_is_pattern(node):
        self.check_pattern(binding, elem_type)
    else:
        self.scope_put(binding, elem_type, 0)
    if yields_views != 0 and binding != 0:
        self.scope_set_is_view_bound(binding)
    let for_meta = self.ast.find_for_meta(node)
    var label = 0
    if for_meta >= 0:
        let index_binding = self.ast.for_meta_index_binding(for_meta)
        label = self.ast.for_meta_label(for_meta)
        if index_binding != 0:
            self.scope_put(index_binding, self.ty_i64 as i32, 0)
    self.loop_depth = self.loop_depth + 1
    self.push_label_frame(label, LabelFrameKind.LFK_FOR, node)
    let saved_drop_cf_for = self.drop_control_flow_depth
    if self.current_drop_type_sym != 0:
        self.drop_control_flow_depth = self.drop_control_flow_depth + 1
    self.check_expr(body)
    self.drop_control_flow_depth = saved_drop_cf_for
    self.pop_label_frame()
    self.loop_depth = self.loop_depth - 1
    self.pop_scope()
    self.ty_void as i32

fn Sema.struct_field_info_by_index(self: Sema, struct_type: i32, index: i32) -> i64:
    if struct_type == 0:
        return 0
    let resolved = self.resolve_alias(struct_type)
    let tk = self.get_type_kind(resolved)
    if tk == TypeKind.TY_STRUCT:
        let te_start = self.get_type_d1(resolved)
        let field_count = self.get_type_d2(resolved)
        if index >= 0 and index < field_count:
            let f_name = self.type_extra.get((te_start + index * 3) as i64)
            let f_type = self.type_extra.get((te_start + index * 3 + 1) as i64)
            return (f_name as i64) | ((f_type as i64) * 4294967296)
    0

fn Sema.struct_field_type(self: Sema, struct_type: i32, field: i32) -> i32:
    if struct_type == 0:
        return 0

    let resolved = self.resolve_alias(struct_type)
    let tk = self.get_type_kind(resolved)

    if tk == TypeKind.TY_STRUCT:
        let te_start = self.get_type_d1(resolved)
        let field_count = self.get_type_d2(resolved)
        for fi in 0..field_count:
            let f_name = self.type_extra.get((te_start + fi * 3) as i64)
            if f_name == field:
                return self.type_extra.get((te_start + fi * 3 + 1) as i64)
        return 0

    if tk == TypeKind.TY_GENERIC_INST:
        let gi_base_sym = self.get_type_d0(resolved)
        if self.type_decl_nodes.contains(gi_base_sym):
            let td_node = self.type_decl_nodes.get(gi_base_sym).unwrap()
            let td_extra = self.ast.get_data1(td_node)
            let td_packed = self.ast.get_data2(td_node)
            if type_decl_sub_kind(td_packed) == TypeDeclKind.Struct:
                let fc = self.ast.get_extra(td_extra)
                let after = td_extra + 1 + fc * 4
                let tp_start = self.ast.get_extra(after + 1)
                let tp_count = self.ast.get_extra(after + 2)
                if self.setup_generic_inst_substitution(resolved, gi_base_sym) != 0:
                    for gi_fi in 0..fc:
                        let base = td_extra + 1 + gi_fi * 3
                        let f_name = self.ast.get_extra(base)
                        if f_name == field:
                            let f_type_node = self.ast.get_extra(base + 1)
                            return self.resolve_generic_return_type_node(f_type_node, tp_start, tp_count)
                else:
                    let gi_struct_tid = self.lookup_named_type_visible(gi_base_sym)
                    if gi_struct_tid != 0:
                        let gi_te_start = self.get_type_d1(gi_struct_tid)
                        for gi_fi in 0..fc:
                            let gi_f_name = self.type_extra.get((gi_te_start + gi_fi * 3) as i64)
                            if gi_f_name == field:
                                return self.type_extra.get((gi_te_start + gi_fi * 3 + 1) as i64)
        return 0

    0

fn Sema.field_access_type_no_diagnostic(self: Sema, node: i32) -> i32:
    if node == 0 or self.ast.kind(node) != NodeKind.NK_FIELD_ACCESS:
        return 0
    let expr = self.ast.get_data0(node)
    let field = self.ast.get_data1(node)
    var obj_type = self.check_expr(expr)
    let static_type_sym = self.static_receiver_base_sym(expr)
    let static_expr_kind = self.ast.kind(expr)
    if static_type_sym != 0 and self.static_receiver_type_is_known(expr) != 0 and (static_expr_kind == NodeKind.NK_IDENT or static_expr_kind == NodeKind.NK_TYPE_NAMED):
        let static_prim = self.primitive_type_by_sym(static_type_sym)
        if static_prim != 0:
            obj_type = static_prim as TypeId
        else:
            let static_named = self.lookup_named_type_visible(static_type_sym)
            if static_named != 0:
                obj_type = static_named as TypeId
    if obj_type == 0:
        return 0
    let field_base = self.auto_deref_ref_ptr_type(obj_type)
    let ftk = self.get_type_kind(field_base)
    if ftk == TypeKind.TY_STRUCT or ftk == TypeKind.TY_GENERIC_INST:
        return self.struct_field_type(field_base as i32, field)
    if ftk == TypeKind.TY_TUPLE:
        let te_start = self.get_type_d0(field_base)
        let elem_count = self.get_type_d1(field_base)
        let field_name = self.pool_resolve(field)
        var idx = 0
        for vi in 0..field_name.len() as i32:
            let ch = field_name[vi]
            if ch >= 48 and ch <= 57:
                idx = idx * 10 + ch - 48
        if idx < elem_count:
            return self.type_extra.get((te_start + idx) as i64)
    0

fn Sema.auto_deref_ref_ptr_type(self: Sema, tid: TypeId) -> TypeId:
    var current = self.resolve_alias(tid)
    var depth = 0
    while depth < 32:
        let tk = self.get_type_kind(current)
        if tk != TypeKind.TY_PTR and tk != TypeKind.TY_REF:
            return current
        let inner = self.get_type_d0(current)
        if inner == 0:
            return current
        current = self.resolve_alias(inner as TypeId)
        depth = depth + 1
    current

fn Sema.check_field_access(self: Sema, node: i32) -> i32:
    let expr = self.ast.get_data0(node)
    let field = self.ast.get_data1(node)

    // comptime cfg.field → resolve to compile-time constant type
    // Only apply when 'cfg' is not a local variable
    if self.ast.kind(expr) == NodeKind.NK_IDENT:
        let cfg_sym = self.ast.get_data0(expr)
        if self.pool_resolve(cfg_sym) == "cfg" and self.scope_lookup(cfg_sym) < 0:
            let field_name = self.pool_resolve(field)
            if field_name == "is_debug" or field_name == "is_release":
                return self.ty_bool as i32
            return self.ty_str as i32

    var obj_type = self.check_expr(expr)
    let static_type_sym = self.static_receiver_base_sym(expr)
    let static_expr_kind = self.ast.kind(expr)
    if static_type_sym != 0 and self.static_receiver_type_is_known(expr) != 0 and (static_expr_kind == NodeKind.NK_IDENT or static_expr_kind == NodeKind.NK_TYPE_NAMED):
        let static_prim = self.primitive_type_by_sym(static_type_sym)
        if static_prim != 0:
            obj_type = static_prim as TypeId
        else:
            let static_named = self.lookup_named_type_visible(static_type_sym)
            if static_named != 0:
                obj_type = static_named as TypeId
        // docs/mut.md Rev 8 §5.3 / §15.4 — `Vec.push` (etc.) parsed as a
        // first-class value expression. Method calls dispatch through
        // check_method_call, which never invokes check_field_access on the
        // callee node. Reaching this point with a static-type base means
        // the field-access is being USED AS A VALUE — i.e., as a method
        // reference. Reject when the resolved method is mutating.
        // Helper: closure-wrap the call:
        //     let f = (xs, value) => xs.push(value)
        let static_owner_sym = self.method_owner_symbol_for_type(obj_type as i32)
        if static_owner_sym != 0:
            let mutating = self.method_has_mut_self_flag(static_owner_sym, field) != 0 or self.builtin_method_requires_mutable_receiver(static_owner_sym, field) != 0
            if mutating:
                let owner_name = self.pool_resolve(static_type_sym)
                let method_name = self.pool_resolve(field)
                self.emit_error("cannot reference mutating method `" ++ owner_name ++ "." ++ method_name ++ "` as a first-class function value (§15.4); wrap in a closure: `(x, ...) => x." ++ method_name ++ "(...)`", node)

    if obj_type == 0:
        return 0

    let field_base = self.auto_deref_ref_ptr_type(obj_type)

    if self.is_tool_capability_type(field_base as i32) and not self.can_access_tool_capability_internals():
        self.emit_error("tool capability fields are private; use capability methods instead", node)
        return 0

    let ftk = self.get_type_kind(field_base)

    if self.is_opaque_value_type(field_base as i32) != 0:
        self.emit_error("field access requires a concrete struct or union type; this type is opaque", node)
        return 0

    if ftk == TypeKind.TY_STRUCT:
        let _ = self.get_type_d0(field_base)
        return self.struct_field_type(field_base as i32, field)

    if ftk == TypeKind.TY_GENERIC_INST:
        return self.struct_field_type(field_base as i32, field)

    if ftk == TypeKind.TY_TUPLE:
        let te_start = self.get_type_d0(field_base)
        let elem_count = self.get_type_d1(field_base)
        let field_name = self.pool_resolve(field)
        // Parse field index
        var idx = 0
        for vi in 0..field_name.len() as i32:
            let ch = field_name[vi]
            if ch >= 48 and ch <= 57:
                idx = idx * 10 + ch - 48
        if idx < elem_count:
            return self.type_extra.get((te_start + idx) as i64)
        return 0

    if ftk == TypeKind.TY_ARRAY or ftk == TypeKind.TY_SLICE or ftk == TypeKind.TY_STR:
        let field_name = self.pool_resolve(field)
        if field_name == "len":
            return self.ty_i64 as i32
        return 0

    if ftk == TypeKind.TY_ENUM:
        if self.static_receiver_type_is_known(expr) != 0 and self.enum_has_variant(obj_type as i32, field) != 0:
            return field_base as i32
        return 0

    0

fn Sema.check_computed_field_access(self: Sema, node: i32) -> i32:
    let expr = self.ast.get_data0(node)
    let field_expr = self.ast.get_data1(node)
    let _ = self.check_expr(expr)
    let field_ty = self.check_expr(field_expr)
    if self.in_comptime_fn == 0:
        self.emit_error("computed field access requires comptime context", node)
        return 0
    if field_ty != 0 and self.resolve_alias(field_ty) != self.ty_str:
        self.emit_error("computed field access requires a string field name", field_expr)
    // Defer concrete field resolution until the comptime transform rewrites
    // this node to a normal NK_FIELD_ACCESS.
    0

fn Sema.index_expr_is_type_level(self: Sema, expr: i32) -> bool:
    if expr == 0:
        return false
    let kind = self.ast.kind(expr)
    if kind == NodeKind.NK_IDENT:
        let sym = self.ast.get_data0(expr)
        return self.has_named_type_visible(sym) != 0
    if kind == NodeKind.NK_INDEX or kind == NodeKind.NK_GROUPED:
        return self.index_expr_is_type_level(self.ast.get_data0(expr))
    false

fn Sema.check_vec_literal_elem(self: Sema, elem_ty: i32, elem_node: i32, arg_index: i32):
    if elem_node == 0:
        return
    let actual_ty = self.check_expr_with_expected(elem_node, elem_ty)
    if elem_ty != 0 and actual_ty != 0:
        if self.types_compatible(elem_ty, actual_ty) == 0:
            if self.arithmetic_result_type(elem_ty, actual_ty) == 0:
                self.emit_argument_type_mismatch("Vec.literal", 0, arg_index, arg_index, elem_ty, actual_ty, elem_node)

fn Sema.check_runtime_index_operand(self: Sema, index_node: i32) -> i32:
    let index_ty = self.check_expr_with_expected(index_node, 0 as TypeId)
    if index_ty == 0:
        return 0
    let index_unwrapped = self.unwrap_builtin_arg_distinct(index_ty)
    let numeric_index_ty = self.numeric_operand_type(index_unwrapped)
    if self.get_type_kind(numeric_index_ty) != TypeKind.TY_INT:
        self.emit_error("index expression must be an integer", index_node)
    return index_ty as i32

fn Sema.check_index(self: Sema, node: i32) -> i32:
    let expr = self.ast.get_data0(node)
    let index = self.ast.get_data1(node)
    let index2 = self.ast.get_data2(node)
    let arr_type = self.check_expr(expr)

    if arr_type == 0:
        self.check_expr(index)
        if index2 != 0:
            self.check_expr(index2)
        return 0

    if index2 != 0 and self.index_expr_is_type_level(expr) == 0:
        return self.check_pair_multi_index(node, arr_type)

    let resolved = self.resolve_alias(arr_type)
    let tk = self.get_type_kind(resolved)
    if tk == TypeKind.TY_PTR:
        self.check_runtime_index_operand(index)
        if self.in_unsafe == 0:
            self.emit_error("raw pointer indexing requires unsafe context", node)
            return 0
        let elem_ty = self.get_type_d0(resolved)
        self.typed_expr_types.insert(node, elem_ty)
        return elem_ty
    var container_tid = resolved
    var container_tk = tk
    if container_tk == TypeKind.TY_REF:
        container_tid = self.resolve_alias(self.get_type_d0(container_tid))
        container_tk = self.get_type_kind(container_tid)
        if container_tk == TypeKind.TY_PTR:
            self.check_runtime_index_operand(index)
            if self.in_unsafe == 0:
                self.emit_error("raw pointer indexing requires unsafe context", node)
                return 0
            let elem_ty = self.get_type_d0(container_tid)
            self.typed_expr_types.insert(node, elem_ty)
            return elem_ty
    if container_tk == TypeKind.TY_ARRAY:
        self.check_runtime_index_operand(index)
        let elem_ty = self.get_type_d0(container_tid)
        self.typed_expr_types.insert(node, elem_ty)
        return elem_ty
    if container_tk == TypeKind.TY_SLICE:
        self.check_runtime_index_operand(index)
        let elem_ty = self.get_type_d0(container_tid)
        self.typed_expr_types.insert(node, elem_ty)
        return elem_ty
    if container_tk == TypeKind.TY_GENERIC_INST:
        let base_name = self.pool_resolve(self.get_type_d0(container_tid))
        let is_type_level_index = self.index_expr_is_type_level(expr)
        if is_type_level_index and base_name == "Vec" and self.get_generic_inst_arg_count(container_tid) > 0:
            let elem_ty = self.get_generic_inst_arg(container_tid, 0)
            self.check_vec_literal_elem(elem_ty, index, 0)
            if index2 != 0:
                self.check_vec_literal_elem(elem_ty, index2, 1)
            self.typed_expr_types.insert(node, container_tid as i32)
            return container_tid as i32
        if not is_type_level_index and base_name == "Vec" and self.get_generic_inst_arg_count(container_tid) > 0:
            self.check_runtime_index_operand(index)
            let elem_ty = self.get_generic_inst_arg(container_tid, 0)
            self.typed_expr_types.insert(node, elem_ty)
            return elem_ty

    // Type-level NodeKind.NK_INDEX: Vec[i32], HashMap[str, i32], etc.
    // Create TypeKind.TY_GENERIC_INST so MirLower can find it in the sema snapshot.
    if container_tk == TypeKind.TY_STRUCT:
        if self.ast.kind(expr) == NodeKind.NK_IDENT:
            let ci_base_sym = self.ast.get_data0(expr)
            if self.has_named_type_visible(ci_base_sym) != 0:
                var ci_arg_type = self.resolve_type_level_arg_expr(index)
                if ci_arg_type > 0:
                    // Check for second type arg (d2 of NodeKind.NK_INDEX) — HashMap[K, V]
                    let ci_index2 = self.ast.get_data2(node)
                    var ci_arg2_type = 0
                    if ci_index2 != 0:
                        ci_arg2_type = self.resolve_type_level_arg_expr(ci_index2)
                    let ci_args: Vec[i32] = Vec.new()
                    ci_args.push(ci_arg_type)
                    var ci_arg_count = 1
                    if ci_arg2_type > 0:
                        ci_args.push(ci_arg2_type)
                        ci_arg_count = 2
                    let ci_cache_key = sema_generic_inst_hash(ci_base_sym, ci_args, ci_arg_count)
                    if self.generic_inst_cache.contains(ci_cache_key):
                        let ci_result = self.generic_inst_cache.get(ci_cache_key).unwrap()
                        self.typed_expr_types.insert(node, ci_result)
                        return ci_result
                    let ci_tid = self.ensure_generic_inst_type(ci_base_sym, ci_args, ci_arg_count)
                    self.typed_expr_types.insert(node, ci_tid as i32)
                    return ci_tid as i32
    0

fn Sema.is_runtime_multi_index_node(self: Sema, node: i32) -> i32:
    let kind = self.ast.kind(node)
    if kind == NodeKind.NK_MULTI_INDEX:
        return 1
    if kind == NodeKind.NK_INDEX:
        if self.ast.get_data2(node) != 0 and self.index_expr_is_type_level(self.ast.get_data0(node)) == 0:
            return 1
    0

fn Sema.multi_index_base_expr(self: Sema, node: i32) -> i32:
    self.ast.get_data0(node)

fn Sema.check_multi_index_part(self: Sema, node: i32, label: str):
    if node == 0:
        return
    let ty = self.check_expr_with_expected(node, self.ty_i64)
    if ty == 0:
        return
    let resolved = self.resolve_alias(ty)
    if self.get_type_kind(resolved) != TypeKind.TY_INT:
        self.emit_error("multi-dimensional index " ++ label ++ " must be an integer", node)

fn Sema.check_multi_index_operands(self: Sema, node: i32) -> TypeId:
    let base = self.ast.get_data0(node)
    let specs_start = self.ast.get_data1(node)
    let specs_count = self.ast.get_data2(node)
    let base_ty = self.check_expr(base)
    var ellipsis_count = 0
    for si in 0..specs_count:
        let spec = self.ast.get_extra(specs_start + si)
        let d0 = self.ast.get_data0(spec)
        let d1 = self.ast.get_data1(spec)
        let d2 = self.ast.get_data2(spec)
        let kind = d2 / INDEX_KIND_SHIFT
        if kind == INDEX_ELLIPSIS:
            ellipsis_count = ellipsis_count + 1
        if ellipsis_count > 1:
            self.emit_error("multi-dimensional index may contain at most one ellipsis", spec)
        self.check_multi_index_part(d0, "start")
        self.check_multi_index_part(d1, "stop")
        let step = d2 - kind * INDEX_KIND_SHIFT
        self.check_multi_index_part(step, "step")
    base_ty

fn Sema.check_pair_multi_index_operands(self: Sema, node: i32, base_ty: TypeId) -> TypeId:
    self.check_multi_index_part(self.ast.get_data1(node), "start")
    self.check_multi_index_part(self.ast.get_data2(node), "start")
    base_ty

fn Sema.check_multi_index_like_operands(self: Sema, node: i32) -> TypeId:
    if self.ast.kind(node) == NodeKind.NK_MULTI_INDEX:
        return self.check_multi_index_operands(node)
    if self.ast.kind(node) == NodeKind.NK_INDEX:
        let base_ty = self.check_expr(self.ast.get_data0(node))
        return self.check_pair_multi_index_operands(node, base_ty)
    0 as TypeId

fn Sema.check_multi_index_method(self: Sema, node: i32, base_ty: TypeId) -> i32:
    if base_ty == 0:
        return 0
    let base_resolved = self.resolve_alias(base_ty)
    let base_name = self.get_type_name(base_resolved as i32)
    if base_name != 0:
        let mi_sym = self.pool_intern("multi_index")
        let mi_sig = self.lookup_method_sig(base_name, mi_sym)
        if mi_sig >= 0:
            if self.validate_multi_index_method_sig(mi_sig, mi_sym, 0, node) != 0:
                return self.sig_return_type(mi_sig)
            return 0
    self.emit_error("type does not support multi-dimensional indexing", node)
    0

fn Sema.check_pair_multi_index(self: Sema, node: i32, base_ty: TypeId) -> i32:
    let checked_base_ty = self.check_pair_multi_index_operands(node, base_ty)
    self.check_multi_index_method(node, checked_base_ty)

fn Sema.is_index_spec_slice_ref_type(self: Sema, tid: i32) -> i32:
    if tid == 0:
        return 0
    let ref_resolved = self.resolve_alias(tid as TypeId)
    if self.get_type_kind(ref_resolved) != TypeKind.TY_REF:
        return 0
    let slice_tid = self.get_type_d0(ref_resolved)
    let slice_resolved = self.resolve_alias(slice_tid as TypeId)
    if self.get_type_kind(slice_resolved) != TypeKind.TY_SLICE:
        return 0
    let elem_tid = self.get_type_d0(slice_resolved)
    let elem_resolved = self.resolve_alias(elem_tid as TypeId)
    if self.get_type_kind(elem_resolved) != TypeKind.TY_STRUCT:
        return 0
    let elem_name = self.get_type_d0(elem_resolved)
    if self.pool_resolve(elem_name) == "IndexSpec":
        return 1
    0

fn Sema.validate_multi_index_method_sig(self: Sema, sig_idx: i32, method_sym: i32, is_set: i32, node: i32) -> i32:
    let method_name = self.pool_resolve(method_sym)
    let expected_count = if is_set != 0: 4 else: 3
    if self.sig_get_param_count(sig_idx) != expected_count:
        let value_text = if is_set != 0: ", value" else: ""
        self.emit_error("method `" ++ method_name ++ "` must have signature `(self, specs: &[IndexSpec], count: i32" ++ value_text ++ ")`", node)
        return 0
    if self.is_index_spec_slice_ref_type(self.sig_param_type(sig_idx, 1)) == 0:
        self.emit_error("method `" ++ method_name ++ "` second parameter must be `&[IndexSpec]`", node)
        return 0
    let count_ty = self.resolve_alias(self.sig_param_type(sig_idx, 2) as TypeId)
    if count_ty != self.ty_i32:
        self.emit_error("method `" ++ method_name ++ "` count parameter must be `i32`", node)
        return 0
    if is_set != 0:
        let ret_ty = self.resolve_alias(self.sig_return_type(sig_idx) as TypeId)
        if ret_ty != self.ty_void:
            self.emit_error("method `" ++ method_name ++ "` must return void", node)
            return 0
    1

fn Sema.check_multi_index(self: Sema, node: i32) -> i32:
    let base_ty = self.check_multi_index_operands(node)
    self.check_multi_index_method(node, base_ty)

fn Sema.check_slice(self: Sema, node: i32) -> i32:
    let expr = self.ast.get_data0(node)
    let start = self.ast.get_data1(node)
    let end = self.ast.get_data2(node)
    let arr_type = self.check_expr(expr)
    if start != 0:
        self.check_expr(start)
    if end != 0:
        self.check_expr(end)

    if arr_type == 0:
        return 0

    let resolved = self.resolve_alias(arr_type)
    let tk = self.get_type_kind(resolved)
    if tk == TypeKind.TY_ARRAY:
        let elem = self.get_type_d0(resolved)
        return self.add_type(TypeKind.TY_SLICE, elem, 0, 0) as i32
    if tk == TypeKind.TY_SLICE:
        return resolved as i32
    0

fn Sema.check_array_literal(self: Sema, node: i32) -> i32:
    let extra_start = self.ast.get_data0(node)
    let elem_count = self.ast.get_data1(node)
    var expected_elem = 0
    if self.has_expected_type != 0 and self.expected_expr_type != 0:
        let expected = self.resolve_alias(self.expected_expr_type)
        let expected_kind = self.get_type_kind(expected)
        if expected_kind == TypeKind.TY_ARRAY or expected_kind == TypeKind.TY_SLICE:
            expected_elem = self.get_type_d0(expected)
    if elem_count == 0:
        if self.has_expected_type != 0 and self.expected_expr_type != 0:
            self.typed_expr_types.insert(node, self.expected_expr_type as i32)
            return self.expected_expr_type as i32
        return 0

    var elem_type = 0
    for i in 0..elem_count:
        let elem = self.ast.get_extra(extra_start + i)
        let et = if expected_elem != 0:
            self.check_expr_with_expected(elem, expected_elem as TypeId)
        else if elem_type != 0 and sema_node_is_numeric_literal(self.ast, elem):
            self.check_expr_with_expected(elem, elem_type as TypeId)
        else:
            self.check_expr(elem)
        if elem_type == 0:
            elem_type = et as i32

    if expected_elem != 0:
        elem_type = expected_elem
    let result: TypeId = if self.has_expected_type != 0 and self.expected_expr_type != 0 and expected_elem != 0:
        self.expected_expr_type
    else:
        self.add_type(TypeKind.TY_ARRAY, elem_type, elem_count, 0)
    self.typed_expr_types.insert(node, result as i32)
    result as i32

fn Sema.check_struct_literal(self: Sema, node: i32) -> i32:
    let name = self.ast.get_data0(node)
    let extra_start = self.ast.get_data1(node)
    let field_count = self.ast.get_data2(node)

    let tid = self.lookup_named_type_visible(name)
    if tid == 0:
        if self.pool_resolve(name) != "Self":
            self.emit_error("unknown type '" ++ self.pool_resolve(name) ++ "' in struct literal", node)
        return 0
    if self.reject_tool_capability_construction_if_needed(name, tid, node):
        return 0
    if tid != 0:
        let resolved = self.resolve_alias(tid as TypeId)
        if self.get_type_kind(resolved) == TypeKind.TY_STRUCT:
            var expected_struct_ty: TypeId = 0 as TypeId
            if self.has_expected_type != 0 and self.expected_expr_type != 0:
                let expected_resolved = self.resolve_alias(self.expected_expr_type)
                let expected_tk = self.get_type_kind(expected_resolved)
                if expected_tk == TypeKind.TY_STRUCT and self.get_type_d0(expected_resolved) == name:
                    expected_struct_ty = expected_resolved
                else if expected_tk == TypeKind.TY_GENERIC_INST and self.get_type_d0(expected_resolved) == name:
                    expected_struct_ty = expected_resolved
            if expected_struct_ty == 0 and self.type_decl_nodes.contains(name):
                let td_node = self.type_decl_nodes.get(name).unwrap()
                if self.type_decl_tp_count(td_node) == 0:
                    expected_struct_ty = resolved
            // Check field initializers and collect value types
            let val_types: Vec[i32] = Vec.new()
            for fi in 0..field_count:
                let f_name = self.ast.get_extra(extra_start + fi * 2)
                let f_value = self.ast.get_extra(extra_start + fi * 2 + 1)
                var field_expected = 0
                if expected_struct_ty != 0:
                    if f_name == 0:
                        let info = self.struct_field_info_by_index(expected_struct_ty as i32, fi)
                        field_expected = (info / 4294967296) as i32
                    else:
                        field_expected = self.struct_field_type(expected_struct_ty as i32, f_name)
                let val_ty = if field_expected != 0: self.check_expr_with_expected(f_value, field_expected as TypeId) else: self.check_expr(f_value)
                val_types.push(val_ty as i32)
            // Check if struct has type params — infer GenericInst
            if self.type_decl_nodes.contains(name):
                let td_node = self.type_decl_nodes.get(name).unwrap()
                let td_extra = self.ast.get_data1(td_node)
                let td_packed = self.ast.get_data2(td_node)
                if type_decl_sub_kind(td_packed) == TypeDeclKind.Struct:
                    let fc = self.ast.get_extra(td_extra)
                    let after = td_extra + 1 + fc * 4
                    let tp_start = self.ast.get_extra(after + 1)
                    let tp_count = self.ast.get_extra(after + 2)
                    if tp_count > 0:
                        // Infer type args from field values
                        var ga0 = 0
                        var ga1 = 0
                        var ga2 = 0
                        var ga3 = 0
                        var inferred = 0
                        var tp_pos = tp_start
                        for ti in 0..tp_count:
                            let tp_name = self.ast.get_extra(tp_pos)
                            let bc = self.ast.get_extra(tp_pos + 1)
                            // Find a field whose type is this param
                            let positional = if field_count > 0: self.ast.get_extra(extra_start) == 0 else: false
                            for fi in 0..fc:
                                let base = td_extra + 1 + fi * 3
                                let f_name_sym = self.ast.get_extra(base)
                                let f_type_node = self.ast.get_extra(base + 1)
                                if self.ast.kind(f_type_node) == NodeKind.NK_TYPE_NAMED:
                                    if self.ast.get_data0(f_type_node) == tp_name:
                                        if positional:
                                            if fi < field_count:
                                                let vt = val_types.get(fi as i64)
                                                if vt > 0:
                                                    if ti == 0: ga0 = vt
                                                    if ti == 1: ga1 = vt
                                                    if ti == 2: ga2 = vt
                                                    if ti == 3: ga3 = vt
                                                    inferred = inferred + 1
                                                break
                                        else:
                                            for li in 0..field_count:
                                                let lit_f = self.ast.get_extra(extra_start + li * 2)
                                                if lit_f == f_name_sym:
                                                    let vt = val_types.get(li as i64)
                                                    if vt > 0:
                                                        if ti == 0: ga0 = vt
                                                        if ti == 1: ga1 = vt
                                                        if ti == 2: ga2 = vt
                                                        if ti == 3: ga3 = vt
                                                        inferred = inferred + 1
                                                    break
                                            break
                            tp_pos = tp_pos + 2 + bc
                        if inferred == tp_count:
                            let gi_args: Vec[i32] = Vec.new()
                            if tp_count > 0: gi_args.push(ga0)
                            if tp_count > 1: gi_args.push(ga1)
                            if tp_count > 2: gi_args.push(ga2)
                            if tp_count > 3: gi_args.push(ga3)
                            let gi = self.ensure_generic_inst_type(name, gi_args, tp_count)
                            self.typed_expr_types.insert(node, gi as i32)
                            return gi as i32
            if expected_struct_ty != 0:
                self.typed_expr_types.insert(node, expected_struct_ty as i32)
                return expected_struct_ty as i32
            self.typed_expr_types.insert(node, resolved as i32)
            return resolved as i32
    0

fn Sema.check_match_expr(self: Sema, node: i32) -> i32:
    let subject = self.ast.get_data0(node)
    let extra_start = self.ast.get_data1(node)
    let arm_count = self.ast.get_data2(node)

    let subject_type = self.check_expr(subject)
    var result_type: TypeId = 0 as TypeId
    let match_expected: TypeId = if self.has_expected_type != 0: self.expected_expr_type else: 0 as TypeId

    for ai in 0..arm_count:
        let arm_node = self.ast.get_extra(extra_start + ai)
        let pat = self.ast.get_data0(arm_node)
        let arm_body = self.ast.get_data1(arm_node)
        let guard = self.ast.get_data2(arm_node)

        self.push_scope()
        self.check_pattern(pat, subject_type as i32)
        if self.ast.kind(pat) == NodeKind.NK_PAT_REGEX:
            self.regex_bind_capture_scope(pat)
        if guard != 0:
            let saved_drop_cf_guard = self.drop_control_flow_depth
            if self.current_drop_type_sym != 0:
                self.drop_control_flow_depth = self.drop_control_flow_depth + 1
            self.check_expr(guard)
            self.drop_control_flow_depth = saved_drop_cf_guard
        let arm_expected: TypeId = if result_type != 0: result_type else: match_expected
        let saved_drop_cf_arm = self.drop_control_flow_depth
        if self.current_drop_type_sym != 0:
            self.drop_control_flow_depth = self.drop_control_flow_depth + 1
        let arm_type = if arm_expected != 0: self.check_expr_with_expected(arm_body, arm_expected) else: self.check_expr(arm_body)
        self.drop_control_flow_depth = saved_drop_cf_arm
        self.pop_scope()

        if result_type == 0:
            result_type = arm_type
        else if result_type == self.ty_never and arm_type != 0:
            // Bottom-type merge: allow concrete arm types after Never arms.
            result_type = arm_type
        else if arm_type != 0 and self.types_compatible(result_type, arm_type) != 0:
            result_type = self.preferred_compatible_type(result_type, arm_type)

    // Exhaustiveness checking for enum and bool subjects.
    // Expression-position match always requires exhaustiveness.
    // Statement-position match allows partial match (unmatched variants are no-op),
    // UNLESS the subject type is @[must_use] (Result, Task).
    var require_exhaustive = 0
    if self.match_in_stmt_pos == 0:
        require_exhaustive = 1
    else:
        // Must-use types require exhaustive match even in statement position
        let type_sym = self.get_type_d0(self.resolve_alias(subject_type))
        if type_sym != 0 and self.must_use_types.contains(type_sym):
            require_exhaustive = 1
    self.check_match_exhaustiveness(node, subject_type as i32, extra_start, arm_count, require_exhaustive)

    if result_type != 0:
        self.typed_expr_types.insert(node, result_type as i32)
    result_type as i32

fn Sema.check_match_exhaustiveness(self: Sema, node: i32, subject_type: i32, extra_start: i32, arm_count: i32, require_exhaustive: i32):
    if subject_type == 0:
        return
    let resolved = self.resolve_alias(subject_type)
    let tk = self.get_type_kind(resolved)

    // Check if any arm is a catch-all (wildcard or binding pattern without guard)
    var has_catchall = 0
    for ai in 0..arm_count:
        let arm_node = self.ast.get_extra(extra_start + ai)
        let pat = self.ast.get_data0(arm_node)
        let guard = self.ast.get_data2(arm_node)
        if guard != 0:
            continue
        if sema_pattern_is_catchall(self.ast, pat):
            has_catchall = 1
            break
    if has_catchall != 0:
        return

    // Bool exhaustiveness
    if tk == TypeKind.TY_BOOL:
        if require_exhaustive == 0:
            return
        var has_true = 0
        var has_false = 0
        for ai in 0..arm_count:
            let arm_node = self.ast.get_extra(extra_start + ai)
            let pat = self.ast.get_data0(arm_node)
            let guard = self.ast.get_data2(arm_node)
            if guard != 0:
                continue
            let pk = self.ast.kind(pat)
            if pk == NodeKind.NK_PAT_BOOL:
                let v = self.ast.get_data0(pat)
                if v != 0:
                    has_true = 1
                else:
                    has_false = 1
        if has_true == 0 or has_false == 0:
            self.emit_warning("non-exhaustive match on bool", node)
        return

    // Sealed trait object exhaustiveness
    if tk == TypeKind.TY_TRAIT_OBJ:
        let trait_sym = self.get_type_d0(resolved)
        if self.sealed_traits.contains(trait_sym) and self.sealed_impl_counts.contains(trait_sym):
            let si_count = self.sealed_impl_counts.get(trait_sym).unwrap()
            let si_start = self.sealed_impl_starts.get(trait_sym).unwrap()
            // Check that each implementor is covered by an arm
            for si in 0..si_count:
                let impl_sym = self.sealed_impl_types.get((si_start + si) as i64)
                var covered = 0
                for ai in 0..arm_count:
                    let arm_node = self.ast.get_extra(extra_start + ai)
                    let pat = self.ast.get_data0(arm_node)
                    let guard = self.ast.get_data2(arm_node)
                    if guard != 0:
                        continue
                    if sema_pattern_covers_variant(self.ast, pat, impl_sym):
                        covered = 1
                        break
                if covered == 0:
                    let impl_name = self.pool_resolve(impl_sym)
                    self.emit_error("non-exhaustive match on sealed trait: missing implementor '" ++ impl_name ++ "'", node)
                    return
        return

    // Enum exhaustiveness
    if tk != TypeKind.TY_ENUM:
        return
    if require_exhaustive == 0:
        return
    let te_start = self.get_type_d1(resolved)
    let variant_count = self.get_type_d2(resolved)
    // Collect all variant name syms
    var pos = te_start
    for vi in 0..variant_count:
        let v_name_sym = self.type_extra.get(pos as i64)
        let pc = self.type_extra.get((pos + 1) as i64)
        // Check if this variant is covered by any arm
        var covered = 0
        for ai in 0..arm_count:
            let arm_node = self.ast.get_extra(extra_start + ai)
            let pat = self.ast.get_data0(arm_node)
            let guard = self.ast.get_data2(arm_node)
            if guard != 0:
                continue
            if sema_pattern_covers_variant(self.ast, pat, v_name_sym):
                covered = 1
                break
        if covered == 0:
            self.emit_warning("non-exhaustive match: missing variant", node)
            return
        pos = pos + 2 + pc

fn sema_pattern_is_catchall(ast: AstPool, pat: i32) -> bool:
    if pat == 0:
        return true
    let kind = ast.kind(pat)
    if kind == NodeKind.NK_PAT_WILDCARD:
        return true
    if kind == NodeKind.NK_PAT_IDENT:
        return true
    false

fn sema_pattern_covers_variant(ast: AstPool, pat: i32, variant_sym: i32) -> bool:
    if pat == 0:
        return false
    let kind = ast.kind(pat)
    if kind == NodeKind.NK_PAT_WILDCARD or kind == NodeKind.NK_PAT_IDENT:
        return true
    if kind == NodeKind.NK_PAT_VARIANT or kind == NodeKind.NK_PAT_ENUM_SHORTHAND:
        return ast.get_data0(pat) == variant_sym
    if kind == NodeKind.NK_PAT_TYPED_BIND:
        return ast.get_data1(pat) == variant_sym
    if kind == NodeKind.NK_PAT_OR:
        let or_start = ast.get_data0(pat)
        let or_count = ast.get_data1(pat)
        for oi in 0..or_count:
            let inner = ast.get_extra(or_start + oi)
            if sema_pattern_covers_variant(ast, inner, variant_sym):
                return true
    false

fn Sema.generic_type_param_index(self: Sema, tp_start: i32, tp_count: i32, param_sym: i32) -> i32:
    var tp_pos = tp_start
    for ti in 0..tp_count:
        if self.ast.get_extra(tp_pos) == param_sym:
            return ti
        let bound_count = self.ast.get_extra(tp_pos + 1)
        tp_pos = tp_pos + 2 + bound_count
    -1

// Infer a concrete generic enum type for direct variant constructor calls like
// Some(7) when the payload directly names the enum's type parameter.
fn Sema.infer_generic_enum_variant_type(self: Sema, variant_sym: i32, arg_types: Vec[i32], arg_count: i32) -> i32:
    if not self.variant_type_ids.contains(variant_sym):
        return 0
    let enum_tid = self.resolve_alias(self.variant_type_ids.get(variant_sym).unwrap() as TypeId) as i32
    if self.get_type_kind(enum_tid) != TypeKind.TY_ENUM:
        return 0
    let base_sym = self.get_type_d0(enum_tid)
    if base_sym == 0 or not self.type_decl_nodes.contains(base_sym):
        return 0
    let td_node = self.type_decl_nodes.get(base_sym).unwrap()
    let tp_count = self.type_decl_tp_count(td_node)
    if tp_count <= 0:
        return 0
    let tp_start = self.type_decl_tp_start(td_node)
    if tp_start <= 0:
        return 0

    let extra_start = self.ast.get_data1(td_node)
    let td_packed = self.ast.get_data2(td_node)
    if type_decl_sub_kind(td_packed) != TypeDeclKind.Enum:
        return 0

    let inferred_args: Vec[i32] = Vec.new()
    for _ in 0..tp_count:
        inferred_args.push(0)

    let variant_count = self.ast.get_extra(extra_start)
    var pos = extra_start + 1
    for _ in 0..variant_count:
        let name_sym = self.ast.get_extra(pos)
        pos = pos + 1
        let payload_count = self.ast.get_extra(pos)
        pos = pos + 1
        if name_sym == variant_sym:
            if payload_count != arg_count:
                return 0
            for ai in 0..payload_count:
                let payload_type_node = self.ast.get_extra(pos + ai)
                if payload_type_node == 0:
                    continue
                if self.ast.kind(payload_type_node) != NodeKind.NK_TYPE_NAMED:
                    continue
                let payload_sym = self.ast.get_data0(payload_type_node)
                let param_index = self.generic_type_param_index(tp_start, tp_count, payload_sym)
                if param_index < 0:
                    continue
                let actual_ty = arg_types.get(ai as i64)
                if actual_ty == 0:
                    continue
                let existing = inferred_args.get(param_index as i64)
                if existing != 0 and self.types_compatible(existing as TypeId, actual_ty as TypeId) == 0:
                    return 0
                let preferred = self.preferred_compatible_type(existing as TypeId, actual_ty as TypeId)
                inferred_args.set_i32(param_index as i64, preferred as i32)
            for ai in 0..tp_count:
                if inferred_args.get(ai as i64) == 0:
                    return 0
            return self.ensure_generic_inst_type(base_sym, inferred_args, tp_count) as i32
        pos = pos + payload_count
    0

// Resolve payload types for a variant of a generic enum (e.g., Option[i32].Some → [i32]).
// Walks the AST type declaration with type param substitution active.
fn Sema.resolve_generic_enum_payload(self: Sema, gi_tid: i32, base_sym: i32, variant_name: i32, expected_count: i32) -> Vec[i32]:
    var result: Vec[i32] = Vec.new()
    if not self.type_decl_nodes.contains(base_sym):
        return result
    if self.setup_generic_inst_substitution(gi_tid, base_sym) == 0:
        return result
    // Walk AST type decl to find variant and re-resolve payload type nodes
    let td_node = self.type_decl_nodes.get(base_sym).unwrap()
    let td_extra_start = self.ast.get_data1(td_node)
    let td_packed = self.ast.get_data2(td_node)
    let td_sub_kind = type_decl_sub_kind(td_packed)
    if td_sub_kind != TypeDeclKind.Enum:
        return result
    // Get type param info for resolve_generic_return_type_node
    let vc = self.ast.get_extra(td_extra_start)
    var tp_epos = td_extra_start + 1
    for tvi in 0..vc:
        tp_epos = tp_epos + 1
        let tpc = self.ast.get_extra(tp_epos)
        tp_epos = tp_epos + 1
        tp_epos = tp_epos + tpc
    let tp_start = self.ast.get_extra(tp_epos + 1)
    let tp_count = self.ast.get_extra(tp_epos + 2)
    // Now walk variants again to find the matching one
    var epos = td_extra_start + 1
    for vi in 0..vc:
        let v_name = self.ast.get_extra(epos)
        epos = epos + 1
        let pc = self.ast.get_extra(epos)
        epos = epos + 1
        if v_name == variant_name:
            for pi in 0..pc:
                let pt_node = self.ast.get_extra(epos + pi)
                let pt_tid = self.resolve_generic_return_type_node(pt_node, tp_start, tp_count)
                result.push(pt_tid)
            return result
        epos = epos + pc
    result

fn Sema.enum_variant_payload_types(self: Sema, enum_tid: i32, variant_name: i32) -> Vec[i32]:
    var result: Vec[i32] = Vec.new()
    let resolved = self.resolve_alias(enum_tid)
    let kind = self.get_type_kind(resolved)
    if kind == TypeKind.TY_ENUM:
        let te_start = self.get_type_d1(resolved)
        let variant_count = self.get_type_d2(resolved)
        var pos = te_start
        for vi in 0..variant_count:
            let name_sym = self.type_extra.get(pos as i64)
            let payload_count = self.type_extra.get((pos + 1) as i64)
            if name_sym == variant_name:
                for pi in 0..payload_count:
                    result.push(self.type_extra.get((pos + 2 + pi) as i64))
                return result
            pos = pos + 2 + payload_count
        return result
    if kind == TypeKind.TY_GENERIC_INST:
        let base_sym = self.get_generic_inst_base(resolved)
        let base_tid = self.lookup_named_type_visible(base_sym)
        if base_tid == 0:
            return result
        if self.get_type_kind(base_tid) != TypeKind.TY_ENUM:
            return result
        let te_start = self.get_type_d1(base_tid)
        let variant_count = self.get_type_d2(base_tid)
        var pos = te_start
        for vi in 0..variant_count:
            let name_sym = self.type_extra.get(pos as i64)
            let payload_count = self.type_extra.get((pos + 1) as i64)
            if name_sym == variant_name:
                let generic_payloads = self.resolve_generic_enum_payload(resolved, base_sym, variant_name, payload_count)
                if generic_payloads.len() as i32 > 0:
                    return generic_payloads
                for pi in 0..payload_count:
                    result.push(self.type_extra.get((pos + 2 + pi) as i64))
                return result
            pos = pos + 2 + payload_count
    result

fn sema_accessor_char_lower(ch: i32) -> str:
    if ch >= 65 and ch <= 90:
        return str_from_byte(ch + 32)
    str_from_byte(ch)

fn sema_accessor_snake_name(name: str) -> str:
    var result = ""
    var prev_lower = false
    var prev_upper = false
    var i = 0
    while i < name.len() as i32:
        let ch = name.byte_at(i as i64)
        let is_upper = ch >= 65 and ch <= 90
        let is_lower = ch >= 97 and ch <= 122
        let is_digit = ch >= 48 and ch <= 57
        if is_upper:
            if prev_lower:
                result = result ++ "_"
            else if prev_upper and i > 1 and i + 1 < name.len() as i32:
                let next = name.byte_at((i + 1) as i64)
                if next >= 97 and next <= 122 and result.len() > 0:
                    result = result ++ "_"
            result = result ++ sema_accessor_char_lower(ch)
            prev_upper = true
            prev_lower = false
        else if is_lower:
            result = result ++ name.slice(i as i64, (i + 1) as i64)
            prev_upper = false
            prev_lower = true
        else if is_digit:
            result = result ++ name.slice(i as i64, (i + 1) as i64)
            prev_upper = false
            prev_lower = false
        else if ch == 95:
            if result.len() > 0:
                result = result ++ "_"
            prev_upper = false
            prev_lower = false
        else:
            result = result ++ name.slice(i as i64, (i + 1) as i64)
            prev_upper = false
            prev_lower = false
        i = i + 1
    result

fn Sema.enum_variant_decl_type(self: Sema, enum_tid: i32) -> i32:
    if enum_tid == 0:
        return 0
    let resolved = self.resolve_alias(enum_tid)
    let kind = self.get_type_kind(resolved)
    if kind == TypeKind.TY_ENUM:
        return resolved as i32
    if kind == TypeKind.TY_GENERIC_INST:
        let base_sym = self.get_generic_inst_base(resolved as i32)
        let base_tid = self.lookup_named_type_visible(base_sym)
        if base_tid != 0 and self.get_type_kind(self.resolve_alias(base_tid as TypeId)) == TypeKind.TY_ENUM:
            return self.resolve_alias(base_tid as TypeId) as i32
    0

fn Sema.enum_accessor_variant_for_method(self: Sema, enum_tid: i32, method_sym: i32) -> i32:
    let enum_decl = self.enum_variant_decl_type(enum_tid)
    if enum_decl == 0:
        return 0
    let method_name = self.pool_resolve(method_sym)
    let te_start = self.get_type_d1(enum_decl)
    let variant_count = self.get_type_d2(enum_decl)
    var pos = te_start
    for _ in 0..variant_count:
        let variant_sym = self.type_extra.get(pos as i64)
        let payload_count = self.type_extra.get((pos + 1) as i64)
        let snake = sema_accessor_snake_name(self.pool_resolve(variant_sym))
        if method_name == "is_" ++ snake:
            return variant_sym
        if method_name == "as_" ++ snake:
            return variant_sym
        if method_name == "as_" ++ snake ++ "_ref":
            return variant_sym
        if method_name == "as_" ++ snake ++ "_mut":
            return variant_sym
        pos = pos + 2 + payload_count
    0

// 1 = is_variant, 2 = as_variant by value, 3 = as_variant_ref by shared ref,
// 4 = as_variant_mut by exclusive ref.
fn Sema.enum_accessor_kind_for_method(self: Sema, enum_tid: i32, method_sym: i32) -> i32:
    let variant_sym = self.enum_accessor_variant_for_method(enum_tid, method_sym)
    if variant_sym == 0:
        return 0
    let method_name = self.pool_resolve(method_sym)
    let snake = sema_accessor_snake_name(self.pool_resolve(variant_sym))
    if method_name == "is_" ++ snake:
        return 1
    if method_name == "as_" ++ snake:
        return 2
    if method_name == "as_" ++ snake ++ "_ref":
        return 3
    if method_name == "as_" ++ snake ++ "_mut":
        return 4
    0

fn Sema.enum_variant_index_for_type(self: Sema, enum_tid: i32, variant_sym: i32) -> i32:
    let enum_decl = self.enum_variant_decl_type(enum_tid)
    if enum_decl == 0 or variant_sym == 0:
        return -1
    let te_start = self.get_type_d1(enum_decl)
    let variant_count = self.get_type_d2(enum_decl)
    var pos = te_start
    for vi in 0..variant_count:
        let cur_sym = self.type_extra.get(pos as i64)
        let payload_count = self.type_extra.get((pos + 1) as i64)
        if cur_sym == variant_sym:
            return vi
        pos = pos + 2 + payload_count
    -1

fn Sema.enum_variant_discriminant_for_type(self: Sema, enum_tid: i32, variant_sym: i32) -> i32:
    let enum_decl = self.enum_variant_decl_type(enum_tid)
    if enum_decl == 0:
        return -1
    let index = self.enum_variant_index_for_type(enum_decl, variant_sym)
    if index < 0:
        return -1
    let qualified = self.qualified_enum_variant_sym(enum_decl, variant_sym)
    if self.disc_values.contains(qualified):
        return self.disc_values.get(qualified).unwrap()
    if self.disc_values.contains(variant_sym):
        return self.disc_values.get(variant_sym).unwrap()
    index

fn Sema.enum_accessor_return_type(self: Sema, enum_tid: i32, variant_sym: i32, accessor_kind: i32) -> i32:
    if accessor_kind == 1:
        return self.ty_bool as i32
    let payloads = self.enum_variant_payload_types(enum_tid, variant_sym)
    let payload_count = payloads.len() as i32
    if payload_count <= 0:
        return 0
    let elem_tys: Vec[i32] = Vec.new()
    for pi in 0..payload_count:
        var elem_ty = payloads.get(pi as i64)
        if accessor_kind == 3:
            elem_ty = self.ensure_exact_type(TypeKind.TY_REF, elem_ty, 0, 0) as i32
        else if accessor_kind == 4:
            elem_ty = self.ensure_exact_type(TypeKind.TY_REF, elem_ty, 1, 0) as i32
        elem_tys.push(elem_ty)
    let payload_ty = if payload_count == 1:
        elem_tys.get(0)
    else:
        self.ensure_tuple_type(elem_tys, payload_count) as i32
    let opt_args: Vec[i32] = Vec.new()
    opt_args.push(payload_ty)
    self.ensure_generic_inst_type(self.syms.option, opt_args, 1) as i32

fn Sema.expected_variant_constructor_type(self: Sema, variant_name: i32) -> i32:
    if self.has_expected_type == 0 or self.expected_expr_type == 0:
        return 0
    let expected = self.resolve_alias(self.expected_expr_type)
    let exp_kind = self.get_type_kind(expected)
    if exp_kind == TypeKind.TY_ENUM:
        if self.enum_has_variant(expected as i32, variant_name) != 0:
            return expected as i32
        return 0
    if exp_kind == TypeKind.TY_GENERIC_INST:
        let gi_base = self.get_type_d0(expected)
        let base_tid = self.lookup_named_type_visible(gi_base)
        if base_tid != 0:
            if self.get_type_kind(base_tid as TypeId) == TypeKind.TY_ENUM:
                if self.enum_has_variant(base_tid, variant_name) != 0:
                    return expected as i32
    0

fn Sema.qualified_enum_variant_sym(self: Sema, enum_tid: i32, variant_name: i32) -> i32:
    if enum_tid == 0 or variant_name == 0:
        return variant_name
    let owner_sym = self.enum_pattern_owner_sym(enum_tid)
    if owner_sym == 0:
        return variant_name
    let qual_name = self.pool_resolve(owner_sym) ++ "." ++ self.pool_resolve(variant_name)
    let qual_sym = self.pool_intern(qual_name)
    if self.variant_lookup.contains(qual_sym):
        return qual_sym
    variant_name

fn Sema.check_pattern(self: Sema, node: i32, subject_type: i32):
    if node == 0:
        return

    let kind = self.ast.kind(node)

    if kind == NodeKind.NK_PAT_WILDCARD:
        return

    if kind == NodeKind.NK_PAT_IDENT:
        let sym = self.ast.get_data0(node)
        self.scope_put(sym, subject_type, 0)
        return

    if kind == NodeKind.NK_PAT_INT or kind == NodeKind.NK_PAT_BOOL or kind == NodeKind.NK_PAT_STRING:
        return

    if kind == NodeKind.NK_PAT_REGEX:
        if subject_type != 0 and self.types_compatible(self.ty_str as i32, subject_type) == 0:
            self.emit_error("regex pattern requires a str-compatible match subject", node)
        let regex_ty = self.lookup_named_type_visible(self.syms.regex)
        if regex_ty != 0:
            let _ = self.ensure_exact_type(TypeKind.TY_REF, regex_ty, 0, 0)
        self.validate_regex_literal(node)
        return

    if kind == NodeKind.NK_PAT_TYPED_BIND:
        let bind_sym = self.ast.get_data0(node)
        let type_sym = self.ast.get_data1(node)
        var concrete_type = 0
        concrete_type = self.lookup_named_type_visible(type_sym)
        if concrete_type != 0:
            self.scope_put(bind_sym, concrete_type, 0)
        else:
            self.scope_put(bind_sym, subject_type, 0)
        return

    if kind == NodeKind.NK_PAT_VARIANT or kind == NodeKind.NK_PAT_ENUM_SHORTHAND:
        var v_name = self.ast.get_data0(node)
        let bind_count = self.ast.get_data2(node)
        let subject_enum_ty = self.enum_pattern_type(subject_type)
        // Resolve for-comprehension markers: _Payload → Some/Ok, _Empty → None/Err
        let v_name_str = self.pool_resolve(v_name)
        if v_name_str == "_Payload" or v_name_str == "_Empty":
            let resolved_st = self.resolve_alias(subject_type)
            let is_payload = v_name_str == "_Payload"
            let try_sym = if is_payload: self.syms.some else: self.syms.none
            if self.enum_has_variant(resolved_st as i32, try_sym) != 0:
                v_name = try_sym
            else:
                let try_sym2 = if is_payload: self.syms.ok else: self.syms.err
                if self.enum_has_variant(resolved_st as i32, try_sym2) != 0:
                    v_name = try_sym2
            self.comp_resolved.insert(node, v_name)
        if kind == NodeKind.NK_PAT_VARIANT and bind_count == 0 and subject_enum_ty == 0 and self.ast.pattern_qualifier(node) == 0:
            let value_sym = self.pattern_variant_value_sym(node, v_name)
            if self.try_mark_value_pattern(node, subject_type, value_sym) != 0:
                return
        let pattern_enum_ty = self.resolve_variant_pattern_enum_type(node, subject_type, v_name)
        if pattern_enum_ty == 0:
            return
        let resolved_variant_sym = self.qualified_enum_variant_sym(pattern_enum_ty, v_name)
        self.comp_resolved.insert(node, resolved_variant_sym)
        let v_extra = self.ast.get_data1(node)
        if subject_enum_ty == 0:
            if bind_count != 0:
                self.emit_error("variant payload pattern requires an enum subject", node)
                return
            self.pattern_value_syms.insert(node, resolved_variant_sym)
            return
        var payload_start = 0
        var payload_count = 0
        var found_variant = 0
        let resolved = self.resolve_alias(pattern_enum_ty)
        let resolved_kind = self.get_type_kind(resolved)
        if resolved_kind == TypeKind.TY_ENUM:
            let te_start = self.get_type_d1(resolved)
            let variant_count = self.get_type_d2(resolved)
            var pos = te_start
            for vi in 0..variant_count:
                let name_sym = self.type_extra.get(pos as i64)
                let pc = self.type_extra.get((pos + 1) as i64)
                if name_sym == v_name:
                    found_variant = 1
                    payload_start = pos + 2
                    payload_count = pc
                    break
                pos = pos + 2 + pc
        else if resolved_kind == TypeKind.TY_GENERIC_INST:
            let gi_base = self.get_generic_inst_base(resolved)
            let base_tid = self.lookup_named_type_visible(gi_base)
            if base_tid != 0:
                if self.get_type_kind(base_tid) == TypeKind.TY_ENUM:
                    let te_start = self.get_type_d1(base_tid)
                    let variant_count = self.get_type_d2(base_tid)
                    var pos = te_start
                    for vi in 0..variant_count:
                        let name_sym = self.type_extra.get(pos as i64)
                        let pc = self.type_extra.get((pos + 1) as i64)
                        if name_sym == v_name:
                            found_variant = 1
                            payload_start = pos + 2
                            payload_count = pc
                            break
                        pos = pos + 2 + pc
        if found_variant == 0:
            return
        // Recursively check each payload pattern (extra stores pattern nodes).
        // For TypeKind.TY_GENERIC_INST, re-resolve payload types from AST with substitution.
        var gi_payload_types: Vec[i32] = Vec.new()
        if resolved_kind == TypeKind.TY_GENERIC_INST and payload_count > 0:
            let gi_base = self.get_generic_inst_base(resolved)
            gi_payload_types = self.resolve_generic_enum_payload(resolved, gi_base, v_name, payload_count)
        var unit_elided_payload_pattern = 0
        if bind_count == 0 and payload_count == 1:
            var only_payload_ty = self.type_extra.get(payload_start as i64)
            if gi_payload_types.len() as i32 > 0 and gi_payload_types.get(0) != 0:
                only_payload_ty = gi_payload_types.get(0)
            if self.type_is_unit(only_payload_ty) != 0:
                unit_elided_payload_pattern = 1
        if unit_elided_payload_pattern == 0 and bind_count != payload_count:
            let v_text = self.pool_resolve(v_name)
            self.emit_error(f"variant pattern '{v_text}' expects {payload_count} payload pattern(s), found {bind_count}", node)
            return
        for bi in 0..bind_count:
            let inner_pat = self.ast.get_extra(v_extra + bi)
            var inner_ty = if bi < payload_count: self.type_extra.get((payload_start + bi) as i64) else: 0
            if bi < gi_payload_types.len() as i32:
                let gi_ty = gi_payload_types.get(bi as i64)
                if gi_ty != 0:
                    inner_ty = gi_ty
            self.check_pattern(inner_pat, inner_ty)
        return

    if kind == NodeKind.NK_PAT_OR:
        let p_extra = self.ast.get_data0(node)
        let p_count = self.ast.get_data1(node)
        for pi in 0..p_count:
            self.check_pattern(self.ast.get_extra(p_extra + pi), subject_type)
        return

    if kind == NodeKind.NK_PAT_AT_BINDING:
        let at_name = self.ast.get_data0(node)
        let inner = self.ast.get_data1(node)
        self.scope_put(at_name, subject_type, 0)
        self.check_pattern(inner, subject_type)
        return

    if kind == NodeKind.NK_PAT_TUPLE:
        let t_extra = self.ast.get_data0(node)
        let t_count = self.ast.get_data1(node)
        if subject_type == 0:
            return
        let resolved = self.resolve_alias(subject_type)
        let resolved_kind = self.get_type_kind(resolved)
        if resolved_kind == TypeKind.TY_ERR:
            return
        if resolved_kind != TypeKind.TY_TUPLE:
            self.emit_error("tuple pattern requires tuple subject", node)
            return
        let elem_start = self.get_type_d0(resolved)
        let elem_count = self.get_type_d1(resolved)
        if t_count != elem_count:
            self.emit_error("tuple pattern arity mismatch", node)
            return
        for ti in 0..t_count:
            let elem_ty = self.type_extra.get((elem_start + ti) as i64)
            self.check_pattern(self.ast.get_extra(t_extra + ti), elem_ty)
        return

    if kind == NodeKind.NK_PAT_SLICE:
        let s_extra = self.ast.get_data0(node)
        let head_count = self.ast.get_data1(node)
        let rest_sym = self.ast.get_data2(node)
        var elem_type = 0
        let resolved = self.resolve_alias(subject_type)
        let stk = self.get_type_kind(resolved)
        if stk == TypeKind.TY_ARRAY:
            elem_type = self.get_type_d0(resolved)
        if stk == TypeKind.TY_SLICE:
            elem_type = self.get_type_d0(resolved)
        let has_rest = self.ast.get_extra(s_extra)
        for hi in 0..head_count:
            let h_sym = self.ast.get_extra(s_extra + 1 + hi)
            if h_sym != 0:
                self.scope_put(h_sym, elem_type, 0)
        if has_rest != 0 and rest_sym != 0:
            self.scope_put(rest_sym, self.ty_i64, 0)
        let tail_count = self.ast.get_extra(s_extra + 1 + head_count)
        for ti in 0..tail_count:
            let t_sym = self.ast.get_extra(s_extra + 2 + head_count + ti)
            if t_sym != 0:
                self.scope_put(t_sym, elem_type, 0)
        return

    if kind == NodeKind.NK_PAT_STRUCT:
        let sp_extra = self.ast.get_data1(node)
        let sp_count = self.ast.get_data2(node)
        let has_rest = self.ast.get_extra(sp_extra)
        var field_start = 0
        var field_count = 0
        let resolved = self.resolve_alias(subject_type)
        if self.get_type_kind(resolved) == TypeKind.TY_STRUCT:
            field_start = self.get_type_d1(resolved)
            field_count = self.get_type_d2(resolved)
        for spi in 0..sp_count:
            let f_name = self.ast.get_extra(sp_extra + 1 + spi * 2)
            let f_pat = self.ast.get_extra(sp_extra + 1 + spi * 2 + 1)
            var field_ty = 0
            for fi in 0..field_count:
                let name_sym = self.type_extra.get((field_start + fi * 3) as i64)
                if name_sym == f_name:
                    field_ty = self.type_extra.get((field_start + fi * 3 + 1) as i64)
                    break
            if f_pat != 0:
                self.check_pattern(f_pat, field_ty)
            else:
                self.scope_put(f_name, field_ty, 0)
        return

fn Sema.check_enum_variant(self: Sema, node: i32) -> i32:
    let type_name = self.ast.get_data0(node)
    let variant_name = self.ast.get_data1(node)
    let extra_start = self.ast.get_data2(node)
    let arg_count = self.ast.get_extra(extra_start)
    for ai in 0..arg_count:
        self.check_expr(self.ast.get_extra(extra_start + 1 + ai))
    let visible_tid = self.lookup_named_type_visible(type_name)
    if visible_tid != 0:
        return self.resolve_alias(visible_tid as TypeId) as i32
    0

fn Sema.check_closure(self: Sema, node: i32) -> i32:
    let body = self.ast.get_data0(node)
    let extra_start = self.ast.get_data1(node)
    let param_count = self.ast.get_data2(node)
    let outer_count = self.bind_names.len() as i32
    let saved_capture_sig_idx = self.current_fn_sig_idx
    let saved_capture_syms: Vec[i32] = Vec.new()
    let saved_capture_effs: Vec[i32] = Vec.new()
    let saved_capture_origins: Vec[i32] = Vec.new()
    for i in 0..self.current_fn_param_syms.len() as i32:
        saved_capture_syms.push(self.current_fn_param_syms.get(i as i64))
        saved_capture_effs.push(self.current_fn_param_effs.get(i as i64))
        saved_capture_origins.push(self.current_fn_param_origins.get(i as i64))
    while self.current_fn_param_syms.len() > 0:
        self.current_fn_param_syms.pop()
        self.current_fn_param_effs.pop()
        self.current_fn_param_origins.pop()
    let closure_capture_syms: Vec[i32] = Vec.new()
    for ci in 0..outer_count:
        let cap_sym = self.bind_names.get(ci as i64)
        if self.expr_uses_symbol(body, cap_sym) != 0:
            closure_capture_syms.push(cap_sym)
            self.current_fn_param_syms.push(cap_sym)
            self.current_fn_param_effs.push(0)
            self.current_fn_param_origins.push(0)
    self.current_fn_sig_idx = if closure_capture_syms.len() > 0: 0 else: saved_capture_sig_idx

    var expected_fn_tid = 0
    if self.has_expected_type != 0 and self.expected_expr_type != 0:
        expected_fn_tid = self.callable_fn_type(self.expected_expr_type)

    // `it` arity validation: if this is an implicit `it` closure (param_count==1,
    // param name is "__it") and the expected type is a fn with != 1 params, error.
    if param_count == 1 and expected_fn_tid != 0:
        let p_sym = self.ast.get_extra(extra_start)
        let p_name = self.pool_resolve(p_sym)
        if p_name == "__it":
            let expected_params = self.get_type_d1(expected_fn_tid)
            if expected_params != 1:
                self.emit_error(f"`it` used in context expecting {expected_params} parameter(s)", node)

    // Save borrow state — closure body borrows are local to the closure.
    let saved_borrow_len = self.borrow_kinds.len() as i32

    self.push_scope()
    let te_start = self.type_extra.len() as i32
    // Partial application: if body is NK_CALL, resolve callee param types for placeholders
    var partial_sig = -1
    if self.ast.kind(body) == NodeKind.NK_CALL:
        let call_callee = self.ast.get_data0(body)
        if self.ast.kind(call_callee) == NodeKind.NK_IDENT:
            let callee_sym = self.ast.get_data0(call_callee)
            partial_sig = self.get_sig(callee_sym)
    for pi in 0..param_count:
        let p_sym = self.ast.get_extra(extra_start + pi * 2)
        let p_type_node = self.ast.get_extra(extra_start + pi * 2 + 1)
        var p_ty = self.ty_i32 as i32
        if p_type_node > 0:
            let explicit_ty = self.resolve_type_expr(p_type_node)
            if explicit_ty != 0:
                p_ty = explicit_ty as i32
        else if expected_fn_tid != 0 and pi < self.get_type_d1(expected_fn_tid):
            let expected_param_ty = self.callable_fn_param_type(expected_fn_tid as TypeId, pi)
            if expected_param_ty != 0:
                p_ty = expected_param_ty
        // For partial app, find which call arg position this placeholder occupies.
        if p_type_node == 0 and expected_fn_tid == 0 and partial_sig >= 0 and self.ast.kind(body) == NodeKind.NK_CALL:
            let call_extra = self.ast.get_data1(body)
            let call_argc = self.ast.get_data2(body)
            for ai in 0..call_argc:
                let arg = self.ast.get_extra(call_extra + ai)
                if self.ast.kind(arg) == NodeKind.NK_IDENT:
                    if self.ast.get_data0(arg) == p_sym:
                        if ai < self.sig_get_param_count(partial_sig):
                            p_ty = self.sig_param_type(partial_sig, ai)
                        break
        self.scope_put(p_sym, p_ty, 0)
        self.type_extra.push(p_ty)
    let saved_label_registry = self.save_label_registry()
    self.reset_label_registry()
    self.collect_function_labels(body)
    self.validate_function_gotos()
    self.push_label_boundary()
    var expected_ret_ty = 0
    if expected_fn_tid != 0:
        expected_ret_ty = self.get_type_d2(expected_fn_tid)
    let body_ty = if expected_ret_ty != 0: self.check_expr_with_expected(body, expected_ret_ty as TypeId) else: self.check_expr(body)
    self.pop_label_frame()
    self.emit_unused_label_warnings()
    self.restore_label_registry(saved_label_registry)
    if body_ty != 0 and body_ty != self.ty_void and body_ty != self.ty_never:
        if self.is_copy(body_ty) == 0:
            self.note_place_effect(body, EFF_ESCAPE_VALUE)
        let body_kind = self.get_type_kind(self.resolve_alias(body_ty))
        if body_kind == TypeKind.TY_REF or body_kind == TypeKind.TY_PTR:
            self.note_place_effect(body, EFF_ESCAPE_VIEW)
            let body_root = self.place_root_sym(body)
            if body_root != 0:
                self.note_param_view_origin(body_root, self.compute_expr_view_origin_mask(body))

    self.pop_scope()

    let closure_capture_effs: Vec[i32] = Vec.new()
    for ci in 0..closure_capture_syms.len() as i32:
        closure_capture_effs.push(self.current_fn_param_effs.get(ci as i64))
    self.set_closure_capture_summary(node, closure_capture_syms, closure_capture_effs)
    while self.current_fn_param_syms.len() > 0:
        self.current_fn_param_syms.pop()
        self.current_fn_param_effs.pop()
        self.current_fn_param_origins.pop()
    for i in 0..saved_capture_syms.len() as i32:
        self.current_fn_param_syms.push(saved_capture_syms.get(i as i64))
        self.current_fn_param_effs.push(saved_capture_effs.get(i as i64))
        self.current_fn_param_origins.push(saved_capture_origins.get(i as i64))
    self.current_fn_sig_idx = saved_capture_sig_idx

    // Restore borrow state — discard borrows created inside closure body.
    while self.borrow_kinds.len() as i32 > saved_borrow_len:
        self.borrow_kinds.pop()
        self.borrow_places.pop()
        self.borrow_fields.pop()
        self.borrow_refs.pop()
        self.borrow_path_starts.pop()
        self.borrow_path_counts.pop()

    var direct_arg_escapes = 0
    if self.closure_direct_arg_escape_flags.len() > 0:
        direct_arg_escapes = self.closure_direct_arg_escape_flags.get((self.closure_direct_arg_escape_flags.len() - 1) as i64)

    // Mark non-escaping if this closure is a direct call argument whose
    // receiving parameter does not let the closure escape the call.
    let is_non_escaping = self.closure_direct_arg_depth > 0 and direct_arg_escapes == 0 and self.ast.is_move_closure(node) == 0
    if is_non_escaping:
        self.ast.mark_non_escaping_closure(node)
        // Register borrows for captured variables.
        // Non-escaping closures capture by reference — register as borrows
        // so the borrow checker can detect conflicts with other borrows.
        // If the variable is only accessed through field paths, register
        // field-level borrows for disjoint capture checking.
        var ci = 0
        while ci < outer_count:
            let cap_sym = self.bind_names.get(ci as i64)
            if self.expr_uses_symbol(body, cap_sym) != 0:
                if self.capture_is_field_only(body, cap_sym) != 0:
                    // Field-level capture: register borrow per field path
                    // Clear transient capture field storage
                    while self.capture_field_syms.len() > 0:
                        self.capture_field_syms.pop()
                        self.capture_field_kinds.pop()
                    self.collect_capture_fields(body, cap_sym)
                    var fi = 0
                    while fi < self.capture_field_syms.len() as i32:
                        let field_sym = self.capture_field_syms.get(fi as i64)
                        let bk = self.capture_field_kinds.get(fi as i64)
                        let path_start = self.borrow_path_data.len() as i32
                        self.borrow_path_data.push(field_sym)
                        self.check_borrow_create_direct(cap_sym, bk, field_sym, path_start, 1, node)
                        fi = fi + 1
                else:
                    // Whole-variable capture
                    let bk = if self.expr_mutates_place(body, cap_sym) != 0: BorrowKind.EXCLUSIVE else: BorrowKind.SHARED
                    let path_start = self.borrow_path_data.len() as i32
                    self.check_borrow_create_direct(cap_sym, bk, 0, path_start, 0, node)
            ci = ci + 1

    // Escaping closures (including move closures) consume non-Copy captures.
    // Mark captured non-Copy variables as moved so subsequent uses error.
    let is_escaping = not is_non_escaping
    if is_escaping:
        var ebi = 0
        while ebi < outer_count:
            let cap_sym = self.bind_names.get(ebi as i64)
            if self.expr_uses_symbol(body, cap_sym) != 0:
                let cap_ty = self.bind_types.get(ebi as i64)
                if self.type_is_ephemeral_value(cap_ty) != 0:
                    self.emit_error("escaping closure cannot capture ephemeral references", node)
                    break
            ebi = ebi + 1
        var emitted_capability_escape = 0
        for cci in 0..closure_capture_syms.len() as i32:
            let cap_sym2 = closure_capture_syms.get(cci as i64)
            let cap_ty2 = self.scope_lookup(cap_sym2)
            if emitted_capability_escape == 0 and self.is_tool_capability_type(cap_ty2):
                self.emit_error("capability-bearing closure cannot escape into runtime code", node)
                emitted_capability_escape = 1
        // docs/mut.md Rev 8 §9.4 / §15.9 — a mutating closure may not
        // escape the scope containing the captured place. If the closure
        // is in escape position (e.g., returned, stored in a long-lived
        // binding) AND mutates any capture, warn.
        var emitted_escape_warn = 0
        var ci = 0
        while ci < outer_count:
            let cap_sym = self.bind_names.get(ci as i64)
            if self.expr_uses_symbol(body, cap_sym) != 0:
                let cap_ty = self.bind_types.get(ci as i64)
                if self.is_copy(cap_ty as TypeId) == 0:
                    self.scope_set_state(cap_sym, VarState.MOVED)
                if emitted_escape_warn == 0 and self.ast.is_move_closure(node) == 0 and self.expr_mutates_place(body, cap_sym) != 0:
                    self.emit_error("closure that mutates captured place cannot escape its defining scope (§15.9)", node)
                    emitted_escape_warn = 1
            ci = ci + 1

    // Use callee return type for partial application closures
    var closure_ret_ty = if body_ty != 0: body_ty as i32 else: self.ty_i32 as i32
    if partial_sig >= 0:
        closure_ret_ty = self.sig_return_type(partial_sig)
    else if expected_ret_ty != 0:
        closure_ret_ty = expected_ret_ty
    let closure_ty = self.add_type(TypeKind.TY_FN, te_start, param_count, closure_ret_ty) as i32
    self.typed_expr_types.insert(node, closure_ty)
    closure_ty

fn Sema.check_pipeline(self: Sema, node: i32) -> i32:
    let lhs = self.ast.get_data0(node)
    let rhs = self.ast.get_data1(node)
    let lhs_ty = self.check_expr(lhs)
    if rhs != 0:
        if self.ast.kind(rhs) == NodeKind.NK_CALL:
            let rhs_callee = self.ast.get_data0(rhs)
            if self.ast.kind(rhs_callee) == NodeKind.NK_IDENT:
                let method = self.ast.get_data0(rhs_callee)
                if self.pipeline_method_exists(lhs_ty as i32, method) != 0:
                    let ret = self.check_method_call_parts(lhs, method, self.ast.get_data1(rhs), self.ast.get_data2(rhs), node)
                    if ret != 0:
                        self.pipeline_method_calls.insert(node, method)
                        self.typed_expr_types.insert(node, ret)
                    return ret
        else if self.ast.kind(rhs) == NodeKind.NK_IDENT:
            let method = self.ast.get_data0(rhs)
            if self.pipeline_method_exists(lhs_ty as i32, method) != 0:
                let ret2 = self.check_method_call_parts(lhs, method, -1, 0, node)
                if ret2 != 0:
                    self.pipeline_method_calls.insert(node, method)
                    self.typed_expr_types.insert(node, ret2)
                return ret2
    let saved = self.in_pipeline_rhs
    self.in_pipeline_rhs = 1
    let rhs_ty = self.check_expr(rhs)
    self.in_pipeline_rhs = saved
    if rhs_ty != 0:
        let resolved = self.resolve_alias(rhs_ty)
        if self.get_type_kind(resolved) == TypeKind.TY_FN:
            return self.get_type_d2(resolved)
    rhs_ty as i32

fn Sema.pipeline_generic_builtin_method_exists(self: Sema, owner_sym: i32, field: i32) -> i32:
    // Temporary bridge: builtin generic collection methods do not all flow
    // through lookup_method_sig on concrete generic instances yet, so pipeline
    // method resolution needs this explicit allowlist. Long term, generic
    // instance method lookup should use the same method table path as ordinary
    // methods and this stdlib-specific list should disappear.
    if owner_sym == self.syms.vec:
        if field == self.syms.push or field == self.syms.set_i32 or field == self.syms.clear:
            return 1
        if field == self.syms.get or field == self.syms.pop or field == self.syms.remove:
            return 1
        if field == self.syms.len or field == self.syms.contains or field == self.syms.join:
            return 1
        if field == self.syms.iter or field == self.syms.slot or field == self.syms.get_disjoint:
            return 1
        if field == self.syms.range_method or field == self.syms.iter_ref or field == self.syms.iter_place:
            return 1
        if field == self.syms.filter or field == self.syms.map or field == self.syms.fold:
            return 1
    if owner_sym == self.syms.hashmap:
        if field == self.syms.insert or field == self.syms.clear:
            return 1
        if field == self.syms.get or field == self.syms.contains or field == self.syms.remove:
            return 1
        if field == self.syms.len or field == self.syms.keys or field == self.syms.entry:
            return 1
        if self.pool_resolve(field) == "increment":
            return 1
    if owner_sym == self.syms.hashmapentry:
        if field == self.syms.or_insert or field == self.syms.get:
            return 1
        if self.pool_resolve(field) == "set":
            return 1
    if owner_sym == self.syms.hashset:
        if field == self.syms.insert or field == self.syms.clear:
            return 1
        if field == self.syms.contains or field == self.syms.remove or field == self.syms.len:
            return 1
    if owner_sym == self.syms.slotmap:
        if field == self.syms.new or field == self.syms.insert or field == self.syms.get:
            return 1
        if field == self.syms.slot or field == self.syms.get_disjoint:
            return 1
        if field == self.syms.remove or field == self.syms.replace:
            return 1
        if field == self.syms.contains or field == self.syms.len:
            return 1
    if owner_sym == self.syms.slotmapslot:
        if field == self.syms.get or self.pool_resolve(field) == "set":
            return 1
    if owner_sym == self.syms.option:
        if field == self.syms.unwrap or field == self.syms.is_some or field == self.syms.is_none or field == self.syms.filter or self.pool_resolve(field) == "unwrap_or":
            return 1
    if owner_sym == self.syms.result:
        if field == self.syms.unwrap or field == self.syms.is_ok or field == self.syms.is_err or self.pool_resolve(field) == "unwrap_or":
            return 1
    if owner_sym == self.syms.vecslot or owner_sym == self.syms.vecrange:
        if field == self.syms.get or self.pool_resolve(field) == "set" or self.pool_resolve(field) == "len":
            return 1
    if owner_sym == self.syms.veciter or owner_sym == self.syms.veciterref or owner_sym == self.syms.veciterplace:
        if field == self.syms.next:
            return 1
    0

fn Sema.pipeline_method_exists(self: Sema, recv_type: i32, method: i32) -> i32:
    if recv_type == 0 or method == 0:
        return 0
    var resolved = self.resolve_alias(recv_type as TypeId)
    let tk0 = self.get_type_kind(resolved)
    if tk0 == TypeKind.TY_PTR or tk0 == TypeKind.TY_REF:
        resolved = self.resolve_alias(self.get_type_d0(resolved) as TypeId)
    let owner = self.method_owner_symbol_for_type(resolved as i32)
    if owner == 0:
        return 0
    if self.lookup_generic_method_fn(owner, method) != 0:
        return 1
    if self.lookup_method_sig(owner, method) >= 0:
        return 1
    if self.builtin_intrinsic_method_return_type(resolved as i32, owner, method) != 0:
        return 1
    if self.get_type_kind(resolved) == TypeKind.TY_GENERIC_INST:
        return self.pipeline_generic_builtin_method_exists(owner, method)
    0

fn Sema.check_tuple(self: Sema, node: i32) -> i32:
    let extra_start = self.ast.get_data0(node)
    let elem_count = self.ast.get_data1(node)
    if elem_count == 0:
        self.typed_expr_types.insert(node, self.ty_void as i32)
        return self.ty_void as i32
    var expected_tuple = 0
    var expected_elem_start = 0
    if self.has_expected_type != 0 and self.expected_expr_type != 0:
        let expected = self.resolve_alias(self.expected_expr_type)
        if self.get_type_kind(expected) == TypeKind.TY_TUPLE and self.get_type_d1(expected) == elem_count:
            expected_tuple = expected as i32
            expected_elem_start = self.get_type_d0(expected)
    let tuple_elems: Vec[i32] = Vec.new()
    for ei in 0..elem_count:
        let elem = self.ast.get_extra(extra_start + ei)
        let expected_elem = if expected_tuple != 0: self.type_extra.get((expected_elem_start + ei) as i64) else: 0
        let et = if expected_elem != 0:
            self.check_expr_with_expected(elem, expected_elem as TypeId)
        else:
            self.check_expr(elem)
        tuple_elems.push(et as i32)
    let result = if expected_tuple != 0:
        self.expected_expr_type
    else:
        self.ensure_tuple_type(tuple_elems, elem_count)
    self.typed_expr_types.insert(node, result as i32)
    result as i32

fn Sema.check_range(self: Sema, node: i32) -> i32:
    let start = self.ast.get_data0(node)
    let end = self.ast.get_data1(node)
    let inclusive = self.ast.get_data2(node)
    var elem_type: TypeId = self.ty_i32
    if start != 0:
        elem_type = self.check_expr(start)
    if end != 0:
        let end_ty = self.check_expr(end)
        if start == 0:
            elem_type = end_ty
        else if self.types_compatible(elem_type, end_ty) == 0:
            self.emit_error("range bounds must have compatible types", node)
    self.ensure_exact_type(TypeKind.TY_RANGE, elem_type as i32, inclusive, 0) as i32

fn Sema.check_with_expr(self: Sema, node: i32) -> i32:
    let source = self.ast.get_data0(node)
    let body = self.ast.get_data1(node)
    let encoded_name = self.ast.get_data2(node)
    let name = decode_with_binding_sym(encoded_name)
    let is_mut = decode_with_binding_is_mut(encoded_name)
    var source_ty = self.check_expr(source)
    self.push_scope()
    let had_binding = self.scope_has(name)
    self.scope_put(name, source_ty as i32, is_mut)
    if had_binding == 0:
        self.register_pending_generic_binding(name, 0, source, source_ty as i32)
    let body_ty = self.check_expr(body)
    let final_source_ty = self.scope_lookup(name)
    if final_source_ty >= 0:
        source_ty = final_source_ty as TypeId
    self.pop_scope()
    // Form 2 builder rule: `with <expr> as mut x:` returns `x` when body
    // ends in Unit; otherwise returns the final expression value.
    if is_mut != 0 and self.with_body_is_unit(body, body_ty):
        return source_ty as i32
    body_ty as i32

fn Sema.with_body_is_unit(self: Sema, body: i32, body_ty: TypeId) -> bool:
    if body_ty == self.ty_void:
        return true
    let bk = self.ast.kind(body)
    if bk == NodeKind.NK_ASSIGN:
        return true
    if bk == NodeKind.NK_BLOCK:
        let tail = self.ast.get_data2(body)
        if tail != 0 and self.ast.kind(tail) == NodeKind.NK_ASSIGN:
            return true
    false

fn Sema.check_with_tuple(self: Sema, node: i32) -> i32:
    let source = self.ast.get_data0(node)
    let body = self.ast.get_data1(node)
    let extra_start = self.ast.get_data2(node)
    let name_count = self.ast.get_extra(extra_start)
    let is_mut = self.ast.get_extra(extra_start + 1)
    let source_ty = self.check_expr(source)
    let resolved = self.resolve_alias(source_ty as TypeId)
    let tk = self.get_type_kind(resolved)
    if tk != TypeKind.TY_TUPLE:
        self.emit_error("'with ... as (a, b)' requires a tuple expression", node)
        return 0
    let tuple_arity = self.get_type_d1(resolved)
    if tuple_arity != name_count:
        self.emit_error("tuple binding count does not match tuple arity", node)
        return 0
    self.push_scope()
    let te_start = self.get_type_d0(resolved)
    for i in 0..name_count:
        let sym = self.ast.get_extra(extra_start + 2 + i)
        if sym != 0:
            let elem_ty = self.type_extra.get((te_start + i) as i64)
            self.scope_put(sym, elem_ty, is_mut)
    let body_ty = self.check_expr(body)
    self.pop_scope()
    if is_mut != 0 and self.with_body_is_unit(body, body_ty as TypeId):
        return source_ty as i32
    body_ty as i32

fn Sema.check_with_implicit(self: Sema, node: i32) -> i32:
    let source = self.ast.get_data0(node)
    let body = self.ast.get_data1(node)
    let binding_name = self.ast.get_data2(node)
    var source_ty = self.check_expr(source)
    // Push implicit binding onto stack
    self.implicit_binding_types.push(source_ty as i32)
    self.implicit_binding_syms.push(binding_name)
    self.push_scope()
    let had_binding = self.scope_has(binding_name)
    self.scope_put(binding_name, source_ty as i32, 0)
    if had_binding == 0:
        self.register_pending_generic_binding(binding_name, 0, source, source_ty as i32)
    let body_ty = self.check_expr(body)
    let final_source_ty = self.scope_lookup(binding_name)
    if final_source_ty >= 0:
        source_ty = final_source_ty as TypeId
    self.pop_scope()
    // Pop implicit binding
    self.implicit_binding_types.pop()
    self.implicit_binding_syms.pop()
    body_ty as i32

fn Sema.check_record_update(self: Sema, node: i32) -> i32:
    let source = self.ast.get_data0(node)
    let extra_start = self.ast.get_data1(node)
    let field_count = self.ast.get_data2(node)
    let source_ty = self.check_expr(source)
    if source_ty != 0:
        let source_resolved = self.resolve_alias(source_ty)
        let source_tk = self.get_type_kind(source_resolved)
        if source_tk != TypeKind.TY_STRUCT and source_tk != TypeKind.TY_GENERIC_INST:
            self.emit_error("record update requires struct type", source)
        let source_owner = self.method_owner_symbol_for_type(source_resolved as i32)
        if source_owner != 0 and self.has_drop_method(source_owner) != 0 and self.current_drop_type_sym != source_owner:
            self.emit_error("partial move from Drop type", source)
    for fi in 0..field_count:
        let f_name = self.ast.get_extra(extra_start + fi * 2)
        let f_value = self.ast.get_extra(extra_start + fi * 2 + 1)
        var field_ty = 0
        if source_ty != 0:
            field_ty = self.struct_field_type(source_ty as i32, f_name)
            if field_ty == 0:
                self.emit_error("unknown field in record update", f_value)
        if field_ty != 0:
            self.check_expr_with_expected(f_value, field_ty as TypeId)
        else:
            self.check_expr(f_value)
    if source_ty != 0 and source_ty != self.ty_void:
        self.typed_expr_types.insert(node, source_ty as i32)
        self.mark_moved_if_consumed(source)
    source_ty as i32

fn Sema.check_let_else(self: Sema, node: i32) -> i32:
    let pattern = self.ast.get_data0(node)
    let value = self.ast.get_data1(node)
    let else_body = self.ast.get_data2(node)
    let val_type = self.check_expr(value)
    if val_type != 0 and val_type != self.ty_void:
        self.typed_expr_types.insert(value, val_type as i32)
    self.check_pattern(pattern, val_type as i32)
    self.check_expr(else_body)
    self.ty_void as i32

fn Sema.check_tuple_destructure(self: Sema, node: i32) -> i32:
    let extra_start = self.ast.get_data0(node)
    let name_count = self.ast.get_data1(node)
    let value = self.ast.get_data2(node)
    let val_type = self.check_expr(value)
    // Ensure the value expression's type is cached for MIR lowering
    if val_type != 0 and val_type != self.ty_void:
        self.typed_expr_types.insert(value, val_type as i32)
    let resolved = self.resolve_alias(val_type)
    let is_tuple = self.get_type_kind(resolved) == TypeKind.TY_TUPLE
    if is_tuple == 0:
        self.emit_error("tuple destructuring requires tuple type", node)
    let elem_start = if is_tuple != 0: self.get_type_d0(resolved) else: 0
    let elem_count = if is_tuple != 0: self.get_type_d1(resolved) else: 0
    // Check for rest pattern (negative sym value)
    var has_rest = false
    var rest_pos = -1
    for ni in 0..name_count:
        let n_sym = self.ast.get_extra(extra_start + ni)
        if n_sym < 0:
            has_rest = true
            rest_pos = ni
    if has_rest:
        // Bind elements before rest
        for ni in 0..rest_pos:
            let n_sym = self.ast.get_extra(extra_start + ni)
            var bind_ty = 0
            if ni < elem_count:
                bind_ty = self.type_extra.get((elem_start + ni) as i64)
            if n_sym > 0:
                self.scope_put(n_sym, bind_ty, 0)
        // Rest binding: bind to sub-tuple of remaining elements
        let rest_sym = 0 - self.ast.get_extra(extra_start + rest_pos)
        let after_rest = name_count - rest_pos - 1
        let rest_elem_count = elem_count - rest_pos - after_rest
        if rest_sym > 0 and rest_elem_count > 0:
            let rest_elems: Vec[i32] = Vec.new()
            for ri in 0..rest_elem_count:
                let idx = rest_pos + ri
                if idx < elem_count:
                    rest_elems.push(self.type_extra.get((elem_start + idx) as i64))
                else:
                    rest_elems.push(0)
            let rest_ty = self.ensure_tuple_type(rest_elems, rest_elem_count)
            self.scope_put(rest_sym, rest_ty as i32, 0)
        else if rest_sym > 0:
            self.scope_put(rest_sym, self.ty_void as i32, 0)
        // Bind elements after rest
        for ni in 0..after_rest:
            let n_sym = self.ast.get_extra(extra_start + rest_pos + 1 + ni)
            let elem_idx = elem_count - after_rest + ni
            var bind_ty = 0
            if elem_idx >= 0 and elem_idx < elem_count:
                bind_ty = self.type_extra.get((elem_start + elem_idx) as i64)
            if n_sym > 0:
                self.scope_put(n_sym, bind_ty, 0)
    else:
        var emitted_arity_error = 0
        for ni in 0..name_count:
            let n_sym = self.ast.get_extra(extra_start + ni)
            var bind_ty = 0
            if ni < elem_count:
                bind_ty = self.type_extra.get((elem_start + ni) as i64)
            else:
                if emitted_arity_error == 0 and is_tuple != 0:
                    self.emit_error("tuple destructuring arity mismatch", node)
                    emitted_arity_error = 1
            if n_sym > 0:
                self.scope_put(n_sym, bind_ty, 0)
    self.ty_void as i32

fn Sema.is_sizeof_or_alignof(self: Sema, callee: i32) -> i32:
    let kind = self.ast.kind(callee)
    if kind != NodeKind.NK_TYPE_GENERIC and kind != NodeKind.NK_INDEX:
        return 0
    let gi_base = self.ast.get_data0(callee)
    if self.ast.kind(gi_base) != NodeKind.NK_IDENT:
        return 0
    let gi_name = self.pool_resolve(self.ast.get_data0(gi_base))
    if gi_name == "sizeof" or gi_name == "size_of":
        return 1
    if gi_name == "alignof" or gi_name == "align_of":
        return 1
    0

fn Sema.is_chan_call(self: Sema, callee: i32) -> i32:
    let kind = self.ast.kind(callee)
    if kind != NodeKind.NK_TYPE_GENERIC and kind != NodeKind.NK_INDEX:
        return 0
    let gi_base = self.ast.get_data0(callee)
    if self.ast.kind(gi_base) != NodeKind.NK_IDENT:
        return 0
    let gi_name = self.pool_resolve(self.ast.get_data0(gi_base))
    if gi_name == "chan":
        return 1
    0

fn Sema.chan_return_type(self: Sema, callee: i32) -> i32:
    // chan[T](cap) → (Sender[T], Receiver[T])
    // Extract T from the generic call's type argument
    let type_arg_node = self.ast.get_data1(callee)
    var elem_type = self.ty_i32 as i32
    if type_arg_node > 0:
        // Look up the type from sema's type cache
        if self.typed_expr_types.contains(type_arg_node):
            elem_type = self.typed_expr_types.get(type_arg_node).unwrap()
        else:
            // Try to resolve as a named type
            let ta_kind = self.ast.kind(type_arg_node)
            if ta_kind == NodeKind.NK_IDENT or ta_kind == NodeKind.NK_TYPE_NAMED:
                let ta_sym = self.ast.get_data0(type_arg_node)
                let prim = self.primitive_type_by_sym(ta_sym)
                if prim != 0:
                    elem_type = prim as i32
                else if self.named_types.contains(ta_sym):
                    elem_type = self.named_types.get(ta_sym).unwrap()
    // Build Sender[T] and Receiver[T] types
    let sender_sym = self.pool_intern("Sender")
    let receiver_sym = self.pool_intern("Receiver")
    let sender_args: Vec[i32] = Vec.new()
    sender_args.push(elem_type)
    let sender_ty = self.ensure_generic_inst_type(sender_sym, sender_args, 1)
    let receiver_args: Vec[i32] = Vec.new()
    receiver_args.push(elem_type)
    let receiver_ty = self.ensure_generic_inst_type(receiver_sym, receiver_args, 1)
    // Build tuple (Sender[T], Receiver[T])
    let tuple_elems: Vec[i32] = Vec.new()
    tuple_elems.push(sender_ty as i32)
    tuple_elems.push(receiver_ty as i32)
    let te_start = self.type_extra.len() as i32
    self.type_extra.push(sender_ty as i32)
    self.type_extra.push(receiver_ty as i32)
    self.add_type(TypeKind.TY_TUPLE, te_start, 2, 0) as i32

fn Sema.is_nameof_call(self: Sema, callee: i32) -> i32:
    let kind = self.ast.kind(callee)
    if kind != NodeKind.NK_TYPE_GENERIC and kind != NodeKind.NK_INDEX:
        return 0
    let gi_base = self.ast.get_data0(callee)
    if self.ast.kind(gi_base) != NodeKind.NK_IDENT:
        return 0
    let gi_name = self.pool_resolve(self.ast.get_data0(gi_base))
    if gi_name == "nameof" or gi_name == "type_name":
        return 1
    0

fn Sema.is_transmute_call(self: Sema, callee: i32) -> i32:
    let kind = self.ast.kind(callee)
    if kind != NodeKind.NK_TYPE_GENERIC and kind != NodeKind.NK_INDEX:
        return 0
    let gi_base = self.ast.get_data0(callee)
    if self.ast.kind(gi_base) != NodeKind.NK_IDENT:
        return 0
    let gi_name = self.pool_resolve(self.ast.get_data0(gi_base))
    if gi_name == "transmute":
        return 1
    0

fn Sema.transmute_target_type(self: Sema, callee: i32) -> i32:
    let tp_node = if self.ast.kind(callee) == NodeKind.NK_TYPE_GENERIC:
        let tp_start = self.ast.get_data1(callee)
        let tp_count = self.ast.get_data2(callee)
        if tp_count == 0:
            return 0
        self.ast.get_extra(tp_start)
    else:
        self.ast.get_data1(callee)
    self.resolve_type_expr(tp_node) as i32

fn Sema.type_is_unit(self: Sema, tid: i32) -> i32:
    if tid == 0:
        return 0
    let resolved = self.resolve_alias(tid as TypeId)
    if resolved == self.ty_void:
        return 1
    if self.get_type_kind(resolved) == TypeKind.TY_TUPLE and self.get_type_d1(resolved) == 0:
        return 1
    0

fn Sema.store_unit_elided_call_arg(self: Sema, call_node: i32):
    let args: Vec[i32] = Vec.new()
    args.push(0)
    self.store_resolved_call_args(call_node, args)

fn Sema.try_unit_elide_call_arg(self: Sema, call_node: i32, arg_count: i32, expected_ty: i32) -> i32:
    if arg_count != 0:
        return 0
    if self.ast.has_call_named_args(call_node) != 0:
        return 0
    if self.has_resolved_call_args(call_node) != 0:
        return 0
    if self.type_is_unit(expected_ty) == 0:
        return 0
    self.store_unit_elided_call_arg(call_node)
    1

fn Sema.check_callable_value_call(self: Sema, call_name: str, fn_tid: i32, closure_node: i32, node: i32, extra_start: i32, arg_count: i32, param_offset: i32, has_resolved: i32, arg_types: Vec[i32]) -> i32:
    let expected = self.get_type_d1(fn_tid)
    let actual = arg_count + param_offset
    if self.ast.has_call_named_args(node) == 0 and self.has_resolved_call_args(node) == 0:
        if actual != expected:
            if call_name.len() > 0:
                self.emit_error(f"callable '{call_name}' expects {expected} argument(s), found {actual}", node)
            else:
                self.emit_error(f"callable value expects {expected} argument(s), found {actual}", node)

    for ai in 0..arg_count:
        let param_i = ai + param_offset
        if param_i >= expected:
            break
        let expected_ty = self.callable_fn_param_type(fn_tid as TypeId, param_i)
        let arg_ty = arg_types.get(ai as i64)
        if expected_ty != 0 and arg_ty != 0:
            let exp_resolved = self.resolve_alias(expected_ty)
            if self.type_is_dyn_object(exp_resolved) == 0:
                if self.types_compatible(expected_ty, arg_ty) == 0:
                    if self.arithmetic_result_type(expected_ty, arg_ty) == 0:
                        let err_arg_node = if has_resolved != 0: self.get_resolved_call_arg(node, ai) else: self.ast.get_extra(extra_start + ai)
                        self.emit_argument_type_mismatch(call_name, 0, ai, param_i, expected_ty, arg_ty, if err_arg_node > 0: err_arg_node else: node)
        let eph_arg_node = if has_resolved != 0: self.get_resolved_call_arg(node, ai) else: self.ast.get_extra(extra_start + ai)
        if eph_arg_node > 0 and self.expr_is_ephemeral_task(eph_arg_node) != 0 and self.param_is_by_reference(expected_ty) == 0:
            self.emit_warning("ephemeral Task passed by value may escape", eph_arg_node)

    if closure_node > 0:
        let capture_count = self.closure_capture_summary_count(closure_node)
        let closure_view_deps: Vec[i32] = Vec.new()
        var closure_view_mask = 0
        for ci in 0..capture_count:
            let cap_sym = self.closure_capture_summary_sym(closure_node, ci)
            let cap_eff = self.closure_capture_summary_eff(closure_node, ci)
            let trans_bits = cap_eff & (EFF_CONSUME | EFF_ESCAPE_VALUE | EFF_ESCAPE_VIEW)
            if trans_bits != 0:
                self.note_param_effect(cap_sym, trans_bits)
            if (cap_eff & EFF_ESCAPE_VIEW) != 0:
                let cap_pi = self.param_index_for_sym(cap_sym)
                if cap_pi >= 0:
                    closure_view_mask = closure_view_mask | (((1 as i64) << (cap_pi as u32)) as i32)
                else:
                    closure_view_mask = closure_view_mask | self.binding_view_origin_mask(cap_sym)
                let dep_count = self.binding_view_dep_count(cap_sym)
                if dep_count > 0:
                    for di in 0..dep_count:
                        self.push_unique_i32(closure_view_deps, self.binding_view_dep_at(cap_sym, di))
                else:
                    let cap_tid = self.scope_lookup(cap_sym)
                    if cap_tid > 0:
                        let cap_tk = self.get_type_kind(self.resolve_alias(cap_tid as TypeId))
                        if cap_tk == TypeKind.TY_REF or cap_tk == TypeKind.TY_PTR:
                            self.push_unique_i32(closure_view_deps, cap_sym)
            if (cap_eff & (EFF_CONSUME | EFF_ESCAPE_VALUE)) != 0 and self.scope_has(cap_sym) != 0:
                let cap_tid = self.scope_lookup(cap_sym)
                if self.is_copy(cap_tid as TypeId) == 0:
                    self.scope_set_state(cap_sym, VarState.MOVED)
        let ret_tk = self.get_type_kind(self.resolve_alias(self.get_type_d2(fn_tid) as TypeId))
        if ret_tk == TypeKind.TY_REF or ret_tk == TypeKind.TY_PTR:
            self.set_expr_view_deps(node, closure_view_mask, closure_view_deps)

    let ret = self.get_type_d2(fn_tid)
    self.typed_expr_types.insert(node, ret)
    ret

fn Sema.check_call(self: Sema, node: i32) -> i32:
    let callee = self.ast.get_data0(node)
    let extra_start = self.ast.get_data1(node)
    let arg_count = self.ast.get_data2(node)

    // sizeof[T]() / alignof[T]() / transmute[T]() / nameof[T]() builtins
    if self.is_sizeof_or_alignof(callee) != 0:
        return self.ty_i64 as i32
    if self.is_nameof_call(callee) != 0:
        return self.ty_str as i32
    if self.is_transmute_call(callee) != 0:
        return self.transmute_target_type(callee)
    if self.is_chan_call(callee) != 0:
        return self.chan_return_type(callee)

    // Method call or callable field: callee is field_access
    if self.ast.kind(callee) == NodeKind.NK_FIELD_ACCESS:
        let callable_tid = self.callable_fn_type(self.field_access_type_no_diagnostic(callee) as TypeId)
        if callable_tid != 0:
            if self.ast.has_call_named_args(node) != 0:
                self.emit_error("named arguments are not supported for closures or function pointers", node)
            let arg_types_for_callable: Vec[i32] = Vec.new()
            for cai in 0..arg_count:
                let arg_node = self.ast.get_extra(extra_start + cai)
                let expected_ty = self.callable_fn_param_type(callable_tid as TypeId, cai)
                let arg_ty = if expected_ty != 0: self.check_expr_with_expected(arg_node, expected_ty as TypeId) else: self.check_expr(arg_node)
                arg_types_for_callable.push(arg_ty as i32)
            for cai2 in 0..arg_count:
                self.mark_moved_if_consumed(self.ast.get_extra(extra_start + cai2))
            return self.check_callable_value_call("", callable_tid, 0, node, extra_start, arg_count, 0, 0, arg_types_for_callable)
        let ret = self.check_method_call(callee, extra_start, arg_count, node)
        if ret != 0:
            self.typed_expr_types.insert(node, ret)
        return ret

    // Direct call: callee should be ident
    var fn_sym = 0
    var local_tid = -1
    var callable_value_tid = 0
    var callable_closure_node = 0
    if self.ast.kind(callee) == NodeKind.NK_IDENT:
        fn_sym = self.ast.get_data0(callee)
        // Resolve for-comprehension _Payload marker to Some or Ok
        let call_name = self.pool_resolve(fn_sym)
        if call_name == "_Payload":
            // Try expected type first, then fall back to Some (most common)
            if self.has_expected_type != 0:
                let exp_resolved = self.resolve_alias(self.expected_expr_type)
                if self.enum_has_variant(exp_resolved as i32, self.syms.ok) != 0:
                    fn_sym = self.syms.ok
                else:
                    fn_sym = self.syms.some
            else:
                fn_sym = self.syms.some
            self.comp_resolved.insert(node, fn_sym)
        local_tid = self.scope_lookup(fn_sym)
        if local_tid >= 0:
            callable_value_tid = self.callable_fn_type(local_tid as TypeId)
            if self.binding_closure_nodes.contains(fn_sym):
                callable_closure_node = self.binding_closure_nodes.get(fn_sym).unwrap()
    else:
        callable_value_tid = self.callable_fn_type(self.check_expr(callee) as TypeId)
        if self.ast.kind(callee) == NodeKind.NK_CLOSURE:
            callable_closure_node = callee

    // Reject named args on closures and function pointers (spec §F4 rule 7)
    if self.ast.has_call_named_args(node) != 0:
        if callable_value_tid != 0:
            self.emit_error("named arguments are not supported for closures or function pointers", node)

    let param_offset = if self.in_pipeline_rhs != 0: 1 else: 0
    let sig_idx_raw = if self.generic_fn_nodes.contains(fn_sym): -1 else: self.get_sig(fn_sym)
    let sig_idx = if sig_idx_raw >= 0 and self.is_ci_visible(fn_sym) == 0: -1 else: sig_idx_raw
    let variant_expected_ty = if self.variant_lookup.contains(fn_sym) and self.is_ci_visible(fn_sym) != 0: self.expected_variant_constructor_type(fn_sym) else: 0
    let imported_variant_owner_for_call = if self.imported_variant_owners.contains(fn_sym): self.imported_variant_owners.get(fn_sym).unwrap() else: 0
    let variant_payload_owner = if variant_expected_ty != 0:
        variant_expected_ty
    else if imported_variant_owner_for_call != 0:
        imported_variant_owner_for_call
    else if self.variant_type_ids.contains(fn_sym):
        self.variant_type_ids.get(fn_sym).unwrap()
    else:
        0
    let variant_payload_tys = if variant_payload_owner != 0: self.enum_variant_payload_types(variant_payload_owner, fn_sym) else: Vec.new()

    // Resolve named arguments: reorder args to match parameter order, fill defaults
    var resolved_extra_start = extra_start
    var resolved_arg_count = arg_count
    if self.ast.has_call_named_args(node) != 0 and sig_idx >= 0 and self.fn_decl_nodes.contains(fn_sym):
        let fn_node = self.fn_decl_nodes.get(fn_sym).unwrap()
        let meta = self.ast.find_fn_meta(fn_node)
        if meta >= 0:
            let param_count = self.sig_get_param_count(sig_idx)
            let ps = self.ast.fn_meta_param_start(meta)
            // Build resolved_args map: param_idx → arg_node
            let resolved_map: HashMap[i32, i32] = HashMap.new()
            let resolved_defaults: HashMap[i32, i32] = HashMap.new()
            // First pass: assign positional args left-to-right
            var first_named_idx = arg_count
            for ai in 0..arg_count:
                let name_sym = self.ast.get_call_named_arg(node, ai)
                if name_sym != 0:
                    first_named_idx = ai
                    break
                let pi = ai + param_offset
                if pi < param_count:
                    resolved_map.insert(pi, self.ast.get_extra(extra_start + ai))
            // Second pass: assign named args by matching parameter names
            for ai in first_named_idx..arg_count:
                let name_sym = self.ast.get_call_named_arg(node, ai)
                if name_sym == 0:
                    continue
                var matched = -1
                for pi in 0..param_count:
                    let pname = self.ast.fn_param_name(ps, pi)
                    if pname == name_sym:
                        matched = pi
                        break
                if matched < 0:
                    let aname = self.pool_resolve(name_sym)
                    self.emit_error(f"no parameter named '{aname}'", node)
                    continue
                if resolved_map.contains(matched):
                    let aname = self.pool_resolve(name_sym)
                    self.emit_error(f"parameter '{aname}' specified more than once", node)
                    continue
                resolved_map.insert(matched, self.ast.get_extra(extra_start + ai))
            // Third pass: fill implicit params from with-implicit scope
            for pi in 0..param_count:
                if resolved_map.contains(pi): continue
                let pflags = self.ast.fn_param_flags(ps, pi)
                if fn_param_is_implicit(pflags) == 0: continue
                let expected_ty = self.sig_param_type(sig_idx, pi)
                var si = self.implicit_binding_types.len() as i32 - 1
                while si >= 0:
                    let bind_ty = self.implicit_binding_types.get(si as i64)
                    if self.types_compatible(expected_ty, bind_ty) != 0:
                        let bind_sym = self.implicit_binding_syms.get(si as i64)
                        resolved_map.insert(pi, 0 - bind_sym)
                        break
                    si = si - 1
            // Fourth pass: fill defaults for remaining unresolved params
            for pi in 0..param_count:
                if not resolved_map.contains(pi):
                    let default_node = self.ast.get_fn_param_default(ps, pi)
                    if default_node != 0:
                        resolved_map.insert(pi, default_node)
                        resolved_defaults.insert(pi, 1)
            // Store resolved arg order in sema (AST is frozen)
            let final_args: Vec[i32] = Vec.new()
            for pi in param_offset..param_count:
                if resolved_map.contains(pi):
                    final_args.push(resolved_map.get(pi).unwrap())
                else:
                    final_args.push(0)
            self.store_resolved_call_args(node, final_args)
            for pi in param_offset..param_count:
                if resolved_defaults.contains(pi):
                    self.mark_resolved_call_arg_default(node, pi - param_offset)
            resolved_arg_count = param_count - param_offset

    // Implicit parameter resolution for plain calls (no named args).
    // When the caller provides fewer args than params and the missing
    // params are implicit, fill them from the with-implicit scope.
    if self.has_resolved_call_args(node) == 0 and sig_idx >= 0 and self.fn_decl_nodes.contains(fn_sym):
        if self.implicit_binding_types.len() > 0:
            let fn_node_impl = self.fn_decl_nodes.get(fn_sym).unwrap()
            let meta_impl = self.ast.find_fn_meta(fn_node_impl)
            if meta_impl >= 0:
                let param_count = self.sig_get_param_count(sig_idx)
                let actual = arg_count + param_offset
                if actual < param_count:
                    let ps = self.ast.fn_meta_param_start(meta_impl)
                    var has_implicit = 0
                    for pi in actual..param_count:
                        let pflags = self.ast.fn_param_flags(ps, pi)
                        if fn_param_is_implicit(pflags) != 0:
                            has_implicit = 1
                            break
                    if has_implicit != 0:
                        let resolved_map: HashMap[i32, i32] = HashMap.new()
                        let resolved_defaults: HashMap[i32, i32] = HashMap.new()
                        // Positional args
                        for ai in 0..arg_count:
                            resolved_map.insert(ai + param_offset, self.ast.get_extra(extra_start + ai))
                        // Fill implicit params
                        for pi in 0..param_count:
                            if resolved_map.contains(pi): continue
                            let pflags = self.ast.fn_param_flags(ps, pi)
                            if fn_param_is_implicit(pflags) == 0: continue
                            let expected_ty = self.sig_param_type(sig_idx, pi)
                            var si = self.implicit_binding_types.len() as i32 - 1
                            while si >= 0:
                                let bind_ty = self.implicit_binding_types.get(si as i64)
                                if self.types_compatible(expected_ty, bind_ty) != 0:
                                    let bind_sym = self.implicit_binding_syms.get(si as i64)
                                    resolved_map.insert(pi, 0 - bind_sym)
                                    break
                                si = si - 1
                        // Fill defaults
                        for pi in 0..param_count:
                            if not resolved_map.contains(pi):
                                let default_node = self.ast.get_fn_param_default(ps, pi)
                                if default_node != 0:
                                    resolved_map.insert(pi, default_node)
                                    resolved_defaults.insert(pi, 1)
                        let final_args: Vec[i32] = Vec.new()
                        for pi in param_offset..param_count:
                            if resolved_map.contains(pi):
                                final_args.push(resolved_map.get(pi).unwrap())
                            else:
                                final_args.push(0)
                        self.store_resolved_call_args(node, final_args)
                        for pi in param_offset..param_count:
                            if resolved_defaults.contains(pi):
                                self.mark_resolved_call_arg_default(node, pi - param_offset)
                        resolved_arg_count = param_count - param_offset

    if self.has_resolved_call_args(node) == 0 and self.ast.has_call_named_args(node) == 0 and arg_count == 0:
        if sig_idx >= 0:
            let sig_param_count = self.sig_get_param_count(sig_idx)
            if sig_param_count - param_offset == 1:
                let expected_unit_ty = self.sig_param_type(sig_idx, param_offset)
                if self.try_unit_elide_call_arg(node, arg_count, expected_unit_ty) != 0:
                    resolved_arg_count = 1
        else if callable_value_tid != 0:
            let callable_param_count = self.get_type_d1(callable_value_tid as TypeId)
            if callable_param_count - param_offset == 1:
                let expected_callable_ty = self.callable_fn_param_type(callable_value_tid as TypeId, param_offset)
                if self.try_unit_elide_call_arg(node, arg_count, expected_callable_ty) != 0:
                    resolved_arg_count = 1
        else if variant_payload_tys.len() as i32 == 1:
            let expected_variant_unit_ty = variant_payload_tys.get(0)
            if self.try_unit_elide_call_arg(node, arg_count, expected_variant_unit_ty) != 0:
                resolved_arg_count = 1
        else if self.generic_fn_nodes.contains(fn_sym):
            let gen_fn_node = self.generic_fn_nodes.get(fn_sym).unwrap()
            let gen_meta = self.ast.find_fn_meta(gen_fn_node)
            if gen_meta >= 0 and self.ast.fn_meta_param_count(gen_meta) == 1:
                let gen_param_start = self.ast.fn_meta_param_start(gen_meta)
                let gen_param_ty_node = self.ast.fn_param_type(gen_param_start, 0)
                let gen_expected_ty = if gen_param_ty_node != 0: self.resolve_type_expr(gen_param_ty_node) as i32 else: 0
                if self.try_unit_elide_call_arg(node, arg_count, gen_expected_ty) != 0:
                    resolved_arg_count = 1

    // Check all arguments (with contextual expected-type propagation when
    // calling a known function signature).
    let has_resolved = self.has_resolved_call_args(node)
    let arg_types: Vec[i32] = Vec.new()
    // docs/mut.md Rev 8 §15.8 — borrow indices to remove after this call's
    // arg-loop completes. Iterator-of-self borrows live for the duration of
    // the enclosing call so sibling closures conflict with them.
    let iter_borrow_idxs: Vec[i32] = Vec.new()
    for ai in 0..resolved_arg_count:
        let arg_node = if has_resolved != 0: self.get_resolved_call_arg(node, ai) else: self.ast.get_extra(resolved_extra_start + ai)
        var expected_ty = 0
        if sig_idx >= 0:
            let param_i = ai + param_offset
            if param_i < self.sig_get_param_count(sig_idx):
                expected_ty = self.sig_param_type(sig_idx, param_i)
        else if ai < variant_payload_tys.len() as i32:
            expected_ty = variant_payload_tys.get(ai as i64)
        else if callable_value_tid != 0:
            expected_ty = self.callable_fn_param_type(callable_value_tid as TypeId, ai + param_offset)
        if arg_node == 0:
            arg_types.push(0)
            continue
        if arg_node < 0:
            let bind_sym = 0 - arg_node
            arg_types.push(self.scope_lookup(bind_sym))
            continue
        let is_closure_arg = self.ast.kind(arg_node) == NodeKind.NK_CLOSURE
        var closure_arg_escapes = 0
        if is_closure_arg and sig_idx >= 0:
            let param_i_for_effect = ai + param_offset
            if param_i_for_effect < self.sig_get_param_count(sig_idx):
                let param_eff = self.sig_param_effect(sig_idx, param_i_for_effect)
                if (param_eff & (EFF_ESCAPE_VALUE | EFF_ESCAPE_VIEW)) != 0:
                    closure_arg_escapes = 1
        if is_closure_arg:
            self.closure_direct_arg_depth = self.closure_direct_arg_depth + 1
            self.closure_direct_arg_escape_flags.push(closure_arg_escapes)
        let arg_ty = if expected_ty != 0: self.check_expr_with_expected(arg_node, expected_ty as TypeId) else: self.check_expr(arg_node)
        if is_closure_arg:
            self.closure_direct_arg_escape_flags.pop()
            self.closure_direct_arg_depth = self.closure_direct_arg_depth - 1
        arg_types.push(arg_ty as i32)
        let iter_idx = self.maybe_register_iter_of_self_borrow(arg_node)
        if iter_idx >= 0:
            iter_borrow_idxs.push(iter_idx)
    // Drop iter-of-self borrows in reverse insertion order so indices stay valid.
    var ibi = iter_borrow_idxs.len() as i32 - 1
    while ibi >= 0:
        self.remove_borrow_at(iter_borrow_idxs.get(ibi as i64))
        ibi = ibi - 1

    // docs/mut.md Rev 8 §9.2 — closure capture conflict detection.
    // When a mutating closure captures a place, sibling arguments may not
    // retain access to the same place (owned move, view, or iterator).
    self.check_closure_capture_conflicts(resolved_extra_start, resolved_arg_count, has_resolved, node)

    // For unknown functions (no signature), conservatively mark all non-Copy args as moved.
    // For known functions, consuming-effect args are marked moved in the per-param loop below.
    if sig_idx < 0:
        for ai in 0..resolved_arg_count:
            let arg_node = if has_resolved != 0: self.get_resolved_call_arg(node, ai) else: self.ast.get_extra(resolved_extra_start + ai)
            if arg_node > 0:
                self.mark_moved_if_consumed(arg_node)

    if self.check_comptime_call_restriction(fn_sym, node) != 0:
        return 0

    // Known function
    if sig_idx >= 0:
        self.comp_resolved.insert(node, fn_sym)
        let ret = self.sig_return_type(sig_idx) as i32
        // Check arg count (supports default parameters via required-count
        // metadata packed into fn_meta flags by the parser).
        let expected = self.sig_get_param_count(sig_idx)
        let min_expected = self.fn_min_expected_arg_count(fn_sym, expected)
        let actual = resolved_arg_count + param_offset
        // Skip arg count check when named args were resolved (already filled defaults)
        if self.ast.has_call_named_args(node) == 0 and self.has_resolved_call_args(node) == 0:
            if self.sig_is_variadic(sig_idx) == 0:
                if actual < min_expected or actual > expected:
                    // Check if missing params include implicit ones
                    var has_unfilled_implicit = 0
                    if self.fn_decl_nodes.contains(fn_sym) and actual < expected:
                        let fn_node_check = self.fn_decl_nodes.get(fn_sym).unwrap()
                        let meta_check = self.ast.find_fn_meta(fn_node_check)
                        if meta_check >= 0:
                            let ps_check = self.ast.fn_meta_param_start(meta_check)
                            for pi in actual..expected:
                                let pflags = self.ast.fn_param_flags(ps_check, pi)
                                if fn_param_is_implicit(pflags) != 0:
                                    has_unfilled_implicit = 1
                    if has_unfilled_implicit != 0:
                        self.emit_error("implicit parameter not provided; add a 'with' binding of the matching type", node)
                    else:
                        let fn_name = self.pool_resolve(fn_sym)
                        if min_expected == expected:
                            self.emit_error(f"function '{fn_name}' expects {expected} argument(s), found {actual}", node)
                        else:
                            self.emit_error(f"function '{fn_name}' expects {min_expected}-{expected} argument(s), found {actual}", node)

        for ai in 0..resolved_arg_count:
            let param_i = ai + param_offset
            if param_i >= expected:
                break
            let expected_ty = self.sig_param_type(sig_idx, param_i)
            let arg_ty = arg_types.get(ai as i64)
            if expected_ty != 0 and arg_ty != 0:
                let exp_resolved = self.resolve_alias(expected_ty)
                if self.type_is_dyn_object(exp_resolved) == 0:
                    if self.types_compatible(expected_ty, arg_ty) == 0:
                        if self.arithmetic_result_type(expected_ty, arg_ty) == 0:
                            let err_arg_node = if has_resolved != 0: self.get_resolved_call_arg(node, ai) else: self.ast.get_extra(resolved_extra_start + ai)
                            if not (self.ci_syms.contains(fn_sym) and self.try_ci_coercion(arg_ty, expected_ty) != 0):
                                self.emit_argument_type_mismatch(self.safe_symbol_text(fn_sym), fn_sym, ai, param_i, expected_ty, arg_ty, if err_arg_node > 0: err_arg_node else: node)
            let eph_arg_node = if has_resolved != 0: self.get_resolved_call_arg(node, ai) else: self.ast.get_extra(resolved_extra_start + ai)
            if eph_arg_node > 0 and self.expr_is_ephemeral_task(eph_arg_node) != 0 and self.param_is_by_reference(expected_ty) == 0:
                self.emit_warning("ephemeral Task passed by value may escape", eph_arg_node)
            // Effect enforcement: if the callee may consume/escape this arg, it must be explicitly moved or copied
            let param_eff = self.sig_param_effect(sig_idx, param_i)
            // Transitive effect propagation: if this arg is a param of the current function,
            // propagate callee's consuming/escaping effects to the current function's effect set.
            let trans_bits = param_eff & (EFF_CONSUME | EFF_ESCAPE_VALUE | EFF_ESCAPE_VIEW)
            if trans_bits != 0:
                let trans_nd = if has_resolved != 0: self.get_resolved_call_arg(node, ai) else: self.ast.get_extra(resolved_extra_start + ai)
                if trans_nd > 0:
                    let trans_sym = self.place_root_sym(trans_nd)
                    if trans_sym != 0:
                        self.note_param_effect(trans_sym, trans_bits)
            if (param_eff & (EFF_CONSUME | EFF_ESCAPE_VALUE)) != 0:
                let eff_arg_nd = if has_resolved != 0: self.get_resolved_call_arg(node, ai) else: self.ast.get_extra(resolved_extra_start + ai)
                if eff_arg_nd > 0:
                    // Mark the arg as consumed so subsequent uses are caught.
                    self.mark_moved_if_consumed(eff_arg_nd)
                    let anode_kind = self.ast.kind(eff_arg_nd)
                    if anode_kind != NodeKind.NK_COPY_ARG and anode_kind != NodeKind.NK_MOVE_ARG:
                        let eff_ty = if arg_ty != 0: arg_ty else: expected_ty
                        if self.is_copy(eff_ty) == 0:
                            self.emit_error("non-Copy argument passed to a function that consumes or escapes it; use 'move x' or 'copy x'", eff_arg_nd)
            // escape_view: move/copy is forbidden because they invalidate the view's origin
            if (param_eff & EFF_ESCAPE_VIEW) != 0:
                let ev_arg_nd = if has_resolved != 0: self.get_resolved_call_arg(node, ai) else: self.ast.get_extra(resolved_extra_start + ai)
                if ev_arg_nd > 0:
                    let ev_kind = self.ast.kind(ev_arg_nd)
                    if ev_kind == NodeKind.NK_MOVE_ARG:
                        self.emit_error("cannot use 'move' for argument when callee returns a view derived from it ('escape_view' effect)", ev_arg_nd)
                    else if ev_kind == NodeKind.NK_COPY_ARG:
                        self.emit_error("cannot use 'copy' for argument when callee returns a view derived from it ('escape_view' effect)", ev_arg_nd)

        self.check_dyn_trait_call_compat(fn_sym, resolved_extra_start, arg_types, resolved_arg_count, param_offset)
        self.record_call_view_origins(node, sig_idx, param_offset, 0, resolved_extra_start, resolved_arg_count, has_resolved)
        self.typed_expr_types.insert(node, ret)
        return ret

    if callable_value_tid != 0:
        let call_name = if self.ast.kind(callee) == NodeKind.NK_IDENT: self.pool_resolve(fn_sym) else: ""
        return self.check_callable_value_call(call_name, callable_value_tid, callable_closure_node, node, resolved_extra_start, resolved_arg_count, param_offset, has_resolved, arg_types)

    // Local variable (not callable)
    if local_tid >= 0:
        self.emit_error("value is not callable", callee)
        return 0

    // Generic function
    if self.generic_fn_nodes.contains(fn_sym):
        let fn_node = self.generic_fn_nodes.get(fn_sym).unwrap()
        let ret = self.check_generic_call(fn_sym, fn_node, arg_types, resolved_arg_count, node)
        self.comp_resolved.insert(node, fn_sym)
        self.typed_expr_types.insert(node, ret)
        return ret

    // Enum variant constructor
    if self.variant_lookup.contains(fn_sym):
        let inferred_variant_ty = self.infer_generic_enum_variant_type(fn_sym, arg_types, resolved_arg_count)
        let imported_variant_ty = imported_variant_owner_for_call
        let variant_tid = self.variant_type_ids.get(fn_sym).unwrap()
        var final_variant_ty: TypeId = if variant_expected_ty != 0: variant_expected_ty as TypeId else:
            if imported_variant_ty != 0: imported_variant_ty as TypeId else: variant_tid as TypeId
        if inferred_variant_ty != 0:
            final_variant_ty = self.preferred_compatible_type(final_variant_ty, inferred_variant_ty as TypeId)
        let final_payload_tys = self.enum_variant_payload_types(final_variant_ty as i32, fn_sym)
        let expected_payload_count = final_payload_tys.len() as i32
        if resolved_arg_count != expected_payload_count:
            let variant_name = self.pool_resolve(fn_sym)
            self.emit_error(f"enum variant constructor '{variant_name}' expects {expected_payload_count} argument(s), found {resolved_arg_count}", node)
        for ai in 0..resolved_arg_count:
            if ai >= expected_payload_count:
                break
            let expected_ty = final_payload_tys.get(ai as i64)
            let arg_ty = arg_types.get(ai as i64)
            if expected_ty != 0 and arg_ty != 0:
                if self.types_compatible(expected_ty, arg_ty) == 0:
                    if self.arithmetic_result_type(expected_ty, arg_ty) == 0:
                        let err_arg_node = if has_resolved != 0: self.get_resolved_call_arg(node, ai) else: self.ast.get_extra(resolved_extra_start + ai)
                        let variant_name2 = self.pool_resolve(fn_sym)
                        self.emit_argument_type_mismatch(variant_name2, fn_sym, ai, ai, expected_ty, arg_ty, if err_arg_node > 0: err_arg_node else: node)
        let resolved_variant_sym = self.qualified_enum_variant_sym(final_variant_ty as i32, fn_sym)
        self.comp_resolved.insert(node, resolved_variant_sym)
        self.typed_expr_types.insert(node, final_variant_ty as i32)
        return final_variant_ty as i32

    // Distinct type constructor: Meters(42) → Meters { value: 42 }
    if self.distinct_type_names.contains(fn_sym):
        let dt_tid = self.distinct_type_names.get(fn_sym).unwrap()
        if arg_count != 1:
            self.emit_error("distinct type constructor requires exactly 1 argument", node)
            return 0
        self.typed_expr_types.insert(node, dt_tid)
        return dt_tid

    // Callable type syntax: TypeName(args) → TypeName.new(args)
    if self.type_decl_nodes.contains(fn_sym):
        let new_name = self.pool_resolve(fn_sym) ++ ".new"
        let new_sym = self.pool_intern(new_name)
        let new_sig = self.get_sig(new_sym)
        if new_sig >= 0:
            let new_ret = self.sig_return_type(new_sig)
            let new_expected = self.sig_get_param_count(new_sig)
            if arg_count > new_expected:
                self.emit_error("too many arguments for " ++ self.pool_resolve(fn_sym) ++ "()", node)
            self.typed_expr_types.insert(node, new_ret)
            return new_ret

    // Intrinsic function
    if self.is_intrinsic_fn_sym(fn_sym) != 0:
        let ret = self.check_intrinsic_call(fn_sym, node, arg_types, arg_count)
        self.typed_expr_types.insert(node, ret)
        return ret

    if self.ast.kind(callee) != NodeKind.NK_IDENT:
        self.emit_error("value is not callable", callee)
        return 0

    let callee_ty = self.check_ident(fn_sym, callee)
    if callee_ty != 0:
        self.emit_error("value is not callable", callee)
    0

fn Sema.store_resolved_call_args(self: Sema, call_node: i32, args: Vec[i32]):
    let start = self.call_resolved_args_data.len() as i32
    let count = args.len() as i32
    for i in 0..count:
        self.call_resolved_args_data.push(args.get(i as i64))
    self.call_resolved_args_map.insert(call_node, start * 65536 + count)

fn Sema.resolved_call_arg_key(self: Sema, call_node: i32, idx: i32) -> i32:
    call_node * 65536 + idx

fn Sema.mark_resolved_call_arg_default(self: Sema, call_node: i32, idx: i32):
    self.call_resolved_default_arg_keys.insert(self.resolved_call_arg_key(call_node, idx), 1)

fn Sema.resolved_call_arg_is_default(self: Sema, call_node: i32, idx: i32) -> i32:
    if self.call_resolved_default_arg_keys.contains(self.resolved_call_arg_key(call_node, idx)): 1 else: 0

fn Sema.magic_ident_kind(self: Sema, node: i32) -> i32:
    if self.magic_ident_kinds.contains(node):
        return self.magic_ident_kinds.get(node).unwrap()
    SemaMagicIdentKind.NONE

fn Sema.get_resolved_call_arg(self: Sema, call_node: i32, idx: i32) -> i32:
    if self.call_resolved_args_map.contains(call_node):
        let packed = self.call_resolved_args_map.get(call_node).unwrap()
        let start = packed / 65536
        return self.call_resolved_args_data.get((start + idx) as i64)
    0

fn Sema.has_resolved_call_args(self: Sema, call_node: i32) -> i32:
    if self.call_resolved_args_map.contains(call_node): 1 else: 0

fn Sema.get_resolved_call_arg_count(self: Sema, call_node: i32) -> i32:
    if self.call_resolved_args_map.contains(call_node):
        let packed = self.call_resolved_args_map.get(call_node).unwrap()
        return packed % 65536
    0

// Walk AST verifying recursive calls are in tail position for @[tailrec] functions.
// in_tail=1 means this node is in tail position, in_tail=0 means it's not.
fn Sema.verify_tail_position(self: Sema, node: i32, fn_sym: i32, in_tail: i32):
    if node == 0:
        return
    let kind = self.ast.kind(node)

    // Recursive call or mutual @[tailrec] call: check it's in tail position
    if kind == NodeKind.NK_CALL:
        let callee = self.ast.get_data0(node)
        if self.ast.kind(callee) == NodeKind.NK_IDENT:
            let callee_sym = self.ast.get_data0(callee)
            // Self-recursive call
            if callee_sym == fn_sym and in_tail == 0:
                self.emit_error("recursive call is not in tail position (function is @[tailrec])", node)
            // Mutual call to another @[tailrec] function
            if callee_sym != fn_sym and in_tail == 0:
                if self.fn_decl_nodes.contains(callee_sym):
                    let callee_node = self.fn_decl_nodes.get(callee_sym).unwrap()
                    let callee_flags = self.ast.get_data2(callee_node)
                    if (callee_flags / FnFlags.TAILREC) % 2 == 1:
                        self.emit_error("call to @[tailrec] function is not in tail position", node)
        // Check args are NOT in tail position
        let extra_start = self.ast.get_data1(node)
        let arg_count = self.ast.get_data2(node)
        for ai in 0..arg_count:
            self.verify_tail_position(self.ast.get_extra(extra_start + ai), fn_sym, 0)
        return

    // Block: last expression (tail) inherits tail position, statements don't
    if kind == NodeKind.NK_BLOCK:
        let extra_start = self.ast.get_data0(node)
        let stmt_count = self.ast.get_data1(node)
        let tail = self.ast.get_data2(node)
        for si in 0..stmt_count:
            self.verify_tail_position(self.ast.get_extra(extra_start + si), fn_sym, 0)
        self.verify_tail_position(tail, fn_sym, in_tail)
        return

    // If-else: both branches inherit tail position
    if kind == NodeKind.NK_IF_EXPR:
        self.verify_tail_position(self.ast.get_data0(node), fn_sym, 0)  // condition
        self.verify_tail_position(self.ast.get_data1(node), fn_sym, in_tail)  // then
        self.verify_tail_position(self.ast.get_data2(node), fn_sym, in_tail)  // else
        return

    // Match: all arm bodies inherit tail position
    if kind == NodeKind.NK_MATCH:
        let subject = self.ast.get_data0(node)
        let arm_start = self.ast.get_data1(node)
        let arm_count = self.ast.get_data2(node)
        self.verify_tail_position(subject, fn_sym, 0)
        for ai in 0..arm_count:
            let arm = self.ast.get_extra(arm_start + ai)
            let arm_body = self.ast.get_data1(arm)
            self.verify_tail_position(arm_body, fn_sym, in_tail)
        return

    // Return: value inherits tail position
    if kind == NodeKind.NK_RETURN:
        self.verify_tail_position(self.ast.get_data0(node), fn_sym, 1)
        return

    // Loops, defer: NOT tail position for body
    if kind == NodeKind.NK_DO_WHILE:
        self.verify_tail_position(self.ast.get_data0(node), fn_sym, 0)
        self.verify_tail_position(self.ast.get_data1(node), fn_sym, 0)
        return
    if kind == NodeKind.NK_FOR or kind == NodeKind.NK_WHILE or kind == NodeKind.NK_LOOP:
        self.verify_tail_position(self.ast.get_data2(node), fn_sym, 0)
        return
    if kind == NodeKind.NK_DEFER or kind == NodeKind.NK_ERRDEFER:
        self.verify_tail_position(self.ast.get_data0(node), fn_sym, 0)
        return

    // Let binding: value is not in tail position
    if kind == NodeKind.NK_LET_BINDING:
        self.verify_tail_position(self.ast.get_data1(node), fn_sym, 0)
        return

    // Binary/unary/assign: operands are not in tail position
    if kind == NodeKind.NK_BINARY:
        self.verify_tail_position(self.ast.get_data1(node), fn_sym, 0)
        self.verify_tail_position(self.ast.get_data2(node), fn_sym, 0)
        return
    if kind == NodeKind.NK_MATCH_OP or kind == NodeKind.NK_NEG_MATCH_OP:
        self.verify_tail_position(self.ast.get_data0(node), fn_sym, 0)
        self.verify_tail_position(self.ast.get_data1(node), fn_sym, 0)
        return
    if kind == NodeKind.NK_UNARY:
        self.verify_tail_position(self.ast.get_data1(node), fn_sym, 0)
        return
    if kind == NodeKind.NK_ASSIGN:
        self.verify_tail_position(self.ast.get_data1(node), fn_sym, 0)
        return

fn Sema.fn_min_expected_arg_count(self: Sema, fn_sym: i32, fallback_expected: i32) -> i32:
    if fallback_expected <= 0:
        return fallback_expected
    if not self.fn_decl_nodes.contains(fn_sym):
        return fallback_expected
    let fn_node = self.fn_decl_nodes.get(fn_sym).unwrap()
    let meta = self.ast.find_fn_meta(fn_node)
    if meta < 0:
        return fallback_expected
    let meta_flags = self.ast.fn_meta_flags(meta)
    let required = meta_flags / FN_META_REQUIRED_UNIT
    if required < 0:
        return fallback_expected
    if required > fallback_expected:
        return fallback_expected
    required

fn Sema.check_expr_with_expected(self: Sema, node: i32, expected: TypeId) -> TypeId:
    let saved_expected = self.expected_expr_type
    let saved_has = self.has_expected_type
    self.expected_expr_type = expected
    self.has_expected_type = if expected != 0: 1 else: 0
    let out = self.check_expr(node)
    self.expected_expr_type = saved_expected
    self.has_expected_type = saved_has
    out

fn Sema.enum_has_variant(self: Sema, enum_tid: i32, variant_sym: i32) -> i32:
    let resolved = self.resolve_alias(enum_tid)
    let resolved_kind = self.get_type_kind(resolved)
    if resolved_kind == TypeKind.TY_GENERIC_INST:
        let base_sym = self.get_generic_inst_base(resolved)
        let base_tid = self.lookup_named_type_visible(base_sym)
        if base_tid != 0:
            return self.enum_has_variant(base_tid, variant_sym)
        return 0
    if resolved_kind != TypeKind.TY_ENUM:
        return 0
    let te_start = self.get_type_d1(resolved)
    let variant_count = self.get_type_d2(resolved)
    var pos = te_start
    for vi in 0..variant_count:
        let v_name = self.type_extra.get(pos as i64)
        let payload_count = self.type_extra.get((pos + 1) as i64)
        if v_name == variant_sym:
            return 1
        pos = pos + 2 + payload_count
    0

fn Sema.enum_pattern_owner_sym(self: Sema, type_id: i32) -> i32:
    if type_id == 0:
        return 0
    let resolved = self.resolve_alias(type_id)
    let resolved_kind = self.get_type_kind(resolved)
    if resolved_kind == TypeKind.TY_ENUM:
        return self.get_type_d0(resolved)
    if resolved_kind == TypeKind.TY_GENERIC_INST:
        let base_sym = self.get_generic_inst_base(resolved)
        let base_tid = self.lookup_named_type_visible(base_sym)
        if base_tid != 0:
            if self.get_type_kind(self.resolve_alias(base_tid)) == TypeKind.TY_ENUM:
                return base_sym
    0

fn Sema.enum_pattern_type(self: Sema, type_id: i32) -> i32:
    if type_id == 0:
        return 0
    let resolved = self.resolve_alias(type_id)
    let resolved_kind = self.get_type_kind(resolved)
    if resolved_kind == TypeKind.TY_ENUM:
        return resolved as i32
    if resolved_kind == TypeKind.TY_GENERIC_INST:
        let base_sym = self.get_generic_inst_base(resolved)
        let base_tid = self.lookup_named_type_visible(base_sym)
        if base_tid != 0:
            if self.get_type_kind(self.resolve_alias(base_tid)) == TypeKind.TY_ENUM:
                return resolved as i32
    0

fn Sema.enum_pattern_subject_matches_repr(self: Sema, subject_type: i32, enum_tid: i32) -> i32:
    if subject_type == 0 or enum_tid == 0:
        return 0
    let repr_ty = self.enum_repr_type(enum_tid)
    if repr_ty == 0:
        return 0
    if self.resolve_alias(subject_type) == self.resolve_alias(repr_ty):
        return 1
    0

fn Sema.resolve_variant_pattern_enum_type(self: Sema, node: i32, subject_type: i32, variant_name: i32) -> i32:
    if subject_type == 0:
        return 0
    let subject_enum_ty = self.enum_pattern_type(subject_type)
    let subject_enum_sym = if subject_enum_ty != 0: self.enum_pattern_owner_sym(subject_enum_ty) else: 0
    let qualifier_sym = self.ast.pattern_qualifier(node)
    if qualifier_sym != 0:
        let qualifier_tid = self.lookup_named_type_visible(qualifier_sym)
        if qualifier_tid == 0:
            self.emit_error("unknown type '" ++ self.pool_resolve(qualifier_sym) ++ "' in qualified enum pattern", node)
            return 0
        let qualifier_enum_ty = self.enum_pattern_type(qualifier_tid)
        let qualifier_enum_sym = if qualifier_enum_ty != 0: self.enum_pattern_owner_sym(qualifier_enum_ty) else: 0
        if qualifier_enum_sym == 0:
            self.emit_error("qualified enum pattern type '" ++ self.pool_resolve(qualifier_sym) ++ "' is not an enum", node)
            return 0
        if subject_enum_sym == 0 and self.enum_pattern_subject_matches_repr(subject_type, qualifier_enum_ty) == 0:
            self.emit_error("qualified enum pattern requires an enum subject", node)
            return 0
        if subject_enum_sym != 0 and qualifier_enum_sym != subject_enum_sym:
            self.emit_error("qualified enum pattern type '" ++ self.pool_resolve(qualifier_sym) ++ "' does not match subject type '" ++ self.pool_resolve(subject_enum_sym) ++ "'", node)
            return 0
        if self.enum_has_variant(qualifier_enum_ty, variant_name) == 0:
            self.emit_error("variant '" ++ self.pool_resolve(variant_name) ++ "' does not belong to enum '" ++ self.pool_resolve(qualifier_enum_sym) ++ "'", node)
            return 0
        return qualifier_enum_ty
    else if subject_enum_sym == 0:
        self.emit_error("variant pattern requires an enum subject", node)
        return 0
    if self.enum_has_variant(subject_enum_ty, variant_name) == 0:
        self.emit_error("variant '" ++ self.pool_resolve(variant_name) ++ "' does not belong to enum '" ++ self.pool_resolve(subject_enum_sym) ++ "'", node)
        return 0
    subject_enum_ty

fn Sema.pattern_variant_value_sym(self: Sema, node: i32, variant_name: i32) -> i32:
    let qualifier_sym = self.ast.pattern_qualifier(node)
    if qualifier_sym == 0:
        return variant_name
    let qual_name = self.pool_resolve(qualifier_sym) ++ "." ++ self.pool_resolve(variant_name)
    self.pool_intern(qual_name)

fn Sema.try_mark_value_pattern(self: Sema, node: i32, subject_type: i32, value_sym: i32) -> i32:
    if node == 0 or subject_type == 0 or value_sym == 0:
        return 0
    let value_ty = self.check_ident(value_sym, node)
    if value_ty == 0:
        return 1
    if self.types_compatible(subject_type as TypeId, value_ty as TypeId) == 0:
        let value_name = self.type_name(value_ty)
        let subject_name = self.type_name(subject_type)
        self.emit_error(
            "pattern value '" ++ self.pool_resolve(value_sym) ++
            "' has type '" ++ value_name ++
            "', which does not match subject type '" ++ subject_name ++ "'",
            node
        )
        return 1
    self.pattern_value_syms.insert(node, value_sym)
    1

fn Sema.check_dyn_trait_call_compat(self: Sema, fn_sym: i32, call_extra_start: i32, arg_types: Vec[i32], arg_count: i32, param_offset: i32) -> void:
    if not self.fn_decl_nodes.contains(fn_sym):
        return
    let fn_node = self.fn_decl_nodes.get(fn_sym).unwrap()
    let meta = self.ast.find_fn_meta(fn_node)
    if meta < 0:
        return

    let param_start = self.ast.fn_meta_param_start(meta)
    let param_count = self.ast.fn_meta_param_count(meta)
    for ai in 0..arg_count:
        let param_i = ai + param_offset
        if param_i >= param_count:
            break

        let p_type_node = self.ast.fn_param_type(param_start, param_i)
        let trait_sym = self.trait_object_from_type_node(p_type_node)
        if trait_sym == 0:
            continue

        let arg_ty = arg_types.get(ai as i64)
        let concrete_sym = self.dyn_arg_concrete_type_symbol(arg_ty)
        if concrete_sym == 0:
            self.emit_error("argument cannot be converted to dyn trait object", self.ast.get_extra(call_extra_start + ai))
            continue

        if self.select_trait_impl(concrete_sym, trait_sym) == 0:
            let type_str = self.pool_resolve(concrete_sym)
            let trait_str = self.pool_resolve(trait_sym)
            self.emit_error("type '" ++ type_str ++ "' does not implement trait '" ++ trait_str ++ "' required for dyn parameter", self.ast.get_extra(call_extra_start + ai))
            continue

        self.obligation_trait_syms.push(trait_sym)
        self.obligation_type_syms.push(concrete_sym)
        self.obligation_nodes.push(self.ast.get_extra(call_extra_start + ai))

fn Sema.check_generic_call(self: Sema, fn_sym: i32, fn_node: i32, arg_types: Vec[i32], arg_count: i32, call_node: i32) -> i32:
    let meta = self.ast.find_fn_meta(fn_node)
    if meta < 0:
        if arg_count > 0:
            return arg_types.get(0)
        return 0

    let param_start = self.ast.fn_meta_param_start(meta)
    let param_count = self.ast.fn_meta_param_count(meta)
    let tp_start = self.ast.fn_meta_tp_start(meta)
    let tp_count = self.ast.fn_meta_tp_count(meta)
    let ret_node = self.ast.fn_meta_ret(meta)

    if arg_count != param_count:
        self.emit_error("wrong argument count", call_node)

    self.clear_generic_substitution()

    // Infer type parameter substitutions from call argument types.
    for pi in 0..param_count:
        if pi >= arg_count:
            break
        let p_type_node = self.ast.fn_param_type(param_start, pi)
        let arg_ty = arg_types.get(pi as i64)
        self.bind_type_params_from_type_expr(p_type_node, arg_ty, tp_start, tp_count, call_node)

    // Obligation model: collect and solve trait bounds for each bound type parameter.
    self.check_generic_trait_bounds(tp_start, tp_count, call_node)
    // Also check where clause bounds if present
    let where_idx = self.ast.find_where_meta(fn_node)
    if where_idx >= 0:
        let where_start = self.ast.state.where_meta.get((where_idx + 1) as i64)
        let where_count = self.ast.state.where_meta.get((where_idx + 2) as i64)
        self.check_generic_trait_bounds(where_start, where_count, call_node)
    self.ensure_generic_substitutions(tp_start, tp_count, param_start, param_count, call_node)

    let spec_key = self.generic_specialization_key(fn_sym, tp_start, tp_count)
    if self.generic_specialization_cache.contains(spec_key):
        let cached = self.generic_specialization_cache.get(spec_key).unwrap()
        self.typed_expr_types.insert(call_node, cached)
        return cached

    let before_errors = self.diags.count_by_severity(DiagSeverity.Error)
    let tp_syms: Vec[i32] = Vec.new()
    let tp_sema_tys: Vec[i32] = Vec.new()
    var tp_pos = tp_start
    for ti in 0..tp_count:
        let tp_sym = self.ast.get_extra(tp_pos)
        let bound_count = self.ast.get_extra(tp_pos + 1)
        tp_syms.push(tp_sym)
        tp_sema_tys.push(self.lookup_generic_subst(tp_sym))
        tp_pos = tp_pos + 2 + bound_count
    let mono_sym = self.pool_intern(f"{self.pool_resolve(fn_sym)}__sema__{spec_key}")
    let _ = self.check_fn_body_concrete(fn_node, tp_syms, tp_sema_tys, mono_sym)
    if self.diags.count_by_severity(DiagSeverity.Error) != before_errors:
        return 0

    let resolved_ret = self.resolve_generic_return_type_node(ret_node, tp_start, tp_count)
    self.generic_specialization_cache.insert(sema_owned_text(spec_key), resolved_ret)
    self.typed_expr_types.insert(call_node, resolved_ret)
    resolved_ret

fn Sema.clear_generic_substitution(self: Sema):
    while self.generic_subst_param_syms.len() > 0:
        self.generic_subst_param_syms.pop()
        self.generic_subst_type_ids.pop()

fn Sema.lookup_generic_subst(self: Sema, param_sym: i32) -> i32:
    var i = self.generic_subst_param_syms.len() as i32 - 1
    while i >= 0:
        if self.generic_subst_param_syms.get(i as i64) == param_sym:
            return self.generic_subst_type_ids.get(i as i64)
        i = i - 1
    0

fn Sema.put_generic_subst(self: Sema, param_sym: i32, tid: i32, node: i32) -> void:
    if tid == 0:
        return
    let existing = self.lookup_generic_subst(param_sym)
    if existing != 0:
        if self.types_compatible(existing, tid) == 0:
            if self.arithmetic_result_type(existing, tid) == 0:
                let tp_name = self.pool_resolve(param_sym)
                let a = self.type_name(existing)
                let b = self.type_name(tid)
                self.emit_error("cannot infer a single type for '" ++ tp_name ++ "': saw '" ++ a ++ "' and '" ++ b ++ "'", node)
        return

    self.generic_subst_param_syms.push(param_sym)
    self.generic_subst_type_ids.push(tid)

fn Sema.type_param_exists(self: Sema, tp_start: i32, tp_count: i32, sym: i32) -> i32:
    var pos = tp_start
    for ti in 0..tp_count:
        let tp_name = self.ast.get_extra(pos)
        let bound_count = self.ast.get_extra(pos + 1)
        if tp_name == sym:
            return 1
        pos = pos + 2 + bound_count
    0

fn Sema.bind_type_params_from_type_expr(self: Sema, type_node: i32, arg_tid: i32, tp_start: i32, tp_count: i32, err_node: i32):
    if type_node == 0 or arg_tid == 0:
        return

    let kind = self.ast.kind(type_node)

    if kind == NodeKind.NK_TYPE_NAMED:
        let sym = self.ast.get_data0(type_node)
        if self.type_param_exists(tp_start, tp_count, sym) != 0:
            self.put_generic_subst(sym, arg_tid, err_node)
        return

    if kind == NodeKind.NK_TYPE_REF:
        let inner_node = self.ast.get_data0(type_node)
        let resolved = self.resolve_alias(arg_tid)
        if self.get_type_kind(resolved) == TypeKind.TY_REF:
            self.bind_type_params_from_type_expr(inner_node, self.get_type_d0(resolved), tp_start, tp_count, err_node)
        return

    if kind == NodeKind.NK_TYPE_PTR:
        let inner_node = self.ast.get_data0(type_node)
        let resolved = self.resolve_alias(arg_tid)
        if self.get_type_kind(resolved) == TypeKind.TY_PTR:
            self.bind_type_params_from_type_expr(inner_node, self.get_type_d0(resolved), tp_start, tp_count, err_node)
        return

    if kind == NodeKind.NK_TYPE_ARRAY:
        let inner_node = self.ast.get_data0(type_node)
        let resolved = self.resolve_alias(arg_tid)
        if self.get_type_kind(resolved) == TypeKind.TY_ARRAY:
            self.bind_type_params_from_type_expr(inner_node, self.get_type_d0(resolved), tp_start, tp_count, err_node)
        return

    if kind == NodeKind.NK_TYPE_SLICE:
        let inner_node = self.ast.get_data0(type_node)
        let resolved = self.resolve_alias(arg_tid)
        if self.get_type_kind(resolved) == TypeKind.TY_SLICE:
            self.bind_type_params_from_type_expr(inner_node, self.get_type_d0(resolved), tp_start, tp_count, err_node)
        return

    if kind == NodeKind.NK_TYPE_TUPLE:
        let inner_start = self.ast.get_data0(type_node)
        let inner_count = self.ast.get_data1(type_node)
        let resolved = self.resolve_alias(arg_tid)
        if self.get_type_kind(resolved) != TypeKind.TY_TUPLE:
            return
        let te_start = self.get_type_d0(resolved)
        let elem_count = self.get_type_d1(resolved)
        let pair_count = if inner_count < elem_count: inner_count else: elem_count
        for ei in 0..pair_count:
            let inner_node = self.ast.get_extra(inner_start + ei)
            let arg_elem = self.type_extra.get((te_start + ei) as i64)
            self.bind_type_params_from_type_expr(inner_node, arg_elem, tp_start, tp_count, err_node)
        return

    if kind == NodeKind.NK_TYPE_GENERIC:
        let base_sym = self.ast.get_data0(type_node)
        let resolved = self.resolve_alias(arg_tid)
        if self.get_type_kind(resolved) != TypeKind.TY_GENERIC_INST:
            return
        if self.get_generic_inst_base(resolved as i32) != base_sym:
            return
        let type_arg_start = self.ast.get_data1(type_node)
        let type_arg_count = self.ast.get_data2(type_node)
        let concrete_arg_count = self.get_generic_inst_arg_count(resolved as i32)
        let bind_count = if type_arg_count < concrete_arg_count: type_arg_count else: concrete_arg_count
        for gai in 0..bind_count:
            let param_arg_node = self.ast.get_extra(type_arg_start + gai)
            let concrete_arg_ty = self.get_generic_inst_arg(resolved as i32, gai)
            self.bind_type_params_from_type_expr(param_arg_node, concrete_arg_ty, tp_start, tp_count, err_node)
        return

fn Sema.generic_specialization_key(self: Sema, fn_sym: i32, tp_start: i32, tp_count: i32) -> str:
    var key = f"{fn_sym}"
    var pos = tp_start
    for ti in 0..tp_count:
        let tp_name = self.ast.get_extra(pos)
        let bound_count = self.ast.get_extra(pos + 1)
        let tp_subst = self.lookup_generic_subst(tp_name)
        key = key ++ f":{tp_name}={tp_subst}"
        pos = pos + 2 + bound_count
    key

fn Sema.check_generic_trait_bounds(self: Sema, tp_start: i32, tp_count: i32, call_node: i32):
    var pos = tp_start
    for ti in 0..tp_count:
        let tp_name = self.ast.get_extra(pos)
        let bound_count = self.ast.get_extra(pos + 1)
        let concrete_tid = self.lookup_generic_subst(tp_name)
        for bi in 0..bound_count:
            let trait_sym = self.ast.get_extra(pos + 2 + bi)
            let trait_name = self.pool_resolve(trait_sym)
            if trait_name == "type":
                continue
            if concrete_tid == 0:
                continue
            let concrete_sym = self.type_symbol_for_bounds(concrete_tid)
            if concrete_sym == 0:
                continue
            self.obligation_trait_syms.push(trait_sym)
            self.obligation_type_syms.push(concrete_sym)
            self.obligation_nodes.push(call_node)
            if self.select_trait_impl(concrete_sym, trait_sym) == 0:
                let type_str = self.pool_resolve(concrete_sym)
                let tp_str = self.pool_resolve(tp_name)
                self.emit_error("type '" ++ type_str ++ "' does not implement trait '" ++ trait_name ++ "' required by bound '" ++ tp_str ++ ": " ++ trait_name ++ "'", call_node)
        pos = pos + 2 + bound_count

fn Sema.resolve_generic_return_type_node(self: Sema, ret_node: i32, tp_start: i32, tp_count: i32) -> i32:
    if ret_node == 0:
        return self.ty_void as i32

    let kind = self.ast.kind(ret_node)

    if kind == NodeKind.NK_TYPE_NAMED:
        let sym = self.ast.get_data0(ret_node)
        if self.type_param_exists(tp_start, tp_count, sym) != 0:
            return self.lookup_generic_subst(sym)
        return self.resolve_type_expr(ret_node) as i32

    if kind == NodeKind.NK_TYPE_REF:
        let pointee = self.resolve_generic_return_type_node(self.ast.get_data0(ret_node), tp_start, tp_count)
        let is_mut = self.ast.get_data1(ret_node)
        return self.ensure_exact_type(TypeKind.TY_REF, pointee, is_mut, 0) as i32

    if kind == NodeKind.NK_TYPE_PTR:
        let pointee = self.resolve_generic_return_type_node(self.ast.get_data0(ret_node), tp_start, tp_count)
        let is_mut = self.ast.get_data1(ret_node)
        return self.ensure_exact_type(TypeKind.TY_PTR, pointee, is_mut, 0) as i32

    if kind == NodeKind.NK_TYPE_ARRAY:
        let elem = self.resolve_generic_return_type_node(self.ast.get_data0(ret_node), tp_start, tp_count)
        let size = self.ast.get_data1(ret_node)
        return self.ensure_exact_type(TypeKind.TY_ARRAY, elem, size, 0) as i32

    if kind == NodeKind.NK_TYPE_SLICE:
        let elem = self.resolve_generic_return_type_node(self.ast.get_data0(ret_node), tp_start, tp_count)
        return self.ensure_exact_type(TypeKind.TY_SLICE, elem, 0, 0) as i32

    if kind == NodeKind.NK_TYPE_TUPLE:
        let extra_start = self.ast.get_data0(ret_node)
        let elem_count = self.ast.get_data1(ret_node)
        let tuple_elems: Vec[i32] = Vec.new()
        for ei in 0..elem_count:
            let e_node = self.ast.get_extra(extra_start + ei)
            tuple_elems.push(self.resolve_generic_return_type_node(e_node, tp_start, tp_count))
        return self.ensure_tuple_type(tuple_elems, elem_count) as i32

    if kind == NodeKind.NK_TYPE_GENERIC:
        let gi_base = self.ast.get_data0(ret_node)
        let gi_extra = self.ast.get_data1(ret_node)
        let gi_argc = self.ast.get_data2(ret_node)
        let range_inclusive = self.canonical_range_type_constructor_inclusive(gi_base)
        if range_inclusive >= 0:
            if gi_argc != 1:
                self.emit_error("Range expects exactly one type argument", ret_node)
                return 0
            let elem_ty = self.resolve_generic_return_type_node(self.ast.get_extra(gi_extra), tp_start, tp_count)
            if elem_ty == 0:
                return 0
            return self.ensure_exact_type(TypeKind.TY_RANGE, elem_ty, range_inclusive, 0) as i32
        let final_base = self.canonical_symbol_by_text(gi_base)
        let gi_args: Vec[i32] = Vec.new()
        for gi in 0..gi_argc:
            let ga_node = self.ast.get_extra(gi_extra + gi)
            let ga_tid = self.resolve_generic_return_type_node(ga_node, tp_start, tp_count)
            if ga_tid == 0:
                return 0
            gi_args.push(ga_tid)
        return self.ensure_generic_inst_type(final_base, gi_args, gi_argc) as i32

    if kind == NodeKind.NK_TYPE_OPTIONAL:
        let inner = self.resolve_generic_return_type_node(self.ast.get_data0(ret_node), tp_start, tp_count)
        let opt_args: Vec[i32] = Vec.new()
        opt_args.push(inner)
        return self.ensure_generic_inst_type(self.syms.option, opt_args, 1) as i32

    // @TypeOf(expr) — resolve the inner expression's type.
    // In generic context, if the inner expr is an identifier matching a type param,
    // resolve to the substituted type.
    if kind == NodeKind.NK_TYPE_TYPEOF:
        let inner_node = self.ast.get_data0(ret_node)
        let inner_kind = self.ast.kind(inner_node)
        if inner_kind == NodeKind.NK_IDENT:
            let sym = self.ast.get_data0(inner_node)
            if self.type_param_exists(tp_start, tp_count, sym) != 0:
                return self.lookup_generic_subst(sym)
        // Fall through: try to type-check the expression in current scope
        let expr_type = self.check_expr(inner_node)
        if expr_type > 0:
            return expr_type as i32
        return 0

    self.resolve_type_expr(ret_node) as i32

fn Sema.selection_cache_key(self: Sema, type_sym: i32, trait_sym: i32) -> i64:
    sema_pair_key(type_sym, trait_sym)

fn Sema.blanket_guard_contains(self: Sema, key: i64) -> i32:
    var i = 0
    while i < self.blanket_guard.len() as i32:
        if self.blanket_guard.get(i as i64) == key:
            return 1
        i = i + 1
    0

fn Sema.select_trait_impl(self: Sema, type_sym: i32, trait_sym: i32) -> i32:
    let key = self.selection_cache_key(type_sym, trait_sym)
    if self.selection_cache.contains(key):
        return self.selection_cache.get(key).unwrap()

    // Cycle guard: if already resolving this pair, assume not found
    if self.blanket_guard_contains(key) != 0:
        return 0

    var found = 0
    // Check direct impls
    if self.impl_lookup.contains(type_sym):
        let idx = self.impl_lookup.get(type_sym).unwrap()
        let start = self.impl_starts.get(idx as i64)
        let count = self.impl_counts.get(idx as i64)
        for i in 0..count:
            if self.impl_extra.get((start + i) as i64) == trait_sym:
                found = 1

    // Check blanket impls: impl[T: Bound] Trait for T
    if found == 0:
        self.blanket_guard.push(key)
        for bi in 0..self.blanket_trait_syms.len() as i32:
            if self.blanket_trait_syms.get(bi as i64) != trait_sym:
                continue
            // For generic blanket impls (impl[T] Trait for Vec[T]),
            // only match if query type's base sym matches the target.
            let target_base = self.blanket_target_base_syms.get(bi as i64)
            if target_base != 0 and target_base != type_sym:
                continue
            if target_base != 0 and self.type_decl_type_param_count(type_sym) == 0:
                continue
            // Check if type_sym satisfies all bounds
            let b_start = self.blanket_bound_starts.get(bi as i64)
            let b_count = self.blanket_bound_counts.get(bi as i64)
            var all_satisfied = 1
            for bj in 0..b_count:
                let bound_trait = self.blanket_bound_syms.get((b_start + bj) as i64)
                let bound_ok = self.select_trait_impl(type_sym, bound_trait)
                if bound_ok == 0:
                    all_satisfied = 0
            if all_satisfied != 0:
                found = 1
        self.blanket_guard.pop()

    self.selection_cache.insert(key, found)
    found

// Check if a TypeKind.TY_GENERIC_INST type implements a trait via exact-match impls.
fn Sema.select_trait_impl_for_generic_inst(self: Sema, tid: i32, trait_sym: i32) -> i32:
    let gi_key = sema_pair_key(tid, trait_sym)
    if self.impl_generic_inst.contains(gi_key):
        return 1
    // Fall back to base symbol lookup (handles impl Trait for Vec without args)
    let base_sym = self.get_type_d0(tid)
    self.select_trait_impl(base_sym, trait_sym)

fn Sema.type_implements_trait(self: Sema, tid: i32, trait_sym: i32) -> i32:
    if tid == 0 or trait_sym == 0:
        return 0
    let resolved = self.resolve_alias(tid)
    if trait_sym == self.syms.copy_trait:
        return self.is_copy(resolved)
    if trait_sym == self.syms.drop:
        let drop_name = self.get_type_name(resolved)
        if drop_name != 0:
            return self.has_drop_method(drop_name)
        return 0
    if self.get_type_kind(resolved) == TypeKind.TY_GENERIC_INST:
        return self.select_trait_impl_for_generic_inst(resolved as i32, trait_sym)
    var type_sym = self.get_type_name(resolved)
    if type_sym == 0:
        type_sym = self.pool_intern(self.type_name(resolved as i32))
    if type_sym == 0:
        return 0
    self.select_trait_impl(type_sym, trait_sym)

fn Sema.type_has_default_value(self: Sema, tid: i32) -> i32:
    if tid == 0:
        return 0
    let resolved = self.resolve_alias(tid as TypeId)
    let tk = self.get_type_kind(resolved)
    if tk == TypeKind.TY_VOID or tk == TypeKind.TY_INT or tk == TypeKind.TY_FLOAT or tk == TypeKind.TY_BOOL or tk == TypeKind.TY_STR or tk == TypeKind.TY_PTR:
        return 1
    if tk == TypeKind.TY_ARRAY or tk == TypeKind.TY_RANGE:
        return self.type_has_default_value(self.get_type_d0(resolved))
    if tk == TypeKind.TY_TUPLE:
        let te_start = self.get_type_d0(resolved)
        let elem_count = self.get_type_d1(resolved)
        for ei in 0..elem_count:
            if self.type_has_default_value(self.type_extra.get((te_start + ei) as i64)) == 0:
                return 0
        return 1
    if tk == TypeKind.TY_GENERIC_INST:
        let base = self.get_generic_inst_base(resolved as i32)
        let arg_count = self.get_generic_inst_arg_count(resolved as i32)
        if base == self.syms.option or base == self.syms.vec or base == self.syms.hashmap or base == self.syms.hashset:
            return 1
        if base == self.syms.result and arg_count == 2:
            return self.type_has_default_value(self.get_generic_inst_arg(resolved as i32, 0))
    let default_trait = self.pool_lookup_symbol("Default")
    if default_trait != 0 and self.type_implements_trait(resolved as i32, default_trait) != 0:
        return 1
    0

// Resolve an associated type from a specific impl: find the impl block for (type_sym, trait_sym)
// and look up the associated type binding for assoc_sym.
fn Sema.resolve_impl_assoc_type(self: Sema, type_sym: i32, trait_sym: i32, assoc_sym: i32) -> i32:
    // Search all impl decls for matching (type_sym, trait_sym)
    for di in 0..self.ast.decl_count():
        let decl = self.ast.get_decl(di)
        if self.ast.kind(decl) != NodeKind.NK_IMPL_DECL:
            continue
        let impl_type = self.ast.get_data0(decl)
        let impl_trait = self.ast.get_data2(decl)
        if impl_type != type_sym or impl_trait != trait_sym:
            continue
        // Found the impl — read its associated type bindings
        let impl_extra_start = self.ast.get_data1(decl)
        let impl_at_count = self.ast.get_extra(impl_extra_start)
        for iai in 0..impl_at_count:
            let at_name = self.ast.get_extra(impl_extra_start + 1 + iai * 2)
            if at_name == assoc_sym:
                let at_type_node = self.ast.get_extra(impl_extra_start + 1 + iai * 2 + 1)
                return self.resolve_type_expr(at_type_node) as i32
        return 0
    0

fn Sema.type_symbol_for_bounds(self: Sema, tid: i32) -> i32:
    let resolved = self.resolve_alias(tid)
    let tk = self.get_type_kind(resolved)
    if tk == TypeKind.TY_STRUCT or tk == TypeKind.TY_ENUM or tk == TypeKind.TY_GENERIC_INST:
        return self.get_type_d0(resolved)
    if tk == TypeKind.TY_INT:
        let bits = self.get_type_d0(resolved)
        let signed = self.get_type_d1(resolved)
        let ptr_width = self.get_type_d2(resolved)
        if ptr_width != 0:
            if signed != 0:
                return self.pool_intern("isize")
            return self.pool_intern("usize")
        if bits == 8:
            if signed != 0:
                return self.pool_intern("i8")
            return self.pool_intern("u8")
        if bits == 16:
            if signed != 0:
                return self.pool_intern("i16")
            return self.pool_intern("u16")
        if bits == 32:
            if signed != 0:
                return self.pool_intern("i32")
            return self.pool_intern("u32")
        if bits == 64:
            if signed != 0:
                return self.pool_intern("i64")
            return self.pool_intern("u64")
        if bits == 128:
            if signed != 0:
                return self.pool_intern("i128")
            return self.pool_intern("u128")
        return 0
    if tk == TypeKind.TY_FLOAT:
        if self.get_type_d0(resolved) == 32:
            return self.pool_intern("f32")
        return self.pool_intern("f64")
    if tk == TypeKind.TY_BOOL:
        return self.pool_intern("bool")
    if tk == TypeKind.TY_STR:
        return self.pool_intern("str")
    0

fn Sema.method_owner_symbol_for_type(self: Sema, tid: i32) -> i32:
    let resolved = self.resolve_alias(tid)
    let named = self.get_type_name(resolved)
    if named != 0:
        return named
    self.dyn_arg_concrete_type_symbol(resolved as i32)

fn Sema.lookup_generic_method_fn(self: Sema, owner_sym: i32, method_sym: i32) -> i32:
    let existing = self.lookup_method_fn(owner_sym, method_sym)
    if existing != 0 and self.generic_fn_nodes.contains(existing):
        return existing
    let owner_name = self.pool_resolve(owner_sym)
    let method_name = self.pool_resolve(method_sym)
    if owner_name.len() == 0 or method_name.len() == 0:
        return 0
    let qualified = self.pool_intern(owner_name ++ "." ++ method_name)
    if self.generic_fn_nodes.contains(qualified):
        return qualified
    0

fn Sema.owner_inst_from_current_subst(self: Sema, owner_sym: i32, tp_start: i32, tp_count: i32) -> i32:
    if tp_count == 0:
        return self.lookup_named_type_visible(owner_sym)
    let args: Vec[i32] = Vec.new()
    var pos = tp_start
    for ti in 0..tp_count:
        let tp_name = self.ast.get_extra(pos)
        let bound_count = self.ast.get_extra(pos + 1)
        let subst = self.lookup_generic_subst(tp_name)
        if subst == 0:
            return 0
        args.push(subst)
        pos = pos + 2 + bound_count
    self.ensure_generic_inst_type(owner_sym, args, tp_count) as i32

fn Sema.resolve_type_node_with_current_subst(self: Sema, type_node: i32, self_ty: i32) -> i32:
    if type_node == 0:
        return self.ty_void as i32
    let kind = self.ast.kind(type_node)
    if kind == NodeKind.NK_TYPE_NAMED:
        let sym = self.ast.get_data0(type_node)
        if sym == self.syms.self_type and self_ty != 0:
            return self_ty
        let subst = self.lookup_generic_subst(sym)
        if subst != 0:
            return subst
        return self.resolve_type_expr(type_node) as i32
    if kind == NodeKind.NK_TYPE_REF:
        let inner = self.resolve_type_node_with_current_subst(self.ast.get_data0(type_node), self_ty)
        return self.ensure_exact_type(TypeKind.TY_REF, inner, self.ast.get_data1(type_node), 0) as i32
    if kind == NodeKind.NK_TYPE_PTR:
        let inner = self.resolve_type_node_with_current_subst(self.ast.get_data0(type_node), self_ty)
        return self.ensure_exact_type(TypeKind.TY_PTR, inner, self.ast.get_data1(type_node), self.ast.get_data2(type_node)) as i32
    if kind == NodeKind.NK_TYPE_ARRAY:
        let elem = self.resolve_type_node_with_current_subst(self.ast.get_data0(type_node), self_ty)
        return self.ensure_exact_type(TypeKind.TY_ARRAY, elem, self.ast.get_data1(type_node), 0) as i32
    if kind == NodeKind.NK_TYPE_SLICE:
        let elem = self.resolve_type_node_with_current_subst(self.ast.get_data0(type_node), self_ty)
        return self.ensure_exact_type(TypeKind.TY_SLICE, elem, 0, 0) as i32
    if kind == NodeKind.NK_TYPE_TUPLE:
        let extra_start = self.ast.get_data0(type_node)
        let elem_count = self.ast.get_data1(type_node)
        let elems: Vec[i32] = Vec.new()
        for ei in 0..elem_count:
            elems.push(self.resolve_type_node_with_current_subst(self.ast.get_extra(extra_start + ei), self_ty))
        return self.ensure_tuple_type(elems, elem_count) as i32
    if kind == NodeKind.NK_TYPE_GENERIC:
        let base_sym = self.ast.get_data0(type_node)
        let extra_start = self.ast.get_data1(type_node)
        let arg_count = self.ast.get_data2(type_node)
        let range_inclusive = self.canonical_range_type_constructor_inclusive(base_sym)
        if range_inclusive >= 0:
            if arg_count != 1:
                self.emit_error("Range expects exactly one type argument", type_node)
                return 0
            let elem_ty = self.resolve_type_node_with_current_subst(self.ast.get_extra(extra_start), self_ty)
            if elem_ty == 0:
                return 0
            return self.ensure_exact_type(TypeKind.TY_RANGE, elem_ty, range_inclusive, 0) as i32
        let final_base = self.canonical_symbol_by_text(base_sym)
        let args: Vec[i32] = Vec.new()
        for ai in 0..arg_count:
            let arg_ty = self.resolve_type_node_with_current_subst(self.ast.get_extra(extra_start + ai), self_ty)
            if arg_ty == 0:
                return 0
            args.push(arg_ty)
        return self.ensure_generic_inst_type(final_base, args, arg_count) as i32
    if kind == NodeKind.NK_TYPE_OPTIONAL:
        let inner = self.resolve_type_node_with_current_subst(self.ast.get_data0(type_node), self_ty)
        let args: Vec[i32] = Vec.new()
        args.push(inner)
        return self.ensure_generic_inst_type(self.syms.option, args, 1) as i32
    self.resolve_type_expr(type_node) as i32

fn Sema.generic_method_bind_owner_from_expected(self: Sema, owner_sym: i32) -> i32:
    if self.has_expected_type == 0 or self.expected_expr_type == 0:
        return 0
    let expected = self.resolve_alias(self.expected_expr_type)
    if self.get_type_kind(expected) != TypeKind.TY_GENERIC_INST:
        return 0
    if self.get_generic_inst_base(expected as i32) != owner_sym:
        return 0
    self.setup_generic_inst_substitution(expected as i32, owner_sym)

fn Sema.check_generic_method_call(self: Sema, owner_sym: i32, owner_type: i32, method_fn_sym: i32, is_static: i32, arg_types: Vec[i32], extra_start: i32, arg_count: i32, node: i32) -> i32:
    if method_fn_sym == 0 or not self.generic_fn_nodes.contains(method_fn_sym):
        return 0
    let fn_node = self.generic_fn_nodes.get(method_fn_sym).unwrap()
    let meta = self.ast.find_fn_meta(fn_node)
    if meta < 0:
        return 0
    if self.check_comptime_method_restriction(method_fn_sym, node) != 0:
        return 0
    if not self.type_decl_nodes.contains(owner_sym):
        return 0
    let td_node = self.type_decl_nodes.get(owner_sym).unwrap()
    let owner_tp_start = self.type_decl_tp_start(td_node)
    let owner_tp_count = self.type_decl_tp_count(td_node)
    let param_start = self.ast.fn_meta_param_start(meta)
    let param_count = self.ast.fn_meta_param_count(meta)
    let fn_tp_start = self.ast.fn_meta_tp_start(meta)
    let fn_tp_count = self.ast.fn_meta_tp_count(meta)

    self.clear_generic_substitution()
    let owner_resolved = self.resolve_alias(owner_type as TypeId)
    if owner_tp_count > 0:
        if self.get_type_kind(owner_resolved) == TypeKind.TY_GENERIC_INST and self.get_generic_inst_base(owner_resolved as i32) == owner_sym:
            let _ = self.setup_generic_inst_substitution(owner_resolved as i32, owner_sym)
        else if is_static != 0:
            let _ = self.generic_method_bind_owner_from_expected(owner_sym)
    if owner_tp_count > 0:
        var bind_param_offset = if is_static != 0: 0 else: 1
        for ai in 0..arg_count:
            let pi = ai + bind_param_offset
            if pi >= param_count:
                break
            let p_type_node = self.ast.fn_param_type(param_start, pi)
            let arg_ty = arg_types.get(ai as i64)
            self.bind_type_params_from_type_expr(p_type_node, arg_ty, owner_tp_start, owner_tp_count, node)
    if fn_tp_count > 0:
        let bind_param_offset2 = if is_static != 0: 0 else: 1
        for ai2 in 0..arg_count:
            let pi2 = ai2 + bind_param_offset2
            if pi2 >= param_count:
                break
            self.bind_type_params_from_type_expr(self.ast.fn_param_type(param_start, pi2), arg_types.get(ai2 as i64), fn_tp_start, fn_tp_count, node)

    var pos = owner_tp_start
    for ti in 0..owner_tp_count:
        let tp_name = self.ast.get_extra(pos)
        let bound_count = self.ast.get_extra(pos + 1)
        if self.lookup_generic_subst(tp_name) == 0:
            self.emit_error("cannot infer generic method type parameter '" ++ self.pool_resolve(tp_name) ++ "'", node)
            return 0
        pos = pos + 2 + bound_count
    var fn_pos = fn_tp_start
    for fti in 0..fn_tp_count:
        let tp_name2 = self.ast.get_extra(fn_pos)
        let bound_count2 = self.ast.get_extra(fn_pos + 1)
        if self.lookup_generic_subst(tp_name2) == 0:
            self.emit_error("cannot infer generic method type parameter '" ++ self.pool_resolve(tp_name2) ++ "'", node)
            return 0
        fn_pos = fn_pos + 2 + bound_count2
    let concrete_owner = if owner_tp_count > 0:
        self.owner_inst_from_current_subst(owner_sym, owner_tp_start, owner_tp_count)
    else:
        if owner_type != 0: owner_type else: self.lookup_named_type_visible(owner_sym)
    if concrete_owner == 0:
        return 0

    let param_offset = if is_static != 0: 0 else: 1
    let expected_args = param_count - param_offset
    if arg_count != expected_args:
        self.emit_error("wrong argument count", node)
    for ai3 in 0..arg_count:
        let pi3 = ai3 + param_offset
        if pi3 >= param_count:
            break
        let expected_ty = self.resolve_type_node_with_current_subst(self.ast.fn_param_type(param_start, pi3), concrete_owner)
        let actual_ty = arg_types.get(ai3 as i64)
        if expected_ty != 0 and actual_ty != 0:
            if self.types_compatible(expected_ty, actual_ty) == 0:
                if self.arithmetic_result_type(expected_ty, actual_ty) == 0:
                    self.emit_argument_type_mismatch(self.safe_symbol_text(method_fn_sym), method_fn_sym, ai3, pi3, expected_ty, actual_ty, self.ast.get_extra(extra_start + ai3))

    let ret_node = self.ast.fn_meta_ret(meta)
    let ret_ty = self.resolve_type_node_with_current_subst(ret_node, concrete_owner)
    if ret_ty != 0:
        self.typed_expr_types.insert(node, ret_ty)
    ret_ty

fn Sema.generic_constructor_return_type(self: Sema, owner_sym: i32, recv_type: i32) -> i32:
    let resolved = self.resolve_alias(recv_type as TypeId)
    if self.get_type_kind(resolved) == TypeKind.TY_GENERIC_INST:
        return resolved as i32
    if self.has_expected_type != 0 and self.expected_expr_type != 0:
        let expected = self.resolve_alias(self.expected_expr_type)
        if self.get_type_kind(expected) == TypeKind.TY_GENERIC_INST:
            if self.get_generic_inst_base(expected as i32) == owner_sym:
                return expected as i32
    recv_type

fn Sema.is_pending_generic_collection_base(self: Sema, base_sym: i32) -> i32:
    if base_sym == self.syms.vec or base_sym == self.syms.hashmap or base_sym == self.syms.hashset:
        return 1
    0

fn Sema.pending_generic_constructor_base(self: Sema, value: i32, val_type: i32) -> i32:
    if value == 0:
        return 0
    if self.ast.kind(value) == NodeKind.NK_GROUPED:
        return self.pending_generic_constructor_base(self.ast.get_data0(value), val_type)
    if self.ast.kind(value) == NodeKind.NK_IDENT:
        let src_sym = self.ast.get_data0(value)
        if self.pending_generic_binding_base.contains(src_sym):
            return self.pending_generic_binding_base.get(src_sym).unwrap()
        return 0
    if self.ast.kind(value) != NodeKind.NK_CALL:
        return 0
    let callee = self.ast.get_data0(value)
    if self.ast.kind(callee) != NodeKind.NK_FIELD_ACCESS:
        return 0
    let field = self.ast.get_data1(callee)
    let method_name = self.pool_resolve(field)
    if field != self.syms.new and method_name != "with_capacity":
        return 0
    let recv = self.ast.get_data0(callee)
    let base_sym = self.static_receiver_base_sym(recv)
    if self.is_pending_generic_collection_base(base_sym) == 0:
        return 0
    if base_sym != self.syms.vec and method_name == "with_capacity":
        return 0
    let resolved = self.resolve_alias(val_type as TypeId)
    if self.get_type_kind(resolved) != TypeKind.TY_STRUCT:
        return 0
    if self.get_type_d0(resolved) != base_sym:
        return 0
    base_sym

fn Sema.pending_generic_constructor_call_node(self: Sema, value: i32) -> i32:
    if value == 0:
        return 0
    if self.ast.kind(value) == NodeKind.NK_GROUPED:
        return self.pending_generic_constructor_call_node(self.ast.get_data0(value))
    if self.ast.kind(value) == NodeKind.NK_IDENT:
        let src_sym = self.ast.get_data0(value)
        if self.pending_generic_binding_call.contains(src_sym):
            return self.pending_generic_binding_call.get(src_sym).unwrap()
        return 0
    if self.ast.kind(value) == NodeKind.NK_CALL:
        return value
    0

fn Sema.register_pending_generic_binding(self: Sema, sym: i32, decl_node: i32, value: i32, val_type: i32):
    if self.is_discard_binding_symbol(sym) != 0:
        return
    let base_sym = self.pending_generic_constructor_base(value, val_type)
    if base_sym == 0:
        return
    self.pending_generic_binding_base.insert(sym, base_sym)
    let call_node = self.pending_generic_constructor_call_node(value)
    if call_node != 0:
        self.pending_generic_binding_call.insert(sym, call_node)
    if decl_node != 0:
        self.pending_generic_binding_decl.insert(sym, decl_node)

fn Sema.pending_generic_expected_type_for_base(self: Sema, expected: i32, base_sym: i32) -> i32:
    if expected == 0 or base_sym == 0:
        return 0
    var resolved = self.resolve_alias(expected as TypeId)
    let expected_kind = self.get_type_kind(resolved)
    if expected_kind == TypeKind.TY_REF or expected_kind == TypeKind.TY_PTR:
        resolved = self.resolve_alias(self.get_type_d0(resolved) as TypeId)
    if self.get_type_kind(resolved) != TypeKind.TY_GENERIC_INST:
        return 0
    if self.get_generic_inst_base(resolved as i32) != base_sym:
        return 0
    resolved as i32

fn Sema.settle_pending_generic_binding(self: Sema, sym: i32, concrete_type: i32, expr_node: i32) -> i32:
    if concrete_type == 0:
        return 0
    if not self.pending_generic_binding_base.contains(sym):
        return 0
    let base_sym = self.pending_generic_binding_base.get(sym).unwrap()
    let concrete = self.resolve_alias(concrete_type as TypeId)
    if self.get_type_kind(concrete) != TypeKind.TY_GENERIC_INST:
        return 0
    if self.get_generic_inst_base(concrete as i32) != base_sym:
        return 0
    let call_node = if self.pending_generic_binding_call.contains(sym): self.pending_generic_binding_call.get(sym).unwrap() else: 0
    for bi in 0..self.bind_names.len() as i32:
        let other_sym = self.bind_names.get(bi as i64)
        if not self.pending_generic_binding_base.contains(other_sym):
            continue
        if self.pending_generic_binding_base.get(other_sym).unwrap() != base_sym:
            continue
        let other_call = if self.pending_generic_binding_call.contains(other_sym): self.pending_generic_binding_call.get(other_sym).unwrap() else: 0
        if call_node != 0 and other_call != call_node:
            continue
        if call_node == 0 and other_sym != sym:
            continue
        self.bind_types.set_i32(bi as i64, concrete as i32)
        if self.pending_generic_binding_decl.contains(other_sym):
            let decl_node = self.pending_generic_binding_decl.get(other_sym).unwrap()
            self.typed_binding_types.insert(decl_node, concrete as i32)
        self.pending_generic_binding_base.remove(other_sym)
        self.pending_generic_binding_call.remove(other_sym)
        self.pending_generic_binding_decl.remove(other_sym)
    if call_node != 0:
        self.typed_expr_types.insert(call_node, concrete as i32)
    if expr_node != 0:
        self.typed_expr_types.insert(expr_node, concrete as i32)
    self.scope_update_type(sym, concrete as i32)
    concrete as i32

fn Sema.settle_pending_generic_binding_from_expected(self: Sema, sym: i32, expected: i32, expr_node: i32) -> i32:
    if not self.pending_generic_binding_base.contains(sym):
        return 0
    let base_sym = self.pending_generic_binding_base.get(sym).unwrap()
    let concrete = self.pending_generic_expected_type_for_base(expected, base_sym)
    if concrete == 0:
        return 0
    self.settle_pending_generic_binding(sym, concrete, expr_node)

fn Sema.infer_pending_generic_method_receiver(self: Sema, expr: i32, field: i32, arg_types: Vec[i32], arg_count: i32, node: i32) -> i32:
    let _ = node
    if expr == 0 or self.ast.kind(expr) != NodeKind.NK_IDENT:
        return 0
    let sym = self.ast.get_data0(expr)
    if not self.pending_generic_binding_base.contains(sym):
        return 0
    let base_sym = self.pending_generic_binding_base.get(sym).unwrap()
    let args: Vec[i32] = Vec.new()
    if base_sym == self.syms.vec:
        if (field == self.syms.push or field == self.syms.contains) and arg_count >= 1:
            let elem_ty = arg_types.get(0)
            if elem_ty != 0 and elem_ty != self.ty_void:
                args.push(elem_ty)
                let concrete = self.ensure_generic_inst_type(base_sym, args, 1) as i32
                return self.settle_pending_generic_binding(sym, concrete, expr)
        if field == self.syms.join:
            args.push(self.ty_str as i32)
            let concrete2 = self.ensure_generic_inst_type(base_sym, args, 1) as i32
            return self.settle_pending_generic_binding(sym, concrete2, expr)
    if base_sym == self.syms.hashset:
        if (field == self.syms.insert or field == self.syms.contains or field == self.syms.remove) and arg_count >= 1:
            let elem_ty2 = arg_types.get(0)
            if elem_ty2 != 0 and elem_ty2 != self.ty_void:
                args.push(elem_ty2)
                let concrete3 = self.ensure_generic_inst_type(base_sym, args, 1) as i32
                return self.settle_pending_generic_binding(sym, concrete3, expr)
    if base_sym == self.syms.hashmap:
        if field == self.syms.insert and arg_count >= 2:
            let key_ty = arg_types.get(0)
            let val_ty = arg_types.get(1)
            if key_ty != 0 and key_ty != self.ty_void and val_ty != 0 and val_ty != self.ty_void:
                args.push(key_ty)
                args.push(val_ty)
                let concrete4 = self.ensure_generic_inst_type(base_sym, args, 2) as i32
                return self.settle_pending_generic_binding(sym, concrete4, expr)
    0

fn Sema.ensure_vec_str_type(self: Sema) -> i32:
    let args: Vec[i32] = Vec.new()
    args.push(self.ty_str as i32)
    self.ensure_generic_inst_type(self.syms.vec, args, 1) as i32

fn Sema.ensure_handle_type_for(self: Sema, elem_ty: i32) -> i32:
    let found = self.find_generic_inst(self.syms.handle, elem_ty)
    if found != 0:
        return found
    let args: Vec[i32] = Vec.new()
    args.push(elem_ty)
    self.ensure_generic_inst_type(self.syms.handle, args, 1) as i32

fn Sema.ensure_slotmapslot_type_for(self: Sema, elem_ty: i32) -> i32:
    let found = self.find_generic_inst(self.syms.slotmapslot, elem_ty)
    if found != 0:
        return found
    let args: Vec[i32] = Vec.new()
    args.push(elem_ty)
    self.ensure_generic_inst_type(self.syms.slotmapslot, args, 1) as i32

fn Sema.ensure_option_ref_type_for(self: Sema, elem_ty: i32) -> i32:
    let ref_ty = self.ensure_exact_type(TypeKind.TY_REF, elem_ty, 0, 0) as i32
    if ref_ty == 0:
        return 0
    let found = self.find_generic_inst(self.syms.option, ref_ty)
    if found != 0:
        return found
    let args: Vec[i32] = Vec.new()
    args.push(ref_ty)
    self.ensure_generic_inst_type(self.syms.option, args, 1) as i32

fn Sema.ensure_option_type_for(self: Sema, elem_ty: i32) -> i32:
    let found = self.find_generic_inst(self.syms.option, elem_ty)
    if found != 0:
        return found
    let args: Vec[i32] = Vec.new()
    args.push(elem_ty)
    self.ensure_generic_inst_type(self.syms.option, args, 1) as i32

fn Sema.builtin_intrinsic_method_return_type(self: Sema, recv_type: i32, owner_sym: i32, field: i32) -> i32:
    if recv_type == 0:
        return 0
    let resolved = self.resolve_alias(recv_type as TypeId)
    let tk = self.get_type_kind(resolved)
    let method_name = self.pool_resolve(field)

    if owner_sym == self.syms.vec:
        if field == self.syms.new or method_name == "with_capacity":
            return self.generic_constructor_return_type(owner_sym, recv_type)
    if owner_sym == self.syms.hashmap:
        if field == self.syms.new:
            return self.generic_constructor_return_type(owner_sym, recv_type)
        if method_name == "increment":
            return self.ty_void as i32
    if owner_sym == self.syms.hashset:
        if field == self.syms.new:
            return self.generic_constructor_return_type(owner_sym, recv_type)
    if owner_sym == self.syms.slotmap:
        if field == self.syms.new:
            return self.generic_constructor_return_type(owner_sym, recv_type)
        if tk == TypeKind.TY_GENERIC_INST:
            let elem_ty = self.get_generic_inst_arg(resolved as i32, 0)
            if field == self.syms.insert:
                return self.ensure_handle_type_for(elem_ty)
            if field == self.syms.get:
                return self.ensure_option_ref_type_for(elem_ty)
            if field == self.syms.slot:
                return self.ensure_slotmapslot_type_for(elem_ty)
            if field == self.syms.get_disjoint:
                let slot_ty = self.ensure_slotmapslot_type_for(elem_ty)
                let elems: Vec[i32] = Vec.new()
                elems.push(slot_ty)
                elems.push(slot_ty)
                return self.ensure_tuple_type(elems, 2) as i32
            if field == self.syms.remove or field == self.syms.replace:
                return self.ensure_option_type_for(elem_ty)
            if field == self.syms.contains:
                return self.ty_bool as i32
            if field == self.syms.len:
                return self.ty_i64 as i32
    if owner_sym == self.syms.slotmapslot:
        if tk == TypeKind.TY_GENERIC_INST:
            if field == self.syms.get:
                return self.get_generic_inst_arg(resolved as i32, 0)
            if method_name == "set":
                return self.ty_void as i32
    if owner_sym == self.syms.option:
        if field == self.syms.is_some or field == self.syms.is_none:
            return self.ty_bool as i32
        if field == self.syms.unwrap or method_name == "unwrap_or":
            if tk == TypeKind.TY_GENERIC_INST:
                return self.get_generic_inst_arg(resolved as i32, 0)
        if field == self.syms.filter:
            return recv_type
    if owner_sym == self.syms.result:
        if field == self.syms.is_ok or field == self.syms.is_err:
            return self.ty_bool as i32
        if field == self.syms.unwrap or method_name == "unwrap_or":
            if tk == TypeKind.TY_GENERIC_INST:
                return self.get_generic_inst_arg(resolved as i32, 0)
    if self.pool_resolve(owner_sym) == "Atomic":
        if field == self.syms.new:
            return self.generic_constructor_return_type(owner_sym, recv_type)
        if method_name == "store":
            return self.ty_void as i32
        if method_name == "load" or method_name == "swap" or method_name == "fetch_add" or method_name == "fetch_sub" or method_name == "fetch_and" or method_name == "fetch_or" or method_name == "fetch_xor" or method_name == "fetch_min" or method_name == "fetch_max" or method_name == "compare_exchange" or method_name == "compare_exchange_weak":
            if tk == TypeKind.TY_GENERIC_INST:
                return self.get_generic_inst_arg(resolved as i32, 0)
    if self.pool_resolve(owner_sym) == "Sender":
        if method_name == "send" or method_name == "close":
            return self.ty_void as i32
    if self.pool_resolve(owner_sym) == "Receiver":
        if method_name == "recv":
            if tk == TypeKind.TY_GENERIC_INST:
                return self.get_generic_inst_arg(resolved as i32, 0)
            return self.ty_i32 as i32
        if method_name == "close":
            return self.ty_void as i32

    if tk == TypeKind.TY_STR:
        if field == self.syms.len:
            return self.ty_i64 as i32
        if method_name == "byte_at":
            return self.ty_i32 as i32
        if field == self.syms.contains or field == self.syms.starts_with or field == self.syms.ends_with:
            return self.ty_bool as i32
        if method_name == "find" or method_name == "index_of":
            return self.ty_i64 as i32
        if field == self.syms.trim or field == self.syms.to_lower or field == self.syms.to_upper or field == self.syms.lower or field == self.syms.upper or field == self.syms.replace or field == self.syms.slice or method_name == "repeat":
            return self.ty_str as i32
        if method_name == "split":
            return self.ensure_vec_str_type()
    if tk == TypeKind.TY_ARRAY:
        if field == self.syms.len:
            return self.ty_i32 as i32
    if tk == TypeKind.TY_INT:
        if method_name == "rotate_left" or method_name == "rotate_right" or method_name == "swap_bytes" or method_name == "bitreverse" or method_name == "min" or method_name == "max":
            return recv_type
        if method_name == "popcount" or method_name == "clz" or method_name == "ctz":
            return self.ty_i32 as i32
        if method_name == "abs":
            return self.unsigned_counterpart(recv_type)
    if tk == TypeKind.TY_FLOAT:
        if method_name == "min" or method_name == "max" or method_name == "abs" or method_name == "mul_add":
            return recv_type

    // HashMap.get and related C-backend intrinsics currently materialize an
    // encoded optional value with the payload's static type. Preserve the
    // existing surface methods until those intrinsics return real Option[T].
    if field == self.syms.is_some or field == self.syms.is_none:
        return self.ty_bool as i32
    if field == self.syms.unwrap:
        return recv_type
    0

fn Sema.method_expected_arg_type(self: Sema, recv_type: i32, field: i32, arg_index: i32) -> i32:
    if recv_type == 0:
        return 0
    let resolved = self.resolve_alias(recv_type as TypeId)
    if self.get_type_kind(resolved) != TypeKind.TY_GENERIC_INST:
        return 0
    let owner_sym = self.get_generic_inst_base(resolved as i32)
    let owner_name = self.pool_resolve(owner_sym)
    let method_name = self.pool_resolve(field)
    if owner_sym == self.syms.vec:
        if (field == self.syms.push or field == self.syms.contains) and arg_index == 0:
            return self.get_generic_inst_arg(resolved as i32, 0)
    if owner_sym == self.syms.hashset:
        if (field == self.syms.insert or field == self.syms.contains or field == self.syms.remove) and arg_index == 0:
            return self.get_generic_inst_arg(resolved as i32, 0)
    if owner_sym == self.syms.hashmap:
        if (field == self.syms.insert or field == self.syms.get or field == self.syms.contains or field == self.syms.remove or method_name == "increment") and arg_index == 0:
            return self.get_generic_inst_arg(resolved as i32, 0)
        if field == self.syms.insert and arg_index == 1:
            return self.get_generic_inst_arg(resolved as i32, 1)
    if owner_name == "Sender" and method_name == "send" and arg_index == 0:
        return self.get_generic_inst_arg(resolved as i32, 0)
    if (owner_sym == self.syms.option or owner_sym == self.syms.result) and method_name == "unwrap_or" and arg_index == 0:
        return self.get_generic_inst_arg(resolved as i32, 0)
    0

fn Sema.trait_object_from_type_node(self: Sema, type_node: i32) -> i32:
    if type_node == 0:
        return 0
    let kind = self.ast.kind(type_node)
    if kind == NodeKind.NK_TYPE_TRAIT_OBJ:
        return self.ast.get_data0(type_node)
    if kind == NodeKind.NK_TYPE_REF or kind == NodeKind.NK_TYPE_PTR:
        return self.trait_object_from_type_node(self.ast.get_data0(type_node))
    if kind == NodeKind.NK_TYPE_GENERIC:
        let base = self.ast.get_data0(type_node)
        if base != self.syms.box:
            return 0
        let extra_start = self.ast.get_data1(type_node)
        let arg_count = self.ast.get_data2(type_node)
        if arg_count != 1:
            return 0
        return self.trait_object_from_type_node(self.ast.get_extra(extra_start))
    0

fn Sema.dyn_trait_symbol_for_type(self: Sema, tid: i32) -> i32:
    if tid == 0:
        return 0
    let resolved = self.resolve_alias(tid)
    let tk = self.get_type_kind(resolved)
    if tk == TypeKind.TY_TRAIT_OBJ:
        return self.get_type_d0(resolved)
    if tk == TypeKind.TY_REF or tk == TypeKind.TY_PTR:
        return self.dyn_trait_symbol_for_type(self.get_type_d0(resolved))
    if tk == TypeKind.TY_GENERIC_INST:
        let base = self.get_generic_inst_base(resolved as i32)
        if base == self.syms.box and self.get_generic_inst_arg_count(resolved as i32) == 1:
            return self.dyn_trait_symbol_for_type(self.get_generic_inst_arg(resolved as i32, 0))
    0

fn Sema.find_dyn_trait_method_info(self: Sema, trait_sym: i32, method_sym: i32) -> SemaDynTraitMethodInfo:
    let trait_node = self.find_trait_decl_node(trait_sym)
    if trait_node == 0:
        return sema_dyn_trait_method_missing()

    let extra_start = self.ast.get_data1(trait_node)
    var pos = extra_start
    pos = pos + 2
    let assoc_count = self.ast.get_extra(pos)
    pos = pos + 1
    for ai in 0..assoc_count:
        let bound_count = self.ast.get_extra(pos + 1)
        pos = pos + 2 + bound_count + 1

    let method_count = self.ast.get_extra(pos)
    pos = pos + 1
    for mi in 0..method_count:
        let cur_method_sym = self.ast.get_extra(pos)
        pos = pos + 1
        let _method_flags = self.ast.get_extra(pos)
        pos = pos + 1
        let param_start = self.ast.get_extra(pos)
        pos = pos + 1
        let param_count = self.ast.get_extra(pos)
        pos = pos + 1
        let ret_node = self.ast.get_extra(pos)
        pos = pos + 1
        pos = pos + 1
        if cur_method_sym == method_sym:
            return SemaDynTraitMethodInfo {
                ok: 1,
                param_start,
                param_count,
                ret_node,
            }

    sema_dyn_trait_method_missing()

fn Sema.check_dyn_trait_method_call(self: Sema, trait_sym: i32, method_sym: i32, arg_types: Vec[i32], extra_start: i32, arg_count: i32, node: i32) -> i32:
    let info = self.find_dyn_trait_method_info(trait_sym, method_sym)
    if info.ok == 0:
        self.emit_error("unknown method '" ++ self.pool_resolve(method_sym) ++ "' for dyn trait '" ++ self.pool_resolve(trait_sym) ++ "'", node)
        return 0
    if self.ensure_trait_object_safe(trait_sym, node) == 0:
        return 0
    if info.param_count <= 0:
        self.emit_error("dyn trait method has no self parameter", node)
        return 0

    let expected_args = info.param_count - 1
    if arg_count != expected_args:
        self.emit_error("wrong argument count", node)

    for ai in 0..arg_count:
        let param_i = ai + 1
        if param_i >= info.param_count:
            break
        let p_type_node = self.ast.fn_param_type(info.param_start, param_i)
        if p_type_node != 0 and self.ast.kind(p_type_node) == NodeKind.NK_TYPE_NAMED and self.ast.get_data0(p_type_node) == self.syms.self_type:
            self.emit_error("dyn trait method parameter cannot mention Self outside the receiver", self.ast.get_extra(extra_start + ai))
            continue
        let expected_ty = self.resolve_type_expr(p_type_node) as i32
        let actual_ty = arg_types.get(ai as i64)
        if expected_ty != 0 and actual_ty != 0:
            if self.types_compatible(expected_ty as TypeId, actual_ty as TypeId) == 0:
                if self.arithmetic_result_type(expected_ty as TypeId, actual_ty as TypeId) == 0:
                    self.emit_argument_type_mismatch(self.pool_resolve(method_sym), method_sym, ai, param_i, expected_ty, actual_ty, self.ast.get_extra(extra_start + ai))

    if info.ret_node == 0:
        self.typed_expr_types.insert(node, self.ty_void as i32)
        return self.ty_void as i32
    if self.ast.kind(info.ret_node) == NodeKind.NK_TYPE_NAMED and self.ast.get_data0(info.ret_node) == self.syms.self_type:
        self.emit_error("dyn trait method return type cannot be Self", node)
        return 0
    let ret_ty = self.resolve_type_expr(info.ret_node) as i32
    if ret_ty != 0:
        self.typed_expr_types.insert(node, ret_ty)
    ret_ty

fn Sema.dyn_arg_concrete_type_symbol(self: Sema, tid: i32) -> i32:
    let resolved = self.resolve_alias(tid)
    let tk = self.get_type_kind(resolved)
    if tk == TypeKind.TY_REF or tk == TypeKind.TY_PTR:
        return self.type_symbol_for_bounds(self.get_type_d0(resolved))
    self.type_symbol_for_bounds(resolved)

// Set up generic substitution for a TypeKind.TY_GENERIC_INST type.
// Maps each type param name → concrete type arg from the generic instance.
// Returns 1 on success, 0 on failure (missing type decl, param mismatch, etc).
fn Sema.setup_generic_inst_substitution(self: Sema, gi_tid: i32, type_sym: i32) -> i32:
    if not self.type_decl_nodes.contains(type_sym):
        return 0
    let td_node = self.type_decl_nodes.get(type_sym).unwrap()
    let td_extra_start = self.ast.get_data1(td_node)
    let td_packed = self.ast.get_data2(td_node)
    let td_sub_kind = type_decl_sub_kind(td_packed)
    var td_tp_start = 0
    var td_tp_count = 0
    if td_sub_kind == TypeDeclKind.Struct:
        let fc = self.ast.get_extra(td_extra_start)
        let after = td_extra_start + 1 + fc * 4
        td_tp_start = self.ast.get_extra(after + 1)
        td_tp_count = self.ast.get_extra(after + 2)
    else if td_sub_kind == TypeDeclKind.Alias or td_sub_kind == TypeDeclKind.Distinct:
        td_tp_start = self.ast.get_extra(td_extra_start + 2)
        td_tp_count = self.ast.get_extra(td_extra_start + 3)
    else if td_sub_kind == TypeDeclKind.Enum:
        // For enum: extra=[variant_count, [var_name, payload_count, payload_type...]*, vis, tp_start, tp_count]
        let vc = self.ast.get_extra(td_extra_start)
        var epos = td_extra_start + 1
        for vi in 0..vc:
            epos = epos + 1  // var_name
            let pc = self.ast.get_extra(epos)
            epos = epos + 1  // payload_count
            epos = epos + pc  // skip payload type nodes
        // epos now points at vis
        td_tp_start = self.ast.get_extra(epos + 1)
        td_tp_count = self.ast.get_extra(epos + 2)
    if td_tp_count == 0:
        return 0
    let gi_arg_count = self.get_generic_inst_arg_count(gi_tid)
    if gi_arg_count != td_tp_count:
        return 0
    self.clear_generic_substitution()
    var tp_pos = td_tp_start
    for ti in 0..td_tp_count:
        let tp_name = self.ast.get_extra(tp_pos)
        let bound_count = self.ast.get_extra(tp_pos + 1)
        let arg_tid = self.get_generic_inst_arg(gi_tid, ti)
        self.put_generic_subst(tp_name, arg_tid, 0)
        tp_pos = tp_pos + 2 + bound_count
    1

fn Sema.substitute_method_return_for_generic_inst(self: Sema, gi_tid: i32, type_sym: i32, method_sym: i32, method_fn_sym: i32, sig_ret: i32) -> i32:
    // Set up type param → concrete arg substitution
    if self.setup_generic_inst_substitution(gi_tid, type_sym) == 0:
        return 0
    // Try substitute_type on the stored sig_ret first
    if sig_ret > 0:
        let subst_count = self.generic_subst_param_syms.len() as i32
        let result = self.substitute_type(sig_ret, self.generic_subst_param_syms, self.generic_subst_type_ids, subst_count)
        if result > 0:
            return result
    // Fallback: re-resolve from the method's return type AST node
    if method_fn_sym == 0 or not self.fn_decl_nodes.contains(method_fn_sym):
        return 0
    let fn_node = self.fn_decl_nodes.get(method_fn_sym).unwrap()
    let meta = self.ast.find_fn_meta(fn_node)
    if meta < 0:
        return 0
    let ret_node = self.ast.fn_meta_ret(meta)
    if ret_node == 0:
        return 0
    let td_node = self.type_decl_nodes.get(type_sym).unwrap()
    let td_extra_start = self.ast.get_data1(td_node)
    let td_packed = self.ast.get_data2(td_node)
    let td_sub_kind = type_decl_sub_kind(td_packed)
    var td_tp_start = 0
    var td_tp_count = 0
    if td_sub_kind == TypeDeclKind.Struct:
        let fc = self.ast.get_extra(td_extra_start)
        let after = td_extra_start + 1 + fc * 4
        td_tp_start = self.ast.get_extra(after + 1)
        td_tp_count = self.ast.get_extra(after + 2)
    else if td_sub_kind == TypeDeclKind.Alias or td_sub_kind == TypeDeclKind.Distinct:
        td_tp_start = self.ast.get_extra(td_extra_start + 2)
        td_tp_count = self.ast.get_extra(td_extra_start + 3)
    else if td_sub_kind == TypeDeclKind.Enum:
        let vc = self.ast.get_extra(td_extra_start)
        var epos = td_extra_start + 1
        for vi in 0..vc:
            epos = epos + 1
            let pc = self.ast.get_extra(epos)
            epos = epos + 1
            epos = epos + pc
        td_tp_start = self.ast.get_extra(epos + 1)
        td_tp_count = self.ast.get_extra(epos + 2)
    self.resolve_generic_return_type_node(ret_node, td_tp_start, td_tp_count)

// docs/mut.md Rev 8 §15.8 — builtins for which `lookup_method_fn` returns
// nothing but whose return value retains access to the receiver. Counterpart
// to the @[iter_of_self] attribute used for user-declared methods. The set
// is small and corresponds to types whose methods are intercepted by the
// builtin codegen path (see `if field == self.syms.iter` in check_method_call).
fn Sema.builtin_method_is_iter_of_self(self: Sema, type_name_sym: i32, field: i32) -> i32:
    if type_name_sym == self.syms.vec:
        if field == self.syms.iter or field == self.syms.keys or field == self.syms.iter_place or field == self.syms.iter_ref:
            return 1
    if type_name_sym == self.syms.hashmap:
        if field == self.syms.iter or field == self.syms.keys:
            return 1
    if type_name_sym == self.syms.hashset:
        if field == self.syms.iter:
            return 1
    0

fn Sema.builtin_method_requires_mutable_receiver(self: Sema, type_name_sym: i32, field: i32) -> i32:
    if type_name_sym == self.syms.vec:
        if field == self.syms.push or field == self.syms.set_i32 or field == self.syms.remove or field == self.syms.clear or field == self.syms.pop:
            return 1
    if type_name_sym == self.syms.hashmap:
        if field == self.syms.insert or field == self.syms.remove or field == self.syms.clear:
            return 1
    if type_name_sym == self.syms.hashset:
        if field == self.syms.insert or field == self.syms.remove or field == self.syms.clear:
            return 1
    0

fn Sema.is_shared_ref_like_receiver(self: Sema, recv_ty: i32) -> i32:
    if recv_ty == 0:
        return 0
    let resolved = self.resolve_alias(recv_ty as TypeId)
    let tk = self.get_type_kind(resolved)
    if tk != TypeKind.TY_REF and tk != TypeKind.TY_PTR:
        return 0
    if self.get_type_d1(resolved) != 0:
        return 0
    1

fn Sema.emit_builtin_mutable_receiver_error(self: Sema, type_name_sym: i32, field: i32, node: i32):
    let owner_name = self.pool_resolve(type_name_sym)
    let method_name = self.pool_resolve(field)
    self.emit_error("method '" ++ owner_name ++ "." ++ method_name ++ "' requires a mutable receiver", node)

fn Sema.check_method_call(self: Sema, callee: i32, extra_start: i32, arg_count: i32, node: i32) -> i32:
    let expr = self.ast.get_data0(callee)
    let field = self.ast.get_data1(callee)
    self.check_method_call_parts(expr, field, extra_start, arg_count, node)

fn Sema.check_method_call_parts(self: Sema, expr: i32, field: i32, extra_start: i32, arg_count: i32, node: i32) -> i32:
    var obj_type = self.check_expr(expr)
    let static_type_sym = self.static_receiver_base_sym(expr)
    let static_expr_kind = self.ast.kind(expr)
    if static_type_sym != 0 and self.static_receiver_type_is_known(expr) != 0 and (static_expr_kind == NodeKind.NK_IDENT or static_expr_kind == NodeKind.NK_TYPE_NAMED):
        let static_prim = self.primitive_type_by_sym(static_type_sym)
        if static_prim != 0:
            obj_type = static_prim as TypeId
        else:
            let static_named = self.lookup_named_type_visible(static_type_sym)
            if static_named != 0:
                obj_type = static_named as TypeId

    if obj_type != 0 and static_type_sym != 0 and self.static_receiver_type_is_known(expr) != 0:
        if self.is_tool_capability_type(obj_type as i32) and self.pool_resolve(field) == "__driver_new" and not self.can_access_tool_capability_internals():
            self.emit_error("tool capability constructor '" ++ self.pool_resolve(static_type_sym) ++ ".__driver_new' can only be called by the compiler driver", node)
            return 0
        let static_type_result = self.check_static_type_method_call(obj_type as i32, field, extra_start, arg_count, node)
        if static_type_result != 0:
            if static_type_result < 0:
                return 0
            return static_type_result
        if static_type_result < 0:
            return 0
    

    // Check all arguments (with expected-type propagation for Atomic ordering params)
    let mc_order_type = self.resolve_atomic_order_type(obj_type as i32)
    let mc_owner_sym_for_effect = self.method_owner_symbol_for_type(obj_type as i32)
    let mc_sig_idx_for_effect = if mc_owner_sym_for_effect != 0: self.lookup_method_sig(mc_owner_sym_for_effect, field) else: -1
    let arg_types: Vec[i32] = Vec.new()
    // docs/mut.md Rev 8 §15.8 — see check_call.
    let mc_iter_borrow_idxs: Vec[i32] = Vec.new()
    var mc_resolved_arg_count = arg_count
    if self.has_resolved_call_args(node) == 0 and self.ast.has_call_named_args(node) == 0 and arg_count == 0:
        var mc_unit_expected = self.atomic_method_expected_arg_type(mc_order_type, field, 0)
        if mc_unit_expected == 0:
            mc_unit_expected = self.method_expected_arg_type(obj_type as i32, field, 0)
        if mc_unit_expected == 0 and self.static_receiver_type_is_known(expr) != 0 and self.enum_has_variant(obj_type, field) != 0:
            let mc_payload_tys = self.enum_variant_payload_types(obj_type, field)
            if mc_payload_tys.len() as i32 == 1:
                mc_unit_expected = mc_payload_tys.get(0)
        if self.try_unit_elide_call_arg(node, arg_count, mc_unit_expected) != 0:
            mc_resolved_arg_count = 1
    let mc_has_resolved_args = self.has_resolved_call_args(node)
    for ai in 0..mc_resolved_arg_count:
        let mc_arg_node = if mc_has_resolved_args != 0: self.get_resolved_call_arg(node, ai) else: self.ast.get_extra(extra_start + ai)
        if mc_arg_node == 0:
            arg_types.push(0)
            continue
        if mc_arg_node < 0:
            let mc_bind_sym = 0 - mc_arg_node
            arg_types.push(self.scope_lookup(mc_bind_sym) as i32)
            continue

        let mc_is_closure = self.ast.kind(mc_arg_node) == NodeKind.NK_CLOSURE
        var mc_closure_arg_escapes = 0
        if mc_is_closure and mc_sig_idx_for_effect >= 0:
            let mc_param_i_for_effect = ai + 1
            if mc_param_i_for_effect < self.sig_get_param_count(mc_sig_idx_for_effect):
                let mc_param_eff = self.sig_param_effect(mc_sig_idx_for_effect, mc_param_i_for_effect)
                if (mc_param_eff & (EFF_ESCAPE_VALUE | EFF_ESCAPE_VIEW)) != 0:
                    mc_closure_arg_escapes = 1
        if mc_is_closure:
            self.closure_direct_arg_depth = self.closure_direct_arg_depth + 1
            self.closure_direct_arg_escape_flags.push(mc_closure_arg_escapes)
        var mc_expected = self.atomic_method_expected_arg_type(mc_order_type, field, ai)
        if mc_expected == 0:
            mc_expected = self.method_expected_arg_type(obj_type as i32, field, ai)
        let mc_arg_ty = if mc_expected != 0: self.check_expr_with_expected(mc_arg_node, mc_expected as TypeId) else: self.check_expr(mc_arg_node)
        arg_types.push(mc_arg_ty as i32)
        if mc_is_closure:
            self.closure_direct_arg_escape_flags.pop()
            self.closure_direct_arg_depth = self.closure_direct_arg_depth - 1
        let mc_iter_idx = self.maybe_register_iter_of_self_borrow(mc_arg_node)
        if mc_iter_idx >= 0:
            mc_iter_borrow_idxs.push(mc_iter_idx)
    var mc_ibi = mc_iter_borrow_idxs.len() as i32 - 1
    while mc_ibi >= 0:
        self.remove_borrow_at(mc_iter_borrow_idxs.get(mc_ibi as i64))
        mc_ibi = mc_ibi - 1

    // docs/mut.md Rev 8 §9.2 — closure capture conflict detection.
    self.check_closure_capture_conflicts(extra_start, mc_resolved_arg_count, mc_has_resolved_args, node)

    let inferred_pending_receiver = self.infer_pending_generic_method_receiver(expr, field, arg_types, mc_resolved_arg_count, node)
    if inferred_pending_receiver != 0:
        obj_type = inferred_pending_receiver as TypeId

    // Validate atomic ordering constraints (spec §14.17.1)
    if mc_order_type != 0:
        self.validate_atomic_ordering(field, extra_start, arg_count, node)

    // Task/ScopedTask surface methods (spec §14.7): cancel(), is_done().
    if field == self.syms.cancel or field == self.syms.is_done:
        if self.expr_is_task_value(expr) == 0 and self.expr_is_scoped_task_value(expr) == 0:
            return 0
        if mc_resolved_arg_count != 0:
            self.emit_error("task method expects zero arguments", node)
            return 0
        if field == self.syms.cancel:
            return self.ty_void as i32
        return self.ty_bool as i32

    if field == self.syms.track:
        if self.ast.kind(expr) != NodeKind.NK_IDENT or self.is_active_async_scope_symbol(self.ast.get_data0(expr)) == 0:
            self.emit_error("track() is only available inside async scope", node)
            return 0
        if mc_resolved_arg_count <= 0:
            self.emit_error("track() requires a Task value", node)
            return 0
        let task_arg = self.ast.get_extra(extra_start)
        if self.expr_is_task_value(task_arg) == 0:
            self.emit_error("track() requires a Task value", task_arg)
        return arg_types.get(0)

    if obj_type == 0:
        return 0

    let resolved = self.resolve_alias(obj_type)
    // Normalize method receivers through ref/ptr layers so builtin
    // method typing matches field access auto-deref behavior.
    var recv_type = self.auto_deref_ref_ptr_type(resolved)
    let dyn_trait_sym = self.dyn_trait_symbol_for_type(obj_type as i32)
    if dyn_trait_sym != 0:
        let dyn_ret = self.check_dyn_trait_method_call(dyn_trait_sym, field, arg_types, extra_start, mc_resolved_arg_count, node)
        if dyn_ret != 0:
            return dyn_ret
        return 0

    let enum_accessor_variant = self.enum_accessor_variant_for_method(recv_type as i32, field)
    if enum_accessor_variant != 0:
        let enum_accessor_kind = self.enum_accessor_kind_for_method(recv_type as i32, field)
        if mc_resolved_arg_count != 0:
            self.emit_error("enum accessor method expects zero arguments", node)
            return 0
        let enum_payloads = self.enum_variant_payload_types(recv_type as i32, enum_accessor_variant)
        if enum_accessor_kind == 2 or enum_accessor_kind == 3 or enum_accessor_kind == 4:
            if enum_payloads.len() as i32 == 0:
                self.emit_error("unit enum variant has no payload accessor; use .is_" ++ sema_accessor_snake_name(self.pool_resolve(enum_accessor_variant)) ++ "() instead", node)
                return 0
        if enum_accessor_kind == 2:
            let obj_resolved = self.resolve_alias(obj_type)
            let obj_kind = self.get_type_kind(obj_resolved)
            if obj_kind == TypeKind.TY_REF or obj_kind == TypeKind.TY_PTR:
                self.emit_error("by-value enum accessor requires an owned enum receiver; use the _ref accessor for borrowed receivers", node)
                return 0
            self.mark_moved_if_consumed(expr)
        else if enum_accessor_kind == 3:
            self.check_borrow_create(expr, BorrowKind.SHARED, node)
        else if enum_accessor_kind == 4:
            let recv_packed = self.classify_place(expr)
            let recv_kind = unpack_place_kind(recv_packed)
            let recv_mut_state = unpack_place_mut(recv_packed)
            let recv_via_ro_ref = self.place_base_is_read_only_ref(expr)
            if recv_kind == PlaceKind.PK_NotPlace:
                self.emit_error("mutable enum accessor requires a place receiver", node)
                return 0
            if recv_mut_state == PlaceMut.PM_ReadOnly or recv_via_ro_ref != 0:
                self.emit_error("cannot call mutable enum accessor through a read-only place", node)
                return 0
            self.check_mutation_against_views(expr, node)
            self.check_borrow_create(expr, BorrowKind.EXCLUSIVE, node)
        let enum_accessor_ret = self.enum_accessor_return_type(recv_type as i32, enum_accessor_variant, enum_accessor_kind)
        if enum_accessor_ret != 0:
            self.typed_expr_types.insert(node, enum_accessor_ret)
            return enum_accessor_ret
        return 0

    let type_name_sym = self.method_owner_symbol_for_type(recv_type as i32)
    if type_name_sym != 0:
        if self.builtin_method_requires_mutable_receiver(type_name_sym, field) != 0:
            if self.is_shared_ref_like_receiver(obj_type as i32) != 0:
                self.emit_builtin_mutable_receiver_error(type_name_sym, field, node)
                return 0
            var deref_expr = expr
            if self.ast.kind(deref_expr) == NodeKind.NK_GROUPED:
                deref_expr = self.ast.get_data0(deref_expr)
            if self.ast.kind(deref_expr) == NodeKind.NK_UNARY and self.ast.get_data0(deref_expr) == UnaryOp.UOP_DEREF:
                let deref_ty = self.resolve_alias(self.check_expr(self.ast.get_data1(deref_expr)) as TypeId)
                let deref_tk = self.get_type_kind(deref_ty)
                if (deref_tk == TypeKind.TY_PTR or deref_tk == TypeKind.TY_REF) and self.get_type_d1(deref_ty) == 0:
                    self.emit_builtin_mutable_receiver_error(type_name_sym, field, node)
                    return 0
            // docs/mut.md Rev 8 §15.17 — mutating method on a view-bound
            // for-loop variable (e.g., `for u in xs.iter(): u.push(1)`).
            let mc_root = self.place_root_sym(expr)
            if mc_root != 0 and self.scope_is_view_bound(mc_root) != 0:
                self.emit_error("cannot mutate through read-only view yielded by iterator (§15.17)", node)
        // docs/mut.md Rev 8 §5.1 — user-defined methods declared with
        // `mut self: Self` require a mutable place receiver. Warnings during
        // P7..P11; promoted to errors at P12 lockdown. Builtins are already
        // handled above via the hardcoded list.
        if self.method_has_mut_self_flag(type_name_sym, field) != 0:
            let recv_packed = self.classify_place(expr)
            let recv_kind = unpack_place_kind(recv_packed)
            let recv_mut_state = unpack_place_mut(recv_packed)
            // Receiver auto-deref through &T or *const T produces a read-only
            // place (§2.3) regardless of the binding's mutability.
            let recv_via_ro_ref = self.place_base_is_read_only_ref(expr)
            if recv_kind == PlaceKind.PK_NotPlace:
                self.emit_error("mutating method requires a place receiver (§15.3)", node)
            else if recv_mut_state == PlaceMut.PM_ReadOnly or recv_via_ro_ref != 0:
                self.emit_error("cannot call mutating method through a read-only place (§15.2)", node)
            else:
                // §15.6 — only check view-liveness when the receiver actually
                // is a mutable place we'd be mutating.
                self.check_mutation_against_views(expr, node)
            let ms_root = self.place_root_sym(expr)
            if ms_root != 0 and self.scope_is_view_bound(ms_root) != 0:
                self.emit_error("cannot mutate through read-only view yielded by iterator (§15.17)", node)
        else if self.method_has_move_self_flag(type_name_sym, field) != 0:
            // docs/mutability.md — move self receiver: the call consumes the
            // receiver binding. Invalidate it so subsequent uses are caught.
            if self.ast.kind(expr) == NodeKind.NK_IDENT:
                let recv_sym = self.ast.get_data0(expr)
                if self.scope_has(recv_sym) != 0:
                    self.scope_set_state(recv_sym, VarState.MOVED)
        else if type_name_sym != 0 and self.builtin_method_requires_mutable_receiver(type_name_sym, field) != 0:
            // §15.6 — view-liveness for builtin mutating methods (push, pop,
            // insert, etc.). The earlier hardcoded path already rejected
            // shared-ref / read-only receivers; here we additionally check
            // for outstanding SHARED borrows of the receiver place.
            self.check_mutation_against_views(expr, node)

        // §8.2 / §15.5 — indexed access conflict in a single mutating call.
        // If the receiver and any argument both reach through NK_INDEX into
        // the same base symbol, the call is conservatively rejected. Only
        // fires when the call is a known-mutating receiver (builtin or user
        // mut self), to avoid noise on read-only method calls.
        let is_mut_recv_call = self.method_has_mut_self_flag(type_name_sym, field) != 0 or self.builtin_method_requires_mutable_receiver(type_name_sym, field) != 0
        if is_mut_recv_call:
            let recv_idx_sym = self.expr_indexed_into(expr)
            if recv_idx_sym != 0:
                var ai = 0
                while ai < arg_count:
                    let arg_node = self.ast.get_extra(extra_start + ai)
                    if self.expr_indexed_into(arg_node) == recv_idx_sym:
                        self.emit_error("conflicting accesses through indexed base in the same call (§15.5)", node)
                        break
                    ai = ai + 1
            // §5.4 — nested mutating calls on the same simple binding.
            // Only fires when the outer receiver is a plain variable (not
            // a field projection like `self.field`), since field-projected
            // receivers have disjoint mutation targets.
            if self.ast.kind(expr) == NodeKind.NK_IDENT:
                let recv_root = self.ast.get_data0(expr)
                if recv_root != 0:
                    var ai = 0
                    while ai < arg_count:
                        let arg_node = self.ast.get_extra(extra_start + ai)
                        if self.expr_has_nested_mutating_call_on(arg_node, recv_root) != 0:
                            self.emit_error("nested mutating calls on the same place; bind the inner result to a local first (§5.4)", node)
                            break
                        ai = ai + 1

    // Static enum variant constructor: Shape.Rect(1, 2), Option[i32].Some(1)
    if self.static_receiver_type_is_known(expr) != 0 and self.enum_has_variant(obj_type, field) != 0:
        let payload_tys = self.enum_variant_payload_types(obj_type, field)
        let expected = payload_tys.len() as i32
        if mc_resolved_arg_count != expected:
            let owner_name = self.type_name(obj_type)
            let variant_name = self.pool_resolve(field)
            self.emit_error(f"enum variant constructor '{owner_name}.{variant_name}' expects {expected} argument(s), found {mc_resolved_arg_count}", node)
        for ai in 0..mc_resolved_arg_count:
            if ai >= expected:
                break
            let expected_ty = payload_tys.get(ai as i64)
            let arg_ty = arg_types.get(ai as i64)
            if expected_ty != 0 and arg_ty != 0:
                if self.types_compatible(expected_ty, arg_ty) == 0:
                if self.arithmetic_result_type(expected_ty, arg_ty) == 0:
                        let owner_name = self.type_name(obj_type)
                        let variant_name = self.pool_resolve(field)
                        let err_arg_node = if mc_has_resolved_args != 0: self.get_resolved_call_arg(node, ai) else: self.ast.get_extra(extra_start + ai)
                        self.emit_argument_type_mismatch(owner_name ++ "." ++ variant_name, field, ai, ai, expected_ty, arg_ty, if err_arg_node > 0: err_arg_node else: node)
        return obj_type as i32

    if self.static_receiver_type_is_known(expr) != 0 and self.pool_resolve(field) == "from_int":
        let enum_resolved = self.resolve_alias(obj_type)
        if self.disc_repr_types.contains(enum_resolved as i32):
            if arg_count != 1:
                self.emit_error("from_int() expects exactly one argument", node)
                return 0
            if arg_types.len() > 0:
                let from_int_arg_ty = arg_types.get(0)
                if from_int_arg_ty != 0 and self.get_type_kind(self.resolve_alias(from_int_arg_ty as TypeId)) != TypeKind.TY_INT:
                    self.emit_error("from_int() argument must be an integer", self.ast.get_extra(extra_start))
                    return 0
            let repr_ty = self.enum_repr_type(enum_resolved as i32)
            let opt_args: Vec[i32] = Vec.new()
            let opt_inner = if repr_ty != 0: repr_ty else: self.ty_i32 as i32
            opt_args.push(opt_inner)
            let opt_ty = self.ensure_generic_inst_type(self.syms.option, opt_args, 1) as i32
            self.typed_expr_types.insert(node, opt_ty)
            return opt_ty

    let is_static_receiver = if static_type_sym != 0 and self.static_receiver_type_is_known(expr) != 0: 1 else: 0
    if type_name_sym != 0:
        let generic_method_fn = self.lookup_generic_method_fn(type_name_sym, field)
        if generic_method_fn != 0:
            let generic_ret = self.check_generic_method_call(type_name_sym, recv_type as i32, generic_method_fn, is_static_receiver, arg_types, extra_start, mc_resolved_arg_count, node)
            return generic_ret

    if type_name_sym != 0:
        let method_fn_sym = self.lookup_method_fn(type_name_sym, field)
        let sig_idx = self.lookup_method_sig(type_name_sym, field)
        if sig_idx >= 0:
            if self.check_comptime_method_restriction(method_fn_sym, node) != 0:
                return 0
            if method_fn_sym != 0:
                self.comp_resolved.insert(node, method_fn_sym)
            let mc_ret = self.sig_return_type(sig_idx)
            // For TypeKind.TY_GENERIC_INST receivers, check arg types and substitute return type
            let mc_resolved_tk = self.get_type_kind(recv_type)
            if mc_resolved_tk == TypeKind.TY_GENERIC_INST:
                // Check argument types against substituted parameter types
                let mc_method_name = self.pool_resolve(type_name_sym) ++ "." ++ self.pool_resolve(field)
                if self.setup_generic_inst_substitution(recv_type, type_name_sym) != 0:
                    let mc_subst_count = self.generic_subst_param_syms.len() as i32
                    // Check argument types via substitute_type on stored sig param types
                    let mc_sig_pc = self.sig_get_param_count(sig_idx)
                    // sig params include self as first param; user args start at index 1
                    let mc_sig_poff = if mc_sig_pc > 0: 1 else: 0
                    for mc_ai in 0..mc_resolved_arg_count:
                        let mc_sig_pi = mc_ai + mc_sig_poff
                        if mc_sig_pi >= mc_sig_pc:
                            break
                        let mc_stored_ty = self.sig_param_type(sig_idx, mc_sig_pi)
                        if mc_stored_ty <= 0:
                            continue
                        let exp_ty = self.substitute_type(mc_stored_ty, self.generic_subst_param_syms, self.generic_subst_type_ids, mc_subst_count)
                        let arg_ty = arg_types.get(mc_ai as i64)
                        if exp_ty != 0 and arg_ty != 0:
                            let exp_r = self.resolve_alias(exp_ty)
                            if self.type_is_dyn_object(exp_r) == 0:
                                if self.types_compatible(exp_ty, arg_ty) == 0:
                                    if self.arithmetic_result_type(exp_ty, arg_ty) == 0:
                                        let mc_err_arg = if mc_has_resolved_args != 0: self.get_resolved_call_arg(node, mc_ai) else: self.ast.get_extra(extra_start + mc_ai)
                                        self.emit_argument_type_mismatch(mc_method_name, method_fn_sym, mc_ai, mc_sig_pi, exp_ty, arg_ty, if mc_err_arg > 0: mc_err_arg else: node)
                let mc_subst_ret = self.substitute_method_return_for_generic_inst(recv_type, type_name_sym, field, method_fn_sym, mc_ret)
                if mc_subst_ret != 0:
                    self.record_call_view_origins(node, sig_idx, 1, expr, extra_start, mc_resolved_arg_count, mc_has_resolved_args)
                    return mc_subst_ret
            self.record_call_view_origins(node, sig_idx, 1, expr, extra_start, mc_resolved_arg_count, mc_has_resolved_args)
            return mc_ret

    // For TypeKind.TY_GENERIC_INST receivers without a registered signature,
    // check argument types and return types for builtin generic methods
    if self.get_type_kind(recv_type) == TypeKind.TY_GENERIC_INST:
        let mc_call_name = self.pool_resolve(type_name_sym) ++ "." ++ self.pool_resolve(field)
        let mc_method_name_raw = self.pool_resolve(field)
        if (type_name_sym == self.syms.vec or type_name_sym == self.syms.hashmap or type_name_sym == self.syms.hashset or type_name_sym == self.syms.slotmap or self.pool_resolve(type_name_sym) == "Atomic") and field == self.syms.new:
            return recv_type as i32
        if type_name_sym == self.syms.vec and mc_method_name_raw == "with_capacity":
            return recv_type as i32
        if field == self.syms.push:
            // Vec.push(value: T) / HashSet.insert(value: T) — arg[0] must be T
            if arg_count >= 1:
                let elem_ty = self.get_generic_inst_arg(recv_type, 0)
                let a0_ty = arg_types.get(0)
                if elem_ty != 0 and a0_ty != 0:
                    if self.builtin_arg_type_compatible(elem_ty, a0_ty) == 0:
                            self.emit_argument_type_mismatch(mc_call_name, 0, 0, 0, elem_ty, a0_ty, self.ast.get_extra(extra_start))
        else if field == self.syms.insert:
            // HashMap.insert(key: K, value: V) — arg[0] must be K, arg[1] must be V
            let gi_argc = self.get_generic_inst_arg_count(recv_type)
            if gi_argc >= 2 and arg_count >= 2:
                let key_ty = self.get_generic_inst_arg(recv_type, 0)
                let val_ty = self.get_generic_inst_arg(recv_type, 1)
                let a0_ty = arg_types.get(0)
                let a1_ty = arg_types.get(1)
                if key_ty != 0 and a0_ty != 0:
                    if self.builtin_arg_type_compatible(key_ty, a0_ty) == 0:
                            self.emit_argument_type_mismatch(mc_call_name, 0, 0, 0, key_ty, a0_ty, self.ast.get_extra(extra_start))
                if val_ty != 0 and a1_ty != 0:
                    if self.builtin_arg_type_compatible(val_ty, a1_ty) == 0:
                            self.emit_argument_type_mismatch(mc_call_name, 0, 1, 1, val_ty, a1_ty, self.ast.get_extra(extra_start + 1))
        else if type_name_sym == self.syms.vec and (field == self.syms.get or field == self.syms.remove):
            // Vec.get(index) / Vec.remove(index) — arg[0] must be integer-ish
            if arg_count >= 1:
                let a0_ty = arg_types.get(0)
                if a0_ty != 0:
                    let index_ty = self.ty_i64 as i32
                    if self.builtin_arg_type_compatible(index_ty, a0_ty) == 0:
                            self.emit_argument_type_mismatch(mc_call_name, 0, 0, 0, index_ty, a0_ty, self.ast.get_extra(extra_start))
        else if type_name_sym == self.syms.vec and field == self.syms.contains:
            // Vec.contains(value: T) — arg[0] must be T
            if arg_count >= 1:
                let elem_ty = self.get_generic_inst_arg(recv_type, 0)
                let a0_ty = arg_types.get(0)
                if elem_ty != 0 and a0_ty != 0:
                    if self.builtin_arg_type_compatible(elem_ty, a0_ty) == 0:
                            self.emit_argument_type_mismatch(mc_call_name, 0, 0, 0, elem_ty, a0_ty, self.ast.get_extra(extra_start))
        else if type_name_sym == self.syms.hashmap and (field == self.syms.get or field == self.syms.contains or field == self.syms.remove):
            // HashMap.get/contains/remove(key: K) — arg[0] must be K
            if arg_count >= 1:
                let key_ty = self.get_generic_inst_arg(recv_type, 0)
                let a0_ty = arg_types.get(0)
                if key_ty != 0 and a0_ty != 0:
                    if self.builtin_arg_type_compatible(key_ty, a0_ty) == 0:
                            self.emit_argument_type_mismatch(mc_call_name, 0, 0, 0, key_ty, a0_ty, self.ast.get_extra(extra_start))
        else if type_name_sym == self.syms.hashset and (field == self.syms.insert or field == self.syms.contains or field == self.syms.remove):
            // HashSet.insert/contains/remove(value: T) — arg[0] must be T
            if arg_count >= 1:
                let elem_ty = self.get_generic_inst_arg(recv_type, 0)
                let a0_ty = arg_types.get(0)
                if elem_ty != 0 and a0_ty != 0:
                    if self.builtin_arg_type_compatible(elem_ty, a0_ty) == 0:
                            self.emit_argument_type_mismatch(mc_call_name, 0, 0, 0, elem_ty, a0_ty, self.ast.get_extra(extra_start))
        else if type_name_sym == self.syms.slotmap:
            let sm_elem_ty = self.get_generic_inst_arg(recv_type, 0)
            let sm_handle_ty = self.ensure_handle_type_for(sm_elem_ty)
            if field == self.syms.insert:
                if arg_count >= 1:
                    let a0_ty = arg_types.get(0)
                    if sm_elem_ty != 0 and a0_ty != 0:
                        if self.builtin_arg_type_compatible(sm_elem_ty, a0_ty) == 0:
                            self.emit_argument_type_mismatch(mc_call_name, 0, 0, 0, sm_elem_ty, a0_ty, self.ast.get_extra(extra_start))
            else if field == self.syms.get or field == self.syms.slot or field == self.syms.remove or field == self.syms.contains:
                if arg_count >= 1:
                    let h_ty = arg_types.get(0)
                    if sm_handle_ty != 0 and h_ty != 0:
                        if self.builtin_arg_type_compatible(sm_handle_ty, h_ty) == 0:
                            self.emit_argument_type_mismatch(mc_call_name, 0, 0, 0, sm_handle_ty, h_ty, self.ast.get_extra(extra_start))
            else if field == self.syms.replace:
                if arg_count >= 1:
                    let h_ty2 = arg_types.get(0)
                    if sm_handle_ty != 0 and h_ty2 != 0:
                        if self.builtin_arg_type_compatible(sm_handle_ty, h_ty2) == 0:
                            self.emit_argument_type_mismatch(mc_call_name, 0, 0, 0, sm_handle_ty, h_ty2, self.ast.get_extra(extra_start))
                if arg_count >= 2:
                    let v_ty = arg_types.get(1)
                    if sm_elem_ty != 0 and v_ty != 0:
                        if self.builtin_arg_type_compatible(sm_elem_ty, v_ty) == 0:
                            self.emit_argument_type_mismatch(mc_call_name, 0, 1, 1, sm_elem_ty, v_ty, self.ast.get_extra(extra_start + 1))
            else if field == self.syms.get_disjoint:
                for sm_hi in 0..2:
                    if arg_count > sm_hi:
                        let h_ty3 = arg_types.get(sm_hi as i64)
                        if sm_handle_ty != 0 and h_ty3 != 0:
                            if self.builtin_arg_type_compatible(sm_handle_ty, h_ty3) == 0:
                                self.emit_argument_type_mismatch(mc_call_name, 0, sm_hi, sm_hi, sm_handle_ty, h_ty3, self.ast.get_extra(extra_start + sm_hi))
        else if type_name_sym == self.syms.slotmapslot:
            if mc_method_name_raw == "set" and arg_count >= 1:
                let slot_elem_ty = self.get_generic_inst_arg(recv_type, 0)
                let set_arg_ty = arg_types.get(0)
                if slot_elem_ty != 0 and set_arg_ty != 0:
                    if self.builtin_arg_type_compatible(slot_elem_ty, set_arg_ty) == 0:
                        self.emit_argument_type_mismatch(mc_call_name, 0, 0, 0, slot_elem_ty, set_arg_ty, self.ast.get_extra(extra_start))
        // Return types for builtin generic methods
        if type_name_sym == self.syms.vec:
            if field == self.syms.push:
                return recv_type as i32
            if field == self.syms.set_i32 or field == self.syms.clear:
                return self.ty_void as i32
            if field == self.syms.get or field == self.syms.pop or field == self.syms.remove:
                return self.get_generic_inst_arg(recv_type, 0)
            if field == self.syms.len:
                return self.ty_i64 as i32
            if field == self.syms.contains:
                return self.ty_bool as i32
            if field == self.syms.join:
                return self.ty_str as i32
            if field == self.syms.iter:
                let iter_elem_ty = self.get_generic_inst_arg(recv_type, 0)
                let iter_tid = self.find_generic_inst(self.syms.veciter, iter_elem_ty)
                if iter_tid != 0:
                    return iter_tid
                let iter_args: Vec[i32] = Vec.new()
                iter_args.push(iter_elem_ty)
                return self.ensure_generic_inst_type(self.syms.veciter, iter_args, 1) as i32
            if field == self.syms.slot:
                let slot_elem_ty = self.get_generic_inst_arg(recv_type, 0)
                let slot_tid = self.find_generic_inst(self.syms.vecslot, slot_elem_ty)
                if slot_tid != 0:
                    return slot_tid
                let slot_args: Vec[i32] = Vec.new()
                slot_args.push(slot_elem_ty)
                return self.ensure_generic_inst_type(self.syms.vecslot, slot_args, 1) as i32
            if field == self.syms.get_disjoint:
                let gd_elem_ty = self.get_generic_inst_arg(recv_type, 0)
                var gd_slot_tid = self.find_generic_inst(self.syms.vecslot, gd_elem_ty)
                if gd_slot_tid == 0:
                    let gd_args: Vec[i32] = Vec.new()
                    gd_args.push(gd_elem_ty)
                    gd_slot_tid = self.ensure_generic_inst_type(self.syms.vecslot, gd_args, 1) as i32
                let gd_elems: Vec[i32] = Vec.new()
                gd_elems.push(gd_slot_tid)
                gd_elems.push(gd_slot_tid)
                return self.ensure_tuple_type(gd_elems, 2) as i32
            if field == self.syms.range_method:
                let vr_elem_ty = self.get_generic_inst_arg(recv_type, 0)
                let vr_tid = self.find_generic_inst(self.syms.vecrange, vr_elem_ty)
                if vr_tid != 0:
                    return vr_tid
                let vr_args: Vec[i32] = Vec.new()
                vr_args.push(vr_elem_ty)
                return self.ensure_generic_inst_type(self.syms.vecrange, vr_args, 1) as i32
            if field == self.syms.iter_ref:
                let iref_elem_ty = self.get_generic_inst_arg(recv_type, 0)
                let iref_tid = self.find_generic_inst(self.syms.veciterref, iref_elem_ty)
                if iref_tid != 0:
                    return iref_tid
                let iref_args: Vec[i32] = Vec.new()
                iref_args.push(iref_elem_ty)
                return self.ensure_generic_inst_type(self.syms.veciterref, iref_args, 1) as i32
            if field == self.syms.iter_place:
                let ip_elem_ty = self.get_generic_inst_arg(recv_type, 0)
                let ip_tid = self.find_generic_inst(self.syms.veciterplace, ip_elem_ty)
                if ip_tid != 0:
                    return ip_tid
                let ip_args: Vec[i32] = Vec.new()
                ip_args.push(ip_elem_ty)
                return self.ensure_generic_inst_type(self.syms.veciterplace, ip_args, 1) as i32
            if field == self.syms.filter:
                return recv_type as i32
            if field == self.syms.map:
                if arg_count >= 1:
                    let mapper_ty = self.resolve_alias(arg_types.get(0) as TypeId)
                    if self.get_type_kind(mapper_ty) == TypeKind.TY_FN:
                        let mapped_elem_ty = self.get_type_d2(mapper_ty)
                        let mapped_tid = self.find_generic_inst(self.syms.vec, mapped_elem_ty)
                        if mapped_tid != 0:
                            return mapped_tid
                        let mapped_args: Vec[i32] = Vec.new()
                        mapped_args.push(mapped_elem_ty)
                        return self.ensure_generic_inst_type(self.syms.vec, mapped_args, 1) as i32
                return recv_type as i32
            if field == self.syms.fold:
                if arg_count >= 1:
                    return arg_types.get(0)
                return self.get_generic_inst_arg(recv_type, 0)
        if type_name_sym == self.syms.vecslot:
            if field == self.syms.get:
                return self.get_generic_inst_arg(recv_type, 0)
            if mc_method_name_raw == "set":
                return self.ty_void as i32
        if type_name_sym == self.syms.vecrange:
            if field == self.syms.get:
                return self.get_generic_inst_arg(recv_type, 0)
            if mc_method_name_raw == "set":
                return self.ty_void as i32
            if mc_method_name_raw == "len":
                return self.ty_i64 as i32
        if type_name_sym == self.syms.veciterplace:
            if field == self.syms.next:
                let ip_elem_ty = self.get_generic_inst_arg(recv_type, 0)
                var vs_tid = self.find_generic_inst(self.syms.vecslot, ip_elem_ty)
                if vs_tid == 0:
                    let vs_args: Vec[i32] = Vec.new()
                    vs_args.push(ip_elem_ty)
                    vs_tid = self.ensure_generic_inst_type(self.syms.vecslot, vs_args, 1) as i32
                let opt_tid = self.find_generic_inst(self.syms.option, vs_tid)
                if opt_tid != 0:
                    return opt_tid
                let opt_args: Vec[i32] = Vec.new()
                opt_args.push(vs_tid)
                return self.ensure_generic_inst_type(self.syms.option, opt_args, 1) as i32
        if type_name_sym == self.syms.veciter:
            if field == self.syms.next:
                let next_elem_ty = self.get_generic_inst_arg(recv_type, 0)
                let next_tid = self.find_generic_inst(self.syms.option, next_elem_ty)
                if next_tid != 0:
                    return next_tid
                let next_args: Vec[i32] = Vec.new()
                next_args.push(next_elem_ty)
                return self.ensure_generic_inst_type(self.syms.option, next_args, 1) as i32
        if type_name_sym == self.syms.veciterref:
            if field == self.syms.next:
                let ref_elem_ty = self.get_generic_inst_arg(recv_type, 0)
                let ref_ty = self.ensure_exact_type(TypeKind.TY_REF, ref_elem_ty, 0, 0) as i32
                if ref_ty == 0:
                    return 0
                let ref_opt_tid = self.find_generic_inst(self.syms.option, ref_ty)
                if ref_opt_tid != 0:
                    return ref_opt_tid
                let ref_opt_args: Vec[i32] = Vec.new()
                ref_opt_args.push(ref_ty)
                return self.ensure_generic_inst_type(self.syms.option, ref_opt_args, 1) as i32
        if type_name_sym == self.syms.hashmap:
            if field == self.syms.insert or field == self.syms.clear:
                return self.ty_void as i32
            if mc_method_name_raw == "increment":
                return self.ty_void as i32
            if field == self.syms.get:
                return self.get_generic_inst_arg(recv_type, 1)
            if field == self.syms.contains:
                return self.ty_bool as i32
            if field == self.syms.remove:
                return self.get_generic_inst_arg(recv_type, 1)
            if field == self.syms.len:
                return self.ty_i64 as i32
            if field == self.syms.keys:
                let key_ty = self.get_generic_inst_arg(recv_type, 0)
                let key_vec_tid = self.find_generic_inst(self.syms.vec, key_ty)
                if key_vec_tid != 0:
                    return key_vec_tid
                let key_vec_args: Vec[i32] = Vec.new()
                key_vec_args.push(key_ty)
                return self.ensure_generic_inst_type(self.syms.vec, key_vec_args, 1) as i32
            if field == self.syms.entry:
                let ek = self.get_generic_inst_arg(recv_type, 0)
                let ev = self.get_generic_inst_arg(recv_type, 1)
                let entry_args: Vec[i32] = Vec.new()
                entry_args.push(ek)
                entry_args.push(ev)
                return self.ensure_generic_inst_type(self.syms.hashmapentry, entry_args, 2) as i32
        if type_name_sym == self.syms.hashmapentry:
            if field == self.syms.or_insert:
                return self.get_generic_inst_arg(recv_type, 1)
            if field == self.syms.get:
                return self.get_generic_inst_arg(recv_type, 1)
            if mc_method_name_raw == "set":
                return self.ty_void as i32
        if type_name_sym == self.syms.hashset:
            if field == self.syms.insert or field == self.syms.clear:
                return self.ty_void as i32
            if field == self.syms.contains or field == self.syms.remove:
                return self.ty_bool as i32
            if field == self.syms.len:
                return self.ty_i64 as i32
        if type_name_sym == self.syms.slotmap:
            let sm_elem_ret_ty = self.get_generic_inst_arg(recv_type, 0)
            if field == self.syms.insert:
                return self.ensure_handle_type_for(sm_elem_ret_ty)
            if field == self.syms.get:
                return self.ensure_option_ref_type_for(sm_elem_ret_ty)
            if field == self.syms.slot:
                return self.ensure_slotmapslot_type_for(sm_elem_ret_ty)
            if field == self.syms.get_disjoint:
                let sm_slot_ty = self.ensure_slotmapslot_type_for(sm_elem_ret_ty)
                let sm_tuple_elems: Vec[i32] = Vec.new()
                sm_tuple_elems.push(sm_slot_ty)
                sm_tuple_elems.push(sm_slot_ty)
                return self.ensure_tuple_type(sm_tuple_elems, 2) as i32
            if field == self.syms.remove or field == self.syms.replace:
                return self.ensure_option_type_for(sm_elem_ret_ty)
            if field == self.syms.contains:
                return self.ty_bool as i32
            if field == self.syms.len:
                return self.ty_i64 as i32
        if type_name_sym == self.syms.slotmapslot:
            if field == self.syms.get:
                return self.get_generic_inst_arg(recv_type, 0)
            if mc_method_name_raw == "set":
                return self.ty_void as i32
        if type_name_sym == self.syms.option:
            if field == self.syms.unwrap:
                return self.get_generic_inst_arg(recv_type, 0)
            if mc_method_name_raw == "unwrap_or":
                if mc_resolved_arg_count != 1:
                    self.emit_error("Option.unwrap_or() expects exactly one argument", node)
                    return 0
                return self.get_generic_inst_arg(recv_type, 0)
            if field == self.syms.is_some or field == self.syms.is_none:
                return self.ty_bool as i32
        if type_name_sym == self.syms.result:
            if field == self.syms.unwrap:
                return self.get_generic_inst_arg(recv_type, 0)
            if mc_method_name_raw == "unwrap_or":
                if mc_resolved_arg_count != 1:
                    self.emit_error("Result.unwrap_or() expects exactly one argument", node)
                    return 0
                return self.get_generic_inst_arg(recv_type, 0)
            if field == self.syms.is_ok or field == self.syms.is_err:
                return self.ty_bool as i32

    // Return types for primitive type methods
    let resolved_tk = self.get_type_kind(recv_type)
    if resolved_tk == TypeKind.TY_STR:
        if field == self.syms.len:
            return self.ty_i64 as i32
        let str_builtin_ret = self.builtin_intrinsic_method_return_type(recv_type as i32, type_name_sym, field)
        if str_builtin_ret != 0:
            return str_builtin_ret
    if resolved_tk == TypeKind.TY_ARRAY:
        if field == self.syms.len:
            return self.ty_i32 as i32

    // Static method call on a named type expression.
    if static_type_sym != 0 and self.static_receiver_type_is_known(expr) != 0:
        let method_fn_sym = self.lookup_method_fn(static_type_sym, field)
        let sig_idx = self.lookup_method_sig(static_type_sym, field)
        if sig_idx >= 0:
            if self.check_comptime_method_restriction(method_fn_sym, node) != 0:
                return 0
            if method_fn_sym != 0:
                self.comp_resolved.insert(node, method_fn_sym)
            return self.sig_return_type(sig_idx)

    let builtin_recv_type = if field == self.syms.unwrap or field == self.syms.is_some or field == self.syms.is_none:
        obj_type as i32
    else:
        recv_type as i32
    let builtin_ret = self.builtin_intrinsic_method_return_type(builtin_recv_type, type_name_sym, field)
    if builtin_ret != 0:
        self.typed_expr_types.insert(node, builtin_ret)
        return builtin_ret

    let receiver_name = self.type_name(obj_type as i32)
    let method_name = self.pool_resolve(field)
    self.emit_error("unknown method '" ++ method_name ++ "' for type '" ++ receiver_name ++ "'", node)
    0

fn Sema.is_intrinsic_fn_sym(self: Sema, fn_sym: i32) -> i32:
    if fn_sym == self.syms.channel or fn_sym == self.syms.send or fn_sym == self.syms.recv or fn_sym == self.syms.close:
        return 1
    if fn_sym == self.syms.todo or fn_sym == self.syms.unreachable:
        return 1
    if fn_sym == self.syms.src:
        return 1
    if fn_sym == self.syms.embed_file:
        return 1
    0

fn Sema.check_intrinsic_call(self: Sema, fn_sym: i32, node: i32, arg_types: Vec[i32], arg_count: i32) -> i32:
    let args_start = self.ast.get_data1(node)
    if fn_sym == self.syms.channel:
        if arg_count > 1:
            self.emit_error("Channel() expects zero or one capacity argument", node)
            return 0
        if arg_count == 1:
            let cap_ty = arg_types.get(0)
            if cap_ty != 0:
                let cap_kind = self.get_type_kind(self.resolve_alias(cap_ty))
                if cap_kind != TypeKind.TY_INT:
                    self.emit_error("Channel() capacity must be an integer", self.ast.get_extra(args_start))
                    return 0
        return self.ty_i64 as i32
    if fn_sym == self.syms.send:
        if arg_count != 2:
            self.emit_error("send() expects exactly two arguments", node)
            return 0
        let ch_ty = arg_types.get(0)
        if ch_ty != 0:
            let ch_kind = self.get_type_kind(self.resolve_alias(ch_ty))
            if ch_kind != TypeKind.TY_INT:
                self.emit_error("send() expects channel handle as integer value", self.ast.get_extra(args_start))
                return 0
        let payload_node = self.ast.get_extra(args_start + 1)
        if self.expr_is_ephemeral_value(payload_node) != 0 or self.expr_is_ephemeral_task(payload_node) != 0:
            self.emit_error("channel send requires Send value", payload_node)
            return 0
        let payload_ty = arg_types.get(1)
        if payload_ty != 0:
            let payload_kind = self.get_type_kind(self.resolve_alias(payload_ty))
            if payload_kind != TypeKind.TY_INT:
                self.emit_error("send() currently supports integer payloads", payload_node)
                return 0
        return self.ty_void as i32
    if fn_sym == self.syms.recv:
        if arg_count != 1:
            self.emit_error("recv() expects exactly one argument", node)
            return 0
        let ch_ty = arg_types.get(0)
        if ch_ty != 0:
            let ch_kind = self.get_type_kind(self.resolve_alias(ch_ty))
            if ch_kind != TypeKind.TY_INT:
                self.emit_error("recv() expects channel handle as integer value", self.ast.get_extra(args_start))
                return 0
        return self.ty_i32 as i32
    if fn_sym == self.syms.close:
        if arg_count != 1:
            self.emit_error("close() expects exactly one argument", node)
            return 0
        let ch_ty = arg_types.get(0)
        if ch_ty != 0:
            let ch_kind = self.get_type_kind(self.resolve_alias(ch_ty))
            if ch_kind != TypeKind.TY_INT:
                self.emit_error("close() expects channel handle as integer value", self.ast.get_extra(args_start))
                return 0
        return self.ty_void as i32
    if fn_sym == self.syms.todo or fn_sym == self.syms.unreachable:
        if arg_count > 1:
            self.emit_error("todo()/unreachable() expect zero or one message argument", node)
            return 0
        if arg_count == 1:
            let msg_ty = arg_types.get(0)
            if msg_ty != 0:
                if self.types_compatible(self.ty_str as i32, msg_ty) == 0:
                    self.emit_error("todo()/unreachable() message must be str-compatible", self.ast.get_extra(self.ast.get_data1(node)))
                    return 0
        return self.ty_never as i32
    if fn_sym == self.syms.src:
        if arg_count != 0:
            self.emit_error("src() takes no arguments", node)
        return self.ty_str as i32
    if fn_sym == self.syms.embed_file:
        if self.in_comptime_fn == 0:
            self.emit_error("embed_file() is only allowed in comptime context", node)
            return self.ty_str as i32
        if arg_count != 1:
            self.emit_error("embed_file() takes exactly one string argument", node)
            return self.ty_str as i32
        let path_ty = arg_types.get(0)
        if path_ty != 0 and self.types_compatible(self.ty_str as i32, path_ty) == 0:
            self.emit_error("embed_file() argument must be str-compatible", self.ast.get_extra(args_start))
            return self.ty_str as i32
        let path_node = self.ast.get_extra(args_start)
        let path_value = comptime_force_eval_expr(self as *mut Sema, self.ast, self.pool, path_node)
        if comptime_value_is_valid(path_value) == 0 or path_value.kind != ComptimeValueKind.CV_STR:
            self.emit_error("embed_file() argument must be a comptime string", path_node)
            return self.ty_str as i32
        let source_path = if self.current_module_path.len() > 0: self.current_module_path else: ""
        let resolved_path = sema_resolve_embed_file_path(source_path, path_value.text)
        if with_fs_file_exists(resolved_path) == 0:
            self.emit_error("embed_file: could not read '" ++ resolved_path ++ "'", node)
        return self.ty_str as i32
    0

fn Sema.static_receiver_base_sym(self: Sema, expr: i32) -> i32:
    if expr == 0:
        return 0
    let kind = self.ast.kind(expr)
    if kind == NodeKind.NK_IDENT or kind == NodeKind.NK_TYPE_NAMED or kind == NodeKind.NK_TYPE_GENERIC:
        return self.ast.get_data0(expr)
    // Handle Vec[i32].method() — NodeKind.NK_INDEX(NodeKind.NK_IDENT("Vec"), ...)
    if kind == NodeKind.NK_INDEX:
        let base = self.ast.get_data0(expr)
        if self.ast.kind(base) == NodeKind.NK_IDENT:
            return self.ast.get_data0(base)
    0

fn Sema.static_receiver_type_is_known(self: Sema, expr: i32) -> i32:
    let base_sym = self.static_receiver_base_sym(expr)
    if base_sym == 0:
        return 0
    if self.primitive_type_by_sym(base_sym) != 0:
        return 1
    if self.has_named_type_visible(base_sym) != 0:
        return 1
    0

fn Sema.type_reflection_field_count(self: Sema, tid: i32) -> i32:
    let resolved = self.resolve_alias(tid)
    let tk = self.get_type_kind(resolved)
    if tk == TypeKind.TY_STRUCT:
        return self.get_type_d2(resolved)
    if tk == TypeKind.TY_GENERIC_INST:
        let base_sym = self.get_generic_inst_base(resolved as i32)
        let base_tid = self.lookup_named_type_visible(base_sym)
        if base_tid != 0:
            if self.get_type_kind(self.resolve_alias(base_tid as TypeId)) == TypeKind.TY_STRUCT:
                return self.get_type_d2(self.resolve_alias(base_tid as TypeId))
    0

fn Sema.type_reflection_field_name(self: Sema, tid: i32, field_index: i32) -> i32:
    let resolved = self.resolve_alias(tid)
    let tk = self.get_type_kind(resolved)
    if tk == TypeKind.TY_STRUCT:
        let te_start = self.get_type_d1(resolved)
        let field_count = self.get_type_d2(resolved)
        if field_index < 0 or field_index >= field_count:
            return 0
        return self.type_extra.get((te_start + field_index * 3) as i64)
    if tk == TypeKind.TY_GENERIC_INST:
        let base_sym = self.get_generic_inst_base(resolved as i32)
        let base_tid = self.lookup_named_type_visible(base_sym)
        if base_tid != 0:
            let base_resolved = self.resolve_alias(base_tid as TypeId)
            if self.get_type_kind(base_resolved) == TypeKind.TY_STRUCT:
                let te_start = self.get_type_d1(base_resolved)
                let field_count = self.get_type_d2(base_resolved)
                if field_index < 0 or field_index >= field_count:
                    return 0
                return self.type_extra.get((te_start + field_index * 3) as i64)
    0

fn Sema.type_reflection_field_type(self: Sema, tid: i32, field_index: i32) -> i32:
    let resolved = self.resolve_alias(tid)
    let tk = self.get_type_kind(resolved)
    if tk == TypeKind.TY_STRUCT:
        let te_start = self.get_type_d1(resolved)
        let field_count = self.get_type_d2(resolved)
        if field_index < 0 or field_index >= field_count:
            return 0
        return self.type_extra.get((te_start + field_index * 3 + 1) as i64)
    if tk == TypeKind.TY_GENERIC_INST:
        let layout_sema = self
        return layout_sema.type_layout_generic_struct_field_type(resolved as i32, field_index)
    0

fn Sema.type_reflection_variant_base(self: Sema, tid: i32) -> i32:
    let resolved = self.resolve_alias(tid)
    let tk = self.get_type_kind(resolved)
    if tk == TypeKind.TY_ENUM:
        return resolved as i32
    if tk == TypeKind.TY_GENERIC_INST:
        let base_sym = self.get_generic_inst_base(resolved as i32)
        let base_tid = self.lookup_named_type_visible(base_sym)
        if base_tid != 0:
            let base_resolved = self.resolve_alias(base_tid as TypeId)
            if self.get_type_kind(base_resolved) == TypeKind.TY_ENUM:
                return base_resolved as i32
    0

fn Sema.type_reflection_variant_position(self: Sema, base_tid: i32, variant_index: i32) -> i32:
    let resolved = self.resolve_alias(base_tid)
    if self.get_type_kind(resolved) != TypeKind.TY_ENUM:
        return -1
    let te_start = self.get_type_d1(resolved)
    let variant_count = self.get_type_d2(resolved)
    if variant_index < 0 or variant_index >= variant_count:
        return -1
    var pos = te_start
    for vi in 0..variant_count:
        if vi == variant_index:
            return pos
        let payload_count = self.type_extra.get((pos + 1) as i64)
        pos = pos + 2 + payload_count
    -1

fn Sema.type_reflection_variant_count(self: Sema, tid: i32) -> i32:
    let base_tid = self.type_reflection_variant_base(tid)
    if base_tid == 0:
        return 0
    self.get_type_d2(base_tid)

fn Sema.type_reflection_variant_name(self: Sema, tid: i32, variant_index: i32) -> i32:
    let base_tid = self.type_reflection_variant_base(tid)
    if base_tid == 0:
        return 0
    let pos = self.type_reflection_variant_position(base_tid, variant_index)
    if pos < 0:
        return 0
    self.type_extra.get(pos as i64)

fn Sema.type_reflection_variant_payload_count(self: Sema, tid: i32, variant_index: i32) -> i32:
    let base_tid = self.type_reflection_variant_base(tid)
    if base_tid == 0:
        return 0
    let pos = self.type_reflection_variant_position(base_tid, variant_index)
    if pos < 0:
        return 0
    self.type_extra.get((pos + 1) as i64)

fn Sema.type_reflection_variant_discriminant(self: Sema, tid: i32, variant_index: i32) -> i64:
    let base_tid = self.type_reflection_variant_base(tid)
    if base_tid == 0:
        return 0
    if not self.disc_repr_types.contains(base_tid):
        return variant_index as i64
    let name_sym = self.type_reflection_variant_name(tid, variant_index)
    if name_sym == 0:
        return variant_index as i64
    let type_name_sym = self.get_type_d0(base_tid)
    if type_name_sym != 0:
        let qual_name = self.pool_resolve(type_name_sym) ++ "." ++ self.pool_resolve(name_sym)
        let qual_sym = self.pool_intern(qual_name)
        if self.disc_values.contains(qual_sym):
            return self.disc_values.get(qual_sym).unwrap() as i64
    if self.disc_values.contains(name_sym):
        return self.disc_values.get(name_sym).unwrap() as i64
    variant_index as i64

fn Sema.type_reflection_variant_payload_type(self: Sema, tid: i32, variant_index: i32, payload_index: i32) -> i32:
    let base_tid = self.type_reflection_variant_base(tid)
    if base_tid == 0:
        return 0
    let pos = self.type_reflection_variant_position(base_tid, variant_index)
    if pos < 0:
        return 0
    let payload_count = self.type_extra.get((pos + 1) as i64)
    if payload_index < 0 or payload_index >= payload_count:
        return 0
    let resolved = self.resolve_alias(tid)
    if self.get_type_kind(resolved) == TypeKind.TY_GENERIC_INST:
        let base_sym = self.get_generic_inst_base(resolved as i32)
        let name_sym = self.type_extra.get(pos as i64)
        let payloads = self.resolve_generic_enum_payload(resolved as i32, base_sym, name_sym, payload_count)
        if payload_index < payloads.len() as i32:
            let payload_tid = payloads.get(payload_index as i64)
            if payload_tid != 0:
                return payload_tid
    self.type_extra.get((pos + 2 + payload_index) as i64)

fn Sema.check_static_type_method_call(self: Sema, obj_type: i32, field: i32, extra_start: i32, arg_count: i32, node: i32) -> i32:
    let is_type_method =
        field == self.syms.fields or
        field == self.syms.variants or
        field == self.syms.name or
        field == self.syms.size or
        field == self.syms.align or
        field == self.syms.implements or
        field == self.syms.is_copy
    if not is_type_method:
        return 0

    if field == self.syms.name:
        if arg_count != 0:
            self.emit_error("type.name() takes no arguments", node)
            return -1
        self.typed_expr_types.insert(node, self.ty_str as i32)
        return self.ty_str as i32

    if field == self.syms.size or field == self.syms.align:
        if arg_count != 0:
            self.emit_error("type size/align methods take no arguments", node)
            return -1
        self.typed_expr_types.insert(node, self.ty_usize as i32)
        return self.ty_usize as i32

    if field == self.syms.implements:
        if arg_count != 1:
            self.emit_error("type.implements() expects exactly one trait argument", node)
            return -1
        let trait_node = self.ast.get_extra(extra_start)
        if trait_node == 0:
            self.emit_error("type.implements() requires a trait name", node)
            return -1
        let trait_kind = self.ast.kind(trait_node)
        if trait_kind != NodeKind.NK_IDENT and trait_kind != NodeKind.NK_TYPE_NAMED:
            self.emit_error("type.implements() requires a trait name", trait_node)
            return -1
        let trait_sym = self.ast.get_data0(trait_node)
        if not self.lang_trait_syms.contains(trait_sym) and not self.trait_lookup.contains(trait_sym):
            self.emit_error("unknown trait '" ++ self.pool_resolve(trait_sym) ++ "'", trait_node)
            return -1
        self.typed_expr_types.insert(node, self.ty_bool as i32)
        return self.ty_bool as i32

    if field == self.syms.is_copy:
        if arg_count != 0:
            self.emit_error("type.is_copy() takes no arguments", node)
            return -1
        self.typed_expr_types.insert(node, self.ty_bool as i32)
        return self.ty_bool as i32

    if field == self.syms.fields:
        if arg_count != 0:
            self.emit_error("type.fields() takes no arguments", node)
            return -1
        let resolved = self.resolve_alias(obj_type)
        let tk = self.get_type_kind(resolved)
        if tk != TypeKind.TY_STRUCT and tk != TypeKind.TY_GENERIC_INST:
            self.emit_error("type.fields() requires a struct type", node)
            return -1
        let field_count = self.type_reflection_field_count(obj_type)
        let result = self.ensure_exact_type(TypeKind.TY_ARRAY, self.ty_field_info as i32, field_count, 0)
        self.typed_expr_types.insert(node, result as i32)
        return result as i32

    let base_tid = self.type_reflection_variant_base(obj_type)
    if arg_count != 0:
        self.emit_error("type.variants() takes no arguments", node)
        return -1
    if base_tid == 0:
        self.emit_error("type.variants() requires an enum type", node)
        return -1
    let variant_count = self.type_reflection_variant_count(obj_type)
    let result = self.ensure_exact_type(TypeKind.TY_ARRAY, self.ty_variant_info as i32, variant_count, 0)
    self.typed_expr_types.insert(node, result as i32)
    result as i32

fn Sema.type_expr_contains_ref(self: Sema, node: i32) -> i32:
    if node == 0:
        return 0
    let kind = self.ast.kind(node)
    if kind == NodeKind.NK_TYPE_REF:
        return 1
    if kind == NodeKind.NK_TYPE_GENERIC:
        let extra_start = self.ast.get_data1(node)
        let arg_count = self.ast.get_data2(node)
        for ai in 0..arg_count:
            if self.type_expr_contains_ref(self.ast.get_extra(extra_start + ai)) != 0:
                return 1
        return 0
    if kind == NodeKind.NK_TYPE_PTR or kind == NodeKind.NK_TYPE_OPTIONAL:
        return self.type_expr_contains_ref(self.ast.get_data0(node))
    if kind == NodeKind.NK_TYPE_FN:
        let extra_start = self.ast.get_data0(node)
        let param_count = self.ast.get_data1(node)
        for pi in 0..param_count:
            if self.type_expr_contains_ref(self.ast.get_extra(extra_start + pi)) != 0:
                return 1
        return self.type_expr_contains_ref(self.ast.get_data2(node))
    if kind == NodeKind.NK_TYPE_TUPLE:
        let extra_start = self.ast.get_data0(node)
        let elem_count = self.ast.get_data1(node)
        for ei in 0..elem_count:
            if self.type_expr_contains_ref(self.ast.get_extra(extra_start + ei)) != 0:
                return 1
        return 0
    if kind == NodeKind.NK_TYPE_ARRAY or kind == NodeKind.NK_TYPE_SLICE:
        return self.type_expr_contains_ref(self.ast.get_data0(node))
    0

fn Sema.type_expr_is_collection_with_ref(self: Sema, node: i32) -> i32:
    if node == 0:
        return 0
    let kind = self.ast.kind(node)
    if kind == NodeKind.NK_TYPE_GENERIC:
        let extra_start = self.ast.get_data1(node)
        let arg_count = self.ast.get_data2(node)
        for ai in 0..arg_count:
            let arg_node = self.ast.get_extra(extra_start + ai)
            if self.type_expr_contains_ref(arg_node) != 0:
                return 1
            if self.type_expr_is_collection_with_ref(arg_node) != 0:
                return 1
        return 0
    if kind == NodeKind.NK_TYPE_PTR or kind == NodeKind.NK_TYPE_OPTIONAL:
        return self.type_expr_is_collection_with_ref(self.ast.get_data0(node))
    if kind == NodeKind.NK_TYPE_FN:
        let extra_start = self.ast.get_data0(node)
        let param_count = self.ast.get_data1(node)
        for pi in 0..param_count:
            if self.type_expr_is_collection_with_ref(self.ast.get_extra(extra_start + pi)) != 0:
                return 1
        return self.type_expr_is_collection_with_ref(self.ast.get_data2(node))
    if kind == NodeKind.NK_TYPE_TUPLE:
        let extra_start = self.ast.get_data0(node)
        let elem_count = self.ast.get_data1(node)
        for ei in 0..elem_count:
            if self.type_expr_is_collection_with_ref(self.ast.get_extra(extra_start + ei)) != 0:
                return 1
        return 0
    if kind == NodeKind.NK_TYPE_ARRAY or kind == NodeKind.NK_TYPE_SLICE:
        return self.type_expr_is_collection_with_ref(self.ast.get_data0(node))
    0

fn Sema.borrow_root_place(self: Sema, node: i32) -> i32:
    if node == 0:
        return 0
    let kind = self.ast.kind(node)
    if kind == NodeKind.NK_IDENT:
        return self.ast.get_data0(node)
    if kind == NodeKind.NK_FIELD_ACCESS:
        return self.borrow_root_place(self.ast.get_data0(node))
    if kind == NodeKind.NK_COMPUTED_FIELD_ACCESS:
        return self.borrow_root_place(self.ast.get_data0(node))
    if kind == NodeKind.NK_INDEX:
        return self.borrow_root_place(self.ast.get_data0(node))
    if kind == NodeKind.NK_GROUPED:
        return self.borrow_root_place(self.ast.get_data0(node))
    0

// Collect full field path from an expression into borrow_path_data.
// Returns (path_start, path_count) by storing the path and returning
// the start index. Fields are stored root-to-leaf order.
fn Sema.borrow_collect_path(self: Sema, node: i32) -> i32:
    let start = self.borrow_path_data.len() as i32
    self.borrow_collect_path_inner(node)
    self.borrow_path_data.len() as i32 - start

// §8.1 sentinel for constant-index path elements. Values < INDEX_PATH_BASE
// are constant indices encoded as INDEX_PATH_BASE - literal_value. A wildcard
// (non-constant index) uses INDEX_PATH_WILDCARD which overlaps with everything.
const INDEX_PATH_BASE: i32 = -100000
const INDEX_PATH_WILDCARD: i32 = -99999

fn Sema.borrow_collect_path_inner(self: Sema, node: i32):
    if node == 0:
        return
    let kind = self.ast.kind(node)
    if kind == NodeKind.NK_FIELD_ACCESS:
        // Recurse into base first (root-to-leaf ordering)
        self.borrow_collect_path_inner(self.ast.get_data0(node))
        self.borrow_path_data.push(self.ast.get_data1(node))
        return
    if kind == NodeKind.NK_COMPUTED_FIELD_ACCESS:
        self.borrow_collect_path_inner(self.ast.get_data0(node))
        return
    if kind == NodeKind.NK_INDEX:
        self.borrow_collect_path_inner(self.ast.get_data0(node))
        let index_expr = self.ast.get_data1(node)
        if self.ast.kind(index_expr) == NodeKind.NK_INT_LIT:
            let lit_val = self.ast.get_data0(index_expr)
            self.borrow_path_data.push(INDEX_PATH_BASE - lit_val)
        else:
            self.borrow_path_data.push(INDEX_PATH_WILDCARD)
        return
    // NodeKind.NK_IDENT, NodeKind.NK_GROUPED: no path element to add

fn Sema.borrow_field(self: Sema, node: i32) -> i32:
    if node == 0:
        return 0
    if self.ast.kind(node) == NodeKind.NK_FIELD_ACCESS:
        return self.ast.get_data1(node)
    0

// Two borrows are disjoint if their field paths diverge at some level.
// A zero-length path (whole variable) overlaps with everything.
// §8.1: index path elements use INDEX_PATH_BASE/WILDCARD sentinels.
fn Sema.are_borrows_disjoint_paths(self: Sema, start_a: i32, count_a: i32, start_b: i32, count_b: i32) -> i32:
    if count_a == 0 or count_b == 0:
        return 0
    let min_count = if count_a < count_b: count_a else: count_b
    var i = 0
    while i < min_count:
        let fa = self.borrow_path_data.get((start_a + i) as i64)
        let fb = self.borrow_path_data.get((start_b + i) as i64)
        if fa != fb:
            // Wildcard index overlaps with all indices at the same position
            if fa == INDEX_PATH_WILDCARD or fb == INDEX_PATH_WILDCARD:
                i = i + 1
                continue
            return 1
        i = i + 1
    // One is a prefix of the other — overlapping
    0

fn Sema.are_borrows_disjoint(self: Sema, new_field: i32, existing_field: i32) -> i32:
    if new_field == 0 or existing_field == 0:
        return 0
    if new_field != existing_field:
        return 1
    0

fn Sema.check_borrow_create(self: Sema, operand_node: i32, kind: i32, err_node: i32) -> void:
    let place = self.borrow_root_place(operand_node)
    if place == 0:
        return
    let new_field = self.borrow_field(operand_node)
    let path_start = self.borrow_path_data.len() as i32
    let path_count = self.borrow_collect_path(operand_node)

    var i = 0
    while i < self.borrow_kinds.len() as i32:
        let existing_place = self.borrow_places.get(i as i64)
        if existing_place != place:
            i = i + 1
            continue

        // Check disjointness using full field paths
        let ex_path_start = self.borrow_path_starts.get(i as i64)
        let ex_path_count = self.borrow_path_counts.get(i as i64)
        if self.are_borrows_disjoint_paths(path_start, path_count, ex_path_start, ex_path_count) != 0:
            i = i + 1
            continue

        let existing_kind = self.borrow_kinds.get(i as i64)
        if kind == BorrowKind.SHARED:
            if existing_kind == BorrowKind.EXCLUSIVE:
                self.emit_error("cannot borrow: already mutably borrowed", err_node)
                return
            i = i + 1
            continue

        // New exclusive borrow conflicts with any existing borrow.
        // Allow reborrowing: when the same place is reborrowed exclusively
        // for a nested call (e.g., &mut self passed to a helper taking &mut Self),
        // suppress the conflict. The original borrow is suspended during the call.
        if existing_kind == BorrowKind.EXCLUSIVE:
            // Reborrow: same place, both exclusive → allow (suspend original)
            i = i + 1
            continue
        self.emit_error("cannot borrow mutably: already borrowed", err_node)
        return

    self.borrow_kinds.push(kind)
    self.borrow_places.push(place)
    self.borrow_fields.push(new_field)
    self.borrow_refs.push(0)
    self.borrow_path_starts.push(path_start)
    self.borrow_path_counts.push(path_count)
    self.borrow_scope_depths.push(self.scope_starts.len() as i32)
    self.borrow_creation_nodes.push(err_node)

fn Sema.find_last_use_in_block(self: Sema, block_extra_start: i32, stmt_count: i32, start_index: i32, tail_node: i32, sym: i32) -> i32:
    var last_node = 0
    var si = start_index
    while si < stmt_count:
        let stmt = self.ast.get_extra(block_extra_start + si)
        if self.expr_uses_symbol(stmt, sym) != 0:
            last_node = stmt
        si = si + 1
    if tail_node != 0 and self.expr_uses_symbol(tail_node, sym) != 0:
        last_node = tail_node
    last_node

fn Sema.check_mutation_against_views(self: Sema, place_node: i32, err_node: i32):
    let place = self.borrow_root_place(place_node)
    if place == 0:
        return
    let path_start = self.borrow_path_data.len() as i32
    let path_count = self.borrow_collect_path(place_node)
    var i = 0
    while i < self.borrow_kinds.len() as i32:
        let existing_place = self.borrow_places.get(i as i64)
        if existing_place != place:
            i = i + 1
            continue
        let existing_kind = self.borrow_kinds.get(i as i64)
        if existing_kind != BorrowKind.SHARED:
            i = i + 1
            continue
        let ref_sym = self.borrow_refs.get(i as i64)
        if ref_sym == 0:
            i = i + 1
            continue
        let ex_path_start = self.borrow_path_starts.get(i as i64)
        let ex_path_count = self.borrow_path_counts.get(i as i64)
        if self.are_borrows_disjoint_paths(path_start, path_count, ex_path_start, ex_path_count) != 0:
            i = i + 1
            continue
        let place_name = self.pool_resolve(place)
        let ref_name = self.pool_resolve(ref_sym)
        let creation_node = self.borrow_creation_nodes.get(i as i64)
        let last_use = self.find_last_use_in_block(self.current_block_extra_start, self.current_block_stmt_count, self.current_block_stmt_index + 1, self.current_block_tail, ref_sym)
        let mutation_start = self.ast.get_start(err_node)
        let mutation_end = self.ast.get_end(err_node)
        let diag = Diagnostic.err("cannot mutate `" ++ place_name ++ "` while read-only view `" ++ ref_name ++ "` is live (§15.6)", Span { file: self.local_file_id, start: mutation_start, end: mutation_end })
        if creation_node != 0:
            let cr_start = self.ast.get_start(creation_node)
            let cr_end = self.ast.get_end(creation_node)
            diag.add_label(Span { file: self.local_file_id, start: cr_start, end: cr_end }, "view created here")
        if last_use != 0:
            let lu_start = self.ast.get_start(last_use)
            let lu_end = self.ast.get_end(last_use)
            diag.add_label(Span { file: self.local_file_id, start: lu_start, end: lu_end }, "view used here")
        self.diags.emit(diag)
        return

// Register a borrow with pre-computed place/kind/field/path.
// Used by closure capture registration.
fn Sema.check_borrow_create_direct(self: Sema, place: i32, kind: i32, field: i32, path_start: i32, path_count: i32, err_node: i32) -> void:
    var i = 0
    while i < self.borrow_kinds.len() as i32:
        let existing_place = self.borrow_places.get(i as i64)
        if existing_place != place:
            i = i + 1
            continue
        let ex_path_start = self.borrow_path_starts.get(i as i64)
        let ex_path_count = self.borrow_path_counts.get(i as i64)
        if self.are_borrows_disjoint_paths(path_start, path_count, ex_path_start, ex_path_count) != 0:
            i = i + 1
            continue
        let existing_kind = self.borrow_kinds.get(i as i64)
        if kind == BorrowKind.SHARED:
            if existing_kind == BorrowKind.EXCLUSIVE:
                self.emit_error("cannot borrow: already mutably borrowed", err_node)
                return
            i = i + 1
            continue
        if existing_kind == BorrowKind.EXCLUSIVE:
            self.emit_error("cannot borrow mutably: already mutably borrowed", err_node)
        else if self.borrow_refs.get(i as i64) == -1:
            let place_name = self.pool_resolve(place)
            self.emit_error("iterator over `" ++ place_name ++ "` retains access; cannot also mutably capture `" ++ place_name ++ "` (§15.8)", err_node)
        else:
            self.emit_error("cannot borrow mutably: already borrowed", err_node)
        return
    self.borrow_kinds.push(kind)
    self.borrow_places.push(place)
    self.borrow_fields.push(field)
    self.borrow_refs.push(0)
    self.borrow_path_starts.push(path_start)
    self.borrow_path_counts.push(path_count)
    self.borrow_scope_depths.push(self.scope_starts.len() as i32)
    self.borrow_creation_nodes.push(err_node)

fn Sema.remove_borrow_at(self: Sema, idx: i32):
    let last = self.borrow_refs.len() as i32 - 1
    if idx < 0 or idx > last:
        return
    if idx < last:
        self.borrow_kinds.set_i32(idx as i64, self.borrow_kinds.get(last as i64))
        self.borrow_places.set_i32(idx as i64, self.borrow_places.get(last as i64))
        self.borrow_fields.set_i32(idx as i64, self.borrow_fields.get(last as i64))
        self.borrow_refs.set_i32(idx as i64, self.borrow_refs.get(last as i64))
        self.borrow_path_starts.set_i32(idx as i64, self.borrow_path_starts.get(last as i64))
        self.borrow_path_counts.set_i32(idx as i64, self.borrow_path_counts.get(last as i64))
        self.borrow_scope_depths.set_i32(idx as i64, self.borrow_scope_depths.get(last as i64))
        self.borrow_creation_nodes.set_i32(idx as i64, self.borrow_creation_nodes.get(last as i64))
    self.borrow_kinds.pop()
    self.borrow_places.pop()
    self.borrow_fields.pop()
    self.borrow_refs.pop()
    self.borrow_path_starts.pop()
    self.borrow_path_counts.pop()
    self.borrow_scope_depths.pop()
    self.borrow_creation_nodes.pop()

fn Sema.expr_uses_symbol(self: Sema, node: i32, sym: i32) -> i32:
    if node == 0:
        return 0
    let kind = self.ast.kind(node)
    if kind == NodeKind.NK_IDENT:
        if self.ast.get_data0(node) == sym:
            return 1
        return 0
    if kind == NodeKind.NK_BINARY:
        if self.expr_uses_symbol(self.ast.get_data1(node), sym) != 0:
            return 1
        return self.expr_uses_symbol(self.ast.get_data2(node), sym)
    if kind == NodeKind.NK_MATCH_OP or kind == NodeKind.NK_NEG_MATCH_OP:
        if self.expr_uses_symbol(self.ast.get_data0(node), sym) != 0:
            return 1
        return self.expr_uses_symbol(self.ast.get_data1(node), sym)
    if kind == NodeKind.NK_UNARY:
        return self.expr_uses_symbol(self.ast.get_data1(node), sym)
    if kind == NodeKind.NK_GROUPED or kind == NodeKind.NK_AWAIT or kind == NodeKind.NK_ASYNC_BLOCK or kind == NodeKind.NK_SPAWN or kind == NodeKind.NK_DEFER or kind == NodeKind.NK_ERRDEFER or kind == NodeKind.NK_YIELD or kind == NodeKind.NK_COMPTIME:
        return self.expr_uses_symbol(self.ast.get_data0(node), sym)
    if kind == NodeKind.NK_LABEL:
        return self.expr_uses_symbol(self.ast.get_data1(node), sym)
    if kind == NodeKind.NK_GOTO:
        return 0
    if kind == NodeKind.NK_CALL:
        if self.expr_uses_symbol(self.ast.get_data0(node), sym) != 0:
            return 1
        let extra_start = self.ast.get_data1(node)
        let arg_count = self.ast.get_data2(node)
        for ai in 0..arg_count:
            if self.expr_uses_symbol(self.ast.get_extra(extra_start + ai), sym) != 0:
                return 1
        return 0
    if kind == NodeKind.NK_FIELD_ACCESS:
        return self.expr_uses_symbol(self.ast.get_data0(node), sym)
    if kind == NodeKind.NK_COMPUTED_FIELD_ACCESS:
        if self.expr_uses_symbol(self.ast.get_data0(node), sym) != 0:
            return 1
        return self.expr_uses_symbol(self.ast.get_data1(node), sym)
    if kind == NodeKind.NK_OPTIONAL_CHAIN:
        if self.expr_uses_symbol(self.ast.get_data0(node), sym) != 0:
            return 1
        let extra_start = self.ast.get_data2(node)
        if extra_start != 0:
            let has_args = self.ast.get_extra(extra_start)
            if has_args != 0:
                let arg_count = self.ast.get_extra(extra_start + 1)
                for ai in 0..arg_count:
                    if self.expr_uses_symbol(self.ast.get_extra(extra_start + 2 + ai), sym) != 0:
                        return 1
        return 0
    if kind == NodeKind.NK_INDEX:
        if self.expr_uses_symbol(self.ast.get_data0(node), sym) != 0:
            return 1
        return self.expr_uses_symbol(self.ast.get_data1(node), sym)
    if kind == NodeKind.NK_SLICE:
        if self.expr_uses_symbol(self.ast.get_data0(node), sym) != 0:
            return 1
        if self.expr_uses_symbol(self.ast.get_data1(node), sym) != 0:
            return 1
        return self.expr_uses_symbol(self.ast.get_data2(node), sym)
    if kind == NodeKind.NK_BLOCK:
        let extra_start = self.ast.get_data0(node)
        let stmt_count = self.ast.get_data1(node)
        let tail = self.ast.get_data2(node)
        for si in 0..stmt_count:
            if self.expr_uses_symbol(self.ast.get_extra(extra_start + si), sym) != 0:
                return 1
        return self.expr_uses_symbol(tail, sym)
    if kind == NodeKind.NK_IF_EXPR:
        if self.expr_uses_symbol(self.ast.get_data0(node), sym) != 0:
            return 1
        if self.expr_uses_symbol(self.ast.get_data1(node), sym) != 0:
            return 1
        return self.expr_uses_symbol(self.ast.get_data2(node), sym)
    if kind == NodeKind.NK_RETURN:
        return self.expr_uses_symbol(self.ast.get_data0(node), sym)
    if kind == NodeKind.NK_LET_BINDING:
        return self.expr_uses_symbol(self.ast.get_data1(node), sym)
    if kind == NodeKind.NK_LET_ELSE:
        if self.expr_uses_symbol(self.ast.get_data1(node), sym) != 0:
            return 1
        return self.expr_uses_symbol(self.ast.get_data2(node), sym)
    if kind == NodeKind.NK_TUPLE_DESTRUCTURE:
        return self.expr_uses_symbol(self.ast.get_data2(node), sym)
    if kind == NodeKind.NK_ASSIGN:
        if self.expr_uses_symbol(self.ast.get_data0(node), sym) != 0:
            return 1
        return self.expr_uses_symbol(self.ast.get_data1(node), sym)
    if kind == NodeKind.NK_TUPLE or kind == NodeKind.NK_ARRAY_LIT:
        let extra_start = self.ast.get_data0(node)
        let elem_count = self.ast.get_data1(node)
        for ei in 0..elem_count:
            if self.expr_uses_symbol(self.ast.get_extra(extra_start + ei), sym) != 0:
                return 1
        return 0
    if kind == NodeKind.NK_RANGE:
        if self.expr_uses_symbol(self.ast.get_data0(node), sym) != 0:
            return 1
        return self.expr_uses_symbol(self.ast.get_data1(node), sym)
    if kind == NodeKind.NK_MATCH:
        if self.expr_uses_symbol(self.ast.get_data0(node), sym) != 0:
            return 1
        let extra_start = self.ast.get_data1(node)
        let arm_count = self.ast.get_data2(node)
        for ai in 0..arm_count:
            let arm = self.ast.get_extra(extra_start + ai)
            let guard = self.ast.get_data2(arm)
            if self.expr_uses_symbol(guard, sym) != 0:
                return 1
            if self.expr_uses_symbol(self.ast.get_data1(arm), sym) != 0:
                return 1
        return 0
    if kind == NodeKind.NK_STRUCT_LIT:
        let extra_start = self.ast.get_data1(node)
        let field_count = self.ast.get_data2(node)
        for fi in 0..field_count:
            if self.expr_uses_symbol(self.ast.get_extra(extra_start + fi * 2 + 1), sym) != 0:
                return 1
        return 0
    if kind == NodeKind.NK_FOR:
        if self.expr_uses_symbol(self.ast.get_data1(node), sym) != 0:
            return 1
        return self.expr_uses_symbol(self.ast.get_data2(node), sym)
    if kind == NodeKind.NK_WHILE:
        if self.expr_uses_symbol(self.ast.get_data0(node), sym) != 0:
            return 1
        return self.expr_uses_symbol(self.ast.get_data1(node), sym)
    if kind == NodeKind.NK_DO_WHILE:
        if self.expr_uses_symbol(self.ast.get_data0(node), sym) != 0:
            return 1
        return self.expr_uses_symbol(self.ast.get_data1(node), sym)
    if kind == NodeKind.NK_LOOP:
        return self.expr_uses_symbol(self.ast.get_data0(node), sym)
    if kind == NodeKind.NK_BREAK:
        return self.expr_uses_symbol(self.ast.get_data0(node), sym)
    if kind == NodeKind.NK_PIPELINE:
        if self.expr_uses_symbol(self.ast.get_data0(node), sym) != 0:
            return 1
        return self.expr_uses_symbol(self.ast.get_data1(node), sym)
    if kind == NodeKind.NK_WITH_EXPR:
        if self.expr_uses_symbol(self.ast.get_data0(node), sym) != 0:
            return 1
        return self.expr_uses_symbol(self.ast.get_data1(node), sym)
    if kind == NodeKind.NK_WITH_TUPLE:
        if self.expr_uses_symbol(self.ast.get_data0(node), sym) != 0:
            return 1
        return self.expr_uses_symbol(self.ast.get_data1(node), sym)
    if kind == NodeKind.NK_RECORD_UPDATE:
        if self.expr_uses_symbol(self.ast.get_data0(node), sym) != 0:
            return 1
        let extra_start = self.ast.get_data1(node)
        let field_count = self.ast.get_data2(node)
        for fi in 0..field_count:
            if self.expr_uses_symbol(self.ast.get_extra(extra_start + fi * 2 + 1), sym) != 0:
                return 1
        return 0
    if kind == NodeKind.NK_ENUM_VARIANT:
        let extra_start = self.ast.get_data2(node)
        let arg_count = self.ast.get_extra(extra_start)
        for ai in 0..arg_count:
            if self.expr_uses_symbol(self.ast.get_extra(extra_start + 1 + ai), sym) != 0:
                return 1
        return 0
    if kind == NodeKind.NK_CLOSURE or kind == NodeKind.NK_CAST:
        return self.expr_uses_symbol(self.ast.get_data0(node), sym)
    if kind == NodeKind.NK_ARRAY_COMPREHENSION:
        if self.expr_uses_symbol(self.ast.get_data0(node), sym) != 0:
            return 1
        if self.expr_uses_symbol(self.ast.get_data2(node), sym) != 0:
            return 1
        return 0
    if kind == NodeKind.NK_ASYNC_SCOPE:
        return self.expr_uses_symbol(self.ast.get_data1(node), sym)
    if kind == NodeKind.NK_SELECT_AWAIT:
        let extra_start = self.ast.get_data0(node)
        let arm_count = self.ast.get_data1(node)
        for ai in 0..arm_count:
            if self.expr_uses_symbol(self.ast.get_extra(extra_start + ai * 3 + 1), sym) != 0:
                return 1
            if self.expr_uses_symbol(self.ast.get_extra(extra_start + ai * 3 + 2), sym) != 0:
                return 1
        return 0
    0

// Check if an expression mutates a variable rooted at `sym`.
// Returns 1 if any subexpression assigns to or takes &mut of the variable.
fn Sema.expr_mutates_place(self: Sema, node: i32, sym: i32) -> i32:
    if node == 0:
        return 0
    let kind = self.ast.kind(node)
    // Assignment: check if target is rooted at sym
    if kind == NodeKind.NK_ASSIGN:
        let target = self.ast.get_data0(node)
        if self.place_root_sym(target) == sym:
            return 1
        // Also check value side for nested mutations
        return self.expr_mutates_place(self.ast.get_data1(node), sym)
    // &raw mut borrow of sym
    if kind == NodeKind.NK_UNARY:
        let op = self.ast.get_data0(node)
        if op == UnaryOp.UOP_RAW_REF_MUT:
            let operand = self.ast.get_data1(node)
            if self.place_root_sym(operand) == sym:
                return 1
        return self.expr_mutates_place(self.ast.get_data1(node), sym)
    // Recursive cases
    if kind == NodeKind.NK_BINARY:
        if self.expr_mutates_place(self.ast.get_data1(node), sym) != 0:
            return 1
        return self.expr_mutates_place(self.ast.get_data2(node), sym)
    if kind == NodeKind.NK_MATCH_OP or kind == NodeKind.NK_NEG_MATCH_OP:
        if self.expr_mutates_place(self.ast.get_data0(node), sym) != 0:
            return 1
        return self.expr_mutates_place(self.ast.get_data1(node), sym)
    if kind == NodeKind.NK_BLOCK:
        let extra_start = self.ast.get_data0(node)
        let stmt_count = self.ast.get_data1(node)
        let tail = self.ast.get_data2(node)
        for si in 0..stmt_count:
            if self.expr_mutates_place(self.ast.get_extra(extra_start + si), sym) != 0:
                return 1
        return self.expr_mutates_place(tail, sym)
    if kind == NodeKind.NK_LABEL:
        return self.expr_mutates_place(self.ast.get_data1(node), sym)
    if kind == NodeKind.NK_GOTO:
        return 0
    if kind == NodeKind.NK_IF_EXPR:
        if self.expr_mutates_place(self.ast.get_data0(node), sym) != 0:
            return 1
        if self.expr_mutates_place(self.ast.get_data1(node), sym) != 0:
            return 1
        return self.expr_mutates_place(self.ast.get_data2(node), sym)
    if kind == NodeKind.NK_CALL:
        // docs/mut.md Rev 8 §5.1 — a method call `sym.method(...)` whose
        // method takes a mutating receiver is a mutation of `sym`. Detect
        // both builtin mutating methods (push, pop, …) and user-defined
        // `mut self: Self` methods.
        let callee = self.ast.get_data0(node)
        if self.ast.kind(callee) == NodeKind.NK_FIELD_ACCESS:
            let cbase = self.ast.get_data0(callee)
            if self.ast.kind(cbase) == NodeKind.NK_IDENT and self.ast.get_data0(cbase) == sym:
                let method_sym = self.ast.get_data1(callee)
                let cap_ty = self.scope_lookup(sym)
                if cap_ty >= 0:
                    let recv_resolved = self.resolve_alias(cap_ty as TypeId)
                    var recv_inner = recv_resolved
                    let recv_tk = self.get_type_kind(recv_inner)
                    if recv_tk == TypeKind.TY_PTR or recv_tk == TypeKind.TY_REF:
                        recv_inner = self.resolve_alias(self.get_type_d0(recv_inner) as TypeId)
                    let owner_sym = self.method_owner_symbol_for_type(recv_inner as i32)
                    if owner_sym != 0:
                        if self.builtin_method_requires_mutable_receiver(owner_sym, method_sym) != 0:
                            return 1
                        if self.method_has_mut_self_flag(owner_sym, method_sym) != 0:
                            return 1
        if self.expr_mutates_place(callee, sym) != 0:
            return 1
        let ea = self.ast.get_data1(node)
        let ac = self.ast.get_data2(node)
        for ai in 0..ac:
            if self.expr_mutates_place(self.ast.get_extra(ea + ai), sym) != 0:
                return 1
        return 0
    if kind == NodeKind.NK_LET_BINDING:
        return self.expr_mutates_place(self.ast.get_data1(node), sym)
    if kind == NodeKind.NK_RETURN:
        return self.expr_mutates_place(self.ast.get_data0(node), sym)
    if kind == NodeKind.NK_FIELD_ACCESS:
        return self.expr_mutates_place(self.ast.get_data0(node), sym)
    if kind == NodeKind.NK_COMPUTED_FIELD_ACCESS:
        if self.expr_mutates_place(self.ast.get_data0(node), sym) != 0:
            return 1
        return self.expr_mutates_place(self.ast.get_data1(node), sym)
    if kind == NodeKind.NK_INDEX:
        if self.expr_mutates_place(self.ast.get_data0(node), sym) != 0:
            return 1
        return self.expr_mutates_place(self.ast.get_data1(node), sym)
    if kind == NodeKind.NK_GROUPED:
        return self.expr_mutates_place(self.ast.get_data0(node), sym)
    if kind == NodeKind.NK_WHILE:
        if self.expr_mutates_place(self.ast.get_data0(node), sym) != 0:
            return 1
        return self.expr_mutates_place(self.ast.get_data1(node), sym)
    if kind == NodeKind.NK_DO_WHILE:
        if self.expr_mutates_place(self.ast.get_data0(node), sym) != 0:
            return 1
        return self.expr_mutates_place(self.ast.get_data1(node), sym)
    if kind == NodeKind.NK_FOR:
        if self.expr_mutates_place(self.ast.get_data1(node), sym) != 0:
            return 1
        return self.expr_mutates_place(self.ast.get_data2(node), sym)
    0

// docs/mut.md Rev 8 §8.2 / §15.5 — returns the symbol of the indexed base
// when the expression includes any NK_INDEX projection, e.g.:
//
//   xs[0]            → returns sym(xs)
//   xs[0].field      → returns sym(xs)
//   xs[i].method()   → returns sym(xs) (the receiver's indexed base)
//
// Returns 0 when the expression has no indexed projection along its
// place chain. Used to detect two accesses through the same indexed
// base in a single call, which §8.2 conservatively rejects.
fn Sema.expr_indexed_into(self: Sema, node: i32) -> i32:
    if node == 0:
        return 0
    let kind = self.ast.kind(node)
    if kind == NodeKind.NK_INDEX:
        return self.place_root_sym(self.ast.get_data0(node))
    if kind == NodeKind.NK_FIELD_ACCESS or kind == NodeKind.NK_COMPUTED_FIELD_ACCESS or kind == NodeKind.NK_GROUPED:
        return self.expr_indexed_into(self.ast.get_data0(node))
    if kind == NodeKind.NK_UNSAFE_BLOCK:
        return self.expr_indexed_into(self.ast.get_data0(node))
    if kind == NodeKind.NK_UNARY:
        let op = self.ast.get_data0(node)
        if op == UnaryOp.UOP_DEREF:
            return self.expr_indexed_into(self.ast.get_data1(node))
    0

// §5.4 — walk an expression subtree looking for a mutating method call
// whose receiver is exactly `recv_sym` (a simple binding, not a field
// projection). This catches `xs.push(xs.pop())` but NOT
// `self.a.insert(self.b.pop())` where the inner and outer receivers are
// disjoint fields of the same root.
fn Sema.expr_has_nested_mutating_call_on(self: Sema, node: i32, recv_sym: i32) -> i32:
    if node == 0:
        return 0
    let kind = self.ast.kind(node)
    if kind == NodeKind.NK_CALL:
        let callee = self.ast.get_data0(node)
        if self.ast.kind(callee) == NodeKind.NK_FIELD_ACCESS:
            let inner_recv = self.ast.get_data0(callee)
            // Only match when the inner receiver is directly `recv_sym`,
            // not `recv_sym.field` (disjoint fields are safe).
            if self.ast.kind(inner_recv) == NodeKind.NK_IDENT and self.ast.get_data0(inner_recv) == recv_sym:
                let method = self.ast.get_data1(callee)
                let inner_ty = self.typed_expr_types.get(inner_recv)
                if inner_ty.is_some():
                    let resolved = self.resolve_alias(inner_ty.unwrap() as TypeId)
                    var inner_resolved = resolved
                    let itk = self.get_type_kind(inner_resolved)
                    if itk == TypeKind.TY_PTR or itk == TypeKind.TY_REF:
                        inner_resolved = self.resolve_alias(self.get_type_d0(inner_resolved) as TypeId)
                    let owner = self.method_owner_symbol_for_type(inner_resolved as i32)
                    if owner != 0:
                        if self.method_has_mut_self_flag(owner, method) != 0 or self.builtin_method_requires_mutable_receiver(owner, method) != 0:
                            return 1
        let ea = self.ast.get_data1(node)
        let ac = self.ast.get_data2(node)
        var ai = 0
        while ai < ac:
            if self.expr_has_nested_mutating_call_on(self.ast.get_extra(ea + ai), recv_sym) != 0:
                return 1
            ai = ai + 1
        return self.expr_has_nested_mutating_call_on(self.ast.get_data0(node), recv_sym)
    if kind == NodeKind.NK_BINARY:
        if self.expr_has_nested_mutating_call_on(self.ast.get_data1(node), recv_sym) != 0:
            return 1
        return self.expr_has_nested_mutating_call_on(self.ast.get_data2(node), recv_sym)
    if kind == NodeKind.NK_MATCH_OP or kind == NodeKind.NK_NEG_MATCH_OP:
        if self.expr_has_nested_mutating_call_on(self.ast.get_data0(node), recv_sym) != 0:
            return 1
        return self.expr_has_nested_mutating_call_on(self.ast.get_data1(node), recv_sym)
    if kind == NodeKind.NK_UNARY:
        return self.expr_has_nested_mutating_call_on(self.ast.get_data1(node), recv_sym)
    if kind == NodeKind.NK_FIELD_ACCESS or kind == NodeKind.NK_COMPUTED_FIELD_ACCESS or kind == NodeKind.NK_INDEX or kind == NodeKind.NK_GROUPED:
        return self.expr_has_nested_mutating_call_on(self.ast.get_data0(node), recv_sym)
    if kind == NodeKind.NK_CAST:
        return self.expr_has_nested_mutating_call_on(self.ast.get_data0(node), recv_sym)
    0

// Get the root symbol of a place expression (ident, field access chain, index).
fn Sema.place_root_sym(self: Sema, node: i32) -> i32:
    if node == 0:
        return 0
    let kind = self.ast.kind(node)
    if kind == NodeKind.NK_IDENT:
        return self.ast.get_data0(node)
    if kind == NodeKind.NK_FIELD_ACCESS or kind == NodeKind.NK_COMPUTED_FIELD_ACCESS or kind == NodeKind.NK_INDEX or kind == NodeKind.NK_MULTI_INDEX or kind == NodeKind.NK_GROUPED:
        return self.place_root_sym(self.ast.get_data0(node))
    // &x.field — strip the reference operator to get the underlying place's root
    if kind == NodeKind.NK_UNARY:
        if self.ast.get_data0(node) == UnaryOp.UOP_REF:
            return self.place_root_sym(self.ast.get_data1(node))
    0

// ── docs/mut.md Rev 8 §2 — Place classification ──────────────────
//
// The mutation model is built on the concept of a *place* — a storage
// location that can be named or reached from a named storage root.
// Place identity is determined syntactically. classify_place walks an
// expression and returns a packed (PlaceKind, PlaceMut) i64 describing
// it. P2.4 lands the analysis as infrastructure only; later phases
// (P11) consume the result for diagnostics on assignment LHS, mutating
// receivers, &raw mut, scoped with-bindings, etc.

enum PlaceKind: i32:
    PK_NotPlace = 0
    PK_Local = 1
    PK_OwnedParam = 2
    PK_Global = 3
    PK_GlobalVar = 4
    PK_Captured = 5
    PK_WithBound = 6
    PK_CompilerTemp = 7
    PK_ForVar = 8
    PK_DerefRef = 9         // *r where r: &T  → ReadOnly
    PK_DerefConstPtr = 10   // *p where p: *const T → ReadOnly (unsafe)
    PK_DerefMutPtr = 11     // *p where p: *mut T → Mutable (unsafe)

enum PlaceMut: i32:
    PM_NoMut = 0    // not a place
    PM_ReadOnly = 1
    PM_Mutable = 2

fn pack_place(kind: i32, mut_state: i32) -> i64:
    (kind as i64) * 4294967296 + (mut_state as i64)

fn unpack_place_kind(packed: i64) -> i32:
    (packed / 4294967296) as i32

fn unpack_place_mut(packed: i64) -> i32:
    (packed % 4294967296) as i32

fn Sema.type_is_index_place(self: Sema, tid: i32) -> i32:
    if tid == 0:
        return 0
    let resolved = self.resolve_alias(tid as TypeId)
    let tk = self.get_type_kind(resolved)
    if tk == TypeKind.TY_ARRAY or tk == TypeKind.TY_SLICE:
        return 1
    if tk == TypeKind.TY_GENERIC_INST:
        let base_sym = self.get_type_d0(resolved)
        if base_sym == self.syms.vec or base_sym == self.syms.hashmap:
            return 1
        let ip_sym = self.pool_lookup_symbol("IndexPlace")
        if ip_sym > 0:
            if self.select_trait_impl(base_sym, ip_sym) != 0:
                return 1
    if tk == TypeKind.TY_STRUCT:
        let struct_sym = self.get_type_d0(resolved)
        let ip_sym = self.pool_lookup_symbol("IndexPlace")
        if ip_sym > 0 and struct_sym != 0:
            if self.select_trait_impl(struct_sym, ip_sym) != 0:
                return 1
    0

// Returns 1 when the base expression has a type that auto-derefs to a
// read-only place: `&T` (TY_REF, regardless of mut bit on legacy &mut) or
// `*const T` (TY_PTR with d1 == 0). Used so projections through such bases
// correctly classify as read-only places per §2.3.
//
// Note: legacy `&mut T` (TY_REF with d1=1) is NOT treated as read-only here
// — that distinction was already special-cased in earlier sema. After P12
// lockdown TY_REF will only ever be `&T` (d1=0).
fn Sema.place_base_is_read_only_ref(self: Sema, base_node: i32) -> i32:
    let cached = self.typed_expr_types.get(base_node)
    var ty: i32 = 0
    if cached.is_some():
        ty = cached.unwrap()
    else:
        ty = self.check_expr(base_node) as i32
    if ty == 0:
        return 0
    let resolved = self.resolve_alias(ty as TypeId)
    let tk = self.get_type_kind(resolved)
    if tk == TypeKind.TY_REF:
        if self.get_type_d1(resolved) == 0:
            return 1
        return 0
    if tk == TypeKind.TY_PTR:
        if self.get_type_d1(resolved) == 0:
            return 1
        return 0
    0

// Classify the operand of a UOP_DEREF expression. Returns the packed
// (kind, mut) for the place produced by *operand.
fn Sema.classify_deref(self: Sema, operand_type: i32) -> i64:
    if operand_type == 0:
        return pack_place(PlaceKind.PK_NotPlace, PlaceMut.PM_NoMut)
    let resolved = self.resolve_alias(operand_type as TypeId)
    let tk = self.get_type_kind(resolved)
    if tk == TypeKind.TY_REF:
        if self.get_type_d1(resolved) != 0:
            return pack_place(PlaceKind.PK_DerefRef, PlaceMut.PM_Mutable)
        // *r where r: &T is read-only (§2.3).
        return pack_place(PlaceKind.PK_DerefRef, PlaceMut.PM_ReadOnly)
    if tk == TypeKind.TY_PTR:
        if self.get_type_d1(resolved) != 0:
            return pack_place(PlaceKind.PK_DerefMutPtr, PlaceMut.PM_Mutable)
        return pack_place(PlaceKind.PK_DerefConstPtr, PlaceMut.PM_ReadOnly)
    pack_place(PlaceKind.PK_NotPlace, PlaceMut.PM_NoMut)

fn Sema.classify_place(self: Sema, node: i32) -> i64:
    if node == 0:
        return pack_place(PlaceKind.PK_NotPlace, PlaceMut.PM_NoMut)
    let kind = self.ast.kind(node)
    // Identifier root — local binding, parameter, or global. P2.4 stub
    // uses scope_lookup to confirm the symbol resolves to a binding;
    // later phases will distinguish OwnedParam / Global / Captured /
    // WithBound / ForVar based on richer scope metadata.
    if kind == NodeKind.NK_IDENT:
        let sym = self.ast.get_data0(node)
        if self.scope_lookup(sym) >= 0:
            // §1 — `let` and `var` bindings both produce mutable places;
            // the binding-mut flag governs rebinding only.
            return pack_place(PlaceKind.PK_Local, PlaceMut.PM_Mutable)
        return pack_place(PlaceKind.PK_NotPlace, PlaceMut.PM_NoMut)
    // Field projection: §2.2 — projection inherits base mutability. But if
    // the base value is `&T` or `*const T`, auto-deref produces a read-only
    // place (§2.3) that overrides the underlying binding's mutability.
    if kind == NodeKind.NK_FIELD_ACCESS or kind == NodeKind.NK_COMPUTED_FIELD_ACCESS:
        let fa_base = self.ast.get_data0(node)
        let base_packed = self.classify_place(fa_base)
        if unpack_place_kind(base_packed) == PlaceKind.PK_NotPlace:
            return pack_place(PlaceKind.PK_NotPlace, PlaceMut.PM_NoMut)
        if self.place_base_is_read_only_ref(fa_base) != 0:
            return pack_place(unpack_place_kind(base_packed), PlaceMut.PM_ReadOnly)
        return base_packed
    // Parenthesized: classify inner.
    if kind == NodeKind.NK_GROUPED:
        return self.classify_place(self.ast.get_data0(node))
    // `unsafe *p` / `unsafe p[i]` wraps a single place expression; classify
    // the inner. Block form (NK_UNSAFE_BLOCK over NK_BLOCK) won't classify as
    // a place because NK_BLOCK isn't in any of the place arms.
    if kind == NodeKind.NK_UNSAFE_BLOCK:
        let saved_unsafe = self.in_unsafe
        self.in_unsafe = 1
        let packed = self.classify_place(self.ast.get_data0(node))
        self.in_unsafe = saved_unsafe
        return packed
    // Index: §2.2 / §2.4 — `p[i]` for raw pointer `p` is always a place
    // (mutability from the pointer's mut bit, unsafe required to access),
    // regardless of whether `p` itself is a place. For non-pointer bases,
    // indexing is a place only when the base is a place AND the base type
    // implements IndexPlace.
    if kind == NodeKind.NK_INDEX:
        let base_node = self.ast.get_data0(node)
        let cached_base_ty = self.typed_expr_types.get(base_node)
        var base_ty: i32 = 0
        if cached_base_ty.is_some():
            base_ty = cached_base_ty.unwrap()
        else:
            base_ty = self.check_expr(base_node) as i32
        if base_ty != 0:
            let base_resolved = self.resolve_alias(base_ty as TypeId)
            let base_tk = self.get_type_kind(base_resolved)
            // Raw pointer indexing: p[i] where p: *const T → read-only;
            // p: *mut T → mutable. Source-level §13.3 still requires unsafe
            // for the actual memory access; that's enforced elsewhere.
            if base_tk == TypeKind.TY_PTR:
                if self.get_type_d1(base_resolved) != 0:
                    return pack_place(PlaceKind.PK_DerefMutPtr, PlaceMut.PM_Mutable)
                return pack_place(PlaceKind.PK_DerefConstPtr, PlaceMut.PM_ReadOnly)
        let base_packed = self.classify_place(base_node)
        if unpack_place_kind(base_packed) == PlaceKind.PK_NotPlace:
            return pack_place(PlaceKind.PK_NotPlace, PlaceMut.PM_NoMut)
        if base_ty != 0 and self.type_is_index_place(base_ty) != 0:
            if self.place_base_is_read_only_ref(base_node) != 0:
                return pack_place(unpack_place_kind(base_packed), PlaceMut.PM_ReadOnly)
            return base_packed
        return pack_place(PlaceKind.PK_NotPlace, PlaceMut.PM_NoMut)
    // Dereference: §2.3 — *r / *p mutability comes from the pointer kind.
    if kind == NodeKind.NK_UNARY:
        let op = self.ast.get_data0(node)
        if op == UnaryOp.UOP_DEREF:
            let operand_node = self.ast.get_data1(node)
            // typed_expr_types is sparse; for binary-expr operands (pointer
            // arithmetic) it's not cached. Look up via check_expr if cache
            // misses — sema is idempotent for already-typed nodes.
            var operand_ty: i32 = 0
            let cached = self.typed_expr_types.get(operand_node)
            if cached.is_some():
                operand_ty = cached.unwrap()
            else:
                operand_ty = self.check_expr(operand_node) as i32
            if operand_ty != 0:
                return self.classify_deref(operand_ty)
            return pack_place(PlaceKind.PK_NotPlace, PlaceMut.PM_NoMut)
    // §2.5 — function call results, arithmetic, literals are not places.
    pack_place(PlaceKind.PK_NotPlace, PlaceMut.PM_NoMut)

// Check if a captured variable is used only through field accesses, never whole.
// Returns 1 if all uses of `sym` in `node` are of the form `sym.field`.
// Returns 0 if `sym` is used directly (passed as arg, assigned, etc).
fn Sema.capture_is_field_only(self: Sema, node: i32, sym: i32) -> i32:
    if node == 0:
        return 1
    let kind = self.ast.kind(node)
    if kind == NodeKind.NK_IDENT:
        // Direct use of sym — not field-only
        if self.ast.get_data0(node) == sym:
            return 0
        return 1
    if kind == NodeKind.NK_FIELD_ACCESS:
        // sym.field — check if base is sym (OK) or recurse
        let base = self.ast.get_data0(node)
        if self.ast.kind(base) == NodeKind.NK_IDENT and self.ast.get_data0(base) == sym:
            return 1
        return self.capture_is_field_only(base, sym)
    if kind == NodeKind.NK_COMPUTED_FIELD_ACCESS:
        if self.capture_is_field_only(self.ast.get_data0(node), sym) == 0:
            return 0
        return self.capture_is_field_only(self.ast.get_data1(node), sym)
    if kind == NodeKind.NK_BINARY:
        if self.capture_is_field_only(self.ast.get_data1(node), sym) == 0:
            return 0
        return self.capture_is_field_only(self.ast.get_data2(node), sym)
    if kind == NodeKind.NK_MATCH_OP or kind == NodeKind.NK_NEG_MATCH_OP:
        if self.capture_is_field_only(self.ast.get_data0(node), sym) == 0:
            return 0
        return self.capture_is_field_only(self.ast.get_data1(node), sym)
    if kind == NodeKind.NK_UNARY:
        let operand = self.ast.get_data1(node)
        // &mut sym.field or &sym.field — check the operand
        return self.capture_is_field_only(operand, sym)
    if kind == NodeKind.NK_CALL:
        // docs/mut.md Rev 8 §9 — a method call `sym.method(...)` parses as
        // NK_CALL whose callee is NK_FIELD_ACCESS on `sym`. From a capture
        // standpoint that's a *method call on the captured variable*, not
        // a field-only access — fall through to whole-variable capture so
        // the EXCLUSIVE/SHARED determination uses expr_mutates_place.
        let callee = self.ast.get_data0(node)
        if self.ast.kind(callee) == NodeKind.NK_FIELD_ACCESS:
            let cbase = self.ast.get_data0(callee)
            if self.ast.kind(cbase) == NodeKind.NK_IDENT and self.ast.get_data0(cbase) == sym:
                return 0
        if self.capture_is_field_only(callee, sym) == 0:
            return 0
        let ea = self.ast.get_data1(node)
        let ac = self.ast.get_data2(node)
        for ai in 0..ac:
            if self.capture_is_field_only(self.ast.get_extra(ea + ai), sym) == 0:
                return 0
        return 1
    if kind == NodeKind.NK_BLOCK:
        let ea = self.ast.get_data0(node)
        let sc = self.ast.get_data1(node)
        let tail = self.ast.get_data2(node)
        for si in 0..sc:
            if self.capture_is_field_only(self.ast.get_extra(ea + si), sym) == 0:
                return 0
        return self.capture_is_field_only(tail, sym)
    if kind == NodeKind.NK_LABEL:
        return self.capture_is_field_only(self.ast.get_data1(node), sym)
    if kind == NodeKind.NK_GOTO:
        return 1
    if kind == NodeKind.NK_ASSIGN:
        if self.capture_is_field_only(self.ast.get_data0(node), sym) == 0:
            return 0
        return self.capture_is_field_only(self.ast.get_data1(node), sym)
    if kind == NodeKind.NK_IF_EXPR:
        if self.capture_is_field_only(self.ast.get_data0(node), sym) == 0:
            return 0
        if self.capture_is_field_only(self.ast.get_data1(node), sym) == 0:
            return 0
        return self.capture_is_field_only(self.ast.get_data2(node), sym)
    if kind == NodeKind.NK_LET_BINDING:
        return self.capture_is_field_only(self.ast.get_data1(node), sym)
    if kind == NodeKind.NK_RETURN:
        return self.capture_is_field_only(self.ast.get_data0(node), sym)
    if kind == NodeKind.NK_INDEX:
        if self.capture_is_field_only(self.ast.get_data0(node), sym) == 0:
            return 0
        return self.capture_is_field_only(self.ast.get_data1(node), sym)
    if kind == NodeKind.NK_GROUPED:
        return self.capture_is_field_only(self.ast.get_data0(node), sym)
    1

// Collect top-level field syms accessed on a captured variable in a closure body.
// Pushes (field_sym, borrow_kind) pairs into capture_field_syms/capture_field_kinds.
// These are parallel Vecs used transiently during closure checking.
fn Sema.collect_capture_fields(self: Sema, node: i32, sym: i32):
    if node == 0:
        return
    let kind = self.ast.kind(node)
    if kind == NodeKind.NK_FIELD_ACCESS:
        let base = self.ast.get_data0(node)
        if self.ast.kind(base) == NodeKind.NK_IDENT and self.ast.get_data0(base) == sym:
            let field_sym = self.ast.get_data1(node)
            // Check if this field is already collected
            var found = 0
            var fi = 0
            while fi < self.capture_field_syms.len() as i32:
                if self.capture_field_syms.get(fi as i64) == field_sym:
                    found = 1
                    break
                fi = fi + 1
            if found == 0:
                self.capture_field_syms.push(field_sym)
                self.capture_field_kinds.push(BorrowKind.SHARED)
            return
        self.collect_capture_fields(base, sym)
        return
    if kind == NodeKind.NK_COMPUTED_FIELD_ACCESS:
        self.collect_capture_fields(self.ast.get_data0(node), sym)
        self.collect_capture_fields(self.ast.get_data1(node), sym)
        return
    if kind == NodeKind.NK_ASSIGN:
        // Check if target is sym.field — if so, mark that field as exclusive
        let target = self.ast.get_data0(node)
        if self.ast.kind(target) == NodeKind.NK_FIELD_ACCESS:
            let tbase = self.ast.get_data0(target)
            if self.ast.kind(tbase) == NodeKind.NK_IDENT and self.ast.get_data0(tbase) == sym:
                let field_sym = self.ast.get_data1(target)
                var found = 0
                var fi = 0
                while fi < self.capture_field_syms.len() as i32:
                    if self.capture_field_syms.get(fi as i64) == field_sym:
                        found = 1
                        self.capture_field_kinds.set_i32(fi as i64, BorrowKind.EXCLUSIVE)
                        break
                    fi = fi + 1
                if found == 0:
                    self.capture_field_syms.push(field_sym)
                    self.capture_field_kinds.push(BorrowKind.EXCLUSIVE)
        self.collect_capture_fields(self.ast.get_data0(node), sym)
        self.collect_capture_fields(self.ast.get_data1(node), sym)
        return
    if kind == NodeKind.NK_UNARY:
        let op = self.ast.get_data0(node)
        let operand = self.ast.get_data1(node)
        if op == UnaryOp.UOP_RAW_REF_MUT:
            // &raw mut sym.field — mark field as exclusive
            if self.ast.kind(operand) == NodeKind.NK_FIELD_ACCESS:
                let fbase = self.ast.get_data0(operand)
                if self.ast.kind(fbase) == NodeKind.NK_IDENT and self.ast.get_data0(fbase) == sym:
                    let field_sym = self.ast.get_data1(operand)
                    var found = 0
                    var fi = 0
                    while fi < self.capture_field_syms.len() as i32:
                        if self.capture_field_syms.get(fi as i64) == field_sym:
                            found = 1
                            self.capture_field_kinds.set_i32(fi as i64, BorrowKind.EXCLUSIVE)
                            break
                        fi = fi + 1
                    if found == 0:
                        self.capture_field_syms.push(field_sym)
                        self.capture_field_kinds.push(BorrowKind.EXCLUSIVE)
                    return
        self.collect_capture_fields(operand, sym)
        return
    // Recursive cases
    if kind == NodeKind.NK_BINARY:
        self.collect_capture_fields(self.ast.get_data1(node), sym)
        self.collect_capture_fields(self.ast.get_data2(node), sym)
        return
    if kind == NodeKind.NK_MATCH_OP or kind == NodeKind.NK_NEG_MATCH_OP:
        self.collect_capture_fields(self.ast.get_data0(node), sym)
        self.collect_capture_fields(self.ast.get_data1(node), sym)
        return
    if kind == NodeKind.NK_BLOCK:
        let ea = self.ast.get_data0(node)
        let sc = self.ast.get_data1(node)
        let tail = self.ast.get_data2(node)
        for si in 0..sc:
            self.collect_capture_fields(self.ast.get_extra(ea + si), sym)
        self.collect_capture_fields(tail, sym)
        return
    if kind == NodeKind.NK_LABEL:
        self.collect_capture_fields(self.ast.get_data1(node), sym)
        return
    if kind == NodeKind.NK_GOTO:
        return
    if kind == NodeKind.NK_CALL:
        self.collect_capture_fields(self.ast.get_data0(node), sym)
        let ea = self.ast.get_data1(node)
        let ac = self.ast.get_data2(node)
        for ai in 0..ac:
            self.collect_capture_fields(self.ast.get_extra(ea + ai), sym)
        return
    if kind == NodeKind.NK_IF_EXPR:
        self.collect_capture_fields(self.ast.get_data0(node), sym)
        self.collect_capture_fields(self.ast.get_data1(node), sym)
        self.collect_capture_fields(self.ast.get_data2(node), sym)
        return
    if kind == NodeKind.NK_LET_BINDING:
        self.collect_capture_fields(self.ast.get_data1(node), sym)
        return
    if kind == NodeKind.NK_RETURN:
        self.collect_capture_fields(self.ast.get_data0(node), sym)
        return
    if kind == NodeKind.NK_INDEX:
        self.collect_capture_fields(self.ast.get_data0(node), sym)
        self.collect_capture_fields(self.ast.get_data1(node), sym)
        return
    if kind == NodeKind.NK_GROUPED:
        self.collect_capture_fields(self.ast.get_data0(node), sym)

fn Sema.expire_dead_borrows_in_block(self: Sema, block_extra_start: i32, stmt_count: i32, next_stmt_index: i32, tail_node: i32):
    let current_depth = self.scope_starts.len() as i32
    var bi = 0
    while bi < self.borrow_refs.len() as i32:
        let ref_sym = self.borrow_refs.get(bi as i64)
        if ref_sym == 0:
            self.remove_borrow_at(bi)
            continue

        // Only expire borrows owned by this scope or deeper — borrows from
        // outer scopes must be expired by the outer scope's own block walk,
        // which has the full forward context (§8.4 NLL scoped expiry).
        if self.borrow_scope_depths.get(bi as i64) < current_depth:
            bi = bi + 1
            continue

        var live = 0
        var si = next_stmt_index
        while si < stmt_count:
            if self.expr_uses_symbol(self.ast.get_extra(block_extra_start + si), ref_sym) != 0:
                live = 1
                break
            si = si + 1

        if live == 0 and tail_node != 0:
            if self.expr_uses_symbol(tail_node, ref_sym) != 0:
                live = 1

        if live == 0:
            self.remove_borrow_at(bi)
        else:
            bi = bi + 1

fn Sema.type_is_ephemeral_value(self: Sema, tid: i32) -> i32:
    if tid == 0:
        return 0
    let resolved = self.resolve_alias(tid)
    let tk = self.get_type_kind(resolved)
    if tk == TypeKind.TY_REF or tk == TypeKind.TY_SLICE:
        return 1
    if tk == TypeKind.TY_ARRAY:
        return self.type_is_ephemeral_value(self.get_type_d0(resolved))
    if tk == TypeKind.TY_TUPLE:
        let te_start = self.get_type_d0(resolved)
        let elem_count = self.get_type_d1(resolved)
        for ei in 0..elem_count:
            if self.type_is_ephemeral_value(self.type_extra.get((te_start + ei) as i64)) != 0:
                return 1
        return 0
    if tk == TypeKind.TY_GENERIC_INST:
        let base_sym = self.get_type_d0(resolved)
        if self.ephemeral_types.contains(base_sym):
            return 1
        let arg_count = self.get_type_d2(resolved)
        let arg_start = self.get_type_d1(resolved)
        for ai in 0..arg_count:
            if self.type_is_ephemeral_value(self.type_extra.get((arg_start + ai) as i64)) != 0:
                return 1
        return 0
    if tk == TypeKind.TY_STRUCT:
        let st_name = self.get_type_d0(resolved)
        if self.ephemeral_types.contains(st_name):
            return 1
        return 0
    0

// ── Helper functions ─────────────────────────────────────────────

fn Sema.infer_for_element_type(self: Sema, iter_type: i32) -> i32:
    if iter_type == 0:
        return 0
    let resolved = self.resolve_alias(iter_type as TypeId)
    let tk = self.get_type_kind(resolved)
    if tk == TypeKind.TY_RANGE:
        return self.get_type_d0(resolved)
    if tk == TypeKind.TY_ARRAY:
        return self.get_type_d0(resolved)
    if tk == TypeKind.TY_SLICE:
        return self.get_type_d0(resolved)
    if tk == TypeKind.TY_GENERIC_INST:
        let base_name = self.pool_resolve(self.get_type_d0(resolved))
        if base_name == "Vec" and self.get_generic_inst_arg_count(resolved as i32) > 0:
            return self.get_generic_inst_arg(resolved as i32, 0)
        if base_name == "VecIterRef" and self.get_generic_inst_arg_count(resolved as i32) > 0:
            let iref_elem = self.get_generic_inst_arg(resolved as i32, 0)
            return self.ensure_exact_type(TypeKind.TY_REF, iref_elem, 0, 0) as i32
        if base_name == "VecIterPlace" and self.get_generic_inst_arg_count(resolved as i32) > 0:
            let vip_elem = self.get_generic_inst_arg(resolved as i32, 0)
            var vip_slot = self.find_generic_inst(self.syms.vecslot, vip_elem)
            if vip_slot == 0:
                let vip_args: Vec[i32] = Vec.new()
                vip_args.push(vip_elem)
                vip_slot = self.ensure_generic_inst_type(self.syms.vecslot, vip_args, 1) as i32
            return vip_slot
    // Generic Iter[T] protocol: look up next() method on the type,
    // extract T from its Option[T] return type.
    let owner_sym = self.method_owner_symbol_for_type(resolved as i32)
    if owner_sym != 0:
        let next_sym = self.pool_lookup_symbol("next")
        if next_sym > 0:
            let sig_idx = self.lookup_method_sig(owner_sym, next_sym)
            if sig_idx >= 0:
                let ret_ty = self.sig_return_type(sig_idx)
                if ret_ty != 0:
                    let ret_resolved = self.resolve_alias(ret_ty as TypeId)
                    let ret_tk = self.get_type_kind(ret_resolved)
                    if ret_tk == TypeKind.TY_GENERIC_INST:
                        let ret_base = self.pool_resolve(self.get_type_d0(ret_resolved))
                        if ret_base == "Option" and self.get_generic_inst_arg_count(ret_resolved as i32) > 0:
                            return self.get_generic_inst_arg(ret_resolved as i32, 0)
    self.ty_i32 as i32

fn Sema.mark_moved_if_consumed(self: Sema, node: i32):
    if node == 0:
        return
    let kind = self.ast.kind(node)
    if kind == NodeKind.NK_FIELD_ACCESS:
        let field_ty_opt = self.typed_expr_types.get(node)
        let field_ty = if field_ty_opt.is_some(): field_ty_opt.unwrap() else: self.field_access_type_no_diagnostic(node)
        if field_ty != 0 and self.is_copy(field_ty as TypeId) == 0:
            let owner_sym = self.drop_owner_for_field_access(node)
            if owner_sym != 0 and self.has_drop_method(owner_sym) != 0:
                let field_sym = self.ast.get_data1(node)
                if self.current_drop_type_sym == owner_sym:
                    if self.drop_control_flow_depth != 0:
                        self.emit_error("field move inside drop cannot be conditional", node)
                        return
                    self.record_drop_consumed_field(owner_sym, field_sym)
                else:
                    self.emit_error("partial move from Drop type", node)
        return
    if kind == NodeKind.NK_IDENT:
        let sym = self.ast.get_data0(node)
        if self.scope_has(sym) != 0:
            let tid = self.scope_lookup(sym)
            if not self.is_copy(tid as TypeId):
                if sema_debug_move_enabled() != 0:
                    let resolved = self.resolve_alias(tid as TypeId)
                    let name = self.pool_resolve(sym)
                    with_eprint(
                        f"[move] sym={name} tid={tid} resolved={resolved as i32} kind={self.get_type_kind(resolved)}"
                    )
                self.scope_set_state(sym, VarState.MOVED)
    if kind == NodeKind.NK_GROUPED:
        self.mark_moved_if_consumed(self.ast.get_data0(node))
    // copy: source remains valid — do not mark as consumed.
    if kind == NodeKind.NK_COPY_ARG:
        return
    // move: binding already invalidated in check_expr; avoid double-processing.
    if kind == NodeKind.NK_MOVE_ARG:
        return

fn Sema.drop_owner_for_fn_symbol(self: Sema, fn_sym: i32) -> i32:
    let text = self.pool_resolve(fn_sym)
    if text.len() == 0:
        return 0
    let dot = sema_str_find_char(text, 46)
    if dot <= 0:
        return 0
    let method = text.slice((dot + 1) as i64, text.len())
    if method != "drop":
        return 0
    let owner_text = text.slice(0, dot as i64)
    let owner_sym = self.pool_intern(owner_text)
    if owner_sym != 0 and self.has_drop_method(owner_sym) != 0:
        return owner_sym
    0

fn Sema.drop_owner_for_field_access(self: Sema, node: i32) -> i32:
    if node == 0 or self.ast.kind(node) != NodeKind.NK_FIELD_ACCESS:
        return 0
    let base = self.ast.get_data0(node)
    var base_ty = 0
    let cached = self.typed_expr_types.get(base)
    if cached.is_some():
        base_ty = cached.unwrap()
    else:
        base_ty = self.check_expr(base) as i32
    if base_ty == 0:
        return 0
    var resolved = self.resolve_alias(base_ty as TypeId)
    let tk = self.get_type_kind(resolved)
    if tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF:
        resolved = self.resolve_alias(self.get_type_d0(resolved) as TypeId)
    self.method_owner_symbol_for_type(resolved as i32)

fn Sema.lookup_method_sig(self: Sema, type_sym: i32, method_sym: i32) -> i32:
    if type_sym <= 0 or method_sym <= 0:
        return -1
    let key = sema_pair_key(type_sym, method_sym)
    if self.method_lookup.sig_lookup.contains(key):
        return self.method_lookup.sig_lookup.get(key).unwrap()
    -1

fn Sema.lookup_method_fn(self: Sema, type_sym: i32, method_sym: i32) -> i32:
    if type_sym <= 0 or method_sym <= 0:
        return 0
    let key = sema_pair_key(type_sym, method_sym)
    if self.method_lookup.fn_lookup.contains(key):
        return self.method_lookup.fn_lookup.get(key).unwrap()
    0

// docs/mut.md Rev 8 §5.1 — returns 1 when the resolved (concrete) method
// for `type_sym.method_sym` was declared with `mut self: Self` (the parser
// records this via FN_PARAM_FLAG_MUT_SELF on the first param). Used by
// check_method_call to warn when a mutating receiver is invoked on a
// non-place or read-only-place receiver.
// docs/mut.md Rev 8 §15.8 — if `arg_node` is a method call to a fn marked
// `@[iter_of_self]`, register a SHARED borrow on the receiver's place root
// and return its index in the borrow vectors. Returns -1 otherwise. Caller
// is responsible for calling remove_borrow_at on the returned index after
// the enclosing call's arg-loop has finished (i.e., once the iterator and
// any sibling closures have been checked together).
fn Sema.maybe_register_iter_of_self_borrow(self: Sema, arg_node: i32) -> i32:
    if arg_node <= 0:
        return -1
    if self.ast.kind(arg_node) != NodeKind.NK_CALL:
        return -1
    let arg_callee = self.ast.get_data0(arg_node)
    if self.ast.kind(arg_callee) != NodeKind.NK_FIELD_ACCESS:
        return -1
    let recv = self.ast.get_data0(arg_callee)
    let method = self.ast.get_data1(arg_callee)
    let recv_root = self.place_root_sym(recv)
    if recv_root == 0:
        return -1
    var recv_ty = 0
    let recv_ty_opt = self.typed_expr_types.get(recv)
    if recv_ty_opt.is_some():
        recv_ty = recv_ty_opt.unwrap()
    else:
        recv_ty = self.check_expr(recv) as i32
    if recv_ty == 0:
        return -1
    let owner_sym = self.method_owner_symbol_for_type(recv_ty)
    if owner_sym == 0:
        return -1
    if self.method_is_iter_of_self_fn(owner_sym, method) == 0:
        return -1
    let pre_count = self.borrow_kinds.len() as i32
    let path_start = self.borrow_path_data.len() as i32
    self.check_borrow_create_direct(recv_root, BorrowKind.SHARED, 0, path_start, 0, arg_node)
    if (self.borrow_kinds.len() as i32) > pre_count:
        self.borrow_refs.set_i32(pre_count as i64, -1)
        return pre_count
    -1

// docs/mut.md Rev 8 §11.4 / §15.17 — returns 1 when the for-loop iterable
// is a .iter() call (or any iter_of_self method), meaning the iterator
// yields &T views rather than owned T values.
fn Sema.for_iterable_yields_views(self: Sema, iterable: i32) -> i32:
    if self.ast.kind(iterable) != NodeKind.NK_CALL:
        return 0
    let callee = self.ast.get_data0(iterable)
    if self.ast.kind(callee) != NodeKind.NK_FIELD_ACCESS:
        return 0
    let recv_node = self.ast.get_data0(callee)
    let method_sym = self.ast.get_data1(callee)
    var recv_type = 0
    if self.typed_expr_types.contains(recv_node):
        recv_type = self.typed_expr_types.get(recv_node).unwrap()
    if recv_type == 0:
        return 0
    let resolved = self.resolve_alias(recv_type as TypeId)
    let owner_sym = self.method_owner_symbol_for_type(resolved as i32)
    if owner_sym == 0:
        return 0
    self.method_is_iter_of_self_fn(owner_sym, method_sym)

// docs/mut.md Rev 8 §9.2 / §15.7 — when a call passes a mutating closure,
// check that no sibling argument retains access to the mutably captured place.
// §9.2 helper: when arg is `&sym.field` or `sym.field`, return the field sym.
// Returns 0 for whole-variable access (`&sym`, `sym`, `sym.iter()`).
// Returns -1 for no access to sym at all.
fn Sema.arg_accessed_field_of(self: Sema, arg_node: i32, sym: i32) -> i32:
    if arg_node == 0:
        return -1
    let kind = self.ast.kind(arg_node)
    if kind == NodeKind.NK_UNARY:
        let op = self.ast.get_data0(arg_node)
        if op == UnaryOp.UOP_REF or op == UnaryOp.UOP_RAW_REF_CONST or op == UnaryOp.UOP_RAW_REF_MUT:
            let operand = self.ast.get_data1(arg_node)
            if self.ast.kind(operand) == NodeKind.NK_FIELD_ACCESS:
                let base = self.ast.get_data0(operand)
                if self.ast.kind(base) == NodeKind.NK_IDENT and self.ast.get_data0(base) == sym:
                    return self.ast.get_data1(operand)
            if self.place_root_sym(operand) == sym:
                return 0
    if kind == NodeKind.NK_FIELD_ACCESS:
        let base = self.ast.get_data0(arg_node)
        if self.ast.kind(base) == NodeKind.NK_IDENT and self.ast.get_data0(base) == sym:
            return self.ast.get_data1(arg_node)
    if kind == NodeKind.NK_IDENT:
        if self.ast.get_data0(arg_node) == sym:
            return 0
    if kind == NodeKind.NK_GROUPED:
        return self.arg_accessed_field_of(self.ast.get_data0(arg_node), sym)
    -1

fn Sema.check_closure_capture_conflicts(self: Sema, extra_start: i32, arg_count: i32, has_resolved: i32, node: i32):
    // Collect closure args that mutably capture a place.
    var ci = 0
    while ci < arg_count:
        let closure_node = if has_resolved != 0: self.get_resolved_call_arg(node, ci) else: self.ast.get_extra(extra_start + ci)
        if closure_node <= 0 or self.ast.kind(closure_node) != NodeKind.NK_CLOSURE:
            ci = ci + 1
            continue
        let closure_body = self.ast.get_data0(closure_node)
        // Scan all in-scope variables for mutating captures.
        let bind_count = self.bind_names.len() as i32
        var bi = 0
        while bi < bind_count:
            let cap_sym = self.bind_names.get(bi as i64)
            if self.expr_mutates_place(closure_body, cap_sym) != 0:
                // §9.2: if the closure only accesses specific fields, use
                // field-level disjointness to avoid false conflicts.
                let field_only = self.capture_is_field_only(closure_body, cap_sym)
                var closure_field_count = 0
                if field_only != 0:
                    while self.capture_field_syms.len() > 0:
                        self.capture_field_syms.pop()
                        self.capture_field_kinds.pop()
                    self.collect_capture_fields(closure_body, cap_sym)
                    closure_field_count = self.capture_field_syms.len() as i32
                // Found a mutating capture. Check sibling args.
                var si = 0
                while si < arg_count:
                    if si == ci:
                        si = si + 1
                        continue
                    let sib_node = if has_resolved != 0: self.get_resolved_call_arg(node, si) else: self.ast.get_extra(extra_start + si)
                    if sib_node <= 0:
                        si = si + 1
                        continue
                    if self.arg_retains_access_to(sib_node, cap_sym) != 0:
                        var conflict = 1
                        if field_only != 0 and closure_field_count > 0:
                            let sib_field = self.arg_accessed_field_of(sib_node, cap_sym)
                            if sib_field > 0:
                                // Sibling accesses a specific field — check overlap
                                conflict = 0
                                var fi = 0
                                while fi < closure_field_count:
                                    if self.capture_field_syms.get(fi as i64) == sib_field:
                                        conflict = 1
                                        break
                                    fi = fi + 1
                        if conflict != 0:
                            let cap_name = self.pool_resolve(cap_sym)
                            self.emit_error("argument retains access to `" ++ cap_name ++ "` which is mutably captured by a closure in the same call (§15.7)", node)
                    si = si + 1
            bi = bi + 1
        ci = ci + 1

// Returns 1 when the expression retains access to the given symbol —
// i.e., the expression is or contains the symbol itself (owned move),
// a reference to it, or an iter-of-self call on it.
fn Sema.arg_retains_access_to(self: Sema, arg_node: i32, sym: i32) -> i32:
    if arg_node == 0:
        return 0
    let kind = self.ast.kind(arg_node)
    // Direct use of the symbol (owned move)
    if kind == NodeKind.NK_IDENT:
        if self.ast.get_data0(arg_node) == sym:
            return 1
        return 0
    // Reference to the symbol (&sym or &sym.field)
    if kind == NodeKind.NK_UNARY:
        let op = self.ast.get_data0(arg_node)
        if op == UnaryOp.UOP_REF or op == UnaryOp.UOP_RAW_REF_CONST or op == UnaryOp.UOP_RAW_REF_MUT:
            let operand = self.ast.get_data1(arg_node)
            if self.place_root_sym(operand) == sym:
                return 1
    // Method call that is iter_of_self (e.g., sym.iter())
    if kind == NodeKind.NK_CALL:
        let callee = self.ast.get_data0(arg_node)
        if self.ast.kind(callee) == NodeKind.NK_FIELD_ACCESS:
            let recv = self.ast.get_data0(callee)
            if self.ast.kind(recv) == NodeKind.NK_IDENT and self.ast.get_data0(recv) == sym:
                let method = self.ast.get_data1(callee)
                let cap_ty = self.scope_lookup(sym)
                if cap_ty >= 0:
                    let resolved = self.resolve_alias(cap_ty as TypeId)
                    var inner = resolved
                    let tk = self.get_type_kind(inner)
                    if tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF:
                        inner = self.resolve_alias(self.get_type_d0(inner) as TypeId)
                    let owner = self.method_owner_symbol_for_type(inner as i32)
                    if owner != 0 and self.method_is_iter_of_self_fn(owner, method) != 0:
                        return 1
    // Grouped expression
    if kind == NodeKind.NK_GROUPED:
        return self.arg_retains_access_to(self.ast.get_data0(arg_node), sym)
    0

// docs/mut.md Rev 8 §15.8 — returns 1 when the method's fn-decl is marked
// `@[iter_of_self]`, indicating the produced value retains access to its
// receiver place (e.g., Vec.iter, HashMap.entries). Used by check_call's
// arg-loop to register a SHARED borrow on the receiver place root for the
// duration of the enclosing call so that sibling closure mutations conflict.
fn Sema.method_is_iter_of_self_fn(self: Sema, type_sym: i32, method_sym: i32) -> i32:
    if self.builtin_method_is_iter_of_self(type_sym, method_sym) != 0:
        return 1
    let fn_sym = self.lookup_method_fn(type_sym, method_sym)
    if fn_sym == 0:
        return 0
    if not self.fn_decl_nodes.contains(fn_sym):
        return 0
    let fn_node = self.fn_decl_nodes.get(fn_sym).unwrap()
    self.ast.is_iter_of_self_fn_node(fn_node)

fn Sema.method_has_mut_self_flag(self: Sema, type_sym: i32, method_sym: i32) -> i32:
    let fn_sym = self.lookup_method_fn(type_sym, method_sym)
    if fn_sym == 0:
        return 0
    if not self.fn_decl_nodes.contains(fn_sym):
        return 0
    let fn_node = self.fn_decl_nodes.get(fn_sym).unwrap()
    let meta = self.ast.find_fn_meta(fn_node)
    if meta < 0:
        return 0
    let pc = self.ast.fn_meta_param_count(meta)
    if pc == 0:
        return 0
    let ps = self.ast.fn_meta_param_start(meta)
    let pflags = self.ast.fn_param_flags(ps, 0)
    fn_param_is_mut_self(pflags)

fn Sema.method_has_move_self_flag(self: Sema, type_sym: i32, method_sym: i32) -> i32:
    let fn_sym = self.lookup_method_fn(type_sym, method_sym)
    if fn_sym == 0:
        return 0
    if not self.fn_decl_nodes.contains(fn_sym):
        return 0
    let fn_node = self.fn_decl_nodes.get(fn_sym).unwrap()
    let meta = self.ast.find_fn_meta(fn_node)
    if meta < 0:
        return 0
    let pc = self.ast.fn_meta_param_count(meta)
    if pc == 0:
        return 0
    let ps = self.ast.fn_meta_param_start(meta)
    let pflags = self.ast.fn_param_flags(ps, 0)
    fn_param_is_move_self(pflags)

fn Sema.get_type_name(self: Sema, tid: TypeId) -> i32:
    let resolved = self.resolve_alias(tid)
    let tk = self.get_type_kind(resolved)
    if tk == TypeKind.TY_REF or tk == TypeKind.TY_PTR:
        return self.get_type_name(self.get_type_d0(resolved))
    if tk == TypeKind.TY_STRUCT:
        return self.get_type_d0(resolved)
    if tk == TypeKind.TY_ENUM:
        return self.get_type_d0(resolved)
    if tk == TypeKind.TY_GENERIC_INST:
        return self.get_type_d0(resolved)
    0

fn Sema.enum_repr_type(self: Sema, tid: i32) -> i32:
    let resolved = self.resolve_alias(tid)
    if self.get_type_kind(resolved) != TypeKind.TY_ENUM:
        return 0
    let opt = self.disc_repr_types.get(resolved as i32)
    if opt.is_some():
        return opt.unwrap()
    0
