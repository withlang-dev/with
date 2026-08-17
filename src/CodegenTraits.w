use Codegen
use Ast
use Mir
use Sema
use InternPool
use Diagnostic
use Source
use Overflow
use AnalysisTypes
use compiler.TrackedInputs

extern fn with_str_clone_ref(s: &str) -> str
extern fn with_eprint(s: &str) -> Unit

// ── Collect trait info ────────────────────────────────────────────

impl Codegen:
    fn collect_trait_info(trait_node: i32):
        let name_sym = self.pool.get_data0(trait_node)
        let extra_start = self.pool.get_data1(trait_node)
        if self.trait_map.get(name_sym).is_some():
            return

        var pos = extra_start
        let tp_count = self.pool.get_extra(pos)
        let tp_start_ast = self.pool.get_extra(pos + 1)
        pos = pos + 2
        let tp_flat_start = self.trait_tp_flat_syms.len() as i32
        self.trait_tp_starts.insert(name_sym, tp_flat_start)
        self.trait_tp_counts.insert(name_sym, tp_count)
        var tp_pos = tp_start_ast
        for tpi in 0..tp_count:
            self.trait_tp_flat_syms.push(self.pool.get_extra(tp_pos))
            let bc = self.pool.get_extra(tp_pos + 1)
            tp_pos = tp_pos + 2 + bc
        // Method records are TRAIT_METHOD_STRIDE wide; read them through the
        // canonical AstPool accessors. A hand-rolled walk here silently drifted
        // when the record gained parser-owned source spans (6 → 8 slots),
        // corrupting every method after the first.
        let method_count = self.pool.trait_method_count(trait_node)

        let method_start = self.trait_method_names.len() as i32
        let ptr_ty = wl_ptr_type(self.context)
        let vtable_fields: Vec[i64] = Vec.new()

        for mi in 0..method_count:
            let method_sym = self.pool.trait_method_field(trait_node, mi, TRAIT_METHOD_NAME)
            let method_flags = self.pool.trait_method_field(trait_node, mi, TRAIT_METHOD_FLAGS)
            let method_param_start = self.pool.trait_method_field(trait_node, mi, TRAIT_METHOD_PARAM_START)
            let method_param_count = self.pool.trait_method_field(trait_node, mi, TRAIT_METHOD_PARAM_COUNT)
            let method_ret_node = self.pool.trait_method_field(trait_node, mi, TRAIT_METHOD_RETURN_TYPE)
            let method_default_body = self.pool.trait_method_field(trait_node, mi, TRAIT_METHOD_DEFAULT_BODY)

            self.trait_method_names.push(method_sym)
            self.trait_method_flags.push(method_flags)
            self.trait_method_param_starts.push(method_param_start)
            // Trait signatures may mention Self, associated types, or the trait's
            // own type parameters. Those only become concrete in an impl-specific
            // context, so collecting trait metadata must not try to lower them.
            self.trait_method_ret_types.push(0)
            self.trait_method_ret_nodes.push(method_ret_node)
            self.trait_method_param_counts.push(method_param_count)
            self.trait_method_default_bodies.push(method_default_body)
            vtable_fields.push(ptr_ty)

        let vtable_ty = wl_struct_type(self.context, vec_data_i64(&vtable_fields), method_count, 0)
        let trait_idx = self.trait_vtable_types.len() as i32
        self.trait_vtable_types.push(vtable_ty)
        self.trait_method_starts.push(method_start)
        self.trait_method_counts.push(method_count)
        self.trait_map.insert(name_sym, trait_idx)
        self.trait_idx_syms.push(name_sym)
        self.trait_decl_nodes.insert(name_sym, trait_node)

    fn audit_trait_method_row(trait_name: &str, trait_node: i32, trait_idx: i32, method_start: i32, method_idx: i32):
        let row = method_start + method_idx
        let ast_name = self.pool.trait_method_field(trait_node, method_idx, TRAIT_METHOD_NAME)
        let ast_flags = self.pool.trait_method_field(trait_node, method_idx, TRAIT_METHOD_FLAGS)
        let ast_param_start = self.pool.trait_method_field(trait_node, method_idx, TRAIT_METHOD_PARAM_START)
        let ast_param_count = self.pool.trait_method_field(trait_node, method_idx, TRAIT_METHOD_PARAM_COUNT)
        let ast_ret_node = self.pool.trait_method_field(trait_node, method_idx, TRAIT_METHOD_RETURN_TYPE)
        let ast_default_body = self.pool.trait_method_field(trait_node, method_idx, TRAIT_METHOD_DEFAULT_BODY)
        let collected_name = self.trait_method_names.get(row as i64)
        let collected_flags = self.trait_method_flags.get(row as i64)
        let collected_param_start = self.trait_method_param_starts.get(row as i64)
        let collected_param_count = self.trait_method_param_counts.get(row as i64)
        let collected_ret_node = self.trait_method_ret_nodes.get(row as i64)
        let collected_default_body = self.trait_method_default_bodies.get(row as i64)
        if collected_name != ast_name:
            self.analysis_fail(f"trait table {trait_name} index={trait_idx} method={method_idx}: name={collected_name} AST={ast_name}")
        if collected_flags != ast_flags:
            self.analysis_fail(f"trait table {trait_name} index={trait_idx} method={method_idx}: flags={collected_flags} AST={ast_flags}")
        if collected_param_start != ast_param_start:
            self.analysis_fail(f"trait table {trait_name} index={trait_idx} method={method_idx}: param-start={collected_param_start} AST={ast_param_start}")
        if collected_param_count != ast_param_count:
            self.analysis_fail(f"trait table {trait_name} index={trait_idx} method={method_idx}: param-count={collected_param_count} AST={ast_param_count}")
        if collected_ret_node != ast_ret_node:
            self.analysis_fail(f"trait table {trait_name} index={trait_idx} method={method_idx}: return-node={collected_ret_node} AST={ast_ret_node}")
        if collected_default_body != ast_default_body:
            self.analysis_fail(f"trait table {trait_name} index={trait_idx} method={method_idx}: default-body={collected_default_body} AST={ast_default_body}")

    // Prove that codegen's denormalized trait metadata is an exact projection of
    // the canonical AST records. This permanently catches record-stride drift:
    // table lengths can stay parallel while every method after the first points
    // at the wrong AST fields.
    fn audit_trait_table_contracts():
        if self.analysis_enabled == 0:
            return
        let trait_count = self.trait_idx_syms.len() as i32
        let method_count = self.trait_method_names.len() as i32
        let trait_tables_parallel =
            self.trait_vtable_types.len() as i32 == trait_count and
            self.trait_method_starts.len() as i32 == trait_count and
            self.trait_method_counts.len() as i32 == trait_count
        if not trait_tables_parallel:
            self.analysis_fail(f"trait tables are not parallel: symbols={trait_count} vtables={self.trait_vtable_types.len() as i32} starts={self.trait_method_starts.len() as i32} counts={self.trait_method_counts.len() as i32}")
        let method_tables_parallel =
            self.trait_method_flags.len() as i32 == method_count and
            self.trait_method_ret_types.len() as i32 == method_count and
            self.trait_method_param_counts.len() as i32 == method_count and
            self.trait_method_param_starts.len() as i32 == method_count and
            self.trait_method_ret_nodes.len() as i32 == method_count and
            self.trait_method_default_bodies.len() as i32 == method_count
        if not method_tables_parallel:
            self.analysis_fail(f"trait method tables are not parallel: names={method_count} flags={self.trait_method_flags.len() as i32} ret-types={self.trait_method_ret_types.len() as i32} param-counts={self.trait_method_param_counts.len() as i32} param-starts={self.trait_method_param_starts.len() as i32} ret-nodes={self.trait_method_ret_nodes.len() as i32} defaults={self.trait_method_default_bodies.len() as i32}")
        if self.trait_map.len() as i32 != trait_count:
            self.analysis_fail(f"trait map size={self.trait_map.len() as i32} indexed-symbols={trait_count}")

        let mapped_syms = self.trait_map.keys()
        for ki in 0..mapped_syms.len() as i32:
            let trait_sym = mapped_syms.get(ki as i64)
            let trait_idx = self.trait_map.get(trait_sym).unwrap()
            if trait_idx < 0 or trait_idx >= trait_count:
                self.analysis_fail(f"trait map symbol={trait_sym}: index={trait_idx} is out of range 0..{trait_count}")
            else if self.trait_idx_syms.get(trait_idx as i64) != trait_sym:
                self.analysis_fail(f"trait map symbol={trait_sym}: index={trait_idx} points to symbol={self.trait_idx_syms.get(trait_idx as i64)}")

        var canonical_method_start = 0
        for trait_idx in 0..trait_count:
            let trait_sym = self.trait_idx_syms.get(trait_idx as i64)
            let trait_name = self.intern.resolve(trait_sym)
            let mapped_idx = self.trait_map.get(trait_sym)
            if not mapped_idx.is_some():
                self.analysis_fail(f"trait index={trait_idx} symbol={trait_sym}: missing inverse map entry")
            else if mapped_idx.unwrap() != trait_idx:
                self.analysis_fail(f"trait index={trait_idx} symbol={trait_sym}: inverse map index={mapped_idx.unwrap()}")
            if not trait_tables_parallel:
                continue
            let decl = self.trait_decl_nodes.get(trait_sym)
            if not decl.is_some():
                self.analysis_fail(f"trait table {trait_name} index={trait_idx}: missing AST declaration")
                continue
            let trait_node = decl.unwrap()
            if self.pool.kind(trait_node) != NodeKind.NK_TRAIT_DECL:
                self.analysis_fail(f"trait table {trait_name} index={trait_idx}: node={trait_node} is not a trait declaration")
                continue
            if self.pool.get_data0(trait_node) != trait_sym:
                self.analysis_fail(f"trait table {trait_name} index={trait_idx}: declaration symbol={self.pool.get_data0(trait_node)} expected={trait_sym}")
            let ast_method_count = self.pool.trait_method_count(trait_node)
            let collected_start = self.trait_method_starts.get(trait_idx as i64)
            let collected_count = self.trait_method_counts.get(trait_idx as i64)
            if collected_start != canonical_method_start:
                self.analysis_fail(f"trait table {trait_name} index={trait_idx}: method-start={collected_start} expected={canonical_method_start}")
            if collected_count != ast_method_count:
                self.analysis_fail(f"trait table {trait_name} index={trait_idx}: method-count={collected_count} AST={ast_method_count}")
            let vtable_ty = self.trait_vtable_types.get(trait_idx as i64)
            var vtable_slots = -1
            if vtable_ty == 0 or wl_get_type_kind(vtable_ty) != wl_struct_type_kind():
                self.analysis_fail(f"trait table {trait_name} index={trait_idx}: vtable type is not an LLVM struct")
            else:
                vtable_slots = wl_count_struct_elem_types(vtable_ty)
                if vtable_slots != ast_method_count:
                    self.analysis_fail(f"trait table {trait_name} index={trait_idx}: vtable-slots={vtable_slots} AST methods={ast_method_count}")
            let row_range_valid = collected_start >= 0 and collected_count >= 0 and collected_start + collected_count <= method_count
            if not row_range_valid:
                self.analysis_fail(f"trait table {trait_name} index={trait_idx}: row range start={collected_start} count={collected_count} rows={method_count}")
            else if method_tables_parallel and collected_count == ast_method_count:
                for method_idx in 0..ast_method_count:
                    self.audit_trait_method_row(trait_name, trait_node, trait_idx, collected_start, method_idx)
            var fact = AnalysisFact.new(AnalysisStage.Codegen, AnalysisFactKind.Invariant)
            fact.id = trait_idx
            fact.parent = trait_node
            fact.node = trait_node
            fact.symbol = trait_sym
            fact.index = collected_start
            fact.flags = 256
            fact.name = with_str_clone_ref(trait_name)
            fact.detail = f"trait-table methods={collected_count} ast-methods={ast_method_count} vtable-slots={vtable_slots}"
            self.analysis_add(move fact)
            canonical_method_start = canonical_method_start + ast_method_count
        if canonical_method_start != method_count:
            self.analysis_fail(f"trait method rows={method_count} canonical AST rows={canonical_method_start}")

    fn find_trait_method_offset(trait_idx: i32, method_sym: i32) -> i32:
        let start = self.trait_method_starts.get(trait_idx as i64)
        let count = self.trait_method_counts.get(trait_idx as i64)
        for i in 0..count:
            if self.trait_method_names.get((start + i) as i64) == method_sym:
                return i
        -1

fn codegen_type_node_mentions_self(pool: AstPool, self_sym: i32, type_node: i32) -> i32:
    if type_node == 0:
        return 0
    let kind = pool.kind(type_node)
    if kind == NodeKind.NK_TYPE_NAMED:
        return if pool.get_data0(type_node) == self_sym: 1 else: 0
    if kind == NodeKind.NK_TYPE_ASSOC:
        return if pool.get_data0(type_node) == self_sym: 1 else: 0
    if kind == NodeKind.NK_TYPE_REF or kind == NodeKind.NK_TYPE_PTR or kind == NodeKind.NK_TYPE_ARRAY or kind == NodeKind.NK_TYPE_SLICE or kind == NodeKind.NK_TYPE_OPTIONAL:
        return codegen_type_node_mentions_self(pool, self_sym, pool.get_data0(type_node))
    if kind == NodeKind.NK_TYPE_TUPLE:
        let extra_start = pool.get_data0(type_node)
        let elem_count = pool.get_data1(type_node)
        for ei in 0..elem_count:
            if codegen_type_node_mentions_self(pool, self_sym, pool.get_extra(extra_start + ei)) != 0:
                return 1
        return 0
    if kind == NodeKind.NK_TYPE_FN or kind == NodeKind.NK_TYPE_EXTERN_FN:
        let extra_start = pool.get_data0(type_node)
        let param_count = pool.get_data1(type_node)
        let ret_node = pool.get_data2(type_node)
        for pi in 0..param_count:
            if codegen_type_node_mentions_self(pool, self_sym, pool.get_extra(extra_start + pi)) != 0:
                return 1
        return codegen_type_node_mentions_self(pool, self_sym, ret_node)
    if kind == NodeKind.NK_TYPE_GENERIC:
        if pool.get_data0(type_node) == self_sym:
            return 1
        let extra_start = pool.get_data1(type_node)
        let arg_count = pool.get_data2(type_node)
        for ai in 0..arg_count:
            if codegen_type_node_mentions_self(pool, self_sym, pool.get_extra(extra_start + ai)) != 0:
                return 1
    0

