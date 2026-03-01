//! expect-stdout: ok

// Behavior test: error declarations (spec SS10.8, SS10.9)
// Missing features:
// - error declarations: error ParseError = Variant(...)
// - error ... from conversion: error MyErr from OtherErr
// Parser skips error declarations. TK_KW_ERROR is lexed.

use Token
use Lexer
use Ast

fn lex(source: str) -> TokenList:
    var l = Lexer.new(source, 0)
    Lexer.tokenize(l)

fn test_error_keyword:
    var tokens = lex("error")
    assert(TokenList.tag_at(tokens, 0) == TK_KW_ERROR())
    assert(TK_KW_ERROR() == 46)

fn test_error_decl_token_sequence:
    // error ParseError = InvalidToken | UnexpectedEof
    var tokens = lex("error ParseError = InvalidToken")
    assert(TokenList.tag_at(tokens, 0) == TK_KW_ERROR())
    assert(TokenList.tag_at(tokens, 1) == TK_IDENT())  // ParseError
    assert(TokenList.tag_at(tokens, 2) == TK_EQ())

fn test_error_with_payload_tokens:
    // error NetworkError = Timeout(i32) | Refused(str)
    var tokens = lex("error NetworkError = Timeout(i32)")
    assert(TokenList.tag_at(tokens, 0) == TK_KW_ERROR())
    assert(TokenList.tag_at(tokens, 1) == TK_IDENT())  // NetworkError
    assert(TokenList.tag_at(tokens, 2) == TK_EQ())
    assert(TokenList.tag_at(tokens, 3) == TK_IDENT())  // Timeout
    assert(TokenList.tag_at(tokens, 4) == TK_L_PAREN())
    assert(TokenList.tag_at(tokens, 5) == TK_IDENT())  // i32
    assert(TokenList.tag_at(tokens, 6) == TK_R_PAREN())

fn test_try_operator_constant:
    // ? (try) is used with error types
    assert(TK_QUESTION() == 74)
    assert(UOP_TRY() == 5)

fn main:
    test_error_keyword()
    test_error_decl_token_sequence()
    test_error_with_payload_tokens()
    test_try_operator_constant()
    println("ok")
