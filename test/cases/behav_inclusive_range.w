//! expect-stdout: ok

// Behavior test: inclusive range in for loops (spec SS4.2)
// Lexer/parser handle ..= but semantic support for
// for i in 0..=10: is unclear.

use Token
use Lexer
use Ast
use Type

fn lex(source: str) -> TokenList:
    var l = Lexer.new(source, 0)
    Lexer.tokenize(l)

fn test_dot_dot_eq_token:
    var tokens = lex("..=")
    assert(TokenList.tag_at(tokens, 0) == TK_DOT_DOT_EQ())
    assert(TK_DOT_DOT_EQ() == 80)

fn test_dot_dot_token:
    var tokens = lex("..")
    assert(TokenList.tag_at(tokens, 0) == TK_DOT_DOT())
    assert(TK_DOT_DOT() == 79)

fn test_inclusive_range_tokens:
    // 0..=10
    var tokens = lex("0..=10")
    assert(TokenList.tag_at(tokens, 0) == TK_INT_LIT())
    assert(TokenList.tag_at(tokens, 1) == TK_DOT_DOT_EQ())
    assert(TokenList.tag_at(tokens, 2) == TK_INT_LIT())

fn test_exclusive_range_tokens:
    // 0..10
    var tokens = lex("0..10")
    assert(TokenList.tag_at(tokens, 0) == TK_INT_LIT())
    assert(TokenList.tag_at(tokens, 1) == TK_DOT_DOT())
    assert(TokenList.tag_at(tokens, 2) == TK_INT_LIT())

fn test_range_node_constant:
    assert(NK_RANGE() == 48)

fn test_range_type_constant:
    assert(TK_RANGE() == 29)

fn test_for_with_range_tokens:
    // for i in 0..=10:
    var tokens = lex("for i in 0..=10:")
    assert(TokenList.tag_at(tokens, 0) == TK_KW_FOR())
    assert(TokenList.tag_at(tokens, 1) == TK_IDENT())  // i
    assert(TokenList.tag_at(tokens, 2) == TK_KW_IN())
    assert(TokenList.tag_at(tokens, 3) == TK_INT_LIT())  // 0
    assert(TokenList.tag_at(tokens, 4) == TK_DOT_DOT_EQ())
    assert(TokenList.tag_at(tokens, 5) == TK_INT_LIT())  // 10
    assert(TokenList.tag_at(tokens, 6) == TK_COLON())

fn test_dot_dot_dot_token:
    // ... (spread) is also a token
    var tokens = lex("...")
    assert(TokenList.tag_at(tokens, 0) == TK_DOT_DOT_DOT())
    assert(TK_DOT_DOT_DOT() == 81)

fn main:
    test_dot_dot_eq_token()
    test_dot_dot_token()
    test_inclusive_range_tokens()
    test_exclusive_range_tokens()
    test_range_node_constant()
    test_range_type_constant()
    test_for_with_range_tokens()
    test_dot_dot_dot_token()
    println("ok")
