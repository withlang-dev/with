use Ast
use Diagnostic
use Resolve
use InternPool
use Sema
use Span
use Mir
use MirLower
use AsyncMir
use AsyncLower
use CCodegen
use compiler.Compilation.Config
use compiler.Backend
use compiler.Frontend
use compiler.Link
use compiler.Zcu

extern fn with_eprint(s: str) -> void
extern fn with_fs_write_file(path: str, data: str) -> i32
extern fn with_getenv_str(name: str) -> str
extern fn with_system(cmd: str) -> i32
extern fn with_clock_nanos() -> i64

fn profile_enabled() -> bool:
    with_getenv_str("WITH_PROFILE").len() > 0

fn profile_now() -> i64:
    with_clock_nanos()

fn profile_emit(name: str, start: i64, counters: str):
    let elapsed_ns = with_clock_nanos() - start
    let ms_whole = elapsed_ns / 1000000
    let ms_frac = (elapsed_ns % 1000000) / 1000
    if counters.len() > 0:
        with_eprint(f"[profile] {name}  {ms_whole}.{ms_frac} ms  {counters}")
    else:
        with_eprint(f"[profile] {name}  {ms_whole}.{ms_frac} ms")

fn compilation_debug_init_enabled() -> i32:
    let raw = with_getenv_str("WITH_DEBUG_STAGE1_TRACE")
    if raw.len() == 0:
        return 0
    1

fn compilation_debug_init(msg: str):
    if compilation_debug_init_enabled() == 0:
        return
    with_eprint("[comp-init] " ++ msg)

fn compilation_debug_pool_flow_enabled() -> i32:
    let raw = with_getenv_str("WITH_DEBUG_POOL_FLOW")
    if raw.len() == 0:
        return 0
    1

fn compilation_debug_pool_flow(label: str, pool: InternPool, typed_pool: AstPool, sema: Sema):
    if compilation_debug_pool_flow_enabled() == 0:
        return
    with_eprint(f"[comp] {label} pool.symbols={pool.state.symbol_texts.len() as i32} typed.decls={typed_pool.decl_count()} sema.pool.symbols={sema.pool.state.symbol_texts.len() as i32} sema.ast.decls={sema.ast.decl_count()}")

fn compilation_debug_type_names_enabled() -> i32:
    let raw = with_getenv_str("WITH_DEBUG_TYPE_NAMES")
    if raw.len() == 0:
        return 0
    if raw == "0":
        return 0
    1

fn compilation_dump_type_names(stage: str, pool: AstPool, intern: InternPool):
    if compilation_debug_type_names_enabled() == 0:
        return
    with_eprint(f"[type-names] stage={stage} decls={pool.decl_count()}")
    for di in 0..pool.decl_count():
        let decl = pool.get_decl(di)
        if pool.kind(decl) != NodeKind.NK_TYPE_DECL:
            continue
        let sub_kind = type_decl_sub_kind(pool.get_data2(decl))
        var kind_name = "alias"
        if sub_kind == TypeDeclKind.Struct:
            kind_name = "struct"
        else if sub_kind == TypeDeclKind.Enum:
            kind_name = "enum"
        else if sub_kind == TypeDeclKind.DiscEnum:
            kind_name = "disc_enum"
        else if sub_kind == TypeDeclKind.Distinct:
            kind_name = "distinct"
        let name_sym = pool.get_data0(decl)
        let name = intern.resolve(name_sym)
        let msg = f"[type-names] {stage} decl={di} node={decl as i32} kind={kind_name} name_sym={name_sym} name={name}"
        with_eprint(msg)

fn compilation_find_fn_decl_index(pool: AstPool, fn_sym: i32) -> i32:
    for di in 0..pool.decl_count():
        let decl = pool.get_decl(di)
        if pool.kind(decl) != NodeKind.NK_FN_DECL:
            continue
        if pool.get_data0(decl) == fn_sym:
            return di
    -1

fn compilation_mir_error_span(zcu: Zcu, pool: AstPool, fn_sym: i32, raw_span: i32) -> Span:
    let decl_index = compilation_find_fn_decl_index(pool, fn_sym)
    if decl_index >= 0:
        let decl = pool.get_decl(decl_index)
        let file_id = zcu.decl_source_file_id_frontend(decl_index)
        let start = if raw_span > 0: raw_span else: pool.get_start(decl)
        var end = if raw_span > 0: raw_span + 1 else: pool.get_end(decl)
        if end <= start:
            end = start + 1
        return Span { file: file_id, start: start, end: end }
    let start = if raw_span > 0: raw_span else: 0
    Span { file: 0, start: start, end: start + 1 }

