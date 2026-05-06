use Ast
use Lexer
use Parser
use Source
use Sema
use SemaDecl
use SemaCheck
use SemaDiag
use ComptimeTransform
use Resolve
use Span
use Diagnostic
use CImport
use render
use compiler.EmbeddedStdlib
use compiler.ProjectConfig
use compiler.Zcu

extern fn with_fs_read_file(path: str) -> str
extern fn with_fs_write_file(path: str, data: str) -> i32
extern fn with_fs_mkdir_p(path: str) -> i32
extern fn with_str_hash(s: str) -> i64
extern fn with_eprint(s: str) -> void
extern fn with_arg_at(idx: i32) -> str
extern fn with_getenv_str(name: str) -> str
extern fn with_clock_nanos() -> i64
extern fn with_str_clone(s: str) -> str
// Frontend pipeline: lex -> parse -> import resolution -> sema.

var frontend_cimport_compiler_fingerprint_ready: i32 = 0
var frontend_cimport_compiler_fingerprint: str = ""

fn frontend_owned_text(text: str) -> str:
    if text.len() == 0:
        return ""
    with_str_clone(text)

fn frontend_str_contains_byte(text: str, target: i32) -> bool:
    for i in 0..text.len():
        if text.byte_at(i as i64) == target:
            return true
    false

fn frontend_resolve_executable_path(argv0: str) -> str:
    if argv0.len() == 0:
        return ""
    if with_fs_read_file(argv0).len() > 0:
        return argv0
    if frontend_str_contains_byte(argv0, 47):
        return ""

    let search_path = with_getenv_str("PATH")
    if search_path.len() == 0:
        return ""

    var segment_start = 0
    var i = 0
    while i <= search_path.len() as i32:
        let at_end = i == search_path.len() as i32
        let ch = if at_end: 58 else: search_path.byte_at(i as i64)
        if ch == 58:
            let dir = search_path.slice(segment_start as i64, i as i64)
            let candidate = if dir.len() == 0: "./" ++ argv0 else: dir ++ "/" ++ argv0
            if with_fs_read_file(candidate).len() > 0:
                return candidate
            segment_start = i + 1
        i = i + 1
    ""

fn frontend_cimport_compiler_fingerprint_line() -> str:
    if frontend_cimport_compiler_fingerprint_ready != 0:
        return frontend_cimport_compiler_fingerprint
    frontend_cimport_compiler_fingerprint_ready = 1
    let compiler_path = frontend_resolve_executable_path(with_arg_at(0))
    if compiler_path.len() == 0:
        return ""
    let compiler_image = with_fs_read_file(compiler_path)
    if compiler_image.len() == 0:
        return ""
    frontend_cimport_compiler_fingerprint = frontend_owned_text(f"\n#compiler-hash:{with_str_hash(compiler_image)}")
    frontend_cimport_compiler_fingerprint

fn count_non_use_decls_frontend(pool: AstPool) -> i32:
    var count = 0
    for di in 0..pool.decl_count():
        let decl = pool.get_decl(di)
        if pool.kind(decl) != NodeKind.NK_USE_DECL:
            count = count + 1
    count

fn Zcu.emit_missing_import_frontend(self: Zcu, pool: AstPool, decl: i32):
    let span = Span {
        file: 0,
        start: pool.get_start(decl),
        end: pool.get_end(decl),
    }
    self.diagnostics.emit(Diagnostic.err("import module not found", span))

fn c_import_str_contains(text: str, needle: str) -> bool:
    if needle.len() == 0:
        return true
    if needle.len() > text.len():
        return false
    var i = 0
    let limit = text.len() as i32 - needle.len() as i32
    while i <= limit:
        if text.slice(i as i64, (i + needle.len() as i32) as i64) == needle:
            return true
        i = i + 1
    false

fn Zcu.read_trace_c_import_cache_frontend(self: Zcu) -> i32:
    let _ = self
    let raw = with_getenv_str("WITH_TRACE_CIMPORT_CACHE")
    if raw.len() == 0:
        return 0
    if raw == "0":
        return 0
    1

fn frontend_debug_type_names_enabled() -> i32:
    let raw = with_getenv_str("WITH_DEBUG_TYPE_NAMES")
    if raw.len() == 0:
        return 0
    if raw == "0":
        return 0
    1

fn frontend_dump_type_decl_names(stage: str, pool: AstPool, intern: InternPool):
    if frontend_debug_type_names_enabled() == 0:
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

fn Sema.init_module_graph(mut self: Sema, resolved: &ResolveResult):
    self.module_paths = Vec.new()
    self.module_import_starts = Vec.new()
    self.module_import_counts = Vec.new()
    self.module_import_targets = Vec.new()
    self.module_index_by_path = HashMap.new()
    self.global_visible_module_paths = HashMap.new()
    self.module_visibility_cache = HashMap.new()

    for mi in 0..resolved.modules.len() as i32:
        let mod = resolved.modules.get(mi as i64)
        let owned_path = frontend_owned_text(mod.path)
        self.module_paths.push(owned_path)
        self.module_import_starts.push(self.module_import_targets.len() as i32)
        var visible_count = 0
        for ii in 0..mod.import_count:
            let imp = resolved.imports.get((mod.import_start + ii) as i64)
            if imp.target_module >= 0:
                self.module_import_targets.push(imp.target_module)
                visible_count = visible_count + 1
        self.module_import_counts.push(visible_count)
        self.module_index_by_path.insert(owned_path, mod.module_id)
    if resolved.modules.len() > 0:
        let global_frontier: Vec[i32] = Vec.new()
        let root = resolved.modules.get(0)
        for ii in 0..root.import_count:
            let imp = resolved.imports.get((root.import_start + ii) as i64)
            if imp.target_module < 0:
                continue
            if imp.path_text == "std.prelude" or imp.path_text == "std.prelude_core":
                global_frontier.push(imp.target_module)
        let seen_global: HashMap[i32, i32] = HashMap.new()
        while global_frontier.len() as i32 > 0:
            let last = global_frontier.len() as i32 - 1
            let mid = global_frontier.get(last as i64)
            global_frontier.pop()
            if seen_global.contains(mid):
                continue
            seen_global.insert(mid, 1)
            let mod = resolved.modules.get(mid as i64)
            self.global_visible_module_paths.insert(frontend_owned_text(mod.path), 1)
            for ii in 0..mod.import_count:
                let imp = resolved.imports.get((mod.import_start + ii) as i64)
                if imp.target_module >= 0:
                    global_frontier.push(imp.target_module)

