use Ast
use InternPool
use Diagnostic
use Resolve
use Source
use Sema
use Mir
use AsyncMir
use compiler.Compilation.Config
use compiler.ProjectConfig
use compiler.Runtime

fn zcu_owned_text(text: str) -> str:
    if text.len() == 0:
        return ""
    runtime_str_clone(text)

fn zcu_debug_init_enabled() -> i32:
    let raw = runtime_getenv("WITH_DEBUG_STAGE1_TRACE")
    if raw.len() == 0:
        return 0
    1

fn zcu_debug_init(msg: str):
    if zcu_debug_init_enabled() == 0:
        return
    runtime_eprint("[zcu-init] " ++ msg)

fn zcu_debug_pool_flow_enabled() -> i32:
    let raw = runtime_getenv("WITH_DEBUG_POOL_FLOW")
    if raw.len() == 0:
        return 0
    1

// Zig Compilation Unit (ZCU) state for the With compiler.
//
// This is the canonical per-compilation owner of interned semantic state,
// diagnostics, and source/import context.
type Zcu {
    pool: InternPool,
    frontend_pool: InternPool,
    diagnostics: DiagnosticList,
    imported_paths: Vec[str],
    decl_source_paths: Vec[str],
    decl_source_file_ids: Vec[i32],
    decl_is_c_import: Vec[i32],
    c_import_cache_keys: Vec[str],
    c_import_cache_values: Vec[str],
    source_dir: str,
    next_file_id: i32,
    current_source_path: str,
    current_source_text: str,
    extra_source_names: Vec[str],
    extra_source_texts: Vec[str],
    source_text_file_ids: Vec[i32],
    source_text_names: Vec[str],
    source_texts: Vec[str],
    tool_mode_entry_path: str,
    pending_warnings: Vec[str],
    last_resolved: ResolveResult,
    resolved_root_path: str,
    // Wave 5 canonical typed sidecars from the latest semantic pass.
    typed_expr_types: HashMap[i32, i32],
    typed_binding_types: HashMap[i32, i32],
    typed_binding_names: HashMap[i32, i32],
    typed_binding_muts: HashMap[i32, i32],
    last_typed_dump: str,
    typed_pool_cache: AstPool,
    last_sema: Sema,
    last_mir_module: MirModule,
    last_mir_dump: str,
    last_async_mir_module: AsyncMirModule,
    last_async_mir_dump: str,
    last_link_lib_names: Vec[str],
    project_config: ProjectConfig,
    trace_c_import_cache: i32,
    prelude_mode: i32,
    cli_diag_gen_starts: Vec[i32],
    cli_diag_gen_ends: Vec[i32],
    cli_diag_source_names: Vec[str],
    cli_diag_source_texts: Vec[str],
}

fn Zcu.init -> Zcu:
    zcu_debug_init("Zcu.init:start")
    let pool: InternPool = InternPool.init()
    zcu_debug_init("Zcu.init:pool")
    let diagnostics: DiagnosticList = DiagnosticList.init()
    zcu_debug_init("Zcu.init:diagnostics")
    let sema_seed: Sema = Sema.placeholder(pool, diagnostics, AstPool.new())
    zcu_debug_init("Zcu.init:sema_seed")
    Zcu {
        pool: pool,
        frontend_pool: pool,
        diagnostics: diagnostics,
        imported_paths: Vec.new(),
        decl_source_paths: Vec.new(),
        decl_source_file_ids: Vec.new(),
        decl_is_c_import: Vec.new(),
        c_import_cache_keys: Vec.new(),
        c_import_cache_values: Vec.new(),
        source_dir: ".",
        next_file_id: 1,
        current_source_path: "<unknown>",
        current_source_text: "",
        extra_source_names: Vec.new(),
        extra_source_texts: Vec.new(),
        source_text_file_ids: Vec.new(),
        source_text_names: Vec.new(),
        source_texts: Vec.new(),
        tool_mode_entry_path: "",
        pending_warnings: Vec.new(),
        last_resolved: ResolveResult.init(),
        resolved_root_path: "",
        typed_expr_types: HashMap.new(),
        typed_binding_types: HashMap.new(),
        typed_binding_names: HashMap.new(),
        typed_binding_muts: HashMap.new(),
        last_typed_dump: "",
        typed_pool_cache: AstPool.new(),
        last_sema: sema_seed,
        last_mir_module: MirModule.init(),
        last_mir_dump: "",
        last_async_mir_module: AsyncMirModule.init(),
        last_async_mir_dump: "",
        last_link_lib_names: Vec.new(),
        project_config: project_config_default(),
        trace_c_import_cache: 0,
        prelude_mode: PRELUDE_FULL(),
        cli_diag_gen_starts: Vec.new(),
        cli_diag_gen_ends: Vec.new(),
        cli_diag_source_names: Vec.new(),
        cli_diag_source_texts: Vec.new(),
    }

