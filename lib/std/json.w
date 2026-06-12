// std.json — Minimal JSON writer and tokenizer
//
// Port of jsmn (https://github.com/zserge/jsmn) by Serge Zaitsev.
// Single-pass tokenizer. Tokens store byte offsets into the source string.
// Always includes parent links. Non-strict mode.

extern fn str_from_byte(b: i32) -> str
extern fn with_alloc_zeroed(count: i64, size: i64) -> *i8

pub type JsonWriter {
    text: str,
    needs_comma: bool,
    after_key: bool,
}

pub trait Serialize:    fn serialize(self: &Self, out:
    JsonWriter) -> JsonWriter

pub type JsonView {
    source: str,
    tokens: *const JsonToken,
    index: i32,
}

pub type JsonDocument {
    source: str,
    tokens: *mut JsonToken,
    count: i32,
}

pub trait Deserialize:    fn deserialize(input:
    JsonView) -> Self

pub fn JsonWriter.new() -> JsonWriter:
    JsonWriter { text: "", needs_comma: false, after_key: false }

pub fn JsonWriter.finish(self: &JsonWriter) -> str:
    self.text

fn json_escape_string(value: str) -> str:
    var out = ""
    var i = 0
    while i < value.len() as i32:
        let ch = value.byte_at(i as i64)
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
            out = out ++ value.slice(i as i64, (i + 1) as i64)
        i = i + 1
    out

fn json_quote(value: str) -> str:
    "\"" ++ json_escape_string(value) ++ "\""

fn JsonWriter.prefix_value(self: JsonWriter) -> JsonWriter:
    if self.after_key:
        return JsonWriter { text: self.text, needs_comma: self.needs_comma, after_key: false }
    if self.needs_comma:
        return JsonWriter { text: self.text ++ ",", needs_comma: self.needs_comma, after_key: self.after_key }
    JsonWriter { text: self.text, needs_comma: self.needs_comma, after_key: self.after_key }

pub fn JsonWriter.begin_object(self: JsonWriter) -> JsonWriter:
    let prefixed = self.prefix_value()
    JsonWriter { text: prefixed.text ++ "{", needs_comma: false, after_key: false }

pub fn JsonWriter.end_object(self: JsonWriter) -> JsonWriter:
    JsonWriter { text: self.text ++ "}", needs_comma: true, after_key: false }

pub fn JsonWriter.key(self: JsonWriter, key: str) -> JsonWriter:
    let prefix = if self.needs_comma: "," else: ""
    JsonWriter { text: self.text ++ prefix ++ json_quote(key) ++ ":", needs_comma: false, after_key: true }

pub fn JsonWriter.value_raw(self: JsonWriter, raw: str) -> JsonWriter:
    let prefixed = self.prefix_value()
    JsonWriter { text: prefixed.text ++ raw, needs_comma: true, after_key: false }

pub fn JsonWriter.value_str(self: JsonWriter, value: str) -> JsonWriter:
    self.value_raw(json_quote(value))

pub fn JsonWriter.value_i32(self: JsonWriter, value: i32) -> JsonWriter:
    self.value_raw(with_i32_to_str(value))

pub fn JsonWriter.value_i64(self: JsonWriter, value: i64) -> JsonWriter:
    self.value_raw(with_i64_to_str(value))

pub fn JsonWriter.value_bool(self: JsonWriter, value: bool) -> JsonWriter:
    self.value_raw(if value: "true" else: "false")

impl Serialize for str:    fn serialize(self: &str, out:
    JsonWriter) -> JsonWriter:
        out.value_str(*self)

impl Serialize for i32:    fn serialize(self: &i32, out:
    JsonWriter) -> JsonWriter:
        out.value_i32(*self)

impl Serialize for i64:    fn serialize(self: &i64, out:
    JsonWriter) -> JsonWriter:
        out.value_i64(*self)

impl Serialize for bool:    fn serialize(self: &bool, out:
    JsonWriter) -> JsonWriter:
        out.value_bool(*self)

