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

extern fn malloc(size: i64) -> *mut u8
extern fn free(ptr: *mut u8) -> void

extern fn with_eprint(s: str) -> void
extern fn with_read_line_stdin() -> str
extern fn with_read_bytes_stdin(count: i32) -> str
extern fn with_write_stdout(s: str) -> void
extern fn with_flush_stdout() -> void
extern fn with_fs_read_file(path: str) -> str
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
    var started = false
    for i in 0..s.len() as i32:
        let ch = s.byte_at(i as i64)
        if ch >= 48 and ch <= 57:
            result = result * 10 + (ch - 48)
            started = true
        else if started:
            break
    result

// ── JSON tokenizer (jsmn port) ──────────────────────────────

let JSON_OBJECT: i32 = 1
let JSON_ARRAY: i32 = 2
let JSON_STRING: i32 = 4
let JSON_PRIMITIVE: i32 = 8

type JsonToken {
    tok_type: i32,
    start: i32,
    end: i32,
    size: i32,
    parent: i32,
}

type JsonParser {
    pos: i32,
    toknext: i32,
    toksuper: i32,
}

unsafe fn jsmn_alloc_token(parser: *mut JsonParser, tokens: *mut JsonToken, num_tokens: i32) -> i32:
    if parser.toknext >= num_tokens:
        return -1
    let idx = parser.toknext
    parser.toknext = parser.toknext + 1
    let tok = tokens + idx as u64
    tok.start = -1
    tok.end = -1
    tok.size = 0
    tok.parent = -1
    tok.tok_type = 0
    idx

unsafe fn jsmn_fill_token(tokens: *mut JsonToken, idx: i32, tok_type: i32, start: i32, end: i32):
    let tok = tokens + idx as u64
    tok.tok_type = tok_type
    tok.start = start
    tok.end = end
    tok.size = 0

unsafe fn jsmn_parse_primitive(parser: *mut JsonParser, js: str, len: i32, tokens: *mut JsonToken, num_tokens: i32) -> i32:
    let start = parser.pos
    while parser.pos < len:
        let c = js.byte_at(parser.pos as i64) as i32
        if c == 0:
            break
        if c == 58 or c == 9 or c == 13 or c == 10 or c == 32 or c == 44 or c == 93 or c == 125:
            break
        if c < 32 or c >= 127:
            parser.pos = start
            return -2
        parser.pos = parser.pos + 1
    let tok_idx = jsmn_alloc_token(parser, tokens, num_tokens)
    if tok_idx < 0:
        parser.pos = start
        return -1
    jsmn_fill_token(tokens, tok_idx, JSON_PRIMITIVE, start, parser.pos)
    (*(tokens + tok_idx as u64)).parent = parser.toksuper
    parser.pos = parser.pos - 1
    0

unsafe fn jsmn_parse_string(parser: *mut JsonParser, js: str, len: i32, tokens: *mut JsonToken, num_tokens: i32) -> i32:
    let start = parser.pos
    parser.pos = parser.pos + 1
    while parser.pos < len:
        let c = js.byte_at(parser.pos as i64) as i32
        if c == 0:
            break
        if c == 34:
            let tok_idx = jsmn_alloc_token(parser, tokens, num_tokens)
            if tok_idx < 0:
                parser.pos = start
                return -1
            jsmn_fill_token(tokens, tok_idx, JSON_STRING, start + 1, parser.pos)
            (*(tokens + tok_idx as u64)).parent = parser.toksuper
            return 0
        if c == 92 and parser.pos + 1 < len:
            parser.pos = parser.pos + 1
            let esc = js.byte_at(parser.pos as i64) as i32
            if esc == 34 or esc == 47 or esc == 92 or esc == 98 or esc == 102 or esc == 114 or esc == 110 or esc == 116:
                0
            else if esc == 117:
                parser.pos = parser.pos + 1
                var hi = 0
                while hi < 4 and parser.pos < len:
                    let hc = js.byte_at(parser.pos as i64) as i32
                    if hc == 0:
                        break
                    if not ((hc >= 48 and hc <= 57) or (hc >= 65 and hc <= 70) or (hc >= 97 and hc <= 102)):
                        parser.pos = start
                        return -2
                    parser.pos = parser.pos + 1
                    hi = hi + 1
                parser.pos = parser.pos - 1
            else:
                parser.pos = start
                return -2
        parser.pos = parser.pos + 1
    parser.pos = start
    -3

unsafe fn jsmn_parse(parser: *mut JsonParser, js: str, len: i32, tokens: *mut JsonToken, num_tokens: i32) -> i32:
    var count = parser.toknext
    while parser.pos < len:
        let c = js.byte_at(parser.pos as i64) as i32
        if c == 0:
            break
        if c == 123 or c == 91:
            count = count + 1
            let tok_idx = jsmn_alloc_token(parser, tokens, num_tokens)
            if tok_idx < 0:
                return -1
            if parser.toksuper != -1:
                let sup = tokens + parser.toksuper as u64
                sup.size = sup.size + 1
                (*(tokens + tok_idx as u64)).parent = parser.toksuper
            if c == 123:
                (*(tokens + tok_idx as u64)).tok_type = JSON_OBJECT
            else:
                (*(tokens + tok_idx as u64)).tok_type = JSON_ARRAY
            (*(tokens + tok_idx as u64)).start = parser.pos
            parser.toksuper = parser.toknext - 1
        else if c == 125 or c == 93:
            var expected_type = JSON_OBJECT
            if c == 93:
                expected_type = JSON_ARRAY
            if parser.toknext < 1:
                return -2
            var ti = parser.toknext - 1
            var matched = false
            while not matched:
                let tok = tokens + ti as u64
                if tok.start != -1 and tok.end == -1:
                    if tok.tok_type != expected_type:
                        return -2
                    tok.end = parser.pos + 1
                    parser.toksuper = tok.parent
                    matched = true
                else if tok.parent == -1:
                    if tok.tok_type != expected_type or parser.toksuper == -1:
                        return -2
                    matched = true
                else:
                    ti = tok.parent
        else if c == 34:
            let r = jsmn_parse_string(parser, js, len, tokens, num_tokens)
            if r < 0:
                return r
            count = count + 1
            if parser.toksuper != -1:
                (*(tokens + parser.toksuper as u64)).size = (*(tokens + parser.toksuper as u64)).size + 1
        else if c == 9 or c == 13 or c == 10 or c == 32:
            0
        else if c == 58:
            parser.toksuper = parser.toknext - 1
        else if c == 44:
            if parser.toksuper != -1:
                let sup = tokens + parser.toksuper as u64
                if sup.tok_type != JSON_ARRAY and sup.tok_type != JSON_OBJECT:
                    parser.toksuper = sup.parent
        else:
            let r = jsmn_parse_primitive(parser, js, len, tokens, num_tokens)
            if r < 0:
                return r
            count = count + 1
            if parser.toksuper != -1:
                (*(tokens + parser.toksuper as u64)).size = (*(tokens + parser.toksuper as u64)).size + 1
        parser.pos = parser.pos + 1
    var i = parser.toknext - 1
    while i >= 0:
        let tok = tokens + i as u64
        if tok.start != -1 and tok.end == -1:
            return -3
        i = i - 1
    count

// ── JSON token accessors ────────────────────────────────────

fn lsp_json_parse(js: str, tokens: *mut JsonToken, num_tokens: i32) -> i32:
    var parser = JsonParser { pos: 0, toknext: 0, toksuper: -1 }
    unsafe: jsmn_parse(&raw mut parser as *mut JsonParser, js, js.len() as i32, tokens, num_tokens)

fn json_tok_str(js: str, tokens: *mut JsonToken, idx: i32) -> str:
    if idx < 0:
        return ""
    var start: i32 = 0
    var end: i32 = 0
    unsafe:
        start = (*(tokens + idx as u64)).start
        end = (*(tokens + idx as u64)).end
    json_unescape(js.slice(start as i64, end as i64))

fn json_tok_int(js: str, tokens: *mut JsonToken, idx: i32) -> i32:
    if idx < 0:
        return -1
    var start: i32 = 0
    var end: i32 = 0
    unsafe:
        start = (*(tokens + idx as u64)).start
        end = (*(tokens + idx as u64)).end
    lsp_parse_int(js.slice(start as i64, end as i64))

fn json_find(js: str, tokens: *mut JsonToken, parent: i32, key: str) -> i32:
    if parent < 0:
        return -1
    var tok_type: i32 = 0
    var size: i32 = 0
    unsafe:
        tok_type = (*(tokens + parent as u64)).tok_type
        size = (*(tokens + parent as u64)).size
    if tok_type != JSON_OBJECT:
        return -1
    var i = 0
    var idx = parent + 1
    while i < size:
        var kstart: i32 = 0
        var kend: i32 = 0
        unsafe:
            kstart = (*(tokens + idx as u64)).start
            kend = (*(tokens + idx as u64)).end
        let k = js.slice(kstart as i64, kend as i64)
        if k == key:
            return idx + 1
        idx = json_skip(tokens, idx + 1)
        i = i + 1
    -1

