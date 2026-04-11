// SemaCheck — type expression resolution, expression type checking, generic/trait resolution.

use Sema
use Ast
use BorrowCfg
use ComptimeEval
use ComptimeValue
use Span
use Diagnostic
use InternPool
use TypeLayout
use render

extern fn with_write(s: str) -> void
extern fn with_eprint(s: str) -> void
extern fn with_fs_file_exists(path: str) -> i32
extern fn with_str_eq(a: str, b: str) -> i32

fn sema_dirname(path: str) -> str:
    var last_slash = 0 - 1
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

    if kind == NodeKind.NK_TYPE_NAMED:
        let sym = self.ast.get_data0(node)
        let prim = self.primitive_type_by_sym(sym)
        if prim != 0:
            return prim as TypeId
        let named_tid = self.lookup_named_type_visible(sym)
        if named_tid != 0 and (self.collecting_types != 0 or self.is_ci_visible(sym) != 0):
            return named_tid as TypeId
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
        if self.ensure_trait_object_safe(trait_sym, node) == 0:
            return 0 as TypeId
        return self.ensure_exact_type(TypeKind.TY_TRAIT_OBJ, trait_sym, 0, 0)

    if kind == NodeKind.NK_TYPE_INFERRED:
        return 0 as TypeId

    // @TypeOf(expr) — in generic functions, resolved at monomorphization time
    // via resolve_generic_return_type_node. Return a placeholder here.
    if kind == NodeKind.NK_TYPE_TYPEOF:
        return self.ty_i32

    0 as TypeId

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
    if body_expected_ret != 0 and body_expected_ret != self.ty_void:
        self.expected_expr_type = body_expected_ret
        self.has_expected_type = 1
    let body_ty = self.check_expr(body)
    self.expected_expr_type = saved_expected_et
    self.has_expected_type = saved_has_et
    self.typed_expr_types.insert(body, body_ty as i32)
    let has_ret_annotation = meta >= 0 and self.ast.fn_meta_ret(meta) != 0
    if not has_ret_annotation:
        let inferred_ret = if body_ty != 0: body_ty else: self.ty_void
        self.set_sig_return_type(sig_idx, inferred_ret)
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

    // Restore state
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

// ── Concrete type-checking for monomorphized generic functions ───
// Type-checks a generic function body with concrete type substitutions,
// populating typed_expr_types so MirLower has type information.
// Returns the sig index for the concrete signature.