// Transitional orchestration root:
// owns compiler-facing config/Zcu state while reusing Driver execution per call.
// This removes long-lived Driver field ownership from Compilation.
type Compilation {
    zcu: Zcu,
    config: CompilationConfig,
    cli_diag_gen_starts: Vec[i32],
    cli_diag_gen_ends: Vec[i32],
    cli_diag_source_names: Vec[str],
    cli_diag_source_texts: Vec[str],
}

fn Compilation.init -> Compilation:
    compilation_debug_init("Compilation.init:start")
    let zcu: Zcu = Zcu.init()
    compilation_debug_init("Compilation.init:zcu_ready")
    Compilation {
        zcu: zcu,
        config: compilation_config_default(),
        cli_diag_gen_starts: Vec.new(),
        cli_diag_gen_ends: Vec.new(),
        cli_diag_source_names: Vec.new(),
        cli_diag_source_texts: Vec.new(),
    }

fn Compilation.configure(self: Compilation, opt_level: i32, no_std: bool, alloc_mode: bool):
    self.config = compilation_config_from_cli(opt_level, no_std, alloc_mode, self.config.prelude_mode)
    var zcu = self.zcu
    zcu.set_prelude_mode(self.config.prelude_mode)
    self.zcu = zcu

fn Compilation.set_prelude_mode(self: Compilation, mode: i32):
    var cfg = self.config
    cfg.prelude_mode = compilation_normalize_prelude_mode(mode)
    self.config = cfg
    var zcu = self.zcu
    zcu.set_prelude_mode(cfg.prelude_mode)
    self.zcu = zcu

fn Compilation.set_debug_info(self: Compilation, enabled: bool):
    var cfg = self.config
    cfg.debug_info = enabled
    self.config = cfg

fn Compilation.add_cli_diag_mapping(self: Compilation, gen_start: i32, gen_end: i32, source_name: str, source_text: str):
    self.cli_diag_gen_starts.push(gen_start)
    self.cli_diag_gen_ends.push(gen_end)
    self.cli_diag_source_names.push(source_name)
    self.cli_diag_source_texts.push(source_text)

fn Compilation.apply_cli_diag_mappings(self: Compilation, zcu: Zcu) -> Zcu:
    zcu.clear_cli_diag_mappings()
    for i in 0..self.cli_diag_gen_starts.len() as i32:
        zcu.add_cli_diag_mapping(
            self.cli_diag_gen_starts.get(i as i64),
            self.cli_diag_gen_ends.get(i as i64),
            self.cli_diag_source_names.get(i as i64),
            self.cli_diag_source_texts.get(i as i64),
        )
    zcu

fn Compilation.compile_file(self: Compilation, path: str) -> AstPool:
    compilation_debug_init("Compilation.compile_file:start " ++ path)
    var zcu = self.zcu
    let pool = zcu.compile_file_frontend(path)
    self.zcu = zcu
    compilation_debug_init(f"Compilation.compile_file:done decls={pool.decl_count()}")
    pool

fn Compilation.compile_entry_file(self: Compilation, path: str) -> AstPool:
    compilation_debug_init("Compilation.compile_entry_file:start " ++ path)
    var zcu = self.zcu
    let pool = zcu.compile_file_frontend_entry(path)
    self.zcu = zcu
    compilation_debug_init(f"Compilation.compile_entry_file:done decls={pool.decl_count()}")
    pool

fn Compilation.resolve_file(self: Compilation, path: str, emit_resolve_diags: bool) -> ResolveResult:
    let _ = emit_resolve_diags
    let _ = self.compile_file(path)
    self.zcu.last_resolved

fn Compilation.has_errors(self: Compilation) -> bool:
    self.zcu.diagnostics.has_errors()

fn Compilation.get_pool(self: Compilation) -> InternPool:
    self.zcu.pool

fn Compilation.emit_ir(self: Compilation, pool: AstPool) -> bool:
    if not self.ensure_codegen_mir(pool):
        return false
    self.zcu.emit_ir_backend(self.active_pool(pool), self.config.opt_level)

fn compilation_cleanup_build_products(obj_path: str, bin_path: str):
    if obj_path.len() > 0:
        let _ = ("rm -f " ++ obj_path) |> with_system
    if bin_path.len() > 0:
        let _ = ("rm -f " ++ bin_path) |> with_system
        let _ = ("rm -rf " ++ bin_path ++ ".dSYM") |> with_system

