// Driver — Pipeline orchestrator for the With compiler.
//
// Coordinates the compilation pipeline:
//   Source → Lex → Parse → [Sema] → CEmit → cc link
//
// Also handles import resolution, file loading, and CLI dispatch.

use Span
use InternPool
use Token
use Lexer
use Parser
use Ast
use Type
use Traits
use Sema
use Source
use CEmit

// ── Compilation mode ─────────────────────────────────────────────────

fn MODE_RUN() -> i32: 0
fn MODE_BUILD() -> i32: 1
fn MODE_TEST() -> i32: 2
fn MODE_CHECK() -> i32: 3

// ── Compilation result ───────────────────────────────────────────────

fn CR_OK() -> i32: 0
fn CR_LEX_ERROR() -> i32: 1
fn CR_PARSE_ERROR() -> i32: 2
fn CR_SEMA_ERROR() -> i32: 3
fn CR_BORROW_ERROR() -> i32: 4
fn CR_CODEGEN_ERROR() -> i32: 5
fn CR_LINK_ERROR() -> i32: 6

// ── Extern functions ─────────────────────────────────────────────────

extern fn with_fs_read_file(path: str) -> str
extern fn with_fs_write_file(path: str, data: str) -> i32
extern fn with_system(cmd: str) -> i32

// ── Driver state ─────────────────────────────────────────────────────

type Driver = {
    mode: i32,
    source_path: str,
    source_text: str,
    source_dir: str,
    intern: InternPool,
    tokens: TokenList,
    pool: AstPool,
    types: TypeTable,
    solver: TraitSolver,
    sema: Sema,
    errors: Vec[str],
    verbose: i32,
    imported: Vec[str],
}

fn Driver.new(mode: i32, source_path: str) -> Driver:
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var intern = InternPool.new()
    var types = TypeTable.new()
    var tokens = TokenList.new()
    var d = Driver {
        mode: mode,
        source_path: source_path,
        source_text: "",
        source_dir: extract_dir(source_path),
        intern: intern,
        tokens: tokens,
        pool: pool,
        types: types,
        solver: TraitSolver.new(),
        sema: Sema.new(pool, "", intern),
        errors: Vec.new(),
        verbose: 0,
        imported: Vec.new(),
    }
    d

// ── Path helpers ─────────────────────────────────────────────────────

fn extract_dir(path: str) -> str:
    var last_slash = -1
    var i = 0
    let len = path.len()
    while i < len:
        if path[i] == 47:
            last_slash = i
        i = i + 1
    if last_slash < 0:
        return "."
    path.slice(0, (last_slash + 1) as i64)

fn extract_basename(path: str) -> str:
    var last_slash = -1
    var i = 0
    let len = path.len()
    while i < len:
        if path[i] == 47:
            last_slash = i
        i = i + 1
    if last_slash < 0:
        return path
    path.slice((last_slash + 1) as i64, len as i64)

// ── Pipeline ─────────────────────────────────────────────────────────

fn Driver.run_pipeline(self: *mut Driver) -> i32:
    // Phase 1: Load source
    let load_result = Driver.load_source(self)
    if load_result != CR_OK():
        return load_result
    // Phase 2: Lex
    let lex_result = Driver.phase_lex(self)
    if lex_result != CR_OK():
        return lex_result
    // Phase 3: Parse
    let parse_result = Driver.phase_parse(self)
    if parse_result != CR_OK():
        return parse_result
    // Phase 4: Process imports
    Driver.process_imports(self)
    // For check mode, stop here
    if self.mode == MODE_CHECK():
        return CR_OK()
    CR_OK()

fn Driver.load_source(self: *mut Driver) -> i32:
    self.source_text = with_fs_read_file(self.source_path)
    if self.source_text.len() == 0:
        self.errors.push("error: could not read file: " ++ self.source_path)
        return CR_LEX_ERROR()
    CR_OK()

fn Driver.phase_lex(self: *mut Driver) -> i32:
    var l = Lexer.new(self.source_text, 0)
    self.tokens = Lexer.tokenize(l)
    CR_OK()

fn Driver.phase_parse(self: *mut Driver) -> i32:
    var p = Parser.new(self.tokens, self.source_text)
    Parser.parse_module(p)
    self.pool = p.pool
    CR_OK()

// ── Import resolution ────────────────────────────────────────────────

fn Driver.process_imports(self: *mut Driver) -> void:
    // Walk use declarations, load and parse imported files,
    // merge declarations into the main pool.
    let dc = AstPool.decl_count(self.pool)
    var i = 0
    while i < dc:
        let decl = AstPool.get_decl(self.pool, i)
        let kind = AstPool.kind(self.pool, decl)
        if kind == NK_USE_DECL():
            let name_sym = AstPool.get_data0(self.pool, decl)
            let name = AstPool.get_string(self.pool, name_sym)
            Driver.import_module(self, name)
        i = i + 1

    // Re-parse once after all imported source text has been appended.
    var l = Lexer.new(self.source_text, 0)
    self.tokens = Lexer.tokenize(l)
    var p = Parser.new(self.tokens, self.source_text)
    Parser.parse_module(p)
    self.pool = p.pool