fn Zcu.expand_c_imports_frontend(self: Zcu, pool: AstPool) -> AstPool:
    var out = pool
    let ordered: Vec[i32] = Vec.new()
    let ordered_paths: Vec[str] = Vec.new()
    let ordered_file_ids: Vec[i32] = Vec.new()
    let ordered_ci: Vec[i32] = Vec.new()
    let base_count = out.decl_count()
    var has_c_import = 0
    for i in 0..base_count:
        let decl = out.get_decl(i)
        if out.kind(decl) == NodeKind.NK_C_IMPORT:
            has_c_import = 1
            break
    if has_c_import == 0:
        return out

    // Pass project config include paths to clang bridge
    if self.project_config.c_import_include_paths.len() > 0:
        ci_set_include_paths(self.project_config.c_import_include_paths)

    for i in 0..base_count:
        let decl = out.get_decl(i)
        if out.kind(decl) != NodeKind.NK_C_IMPORT:
            ordered.push(decl as i32)
            ordered_paths.push(self.decl_source_path_frontend(i))
            ordered_file_ids.push(self.decl_source_file_id_frontend(i))
            let ci_f = if i < self.decl_is_c_import.len() as i32: self.decl_is_c_import.get(i as i64) else: 0
            ordered_ci.push(ci_f)
            continue

        // Preserve the original c_import declaration as an ownership marker so
        // later sema passes can still tell which modules directly use c_import,
        // even if header expansion is deduplicated elsewhere in the merged AST.
        ordered.push(decl as i32)
        ordered_paths.push(self.decl_source_path_frontend(i))
        ordered_file_ids.push(self.decl_source_file_id_frontend(i))
        ordered_ci.push(0)

        let header_sym = out.get_data0(decl)
        let header_spec = self.pool.resolve(header_sym)
        let decl_dir = self.decl_source_dir_frontend(i)
        let resolved_header_spec = project_config_resolve_c_import_header(self.project_config, decl_dir, header_spec)
        let cache_key = self.c_import_cache_key_frontend(out, decl, resolved_header_spec)

        var synthetic = ""
        let cached = self.c_import_cache_lookup(cache_key)
        if cached.len() > 0:
            // Already injected in this compilation — skip to avoid duplicate declarations
            if self.trace_c_import_cache != 0:
                with_eprint("c_import cache hit (memory) — skipping duplicate")
            continue
        else:
            // Check file-system cache
            let fs_cached = c_import_fs_cache_lookup(cache_key)
            if fs_cached.len() > 0:
                if self.trace_c_import_cache != 0:
                    with_eprint("c_import cache hit (fs)")
                synthetic = fs_cached
                self.c_import_cache_store(cache_key, synthetic)
                // Populate dedup table so subsequent c_imports don't re-emit these names
                ci_mark_cached_names(synthetic)
            else:
                if self.trace_c_import_cache != 0:
                    with_eprint("c_import cache miss")
                let libclang_result = process_c_import(resolved_header_spec)
                if self.trace_c_import_cache != 0 and libclang_result.len() > 0:
                    with_eprint("c_import generated:")
                    with_eprint(libclang_result)
                if libclang_result.len() > 0:
                    synthetic = libclang_result
                else:
                    synthetic = self.c_import_expand_header_spec_frontend(header_spec, decl)
                    if self.diagnostics.has_errors():
                        continue
                self.c_import_cache_store(cache_key, synthetic)
                // Store to file-system cache
                if synthetic.len() > 0:
                    c_import_fs_cache_store(cache_key, synthetic)

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
        // Mark all c_import-synthesized declarations
        let ci_owner_path = self.decl_source_path_frontend(i)
        let ci_owner_file_id = self.decl_source_file_id_frontend(i)
        var di = before
        while di < after:
            ordered.push(out.get_decl(di) as i32)
            ordered_paths.push(ci_owner_path)
            ordered_file_ids.push(ci_owner_file_id)
            ordered_ci.push(1)  // c_import origin
            di = di + 1

    while out.decl_count() > 0:
        out.state.decls.pop()
    for oi in 0..ordered.len() as i32:
        out.add_decl(ordered.get(oi as i64))
    self.decl_source_paths = ordered_paths
    self.decl_source_file_ids = ordered_file_ids
    self.decl_is_c_import = ordered_ci
    out

fn Zcu.c_import_cache_key_frontend(self: Zcu, pool: AstPool, decl: i32, header_spec: str) -> str:
    var key = header_spec ++ "\n#format:cimport-v3\n#links:"
    let link_start = pool.get_data1(decl)
    let link_count = pool.get_data2(decl)
    for li in 0..link_count:
        let lib_sym = pool.get_extra(link_start + li)
        key = key ++ "|" ++ self.pool.resolve(lib_sym)
    key = key ++ frontend_cimport_compiler_fingerprint_line()
    let epoch = with_getenv_str("WITH_CIMPORT_CACHE_EPOCH")
    if epoch.len() > 0:
        key = key ++ "\n#epoch:" ++ epoch
    key

fn c_import_fs_cache_dir() -> str:
    let home = with_getenv_str("HOME")
    if home.len() == 0:
        return ""
    home ++ "/.cache/with/c_import"

fn c_import_fs_cache_lookup(cache_key: str) -> str:
    let dir = c_import_fs_cache_dir()
    if dir.len() == 0:
        return ""
    let h = with_str_hash(cache_key)
    // Make hash positive for filename
    var hash_str = f"{h}"
    if h < 0:
        hash_str = f"n{0 - h}"
    let path = f"{dir}/{hash_str}.w"
    with_fs_read_file(path)

fn c_import_fs_cache_store(cache_key: str, value: str):
    let dir = c_import_fs_cache_dir()
    if dir.len() == 0:
        return
    with_fs_mkdir_p(dir)
    let h = with_str_hash(cache_key)
    var hash_str = f"{h}"
    if h < 0:
        hash_str = f"n{0 - h}"
    let path = f"{dir}/{hash_str}.w"
    with_fs_write_file(path, value)

fn Zcu.c_import_emit_header_error_frontend(self: Zcu, decl: i32, header_spec: str):
    let _ = decl
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

fn Zcu.c_import_expand_header_spec_frontend(self: Zcu, header_spec_raw: str, decl: i32) -> str:
    let decoded = c_import_decode_escapes(header_spec_raw)
    let rendered = c_import_render_header_spec(decoded)
    let header = c_import_trim(rendered)
    if header.len() == 0:
        self.c_import_emit_header_error_frontend(decl, header_spec_raw)
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
                    let inc = self.c_import_include_decls_frontend(line, decl, header_spec_raw)
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
                    self.c_import_emit_header_error_frontend(decl, header_spec_raw)
                    return ""
                generated = generated ++ fn_decl
            stmt_start = si + 1
        si = si + 1

    generated

