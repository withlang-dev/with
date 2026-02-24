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
//   - Borrowed tree access via helper methods
//   - with blocks (scoped mutation)
// ===================================================================

// --- JSON Value Type ---

type JsonValue =
    | Null
    | Bool(bool)
    | Number(f64)
    | Str(str)
    | Array(Vec[JsonValue])
    | Object(Vec[(str, JsonValue)])

// --- Errors ---

error JsonError =
    UnexpectedChar(pos: usize, expected: str, got: u8)
    UnexpectedEof(pos: usize, context: str)
    InvalidNumber(pos: usize, text: str)
    InvalidEscape(pos: usize, ch: u8)
    TrailingContent(pos: usize)

// --- Token Types ---

type Token =
    | LBrace
    | RBrace
    | LBracket
    | RBracket
    | Colon
    | Comma
    | TNull
    | TBool(bool)
    | TNumber(f64)
    | TString(str)

// --- Tokenizer ---

type Tokenizer = {
    input: Vec[u8],
    pos: usize = 0,
}

fn Tokenizer.new(input: str) -> Tokenizer =
    Tokenizer { input: input.into_bytes() }

fn Tokenizer.peek(self: &Self) -> Option[u8] =
    if self.pos < self.input.len():
        Some(self.input[self.pos])
    else:
        None

fn Tokenizer.advance(self: &mut Self) -> Option[u8] =
    if self.pos < self.input.len():
        let ch = self.input[self.pos]
        self.pos = self.pos + 1
        Some(ch)
    else:
        None

fn Tokenizer.skip_whitespace(self: &mut Self) =
    loop:
        match self.peek()
            Some(b' ') | Some(b'\t') | Some(b'\n') | Some(b'\r') ->
                self.pos = self.pos + 1
            _ -> break

fn Tokenizer.next_token(self: &mut Self) -> Result[Option[Token], JsonError] =
    self.skip_whitespace()
    match self.advance()
        None        -> Ok(None)
        Some(b'{')  -> Ok(Some(.LBrace))
        Some(b'}')  -> Ok(Some(.RBrace))
        Some(b'[')  -> Ok(Some(.LBracket))
        Some(b']')  -> Ok(Some(.RBracket))
        Some(b':')  -> Ok(Some(.Colon))
        Some(b',')  -> Ok(Some(.Comma))
        Some(b'"')  -> self.read_string() |> Result.map(.TString) |> Result.map(Some)
        Some(b't')  -> self.expect_literal("rue")  |> Result.map(|_| Some(.TBool(true)))
        Some(b'f')  -> self.expect_literal("alse") |> Result.map(|_| Some(.TBool(false)))
        Some(b'n')  -> self.expect_literal("ull")  |> Result.map(|_| Some(.TNull))
        Some(ch) if ch == b'-' or (ch >= b'0' and ch <= b'9') ->
            self.pos = self.pos - 1
            self.read_number() |> Result.map(.TNumber) |> Result.map(Some)
        Some(ch) ->
            Err(.UnexpectedChar(
                pos: self.pos - 1,
                expected: "valid JSON token",
                got: ch,
            ))

fn Tokenizer.read_string(self: &mut Self) -> Result[str, JsonError] =
    with str.new() as mut buf:
        loop:
            match self.advance()
                None ->
                    return Err(.UnexpectedEof(
                        pos: self.pos,
                        context: "unterminated string",
                    ))
                Some(b'"') -> break
                Some(b'\\') ->
                    match self.advance()
                        Some(b'"')  -> buf.push(b'"')
                        Some(b'\\') -> buf.push(b'\\')
                        Some(b'/')  -> buf.push(b'/')
                        Some(b'n')  -> buf.push(b'\n')
                        Some(b't')  -> buf.push(b'\t')
                        Some(b'r')  -> buf.push(b'\r')
                        Some(ch)    -> return Err(.InvalidEscape(pos: self.pos - 1, ch))
                        None        -> return Err(.UnexpectedEof(
                            pos: self.pos,
                            context: "escape sequence",
                        ))
                Some(ch) -> buf.push(ch)
        Ok(buf)

fn Tokenizer.read_number(self: &mut Self) -> Result[f64, JsonError] =
    let start = self.pos
    // optional minus
    if self.peek() == Some(b'-'):
        self.pos = self.pos + 1
    // integer part
    self.read_digits()
    // optional fractional part
    if self.peek() == Some(b'.'):
        self.pos = self.pos + 1
        self.read_digits()
    // optional exponent
    match self.peek()
        Some(b'e') | Some(b'E') ->
            self.pos = self.pos + 1
            match self.peek()
                Some(b'+') | Some(b'-') -> self.pos = self.pos + 1
                _ -> ()
            self.read_digits()
        _ -> ()

    let text = str.from_utf8_lossy(&self.input[start..self.pos])
    text.parse_f64()
        .map_err(|_| .InvalidNumber(pos: start, text: text.to_string()))

