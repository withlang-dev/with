//! expect-stdout: ok

// Behavior test: Option[T]
// Tests: Option type construction, Some/None, ?? default, ? try

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

fn test_question_tokens:
    var tokens = lex("? ??")
    assert(TokenList.tag_at(tokens, 0) == TK_QUESTION())
    assert(TokenList.tag_at(tokens, 1) == TK_QUESTION_QUESTION())

fn test_question_dot_token:
    var tokens = lex("?.")
    assert(TokenList.tag_at(tokens, 0) == TK_QUESTION_DOT())

fn test_type_option:
    var types = TypeTable.new()
    let opt = TypeTable.add_option(types, TYPE_I32())
    assert(TypeTable.kind(types, opt) == TK_OPTION())
    assert(TypeTable.get_data0(types, opt) == TYPE_I32())

fn test_type_option_str:
    var types = TypeTable.new()
    let opt = TypeTable.add_option(types, TYPE_STR())
    assert(TypeTable.kind(types, opt) == TK_OPTION())
    assert(TypeTable.get_data0(types, opt) == TYPE_STR())

fn test_type_option_nested:
    var types = TypeTable.new()
    let inner = TypeTable.add_option(types, TYPE_I32())
    let outer = TypeTable.add_option(types, inner)
    assert(TypeTable.kind(types, outer) == TK_OPTION())
    assert(TypeTable.get_data0(types, outer) == inner)

fn test_parse_optional_type:
    let src = "fn f(x: ?i32) -> ?i32:\n    x\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    assert(AstPool.kind(p.pool, decl) == NK_FN_DECL())

fn main:
    test_question_tokens()
    test_question_dot_token()
    test_type_option()
    test_type_option_str()
    test_type_option_nested()
    test_parse_optional_type()
    println("ok")
