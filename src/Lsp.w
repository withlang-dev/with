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

// ── Document state ───────────────────────────────────────────

type LspDocument {
    uri: str,
    path: str,
    text: str,
    version: i32,
}

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
    // Replace existing or append new. Vec.set may not be available,
    // so rebuild the list when replacing.
    let doc = LspDocument { uri, path: uri_to_path(uri), text, version }
    let idx = self.find_doc(uri)
    if idx < 0:
        self.documents.push(doc)
        return
    // Rebuild without the old entry, then add updated
    let new_docs: Vec[LspDocument] = Vec.new()
    for i in 0..self.documents.len() as i32:
        if i == idx:
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

fn lsp_publish_diagnostics(uri: str, text: str):
    let path = uri_to_path(uri)
    var comp = Compilation.init()
    comp.set_prelude_mode(0)
    let pool = comp.compile_source_text(path, text)

    var diags = jarr_start()
    let dl = comp.zcu.diagnostics
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

fn lsp_definition(id: i32, uri: str, text: str, line: i32, col: i32):
    let path = uri_to_path(uri)
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

    var comp = Compilation.init()
    comp.set_prelude_mode(0)
    let pool = comp.compile_source_text(path, text)
    let intern = comp.zcu.pool

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

fn lsp_hover(id: i32, uri: str, text: str, line: i32, col: i32):
    let path = uri_to_path(uri)
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

    var comp = Compilation.init()
    comp.set_prelude_mode(0)
    let pool = comp.compile_source_text(path, text)
    let intern = comp.zcu.pool

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
            let caps = jobj_start() ++ jkv_int("textDocumentSync", 1) ++ "," ++ jkv_bool("hoverProvider", true) ++ "," ++ jkv_bool("definitionProvider", true) ++ "," ++ jkv_bool("documentFormattingProvider", true) ++ jobj_end()
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
            lsp_publish_diagnostics(uri, text)

        else if method == "textDocument/didChange":
            let td = json_get_object(params, "textDocument")
            let uri = json_get_string(td, "uri")
            let text = json_get_string(msg, "text")
            if text.len() > 0:
                state.set_doc(uri, text, 0)
                lsp_publish_diagnostics(uri, text)

        else if method == "textDocument/didSave":
            let td = json_get_object(params, "textDocument")
            let uri = json_get_string(td, "uri")
            let idx = state.find_doc(uri)
            if idx >= 0:
                let doc = state.documents.get(idx as i64)
                lsp_publish_diagnostics(uri, doc.text)

        else if method == "textDocument/hover":
            let td = json_get_object(params, "textDocument")
            let uri = json_get_string(td, "uri")
            let pos = json_get_object(params, "position")
            let idx = state.find_doc(uri)
            if idx >= 0:
                let doc = state.documents.get(idx as i64)
                lsp_hover(id, uri, doc.text, json_get_int(pos, "line"), json_get_int(pos, "character"))
            else:
                lsp_write_response(jrpc_result_null(id))

        else if method == "textDocument/definition":
            let td = json_get_object(params, "textDocument")
            let uri = json_get_string(td, "uri")
            let pos = json_get_object(params, "position")
            let idx = state.find_doc(uri)
            if idx >= 0:
                let doc = state.documents.get(idx as i64)
                lsp_definition(id, uri, doc.text, json_get_int(pos, "line"), json_get_int(pos, "character"))
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

        else:
            if id >= 0:
                lsp_write_response(jrpc_error(id, -32601, "Method not found: " ++ method))
    0