fn Zcu.c_import_include_decls_frontend(self: Zcu, line: str, decl: i32, header_spec_raw: str) -> str:
    let rest = c_import_trim(line.slice(8, line.len()))
    if rest.len() < 3:
        self.c_import_emit_header_error_frontend(decl, header_spec_raw)
        return ""

    var header_name = ""
    let first = rest.byte_at(0)
    let last = rest.byte_at(rest.len() as i64 - 1)
    if first == 60 and last == 62:
        header_name = rest.slice(1, rest.len() - 1)
    else if first == 34 and last == 34:
        header_name = rest.slice(1, rest.len() - 1)
    else:
        self.c_import_emit_header_error_frontend(decl, header_spec_raw)
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

    self.c_import_emit_header_error_frontend(decl, header_spec_raw)
    ""

fn c_import_render_header_spec(spec_raw: str) -> str:
    let spec = c_import_trim(spec_raw)
    if spec.len() == 0:
        return ""

    let has_newline = c_import_str_contains(spec, "\n")
    let has_directive = c_import_starts_with(spec, "#")
    let has_statement = c_import_str_contains(spec, ";")
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
    if i < rest.len() as i32 and rest.byte_at(i as i64) == 40:
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
        if ch == 40 and open < 0:
            open = i
        if ch == 41:
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
            if i == plen or params_text.byte_at(i as i64) == 44:
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
                        params_out = params_out ++ f"p{param_index}: " ++ pty
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
        if spec.byte_at(i as i64) == 42:
            star_count = star_count + 1

    var base = "i32"
    if c_import_str_contains(spec, "unsigned __int128"):
        base = "u128"
    else if c_import_str_contains(spec, "__int128"):
        base = "i128"
    else if c_import_str_contains(spec, "unsigned long long"):
        base = "u64"
    else if c_import_str_contains(spec, "unsigned long"):
        base = "u64"
    else if c_import_str_contains(spec, "long long"):
        base = "i64"
    else if c_import_str_contains(spec, "size_t"):
        base = "u64"
    else if c_import_str_contains(spec, "unsigned int"):
        base = "u32"
    else if c_import_str_contains(spec, "unsigned short"):
        base = "u16"
    else if c_import_str_contains(spec, "unsigned char"):
        base = "u8"
    else if c_import_str_contains(spec, "short"):
        base = "i16"
    else if c_import_str_contains(spec, "char"):
        base = "i8"
    else if c_import_str_contains(spec, "double"):
        base = "f64"
    else if c_import_str_contains(spec, "float"):
        base = "f32"
    else if c_import_str_contains(spec, "long"):
        base = "i64"
    else if c_import_str_contains(spec, "void"):
        base = "void"
    else if c_import_str_contains(spec, "int"):
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
        if ch != 92 or i + 1 >= len:
            out = out ++ raw.slice(i as i64, (i + 1) as i64)
            i = i + 1
            continue

        let esc = raw.byte_at((i + 1) as i64)
        if esc == 110:
            out = out ++ "\n"
        else if esc == 114:
            out = out ++ "\r"
        else if esc == 116:
            out = out ++ "\t"
        else if esc == 92:
            out = out ++ "\\"
        else if esc == 34:
            out = out ++ "\""
        else:
            out = out ++ raw.slice((i + 1) as i64, (i + 2) as i64)
        i = i + 2
    out

fn c_import_trim_outer_parens(value_raw: str) -> str:
    var v = c_import_trim(value_raw)
    while v.len() >= 2 and v.byte_at(0) == 40 and v.byte_at(v.len() as i64 - 1) == 41:
        v = c_import_trim(v.slice(1, v.len() - 1))
    v

fn c_import_escape_with_string(value: str) -> str:
    var out = ""
    for i in 0..value.len() as i32:
        let ch = value.byte_at(i as i64)
        if ch == 92:
            out = out ++ "\\\\"
        else if ch == 34:
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
    if text.byte_at(0) == 45 or text.byte_at(0) == 43:
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

fn Zcu.inject_prelude_frontend(self: Zcu, pool: AstPool) -> AstPool:
    if self.prelude_mode == PRELUDE_NONE():
        return pool

    let prelude_module = if self.prelude_mode == PRELUDE_CORE(): "std.prelude_core" else: "std.prelude"
    let synthetic = "use " ++ prelude_module ++ "\n"

    var lexer = Lexer.init(synthetic, 0)
    let tokens = lexer.tokenize()
    var parser = Parser.init_with_pool(tokens, synthetic, 0, self.pool, self.diagnostics, pool)
    let merged_pool = parser.parse_module()
    self.pool = parser.intern
    self.diagnostics = parser.diags
    merged_pool

// Parse the prelude USE declaration into a fresh pool, then parse the user
// source into the same pool so the prelude USE comes first in decl order.
// This ensures prelude-provided types (Vec, HashMap, etc.) are imported
// before any user modules that depend on them.
fn Zcu.parse_with_prelude_first_mode(self: Zcu, text: str, file_id: i32, implicit_main_mode: i32) -> AstPool:
    let prelude_module = if self.prelude_mode == PRELUDE_CORE(): "std.prelude_core" else: "std.prelude"
    let synthetic = "use " ++ prelude_module ++ "\n"

    // Step 1: parse prelude USE into a fresh pool
    var plexer = Lexer.init(synthetic, 0)
    let ptokens = plexer.tokenize()
    var pparser = Parser.init(ptokens, synthetic, 0, self.pool, self.diagnostics)
    var pool = pparser.parse_module()
    self.pool = pparser.intern
    self.diagnostics = pparser.diags

    // Step 2: parse user source into the same pool (appends after prelude USE)
    var ulexer = Lexer.init(text, file_id)
    let utokens = ulexer.tokenize()
    var uparser = Parser.init_with_pool(utokens, text, file_id, self.pool, self.diagnostics, pool)
    if implicit_main_mode != 0:
        uparser.enable_implicit_main_mode()
    pool = uparser.parse_module()
    self.pool = uparser.intern
    self.diagnostics = uparser.diags
    pool

fn Zcu.parse_with_prelude_first(self: Zcu, text: str, file_id: i32) -> AstPool:
    self.parse_with_prelude_first_mode(text, file_id, 0)

fn Zcu.compile_file_frontend(self: Zcu, path: str) -> AstPool:
    let do_profile = with_getenv_str("WITH_PROFILE").len() > 0
    if zcu_debug_init_enabled() != 0:
        with_eprint("[frontend] compile_file:start " ++ path)
    let source_dir = frontend_dirname(path)
    self.reset_for_new_invocation(source_dir, path, "")
    self.project_config = project_config_load_for_source(path)

    let t_read = with_clock_nanos()
    let text = with_fs_read_file(path)
    if text.len() == 0:
        with_eprint("error: cannot open '" ++ path ++ "'")
        self.set_resolve_snapshot(ResolveResult.init(), path)
        return AstPool.new()
    if do_profile:
        let read_ns = with_clock_nanos() - t_read
        with_eprint(f"[profile] frontend.read  {read_ns / 1000000}.{(read_ns % 1000000) / 1000} ms  bytes={text.len() as i32}")

    self.set_current_source(source_dir, path, text)
    if zcu_debug_init_enabled() != 0:
        with_eprint(f"[frontend] compile_file:source_ready bytes={text.len() as i32}")
    let pool = self.compile_source_frontend(text, path, 0)
    if pool.decl_count() == 0 and not self.diagnostics.has_errors():
        with_eprint("error: compiler produced an empty module for '" ++ path ++ "'")
    pool