/// Token type: undefined/uninitialized.
let JSON_UNDEFINED: i32 = 0
/// Token type: JSON object `{}`.
let JSON_OBJECT: i32 = 1
/// Token type: JSON array `[]`.
let JSON_ARRAY: i32 = 2
/// Token type: JSON string `"..."`.
let JSON_STRING: i32 = 4
/// Token type: JSON primitive (number, boolean, null).
let JSON_PRIMITIVE: i32 = 8

/// Error: not enough token slots. Allocate a larger token array.
let JSON_ERROR_NOMEM: i32 = -1
/// Error: invalid/malformed JSON.
let JSON_ERROR_INVAL: i32 = -2
/// Error: incomplete JSON, more data expected.
let JSON_ERROR_PART: i32 = -3

/// A parsed JSON token. Stores byte offsets into the source string.
/// `tok_type` is one of JSON_OBJECT, JSON_ARRAY, JSON_STRING, JSON_PRIMITIVE.
/// `size` is the number of direct children (keys for objects, elements for arrays).
/// `parent` is the index of the parent token (-1 for root).
pub type JsonToken {
    tok_type: i32,
    start: i32,
    end: i32,
    size: i32,
    parent: i32,
}

/// Parser state. Create with `JsonParser.new()`, pass to `json_parse()`.
type JsonParser {
    pos: i32,
    toknext: i32,
    toksuper: i32,
}

/// Create a new JSON parser, ready to parse.
pub fn JsonParser.new() -> JsonParser:
    JsonParser { pos: 0, toknext: 0, toksuper: -1 }

// Allocate a token slot. Returns index or -1 if full.
unsafe fn alloc_token(parser: *mut JsonParser, tokens: *mut JsonToken, num_tokens: i32) -> i32:
    if parser.toknext >= num_tokens:
        return -1
    let idx = parser.toknext
    parser.toknext = parser.toknext + 1
    let tok = tokens + idx as u64
    tok.start = -1
    tok.end = -1
    tok.size = 0
    tok.parent = -1
    tok.tok_type = JSON_UNDEFINED
    idx

// Set token type and boundaries.
unsafe fn fill_token(tokens: *mut JsonToken, idx: i32, tok_type: i32, start: i32, end: i32):
    let tok = tokens + idx as u64
    tok.tok_type = tok_type
    tok.start = start
    tok.end = end
    tok.size = 0

// Parse a primitive (number, boolean, null).
unsafe fn parse_primitive(parser: *mut JsonParser, js: str, len: i32, tokens: *mut JsonToken, num_tokens: i32) -> i32:
    let start = parser.pos
    while parser.pos < len:
        let c = js.byte_at(parser.pos as i64) as i32
        if c == 0:
            break
        // Terminators: : \t \r \n space , ] }
        if c == 58 or c == 9 or c == 13 or c == 10 or c == 32 or c == 44 or c == 93 or c == 125:
            break
        if c < 32 or c >= 127:
            parser.pos = start
            return JSON_ERROR_INVAL
        parser.pos = parser.pos + 1
    // Allocate and fill
    let tok_idx = alloc_token(parser, tokens, num_tokens)
    if tok_idx < 0:
        parser.pos = start
        return JSON_ERROR_NOMEM
    fill_token(tokens, tok_idx, JSON_PRIMITIVE, start, parser.pos)
    (*(tokens + tok_idx as u64)).parent = parser.toksuper
    parser.pos = parser.pos - 1
    0

