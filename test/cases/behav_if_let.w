//! expect-stdout: ok

// Behavior test: if let (spec SS9.7)
// Missing feature: parser should support `if let Some(x) = expr:`
// and chained `if let Some(x) = a, let Ok(y) = b:`
// Currently not parsed.

use Token
use Lexer
use Ast

fn lex(source: str) -> TokenList:
    var l = Lexer.new(source, 0)
    Lexer.tokenize(l)

fn test_if_let_token_sequence:
    // "if let" should lex as TK_KW_IF followed by TK_KW_LET
    var tokens = lex("if let")
    assert(TokenList.tag_at(tokens, 0) == TK_KW_IF())
    assert(TokenList.tag_at(tokens, 1) == TK_KW_LET())

fn test_if_let_pattern_tokens:
    // Token sequence for: if let Some(x) = expr:
    var tokens = lex("if let .Some(x) = val:")
    assert(TokenList.tag_at(tokens, 0) == TK_KW_IF())
    assert(TokenList.tag_at(tokens, 1) == TK_KW_LET())
    assert(TokenList.tag_at(tokens, 2) == TK_DOT_IDENT())  // .Some
    assert(TokenList.tag_at(tokens, 3) == TK_L_PAREN())
    assert(TokenList.tag_at(tokens, 4) == TK_IDENT())  // x
    assert(TokenList.tag_at(tokens, 5) == TK_R_PAREN())
    assert(TokenList.tag_at(tokens, 6) == TK_EQ())
    assert(TokenList.tag_at(tokens, 7) == TK_IDENT())  // val
    assert(TokenList.tag_at(tokens, 8) == TK_COLON())

fn test_chained_if_let_tokens:
    // Token sequence for: if let Some(a) = x, let Ok(b) = y:
    var tokens = lex("if let .Some(a) = x, let .Ok(b) = y:")
    assert(TokenList.tag_at(tokens, 0) == TK_KW_IF())
    assert(TokenList.tag_at(tokens, 1) == TK_KW_LET())

fn test_pattern_node_constants:
    // Pattern node kinds used by if let
    assert(NK_PAT_IDENT() == 101)
    assert(NK_PAT_VARIANT() == 105)
    assert(NK_PAT_ENUM_SHORTHAND() == 111)

fn main:
    test_if_let_token_sequence()
    test_if_let_pattern_tokens()
    test_chained_if_let_tokens()
    test_pattern_node_constants()
    println("ok")