fn Zcu.compile_file_frontend_entry(self: Zcu, path: str) -> AstPool:
    let do_profile = with_getenv_str("WITH_PROFILE").len() > 0
    if zcu_debug_init_enabled() != 0:
        with_eprint("[frontend] compile_file_entry:start " ++ path)
    let source_dir = frontend_dirname(path)
    self.reset_for_new_invocation(source_dir, path, "")
    self.project_config = project_config_load_for_source(path)

    let t_read = with_clock_nanos()
    let text = with_fs_read_file(path)
    if text.len() == 0:
        with_eprint("error: cannot open '" ++ path ++ "'")
        self.set_resolve_snapshot(ResolveResult.init(), path)
        return AstPool.new()
    if do_profile:
        let read_ns = with_clock_nanos() - t_read
        with_eprint(f"[profile] frontend.read  {read_ns / 1000000}.{(read_ns % 1000000) / 1000} ms  bytes={text.len() as i32}")

    self.set_current_source(source_dir, path, text)
    let pool = self.compile_source_frontend_mode(text, path, 0, 1)
    if pool.decl_count() == 0 and not self.diagnostics.has_errors():
        with_eprint("error: compiler produced an empty module for '" ++ path ++ "'")
    pool

fn Zcu.compile_source_frontend(self: Zcu, text: str, name: str, file_id: i32) -> AstPool:
    self.compile_source_frontend_mode(text, name, file_id, 0)

fn Zcu.compile_source_frontend_mode(self: Zcu, text: str, name: str, file_id: i32, implicit_main_mode: i32) -> AstPool:
    let do_profile = with_getenv_str("WITH_PROFILE").len() > 0
    if zcu_debug_init_enabled() != 0:
        with_eprint("[frontend] compile_source:parse")

    // Phase 1+2: Lex + Parse.  When prelude is enabled, parse the prelude
    // USE declaration first so it appears at decl position 0, ensuring
    // prelude-provided types are imported before user modules.
    let t_parse = with_clock_nanos()
    var pool: AstPool = AstPool.new()
    if self.prelude_mode != PRELUDE_NONE():
        pool = self.parse_with_prelude_first_mode(text, file_id, implicit_main_mode)
    else:
        var lexer = Lexer.init(text, file_id)
        let tokens = lexer.tokenize()
        var parser = Parser.init(tokens, text, file_id, self.pool, self.diagnostics)
        if implicit_main_mode != 0:
            parser.enable_implicit_main_mode()
        pool = parser.parse_module()
        self.pool = parser.intern
        self.diagnostics = parser.diags

    self.seed_decl_source_paths(pool, name, file_id)
    if do_profile:
        let parse_ns = with_clock_nanos() - t_parse
        with_eprint(f"[profile] frontend.parse  {parse_ns / 1000000}.{(parse_ns % 1000000) / 1000} ms  decls={pool.decl_count()}")

    let root_local_decl_count = count_non_use_decls_frontend(pool)

    if self.diagnostics.has_errors():
        let source = Source.from_string(name, text, file_id)
        self.diagnostics.render_all(source)
        self.set_resolve_snapshot(ResolveResult.init(), name)
        return AstPool.new()

    if zcu_debug_init_enabled() != 0:
        with_eprint("[frontend] compile_source:resolve")
    // Wave 4: sidecar resolved artifact.
    let t_resolve = with_clock_nanos()
    let artifacts = resolve_from_root_pool(name, text, file_id, pool, self.pool, self.diagnostics, false)
    if do_profile:
        let resolve_ns = with_clock_nanos() - t_resolve
        with_eprint(f"[profile] frontend.resolve  {resolve_ns / 1000000}.{(resolve_ns % 1000000) / 1000} ms")
    self.pool = artifacts.pool
    self.diagnostics = artifacts.diags
    self.set_resolve_snapshot(artifacts.result, name)
    self.capture_last_link_lib_names(self.pool, self.last_resolved)

    if self.diagnostics.has_errors():
        let source = Source.from_string(name, text, file_id)
        self.diagnostics.render_all(source)
        self.set_typed_snapshot("", AstPool.new())
        return AstPool.new()

    if zcu_debug_init_enabled() != 0:
        with_eprint("[frontend] compile_source:imports")
    // Build the sema/codegen pool via recursive syntactic import expansion.
    // This still sees implicit prelude imports because `inject_prelude_frontend`
    // materializes them as normal `use` declarations in the root pool.
    let t_imports = with_clock_nanos()
    pool = self.process_imports_frontend(pool)
    if do_profile:
        let imports_ns = with_clock_nanos() - t_imports
        with_eprint(f"[profile] frontend.imports  {imports_ns / 1000000}.{(imports_ns % 1000000) / 1000} ms")
    let t_cimport = with_clock_nanos()
    self.trace_c_import_cache = self.read_trace_c_import_cache_frontend()
    pool = self.expand_c_imports_frontend(pool)
    if do_profile:
        let cimport_ns = with_clock_nanos() - t_cimport
        with_eprint(f"[profile] frontend.c_import  {cimport_ns / 1000000}.{(cimport_ns % 1000000) / 1000} ms")
    pool.set_local_decl_count(root_local_decl_count)
    self.set_typed_snapshot("", pool)
    self.set_frontend_pool(self.pool)
    frontend_dump_type_decl_names("post-imports", pool, self.pool)

    if self.diagnostics.has_errors():
        self.render_all_diagnostics_frontend()
        self.set_typed_snapshot("", AstPool.new())
        return AstPool.new()

    // Comptime transform: fold forced comptime expressions and prune dead
    // comptime branches before final sema.
    let t_comptime = with_clock_nanos()
    if pool.has_comptime_nodes() or pool.has_type_derives():
        if zcu_debug_init_enabled() != 0:
            with_eprint("[frontend] compile_source:comptime-transform")
        var pre_sema = Sema.init(self.pool, self.diagnostics, pool)
        pre_sema.source_text = text
        pre_sema.decl_source_paths = self.decl_source_paths
        pre_sema.decl_source_file_ids = self.decl_source_file_ids
        pre_sema.decl_is_c_import = self.decl_is_c_import
        pre_sema.init_module_graph(&self.last_resolved)
        pre_sema.prepare_for_comptime_transform()
        // The comptime transform must run against the same intern pool that
        // pre-sema prepared, otherwise cloned AST symbol ids may be resolved
        // against a stale symbol table in the transform pass.
        self.pool = pre_sema.pool
        pool = pre_sema.comptime_transform_module(pool, self.pool)
        self.diagnostics = pre_sema.diags
        self.decl_source_paths = pre_sema.decl_source_paths
        self.decl_source_file_ids = pre_sema.decl_source_file_ids
        self.decl_is_c_import = pre_sema.decl_is_c_import
        if self.diagnostics.has_errors():
            self.render_all_diagnostics_frontend()
            self.set_typed_snapshot("", AstPool.new())
            return AstPool.new()

    if do_profile:
        let comptime_ns = with_clock_nanos() - t_comptime
        if comptime_ns > 100000:
            with_eprint(f"[profile] frontend.comptime  {comptime_ns / 1000000}.{(comptime_ns % 1000000) / 1000} ms")

    // AstPool construction is complete — freeze to catch any future mutations.
    pool.freeze()

    if zcu_debug_init_enabled() != 0:
        with_eprint("[frontend] compile_source:sema")
    let t_sema = with_clock_nanos()
    var sema = Sema.init(self.pool, self.diagnostics, pool)
    sema.source_text = text
    sema.decl_source_paths = self.decl_source_paths
    sema.decl_source_file_ids = self.decl_source_file_ids
    sema.decl_is_c_import = self.decl_is_c_import
    sema.init_module_graph(&self.last_resolved)
    sema.check_module()
    if do_profile:
        let sema_ns = with_clock_nanos() - t_sema
        with_eprint(f"[profile] frontend.sema  {sema_ns / 1000000}.{(sema_ns % 1000000) / 1000} ms  decls={pool.decl_count()}")
    self.sync_from_sema(sema)
    frontend_dump_type_decl_names("post-sema", self.last_sema.ast, self.last_sema.pool)
    self.last_typed_dump = ""

    if self.diagnostics.has_errors():
        self.render_all_diagnostics_frontend()
        self.set_typed_snapshot("", AstPool.new())
        return AstPool.new()

    if pool.decl_count() == 0:
        with_eprint("error: parser returned an empty module without diagnostics for '" ++ name ++ "'")
        return AstPool.new()

    pool