fn Zcu.reset_import_state(self: Zcu):
    let empty: Vec[str] = Vec.new()
    self.imported_paths = empty
    self.decl_source_paths = Vec.new()
    self.decl_source_file_ids = Vec.new()
    self.next_file_id = 1

fn Zcu.has_imported_path(self: Zcu, path: str) -> i32:
    for i in 0..self.imported_paths.len() as i32:
        if self.imported_paths.get(i as i64) == path:
            return 1
    0

fn Zcu.add_imported_path(self: Zcu, path: str) -> void:
    self.imported_paths.push(zcu_owned_text(path))

fn Zcu.seed_decl_source_paths(self: Zcu, pool: AstPool, path: str, file_id: i32) -> void:
    self.decl_source_paths = Vec.new()
    self.decl_source_file_ids = Vec.new()
    self.decl_is_c_import = Vec.new()
    let owned = zcu_owned_text(path)
    for _ in 0..pool.decl_count():
        self.decl_source_paths.push(owned)
        self.decl_source_file_ids.push(file_id)
        self.decl_is_c_import.push(0)

fn Zcu.append_decl_source_paths(self: Zcu, count: i32, path: str, file_id: i32) -> void:
    let owned = zcu_owned_text(path)
    for _ in 0..count:
        self.decl_source_paths.push(owned)
        self.decl_source_file_ids.push(file_id)
        self.decl_is_c_import.push(0)

fn Zcu.append_c_import_decl_paths(self: Zcu, count: i32, path: str, file_id: i32) -> void:
    let owned = zcu_owned_text(path)
    for _ in 0..count:
        self.decl_source_paths.push(owned)
        self.decl_source_file_ids.push(file_id)
        self.decl_is_c_import.push(1)

fn Zcu.decl_source_path_frontend(self: Zcu, decl_index: i32) -> str:
    if decl_index >= 0 and decl_index < self.decl_source_paths.len() as i32:
        return self.decl_source_paths.get(decl_index as i64)
    self.current_source_path

fn Zcu.decl_source_file_id_frontend(self: Zcu, decl_index: i32) -> i32:
    if decl_index >= 0 and decl_index < self.decl_source_file_ids.len() as i32:
        return self.decl_source_file_ids.get(decl_index as i64)
    0

fn Zcu.decl_source_dir_frontend(self: Zcu, decl_index: i32) -> str:
    let path = self.decl_source_path_frontend(decl_index)
    if path.len() == 0:
        return self.source_dir
    resolve_dirname(path)

fn Zcu.c_import_cache_lookup(self: Zcu, key: str) -> str:
    for i in 0..self.c_import_cache_keys.len() as i32:
        if self.c_import_cache_keys.get(i as i64) == key:
            return self.c_import_cache_values.get(i as i64)
    ""

fn Zcu.c_import_cache_store(self: Zcu, key: str, value: str) -> void:
    self.c_import_cache_keys.push(key)
    self.c_import_cache_values.push(value)

fn Zcu.set_prelude_mode(self: Zcu, mode: i32):
    self.prelude_mode = compilation_normalize_prelude_mode(mode)

fn Zcu.clear_cli_diag_mappings(self: Zcu):
    self.cli_diag_gen_starts = Vec.new()
    self.cli_diag_gen_ends = Vec.new()
    self.cli_diag_source_names = Vec.new()
    self.cli_diag_source_texts = Vec.new()

