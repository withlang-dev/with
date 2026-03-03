use Ast
use Lexer
use Parser
use Source
use Sema
use Resolve
use compiler.Zcu

extern fn with_fs_read_file(path: str) -> str
extern fn with_eprintln(s: str) -> void

// Frontend pipeline: lex -> parse -> import resolution -> sema.

fn Zcu.compile_file_frontend(self: Zcu, path: str) -> AstPool:
    self.source_dir = frontend_dirname(path)
    self.current_source_path = path
    self.reset_import_state()

    let text = with_fs_read_file(path)
    if text.len() == 0:
        with_eprintln("error: cannot open '" ++ path ++ "'")
        self.last_resolved = ResolveResult.init()
        self.resolved_root_path = path
        return AstPool.new()

    self.current_source_text = text
    let pool = self.compile_source_frontend(text, path, 0)
    if pool.decl_count() == 0 and not self.diagnostics.has_errors():
        with_eprintln("error: compiler produced an empty module for '" ++ path ++ "'")
    pool

fn Zcu.compile_source_frontend(self: Zcu, text: str, name: str, file_id: i32) -> AstPool:
    // Phase 1: Lex.
    var lexer = Lexer.init(text, file_id)
    let tokens = lexer.tokenize()

    // Phase 2: Parse.
    var parser = Parser.init(tokens, text, file_id, self.pool, self.diagnostics)
    var pool = parser.parse_module()

    // Propagate parser updates (intern + diagnostics) back into ZCU.
    self.pool = parser.intern
    self.diagnostics = parser.diags

    if self.diagnostics.has_errors():
        let source = Source.from_string(name, text, file_id)
        self.diagnostics.render_all(source)
        self.last_resolved = ResolveResult.init()
        self.resolved_root_path = name
        return AstPool.new()

    // Wave 4: sidecar resolved artifact.
    let artifacts = resolve_from_root_pool(name, text, file_id, pool, self.pool, self.diagnostics, false)
    self.pool = artifacts.pool
    self.diagnostics = artifacts.diags
    self.last_resolved = artifacts.result
    self.resolved_root_path = name

    // Phase 2.5: Import expansion to a fixed point.
    for import_passes in 0..64:
        let before = pool.decl_count()
        pool = self.process_imports_frontend(pool)
        let after = pool.decl_count()
        if after == before:
            break

    // Phase 3: Semantic analysis.
    var sema = Sema.init(self.pool, self.diagnostics, pool)
    sema.check_module()
    self.pool = sema.pool
    self.diagnostics = sema.diags
    self.typed_expr_types = sema.typed_expr_types
    self.typed_binding_types = sema.typed_binding_types
    self.typed_binding_names = sema.typed_binding_names
    self.typed_binding_muts = sema.typed_binding_muts
    // Keep typed sidecars for downstream stages, but materialize the textual
    // typed dump only when explicitly requested.
    self.last_typed_dump = ""

    if self.diagnostics.has_errors():
        let source = Source.from_string(name, text, file_id)
        self.diagnostics.render_all(source)
        self.last_resolved = ResolveResult.init()
        self.resolved_root_path = name
        return AstPool.new()

    if pool.decl_count() == 0:
        with_eprintln("error: parser returned an empty module without diagnostics for '" ++ name ++ "'")
        return AstPool.new()

    pool

fn Zcu.process_imports_frontend(self: Zcu, pool: AstPool) -> AstPool:
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

        let path_name = self.use_path_name_frontend(merged_pool, path_start, path_count)
        let file_path = self.resolve_module_path_frontend(path_name)
        if file_path.len() == 0:
            continue

        if self.imported_paths.contains(file_path):
            continue

        self.imported_paths.insert(file_path, 1)
        let before = merged_pool.decl_count()
        merged_pool = self.parse_imported_file_frontend(file_path, merged_pool)
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

fn Zcu.use_path_name_frontend(self: Zcu, pool: AstPool, path_start: i32, path_count: i32) -> str:
    var path = ""
    for pi in 0..path_count:
        if pi > 0:
            path = path ++ "/"
        let seg = pool.get_extra(path_start + pi)
        path = path ++ self.pool.resolve(seg)
    path

fn Zcu.resolve_module_path_frontend(self: Zcu, module_name: str) -> str:
    let module_rel = frontend_normalize_module_path(module_name)

    // Strategy 1: relative to source directory
    let path1 = self.source_dir ++ "/" ++ module_rel ++ ".w"
    let text1 = with_fs_read_file(path1)
    if text1.len() > 0:
        return path1

    // Strategy 2: lib/ relative to working directory
    let path2 = "lib/" ++ module_rel ++ ".w"
    let text2 = with_fs_read_file(path2)
    if text2.len() > 0:
        return path2

    // Strategy 3: src/ directory (for self-hosted imports)
    let path3 = "src/" ++ module_rel ++ ".w"
    let text3 = with_fs_read_file(path3)
    if text3.len() > 0:
        return path3

    ""

fn Zcu.parse_imported_file_frontend(self: Zcu, path: str, target_pool: AstPool) -> AstPool:
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

fn frontend_normalize_module_path(module_name: str) -> str:
    var out = ""
    for i in 0..module_name.len():
        if module_name[i] == 46: // '.'
            out = out ++ "/"
        else:
            out = out ++ module_name.slice(i as i64, (i + 1) as i64)
    out

fn frontend_dirname(path: str) -> str:
    var last_slash = -1
    for i in 0..path.len():
        if path[i] == 47: // '/'
            last_slash = i as i32
    if last_slash < 0:
        return "."
    path.slice(0, last_slash as i64)