fn Zcu.merge_resolved_modules_frontend(self: Zcu, root_pool: AstPool, root_path: str) -> AstPool:
    var merged_pool = root_pool

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
        let before = merged_pool.decl_count()
        var parser = Parser.init_with_pool(tokens, text, mod.file_id, self.pool, self.diagnostics, merged_pool)
        merged_pool = parser.parse_module()
        self.pool = parser.intern
        self.diagnostics = parser.diags
        self.append_decl_source_paths(merged_pool.decl_count() - before, path, mod.file_id)

    self.strip_use_decls_frontend(merged_pool)

fn Zcu.strip_use_decls_frontend(self: Zcu, pool: AstPool) -> AstPool:
    var out = pool
    var has_use = 0
    for i in 0..out.decl_count():
        let decl = out.get_decl(i)
        if out.kind(decl) == NodeKind.NK_USE_DECL:
            has_use = 1
            break
    if has_use == 0:
        return out

    let ordered: Vec[i32] = Vec.new()
    let ordered_paths: Vec[str] = Vec.new()
    let ordered_file_ids: Vec[i32] = Vec.new()
    let ordered_c_import: Vec[i32] = Vec.new()
    for i in 0..out.decl_count():
        let decl = out.get_decl(i)
        if out.kind(decl) != NodeKind.NK_USE_DECL:
            ordered.push(decl as i32)
            ordered_paths.push(self.decl_source_path_frontend(i))
            ordered_file_ids.push(self.decl_source_file_id_frontend(i))
            let ci_flag = if i < self.decl_is_c_import.len() as i32: self.decl_is_c_import.get(i as i64) else: 0
            ordered_c_import.push(ci_flag)

    while out.decl_count() > 0:
        out.state.decls.pop()
    for oi in 0..ordered.len() as i32:
        out.add_decl(ordered.get(oi as i64))
    self.decl_source_paths = ordered_paths
    self.decl_source_file_ids = ordered_file_ids
    self.decl_is_c_import = ordered_c_import
    out