fn json_skip(tokens: *mut JsonToken, idx: i32) -> i32:
    var tok_type: i32 = 0
    var size: i32 = 0
    unsafe:
        tok_type = (*(tokens + idx as u64)).tok_type
        size = (*(tokens + idx as u64)).size
    if tok_type == JSON_OBJECT:
        var i = 0
        var next = idx + 1
        while i < size:
            next = json_skip(tokens, next)
            next = json_skip(tokens, next)
            i = i + 1
        return next
    if tok_type == JSON_ARRAY:
        var i = 0
        var next = idx + 1
        while i < size:
            next = json_skip(tokens, next)
            i = i + 1
        return next
    idx + 1

fn json_unescape(s: str) -> str:
    if not s.contains("\\"):
        return s
    var out = ""
    var i = 0
    while i < s.len() as i32:
        let ch = s.byte_at(i as i64)
        if ch == 92 and i + 1 < s.len() as i32:
            let next = s.byte_at((i + 1) as i64)
            if next == 110:
                out = out ++ str_from_byte(10)
            else if next == 116:
                out = out ++ str_from_byte(9)
            else if next == 114:
                out = out ++ str_from_byte(13)
            else if next == 34:
                out = out ++ str_from_byte(34)
            else if next == 92:
                out = out ++ str_from_byte(92)
            else:
                out = out ++ s.slice(i as i64, (i + 2) as i64)
            i = i + 2
        else:
            out = out ++ s.slice(i as i64, (i + 1) as i64)
            i = i + 1
    out

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
    // Fast-tier cache (parse-only, invalidated on text change)
    fast_pool: AstPool,
    fast_intern: InternPool,
    fast_text_len: i32,
    fast_valid: bool,
    // Slow-tier cache (full compilation, invalidated on text change)
    cached_pool: AstPool,
    cached_intern: InternPool,
    cached_diags: DiagnosticList,
    cached_decl_paths: Vec[str],
    // Sema data (built during ensure_analyzed while Compilation is alive)
    // Maps byte offset of expression → resolved type name
    cached_type_at: HashMap[i32, str],
    // Maps type name → list of trait method names
    cached_trait_methods: HashMap[str, Vec[str]],
    cached_text_len: i32,
    cache_valid: bool,
}

fn LspDocument.new(uri: str, path: str, text: str, version: i32) -> LspDocument:
    LspDocument {
        uri, path, text, version,
        fast_pool: AstPool.new(),
        fast_intern: InternPool.init(),
        fast_text_len: 0,
        fast_valid: false,
        cached_pool: AstPool.new(),
        cached_intern: InternPool.init(),
        cached_diags: DiagnosticList.init(),
        cached_decl_paths: Vec.new(),
        cached_type_at: HashMap.new(),
        cached_trait_methods: HashMap.new(),
        cached_text_len: 0,
        cache_valid: false,
    }

// Fast-tier: parse-only, no imports, no sema. ~1ms.
fn LspDocument.ensure_parsed(self: LspDocument):
    if self.fast_valid and self.fast_text_len == self.text.len() as i32:
        return
    var lexer = Lexer.init(self.text, 0)
    let tokens = lexer.tokenize()
    var intern = InternPool.init()
    var diags = DiagnosticList.init()
    var parser = Parser.init(tokens, self.text, 0, intern, diags)
    self.fast_pool = parser.parse_module()
    self.fast_intern = parser.intern
    self.fast_text_len = self.text.len() as i32
    self.fast_valid = true

// Slow-tier: full compilation with PRELUDE_NONE. ~50-200ms.
fn LspDocument.ensure_analyzed(self: LspDocument):
    if self.cache_valid and self.cached_text_len == self.text.len() as i32:
        return
    var comp = Compilation.init()
    comp.set_prelude_mode(2)
    let pool = comp.compile_source_text(self.path, self.text)
    self.cached_pool = pool
    self.cached_intern = comp.zcu.pool
    self.cached_diags = comp.zcu.diagnostics
    self.cached_decl_paths = comp.zcu.decl_source_paths
    // Build type-at-offset map from sema's typed_expr_types.
    // Iterate all AST nodes and check which have type info.
    let sema = comp.zcu.last_sema
    let typed = comp.zcu.typed_expr_types
    self.cached_type_at = HashMap.new()
    for ni in 0..pool.node_count():
        let tid_opt = typed.get(ni)
        if tid_opt.is_some():
            let start = pool.get_start(ni as NodeId)
            if start > 0:
                let tname = sema.get_type_name_for_lsp(tid_opt.unwrap() as i32)
                if tname.len() > 0:
                    self.cached_type_at.insert(start, tname)
    // Build trait-methods-per-type map from sema's impl tables.
    self.cached_trait_methods = HashMap.new()
    for ii in 0..sema.impl_type_syms.len() as i32:
        let type_sym = sema.impl_type_syms.get(ii as i64)
        let type_name = sema.pool_resolve(type_sym)
        if type_name.len() == 0:
            continue
        let start = sema.impl_starts.get(ii as i64)
        let count = sema.impl_counts.get(ii as i64)
        var methods: Vec[str] = Vec.new()
        let existing = self.cached_trait_methods.get(type_name)
        if existing.is_some():
            methods = existing.unwrap()
        var ti = 0
        while ti < count:
            let trait_sym = sema.impl_extra.get((start + ti) as i64)
            let trait_opt = sema.trait_lookup.get(trait_sym)
            if trait_opt.is_some():
                let tidx = trait_opt.unwrap()
                if tidx >= 0 and tidx < sema.trait_method_starts.len() as i32:
                    let mstart = sema.trait_method_starts.get(tidx as i64)
                    let mcount = sema.trait_method_counts.get(tidx as i64)
                    var mi = 0
                    while mi < mcount:
                        let msym = sema.trait_method_names.get((mstart + mi) as i64)
                        let mname = sema.pool_resolve(msym)
                        if mname.len() > 0:
                            methods.push(mname)
                        mi = mi + 1
            ti = ti + 1
        if methods.len() > 0:
            self.cached_trait_methods.insert(type_name, methods)
    self.cached_text_len = self.text.len() as i32
    self.cache_valid = true

// Find the type of an expression at a byte offset using the slow tier.
fn LspDocument.type_at_offset(self: LspDocument, offset: i32) -> str:
    if not self.cache_valid:
        return ""
    let opt = self.cached_type_at.get(offset)
    if opt.is_some():
        return opt.unwrap()
    ""

// Get trait methods for a type via cached sema data.
fn LspDocument.trait_methods_for_type(self: LspDocument, type_name: str) -> Vec[str]:
    if not self.cache_valid:
        return Vec.new()
    let opt = self.cached_trait_methods.get(type_name)
    if opt.is_some():
        return opt.unwrap()
    Vec.new()

fn LspDocument.invalidate(self: LspDocument):
    self.cache_valid = false
    self.fast_valid = false

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

fn LspState.get_parsed(self: LspState, uri: str, text: str) -> LspParseResult:
    let idx = self.find_doc(uri)
    if idx >= 0:
        self.documents.get(idx as i64).ensure_parsed()
        let doc = self.documents.get(idx as i64)
        if doc.fast_valid:
            return LspParseResult { pool: doc.fast_pool, intern: doc.fast_intern }
    lsp_parse_file(text)

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
        comp.set_prelude_mode(2)
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

    // Try slow tier first (cross-file via decl_source_paths)
    let idx = state.find_doc(uri)
    if idx >= 0:
        state.documents.get(idx as i64).ensure_analyzed()
    var slow_pool = AstPool.new()
    var slow_intern = InternPool.init()
    var slow_paths: Vec[str] = Vec.new()
    var slow_valid = false
    if idx >= 0 and state.documents.get(idx as i64).cache_valid:
        slow_pool = state.documents.get(idx as i64).cached_pool
        slow_intern = state.documents.get(idx as i64).cached_intern
        slow_paths = state.documents.get(idx as i64).cached_decl_paths
        slow_valid = true
    if slow_valid:
        for di in 0..slow_pool.decl_count():
            let decl = slow_pool.get_decl(di)
            let kind = slow_pool.kind(decl)
            if kind == NodeKind.NK_FN_DECL or kind == NodeKind.NK_TYPE_DECL or kind == NodeKind.NK_TRAIT_DECL or kind == NodeKind.NK_LET_DECL or kind == NodeKind.NK_EXTERN_FN:
                let name = slow_intern.resolve(slow_pool.get_data0(decl))
                if name == token_text:
                    let ds = slow_pool.get_start(decl)
                    var def_uri = uri
                    var def_text = text
                    if di < slow_paths.len() as i32:
                        let decl_path = slow_paths.get(di as i64)
                        if decl_path.len() > 0 and decl_path != uri_to_path(uri):
                            def_uri = "file://" ++ decl_path
                            let file_text = with_fs_read_file(decl_path)
                            if file_text.len() > 0:
                                def_text = file_text
                            else:
                                continue
                    let dl = lsp_offset_to_line(def_text, ds)
                    let dc = lsp_offset_to_col(def_text, ds)
                    let loc = jobj_start() ++ jkv_str("uri", def_uri) ++ "," ++ jkv_raw("range", jrange(dl, dc, dl, dc + name.len() as i32)) ++ jobj_end()
                    lsp_write_response(jrpc_result(id, loc))
                    return

    // Fall back to fast-tier same-file lookup (parse-only, cached)
    let parsed = state.get_parsed(uri, text)
    for di in 0..parsed.pool.decl_count():
        let decl = parsed.pool.get_decl(di)
        let kind = parsed.pool.kind(decl)
        if kind == NodeKind.NK_FN_DECL or kind == NodeKind.NK_TYPE_DECL or kind == NodeKind.NK_TRAIT_DECL or kind == NodeKind.NK_LET_DECL:
            let name = parsed.intern.resolve(parsed.pool.get_data0(decl))
            if name == token_text:
                let ds = parsed.pool.get_start(decl)
                let dl = lsp_offset_to_line(text, ds)
                let dc = lsp_offset_to_col(text, ds)
                let loc = jobj_start() ++ jkv_str("uri", uri) ++ "," ++ jkv_raw("range", jrange(dl, dc, dl, dc + name.len() as i32)) ++ jobj_end()
                lsp_write_response(jrpc_result(id, loc))
                return

    lsp_write_response(jrpc_result_null(id))

