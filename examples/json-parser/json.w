module json

// ===================================================================
// JSON Parser — Recursive Descent
//
// Demonstrates:
//   - Algebraic data types (enum variants with data)
//   - Pattern matching (nested, guards, or-patterns)
//   - Error declarations with positional context
//   - Generators for lazy tree traversal
//   - Pipeline operators for composition
//   - StrView (ephemeral string slices)
//   - Collection comprehensions
//   - with blocks (scoped mutation)
// ===================================================================

// --- JSON Value Type ---

enum JsonValue {
    Null
    | Bool(bool)
    | Number(f64)
    | Str(str)
    | Array(Vec[JsonValue])
    | Object(Vec[(str, JsonValue)])
}

// --- Errors ---

error JsonError =
    UnexpectedChar(pos: usize, expected: str, got: u8)
    | UnexpectedEof(pos: usize, context: str)
    | InvalidNumber(pos: usize, text: str)
    | InvalidEscape(pos: usize, ch: u8)
    | TrailingContent(pos: usize)

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
    input: Vec[u8],
    pos: usize = 0,
}

fn is_whitespace(ch: u8) -> bool:
    ch in [32, 9, 10, 13]

fn is_digit(ch: u8) -> bool:
    ch in 48..=57

extend Tokenizer:
    fn new(input: str):
        Tokenizer { input: input.into_bytes() }

    fn peek(self: &Self) -> Option[u8]:
        if self.pos < self.input.len():
            Some(self.input[self.pos])
        else:
            None

    fn advance(self: &mut Self) -> Option[u8]:
        if self.pos < self.input.len():
            let ch = self.input[self.pos]
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

    fn read_number_token(self: &mut Self) -> Result[Option[Token], JsonError]:
        self.pos = self.pos - 1
        self.read_number() |> Result.map(.TNumber) |> Result.map(Some)

    fn next_token(self: &mut Self) -> Result[Option[Token], JsonError]:
        self.skip_whitespace()
        match self.advance():
            None         => Ok(None)
            Some(123)    => Ok(Some(.LBrace))      // '{'
            Some(125)    => Ok(Some(.RBrace))      // '}'
            Some(91)     => Ok(Some(.LBracket))    // '['
            Some(93)     => Ok(Some(.RBracket))    // ']'
            Some(58)     => Ok(Some(.Colon))       // ':'
            Some(44)     => Ok(Some(.Comma))       // ','
            Some(34)     => self.read_string() |> Result.map(.TString) |> Result.map(Some)
            Some(116)    => self.expect_literal("rue") |> Result.map(_ => Some(.TBool(true)))
            Some(102)    => self.expect_literal("alse") |> Result.map(_ => Some(.TBool(false)))
            Some(110)    => self.expect_literal("ull") |> Result.map(_ => Some(.TNull))
            Some(ch) if ch == 45 or is_digit(ch) => self.read_number_token()
            Some(ch) => Err(.UnexpectedChar(self.pos - 1, "valid JSON token", ch))

    fn read_string(self: &mut Self) -> Result[str, JsonError]:
        with str.new() as mut buf:
            loop:
                match self.advance():
                    None => return Err(.UnexpectedEof(self.pos, "unterminated string"))
                    Some(34) => break                     // '"'
                    Some(92) =>                           // '\\'
                        match self.advance():
                            Some(34)  => buf.push(34)     // '"'
                            Some(92)  => buf.push(92)     // '\\'
                            Some(47)  => buf.push(47)     // '/'
                            Some(110) => buf.push(10)     // 'n' => newline
                            Some(116) => buf.push(9)      // 't' => tab
                            Some(114) => buf.push(13)     // 'r' => carriage return
                            Some(ch)  => return Err(.InvalidEscape(self.pos - 1, ch))
                            None => return Err(.UnexpectedEof(self.pos, "escape sequence"))
                    Some(ch) => buf.push(ch)
            buf

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

        let text = str.from_utf8_lossy(&self.input[start..self.pos])
        text.parse_f64().map_err(_ => .InvalidNumber(start, text.to_string()))

    fn read_digits(self: &mut Self):
        loop:
            match self.peek():
                Some(ch) if is_digit(ch) => self.pos = self.pos + 1
                _ => break

    fn expect_literal(self: &mut Self, expected: &str) -> Result[Unit, JsonError]:
        for ch in expected.bytes():
            match self.advance():
                Some(got) if got == ch => ()
                Some(got) => return Err(.UnexpectedChar(self.pos - 1, expected.to_string(), got))
                None => return Err(.UnexpectedEof(self.pos, "literal"))

