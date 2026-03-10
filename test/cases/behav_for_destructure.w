//! expect-stdout: ok

// Behavior test: for-loop destructuring (spec SS9.7)
// Missing feature: for (key, val) in map: should destructure tuples
// Pattern matching in function parameters also not supported.

use Token
use Lexer
use Ast

fn lex(source: str) -> TokenList:
    var l = Lexer.new(source, 0)
    Lexer.tokenize(l)

fn test_for_destructure_tokens:
    // for (k, v) in map:
    var tokens = lex("for (k, v) in map:")
    assert(TokenList.tag_at(tokens, 0) == TK_KW_FOR)
    assert(TokenList.tag_at(tokens, 1) == TK_L_PAREN)
    assert(TokenList.tag_at(tokens, 2) == TK_IDENT)  // k
    assert(TokenList.tag_at(tokens, 3) == TK_COMMA)
    assert(TokenList.tag_at(tokens, 4) == TK_IDENT)  // v
    assert(TokenList.tag_at(tokens, 5) == TK_R_PAREN)
    assert(TokenList.tag_at(tokens, 6) == TK_KW_IN)

fn test_for_triple_destructure_tokens:
    // for (a, b, c) in items:
    // tokens: for ( a , b , c ) in items :
    //         0   1 2 3 4 5 6 7 8   9   10
    var tokens = lex("for (a, b, c) in items:")
    assert(TokenList.tag_at(tokens, 0) == TK_KW_FOR)
    assert(TokenList.tag_at(tokens, 1) == TK_L_PAREN)
    assert(TokenList.tag_at(tokens, 8) == TK_KW_IN)

fn test_for_node_constant:
    assert(NK_FOR == 37)

fn test_tuple_destructure_node:
    assert(NK_TUPLE_DESTRUCTURE == 63)

fn test_tuple_node:
    assert(NK_TUPLE == 41)

fn test_pattern_fn_param_tokens:
    // Pattern matching in fn params: fn f((a, b): (i32, i32)):
    var tokens = lex("fn f((a, b): (i32, i32)):")
    assert(TokenList.tag_at(tokens, 0) == TK_KW_FN)
    assert(TokenList.tag_at(tokens, 1) == TK_IDENT)  // f
    assert(TokenList.tag_at(tokens, 2) == TK_L_PAREN)
    assert(TokenList.tag_at(tokens, 3) == TK_L_PAREN)  // inner (
    assert(TokenList.tag_at(tokens, 4) == TK_IDENT)  // a

fn main:
    test_for_destructure_tokens()
    test_for_triple_destructure_tokens()
    test_for_node_constant()
    test_tuple_destructure_node()
    test_tuple_node()
    test_pattern_fn_param_tokens()
    println("ok")