// Parse a JSON string with escape handling.
unsafe fn parse_string(parser: *mut JsonParser, js: str, len: i32, tokens: *mut JsonToken, num_tokens: i32) -> i32:
    let start = parser.pos
    // Skip opening quote
    parser.pos = parser.pos + 1
    while parser.pos < len:
        let c = js.byte_at(parser.pos as i64) as i32
        if c == 0:
            break
        // Closing quote
        if c == 34:
            let tok_idx = alloc_token(parser, tokens, num_tokens)
            if tok_idx < 0:
                parser.pos = start
                return JSON_ERROR_NOMEM
            fill_token(tokens, tok_idx, JSON_STRING, start + 1, parser.pos)
            (*(tokens + tok_idx as u64)).parent = parser.toksuper
            return 0
        // Backslash escape
        if c == 92 and parser.pos + 1 < len:
            parser.pos = parser.pos + 1
            let esc = js.byte_at(parser.pos as i64) as i32
            // " / \ b f r n t
            if esc == 34 or esc == 47 or esc == 92 or esc == 98 or esc == 102 or esc == 114 or esc == 110 or esc == 116:
                0  // valid escape, continue
            else if esc == 117:
                // \uXXXX
                parser.pos = parser.pos + 1
                var hi = 0
                while hi < 4 and parser.pos < len:
                    let hc = js.byte_at(parser.pos as i64) as i32
                    if hc == 0:
                        break
                    if not ((hc >= 48 and hc <= 57) or (hc >= 65 and hc <= 70) or (hc >= 97 and hc <= 102)):
                        parser.pos = start
                        return JSON_ERROR_INVAL
                    parser.pos = parser.pos + 1
                    hi = hi + 1
                parser.pos = parser.pos - 1
            else:
                parser.pos = start
                return JSON_ERROR_INVAL
        parser.pos = parser.pos + 1
    parser.pos = start
    JSON_ERROR_PART

// Parse JSON string into tokens.
// Returns token count on success, negative error code on failure.
unsafe fn json_parse_impl(parser: *mut JsonParser, js: str, len: i32, tokens: *mut JsonToken, num_tokens: i32) -> i32:
    var count = parser.toknext

    while parser.pos < len:
        let c = js.byte_at(parser.pos as i64) as i32
        if c == 0:
            break

        // { or [
        if c == 123 or c == 91:
            count = count + 1
            let tok_idx = alloc_token(parser, tokens, num_tokens)
            if tok_idx < 0:
                return JSON_ERROR_NOMEM
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

        // } or ]
        else if c == 125 or c == 93:
            var expected_type = JSON_OBJECT
            if c == 93:
                expected_type = JSON_ARRAY
            if parser.toknext < 1:
                return JSON_ERROR_INVAL
            // Walk parent links to find matching opener
            var ti = parser.toknext - 1
            var matched = false
            while not matched:
                let tok = tokens + ti as u64
                if tok.start != -1 and tok.end == -1:
                    if tok.tok_type != expected_type:
                        return JSON_ERROR_INVAL
                    tok.end = parser.pos + 1
                    parser.toksuper = tok.parent
                    matched = true
                else if tok.parent == -1:
                    if tok.tok_type != expected_type or parser.toksuper == -1:
                        return JSON_ERROR_INVAL
                    matched = true
                else:
                    ti = tok.parent

        // "
        else if c == 34:
            let r = parse_string(parser, js, len, tokens, num_tokens)
            if r < 0:
                return r
            count = count + 1
            if parser.toksuper != -1:
                (*(tokens + parser.toksuper as u64)).size = (*(tokens + parser.toksuper as u64)).size + 1

        // whitespace
        else if c == 9 or c == 13 or c == 10 or c == 32:
            0  // skip

        // :
        else if c == 58:
            parser.toksuper = parser.toknext - 1

        // ,
        else if c == 44:
            if parser.toksuper != -1:
                let sup = tokens + parser.toksuper as u64
                if sup.tok_type != JSON_ARRAY and sup.tok_type != JSON_OBJECT:
                    parser.toksuper = sup.parent

        // default: primitive
        else:
            let r = parse_primitive(parser, js, len, tokens, num_tokens)
            if r < 0:
                return r
            count = count + 1
            if parser.toksuper != -1:
                (*(tokens + parser.toksuper as u64)).size = (*(tokens + parser.toksuper as u64)).size + 1

        parser.pos = parser.pos + 1

    // Check for unclosed containers
    var i = parser.toknext - 1
    while i >= 0:
        let tok = tokens + i as u64
        if tok.start != -1 and tok.end == -1:
            return JSON_ERROR_PART
        i = i - 1

    count

/// Parse a JSON string into tokens. Returns token count on success,
/// or a negative error code (JSON_ERROR_NOMEM, JSON_ERROR_INVAL, JSON_ERROR_PART).
pub unsafe fn json_parse(parser: *mut JsonParser, js: str, tokens: *mut JsonToken, num_tokens: i32) -> i32:
    let len = js.len() as i32
    json_parse_impl(parser, js, len, tokens, num_tokens)

