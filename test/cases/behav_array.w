//! expect-stdout: ok

// Behavior test: arrays
// Tests: array literals, indexing, .len, nested arrays

use Token
use Lexer
use Ast
use Type
use Sema
use InternPool
use Parser

fn lex(source: str) -> TokenList:
    var l = Lexer.new(source, 0)
    Lexer.tokenize(l)

fn test_array_delimiters:
    var tokens = lex("[1, 2, 3]")
    assert(TokenList.tag_at(tokens, 0) == TK_L_BRACKET())
    assert(TokenList.tag_at(tokens, 1) == TK_INT_LIT())
    assert(TokenList.tag_at(tokens, 2) == TK_COMMA())
    assert(TokenList.tag_at(tokens, 3) == TK_INT_LIT())
    assert(TokenList.tag_at(tokens, 4) == TK_COMMA())
    assert(TokenList.tag_at(tokens, 5) == TK_INT_LIT())
    assert(TokenList.tag_at(tokens, 6) == TK_R_BRACKET())

fn test_parse_array_lit:
    let src = "fn f:\n    [1, 2, 3]\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_ARRAY_LIT())

fn test_parse_index:
    let src = "fn f:\n    a[0]\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_INDEX())

fn test_type_array:
    var types = TypeTable.new()
    let at = TypeTable.add_array(types, TYPE_I32(), 5)
    assert(TypeTable.kind(types, at) == TK_ARRAY())
    assert(TypeTable.get_data0(types, at) == TYPE_I32())
    assert(TypeTable.get_data1(types, at) == 5)

fn test_type_slice:
    var types = TypeTable.new()
    let st = TypeTable.add_slice(types, TYPE_I32())
    assert(TypeTable.kind(types, st) == TK_SLICE())
    assert(TypeTable.get_data0(types, st) == TYPE_I32())

fn main:
    test_array_delimiters()
    test_parse_array_lit()
    test_parse_index()
    test_type_array()
    test_type_slice()
    println("ok")
