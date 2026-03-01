//! expect-stdout: ok

// Behavior test: else: colon form (bare else blocks)
// Tests: else: with block body, else: in if/else if/else chains

use Token
use Lexer
use Ast
use Parser

fn lex(source: str) -> TokenList:
    var l = Lexer.new(source, 0)
    Lexer.tokenize(l)

fn test_parse_else_colon:
    let src = "fn f:\n    if true:\n        1\n    else:\n        2\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_IF_EXPR())
    // Verify else branch exists (d2 != 0)
    let else_body = AstPool.get_data2(p.pool, body)
    assert(else_body != 0)

fn test_parse_else_if_else_colon:
    let src = "fn f:\n    if true:\n        1\n    else if false:\n        2\n    else:\n        3\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_IF_EXPR())
    // The else branch should be a nested if-expr
    let else_branch = AstPool.get_data2(p.pool, body)
    assert(else_branch != 0)
    assert(AstPool.kind(p.pool, else_branch) == NK_IF_EXPR())
    // The nested if-expr should have its own else branch
    let inner_else = AstPool.get_data2(p.pool, else_branch)
    assert(inner_else != 0)

fn main:
    test_parse_else_colon()
    test_parse_else_if_else_colon()
    println("ok")
