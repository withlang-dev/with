// Lsp — Language Server Protocol handler for `with lsp`.
//
// Speaks JSON-RPC 2.0 over stdio using Content-Length framing.
// Reuses the compiler frontend for diagnostics.

use Ast
use Lexer
use Token
use Parser
use InternPool
use Diagnostic
use Source
use Compilation
use Fmt
use compiler.Frontend
use compiler.Zcu

extern fn with_eprint(s: str) -> void
extern fn with_read_line_stdin() -> str
extern fn with_read_bytes_stdin(count: i32) -> str
extern fn with_write_stdout(s: str) -> void
extern fn with_flush_stdout() -> void
extern fn with_embedded_std_list_modules() -> str

// ── JSON-RPC framing ─────────────────────────────────────────

fn lsp_read_message() -> str:
    var content_length = 0
    while true:
        let line = with_read_line_stdin()
        if line.len() == 0:
            break
        if line.starts_with("Content-Length: "):
            content_length = lsp_parse_int(line.slice(16, line.len()))
    if content_length <= 0:
        return ""
    with_read_bytes_stdin(content_length)

fn lsp_write_response(json: str):
    let len_str = int_to_string(json.len() as i32)
    with_write_stdout("Content-Length: " ++ len_str ++ "\r\n\r\n")
    with_write_stdout(json)
    with_flush_stdout()

fn lsp_parse_int(s: str) -> i32:
    var result = 0
    for i in 0..s.len() as i32:
        let ch = s.byte_at(i as i64)
        if ch >= 48 and ch <= 57:
            result = result * 10 + (ch - 48)
    result

// ── Minimal JSON helpers ─────────────────────────────────────

fn json_get_string(json: str, key: str) -> str:
    let search = "\"" ++ key ++ "\":"
    var pos = lsp_find_substr(json, search)
    if pos < 0:
        return ""
    pos = pos + search.len() as i32
    while pos < json.len() as i32 and json.byte_at(pos as i64) == 32:
        pos = pos + 1
    if pos >= json.len() as i32 or json.byte_at(pos as i64) != 34:
        return ""
    pos = pos + 1
    var end = pos
    while end < json.len() as i32 and json.byte_at(end as i64) != 34:
        if json.byte_at(end as i64) == 92:
            end = end + 1
        end = end + 1
    json.slice(pos as i64, end as i64)

fn json_get_int(json: str, key: str) -> i32:
    let search = "\"" ++ key ++ "\":"
    var pos = lsp_find_substr(json, search)
    if pos < 0:
        return -1
    pos = pos + search.len() as i32
    while pos < json.len() as i32 and json.byte_at(pos as i64) == 32:
        pos = pos + 1
    lsp_parse_int(json.slice(pos as i64, json.len()))

fn json_get_object(json: str, key: str) -> str:
    let search = "\"" ++ key ++ "\":"
    var pos = lsp_find_substr(json, search)
    if pos < 0:
        return ""
    pos = pos + search.len() as i32
    while pos < json.len() as i32 and json.byte_at(pos as i64) == 32:
        pos = pos + 1
    if pos >= json.len() as i32 or json.byte_at(pos as i64) != 123:
        return ""
    var depth = 1
    var end = pos + 1
    while end < json.len() as i32 and depth > 0:
        let ch = json.byte_at(end as i64)
        if ch == 123:
            depth = depth + 1
        else if ch == 125:
            depth = depth - 1
        else if ch == 34:
            end = end + 1
            while end < json.len() as i32 and json.byte_at(end as i64) != 34:
                if json.byte_at(end as i64) == 92:
                    end = end + 1
                end = end + 1
        end = end + 1
    json.slice(pos as i64, end as i64)

fn lsp_find_substr(haystack: str, needle: str) -> i32:
    let h_len = haystack.len() as i32
    let n_len = needle.len() as i32
    if n_len == 0 or n_len > h_len:
        return -1
    for i in 0..(h_len - n_len + 1):
        var ok = true
        for j in 0..n_len:
            if haystack.byte_at((i + j) as i64) != needle.byte_at(j as i64):
                ok = false
                break
        if ok:
            return i
    -1

