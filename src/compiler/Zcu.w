use Ast
use InternPool
use Diagnostic
use Resolve
use Source
use Sema
use Mir
use AsyncMir
use compiler.Compilation.Config

extern fn with_eprintln(s: str) -> void
extern fn with_getenv_str(name: str) -> str
extern fn int_to_string(n: i32) -> str

fn zcu_debug_init_enabled() -> i32:
    let raw = with_getenv_str("WITH_DEBUG_STAGE1_TRACE")
    if raw.len() == 0:
        return 0
    1

fn zcu_debug_init(msg: str):
    if zcu_debug_init_enabled() == 0:
        return
    with_eprintln("[zcu-init] " ++ msg)

fn zcu_debug_pool_flow_enabled() -> i32:
    let raw = with_getenv_str("WITH_DEBUG_POOL_FLOW")
    if raw.len() == 0:
        return 0
    1

// Zig Compilation Unit (ZCU) state for the With compiler.
//
// This is the canonical per-compilation owner of interned semantic state,
// diagnostics, and source/import context.
type Zcu = {
    pool: InternPool,
    frontend_pool: InternPool,
    diagnostics: DiagnosticList,
    imported_paths: Vec[str],
    c_import_cache_keys: Vec[str],
    c_import_cache_values: Vec[str],
    source_dir: str,
    next_file_id: i32,
    current_source_path: str,
    current_source_text: str,
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
    trace_c_import_cache: i32,
    prelude_mode: i32,
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
        c_import_cache_keys: Vec.new(),
        c_import_cache_values: Vec.new(),
        source_dir: ".",
        next_file_id: 1,
        current_source_path: "<unknown>",
        current_source_text: "",
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
        trace_c_import_cache: 0,
        prelude_mode: PRELUDE_FULL(),
    }

fn Zcu.reset_import_state(self: Zcu):
    let empty: Vec[str] = Vec.new()
    self.imported_paths = empty
    self.next_file_id = 1

fn Zcu.has_imported_path(self: Zcu, path: str) -> i32:
    for i in 0..self.imported_paths.len() as i32:
        if self.imported_paths.get(i as i64) == path:
            return 1
    0

fn Zcu.add_imported_path(self: Zcu, path: str):
    self.imported_paths.push(path)

fn Zcu.c_import_cache_lookup(self: Zcu, key: str) -> str:
    for i in 0..self.c_import_cache_keys.len() as i32:
        if self.c_import_cache_keys.get(i as i64) == key:
            return self.c_import_cache_values.get(i as i64)
    ""

fn Zcu.c_import_cache_store(self: Zcu, key: str, value: str):
    self.c_import_cache_keys.push(key)
    self.c_import_cache_values.push(value)

fn Zcu.set_prelude_mode(self: Zcu, mode: i32):
    self.prelude_mode = compilation_normalize_prelude_mode(mode)

fn Zcu.print_warnings(self: Zcu):
    let source = Source.from_string(self.current_source_path, self.current_source_text, 0)
    self.diagnostics.render_warnings(source)

fn Zcu.reset_pending_warnings(self: Zcu):
    let empty: Vec[str] = Vec.new()
    self.pending_warnings = empty

fn Zcu.capture_pending_warnings(self: Zcu):
    self.reset_pending_warnings()

fn Zcu.set_current_source(self: Zcu, source_dir: str, path: str, text: str):
    self.source_dir = source_dir
    self.current_source_path = path
    self.current_source_text = text

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

fn Zcu.reset_for_new_invocation(self: Zcu, source_dir: str, path: str, text: str):
    self.set_current_source(source_dir, path, text)
    self.reset_import_state()
    self.reset_pending_warnings()
    self.clear_stage_outputs()

fn Zcu.set_pending_warnings(self: Zcu, warnings: Vec[str]):
    self.pending_warnings = warnings

fn Zcu.set_pool(self: Zcu, pool: InternPool):
    self.pool = pool

fn Zcu.set_frontend_pool(self: Zcu, pool: InternPool):
    self.frontend_pool = pool

fn Zcu.sync_from_sema(self: Zcu, sema: Sema):
    if zcu_debug_pool_flow_enabled() != 0:
        with_eprintln("[zcu] sync_from_sema:before zcu.pool=" ++ int_to_string(self.pool.symbol_texts.len() as i32) ++
            " sema.pool=" ++ int_to_string(sema.pool.symbol_texts.len() as i32) ++
            " sema.ast.decls=" ++ int_to_string(sema.ast.decl_count()))
    self.pool = sema.pool
    self.diagnostics = sema.diags
    self.typed_expr_types = sema.typed_expr_types
    self.typed_binding_types = sema.typed_binding_types
    self.typed_binding_names = sema.typed_binding_names
    self.typed_binding_muts = sema.typed_binding_muts
    self.last_sema = sema
    if zcu_debug_pool_flow_enabled() != 0:
        with_eprintln("[zcu] sync_from_sema:after zcu.pool=" ++ int_to_string(self.pool.symbol_texts.len() as i32) ++
            " last_sema.pool=" ++ int_to_string(self.last_sema.pool.symbol_texts.len() as i32) ++
            " last_sema.ast.decls=" ++ int_to_string(self.last_sema.ast.decl_count()))

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

fn Zcu.capture_last_link_lib_names(self: Zcu, pool: InternPool, result: ResolveResult):
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
    let source: Source = Source.from_string(self.current_source_path, self.current_source_text, 0)
    self.diagnostics.render_all(source)