fn Zcu.add_cli_diag_mapping(self: Zcu, gen_start: i32, gen_end: i32, source_name: str, source_text: str) -> void:
    self.cli_diag_gen_starts.push(gen_start)
    self.cli_diag_gen_ends.push(gen_end)
    self.cli_diag_source_names.push(source_name)
    self.cli_diag_source_texts.push(source_text)

fn Zcu.cli_diag_mapping_index(self: Zcu, offset: i32) -> i32:
    for i in 0..self.cli_diag_gen_starts.len() as i32:
        let start = self.cli_diag_gen_starts.get(i as i64)
        let end = self.cli_diag_gen_ends.get(i as i64)
        if offset >= start and offset <= end:
            return i
    -1

fn Zcu.render_diag_frontend(self: Zcu, diag: Diagnostic):
    let map_idx = self.cli_diag_mapping_index(diag.primary.start)
    if map_idx >= 0:
        let gen_start = self.cli_diag_gen_starts.get(map_idx as i64)
        let source = Source.from_string(self.cli_diag_source_names.get(map_idx as i64), self.cli_diag_source_texts.get(map_idx as i64), 0)
        var mapped = diag
        mapped.primary.start = mapped.primary.start - gen_start
        mapped.primary.end = mapped.primary.end - gen_start
        if mapped.primary.start < 0:
            mapped.primary.start = 0
        if mapped.primary.end <= mapped.primary.start:
            mapped.primary.end = mapped.primary.start + 1
        mapped.render(source)
        return
    let source = self.source_for_file_id_frontend(diag.primary.file)
    diag.render(source)

fn Zcu.source_for_file_id_frontend(self: Zcu, file_id: i32) -> Source:
    if file_id == 0:
        return Source.from_string(self.current_source_path, self.current_source_text, 0)
    for i in 0..self.decl_source_file_ids.len() as i32:
        if self.decl_source_file_ids.get(i as i64) != file_id:
            continue
        let path = self.decl_source_path_frontend(i)
        for si in 0..self.source_text_file_ids.len() as i32:
            if self.source_text_file_ids.get(si as i64) == file_id:
                return Source.from_string(self.source_text_names.get(si as i64), self.source_texts.get(si as i64), file_id)
        let embedded_rel = embedded_std_rel_path(path)
        let text = if embedded_rel.len() > 0: embedded_std_source(embedded_rel) else: runtime_read_file(path)
        return Source.from_string(path, text, file_id)
    Source.from_string(self.current_source_path, self.current_source_text, 0)

fn Zcu.render_all_diagnostics_frontend(self: Zcu):
    for i in 0..self.diagnostics.items.len() as i32:
        let diag = self.diagnostics.items.get(i as i64)
        self.render_diag_frontend(diag)
        if i + 1 < self.diagnostics.items.len() as i32:
            runtime_eprint("")

fn Zcu.render_warnings_frontend(self: Zcu):
    var printed = 0
    for i in 0..self.diagnostics.items.len() as i32:
        let diag = self.diagnostics.items.get(i as i64)
        if diag.severity != DiagSeverity.Warning:
            continue
        if printed != 0:
            runtime_eprint("")
        let source = self.source_for_file_id_frontend(diag.primary.file)
        diag.render(source)
        printed = printed + 1

fn Zcu.print_warnings(self: Zcu):
    self.render_warnings_frontend()

fn Zcu.reset_pending_warnings(self: Zcu):
    let empty: Vec[str] = Vec.new()
    self.pending_warnings = empty

fn Zcu.capture_pending_warnings(self: Zcu):
    self.reset_pending_warnings()

fn Zcu.set_current_source(self: Zcu, source_dir: str, path: str, text: str):
    self.source_dir = source_dir
    self.current_source_path = path
    self.current_source_text = text

fn Zcu.set_extra_sources(self: Zcu, names: Vec[str], texts: Vec[str]):
    self.extra_source_names = names
    self.extra_source_texts = texts

fn Zcu.add_source_text_mapping(self: Zcu, file_id: i32, name: str, text: str):
    self.source_text_file_ids.push(file_id)
    self.source_text_names.push(zcu_owned_text(name))
    self.source_texts.push(zcu_owned_text(text))