fn json_escape(s: str) -> str:
    var out = ""
    for i in 0..s.len() as i32:
        let ch = s.byte_at(i as i64)
        if ch == 34:
            out = out ++ "\\\""
        else if ch == 92:
            out = out ++ "\\\\"
        else if ch == 10:
            out = out ++ "\\n"
        else if ch == 13:
            out = out ++ "\\r"
        else if ch == 9:
            out = out ++ "\\t"
        else:
            out = out ++ s.slice(i as i64, (i + 1) as i64)
    out

// ── JSON builders (avoid f-string brace complexity) ──────────

fn jobj_start() -> str:
    str_from_byte(123)

fn jobj_end() -> str:
    str_from_byte(125)

fn jarr_start() -> str:
    "["

fn jarr_end() -> str:
    "]"

fn jkv_str(key: str, val: str) -> str:
    "\"" ++ key ++ "\":\"" ++ json_escape(val) ++ "\""

fn jkv_int(key: str, val: i32) -> str:
    "\"" ++ key ++ "\":" ++ int_to_string(val)

fn jkv_raw(key: str, val: str) -> str:
    "\"" ++ key ++ "\":" ++ val

fn jkv_null(key: str) -> str:
    "\"" ++ key ++ "\":null"

fn jkv_bool(key: str, val: bool) -> str:
    "\"" ++ key ++ "\":" ++ (if val: "true" else: "false")

fn jpos(line: i32, col: i32) -> str:
    jobj_start() ++ jkv_int("line", line) ++ "," ++ jkv_int("character", col) ++ jobj_end()

fn jrange(sl: i32, sc: i32, el: i32, ec: i32) -> str:
    jobj_start() ++ jkv_raw("start", jpos(sl, sc)) ++ "," ++ jkv_raw("end", jpos(el, ec)) ++ jobj_end()

fn jrpc_result(id: i32, result: str) -> str:
    jobj_start() ++ jkv_str("jsonrpc", "2.0") ++ "," ++ jkv_int("id", id) ++ "," ++ jkv_raw("result", result) ++ jobj_end()

fn jrpc_result_null(id: i32) -> str:
    jobj_start() ++ jkv_str("jsonrpc", "2.0") ++ "," ++ jkv_int("id", id) ++ "," ++ jkv_null("result") ++ jobj_end()

fn jrpc_notification(method: str, params: str) -> str:
    jobj_start() ++ jkv_str("jsonrpc", "2.0") ++ "," ++ jkv_str("method", method) ++ "," ++ jkv_raw("params", params) ++ jobj_end()

fn jrpc_error(id: i32, code: i32, message: str) -> str:
    let err = jobj_start() ++ jkv_int("code", code) ++ "," ++ jkv_str("message", message) ++ jobj_end()
    jobj_start() ++ jkv_str("jsonrpc", "2.0") ++ "," ++ jkv_int("id", id) ++ "," ++ jkv_raw("error", err) ++ jobj_end()

// ── Document state + analysis cache ──────────────────────────

type LspDocument {
    uri: str,
    path: str,
    text: str,
    version: i32,
    // Cached analysis results (invalidated when text changes)
    cached_text_len: i32,
    cached_pool: AstPool,
    cached_intern: InternPool,
    cached_diags: DiagnosticList,
    cache_valid: bool,
}

fn LspDocument.new(uri: str, path: str, text: str, version: i32) -> LspDocument:
    LspDocument {
        uri, path, text, version,
        cached_text_len: 0,
        cached_pool: AstPool.new(),
        cached_intern: InternPool.init(),
        cached_diags: DiagnosticList.init(),
        cache_valid: false,
    }

fn LspDocument.ensure_analyzed(self: LspDocument):
    if self.cache_valid and self.cached_text_len == self.text.len() as i32:
        return
    var comp = Compilation.init()
    comp.set_prelude_mode(0)
    let pool = comp.compile_source_text(self.path, self.text)
    self.cached_pool = pool
    self.cached_intern = comp.zcu.pool
    self.cached_diags = comp.zcu.diagnostics
    self.cached_text_len = self.text.len() as i32
    self.cache_valid = true

