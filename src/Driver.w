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
use Codegen
use CImport
use Resolve

extern fn with_fs_read_file(path: str) -> str
extern fn with_eprintln(s: str) -> void
extern fn with_system(cmd: str) -> i32
extern fn int_to_string(n: i32) -> str
extern fn with_arg_count() -> i32
extern fn with_arg_at(idx: i32) -> str

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
    // Pending warning messages.
    pending_warnings: Vec[str],
    // Wave 4 resolve artifact from the most recent compile/resolve run.
    last_resolved: ResolveResult,
    // Root path used when producing the last resolve artifact.
    resolved_root_path: str,
}

fn Driver.init -> Driver:
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
        pending_warnings: Vec.new(),
        last_resolved: ResolveResult.init(),
        resolved_root_path: "",
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
    // Phase 1: Lex.
    var lexer = Lexer.init(text, file_id)
    let tokens = lexer.tokenize()

    // Phase 2: Parse.
    var parser = Parser.init(tokens, text, file_id, self.pool, self.diagnostics)
    var pool = parser.parse_module()

    // Propagate parser's intern pool and diagnostics back to the driver.
    // (Struct params are passed by value, so the parser operated on copies.)
    self.pool = parser.intern
    self.diagnostics = parser.diags

    if self.diagnostics.has_errors():
        let source = Source.from_string(name, text, file_id)
        self.diagnostics.render_all(source)
        return AstPool.new()

    // Wave 4: build a deterministic resolved module graph sidecar.
    let artifacts = resolve_from_root_pool(name, text, file_id, pool, self.pool, self.diagnostics, false)
    self.pool = artifacts.pool
    self.diagnostics = artifacts.diags
    self.last_resolved = artifacts.result
    self.resolved_root_path = name

    // Phase 2.5: Process use imports.
    // Iterate to a fixed point so nested imports are resolved.
    for import_passes in 0..64:
        let before = pool.decl_count()
        pool = self.process_imports(pool, text)
        let after = pool.decl_count()
        if after == before:
            break

    // Phase 3: Semantic analysis.
    var sema = Sema.init(self.pool, self.diagnostics, pool)
    sema.check_module()

    // Propagate sema's changes back.
    self.pool = sema.pool
    self.diagnostics = sema.diags

    if self.diagnostics.has_errors():
        let source = Source.from_string(name, text, file_id)
        self.diagnostics.render_all(source)
        return AstPool.new()

    if pool.decl_count() == 0:
        with_eprintln("error: parser returned an empty module without diagnostics for '" ++ name ++ "'")
        return AstPool.new()

    pool

// ── Codegen + link ───────────────────────────────────────────────

// Compile a module to an object file. Returns 0 on success, 1 on failure.
fn Driver.compile_to_object(self: Driver, pool: AstPool, output_path: str) -> i32:
    var cg = Codegen.init("with_module")
    cg.source_file = self.current_source_path
    cg.source_text = self.current_source_text
    let result = cg.gen_module(pool, self.pool)
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
    var cg = Codegen.init("with_module")
    cg.source_file = self.current_source_path
    cg.source_text = self.current_source_text
    let result = cg.gen_module(pool, self.pool)
    if result != 0:
        with_eprintln("error: code generation failed")
        return false
    cg.print_ir()
    true

// Link an object file into a binary using the system linker.
fn link(obj_path: str, bin_path: str) -> bool:
    let cmd = "cc " ++ obj_path ++ " -o " ++ bin_path
    let result = with_system(cmd)
    result == 0

// Link with extra object files.
fn link_with_extras(obj_path: str, bin_path: str, extras: Vec[str]) -> bool:
    var cmd = "cc " ++ obj_path
    for i in 0..extras.len() as i32:
        cmd = cmd ++ " " ++ extras.get(i as i64)
    cmd = cmd ++ " -o " ++ bin_path
    let result = with_system(cmd)
    result == 0

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

fn should_link_llvm_bridge(source_path: str) -> bool:
    source_path == "src/main.w" or source_path.ends_with("/src/main.w") or source_path.ends_with("\\src\\main.w")

// Full pipeline: parse → codegen → link → binary.
// Returns the output binary path on success, "" on failure.
fn Driver.build_binary(self: Driver, source_path: str) -> str:
    let dir = dirname(source_path)
    self.build_binary_at(source_path, dir)

fn Driver.build_binary_at(self: Driver, source_path: str, output_dir: str) -> str:
    if should_delegate_compiler_build(source_path):
        // Stage bootstrap fallback: delegate self-host compiler rebuilds to
        // the bootstrap compiler while Stage1 codegen remains unstable.
        let cmd = "bootstrap/zig-out/bin/with build " ++ source_path
        let rc = with_system(cmd)
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

    var link_ok = false
    if should_link_llvm_bridge(source_path):
        let bridge_path = find_llvm_bridge_path()
        if bridge_path.len() == 0:
            with_eprintln("error: missing runtime/libwith_llvm_bridge.dylib")
            return ""
        let extras: Vec[str] = Vec.new()
        extras.push(bridge_path)
        link_ok = link_with_extras(obj_path, bin_path, extras)
    else:
        link_ok = link(obj_path, bin_path)
    if not link_ok:
        with_eprintln("error: linking failed")
        return ""

    // Clean up .o file
    with_system("rm -f " ++ obj_path)
    bin_path

fn should_delegate_compiler_build(source_path: str) -> bool:
    source_path == "src/main.w" or source_path.ends_with("/src/main.w") or source_path.ends_with("\\src\\main.w")

// ── Import resolution ────────────────────────────────────────────

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