fn Sema.check_fn_body_concrete(self: Sema, fn_node: i32, tp_syms: Vec[i32], tp_sema_tys: Vec[i32], mono_sym: i32) -> i32:
    let fn_name = self.ast.get_data0(fn_node)
    let body = self.ast.get_data1(fn_node)
    let meta = self.ast.find_fn_meta(fn_node)
    if meta < 0:
        return 0 - 1

    let tp_count = tp_syms.len() as i32

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

    // Restore named_types
    for ti in 0..tp_count:
        let tp_sym = tp_syms.get(ti as i64)
        if saved_had.get(ti as i64) == 1:
            self.named_types.insert(tp_sym, saved_named.get(ti as i64))
        // Note: can't remove from HashMap, leave as-is if wasn't present before

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
        if op == UnaryOp.UOP_REF or op == UnaryOp.UOP_MUT_REF:
            return 1
        return self.expr_is_ephemeral_value(self.ast.get_data1(node))
    if kind == NodeKind.NK_SLICE:
        return 1
    if kind == NodeKind.NK_CALL:
        return self.expr_is_ephemeral_task(node)
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
        return self.ty_str

    if kind == NodeKind.NK_FSTRING:
        return self.check_fstring(node) as TypeId

    if kind == NodeKind.NK_C_STRING_LIT:
        return self.ty_const_i8_ptr

    if kind == NodeKind.NK_NULL_LIT:
        if self.has_expected_type != 0 and self.expected_expr_type != 0:
            let expected = self.resolve_alias(self.expected_expr_type)
            let expected_kind = self.get_type_kind(expected)
            if expected_kind == TypeKind.TY_PTR or expected_kind == TypeKind.TY_REF or self.is_option_pointer_type(expected) != 0:
                return expected
        return self.ty_const_i8_ptr

    if kind == NodeKind.NK_IDENT:
        return self.check_ident(self.ast.get_data0(node), node) as TypeId

    if kind == NodeKind.NK_BINARY:
        return self.check_binary(node) as TypeId

    if kind == NodeKind.NK_UNARY:
        return self.check_unary(node) as TypeId

    if kind == NodeKind.NK_GROUPED:
        return self.check_expr(self.ast.get_data0(node))

    if kind == NodeKind.NK_BLOCK:
        return self.check_block(node) as TypeId

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
        self.check_expr(cond)
        self.loop_depth = self.loop_depth + 1
        self.check_expr(body)
        self.loop_depth = self.loop_depth - 1
        return self.ty_void

    if kind == NodeKind.NK_LOOP:
        let saved_break = self.break_value_type
        let saved_has = self.has_break_value_type
        self.break_value_type = 0 as TypeId
        self.has_break_value_type = 0
        self.loop_depth = self.loop_depth + 1
        self.check_expr(self.ast.get_data0(node))
        self.loop_depth = self.loop_depth - 1
        var result = self.ty_void
        if self.has_break_value_type != 0:
            result = self.break_value_type
        self.break_value_type = saved_break
        self.has_break_value_type = saved_has
        return result

    if kind == NodeKind.NK_FOR:
        return self.check_for(node) as TypeId

    if kind == NodeKind.NK_BREAK:
        if self.in_defer != 0:
            self.emit_error("break not allowed in defer", node)
        if self.loop_depth == 0:
            self.emit_error("break outside of loop", node)
        let val = self.ast.get_data0(node)
        if val != 0:
            let vt = self.check_expr(val)
            if vt != 0:
                if self.has_break_value_type == 0:
                    self.break_value_type = vt
                    self.has_break_value_type = 1
                else:
                    if self.types_compatible(self.break_value_type, vt) == 0:
                        let widened = self.arithmetic_result_type(self.break_value_type, vt)
                        if widened == 0:
                            self.emit_error("type mismatch in break value", node)
                        else:
                            self.break_value_type = widened
                    else:
                        self.break_value_type = vt
        return self.ty_void

    if kind == NodeKind.NK_CONTINUE:
        if self.in_defer != 0:
            self.emit_error("continue not allowed in defer", node)
        if self.loop_depth == 0:
            self.emit_error("continue outside of loop", node)
        return self.ty_void

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
        self.check_expr_with_expected(self.ast.get_data0(node), 0 as TypeId)
        let cast_tid = self.resolve_type_expr(self.ast.get_data1(node))
        // Store resolved cast type so MIR lowering can read it without
        // calling resolve_type_expr (which would add_type on a shallow-copied Sema).
        self.typed_expr_types.insert(node, cast_tid as i32)
        return cast_tid

    if kind == NodeKind.NK_PIPELINE:
        return self.check_pipeline(node) as TypeId

    if kind == NodeKind.NK_UNSAFE_BLOCK:
        if self.in_comptime_fn != 0:
            self.emit_error("unsafe is not allowed in comptime", node)
        let saved_unsafe = self.in_unsafe
        self.in_unsafe = 1
        // Propagate expected type through unsafe block
        let unsafe_result = if self.has_expected_type != 0: self.check_expr_with_expected(self.ast.get_data0(node), self.expected_expr_type) else: self.check_expr(self.ast.get_data0(node))
        self.in_unsafe = saved_unsafe
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

    if kind == NodeKind.NK_WITH_IMPLICIT:
        return self.check_with_implicit(node) as TypeId

    if kind == NodeKind.NK_RECORD_UPDATE:
        return self.check_record_update(node) as TypeId

    if kind == NodeKind.NK_LET_ELSE:
        return self.check_let_else(node) as TypeId

    if kind == NodeKind.NK_TUPLE_DESTRUCTURE:
        return self.check_tuple_destructure(node) as TypeId

    if kind == NodeKind.NK_AWAIT:
        if self.in_async_fn == 0:
            self.emit_error("await requires async context", node)
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
        let ab_body_ty = self.check_expr(self.ast.get_data0(node))
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

    if kind == NodeKind.NK_ASYNC_SCOPE:
        let body = self.ast.get_data1(node)
        let name = self.ast.get_data0(node)
        self.push_scope()
        self.scope_put(name, self.ty_void, 0)
        self.async_scope_names.push(name)
        let result = self.check_expr(body)
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
            self.push_scope()
            self.scope_put(arm_name, task_ty as i32, 0)
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
        self.typed_expr_types.insert(node, tid)
        return tid

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
        let variant_expected_tid = self.expected_variant_constructor_type(sym)
        let variant_tid = if variant_expected_tid != 0: variant_expected_tid else: self.variant_type_ids.get(sym).unwrap()
        self.typed_expr_types.insert(node, variant_tid)
        return variant_tid

    // Unknown identifier — suggest close matches
    let target_name = self.pool_resolve(sym)
    let suggestion = self.suggest_name(target_name, node)
    self.emit_error_with_suggestion("undefined variable", node, suggestion)
    0

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
    else if op == BinaryOp.OP_ADD or op == BinaryOp.OP_SUB or op == BinaryOp.OP_MUL or op == BinaryOp.OP_DIV or op == BinaryOp.OP_MOD or
       op == BinaryOp.OP_ADD_WRAP or op == BinaryOp.OP_SUB_WRAP or op == BinaryOp.OP_MUL_WRAP or
       op == BinaryOp.OP_ADD_SAT or op == BinaryOp.OP_SUB_SAT or op == BinaryOp.OP_MUL_SAT or
       op == BinaryOp.OP_BIT_AND or op == BinaryOp.OP_BIT_OR or op == BinaryOp.OP_BIT_XOR or
       op == BinaryOp.OP_SHL or op == BinaryOp.OP_SHR:
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
        let wrap_op = if op == BinaryOp.OP_ADD: BinaryOp.OP_ADD_WRAP else: if op == BinaryOp.OP_SUB: BinaryOp.OP_SUB_WRAP else: BinaryOp.OP_MUL_WRAP
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
        // Pointer arithmetic: ptr + int → ptr, ptr - int → ptr
        let lhs_k = self.get_type_kind(self.resolve_alias(lhs))
        let rhs_k = self.get_type_kind(self.resolve_alias(rhs))
        if self.in_comptime_fn != 0 and (lhs_k == TypeKind.TY_PTR or rhs_k == TypeKind.TY_PTR):
            self.emit_error("raw pointer arithmetic is not allowed in comptime", node)
            return 0
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

    // Bitwise
    if op == BinaryOp.OP_BIT_AND or op == BinaryOp.OP_BIT_OR or op == BinaryOp.OP_BIT_XOR or op == BinaryOp.OP_SHL or op == BinaryOp.OP_SHR:
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
    let operand = self.check_expr(operand_node)
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
    if op == UnaryOp.UOP_REF or op == UnaryOp.UOP_MUT_REF:
        // Reject address-of bitpacked fields — they may not be byte-aligned
        if self.ast.kind(operand_node) == NodeKind.NK_FIELD_ACCESS:
            let ref_recv = self.ast.get_data0(operand_node)
            let ref_recv_ty = self.resolve_alias(self.check_expr(ref_recv))
            if self.bitpacked_types.contains(ref_recv_ty as i32):
                self.emit_error("cannot take address of bitpacked field", node)
                return 0
        if op == UnaryOp.UOP_REF:
            self.check_borrow_create(operand_node, BorrowKind.SHARED, node)
            return self.add_type(TypeKind.TY_REF, operand as i32, 0, 0) as i32
        self.check_borrow_create(operand_node, BorrowKind.EXCLUSIVE, node)
        return self.add_type(TypeKind.TY_REF, operand as i32, 1, 0) as i32
    if op == UnaryOp.UOP_DEREF:
        let resolved = self.resolve_alias(operand)
        let tk = self.get_type_kind(resolved)
        if tk == TypeKind.TY_REF:
            return self.get_type_d0(resolved)
        if tk == TypeKind.TY_PTR:
            return self.get_type_d0(resolved)
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

    self.push_scope()

    for i in 0..stmt_count:
        let stmt = self.ast.get_extra(extra_start + i)
        let saved_stmt_pos = self.match_in_stmt_pos
        self.match_in_stmt_pos = 1
        let stmt_ty = self.check_expr(stmt)
        self.match_in_stmt_pos = saved_stmt_pos
        self.typed_expr_types.insert(stmt, stmt_ty as i32)
        let stmt_kind = self.ast.kind(stmt)
        let can_discard_task = stmt_kind == NodeKind.NK_CALL or stmt_kind == NodeKind.NK_IDENT or stmt_kind == NodeKind.NK_GROUPED or stmt_kind == NodeKind.NK_ASYNC_BLOCK or stmt_kind == NodeKind.NK_TUPLE
        let is_discarded_task = can_discard_task and stmt_kind != NodeKind.NK_SPAWN and self.expr_is_task_value(stmt) != 0 and self.expr_is_scoped_task_value(stmt) == 0
        if is_discarded_task:
            self.emit_error("E0801: unused Task value", stmt)
        self.expire_dead_borrows_in_block(extra_start, stmt_count, i + 1, tail)

    var result: TypeId = self.ty_void
    if tail != 0:
        // If the tail is a match in a void/unspecified-return context, treat as statement
        // position so partial enum match is allowed (value is not used).
        let saved_stmt_pos = self.match_in_stmt_pos
        let ret_is_void = self.current_return_type == self.ty_void or self.current_return_type == 0
        if ret_is_void and self.ast.kind(tail) == NodeKind.NK_MATCH:
            self.match_in_stmt_pos = 1
        result = self.check_expr(tail)
        self.match_in_stmt_pos = saved_stmt_pos
        self.typed_expr_types.insert(tail, result as i32)
    self.expire_dead_borrows_in_block(extra_start, stmt_count, stmt_count, 0)

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

    self.scope_put_at(name, bind_type as i32, is_mut, node)
    self.typed_binding_types.insert(node, bind_type as i32)
    self.typed_binding_names.insert(node, name)
    self.typed_binding_muts.insert(node, is_mut)
    var is_task_val = self.expr_is_task_value(value)
    if is_task_val == 0:
        is_task_val = self.type_is_task(bind_type as i32)
    self.scope_set_is_task(name, is_task_val)
    self.scope_set_is_scoped_task(name, self.expr_is_scoped_task_value(value))
    self.scope_set_is_ephemeral_task(name, self.expr_is_ephemeral_task(value))

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
        if uop == UnaryOp.UOP_REF or uop == UnaryOp.UOP_MUT_REF:
            let blen = self.borrow_refs.len() as i32
            if blen > 0:
                self.borrow_refs.set_i32((blen - 1) as i64, name)

    self.ty_void as i32

