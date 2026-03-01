//! expect-stdout: ok

// Behavior test: partial application and placeholder closures (spec SS9.3, SS9.4)
// Missing features:
// - Partial application: add(5, _) creates a closure
// - Placeholder closure: _.field, _.method(), _ + 1
// Currently not parsed. _ in non-pattern position lexes as TK_IDENT.

use Token
use Lexer
use Ast

fn lex(source: str) -> TokenList:
    var l = Lexer.new(source, 0)
    Lexer.tokenize(l)

fn test_underscore_as_ident:
    // _ lexes as TK_IDENT in expression position
    var tokens = lex("_")
    assert(TokenList.tag_at(tokens, 0) == TK_IDENT())

fn test_partial_app_token_sequence:
    // add(5, _) — _ is placeholder for partial application
    var tokens = lex("add(5, _)")
    assert(TokenList.tag_at(tokens, 0) == TK_IDENT())  // add
    assert(TokenList.tag_at(tokens, 1) == TK_L_PAREN())
    assert(TokenList.tag_at(tokens, 2) == TK_INT_LIT())  // 5
    assert(TokenList.tag_at(tokens, 3) == TK_COMMA())
    assert(TokenList.tag_at(tokens, 4) == TK_IDENT())  // _
    assert(TokenList.tag_at(tokens, 5) == TK_R_PAREN())

fn test_placeholder_field_tokens:
    // _.field — placeholder closure accessing a field
    var tokens = lex("_.field")
    assert(TokenList.tag_at(tokens, 0) == TK_IDENT())  // _
    assert(TokenList.tag_at(tokens, 1) == TK_DOT())
    assert(TokenList.tag_at(tokens, 2) == TK_IDENT())  // field

fn test_placeholder_method_tokens:
    // _.method() — placeholder closure calling a method
    var tokens = lex("_.method()")
    assert(TokenList.tag_at(tokens, 0) == TK_IDENT())  // _
    assert(TokenList.tag_at(tokens, 1) == TK_DOT())
    assert(TokenList.tag_at(tokens, 2) == TK_IDENT())  // method
    assert(TokenList.tag_at(tokens, 3) == TK_L_PAREN())
    assert(TokenList.tag_at(tokens, 4) == TK_R_PAREN())

fn test_placeholder_expr_tokens:
    // _ + 1 — placeholder closure with binary op
    var tokens = lex("_ + 1")
    assert(TokenList.tag_at(tokens, 0) == TK_IDENT())  // _
    assert(TokenList.tag_at(tokens, 1) == TK_PLUS())
    assert(TokenList.tag_at(tokens, 2) == TK_INT_LIT())  // 1

fn test_closure_node_constant:
    // Placeholder closures would desugar to NK_CLOSURE
    assert(NK_CLOSURE() == 44)

fn main:
    test_underscore_as_ident()
    test_partial_app_token_sequence()
    test_placeholder_field_tokens()
    test_placeholder_method_tokens()
    test_placeholder_expr_tokens()
    test_closure_node_constant()
    println("ok")
