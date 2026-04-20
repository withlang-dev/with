module json

// ===================================================================
// JSON Parser — Recursive Descent
//
// Demonstrates:
//   - Algebraic data types (enum variants with data)
//   - Pattern matching (nested, guards, or-patterns)
//   - Error declarations with positional context
//   - with blocks (scoped mutation)
//   - String interpolation (f-strings)
//   - Result type and ? operator
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

fn is_whitespace(ch: u8) -> bool:
    ch == 32 or ch == 9 or ch == 10 or ch == 13

fn is_digit(ch: u8) -> bool:
    ch >= 48 and ch <= 57

extend Tokenizer:
    fn new(input: str):
        Tokenizer { input: input }

    fn peek(self: &Self) -> Option[u8]:
        if self.pos < self.input.len():
            Some(self.input.byte_at(self.pos as i64))
        else:
            None

    fn advance(self: &mut Self) -> Option[u8]:
        if self.pos < self.input.len():
            let ch = self.input.byte_at(self.pos as i64)
            self.pos = self.pos + 1
            Some(ch)
        else:
            None

    fn skip_whitespace(self: &mut Self):
        loop:
            match self.peek():
                Some(ch) if is_whitespace(ch) =>
                    self.pos = self.pos + 1
                _ => break

    fn next_token(self: &mut Self) -> Result[Option[Token], JsonError]:
        self.skip_whitespace()
        match self.advance():
            None         => Ok(None)
            Some(123)    => Ok(Some(Token.LBrace))      // '{'
            Some(125)    => Ok(Some(Token.RBrace))      // '}'
            Some(91)     => Ok(Some(Token.LBracket))    // '['
            Some(93)     => Ok(Some(Token.RBracket))    // ']'
            Some(58)     => Ok(Some(Token.Colon))       // ':'
            Some(44)     => Ok(Some(Token.Comma))       // ','
            Some(34)     =>                              // '"'
                let s = self.read_string()?
                Ok(Some(Token.TString(s)))
            Some(116)    =>                              // 't'
                self.expect_literal("rue")?
                Ok(Some(Token.TBool(true)))
            Some(102)    =>                              // 'f'
                self.expect_literal("alse")?
                Ok(Some(Token.TBool(false)))
            Some(110)    =>                              // 'n'
                self.expect_literal("ull")?
                Ok(Some(Token.TNull))
            Some(ch) if ch == 45 or is_digit(ch) =>
                self.pos = self.pos - 1
                let n = self.read_number()?
                Ok(Some(Token.TNumber(n)))
            Some(ch) => Err(JsonError.UnexpectedChar(self.pos - 1, "valid JSON token", ch))

    fn read_string(self: &mut Self) -> Result[str, JsonError]:
        var result = ""
        loop:
            match self.advance():
                None => return Err(JsonError.UnexpectedEof(self.pos, "unterminated string"))
                Some(34) => break                         // '"'
                Some(92) =>                               // '\\'
                    match self.advance():
                        Some(34)  => result = result ++ "\""
                        Some(92)  => result = result ++ "\\"
                        Some(47)  => result = result ++ "/"
                        Some(110) => result = result ++ "\n"
                        Some(116) => result = result ++ "\t"
                        Some(114) => result = result ++ "\r"
                        Some(ch)  => return Err(JsonError.InvalidEscape(self.pos - 1, ch))
                        None => return Err(JsonError.UnexpectedEof(self.pos, "escape sequence"))
                Some(ch) =>
                    // Build string one character at a time
                    result = result ++ self.input.slice((self.pos - 1) as i64, self.pos as i64)
        Ok(result)

    fn read_number(self: &mut Self) -> Result[f64, JsonError]:
        let start = self.pos
        // optional minus
        if self.peek() == Some(45):                       // '-'
            self.pos = self.pos + 1
        // integer part
        self.read_digits()
        // optional fractional part
        if self.peek() == Some(46):                       // '.'
            self.pos = self.pos + 1
            self.read_digits()
        // optional exponent
        let p = self.peek()
        if p == Some(101) or p == Some(69):               // 'e' | 'E'
            self.pos = self.pos + 1
            let sign = self.peek()
            if sign == Some(43) or sign == Some(45):      // '+' | '-'
                self.pos = self.pos + 1
            self.read_digits()

        let text = self.input.slice(start as i64, self.pos as i64)
        // Simple manual number parsing
        parse_number_str(text, start)

    fn read_digits(self: &mut Self):
        loop:
            match self.peek():
                Some(ch) if is_digit(ch) => self.pos = self.pos + 1
                _ => break

    fn expect_literal(self: &mut Self, expected: &str) -> Result[void, JsonError]:
        for i in 0..expected.len():
            match self.advance():
                Some(got) if got == expected.byte_at(i as i64) => ()
                Some(got) => return Err(JsonError.UnexpectedChar(self.pos - 1, expected, got))
                None => return Err(JsonError.UnexpectedEof(self.pos, "literal"))