fn Sema.check_if_expr(self: Sema, node: i32) -> i32:
    let cond = self.ast.get_data0(node)
    let then_body = self.ast.get_data1(node)
    let else_body = self.ast.get_data2(node)

    self.check_expr(cond)
    let outer_expected: TypeId = if self.has_expected_type != 0: self.expected_expr_type else: 0 as TypeId
    let then_type = if outer_expected != 0: self.check_expr_with_expected(then_body, outer_expected) else: self.check_expr(then_body)

    var result_type: TypeId = self.ty_void
    if else_body != 0:
        let else_expected: TypeId = if then_type != 0 and then_type != self.ty_void: then_type else: outer_expected
        let else_type = if else_expected != 0: self.check_expr_with_expected(else_body, else_expected) else: self.check_expr(else_body)
        if then_type != 0 and else_type != 0:
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
    if not self.fn_decl_nodes.contains(fn_sym):
        return 0
    let fn_node = self.fn_decl_nodes.get(fn_sym).unwrap()
    if self.ast.is_comptime_decl_node(fn_node) != 0:
        return 1
    let meta = self.ast.find_fn_meta(fn_node)
    if meta < 0:
        return 0
    let flags = self.ast.fn_meta_flags(meta)
    if (flags / FnFlags.COMPTIME) % 2 == 1:
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
        if self.fn_symbol_is_comptime(fn_sym) == 0:
            self.emit_error("comptime can only call comptime functions", node)
            return 1
    0

fn Sema.check_comptime_method_restriction(self: Sema, method_sym: i32, node: i32) -> i32:
    if self.in_comptime_fn == 0 or method_sym == 0:
        return 0
    if self.fn_symbol_is_comptime(method_sym) == 0:
        self.emit_error("comptime can only call comptime functions", node)
        return 1
    0

fn Sema.check_return(self: Sema, node: i32) -> i32:
    if self.in_defer != 0:
        self.emit_error("return not allowed in defer", node)
    let value = self.ast.get_data0(node)
    if value != 0:
        let val_type = if self.current_return_type != 0: self.check_expr_with_expected(value, self.current_return_type) else: self.check_expr(value)
        if self.current_return_type != 0 and val_type != 0:
            let compat = self.types_compatible(self.current_return_type as i32, val_type as i32)
            let arith = if compat == 0: self.arithmetic_result_type(self.current_return_type, val_type) else: 1 as TypeId
            if compat == 0:
                if arith == 0:
                    self.emit_error("return type mismatch", node)
    self.ty_void as i32

fn Sema.check_assign(self: Sema, node: i32) -> i32:
    let target = self.ast.get_data0(node)
    let value = self.ast.get_data1(node)

    let target_type = self.check_expr(target)
    let value_type = if target_type != 0: self.check_expr_with_expected(value, target_type) else: self.check_expr(value)

    // Multi-index assignment: a[i, j] = value → requires multi_index_set
    if self.ast.kind(target) == NodeKind.NK_MULTI_INDEX:
        let mi_base = self.ast.get_data0(target)
        let mi_base_resolved = self.resolve_alias(target_type)
        let mi_name = self.get_type_name(mi_base_resolved as i32)
        if mi_name != 0:
            let mis_sym = self.pool_intern("multi_index_set")
            let mis_sig = self.lookup_method_sig(mi_name, mis_sym)
            if mis_sig < 0:
                self.emit_error("type does not support indexed assignment (no multi_index_set method)", target)

    // Check mutability
    if self.ast.kind(target) == NodeKind.NK_IDENT:
        let target_sym = self.ast.get_data0(target)
        if self.scope_has(target_sym) != 0:
            if self.scope_lookup_mut(target_sym) == 0:
                self.emit_error("cannot assign to immutable variable", node)

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
        self.scope_set_is_task(target_sym, self.expr_is_task_value(value))
        self.scope_set_is_scoped_task(target_sym, self.expr_is_scoped_task_value(value))
        self.scope_set_is_ephemeral_task(target_sym, self.expr_is_ephemeral_task(value))

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

    self.push_scope()
    if self.ast.for_binding_is_pattern(node):
        self.check_pattern(binding, elem_type)
    else:
        self.scope_put(binding, elem_type, 0)
    let for_meta = self.ast.find_for_meta(node)
    if for_meta >= 0:
        let index_binding = self.ast.for_meta_index_binding(for_meta)
        if index_binding != 0:
            self.scope_put(index_binding, self.ty_i64 as i32, 0)
    self.loop_depth = self.loop_depth + 1
    self.check_expr(body)
    self.loop_depth = self.loop_depth - 1
    self.pop_scope()
    self.ty_void as i32

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

    let obj_type = self.check_expr(expr)

    if obj_type == 0:
        return 0

    let resolved = self.resolve_alias(obj_type)
    let tk = self.get_type_kind(resolved)

    // Auto-deref through ptrs and refs
    var field_base: TypeId = resolved
    if tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF:
        field_base = self.resolve_alias(self.get_type_d0(resolved) as TypeId)

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

    let resolved = self.resolve_alias(arr_type)
    let tk = self.get_type_kind(resolved)
    if tk == TypeKind.TY_PTR:
        self.check_runtime_index_operand(index)
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
                let arg_kind = self.ast.kind(index)
                var ci_arg_type = 0
                if arg_kind == NodeKind.NK_IDENT or arg_kind == NodeKind.NK_TYPE_NAMED:
                    let arg_sym = self.ast.get_data0(index)
                    let prim = self.primitive_type_by_sym(arg_sym)
                    if prim != 0:
                        ci_arg_type = prim
                    else:
                        ci_arg_type = self.lookup_named_type_visible(arg_sym)
                if ci_arg_type > 0:
                    // Check for second type arg (d2 of NodeKind.NK_INDEX) — HashMap[K, V]
                    let ci_index2 = self.ast.get_data2(node)
                    var ci_arg2_type = 0
                    if ci_index2 != 0:
                        let a2_kind = self.ast.kind(ci_index2)
                        if a2_kind == NodeKind.NK_IDENT or a2_kind == NodeKind.NK_TYPE_NAMED:
                            let a2_sym = self.ast.get_data0(ci_index2)
                            let a2_prim = self.primitive_type_by_sym(a2_sym)
                            if a2_prim != 0:
                                ci_arg2_type = a2_prim
                            else:
                                ci_arg2_type = self.lookup_named_type_visible(a2_sym)
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