fn Tokenizer.read_digits(self: &mut Self) =
    loop:
        match self.peek()
            Some(ch) if ch >= b'0' and ch <= b'9' -> self.pos = self.pos + 1
            _ -> break

fn Tokenizer.expect_literal(self: &mut Self, expected: &str) -> Result[Unit, JsonError] =
    for ch in expected.bytes():
        match self.advance()
            Some(got) if got == ch -> ()
            Some(got) -> return Err(.UnexpectedChar(
                pos: self.pos - 1,
                expected: expected.to_string(),
                got,
            ))
            None -> return Err(.UnexpectedEof(
                pos: self.pos,
                context: "literal '{expected}'",
            ))
    Ok()

// --- Recursive Descent Parser ---

type Parser = {
    tokenizer: Tokenizer,
    current: Option[Token],
}

fn Parser.new(input: str) -> Result[Parser, JsonError] =
    var tokenizer = Tokenizer.new(input)
    let first = tokenizer.next_token()?
    Ok(Parser { tokenizer, current: first })

fn Parser.bump(self: &mut Self) -> Result[Unit, JsonError] =
    self.current = self.tokenizer.next_token()?
    Ok()

fn Parser.expect_token(self: &mut Self, description: str) -> Result[Token, JsonError] =
    match self.current.take()
        Some(tok) ->
            self.bump()?
            Ok(tok)
        None ->
            Err(.UnexpectedEof(
                pos: self.tokenizer.pos,
                context: description,
            ))

fn parse(input: str) -> Result[JsonValue, JsonError] =
    var parser = Parser.new(input)?
    let value = parser.parse_value()?
    if parser.current.is_some():
        return Err(.TrailingContent(pos: parser.tokenizer.pos))
    Ok(value)

fn Parser.parse_value(self: &mut Self) -> Result[JsonValue, JsonError] =
    match &self.current
        Some(.LBrace)   -> self.parse_object()
        Some(.LBracket) -> self.parse_array()
        Some(.TNull)    ->
            self.bump()?
            Ok(.Null)
        Some(.TBool(_)) ->
            let .TBool(b) = self.expect_token("bool")?
            Ok(.Bool(b))
        Some(.TNumber(_)) ->
            let .TNumber(n) = self.expect_token("number")?
            Ok(.Number(n))
        Some(.TString(_)) ->
            let .TString(s) = self.expect_token("string")?
            Ok(.Str(s))
        Some(_) ->
            Err(.UnexpectedChar(
                pos: self.tokenizer.pos,
                expected: "JSON value",
                got: 0,
            ))
        None ->
            Err(.UnexpectedEof(
                pos: self.tokenizer.pos,
                context: "JSON value",
            ))

fn Parser.parse_array(self: &mut Self) -> Result[JsonValue, JsonError] =
    self.bump()?  // consume '['
    with Vec.new() as mut items:
        // empty array
        if let Some(.RBracket) = &self.current:
            self.bump()?
            return Ok(.Array(items))
        // first element
        items.push(self.parse_value()?)
        // remaining elements
        loop:
            match &self.current
                Some(.Comma) ->
                    self.bump()?
                    items.push(self.parse_value()?)
                Some(.RBracket) ->
                    self.bump()?
                    break
                _ -> return Err(.UnexpectedEof(
                    pos: self.tokenizer.pos,
                    context: "array element or ']'",
                ))
        Ok(.Array(items))

fn Parser.parse_object(self: &mut Self) -> Result[JsonValue, JsonError] =
    self.bump()?  // consume '{'
    with Vec.new() as mut entries:
        // empty object
        if let Some(.RBrace) = &self.current:
            self.bump()?
            return Ok(.Object(entries))
        // first key-value pair
        entries.push(self.parse_kv()?)
        // remaining pairs
        loop:
            match &self.current
                Some(.Comma) ->
                    self.bump()?
                    entries.push(self.parse_kv()?)
                Some(.RBrace) ->
                    self.bump()?
                    break
                _ -> return Err(.UnexpectedEof(
                    pos: self.tokenizer.pos,
                    context: "object entry or '}'",
                ))
        Ok(.Object(entries))