// ── Hover ────────────────────────────────────────────────────

// Extract /// doc comment lines above a declaration at the given byte offset.
fn lsp_extract_doc_comment(text: str, decl_start: i32) -> str:
    // Walk backward from decl_start to find preceding /// comment lines.
    var pos = decl_start - 1
    // Skip whitespace/newlines before the declaration
    while pos >= 0 and (text.byte_at(pos as i64) == 32 or text.byte_at(pos as i64) == 9 or text.byte_at(pos as i64) == 13 or text.byte_at(pos as i64) == 10):
        pos = pos - 1
    // Collect doc comment lines (walking backward)
    var doc_lines: Vec[str] = Vec.new()
    while pos >= 0:
        // Find start of this line
        var line_start = pos
        while line_start > 0 and text.byte_at((line_start - 1) as i64) != 10:
            line_start = line_start - 1
        let line = text.slice(line_start as i64, (pos + 1) as i64).trim()
        if line.starts_with("///"):
            let content = line.slice(3, line.len()).trim()
            doc_lines.push(content)
            // Move to previous line
            pos = line_start - 1
            while pos >= 0 and (text.byte_at(pos as i64) == 32 or text.byte_at(pos as i64) == 9 or text.byte_at(pos as i64) == 13 or text.byte_at(pos as i64) == 10):
                pos = pos - 1
        else:
            break
    // Reverse the collected lines (they were collected bottom-up)
    var result = ""
    var i = doc_lines.len() as i32 - 1
    while i >= 0:
        if result.len() > 0:
            result = result ++ "\n"
        result = result ++ doc_lines.get(i as i64)
        i = i - 1
    result

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
        comp.set_prelude_mode(2)
        pool = comp.compile_source_text(uri_to_path(uri), text)
        intern = comp.zcu.pool

    var hover = ""
    var decl_start = 0
    for di in 0..pool.decl_count():
        let decl = pool.get_decl(di)
        let kind = pool.kind(decl)
        if kind == NodeKind.NK_FN_DECL:
            if intern.resolve(pool.get_data0(decl)) == token_text:
                hover = "fn " ++ token_text
                decl_start = pool.get_start(decl)
                break
        if kind == NodeKind.NK_TYPE_DECL:
            if intern.resolve(pool.get_data0(decl)) == token_text:
                hover = "type " ++ token_text
                decl_start = pool.get_start(decl)
                break
        if kind == NodeKind.NK_TRAIT_DECL:
            if intern.resolve(pool.get_data0(decl)) == token_text:
                hover = "trait " ++ token_text
                decl_start = pool.get_start(decl)
                break
        if kind == NodeKind.NK_LET_DECL:
            if intern.resolve(pool.get_data0(decl)) == token_text:
                hover = "let " ++ token_text
                decl_start = pool.get_start(decl)
                break

    if hover.len() == 0:
        lsp_write_response(jrpc_result_null(id))
        return

    // Extract doc comment above the declaration
    let doc = lsp_extract_doc_comment(text, decl_start)
    var value = "`" ++ hover ++ "`"
    if doc.len() > 0:
        value = value ++ "\n\n---\n\n" ++ doc

    let content = jobj_start() ++ jkv_str("kind", "markdown") ++ "," ++ jkv_str("value", value) ++ jobj_end()
    lsp_write_response(jrpc_result(id, jobj_start() ++ jkv_raw("contents", content) ++ jobj_end()))

// ── Dot completion ───────────────────────────────────────────

fn lsp_dot_completion(id: i32, state: LspState, uri: str, text: str, offset: i32, dot_pos: i32):
    // Find the receiver identifier before the dot
    var recv_end = dot_pos
    var recv_start = recv_end - 1
    while recv_start >= 0 and lsp_is_ident_char(text.byte_at(recv_start as i64)):
        recv_start = recv_start - 1
    recv_start = recv_start + 1
    if recv_start >= recv_end:
        lsp_write_response(jrpc_result(id, jobj_start() ++ jkv_raw("items", "[]") ++ jobj_end()))
        return
    let receiver = text.slice(recv_start as i64, recv_end as i64)

    // Parse file to find receiver's type (cached)
    let parsed = state.get_parsed(uri, text)
    var type_name = lsp_resolve_receiver_type(parsed.pool, parsed.intern, receiver, offset)

    // Slow-tier fallback: use typed_expr_types for type inference
    if type_name.len() == 0:
        let cidx = state.find_doc(uri)
        if cidx >= 0 and state.documents.get(cidx as i64).cache_valid:
            type_name = state.documents.get(cidx as i64).type_at_offset(recv_start)

    // Build items JSON inline (Vec is pass-by-value, can't use helpers)
    var items = jarr_start()
    var first = true

    if type_name == "str":
        // str methods
        let str_methods = "len,slice,starts_with,ends_with,contains,find,replace,to_upper,to_lower,upper,lower,trim,split,byte_at,repeat"
        var sm_start = 0
        for smi in 0..str_methods.len() as i32:
            if str_methods.byte_at(smi as i64) == 44 or smi == str_methods.len() as i32 - 1:
                let sm_end = if str_methods.byte_at(smi as i64) == 44: smi else: smi + 1
                let m = str_methods.slice(sm_start as i64, sm_end as i64)
                if not first: items = items ++ ","
                first = false
                items = items ++ jobj_start() ++ jkv_str("label", m) ++ "," ++ jkv_int("kind", 2) ++ jobj_end()
                sm_start = smi + 1

    else if type_name == "Vec":
        let vec_methods = "push,pop,get,len,is_empty,contains,clear"
        var vm_start = 0
        for vmi in 0..vec_methods.len() as i32:
            if vec_methods.byte_at(vmi as i64) == 44 or vmi == vec_methods.len() as i32 - 1:
                let vm_end = if vec_methods.byte_at(vmi as i64) == 44: vmi else: vmi + 1
                let m = vec_methods.slice(vm_start as i64, vm_end as i64)
                if not first: items = items ++ ","
                first = false
                items = items ++ jobj_start() ++ jkv_str("label", m) ++ "," ++ jkv_int("kind", 2) ++ jobj_end()
                vm_start = vmi + 1

    else if type_name == "HashMap":
        let hm_methods = "get,insert,contains,remove,len,is_empty,clear"
        var hm_start = 0
        for hmi in 0..hm_methods.len() as i32:
            if hm_methods.byte_at(hmi as i64) == 44 or hmi == hm_methods.len() as i32 - 1:
                let hm_end = if hm_methods.byte_at(hmi as i64) == 44: hmi else: hmi + 1
                let m = hm_methods.slice(hm_start as i64, hm_end as i64)
                if not first: items = items ++ ","
                first = false
                items = items ++ jobj_start() ++ jkv_str("label", m) ++ "," ++ jkv_int("kind", 2) ++ jobj_end()
                hm_start = hmi + 1

    else if type_name.len() > 0:
        // User struct: find fields from type declaration
        for di in 0..parsed.pool.decl_count():
            let decl = parsed.pool.get_decl(di)
            if parsed.pool.kind(decl) != NodeKind.NK_TYPE_DECL:
                continue
            let dname = parsed.intern.resolve(parsed.pool.get_data0(decl))
            if dname != type_name:
                continue
            let sub = type_decl_sub_kind(parsed.pool.get_data2(decl))
            if sub != TypeDeclKind.Struct:
                continue
            // Walk struct fields from extra data
            let es = parsed.pool.get_data1(decl)
            let fc = parsed.pool.get_extra(es)
            for fi in 0..fc:
                let field_name_node = parsed.pool.get_extra(es + 1 + fi * 3)
                if field_name_node != 0:
                    let fname = parsed.intern.resolve(field_name_node)
                    if fname.len() > 0:
                        if not first: items = items ++ ","
                        first = false
                        items = items ++ jobj_start() ++ jkv_str("label", fname) ++ "," ++ jkv_int("kind", 5) ++ jobj_end()
            break
        // Find methods from extend/impl blocks.
        // Methods are NK_FN_DECL with mangled names like "TypeName.method".
        let prefix = type_name ++ "."
        for di in 0..parsed.pool.decl_count():
            let decl = parsed.pool.get_decl(di)
            if parsed.pool.kind(decl) != NodeKind.NK_FN_DECL:
                continue
            let dname = parsed.intern.resolve(parsed.pool.get_data0(decl))
            if dname.starts_with(prefix) and dname.len() > prefix.len():
                let method_name = dname.slice(prefix.len(), dname.len())
                if not first: items = items ++ ","
                first = false
                items = items ++ jobj_start() ++ jkv_str("label", method_name) ++ "," ++ jkv_int("kind", 2) ++ jobj_end()
        // Trait methods: find impls for this type, then look up trait methods
        for di in 0..parsed.pool.decl_count():
            let decl = parsed.pool.get_decl(di)
            if parsed.pool.kind(decl) != NodeKind.NK_IMPL_DECL:
                continue
            let impl_type = parsed.intern.resolve(parsed.pool.get_data0(decl))
            if impl_type != type_name:
                continue
            let trait_sym = parsed.pool.get_data2(decl)
            if trait_sym == 0:
                continue
            // Find the trait declaration and extract its method names
            let trait_name = parsed.intern.resolve(trait_sym)
            for ti in 0..parsed.pool.decl_count():
                let tdecl = parsed.pool.get_decl(ti)
                if parsed.pool.kind(tdecl) != NodeKind.NK_TRAIT_DECL:
                    continue
                if parsed.intern.resolve(parsed.pool.get_data0(tdecl)) != trait_name:
                    continue
                // Walk trait methods from extra data
                let tes = parsed.pool.get_data1(tdecl)
                let tp_count = parsed.pool.get_extra(tes)
                // Skip type params: tes+1 = tp_start (unused here)
                var tpos = tes + 2
                // Skip associated types
                let assoc_count = parsed.pool.get_extra(tpos)
                tpos = tpos + 1
                var ai = 0
                while ai < assoc_count:
                    tpos = tpos + 1  // name
                    let bc = parsed.pool.get_extra(tpos)
                    tpos = tpos + 1 + bc + 1  // bounds + default
                    ai = ai + 1
                let method_count = parsed.pool.get_extra(tpos)
                tpos = tpos + 1
                for mi in 0..method_count:
                    let mname = parsed.intern.resolve(parsed.pool.get_extra(tpos))
                    if mname.len() > 0:
                        if not first: items = items ++ ","
                        first = false
                        items = items ++ jobj_start() ++ jkv_str("label", mname) ++ "," ++ jkv_int("kind", 2) ++ jobj_end()
                    tpos = tpos + 6  // name, flags, param_start, param_count, ret_type, body
                break
        // Sema-based trait methods from slow tier (includes imported traits)
        let cidx = state.find_doc(uri)
        if cidx >= 0 and state.documents.get(cidx as i64).cache_valid:
            let trait_methods = state.documents.get(cidx as i64).trait_methods_for_type(type_name)
            for tmi in 0..trait_methods.len() as i32:
                let tmname = trait_methods.get(tmi as i64)
                if not first: items = items ++ ","
                first = false
                items = items ++ jobj_start() ++ jkv_str("label", tmname) ++ "," ++ jkv_int("kind", 2) ++ jobj_end()

    items = items ++ jarr_end()
    lsp_write_response(jrpc_result(id, jobj_start() ++ jkv_raw("items", items) ++ jobj_end()))