fn LspDocument.invalidate(self: LspDocument):
    self.cache_valid = false

type LspState {
    initialized: bool,
    documents: Vec[LspDocument],
}

fn LspState.new() -> LspState:
    LspState { initialized: false, documents: Vec.new() }

fn LspState.find_doc(self: LspState, uri: str) -> i32:
    for i in 0..self.documents.len() as i32:
        if self.documents.get(i as i64).uri == uri:
            return i
    -1

fn LspState.set_doc(self: LspState, uri: str, text: str, version: i32):
    let idx = self.find_doc(uri)
    if idx < 0:
        self.documents.push(LspDocument.new(uri, uri_to_path(uri), text, version))
        return
    // Update text and invalidate cache
    let new_docs: Vec[LspDocument] = Vec.new()
    for i in 0..self.documents.len() as i32:
        if i == idx:
            var doc = LspDocument.new(uri, uri_to_path(uri), text, version)
            new_docs.push(doc)
        else:
            new_docs.push(self.documents.get(i as i64))
    self.documents = new_docs

fn uri_to_path(uri: str) -> str:
    if uri.starts_with("file://"):
        return uri.slice(7, uri.len())
    uri

// ── Line/column utilities ────────────────────────────────────

fn lsp_offset_to_line(text: str, offset: i32) -> i32:
    var line = 0
    var i = 0
    while i < offset and i < text.len() as i32:
        if text.byte_at(i as i64) == 10:
            line = line + 1
        i = i + 1
    line

fn lsp_offset_to_col(text: str, offset: i32) -> i32:
    var col = 0
    var i = 0
    while i < offset and i < text.len() as i32:
        if text.byte_at(i as i64) == 10:
            col = 0
        else:
            col = col + 1
        i = i + 1
    col

fn lsp_line_col_to_offset(text: str, line: i32, col: i32) -> i32:
    var cur_line = 0
    var cur_col = 0
    for i in 0..text.len() as i32:
        if cur_line == line and cur_col == col:
            return i
        if text.byte_at(i as i64) == 10:
            cur_line = cur_line + 1
            cur_col = 0
        else:
            cur_col = cur_col + 1
    text.len() as i32

// ── Diagnostics ──────────────────────────────────────────────

fn lsp_publish_diagnostics(state: LspState, uri: str, text: str):
    let idx = state.find_doc(uri)
    if idx >= 0:
        state.documents.get(idx as i64).ensure_analyzed()

    // Use cached diagnostics if available
    var dl = DiagnosticList.init()
    if idx >= 0 and state.documents.get(idx as i64).cache_valid:
        dl = state.documents.get(idx as i64).cached_diags
    else:
        var comp = Compilation.init()
        comp.set_prelude_mode(0)
        let pool = comp.compile_source_text(uri_to_path(uri), text)
        dl = comp.zcu.diagnostics

    var diags = jarr_start()
    var first = true
    for i in 0..dl.count():
        let d = dl.items.get(i as i64)
        let severity = d.severity
        let sl = lsp_offset_to_line(text, d.primary.start)
        let sc = lsp_offset_to_col(text, d.primary.start)
        var el = sl
        var ec = sc + 1
        if d.primary.end > d.primary.start and d.primary.end <= text.len() as i32:
            el = lsp_offset_to_line(text, d.primary.end)
            ec = lsp_offset_to_col(text, d.primary.end)
        if not first:
            diags = diags ++ ","
        first = false
        let range = jrange(sl, sc, el, ec)
        diags = diags ++ jobj_start() ++ jkv_raw("range", range) ++ "," ++ jkv_int("severity", severity) ++ "," ++ jkv_str("source", "with") ++ "," ++ jkv_str("message", d.message) ++ jobj_end()
    diags = diags ++ jarr_end()

    let params = jobj_start() ++ jkv_str("uri", uri) ++ "," ++ jkv_raw("diagnostics", diags) ++ jobj_end()
    lsp_write_response(jrpc_notification("textDocument/publishDiagnostics", params))

