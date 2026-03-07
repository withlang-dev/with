use std.prelude_core

use Ast
use Lexer
use Parser
use Source
use Sema
use Resolve
use Span
use Diagnostic
use compiler.Zcu

extern fn with_fs_read_file(path: str) -> str
extern fn with_eprintln(s: str) -> void
extern fn with_getenv_str(name: str) -> str

// Frontend pipeline: lex -> parse -> import resolution -> sema.

fn count_non_use_decls_frontend(pool: AstPool) -> i32:
    var count = 0
    for di in 0..pool.decl_count():
        let decl = pool.get_decl(di)
        if pool.kind(decl) != NK_USE_DECL():
            count = count + 1
    count

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

fn Zcu.expand_c_imports_frontend(self: Zcu, pool: AstPool) -> AstPool:
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
        let cache_key = self.c_import_cache_key_frontend(out, decl, header_spec)

        var synthetic = ""
        let cached = self.c_import_cache_lookup(cache_key)
        if cached.len() > 0:
            if self.trace_c_import_cache != 0:
                with_eprintln("c_import cache hit")
            synthetic = cached
        else:
            if self.trace_c_import_cache != 0:
                with_eprintln("c_import cache miss")
            synthetic = self.c_import_expand_header_spec_frontend(header_spec, decl)
            if self.diagnostics.has_errors():
                continue
            self.c_import_cache_store(cache_key, synthetic)

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

fn Zcu.c_import_cache_key_frontend(self: Zcu, pool: AstPool, decl: i32, header_spec: str) -> str:
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
        if spec.byte_at(i as i64) == 42:
            star_count = star_count + 1

    var base = "i32"
    if c_import_str_contains(spec, "unsigned long long"):
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

fn Zcu.compile_file_frontend(self: Zcu, path: str) -> AstPool:
    if zcu_debug_init_enabled() != 0:
        with_eprintln("[frontend] compile_file:start " ++ path)
    let source_dir = frontend_dirname(path)
    self.reset_for_new_invocation(source_dir, path, "")

    let text = with_fs_read_file(path)
    if text.len() == 0:
        with_eprintln("error: cannot open '" ++ path ++ "'")
        self.set_resolve_snapshot(ResolveResult.init(), path)
        return AstPool.new()

    self.set_current_source(source_dir, path, text)
    if zcu_debug_init_enabled() != 0:
        with_eprintln("[frontend] compile_file:source_ready bytes=" ++ int_to_string(text.len() as i32))
    let pool = self.compile_source_frontend(text, path, 0)
    if pool.decl_count() == 0 and not self.diagnostics.has_errors():
        with_eprintln("error: compiler produced an empty module for '" ++ path ++ "'")
    pool

fn Zcu.compile_source_frontend(self: Zcu, text: str, name: str, file_id: i32) -> AstPool:
    if zcu_debug_init_enabled() != 0:
        with_eprintln("[frontend] compile_source:lex")
    // Phase 1: Lex.
    var lexer = Lexer.init(text, file_id)
    let tokens = lexer.tokenize()

    if zcu_debug_init_enabled() != 0:
        with_eprintln("[frontend] compile_source:parse")
    // Phase 2: Parse.
    var parser = Parser.init(tokens, text, file_id, self.pool, self.diagnostics)
    var pool = parser.parse_module()
    let root_local_decl_count = count_non_use_decls_frontend(pool)

    // Propagate parser updates (intern + diagnostics) back into ZCU.
    self.pool = parser.intern
    self.diagnostics = parser.diags

    if self.diagnostics.has_errors():
        let source = Source.from_string(name, text, file_id)
        self.diagnostics.render_all(source)
        self.set_resolve_snapshot(ResolveResult.init(), name)
        return AstPool.new()

    if zcu_debug_init_enabled() != 0:
        with_eprintln("[frontend] compile_source:inject_prelude")
    pool = self.inject_prelude_frontend(pool)
    if self.diagnostics.has_errors():
        let source = Source.from_string(name, text, file_id)
        self.diagnostics.render_all(source)
        self.set_resolve_snapshot(ResolveResult.init(), name)
        return AstPool.new()

    if zcu_debug_init_enabled() != 0:
        with_eprintln("[frontend] compile_source:resolve")
    // Wave 4: sidecar resolved artifact.
    let artifacts = resolve_from_root_pool(name, text, file_id, pool, self.pool, self.diagnostics, false)
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
        with_eprintln("[frontend] compile_source:imports")
    // Build the sema/codegen pool via recursive syntactic import expansion.
    // This still sees implicit prelude imports because `inject_prelude_frontend`
    // materializes them as normal `use` declarations in the root pool.
    pool = self.process_imports_frontend(pool)
    self.trace_c_import_cache = self.read_trace_c_import_cache_frontend()
    pool = self.expand_c_imports_frontend(pool)
    pool.set_local_decl_count(root_local_decl_count)
    self.set_typed_snapshot("", pool)

    if self.diagnostics.has_errors():
        let source = Source.from_string(name, text, file_id)
        self.diagnostics.render_all(source)
        self.set_typed_snapshot("", AstPool.new())
        return AstPool.new()

    if zcu_debug_init_enabled() != 0:
        with_eprintln("[frontend] compile_source:sema")
    // Phase 3: Semantic analysis.
    var sema = Sema.init(self.pool, self.diagnostics, pool)
    sema.source_text = text
    sema.check_module()
    self.sync_from_sema(sema)
    // Keep typed sidecars for downstream stages, but materialize the textual
    // typed dump only when explicitly requested.
    self.last_typed_dump = ""

    if self.diagnostics.has_errors():
        let source = Source.from_string(name, text, file_id)
        self.diagnostics.render_all(source)
        self.set_typed_snapshot("", AstPool.new())
        return AstPool.new()

    if pool.decl_count() == 0:
        with_eprintln("error: parser returned an empty module without diagnostics for '" ++ name ++ "'")
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
        var parser = Parser.init_with_pool(tokens, text, mod.file_id, self.pool, self.diagnostics, merged_pool)
        merged_pool = parser.parse_module()
        self.pool = parser.intern
        self.diagnostics = parser.diags

    self.strip_use_decls_frontend(merged_pool)

fn Zcu.strip_use_decls_frontend(self: Zcu, pool: AstPool) -> AstPool:
    let _ = self
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

fn Zcu.process_imports_frontend(self: Zcu, pool: AstPool) -> AstPool:
    // Keep declaration order stable by replacing each `use` with imported decls,
    // scanning newly appended declarations so nested imports are expanded too.
    var merged_pool = pool
    var ordered: Vec[i32] = Vec.new()
    var i = 0
    while i < merged_pool.decl_count():
        let decl = merged_pool.get_decl(i)
        let kind = merged_pool.kind(decl)
        if kind != NK_USE_DECL():
            ordered.push(decl)
            i = i + 1
            continue

        let path_start = merged_pool.get_data0(decl)
        let path_count = merged_pool.get_data1(decl)
        if path_count <= 0:
            i = i + 1
            continue

        let path_name = self.use_path_name_frontend(merged_pool, path_start, path_count)
        let file_path = self.resolve_module_path_frontend(path_name)
        if file_path.len() == 0:
            i = i + 1
            continue

        if self.has_imported_path(file_path) != 0:
            i = i + 1
            continue

        self.add_imported_path(file_path)
        merged_pool = self.parse_imported_file_frontend(file_path, merged_pool)
        i = i + 1

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
