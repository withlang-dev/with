//! expect-stdout: ok

// Behavior test: with expressions
// Tests: with keyword, parsing

use Token
use Lexer
use Ast

fn lex(source: str) -> TokenList:
    var l = Lexer.new(source, 0)
    Lexer.tokenize(l)

fn test_with_keyword:
    var tokens = lex("with")
    assert(TokenList.tag_at(tokens, 0) == TK_KW_WITH())

fn test_parse_with_binding:
    let src = "fn f:\n    with x as name:\n        name\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_WITH_EXPR())

fn main:
    test_with_keyword()
    test_parse_with_binding()
    println("ok")