fn Sema.check_multi_index(self: Sema, node: i32) -> i32:
    let base = self.ast.get_data0(node)
    let specs_start = self.ast.get_data1(node)
    let specs_count = self.ast.get_data2(node)
    let base_ty = self.check_expr(base)
    // Check each index spec
    for si in 0..specs_count:
        let spec = self.ast.get_extra(specs_start + si)
        let d0 = self.ast.get_data0(spec)
        let d1 = self.ast.get_data1(spec)
        let d2 = self.ast.get_data2(spec)
        let kind = d2 / INDEX_KIND_SHIFT
        if d0 != 0: self.check_expr(d0)
        if d1 != 0: self.check_expr(d1)
        let step = d2 - kind * INDEX_KIND_SHIFT
        if step != 0: self.check_expr(step)
    // Look up multi_index method on base type
    let base_resolved = self.resolve_alias(base_ty)
    let base_name = self.get_type_name(base_resolved as i32)
    if base_name != 0:
        let mi_sym = self.pool_intern("multi_index")
        let mi_sig = self.lookup_method_sig(base_name, mi_sym)
        if mi_sig >= 0:
            return self.sig_return_type(mi_sig)
    self.emit_error("type does not support multi-dimensional indexing", node)
    0

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
                let field_expected = if expected_struct_ty != 0: self.struct_field_type(expected_struct_ty as i32, f_name) else: 0
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
                            for fi in 0..fc:
                                let base = td_extra + 1 + fi * 3
                                let f_name_sym = self.ast.get_extra(base)
                                let f_type_node = self.ast.get_extra(base + 1)
                                if self.ast.kind(f_type_node) == NodeKind.NK_TYPE_NAMED:
                                    if self.ast.get_data0(f_type_node) == tp_name:
                                        // Match field name in literal to get value type
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
        if guard != 0:
            self.check_expr(guard)
        let arm_expected: TypeId = if result_type != 0: result_type else: match_expected
        let arm_type = if arm_expected != 0: self.check_expr_with_expected(arm_body, arm_expected) else: self.check_expr(arm_body)
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
    0 - 1

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
        let v_extra = self.ast.get_data1(node)
        if subject_enum_ty == 0:
            if bind_count != 0:
                self.emit_error("variant payload pattern requires an enum subject", node)
                return
            let value_sym = self.pattern_variant_value_sym(node, v_name)
            self.pattern_value_syms.insert(node, value_sym)
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
        var elem_start = 0
        var elem_count = 0
        let resolved = self.resolve_alias(subject_type)
        if self.get_type_kind(resolved) == TypeKind.TY_TUPLE:
            elem_start = self.get_type_d0(resolved)
            elem_count = self.get_type_d1(resolved)
        for ti in 0..t_count:
            let elem_ty = if ti < elem_count: self.type_extra.get((elem_start + ti) as i64) else: 0
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

    // `it` arity validation: if this is an implicit `it` closure (param_count==1,
    // param name is "__it") and the expected type is a fn with != 1 params, error.
    if param_count == 1 and self.has_expected_type != 0:
        let p_sym = self.ast.get_extra(extra_start)
        let p_name = self.pool_resolve(p_sym)
        if p_name == "__it":
            let expected = self.resolve_alias(self.expected_expr_type)
            if self.get_type_kind(expected) == TypeKind.TY_FN:
                let expected_params = self.get_type_d1(expected)
                if expected_params != 1:
                    self.emit_error(f"`it` used in context expecting {expected_params} parameter(s)", node)

    // Save borrow state — closure body borrows are local to the closure.
    let saved_borrow_len = self.borrow_kinds.len() as i32

    self.push_scope()
    let te_start = self.type_extra.len() as i32
    // Partial application: if body is NK_CALL, resolve callee param types for placeholders
    var partial_sig = 0 - 1
    if self.ast.kind(body) == NodeKind.NK_CALL:
        let call_callee = self.ast.get_data0(body)
        if self.ast.kind(call_callee) == NodeKind.NK_IDENT:
            let callee_sym = self.ast.get_data0(call_callee)
            partial_sig = self.get_sig(callee_sym)
    for pi in 0..param_count:
        let p_sym = self.ast.get_extra(extra_start + pi * 2)
        var p_ty = self.ty_i32 as i32
        // For partial app, find which call arg position this placeholder occupies
        if partial_sig >= 0 and self.ast.kind(body) == NodeKind.NK_CALL:
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
    self.check_expr(body)

    // Phase 1 ephemerality rule: closures cannot capture ephemeral refs/values.
    var bi = 0
    while bi < outer_count:
        let cap_sym = self.bind_names.get(bi as i64)
        if self.expr_uses_symbol(body, cap_sym) != 0:
            let cap_ty = self.bind_types.get(bi as i64)
            if self.type_is_ephemeral_value(cap_ty) != 0:
                self.emit_error("closures cannot capture ephemeral references", node)
                break
        bi = bi + 1
    self.pop_scope()

    // Restore borrow state — discard borrows created inside closure body.
    while self.borrow_kinds.len() as i32 > saved_borrow_len:
        self.borrow_kinds.pop()
        self.borrow_places.pop()
        self.borrow_fields.pop()
        self.borrow_refs.pop()
        self.borrow_path_starts.pop()
        self.borrow_path_counts.pop()

    // Mark non-escaping if this closure is a direct call argument
    let is_non_escaping = self.closure_direct_arg_depth > 0 and self.ast.is_move_closure(node) == 0
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
        var ci = 0
        while ci < outer_count:
            let cap_sym = self.bind_names.get(ci as i64)
            if self.expr_uses_symbol(body, cap_sym) != 0:
                let cap_ty = self.bind_types.get(ci as i64)
                if not self.is_copy(cap_ty as TypeId):
                    self.scope_set_state(cap_sym, VarState.MOVED)
            ci = ci + 1

    // Use callee return type for partial application closures
    var closure_ret_ty = self.ty_i32 as i32
    if partial_sig >= 0:
        closure_ret_ty = self.sig_return_type(partial_sig)
    self.add_type(TypeKind.TY_FN, te_start, param_count, closure_ret_ty) as i32

fn Sema.check_pipeline(self: Sema, node: i32) -> i32:
    let lhs = self.ast.get_data0(node)
    let rhs = self.ast.get_data1(node)
    self.check_expr(lhs)
    let saved = self.in_pipeline_rhs
    self.in_pipeline_rhs = 1
    let rhs_ty = self.check_expr(rhs)
    self.in_pipeline_rhs = saved
    if rhs_ty != 0:
        let resolved = self.resolve_alias(rhs_ty)
        if self.get_type_kind(resolved) == TypeKind.TY_FN:
            return self.get_type_d2(resolved)
    rhs_ty as i32