fn lsp_is_ident_char(ch: i32) -> bool:
    (ch >= 97 and ch <= 122) or (ch >= 65 and ch <= 90) or (ch >= 48 and ch <= 57) or ch == 95

fn lsp_resolve_receiver_type(pool: AstPool, intern: InternPool, receiver: str, offset: i32) -> str:
    // Find the enclosing function, then look for:
    // 1. Parameter with type annotation: fn foo(x: MyType) → "MyType"
    // 2. Let binding with type annotation: let x: MyType = ... → "MyType"
    // 3. Known builtin names: "str" literal → "str"
    let fn_node = lsp_find_enclosing_fn(pool, offset)
    if fn_node as i32 == 0:
        return ""

    // Check parameters
    let meta = pool.find_fn_meta(fn_node)
    if meta >= 0:
        let param_start = pool.fn_meta_param_start(meta)
        let param_count = pool.fn_meta_param_count(meta)
        for pi in 0..param_count:
            let pname = intern.resolve(pool.fn_param_name(param_start, pi))
            if pname == receiver:
                let ptype_node = pool.fn_param_type(param_start, pi)
                if ptype_node > 0:
                    return lsp_type_node_to_name(pool, intern, ptype_node)

    // Check let/var bindings in the body
    let body = pool.get_data1(fn_node)
    if body != 0 and pool.kind(body as NodeId) == NodeKind.NK_BLOCK:
        let blk = body as NodeId
        let es = pool.get_data0(blk)
        let sc = pool.get_data1(blk)
        for si in 0..sc:
            let stmt = pool.get_extra(es + si)
            if stmt == 0:
                continue
            if pool.kind(stmt as NodeId) != NodeKind.NK_LET_BINDING:
                continue
            let sym = pool.get_data0(stmt as NodeId)
            if sym != 0 and intern.resolve(sym) == receiver:
                // Check for type annotation — data2 has flags, but the
                // value expression (data1) might give type info
                // For now, check if there's a struct literal as value
                let value = pool.get_data1(stmt as NodeId)
                if value != 0:
                    let vk = pool.kind(value as NodeId)
                    if vk == NodeKind.NK_STRUCT_LIT:
                        let struct_sym = pool.get_data0(value as NodeId)
                        if struct_sym != 0:
                            return intern.resolve(struct_sym)
                    if vk == NodeKind.NK_STRING_LIT or vk == NodeKind.NK_FSTRING:
                        return "str"
                    if vk == NodeKind.NK_CALL:
                        let callee = pool.get_data0(value as NodeId)
                        if callee != 0:
                            let ck = pool.kind(callee as NodeId)
                            // Vec.new(), HashMap.new() — Type.method() pattern
                            if ck == NodeKind.NK_FIELD_ACCESS:
                                let base = pool.get_data0(callee as NodeId)
                                if base != 0 and pool.kind(base as NodeId) == NodeKind.NK_IDENT:
                                    return intern.resolve(pool.get_data0(base as NodeId))
                            // fn_name() — look up function return type
                            if ck == NodeKind.NK_IDENT:
                                let call_name = intern.resolve(pool.get_data0(callee as NodeId))
                                let ret_type = lsp_fn_return_type(pool, intern, call_name)
                                if ret_type.len() > 0:
                                    return ret_type
    ""

fn lsp_fn_return_type(pool: AstPool, intern: InternPool, fn_name: str) -> str:
    for di in 0..pool.decl_count():
        let decl = pool.get_decl(di)
        if pool.kind(decl) != NodeKind.NK_FN_DECL:
            continue
        if intern.resolve(pool.get_data0(decl)) != fn_name:
            continue
        let meta = pool.find_fn_meta(decl)
        if meta >= 0:
            let ret_node = pool.fn_meta_ret(meta)
            if ret_node > 0:
                return lsp_type_node_to_name(pool, intern, ret_node)
        break
    ""

fn lsp_type_node_to_name(pool: AstPool, intern: InternPool, type_node: i32) -> str:
    let tk = pool.kind(type_node as NodeId)
    if tk == NodeKind.NK_TYPE_NAMED:
        return intern.resolve(pool.get_data0(type_node as NodeId))
    if tk == NodeKind.NK_TYPE_REF:
        let inner = pool.get_data0(type_node as NodeId)
        if inner > 0:
            return lsp_type_node_to_name(pool, intern, inner)
    if tk == NodeKind.NK_TYPE_GENERIC or tk == NodeKind.NK_INDEX:
        let base = pool.get_data0(type_node as NodeId)
        if base > 0 and pool.kind(base as NodeId) == NodeKind.NK_IDENT:
            return intern.resolve(pool.get_data0(base as NodeId))
    ""

