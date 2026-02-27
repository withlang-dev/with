//! expect-stdout: ok

// Behavior test: for loops
// Tests: for-range, for-array, for-in

use Token
use Lexer
use Ast
use Type
use Sema
use InternPool

fn lex(source: str) -> TokenList:
    var l = Lexer.new(source, 0)
    Lexer.tokenize(l)

fn test_for_keyword:
    var tokens = lex("for in")
    assert(TokenList.tag_at(tokens, 0) == TK_KW_FOR())
    assert(TokenList.tag_at(tokens, 1) == TK_KW_IN())

fn test_parse_for:
    let src = "fn f:\n    for i in 0..10:\n        i\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_FOR())

fn test_parse_range:
    let src = "fn f:\n    0..10\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_RANGE())

fn test_range_tokens:
    var tokens = lex("0..10")
    assert(TokenList.tag_at(tokens, 0) == TK_INT_LIT())
    assert(TokenList.tag_at(tokens, 1) == TK_DOT_DOT())
    assert(TokenList.tag_at(tokens, 2) == TK_INT_LIT())

fn test_range_inclusive_tokens:
    var tokens = lex("0..=10")
    assert(TokenList.tag_at(tokens, 0) == TK_INT_LIT())
    assert(TokenList.tag_at(tokens, 1) == TK_DOT_DOT_EQ())
    assert(TokenList.tag_at(tokens, 2) == TK_INT_LIT())

fn test_type_range:
    var types = TypeTable.new()
    let rt = TypeTable.add_range(types, TYPE_I32(), 0)
    assert(TypeTable.kind(types, rt) == TK_RANGE())
    assert(TypeTable.get_data0(types, rt) == TYPE_I32())
    assert(TypeTable.get_data1(types, rt) == 0)

fn main:
    test_for_keyword()
    test_parse_for()
    test_parse_range()
    test_range_tokens()
    test_range_inclusive_tokens()
    test_type_range()
    println("ok")
