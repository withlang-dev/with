//! expect-stdout: ok

// Behavior test: closures
// Tests: non-capturing closures (fn ptrs), closure syntax

use Token
use Lexer
use Ast
use Type
use Sema
use InternPool

fn lex(source: str) -> TokenList:
    var l = Lexer.new(source, 0)
    Lexer.tokenize(l)

fn test_fat_arrow:
    var tokens = lex("=>")
    assert(TokenList.tag_at(tokens, 0) == TK_FAT_ARROW())

fn test_parse_closure:
    let src = "fn f:\n    |x| => x + 1\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_CLOSURE())

fn test_type_fn_ptr:
    var types = TypeTable.new()
    var params = Vec.new()
    params.push(TYPE_I32())
    let ft = TypeTable.add_fn(types, params, TYPE_I32(), 0)
    assert(TypeTable.kind(types, ft) == TK_FN())
    assert(TypeTable.fn_param_count(types, ft) == 1)
    assert(TypeTable.fn_return_type(types, ft) == TYPE_I32())

fn test_type_fn_variadic:
    var types = TypeTable.new()
    var params = Vec.new()
    params.push(TYPE_STR())
    let ft = TypeTable.add_fn(types, params, TYPE_I32(), 1)  // is_variadic=1
    assert(TypeTable.kind(types, ft) == TK_FN())

fn main:
    test_fat_arrow()
    test_parse_closure()
    test_type_fn_ptr()
    test_type_fn_variadic()
    println("ok")