fn Sema.check_tuple(self: Sema, node: i32) -> i32:
    let extra_start = self.ast.get_data0(node)
    let elem_count = self.ast.get_data1(node)
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
    self.add_type(TypeKind.TY_RANGE, elem_type as i32, inclusive, 0) as i32

fn Sema.check_with_expr(self: Sema, node: i32) -> i32:
    let source = self.ast.get_data0(node)
    let body = self.ast.get_data1(node)
    let encoded_name = self.ast.get_data2(node)
    let name = decode_with_binding_sym(encoded_name)
    let is_mut = decode_with_binding_is_mut(encoded_name)
    let source_ty = self.check_expr(source)
    self.push_scope()
    self.scope_put(name, source_ty as i32, is_mut)
    let body_ty = self.check_expr(body)
    self.pop_scope()
    // Form 2 builder rule: `with <expr> as mut x:` returns `x` when body
    // ends in Unit; otherwise returns the final expression value.
    if is_mut != 0 and body_ty == self.ty_void:
        return source_ty as i32
    body_ty as i32

fn Sema.check_with_implicit(self: Sema, node: i32) -> i32:
    let source = self.ast.get_data0(node)
    let body = self.ast.get_data1(node)
    let binding_name = self.ast.get_data2(node)
    let source_ty = self.check_expr(source)
    // Push implicit binding onto stack
    self.implicit_binding_types.push(source_ty as i32)
    self.implicit_binding_syms.push(binding_name)
    self.push_scope()
    self.scope_put(binding_name, source_ty as i32, 0)
    let body_ty = self.check_expr(body)
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
    for fi in 0..field_count:
        let f_name = self.ast.get_extra(extra_start + fi * 2)
        let f_value = self.ast.get_extra(extra_start + fi * 2 + 1)
        self.check_expr(f_value)
    if source_ty != 0 and source_ty != self.ty_void:
        self.typed_expr_types.insert(node, source_ty as i32)
    source_ty as i32

fn Sema.check_let_else(self: Sema, node: i32) -> i32:
    let pattern = self.ast.get_data0(node)
    let value = self.ast.get_data1(node)
    let else_body = self.ast.get_data2(node)
    let val_type = self.check_expr(value)
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

fn Sema.check_callable_value_call(self: Sema, call_name: str, fn_tid: i32, node: i32, extra_start: i32, arg_count: i32, param_offset: i32, has_resolved: i32, arg_types: Vec[i32]) -> i32:
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

    // Method call: callee is field_access
    if self.ast.kind(callee) == NodeKind.NK_FIELD_ACCESS:
        let ret = self.check_method_call(callee, extra_start, arg_count, node)
        if ret != 0:
            self.typed_expr_types.insert(node, ret)
        return ret

    // Direct call: callee should be ident
    var fn_sym = 0
    var local_tid = 0 - 1
    var callable_value_tid = 0
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
    else:
        callable_value_tid = self.callable_fn_type(self.check_expr(callee) as TypeId)

    // Reject named args on closures and function pointers (spec §F4 rule 7)
    if self.ast.has_call_named_args(node) != 0:
        if callable_value_tid != 0:
            self.emit_error("named arguments are not supported for closures or function pointers", node)

    let param_offset = if self.in_pipeline_rhs != 0: 1 else: 0
    let sig_idx_raw = if self.generic_fn_nodes.contains(fn_sym): 0 - 1 else: self.get_sig(fn_sym)
    let sig_idx = if sig_idx_raw >= 0 and self.is_ci_visible(fn_sym) == 0: 0 - 1 else: sig_idx_raw
    let variant_expected_ty = if self.variant_lookup.contains(fn_sym) and self.is_ci_visible(fn_sym) != 0: self.expected_variant_constructor_type(fn_sym) else: 0
    let variant_payload_tys = if variant_expected_ty != 0: self.enum_variant_payload_types(variant_expected_ty, fn_sym) else: Vec.new()

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
                var matched = 0 - 1
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
            // Store resolved arg order in sema (AST is frozen)
            let final_args: Vec[i32] = Vec.new()
            for pi in param_offset..param_count:
                if resolved_map.contains(pi):
                    final_args.push(resolved_map.get(pi).unwrap())
                else:
                    final_args.push(0)
            self.store_resolved_call_args(node, final_args)
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
                        let final_args: Vec[i32] = Vec.new()
                        for pi in param_offset..param_count:
                            if resolved_map.contains(pi):
                                final_args.push(resolved_map.get(pi).unwrap())
                            else:
                                final_args.push(0)
                        self.store_resolved_call_args(node, final_args)
                        resolved_arg_count = param_count - param_offset

    // Check all arguments (with contextual expected-type propagation when
    // calling a known function signature).
    let has_resolved = self.has_resolved_call_args(node)
    let arg_types: Vec[i32] = Vec.new()
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
        if is_closure_arg:
            self.closure_direct_arg_depth = self.closure_direct_arg_depth + 1
        let arg_ty = if expected_ty != 0: self.check_expr_with_expected(arg_node, expected_ty as TypeId) else: self.check_expr(arg_node)
        if is_closure_arg:
            self.closure_direct_arg_depth = self.closure_direct_arg_depth - 1
        arg_types.push(arg_ty as i32)

    // Mark non-Copy args as moved
    for ai in 0..resolved_arg_count:
        let arg_node = if has_resolved != 0: self.get_resolved_call_arg(node, ai) else: self.ast.get_extra(resolved_extra_start + ai)
        if arg_node > 0:
            self.mark_moved_if_consumed(arg_node)

    if self.check_comptime_call_restriction(fn_sym, node) != 0:
        return 0

    // Known function
    if sig_idx >= 0:
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

        self.check_dyn_trait_call_compat(fn_sym, resolved_extra_start, arg_types, resolved_arg_count, param_offset)
        self.typed_expr_types.insert(node, ret)
        return ret

    if callable_value_tid != 0:
        let call_name = if self.ast.kind(callee) == NodeKind.NK_IDENT: self.pool_resolve(fn_sym) else: ""
        return self.check_callable_value_call(call_name, callable_value_tid, node, resolved_extra_start, resolved_arg_count, param_offset, has_resolved, arg_types)

    // Local variable (not callable)
    if local_tid >= 0:
        self.emit_error("value is not callable", callee)
        return 0

    // Generic function
    if self.generic_fn_nodes.contains(fn_sym):
        let fn_node = self.generic_fn_nodes.get(fn_sym).unwrap()
        let ret = self.check_generic_call(fn_sym, fn_node, arg_types, arg_count, node)
        self.typed_expr_types.insert(node, ret)
        return ret

    // Enum variant constructor
    if self.variant_lookup.contains(fn_sym):
        let inferred_variant_ty = self.infer_generic_enum_variant_type(fn_sym, arg_types, arg_count)
        let variant_tid = self.variant_type_ids.get(fn_sym).unwrap()
        var final_variant_ty: TypeId = if variant_expected_ty != 0: variant_expected_ty as TypeId else: variant_tid as TypeId
        if inferred_variant_ty != 0:
            final_variant_ty = self.preferred_compatible_type(final_variant_ty, inferred_variant_ty as TypeId)
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