fn json_panic(msg: str) -> Unit:
    with_panic(msg, "", 0)

fn JsonToken.empty() -> JsonToken:
    JsonToken { tok_type: JSON_UNDEFINED, start: -1, end: -1, size: 0, parent: -1 }

/// Parse a JSON document into a fixed-size token buffer.
pub fn JsonDocument.parse(js: str) -> JsonDocument:
    let tokens = with_alloc_zeroed(256, sizeof[JsonToken]()) as *mut JsonToken
    if tokens == null:
        json_panic("could not allocate JSON token buffer")
    var parser = JsonParser.new()
    let count = unsafe { json_parse(&raw mut parser as *mut JsonParser, js, tokens, 256) }
    if count < 0:
        json_panic("invalid JSON")
    JsonDocument { source: js, tokens, count }

pub fn JsonDocument.root(self: &JsonDocument) -> JsonView:
    if self.count <= 0:
        json_panic("empty JSON document")
    JsonView { source: self.source, tokens: self.tokens as *const JsonToken, index: 0 }

fn JsonView.token_type(self: JsonView) -> i32:
    if self.index < 0:
        json_panic("missing JSON value")
    unsafe (*(self.tokens + self.index as u64)).tok_type

pub fn JsonView.raw(self: JsonView) -> str:
    json_str(self.source, self.tokens, self.index)

pub fn JsonView.field(self: JsonView, key: str) -> JsonView:
    if self.token_type() != JSON_OBJECT:
        json_panic("expected JSON object")
    let value_idx = json_find(self.source, self.tokens, self.index, key)
    if value_idx < 0:
        json_panic("missing JSON field: " ++ key)
    JsonView { source: self.source, tokens: self.tokens, index: value_idx }

// ── Lookup helpers ──────────────────────────────────────────────

/// Extract the text of a token from the source JSON string.
pub fn json_str(js: str, tokens: *const JsonToken, idx: i32) -> str:
    var start: i32 = 0
    var end: i32 = 0
    unsafe:
        start = (*(tokens + idx as u64)).start
        end = (*(tokens + idx as u64)).end
    js.slice(start as i64, end as i64)

/// Find the value token for a key in a JSON object.
/// Returns the token index of the value, or -1 if not found.
pub fn json_find(js: str, tokens: *const JsonToken, parent: i32, key: str) -> i32:
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
        // Each object child is a key-value pair: key at idx, value at idx+1
        let k = json_str(js, tokens, idx)
        if k == key:
            return idx + 1
        // Skip over the value (and any nested tokens)
        idx = json_skip(tokens, idx + 1)
        i = i + 1
    -1

/// Parse a primitive token as an integer. Returns 0 for non-numeric tokens.
pub fn json_int(js: str, tokens: *const JsonToken, idx: i32) -> i32:
    var start: i32 = 0
    var end: i32 = 0
    unsafe:
        start = (*(tokens + idx as u64)).start
        end = (*(tokens + idx as u64)).end
    // Manual int parse
    var val = 0
    var neg = false
    var pos = start
    if pos < end and js.byte_at(pos as i64) == 45:
        neg = true
        pos = pos + 1
    while pos < end:
        let d = js.byte_at(pos as i64) as i32
        if d >= 48 and d <= 57:
            val = val * 10 + (d - 48)
        else:
            break
        pos = pos + 1
    if neg: 0 - val else: val

/// Parse a primitive token as an i64. Returns 0 for non-numeric tokens.
pub fn json_i64(js: str, tokens: *const JsonToken, idx: i32) -> i64:
    var start: i32 = 0
    var end: i32 = 0
    unsafe:
        start = (*(tokens + idx as u64)).start
        end = (*(tokens + idx as u64)).end
    var val: i64 = 0
    var neg = false
    var pos = start
    if pos < end and js.byte_at(pos as i64) == 45:
        neg = true
        pos = pos + 1
    while pos < end:
        let d = js.byte_at(pos as i64) as i32
        if d >= 48 and d <= 57:
            val = val * 10 + (d - 48) as i64
        else:
            break
        pos = pos + 1
    if neg: 0i64 - val else: val