// ── Go to definition ─────────────────────────────────────────

fn lsp_definition(id: i32, state: LspState, uri: str, text: str, line: i32, col: i32):
    let offset = lsp_line_col_to_offset(text, line, col)

    var lexer = Lexer.init(text, 0)
    let tokens = lexer.tokenize()
    var token_text = ""
    for i in 0..tokens.len():
        if offset >= tokens.get_start(i) and offset < tokens.get_end(i):
            if tokens.get_tag(i) == TokenKind.TK_IDENT:
                token_text = text.slice(tokens.get_start(i) as i64, tokens.get_end(i) as i64)
            break

    if token_text.len() == 0:
        lsp_write_response(jrpc_result_null(id))
        return

    let idx = state.find_doc(uri)
    if idx >= 0:
        state.documents.get(idx as i64).ensure_analyzed()
    var pool = AstPool.new()
    var intern = InternPool.init()
    if idx >= 0 and state.documents.get(idx as i64).cache_valid:
        pool = state.documents.get(idx as i64).cached_pool
        intern = state.documents.get(idx as i64).cached_intern
    else:
        var comp = Compilation.init()
        comp.set_prelude_mode(0)
        pool = comp.compile_source_text(uri_to_path(uri), text)
        intern = comp.zcu.pool

    for di in 0..pool.decl_count():
        let decl = pool.get_decl(di)
        let kind = pool.kind(decl)
        if kind == NodeKind.NK_FN_DECL or kind == NodeKind.NK_TYPE_DECL or kind == NodeKind.NK_TRAIT_DECL or kind == NodeKind.NK_LET_DECL:
            let name = intern.resolve(pool.get_data0(decl))
            if name == token_text:
                let ds = pool.get_start(decl)
                let dl = lsp_offset_to_line(text, ds)
                let dc = lsp_offset_to_col(text, ds)
                let loc = jobj_start() ++ jkv_str("uri", uri) ++ "," ++ jkv_raw("range", jrange(dl, dc, dl, dc + name.len() as i32)) ++ jobj_end()
                lsp_write_response(jrpc_result(id, loc))
                return

    lsp_write_response(jrpc_result_null(id))

// ── Hover ────────────────────────────────────────────────────

fn lsp_hover(id: i32, state: LspState, uri: str, text: str, line: i32, col: i32):
    let offset = lsp_line_col_to_offset(text, line, col)

    var lexer = Lexer.init(text, 0)
    let tokens = lexer.tokenize()
    var token_text = ""
    for i in 0..tokens.len():
        if offset >= tokens.get_start(i) and offset < tokens.get_end(i):
            if tokens.get_tag(i) == TokenKind.TK_IDENT:
                token_text = text.slice(tokens.get_start(i) as i64, tokens.get_end(i) as i64)
            break

    if token_text.len() == 0:
        lsp_write_response(jrpc_result_null(id))
        return

    let idx = state.find_doc(uri)
    if idx >= 0:
        state.documents.get(idx as i64).ensure_analyzed()
    var pool = AstPool.new()
    var intern = InternPool.init()
    if idx >= 0 and state.documents.get(idx as i64).cache_valid:
        pool = state.documents.get(idx as i64).cached_pool
        intern = state.documents.get(idx as i64).cached_intern
    else:
        var comp = Compilation.init()
        comp.set_prelude_mode(0)
        pool = comp.compile_source_text(uri_to_path(uri), text)
        intern = comp.zcu.pool

    var hover = ""
    for di in 0..pool.decl_count():
        let decl = pool.get_decl(di)
        let kind = pool.kind(decl)
        if kind == NodeKind.NK_FN_DECL:
            if intern.resolve(pool.get_data0(decl)) == token_text:
                hover = "fn " ++ token_text
                break
        if kind == NodeKind.NK_TYPE_DECL:
            if intern.resolve(pool.get_data0(decl)) == token_text:
                hover = "type " ++ token_text
                break
        if kind == NodeKind.NK_TRAIT_DECL:
            if intern.resolve(pool.get_data0(decl)) == token_text:
                hover = "trait " ++ token_text
                break

    if hover.len() == 0:
        lsp_write_response(jrpc_result_null(id))
        return

    let content = jobj_start() ++ jkv_str("kind", "markdown") ++ "," ++ jkv_str("value", "`" ++ hover ++ "`") ++ jobj_end()
    lsp_write_response(jrpc_result(id, jobj_start() ++ jkv_raw("contents", content) ++ jobj_end()))