fn Sema.check_dyn_trait_call_compat(self: Sema, fn_sym: i32, call_extra_start: i32, arg_types: Vec[i32], arg_count: i32, param_offset: i32):
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
        let where_start = self.ast.where_meta.get((where_idx + 1) as i64)
        let where_count = self.ast.where_meta.get((where_idx + 2) as i64)
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

fn Sema.put_generic_subst(self: Sema, param_sym: i32, tid: i32, node: i32):
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
        let gi_args: Vec[i32] = Vec.new()
        for gi in 0..gi_argc:
            let ga_node = self.ast.get_extra(gi_extra + gi)
            let ga_tid = self.resolve_generic_return_type_node(ga_node, tp_start, tp_count)
            if ga_tid == 0:
                return 0
            gi_args.push(ga_tid)
        return self.ensure_generic_inst_type(gi_base, gi_args, gi_argc) as i32

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
    if trait_sym == self.syms.copy:
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

fn Sema.builtin_method_requires_mutable_receiver(self: Sema, type_name_sym: i32, field: i32) -> i32:
    let _ = self
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
    let obj_type = self.check_expr(expr)
    let static_type_sym = self.static_receiver_base_sym(expr)

    if obj_type != 0 and static_type_sym != 0 and self.static_receiver_type_is_known(expr) != 0:
        let static_type_result = self.check_static_type_method_call(obj_type as i32, field, extra_start, arg_count, node)
        if static_type_result != 0:
            if static_type_result < 0:
                return 0
            return static_type_result
        if static_type_result < 0:
            return 0
    

    // Check all arguments (with expected-type propagation for Atomic ordering params)
    let mc_order_type = self.resolve_atomic_order_type(obj_type as i32)
    let arg_types: Vec[i32] = Vec.new()
    for ai in 0..arg_count:
        let mc_arg_node = self.ast.get_extra(extra_start + ai)
        let mc_is_closure = self.ast.kind(mc_arg_node) == NodeKind.NK_CLOSURE
        if mc_is_closure:
            self.closure_direct_arg_depth = self.closure_direct_arg_depth + 1
        let mc_expected = self.atomic_method_expected_arg_type(mc_order_type, field, ai)
        let mc_arg_ty = if mc_expected != 0: self.check_expr_with_expected(mc_arg_node, mc_expected as TypeId) else: self.check_expr(mc_arg_node)
        arg_types.push(mc_arg_ty as i32)
        if mc_is_closure:
            self.closure_direct_arg_depth = self.closure_direct_arg_depth - 1

    // Validate atomic ordering constraints (spec §14.17.1)
    if mc_order_type != 0:
        self.validate_atomic_ordering(field, extra_start, arg_count, node)

    // Task/ScopedTask surface methods (spec §14.7): cancel(), is_done().
    if field == self.syms.cancel or field == self.syms.is_done:
        if self.expr_is_task_value(expr) == 0 and self.expr_is_scoped_task_value(expr) == 0:
            return 0
        if arg_count != 0:
            self.emit_error("task method expects zero arguments", node)
            return 0
        if field == self.syms.cancel:
            return self.ty_void as i32
        return self.ty_bool as i32

    if field == self.syms.track:
        if self.ast.kind(expr) != NodeKind.NK_IDENT or self.is_active_async_scope_symbol(self.ast.get_data0(expr)) == 0:
            self.emit_error("track() is only available inside async scope", node)
            return 0
        if arg_count <= 0:
            self.emit_error("track() requires a Task value", node)
            return 0
        let task_arg = self.ast.get_extra(extra_start)
        if self.expr_is_task_value(task_arg) == 0:
            self.emit_error("track() requires a Task value", task_arg)
        return arg_types.get(0)

    if obj_type == 0:
        return 0

    let resolved = self.resolve_alias(obj_type)
    // Normalize method receivers through one layer of ref/ptr so builtin
    // method typing matches field access auto-deref behavior.
    var recv_type = resolved
    let resolved_tk0 = self.get_type_kind(recv_type)
    if resolved_tk0 == TypeKind.TY_PTR or resolved_tk0 == TypeKind.TY_REF:
        recv_type = self.resolve_alias(self.get_type_d0(recv_type) as TypeId)
    let type_name_sym = self.get_type_name(recv_type)
    if type_name_sym != 0:
        if self.builtin_method_requires_mutable_receiver(type_name_sym, field) != 0:
            if self.is_shared_ref_like_receiver(obj_type as i32) != 0:
                self.emit_builtin_mutable_receiver_error(type_name_sym, field, node)
                return 0
            if self.ast.kind(expr) == NodeKind.NK_UNARY and self.ast.get_data0(expr) == UnaryOp.UOP_DEREF:
                let deref_ty = self.resolve_alias(self.check_expr(self.ast.get_data1(expr)) as TypeId)
                let deref_tk = self.get_type_kind(deref_ty)
                if (deref_tk == TypeKind.TY_PTR or deref_tk == TypeKind.TY_REF) and self.get_type_d1(deref_ty) == 0:
                    self.emit_builtin_mutable_receiver_error(type_name_sym, field, node)
                    return 0

    // Static enum variant constructor: Shape.Rect(1, 2), Option[i32].Some(1)
    if self.static_receiver_type_is_known(expr) != 0 and self.enum_has_variant(obj_type, field) != 0:
        let payload_tys = self.enum_variant_payload_types(obj_type, field)
        let expected = payload_tys.len() as i32
        if arg_count != expected:
            let owner_name = self.type_name(obj_type)
            let variant_name = self.pool_resolve(field)
            self.emit_error(f"enum variant constructor '{owner_name}.{variant_name}' expects {expected} argument(s), found {arg_count}", node)
        for ai in 0..arg_count:
            if ai >= expected:
                break
            let expected_ty = payload_tys.get(ai as i64)
            let arg_ty = arg_types.get(ai as i64)
            if expected_ty != 0 and arg_ty != 0:
                if self.types_compatible(expected_ty, arg_ty) == 0:
                    if self.arithmetic_result_type(expected_ty, arg_ty) == 0:
                        let owner_name = self.type_name(obj_type)
                        let variant_name = self.pool_resolve(field)
                        self.emit_argument_type_mismatch(owner_name ++ "." ++ variant_name, field, ai, ai, expected_ty, arg_ty, self.ast.get_extra(extra_start + ai))
        return obj_type as i32

    if type_name_sym != 0:
        let method_fn_sym = self.lookup_method_fn(type_name_sym, field)
        let sig_idx = self.lookup_method_sig(type_name_sym, field)
        if sig_idx >= 0:
            if self.check_comptime_method_restriction(method_fn_sym, node) != 0:
                return 0
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
                    let mc_sig_poff = if mc_sig_pc > 0: 1 else 0
                    for mc_ai in 0..arg_count:
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
                                        self.emit_argument_type_mismatch(mc_method_name, method_fn_sym, mc_ai, mc_sig_pi, exp_ty, arg_ty, self.ast.get_extra(extra_start + mc_ai))
                let mc_subst_ret = self.substitute_method_return_for_generic_inst(recv_type, type_name_sym, field, method_fn_sym, mc_ret)
                if mc_subst_ret != 0:
                    return mc_subst_ret
            return mc_ret

    // For TypeKind.TY_GENERIC_INST receivers without a registered signature,
    // check argument types and return types for builtin generic methods
    if self.get_type_kind(recv_type) == TypeKind.TY_GENERIC_INST:
        let mc_call_name = self.pool_resolve(type_name_sym) ++ "." ++ self.pool_resolve(field)
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
        // Return types for builtin generic methods
        if type_name_sym == self.syms.vec:
            if field == self.syms.push or field == self.syms.set_i32 or field == self.syms.clear:
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
        if type_name_sym == self.syms.veciter:
            if field == self.syms.next:
                let next_elem_ty = self.get_generic_inst_arg(recv_type, 0)
                let next_tid = self.find_generic_inst(self.syms.option, next_elem_ty)
                if next_tid != 0:
                    return next_tid
                let next_args: Vec[i32] = Vec.new()
                next_args.push(next_elem_ty)
                return self.ensure_generic_inst_type(self.syms.option, next_args, 1) as i32
        if type_name_sym == self.syms.hashmap:
            if field == self.syms.insert or field == self.syms.clear:
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
        if type_name_sym == self.syms.hashset:
            if field == self.syms.insert or field == self.syms.clear:
                return self.ty_void as i32
            if field == self.syms.contains or field == self.syms.remove:
                return self.ty_bool as i32
            if field == self.syms.len:
                return self.ty_i64 as i32
        if type_name_sym == self.syms.option:
            if field == self.syms.unwrap:
                return self.get_generic_inst_arg(recv_type, 0)
            if field == self.syms.is_some or field == self.syms.is_none:
                return self.ty_bool as i32
        if type_name_sym == self.syms.result:
            if field == self.syms.unwrap:
                return self.get_generic_inst_arg(recv_type, 0)
            if field == self.syms.is_ok or field == self.syms.is_err:
                return self.ty_bool as i32

    // Return types for primitive type methods
    let resolved_tk = self.get_type_kind(recv_type)
    if resolved_tk == TypeKind.TY_STR:
        if field == self.syms.len:
            return self.ty_i32 as i32
        if field == self.syms.contains or field == self.syms.starts_with or field == self.syms.ends_with:
            return self.ty_bool as i32
        if field == self.syms.trim or field == self.syms.to_lower or field == self.syms.to_upper or field == self.syms.replace or field == self.syms.slice:
            return self.ty_str as i32
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
            return self.sig_return_type(sig_idx)

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
        let path_value = comptime_force_eval_expr(self as *mut Sema, &mut self.diags, self.ast, self.pool, path_node)
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
    let _ = self
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
        return 0 - 1
    let te_start = self.get_type_d1(resolved)
    let variant_count = self.get_type_d2(resolved)
    if variant_index < 0 or variant_index >= variant_count:
        return 0 - 1
    var pos = te_start
    for vi in 0..variant_count:
        if vi == variant_index:
            return pos
        let payload_count = self.type_extra.get((pos + 1) as i64)
        pos = pos + 2 + payload_count
    0 - 1

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
    let name_sym = self.type_reflection_variant_name(tid, variant_index)
    if name_sym == 0:
        return 0
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
            return 0 - 1
        self.typed_expr_types.insert(node, self.ty_str as i32)
        return self.ty_str as i32

    if field == self.syms.size or field == self.syms.align:
        if arg_count != 0:
            self.emit_error("type size/align methods take no arguments", node)
            return 0 - 1
        self.typed_expr_types.insert(node, self.ty_usize as i32)
        return self.ty_usize as i32

    if field == self.syms.implements:
        if arg_count != 1:
            self.emit_error("type.implements() expects exactly one trait argument", node)
            return 0 - 1
        let trait_node = self.ast.get_extra(extra_start)
        if trait_node == 0:
            self.emit_error("type.implements() requires a trait name", node)
            return 0 - 1
        let trait_kind = self.ast.kind(trait_node)
        if trait_kind != NodeKind.NK_IDENT and trait_kind != NodeKind.NK_TYPE_NAMED:
            self.emit_error("type.implements() requires a trait name", trait_node)
            return 0 - 1
        let trait_sym = self.ast.get_data0(trait_node)
        if not self.lang_trait_syms.contains(trait_sym) and not self.trait_lookup.contains(trait_sym):
            self.emit_error("unknown trait '" ++ self.pool_resolve(trait_sym) ++ "'", trait_node)
            return 0 - 1
        self.typed_expr_types.insert(node, self.ty_bool as i32)
        return self.ty_bool as i32

    if field == self.syms.is_copy:
        if arg_count != 0:
            self.emit_error("type.is_copy() takes no arguments", node)
            return 0 - 1
        self.typed_expr_types.insert(node, self.ty_bool as i32)
        return self.ty_bool as i32

    if field == self.syms.fields:
        if arg_count != 0:
            self.emit_error("type.fields() takes no arguments", node)
            return 0 - 1
        let resolved = self.resolve_alias(obj_type)
        let tk = self.get_type_kind(resolved)
        if tk != TypeKind.TY_STRUCT and tk != TypeKind.TY_GENERIC_INST:
            self.emit_error("type.fields() requires a struct type", node)
            return 0 - 1
        let field_count = self.type_reflection_field_count(obj_type)
        let result = self.ensure_exact_type(TypeKind.TY_ARRAY, self.ty_field_info as i32, field_count, 0)
        self.typed_expr_types.insert(node, result as i32)
        return result as i32

    let base_tid = self.type_reflection_variant_base(obj_type)
    if arg_count != 0:
        self.emit_error("type.variants() takes no arguments", node)
        return 0 - 1
    if base_tid == 0:
        self.emit_error("type.variants() requires an enum type", node)
        return 0 - 1
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
    // NodeKind.NK_IDENT, NodeKind.NK_INDEX, NodeKind.NK_GROUPED: no field to add

