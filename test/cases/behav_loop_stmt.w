//! expect-stdout: ok

// Behavior test: loop: (infinite loop) (spec SS13.4)
// Missing feature: loop: as distinct from while true:
// Keyword TK_KW_LOOP is lexed. AST has NK_LOOP.
// Parser does not parse loop: as its own statement yet.

use Token
use Lexer
use Ast

fn lex(source: str) -> TokenList:
    var l = Lexer.new(source, 0)
    Lexer.tokenize(l)

fn test_loop_keyword:
    var tokens = lex("loop")
    assert(TokenList.tag_at(tokens, 0) == TK_KW_LOOP())
    assert(TK_KW_LOOP() == 23)

fn test_loop_node_constant:
    assert(NK_LOOP() == 36)

fn test_loop_colon_tokens:
    // loop:
    var tokens = lex("loop:")
    assert(TokenList.tag_at(tokens, 0) == TK_KW_LOOP())
    assert(TokenList.tag_at(tokens, 1) == TK_COLON())

fn test_loop_distinct_from_while:
    // loop and while are different keywords
    var t1 = lex("loop")
    var t2 = lex("while")
    assert(TokenList.tag_at(t1, 0) == TK_KW_LOOP())
    assert(TokenList.tag_at(t2, 0) == TK_KW_WHILE())
    assert(TK_KW_LOOP() != TK_KW_WHILE())

fn test_loop_vs_while_nodes:
    // NK_LOOP and NK_WHILE are distinct node kinds
    assert(NK_LOOP() == 36)
    assert(NK_WHILE() == 35)
    assert(NK_LOOP() != NK_WHILE())

fn test_break_continue_in_loop:
    // break and continue tokens work with loop
    var tokens = lex("break continue")
    assert(TokenList.tag_at(tokens, 0) == TK_KW_BREAK())
    assert(TokenList.tag_at(tokens, 1) == TK_KW_CONTINUE())
    assert(NK_BREAK() == 38)
    assert(NK_CONTINUE() == 39)

fn main:
    test_loop_keyword()
    test_loop_node_constant()
    test_loop_colon_tokens()
    test_loop_distinct_from_while()
    test_loop_vs_while_nodes()
    test_break_continue_in_loop()
    println("ok")