// ── Completion ───────────────────────────────────────────────

fn lsp_completion(id: i32, state: LspState, uri: str, text: str, line: i32, col: i32):
    let offset = lsp_line_col_to_offset(text, line, col)

    // Find the line text up to cursor to detect context
    var line_start = offset
    while line_start > 0 and text.byte_at((line_start - 1) as i64) != 10:
        line_start = line_start - 1
    let line_text = text.slice(line_start as i64, offset as i64)

    var items = jarr_start()
    var first = true

    // Context: "use std." → suggest embedded stdlib modules
    if lsp_find_substr(line_text, "use std.") >= 0:
        let modules = lsp_list_embedded_modules("std/")
        for i in 0..modules.len() as i32:
            let m = modules.get(i as i64)
            if not first:
                items = items ++ ","
            first = false
            items = items ++ jobj_start() ++ jkv_str("label", m) ++ "," ++ jkv_int("kind", 9) ++ jobj_end()
        items = items ++ jarr_end()
        lsp_write_response(jrpc_result(id, jobj_start() ++ jkv_raw("items", items) ++ jobj_end()))
        return

    // Context: "use test." → suggest embedded test modules
    if lsp_find_substr(line_text, "use test.") >= 0:
        let test_mods = lsp_list_embedded_modules("test/")
        for i in 0..test_mods.len() as i32:
            let m = test_mods.get(i as i64)
            if not first:
                items = items ++ ","
            first = false
            items = items ++ jobj_start() ++ jkv_str("label", m) ++ "," ++ jkv_int("kind", 9) ++ jobj_end()
        items = items ++ jarr_end()
        lsp_write_response(jrpc_result(id, jobj_start() ++ jkv_raw("items", items) ++ jobj_end()))
        return

    // Scan tokens before cursor for local let/var bindings and fn parameters.
    // This gives scope-aware completion without full sema integration.
    var lexer = Lexer.init(text, 0)
    let tokens = lexer.tokenize()
    let local_names: Vec[str] = Vec.new()
    let seen_locals: Vec[str] = Vec.new()
    var ti = 0
    while ti < tokens.len():
        let tok_start = tokens.get_start(ti)
        if tok_start >= offset:
            break
        let tag = tokens.get_tag(ti)
        // let <name> or var <name>
        if (tag == TokenKind.TK_KW_LET or tag == TokenKind.TK_KW_VAR) and ti + 1 < tokens.len():
            let next_tag = tokens.get_tag(ti + 1)
            if next_tag == TokenKind.TK_IDENT:
                let name = text.slice(tokens.get_start(ti + 1) as i64, tokens.get_end(ti + 1) as i64)
                if lsp_vec_str_contains(seen_locals, name) == 0:
                    local_names.push(name)
                    seen_locals.push(name)
        // fn <name>(<param>: <type>, ...)
        // After fn and ident, look for ( ... ) and collect param names
        if tag == TokenKind.TK_KW_FN and ti + 2 < tokens.len():
            if tokens.get_tag(ti + 1) == TokenKind.TK_IDENT and tokens.get_tag(ti + 2) == TokenKind.TK_L_PAREN:
                var pi = ti + 3
                while pi < tokens.len() and tokens.get_tag(pi) != TokenKind.TK_R_PAREN and tokens.get_start(pi) < offset:
                    if tokens.get_tag(pi) == TokenKind.TK_IDENT:
                        // Check if next is : (parameter pattern)
                        if pi + 1 < tokens.len() and tokens.get_tag(pi + 1) == TokenKind.TK_COLON:
                            let pname = text.slice(tokens.get_start(pi) as i64, tokens.get_end(pi) as i64)
                            if pname != "self" and lsp_vec_str_contains(seen_locals, pname) == 0:
                                local_names.push(pname)
                                seen_locals.push(pname)
                    pi = pi + 1
        ti = ti + 1

    // Emit local variables first (most relevant)
    for li in 0..local_names.len() as i32:
        let lname = local_names.get(li as i64)
        if not first:
            items = items ++ ","
        first = false
        items = items ++ jobj_start() ++ jkv_str("label", lname) ++ "," ++ jkv_int("kind", 6) ++ jobj_end()

    // Then keywords
    let keywords = lsp_keywords()
    for i in 0..keywords.len() as i32:
        let kw = keywords.get(i as i64)
        if not first:
            items = items ++ ","
        first = false
        items = items ++ jobj_start() ++ jkv_str("label", kw) ++ "," ++ jkv_int("kind", 14) ++ jobj_end()

    // Add declarations from the file (use cache)
    let cidx = state.find_doc(uri)
    if cidx >= 0:
        state.documents.get(cidx as i64).ensure_analyzed()
    var pool = AstPool.new()
    var intern = InternPool.init()
    if cidx >= 0 and state.documents.get(cidx as i64).cache_valid:
        pool = state.documents.get(cidx as i64).cached_pool
        intern = state.documents.get(cidx as i64).cached_intern
    else:
        var comp = Compilation.init()
        comp.set_prelude_mode(0)
        pool = comp.compile_source_text(uri_to_path(uri), text)
        intern = comp.zcu.pool

    for di in 0..pool.decl_count():
        let decl = pool.get_decl(di)
        let kind = pool.kind(decl)
        var label = ""
        var ck = 0
        if kind == NodeKind.NK_FN_DECL:
            label = intern.resolve(pool.get_data0(decl))
            ck = 3
        else if kind == NodeKind.NK_TYPE_DECL:
            label = intern.resolve(pool.get_data0(decl))
            ck = 22
        else if kind == NodeKind.NK_TRAIT_DECL:
            label = intern.resolve(pool.get_data0(decl))
            ck = 8
        else if kind == NodeKind.NK_LET_DECL:
            label = intern.resolve(pool.get_data0(decl))
            ck = 6
        if label.len() > 0:
            if not first:
                items = items ++ ","
            first = false
            items = items ++ jobj_start() ++ jkv_str("label", label) ++ "," ++ jkv_int("kind", ck) ++ jobj_end()

    items = items ++ jarr_end()
    lsp_write_response(jrpc_result(id, jobj_start() ++ jkv_raw("items", items) ++ jobj_end()))

