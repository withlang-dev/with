extern fn with_str_clone_ref(s: &str) -> str
use Ast
use Sema
use Codegen
use CodegenDispatch
use CodegenTraits
use compiler.Zcu
use compiler.Runtime
use compiler.TrackedInputs
use compiler.CodegenUnits
use AnalysisTypes

fn backend_debug_pool_flow_enabled() -> i32:
    let raw = runtime_getenv("WITH_DEBUG_POOL_FLOW")
    if raw.len() == 0:
        return 0
    1

impl Zcu:
    mut fn compile_to_object_backend(pool: AstPool, opt_level: i32, output_path: &str, debug_info: bool, module_object_mode: bool) -> i32:
        if self.last_mir_module.body_count() == 0:
            runtime_eprint("error: missing MIR input for LLVM backend")
            return 1
        // #681: multi-unit builds generate each unit's module directly from
        // MIR (serially — one cg alive at a time), then optimize+emit the
        // small per-unit bitcodes on threads. Peak memory ≈ frontend + one
        // unit module, replacing whole-module bitcode + K full parses.
        if not module_object_mode:
            let env_units0 = codegen_units_env_count()
            let unit_count0 = if env_units0 > 0: env_units0 else: codegen_units_default_count(self.last_mir_module.body_count())
            if unit_count0 > 1:
                var backend_pool0 = pool
                if self.last_sema.ast.decl_count() > 0:
                    backend_pool0 = self.last_sema.ast
                return self.compile_units_generated(backend_pool0, opt_level, output_path, debug_info, unit_count0)
        var backend_pool = pool
        var backend_intern = self.pool
        // D17/#697: Copy pool handles captured before the sema moves; codegen
        // OWNS the sema for the emission (take-and-return, the lower_module
        // pattern) and every exit path hands it back — last_sema is blank in
        // between, never aliased.
        let sema_ast = self.last_sema.ast
        let sema_pool = self.last_sema.pool
        if sema_ast.decl_count() > 0:
            backend_pool = sema_ast
        if sema_pool.state.symbol_texts.len() as i32 > 1:
            backend_intern = sema_pool
        var cg = Codegen.init_with_opt_and_intern("with_module", opt_level, move backend_intern, move self.last_sema)
        cg.source_file = with_str_clone_ref(self.current_source_path)
        cg.source_text = move self.current_source_text
        cg.decl_source_paths = sema_clone_str_vec(&self.decl_source_paths)
        cg.current_decl_source_file = with_str_clone_ref(self.current_source_path)
        cg.add_bundle_prefixes(&self.link_bundle_prefixes)
        cg.bundle_corpus = with_str_clone_ref(self.bundle_corpus)
        cg.module_object_mode = if module_object_mode: 1 else: 0
        if not debug_info:
            cg.debug_info = 0
        if self.pool.state.symbol_texts.len() as i32 <= 4 or sema_pool.state.symbol_texts.len() as i32 <= 4 or backend_debug_pool_flow_enabled() != 0:
            runtime_eprint(f"[backend] zcu.pool symbols={self.pool.state.symbol_texts.len() as i32}")
            runtime_eprint(f"[backend] frontend.pool symbols={self.frontend_pool.state.symbol_texts.len() as i32}")
            runtime_eprint(f"[backend] sema.pool symbols={sema_pool.state.symbol_texts.len() as i32}")
            runtime_eprint(f"[backend] backend_pool decls={backend_pool.decl_count()} sema.ast.decls={sema_ast.decl_count()}")
        if self.pool.state.symbol_texts.len() as i32 <= 4 or sema_pool.state.symbol_texts.len() as i32 <= 4 or cg.intern.state.symbol_texts.len() as i32 <= 4 or backend_debug_pool_flow_enabled() != 0:
            runtime_eprint(f"[backend] cg.intern symbols={cg.intern.state.symbol_texts.len() as i32}")
        if backend_debug_pool_flow_enabled() != 0:
            runtime_eprint(f"[backend-diag] pool.extra_len={backend_pool.extra_len()} pool.nodes={backend_pool.node_count()}")
            backend_dump_struct_extras(backend_pool, cg.intern)
        let do_profile = runtime_getenv("WITH_PROFILE").len() > 0
        let t_codegen = runtime_clock_nanos()
        var backend_mir = move self.last_mir_module
        let result = cg.gen_module_from_mir(&raw const backend_mir as i64, backend_pool)
        var tracked_paths = move self.tracked_input_paths
        self.tracked_input_paths = tracked_input_merge_unique(move tracked_paths, &cg.tracked_input_paths)
        self.last_bundle_unlowered_globals = sema_clone_str_vec(&cg.bundle_unlowered_globals)
        if result != 0:
            self.last_sema = cg.take_sema()
            runtime_eprint("error: code generation failed")
            return 1
        if do_profile:
            let codegen_ns = runtime_clock_nanos() - t_codegen
            runtime_eprint(f"[profile] llvm.gen_module  {codegen_ns / 1000000}.{(codegen_ns % 1000000) / 1000} ms")
        self.last_codegen_unit_count = 1
        if opt_level > 0:
            let t_opt = runtime_clock_nanos()
            cg.optimize(opt_level)
            if do_profile:
                let opt_ns = runtime_clock_nanos() - t_opt
                runtime_eprint(f"[profile] llvm.optimize  {opt_ns / 1000000}.{(opt_ns % 1000000) / 1000} ms")
        let t_emit = runtime_clock_nanos()
        let emit_result = cg.emit_object_file(output_path)
        self.last_sema = cg.take_sema()
        if emit_result != 0:
            runtime_eprint("error: failed to emit object file")
            return 1
        if runtime_file_exists(output_path) == 0:
            runtime_eprint(f"error: backend reported emit success but no object file exists at {output_path}")
            return 1
        if do_profile:
            let emit_ns = runtime_clock_nanos() - t_emit
            runtime_eprint(f"[profile] llvm.emit_object  {emit_ns / 1000000}.{(emit_ns % 1000000) / 1000} ms")
        0

    // #681: serial per-unit generation. Each round constructs one Codegen
    // (its own context/module; sema/intern copied exactly as the single-unit
    // path does — only one alive at a time), generates only unit-k bodies,
    // applies the shared global-ownership surgery, writes the unit's small
    // bitcode, and disposes everything before the next round. Threads then
    // optimize+emit the small bitcodes concurrently.
    mut fn compile_units_generated(pool: AstPool, opt_level: i32, output_path: &str, debug_info: bool, unit_count: i32) -> i32:
        let do_profile = runtime_getenv("WITH_PROFILE").len() > 0
        var backend_mir = move self.last_mir_module
        let mir_ptr = &raw const backend_mir as i64
        var assign = codegen_units_assign_from_mir(mir_ptr, unit_count)
        // Pin main's body to unit 0: the exit wrapper is synthesized there
        // and must wrap the definition, not a declaration.
        let main_sym = self.last_sema.pool_lookup_symbol("main")
        if main_sym != 0:
            var mi = 0
            while mi < assign.fn_syms.len() as i32:
                if assign.fn_syms[mi] == main_sym:
                    let main_slot = mi as i64
                    with assign.units.slot(main_slot) as mut unit_slot:
                        unit_slot.set(0)
                mi = mi + 1
        let t_codegen = runtime_clock_nanos()
        let unit_bcs: Vec[str] = Vec.new()
        var k = 0
        while k < unit_count:
            var backend_intern = self.pool
            // D17/#697: per-round take-and-return — each round's Codegen owns
            // the sema and hands it back before deinit or any early return.
            let round_sema_pool = self.last_sema.pool
            if round_sema_pool.state.symbol_texts.len() as i32 > 1:
                backend_intern = round_sema_pool
            var cg = Codegen.init_with_opt_and_intern(f"with_module_u{k}", opt_level, move backend_intern, move self.last_sema)
            cg.source_file = with_str_clone_ref(self.current_source_path)
            cg.source_text = move self.current_source_text
            cg.decl_source_paths = sema_clone_str_vec(&self.decl_source_paths)
            cg.current_decl_source_file = with_str_clone_ref(self.current_source_path)
            cg.add_bundle_prefixes(&self.link_bundle_prefixes)
            cg.bundle_corpus = with_str_clone_ref(self.bundle_corpus)
            cg.module_object_mode = 0
            if not debug_info:
                cg.debug_info = 0
            cg.unit_total = unit_count
            cg.unit_index = k
            var ai = 0
            while ai < assign.fn_syms.len() as i32:
                cg.unit_assign_insert(assign.fn_syms[ai], assign.units[ai], ai)
                ai = ai + 1
            let rc = cg.gen_module_from_mir(mir_ptr, pool)
            var tracked = move self.tracked_input_paths
            self.tracked_input_paths = tracked_input_merge_unique(move tracked, &cg.tracked_input_paths)
            if rc != 0:
                self.last_sema = cg.take_sema()
                runtime_eprint(f"error: code generation failed for unit {k}")
                return 1
            codegen_units_apply_global_ownership(cg.llmod, k)
            let unit_bc = f"{output_path}.u{k}.gen.bc"
            if wl_write_bitcode(cg.llmod, unit_bc) != 0:
                self.last_sema = cg.take_sema()
                runtime_eprint(f"error: unit bitcode write failed for unit {k}")
                return 1
            unit_bcs.push(unit_bc)
            self.last_sema = cg.take_sema()
            cg.deinit()
            k = k + 1
        if do_profile:
            let codegen_ns = runtime_clock_nanos() - t_codegen
            runtime_eprint(f"[profile] llvm.gen_units_serial  {codegen_ns / 1000000}.{(codegen_ns % 1000000) / 1000} ms")
        let emit_window = codegen_units_emit_width(unit_count, assign.total_cost)
        if do_profile:
            runtime_eprint(f"[profile] llvm.units plan_cost={assign.total_cost} window={emit_window}/{unit_count}")
        let emit_rc = codegen_units_emit_generated_all(&unit_bcs, output_path, opt_level, do_profile, emit_window)
        if emit_rc != 0:
            return 1
        if runtime_file_exists(output_path) == 0:
            runtime_eprint(f"error: codegen-units reported success but no object file exists at {output_path}")
            return 1
        self.last_codegen_unit_count = unit_count
        0

    mut fn emit_ir_backend(pool: AstPool, opt_level: i32) -> bool:
        if self.last_mir_module.body_count() == 0:
            runtime_eprint("error: missing MIR input for LLVM backend")
            return false
        var backend_pool = pool
        var backend_intern = self.pool
        // D17/#697: take-and-return (docs/memory-model.md seam rule) — Copy
        // handles captured first, sema moved in, handed back on every exit.
        let sema_ast = self.last_sema.ast
        let sema_pool = self.last_sema.pool
        if sema_ast.decl_count() > 0:
            backend_pool = sema_ast
        if sema_pool.state.symbol_texts.len() as i32 > 1:
            backend_intern = sema_pool
        var cg = Codegen.init_with_opt_and_intern("with_module", opt_level, move backend_intern, move self.last_sema)
        cg.source_file = with_str_clone_ref(self.current_source_path)
        cg.source_text = move self.current_source_text
        cg.decl_source_paths = sema_clone_str_vec(&self.decl_source_paths)
        cg.current_decl_source_file = with_str_clone_ref(self.current_source_path)
        cg.add_bundle_prefixes(&self.link_bundle_prefixes)
        cg.bundle_corpus = with_str_clone_ref(self.bundle_corpus)
        if self.pool.state.symbol_texts.len() as i32 <= 4 or sema_pool.state.symbol_texts.len() as i32 <= 4 or backend_debug_pool_flow_enabled() != 0:
            runtime_eprint(f"[backend] zcu.pool symbols={self.pool.state.symbol_texts.len() as i32}")
            runtime_eprint(f"[backend] frontend.pool symbols={self.frontend_pool.state.symbol_texts.len() as i32}")
            runtime_eprint(f"[backend] sema.pool symbols={sema_pool.state.symbol_texts.len() as i32}")
            runtime_eprint(f"[backend] backend_pool decls={backend_pool.decl_count()} sema.ast.decls={sema_ast.decl_count()}")
        if self.pool.state.symbol_texts.len() as i32 <= 4 or sema_pool.state.symbol_texts.len() as i32 <= 4 or cg.intern.state.symbol_texts.len() as i32 <= 4 or backend_debug_pool_flow_enabled() != 0:
            runtime_eprint(f"[backend] cg.intern symbols={cg.intern.state.symbol_texts.len() as i32}")
        var backend_mir = move self.last_mir_module
        let result = cg.gen_module_from_mir(&raw const backend_mir as i64, backend_pool)
        var tracked_paths = move self.tracked_input_paths
        self.tracked_input_paths = tracked_input_merge_unique(move tracked_paths, &cg.tracked_input_paths)
        self.last_sema = cg.take_sema()
        if result != 0:
            runtime_eprint("error: code generation failed")
            return false
        cg.print_ir()
        true

    // Run the real LLVM backend with analysis instrumentation enabled, but do not
    // print IR or emit an object. The returned facts come from the same marshalling
    // and callee-binding branches used for production codegen.
    mut fn analyze_codegen_backend(pool: AstPool, opt_level: i32, query: &str) -> AnalysisBackendResult:
        if self.last_mir_module.body_count() == 0:
            let report = AnalysisReport.init()
            report.fail("missing MIR input for codegen analysis")
            return AnalysisBackendResult { report, status: 1 }
        // D17/#697 take-and-return, post-#691 spelling (#726): the pre-flip
        // version bare-read these pools into locals (then handle-copy
        // aliases); under reset-on-move those reads became MOVES, and the
        // assign-then-overwrite pattern DROPPED a still-viewed InternPool.
        // Freed pool pages were recycled into the LLVM context and the
        // corruption surfaced as audit segfaults on valid-looking types.
        // Now: the winner is chosen without dropping the loser, the loser
        // stays owned by its home field, and everything lent to the codegen
        // run is restored after take_sema.
        let use_sema_ast = self.last_sema.ast.decl_count() > 0
        let use_sema_pool = self.last_sema.pool.state.symbol_texts.len() as i32 > 1
        let backend_intern = if use_sema_pool: move self.last_sema.pool else: move self.pool
        var cg = Codegen.init_with_opt_and_intern("with_analysis", opt_level, move backend_intern, move self.last_sema)
        cg.source_file = with_str_clone_ref(self.current_source_path)
        cg.source_text = move self.current_source_text
        cg.decl_source_paths = sema_clone_str_vec(&self.decl_source_paths)
        cg.current_decl_source_file = with_str_clone_ref(self.current_source_path)
        cg.add_bundle_prefixes(&self.link_bundle_prefixes)
        cg.bundle_corpus = with_str_clone_ref(self.bundle_corpus)
        cg.enable_analysis(query)
        var backend_mir = move self.last_mir_module
        let backend_pool = if use_sema_ast: move cg.sema.ast else: move pool
        let rc = cg.gen_module_from_mir(&raw const backend_mir as i64, backend_pool)
        cg.audit_declared_share_place_contracts()
        cg.audit_return_shape_contracts()
        cg.audit_trait_table_contracts()
        cg.audit_codegen_call_coverage()
        if rc != 0:
            cg.analysis_fail("code generation failed during integrated analysis")
        let status = if rc != 0: 1 else: cg.analysis_status()
        self.last_mir_module = move backend_mir
        self.last_sema = cg.take_sema()
        if use_sema_ast:
            self.last_sema.ast = cg.take_pool()
        if use_sema_pool:
            self.last_sema.pool = cg.take_intern()
        else:
            self.pool = cg.take_intern()
        AnalysisBackendResult { report: move cg.analysis_report, status }

fn backend_dump_struct_extras(pool: AstPool, intern: InternPool):
    for di in 0..pool.decl_count():
        let decl = pool.get_decl(di)
        if pool.kind(decl) != NodeKind.NK_TYPE_DECL:
            continue
        let sub_kind = type_decl_sub_kind(pool.get_data2(decl))
        if sub_kind != TypeDeclKind.Struct:
            continue
        let name_sym = pool.get_data0(decl)
        let name = intern.resolve(name_sym)
        let es = pool.get_data1(decl)
        let fc = pool.get_extra(es)
        if fc <= 0 or fc > 100:
            runtime_eprint(f"[sd] BAD {name} d={decl as i32} es={es} fc={fc}")
            continue
        var ok = 1
        for fi in 0..fc:
            let o = es + 1 + fi * 3
            let tn = pool.get_extra(o + 1)
            let k = pool.kind(tn as NodeId)
            if k < 50 or k > 200:
                ok = 0
                runtime_eprint(f"[sd] {name} f{fi} tn={tn} k={k} es={es} o={o}")
        if ok == 1 and (name == "Codegen" or name == "ContextError"):
            runtime_eprint(f"[sd] OK {name} d={decl as i32} es={es} fc={fc}")

let _backend_eof_guard = 0