// Simple number parsing helper
fn parse_number_str(text: str, start: usize) -> Result[f64, JsonError]:
    var result: f64 = 0.0
    var sign: f64 = 1.0
    var i: usize = 0

    // handle sign
    if i < text.len() and text.byte_at(i as i64) == 45:   // '-'
        sign = 0.0 - 1.0
        i = i + 1

    // integer part
    while i < text.len() and text.byte_at(i as i64) >= 48 and text.byte_at(i as i64) <= 57:
        result = result * 10.0 + (text.byte_at(i as i64) - 48) as f64
        i = i + 1

    // fractional part
    if i < text.len() and text.byte_at(i as i64) == 46:   // '.'
        i = i + 1
        var frac: f64 = 0.1
        while i < text.len() and text.byte_at(i as i64) >= 48 and text.byte_at(i as i64) <= 57:
            result = result + (text.byte_at(i as i64) - 48) as f64 * frac
            frac = frac * 0.1
            i = i + 1

    // skip exponent for now (simplified)
    Ok(sign * result)

// --- Recursive Descent Parser ---

type Parser {
    tokenizer: Tokenizer,
    current: Option[Token],
}

extend Parser:
    fn new(input: str) -> Result[Parser, JsonError]:
        var tokenizer = Tokenizer.new(input)
        let first = tokenizer.next_token()?
        Ok(Parser { tokenizer: tokenizer, current: first })

    fn bump(self: &mut Self) -> Result[void, JsonError]:
        self.current = self.tokenizer.next_token()?
        Ok(())

    fn parse_value(self: &mut Self) -> Result[JsonValue, JsonError]:
        let is_lbrace = match self.current:
            Some(Token.LBrace) => true
            _ => false
        if is_lbrace:
            return self.parse_object()

        let is_lbracket = match self.current:
            Some(Token.LBracket) => true
            _ => false
        if is_lbracket:
            return self.parse_array()

        let is_null = match self.current:
            Some(Token.TNull) => true
            _ => false
        if is_null:
            self.bump()?
            return Ok(JsonValue.Null)

        let is_bool = match self.current:
            Some(Token.TBool(_)) => true
            _ => false
        if is_bool:
            // Extract the bool value before bumping
            let b = match self.current:
                Some(Token.TBool(v)) => v
                _ => false
            self.bump()?
            return Ok(JsonValue.Bool(b))

        let is_number = match self.current:
            Some(Token.TNumber(_)) => true
            _ => false
        if is_number:
            let n = match self.current:
                Some(Token.TNumber(v)) => v
                _ => 0.0
            self.bump()?
            return Ok(JsonValue.Number(n))

        let is_string = match self.current:
            Some(Token.TString(_)) => true
            _ => false
        if is_string:
            let s = match self.current:
                Some(Token.TString(v)) => v
                _ => ""
            self.bump()?
            return Ok(JsonValue.Str(s))

        let is_none = match self.current:
            None => true
            _ => false
        if is_none:
            return Err(JsonError.UnexpectedEof(self.tokenizer.pos, "JSON value"))

        Err(JsonError.UnexpectedChar(self.tokenizer.pos, "JSON value", 0))

    fn parse_array(self: &mut Self) -> Result[JsonValue, JsonError]:
        self.bump()?  // consume '['
        var items: Vec[JsonValue] = Vec.new()
        // empty array
        let is_rbracket = match self.current:
            Some(Token.RBracket) => true
            _ => false
        if is_rbracket:
            self.bump()?
            return Ok(JsonValue.Array(items))
        // first element
        let first = self.parse_value()?
        items.push(first)
        // remaining elements
        loop:
            let is_comma = match self.current:
                Some(Token.Comma) => true
                _ => false
            let is_end = match self.current:
                Some(Token.RBracket) => true
                _ => false
            if is_comma:
                self.bump()?
                let elem = self.parse_value()?
                items.push(elem)
            else if is_end:
                self.bump()?
                break
            else:
                return Err(JsonError.UnexpectedEof(self.tokenizer.pos, "array element or ']'"))
        Ok(JsonValue.Array(items))

    fn parse_object(self: &mut Self) -> Result[JsonValue, JsonError]:
        self.bump()?  // consume '{'
        var entries: Vec[JsonKV] = Vec.new()
        // empty object
        let is_rbrace = match self.current:
            Some(Token.RBrace) => true
            _ => false
        if is_rbrace:
            self.bump()?
            return Ok(JsonValue.Object(entries))
        // first key-value pair
        let first_kv = self.parse_kv()?
        entries.push(first_kv)
        // remaining pairs
        loop:
            let is_comma = match self.current:
                Some(Token.Comma) => true
                _ => false
            let is_end = match self.current:
                Some(Token.RBrace) => true
                _ => false
            if is_comma:
                self.bump()?
                let kv = self.parse_kv()?
                entries.push(kv)
            else if is_end:
                self.bump()?
                break
            else:
                return Err(JsonError.UnexpectedEof(self.tokenizer.pos, "object entry or '}'"))
        Ok(JsonValue.Object(entries))

    fn parse_kv(self: &mut Self) -> Result[JsonKV, JsonError]:
        // expect string key
        let is_string = match self.current:
            Some(Token.TString(_)) => true
            _ => false
        if not is_string:
            return Err(JsonError.UnexpectedChar(self.tokenizer.pos, "string key", 0))
        let key = match self.current:
            Some(Token.TString(s)) => s
            _ => ""
        self.bump()?
        // expect colon
        let is_colon = match self.current:
            Some(Token.Colon) => true
            _ => false
        if not is_colon:
            return Err(JsonError.UnexpectedChar(self.tokenizer.pos, "':'", 0))
        self.bump()?
        let value = self.parse_value()?
        Ok(JsonKV { key: key, value: value })