// (helpers removed — items built inline due to pass-by-value)

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

    // Context: "use std." / "use test." → module completion (check before dot)
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

    // Detect dot context: character before cursor is '.'
    var dot_pos = offset - 1
    while dot_pos >= 0 and text.byte_at(dot_pos as i64) == 32:
        dot_pos = dot_pos - 1
    if dot_pos >= 0 and text.byte_at(dot_pos as i64) == 46:
        lsp_dot_completion(id, state, uri, text, offset, dot_pos)
        return

    // Get cached analysis
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
        comp.set_prelude_mode(2)
        pool = comp.compile_source_text(uri_to_path(uri), text)
        intern = comp.zcu.pool

    // Phase 2: scope-aware completion via AST walking.
    // Find the enclosing function, collect its parameters and local bindings
    // that are visible at the cursor position.
    // Fast-tier scope-aware completion (cached).
    let parsed = state.get_parsed(uri, text)
    let parse_pool = parsed.pool
    let parse_intern = parsed.intern
    let enclosing_fn = lsp_find_enclosing_fn(parse_pool, offset)
    var scope_names: Vec[str] = Vec.new()
    if enclosing_fn as i32 != 0:
        let params = lsp_collect_fn_params(parse_pool, parse_intern, enclosing_fn)
        for pi in 0..params.len() as i32:
            scope_names.push(params.get(pi as i64))
        // Walk body recursively to collect bindings visible at cursor.
        let body = parse_pool.get_data1(enclosing_fn)
        if body != 0:
            let bindings = lsp_collect_bindings_rec(parse_pool, parse_intern, body, offset)
            for bi in 0..bindings.len() as i32:
                scope_names.push(bindings.get(bi as i64))
    for si in 0..scope_names.len() as i32:
        let sname = scope_names.get(si as i64)
        if not first:
            items = items ++ ","
        first = false
        items = items ++ jobj_start() ++ jkv_str("label", sname) ++ "," ++ jkv_int("kind", 6) ++ jobj_end()

    // Keywords
    let keywords = lsp_keywords()
    for i in 0..keywords.len() as i32:
        let kw = keywords.get(i as i64)
        if not first:
            items = items ++ ","
        first = false
        items = items ++ jobj_start() ++ jkv_str("label", kw) ++ "," ++ jkv_int("kind", 14) ++ jobj_end()

    // Top-level declarations
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

    // Prelude builtins (always available without explicit import)
    let prelude_fns = "print,eprint,write,ewrite,print_i32,print_i64,print_bool,assert,require,check,int_to_string"
    let prelude_types = "Vec,HashMap,HashSet,Option,Result,Some,None,Ok,Err"
    items = lsp_append_csv_items(items, prelude_fns, 3, first)
    if prelude_fns.len() > 0:
        first = false
    items = lsp_append_csv_items(items, prelude_types, 22, first)

    items = items ++ jarr_end()
    lsp_write_response(jrpc_result(id, jobj_start() ++ jkv_raw("items", items) ++ jobj_end()))

fn lsp_append_csv_items(items: str, csv: str, kind: i32, first: bool) -> str:
    var result = items
    var f = first
    var start = 0
    for i in 0..csv.len() as i32:
        if csv.byte_at(i as i64) == 44 or i == csv.len() as i32 - 1:
            let end = if csv.byte_at(i as i64) == 44: i else: i + 1
            let name = csv.slice(start as i64, end as i64)
            if not f:
                result = result ++ ","
            f = false
            result = result ++ jobj_start() ++ jkv_str("label", name) ++ "," ++ jkv_int("kind", kind) ++ jobj_end()
            start = i + 1
    result

// ── Fast-tier parse + scope collection ───────────────────────

type LspParseResult {
    pool: AstPool,
    intern: InternPool,
}

fn lsp_parse_file(text: str) -> LspParseResult:
    var lexer = Lexer.init(text, 0)
    let tokens = lexer.tokenize()
    var intern = InternPool.init()
    var diags = DiagnosticList.init()
    var parser = Parser.init(tokens, text, 0, intern, diags)
    let pool = parser.parse_module()
    LspParseResult { pool, intern: parser.intern }

fn lsp_find_enclosing_fn(pool: AstPool, offset: i32) -> NodeId:
    // Find the function whose span contains the cursor. Use the start of
    // the NEXT declaration as the upper bound, not get_end — the parser's
    // end span may not cover trailing blank lines inside the function.
    var best: NodeId = 0 as NodeId
    for di in 0..pool.decl_count():
        let decl = pool.get_decl(di)
        if pool.kind(decl) != NodeKind.NK_FN_DECL:
            continue
        let fn_start = pool.get_start(decl)
        if fn_start > offset:
            break
        // Cursor is after this fn's start. Check if it's before the next decl.
        var fn_upper = pool.get_end(decl)
        // Look for the next declaration to use as upper bound
        for di2 in (di + 1)..pool.decl_count():
            let next = pool.get_decl(di2)
            let ns = pool.get_start(next)
            if ns > fn_start:
                fn_upper = ns
                break
        if offset >= fn_start and offset <= fn_upper:
            best = decl
    best

fn lsp_collect_fn_params(pool: AstPool, intern: InternPool, fn_node: NodeId) -> Vec[str]:
    let names: Vec[str] = Vec.new()
    let meta = pool.find_fn_meta(fn_node)
    if meta < 0:
        return names
    let param_start = pool.fn_meta_param_start(meta)
    let param_count = pool.fn_meta_param_count(meta)
    for pi in 0..param_count:
        let psym = pool.fn_param_name(param_start, pi)
        if psym != 0:
            let pname = intern.resolve(psym)
            if pname != "self" and pname.len() > 0:
                names.push(pname)
    names

fn lsp_collect_bindings_rec(pool: AstPool, intern: InternPool, node: i32, offset: i32) -> Vec[str]:
    let empty: Vec[str] = Vec.new()
    if node == 0:
        return empty
    let nid = node as NodeId
    let kind = pool.kind(nid)
    let node_start = pool.get_start(nid)
    let node_end = pool.get_end(nid)

    if kind == NodeKind.NK_LET_BINDING:
        if node_start < offset:
            let sym = pool.get_data0(nid)
            if sym != 0:
                let name = intern.resolve(sym)
                if name.len() > 0:
                    let result: Vec[str] = Vec.new()
                    result.push(name)
                    return result
        return empty

    if kind == NodeKind.NK_LABEL:
        return lsp_collect_bindings_rec(pool, intern, pool.get_data1(nid), offset)

    if kind == NodeKind.NK_GOTO:
        return empty

    if kind == NodeKind.NK_FOR:
        var result: Vec[str] = Vec.new()
        if node_start < offset and offset <= node_end and not pool.for_binding_is_pattern(nid):
            let sym = pool.get_data0(nid)
            if sym != 0:
                let name = intern.resolve(sym)
                if name.len() > 0 and name != "_":
                    result.push(name)
        let for_body = pool.get_data2(nid)
        if for_body != 0:
            let inner = lsp_collect_bindings_rec(pool, intern, for_body, offset)
            for ii in 0..inner.len() as i32:
                result.push(inner.get(ii as i64))
        return result

    if kind == NodeKind.NK_BLOCK:
        let extra_start = pool.get_data0(nid)
        let stmt_count = pool.get_data1(nid)
        let tail = pool.get_data2(nid)
        var result: Vec[str] = Vec.new()
        for i in 0..stmt_count:
            let stmt = pool.get_extra(extra_start + i)
            let inner = lsp_collect_bindings_rec(pool, intern, stmt, offset)
            for ii in 0..inner.len() as i32:
                result.push(inner.get(ii as i64))
        if tail != 0:
            let inner = lsp_collect_bindings_rec(pool, intern, tail, offset)
            for ii in 0..inner.len() as i32:
                result.push(inner.get(ii as i64))
        return result

    if kind == NodeKind.NK_IF_EXPR:
        let then_body = pool.get_data1(nid)
        let else_body = pool.get_data2(nid)
        var result: Vec[str] = Vec.new()
        if then_body != 0 and offset >= pool.get_start(then_body as NodeId) and offset <= pool.get_end(then_body as NodeId):
            let inner = lsp_collect_bindings_rec(pool, intern, then_body, offset)
            for ii in 0..inner.len() as i32:
                result.push(inner.get(ii as i64))
        if else_body != 0 and offset >= pool.get_start(else_body as NodeId) and offset <= pool.get_end(else_body as NodeId):
            let inner = lsp_collect_bindings_rec(pool, intern, else_body, offset)
            for ii in 0..inner.len() as i32:
                result.push(inner.get(ii as i64))
        return result

    if kind == NodeKind.NK_WHILE:
        let body = pool.get_data1(nid)
        if body != 0:
            return lsp_collect_bindings_rec(pool, intern, body, offset)
        return empty

    if kind == NodeKind.NK_DO_WHILE:
        let body = pool.get_data0(nid)
        if body != 0:
            return lsp_collect_bindings_rec(pool, intern, body, offset)
        return empty

    if kind == NodeKind.NK_LOOP:
        let body = pool.get_data0(nid)
        if body != 0:
            return lsp_collect_bindings_rec(pool, intern, body, offset)
        return empty

    if kind == NodeKind.NK_MATCH:
        let arms_start = pool.get_data1(nid)
        let arms_count = pool.get_data2(nid)
        for ai in 0..arms_count:
            let arm = pool.get_extra(arms_start + ai)
            if arm != 0:
                let arm_body = pool.get_data1(arm as NodeId)
                if arm_body != 0 and offset >= pool.get_start(arm_body as NodeId) and offset <= pool.get_end(arm_body as NodeId):
                    return lsp_collect_bindings_rec(pool, intern, arm_body, offset)
        return empty

    empty