fn Compilation.build_binary(self: Compilation, source_path: str) -> str:
    self.build_binary_to_path(source_path, link_stage_output_path_for_source(source_path))

fn Compilation.build_binary_from_source(self: Compilation, source_path: str, source_text: str) -> str:
    self.build_binary_from_source_to_path(source_path, source_text, link_stage_output_path_for_source(source_path))

fn Compilation.build_binary_at(self: Compilation, source_path: str, output_dir: str) -> str:
    let stem = link_stage_source_stem(source_path)
    self.build_binary_to_path(source_path, output_dir ++ "/" ++ stem)

fn Compilation.compile_source_text(self: Compilation, source_path: str, source_text: str) -> AstPool:
    var zcu = self.zcu
    let source_dir = frontend_dirname(source_path)
    zcu.reset_for_new_invocation(source_dir, source_path, "")
    zcu.project_config = project_config_load_for_source(source_path)
    if zcu.project_config.manifest_error.len() > 0:
        with_eprint("error: invalid with.toml: " ++ zcu.project_config.manifest_error)
        self.zcu = zcu
        return AstPool.new()
    zcu.set_current_source(source_dir, source_path, source_text)
    let pool = zcu.compile_source_frontend(source_text, source_path, 0)
    self.zcu = zcu
    pool

fn Compilation.compile_entry_source_text(self: Compilation, source_path: str, source_text: str) -> AstPool:
    var zcu = self.zcu
    let source_dir = frontend_dirname(source_path)
    zcu.reset_for_new_invocation(source_dir, source_path, "")
    zcu.project_config = project_config_load_for_source(source_path)
    if zcu.project_config.manifest_error.len() > 0:
        with_eprint("error: invalid with.toml: " ++ zcu.project_config.manifest_error)
        self.zcu = zcu
        return AstPool.new()
    zcu.set_current_source(source_dir, source_path, source_text)
    zcu = self.apply_cli_diag_mappings(zcu)
    let pool = zcu.compile_source_frontend_mode(source_text, source_path, 0, 1)
    self.zcu = zcu
    pool

fn Compilation.finish_binary_from_pool(self: Compilation, pool: AstPool, source_path: str, obj_path: str, bin_path: str) -> str:
    compilation_debug_init(f"build_binary_to_path:compiled {source_path} decls={pool.decl_count()}")
    if pool.decl_count() == 0:
        return ""
    if not self.ensure_codegen_mir(pool):
        compilation_debug_init("build_binary_to_path:ensure_codegen_mir FAILED")
        compilation_cleanup_build_products(obj_path, bin_path)
        return ""
    let active_pool: AstPool = self.active_pool(pool)
    let opt_level = self.config.opt_level
    let requires_async_runtime = self.zcu.last_async_mir_module.requires_async_runtime()
    compilation_debug_pool_flow("build_binary_to_path:after_codegen", self.zcu.pool, active_pool, self.zcu.last_sema)
    compilation_debug_init("build_binary_to_path:compile_to_object_backend")
    let t_backend = profile_now()
    let backend_rc = self.zcu.compile_to_object_backend(active_pool, opt_level, obj_path, self.config.debug_info, false)
    if backend_rc != 0:
        compilation_debug_init(f"build_binary_to_path:backend FAILED rc={backend_rc}")
        compilation_cleanup_build_products(obj_path, bin_path)
        return ""
    compilation_debug_init("build_binary_to_path:linking")
    // Merge dep_link_libs from project config into link libs
    var all_link_libs = self.zcu.last_link_lib_names
    for dli in 0..self.zcu.project_config.dep_link_libs.len() as i32:
        all_link_libs.push(self.zcu.project_config.dep_link_libs.get(dli as i64))
    let t_link = profile_now()
    if not link_stage_link_object_to_binary(obj_path, bin_path, all_link_libs, self.zcu.project_config.link_search_paths, requires_async_runtime):
        compilation_debug_init("build_binary_to_path:link FAILED")
        compilation_cleanup_build_products(obj_path, bin_path)
        return ""
    if profile_enabled():
        profile_emit("link", t_link, "")
    if self.config.debug_info:
        let t_dsym = profile_now()
        let _ = ("dsymutil " ++ bin_path ++ " 2>/dev/null") |> with_system
        if profile_enabled():
            profile_emit("dsymutil", t_dsym, "")
    let _ = ("rm -f " ++ obj_path) |> with_system
    bin_path

