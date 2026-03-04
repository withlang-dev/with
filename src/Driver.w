// Driver — Pipeline orchestration: lex → parse → (sema) → codegen → link.
//
// The Driver is the central coordinator that runs each compilation
// phase in sequence and manages shared state (intern pool, diagnostics).
// Direct port of bootstrap/src/Driver.zig to With.

use Ast
use Token
use Lexer
use InternPool
use Parser
use Diagnostic
use Source
use Span
use Sema
use Mir
use MirLower
use AsyncMir
use AsyncLower
use Codegen
use CImport
use Resolve

extern fn with_fs_read_file(path: str) -> str
extern fn with_eprintln(s: str) -> void
extern fn with_system(cmd: str) -> i32
extern fn int_to_string(n: i32) -> str
extern fn with_arg_count() -> i32
extern fn with_arg_at(idx: i32) -> str
extern fn with_getenv_str(name: str) -> str

type Driver = {
    pool: InternPool,
    diagnostics: DiagnosticList,
    // Set of already-imported file paths (to avoid duplicates/cycles).
    imported_paths: HashMap[str, i32],
    // Directory of the main source file being compiled.
    source_dir: str,
    // Next file ID for imported sources.
    next_file_id: i32,
    // Optimization level: 0=none, 1=basic, 2=standard, 3=aggressive.
    opt_level: i32,
    // Freestanding mode flags.
    no_std: bool,
    alloc: bool,
    // Path of the main source file.
    current_source_path: str,
    // Source text of the main file.
    current_source_text: str,
    // Root-module non-use declaration count for bounded textual dumps.
    last_root_decl_count: i32,
    // Pending warning messages.
    pending_warnings: Vec[str],
    // c_import expansion cache: key -> synthetic declaration source.
    c_import_cache: HashMap[str, str],
    // Emit cache hit/miss diagnostics when enabled.
    trace_c_import_cache: i32,
    // Wave 4 resolve artifact from the most recent compile/resolve run.
    last_resolved: ResolveResult,
    // Root path used when producing the last resolve artifact.
    resolved_root_path: str,
    // Wave 5 canonical typed sidecars from the latest semantic pass.
    typed_expr_types: HashMap[i32, i32],
    typed_binding_types: HashMap[i32, i32],
    typed_binding_names: HashMap[i32, i32],
    typed_binding_muts: HashMap[i32, i32],
    // Cached post-frontend AST used by dump-only paths to avoid unstable
    // by-value AstPool handoff through function return values.
    typed_pool_cache: AstPool,
    // Direct typed-emission mode (avoids AstPool by-value handoff).
    emit_typed_during_compile: i32,
    typed_emitted_during_compile: i32,
    last_typed_dump: str,
    // Wave 7 MIR artifacts from the latest successful semantic pass.
    last_sema: Sema,
    last_mir_module: MirModule,
    last_mir_dump: str,
    // Wave 9 Async-MIR artifacts derived from MIR.
    last_async_mir_module: AsyncMirModule,
    last_async_mir_dump: str,
}

fn Driver.init -> Driver:
    let sema_seed = Sema.init(InternPool.init(), DiagnosticList.init(), AstPool.new())
    Driver {
        pool: InternPool.init(),
        diagnostics: DiagnosticList.init(),
        imported_paths: HashMap.new(),
        source_dir: ".",
        next_file_id: 1,
        opt_level: 0,
        no_std: false,
        alloc: false,
        current_source_path: "<unknown>",
        current_source_text: "",
        last_root_decl_count: 0,
        pending_warnings: Vec.new(),
        c_import_cache: HashMap.new(),
        trace_c_import_cache: 0,
        last_resolved: ResolveResult.init(),
        resolved_root_path: "",
        typed_expr_types: HashMap.new(),
        typed_binding_types: HashMap.new(),
        typed_binding_names: HashMap.new(),
        typed_binding_muts: HashMap.new(),
        typed_pool_cache: AstPool.new(),
        emit_typed_during_compile: 0,
        typed_emitted_during_compile: 0,
        last_typed_dump: "",
        last_sema: sema_seed,
        last_mir_module: MirModule.init(),
        last_mir_dump: "",
        last_async_mir_module: AsyncMirModule.init(),
        last_async_mir_dump: "",
    }

fn Driver.deinit(self: Driver):
    return

fn Driver.configure(self: Driver, opt_level: i32, no_std: bool, alloc_mode: bool) -> void:
    self.opt_level = opt_level
    self.no_std = no_std
    self.alloc = alloc_mode

// ── Compile pipeline ─────────────────────────────────────────────

// Compile a single source file through the full pipeline.
// Returns the parsed AstPool on success, or a pool with 0 decls on failure.
fn Driver.compile_file(self: Driver, path: str) -> AstPool:
    self.source_dir = dirname(path)
    self.current_source_path = path

    // Load source text.
    let text = with_fs_read_file(path)
    if text.len() == 0:
        with_eprintln("error: cannot open '" ++ path ++ "'")
        self.last_resolved = ResolveResult.init()
        self.resolved_root_path = path
        self.last_mir_module = MirModule.init()
        self.last_mir_dump = ""
        self.last_async_mir_module = AsyncMirModule.init()
        self.last_async_mir_dump = ""
        return AstPool.new()

    self.current_source_text = text
    let pool = self.compile_source(text, path, 0)
    if pool.decl_count() == 0 and not self.diagnostics.has_errors():
        with_eprintln("error: compiler produced an empty module for '" ++ path ++ "'")
    pool

fn Driver.resolve_file(self: Driver, path: str, emit_resolve_diags: bool) -> ResolveResult:
    self.source_dir = dirname(path)
    self.current_source_path = path

    let text = with_fs_read_file(path)
    if text.len() == 0:
        with_eprintln("error: cannot open '" ++ path ++ "'")
        self.last_resolved = ResolveResult.init()
        self.resolved_root_path = path
        return self.last_resolved

    self.current_source_text = text

    var lexer = Lexer.init(text, 0)
    let tokens = lexer.tokenize()
    var parser = Parser.init(tokens, text, 0, self.pool, self.diagnostics)
    let pool = parser.parse_module()
    self.pool = parser.intern
    self.diagnostics = parser.diags

    if self.diagnostics.has_errors():
        let source = Source.from_string(path, text, 0)
        self.diagnostics.render_all(source)
        self.last_resolved = ResolveResult.init()
        self.resolved_root_path = path
        return self.last_resolved

    let artifacts = resolve_from_root_pool(path, text, 0, pool, self.pool, self.diagnostics, emit_resolve_diags)
    self.pool = artifacts.pool
    self.diagnostics = artifacts.diags
    self.last_resolved = artifacts.result
    self.resolved_root_path = path

    if emit_resolve_diags and self.diagnostics.has_errors():
        let source = Source.from_string(path, text, 0)
        self.diagnostics.render_all(source)

    self.last_resolved

