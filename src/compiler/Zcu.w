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
use compiler.TrackedInputs
use compiler.EmbeddedRuntime
use std.collections.HashMap
extern fn with_str_clone_ref(s: &str) -> str

fn zcu_owned_text(text: &str) -> str:
    if text.len() == 0:
        return ""
    runtime_str_clone(text)

fn zcu_new_vec_str -> Vec[str]:
    let out: Vec[str] = Vec{ ptr: 0, len: 0, cap: 0, elem_size: 16 }
    out

fn zcu_debug_init_enabled() -> i32:
    let raw = runtime_getenv("WITH_DEBUG_STAGE1_TRACE")
    if raw.len() == 0:
        return 0
    1

fn zcu_debug_init(msg: &str):
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
    // #682-inc1: pool decl count (and its non-use subset) of the pre-expanded
    // prelude closure prefix — [use decl, closure decls...] parsed BEFORE the
    // user source so the prefix's node/intern/file ids are deterministic for
    // a given compiler fingerprint + prelude mode. 0 = no prefix (non-prelude
    // modes and secondary frontend entries keep the legacy order).
    prelude_prefix_decls: i32,
    prelude_prefix_non_use: i32,
    decl_source_paths: Vec[str],
    decl_source_file_ids: Vec[i32],
    decl_is_c_import: Vec[i32],
    c_import_omitted_symbols: HashMap[str, str],
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
    last_typed_dump: str,
    typed_pool_cache: AstPool,
    last_sema: Sema,
    last_mir_module: MirModule,
    last_mir_dump: str,
    last_async_mir_module: AsyncMirModule,
    last_async_mir_dump: str,
    // #650: how many codegen-unit objects the last backend emit produced
    // (1 = single canonical object; K > 1 adds <obj>.u1.o .. .u{K-1}.o).
    last_codegen_unit_count: i32,
    last_link_lib_names: Vec[str],
    tracked_input_paths: Vec[str],
    // D39: module prefixes of the `--link-bundle` manifests — codegen
    // declares (never defines) the functions of these modules, exactly as
    // for the compiler's embedded bundles (Codegen.bundle_prefixes).
    link_bundle_prefixes: Vec[str],
    project_config: ProjectConfig,
    trace_c_import_cache: i32,
    // Analysis commands preserve diagnostics but may continue past preliminary
    // semantic errors to produce a partial final-Sema fact snapshot.
    analysis_partial_semantics: i32,
    // No-silent-fallbacks guard: set only when compile_source_frontend_mode
    // ran sema to completion. Success verdicts (check_pool) require this
    // POSITIVE evidence — a pipeline that stops before sema must never map
    // to exit 0, whatever state produced the stop.
    frontend_sema_completed: i32,
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
    let sema_seed: Sema = Sema.placeholder(pool, DiagnosticList.init(), AstPool.new())
    zcu_debug_init("Zcu.init:sema_seed")
    Zcu {
        pool: pool,
        frontend_pool: pool,
        // Zcu owns the active diagnostic list. The placeholder snapshot has an
        // independent empty list so neither field aliases or moves from the other.
        diagnostics,
        imported_paths: zcu_new_vec_str(),
        prelude_prefix_decls: 0,
        prelude_prefix_non_use: 0,
        decl_source_paths: zcu_new_vec_str(),
        decl_source_file_ids: Vec.new(),
        decl_is_c_import: Vec.new(),
        c_import_omitted_symbols: HashMap.new(),
        c_import_cache_keys: zcu_new_vec_str(),
        c_import_cache_values: zcu_new_vec_str(),
        source_dir: ".",
        next_file_id: 1,
        current_source_path: "<unknown>",
        current_source_text: "",
        extra_source_names: zcu_new_vec_str(),
        extra_source_texts: zcu_new_vec_str(),
        source_text_file_ids: Vec.new(),
        source_text_names: zcu_new_vec_str(),
        source_texts: zcu_new_vec_str(),
        tool_mode_entry_path: "",
        pending_warnings: zcu_new_vec_str(),
        last_resolved: ResolveResult.init(),
        resolved_root_path: "",
        last_typed_dump: "",
        typed_pool_cache: AstPool.new(),
        last_sema: sema_seed,
        last_mir_module: MirModule.init(),
        last_mir_dump: "",
        last_async_mir_module: AsyncMirModule.init(),
        last_async_mir_dump: "",
        last_codegen_unit_count: 1,
        last_link_lib_names: zcu_new_vec_str(),
        tracked_input_paths: zcu_new_vec_str(),
        link_bundle_prefixes: zcu_new_vec_str(),
        project_config: project_config_default(),
        trace_c_import_cache: 0,
        analysis_partial_semantics: 0,
        frontend_sema_completed: 0,
        prelude_mode: PRELUDE_FULL(),
        cli_diag_gen_starts: Vec.new(),
        cli_diag_gen_ends: Vec.new(),
        cli_diag_source_names: zcu_new_vec_str(),
        cli_diag_source_texts: zcu_new_vec_str(),
    }