fn Sema.borrow_field(self: Sema, node: i32) -> i32:
    if node == 0:
        return 0
    if self.ast.kind(node) == NodeKind.NK_FIELD_ACCESS:
        return self.ast.get_data1(node)
    0

// Two borrows are disjoint if their field paths diverge at some level.
// A zero-length path (whole variable) overlaps with everything.
fn Sema.are_borrows_disjoint_paths(self: Sema, start_a: i32, count_a: i32, start_b: i32, count_b: i32) -> i32:
    if count_a == 0 or count_b == 0:
        return 0
    let min_count = if count_a < count_b: count_a else: count_b
    var i = 0
    while i < min_count:
        let fa = self.borrow_path_data.get((start_a + i) as i64)
        let fb = self.borrow_path_data.get((start_b + i) as i64)
        if fa != fb:
            return 1
        i = i + 1
    // One is a prefix of the other — overlapping
    0

fn Sema.are_borrows_disjoint(self: Sema, new_field: i32, existing_field: i32) -> i32:
    let _ = self
    if new_field == 0 or existing_field == 0:
        return 0
    if new_field != existing_field:
        return 1
    0

fn Sema.check_borrow_create(self: Sema, operand_node: i32, kind: i32, err_node: i32):
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

// Register a borrow with pre-computed place/kind/field/path.
// Used by closure capture registration.
fn Sema.check_borrow_create_direct(self: Sema, place: i32, kind: i32, field: i32, path_start: i32, path_count: i32, err_node: i32):
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
        else:
            self.emit_error("cannot borrow mutably: already borrowed", err_node)
        return
    self.borrow_kinds.push(kind)
    self.borrow_places.push(place)
    self.borrow_fields.push(field)
    self.borrow_refs.push(0)
    self.borrow_path_starts.push(path_start)
    self.borrow_path_counts.push(path_count)

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
    self.borrow_kinds.pop()
    self.borrow_places.pop()
    self.borrow_fields.pop()
    self.borrow_refs.pop()
    self.borrow_path_starts.pop()
    self.borrow_path_counts.pop()

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
    if kind == NodeKind.NK_UNARY:
        return self.expr_uses_symbol(self.ast.get_data1(node), sym)
    if kind == NodeKind.NK_GROUPED or kind == NodeKind.NK_AWAIT or kind == NodeKind.NK_ASYNC_BLOCK or kind == NodeKind.NK_SPAWN or kind == NodeKind.NK_DEFER or kind == NodeKind.NK_ERRDEFER or kind == NodeKind.NK_YIELD or kind == NodeKind.NK_COMPTIME:
        return self.expr_uses_symbol(self.ast.get_data0(node), sym)
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
    // &mut borrow of sym
    if kind == NodeKind.NK_UNARY:
        let op = self.ast.get_data0(node)
        if op == UnaryOp.UOP_MUT_REF:
            let operand = self.ast.get_data1(node)
            if self.place_root_sym(operand) == sym:
                return 1
        return self.expr_mutates_place(self.ast.get_data1(node), sym)
    // Recursive cases
    if kind == NodeKind.NK_BINARY:
        if self.expr_mutates_place(self.ast.get_data1(node), sym) != 0:
            return 1
        return self.expr_mutates_place(self.ast.get_data2(node), sym)
    if kind == NodeKind.NK_BLOCK:
        let extra_start = self.ast.get_data0(node)
        let stmt_count = self.ast.get_data1(node)
        let tail = self.ast.get_data2(node)
        for si in 0..stmt_count:
            if self.expr_mutates_place(self.ast.get_extra(extra_start + si), sym) != 0:
                return 1
        return self.expr_mutates_place(tail, sym)
    if kind == NodeKind.NK_IF_EXPR:
        if self.expr_mutates_place(self.ast.get_data0(node), sym) != 0:
            return 1
        if self.expr_mutates_place(self.ast.get_data1(node), sym) != 0:
            return 1
        return self.expr_mutates_place(self.ast.get_data2(node), sym)
    if kind == NodeKind.NK_CALL:
        if self.expr_mutates_place(self.ast.get_data0(node), sym) != 0:
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
    if kind == NodeKind.NK_FOR:
        if self.expr_mutates_place(self.ast.get_data1(node), sym) != 0:
            return 1
        return self.expr_mutates_place(self.ast.get_data2(node), sym)
    0