// Compile from already-loaded source text.
fn Driver.compile_source(self: Driver, text: str, name: str, file_id: i32) -> AstPool:
    self.reset_pending_warnings()
    self.trace_c_import_cache = self.read_trace_c_import_cache()
    self.typed_emitted_during_compile = 0

    // Phase 1: Lex.
    var lexer = Lexer.init(text, file_id)
    let tokens = lexer.tokenize()

    // Phase 2: Parse.
    var parser = Parser.init(tokens, text, file_id, self.pool, self.diagnostics)
    var pool = parser.parse_module()
    let root_local_decl_count = count_non_use_decls(pool)
    self.last_root_decl_count = root_local_decl_count

    // Propagate parser's intern pool and diagnostics back to the driver.
    // (Struct params are passed by value, so the parser operated on copies.)
    self.pool = parser.intern
    self.diagnostics = parser.diags

    if self.diagnostics.has_errors():
        let source = Source.from_string(name, text, file_id)
        self.diagnostics.render_all(source)
        self.typed_pool_cache = AstPool.new()
        return AstPool.new()

    // Wave 4: build a deterministic resolved module graph sidecar.
    let artifacts = resolve_from_root_pool(name, text, file_id, pool, self.pool, self.diagnostics, true)
    self.pool = artifacts.pool
    self.diagnostics = artifacts.diags
    self.last_resolved = artifacts.result
    self.resolved_root_path = name
    if self.diagnostics.has_errors():
        let source = Source.from_string(name, text, file_id)
        self.diagnostics.render_all(source)
        self.last_mir_module = MirModule.init()
        self.last_mir_dump = ""
        self.last_async_mir_module = AsyncMirModule.init()
        self.last_async_mir_dump = ""
        self.typed_pool_cache = AstPool.new()
        return AstPool.new()

    // Phase 2.5: Merge resolved import modules into a single pool.
    // Use the Wave 4 resolver graph as the import oracle so nested relative
    // imports resolve from each module's own directory (not only root dir).
    pool = self.merge_resolved_modules(pool, name, text)

    // Phase 2.6: Expand c_import declarations into synthetic extern/const
    // declarations before semantic analysis.
    pool = self.expand_c_imports(pool)
    // Preserve root-module ownership boundary for orphan-rule checks.
    pool.set_local_decl_count(root_local_decl_count)
    self.typed_pool_cache = pool
    if self.diagnostics.has_errors():
        let source = Source.from_string(name, text, file_id)
        self.diagnostics.render_all(source)
        self.last_mir_module = MirModule.init()
        self.last_mir_dump = ""
        self.last_async_mir_module = AsyncMirModule.init()
        self.last_async_mir_dump = ""
        self.typed_pool_cache = AstPool.new()
        return AstPool.new()

    // Phase 3: Semantic analysis.
    var sema = Sema.init(self.pool, self.diagnostics, pool)
    sema.source_text = text
    sema.check_module()

    // Propagate sema's changes back.
    self.pool = sema.pool
    self.diagnostics = sema.diags
    self.typed_expr_types = sema.typed_expr_types
    self.typed_binding_types = sema.typed_binding_types
    self.typed_binding_names = sema.typed_binding_names
    self.typed_binding_muts = sema.typed_binding_muts
    // Keep typed sidecars for downstream stages, but build the textual typed
    // dump lazily only on explicit --dump-typed paths.
    self.last_typed_dump = ""

    if self.diagnostics.has_errors():
        sema.pool = self.pool
        self.last_sema = sema
        let source = Source.from_string(name, text, file_id)
        self.diagnostics.render_all(source)
        self.last_mir_module = MirModule.init()
        self.last_mir_dump = ""
        self.last_async_mir_module = AsyncMirModule.init()
        self.last_async_mir_dump = ""
        self.typed_pool_cache = AstPool.new()
        return AstPool.new()

    if self.emit_typed_during_compile != 0:
        sema.pool = self.pool
        sema.emit_typed_module(0)
        self.typed_emitted_during_compile = 1

    self.last_mir_module = lower_module(sema, pool, self.pool)
    self.last_mir_dump = ""
    let async_artifacts = lower_async_module(self.last_mir_module, pool, self.pool, sema, self.diagnostics)
    self.last_async_mir_module = async_artifacts.out_mod
    self.last_async_mir_dump = ""
    self.diagnostics = async_artifacts.diags
    // Lowering stages may mutate copied pool ownership; refresh cached sema
    // with the current driver pool before any future typed rendering.
    sema.pool = self.pool
    self.last_sema = sema
    self.capture_pending_warnings()

    if self.diagnostics.has_errors():
        let source = Source.from_string(name, text, file_id)
        self.diagnostics.render_all(source)
        self.typed_pool_cache = AstPool.new()
        return AstPool.new()

    if pool.decl_count() == 0:
        with_eprintln("error: parser returned an empty module without diagnostics for '" ++ name ++ "'")
        return AstPool.new()

    pool

fn Driver.reset_pending_warnings(self: Driver) -> void:
    while self.pending_warnings.len() > 0:
        self.pending_warnings.pop()
    return

fn Driver.capture_pending_warnings(self: Driver) -> void:
    self.reset_pending_warnings()
    for i in 0..self.diagnostics.items.len() as i32:
        let diag = self.diagnostics.items.get(i as i64)
        if diag.severity == DIAG_SEVERITY_WARNING():
            if diag.code.len() > 0:
                self.pending_warnings.push("warning[" ++ diag.code ++ "]: " ++ diag.message)
            else:
                self.pending_warnings.push("warning: " ++ diag.message)
    return

fn Driver.set_emit_typed_during_compile(self: Driver, enabled: i32) -> void:
    self.emit_typed_during_compile = enabled
    if enabled == 0:
        self.typed_emitted_during_compile = 0
    return

fn Driver.did_emit_typed_during_compile(self: Driver) -> i32:
    self.typed_emitted_during_compile

fn Driver.dump_typed(self: Driver, pool: AstPool) -> str:
    // Always build a fresh semantic view for textual typed dumps. Reusing a
    // cached, by-value Sema copy here can corrupt large symbol payloads under
    // repeated dump paths and lead to pathological hangs.
    var sema = Sema.init(self.pool, self.diagnostics, pool)
    sema.source_text = self.current_source_text
    if self.no_std:
        sema.no_std = 1
    if self.alloc:
        sema.alloc = 1
    sema.check_module()

    self.pool = sema.pool
    self.diagnostics = sema.diags
    self.typed_expr_types = sema.typed_expr_types
    self.typed_binding_types = sema.typed_binding_types
    self.typed_binding_names = sema.typed_binding_names
    self.typed_binding_muts = sema.typed_binding_muts
    // Keep sema's pool in sync with driver ownership before rendering.
    sema.pool = self.pool
    self.last_typed_dump = sema.dump_typed_module()
    self.last_sema = sema
    self.last_mir_dump = ""
    self.last_async_mir_module = AsyncMirModule.init()
    self.last_async_mir_dump = ""

    if self.diagnostics.has_errors():
        let source = Source.from_string(self.current_source_path, self.current_source_text, 0)
        self.diagnostics.render_all(source)
        self.last_mir_module = MirModule.init()
        self.last_async_mir_module = AsyncMirModule.init()
        return ""

    self.last_typed_dump