fn Zcu.process_imports_frontend(self: Zcu, pool: AstPool) -> AstPool:
    // Three-tier import resolution (later-wins in the decl list):
    //   1. Prelude imports   (lowest priority — first in list)
    //   2. Explicit user imports (middle)
    //   3. Root-file definitions (highest — last in list)
    // Shadowed fn/extern_fn decls are dropped entirely so the sema and
    // codegen never see the duplicate.
    var merged_pool = pool
    let initial_count = merged_pool.decl_count()
    var prelude_ordered: Vec[i32] = Vec.new()
    var prelude_paths: Vec[str] = Vec.new()
    var prelude_file_ids: Vec[i32] = Vec.new()
    var user_import_ordered: Vec[i32] = Vec.new()
    var user_import_paths: Vec[str] = Vec.new()
    var user_import_file_ids: Vec[i32] = Vec.new()
    var root_ordered: Vec[i32] = Vec.new()
    var root_paths: Vec[str] = Vec.new()
    var root_file_ids: Vec[i32] = Vec.new()

    // Phase 1: Expand prelude USE (position 0) and its transitive imports.
    let has_prelude = self.prelude_mode != PRELUDE_NONE() and initial_count > 0 and merged_pool.kind(merged_pool.get_decl(0)) == NodeKind.NK_USE_DECL
    if has_prelude:
        let first = merged_pool.get_decl(0)
        let ps = merged_pool.get_data0(first)
        let pc = merged_pool.get_data1(first)
        if pc > 0:
            let pname = self.use_path_name_frontend(merged_pool, ps, pc)
            let fpath = self.resolve_module_path_frontend(pname, self.decl_source_dir_frontend(0))
            if fpath.len() > 0 and self.has_imported_path(fpath) == 0:
                self.add_imported_path(fpath)
                merged_pool = self.parse_imported_file_frontend(fpath, merged_pool)
            else if fpath.len() == 0:
                self.emit_missing_import_frontend(merged_pool, first)
        // Scan all decls added by prelude expansion (from initial_count onward).
        // Nested USE decls get expanded transitively.
        var pi = initial_count
        while pi < merged_pool.decl_count():
            let decl = merged_pool.get_decl(pi)
            let kind = merged_pool.kind(decl)
            if kind != NodeKind.NK_USE_DECL:
                prelude_ordered.push(decl as i32)
                prelude_paths.push(self.decl_source_path_frontend(pi))
                prelude_file_ids.push(self.decl_source_file_id_frontend(pi))
                pi = pi + 1
                continue
            let pps = merged_pool.get_data0(decl)
            let ppc = merged_pool.get_data1(decl)
            if ppc > 0:
                let ppname = self.use_path_name_frontend(merged_pool, pps, ppc)
                let ppfpath = self.resolve_module_path_frontend(ppname, self.decl_source_dir_frontend(pi))
                if ppfpath.len() > 0 and self.has_imported_path(ppfpath) == 0:
                    self.add_imported_path(ppfpath)
                    merged_pool = self.parse_imported_file_frontend(ppfpath, merged_pool)
                else if ppfpath.len() == 0:
                    self.emit_missing_import_frontend(merged_pool, decl)
            pi = pi + 1
    let after_prelude = merged_pool.decl_count()

    // Phase 2: Process root-file decls (positions 1..initial_count-1 if prelude,
    // 0..initial_count-1 if no prelude). Expand user USE decls; collect non-USE decls.
    let user_start = if has_prelude: 1 else: 0
    for ui in user_start..initial_count:
        let decl = merged_pool.get_decl(ui)
        let kind = merged_pool.kind(decl)
        if kind != NodeKind.NK_USE_DECL:
            root_ordered.push(decl as i32)
            root_paths.push(self.decl_source_path_frontend(ui))
            root_file_ids.push(self.decl_source_file_id_frontend(ui))
            continue
        let ups = merged_pool.get_data0(decl)
        let upc = merged_pool.get_data1(decl)
        if upc > 0:
            let upname = self.use_path_name_frontend(merged_pool, ups, upc)
            let upfpath = self.resolve_module_path_frontend(upname, self.decl_source_dir_frontend(ui))
            if upfpath.len() > 0 and self.has_imported_path(upfpath) == 0:
                self.add_imported_path(upfpath)
                merged_pool = self.parse_imported_file_frontend(upfpath, merged_pool)
            else if upfpath.len() == 0:
                self.emit_missing_import_frontend(merged_pool, decl)

    // Scan decls added by user-import expansion (from after_prelude onward).
    var ui2 = after_prelude
    while ui2 < merged_pool.decl_count():
        let decl = merged_pool.get_decl(ui2)
        let kind = merged_pool.kind(decl)
        if kind != NodeKind.NK_USE_DECL:
            user_import_ordered.push(decl as i32)
            user_import_paths.push(self.decl_source_path_frontend(ui2))
            user_import_file_ids.push(self.decl_source_file_id_frontend(ui2))
            ui2 = ui2 + 1
            continue
        let ups = merged_pool.get_data0(decl)
        let upc = merged_pool.get_data1(decl)
        if upc > 0:
            let upname = self.use_path_name_frontend(merged_pool, ups, upc)
            let upfpath = self.resolve_module_path_frontend(upname, self.decl_source_dir_frontend(ui2))
            if upfpath.len() > 0 and self.has_imported_path(upfpath) == 0:
                self.add_imported_path(upfpath)
                merged_pool = self.parse_imported_file_frontend(upfpath, merged_pool)
            else if upfpath.len() == 0:
                self.emit_missing_import_frontend(merged_pool, decl)
        ui2 = ui2 + 1

    let prelude_reordered = self.reorder_import_tier_frontend(prelude_ordered, prelude_paths, prelude_file_ids)
    prelude_ordered = prelude_reordered.decls
    prelude_paths = prelude_reordered.paths
    prelude_file_ids = prelude_reordered.file_ids

    let user_reordered = self.reorder_import_tier_frontend(user_import_ordered, user_import_paths, user_import_file_ids)
    user_import_ordered = user_reordered.decls
    user_import_paths = user_reordered.paths
    user_import_file_ids = user_reordered.file_ids

    // Collect fn names from higher-priority tiers for deduplication.
    var root_fn_names: Vec[i32] = Vec.new()
    for ri in 0..root_ordered.len() as i32:
        let rd = root_ordered.get(ri as i64)
        let rk = merged_pool.kind(rd)
        if rk == NodeKind.NK_FN_DECL or rk == NodeKind.NK_EXTERN_FN:
            root_fn_names.push(merged_pool.get_data0(rd))

    var user_fn_names: Vec[i32] = Vec.new()
    for ui in 0..user_import_ordered.len() as i32:
        let ud = user_import_ordered.get(ui as i64)
        let uk = merged_pool.kind(ud)
        if uk == NodeKind.NK_FN_DECL or uk == NodeKind.NK_EXTERN_FN:
            user_fn_names.push(merged_pool.get_data0(ud))

    // Rebuild decl list: prelude → user imports → root.
    // Drop fn/extern_fn decls shadowed by a higher-priority tier.
    while merged_pool.decl_count() > 0:
        merged_pool.state.decls.pop()
    let rebuilt_paths: Vec[str] = Vec.new()
    let rebuilt_file_ids: Vec[i32] = Vec.new()
    // Combine user + root fn names for prelude cross-tier shadowing.
    var higher_fn_names: Vec[i32] = Vec.new()
    for hi in 0..root_fn_names.len() as i32:
        higher_fn_names.push(root_fn_names.get(hi as i64))
    for hi in 0..user_fn_names.len() as i32:
        higher_fn_names.push(user_fn_names.get(hi as i64))
    for oi in 0..prelude_ordered.len() as i32:
        let id = prelude_ordered.get(oi as i64)
        let ik = merged_pool.kind(id)
        if (ik == NodeKind.NK_FN_DECL or ik == NodeKind.NK_EXTERN_FN) and frontend_fn_shadowed_in_tier(prelude_ordered, merged_pool, oi, higher_fn_names):
            // Error when a prelude fn (with a body) is shadowed by an extern fn
            // (no body). The extern silently replaces the real function with an
            // unresolved C symbol, causing a cryptic linker error later.
            if ik == NodeKind.NK_FN_DECL:
                let shadowed_name = merged_pool.get_data0(id)
                if frontend_name_shadowed_by_extern(root_ordered, merged_pool, shadowed_name):
                    let sname = self.pool.resolve(shadowed_name)
                    self.diagnostics.emit(Diagnostic.err(f"extern fn '{sname}' shadows prelude function '{sname}'", Span { file: 0, start: merged_pool.get_start(id), end: merged_pool.get_end(id) }))
            continue
        if ik == NodeKind.NK_EXTERN_VAR:
            if frontend_extern_var_shadowed_in_tier(prelude_ordered, merged_pool, self.pool, oi) or frontend_extern_var_shadowed_by_tier(user_import_ordered, merged_pool, self.pool, id) or frontend_extern_var_shadowed_by_tier(root_ordered, merged_pool, self.pool, id):
                continue
        merged_pool.add_decl(id)
        rebuilt_paths.push(prelude_paths.get(oi as i64))
        rebuilt_file_ids.push(prelude_file_ids.get(oi as i64))
    for oi in 0..user_import_ordered.len() as i32:
        let id = user_import_ordered.get(oi as i64)
        let ik = merged_pool.kind(id)
        if (ik == NodeKind.NK_FN_DECL or ik == NodeKind.NK_EXTERN_FN) and frontend_fn_shadowed_in_tier(user_import_ordered, merged_pool, oi, root_fn_names):
            continue
        if ik == NodeKind.NK_EXTERN_VAR:
            if frontend_extern_var_shadowed_in_tier(user_import_ordered, merged_pool, self.pool, oi) or frontend_extern_var_shadowed_by_tier(root_ordered, merged_pool, self.pool, id):
                continue
        merged_pool.add_decl(id)
        rebuilt_paths.push(user_import_paths.get(oi as i64))
        rebuilt_file_ids.push(user_import_file_ids.get(oi as i64))
    for oi in 0..root_ordered.len() as i32:
        let id = root_ordered.get(oi as i64)
        let ik = merged_pool.kind(id)
        if ik == NodeKind.NK_EXTERN_VAR and frontend_extern_var_shadowed_in_tier(root_ordered, merged_pool, self.pool, oi):
            continue
        merged_pool.add_decl(id)
        rebuilt_paths.push(root_paths.get(oi as i64))
        rebuilt_file_ids.push(root_file_ids.get(oi as i64))
    self.decl_source_paths = rebuilt_paths
    self.decl_source_file_ids = rebuilt_file_ids
    merged_pool

