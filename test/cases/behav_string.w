//! expect-stdout: ok

// Behavior test: strings
// Tests: string literals, escape sequences, string methods

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

fn test_string_literal_token:
    let src = "\"hello world\""
    var tokens = lex(src)
    assert(TokenList.tag_at(tokens, 0) == TK_STRING_LIT())

fn test_string_with_escape:
    let src = "\"hello\\nworld\""
    var tokens = lex(src)
    assert(TokenList.tag_at(tokens, 0) == TK_STRING_LIT())

fn test_c_string_token:
    let src = "c\"hello\""
    var tokens = lex(src)
    assert(TokenList.tag_at(tokens, 0) == TK_C_STRING_LIT())

fn test_parse_string_lit:
    let src = "fn f:\n    \"hello\"\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_STRING_LIT())

fn test_sema_string_type:
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    let n = AstPool.add_node(pool, NK_STRING_LIT(), 0, 7, 0, 0, 0)
    let t = Sema.check_expr(s, n)
    assert(t == TYPE_STR())

fn test_type_str_is_not_copy:
    var types = TypeTable.new()
    assert(TypeTable.is_copy(types, TYPE_STR()) == false)

fn test_empty_string:
    let src = "\"\""
    var tokens = lex(src)
    assert(TokenList.tag_at(tokens, 0) == TK_STRING_LIT())

fn main:
    test_string_literal_token()
    test_string_with_escape()
    test_c_string_token()
    test_parse_string_lit()
    test_sema_string_type()
    test_type_str_is_not_copy()
    test_empty_string()
    println("ok")
