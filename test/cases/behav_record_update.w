//! expect-stdout: ok

// Behavior test: record update syntax { expr with field: val }
// Tests: parsing record update expressions

use Token
use Lexer
use Ast
use Parser

fn lex(source: str) -> TokenList:
    var l = Lexer.new(source, 0)
    Lexer.tokenize(l)

fn test_parse_record_update:
    let src = "fn f:\n    { p with x: 10 }\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_RECORD_UPDATE())

fn test_brace_tokens:
    var tokens = lex("{ }")
    assert(TokenList.tag_at(tokens, 0) == TK_L_BRACE())
    assert(TokenList.tag_at(tokens, 1) == TK_R_BRACE())

fn main:
    test_parse_record_update()
    test_brace_tokens()
    println("ok")