fn lsp_vec_str_contains(v: Vec[str], s: str) -> i32:
    for i in 0..v.len() as i32:
        if v.get(i as i64) == s:
            return 1
    0

fn lsp_list_embedded_modules(prefix: str) -> Vec[str]:
    // Query the embedded stdlib listing and filter by prefix.
    // Returns module names without prefix or .w extension.
    // e.g. prefix="std/" returns ["collections", "fmt", "fs", ...]
    let listing = with_embedded_std_list_modules()
    let result: Vec[str] = Vec.new()
    if listing.len() == 0:
        return result
    // Split by newline and filter
    var start = 0
    var i = 0
    while i <= listing.len() as i32:
        let at_end = i == listing.len() as i32
        let ch = if at_end: 10 else: listing.byte_at(i as i64)
        if ch == 10:
            let entry = listing.slice(start as i64, i as i64)
            if entry.starts_with(prefix) and entry.ends_with(".w"):
                // Extract module name: strip prefix and .w
                let name = entry.slice(prefix.len(), entry.len() - 2)
                // Skip subdir modules (contain /) for top-level completion
                if lsp_find_substr(name, "/") < 0:
                    result.push(name)
            start = i + 1
        i = i + 1
    result

fn lsp_keywords() -> Vec[str]:
    let k: Vec[str] = Vec.new()
    k.push("fn")
    k.push("let")
    k.push("var")
    k.push("type")
    k.push("enum")
    k.push("trait")
    k.push("impl")
    k.push("extend")
    k.push("use")
    k.push("if")
    k.push("else")
    k.push("match")
    k.push("for")
    k.push("while")
    k.push("loop")
    k.push("return")
    k.push("break")
    k.push("continue")
    k.push("defer")
    k.push("const")
    k.push("pub")
    k.push("extern")
    k.push("async")
    k.push("await")
    k.push("spawn")
    k.push("comptime")
    k.push("error")
    k

