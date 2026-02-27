//! expect-stdout: ok

// Behavior test: while loops
// Tests: while, break, continue, loop

use Token
use Lexer
use Ast
use Type
use Sema
use InternPool
use Mir
use MirBuild

fn lex(source: str) -> TokenList:
    var l = Lexer.new(source, 0)
    Lexer.tokenize(l)

fn test_while_keyword:
    var tokens = lex("while loop break continue")
    assert(TokenList.tag_at(tokens, 0) == TK_KW_WHILE())
    assert(TokenList.tag_at(tokens, 1) == TK_KW_LOOP())
    assert(TokenList.tag_at(tokens, 2) == TK_KW_BREAK())
    assert(TokenList.tag_at(tokens, 3) == TK_KW_CONTINUE())

fn test_parse_while:
    let src = "fn f:\n    while true:\n        42\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_WHILE())
    let cond = AstPool.get_data0(p.pool, body)
    assert(AstPool.kind(p.pool, cond) == NK_BOOL_LIT())

fn test_parse_loop:
    let src = "fn f:\n    loop:\n        break\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_LOOP())

fn test_parse_break:
    let src = "fn f:\n    break\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_BREAK())

fn test_parse_continue:
    let src = "fn f:\n    continue\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_CONTINUE())

fn test_sema_while:
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    s.loop_depth = 1  // pretend we're in a loop context
    let cond = AstPool.add_node(pool, NK_BOOL_LIT(), 0, 4, 1, 0, 0)
    let body = AstPool.add_node(pool, NK_INT_LIT(), 10, 12, 42, 0, 0)
    let w = AstPool.add_node(pool, NK_WHILE(), 0, 12, cond, body, 0)
    let t = Sema.check_expr(s, w)
    assert(t == TYPE_VOID())

fn test_mir_while_lowering:
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    let cond = AstPool.add_node(pool, NK_BOOL_LIT(), 6, 10, 1, 0, 0)
    let body = AstPool.add_node(pool, NK_INT_LIT(), 16, 18, 42, 0, 0)
    let w = AstPool.add_node(pool, NK_WHILE(), 0, 18, cond, body, 0)
    let name_sym = AstPool.add_string(pool, "f")
    let e0 = AstPool.add_extra(pool, 0)
    AstPool.add_extra(pool, 0)
    AstPool.add_extra(pool, 0)
    let fn_node = AstPool.add_node(pool, NK_FN_DECL(), 0, 20, name_sym, w, e0)
    AstPool.add_decl(pool, fn_node)
    var types = TypeTable.new()
    var builder = MirBuilder.new(pool, types, "fn f:\n    while true:\n        42\n")
    let mir = MirBuilder.lower_fn(builder, fn_node)
    // While creates at least 3 blocks: cond, body, exit
    assert(MirBody.block_count(mir) >= 3)

fn main:
    test_while_keyword()
    test_parse_while()
    test_parse_loop()
    test_parse_break()
    test_parse_continue()
    test_sema_while()
    test_mir_while_lowering()
    println("ok")