fn frontend_name_shadowed_by_extern(tier: Vec[i32], pool: AstPool, name: i32) -> bool:
    for i in 0..tier.len() as i32:
        let d = tier.get(i as i64)
        if pool.kind(d) == NodeKind.NK_EXTERN_FN and pool.get_data0(d) == name:
            return true
    false

fn frontend_fn_decl_rank(kind: i32) -> i32:
    if kind == NodeKind.NK_FN_DECL:
        return 2
    if kind == NodeKind.NK_EXTERN_FN:
        return 1
    0

fn frontend_fn_shadowed_in_tier(tier: Vec[i32], pool: AstPool, idx: i32, higher_names: Vec[i32]) -> bool:
    // Check if this fn is shadowed by a higher-priority tier.
    let current = tier.get(idx as i64)
    let current_kind = pool.kind(current)
    let iname = pool.get_data0(current)
    if frontend_vec_contains_i32(higher_names, iname):
        return true

    // Within-tier precedence:
    // - a real fn beats any extern fn of the same name, regardless of order
    // - otherwise, a later decl of the same rank wins
    if current_kind == NodeKind.NK_EXTERN_FN:
        for j in 0..tier.len() as i32:
            if j == idx:
                continue
            let jd = tier.get(j as i64)
            if pool.kind(jd) == NodeKind.NK_FN_DECL and pool.get_data0(jd) == iname:
                return true
        return false

    let current_rank = frontend_fn_decl_rank(current_kind)
    var j = idx + 1
    while j < tier.len() as i32:
        let jd = tier.get(j as i64)
        let jk = pool.kind(jd)
        if (jk == NodeKind.NK_FN_DECL or jk == NodeKind.NK_EXTERN_FN) and pool.get_data0(jd) == iname:
            let other_rank = frontend_fn_decl_rank(jk)
            if other_rank >= current_rank:
                return true
        j = j + 1
    false

fn frontend_global_decl_mut(pool: AstPool, decl: i32) -> i32:
    let kind = pool.kind(decl)
    if kind == NodeKind.NK_EXTERN_VAR:
        return if pool.get_data2(decl) != 0: 1 else: 0
    if kind == NodeKind.NK_LET_DECL:
        return pool.get_data2(decl) % 2
    -1

fn frontend_global_decl_type_text(pool: AstPool, intern: InternPool, decl: i32) -> str:
    let kind = pool.kind(decl)
    if kind == NodeKind.NK_EXTERN_VAR:
        return render_type_expr(pool, intern, (pool.get_data1(decl)) as NodeId)
    if kind == NodeKind.NK_LET_DECL:
        let type_ann = top_level_let_type_ann(pool, pool.get_data2(decl))
        if type_ann != 0:
            return render_type_expr(pool, intern, (type_ann) as NodeId)
    ""

fn frontend_extern_var_matches_decl(pool: AstPool, intern: InternPool, decl: i32, other: i32) -> bool:
    if pool.kind(decl) != NodeKind.NK_EXTERN_VAR:
        return false
    let other_kind = pool.kind(other)
    if other_kind != NodeKind.NK_EXTERN_VAR and other_kind != NodeKind.NK_LET_DECL:
        return false
    if pool.get_data0(other) != pool.get_data0(decl):
        return false
    if frontend_global_decl_mut(pool, other) != frontend_global_decl_mut(pool, decl):
        return false
    let decl_type = frontend_global_decl_type_text(pool, intern, decl)
    let other_type = frontend_global_decl_type_text(pool, intern, other)
    if decl_type.len() == 0 or other_type.len() == 0:
        return false
    other_type == decl_type

fn frontend_extern_var_shadowed_by_tier(tier: Vec[i32], pool: AstPool, intern: InternPool, decl: i32) -> bool:
    for i in 0..tier.len() as i32:
        if frontend_extern_var_matches_decl(pool, intern, decl, tier.get(i as i64)):
            return true
    false

fn frontend_extern_var_shadowed_in_tier(tier: Vec[i32], pool: AstPool, intern: InternPool, idx: i32) -> bool:
    let decl = tier.get(idx as i64)
    for j in 0..tier.len() as i32:
        if j == idx:
            continue
        let jd = tier.get(j as i64)
        if pool.kind(jd) == NodeKind.NK_LET_DECL and frontend_extern_var_matches_decl(pool, intern, decl, jd):
            return true
    var j = idx + 1
    while j < tier.len() as i32:
        let jd = tier.get(j as i64)
        if pool.kind(jd) == NodeKind.NK_EXTERN_VAR:
            if frontend_extern_var_matches_decl(pool, intern, decl, jd):
                return true
        j = j + 1
    false

fn frontend_vec_contains_i32(v: Vec[i32], target: i32) -> bool:
    for i in 0..v.len() as i32:
        if v.get(i as i64) == target:
            return true
    false

fn Zcu.find_module_id_by_path_frontend(self: Zcu, path: str) -> i32:
    for mi in 0..self.last_resolved.modules.len() as i32:
        let mod = self.last_resolved.modules.get(mi as i64)
        if mod.path == path:
            return mod.module_id
    -1

type DepOrderAccumState {
    order: Vec[str],
}

type DepOrderAccum {
    state: *mut DepOrderAccumState,
}

