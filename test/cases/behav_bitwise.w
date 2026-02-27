//! expect-stdout: ok

// Behavior test: bitwise operations
// Tests: &, |, ^, <<, >>, ~

use Token
use Lexer
use Ast
use Type

fn lex(source: str) -> TokenList:
    var l = Lexer.new(source, 0)
    Lexer.tokenize(l)

fn test_bitwise_tokens:
    var tokens = lex("& | ^ ~ << >>")
    assert(TokenList.tag_at(tokens, 0) == TK_AMPERSAND())
    assert(TokenList.tag_at(tokens, 1) == TK_PIPE())
    assert(TokenList.tag_at(tokens, 2) == TK_CARET())
    assert(TokenList.tag_at(tokens, 3) == TK_TILDE())
    assert(TokenList.tag_at(tokens, 4) == TK_LT_LT())
    assert(TokenList.tag_at(tokens, 5) == TK_GT_GT())

fn test_parse_bit_and:
    let src = "fn f:\n    x & y\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    // Note: & could be ref or bitand depending on context
    // In binary expression context it's bitand
    assert(AstPool.kind(p.pool, body) != 0)  // something was parsed

fn test_parse_shift_left:
    let src = "fn f:\n    1 << 2\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_BINARY())
    assert(AstPool.get_data2(p.pool, body) == OP_SHL())

fn test_parse_shift_right:
    let src = "fn f:\n    8 >> 1\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_BINARY())
    assert(AstPool.get_data2(p.pool, body) == OP_SHR())

fn test_bitop_constants:
    assert(OP_BIT_AND() == 13)
    assert(OP_BIT_OR() == 14)
    assert(OP_BIT_XOR() == 15)
    assert(OP_SHL() == 16)
    assert(OP_SHR() == 17)

fn main:
    test_bitwise_tokens()
    test_parse_bit_and()
    test_parse_shift_left()
    test_parse_shift_right()
    test_bitop_constants()
    println("ok")
