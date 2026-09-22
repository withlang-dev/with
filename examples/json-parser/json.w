module json

// ===================================================================
// JSON Parser — Recursive Descent
//
// Demonstrates:
//   - Algebraic data types (enum variants with data)
//   - Pattern matching (nested, guards, or-patterns)
//   - Error declarations with positional context
//   - mut fn receivers (scoped mutation of the tokenizer and parser)
//   - String interpolation (f-strings)
//   - Result type, ? and implicit Ok on the happy path
//   - Borrowed tree access: Option[&JsonValue] views
// ===================================================================

// --- JSON Value Type ---

enum JsonValue {
    Null
    | Bool(bool)
    | Number(f64)
    | Str(str)
    | Array(Vec[JsonValue])
    | Object(Vec[JsonKV])
}

type JsonKV {
    key: str,
    value: JsonValue,
}

// --- Errors ---

error JsonError =
    UnexpectedChar(usize, str, u8)
    | UnexpectedEof(usize, str)
    | InvalidNumber(usize, str)
    | InvalidEscape(usize, u8)
    | TrailingContent(usize)

// --- Token Types ---

enum Token {
    LBrace
    | RBrace
    | LBracket
    | RBracket
    | Colon
    | Comma
    | TNull
    | TBool(bool)
    | TNumber(f64)
    | TString(str)
}

// --- Tokenizer ---

type Tokenizer {
    input: str,
    pos: usize = 0,
}

fn is_whitespace(ch: u8) -> bool: ch in [b' ', b'\t', b'\n', b'\r']

fn is_digit(ch: u8) -> bool: ch in b'0'..=b'9'

fn Tokenizer.new(input: str): Tokenizer { input }

// The byte arms are guards until a byte literal is accepted as a
// pattern (#1295).
extend Tokenizer:
    fn peek() -> Option[u8]:
        if self.pos < self.input.len():
            Some(self.input.byte_at(self.pos as i64))
        else:
            None

    mut fn advance() -> Option[u8]:
        let ch = self.peek() ?? return None
        self.pos += 1
        Some(ch)

    mut fn skip_whitespace():
        loop:
            match self.peek():
                Some(ch) if is_whitespace(ch) => self.pos += 1
                _ => break

    mut fn next_token() -> Result[Option[Token], JsonError]:
        self.skip_whitespace()
        match self.advance():
            None                       => None
            Some(ch) if ch == b'{'     => Some(.LBrace)
            Some(ch) if ch == b'}'     => Some(.RBrace)
            Some(ch) if ch == b'['     => Some(.LBracket)
            Some(ch) if ch == b']'     => Some(.RBracket)
            Some(ch) if ch == b':'     => Some(.Colon)
            Some(ch) if ch == b','     => Some(.Comma)
            Some(ch) if ch == b'"'     =>
                let s = self.read_string()?
                Some(.TString(s))
            Some(ch) if ch == b't'     =>
                self.expect_literal("rue")?
                Some(.TBool(true))
            Some(ch) if ch == b'f'     =>
                self.expect_literal("alse")?
                Some(.TBool(false))
            Some(ch) if ch == b'n'     =>
                self.expect_literal("ull")?
                Some(.TNull)
            Some(ch) if ch == b'-' or is_digit(ch) =>
                self.pos -= 1
                let n = self.read_number()?
                Some(.TNumber(n))
            Some(ch) => return Err(.UnexpectedChar(self.pos - 1, "valid JSON token", ch))

    mut fn read_string() -> Result[str, JsonError]:
        var result = ""
        loop:
            match self.advance():
                None => return Err(.UnexpectedEof(self.pos, "unterminated string"))
                Some(ch) if ch == b'"' => break
                Some(ch) if ch == b'\\' =>
                    match self.advance():
                        Some(esc) if esc == b'"'  => result = result ++ "\""
                        Some(esc) if esc == b'\\' => result = result ++ "\\"
                        Some(esc) if esc == b'/'  => result = result ++ "/"
                        Some(esc) if esc == b'n'  => result = result ++ "\n"
                        Some(esc) if esc == b't'  => result = result ++ "\t"
                        Some(esc) if esc == b'r'  => result = result ++ "\r"
                        Some(esc) => return Err(.InvalidEscape(self.pos - 1, esc))
                        None => return Err(.UnexpectedEof(self.pos, "escape sequence"))
                Some(_) =>
                    // Build string one character at a time
                    result = result ++ self.input.slice((self.pos - 1) as i64, self.pos as i64)
        result

    mut fn read_number() -> Result[f64, JsonError]:
        let start = self.pos
        // optional minus
        if self.peek() == Some(b'-'):
            self.pos += 1
        // integer part
        self.read_digits()
        // optional fractional part
        if self.peek() == Some(b'.'):
            self.pos += 1
            self.read_digits()
        // optional exponent
        let p = self.peek()
        if p == Some(b'e') or p == Some(b'E'):
            self.pos += 1
            let sign = self.peek()
            if sign == Some(b'+') or sign == Some(b'-'):
                self.pos += 1
            self.read_digits()

        let text = self.input.slice(start as i64, self.pos as i64)
        // Simple manual number parsing
        parse_number_str(text, start)

    mut fn read_digits():
        loop:
            match self.peek():
                Some(ch) if is_digit(ch) => self.pos += 1
                _ => break

    mut fn expect_literal(expected: &str) -> Result[Unit, JsonError]:
        for i in 0..expected.len():
            match self.advance():
                Some(got) if got == expected.byte_at(i as i64) => ()
                Some(got) => return Err(.UnexpectedChar(self.pos - 1, expected, got))
                None => return Err(.UnexpectedEof(self.pos, "literal"))