fn Parser.parse_kv(self: &mut Self) -> Result[(str, JsonValue), JsonError] =
    let key = match self.expect_token("object key")?
        .TString(s) -> s
        _ -> return Err(.UnexpectedChar(
            pos: self.tokenizer.pos,
            expected: "string key",
            got: 0,
        ))
    // expect colon
    match self.expect_token("':'")?
        .Colon -> ()
        _ -> return Err(.UnexpectedChar(
            pos: self.tokenizer.pos,
            expected: "':'",
            got: 0,
        ))
    let value = self.parse_value()?
    Ok((key, value))

// --- Generator: Leaf Path Walker ---
//
// Lazily walks the JSON tree and yields (path, leaf_value) pairs.
// Captures &JsonValue — generator is ephemeral (cannot be stored).

gen fn walk_leaves(value: &JsonValue, path: str) -> (str, &JsonValue) =
    match value
        .Null | .Bool(_) | .Number(_) | .Str(_) ->
            yield (path, value)
        .Array(items) ->
            for (i, item) in items.iter().enumerate():
                let child_path = "{path}[{i}]"
                for leaf in walk_leaves(item, child_path):
                    yield leaf
        .Object(entries) ->
            for (key, val) in entries:
                let child_path = if path.is_empty() then key.clone() else "{path}.{key}"
                for leaf in walk_leaves(val, child_path):
                    yield leaf

// --- Display ---

fn JsonValue.to_string(self: &Self) -> str =
    match self
        .Null       -> "null"
        .Bool(b)    -> "{b}"
        .Number(n)  -> "{n}"
        .Str(s)     -> "\"{s}\""
        .Array(items) ->
            let inner = items.iter()
                |> map(|item| "{item}")
                |> collect[Vec]()
                |> join(", ")
            "[{inner}]"
        .Object(entries) ->
            let inner = entries.iter()
                |> map(|(k, v)| "\"{k}\": {v}")
                |> collect[Vec]()
                |> join(", ")
            "{ {inner} }"

// --- Accessors ---

fn JsonValue.get(self: &Self, key: &str) -> Option[&JsonValue] =
    match self
        .Object(entries) ->
            entries.iter()
                |> find(|(k, _)| k == key)
                |> Option.map(|(_, v)| v)
        _ -> None

fn JsonValue.index(self: &Self, i: usize) -> Option[&JsonValue] =
    match self
        .Array(items) if i < items.len() -> Some(&items[i])
        _ -> None

// Auto-generated enum accessors (.as_variant()) consume self (§4.4).
// For tree navigation we usually have &JsonValue, so add borrowed
// helpers that preserve ownership of the parsed tree.

fn JsonValue.as_str_ref(self: &Self) -> Option[&str] =
    match self
        .Str(s) -> Some(s.as_view())
        _ -> None

fn JsonValue.as_number_ref(self: &Self) -> Option[f64] =
    match self
        .Number(n) -> Some(*n)
        _ -> None

fn JsonValue.as_array_ref(self: &Self) -> Option[&Vec[JsonValue]] =
    match self
        .Array(items) -> Some(items)
        _ -> None

// --- Main Demo ---

fn main() =
    let input = r#"{
        "name": "With Language",
        "version": 3.2,
        "features": ["handles", "fibers", "comptime"],
        "meta": {
            "stable": false,
            "authors": ["core-team"],
            "stats": { "stars": 0, "forks": null }
        }
    }"#

    println("=== JSON Parser Demo ===\n")
    println("Input ({input.len()} bytes):\n{input}\n")

    match parse(input)
        Ok(value) ->
            println("Parsed successfully!\n")
            println("Pretty: {value}\n")

            // Access nested values via optional chaining + ??
            let name = value.get("name")?.as_str_ref() ?? "unknown"
            println("Name: {name}")

            let version = value.get("version")?.as_number_ref() ?? 0.0
            println("Version: {version}")

            // Access array elements
            let first_feature = value.get("features")?.index(0)?.as_str_ref() ?? "none"
            println("First feature: {first_feature}")

            // Walk all leaves using generator
            println("\nAll leaf paths:")
            for (path, leaf) in walk_leaves(&value, ""):
                println("  {path} = {leaf}")

            // Count features using optional chaining
            let feature_count = value.get("features")?.as_array_ref()?.len() ?? 0
            println("\nFeature count: {feature_count}")

        Err(e) ->
            println("Parse error: {e}")

    // Demonstrate error handling
    println("\n--- Error cases ---")
    let bad_inputs = [
        (r#"{"key": }"#, "missing value"),
        (r#"[1, 2,"#,    "unterminated array"),
        (r#""hello"#,    "unterminated string"),
    ]
    for (input, description) in bad_inputs:
        match parse(input.to_string())
            Ok(_)  -> println("  {description}: unexpectedly succeeded")
            Err(e) -> println("  {description}: {e}")

    println("\n=== Demo complete ===")