fn Driver.emit_typed(self: Driver, pool: AstPool) -> i32:
    // Reuse cached sema from the immediately preceding compile/check pipeline
    // when available to keep dump-typed behavior aligned with the checked AST.
    if self.last_sema.ast.decl_count() == pool.decl_count() and pool.decl_count() > 0:
        self.last_sema.emit_typed_module(0)
        return 1

    // Always run a fresh sema pass for typed emission. This avoids depending on
    // cached by-value Sema copies during dump-only paths.
    var typed_pool = pool
    if self.typed_pool_cache.decl_count() > 0:
        typed_pool = self.typed_pool_cache
    var sema = Sema.init(self.pool, self.diagnostics, typed_pool)
    sema.source_text = self.current_source_text
    if self.no_std:
        sema.no_std = 1
    if self.alloc:
        sema.alloc = 1
    sema.check_module()

    self.pool = sema.pool
    self.diagnostics = sema.diags
    self.typed_expr_types = sema.typed_expr_types
    self.typed_binding_types = sema.typed_binding_types
    self.typed_binding_names = sema.typed_binding_names
    self.typed_binding_muts = sema.typed_binding_muts
    self.last_sema = sema
    self.last_typed_dump = ""
    self.last_mir_dump = ""
    self.last_async_mir_module = AsyncMirModule.init()
    self.last_async_mir_dump = ""

    if self.diagnostics.has_errors():
        let source = Source.from_string(self.current_source_path, self.current_source_text, 0)
        self.diagnostics.render_all(source)
        self.last_mir_module = MirModule.init()
        self.last_async_mir_module = AsyncMirModule.init()
        return 0

    self.last_sema.emit_typed_module(0)
    1

fn Driver.run_mir_lower(self: Driver, pool: AstPool) -> MirModule:
    var sema = Sema.init(self.pool, self.diagnostics, pool)
    sema.source_text = self.current_source_text
    if self.no_std:
        sema.no_std = 1
    if self.alloc:
        sema.alloc = 1
    sema.check_module()

    self.pool = sema.pool
    self.diagnostics = sema.diags
    self.typed_expr_types = sema.typed_expr_types
    self.typed_binding_types = sema.typed_binding_types
    self.typed_binding_names = sema.typed_binding_names
    self.typed_binding_muts = sema.typed_binding_muts
    self.last_sema = sema

    if self.diagnostics.has_errors():
        let source = Source.from_string(self.current_source_path, self.current_source_text, 0)
        self.diagnostics.render_all(source)
        self.last_mir_module = MirModule.init()
        self.last_mir_dump = ""
        self.last_async_mir_module = AsyncMirModule.init()
        self.last_async_mir_dump = ""
        return self.last_mir_module

    self.last_mir_module = lower_module(sema, pool, self.pool)
    self.last_mir_dump = ""
    let async_artifacts = lower_async_module(self.last_mir_module, pool, self.pool, sema, self.diagnostics)
    self.last_async_mir_module = async_artifacts.out_mod
    self.last_async_mir_dump = ""
    self.diagnostics = async_artifacts.diags
    self.last_mir_module

fn Driver.run_async_mir_lower(self: Driver, pool: AstPool) -> AsyncMirModule:
    let _ = self.run_mir_lower(pool)
    if self.diagnostics.has_errors():
        self.last_async_mir_module = AsyncMirModule.init()
        self.last_async_mir_dump = ""
        return self.last_async_mir_module
    self.last_async_mir_module

fn Driver.dump_mir(self: Driver, pool: AstPool) -> str:
    if self.last_mir_module.body_count() == 0:
        let _ = self.run_mir_lower(pool)

    self.last_mir_dump = dump_mir_module(self.last_mir_module, self.pool, self.last_sema)
    self.last_mir_dump

fn Driver.print_mir(self: Driver, pool: AstPool) -> bool:
    if self.last_mir_module.body_count() == 0:
        let _ = self.run_mir_lower(pool)
    if self.last_mir_module.body_count() == 0:
        return false
    print_mir_module(self.last_mir_module, self.pool, self.last_sema)
    true

fn Driver.dump_async_mir(self: Driver, pool: AstPool) -> str:
    if self.last_async_mir_module.body_count() == 0:
        let _ = self.run_async_mir_lower(pool)
    if self.last_async_mir_module.body_count() == 0:
        return ""
    self.last_async_mir_dump = dump_async_mir_module(self.last_async_mir_module, self.pool)
    self.last_async_mir_dump

// ── Codegen + link ───────────────────────────────────────────────

fn Driver.ensure_codegen_mir(self: Driver, pool: AstPool) -> bool:
    if self.last_mir_module.body_count() == 0:
        let _ = self.run_mir_lower(pool)
    if self.diagnostics.has_errors():
        return false
    self.last_mir_module.body_count() > 0

// Compile a module to an object file. Returns 0 on success, 1 on failure.
fn Driver.compile_to_object(self: Driver, pool: AstPool, output_path: str) -> i32:
    if not self.ensure_codegen_mir(pool):
        with_eprintln("error: code generation failed")
        return 1
    var cg = Codegen.init("with_module")
    cg.source_file = self.current_source_path
    cg.source_text = self.current_source_text
    cg.intern = self.pool
    let result = cg.gen_module_from_mir(self.last_mir_module, pool)
    if result != 0:
        with_eprintln("error: code generation failed")
        return 1
    if self.opt_level > 0:
        cg.optimize(self.opt_level)
    let emit_result = cg.emit_object_file(output_path)
    if emit_result != 0:
        with_eprintln("error: failed to emit object file")
        return 1
    0

// Dump LLVM IR to stdout.
fn Driver.emit_ir(self: Driver, pool: AstPool) -> bool:
    if not self.ensure_codegen_mir(pool):
        with_eprintln("error: code generation failed")
        return false
    var cg = Codegen.init("with_module")
    cg.source_file = self.current_source_path
    cg.source_text = self.current_source_text
    cg.intern = self.pool
    let result = cg.gen_module_from_mir(self.last_mir_module, pool)
    if result != 0:
        with_eprintln("error: code generation failed")
        return false
    cg.print_ir()
    true

// Link an object file into a binary using the system linker.
fn link(obj_path: str, bin_path: str) -> bool:
    let extras: Vec[str] = Vec.new()
    let link_libs: Vec[str] = Vec.new()
    link_with_extras_and_libs(obj_path, bin_path, extras, link_libs)

// Link with extra object files.
fn link_with_extras(obj_path: str, bin_path: str, extras: Vec[str]) -> bool:
    let link_libs: Vec[str] = Vec.new()
    link_with_extras_and_libs(obj_path, bin_path, extras, link_libs)

// Link with extra object files and explicit -l<name> directives.
fn link_with_extras_and_libs(obj_path: str, bin_path: str, extras: Vec[str], link_libs: Vec[str]) -> bool:
    var cmd = "cc " ++ obj_path
    for i in 0..extras.len() as i32:
        cmd = cmd ++ " " ++ extras.get(i as i64)
    cmd = cmd ++ " -o " ++ bin_path
    for i in 0..link_libs.len() as i32:
        cmd = cmd ++ " -l" ++ link_libs.get(i as i64)
    let result = cmd |> with_system
    result == 0