fn Compilation.emit_object_to_path(self: Compilation, source_path: str, obj_path: str) -> str:
    let output_dir = link_stage_dirname(obj_path)
    let _ = ("mkdir -p " ++ output_dir) |> with_system

    let pool = self.compile_file(source_path)
    if pool.decl_count() == 0:
        return ""
    if not self.ensure_codegen_mir(pool):
        return ""
    let active_pool: AstPool = self.active_pool(pool)
    let opt_level = self.config.opt_level
    let backend_rc = self.zcu.compile_to_object_backend(active_pool, opt_level, obj_path, self.config.debug_info, true)
    if backend_rc != 0:
        let _ = ("rm -f " ++ obj_path) |> with_system
        return ""
    obj_path

fn Compilation.build_binary_to_path(self: Compilation, source_path: str, bin_path: str) -> str:
    if bin_path.len() == 0:
        return self.build_binary(source_path)
    let obj_path = bin_path ++ ".o"
    let output_dir = link_stage_dirname(bin_path)
    let _ = ("mkdir -p " ++ output_dir) |> with_system
    let _ = ("rm -rf " ++ bin_path ++ ".dSYM") |> with_system

    let pool = self.compile_entry_file(source_path)
    self.finish_binary_from_pool(pool, source_path, obj_path, bin_path)

fn Compilation.build_binary_to_path_with_link_libs(self: Compilation, source_path: str, bin_path: str, link_libs: Vec[str]) -> str:
    if bin_path.len() == 0:
        return self.build_binary_to_path(source_path, bin_path)
    let obj_path = bin_path ++ ".o"
    let output_dir = link_stage_dirname(bin_path)
    let _ = ("mkdir -p " ++ output_dir) |> with_system
    let _ = ("rm -rf " ++ bin_path ++ ".dSYM") |> with_system

    let pool = self.compile_entry_file(source_path)
    var zcu = self.zcu
    for li in 0..link_libs.len() as i32:
        zcu.project_config.dep_link_libs.push(link_libs.get(li as i64))
    self.zcu = zcu
    self.finish_binary_from_pool(pool, source_path, obj_path, bin_path)

fn Compilation.build_binary_from_source_to_path(self: Compilation, source_path: str, source_text: str, bin_path: str) -> str:
    if bin_path.len() == 0:
        return self.build_binary_from_source(source_path, source_text)
    let obj_path = bin_path ++ ".o"
    let output_dir = link_stage_dirname(bin_path)
    let _ = ("mkdir -p " ++ output_dir) |> with_system
    let _ = ("rm -rf " ++ bin_path ++ ".dSYM") |> with_system

    let pool = self.compile_source_text(source_path, source_text)
    self.finish_binary_from_pool(pool, source_path, obj_path, bin_path)

fn Compilation.build_entry_binary_from_source_to_path(self: Compilation, source_path: str, source_text: str, bin_path: str) -> str:
    if bin_path.len() == 0:
        return self.build_binary_from_source(source_path, source_text)
    let obj_path = bin_path ++ ".o"
    let output_dir = link_stage_dirname(bin_path)
    let _ = ("mkdir -p " ++ output_dir) |> with_system
    let _ = ("rm -rf " ++ bin_path ++ ".dSYM") |> with_system

    let pool = self.compile_entry_source_text(source_path, source_text)
    self.finish_binary_from_pool(pool, source_path, obj_path, bin_path)

fn Compilation.emit_c(self: Compilation, source_path: str, output_path: str) -> str:
    let pool = self.compile_file(source_path)
    if pool.decl_count() == 0:
        return ""
    if not self.ensure_codegen_mir(pool):
        with_eprint("error: C emission failed during MIR lowering")
        return ""
    let typed_pool: AstPool = self.active_pool(pool)

    var final_output = output_path
    if final_output.len() == 0:
        final_output = link_stage_output_path_for_source(source_path) ++ ".c"
    let _ = ("mkdir -p " ++ link_stage_dirname(final_output)) |> with_system

    let emitted = c_emit_module(self.zcu.last_mir_module, typed_pool, self.zcu.pool, self.zcu.last_sema, self.zcu.current_source_path, self.zcu.current_source_text)
    if emitted.ok == 0:
        with_eprint("error: C emission failed: " ++ emitted.err_msg)
        return ""

    let write_rc = with_fs_write_file(final_output, emitted.source)
    if write_rc != 0:
        with_eprint("error: failed to write '" ++ final_output ++ "'")
        return ""

    final_output