// Get the root symbol of a place expression (ident, field access chain, index).
fn Sema.place_root_sym(self: Sema, node: i32) -> i32:
    if node == 0:
        return 0
    let kind = self.ast.kind(node)
    if kind == NodeKind.NK_IDENT:
        return self.ast.get_data0(node)
    if kind == NodeKind.NK_FIELD_ACCESS or kind == NodeKind.NK_COMPUTED_FIELD_ACCESS or kind == NodeKind.NK_INDEX or kind == NodeKind.NK_GROUPED:
        return self.place_root_sym(self.ast.get_data0(node))
    0

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
    if kind == NodeKind.NK_UNARY:
        let operand = self.ast.get_data1(node)
        // &mut sym.field or &sym.field — check the operand
        return self.capture_is_field_only(operand, sym)
    if kind == NodeKind.NK_CALL:
        if self.capture_is_field_only(self.ast.get_data0(node), sym) == 0:
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
        if op == UnaryOp.UOP_MUT_REF:
            // &mut sym.field — mark field as exclusive
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
    if kind == NodeKind.NK_BLOCK:
        let ea = self.ast.get_data0(node)
        let sc = self.ast.get_data1(node)
        let tail = self.ast.get_data2(node)
        for si in 0..sc:
            self.collect_capture_fields(self.ast.get_extra(ea + si), sym)
        self.collect_capture_fields(tail, sym)
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
    var bi = 0
    while bi < self.borrow_refs.len() as i32:
        let ref_sym = self.borrow_refs.get(bi as i64)
        if ref_sym == 0:
            // Unnamed temporary borrows (e.g. &mut x as *mut T passed to a call)
            // have no named reference holding them, so they expire at statement
            // boundaries — the borrow is consumed by the enclosing expression.
            self.remove_borrow_at(bi)
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
    if tk == TypeKind.TY_STRUCT:
        let st_name = self.get_type_d0(resolved)
        if self.ephemeral_types.contains(st_name):
            return 1
        let te_start = self.get_type_d1(resolved)
        let field_count = self.get_type_d2(resolved)
        for fi in 0..field_count:
            let ft = self.type_extra.get((te_start + fi * 3 + 1) as i64)
            if self.type_is_ephemeral_value(ft) != 0:
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
    self.ty_i32 as i32

fn Sema.mark_moved_if_consumed(self: Sema, node: i32):
    if node == 0:
        return
    let kind = self.ast.kind(node)
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

fn Sema.lookup_method_sig(self: Sema, type_sym: i32, method_sym: i32) -> i32:
    if type_sym <= 0 or method_sym <= 0:
        return 0 - 1
    let key = sema_pair_key(type_sym, method_sym)
    if self.method_lookup.sig_lookup.contains(key):
        return self.method_lookup.sig_lookup.get(key).unwrap()
    0 - 1

fn Sema.lookup_method_fn(self: Sema, type_sym: i32, method_sym: i32) -> i32:
    if type_sym <= 0 or method_sym <= 0:
        return 0
    let key = sema_pair_key(type_sym, method_sym)
    if self.method_lookup.fn_lookup.contains(key):
        return self.method_lookup.fn_lookup.get(key).unwrap()
    0

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