fn str_contains(hay: str, needle: str) -> bool:
    let hay_len = hay.len() as i32
    let needle_len = needle.len() as i32
    if needle_len <= 0:
        return true
    if hay_len < needle_len:
        return false

    var i = 0
    while i <= hay_len - needle_len:
        var matched = true
        var j = 0
        while j < needle_len:
            if hay.byte_at((i + j) as i64) != needle.byte_at(j as i64):
                matched = false
                break
            j = j + 1
        if matched:
            return true
        i = i + 1
    false

fn undefined_symbols_for_object(obj_path: str) -> str:
    let report_path = obj_path ++ ".undef"
    let probe_cmd = "nm -u " ++ obj_path ++ " > " ++ report_path ++ " 2>/dev/null"
    let probe_rc = probe_cmd |> with_system
    if probe_rc != 0:
        let _ = ("rm -f " ++ report_path) |> with_system
        return "<probe-failed>"
    let symbols = with_fs_read_file(report_path)
    let _ = ("rm -f " ++ report_path) |> with_system
    symbols

fn object_needs_helpers_runtime(obj_path: str) -> i32:
    // Probe the unresolved symbol set first; this lets us avoid linking helpers
    // into binaries that do not reference runtime helper symbols.
    let undef = undefined_symbols_for_object(obj_path)
    if undef == "<probe-failed>":
        // Keep prior behavior if symbol probing is unavailable.
        return 1
    if undef.len() == 0:
        return 0
    if str_contains(undef, "_with_"):
        return 1
    if str_contains(undef, "_int_to_string"):
        return 1
    if str_contains(undef, "_i32_to_str"):
        return 1
    if str_contains(undef, "_str_from_byte"):
        return 1
    0

fn object_needs_fiber_runtime(obj_path: str) -> i32:
    // Channel runtime symbols are implemented in runtime/fiber.o.
    // Keep this symbol-probe path narrow so sync-only programs avoid
    // unnecessary fiber runtime linkage.
    let undef = undefined_symbols_for_object(obj_path)
    if undef == "<probe-failed>":
        return 0
    if undef.len() == 0:
        return 0
    if str_contains(undef, "_with_channel_"):
        return 1
    0

fn compiler_runtime_dir() -> str:
    let argv0 = with_arg_at(0)
    if argv0.len() == 0:
        return "runtime"
    dirname(argv0) ++ "/runtime"

fn find_llvm_bridge_path() -> str:
    let p1 = compiler_runtime_dir() ++ "/libwith_llvm_bridge.dylib"
    if with_fs_read_file(p1).len() > 0:
        return p1

    let p2 = "bootstrap/zig-out/bin/runtime/libwith_llvm_bridge.dylib"
    if with_fs_read_file(p2).len() > 0:
        return p2

    let p3 = "runtime/libwith_llvm_bridge.dylib"
    if with_fs_read_file(p3).len() > 0:
        return p3

    ""

fn find_runtime_object_path(name: str) -> str:
    let p1 = compiler_runtime_dir() ++ "/" ++ name
    if with_fs_read_file(p1).len() > 0:
        return p1

    let p2 = "bootstrap/zig-out/bin/runtime/" ++ name
    if with_fs_read_file(p2).len() > 0:
        return p2

    let p3 = "runtime/" ++ name
    if with_fs_read_file(p3).len() > 0:
        return p3

    ""

fn should_link_llvm_bridge(source_path: str) -> bool:
    source_path == "src/main.w" or source_path.ends_with("/src/main.w") or source_path.ends_with("\\src\\main.w")

fn Driver.collect_link_libs(self: Driver) -> Vec[str]:
    let out: Vec[str] = Vec.new()
    for li in 0..self.last_resolved.link_libs.len() as i32:
        let lib_sym = self.last_resolved.link_libs.get(li as i64)
        let lib_name = self.pool.resolve(lib_sym)
        if lib_name.len() > 0:
            out.push(lib_name)
    out

// Full pipeline: parse → codegen → link → binary.
// Returns the output binary path on success, "" on failure.
fn Driver.build_binary(self: Driver, source_path: str) -> str:
    let dir = dirname(source_path)
    self.build_binary_at(source_path, dir)

fn Driver.build_binary_at(self: Driver, source_path: str, output_dir: str) -> str:
    if should_delegate_compiler_build(source_path):
        // Stage bootstrap fallback: delegate self-host compiler rebuilds to
        // the bootstrap compiler while Stage1 codegen remains unstable.
        let rc = ("bootstrap/zig-out/bin/with build " ++ source_path) |> with_system
        if rc != 0:
            with_eprintln("error: bootstrap fallback build failed")
            return ""
        let built = ".with/build/main"
        if with_fs_read_file(built).len() == 0:
            with_eprintln("error: bootstrap fallback did not produce .with/build/main")
            return ""
        return built

    let pool = self.compile_file(source_path)
    if pool.decl_count() == 0:
        return ""

    let stem = source_stem(source_path)
    let obj_path = output_dir ++ "/" ++ stem ++ ".o"
    let bin_path = output_dir ++ "/" ++ stem

    let result = self.compile_to_object(pool, obj_path)
    if result != 0:
        return ""

    let link_libs = self.collect_link_libs()
    let extras: Vec[str] = Vec.new()

    // Async runtime objects are linked only when Async-MIR indicates async
    // suspension/runtime operations are present.
    let needs_async_runtime = self.last_async_mir_module.requires_async_runtime()
    let needs_fiber_runtime = if needs_async_runtime: 1 else: object_needs_fiber_runtime(obj_path)
    if needs_fiber_runtime != 0:
        let fiber_path = find_runtime_object_path("fiber.o")
        if fiber_path.len() == 0:
            with_eprintln("error: missing runtime/fiber.o")
            return ""
        extras.push(fiber_path)
        let fiber_asm_path = find_runtime_object_path("fiber_asm.o")
        if fiber_asm_path.len() == 0:
            with_eprintln("error: missing runtime/fiber_asm.o")
            return ""
        extras.push(fiber_asm_path)

    // Link helpers runtime object only when object symbols require it.
    let needs_helpers_runtime = object_needs_helpers_runtime(obj_path)
    if needs_helpers_runtime != 0:
        let helpers_path = find_runtime_object_path("helpers.o")
        if helpers_path.len() == 0:
            with_eprintln("error: missing runtime/helpers.o")
            return ""
        extras.push(helpers_path)

    if should_link_llvm_bridge(source_path):
        let bridge_path = find_llvm_bridge_path()
        if bridge_path.len() == 0:
            with_eprintln("error: missing runtime/libwith_llvm_bridge.dylib")
            return ""
        extras.push(bridge_path)
    let link_ok = if extras.len() > 0 or link_libs.len() > 0:
        link_with_extras_and_libs(obj_path, bin_path, extras, link_libs)
    else:
        link(obj_path, bin_path)
    if not link_ok:
        with_eprintln("error: linking failed")
        return ""

    // Clean up .o file
    with_system("rm -f " ++ obj_path)
    bin_path

fn should_delegate_compiler_build(source_path: str) -> bool:
    source_path == "src/main.w" or source_path.ends_with("/src/main.w") or source_path.ends_with("\\src\\main.w")

