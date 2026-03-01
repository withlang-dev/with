//! expect-stdout: ok

// Behavior test: @[attribute] annotations (spec SS11.8)
// Missing feature: @[derive(Eq)], @[tailrec], @[repr(C)], etc.
// @ is lexed as TK_AT. Parser does not handle @[...] annotations.
// Also covers @[must_use] and @[no_await_guard].

use Token
use Lexer
use Ast

fn lex(source: str) -> TokenList:
    var l = Lexer.new(source, 0)
    Lexer.tokenize(l)

fn test_at_token:
    var tokens = lex("@")
    assert(TokenList.tag_at(tokens, 0) == TK_AT())
    assert(TK_AT() == 73)

fn test_attr_derive_tokens:
    // @[derive(Eq, Hash)]
    var tokens = lex("@[derive(Eq, Hash)]")
    assert(TokenList.tag_at(tokens, 0) == TK_AT())
    assert(TokenList.tag_at(tokens, 1) == TK_L_BRACKET())
    assert(TokenList.tag_at(tokens, 2) == TK_IDENT())  // derive
    assert(TokenList.tag_at(tokens, 3) == TK_L_PAREN())
    assert(TokenList.tag_at(tokens, 4) == TK_IDENT())  // Eq
    assert(TokenList.tag_at(tokens, 5) == TK_COMMA())
    assert(TokenList.tag_at(tokens, 6) == TK_IDENT())  // Hash

fn test_attr_tailrec_tokens:
    // @[tailrec]
    var tokens = lex("@[tailrec]")
    assert(TokenList.tag_at(tokens, 0) == TK_AT())
    assert(TokenList.tag_at(tokens, 1) == TK_L_BRACKET())
    assert(TokenList.tag_at(tokens, 2) == TK_IDENT())  // tailrec
    assert(TokenList.tag_at(tokens, 3) == TK_R_BRACKET())

fn test_attr_repr_tokens:
    // @[repr(C)]
    var tokens = lex("@[repr(C)]")
    assert(TokenList.tag_at(tokens, 0) == TK_AT())
    assert(TokenList.tag_at(tokens, 1) == TK_L_BRACKET())
    assert(TokenList.tag_at(tokens, 2) == TK_IDENT())  // repr
    assert(TokenList.tag_at(tokens, 3) == TK_L_PAREN())
    assert(TokenList.tag_at(tokens, 4) == TK_IDENT())  // C
    assert(TokenList.tag_at(tokens, 5) == TK_R_PAREN())
    assert(TokenList.tag_at(tokens, 6) == TK_R_BRACKET())

fn test_attr_must_use_tokens:
    // @[must_use]
    var tokens = lex("@[must_use]")
    assert(TokenList.tag_at(tokens, 0) == TK_AT())
    assert(TokenList.tag_at(tokens, 1) == TK_L_BRACKET())

fn test_tailrec_flag_constant:
    assert(FN_FLAG_TAILREC() == 16)

fn test_must_use_flag_constant:
    assert(FN_FLAG_MUST_USE() == 32)

fn main:
    test_at_token()
    test_attr_derive_tokens()
    test_attr_tailrec_tokens()
    test_attr_repr_tokens()
    test_attr_must_use_tokens()
    test_tailrec_flag_constant()
    test_must_use_flag_constant()
    println("ok")