fn lsp_collect_bindings(pool: AstPool, intern: InternPool, node: i32, offset: i32, names: Vec[str], seen: Vec[str]):
    if node == 0:
        return
    let nid = node as NodeId
    let kind = pool.kind(nid)
    let node_start = pool.get_start(nid)

    if kind == NodeKind.NK_LET_BINDING:
        if node_start < offset:
            let sym = pool.get_data0(nid)
            if sym != 0:
                let name = intern.resolve(sym)
                if name.len() > 0 and lsp_vec_str_contains(seen, name) == 0:
                    names.push(name)
                    seen.push(name)
        return

    if kind == NodeKind.NK_LABEL:
        lsp_collect_bindings(pool, intern, pool.get_data1(nid), offset, names, seen)
        return

    if kind == NodeKind.NK_GOTO:
        return

    if kind == NodeKind.NK_FOR:
        if node_start < offset and not pool.for_binding_is_pattern(nid):
            let sym = pool.get_data0(nid)
            if sym != 0:
                let name = intern.resolve(sym)
                if name.len() > 0 and name != "_" and lsp_vec_str_contains(seen, name) == 0:
                    names.push(name)
                    seen.push(name)
        let for_body = pool.get_data2(nid)
        if for_body != 0:
            lsp_collect_bindings(pool, intern, for_body, offset, names, seen)
        return

    if kind == NodeKind.NK_BLOCK:
        let extra_start = pool.get_data0(nid)
        let stmt_count = pool.get_data1(nid)
        let tail = pool.get_data2(nid)
        for i in 0..stmt_count:
            lsp_collect_bindings(pool, intern, pool.get_extra(extra_start + i), offset, names, seen)
        if tail != 0:
            lsp_collect_bindings(pool, intern, tail, offset, names, seen)
        return

    if kind == NodeKind.NK_IF_EXPR:
        let then_body = pool.get_data1(nid)
        let else_body = pool.get_data2(nid)
        if then_body != 0:
            lsp_collect_bindings(pool, intern, then_body, offset, names, seen)
        if else_body != 0:
            lsp_collect_bindings(pool, intern, else_body, offset, names, seen)
        return

    if kind == NodeKind.NK_WHILE:
        let body = pool.get_data1(nid)
        if body != 0:
            lsp_collect_bindings(pool, intern, body, offset, names, seen)
        return

    if kind == NodeKind.NK_DO_WHILE:
        let body = pool.get_data0(nid)
        if body != 0:
            lsp_collect_bindings(pool, intern, body, offset, names, seen)
        return

    if kind == NodeKind.NK_MATCH:
        let arms_start = pool.get_data1(nid)
        let arms_count = pool.get_data2(nid)
        for ai in 0..arms_count:
            let arm = pool.get_extra(arms_start + ai)
            if arm != 0:
                let arm_body = pool.get_data1(arm as NodeId)
                if arm_body != 0:
                    lsp_collect_bindings(pool, intern, arm_body, offset, names, seen)
        return

    if kind == NodeKind.NK_LOOP:
        let body = pool.get_data0(nid)
        if body != 0:
            lsp_collect_bindings(pool, intern, body, offset, names, seen)
        return

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
    k.push("goto")
    k.push("const")
    k.push("pub")
    k.push("extern")
    k.push("async")
    k.push("await")
    k.push("spawn")
    k.push("comptime")
    k.push("error")
    k

// ── Signature help ───────────────────────────────────────────

fn lsp_signature_help(id: i32, state: LspState, uri: str, text: str, line: i32, col: i32):
    let offset = lsp_line_col_to_offset(text, line, col)

    // Walk tokens backward from cursor to find the opening ( and function name.
    var lexer = Lexer.init(text, 0)
    let tokens = lexer.tokenize()

    // Find the token at or just before cursor
    var cursor_tok = -1
    for i in 0..tokens.len():
        if tokens.get_start(i) >= offset:
            cursor_tok = i - 1
            break
    if cursor_tok < 0:
        cursor_tok = tokens.len() - 1

    // Walk backward to find the opening ( and count commas for active param
    var paren_depth = 0
    var comma_count = 0
    var fn_name_tok = -1
    var ti = cursor_tok
    while ti >= 0:
        let tag = tokens.get_tag(ti)
        if tag == TokenKind.TK_R_PAREN:
            paren_depth = paren_depth + 1
        else if tag == TokenKind.TK_L_PAREN:
            if paren_depth > 0:
                paren_depth = paren_depth - 1
            else:
                // Found the opening paren. The token before it is the function name.
                if ti > 0 and tokens.get_tag(ti - 1) == TokenKind.TK_IDENT:
                    fn_name_tok = ti - 1
                break
        else if tag == TokenKind.TK_COMMA and paren_depth == 0:
            comma_count = comma_count + 1
        ti = ti - 1

    if fn_name_tok < 0:
        lsp_write_response(jrpc_result_null(id))
        return

    let fn_name = text.slice(tokens.get_start(fn_name_tok) as i64, tokens.get_end(fn_name_tok) as i64)

    // Look up the function declaration in the parsed AST (cached)
    let parsed = state.get_parsed(uri, text)
    var sig_label = ""
    let param_labels: Vec[str] = Vec.new()

    for di in 0..parsed.pool.decl_count():
        let decl = parsed.pool.get_decl(di)
        if parsed.pool.kind(decl) != NodeKind.NK_FN_DECL:
            continue
        let name = parsed.intern.resolve(parsed.pool.get_data0(decl))
        if name != fn_name:
            continue
        // Found the function. Build signature label from parameters.
        let meta = parsed.pool.find_fn_meta(decl)
        if meta < 0:
            continue
        let param_start = parsed.pool.fn_meta_param_start(meta)
        let param_count = parsed.pool.fn_meta_param_count(meta)
        var label = "fn " ++ fn_name ++ "("
        for pi in 0..param_count:
            let pname = parsed.intern.resolve(parsed.pool.fn_param_name(param_start, pi))
            let ptype_node = parsed.pool.fn_param_type(param_start, pi)
            var ptype_str = ""
            if ptype_node > 0:
                let ptk = parsed.pool.kind(ptype_node as NodeId)
                if ptk == NodeKind.NK_TYPE_NAMED:
                    ptype_str = parsed.intern.resolve(parsed.pool.get_data0(ptype_node as NodeId))
                else if ptk == NodeKind.NK_TYPE_REF:
                    let inner = parsed.pool.get_data0(ptype_node as NodeId)
                    if inner > 0 and parsed.pool.kind(inner as NodeId) == NodeKind.NK_TYPE_NAMED:
                        ptype_str = "&" ++ parsed.intern.resolve(parsed.pool.get_data0(inner as NodeId))
            let param_text = if ptype_str.len() > 0: pname ++ ": " ++ ptype_str else: pname
            param_labels.push(param_text)
            if pi > 0:
                label = label ++ ", "
            label = label ++ param_text
        label = label ++ ")"
        sig_label = label
        break

    if sig_label.len() == 0:
        lsp_write_response(jrpc_result_null(id))
        return

    // Build SignatureHelp response
    var params_json = jarr_start()
    for pi in 0..param_labels.len() as i32:
        if pi > 0:
            params_json = params_json ++ ","
        params_json = params_json ++ jobj_start() ++ jkv_str("label", param_labels.get(pi as i64)) ++ jobj_end()
    params_json = params_json ++ jarr_end()

    let sig = jobj_start() ++ jkv_str("label", sig_label) ++ "," ++ jkv_raw("parameters", params_json) ++ jobj_end()
    let result = jobj_start() ++ jkv_raw("signatures", jarr_start() ++ sig ++ jarr_end()) ++ "," ++ jkv_int("activeSignature", 0) ++ "," ++ jkv_int("activeParameter", comma_count) ++ jobj_end()
    lsp_write_response(jrpc_result(id, result))

// ── Find references ──────────────────────────────────────────