// ── Document symbols ─────────────────────────────────────────

fn lsp_document_symbols(id: i32, state: LspState, uri: str, text: str):
    let idx = state.find_doc(uri)
    if idx >= 0:
        state.documents.get(idx as i64).ensure_analyzed()
    var pool = AstPool.new()
    var intern = InternPool.init()
    if idx >= 0 and state.documents.get(idx as i64).cache_valid:
        pool = state.documents.get(idx as i64).cached_pool
        intern = state.documents.get(idx as i64).cached_intern
    else:
        var comp = Compilation.init()
        comp.set_prelude_mode(0)
        pool = comp.compile_source_text(uri_to_path(uri), text)
        intern = comp.zcu.pool

    var items = jarr_start()
    var first = true
    for di in 0..pool.decl_count():
        let decl = pool.get_decl(di)
        let kind = pool.kind(decl)
        var label = ""
        var sk = 0
        if kind == NodeKind.NK_FN_DECL:
            label = intern.resolve(pool.get_data0(decl))
            sk = 12
        else if kind == NodeKind.NK_TYPE_DECL:
            label = intern.resolve(pool.get_data0(decl))
            sk = 23
        else if kind == NodeKind.NK_TRAIT_DECL:
            label = intern.resolve(pool.get_data0(decl))
            sk = 11
        else if kind == NodeKind.NK_LET_DECL:
            label = intern.resolve(pool.get_data0(decl))
            sk = 13
        else if kind == NodeKind.NK_EXTERN_FN:
            label = intern.resolve(pool.get_data0(decl))
            sk = 12
        if label.len() > 0:
            let ds = pool.get_start(decl)
            let de = pool.get_end(decl)
            let sl = lsp_offset_to_line(text, ds)
            let sc = lsp_offset_to_col(text, ds)
            let el = lsp_offset_to_line(text, de)
            let ec = lsp_offset_to_col(text, de)
            let range = jrange(sl, sc, el, ec)
            if not first:
                items = items ++ ","
            first = false
            items = items ++ jobj_start() ++ jkv_str("name", label) ++ "," ++ jkv_int("kind", sk) ++ "," ++ jkv_raw("range", range) ++ "," ++ jkv_raw("selectionRange", range) ++ jobj_end()
    items = items ++ jarr_end()
    lsp_write_response(jrpc_result(id, items))

// ── Main loop ────────────────────────────────────────────────

