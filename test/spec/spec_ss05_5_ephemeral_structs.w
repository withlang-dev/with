// Spec test: Section 5.5 — Ephemeral Structs.

enum TokenKind:
    Ident
    Number
    String

type Token = ephemeral {
    text: StrView,
    kind: TokenKind,
    line: usize,
}

fn first_token(src: StrView) -> Option[Token]:
    if src.len() == 0:
        return None
    Some(Token { text: src, kind: .Ident, line: 1 })

fn describe(tok: Token) -> str:
    match tok.kind:
        .Ident => "identifier"
        .Number => "number"
        .String => "string"

fn test_ephemeral_struct_with_view_fields:
    let tok = first_token("hello").unwrap()
    assert(tok.kind == .Ident)
    assert(tok.text.len() == 5)
    assert(tok.line == 1)

fn test_ephemeral_struct_in_pattern_matching:
    let tok = Token { text: "123", kind: .Number, line: 2 }
    assert(describe(tok) == "number")