// ── Import resolution ────────────────────────────────────────────

fn count_non_use_decls(pool: AstPool) -> i32:
    var count = 0
    for di in 0..pool.decl_count():
        let decl = pool.get_decl(di)
        if pool.kind(decl) != NK_USE_DECL():
            count = count + 1
    count

fn Driver.recompute_root_decl_count(self: Driver) -> i32:
    if self.current_source_text.len() == 0:
        return 0
    var lexer = Lexer.init(self.current_source_text, 0)
    let tokens = lexer.tokenize()
    var parser = Parser.init(tokens, self.current_source_text, 0, self.pool, self.diagnostics)
    let root_pool = parser.parse_module()
    count_non_use_decls(root_pool)

fn Driver.merge_resolved_modules(self: Driver, root_pool: AstPool, root_path: str, root_text: str) -> AstPool:
    var merged_pool = root_pool

    // Merge every resolved module exactly once in deterministic module-id
    // order; module 0 is the root module that is already parsed.
    for mi in 0..self.last_resolved.modules.len() as i32:
        let mod = self.last_resolved.modules.get(mi as i64)
        if mod.module_id == 0:
            continue

        let path = mod.path
        if path.len() == 0 or path == root_path:
            continue

        let text = with_fs_read_file(path)
        if text.len() == 0:
            let span = Span { file: 0, start: 0, end: 0 }
            self.diagnostics.emit(Diagnostic.err("failed to read imported module", span))
            continue

        var lexer = Lexer.init(text, mod.file_id)
        let tokens = lexer.tokenize()
        var parser = Parser.init_with_pool(tokens, text, mod.file_id, self.pool, self.diagnostics, merged_pool)
        merged_pool = parser.parse_module()
        self.pool = parser.intern
        self.diagnostics = parser.diags
    self.strip_use_decls(merged_pool)

fn Driver.strip_use_decls(self: Driver, pool: AstPool) -> AstPool:
    var out = pool
    var has_use = 0
    for i in 0..out.decl_count():
        let decl = out.get_decl(i)
        if out.kind(decl) == NK_USE_DECL():
            has_use = 1
            break
    if has_use == 0:
        return out

    let ordered: Vec[i32] = Vec.new()
    for i in 0..out.decl_count():
        let decl = out.get_decl(i)
        if out.kind(decl) != NK_USE_DECL():
            ordered.push(decl)

    while out.decl_count() > 0:
        out.decls.pop()
    for oi in 0..ordered.len() as i32:
        out.add_decl(ordered.get(oi as i64))
    out

fn Driver.read_trace_c_import_cache(self: Driver) -> i32:
    let raw = with_getenv_str("WITH_TRACE_CIMPORT_CACHE")
    if raw.len() == 0:
        return 0
    if raw == "0":
        return 0
    1

fn Driver.expand_c_imports(self: Driver, pool: AstPool) -> AstPool:
    var out = pool
    let ordered: Vec[i32] = Vec.new()
    let base_count = out.decl_count()
    var has_c_import = 0
    for i in 0..base_count:
        let decl = out.get_decl(i)
        if out.kind(decl) == NK_C_IMPORT():
            has_c_import = 1
            break
    if has_c_import == 0:
        return out

    for i in 0..base_count:
        let decl = out.get_decl(i)
        if out.kind(decl) != NK_C_IMPORT():
            ordered.push(decl)
            continue

        let header_sym = out.get_data0(decl)
        let header_spec = self.pool.resolve(header_sym)
        let cache_key = self.c_import_cache_key(out, decl, header_spec)

        var synthetic = ""
        let cached = self.c_import_cache.get(cache_key)
        if cached.is_some():
            if self.trace_c_import_cache != 0:
                with_eprintln("c_import cache hit")
            synthetic = cached.unwrap()
        else:
            if self.trace_c_import_cache != 0:
                with_eprintln("c_import cache miss")
            synthetic = self.c_import_expand_header_spec(header_spec, decl)
            if self.diagnostics.has_errors():
                continue
            self.c_import_cache.insert(cache_key, synthetic)

        if synthetic.len() == 0:
            continue

        let before = out.decl_count()
        var lexer = Lexer.init(synthetic, 0)
        let tokens = lexer.tokenize()
        var parser = Parser.init_with_pool(tokens, synthetic, 0, self.pool, self.diagnostics, out)
        out = parser.parse_module()
        self.pool = parser.intern
        self.diagnostics = parser.diags

        let after = out.decl_count()
        var di = before
        while di < after:
            ordered.push(out.get_decl(di))
            di = di + 1

    while out.decl_count() > 0:
        out.decls.pop()
    for oi in 0..ordered.len() as i32:
        out.add_decl(ordered.get(oi as i64))
    out

fn Driver.c_import_cache_key(self: Driver, pool: AstPool, decl: i32, header_spec: str) -> str:
    var key = header_spec ++ "\n#links:"
    let link_start = pool.get_data1(decl)
    let link_count = pool.get_data2(decl)
    for li in 0..link_count:
        let lib_sym = pool.get_extra(link_start + li)
        key = key ++ "|" ++ self.pool.resolve(lib_sym)
    let epoch = with_getenv_str("WITH_CIMPORT_CACHE_EPOCH")
    if epoch.len() > 0:
        key = key ++ "\n#epoch:" ++ epoch
    key

fn Driver.c_import_emit_header_error(self: Driver, decl: i32, header_spec: str):
    let span = Span {
        file: 0,
        start: self.current_source_text.len() as i32,
        end: self.current_source_text.len() as i32,
    }
    let msg = if header_spec.len() > 0:
        "failed to compile C header snippet: " ++ header_spec
    else:
        "failed to compile C header snippet"
    self.diagnostics.emit(Diagnostic.err(msg, span))

fn Driver.c_import_expand_header_spec(self: Driver, header_spec_raw: str, decl: i32) -> str:
    let decoded = c_import_decode_escapes(header_spec_raw)
    let rendered = c_import_render_header_spec(decoded)
    let header = c_import_trim(rendered)
    if header.len() == 0:
        self.c_import_emit_header_error(decl, header_spec_raw)
        return ""

    var generated = ""
    var body = ""

    var line_start = 0
    var i = 0
    let total = header.len() as i32
    while i <= total:
        if i == total or header.byte_at(i as i64) == 10:
            let raw_line = header.slice(line_start as i64, i as i64)
            let line = c_import_trim(raw_line)
            if line.len() > 0:
                if c_import_starts_with(line, "#include"):
                    let inc = self.c_import_include_decls(line, decl, header_spec_raw)
                    if self.diagnostics.has_errors():
                        return ""
                    generated = generated ++ inc
                else if c_import_starts_with(line, "#define"):
                    generated = generated ++ c_import_macro_decl(line)
                else:
                    body = body ++ line ++ "\n"
            line_start = i + 1
        i = i + 1

    var stmt_start = 0
    var si = 0
    let body_len = body.len() as i32
    while si <= body_len:
        if si == body_len or body.byte_at(si as i64) == 59:
            let stmt = c_import_trim(body.slice(stmt_start as i64, si as i64))
            if stmt.len() > 0:
                let fn_decl = c_import_function_decl(stmt)
                if fn_decl.len() == 0:
                    self.c_import_emit_header_error(decl, header_spec_raw)
                    return ""
                generated = generated ++ fn_decl
            stmt_start = si + 1
        si = si + 1

    generated