fn Zcu.clear_stage_outputs(self: Zcu):
    self.last_resolved = ResolveResult.init()
    self.resolved_root_path = ""
    self.typed_expr_types = HashMap.new()
    self.typed_binding_types = HashMap.new()
    self.typed_binding_names = HashMap.new()
    self.typed_binding_muts = HashMap.new()
    self.last_typed_dump = ""
    self.typed_pool_cache = AstPool.new()
    self.last_sema = Sema.placeholder(self.pool, self.diagnostics, AstPool.new())
    self.last_mir_module = MirModule.init()
    self.last_mir_dump = ""
    self.last_async_mir_module = AsyncMirModule.init()
    self.last_async_mir_dump = ""
    self.reset_last_link_lib_names()
    self.trace_c_import_cache = 0
    self.source_text_file_ids = Vec.new()
    self.source_text_names = Vec.new()
    self.source_texts = Vec.new()

fn Zcu.reset_for_new_invocation(self: Zcu, source_dir: str, path: str, text: str):
    self.set_current_source(source_dir, path, text)
    self.extra_source_names = Vec.new()
    self.extra_source_texts = Vec.new()
    self.reset_import_state()
    self.reset_pending_warnings()
    self.clear_stage_outputs()
    self.project_config = project_config_default()

fn Zcu.set_pending_warnings(self: Zcu, warnings: Vec[str]):
    self.pending_warnings = warnings

fn Zcu.set_pool(self: Zcu, pool: InternPool):
    self.pool = pool

fn Zcu.set_frontend_pool(self: Zcu, pool: InternPool):
    self.frontend_pool = pool

fn Zcu.sync_from_sema(self: Zcu, sema: Sema):
    if zcu_debug_pool_flow_enabled() != 0:
        runtime_eprint(f"[zcu] sync_from_sema:before zcu.pool={self.pool.state.symbol_texts.len() as i32} sema.pool={sema.pool.state.symbol_texts.len() as i32} sema.ast.decls={sema.ast.decl_count()}")
    self.pool = sema.pool
    self.diagnostics = sema.diags
    self.typed_expr_types = sema.typed_expr_types
    self.typed_binding_types = sema.typed_binding_types
    self.typed_binding_names = sema.typed_binding_names
    self.typed_binding_muts = sema.typed_binding_muts
    self.last_sema = sema
    if zcu_debug_pool_flow_enabled() != 0:
        runtime_eprint(f"[zcu] sync_from_sema:after zcu.pool={self.pool.state.symbol_texts.len() as i32} last_sema.pool={self.last_sema.pool.state.symbol_texts.len() as i32} last_sema.ast.decls={self.last_sema.ast.decl_count()}")

fn Zcu.set_resolve_snapshot(self: Zcu, result: ResolveResult, root_path: str):
    self.last_resolved = result
    self.resolved_root_path = root_path

fn Zcu.set_typed_snapshot(self: Zcu, typed_dump: str, typed_pool: AstPool):
    self.last_typed_dump = typed_dump
    self.typed_pool_cache = typed_pool

fn Zcu.set_codegen_snapshot(self: Zcu, mir_mod: MirModule, mir_dump: str, async_mod: AsyncMirModule, async_dump: str):
    self.last_mir_module = mir_mod
    self.last_mir_dump = mir_dump
    self.last_async_mir_module = async_mod
    self.last_async_mir_dump = async_dump

fn Zcu.set_link_lib_names(self: Zcu, names: Vec[str]):
    self.last_link_lib_names = names

fn Zcu.reset_last_link_lib_names(self: Zcu):
    let empty: Vec[str] = Vec.new()
    self.last_link_lib_names = empty

fn Zcu.capture_last_link_lib_names(self: Zcu, pool: InternPool, result: ResolveResult) -> void:
    self.reset_last_link_lib_names()
    for li in 0..result.link_libs.len() as i32:
        let lib_sym = result.link_libs.get(li as i64)
        if lib_sym <= 0:
            continue
        let lib_name: str = pool.resolve(lib_sym)
        if lib_name.len() > 0:
            self.last_link_lib_names.push(lib_name)

fn Zcu.set_diagnostics(self: Zcu, diags: DiagnosticList):
    self.diagnostics = diags

fn Zcu.render_current_diagnostics(self: Zcu):
    self.render_all_diagnostics_frontend()