fn run_lsp() -> i32:
    var state = LspState.new()

    while true:
        let msg = lsp_read_message()
        if msg.len() == 0:
            break

        let method = json_get_string(msg, "method")
        let id = json_get_int(msg, "id")
        let params = json_get_object(msg, "params")

        if method == "initialize":
            state.initialized = true
            let completion_opts = jobj_start() ++ jkv_raw("triggerCharacters", "[\".\"]") ++ jobj_end()
            let caps = jobj_start() ++ jkv_int("textDocumentSync", 1) ++ "," ++ jkv_bool("hoverProvider", true) ++ "," ++ jkv_bool("definitionProvider", true) ++ "," ++ jkv_bool("documentFormattingProvider", true) ++ "," ++ jkv_raw("completionProvider", completion_opts) ++ "," ++ jkv_bool("documentSymbolProvider", true) ++ jobj_end()
            let info = jobj_start() ++ jkv_str("name", "with-lsp") ++ "," ++ jkv_str("version", "0.1.0") ++ jobj_end()
            let result = jobj_start() ++ jkv_raw("capabilities", caps) ++ "," ++ jkv_raw("serverInfo", info) ++ jobj_end()
            lsp_write_response(jrpc_result(id, result))

        else if method == "initialized":
            continue

        else if method == "shutdown":
            lsp_write_response(jrpc_result_null(id))

        else if method == "exit":
            return 0

        else if method == "textDocument/didOpen":
            let td = json_get_object(params, "textDocument")
            let uri = json_get_string(td, "uri")
            let text = json_get_string(td, "text")
            state.set_doc(uri, text, json_get_int(td, "version"))
            lsp_publish_diagnostics(state, uri, text)

        else if method == "textDocument/didChange":
            let td = json_get_object(params, "textDocument")
            let uri = json_get_string(td, "uri")
            let text = json_get_string(msg, "text")
            if text.len() > 0:
                state.set_doc(uri, text, 0)
                lsp_publish_diagnostics(state, uri, text)

        else if method == "textDocument/didSave":
            let td = json_get_object(params, "textDocument")
            let uri = json_get_string(td, "uri")
            let idx = state.find_doc(uri)
            if idx >= 0:
                let doc = state.documents.get(idx as i64)
                lsp_publish_diagnostics(state, uri, doc.text)

        else if method == "textDocument/hover":
            let td = json_get_object(params, "textDocument")
            let uri = json_get_string(td, "uri")
            let pos = json_get_object(params, "position")
            let idx = state.find_doc(uri)
            if idx >= 0:
                let doc = state.documents.get(idx as i64)
                lsp_hover(id, state, uri, doc.text, json_get_int(pos, "line"), json_get_int(pos, "character"))
            else:
                lsp_write_response(jrpc_result_null(id))

        else if method == "textDocument/definition":
            let td = json_get_object(params, "textDocument")
            let uri = json_get_string(td, "uri")
            let pos = json_get_object(params, "position")
            let idx = state.find_doc(uri)
            if idx >= 0:
                let doc = state.documents.get(idx as i64)
                lsp_definition(id, state, uri, doc.text, json_get_int(pos, "line"), json_get_int(pos, "character"))
            else:
                lsp_write_response(jrpc_result_null(id))

        else if method == "textDocument/formatting":
            let td = json_get_object(params, "textDocument")
            let uri = json_get_string(td, "uri")
            let idx = state.find_doc(uri)
            if idx >= 0:
                let doc = state.documents.get(idx as i64)
                let formatted = format_source(doc.text)
                if formatted != doc.text:
                    let el = lsp_offset_to_line(doc.text, doc.text.len() as i32)
                    let edit = jarr_start() ++ jobj_start() ++ jkv_raw("range", jrange(0, 0, el + 1, 0)) ++ "," ++ jkv_str("newText", formatted) ++ jobj_end() ++ jarr_end()
                    lsp_write_response(jrpc_result(id, edit))
                else:
                    lsp_write_response(jrpc_result(id, "[]"))
            else:
                lsp_write_response(jrpc_result(id, "[]"))

        else if method == "textDocument/completion":
            let td = json_get_object(params, "textDocument")
            let uri = json_get_string(td, "uri")
            let pos = json_get_object(params, "position")
            let idx = state.find_doc(uri)
            if idx >= 0:
                let doc = state.documents.get(idx as i64)
                lsp_completion(id, state, uri, doc.text, json_get_int(pos, "line"), json_get_int(pos, "character"))
            else:
                lsp_write_response(jrpc_result(id, jobj_start() ++ jkv_raw("items", "[]") ++ jobj_end()))

        else if method == "textDocument/documentSymbol":
            let td = json_get_object(params, "textDocument")
            let uri = json_get_string(td, "uri")
            let idx = state.find_doc(uri)
            if idx >= 0:
                let doc = state.documents.get(idx as i64)
                lsp_document_symbols(id, state, uri, doc.text)
            else:
                lsp_write_response(jrpc_result(id, "[]"))

        else:
            if id >= 0:
                lsp_write_response(jrpc_error(id, -32601, "Method not found: " ++ method))
    0