// --- Recursive Descent Parser ---

type Parser {
    tokenizer: Tokenizer,
    current: Option[Token],
}

extend Parser:
    fn new(input: str) -> Result[Parser, JsonError]:
        var tokenizer = Tokenizer.new(input)
        let first = tokenizer.next_token()?
        Parser { tokenizer, current: first }

    fn bump(self: &mut Self) -> Result[Unit, JsonError]:
        self.current = self.tokenizer.next_token()?

    fn expect_token(self: &mut Self, description: str) -> Result[Token, JsonError]:
        match self.current.take():
            Some(tok) =>
                self.bump()?
                tok
            None =>
                Err(.UnexpectedEof(
                    pos: self.tokenizer.pos,
                    context: description,
                ))

    fn parse_value(self: &mut Self) -> Result[JsonValue, JsonError]:
        match &self.current:
            Some(.LBrace)   => self.parse_object()
            Some(.LBracket) => self.parse_array()
            Some(.TNull)    =>
                self.bump()?
                .Null
            Some(.TBool(_)) =>
                match self.expect_token("bool")?:
                    .TBool(b) => .Bool(b)
                    _ => .Null
            Some(.TNumber(_)) =>
                match self.expect_token("number")?:
                    .TNumber(n) => .Number(n)
                    _ => .Null
            Some(.TString(_)) =>
                match self.expect_token("string")?:
                    .TString(s) => .Str(s)
                    _ => .Null
            Some(_) =>
                Err(.UnexpectedChar(
                    pos: self.tokenizer.pos,
                    expected: "JSON value",
                    got: 0,
                ))
            None =>
                Err(.UnexpectedEof(
                    pos: self.tokenizer.pos,
                    context: "JSON value",
                ))

    fn parse_array(self: &mut Self) -> Result[JsonValue, JsonError]:
        self.bump()?  // consume '['
        with Vec.new() as mut items:
            // empty array
            if let Some(.RBracket) = &self.current:
                self.bump()?
                return .Array(items)
            // first element
            items.push(self.parse_value()?)
            // remaining elements
            loop:
                match &self.current:
                    Some(.Comma) =>
                        self.bump()?
                        items.push(self.parse_value()?)
                    Some(.RBracket) =>
                        self.bump()?
                        break
                    _ => return Err(.UnexpectedEof(
                        pos: self.tokenizer.pos,
                        context: "array element or ']'",
                    ))
            .Array(items)

    fn parse_object(self: &mut Self) -> Result[JsonValue, JsonError]:
        self.bump()?  // consume '{'
        with Vec.new() as mut entries:
            // empty object
            if let Some(.RBrace) = &self.current:
                self.bump()?
                return .Object(entries)
            // first key-value pair
            entries.push(self.parse_kv()?)
            // remaining pairs
            loop:
                match &self.current:
                    Some(.Comma) =>
                        self.bump()?
                        entries.push(self.parse_kv()?)
                    Some(.RBrace) =>
                        self.bump()?
                        break
                    _ => return Err(.UnexpectedEof(
                        pos: self.tokenizer.pos,
                        context: "object entry or '}'",
                    ))
            .Object(entries)

    fn parse_kv(self: &mut Self) -> Result[(str, JsonValue), JsonError]:
        let key = match self.expect_token("object key")?:
            .TString(s) => s
            _ => return Err(.UnexpectedChar(
                pos: self.tokenizer.pos,
                expected: "string key",
                got: 0,
            ))
        // expect colon
        match self.expect_token("':'")?:
            .Colon => ()
            _ => return Err(.UnexpectedChar(
                pos: self.tokenizer.pos,
                expected: "':'",
                got: 0,
            ))
        let value = self.parse_value()?
        (key, value)

