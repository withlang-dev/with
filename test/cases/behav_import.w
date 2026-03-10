//! expect-stdout: ok

// Behavior test: use/import
// Tests: use keyword, parsing use declarations

use Token
use Lexer
use Ast
use Parser

fn lex(source: str) -> TokenList:
    var l = Lexer.new(source, 0)
    Lexer.tokenize(l)

fn test_use_keyword:
    var tokens = lex("use")
    assert(TokenList.tag_at(tokens, 0) == TK_KW_USE)

fn test_parse_use:
    let src = "use Token\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    assert(AstPool.decl_count(p.pool) == 1)
    let decl = AstPool.get_decl(p.pool, 0)
    assert(AstPool.kind(p.pool, decl) == NK_USE_DECL)

fn test_parse_multiple_use:
    let src = "use Token\nuse Lexer\nuse Ast\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    assert(AstPool.decl_count(p.pool) == 3)

fn test_module_keyword:
    var tokens = lex("module")
    assert(TokenList.tag_at(tokens, 0) == TK_KW_MODULE)

fn main:
    test_use_keyword()
    test_parse_use()
    test_parse_multiple_use()
    test_module_keyword()
    println("ok")
