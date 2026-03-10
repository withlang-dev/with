//! expect-stdout: ok

// Behavior test: multiple with bindings (spec SS7.5)
// Missing feature: with a as x, b as y: (comma-separated bindings)
// Also: with Form 1 (guarded access via Scoped trait) — needs sema.

use Token
use Lexer
use Ast

fn lex(source: str) -> TokenList:
    var l = Lexer.new(source, 0)
    Lexer.tokenize(l)

fn test_with_keyword:
    var tokens = lex("with")
    assert(TokenList.tag_at(tokens, 0) == TK_KW_WITH)
    assert(TK_KW_WITH == 27)

fn test_as_keyword:
    var tokens = lex("as")
    assert(TokenList.tag_at(tokens, 0) == TK_KW_AS)
    assert(TK_KW_AS == 28)

fn test_multi_with_token_sequence:
    // with a as x, b as y:
    var tokens = lex("with a as x, b as y:")
    assert(TokenList.tag_at(tokens, 0) == TK_KW_WITH)
    assert(TokenList.tag_at(tokens, 1) == TK_IDENT)  // a
    assert(TokenList.tag_at(tokens, 2) == TK_KW_AS)
    assert(TokenList.tag_at(tokens, 3) == TK_IDENT)  // x
    assert(TokenList.tag_at(tokens, 4) == TK_COMMA)
    assert(TokenList.tag_at(tokens, 5) == TK_IDENT)  // b
    assert(TokenList.tag_at(tokens, 6) == TK_KW_AS)
    assert(TokenList.tag_at(tokens, 7) == TK_IDENT)  // y
    assert(TokenList.tag_at(tokens, 8) == TK_COLON)

fn test_with_mut_tokens:
    // with expr as mut name:
    var tokens = lex("with expr as mut name:")
    assert(TokenList.tag_at(tokens, 0) == TK_KW_WITH)
    assert(TokenList.tag_at(tokens, 1) == TK_IDENT)  // expr
    assert(TokenList.tag_at(tokens, 2) == TK_KW_AS)
    assert(TokenList.tag_at(tokens, 3) == TK_KW_MUT)
    assert(TokenList.tag_at(tokens, 4) == TK_IDENT)  // name

fn test_with_expr_node:
    assert(NK_WITH_EXPR == 52)

fn main:
    test_with_keyword()
    test_as_keyword()
    test_multi_with_token_sequence()
    test_with_mut_tokens()
    test_with_expr_node()
    println("ok")