// Simple number parsing helper
fn parse_number_str(text: str, start: usize) -> Result[f64, JsonError]:
    var result: f64 = 0.0
    var sign: f64 = 1.0
    var i: usize = 0

    // handle sign
    if i < text.len() and text.byte_at(i as i64) == b'-':
        sign = -1.0
        i += 1

    // integer part
    while i < text.len() and is_digit(text.byte_at(i as i64)):
        result = result * 10.0 + (text.byte_at(i as i64) - b'0') as f64
        i += 1

    // fractional part
    if i < text.len() and text.byte_at(i as i64) == b'.':
        i += 1
        var frac: f64 = 0.1
        while i < text.len() and is_digit(text.byte_at(i as i64)):
            result = result + (text.byte_at(i as i64) - b'0') as f64 * frac
            frac = frac * 0.1
            i += 1

    // skip exponent for now (simplified)
    sign * result

// --- Recursive Descent Parser ---
//
// The parser holds one token of lookahead. `advance` transfers the
// current token out (a vacate from the `mut fn` receiver, §2.2) and
// loads the next one; the `peek_*` helpers observe it through a view.

type Parser {
    tokenizer: Tokenizer,
    current: Option[Token],
}

fn Parser.new(input: str) -> Result[Parser, JsonError]:
    var tokenizer = Tokenizer.new(input)
    let first = tokenizer.next_token()?
    Parser { tokenizer, current: first }

fn is_comma(tok: &Option[Token]) -> bool:
    match tok:
        Some(.Comma) => true
        _ => false

fn is_rbracket(tok: &Option[Token]) -> bool:
    match tok:
        Some(.RBracket) => true
        _ => false

fn is_rbrace(tok: &Option[Token]) -> bool:
    match tok:
        Some(.RBrace) => true
        _ => false

extend Parser:
    // Consume the current token and read the next one.
    mut fn advance() -> Result[Option[Token], JsonError]:
        let tok = move self.current
        self.current = self.tokenizer.next_token()?
        tok

    mut fn parse_value() -> Result[JsonValue, JsonError]:
        match self.advance()?:
            Some(.LBrace)     => return self.parse_object()
            Some(.LBracket)   => return self.parse_array()
            Some(.TNull)      => .Null
            Some(.TBool(b))   => .Bool(b)
            Some(.TNumber(n)) => .Number(n)
            Some(.TString(s)) => .Str(s)
            Some(_)           => return Err(.UnexpectedChar(self.tokenizer.pos, "JSON value", 0))
            None              => return Err(.UnexpectedEof(self.tokenizer.pos, "JSON value"))

    // Called after '[' was consumed.
    mut fn parse_array() -> Result[JsonValue, JsonError]:
        var items: Vec[JsonValue] = Vec.new()
        // empty array
        if is_rbracket(&self.current):
            self.advance()?
            return Ok(.Array(items))
        // first element
        let first = self.parse_value()?
        items.push(first)
        // remaining elements
        loop:
            if is_comma(&self.current):
                self.advance()?
                let elem = self.parse_value()?
                items.push(elem)
            else if is_rbracket(&self.current):
                self.advance()?
                break
            else:
                return Err(.UnexpectedEof(self.tokenizer.pos, "array element or ']'"))
        JsonValue.Array(items)

    // Called after '{' was consumed.
    mut fn parse_object() -> Result[JsonValue, JsonError]:
        var entries: Vec[JsonKV] = Vec.new()
        // empty object
        if is_rbrace(&self.current):
            self.advance()?
            return Ok(.Object(entries))
        // first key-value pair
        let first_kv = self.parse_kv()?
        entries.push(first_kv)
        // remaining pairs
        loop:
            if is_comma(&self.current):
                self.advance()?
                let kv = self.parse_kv()?
                entries.push(kv)
            else if is_rbrace(&self.current):
                self.advance()?
                break
            else:
                return Err(.UnexpectedEof(self.tokenizer.pos, "object entry or '}'"))
        JsonValue.Object(entries)

    mut fn parse_kv() -> Result[JsonKV, JsonError]:
        // expect string key
        let key = match self.advance()?:
            Some(.TString(s)) => s
            _ => return Err(.UnexpectedChar(self.tokenizer.pos, "string key", 0))
        // expect colon
        match self.advance()?:
            Some(.Colon) => ()
            _ => return Err(.UnexpectedChar(self.tokenizer.pos, "':'", 0))
        let value = self.parse_value()?
        JsonKV { key, value }

