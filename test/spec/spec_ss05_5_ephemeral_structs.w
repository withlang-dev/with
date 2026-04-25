//! skip
// Spec test: Section 5.5 — Ephemeral Structs (formerly 25.41)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

enum TokenKind { Ident | Number | String | LParen | RParen }

// PASS: ephemeral struct with view fields
type Token = ephemeral {
    text: StrView,
    kind: TokenKind,
    line: usize,
}

fn first_token(src: StrView) -> Option[Token]:
    if src.len() == 0 then return None
    Some(Token { text: src.slice(0, 1), kind: .Ident, line: 1 })

fn test:
    let src = "hello world"
    let tok = first_token(src.as_view())?
    assert(tok.kind == .Ident)

// PASS: ephemeral struct in pattern matching
fn describe(tok: Token) -> str:
    match tok.kind:
        .Ident  => "identifier: {tok.text}"
        .Number => "number: {tok.text}"
        _       => "other"

// PASS: Vec of ephemeral struct (Vec itself becomes ephemeral)
fn tokenize(src: StrView) -> Vec[Token]:
    // Vec[Token] is ephemeral — cannot escape scope of src
    Vec.new()

// FAIL: non-ephemeral struct with ephemeral field
type BadToken {
    text: StrView,     // ERROR: ephemeral field in non-ephemeral struct
    kind: TokenKind,
}

// FAIL: store ephemeral struct in long-lived container
type Module {
    tokens: Vec[Token]  // ERROR: ephemeral field in non-ephemeral struct
}