fn lsp_find_references(id: i32, state: LspState, uri: str, text: str, line: i32, col: i32):
    let offset = lsp_line_col_to_offset(text, line, col)

    // Find the identifier at cursor
    var lex0 = Lexer.init(text, 0)
    let tok0 = lex0.tokenize()
    var target = ""
    for i in 0..tok0.len():
        if offset >= tok0.get_start(i) and offset < tok0.get_end(i):
            if tok0.get_tag(i) == TokenKind.TK_IDENT:
                target = text.slice(tok0.get_start(i) as i64, tok0.get_end(i) as i64)
            break

    if target.len() == 0:
        lsp_write_response(jrpc_result(id, "[]"))
        return

    // Determine if target is a top-level declaration or a local variable.
    // For locals, restrict references to the enclosing function scope.
    let parsed = state.get_parsed(uri, text)
    var is_top_level = false
    var scope_start = 0
    var scope_end = text.len() as i32
    for di in 0..parsed.pool.decl_count():
        let decl = parsed.pool.get_decl(di)
        let kind = parsed.pool.kind(decl)
        if kind == NodeKind.NK_FN_DECL or kind == NodeKind.NK_TYPE_DECL or kind == NodeKind.NK_TRAIT_DECL or kind == NodeKind.NK_LET_DECL or kind == NodeKind.NK_EXTERN_FN:
            if parsed.intern.resolve(parsed.pool.get_data0(decl)) == target:
                is_top_level = true
                break
    if not is_top_level:
        // Local variable: restrict to enclosing function
        let fn_node = lsp_find_enclosing_fn(parsed.pool, offset)
        if fn_node as i32 != 0:
            scope_start = parsed.pool.get_start(fn_node as NodeId)
            // Use next declaration start as end bound
            var found_current = false
            for di in 0..parsed.pool.decl_count():
                let decl = parsed.pool.get_decl(di)
                if found_current:
                    scope_end = parsed.pool.get_start(decl)
                    break
                if parsed.pool.get_start(decl) == scope_start:
                    found_current = true

    // Scan current file for matching identifiers within scope
    var locs = jarr_start()
    var first = true
    var lex1 = Lexer.init(text, 0)
    let toks1 = lex1.tokenize()
    for ti in 0..toks1.len():
        if toks1.get_tag(ti) != TokenKind.TK_IDENT:
            continue
        let tstart = toks1.get_start(ti)
        if not is_top_level and (tstart < scope_start or tstart >= scope_end):
            continue
        let tt = text.slice(tstart as i64, toks1.get_end(ti) as i64)
        if tt != target:
            continue
        let rl = lsp_offset_to_line(text, tstart)
        let rc = lsp_offset_to_col(text, tstart)
        let re = lsp_offset_to_col(text, toks1.get_end(ti))
        if not first:
            locs = locs ++ ","
        first = false
        locs = locs ++ jobj_start() ++ jkv_str("uri", uri) ++ "," ++ jkv_raw("range", jrange(rl, rc, rl, re)) ++ jobj_end()

    // Cross-file: only scan for top-level declarations (locals can't be cross-file)
    if not is_top_level:
        locs = locs ++ jarr_end()
        lsp_write_response(jrpc_result(id, locs))
        return
    let idx = state.find_doc(uri)
    if idx >= 0:
        state.documents.get(idx as i64).ensure_analyzed()
    var cached_paths: Vec[str] = Vec.new()
    if idx >= 0 and state.documents.get(idx as i64).cache_valid:
        cached_paths = state.documents.get(idx as i64).cached_decl_paths
    if cached_paths.len() > 0:
        var scanned_paths = uri_to_path(uri) ++ "\n"
        for di in 0..cached_paths.len() as i32:
            let dpath = cached_paths.get(di as i64)
            if dpath.len() == 0:
                continue
            if dpath.starts_with("<embedded"):
                continue
            if lsp_find_substr(scanned_paths, dpath) >= 0:
                continue
            scanned_paths = scanned_paths ++ dpath ++ "\n"
            let ft = with_fs_read_file(dpath)
            if ft.len() == 0:
                continue
            let file_uri = "file://" ++ dpath
            var lex2 = Lexer.init(ft, 0)
            let toks2 = lex2.tokenize()
            for ti2 in 0..toks2.len():
                if toks2.get_tag(ti2) != TokenKind.TK_IDENT:
                    continue
                let tt2 = ft.slice(toks2.get_start(ti2) as i64, toks2.get_end(ti2) as i64)
                if tt2 != target:
                    continue
                let rl2 = lsp_offset_to_line(ft, toks2.get_start(ti2))
                let rc2 = lsp_offset_to_col(ft, toks2.get_start(ti2))
                let re2 = lsp_offset_to_col(ft, toks2.get_end(ti2))
                if not first:
                    locs = locs ++ ","
                first = false
                locs = locs ++ jobj_start() ++ jkv_str("uri", file_uri) ++ "," ++ jkv_raw("range", jrange(rl2, rc2, rl2, re2)) ++ jobj_end()

    locs = locs ++ jarr_end()
    lsp_write_response(jrpc_result(id, locs))

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
        comp.set_prelude_mode(2)
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

// ── Rename symbol ───────────────────────────────────────────

fn lsp_is_valid_ident(name: str) -> bool:
    if name.len() == 0:
        return false
    let first_ch = name.byte_at(0)
    if not ((first_ch >= 97 and first_ch <= 122) or (first_ch >= 65 and first_ch <= 90) or first_ch == 95):
        return false
    for i in 1..name.len() as i32:
        let ch = name.byte_at(i as i64)
        if not ((ch >= 97 and ch <= 122) or (ch >= 65 and ch <= 90) or (ch >= 48 and ch <= 57) or ch == 95):
            return false
    true

fn lsp_rename(id: i32, state: LspState, uri: str, text: str, line: i32, col: i32, new_name: str):
    let offset = lsp_line_col_to_offset(text, line, col)

    // Find the identifier at cursor
    var lex0 = Lexer.init(text, 0)
    let tok0 = lex0.tokenize()
    var target = ""
    for i in 0..tok0.len():
        if offset >= tok0.get_start(i) and offset < tok0.get_end(i):
            if tok0.get_tag(i) == TokenKind.TK_IDENT:
                target = text.slice(tok0.get_start(i) as i64, tok0.get_end(i) as i64)
            break

    if target.len() == 0 or new_name.len() == 0:
        lsp_write_response(jrpc_result_null(id))
        return

    // Validate new name is a legal identifier
    if not lsp_is_valid_ident(new_name):
        lsp_write_response(jrpc_error(id, -32602, "Invalid identifier: " ++ new_name))
        return

    // Build WorkspaceEdit with changes per file
    var changes = jobj_start()
    var first_file = true

    // Current file edits
    var edits = jarr_start()
    var first = true
    var lex1 = Lexer.init(text, 0)
    let toks1 = lex1.tokenize()
    for ti in 0..toks1.len():
        if toks1.get_tag(ti) != TokenKind.TK_IDENT:
            continue
        let tt = text.slice(toks1.get_start(ti) as i64, toks1.get_end(ti) as i64)
        if tt != target:
            continue
        let rl = lsp_offset_to_line(text, toks1.get_start(ti))
        let rc = lsp_offset_to_col(text, toks1.get_start(ti))
        let re = lsp_offset_to_col(text, toks1.get_end(ti))
        if not first:
            edits = edits ++ ","
        first = false
        edits = edits ++ jobj_start() ++ jkv_raw("range", jrange(rl, rc, rl, re)) ++ "," ++ jkv_str("newText", new_name) ++ jobj_end()
    edits = edits ++ jarr_end()
    changes = changes ++ jkv_raw(json_escape(uri), edits)
    first_file = false

    // Cross-file edits via cached decl_source_paths
    let cidx = state.find_doc(uri)
    if cidx >= 0:
        state.documents.get(cidx as i64).ensure_analyzed()
    var cached_paths: Vec[str] = Vec.new()
    if cidx >= 0 and state.documents.get(cidx as i64).cache_valid:
        cached_paths = state.documents.get(cidx as i64).cached_decl_paths
    if cached_paths.len() > 0:
        var scanned_paths = uri_to_path(uri) ++ "\n"
        for di in 0..cached_paths.len() as i32:
            let dpath = cached_paths.get(di as i64)
            if dpath.len() == 0 or dpath.starts_with("<embedded"):
                continue
            if lsp_find_substr(scanned_paths, dpath) >= 0:
                continue
            scanned_paths = scanned_paths ++ dpath ++ "\n"
            let ft = with_fs_read_file(dpath)
            if ft.len() == 0:
                continue
            var file_edits = jarr_start()
            var fe_first = true
            var lex2 = Lexer.init(ft, 0)
            let toks2 = lex2.tokenize()
            var has_edits = false
            for ti2 in 0..toks2.len():
                if toks2.get_tag(ti2) != TokenKind.TK_IDENT:
                    continue
                let tt2 = ft.slice(toks2.get_start(ti2) as i64, toks2.get_end(ti2) as i64)
                if tt2 != target:
                    continue
                let rl2 = lsp_offset_to_line(ft, toks2.get_start(ti2))
                let rc2 = lsp_offset_to_col(ft, toks2.get_start(ti2))
                let re2 = lsp_offset_to_col(ft, toks2.get_end(ti2))
                if not fe_first:
                    file_edits = file_edits ++ ","
                fe_first = false
                has_edits = true
                file_edits = file_edits ++ jobj_start() ++ jkv_raw("range", jrange(rl2, rc2, rl2, re2)) ++ "," ++ jkv_str("newText", new_name) ++ jobj_end()
            file_edits = file_edits ++ jarr_end()
            if has_edits:
                let file_uri = "file://" ++ dpath
                if not first_file:
                    changes = changes ++ ","
                first_file = false
                changes = changes ++ jkv_raw(json_escape(file_uri), file_edits)

    changes = changes ++ jobj_end()
    let result = jobj_start() ++ jkv_raw("changes", changes) ++ jobj_end()
    lsp_write_response(jrpc_result(id, result))