fn Compilation.emit_typed(self: Compilation, pool: AstPool) -> bool:
    var zcu = self.zcu
    let typed_pool = pool
    if typed_pool.decl_count() == 0:
        with_eprint("error: no source loaded for typed emission")
        return false
    if zcu.last_sema.ast.decl_count() == typed_pool.decl_count() and typed_pool.decl_count() > 0:
        zcu.last_sema.emit_typed_module(0)
        self.zcu = zcu
        return true

    var sema = Sema.init(zcu.pool, zcu.diagnostics, typed_pool)
    sema.source_text = zcu.current_source_text
    if self.config.no_std:
        sema.no_std = 1
    if self.config.alloc_mode:
        sema.alloc = 1
    sema.check_module()

    zcu.sync_from_sema(sema)
    zcu.set_typed_snapshot("", typed_pool)
    zcu.set_codegen_snapshot(MirModule.init(), "", AsyncMirModule.init(), "")

    if zcu.diagnostics.has_errors():
        zcu.render_current_diagnostics()
        self.zcu = zcu
        return false

    zcu.last_sema.emit_typed_module(0)
    self.zcu = zcu
    true

fn Compilation.emit_typed_file(self: Compilation, source_path: str) -> bool:
    let pool = self.compile_file(source_path)
    if pool.decl_count() == 0:
        return false
    self.emit_typed(pool)

fn Compilation.print_mir(self: Compilation, pool: AstPool) -> bool:
    if self.zcu.last_mir_module.body_count() == 0:
        let _ = self.run_mir_lower(pool)
    if self.zcu.last_mir_module.body_count() == 0:
        return false
    print_mir_module(self.zcu.last_mir_module, self.zcu.pool, self.zcu.last_sema)
    true

fn Compilation.print_mir_file(self: Compilation, source_path: str) -> bool:
    let pool = self.compile_file(source_path)
    if pool.decl_count() == 0:
        return false
    self.print_mir(pool)

fn Compilation.dump_async_mir(self: Compilation, pool: AstPool) -> str:
    if self.zcu.last_async_mir_module.body_count() == 0:
        let _ = self.run_async_mir_lower(pool)
    if self.zcu.last_async_mir_module.body_count() == 0:
        return ""
    let text: str = dump_async_mir_module(self.zcu.last_async_mir_module, self.zcu.pool)
    self.zcu.set_codegen_snapshot(self.zcu.last_mir_module, self.zcu.last_mir_dump, self.zcu.last_async_mir_module, text)
    text

fn Compilation.dump_async_mir_file(self: Compilation, source_path: str) -> str:
    let pool = self.compile_file(source_path)
    if pool.decl_count() == 0:
        return ""
    self.dump_async_mir(pool)

fn Compilation.print_warnings(self: Compilation):
    self.zcu.print_warnings()

fn Compilation.active_pool(self: Compilation, pool: AstPool) -> AstPool:
    if self.zcu.typed_pool_cache.decl_count() > 0:
        return self.zcu.typed_pool_cache
    pool