fn DepOrderAccum.new() -> DepOrderAccum:
    let ptr = with_alloc(32) as *mut DepOrderAccumState
    unsafe:
        *ptr = DepOrderAccumState { order: Vec.new() }
    DepOrderAccum { state: ptr }

type ReorderedTier {
    decls: Vec[i32],
    paths: Vec[str],
    file_ids: Vec[i32],
}

fn Zcu.collect_module_dependency_order_frontend(self: Zcu, path: str, wanted_paths: HashMap[str, i32], seen_paths: HashMap[str, i32], accum: DepOrderAccum):
    if path.len() == 0:
        return
    if seen_paths.contains(path):
        return
    seen_paths.insert(frontend_owned_text(path), 1)
    let module_id = self.find_module_id_by_path_frontend(path)
    if module_id >= 0:
        let mod = self.last_resolved.modules.get(module_id as i64)
        for ii in 0..mod.import_count:
            let imp = self.last_resolved.imports.get((mod.import_start + ii) as i64)
            if imp.target_module < 0:
                continue
            let dep = self.last_resolved.modules.get(imp.target_module as i64)
            if wanted_paths.contains(dep.path):
                self.collect_module_dependency_order_frontend(dep.path, wanted_paths, seen_paths, accum)
    accum.state.order.push(frontend_owned_text(path))

fn Zcu.reorder_import_tier_frontend(self: Zcu, decls: Vec[i32], paths: Vec[str], file_ids: Vec[i32]) -> ReorderedTier:
    let wanted_paths: HashMap[str, i32] = HashMap.new()
    let first_seen_paths: Vec[str] = Vec.new()
    for i in 0..paths.len() as i32:
        let path = paths.get(i as i64)
        if path.len() == 0:
            continue
        if wanted_paths.contains(path):
            continue
        wanted_paths.insert(frontend_owned_text(path), 1)
        first_seen_paths.push(frontend_owned_text(path))

    let accum = DepOrderAccum.new()
    let seen_paths: HashMap[str, i32] = HashMap.new()
    for i in 0..first_seen_paths.len() as i32:
        self.collect_module_dependency_order_frontend(first_seen_paths.get(i as i64), wanted_paths, seen_paths, accum)

    let module_order = accum.state.order
    let out_decls: Vec[i32] = Vec.new()
    let out_paths: Vec[str] = Vec.new()
    let out_file_ids: Vec[i32] = Vec.new()
    for oi in 0..module_order.len() as i32:
        let module_path = module_order.get(oi as i64)
        for di in 0..decls.len() as i32:
            if paths.get(di as i64) != module_path:
                continue
            out_decls.push(decls.get(di as i64))
            out_paths.push(frontend_owned_text(paths.get(di as i64)))
            out_file_ids.push(file_ids.get(di as i64))
    for di in 0..decls.len() as i32:
        let path = paths.get(di as i64)
        if path.len() != 0:
            continue
        out_decls.push(decls.get(di as i64))
        out_paths.push(frontend_owned_text(path))
        out_file_ids.push(file_ids.get(di as i64))
    ReorderedTier { decls: out_decls, paths: out_paths, file_ids: out_file_ids }

fn frontend_parent_module_rel(module_rel: str) -> str:
    var last_slash = -1
    for i in 0..module_rel.len():
        if module_rel[i] == 47:
            last_slash = i as i32
    if last_slash <= 0:
        return ""
    module_rel.slice(0, last_slash as i64)

fn frontend_resolve_module_rel(module_dir: str, rel_path: str) -> str:
    let cand1 = resolve_join(module_dir, rel_path)
    if resolve_file_exists(cand1):
        return cand1

    let parent_walk = resolve_parent_lib_candidate(module_dir, rel_path)
    if parent_walk.len() > 0:
        return parent_walk

    let rooted = resolve_project_root_candidate(module_dir, rel_path)
    if rooted.len() > 0:
        return rooted

    let cand5 = resolve_join("src", rel_path)
    if resolve_file_exists(cand5):
        return cand5

    let cand6 = resolve_join("lib", rel_path)
    if resolve_file_exists(cand6):
        return cand6

    ""

fn Zcu.use_path_name_frontend(self: Zcu, pool: AstPool, path_start: i32, path_count: i32) -> str:
    var path = ""
    for pi in 0..path_count:
        if pi > 0:
            path = path ++ "/"
        let seg = pool.get_extra(path_start + pi)
        path = path ++ self.pool.resolve(seg)
    path

fn Zcu.resolve_module_path_frontend(self: Zcu, module_name: str, source_dir_raw: str) -> str:
    let module_rel = frontend_normalize_module_path(module_name)
    let rel_primary = module_rel ++ ".w"
    let rel_fallback = if frontend_parent_module_rel(module_rel).len() > 0: frontend_parent_module_rel(module_rel) ++ ".w" else: ""

    if embedded_std_is_module_rel(module_rel):
        let embedded_primary = embedded_std_resolve_path(rel_primary)
        if embedded_primary.len() > 0:
            return embedded_primary
        if rel_fallback.len() > 0:
            let embedded_fallback = embedded_std_resolve_path(rel_fallback)
            if embedded_fallback.len() > 0:
                return embedded_fallback
        // Not embedded — fall through to filesystem resolution

    let source_dir = if source_dir_raw.len() > 0: source_dir_raw else: self.source_dir
    let has_root_fallback = source_dir != self.source_dir

    let primary = frontend_resolve_module_rel(source_dir, rel_primary)
    if primary.len() > 0:
        return primary
    if has_root_fallback:
        let root_primary = frontend_resolve_module_rel(self.source_dir, rel_primary)
        if root_primary.len() > 0:
            return root_primary
    if rel_fallback.len() > 0:
        let fallback = frontend_resolve_module_rel(source_dir, rel_fallback)
        if fallback.len() > 0:
            return fallback
        if has_root_fallback:
            return frontend_resolve_module_rel(self.source_dir, rel_fallback)
    ""

fn Zcu.parse_imported_file_frontend(self: Zcu, path: str, target_pool: AstPool) -> AstPool:
    let embedded_rel = embedded_std_rel_path(path)
    let text = if embedded_rel.len() > 0: embedded_std_source(embedded_rel) else: with_fs_read_file(path)
    if text.len() == 0:
        return target_pool

    let before = target_pool.decl_count()
    let file_id = self.next_file_id
    self.next_file_id = self.next_file_id + 1

    var lexer = Lexer.init(text, file_id)
    let tokens = lexer.tokenize()

    var parser = Parser.init_with_pool(tokens, text, file_id, self.pool, self.diagnostics, target_pool)
    let merged_pool = parser.parse_module()
    self.pool = parser.intern
    self.diagnostics = parser.diags
    self.append_decl_source_paths(merged_pool.decl_count() - before, path, file_id)
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