// ── Main loop ────────────────────────────────────────────────

fn lsp_extract_uri(msg: str, tokens: *mut JsonToken, params_idx: i32) -> str:
    let td = json_find(msg, tokens, params_idx, "textDocument")
    json_tok_str(msg, tokens, json_find(msg, tokens, td, "uri"))

fn lsp_extract_position(msg: str, tokens: *mut JsonToken, params_idx: i32, line_out: *mut i32, char_out: *mut i32):
    let pos = json_find(msg, tokens, params_idx, "position")
    unsafe:
        *(line_out + 0u64) = json_tok_int(msg, tokens, json_find(msg, tokens, pos, "line"))
        *(char_out + 0u64) = json_tok_int(msg, tokens, json_find(msg, tokens, pos, "character"))

let LSP_MAX_TOKENS: i32 = 256

fn run_lsp() -> i32:
    var state = LspState.new()
    let tokens = malloc((LSP_MAX_TOKENS * 20) as i64) as *mut JsonToken

    while true:
        let msg = lsp_read_message()
        if msg.len() == 0:
            break

        let count = lsp_json_parse(msg, tokens, LSP_MAX_TOKENS)
        if count < 0:
            continue

        let method = json_tok_str(msg, tokens, json_find(msg, tokens, 0, "method"))
        let id = json_tok_int(msg, tokens, json_find(msg, tokens, 0, "id"))
        let params_idx = json_find(msg, tokens, 0, "params")

        if method == "initialize":
            state.initialized = true
            let completion_opts = jobj_start() ++ jkv_raw("triggerCharacters", "[\".\"]") ++ jobj_end()
            let sig_help_opts = jobj_start() ++ jkv_raw("triggerCharacters", "[\"(\", \",\"]") ++ jobj_end()
            let caps = jobj_start() ++ jkv_int("textDocumentSync", 1) ++ "," ++ jkv_bool("hoverProvider", true) ++ "," ++ jkv_bool("definitionProvider", true) ++ "," ++ jkv_bool("documentFormattingProvider", true) ++ "," ++ jkv_raw("completionProvider", completion_opts) ++ "," ++ jkv_raw("signatureHelpProvider", sig_help_opts) ++ "," ++ jkv_bool("documentSymbolProvider", true) ++ "," ++ jkv_bool("referencesProvider", true) ++ "," ++ jkv_bool("renameProvider", true) ++ jobj_end()
            let info = jobj_start() ++ jkv_str("name", "with-lsp") ++ "," ++ jkv_str("version", "0.1.0") ++ jobj_end()
            let result = jobj_start() ++ jkv_raw("capabilities", caps) ++ "," ++ jkv_raw("serverInfo", info) ++ jobj_end()
            lsp_write_response(jrpc_result(id, result))

        else if method == "initialized":
            continue

        else if method == "shutdown":
            lsp_write_response(jrpc_result_null(id))

        else if method == "exit":
            free(tokens as *mut u8)
            return 0

        else if method == "textDocument/didOpen":
            let td = json_find(msg, tokens, params_idx, "textDocument")
            let uri = json_tok_str(msg, tokens, json_find(msg, tokens, td, "uri"))
            let text = json_tok_str(msg, tokens, json_find(msg, tokens, td, "text"))
            let version = json_tok_int(msg, tokens, json_find(msg, tokens, td, "version"))
            state.set_doc(uri, text, version)
            // Proactive: parse + analyze so subsequent requests hit cache
            let oi = state.find_doc(uri)
            if oi >= 0:
                state.documents.get(oi as i64).ensure_parsed()
                state.documents.get(oi as i64).ensure_analyzed()
            lsp_publish_diagnostics(state, uri, text)

        else if method == "textDocument/didChange":
            let uri = lsp_extract_uri(msg, tokens, params_idx)
            // contentChanges[0].text (full sync mode)
            let changes_idx = json_find(msg, tokens, params_idx, "contentChanges")
            var text = ""
            if changes_idx >= 0:
                // First array element is at changes_idx + 1
                let change_idx = changes_idx + 1
                text = json_tok_str(msg, tokens, json_find(msg, tokens, change_idx, "text"))
            if text.len() > 0:
                state.set_doc(uri, text, 0)
                lsp_publish_diagnostics(state, uri, text)

        else if method == "textDocument/didSave":
            let uri = lsp_extract_uri(msg, tokens, params_idx)
            let idx = state.find_doc(uri)
            if idx >= 0:
                // Re-analyze on save (slow tier refreshes cross-file data)
                state.documents.get(idx as i64).ensure_analyzed()
                let doc = state.documents.get(idx as i64)
                lsp_publish_diagnostics(state, uri, doc.text)

        else if method == "textDocument/hover":
            let uri = lsp_extract_uri(msg, tokens, params_idx)
            var line: i32 = 0
            var character: i32 = 0
            lsp_extract_position(msg, tokens, params_idx, &raw mut line as *mut i32, &raw mut character as *mut i32)
            let idx = state.find_doc(uri)
            if idx >= 0:
                let doc = state.documents.get(idx as i64)
                lsp_hover(id, state, uri, doc.text, line, character)
            else:
                lsp_write_response(jrpc_result_null(id))

        else if method == "textDocument/definition":
            let uri = lsp_extract_uri(msg, tokens, params_idx)
            var line: i32 = 0
            var character: i32 = 0
            lsp_extract_position(msg, tokens, params_idx, &raw mut line as *mut i32, &raw mut character as *mut i32)
            let idx = state.find_doc(uri)
            if idx >= 0:
                let doc = state.documents.get(idx as i64)
                lsp_definition(id, state, uri, doc.text, line, character)
            else:
                lsp_write_response(jrpc_result_null(id))

        else if method == "textDocument/formatting":
            let uri = lsp_extract_uri(msg, tokens, params_idx)
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
            let uri = lsp_extract_uri(msg, tokens, params_idx)
            var line: i32 = 0
            var character: i32 = 0
            lsp_extract_position(msg, tokens, params_idx, &raw mut line as *mut i32, &raw mut character as *mut i32)
            let idx = state.find_doc(uri)
            if idx >= 0:
                let doc = state.documents.get(idx as i64)
                lsp_completion(id, state, uri, doc.text, line, character)
            else:
                lsp_write_response(jrpc_result(id, jobj_start() ++ jkv_raw("items", "[]") ++ jobj_end()))

        else if method == "textDocument/signatureHelp":
            let uri = lsp_extract_uri(msg, tokens, params_idx)
            var line: i32 = 0
            var character: i32 = 0
            lsp_extract_position(msg, tokens, params_idx, &raw mut line as *mut i32, &raw mut character as *mut i32)
            let idx = state.find_doc(uri)
            if idx >= 0:
                let doc = state.documents.get(idx as i64)
                lsp_signature_help(id, state, uri, doc.text, line, character)
            else:
                lsp_write_response(jrpc_result_null(id))

        else if method == "textDocument/references":
            let uri = lsp_extract_uri(msg, tokens, params_idx)
            var line: i32 = 0
            var character: i32 = 0
            lsp_extract_position(msg, tokens, params_idx, &raw mut line as *mut i32, &raw mut character as *mut i32)
            let idx = state.find_doc(uri)
            if idx >= 0:
                let doc = state.documents.get(idx as i64)
                lsp_find_references(id, state, uri, doc.text, line, character)
            else:
                lsp_write_response(jrpc_result(id, "[]"))

        else if method == "textDocument/documentSymbol":
            let uri = lsp_extract_uri(msg, tokens, params_idx)
            let idx = state.find_doc(uri)
            if idx >= 0:
                let doc = state.documents.get(idx as i64)
                lsp_document_symbols(id, state, uri, doc.text)
            else:
                lsp_write_response(jrpc_result(id, "[]"))

        else if method == "textDocument/rename":
            let uri = lsp_extract_uri(msg, tokens, params_idx)
            var line: i32 = 0
            var character: i32 = 0
            lsp_extract_position(msg, tokens, params_idx, &raw mut line as *mut i32, &raw mut character as *mut i32)
            let new_name = json_tok_str(msg, tokens, json_find(msg, tokens, params_idx, "newName"))
            let idx = state.find_doc(uri)
            if idx >= 0:
                let doc = state.documents.get(idx as i64)
                lsp_rename(id, state, uri, doc.text, line, character, new_name)
            else:
                lsp_write_response(jrpc_result_null(id))

        else:
            if id >= 0:
                lsp_write_response(jrpc_error(id, -32601, "Method not found: " ++ method))

    free(tokens as *mut u8)
    0