fn Compilation.run_mir_lower(self: Compilation, pool: AstPool) -> MirModule:
    let do_profile = profile_enabled()
    var zcu = self.zcu
    let active_pool = pool
    compilation_debug_pool_flow("run_mir_lower:start", zcu.pool, active_pool, zcu.last_sema)
    var sema = Sema.init(zcu.pool, zcu.diagnostics, active_pool)
    compilation_debug_pool_flow("run_mir_lower:after_init", zcu.pool, active_pool, sema)
    sema.source_text = zcu.current_source_text
    sema.decl_source_paths = zcu.decl_source_paths
    sema.decl_source_file_ids = zcu.decl_source_file_ids
    sema.decl_is_c_import = zcu.decl_is_c_import
    sema.init_module_graph(&zcu.last_resolved)
    if self.config.no_std:
        sema.no_std = 1
    if self.config.alloc_mode:
        sema.alloc = 1
    let t_sema = profile_now()
    sema.check_module()
    sema.preregister_mir_types()
    sema.freeze_symbols()
    sema.freeze_types()
    if do_profile:
        profile_emit("sema", t_sema, f"types={sema.type_kinds.len() as i32}")
    compilation_debug_pool_flow("run_mir_lower:after_check", zcu.pool, active_pool, sema)

    // Check for sema errors before lowering
    if sema.diags.has_errors():
        zcu.sync_from_sema(sema)
        compilation_debug_pool_flow("run_mir_lower:after_sync", zcu.pool, active_pool, zcu.last_sema)
        zcu.render_current_diagnostics()
        zcu.set_codegen_snapshot(MirModule.init(), "", AsyncMirModule.init(), "")
        self.zcu = zcu
        return self.zcu.last_mir_module

    let t_mir = profile_now()
    let mir_mod: MirModule = lower_module(sema, active_pool, zcu.pool)
    let tailrec_syms = collect_tailrec_fn_syms(active_pool)
    if tailrec_syms.len() > 0:
        let tailrec_violations = mir_mod.verify_tailrec_contracts(sema, active_pool, tailrec_syms)
        if tailrec_violations.len() > 0:
            zcu.sync_from_sema(sema)
            compilation_debug_pool_flow("run_mir_lower:after_sync", zcu.pool, active_pool, zcu.last_sema)
            for vi in 0..tailrec_violations.len() as i32:
                let violation = tailrec_violations.get(vi as i64)
                let start = active_pool.get_start(violation.node)
                let end_raw = active_pool.get_end(violation.node)
                let end = if end_raw > start: end_raw else: start + 1
                let span = Span { file: sema.local_file_id, start, end }
                zcu.diagnostics.emit(Diagnostic.err(violation.message, span))
            zcu.render_all_diagnostics_frontend()
            zcu.set_codegen_snapshot(MirModule.init(), "", AsyncMirModule.init(), "")
            self.zcu = zcu
            return self.zcu.last_mir_module
    if sema.diags.has_errors():
        zcu.sync_from_sema(sema)
        compilation_debug_pool_flow("run_mir_lower:after_sync", zcu.pool, active_pool, zcu.last_sema)
        zcu.render_all_diagnostics_frontend()
        zcu.set_codegen_snapshot(MirModule.init(), "", AsyncMirModule.init(), "")
        self.zcu = zcu
        return self.zcu.last_mir_module
    if do_profile:
        profile_emit("mir.lower", t_mir, f"bodies={mir_mod.body_count()}")
    let t_mir_validate = profile_now()
    let mir_err = validate_typed_mir_module(mir_mod)
    if do_profile:
        profile_emit("mir.validate", t_mir_validate, "")
    if mir_validation_has_error(mir_err):
        let diag_span = compilation_mir_error_span(zcu, active_pool, mir_err.fn_sym, mir_err.span)
        sema.diags.emit(Diagnostic.err("invalid MIR before codegen: " ++ mir_err.message, diag_span))
        zcu.sync_from_sema(sema)
        compilation_debug_pool_flow("run_mir_lower:after_sync", zcu.pool, active_pool, zcu.last_sema)
        zcu.render_all_diagnostics_frontend()
        zcu.set_codegen_snapshot(MirModule.init(), "", AsyncMirModule.init(), "")
        self.zcu = zcu
        return self.zcu.last_mir_module
    let t_async = profile_now()
    let async_artifacts: AsyncLowerResult = lower_async_module(mir_mod, active_pool, zcu.pool, sema, zcu.diagnostics)
    if do_profile:
        profile_emit("async.lower", t_async, "")
    zcu.diagnostics = async_artifacts.diags
    compilation_dump_type_names("post-mir-lower", active_pool, zcu.pool)

    // Sync sema AFTER MIR lowering — type tables are frozen but other
    // sema state (e.g. diagnostics) may have been updated.
    zcu.sync_from_sema(sema)
    compilation_debug_pool_flow("run_mir_lower:after_sync", zcu.pool, active_pool, zcu.last_sema)
    zcu.set_codegen_snapshot(mir_mod, "", async_artifacts.out_mod, "")
    self.zcu = zcu
    self.zcu.last_mir_module

fn Compilation.run_async_mir_lower(self: Compilation, pool: AstPool) -> AsyncMirModule:
    let _ = self.run_mir_lower(pool)
    if self.zcu.diagnostics.has_errors():
        self.zcu.set_codegen_snapshot(self.zcu.last_mir_module, self.zcu.last_mir_dump, AsyncMirModule.init(), "")
        return self.zcu.last_async_mir_module
    self.zcu.last_async_mir_module

fn Compilation.ensure_codegen_mir(self: Compilation, pool: AstPool) -> bool:
    if self.zcu.last_mir_module.body_count() == 0:
        let _ = self.run_mir_lower(pool)
    if self.zcu.diagnostics.has_errors():
        return false
    self.zcu.last_mir_module.body_count() > 0

let _compiler_compilation_eof_guard = 0