fn Driver.c_import_include_decls(self: Driver, line: str, decl: i32, header_spec_raw: str) -> str:
    let rest = c_import_trim(line.slice(8, line.len()))
    if rest.len() < 3:
        self.c_import_emit_header_error(decl, header_spec_raw)
        return ""

    var header_name = ""
    let first = rest.byte_at(0)
    let last = rest.byte_at(rest.len() as i64 - 1)
    if first == 60 and last == 62:  // <...>
        header_name = rest.slice(1, rest.len() - 1)
    else if first == 34 and last == 34:  // "..."
        header_name = rest.slice(1, rest.len() - 1)
    else:
        self.c_import_emit_header_error(decl, header_spec_raw)
        return ""

    if header_name == "stdio.h":
        return "extern fn puts(p0: *const i8) -> i32\n" ++
               "extern fn printf(p0: *const i8, ...) -> i32\n" ++
               "extern fn fopen(p0: *const i8, p1: *const i8) -> *const i8\n" ++
               "extern fn fclose(p0: *const i8) -> i32\n" ++
               "extern fn fputs(p0: *const i8, p1: *const i8) -> i32\n" ++
               "extern fn fread(p0: *const i8, p1: i64, p2: i64, p3: *const i8) -> i64\n" ++
               "extern fn remove(p0: *const i8) -> i32\n" ++
               "extern fn rename(p0: *const i8, p1: *const i8) -> i32\n"
    if header_name == "string.h":
        return "extern fn strlen(p0: *const i8) -> i64\n" ++
               "extern fn strcmp(p0: *const i8, p1: *const i8) -> i32\n" ++
               "extern fn memcpy(p0: *const i8, p1: *const i8, p2: i64) -> *const i8\n" ++
               "extern fn memmove(p0: *const i8, p1: *const i8, p2: i64) -> *const i8\n" ++
               "extern fn memset(p0: *const i8, p1: i32, p2: i64) -> *const i8\n" ++
               "extern fn memcmp(p0: *const i8, p1: *const i8, p2: i64) -> i32\n"
    if header_name == "stdlib.h":
        return "extern fn malloc(p0: i64) -> *const i8\n" ++
               "extern fn free(p0: *const i8) -> void\n" ++
               "extern fn calloc(p0: i64, p1: i64) -> *const i8\n" ++
               "extern fn realloc(p0: *const i8, p1: i64) -> *const i8\n" ++
               "extern fn atol(p0: *const i8) -> i64\n" ++
               "extern fn rand() -> i32\n" ++
               "extern fn srand(p0: i32) -> void\n"
    if header_name == "unistd.h":
        return "extern fn access(p0: *const i8, p1: i32) -> i32\n" ++
               "extern fn rmdir(p0: *const i8) -> i32\n"
    if header_name == "sys/stat.h":
        return "extern fn mkdir(p0: *const i8, p1: u16) -> i32\n"
    if header_name == "ctype.h":
        return "extern fn isalpha(p0: i32) -> i32\n" ++
               "extern fn isdigit(p0: i32) -> i32\n" ++
               "extern fn isspace(p0: i32) -> i32\n"
    if header_name == "math.h":
        return "extern fn sqrt(p0: f64) -> f64\n" ++
               "extern fn pow(p0: f64, p1: f64) -> f64\n" ++
               "extern fn floor(p0: f64) -> f64\n" ++
               "extern fn ceil(p0: f64) -> f64\n" ++
               "extern fn round(p0: f64) -> f64\n" ++
               "extern fn sin(p0: f64) -> f64\n" ++
               "extern fn cos(p0: f64) -> f64\n" ++
               "extern fn tan(p0: f64) -> f64\n" ++
               "extern fn log(p0: f64) -> f64\n" ++
               "extern fn log10(p0: f64) -> f64\n" ++
               "extern fn exp(p0: f64) -> f64\n" ++
               "extern fn fabs(p0: f64) -> f64\n" ++
               "extern fn fmod(p0: f64, p1: f64) -> f64\n" ++
               "extern fn asin(p0: f64) -> f64\n" ++
               "extern fn acos(p0: f64) -> f64\n" ++
               "extern fn atan(p0: f64) -> f64\n" ++
               "extern fn atan2(p0: f64, p1: f64) -> f64\n"

    self.c_import_emit_header_error(decl, header_spec_raw)
    ""

fn c_import_render_header_spec(spec_raw: str) -> str:
    let spec = c_import_trim(spec_raw)
    if spec.len() == 0:
        return ""

    let has_newline = str_contains(spec, "\n")
    let has_directive = c_import_starts_with(spec, "#")
    let has_statement = str_contains(spec, ";")
    if has_newline or has_directive or has_statement:
        return spec

    let first = spec.byte_at(0)
    let last = spec.byte_at(spec.len() as i64 - 1)
    if (first == 60 and last == 62) or (first == 34 and last == 34):
        return "#include " ++ spec
    "#include <" ++ spec ++ ">"

fn c_import_macro_decl(line: str) -> str:
    var rest = line
    if c_import_starts_with(rest, "#define"):
        rest = c_import_trim(rest.slice(7, rest.len()))
    else:
        return ""
    if rest.len() == 0:
        return ""

    var i = 0
    while i < rest.len() as i32 and c_import_is_ident_char(rest.byte_at(i as i64)):
        i = i + 1
    if i <= 0:
        return ""
    let name = rest.slice(0, i as i64)
    if i < rest.len() as i32 and rest.byte_at(i as i64) == 40:  // function-like macro
        return ""

    var value = c_import_trim(rest.slice(i as i64, rest.len()))
    if value.len() == 0:
        return ""
    value = c_import_trim_outer_parens(value)

    if c_import_is_int_literal(value):
        return "let " ++ name ++ " = " ++ value ++ "\n"

    if value.len() >= 2 and value.byte_at(0) == 34 and value.byte_at(value.len() as i64 - 1) == 34:
        let inner = value.slice(1, value.len() - 1)
        let escaped = c_import_escape_with_string(inner)
        return "let " ++ name ++ " = \"" ++ escaped ++ "\"\n"

    ""