fn parse(input: str) -> Result[JsonValue, JsonError]:
    var parser = Parser.new(input)?
    let value = parser.parse_value()?
    if parser.current.is_some():
        return Err(JsonError.TrailingContent(parser.tokenizer.pos))
    Ok(value)

// --- Display ---

fn json_to_string(val: JsonValue) -> str:
    match val:
        .Null       => "null"
        .Bool(b)    => f"{b}"
        .Number(n)  => f"{n}"
        .Str(s)     => "\"" ++ s ++ "\""
        .Array(items) =>
            var parts: Vec[str] = Vec.new()
            for i in 0..items.len():
                let item = items.get(i)
                parts.push(json_to_string(item))
            let inner = parts.join(", ")
            "[" ++ inner ++ "]"
        .Object(entries) =>
            var parts: Vec[str] = Vec.new()
            for i in 0..entries.len():
                let entry = entries.get(i)
                let k = entry.key
                let v = json_to_string(entry.value)
                parts.push("\"" ++ k ++ "\": " ++ v)
            let inner = parts.join(", ")
            "{" ++ inner ++ "}"

fn json_get_field(val: JsonValue, key: str) -> Option[JsonValue]:
    match val:
        .Object(entries) =>
            for i in 0..entries.len():
                let entry = entries.get(i)
                if entry.key == key:
                    return Some(entry.value)
            None
        _ => None

fn json_get_index(val: JsonValue, idx: usize) -> Option[JsonValue]:
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
            let pretty = json_to_string(value)
            print(f"Pretty: {pretty}\n")

            // Access nested values
            let name = match json_get_field(value, "name"):
                Some(.Str(s)) => s
                _ => "unknown"
            print(f"Name: {name}")

            let version = match json_get_field(value, "version"):
                Some(.Number(n)) => n
                _ => 0.0
            print(f"Version: {version}")

            // Access array elements
            let features = json_get_field(value, "features")
            let first_feature = match features:
                Some(.Array(arr)) =>
                    if arr.len() > 0:
                        match arr.get(0):
                            .Str(s) => s
                            _ => "none"
                    else:
                        "none"
                _ => "none"
            print(f"First feature: {first_feature}")

            // Count features
            let features2 = json_get_field(value, "features")
            let feature_count = match features2:
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
