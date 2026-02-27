//! expect-stdout: ok

// Behavior test: Result[T, E]
// Tests: Result type construction, Ok/Err, ?? default, ? try

use Token
use Lexer
use Ast
use Type
use Sema
use InternPool

fn lex(source: str) -> TokenList:
    var l = Lexer.new(source, 0)
    Lexer.tokenize(l)

fn test_type_result:
    var types = TypeTable.new()
    let rt = TypeTable.add_result(types, TYPE_I32(), TYPE_STR())
    assert(TypeTable.kind(types, rt) == TK_RESULT())
    assert(TypeTable.get_data0(types, rt) == TYPE_I32())
    assert(TypeTable.get_data1(types, rt) == TYPE_STR())

fn test_type_result_void_err:
    var types = TypeTable.new()
    let rt = TypeTable.add_result(types, TYPE_I32(), TYPE_VOID())
    assert(TypeTable.kind(types, rt) == TK_RESULT())

fn test_type_result_nested:
    var types = TypeTable.new()
    let inner = TypeTable.add_result(types, TYPE_I32(), TYPE_STR())
    let outer = TypeTable.add_option(types, inner)
    assert(TypeTable.kind(types, outer) == TK_OPTION())
    assert(TypeTable.get_data0(types, outer) == inner)

fn test_parse_default_op:
    let src = "fn f:\n    x ?? 0\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_BINARY())
    assert(AstPool.get_data2(p.pool, body) == OP_DEFAULT())

fn main:
    test_type_result()
    test_type_result_void_err()
    test_type_result_nested()
    test_parse_default_op()
    println("ok")