fn parse(input: str) -> Result[JsonValue, JsonError]:
    var parser = Parser.new(input)?
    let value = parser.parse_value()?
    if parser.current.is_some():
        return Err(.TrailingContent(parser.tokenizer.pos))
    value

// --- Display ---
//
// The tree is observed, never consumed (§3.8): every accessor takes
// `&JsonValue` and the lookups return views (Option[&JsonValue], D27).

fn json_to_string(val: &JsonValue) -> str:
    match val:
        .Null       => "null"
        .Bool(b)    => f"{b}"
        .Number(n)  => f"{n}"
        .Str(s)     => "\"" ++ s ++ "\""
        .Array(items) =>
            var parts: Vec[str] = Vec.new()
            for item in items:
                parts.push(json_to_string(item))
            let inner = parts.join(", ")
            "[" ++ inner ++ "]"
        .Object(entries) =>
            var parts: Vec[str] = Vec.new()
            for entry in entries:
                let v = json_to_string(&entry.value)
                parts.push("\"" ++ entry.key ++ "\": " ++ v)
            let inner = parts.join(", ")
            "{" ++ inner ++ "}"

// A field view of an entry. (`&entry.value` inline is rejected until
// #1297 pins the projection to the parameter's origin.)
fn kv_value(kv: &JsonKV) -> &JsonValue: &kv.value

fn json_get_field(val: &JsonValue, key: str) -> Option[&JsonValue]:
    match val:
        .Object(entries) =>
            for i in 0..entries.len():
                if entries[i].key == key:
                    return Some(kv_value(entries.get(i)))
            None
        _ => None

fn json_get_index(val: &JsonValue, idx: i32) -> Option[&JsonValue]:
    match val:
        .Array(items) if idx < items.len() => Some(items.get(idx))
        _ => None

// --- Main Demo ---

fn main:
    let input = "{\"name\": \"With Language\", \"version\": 3.2, \"features\": [\"handles\", \"fibers\", \"comptime\"], \"meta\": {\"stable\": false, \"authors\": [\"core-team\"], \"stats\": {\"stars\": 0, \"forks\": null}}}"

    print("=== JSON Parser Demo ===\n")
    print(f"Input ({input.len()} bytes):\n{input}\n")

    match parse(input):
        Ok(value) =>
            print("Parsed successfully!\n")
            let pretty = json_to_string(&value)
            print(f"Pretty: {pretty}\n")

            // Access nested values through views
            if let Some(.Str(name)) = json_get_field(&value, "name"):
                print(f"Name: {name}")
            else:
                print("Name: unknown")

            let version = match json_get_field(&value, "version"):
                Some(.Number(n)) => n
                _ => 0.0
            print(f"Version: {version}")

            // Access array elements
            let features = json_get_field(&value, "features")
            if let Some(list) = features:
                if let Some(.Str(first)) = json_get_index(list, 0):
                    print(f"First feature: {first}")
                else:
                    print("First feature: none")
            else:
                print("First feature: none")

            // Count features
            let feature_count = match json_get_field(&value, "features"):
                Some(.Array(arr)) => arr.len()
                _ => 0
            print(f"\nFeature count: {feature_count}")

        Err(e) =>
            print(f"Parse error: {e}")

    // Demonstrate error handling
    print("\n--- Error cases ---")
    let bad1 = "{\"key\": }"
    let bad2 = "[1, 2,"
    let bad3 = "\"hello"
    match parse(bad1):
        Ok(_)  => print("  missing value: unexpectedly succeeded")
        Err(e) => print(f"  missing value: {e}")
    match parse(bad2):
        Ok(_)  => print("  unterminated array: unexpectedly succeeded")
        Err(e) => print(f"  unterminated array: {e}")
    match parse(bad3):
        Ok(_)  => print("  unterminated string: unexpectedly succeeded")
        Err(e) => print(f"  unterminated string: {e}")

    print("\n=== Demo complete ===")