fn c_import_function_decl(stmt_raw: str) -> str:
    let stmt = c_import_trim(stmt_raw)
    if stmt.len() == 0:
        return ""

    var open = 0 - 1
    var close = 0 - 1
    for i in 0..stmt.len() as i32:
        let ch = stmt.byte_at(i as i64)
        if ch == 40 and open < 0:  // (
            open = i
        if ch == 41:  // )
            close = i
    if open <= 0 or close <= open:
        return ""

    let trailing = c_import_trim(stmt.slice((close + 1) as i64, stmt.len()))
    if trailing.len() > 0:
        return ""

    var ne = open - 1
    while ne >= 0 and c_import_is_space(stmt.byte_at(ne as i64)):
        ne = ne - 1
    if ne < 0:
        return ""
    var ns = ne
    while ns >= 0 and c_import_is_ident_char(stmt.byte_at(ns as i64)):
        ns = ns - 1
    ns = ns + 1
    if ns > ne:
        return ""

    let fn_name = stmt.slice(ns as i64, (ne + 1) as i64)
    let ret_spec = c_import_trim(stmt.slice(0, ns as i64))
    if ret_spec.len() == 0:
        return ""
    let ret_ty = c_import_map_c_type(ret_spec)

    let params_text = c_import_trim(stmt.slice((open + 1) as i64, close as i64))
    var params_out = ""
    var has_variadic = 0
    var param_index = 0
    if params_text.len() > 0 and params_text != "void":
        var seg_start = 0
        var i = 0
        let plen = params_text.len() as i32
        while i <= plen:
            if i == plen or params_text.byte_at(i as i64) == 44:  // ,
                let seg = c_import_trim(params_text.slice(seg_start as i64, i as i64))
                if seg.len() > 0:
                    if seg == "...":
                        has_variadic = 1
                    else:
                        let pty = c_import_param_type(seg)
                        if pty.len() == 0:
                            return ""
                        if params_out.len() > 0:
                            params_out = params_out ++ ", "
                        params_out = params_out ++ "p" ++ int_to_string(param_index) ++ ": " ++ pty
                        param_index = param_index + 1
                seg_start = i + 1
            i = i + 1

    if has_variadic != 0:
        if params_out.len() > 0:
            params_out = params_out ++ ", ..."
        else:
            params_out = "..."

    "extern fn " ++ fn_name ++ "(" ++ params_out ++ ") -> " ++ ret_ty ++ "\n"

fn c_import_param_type(param_raw: str) -> str:
    var param = c_import_trim_outer_parens(c_import_trim(param_raw))
    if param.len() == 0:
        return ""
    if param == "void":
        return ""

    let len = param.len() as i32
    var end = len - 1
    while end >= 0 and c_import_is_space(param.byte_at(end as i64)):
        end = end - 1

    var type_spec = param
    if end >= 0 and c_import_is_ident_char(param.byte_at(end as i64)):
        var j = end
        while j >= 0 and c_import_is_ident_char(param.byte_at(j as i64)):
            j = j - 1
        let prefix = c_import_trim(param.slice(0, (j + 1) as i64))
        if prefix.len() > 0:
            type_spec = prefix

    c_import_map_c_type(type_spec)

fn c_import_map_c_type(spec_raw: str) -> str:
    let spec = c_import_trim(spec_raw)
    if spec.len() == 0:
        return "i32"

    var star_count = 0
    for i in 0..spec.len() as i32:
        if spec.byte_at(i as i64) == 42:  // *
            star_count = star_count + 1

    var base = "i32"
    if str_contains(spec, "unsigned long long"):
        base = "u64"
    else if str_contains(spec, "unsigned long"):
        base = "u64"
    else if str_contains(spec, "long long"):
        base = "i64"
    else if str_contains(spec, "size_t"):
        base = "u64"
    else if str_contains(spec, "unsigned int"):
        base = "u32"
    else if str_contains(spec, "unsigned short"):
        base = "u16"
    else if str_contains(spec, "unsigned char"):
        base = "u8"
    else if str_contains(spec, "short"):
        base = "i16"
    else if str_contains(spec, "char"):
        base = "i8"
    else if str_contains(spec, "double"):
        base = "f64"
    else if str_contains(spec, "float"):
        base = "f32"
    else if str_contains(spec, "long"):
        base = "i64"
    else if str_contains(spec, "void"):
        base = "void"
    else if str_contains(spec, "int"):
        base = "i32"

    if star_count <= 0:
        return base

    var inner = base
    if inner == "void":
        inner = "i8"
    var out = inner
    for i in 0..star_count:
        out = "*const " ++ out
    out

fn c_import_decode_escapes(raw: str) -> str:
    var out = ""
    var i = 0
    let len = raw.len() as i32
    while i < len:
        let ch = raw.byte_at(i as i64)
        if ch != 92 or i + 1 >= len:  // '\'
            out = out ++ raw.slice(i as i64, (i + 1) as i64)
            i = i + 1
            continue

        let esc = raw.byte_at((i + 1) as i64)
        if esc == 110:  // n
            out = out ++ "\n"
        else if esc == 114:  // r
            out = out ++ "\r"
        else if esc == 116:  // t
            out = out ++ "\t"
        else if esc == 92:  // \
            out = out ++ "\\"
        else if esc == 34:  // "
            out = out ++ "\""
        else:
            out = out ++ raw.slice((i + 1) as i64, (i + 2) as i64)
        i = i + 2
    out

fn c_import_trim_outer_parens(value_raw: str) -> str:
    var v = c_import_trim(value_raw)
    while v.len() >= 2 and v.byte_at(0) == 40 and v.byte_at(v.len() as i64 - 1) == 41:  // (...)
        v = c_import_trim(v.slice(1, v.len() - 1))
    v

fn c_import_escape_with_string(value: str) -> str:
    var out = ""
    for i in 0..value.len() as i32:
        let ch = value.byte_at(i as i64)
        if ch == 92:  // \
            out = out ++ "\\\\"
        else if ch == 34:  // "
            out = out ++ "\\\""
        else if ch == 10:
            out = out ++ "\\n"
        else if ch == 13:
            out = out ++ "\\r"
        else if ch == 9:
            out = out ++ "\\t"
        else:
            out = out ++ value.slice(i as i64, (i + 1) as i64)
    out

fn c_import_is_int_literal(text_raw: str) -> i32:
    let text = c_import_trim(text_raw)
    if text.len() == 0:
        return 0

    var i = 0
    if text.byte_at(0) == 45 or text.byte_at(0) == 43:  // +/- 
        i = 1
    if i >= text.len() as i32:
        return 0

    if i + 1 < text.len() as i32 and text.byte_at(i as i64) == 48 and (text.byte_at((i + 1) as i64) == 120 or text.byte_at((i + 1) as i64) == 88):
        i = i + 2
        if i >= text.len() as i32:
            return 0
        while i < text.len() as i32:
            let ch = text.byte_at(i as i64)
            let is_digit = ch >= 48 and ch <= 57
            let is_hex_lo = ch >= 97 and ch <= 102
            let is_hex_hi = ch >= 65 and ch <= 70
            if not (is_digit or is_hex_lo or is_hex_hi):
                return 0
            i = i + 1
        return 1

    while i < text.len() as i32:
        let ch = text.byte_at(i as i64)
        if ch < 48 or ch > 57:
            return 0
        i = i + 1
    1

fn c_import_is_space(ch: i32) -> bool:
    ch == 32 or ch == 9 or ch == 10 or ch == 13

fn c_import_trim(s: str) -> str:
    var start = 0
    var end = s.len() as i32
    while start < end and c_import_is_space(s.byte_at(start as i64)):
        start = start + 1
    while end > start and c_import_is_space(s.byte_at((end - 1) as i64)):
        end = end - 1
    s.slice(start as i64, end as i64)