impl Zcu:
    mut fn add_link_bundle_prefixes(prefixes: &Vec[str]):
        for i in 0..prefixes.len() as i32:
            let prefix = prefixes.get(i as i64)
            if not self.link_bundle_prefixes.contains(prefix):
                self.link_bundle_prefixes.push(with_str_clone_ref(prefix))

    mut fn reset_import_state():
        let empty = zcu_new_vec_str()
        self.imported_paths = empty
        self.decl_source_paths = zcu_new_vec_str()
        self.decl_source_file_ids = Vec.new()
        self.decl_is_c_import = Vec.new()
        self.c_import_omitted_symbols = HashMap.new()
        self.next_file_id = 1

    // #592: import dedup compares CANONICAL keys, so different spellings of the
    // same file (root vs import-resolved, ./-prefixed, absolute, via ..) collapse
    // to one import and the loader never parses a file twice.
    fn has_imported_path(path: &str) -> i32:
        let key = resolve_canonical_module_key(path)
        for i in 0..self.imported_paths.len() as i32:
            if self.imported_paths.get(i as i64) == key:
                return 1
        0

    fn add_imported_path(path: &str) -> Unit:
        self.imported_paths.push(zcu_owned_text(resolve_canonical_module_key(path)))

    mut fn seed_decl_source_paths(pool: AstPool, path: &str, file_id: i32) -> Unit:
        self.decl_source_paths = Vec.new()
        self.decl_source_file_ids = Vec.new()
        self.decl_is_c_import = Vec.new()
        for _ in 0..pool.decl_count():
            self.decl_source_paths.push(zcu_owned_text(path))
            self.decl_source_file_ids.push(file_id)
            self.decl_is_c_import.push(0)

    fn append_decl_source_paths(count: i32, path: &str, file_id: i32) -> Unit:
        for _ in 0..count:
            self.decl_source_paths.push(zcu_owned_text(path))
            self.decl_source_file_ids.push(file_id)
            self.decl_is_c_import.push(0)

    fn append_c_import_decl_paths(count: i32, path: &str, file_id: i32) -> Unit:
        for _ in 0..count:
            self.decl_source_paths.push(zcu_owned_text(path))
            self.decl_source_file_ids.push(file_id)
            self.decl_is_c_import.push(1)

    fn decl_source_path_frontend(decl_index: i32) -> str:
        if decl_index >= 0 and decl_index < self.decl_source_paths.len() as i32:
            return with_str_clone_ref(self.decl_source_paths.get(decl_index as i64))
        self.current_source_path.clone()

    fn decl_source_file_id_frontend(decl_index: i32) -> i32:
        if decl_index >= 0 and decl_index < self.decl_source_file_ids.len() as i32:
            return self.decl_source_file_ids.get(decl_index as i64)
        0

    fn decl_source_dir_frontend(decl_index: i32) -> str:
        let path = self.decl_source_path_frontend(decl_index)
        if path.len() == 0:
            return self.source_dir.clone()
        resolve_dirname(path)

    fn c_import_cache_lookup(key: &str) -> str:
        for i in 0..self.c_import_cache_keys.len() as i32:
            if self.c_import_cache_keys.get(i as i64) == key:
                return with_str_clone_ref(self.c_import_cache_values.get(i as i64))
        ""

    fn c_import_cache_store(key: &str, value: &str) -> Unit:
        self.c_import_cache_keys.push(with_str_clone_ref(key))
        self.c_import_cache_values.push(with_str_clone_ref(value))

    mut fn set_prelude_mode(mode: i32):
        self.prelude_mode = compilation_normalize_prelude_mode(mode)

    mut fn clear_cli_diag_mappings():
        self.cli_diag_gen_starts = Vec.new()
        self.cli_diag_gen_ends = Vec.new()
        self.cli_diag_source_names = Vec.new()
        self.cli_diag_source_texts = Vec.new()

    fn add_cli_diag_mapping(gen_start: i32, gen_end: i32, source_name: &str, source_text: &str) -> Unit:
        self.cli_diag_gen_starts.push(gen_start)
        self.cli_diag_gen_ends.push(gen_end)
        self.cli_diag_source_names.push(with_str_clone_ref(source_name))
        self.cli_diag_source_texts.push(with_str_clone_ref(source_text))

    fn cli_diag_mapping_index(offset: i32) -> i32:
        for i in 0..self.cli_diag_gen_starts.len() as i32:
            let start = self.cli_diag_gen_starts.get(i as i64)
            let end = self.cli_diag_gen_ends.get(i as i64)
            if offset >= start and offset <= end:
                return i
        -1

    // Borrows: rendering only reads. Consuming it made the caller copy an
    // element out of self.diagnostics.items — an aliasing bit-copy whose
    // drop freed the stored diagnostic's label/note buffers (#715 class,
    // reproduced as a DOUBLE FREE under --debug-alloc).
    fn render_diag_frontend(diag: &Diagnostic):
        let source = self.source_for_file_id_frontend(diag.primary.file)
        self.render_diag_frontend_with(diag, &source)

    // Renders against a caller-supplied primary Source so diagnostic loops
    // can reuse one Source per file. Building a fresh Source per diagnostic
    // clones the whole file text and recomputes its line-offset table —
    // quadratic on a warning/error flood over a large file (#747: the
    // migrate fix-it pass spent minutes here on the emitted compiler C).
    // CLI-mapped diagnostics resolve their own source and ignore `source`.
    fn render_diag_frontend_with(diag: &Diagnostic, source: &Source):
        let map_idx = self.cli_diag_mapping_index(diag.primary.start)
        if map_idx >= 0:
            let gen_start = self.cli_diag_gen_starts.get(map_idx as i64)
            let mapped = Source.from_string(self.cli_diag_source_names.get(map_idx as i64), self.cli_diag_source_texts.get(map_idx as i64), 0)
            diag.render_at_offset(mapped, gen_start)
            return
        // #670: labels can point into other files (e.g. E0921's concurrency
        // evidence in the std prelude); resolve each one against its own file.
        let label_paths: Vec[str] = Vec.new()
        let label_texts: Vec[str] = Vec.new()
        for li in 0..diag.labels.len() as i32:
            let lab_file = diag.labels.get(li as i64).span.file
            if lab_file != 0 and lab_file != diag.primary.file:
                var lab_source = self.source_for_file_id_frontend(lab_file)
                label_paths.push(move lab_source.path)
                label_texts.push(move lab_source.text)
            else:
                label_paths.push("")
                label_texts.push("")
        diag.render_with_label_sources(source, &label_paths, &label_texts)

    fn source_for_file_id_frontend(file_id: i32) -> Source:
        if file_id == 0:
            return Source.from_string(self.current_source_path, self.current_source_text, 0)
        // #661: consult the unconditional file registry FIRST. Gating it
        // behind the per-decl tables meant a module whose parse produced
        // zero decls was unfindable, and its errors rendered against the
        // ROOT module's text — phantom carets at root EOF.
        for si in 0..self.source_text_file_ids.len() as i32:
            if self.source_text_file_ids.get(si as i64) == file_id:
                return Source.from_string(self.source_text_names.get(si as i64), self.source_texts.get(si as i64), file_id)
        for i in 0..self.decl_source_file_ids.len() as i32:
            if self.decl_source_file_ids.get(i as i64) != file_id:
                continue
            let path = self.decl_source_path_frontend(i)
            let embedded_rel = embedded_std_rel_path(path)
            let embedded_rt_rel = embedded_rt_rel_path(path)
            let text = if embedded_rel.len() > 0: embedded_std_source(embedded_rel)
                else if embedded_rt_rel.len() > 0: embedded_rt_source(embedded_rt_rel)
                else: runtime_read_file(path)
            return Source.from_string(path, text, file_id)
        Source.from_string(self.current_source_path, self.current_source_text, 0)

    fn render_all_diagnostics_frontend():
        // One Source per file, not per diagnostic (#747; see
        // render_diag_frontend_with).
        var cached_file = -2147483648
        var cached_source = Source.from_string("", "", 0)
        for i in 0..self.diagnostics.items.len() as i32:
            let diag = &self.diagnostics.items[i as i64]
            if self.cli_diag_mapping_index(diag.primary.start) < 0 and diag.primary.file != cached_file:
                cached_source = self.source_for_file_id_frontend(diag.primary.file)
                cached_file = diag.primary.file
            self.render_diag_frontend_with(diag, &cached_source)
            if i + 1 < self.diagnostics.items.len() as i32:
                runtime_eprint("")

    fn render_warnings_frontend():
        var printed = 0
        var cached_file = -2147483648
        var cached_source = Source.from_string("", "", 0)
        for i in 0..self.diagnostics.items.len() as i32:
            let diag = &self.diagnostics.items[i as i64]
            if diag.severity != DiagSeverity.Warning:
                continue
            if printed != 0:
                runtime_eprint("")
            if diag.primary.file != cached_file:
                cached_source = self.source_for_file_id_frontend(diag.primary.file)
                cached_file = diag.primary.file
            diag.render(cached_source)
            printed = printed + 1

    fn print_warnings():
        self.render_warnings_frontend()

    mut fn reset_pending_warnings():
        let empty = zcu_new_vec_str()
        self.pending_warnings = empty

    mut fn capture_pending_warnings():
        self.reset_pending_warnings()

    mut fn set_current_source(source_dir: &str, path: &str, text: &str):
        self.source_dir = with_str_clone_ref(source_dir)
        self.current_source_path = with_str_clone_ref(path)
        self.current_source_text = with_str_clone_ref(text)

    fn tracked_input_root() -> str:
        if self.project_config.root_dir.len() > 0:
            return self.project_config.root_dir.clone()
        self.source_dir.clone()

    fn configure_tracked_input_sema(sema: Sema) -> Sema:
        sema.set_tracked_input_context(self.tracked_input_root(), &self.tracked_input_paths)
        sema

    mut fn set_extra_sources(names: Vec[str], texts: Vec[str]):
        self.extra_source_names = names
        self.extra_source_texts = texts

    fn add_source_text_mapping(file_id: i32, name: &str, text: &str) -> Unit:
        self.source_text_file_ids.push(file_id)
        self.source_text_names.push(zcu_owned_text(name))
        self.source_texts.push(zcu_owned_text(text))

    mut fn clear_stage_outputs():
        self.last_resolved = ResolveResult.init()
        self.resolved_root_path = ""
        self.last_typed_dump = ""
        self.typed_pool_cache = AstPool.new()
        // Reset the active diagnostics and the placeholder snapshot independently.
        // Moving one list into both roles leaves the active Vec as a reset sentinel,
        // which is not a reusable empty Vec (its element-size metadata is zero).
        self.diagnostics = DiagnosticList.init()
        self.last_sema = Sema.placeholder(self.pool, DiagnosticList.init(), AstPool.new())
        self.last_mir_module = MirModule.init()
        self.last_mir_dump = ""
        self.last_async_mir_module = AsyncMirModule.init()
        self.last_async_mir_dump = ""
        self.reset_last_link_lib_names()
        self.tracked_input_paths = Vec.new()
        self.trace_c_import_cache = 0
        self.source_text_file_ids = Vec.new()
        self.source_text_names = Vec.new()
        self.source_texts = Vec.new()

    mut fn reset_for_new_invocation(source_dir: &str, path: &str, text: &str):
        self.set_current_source(source_dir, path, text)
        self.frontend_sema_completed = 0
        self.extra_source_names = Vec.new()
        self.extra_source_texts = Vec.new()
        self.reset_import_state()
        self.reset_pending_warnings()
        self.clear_stage_outputs()
        self.project_config = project_config_default()

    mut fn set_pending_warnings(warnings: Vec[str]):
        self.pending_warnings = warnings

    mut fn set_pool(pool: InternPool):
        self.pool = pool

    mut fn set_frontend_pool(pool: InternPool):
        self.frontend_pool = pool

    mut fn sync_from_sema(sema: Sema):
        if zcu_debug_pool_flow_enabled() != 0:
            runtime_eprint(f"[zcu] sync_from_sema:before zcu.pool={self.pool.state.symbol_texts.len() as i32} sema.pool={sema.pool.state.symbol_texts.len() as i32} sema.ast.decls={sema.ast.decl_count()}")
        self.pool = sema.pool
        var tracked_paths = move self.tracked_input_paths
        self.tracked_input_paths = tracked_input_merge_unique(move tracked_paths, &sema.tracked_input_paths)
        // Callers move sema.diags into Zcu.diagnostics before syncing. The moved
        // field is an all-zero reset sentinel, not a reusable Vec: pushing a
        // later comptime/action diagnostic would allocate zero bytes and leave
        // stale allocator contents to be dropped as a Diagnostic (#743).
        sema.diags = DiagnosticList.init()
        self.last_sema = sema
        if zcu_debug_pool_flow_enabled() != 0:
            runtime_eprint(f"[zcu] sync_from_sema:after zcu.pool={self.pool.state.symbol_texts.len() as i32} last_sema.pool={self.last_sema.pool.state.symbol_texts.len() as i32} last_sema.ast.decls={self.last_sema.ast.decl_count()}")

    mut fn set_resolve_snapshot(result: &ResolveResult, root_path: &str):
        let modules: Vec[ResolvedModule] = Vec.new()
        for i in 0..result.modules.len() as i32:
            let m = result.modules.get(i as i64)
            modules.push(ResolvedModule {
                module_id: m.module_id,
                file_id: m.file_id,
                path: zcu_owned_text(m.path),
                import_start: m.import_start,
                import_count: m.import_count,
                decl_count: m.decl_count,
            })

        let imports: Vec[ResolvedImport] = Vec.new()
        for i in 0..result.imports.len() as i32:
            let imp = result.imports.get(i as i64)
            imports.push(ResolvedImport {
                module_id: imp.module_id,
                index_in_module: imp.index_in_module,
                kind: imp.kind,
                path_text: zcu_owned_text(imp.path_text),
                target_module: imp.target_module,
                span_start: imp.span_start,
                span_end: imp.span_end,
            })

        let defs: Vec[ResolvedDef] = Vec.new()
        for i in 0..result.defs.len() as i32:
            defs.push(result.defs.get(i as i64))

        let scopes: Vec[ResolvedScope] = Vec.new()
        for i in 0..result.scopes.len() as i32:
            scopes.push(result.scopes.get(i as i64))

        let bindings: Vec[ResolvedBinding] = Vec.new()
        for i in 0..result.bindings.len() as i32:
            bindings.push(result.bindings.get(i as i64))

        let uses: Vec[ResolvedUse] = Vec.new()
        for i in 0..result.uses.len() as i32:
            uses.push(result.uses.get(i as i64))

        let link_libs: Vec[i32] = Vec.new()
        for i in 0..result.link_libs.len() as i32:
            link_libs.push(result.link_libs.get(i as i64))

        self.last_resolved = ResolveResult {
            modules,
            imports,
            defs,
            scopes,
            bindings,
            uses,
            link_libs,
        }
        self.resolved_root_path = zcu_owned_text(root_path)

    mut fn set_typed_snapshot(typed_dump: &str, typed_pool: AstPool):
        self.last_typed_dump = with_str_clone_ref(typed_dump)
        self.typed_pool_cache = typed_pool

    mut fn set_codegen_snapshot(mir_mod: MirModule, mir_dump: &str, async_mod: AsyncMirModule, async_dump: &str):
        self.last_mir_module = mir_mod
        self.last_mir_dump = with_str_clone_ref(mir_dump)
        self.last_async_mir_module = async_mod
        self.last_async_mir_dump = with_str_clone_ref(async_dump)

    mut fn set_link_lib_names(names: Vec[str]):
        self.last_link_lib_names = names

    mut fn reset_last_link_lib_names():
        let empty = zcu_new_vec_str()
        self.last_link_lib_names = empty

    mut fn capture_last_link_lib_names(pool: InternPool, result: &ResolveResult) -> Unit:
        self.reset_last_link_lib_names()
        for li in 0..result.link_libs.len() as i32:
            let lib_sym = result.link_libs.get(li as i64)
            if lib_sym <= 0:
                continue
            let lib_name: str = with_str_clone_ref(pool.resolve(lib_sym))
            if lib_name.len() > 0:
                self.last_link_lib_names.push(lib_name)

    mut fn set_diagnostics(diags: DiagnosticList):
        self.diagnostics = diags

    fn render_current_diagnostics():
        self.render_all_diagnostics_frontend()