impl Codegen:
    // report_errors=false makes the skippable cases (a method whose signature
    // mentions Self, or an unresolvable type) return 0 WITHOUT setting had_error
    // or printing — so a vtable-build caller can fall back to the real method's
    // by-value type for a non-dispatchable slot (e.g. `Ord.cmp`) instead of
    // failing the whole compilation. The real dispatch site passes true, where a
    // Self-mentioning method IS a genuine "can't dynamically dispatch this" error.
    mut fn dyn_trait_method_fn_type(trait_sym: i32, method_sym: i32) -> i64:
        self.dyn_trait_method_fn_type_reporting(trait_sym, method_sym, true)

    mut fn dyn_trait_method_fn_type_reporting(trait_sym: i32, method_sym: i32, report_errors: bool) -> i64:
        let trait_idx_opt = self.trait_map.get(trait_sym)
        if not trait_idx_opt.is_some():
            if report_errors:
                with_eprint("error: missing trait metadata for dyn dispatch on '" ++ self.intern.resolve(trait_sym) ++ "'")
                self.had_error = 1
            return 0
        let trait_idx = trait_idx_opt.unwrap()
        let method_offset = self.find_trait_method_offset(trait_idx, method_sym)
        if method_offset < 0:
            if report_errors:
                with_eprint("error: missing trait method '" ++ self.intern.resolve(method_sym) ++ "' in dyn trait '" ++ self.intern.resolve(trait_sym) ++ "'")
                self.had_error = 1
            return 0
        let method_idx = self.trait_method_starts.get(trait_idx as i64) + method_offset
        let method_flags = self.trait_method_flags.get(method_idx as i64)
        let param_start = self.trait_method_param_starts.get(method_idx as i64)
        let param_count = self.trait_method_param_counts.get(method_idx as i64)
        let ret_node = self.trait_method_ret_nodes.get(method_idx as i64)

        let ptr_ty = wl_ptr_type(self.context)
        let param_types: Vec[i64] = Vec.new()
        param_types.push(ptr_ty)
        var pi = 1
        while pi < param_count:
            let p_type_node = self.pool.fn_param_type(param_start, pi)
            if codegen_type_node_mentions_self(self.pool, self.sym_Self, p_type_node) != 0:
                if report_errors:
                    with_eprint("error: cannot lower dyn trait method '" ++ self.intern.resolve(method_sym) ++ "' because a non-receiver parameter mentions Self")
                    self.had_error = 1
                return 0
            var p_ty = self.resolve_type(p_type_node)
            if p_ty == 0:
                if report_errors:
                    with_eprint("error: cannot resolve parameter type for dyn trait method '" ++ self.intern.resolve(method_sym) ++ "'")
                    self.had_error = 1
                return 0
            param_types.push(p_ty)
            pi = pi + 1

        var ret_sema_ty = self.sema.ty_void as i32
        if ret_node != 0:
            if codegen_type_node_mentions_self(self.pool, self.sym_Self, ret_node) != 0:
                if report_errors:
                    with_eprint("error: cannot lower dyn trait method '" ++ self.intern.resolve(method_sym) ++ "' because its return type mentions Self")
                    self.had_error = 1
                return 0
            ret_sema_ty = self.sema.resolve_type_expr_frozen(ret_node) as i32
            if ret_sema_ty == 0:
                if report_errors:
                    with_eprint("error: cannot resolve return type for dyn trait method '" ++ self.intern.resolve(method_sym) ++ "'")
                    self.had_error = 1
                return 0
        if (method_flags / FnFlags.ASYNC) % 2 == 1:
            let task_args: Vec[i32] = Vec.new()
            task_args.push(ret_sema_ty)
            ret_sema_ty = self.sema.find_generic_inst_type(self.sema.syms.task, task_args, 1) as i32
        let ret_ty = self.sema_type_to_llvm(ret_sema_ty)
        if ret_ty == 0:
            if report_errors:
                with_eprint("error: cannot lower return type for dyn trait method '" ++ self.intern.resolve(method_sym) ++ "'")
                self.had_error = 1
            return 0

        // D6: the reconstructed dispatch type MUST match the real method and its
        // vtable wrapper (create_dyn_wrapper copies the method's ABI-lowered param
        // layout). Trait methods use the native (internal) With ABI, so apply the
        // same sret / indirect-param lowering declare_function does. Without this,
        // a win64 aggregate return (>8B, e.g. `str`) is reconstructed here by-value
        // while the wrapper returns via sret — the exact caller/callee ABI
        // divergence D6 forbids, producing wrong output at every dyn call site.
        let abi_param_types: Vec[i64] = Vec.new()
        var actual_ret_ty = ret_ty
        if self.internal_abi_needs_sret(ret_ty):
            actual_ret_ty = wl_void_type(self.context)
            abi_param_types.push(ptr_ty)
        var api = 0
        while api < param_types.len() as i32:
            let src_ty = param_types.get(api as i64)
            if self.internal_abi_needs_indirect_param(src_ty):
                abi_param_types.push(ptr_ty)
            else:
                abi_param_types.push(src_ty)
            api = api + 1
        wl_function_type(actual_ret_ty, vec_data_i64(&abi_param_types), abi_param_types.len() as i32, 0)

    fn find_decl_index(node: i32) -> i32:
        for i in 0..self.pool.decl_count():
            if self.pool.get_decl(i) == node:
                return i
        -1

    fn lookup_impl_method_symbol_by_slot(impl_node: i32, slot: i32) -> i32:
        if slot < 0:
            return 0
        let impl_extra = self.pool.get_data1(impl_node)
        if impl_extra < 0 or impl_extra >= self.pool.extra_len():
            return 0
        // Skip past associated type entries: [assoc_count, [name, type]*, method_count]
        let assoc_count = self.pool.get_extra(impl_extra)
        let method_count = self.pool.get_extra(impl_extra + 1 + assoc_count * 2)
        if method_count <= 0 or slot >= method_count:
            return 0
        let decl_idx = self.find_decl_index(impl_node)
        if decl_idx <= 0:
            return 0
        let rev_syms: Vec[i32] = Vec.new()
        var di = decl_idx - 1
        while di >= 0 and rev_syms.len() as i32 < method_count:
            let decl = self.pool.get_decl(di)
            if self.pool.kind(decl) == NodeKind.NK_FN_DECL:
                rev_syms.push(self.pool.get_data0(decl))
            di = di - 1
        if rev_syms.len() as i32 != method_count:
            return 0
        let rev_idx = method_count - 1 - slot
        if rev_idx < 0 or rev_idx >= rev_syms.len() as i32:
            return 0
        rev_syms.get(rev_idx as i64)

    fn find_impl_for_type_trait(impl_type_sym: i32, trait_sym: i32) -> i32:
        if impl_type_sym == 0 or trait_sym == 0:
            return 0
        for i in 0..self.pool.decl_count():
            let decl = self.pool.get_decl(i)
            if self.pool.kind(decl) != NodeKind.NK_IMPL_DECL:
                continue
            if self.pool.get_data0(decl) == impl_type_sym and self.pool.get_data2(decl) == trait_sym:
                return decl
        0

    mut fn create_dyn_wrapper(impl_type_sym: i32, impl_fn_sym: i32, method_sym: i32, method_fn: i64, method_ft: i64, dyn_ft: i64, consumes_self: i32) -> i64:
        let type_name = self.intern.resolve(impl_type_sym)
        let method_name = self.intern.resolve(method_sym)
        let wrapper_name = "__dynwrap_" ++ type_name ++ "_" ++ method_name
        let existing = wl_get_named_function(self.llmod, wrapper_name)
        if existing != 0:
            return existing

        let ptr_ty = wl_ptr_type(self.context)
        let orig_param_count = wl_count_param_types(method_ft)
        if orig_param_count <= 0:
            return method_fn
        let is_async_method = if impl_fn_sym != 0 and self.async_fn_ret_types.get(impl_fn_sym).is_some(): 1 else: 0
        // dyn_trait_method_fn_type applies the native win64 ABI: an aggregate
        // return >8B (an async Task {i32,ptr}, or a fat Option like
        // `Option[&dyn Error]` = {i32,{ptr,ptr}}) becomes a leading sret
        // parameter and a void return. The wrapper IS the vtable slot, so its
        // signature must match dyn_ft — carry the sret slot, place self/args
        // after it, and write the produced value through it instead of
        // returning by value. Detect it structurally (void return + one extra
        // leading param vs the real method) so it fires for sync aggregate
        // returns too, not only async. On SysV a 16B/24B aggregate returns in
        // registers (no sret), so the non-sret path below stays byte-identical.
        let dyn_ret_ty = wl_get_return_type(dyn_ft)
        let dyn_param_count = wl_count_param_types(dyn_ft)
        let has_sret = dyn_ret_ty == wl_void_type(self.context) and dyn_param_count == orig_param_count + 1
        let base = if has_sret: 1 else: 0
        // For the sret and async paths dyn_ft is authoritative (win64 aggregate
        // sret lowering / the reconstructed Task type). For a plain sync by-value
        // return the IMPL fn's actual monomorphized return is authoritative:
        // dyn_trait_method_fn_type resolves the trait method's DECLARED return,
        // which for a generic return (e.g. `Scoped[T].with_enter -> T`) is the
        // unsubstituted parameter and can lower to the wrong width (i32 vs the
        // impl's i64). The wrapper body returns method_ft's value, so declaring
        // the wrapper with method_ft's return keeps producer and body consistent
        // and reproduces the pre-sret-fix behavior for this case.
        let ret_ty = if has_sret or is_async_method != 0: dyn_ret_ty else: wl_get_return_type(method_ft)
        let wrapper_param_types: Vec[i64] = Vec.new()
        if has_sret:
            wrapper_param_types.push(ptr_ty)
        wrapper_param_types.push(ptr_ty)
        var pi = 1
        while pi < orig_param_count:
            let pval = wl_get_param(method_fn, pi)
            wrapper_param_types.push(wl_type_of(pval))
            pi = pi + 1
        let wrapper_ft = wl_function_type(ret_ty, vec_data_i64(&wrapper_param_types), orig_param_count + base, 0)
        let wrapper_fn = wl_add_function(self.llmod, wrapper_name, wrapper_ft)
        wl_set_linkage(wrapper_fn, wl_internal_linkage())

        let saved_fn = self.current_function
        let saved_fn_name_sym = self.current_function_name_sym
        let saved_ret = self.current_ret_type
        let saved_bb = wl_get_insert_block(self.builder)
        self.current_function = wrapper_fn
        self.current_function_name_sym = 0
        self.current_ret_type = ret_ty

        let entry = wl_append_bb(self.context, wrapper_fn, "entry")
        wl_position_at_end(self.builder, entry)

        let data_ptr = wl_get_param(wrapper_fn, base)
        let self_param_ty = if orig_param_count > 0: wl_type_of(wl_get_param(method_fn, 0)) else: ptr_ty
        let self_arg = if wl_get_type_kind(self_param_ty) == wl_pointer_type_kind():
            wl_build_bitcast(self.builder, data_ptr, self_param_ty)
        else:
            wl_build_load(self.builder, self_param_ty, data_ptr)

        let call_args: Vec[i64] = Vec.new()
        call_args.push(self_arg)
        pi = 1
        while pi < orig_param_count:
            let p = wl_get_param(wrapper_fn, base + pi)
            let target_ty = wl_type_of(wl_get_param(method_fn, pi))
            call_args.push(self.coerce_value_to_type(p, target_ty))
            pi = pi + 1

        var call_val: i64 = 0
        if is_async_method != 0:
            var async_task_ty = ret_ty
            if has_sret:
                let task_fields: Vec[i64] = Vec.new()
                task_fields.push(wl_i32_type(self.context))
                task_fields.push(ptr_ty)
                async_task_ty = wl_struct_type(self.context, vec_data_i64(&task_fields), 2, 0)
            call_val = self.emit_async_fn_spawn_task_value(impl_fn_sym, method_fn, method_ft, &call_args, async_task_ty)
        else:
            call_val = wl_build_call(self.builder, method_ft, method_fn, vec_data_i64(&call_args), orig_param_count)
        if consumes_self != 0:
            let free_fn = self.ensure_box_free_fn()
            if free_fn != 0:
                let free_args: Vec[i64] = Vec.new()
                free_args.push(data_ptr)
                let _ = wl_build_call(self.builder, wl_global_get_value_type(free_fn), free_fn, vec_data_i64(&free_args), 1)
        if has_sret:
            let _ = wl_build_store(self.builder, call_val, wl_get_param(wrapper_fn, 0))
            let _ = wl_build_ret_void(self.builder)
        else:
            if ret_ty == wl_void_type(self.context):
                let _ = wl_build_ret_void(self.builder)
            else:
                let _ = wl_build_ret(self.builder, call_val)

        self.current_function = saved_fn
        self.current_function_name_sym = saved_fn_name_sym
        self.current_ret_type = saved_ret
        if saved_bb != 0:
            wl_position_at_end(self.builder, saved_bb)

        wrapper_fn

    mut fn resolve_trait_method_type_for_impl(type_node: i32, impl_type_sym: i32) -> i64:
        return self.resolve_trait_method_type_for_impl_with_trait(type_node, impl_type_sym, 0, 0)

    mut fn resolve_trait_method_type_for_impl_with_trait(type_node: i32, impl_type_sym: i32, trait_sym: i32, impl_node: i32) -> i64:
        if type_node == 0:
            return 0
        var concrete_ty = 0
        let st = self.struct_type_map.get(impl_type_sym)
        if st.is_some():
            concrete_ty = self.struct_llvm_types.get(st.unwrap() as i64)
        else:
            let et = self.enum_type_map.get(impl_type_sym)
            if et.is_some():
                concrete_ty = self.enum_llvm_types.get(et.unwrap() as i64)
        if concrete_ty == 0:
            return self.resolve_type(type_node)

        let saved_syms = self.type_binding_syms
        let saved_tys = self.type_binding_types
        let saved_len = self.type_bindings_len
        let fresh_syms: Vec[i32] = Vec.new()
        let fresh_tys: Vec[i64] = Vec.new()
        self.type_binding_syms = fresh_syms
        self.type_binding_types = fresh_tys
        self.type_bindings_len = 0
        var found_self = false
        for i in 0..saved_len:
            let sym = saved_syms.get(i as i64)
            var ty: i64 = saved_tys.get(i as i64)
            if sym == self.sym_Self:
                ty = concrete_ty
                found_self = true
            self.type_binding_syms.push(sym)
            self.type_binding_types.push(ty)
            self.type_bindings_len = self.type_bindings_len + 1
        if not found_self:
            self.type_binding_syms.push(self.sym_Self)
            self.type_binding_types.push(concrete_ty)
            self.type_bindings_len = self.type_bindings_len + 1

        // Bind trait type params from impl trait type args
        if trait_sym != 0 and impl_node != 0:
            let tp_count_opt = self.trait_tp_counts.get(trait_sym)
            if tp_count_opt.is_some():
                let tp_count = tp_count_opt.unwrap()
                let tp_start = self.trait_tp_starts.get(trait_sym).unwrap()
                let tta_idx = self.pool.find_impl_trait_type_args(impl_node)
                if tta_idx >= 0:
                    let arg_start = self.pool.state.impl_trait_type_args.get((tta_idx + 1) as i64)
                    let arg_count = self.pool.state.impl_trait_type_args.get((tta_idx + 2) as i64)
                    var ti = 0
                    while ti < tp_count and ti < arg_count:
                        let tp_sym: i32 = self.trait_tp_flat_syms.get((tp_start + ti) as i64)
                        let arg_node = self.pool.get_extra(arg_start + ti)
                        let arg_ty = self.resolve_type(arg_node)
                        if arg_ty != 0:
                            self.type_binding_syms.push(tp_sym)
                            self.type_binding_types.push(arg_ty)
                            self.type_bindings_len = self.type_bindings_len + 1
                        ti = ti + 1

        let resolved = self.resolve_type(type_node)
        self.type_binding_syms = saved_syms
        self.type_binding_types = saved_tys
        self.type_bindings_len = saved_len
        resolved

    mut fn generate_default_trait_method_for_impl_ext(impl_type_sym: i32, method_idx: i32, trait_sym: i32, impl_node: i32):
        // Set up trait type param bindings before generating the method.
        // #691: scope the extra bindings by remembering lengths and popping
        // back — never by moving the vec headers out and back (the moved-out
        // field cannot be pushed, and pre-flip the bit-copied header aliased
        // the live buffer across a possible realloc).
        let saved_vec_len = self.type_binding_syms.len()
        let saved_len = self.type_bindings_len
        let body_node = self.trait_method_default_bodies.get(method_idx as i64)
        if body_node == 0:
            return

        if trait_sym != 0 and impl_node != 0:
            let tp_count_opt = self.trait_tp_counts.get(trait_sym)
            if tp_count_opt.is_some():
                let tp_count = tp_count_opt.unwrap()
                let tp_start = self.trait_tp_starts.get(trait_sym).unwrap()
                // Try to bind from explicit trait type args (impl Trait[i32] for Type)
                let tta_idx = self.pool.find_impl_trait_type_args(impl_node)
                if tta_idx >= 0:
                    let arg_start = self.pool.state.impl_trait_type_args.get((tta_idx + 1) as i64)
                    let arg_count = self.pool.state.impl_trait_type_args.get((tta_idx + 2) as i64)
                    var ti = 0
                    while ti < tp_count and ti < arg_count:
                        let tp_sym: i32 = self.trait_tp_flat_syms.get((tp_start + ti) as i64)
                        let arg_node = self.pool.get_extra(arg_start + ti)
                        let arg_ty = self.resolve_type(arg_node)
                        if arg_ty != 0:
                            self.type_binding_syms.push(tp_sym)
                            self.type_binding_types.push(arg_ty)
                            self.type_bindings_len = self.type_bindings_len + 1
                        ti = ti + 1

        self.generate_default_trait_method_for_impl(impl_type_sym, method_idx)

        while self.type_binding_syms.len() > saved_vec_len:
            let _ = self.type_binding_syms.pop()
        while self.type_binding_types.len() > saved_vec_len:
            let _ = self.type_binding_types.pop()
        self.type_bindings_len = saved_len

    mut fn generate_default_trait_method_for_impl(impl_type_sym: i32, method_idx: i32):
        let body_node = self.trait_method_default_bodies.get(method_idx as i64)
        if body_node == 0:
            return

        let method_sym = self.trait_method_names.get(method_idx as i64)
        let method_name = self.intern.resolve(method_sym)
        let type_name = self.intern.resolve(impl_type_sym)
        let mangled = type_name ++ "." ++ method_name
        let fn_sym = self.intern.intern(mangled)
        if self.fn_values.get(fn_sym).is_some():
            return

        let param_start = self.trait_method_param_starts.get(method_idx as i64)
        let param_count = self.trait_method_param_counts.get(method_idx as i64)
        let ret_node = self.trait_method_ret_nodes.get(method_idx as i64)
        if with_getenv_str("WITH_DEBUG_DTM").len() > 0:
            with_eprint(f"[dtm] {mangled} method_idx={method_idx} param_start={param_start} param_count={param_count} ret_node={ret_node} body_node={body_node}")
        if param_start < 0:
            return
        if param_count < 0 or param_count > 64:
            return

        let param_types: Vec[i64] = Vec.new()
        var has_ref_param = false
        for pi in 0..param_count:
            let type_slot = param_start + pi * FN_PARAM_STRIDE + 1
            if type_slot < 0 or type_slot >= self.pool.extra_len():
                return
            let p_type_node = self.pool.fn_param_type(param_start, pi)
            if pi == 0 and p_type_node != 0 and self.pool.kind(p_type_node) == NodeKind.NK_TYPE_NAMED:
                let p_sym = self.pool.get_data0(p_type_node)
                if p_sym == impl_type_sym or p_sym == self.sym_Self:
                    let p_ty = wl_ptr_type(self.context)
                    has_ref_param = true
                    param_types.push(p_ty)
                    continue
            var p_ty = self.resolve_trait_method_type_for_impl(p_type_node, impl_type_sym)
            if p_ty == 0:
                p_ty = self.type_fallback()
            param_types.push(p_ty)

        let ret_ty = if ret_node != 0:
            self.resolve_trait_method_type_for_impl(ret_node, impl_type_sym)
        else:
            wl_void_type(self.context)
        let final_ret_ty = if ret_ty != 0: ret_ty else: wl_void_type(self.context)
        let fn_ty = wl_function_type(final_ret_ty, vec_data_i64(&param_types), param_count, 0)
        if fn_ty == 0 or wl_get_type_kind(fn_ty) != wl_function_type_kind():
            return
        let function = wl_add_function(self.llmod, mangled, fn_ty)
        self.apply_noalias_param_attrs(function, param_start, param_count)
        if function == 0 or wl_get_value_kind(function) != wl_function_value_kind():
            return
        self.fn_values.insert(fn_sym, function)
        self.fn_fn_types.insert(fn_sym, fn_ty)
        if has_ref_param:
            self.record_ref_param(fn_sym, 0, param_count)

        let saved_fn = self.current_function
        let saved_fn_name_sym = self.current_function_name_sym
        let saved_ret = self.current_ret_type
        let saved_owner = self.current_method_owner_sym
        let saved_allocas = self.local_allocas
        let saved_types = self.local_types
        let saved_muts = self.local_muts
        let saved_fn_sigs = self.local_fn_sigs
        let saved_pointees = self.local_pointee_structs
        let saved_task_locals = self.task_locals
        let saved_trait_locals = self.trait_locals
        let saved_trait_concrete = self.trait_local_concrete_types
        let saved_scope_syms = self.scope_local_syms
        let saved_scope_allocas = self.scope_local_allocas
        let saved_scope_types = self.scope_local_types
        let saved_scope_count = self.scope_local_count
        let saved_defer = self.defer_stack
        let saved_errdefer = self.errdefer_stack
        let saved_enum_local_types = self.enum_local_types
        let saved_sema_local_types = self.local_sema_types
        let saved_expected = self.expected_type
        let saved_expected_node = self.expected_type_node
        let saved_result_err = self.current_result_err_symbol
        let saved_returns_result = self.current_fn_returns_result
        let saved_saw_return = self.current_fn_saw_explicit_return
        let saved_tail_bb = self.tailrec_body_bb
        let saved_tail_sym = self.tailrec_fn_sym
        let saved_tail_allocas = self.tailrec_param_allocas
        let saved_loops = self.capture_loop_state()
        let saved_bb = wl_get_insert_block(self.builder)

        self.current_function = function
        self.current_function_name_sym = fn_sym
        self.current_ret_type = final_ret_ty
        self.current_method_owner_sym = impl_type_sym
        let fresh_local_allocas: HashMap[i32, i64] = HashMap.new()
        let fresh_local_types: HashMap[i32, i64] = HashMap.new()
        let fresh_local_muts: HashMap[i32, i32] = HashMap.new()
        let fresh_local_fn_sigs: HashMap[i32, i64] = HashMap.new()
        let fresh_local_pointees: HashMap[i32, i32] = HashMap.new()
        let fresh_task_locals: HashMap[i32, i32] = HashMap.new()
        let fresh_trait_locals: HashMap[i32, i32] = HashMap.new()
        let fresh_trait_concrete: HashMap[i32, i32] = HashMap.new()
        let fresh_enum_local_types: HashMap[i32, i32] = HashMap.new()
        let fresh_scope_syms: Vec[i32] = Vec.new()
        let fresh_scope_allocas: Vec[i64] = Vec.new()
        let fresh_scope_types: Vec[i64] = Vec.new()
        let fresh_defer_stack: Vec[i32] = Vec.new()
        let fresh_errdefer_stack: Vec[i32] = Vec.new()
        let fresh_tail_allocas: Vec[i64] = Vec.new()
        self.local_allocas = fresh_local_allocas
        self.local_types = fresh_local_types
        self.local_muts = fresh_local_muts
        self.local_fn_sigs = fresh_local_fn_sigs
        self.local_pointee_structs = fresh_local_pointees
        self.task_locals = fresh_task_locals
        self.trait_locals = fresh_trait_locals
        self.trait_local_concrete_types = fresh_trait_concrete
        self.enum_local_types = fresh_enum_local_types
        // The save above moves the map out (blank handle); the body reads it
        // via sema_type_of_node, so a fresh map must be installed like every
        // other saved container (the _ext twin already does).
        self.local_sema_types = HashMap.new()
        self.scope_local_syms = fresh_scope_syms
        self.scope_local_allocas = fresh_scope_allocas
        self.scope_local_types = fresh_scope_types
        self.scope_local_count = 0
        self.defer_stack = fresh_defer_stack
        self.errdefer_stack = fresh_errdefer_stack
        self.expected_type = final_ret_ty
        self.expected_type_node = 0
        self.current_result_err_symbol = 0
        self.current_fn_returns_result = false
        self.current_fn_saw_explicit_return = false
        self.tailrec_body_bb = 0
        self.tailrec_fn_sym = 0
        self.tailrec_param_allocas = fresh_tail_allocas
        self.reset_loop_state()

        let entry = wl_append_bb(self.context, function, "entry")
        wl_position_at_end(self.builder, entry)
        var lowered_param_count: i32 = param_count
        let actual_param_count = wl_count_params(function)
        if actual_param_count >= 0 and actual_param_count < lowered_param_count:
            lowered_param_count = actual_param_count
        if lowered_param_count < 0:
            lowered_param_count = 0
        var pi = 0
        while pi < lowered_param_count:
            let name_slot = param_start + pi * FN_PARAM_STRIDE
            let type_slot = param_start + pi * FN_PARAM_STRIDE + 1
            if name_slot < 0 or type_slot < 0 or type_slot >= self.pool.extra_len():
                break
            let p_name = self.pool.fn_param_name(param_start, pi)
            let p_type_node = self.pool.fn_param_type(param_start, pi)
            let p_val = wl_get_param(function, pi)
            let p_ty = wl_type_of(p_val)
            let p_alloca = self.create_entry_alloca(p_ty)
            wl_build_store(self.builder, p_val, p_alloca)
            self.record_local(p_name, p_alloca, p_ty, 1)

            if pi == 0 and wl_get_type_kind(p_ty) == wl_pointer_type_kind():
                self.record_local_pointee_struct(p_name, impl_type_sym)
            if pi == 0 and p_type_node != 0 and self.pool.kind(p_type_node) == NodeKind.NK_TYPE_NAMED:
                let psym = self.pool.get_data0(p_type_node)
                if psym == self.sym_Self and wl_get_type_kind(p_ty) == wl_pointer_type_kind():
                    self.record_local_pointee_struct(p_name, impl_type_sym)
            pi = pi + 1

        // ── MIR-based default trait method body compilation ──
        let saved_mir_locals = self.mir_local_ptrs
        let saved_mir_local_types = self.mir_local_types
        let saved_mir_memory_locals = self.mir_memory_locals
        let saved_mir_bbs = self.mir_bb_values
        let saved_mir_unreachable = self.mir_default_unreachable_bbs
        let dtm_fresh_mir_locals: HashMap[i32, i64] = HashMap.new()
        let dtm_fresh_mir_types: HashMap[i32, i64] = HashMap.new()
        let dtm_fresh_mir_bbs: Vec[i64] = Vec.new()
        let dtm_fresh_mir_unr: Vec[i64] = Vec.new()
        self.mir_local_ptrs = dtm_fresh_mir_locals
        self.mir_local_types = dtm_fresh_mir_types
        self.mir_memory_locals = HashMap.new()
        self.mir_bb_values = dtm_fresh_mir_bbs
        self.mir_default_unreachable_bbs = dtm_fresh_mir_unr

        var dtm_builder = MirBuilder.init(self.sema, self.pool, self.intern, fn_sym)
        // Set return type
        let dtm_ret_sema = self.sema_type_of_node(body_node)
        if dtm_ret_sema != 0 and dtm_ret_sema != self.sema.ty_void:
            dtm_builder.body.local_type_ids.set_i32(0, dtm_ret_sema)
        else:
            dtm_builder.body.local_type_ids.set_i32(0, self.sema.ty_i32)

        dtm_builder.push_scope()

        // Register params as MIR locals
        for dtm_pi in 0..param_count:
            let dtm_p_name = self.pool.fn_param_name(param_start, dtm_pi)
            let dtm_p_type_node = self.pool.fn_param_type(param_start, dtm_pi)
            var dtm_p_sema_ty = self.sema.ty_i32 as i32
            if dtm_p_type_node > 0:
                if self.sema.typed_expr_types.contains(dtm_p_type_node):
                    let dtm_tt = self.sema.typed_expr_types.get(dtm_p_type_node).unwrap()
                    if dtm_tt > 0:
                        dtm_p_sema_ty = dtm_tt
                if dtm_p_sema_ty == self.sema.ty_i32:
                    // `self: &Self` (and `&T` generally) is an NK_TYPE_REF
                    // wrapper; registering the receiver as ty_i32 made the
                    // synthesized body's method-call marshalling read the
                    // receiver through one extra indirection (spec_ss11_6:
                    // "Ada\0" bytes folded as a str pointer).
                    var dtm_tn = dtm_p_type_node
                    var dtm_is_ref = 0
                    if self.pool.kind(dtm_tn) == NodeKind.NK_TYPE_REF:
                        dtm_is_ref = 1
                        dtm_tn = self.pool.get_data0(dtm_tn)
                    let dtm_pk = self.pool.kind(dtm_tn)
                    if dtm_pk == NodeKind.NK_TYPE_NAMED or dtm_pk == NodeKind.NK_IDENT:
                        var dtm_type_sym = self.pool.get_data0(dtm_tn)
                        if dtm_type_sym == self.sym_Self:
                            dtm_type_sym = impl_type_sym
                        let dtm_prim = self.sema.primitive_type_by_sym(dtm_type_sym)
                        if dtm_prim != 0:
                            dtm_p_sema_ty = dtm_prim as i32
                        else if self.sema.named_types.contains(dtm_type_sym):
                            dtm_p_sema_ty = self.sema.named_types.get(dtm_type_sym).unwrap()
                        if dtm_is_ref != 0 and dtm_p_sema_ty != self.sema.ty_i32 as i32:
                            let dtm_ref_ty = self.sema.find_exact_type(TypeKind.TY_REF, dtm_p_sema_ty, self.pool.get_data1(dtm_p_type_node), 0) as i32
                            if dtm_ref_ty != 0:
                                dtm_p_sema_ty = dtm_ref_ty
            let dtm_p_local = dtm_builder.body.new_local(dtm_p_sema_ty, 1, dtm_p_name, 1)
            dtm_builder.bind_local(dtm_p_name, dtm_p_local)

        dtm_builder.expected_type = dtm_builder.body.local_type_ids.get(0)

        // Lower body to MIR
        let dtm_result = dtm_builder.lower_expr(body_node)
        let dtm_ret_place = dtm_builder.place_for_local(0)
        dtm_builder.assign_operand_to_place(dtm_ret_place, dtm_result, self.pool.get_end(body_node))
        dtm_builder.pop_scope_inline()
        dtm_builder.terminate(TermKind.TK_RETURN, 0, 0, 0, 0)
        let dtm_body = dtm_builder.body

        // Set up return alloca (MIR local 0). Void returns keep the dead i32
        // slot the normal MIR emitter uses — alloca of void is invalid LLVM and
        // traps inside DataLayout::getTypeSizeInBits.
        let dtm_ret_store_ty = if final_ret_ty != wl_void_type(self.context): final_ret_ty else: wl_i32_type(self.context)
        let dtm_ret_alloca = self.create_entry_alloca(dtm_ret_store_ty)
        self.mir_local_ptrs.insert(0, dtm_ret_alloca)
        self.mir_local_types.insert(0, dtm_ret_store_ty)

        // Map param MIR locals to existing LLVM allocas
        for dtm_mi in 0..param_count:
            let dtm_m_name = self.pool.fn_param_name(param_start, dtm_mi)
            let dtm_m_local_id = dtm_mi + 1
            let dtm_m_alloca_opt = self.local_allocas.get(dtm_m_name)
            if dtm_m_alloca_opt.is_some():
                let dtm_m_alloca: i64 = dtm_m_alloca_opt.unwrap()
                self.mir_local_ptrs.insert(dtm_m_local_id, dtm_m_alloca)
                let dtm_m_ty_opt = self.local_types.get(dtm_m_name)
                if dtm_m_ty_opt.is_some():
                    let dtm_m_ty: i64 = dtm_m_ty_opt.unwrap()
                    self.mir_local_types.insert(dtm_m_local_id, dtm_m_ty)

        self.mir_scan_memory_locals(dtm_body)

        // Pre-populate globals
        for dtm_gli in 0..dtm_body.local_names.len() as i32:
            let dtm_gl_name = dtm_body.local_names.get(dtm_gli as i64)
            if dtm_gl_name != 0:
                let dtm_gl_mc = self.module_constants.get(dtm_gl_name)
                if dtm_gl_mc.is_some():
                    let dtm_global_value: i64 = dtm_gl_mc.unwrap()
                    self.mir_local_ptrs.insert(dtm_gli, dtm_global_value)

        // Create LLVM basic blocks
        for dtm_bb in 0..dtm_body.block_count():
            let dtm_bb_name = f"mir.bb{dtm_bb}"
            let dtm_llbb = wl_append_bb(self.context, function, dtm_bb_name)
            self.mir_bb_values.push(dtm_llbb)

        // Branch from entry to first MIR BB
        if self.mir_bb_values.len() as i32 > 0:
            wl_build_br(self.builder, self.mir_bb_values.get(0))
        else:
            let _ = wl_build_ret(self.builder, wl_const_int(final_ret_ty, 0, 0))

        // Emit MIR statements and terminators
        for dtm_bb in 0..dtm_body.block_count():
            if dtm_bb < 0 or dtm_bb >= self.mir_bb_values.len() as i32:
                continue
            let dtm_llbb: i64 = self.mir_bb_values.get(dtm_bb as i64)
            wl_position_at_end(self.builder, dtm_llbb)
            let dtm_stmt_start = dtm_body.bb_stmt_starts.get(dtm_bb as i64)
            let dtm_stmt_count = dtm_body.bb_stmt_counts.get(dtm_bb as i64)
            for dtm_si in 0..dtm_stmt_count:
                let dtm_stmt_id = dtm_stmt_start + dtm_si
                if not self.mir_emit_stmt(dtm_body, dtm_stmt_id):
                    if wl_get_bb_terminator(dtm_llbb) == 0:
                        wl_build_unreachable(self.builder)
            if wl_get_bb_terminator(dtm_llbb) == 0:
                if not self.mir_emit_term(dtm_body, dtm_bb):
                    if wl_get_bb_terminator(dtm_llbb) == 0:
                        if final_ret_ty == wl_void_type(self.context):
                            let _ = wl_build_ret_void(self.builder)
                        else:
                            let _ = wl_build_ret(self.builder, wl_const_int(final_ret_ty, 0, 0))

        // Synthesized bodies must pass the same cleanup + verification as
        // every other function — an invalid synthesized default method
        // previously shipped silently and crashed at runtime (spec_ss11_6).
        self.run_mir_cleanup_passes(function, mangled)

        // Restore MIR state
        self.mir_local_ptrs = saved_mir_locals
        self.mir_local_types = saved_mir_local_types
        self.mir_memory_locals = saved_mir_memory_locals
        self.mir_bb_values = saved_mir_bbs
        self.mir_default_unreachable_bbs = saved_mir_unreachable

        self.current_function = saved_fn
        self.current_function_name_sym = saved_fn_name_sym
        self.current_ret_type = saved_ret
        self.current_method_owner_sym = saved_owner
        self.local_allocas = saved_allocas
        self.local_types = saved_types
        self.local_muts = saved_muts
        self.local_fn_sigs = saved_fn_sigs
        self.local_pointee_structs = saved_pointees
        self.task_locals = saved_task_locals
        self.trait_locals = saved_trait_locals
        self.trait_local_concrete_types = saved_trait_concrete
        self.enum_local_types = saved_enum_local_types
        self.local_sema_types = saved_sema_local_types
        self.scope_local_syms = saved_scope_syms
        self.scope_local_allocas = saved_scope_allocas
        self.scope_local_types = saved_scope_types
        self.scope_local_count = saved_scope_count
        self.defer_stack = saved_defer
        self.errdefer_stack = saved_errdefer
        self.expected_type = saved_expected
        self.expected_type_node = saved_expected_node
        self.current_result_err_symbol = saved_result_err
        self.current_fn_returns_result = saved_returns_result
        self.current_fn_saw_explicit_return = saved_saw_return
        self.tailrec_body_bb = saved_tail_bb
        self.tailrec_fn_sym = saved_tail_sym
        self.tailrec_param_allocas = saved_tail_allocas
        self.restore_loop_state(saved_loops)
        if saved_bb != 0:
            wl_position_at_end(self.builder, saved_bb)

    mut fn generate_default_trait_methods_for_impl(impl_node: i32):
        let impl_type_sym = self.pool.get_data0(impl_node)
        let trait_sym = self.pool.get_data2(impl_node)
        if trait_sym == 0:
            return
        let trait_idx_opt = self.trait_map.get(trait_sym)
        if not trait_idx_opt.is_some():
            return
        let trait_idx = trait_idx_opt.unwrap()
        let method_start: i32 = self.trait_method_starts.get(trait_idx as i64)
        let method_count = self.trait_method_counts.get(trait_idx as i64)
        for mi in 0..method_count:
            self.generate_default_trait_method_for_impl_ext(impl_type_sym, method_start + mi, trait_sym, impl_node)

    mut fn generate_default_trait_methods():
        for i in 0..self.pool.decl_count():
            let decl = self.pool.get_decl(i)
            if self.pool.kind(decl) == NodeKind.NK_IMPL_DECL:
                self.generate_default_trait_methods_for_impl(decl)

    mut fn generate_trait_vtable_for_impl(impl_node: i32):
        let impl_type_sym = self.pool.get_data0(impl_node)
        let trait_sym = self.pool.get_data2(impl_node)
        if trait_sym == 0:
            return

        let trait_idx_opt = self.trait_map.get(trait_sym)
        if not trait_idx_opt.is_some():
            return
        let trait_idx = trait_idx_opt.unwrap()
        let method_start = self.trait_method_starts.get(trait_idx as i64)
        let method_count = self.trait_method_counts.get(trait_idx as i64)
        let vtable_ty = self.trait_vtable_types.get(trait_idx as i64)

        let entries: Vec[i64] = Vec.new()
        for mi in 0..method_count:
            let method_sym: i32 = self.trait_method_names.get((method_start + mi) as i64)
            let method_flags = self.trait_method_flags.get((method_start + mi) as i64)
            let trait_method_idx = method_start + mi
            let param_start = self.trait_method_param_starts.get(trait_method_idx as i64)
            let param_count = self.trait_method_param_counts.get(trait_method_idx as i64)
            let consumes_self =
                if param_count > 0 and fn_param_is_move_self(self.pool.fn_param_flags(param_start, 0)) != 0: 1
                else: 0
            let method_name = self.intern.resolve(method_sym)
            let type_name = self.intern.resolve(impl_type_sym)
            let mangled = type_name ++ "." ++ method_name
            var impl_fn_sym = self.intern.intern(mangled)
            var fv = self.fn_values.get(impl_fn_sym)
            var ft = self.fn_fn_types.get(impl_fn_sym)
            if not fv.is_some() or not ft.is_some():
                let slot_sym = self.lookup_impl_method_symbol_by_slot(impl_node, mi)
                if slot_sym != 0:
                    impl_fn_sym = slot_sym
                    fv = self.fn_values.get(impl_fn_sym)
                    ft = self.fn_fn_types.get(impl_fn_sym)
            if fv.is_some() and ft.is_some():
                // Materialize fv/ft to plain values before the mut call below —
                // they are Option views into self and cannot stay live across
                // self.dyn_trait_method_fn_type.
                let fv_val = fv.unwrap() as i64
                let ft_val = ft.unwrap() as i64
                // D6: the vtable slot type is dyn_trait_method_fn_type — the SAME
                // descriptor the call site (mir_emit_dyn_trait_call) reads. The
                // wrapper must be declared with it so producer and consumer agree,
                // including the win64 sret lowering of an aggregate (>8B) return.
                // Gating this on async only (the old code) left a non-async
                // aggregate return — e.g. `source() -> Option[&dyn Error]` — with a
                // by-value wrapper against an sret call site: the exact divergence.
                var dyn_ft = self.dyn_trait_method_fn_type_reporting(trait_sym, method_sym, false)
                if dyn_ft == 0:
                    // Non-dispatchable slot (signature mentions Self, e.g.
                    // `Ord.cmp`): fall back to the real method's by-value type.
                    // The slot is never dynamically dispatched, so it can't
                    // diverge from a call site — reproducing the old behavior.
                    dyn_ft = ft_val
                let wrapper = self.create_dyn_wrapper(impl_type_sym, impl_fn_sym, method_sym, fv_val, ft_val, dyn_ft, consumes_self)
                entries.push(wrapper)
            else:
                entries.push(wl_const_null(wl_ptr_type(self.context)))

        let key = codegen_hash_type_trait_key(impl_type_sym, trait_sym)
        if self.vtable_globals.get(key).is_some():
            return

        let trait_name = self.intern.resolve(trait_sym)
        let type_name = self.intern.resolve(impl_type_sym)
        let global_name = "__vtable_" ++ type_name ++ "_" ++ trait_name
        let vg = wl_add_global(self.llmod, vtable_ty, global_name)
        let vconst = wl_const_named_struct(vtable_ty, vec_data_i64(&entries), method_count)
        wl_set_initializer(vg, vconst)
        wl_set_global_constant(vg, 1)
        wl_set_linkage(vg, wl_internal_linkage())
        self.vtable_globals.insert(key, vg)

    fn trait_vtable_global_name(impl_type_sym: i32, trait_sym: i32) -> str:
        var type_name: str = with_str_clone_ref(self.intern.resolve(impl_type_sym))
        if type_name.len() == 0:
            type_name = self.sema_symbol_text(impl_type_sym)
        var trait_name: str = with_str_clone_ref(self.intern.resolve(trait_sym))
        if trait_name.len() == 0:
            trait_name = self.sema_symbol_text(trait_sym)
        if type_name.len() == 0 or trait_name.len() == 0:
            return ""
        "__vtable_" ++ type_name ++ "_" ++ trait_name

    fn lookup_trait_vtable_global(impl_type_sym: i32, trait_sym: i32) -> i64:
        let key = codegen_hash_type_trait_key(impl_type_sym, trait_sym)
        let global_name = self.trait_vtable_global_name(impl_type_sym, trait_sym)
        if global_name.len() > 0:
            let existing_global = wl_get_named_global(self.llmod, global_name)
            if existing_global != 0:
                self.vtable_globals.insert(key, existing_global)
                return existing_global
        let direct = self.vtable_globals.get(key)
        if direct.is_some() and direct.unwrap() != 0:
            return direct.unwrap() as i64
        0

    mut fn ensure_monomorphized_trait_vtable(impl_type_sym: i32, trait_sym: i32):
        let key = codegen_hash_type_trait_key(impl_type_sym, trait_sym)
        if self.lookup_trait_vtable_global(impl_type_sym, trait_sym) != 0:
            return
        let base_opt = self.mono_struct_base.get(impl_type_sym)
        if not base_opt.is_some():
            return
        let impl_node = self.find_impl_for_type_trait(base_opt.unwrap(), trait_sym)
        if impl_node == 0:
            return
        let trait_idx_opt = self.trait_map.get(trait_sym)
        if not trait_idx_opt.is_some():
            return

        let trait_idx = trait_idx_opt.unwrap()
        let method_start = self.trait_method_starts.get(trait_idx as i64)
        let method_count = self.trait_method_counts.get(trait_idx as i64)
        let vtable_ty = self.trait_vtable_types.get(trait_idx as i64)
        let type_name = self.intern.resolve(impl_type_sym)
        let trait_name = self.intern.resolve(trait_sym)

        let entries: Vec[i64] = Vec.new()
        for mi in 0..method_count:
            let method_sym = self.trait_method_names.get((method_start + mi) as i64)
            let method_flags = self.trait_method_flags.get((method_start + mi) as i64)
            let trait_method_idx = method_start + mi
            let param_start = self.trait_method_param_starts.get(trait_method_idx as i64)
            let param_count = self.trait_method_param_counts.get(trait_method_idx as i64)
            let consumes_self =
                if param_count > 0 and fn_param_is_move_self(self.pool.fn_param_flags(param_start, 0)) != 0: 1
                else: 0
            let method_name = self.intern.resolve(method_sym)
            let concrete_sym = self.intern.intern(type_name ++ "." ++ method_name)
            let fv = self.fn_values.get(concrete_sym)
            let ft = self.fn_fn_types.get(concrete_sym)
            if not fv.is_some() or not ft.is_some():
                with_eprint("error: missing monomorphized trait method '" ++ type_name ++ "." ++ method_name ++ "' for trait '" ++ trait_name ++ "'")
                self.had_error = 1
                return
            let fv_val = fv.unwrap() as i64
            let ft_val = ft.unwrap() as i64
            var dyn_ft = self.dyn_trait_method_fn_type_reporting(trait_sym, method_sym, false)
            if dyn_ft == 0:
                dyn_ft = ft_val
            let wrapper = self.create_dyn_wrapper(impl_type_sym, concrete_sym, method_sym, fv_val, ft_val, dyn_ft, consumes_self)
            entries.push(wrapper)

        let global_name = "__vtable_" ++ type_name ++ "_" ++ trait_name
        let vg = wl_add_global(self.llmod, vtable_ty, global_name)
        let vconst = wl_const_named_struct(vtable_ty, vec_data_i64(&entries), method_count)
        wl_set_initializer(vg, vconst)
        wl_set_global_constant(vg, 1)
        wl_set_linkage(vg, wl_internal_linkage())
        self.vtable_globals.insert(key, vg)

    // Vtable for a dyn-erased generic inst (blanket impls like
    // `impl[E: Error] Error for ContextError[E]`): resolve each trait method
    // through Sema's dyn_impl specialization rows (recorded when the
    // ref-to-dyn coercion was accepted) instead of the Type__Arg.method
    // monomorph naming, force-generating the MIR specialization if nothing
    // referenced it yet. Falls back to the old-style monomorph per method.
    mut fn ensure_generic_inst_trait_vtable(concrete_sema_ty: i32, impl_type_sym: i32, trait_sym: i32):
        if self.lookup_trait_vtable_global(impl_type_sym, trait_sym) != 0:
            return
        let trait_idx_opt = self.trait_map.get(trait_sym)
        if not trait_idx_opt.is_some():
            return
        let trait_idx = trait_idx_opt.unwrap()
        let trait_text = self.intern.resolve(trait_sym)
        let method_start = self.trait_method_starts.get(trait_idx as i64)
        let method_count = self.trait_method_counts.get(trait_idx as i64)
        let vtable_ty = self.trait_vtable_types.get(trait_idx as i64)
        let type_name: str = with_str_clone_ref(self.intern.resolve(impl_type_sym))
        let entries: Vec[i64] = Vec.new()
        var used_row = 0
        for mi in 0..method_count:
            let method_sym = self.trait_method_names.get((method_start + mi) as i64)
            let method_flags = self.trait_method_flags.get((method_start + mi) as i64)
            let trait_method_idx = method_start + mi
            let param_start = self.trait_method_param_starts.get(trait_method_idx as i64)
            let param_count = self.trait_method_param_counts.get(trait_method_idx as i64)
            let consumes_self =
                if param_count > 0 and fn_param_is_move_self(self.pool.fn_param_flags(param_start, 0)) != 0: 1
                else: 0
            let method_text: str = with_str_clone_ref(self.intern.resolve(method_sym))
            let row = self.sema.dyn_impl_method_row(concrete_sema_ty, trait_text, method_text)
            var fv: i64 = 0
            var ft: i64 = 0
            var wrapper_fn_sym = 0
            if row >= 0:
                let cmf = self.ensure_concrete_mir_function(0, self.sema.dyn_impl_row_sig(row), self.sema.dyn_impl_row_mono_sym(row), 0, "dyn trait method " ++ type_name ++ "." ++ method_text)
                fv = cmf.value
                ft = cmf.fn_type
                wrapper_fn_sym = cmf.sym
                used_row = 1
            else:
                let concrete_sym = self.intern.intern(type_name ++ "." ++ method_text)
                let ofv = self.fn_values.get(concrete_sym)
                let oft = self.fn_fn_types.get(concrete_sym)
                if ofv.is_some() and oft.is_some():
                    fv = ofv.unwrap() as i64
                    ft = oft.unwrap() as i64
                    wrapper_fn_sym = concrete_sym
            if fv == 0 or ft == 0:
                with_eprint("error: missing monomorphized trait method '" ++ type_name ++ "." ++ method_text ++ "' for trait '" ++ trait_text ++ "' (dyn generic inst)")
                self.had_error = 1
                return
            var dyn_ft = self.dyn_trait_method_fn_type_reporting(trait_sym, method_sym, false)
            if dyn_ft == 0:
                dyn_ft = ft
            let wrapper = self.create_dyn_wrapper(impl_type_sym, wrapper_fn_sym, method_sym, fv, ft, dyn_ft, consumes_self)
            entries.push(wrapper)
        if used_row == 0:
            return
        let key = codegen_hash_type_trait_key(impl_type_sym, trait_sym)
        let global_name = "__vtable_" ++ type_name ++ "_" ++ trait_text
        let vg = wl_add_global(self.llmod, vtable_ty, global_name)
        let vconst = wl_const_named_struct(vtable_ty, vec_data_i64(&entries), method_count)
        wl_set_initializer(vg, vconst)
        wl_set_global_constant(vg, 1)
        wl_set_linkage(vg, wl_internal_linkage())
        self.vtable_globals.insert(key, vg)

    mut fn generate_trait_vtables():
        for i in 0..self.pool.decl_count():
            let decl = self.pool.get_decl(i)
            if self.pool.kind(decl) == NodeKind.NK_IMPL_DECL:
                self.generate_trait_vtable_for_impl(decl)

