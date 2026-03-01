//! expect-stdout: ok

// Behavior test: list comprehensions (spec SS13.6)
// Missing feature: parser should support [expr for x in iter if cond]
// Currently not parsed. Need new AST node(s) for comprehension.

use Token
use Lexer
use Ast

fn lex(source: str) -> TokenList:
    var l = Lexer.new(source, 0)
    Lexer.tokenize(l)

fn test_comprehension_token_sequence:
    // [x * 2 for x in items]
    var tokens = lex("[x * 2 for x in items]")
    assert(TokenList.tag_at(tokens, 0) == TK_L_BRACKET())
    assert(TokenList.tag_at(tokens, 1) == TK_IDENT())  // x
    assert(TokenList.tag_at(tokens, 2) == TK_STAR())
    assert(TokenList.tag_at(tokens, 3) == TK_INT_LIT())  // 2
    assert(TokenList.tag_at(tokens, 4) == TK_KW_FOR())
    assert(TokenList.tag_at(tokens, 5) == TK_IDENT())  // x
    assert(TokenList.tag_at(tokens, 6) == TK_KW_IN())
    assert(TokenList.tag_at(tokens, 7) == TK_IDENT())  // items
    assert(TokenList.tag_at(tokens, 8) == TK_R_BRACKET())

fn test_filtered_comprehension_tokens:
    // [x for x in items if x > 0]
    // tokens: [ x for x in items if x > 0 ]
    //         0 1 2   3 4  5     6  7 8 9 10
    var tokens = lex("[x for x in items if x > 0]")
    assert(TokenList.tag_at(tokens, 0) == TK_L_BRACKET())
    assert(TokenList.tag_at(tokens, 2) == TK_KW_FOR())
    assert(TokenList.tag_at(tokens, 4) == TK_KW_IN())
    assert(TokenList.tag_at(tokens, 6) == TK_KW_IF())

fn test_for_in_keywords:
    var tokens = lex("for x in items")
    assert(TokenList.tag_at(tokens, 0) == TK_KW_FOR())
    assert(TokenList.tag_at(tokens, 2) == TK_KW_IN())

fn test_bracket_tokens:
    var tokens = lex("[]")
    assert(TokenList.tag_at(tokens, 0) == TK_L_BRACKET())
    assert(TokenList.tag_at(tokens, 1) == TK_R_BRACKET())

fn main:
    test_comprehension_token_sequence()
    test_filtered_comprehension_tokens()
    test_for_in_keywords()
    test_bracket_tokens()
    println("ok")
