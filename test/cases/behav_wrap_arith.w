//! expect-stdout: ok

// Behavior test: wrapping arithmetic operators (spec SS4.2)
// Missing feature: +%, -%, *% for wrapping (non-trapping) arithmetic.
// Tokens TK_PLUS_WRAP, TK_MINUS_WRAP, TK_STAR_WRAP are lexed.
// Parser does not handle them as binary operators yet.

use Token
use Lexer
use Ast

fn lex(source: str) -> TokenList:
    var l = Lexer.new(source, 0)
    Lexer.tokenize(l)

fn test_plus_wrap_token:
    var tokens = lex("+%")
    assert(TokenList.tag_at(tokens, 0) == TK_PLUS_WRAP)
    assert(TK_PLUS_WRAP == 59)

fn test_minus_wrap_token:
    var tokens = lex("-%")
    assert(TokenList.tag_at(tokens, 0) == TK_MINUS_WRAP)
    assert(TK_MINUS_WRAP == 60)

fn test_star_wrap_token:
    var tokens = lex("*%")
    assert(TokenList.tag_at(tokens, 0) == TK_STAR_WRAP)
    assert(TK_STAR_WRAP == 61)

fn test_wrap_in_expression_tokens:
    // a +% b
    var tokens = lex("a +% b")
    assert(TokenList.tag_at(tokens, 0) == TK_IDENT)  // a
    assert(TokenList.tag_at(tokens, 1) == TK_PLUS_WRAP)
    assert(TokenList.tag_at(tokens, 2) == TK_IDENT)  // b

fn test_wrap_sub_expression_tokens:
    // x -% y
    var tokens = lex("x -% y")
    assert(TokenList.tag_at(tokens, 0) == TK_IDENT)
    assert(TokenList.tag_at(tokens, 1) == TK_MINUS_WRAP)
    assert(TokenList.tag_at(tokens, 2) == TK_IDENT)

fn test_wrap_mul_expression_tokens:
    // x *% y
    var tokens = lex("x *% y")
    assert(TokenList.tag_at(tokens, 0) == TK_IDENT)
    assert(TokenList.tag_at(tokens, 1) == TK_STAR_WRAP)
    assert(TokenList.tag_at(tokens, 2) == TK_IDENT)

fn test_regular_arith_unchanged:
    // + - * should still produce normal tokens
    var tokens = lex("+ - *")
    assert(TokenList.tag_at(tokens, 0) == TK_PLUS)
    assert(TokenList.tag_at(tokens, 1) == TK_MINUS)
    assert(TokenList.tag_at(tokens, 2) == TK_STAR)

fn main:
    test_plus_wrap_token()
    test_minus_wrap_token()
    test_star_wrap_token()
    test_wrap_in_expression_tokens()
    test_wrap_sub_expression_tokens()
    test_wrap_mul_expression_tokens()
    test_regular_arith_unchanged()
    println("ok")