fn CONST_EVAL_FAIL -> i64: -9223372036854775807

type ConstStringEval {
    ok: bool,
    text: str,
}

fn const_string_eval_fail -> ConstStringEval:
    ConstStringEval {
        ok: false,
        text: "",
    }

fn const_string_eval_ok(text: &str) -> ConstStringEval:
    ConstStringEval {
        ok: true,
        text: with_str_clone_ref(text),
    }

impl Codegen:
    fn codegen_const_int_width(type_id: i32) -> i32:
        let numeric = self.sema.numeric_operand_type(type_id)
        let resolved = self.sema.resolve_alias(numeric as TypeId)
        if self.sema.get_type_kind(resolved) == TypeKind.TY_INT:
            return self.sema.get_type_d0(resolved)
        64

    fn codegen_const_int_is_unsigned(type_id: i32) -> bool:
        let numeric = self.sema.numeric_operand_type(type_id)
        let resolved = self.sema.resolve_alias(numeric as TypeId)
        if self.sema.get_type_kind(resolved) == TypeKind.TY_INT:
            return self.sema.get_type_d1(resolved) == 0
        false

    fn decl_source_path(decl_index: i32) -> str:
        if decl_index >= 0 and decl_index < self.decl_source_paths.len() as i32:
            let path = self.decl_source_paths.get(decl_index as i64)
            if path.len() > 0:
                return with_str_clone_ref(path)
        if self.current_decl_source_file.len() > 0 and self.current_decl_source_file != "<unknown>":
            return with_str_clone_ref(self.current_decl_source_file)
        with_str_clone_ref(self.source_file)

    mut fn sync_decl_context(decl_index: i32):
        self.current_decl_source_file = self.decl_source_path(decl_index)
        // Frozen name resolution (resolve_type_expr_frozen and friends) judges
        // module visibility from sema.current_module_path. Point it at the
        // DECLARING module, not the compilation root: a tool root does not
        // share src/'s internal-implementation boundary, so a non-pub distinct
        // alias like Mir.BlockId in MirLower's structs resolved for the
        // compiler root but not for tool-mode roots (#705). Same save/set
        // pattern as ComptimeEval.eval_decl and MirLower's module switch.
        // #747 instance G: sema retains its own copy — a plain field read here
        // is a move under the flip, and the reset-on-move blank made every decl
        // look like the root module (whole-program --emit-obj objects).
        if self.current_decl_source_file.len() > 0:
            self.sema.current_module_path = with_str_clone_ref(self.current_decl_source_file)

    fn find_module_fn_decl_index(sym: i32) -> i32:
        for di in 0..self.pool.decl_count():
            let decl = self.pool.get_decl(di)
            if self.pool.kind(decl) != NodeKind.NK_FN_DECL:
                continue
            if self.pool.get_data0(decl) == sym:
                return di
        -1

    fn function_link_name_for_sym(sym: i32) -> str:
        let name = self.function_symbol_name(sym)
        if self.module_object_mode == 0:
            return name
        let decl_index = self.find_module_fn_decl_index(sym)
        if decl_index < 0:
            return name
        let fn_node = self.pool.get_decl(decl_index)
        let flags = self.pool.get_data2(fn_node)
        if (flags / FnFlags.ENTRY) % 2 == 1:
            return "main"
        let meta = self.pool.find_fn_meta(fn_node)
        if meta >= 0:
            let cc_name = self.fn_callconv_name(meta)
            if cc_name.len() > 9 and cc_name.slice(0, 9) == "c_export:":
                let export_name = cc_name.slice(9, cc_name.len() as i64)
                if export_name.len() > 0:
                    return export_name
        self.module_link_name_for_path(self.decl_source_path(decl_index), name)

    fn current_decl_is_imported_module_symbol() -> bool:
        if self.module_object_mode == 0:
            return false
        if self.current_decl_source_file.len() == 0 or self.current_decl_source_file == "<unknown>":
            return false
        if self.source_file.len() == 0 or self.source_file == "<unknown>":
            return false
        self.current_decl_source_file != self.source_file

    fn find_module_let_decl_index(sym: i32) -> i32:
        for di in 0..self.pool.decl_count():
            let decl = self.pool.get_decl(di)
            if self.pool.kind(decl) != NodeKind.NK_LET_DECL:
                continue
            if self.pool.get_data0(decl) == sym:
                return di
        -1

    mut fn record_tracked_input(path: &str):
        var paths = move self.tracked_input_paths
        self.tracked_input_paths = tracked_input_insert_unique(move paths, path)

    mut fn read_tracked_embed_file(source_path: &str, raw_path: &str) -> TrackedReadResult:
        let result = tracked_embed_read(source_path, raw_path, self.tracked_input_root)
        if result.ok:
            self.record_tracked_input(result.resolved_path)
        result

    mut fn try_eval_const_string(node: i32, source_path: &str, depth: i32) -> ConstStringEval:
        if node == 0 or depth > 32:
            return const_string_eval_fail()

        let kind = self.pool.kind(node)
        if kind == NodeKind.NK_STRING_LIT or kind == NodeKind.NK_C_STRING_LIT:
            let sym = self.pool.get_data0(node)
            let raw = self.intern.resolve(sym)
            if raw.len() >= 5 and raw.byte_at(0) == 1 and raw.byte_at(1) == 114 and raw.byte_at(2) == 97 and raw.byte_at(3) == 119 and raw.byte_at(4) == 1:
                return const_string_eval_ok(raw.slice(5, raw.len()))
            return const_string_eval_ok(self.decode_string_escapes(raw))

        if kind == NodeKind.NK_COMPTIME or kind == NodeKind.NK_GROUPED:
            return self.try_eval_const_string(self.pool.get_data0(node), source_path, depth + 1)

        if kind == NodeKind.NK_BINARY:
            let op = self.pool.get_data0(node)
            if op == BinaryOp.OP_CONCAT or op == BinaryOp.OP_ADD:
                let lhs = self.try_eval_const_string(self.pool.get_data1(node), source_path, depth + 1)
                if not lhs.ok:
                    return lhs
                let rhs = self.try_eval_const_string(self.pool.get_data2(node), source_path, depth + 1)
                if not rhs.ok:
                    return rhs
                return const_string_eval_ok(lhs.text ++ rhs.text)

        if kind == NodeKind.NK_IDENT:
            let sym = self.pool.get_data0(node)
            let decl_index = self.find_module_let_decl_index(sym)
            if decl_index < 0:
                return const_string_eval_fail()
            let decl = self.pool.get_decl(decl_index)
            let flags = self.pool.get_data2(decl)
            if flags % 2 != 0:
                return const_string_eval_fail()
            var value_node = self.pool.get_data1(decl)
            if value_node == 0:
                return const_string_eval_fail()
            if self.pool.kind(value_node) == NodeKind.NK_COMPTIME:
                value_node = self.pool.get_data0(value_node)
            return self.try_eval_const_string(value_node, self.decl_source_path(decl_index), depth + 1)

        if kind == NodeKind.NK_CALL:
            let callee = self.pool.get_data0(node)
            if self.pool.kind(callee) != NodeKind.NK_IDENT:
                return const_string_eval_fail()
            let callee_sym = self.pool.get_data0(callee)
            if callee_sym != self.sema.syms.embed_file or self.pool.get_data2(node) != 1:
                return const_string_eval_fail()
            let args_start = self.pool.get_data1(node)
            let path_value = self.try_eval_const_string(self.pool.get_extra(args_start), source_path, depth + 1)
            if not path_value.ok:
                return path_value
            let read_result = self.read_tracked_embed_file(source_path, path_value.text)
            if not read_result.ok:
                with_eprint("error: " ++ read_result.error_msg)
                self.had_error = 1
                return const_string_eval_fail()
            return const_string_eval_ok(read_result.contents)

        const_string_eval_fail()

    mut fn try_resolve_vec_new_global_type(value_node: i32, flags: i32) -> i32:
        if value_node == 0 or self.pool.kind(value_node) != NodeKind.NK_CALL:
            return 0
        if self.pool.get_data2(value_node) != 0:
            return 0
        let callee = self.pool.get_data0(value_node)
        if self.pool.kind(callee) != NodeKind.NK_FIELD_ACCESS:
            return 0
        let recv = self.pool.get_data0(callee)
        let method_sym = self.pool.get_data1(callee)
        if method_sym != self.sym_new:
            return 0

        var recv_is_vec = false
        if self.pool.kind(recv) == NodeKind.NK_IDENT:
            recv_is_vec = self.pool.get_data0(recv) == self.sym_vec
        else if self.pool.kind(recv) == NodeKind.NK_INDEX:
            let recv_base = self.pool.get_data0(recv)
            if self.pool.kind(recv_base) == NodeKind.NK_IDENT:
                recv_is_vec = self.pool.get_data0(recv_base) == self.sym_vec
        if not recv_is_vec:
            return 0

        let type_extra_packed = flags / 16
        if type_extra_packed > 0:
            let type_ann_node = self.pool.get_extra(type_extra_packed - 1)
            let annotated = self.sema.resolve_type_expr_frozen(type_ann_node)
            if annotated > 0:
                return annotated as i32
        if self.sema.typed_expr_types.contains(value_node):
            let inferred = self.sema.typed_expr_types.get(value_node).unwrap()
            if inferred > 0:
                return inferred
        0

    mut fn emit_vec_new_global(name_sym: i32, vec_tid: i32, is_mut: i32) -> bool:
        let resolved = self.sema.resolve_alias(vec_tid)
        if self.sema.get_type_kind(resolved) != TypeKind.TY_GENERIC_INST:
            return false
        let base_sym = self.sema.get_type_d0(resolved)
        if base_sym != self.sym_vec:
            return false
        if self.sema.get_type_d2(resolved) != 1:
            return false

        let elem_tid = self.sema.get_generic_inst_arg(resolved, 0)
        let elem_llvm = self.sema_type_to_llvm(elem_tid)
        let vec_llvm = self.sema_type_to_llvm(resolved)
        if elem_llvm == 0 or vec_llvm == 0:
            return false

        let i64_ty = wl_i64_type(self.context)
        let fields: Vec[i64] = Vec.new()
        fields.push(wl_const_null(wl_ptr_type(self.context)))
        fields.push(wl_const_int(i64_ty, 0, 0))
        fields.push(wl_const_int(i64_ty, 0, 0))
        // Vec.new() is logically { null, 0, 0, sizeof(T) } for globals.
        fields.push(wl_const_int(i64_ty, self.abi_size_of(elem_llvm), 0))
        let init = wl_const_named_struct(vec_llvm, vec_data_i64(&fields), 4)

        let _ = self.record_module_binding_global(name_sym, vec_llvm, init, is_mut)
        true

    fn finalize_module_binding_global(gv: i64, is_mut: i32):
        if self.module_object_mode != 0:
            if is_mut == 0:
                wl_set_global_constant(gv, 1)
            wl_set_linkage(gv, 0)
            return
        if is_mut == 0:
            wl_set_global_constant(gv, 1)
            wl_set_linkage(gv, wl_internal_linkage())
            return
        wl_set_linkage(gv, 0)

    fn declare_module_binding_global(name_sym: i32, global_ty: i64, is_mut: i32) -> i64:
        let name_str = self.current_decl_module_link_name(self.intern.resolve(name_sym))
        let existing = wl_get_named_global(self.llmod, name_str)
        let gv =
            if existing != 0:
                existing
            else:
                wl_add_global(self.llmod, global_ty, name_str)
        if is_mut == 0:
            wl_set_global_constant(gv, 1)
        wl_set_linkage(gv, 0)
        self.module_constants.insert(name_sym, gv)
        gv

    fn define_module_binding_global(name_sym: i32, global_ty: i64, init: i64, is_mut: i32) -> i64:
        let name_str = self.current_decl_module_link_name(self.intern.resolve(name_sym))
        let existing = wl_get_named_global(self.llmod, name_str)
        let gv =
            if existing != 0:
                existing
            else:
                wl_add_global(self.llmod, global_ty, name_str)
        wl_set_initializer(gv, init)
        self.finalize_module_binding_global(gv, is_mut)
        self.module_constants.insert(name_sym, gv)
        gv

    fn record_module_binding_global(name_sym: i32, global_ty: i64, init: i64, is_mut: i32) -> i64:
        if self.current_decl_is_imported_module_symbol():
            return self.declare_module_binding_global(name_sym, global_ty, is_mut)
        self.define_module_binding_global(name_sym, global_ty, init, is_mut)

    mut fn register_module_global_drop(name_sym: i32, tid: i32):
        // #777: the exit wrapper drops droppable module globals. Only
        // writable storage registers — a storage-const global can never own
        // heap data, and its read-only page would fault on the drop's
        // zeroing write. Callers enforce the writability condition.
        if tid == 0 or self.sema.type_needs_drop_frozen(tid) == 0: return
        for i in 0..self.module_drop_global_syms.len() as i32:
            if self.module_drop_global_syms.get(i as i64) == name_sym: return
        self.module_drop_global_syms.push(name_sym)
        self.module_drop_global_tids.push(tid)

    fn record_runtime_init_storage_global(name_sym: i32, global_ty: i64) -> i64:
        // Runtime-initialized module constants are still language-level `const`
        // bindings, but their backing storage must remain writable until the
        // wrapper main populates them via __with_init_const_* helpers.
        self.record_module_binding_global(name_sym, global_ty, self.build_default_value(global_ty), 1)

    mut fn queue_module_runtime_init(name_sym: i32, value_node: i32, result_tid: i32, is_mut: i32) -> bool:
        let _ = is_mut
        let global_ty = self.sema_type_to_llvm(result_tid)
        if global_ty == 0:
            return false
        let _ = self.record_runtime_init_storage_global(name_sym, global_ty)
        // Runtime-init storage is writable even for `let` bindings, so its
        // heap-owning value registers for the exit drop regardless of mut.
        self.register_module_global_drop(name_sym, result_tid)
        if self.current_decl_is_imported_module_symbol():
            return true
        self.module_runtime_init_syms.push(name_sym)
        self.module_runtime_init_nodes.push(value_node)
        self.module_runtime_init_type_ids.push(result_tid)
        true

    mut fn emit_module_runtime_init_fn(name_sym: i32, value_node: i32, result_tid: i32) -> i64:
        let ret_ty = self.sema_type_to_llvm(result_tid)
        if ret_ty == 0:
            return 0
        let init_name = "__with_init_const_" ++ self.intern.resolve(name_sym)
        let existing = wl_get_named_function(self.llmod, init_name)
        if existing != 0:
            return existing

        let ft = wl_function_type(ret_ty, 0, 0, 0)
        let function = wl_add_function(self.llmod, init_name, ft)
        wl_set_linkage(function, wl_internal_linkage())

        let saved_fn = self.current_function
        let saved_ret = self.current_ret_type
        let saved_owner = self.current_method_owner_sym
        let saved_allocas = self.local_allocas
        let saved_types = self.local_types
        let saved_muts = self.local_muts
        let saved_fn_sigs = self.local_fn_sigs
        let saved_pointees = self.local_pointee_structs
        let saved_tasks = self.task_locals
        let saved_trait_locals = self.trait_locals
        let saved_trait_concrete = self.trait_local_concrete_types
        let saved_scope_syms = self.scope_local_syms
        let saved_scope_allocas = self.scope_local_allocas
        let saved_scope_types = self.scope_local_types
        let saved_scope_count = self.scope_local_count
        let saved_defer = self.defer_stack
        let saved_errdefer = self.errdefer_stack
        let saved_enum_local_types = self.enum_local_types
        let saved_sema_local_types = self.local_sema_types
        let saved_expected = self.expected_type
        let saved_expected_node = self.expected_type_node
        let saved_result_err = self.current_result_err_symbol
        let saved_returns_result = self.current_fn_returns_result
        let saved_saw_return = self.current_fn_saw_explicit_return
        let saved_tail_bb = self.tailrec_body_bb
        let saved_tail_sym = self.tailrec_fn_sym
        let saved_tail_allocas = self.tailrec_param_allocas
        let saved_loops = self.capture_loop_state()
        let saved_bb = wl_get_insert_block(self.builder)
        let saved_mir_values = self.mir_local_values
        let saved_mir_memory_locals = self.mir_memory_locals
        // The return terminator lowering reads current_function_name_sym to look
        // up this function's sret ABI (extern_fn_has_sret). If we leave the
        // previously-emitted function's sym here, an init fn inherits that
        // function's sret decision — on windows that means storing to a null
        // sret param (there is none) and `ret void` against a value return.
        let saved_fn_name_sym = self.current_function_name_sym

        let fresh_local_allocas: HashMap[i32, i64] = HashMap.new()
        let fresh_local_types: HashMap[i32, i64] = HashMap.new()
        let fresh_local_muts: HashMap[i32, i32] = HashMap.new()
        let fresh_local_fn_sigs: HashMap[i32, i64] = HashMap.new()
        let fresh_local_pointees: HashMap[i32, i32] = HashMap.new()
        let fresh_task_locals: HashMap[i32, i32] = HashMap.new()
        let fresh_trait_locals: HashMap[i32, i32] = HashMap.new()
        let fresh_trait_concrete: HashMap[i32, i32] = HashMap.new()
        let fresh_enum_local_types: HashMap[i32, i32] = HashMap.new()
        let fresh_scope_syms: Vec[i32] = Vec.new()
        let fresh_scope_allocas: Vec[i64] = Vec.new()
        let fresh_scope_types: Vec[i64] = Vec.new()
        let fresh_defer_stack: Vec[i32] = Vec.new()
        let fresh_errdefer_stack: Vec[i32] = Vec.new()
        let fresh_tail_allocas: Vec[i64] = Vec.new()

        self.current_function = function
        self.current_ret_type = ret_ty
        self.current_method_owner_sym = 0
        self.local_allocas = fresh_local_allocas
        self.local_types = fresh_local_types
        self.local_muts = fresh_local_muts
        self.local_fn_sigs = fresh_local_fn_sigs
        self.local_pointee_structs = fresh_local_pointees
        self.task_locals = fresh_task_locals
        self.trait_locals = fresh_trait_locals
        self.trait_local_concrete_types = fresh_trait_concrete
        self.enum_local_types = fresh_enum_local_types
        self.scope_local_syms = fresh_scope_syms
        self.scope_local_allocas = fresh_scope_allocas
        self.scope_local_types = fresh_scope_types
        self.scope_local_count = 0
        self.defer_stack = fresh_defer_stack
        self.errdefer_stack = fresh_errdefer_stack
        self.local_sema_types = HashMap.new()
        self.expected_type = ret_ty
        self.expected_type_node = 0
        self.current_result_err_symbol = 0
        self.current_fn_returns_result = false
        self.current_fn_saw_explicit_return = false
        self.tailrec_body_bb = 0
        self.tailrec_fn_sym = 0
        self.tailrec_param_allocas = fresh_tail_allocas
        self.reset_loop_state()

        let entry = wl_append_bb(self.context, function, "entry")
        wl_position_at_end(self.builder, entry)

        let saved_mir_locals = self.mir_local_ptrs
        let saved_mir_local_types = self.mir_local_types
        let saved_mir_bbs = self.mir_bb_values
        let saved_mir_unreachable = self.mir_default_unreachable_bbs
        self.mir_local_ptrs = HashMap.new()
        self.mir_local_values = HashMap.new()
        self.mir_memory_locals = HashMap.new()
        self.mir_local_types = HashMap.new()
        self.mir_bb_values = Vec.new()
        self.mir_default_unreachable_bbs = Vec.new()

        let init_sym = self.intern.intern(init_name)
        // This function is declared with a direct value return (no sret param),
        // so its return-lowering must read its own (absent) sret status, not the
        // stale predecessor's.
        self.current_function_name_sym = init_sym
        var init_builder = MirBuilder.init(self.sema, self.pool, self.intern, init_sym)
        init_builder.body.local_type_ids.set_i32(0, result_tid)
        init_builder.push_scope()
        init_builder.expected_type = result_tid
        let init_result = init_builder.lower_expr(value_node)
        let init_ret_place = init_builder.place_for_local(0)
        init_builder.assign_operand_to_place(init_ret_place, init_result, self.pool.get_end(value_node))
        init_builder.pop_scope_inline()
        init_builder.terminate(TermKind.TK_RETURN, 0, 0, 0, 0)
        let init_body = init_builder.body
        // Codegen-synthesized bodies never reach `--dump-mir` (that dumps the
        // Sema-lowered module). WITH_DUMP_INIT_MIR exposes them; #719 was
        // invisible without it.
        if with_getenv_str("WITH_DUMP_INIT_MIR").len() > 0:
            with_eprint(dump_mir_body(&init_body, &self.intern, &self.sema))
        // #719 class: a synthesized body that reads a killed local computes from
        // zeroed storage. Report it here rather than emitting silently broken code.
        let uak = validate_use_after_kill(&init_body, &self.intern)
        if uak.len() > 0:
            with_eprint("error: const initializer MIR is invalid: " ++ uak)
        self.mir_scan_memory_locals(init_body)

        // Void results keep the dead i32 slot — alloca of void traps in LLVM.
        let init_ret_store_ty = if ret_ty != wl_void_type(self.context): ret_ty else: wl_i32_type(self.context)
        let ret_alloca = self.create_entry_alloca(init_ret_store_ty)
        self.mir_local_ptrs.insert(0, ret_alloca)
        self.mir_local_types.insert(0, ret_ty)

        for gli in 0..init_body.local_names.len() as i32:
            let gl_name = init_body.local_names.get(gli as i64)
            if gl_name == 0:
                continue
            let gl_opt = self.module_constants.get(gl_name)
            if gl_opt.is_some():
                let global_value: i64 = gl_opt.unwrap()
                self.mir_local_ptrs.insert(gli, global_value)

        for bb in 0..init_body.block_count():
            let llbb = wl_append_bb(self.context, function, f"mir.bb{bb}")
            self.mir_bb_values.push(llbb)

        if self.mir_bb_values.len() as i32 > 0:
            wl_build_br(self.builder, self.mir_bb_values.get(0))
        else:
            let _ = wl_build_ret(self.builder, wl_const_null(ret_ty))

        for bb in 0..init_body.block_count():
            if bb < 0 or bb >= self.mir_bb_values.len() as i32:
                continue
            let llbb = self.mir_bb_values.get(bb as i64)
            wl_position_at_end(self.builder, llbb)
            let stmt_start = init_body.bb_stmt_starts.get(bb as i64)
            let stmt_count = init_body.bb_stmt_counts.get(bb as i64)
            for si in 0..stmt_count:
                let stmt_id = stmt_start + si
                if not self.mir_emit_stmt(init_body, stmt_id):
                    let fail_bb = wl_get_insert_block(self.builder)
                    if fail_bb != 0 and wl_get_bb_terminator(fail_bb) == 0:
                        wl_build_unreachable(self.builder)
            let term_bb = wl_get_insert_block(self.builder)
            if term_bb != 0 and wl_get_bb_terminator(term_bb) == 0:
                if not self.mir_emit_term(init_body, bb):
                    let after_term_bb = wl_get_insert_block(self.builder)
                    if after_term_bb != 0 and wl_get_bb_terminator(after_term_bb) == 0:
                        let _ = wl_build_ret(self.builder, wl_const_null(ret_ty))

        self.mir_local_ptrs = saved_mir_locals
        self.mir_local_values = saved_mir_values
        self.mir_memory_locals = saved_mir_memory_locals
        self.mir_local_types = saved_mir_local_types
        self.mir_bb_values = saved_mir_bbs
        self.mir_default_unreachable_bbs = saved_mir_unreachable

        self.current_function = saved_fn
        self.current_ret_type = saved_ret
        self.current_function_name_sym = saved_fn_name_sym
        self.current_method_owner_sym = saved_owner
        self.local_allocas = saved_allocas
        self.local_types = saved_types
        self.local_muts = saved_muts
        self.local_fn_sigs = saved_fn_sigs
        self.local_pointee_structs = saved_pointees
        self.task_locals = saved_tasks
        self.trait_locals = saved_trait_locals
        self.trait_local_concrete_types = saved_trait_concrete
        self.enum_local_types = saved_enum_local_types
        self.scope_local_syms = saved_scope_syms
        self.scope_local_allocas = saved_scope_allocas
        self.scope_local_types = saved_scope_types
        self.scope_local_count = saved_scope_count
        self.defer_stack = saved_defer
        self.errdefer_stack = saved_errdefer
        self.local_sema_types = saved_sema_local_types
        self.expected_type = saved_expected
        self.expected_type_node = saved_expected_node
        self.current_result_err_symbol = saved_result_err
        self.current_fn_returns_result = saved_returns_result
        self.current_fn_saw_explicit_return = saved_saw_return
        self.tailrec_body_bb = saved_tail_bb
        self.tailrec_fn_sym = saved_tail_sym
        self.tailrec_param_allocas = saved_tail_allocas
        self.restore_loop_state(saved_loops)
        if saved_bb != 0:
            wl_position_at_end(self.builder, saved_bb)

        function

    mut fn emit_module_runtime_init_helpers() -> Unit:
        for i in 0..self.module_runtime_init_syms.len() as i32:
            let name_sym = self.module_runtime_init_syms.get(i as i64)
            let value_node = self.module_runtime_init_nodes.get(i as i64)
            let result_tid = self.module_runtime_init_type_ids.get(i as i64)
            let global_opt = self.module_constants.get(name_sym)
            if not global_opt.is_some():
                with_eprint("error: missing global storage for runtime-initialized module constant '" ++ self.intern.resolve(name_sym) ++ "'")
                self.had_error = 1
                return
            let init_fn = self.emit_module_runtime_init_fn(name_sym, value_node, result_tid)
            let init_ty = self.sema_type_to_llvm(result_tid)
            if init_fn == 0 or init_ty == 0:
                with_eprint("error: failed to emit runtime initializer for module constant '" ++ self.intern.resolve(name_sym) ++ "'")
                self.had_error = 1
                return
            self.module_runtime_init_globals.push(global_opt.unwrap() as i64)
            self.module_runtime_init_fns.push(init_fn)
            self.module_runtime_init_types.push(init_ty)

    fn is_collection_runtime_intrinsic(intrinsic: MirIntrinsic) -> bool:
        let _ = self
        if intrinsic == MirIntrinsic.VEC_NEW or intrinsic == MirIntrinsic.VEC_WITH_CAPACITY or intrinsic == MirIntrinsic.VEC_PUSH or intrinsic == MirIntrinsic.VEC_GET or intrinsic == MirIntrinsic.VEC_LEN or intrinsic == MirIntrinsic.VEC_IS_EMPTY or intrinsic == MirIntrinsic.VEC_LEN32 or intrinsic == MirIntrinsic.VEC_LEN64 or intrinsic == MirIntrinsic.VEC_ULEN32 or intrinsic == MirIntrinsic.VEC_SET or intrinsic == MirIntrinsic.VEC_REMOVE or intrinsic == MirIntrinsic.VEC_CLEAR or intrinsic == MirIntrinsic.VEC_POP or intrinsic == MirIntrinsic.VEC_ITER or intrinsic == MirIntrinsic.VEC_MAP or intrinsic == MirIntrinsic.VEC_FILTER or intrinsic == MirIntrinsic.VEC_FOLD or intrinsic == MirIntrinsic.VEC_CONTAINS or intrinsic == MirIntrinsic.VEC_JOIN:
            return true
        if intrinsic == MirIntrinsic.MAP_NEW or intrinsic == MirIntrinsic.MAP_INSERT or intrinsic == MirIntrinsic.MAP_GET or intrinsic == MirIntrinsic.MAP_CONTAINS or intrinsic == MirIntrinsic.MAP_LEN or intrinsic == MirIntrinsic.MAP_LEN32 or intrinsic == MirIntrinsic.MAP_LEN64 or intrinsic == MirIntrinsic.MAP_ULEN32 or intrinsic == MirIntrinsic.MAP_REMOVE or intrinsic == MirIntrinsic.MAP_CLEAR or intrinsic == MirIntrinsic.MAP_INCREMENT or intrinsic == MirIntrinsic.MAP_DECREMENT or intrinsic == MirIntrinsic.MAP_UPDATE:
            return true
        if intrinsic == MirIntrinsic.SLOTMAP_NEW or intrinsic == MirIntrinsic.SLOTMAP_INSERT or intrinsic == MirIntrinsic.SLOTMAP_GET or intrinsic == MirIntrinsic.SLOTMAP_SLOT or intrinsic == MirIntrinsic.SLOTMAP_REMOVE or intrinsic == MirIntrinsic.SLOTMAP_REPLACE or intrinsic == MirIntrinsic.SLOTMAP_CONTAINS or intrinsic == MirIntrinsic.SLOTMAP_LEN or intrinsic == MirIntrinsic.SLOTMAP_LEN32 or intrinsic == MirIntrinsic.SLOTMAP_LEN64 or intrinsic == MirIntrinsic.SLOTMAP_ULEN32 or intrinsic == MirIntrinsic.SLOTMAP_GET_DISJOINT or intrinsic == MirIntrinsic.SLOTMAPSLOT_GET or intrinsic == MirIntrinsic.SLOTMAPSLOT_SET:
            return true
        false

    mut fn module_const_contains_runtime_collection(node: i32) -> bool:
        if node == 0:
            return false
        let kind = self.pool.kind(node)
        if kind == NodeKind.NK_COMPTIME or kind == NodeKind.NK_GROUPED or kind == NodeKind.NK_RETURN:
            return self.module_const_contains_runtime_collection(self.pool.get_data0(node))
        if kind == NodeKind.NK_LABEL:
            return self.module_const_contains_runtime_collection(self.pool.get_data1(node))
        if kind == NodeKind.NK_GOTO:
            return false
        if kind == NodeKind.NK_UNARY:
            return self.module_const_contains_runtime_collection(self.pool.get_data1(node))
        if kind == NodeKind.NK_BINARY or kind == NodeKind.NK_ASSIGN or kind == NodeKind.NK_INDEX:
            if self.module_const_contains_runtime_collection(self.pool.get_data0(node)):
                return true
            if self.module_const_contains_runtime_collection(self.pool.get_data1(node)):
                return true
            return self.module_const_contains_runtime_collection(self.pool.get_data2(node))
        if kind == NodeKind.NK_FIELD_ACCESS:
            return self.module_const_contains_runtime_collection(self.pool.get_data0(node))
        if kind == NodeKind.NK_CALL:
            let callee = self.pool.get_data0(node)
            if self.pool.kind(callee) == NodeKind.NK_FIELD_ACCESS:
                let recv = self.pool.get_data0(callee)
                let method_sym = self.pool.get_data1(callee)
                let intrinsic = self.classify_generic_call_intrinsic(self.ast_static_type_expr(recv), method_sym)
                if self.is_collection_runtime_intrinsic(intrinsic):
                    return true
                if self.module_const_contains_runtime_collection(recv):
                    return true
            else if self.module_const_contains_runtime_collection(callee):
                return true
            let extra_start = self.pool.get_data1(node)
            let arg_count = self.pool.get_data2(node)
            for i in 0..arg_count:
                if self.module_const_contains_runtime_collection(self.pool.get_extra(extra_start + i)):
                    return true
            return false
        if kind == NodeKind.NK_LET_BINDING:
            return self.module_const_contains_runtime_collection(self.pool.get_data1(node))
        if kind == NodeKind.NK_BLOCK:
            let stmt_start = self.pool.get_data0(node)
            let stmt_count = self.pool.get_data1(node)
            for i in 0..stmt_count:
                if self.module_const_contains_runtime_collection(self.pool.get_extra(stmt_start + i)):
                    return true
            return self.module_const_contains_runtime_collection(self.pool.get_data2(node))
        if kind == NodeKind.NK_STRUCT_LIT:
            let field_start = self.pool.get_data1(node)
            let field_count = self.pool.get_data2(node)
            for i in 0..field_count:
                let value_node = self.pool.get_extra(field_start + i * 2 + 1)
                if self.module_const_contains_runtime_collection(value_node):
                    return true
            return false
        if kind == NodeKind.NK_ARRAY_LIT or kind == NodeKind.NK_TUPLE:
            let extra_start = self.pool.get_data1(node)
            let item_count = self.pool.get_data2(node)
            for i in 0..item_count:
                if self.module_const_contains_runtime_collection(self.pool.get_extra(extra_start + i)):
                    return true
            return false
        if kind == NodeKind.NK_IF_EXPR:
            if self.module_const_contains_runtime_collection(self.pool.get_data0(node)):
                return true
            if self.module_const_contains_runtime_collection(self.pool.get_data1(node)):
                return true
            return self.module_const_contains_runtime_collection(self.pool.get_data2(node))
        false

    fn module_const_value_node(sym: i32) -> i32:
        for di in 0..self.pool.decl_count():
            let decl = self.pool.get_decl(di)
            if self.pool.kind(decl) != NodeKind.NK_LET_DECL:
                continue
            if self.pool.get_data0(decl) != sym:
                continue
            let flags = self.pool.get_data2(decl)
            let is_mut = flags % 2
            if is_mut != 0:
                continue
            var value_node = self.pool.get_data1(decl)
            if value_node == 0:
                continue
            if self.pool.kind(value_node) == NodeKind.NK_COMPTIME:
                value_node = self.pool.get_data0(value_node)
            return value_node
        0

    mut fn exact_int_const_llvm(node: i32, sema_tid: i32) -> i64:
        if node == 0 or sema_tid == 0:
            return 0
        let resolved = self.sema.resolve_alias(sema_tid as TypeId)
        let tk = self.sema.get_type_kind(resolved)
        if tk != TypeKind.TY_INT and tk != TypeKind.TY_BOOL:
            return 0
        let bits = if tk == TypeKind.TY_BOOL: 1 else: self.sema.get_type_d0(resolved)
        let signed = if tk == TypeKind.TY_INT: self.sema.get_type_d1(resolved) else: 0
        let words = self.pool.int_literal_expr_bits(node, bits, signed)
        if words.ok == 0 or words.overflow != 0:
            return 0
        let llvm_ty = self.sema_type_to_llvm(resolved)
        if llvm_ty == 0:
            return 0
        wl_const_int_words(llvm_ty, words.lo, words.hi, if bits > 64: 2 else: 1)

    fn exact_int_expr_to_f64(node: i32) -> f64:
        let expr = self.pool.int_literal_exact_expr(node)
        if expr.ok == 0 or expr.overflow != 0:
            return 0.0
        let mag = exact_int_expr_magnitude(expr)
        var out = exact_int_word_to_f64(mag.hi) * 18446744073709551616.0 + exact_int_word_to_f64(mag.lo)
        if expr.negative != 0:
            out = -out
        out

    fn unwrap_const_expr_node(node: i32) -> i32:
        var cur = node
        while cur != 0:
            let kind = self.pool.kind(cur)
            if kind == NodeKind.NK_COMPTIME or kind == NodeKind.NK_GROUPED or kind == NodeKind.NK_CAST:
                cur = self.pool.get_data0(cur)
                continue
            break
        cur

    fn coerce_const_value_to_type(value: i64, expected_ty: i64) -> i64:
        if value == 0 or expected_ty == 0:
            return 0
        let actual_ty = wl_type_of(value)
        if actual_ty == expected_ty:
            return value
        if wl_get_type_kind(actual_ty) == wl_pointer_type_kind() and wl_get_type_kind(expected_ty) == wl_pointer_type_kind():
            return wl_const_bitcast(value, expected_ty)
        0

    fn const_c_string_pointer(text: &str, ptr_ty: i64) -> i64:
        if ptr_ty == 0:
            return 0
        let name = f"__with_cstr_{codegen_hash_name_component(with_str_hash(text))}_{text.len()}"
        var bytes_global = wl_get_named_global(self.llmod, name)
        if bytes_global == 0:
            let bytes_ty = wl_array_type(wl_i8_type(self.context), text.len() + 1)
            bytes_global = wl_add_global(self.llmod, bytes_ty, name)
            wl_set_initializer(bytes_global, wl_const_string(self.context, text, 0))
            wl_set_global_constant(bytes_global, 1)
            wl_set_linkage(bytes_global, wl_private_linkage())
        self.coerce_const_value_to_type(bytes_global, ptr_ty)

    mut fn try_eval_const_pointer_llvm(node: i32, expected_tid: i32) -> i64:
        if node == 0 or expected_tid <= 0:
            return 0
        let resolved = self.sema.resolve_alias(expected_tid as TypeId)
        let ptr_ty = self.sema_type_to_llvm(resolved)
        if ptr_ty == 0:
            return 0

        let cur = self.unwrap_const_expr_node(node)
        if cur == 0:
            return 0
        let kind = self.pool.kind(cur)
        if kind == NodeKind.NK_NULL_LIT:
            return wl_const_null(ptr_ty)

        let current_source_file = self.current_decl_source_file
        let str_value = self.try_eval_const_string(cur, current_source_file, 0)
        if str_value.ok:
            return self.const_c_string_pointer(str_value.text, ptr_ty)

        if kind == NodeKind.NK_IDENT:
            let sym = self.pool.get_data0(cur)
            let fn_val = self.fn_values.get(sym)
            if fn_val.is_some():
                return self.coerce_const_value_to_type(fn_val.unwrap() as i64, ptr_ty)
            return 0

        if kind == NodeKind.NK_UNARY:
            let uop = self.pool.get_data0(cur)
            if uop == UnaryOp.UOP_REF or uop == UnaryOp.UOP_RAW_REF_CONST or uop == UnaryOp.UOP_RAW_REF_MUT:
                let target = self.unwrap_const_expr_node(self.pool.get_data1(cur))
                if target == 0:
                    return 0
                if self.pool.kind(target) == NodeKind.NK_IDENT:
                    let target_sym = self.pool.get_data0(target)
                    let gv = self.module_constants.get(target_sym)
                    if gv.is_some():
                        return self.coerce_const_value_to_type(gv.unwrap() as i64, ptr_ty)
                    return 0
                if self.pool.kind(target) == NodeKind.NK_INDEX:
                    let base = self.unwrap_const_expr_node(self.pool.get_data0(target))
                    let idx_node = self.pool.get_data1(target)
                    let idx_val = self.try_eval_const_int(idx_node)
                    if idx_val != 0:
                        return 0
                    if base != 0 and self.pool.kind(base) == NodeKind.NK_IDENT:
                        let base_sym = self.pool.get_data0(base)
                        let gv = self.module_constants.get(base_sym)
                        if gv.is_some():
                            return self.coerce_const_value_to_type(gv.unwrap() as i64, ptr_ty)
                    return 0

        let ptr_zero = self.try_eval_const_int(cur)
        if ptr_zero == 0:
            return wl_const_null(ptr_ty)
        0

    fn struct_literal_field_value_node(lit_node: i32, field_name: i32, field_index: i32) -> i32:
        if lit_node == 0 or self.pool.kind(lit_node) != NodeKind.NK_STRUCT_LIT:
            return 0
        let field_start = self.pool.get_data1(lit_node)
        let lit_field_count = self.pool.get_data2(lit_node)
        let want_text = self.intern.resolve(field_name)
        for li in 0..lit_field_count:
            let lit_name = self.pool.get_extra(field_start + li * 2)
            let lit_value = self.pool.get_extra(field_start + li * 2 + 1)
            if lit_name == 0:
                if li == field_index:
                    return lit_value
            else if lit_name == field_name:
                return lit_value
            else if want_text.len() > 0 and self.intern.resolve(lit_name) == want_text:
                return lit_value
        0

    mut fn try_eval_const_struct_llvm(node: i32, expected_tid: i32) -> i64:
        if node == 0 or expected_tid <= 0:
            return 0
        let cur = self.unwrap_const_expr_node(node)
        if cur == 0 or self.pool.kind(cur) != NodeKind.NK_STRUCT_LIT:
            return 0
        let resolved = self.sema.resolve_alias(expected_tid as TypeId)
        if self.sema.get_type_kind(resolved) != TypeKind.TY_STRUCT:
            return 0
        let struct_ty = self.sema_type_to_llvm(resolved)
        if struct_ty == 0 or wl_get_type_kind(struct_ty) != wl_struct_type_kind():
            return 0
        let struct_idx = self.find_struct_index_by_type(struct_ty)
        if struct_idx < 0:
            return 0

        let llvm_field_count = wl_count_struct_elem_types(struct_ty)
        let fields: Vec[i64] = Vec.new()
        for li in 0..llvm_field_count:
            let llvm_field_ty = wl_struct_get_type_at(struct_ty, li)
            fields.push(self.build_default_value(llvm_field_ty))

        let te_start = self.sema.get_type_d1(resolved)
        let source_field_count = self.sema.get_type_d2(resolved)
        if self.is_union_struct_index(struct_idx):
            for fi in 0..source_field_count:
                let field_name = self.sema.type_extra.get((te_start + fi * 3) as i64)
                let field_tid: i32 = self.sema.type_extra.get((te_start + fi * 3 + 1) as i64)
                let value_node = self.struct_literal_field_value_node(cur, field_name, fi)
                if value_node == 0:
                    continue
                let llvm_idx = self.get_llvm_field_index(struct_ty, fi)
                if llvm_idx < 0 or llvm_idx >= llvm_field_count:
                    return 0
                let storage_ty = wl_struct_get_type_at(struct_ty, llvm_idx)
                let field_val = self.try_eval_const_llvm(value_node, field_tid)
                let coerced = self.coerce_const_value_to_type(field_val, storage_ty)
                if coerced == 0:
                    return 0
                fields[llvm_idx] = coerced
                return wl_const_named_struct(struct_ty, vec_data_i64(&fields), llvm_field_count)
            return wl_const_named_struct(struct_ty, vec_data_i64(&fields), llvm_field_count)
        for fi in 0..source_field_count:
            let field_name = self.sema.type_extra.get((te_start + fi * 3) as i64)
            let field_tid: i32 = self.sema.type_extra.get((te_start + fi * 3 + 1) as i64)
            let default_node = self.sema.type_extra.get((te_start + fi * 3 + 2) as i64)
            let llvm_idx = self.get_llvm_field_index(struct_ty, fi)
            if llvm_idx < 0 or llvm_idx >= llvm_field_count:
                return 0
            let field_llvm_ty = wl_struct_get_type_at(struct_ty, llvm_idx)
            let value_node = self.struct_literal_field_value_node(cur, field_name, fi)
            var field_val: i64 = 0
            if value_node != 0:
                field_val = self.try_eval_const_llvm(value_node, field_tid)
            else if default_node != 0:
                field_val = self.try_eval_const_llvm(default_node, field_tid)
            else:
                field_val = self.build_default_value(field_llvm_ty)
            field_val = self.coerce_const_value_to_type(field_val, field_llvm_ty)
            if field_val == 0:
                return 0
            fields[llvm_idx] = field_val

        wl_const_named_struct(struct_ty, vec_data_i64(&fields), llvm_field_count)

    fn try_eval_const_result_type(node: i32, expected_tid: i32) -> i32:
        if expected_tid != 0:
            return expected_tid
        let typed = self.sema_type_of_node(node)
        if typed != 0:
            return typed
        expected_tid

    mut fn try_eval_const_int(node: i32) -> i64:
        self.try_eval_const_int_expected(node, 0)

    mut fn try_eval_const_int_expected(node: i32, expected_tid: i32) -> i64:
        let kind = self.pool.kind(node)
        if kind == NodeKind.NK_INT_LIT:
            let fast = self.pool.int_literal_fast_i64(node as NodeId)
            if fast.ok == 0:
                return CONST_EVAL_FAIL()
            return fast.value
        if kind == NodeKind.NK_COMPTIME:
            return self.try_eval_const_int_expected(self.pool.get_data0(node), expected_tid)
        if kind == NodeKind.NK_GROUPED:
            return self.try_eval_const_int_expected(self.pool.get_data0(node), expected_tid)
        if kind == NodeKind.NK_CAST:
            return self.try_eval_const_int_expected(self.pool.get_data0(node), expected_tid)
        if kind == NodeKind.NK_BOOL_LIT:
            return self.pool.get_data0(node) as i64
        if kind == NodeKind.NK_UNARY:
            let op = self.pool.get_data0(node)
            let inner_val = self.try_eval_const_int_expected(self.pool.get_data1(node), expected_tid)
            if inner_val == CONST_EVAL_FAIL(): return CONST_EVAL_FAIL()
            if op == UnaryOp.UOP_NEGATE:
                let result_ty = self.try_eval_const_result_type(node, expected_tid)
                let arith = int_eval_unary_neg(inner_val, self.codegen_const_int_width(result_ty), self.overflow_mode)
                if arith.ok == 0 or arith.overflow != 0: return CONST_EVAL_FAIL()
                return arith.value
            if op == UnaryOp.UOP_BIT_NOT: return 0 - inner_val - 1
            if op == UnaryOp.UOP_NOT:
                if inner_val == 0: return 1
                return 0
            return CONST_EVAL_FAIL()
        if kind == NodeKind.NK_BINARY:
            let op = self.pool.get_data0(node)
            let lv = self.try_eval_const_int_expected(self.pool.get_data1(node), expected_tid)
            if lv == CONST_EVAL_FAIL(): return CONST_EVAL_FAIL()
            let rv = self.try_eval_const_int_expected(self.pool.get_data2(node), expected_tid)
            if rv == CONST_EVAL_FAIL(): return CONST_EVAL_FAIL()
            if op == BinaryOp.OP_ADD or op == BinaryOp.OP_ADD_WRAP or op == BinaryOp.OP_ADD_SAT or op == BinaryOp.OP_SUB or op == BinaryOp.OP_SUB_WRAP or op == BinaryOp.OP_SUB_SAT or op == BinaryOp.OP_MUL or op == BinaryOp.OP_MUL_WRAP or op == BinaryOp.OP_MUL_SAT:
                let result_ty = self.try_eval_const_result_type(node, expected_tid)
                let arith = int_eval_binary_arithmetic(op, lv, rv, self.codegen_const_int_width(result_ty), self.codegen_const_int_is_unsigned(result_ty), self.overflow_mode)
                if arith.ok == 0 or arith.overflow != 0: return CONST_EVAL_FAIL()
                return arith.value
            if op == BinaryOp.OP_DIV:
                if rv == 0: return CONST_EVAL_FAIL()
                let result_ty = self.try_eval_const_result_type(node, expected_tid)
                if int_div_overflows(lv, rv, self.codegen_const_int_width(result_ty), self.codegen_const_int_is_unsigned(result_ty)):
                    if self.overflow_mode == OVERFLOW_MODE_WRAP():
                        return int_signed_min(self.codegen_const_int_width(result_ty))
                    if self.overflow_mode == OVERFLOW_MODE_SATURATE():
                        return int_signed_max(self.codegen_const_int_width(result_ty))
                    return CONST_EVAL_FAIL()
                return lv / rv
            if op == BinaryOp.OP_MOD:
                if rv == 0: return CONST_EVAL_FAIL()
                let result_ty = self.try_eval_const_result_type(node, expected_tid)
                if int_div_overflows(lv, rv, self.codegen_const_int_width(result_ty), self.codegen_const_int_is_unsigned(result_ty)):
                    if self.overflow_mode == OVERFLOW_MODE_WRAP() or self.overflow_mode == OVERFLOW_MODE_SATURATE():
                        return 0
                    return CONST_EVAL_FAIL()
                return lv % rv
            if op == BinaryOp.OP_SHL:
                // Implement shift via multiplication to bootstrap (seed doesn't have << operator yet)
                var shift_result: i64 = lv
                var shift_i: i64 = 0
                while shift_i < rv:
                    shift_result = shift_result * 2
                    shift_i = shift_i + 1
                return shift_result
            if op == BinaryOp.OP_SHR:
                var shift_result: i64 = lv
                var shift_i: i64 = 0
                while shift_i < rv:
                    shift_result = shift_result / 2
                    shift_i = shift_i + 1
                return shift_result
            if op == BinaryOp.OP_BIT_AND: return lv & rv
            if op == BinaryOp.OP_BIT_OR: return lv | rv
            if op == BinaryOp.OP_BIT_XOR: return lv ^ rv
            return CONST_EVAL_FAIL()
        // sizeof[T]() / alignof[T]() as module-level constants
        if kind == NodeKind.NK_CALL:
            let callee = self.pool.get_data0(node)
            let callee_kind = self.pool.kind(callee)
            if callee_kind == NodeKind.NK_TYPE_GENERIC or callee_kind == NodeKind.NK_INDEX:
                let base = self.pool.get_data0(callee)
                if self.pool.kind(base) == NodeKind.NK_IDENT:
                    let name_sym = self.pool.get_data0(base)
                    if name_sym == self.sym_sizeof or name_sym == self.sym_size_of or name_sym == self.sym_alignof or name_sym == self.sym_align_of:
                        let tp_node = if callee_kind == NodeKind.NK_TYPE_GENERIC:
                            let tp_start = self.pool.get_data1(callee)
                            let tp_count = self.pool.get_data2(callee)
                            if tp_count == 0: return CONST_EVAL_FAIL()
                            self.pool.get_extra(tp_start)
                        else:
                            self.pool.get_data1(callee)
                        let type_val = self.resolve_type(tp_node)
                        if type_val != 0:
                            let dl = wl_get_module_data_layout(self.llmod)
                            if name_sym == self.sym_sizeof or name_sym == self.sym_size_of:
                                return wl_abi_size_of(dl, type_val)
                            return wl_abi_align_of(dl, type_val) as i64
            return CONST_EVAL_FAIL()
        if kind == NodeKind.NK_IDENT:
            let sym = self.pool.get_data0(node)
            // Linear search for known constant
            for ci in 0..self.const_int_syms.len() as i32:
                if self.const_int_syms.get(ci as i64) == sym:
                    return self.const_int_vals.get(ci as i64)
            return CONST_EVAL_FAIL()
        CONST_EVAL_FAIL()

    mut fn try_eval_const_llvm(node: i32, expected_tid: i32) -> i64:
        if node == 0 or expected_tid <= 0:
            return 0

        var cur = self.unwrap_const_expr_node(node)

        if cur == 0:
            return 0

        let resolved = self.sema.resolve_alias(expected_tid as TypeId)
        let tk = self.sema.get_type_kind(resolved)

        if self.pool.kind(cur) == NodeKind.NK_IDENT:
            let value_node = self.module_const_value_node(self.pool.get_data0(cur))
            if value_node != 0 and value_node != cur:
                return self.try_eval_const_llvm(value_node, expected_tid)

        if tk == TypeKind.TY_ARRAY:
            if self.pool.kind(cur) != NodeKind.NK_ARRAY_LIT:
                return 0
            let elem_tid = self.sema.get_type_d0(resolved)
            let elem_llvm = self.sema_type_to_llvm(elem_tid)
            if elem_llvm == 0:
                return 0
            let extra_start = self.pool.get_data0(cur)
            let elem_count = self.pool.get_data1(cur)
            if elem_count != self.sema.get_type_d1(resolved):
                return 0
            let elems: Vec[i64] = Vec.new()
            for i in 0..elem_count:
                let elem_node = self.pool.get_extra(extra_start + i)
                let elem_val = self.try_eval_const_llvm(elem_node, elem_tid as i32)
                if elem_val == 0:
                    return 0
                elems.push(elem_val)
            return wl_const_array(elem_llvm, vec_data_i64(&elems), elem_count)

        if tk == TypeKind.TY_STRUCT:
            return self.try_eval_const_struct_llvm(cur, resolved as i32)

        if tk == TypeKind.TY_PTR or tk == TypeKind.TY_REF:
            return self.try_eval_const_pointer_llvm(cur, resolved as i32)

        if tk == TypeKind.TY_INT or tk == TypeKind.TY_BOOL:
            let exact = self.exact_int_const_llvm(cur, resolved as i32)
            if exact != 0:
                return exact
            let val = self.try_eval_const_int_expected(cur, resolved as i32)
            if val == CONST_EVAL_FAIL():
                return 0
            let llvm_ty = self.sema_type_to_llvm(resolved)
            if llvm_ty == 0:
                return 0
            return wl_const_int(llvm_ty, val, 1)

        if tk == TypeKind.TY_FLOAT:
            let exact_expr = self.pool.int_literal_exact_expr(cur)
            if exact_expr.ok != 0 and exact_expr.overflow == 0:
                let llvm_ty = self.sema_type_to_llvm(resolved)
                if llvm_ty == 0:
                    return 0
                return wl_const_real(llvm_ty, self.exact_int_expr_to_f64(cur))
            var float_node = cur
            var float_negate = false
            if self.pool.kind(float_node) == NodeKind.NK_UNARY and self.pool.get_data0(float_node) == UnaryOp.UOP_NEGATE:
                float_node = self.pool.get_data1(float_node)
                float_negate = true
            if self.pool.kind(float_node) != NodeKind.NK_FLOAT_LIT:
                return 0
            let str_idx = self.pool.get_data0(float_node)
            if str_idx < 0 or str_idx >= self.pool.state.strings.len() as i32:
                return 0
            var fval = with_parse_float_ref(with_str_clone_ref(self.pool.get_string(str_idx)))
            if float_negate:
                fval = -fval
            let llvm_ty = self.sema_type_to_llvm(resolved)
            if llvm_ty == 0:
                return 0
            return wl_const_real(llvm_ty, fval)

        0

    mut fn emit_const_array_global(name_sym: i32, array_tid: i32, value_node: i32, is_mut: i32) -> bool:
        if array_tid <= 0:
            return false
        let resolved = self.sema.resolve_alias(array_tid as TypeId)
        if self.sema.get_type_kind(resolved) != TypeKind.TY_ARRAY:
            return false
        let global_ty = self.sema_type_to_llvm(resolved)
        if global_ty == 0:
            return false
        let init = self.try_eval_const_llvm(value_node, resolved as i32)
        if init == 0:
            return false
        let _ = self.record_module_binding_global(name_sym, global_ty, init, is_mut)
        true

    mut fn gen_module_constant(let_node: i32):
        let name_sym = self.pool.get_data0(let_node)
        var value_node = self.pool.get_data1(let_node)
        let flags = self.pool.get_data2(let_node)
        let is_mut = flags % 2
        var binding_ty = if self.sema.typed_binding_types.contains(let_node):
            self.sema.typed_binding_types.get(let_node).unwrap()
        else:
            0
        if binding_ty == 0:
            let ann_extra = self.sema.top_level_let_type_ann_extra(flags)
            if ann_extra >= 0:
                let ann_node = self.pool.get_extra(ann_extra)
                let ann_ty = self.sema.resolve_type_expr_frozen(ann_node)
                if ann_ty != 0:
                    binding_ty = ann_ty as i32
        let resolved_binding_ty = if binding_ty != 0: self.sema.resolve_alias(binding_ty) else: 0
        if value_node == 0:
            if resolved_binding_ty == 0:
                return
            let global_ty = self.sema_type_to_llvm(resolved_binding_ty)
            if global_ty == 0:
                return
            if is_mut != 0:
                self.register_module_global_drop(name_sym, resolved_binding_ty)
            let _ = self.record_module_binding_global(name_sym, global_ty, self.build_default_value(global_ty), is_mut)
            return

        // NK_COMPTIME wrapper is already removed by ComptimeTransform.
        // Unwrap only as a fallback for cases the transform didn't handle.
        if self.pool.kind(value_node) == NodeKind.NK_COMPTIME:
            let ct_inner = self.pool.get_data0(value_node)
            if ct_inner != 0:
                value_node = ct_inner

        let inferred_value_ty =
            if self.sema.typed_expr_types.contains(value_node):
                self.sema.resolve_alias(self.sema.typed_expr_types.get(value_node).unwrap() as TypeId)
            else:
                0
        var const_binding_ty = if resolved_binding_ty != 0: resolved_binding_ty else: inferred_value_ty
        if is_mut != 0:
            self.register_module_global_drop(name_sym, const_binding_ty)
        if const_binding_ty == 0 and self.pool.kind(value_node) == NodeKind.NK_STRUCT_LIT:
            let lit_sym = self.pool.get_data0(value_node)
            let lit_name = if lit_sym != 0: with_str_clone_ref(self.intern.resolve(lit_sym)) else: ""
            let sema_lit_sym = if lit_name.len() > 0: self.sema.pool_lookup_symbol(lit_name) else: 0
            if sema_lit_sym != 0 and self.sema.named_types.contains(sema_lit_sym):
                const_binding_ty = self.sema.resolve_alias(self.sema.named_types.get(sema_lit_sym).unwrap() as TypeId)

        if self.pool.kind(value_node) == NodeKind.NK_NULL_LIT:
            var null_ty = resolved_binding_ty
            if null_ty == 0 and self.sema.typed_expr_types.contains(value_node):
                let inferred_null_ty = self.sema.typed_expr_types.get(value_node).unwrap()
                if inferred_null_ty != 0:
                    null_ty = self.sema.resolve_alias(inferred_null_ty)
            let null_tk = if null_ty != 0: self.sema.get_type_kind(null_ty) else: 0
            if null_tk == TypeKind.TY_PTR or null_tk == TypeKind.TY_REF:
                let global_ty = self.sema_type_to_llvm(null_ty)
                if global_ty != 0:
                    let _ = self.record_module_binding_global(name_sym, global_ty, wl_const_null(global_ty), is_mut)
                    return
        let val = self.try_eval_const_int_expected(value_node, const_binding_ty as i32)
        if val != CONST_EVAL_FAIL():
            if resolved_binding_ty != 0:
                let binding_kind = self.sema.get_type_kind(resolved_binding_ty)
                if binding_kind == TypeKind.TY_PTR or binding_kind == TypeKind.TY_REF:
                    let global_ty = self.sema_type_to_llvm(resolved_binding_ty)
                    if global_ty != 0 and val == 0:
                        let _ = self.record_module_binding_global(name_sym, global_ty, wl_const_null(global_ty), is_mut)
                        return
            if resolved_binding_ty != 0 and self.sema.get_type_kind(resolved_binding_ty) == TypeKind.TY_FLOAT:
                let global_ty = self.sema_type_to_llvm(resolved_binding_ty)
                let _ = self.record_module_binding_global(name_sym, global_ty, wl_const_real(global_ty, val as f64), is_mut)
                return
            if is_mut == 0:
                self.const_int_syms.push(name_sym)
                self.const_int_vals.push(val)
            // Respect the sema-resolved binding type when available.
            var global_ty = if val < -2147483648 or val > 2147483647: wl_i64_type(self.context) else: wl_i32_type(self.context)
            if resolved_binding_ty != 0 and self.sema.get_type_kind(resolved_binding_ty) == TypeKind.TY_INT:
                let inferred_llvm = self.sema_type_to_llvm(resolved_binding_ty)
                if inferred_llvm != 0:
                    global_ty = inferred_llvm
            let _ = self.record_module_binding_global(name_sym, global_ty, wl_const_int(global_ty, val, 1), is_mut)
            return

        if const_binding_ty != 0:
            let binding_kind = self.sema.get_type_kind(const_binding_ty)
            if binding_kind == TypeKind.TY_INT or binding_kind == TypeKind.TY_BOOL or binding_kind == TypeKind.TY_FLOAT or binding_kind == TypeKind.TY_STRUCT or binding_kind == TypeKind.TY_ARRAY or binding_kind == TypeKind.TY_PTR or binding_kind == TypeKind.TY_REF:
                let init = self.try_eval_const_llvm(value_node, const_binding_ty as i32)
                if init != 0:
                    let global_ty = self.sema_type_to_llvm(const_binding_ty)
                    if global_ty != 0:
                        let _ = self.record_module_binding_global(name_sym, global_ty, init, is_mut)
                        return

        let current_source_file = self.current_decl_source_file
        let str_value = self.try_eval_const_string(value_node, current_source_file, 0)
        if str_value.ok:
            let st_opt = self.struct_type_map.get(self.sym_str)
            if not st_opt.is_some():
                with_eprint("warning: [string-global] str struct type not found")
                return
            let str_ty = self.struct_llvm_types.get(st_opt.unwrap() as i64)
            if self.current_decl_is_imported_module_symbol():
                let _ = self.declare_module_binding_global(name_sym, str_ty, is_mut)
                return
            let name_str = self.intern.resolve(name_sym)
            let bytes_name = name_str ++ ".__bytes"
            let bytes_ty = wl_array_type(wl_i8_type(self.context), str_value.text.len() + 1)
            let bytes_global = wl_add_global(self.llmod, bytes_ty, bytes_name)
            wl_set_initializer(bytes_global, wl_const_string(self.context, str_value.text, 0))
            wl_set_global_constant(bytes_global, 1)
            wl_set_linkage(bytes_global, wl_private_linkage())

            let fields: Vec[i64] = Vec.new()
            fields.push(wl_const_bitcast(bytes_global, wl_ptr_type(self.context)))
            fields.push(wl_const_int(wl_i64_type(self.context), str_value.text.len(), 1))
            let str_init = wl_const_named_struct(str_ty, vec_data_i64(&fields), 2)

            let _ = self.define_module_binding_global(name_sym, str_ty, str_init, is_mut)
            return

        let vec_tid = self.try_resolve_vec_new_global_type(value_node, flags)
        if vec_tid > 0:
            if self.emit_vec_new_global(name_sym, vec_tid, is_mut):
                return

        let array_tid =
            if const_binding_ty != 0:
                const_binding_ty as i32
            else:
                0
        if array_tid > 0:
            if self.emit_const_array_global(name_sym, array_tid, value_node, is_mut):
                return

        // Float constant: NodeKind.NK_FLOAT_LIT or unary negate of one
        var float_node = value_node
        var float_negate = false
        if self.pool.kind(float_node) == NodeKind.NK_UNARY:
            if self.pool.get_data0(float_node) == UnaryOp.UOP_NEGATE:
                float_node = self.pool.get_data1(float_node)
                float_negate = true
        if self.pool.kind(float_node) == NodeKind.NK_FLOAT_LIT:
            let str_idx = self.pool.get_data0(float_node)
            var fval: f64 = 0.0
            if str_idx >= 0 and str_idx < self.pool.state.strings.len() as i32:
                let float_text = self.pool.get_string(str_idx)
                if float_text.len() > 0:
                    fval = with_parse_float_ref(with_str_clone_ref(float_text))
            if float_negate:
                fval = -fval
            var global_ty = wl_f64_type(self.context)
            if resolved_binding_ty != 0 and self.sema.get_type_kind(resolved_binding_ty) == TypeKind.TY_FLOAT:
                let inferred_llvm = self.sema_type_to_llvm(resolved_binding_ty)
                if inferred_llvm != 0:
                    global_ty = inferred_llvm
            let _ = self.record_module_binding_global(name_sym, global_ty, wl_const_real(global_ty, fval), is_mut)
            return

        let runtime_tid =
            if binding_ty != 0:
                binding_ty as i32
            else if const_binding_ty != 0:
                const_binding_ty as i32
            else if self.sema.typed_expr_types.contains(value_node):
                self.sema.typed_expr_types.get(value_node).unwrap()
            else:
                0
        if runtime_tid != 0:
            let resolved_runtime = self.sema.resolve_alias(runtime_tid as TypeId)
            let runtime_kind = self.sema.get_type_kind(resolved_runtime)
            if runtime_kind != TypeKind.TY_INT and runtime_kind != TypeKind.TY_FLOAT and runtime_kind != TypeKind.TY_STR:
                if self.queue_module_runtime_init(name_sym, value_node, runtime_tid, is_mut):
                    return