fn json_hex_value(ch: i32) -> i32:
    if ch >= 48 and ch <= 57:
        return ch - 48
    if ch >= 65 and ch <= 70:
        return ch - 55
    if ch >= 97 and ch <= 102:
        return ch - 87
    -1

fn json_unescape_string(value: str) -> str:
    var out = ""
    var i = 0
    while i < value.len() as i32:
        let ch = value.byte_at(i as i64) as i32
        if ch != 92:
            out = out ++ value.slice(i as i64, (i + 1) as i64)
        else:
            i = i + 1
            if i >= value.len() as i32:
                json_panic("invalid JSON string escape")
            let esc = value.byte_at(i as i64) as i32
            if esc == 34:
                out = out ++ "\""
            else if esc == 92:
                out = out ++ "\\"
            else if esc == 47:
                out = out ++ "/"
            else if esc == 98:
                out = out ++ str_from_byte(8)
            else if esc == 102:
                out = out ++ str_from_byte(12)
            else if esc == 110:
                out = out ++ "\n"
            else if esc == 114:
                out = out ++ "\r"
            else if esc == 116:
                out = out ++ "\t"
            else if esc == 117:
                if i + 4 >= value.len() as i32:
                    json_panic("invalid JSON unicode escape")
                let h0 = json_hex_value(value.byte_at((i + 1) as i64) as i32)
                let h1 = json_hex_value(value.byte_at((i + 2) as i64) as i32)
                let h2 = json_hex_value(value.byte_at((i + 3) as i64) as i32)
                let h3 = json_hex_value(value.byte_at((i + 4) as i64) as i32)
                if h0 < 0 or h1 < 0 or h2 < 0 or h3 < 0:
                    json_panic("invalid JSON unicode escape")
                let code = ((h0 * 4096) + (h1 * 256) + (h2 * 16) + h3)
                if code < 128:
                    out = out ++ str_from_byte(code)
                else:
                    json_panic("JSON unicode escapes above ASCII are not supported yet")
                i = i + 4
            else:
                json_panic("invalid JSON string escape")
        i = i + 1
    out

impl Deserialize for str:    fn deserialize(input:
    JsonView) -> str:
        if input.token_type() != JSON_STRING:
            json_panic("expected JSON string")
        json_unescape_string(input.raw())

impl Deserialize for i32:    fn deserialize(input:
    JsonView) -> i32:
        if input.token_type() != JSON_PRIMITIVE:
            json_panic("expected JSON integer")
        json_int(input.source, input.tokens, input.index)

impl Deserialize for i64:    fn deserialize(input:
    JsonView) -> i64:
        if input.token_type() != JSON_PRIMITIVE:
            json_panic("expected JSON integer")
        json_i64(input.source, input.tokens, input.index)

impl Deserialize for bool:    fn deserialize(input:
    JsonView) -> bool:
        if input.token_type() != JSON_PRIMITIVE:
            json_panic("expected JSON bool")
        let raw = input.raw()
        if raw == "true":
            return true
        if raw == "false":
            return false
        json_panic("expected JSON bool")
        false

// Skip over a token and all its nested children. Returns the next token index.
fn json_skip(tokens: *const JsonToken, idx: i32) -> i32:
    var tok_type: i32 = 0
    var size: i32 = 0
    unsafe:
        tok_type = (*(tokens + idx as u64)).tok_type
        size = (*(tokens + idx as u64)).size
    if tok_type == JSON_OBJECT:
        // Object: skip size key-value pairs
        var i = 0
        var next = idx + 1
        while i < size:
            next = json_skip(tokens, next)  // skip key
            next = json_skip(tokens, next)  // skip value
            i = i + 1
        return next
    if tok_type == JSON_ARRAY:
        // Array: skip size elements
        var i = 0
        var next = idx + 1
        while i < size:
            next = json_skip(tokens, next)
            i = i + 1
        return next
    // Primitive or string: just skip this one token
    idx + 1