fn Driver.import_module(self: *mut Driver, name: str) -> void:
    // Check if already imported (prevent cycles)
    var already = false
    var ci = 0
    let ic = self.imported.len() as i32
    while ci < ic:
        if self.imported.get(ci as i64) == name:
            already = true
            ci = ic
        ci = ci + 1
    if already:
        return
    self.imported.push(name)

    // Resolve module path: look in source dir first, then lib/std/
    let path = self.source_dir ++ name ++ ".w"
    var text = with_fs_read_file(path)
    if text.len() == 0:
        // Try lib/std/
        let std_path = "lib/std/" ++ name ++ ".w"
        text = with_fs_read_file(std_path)
    if text.len() == 0:
        // Module not found — not an error (might be a builtin)
        return

    // Append imported module source so one final parse sees all declarations.
    self.source_text = self.source_text ++ "\n" ++ text ++ "\n"

    // Lex the imported module
    var l = Lexer.new(text, 0)
    let tokens = Lexer.tokenize(l)

    // Parse the imported module
    var p = Parser.new(tokens, text)
    Parser.parse_module(p)
    let imported_pool = p.pool

    // Recursively process imports in the imported module
    let idc = AstPool.decl_count(imported_pool)
    var j = 0
    while j < idc:
        let idecl = AstPool.get_decl(imported_pool, j)
        let ikind = AstPool.kind(imported_pool, idecl)
        if ikind == NK_USE_DECL():
            let iname_sym = AstPool.get_data0(imported_pool, idecl)
            let iname = AstPool.get_string(imported_pool, iname_sym)
            Driver.import_module(self, iname)
        j = j + 1

fn Driver.merge_pool(self: *mut Driver, other: AstPool, other_source: str) -> void:
    // Copy all declarations from other pool into self.pool
    // This is a simplified merge — it re-parses the source into our pool
    // For a real implementation, we'd need to remap node indices
    let odc = AstPool.decl_count(other)
    var i = 0
    while i < odc:
        let odecl = AstPool.get_decl(other, i)
        let okind = AstPool.kind(other, odecl)
        // Skip use declarations (we handle imports ourselves)
        if okind != NK_USE_DECL():
            // Re-lex and re-parse into our pool is too complex
            // Instead, just copy the node data
            // For now, re-parse the entire imported source into our pool
            0
        i = i + 1

    // Simpler approach: re-lex and re-parse the source into our pool
    var l = Lexer.new(other_source, 0)
    let tokens = Lexer.tokenize(l)
    var p = Parser.new(tokens, other_source)
    // We need to parse into self.pool, not a new pool
    // Since Parser creates its own pool, we'll parse and then merge declarations
    Parser.parse_module(p)
    let new_pool = p.pool
    let ndc = AstPool.decl_count(new_pool)
    var j = 0
    while j < ndc:
        let ndecl = AstPool.get_decl(new_pool, j)
        let nkind = AstPool.kind(new_pool, ndecl)
        if nkind != NK_USE_DECL():
            // Copy node from new_pool to self.pool
            let node_kind = AstPool.kind(new_pool, ndecl)
            let s = AstPool.get_start(new_pool, ndecl)
            let e = AstPool.get_end(new_pool, ndecl)
            let d0 = AstPool.get_data0(new_pool, ndecl)
            let d1 = AstPool.get_data1(new_pool, ndecl)
            let d2 = AstPool.get_data2(new_pool, ndecl)
            // Remap string indices
            // This is complex — for now, just add to our pool's decl list
            // The real solution is to share AstPools or use a module system
            0
        j = j + 1

// ── C Backend Pipeline ───────────────────────────────────────────────

fn Driver.compile_to_c(self: *mut Driver, output_path: str) -> i32:
    // Run front-end pipeline
    let result = Driver.run_pipeline(self)
    if result != CR_OK():
        return result

    // Generate C code
    var emitter = CEmit.new(self.pool, self.source_text)
    let c_source = emitter.emit_module()

    // Ensure output directory exists
    with_system("mkdir -p .with/build")

    // Write C source
    let c_path = ".with/build/_main.c"
    let write_result = with_fs_write_file(c_path, c_source)
    if write_result != 0:
        self.errors.push("error: could not write C source to " ++ c_path)
        return CR_CODEGEN_ERROR()

    // Compile C source to executable
    let runtime_dir = Driver.find_runtime_dir(self)
    let cc_cmd = "cc -o " ++ output_path ++ " " ++ c_path ++ " " ++ runtime_dir ++ "/with_runtime.c " ++ runtime_dir ++ "/helpers.c -I" ++ runtime_dir ++ " -lm 2>&1"
    let cc_result = with_system(cc_cmd)
    if cc_result != 0:
        self.errors.push("error: C compilation failed (exit code " ++ i32_to_str(cc_result) ++ ")")
        return CR_LINK_ERROR()
    CR_OK()

fn Driver.compile_and_run(self: *mut Driver) -> i32:
    let exe_path = ".with/build/main"
    let result = Driver.compile_to_c(self, exe_path)
    if result != CR_OK():
        return result
    let run_result = with_system(exe_path)
    if run_result != 0:
        return CR_LINK_ERROR()
    CR_OK()

fn Driver.find_runtime_dir(self: *mut Driver) -> str:
    // Look for runtime/ relative to the compiler
    // Try common locations
    let r1 = with_fs_read_file("runtime/with_runtime.h")
    if r1.len() > 0:
        return "runtime"
    let r2 = with_fs_read_file("../runtime/with_runtime.h")
    if r2.len() > 0:
        return "../runtime"
    // Fallback
    "runtime"

extern fn i32_to_str(n: i32) -> str

// ── Error reporting ──────────────────────────────────────────────────

fn Driver.report_errors(self: *mut Driver) -> void:
    // Report driver-level errors
    let ec = self.errors.len() as i32
    var i = 0
    while i < ec:
        let msg = self.errors.get(i as i64)
        println(msg)
        i = i + 1

fn Driver.error_count(self: *mut Driver) -> i32:
    self.errors.len() as i32
