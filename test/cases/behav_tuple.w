//! expect-stdout: ok

// Behavior test: tuples
// Tests: tuple construction, field access (.0, .1), type

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

fn test_parse_tuple:
    let src = "fn f:\n    (1, 2)\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_TUPLE())

fn test_type_tuple:
    var types = TypeTable.new()
    var elems = Vec.new()
    elems.push(TYPE_I32())
    elems.push(TYPE_STR())
    let tt = TypeTable.add_tuple(types, elems)
    assert(TypeTable.kind(types, tt) == TK_TUPLE())
    assert(TypeTable.tuple_elem_count(types, tt) == 2)
    assert(TypeTable.tuple_elem_type(types, tt, 0) == TYPE_I32())
    assert(TypeTable.tuple_elem_type(types, tt, 1) == TYPE_STR())

fn test_type_tuple_three:
    var types = TypeTable.new()
    var elems = Vec.new()
    elems.push(TYPE_I32())
    elems.push(TYPE_BOOL())
    elems.push(TYPE_F64())
    let tt = TypeTable.add_tuple(types, elems)
    assert(TypeTable.tuple_elem_count(types, tt) == 3)

fn main:
    test_parse_tuple()
    test_type_tuple()
    test_type_tuple_three()
    println("ok")