fn parse(input: str) -> Result[JsonValue, JsonError]:
    var parser = Parser.new(input)?
    let value = parser.parse_value()?
    if parser.current.is_some():
        return Err(.TrailingContent(pos: parser.tokenizer.pos))
    value

// --- Generator: Leaf Path Walker ---
//
// Lazily walks the JSON tree and yields (path, leaf_value) pairs.
// Captures &JsonValue — generator is ephemeral (cannot be stored).

gen fn walk_leaves(value: &JsonValue, path: str) -> (str, &JsonValue):
    match value:
        .Null | .Bool(_) | .Number(_) | .Str(_) =>
            yield (path, value)
        .Array(items) =>
            for (i, item) in items.iter().enumerate():
                let child_path = "{path}[{i}]"
                for leaf in walk_leaves(item, child_path):
                    yield leaf
        .Object(entries) =>
            for (key, val) in entries:
                let child_path = if path.is_empty() then key.clone() else "{path}.{key}"
                for leaf in walk_leaves(val, child_path):
                    yield leaf

// --- Display ---

extend JsonValue:
    fn to_string(self: &Self) -> str:
        match self:
            .Null       => "null"
            .Bool(b)    => "{b}"
            .Number(n)  => "{n}"
            .Str(s)     => "\"{s}\""
            .Array(items) =>
                let inner = items.iter()
                    |> map(item => "{item}")
                    |> collect[Vec]()
                    |> join(", ")
                "[{inner}]"
            .Object(entries) =>
                let inner = entries.iter()
                    |> map(entry => "\"{entry.0}\": {entry.1}")
                    |> collect[Vec]()
                    |> join(", ")
                "\\{{inner}\\}"

    // --- Accessors ---

    fn get(self: &Self, key: &str) -> Option[&JsonValue]:
        match self:
            .Object(entries) =>
                entries.iter()
                    |> find(entry => entry.0 == key)
                    |> Option.map(entry => &entry.1)
            _ => None

    fn index(self: &Self, i: usize) -> Option[&JsonValue]:
        match self:
            .Array(items) if i < items.len() => Some(&items[i])
            _ => None

// Accessor methods — .as_str(), .as_number(), .as_bool(), .as_array(),
// .as_object() and .is_null(), .is_str(), etc. — are auto-generated
// for every enum variant (S4.4). No manual definitions needed.

// --- Main Demo ---

fn main:
    let input = "{\"name\": \"With Language\", \"version\": 3.2, \"features\": [\"handles\", \"fibers\", \"comptime\"], \"meta\": {\"stable\": false, \"authors\": [\"core-team\"], \"stats\": {\"stars\": 0, \"forks\": null}}}"

    print("=== JSON Parser Demo ===\n")
    print("Input ({input.len()} bytes):\n{input}\n")

    match parse(input):
        Ok(value) =>
            print("Parsed successfully!\n")
            print("Pretty: {value}\n")

            // Access nested values via optional chaining + ??
            let name = value.get("name")?.as_str() ?? "unknown"
            print("Name: {name}")

            let version = value.get("version")?.as_number() ?? 0.0
            print("Version: {version}")

            // Access array elements
            let first_feature = value.get("features")?.index(0)?.as_str() ?? "none"
            print("First feature: {first_feature}")

            // Walk all leaves using generator
            print("\nAll leaf paths:")
            for (path, leaf) in walk_leaves(&value, ""):
                print("  {path} = {leaf}")

            // Count features using optional chaining
            let feature_count = value.get("features")?.as_array()?.len() ?? 0
            print("\nFeature count: {feature_count}")

        Err(e) =>
            print("Parse error: {e}")

    // Demonstrate error handling
    print("\n--- Error cases ---")
    let bad_inputs = [
        ("{\"key\": }", "missing value"),
        ("[1, 2,",      "unterminated array"),
        ("\"hello",     "unterminated string"),
    ]
    for (input, description) in bad_inputs:
        match parse(input.to_string()):
            Ok(_)  => print("  {description}: unexpectedly succeeded")
            Err(e) => print("  {description}: {e}")

    print("\n=== Demo complete ===")