fn c_import_starts_with(text: str, prefix: str) -> bool:
    if prefix.len() > text.len():
        return false
    text.slice(0, prefix.len()) == prefix

fn c_import_is_ident_char(ch: i32) -> bool:
    let is_alpha = (ch >= 65 and ch <= 90) or (ch >= 97 and ch <= 122)
    let is_digit = ch >= 48 and ch <= 57
    is_alpha or is_digit or ch == 95

fn Driver.process_imports(self: Driver, pool: AstPool, source_text: str) -> AstPool:
    // Keep declaration order stable by replacing each `use` with imported decls.
    var merged_pool = pool
    let base_count = merged_pool.decl_count()

    var base_decls: Vec[i32] = Vec.new()
    for bi in 0..base_count:
        base_decls.push(merged_pool.get_decl(bi))

    var ordered: Vec[i32] = Vec.new()
    for i in 0..base_count:
        let decl = base_decls.get(i as i64)
        let kind = merged_pool.kind(decl)
        if kind != NK_USE_DECL():
            ordered.push(decl)
            continue

        let path_start = merged_pool.get_data0(decl)
        let path_count = merged_pool.get_data1(decl)
        if path_count <= 0:
            continue

        let path_name = self.use_path_name(merged_pool, path_start, path_count)
        let file_path = self.resolve_module_path(path_name)
        if file_path.len() == 0:
            // Emit error matching Stage0 behavior: import module not found.
            let span = Span {
                file: 0,
                start: merged_pool.get_start(decl),
                end: merged_pool.get_end(decl),
            }
            self.diagnostics.emit(Diagnostic.err("import module not found", span))
            continue

        if self.imported_paths.contains(file_path):
            continue

        self.imported_paths.insert(file_path, 1)
        let before = merged_pool.decl_count()
        merged_pool = self.parse_imported_file(file_path, merged_pool)
        let after = merged_pool.decl_count()
        var di = before
        while di < after:
            ordered.push(merged_pool.get_decl(di))
            di = di + 1

    // Rebuild decl list in-place to avoid replacing Vec ownership.
    while merged_pool.decl_count() > 0:
        merged_pool.decls.pop()
    for oi in 0..ordered.len() as i32:
        merged_pool.add_decl(ordered.get(oi as i64))
    merged_pool

fn Driver.use_path_name(self: Driver, pool: AstPool, path_start: i32, path_count: i32) -> str:
    var path = ""
    for pi in 0..path_count:
        if pi > 0:
            path = path ++ "/"
        let seg = pool.get_extra(path_start + pi)
        path = path ++ self.pool.resolve(seg)
    path

fn Driver.resolve_module_path(self: Driver, module_name: str) -> str:
    let module_rel = normalize_module_path(module_name)
    let primary = module_rel ++ ".w"
    let path1 = resolve_module_rel_from(self.source_dir, primary)
    if path1.len() > 0:
        return path1

    // Item-import fallback:
    // use std.time.Duration -> try std/time.w if std/time/Duration.w is missing.
    let fallback = module_item_fallback(module_rel)
    if fallback.len() > 0:
        let path2 = resolve_module_rel_from(self.source_dir, fallback ++ ".w")
        if path2.len() > 0:
            return path2

    ""

fn normalize_module_path(module_name: str) -> str:
    var out = ""
    for i in 0..module_name.len():
        if module_name[i] == 46: // '.'
            out = out ++ "/"
        else:
            out = out ++ module_name.slice(i as i64, (i + 1) as i64)
    out

fn module_item_fallback(module_rel: str) -> str:
    var last_slash = -1
    for i in 0..module_rel.len():
        if module_rel[i] == 47:
            last_slash = i as i32
    if last_slash <= 0:
        return ""
    module_rel.slice(0, last_slash as i64)

fn resolve_module_rel_from(source_dir: str, rel_path: str) -> str:
    // Strategy 1: relative to current source directory.
    let cand1 = resolve_join(source_dir, rel_path)
    if resolve_file_exists(cand1):
        return cand1

    // Strategy 2: walk upward and probe lib/<rel_path>.
    var cur = source_dir
    while true:
        let cand = resolve_join(resolve_join(cur, "lib"), rel_path)
        if resolve_file_exists(cand):
            return cand
        let parent = dirname(cur)
        if parent == cur:
            break
        cur = parent

    // Strategy 3/4: project root by build.zig, then lib/ and src/.
    let root = find_project_root(source_dir)
    if root.len() > 0:
        let cand3 = resolve_join(resolve_join(root, "lib"), rel_path)
        if resolve_file_exists(cand3):
            return cand3
        let cand4 = resolve_join(resolve_join(root, "src"), rel_path)
        if resolve_file_exists(cand4):
            return cand4

    // Strategy 5: src/<rel_path> from cwd.
    let cand5 = resolve_join("src", rel_path)
    if resolve_file_exists(cand5):
        return cand5

    // Strategy 6: lib/<rel_path> from cwd.
    let cand6 = resolve_join("lib", rel_path)
    if resolve_file_exists(cand6):
        return cand6

    ""

fn find_project_root(start_dir: str) -> str:
    var cur = start_dir
    while true:
        let build_file = resolve_join(cur, "build.zig")
        if resolve_file_exists(build_file):
            return cur
        let parent = dirname(cur)
        if parent == cur:
            break
        cur = parent
    ""

fn resolve_file_exists(path: str) -> bool:
    with_fs_read_file(path).len() > 0

fn resolve_join(a: str, b: str) -> str:
    if a.len() == 0:
        return b
    if b.len() == 0:
        return a
    if a == ".":
        return b
    if a.ends_with("/"):
        return a ++ b
    a ++ "/" ++ b

fn Driver.parse_imported_file(self: Driver, path: str, target_pool: AstPool) -> AstPool:
    let text = with_fs_read_file(path)
    if text.len() == 0:
        return target_pool

    let file_id = self.next_file_id
    self.next_file_id = self.next_file_id + 1

    var lexer = Lexer.init(text, file_id)
    let tokens = lexer.tokenize()

    var parser = Parser.init_with_pool(tokens, text, file_id, self.pool, self.diagnostics, target_pool)
    let merged_pool = parser.parse_module()
    self.pool = parser.intern
    self.diagnostics = parser.diags
    merged_pool

// ── Helpers ──────────────────────────────────────────────────────

fn dirname(path: str) -> str:
    var last_slash = -1
    for i in 0..path.len():
        if path[i] == 47: // '/'
            last_slash = i as i32
    if last_slash < 0:
        return "."
    path.slice(0, last_slash as i64)

fn source_stem(source_path: str) -> str:
    // Extract basename and remove .w extension
    var last_slash = -1
    for i in 0..source_path.len():
        if source_path[i] == 47: // '/'
            last_slash = i as i32
    let base = if last_slash >= 0:
        source_path.slice((last_slash + 1) as i64, source_path.len() as i64)
    else:
        source_path
    if base.len() > 2 and base.ends_with(".w"):
        return base.slice(0, (base.len() - 2) as i64)
    base

fn Driver.print_warnings(self: Driver):
    for i in 0..self.pending_warnings.len() as i32:
        with_eprintln(self.pending_warnings.get(i as i64))
