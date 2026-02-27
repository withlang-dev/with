//! expect-stdout: ok

// Behavior test: match expressions
// Tests: int match, bool match, wildcard, guard, nested

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

fn test_match_keyword:
    var tokens = lex("match")
    assert(TokenList.tag_at(tokens, 0) == TK_KW_MATCH())

fn test_parse_match_int:
    let src = "fn f:\n    match x\n        0 -> 1\n        1 -> 2\n        _ -> 3\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_MATCH())
    assert(AstPool.get_data2(p.pool, body) == 3)  // 3 arms

fn test_parse_match_two_arms:
    let src = "fn f:\n    match x\n        true -> 1\n        false -> 2\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_MATCH())
    assert(AstPool.get_data2(p.pool, body) == 2)  // 2 arms

fn test_parse_match_wildcard:
    let src = "fn f:\n    match x\n        _ -> 0\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_MATCH())
    assert(AstPool.get_data2(p.pool, body) == 1)

fn test_mir_match_lowering:
    // Build: fn f: match 1 → 0 -> 10, _ -> 20
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    let subject = AstPool.add_node(pool, NK_INT_LIT(), 10, 11, 1, 0, 0)
    // Arm 1: pat 0 → body 10
    let pat1 = AstPool.add_node(pool, NK_PAT_INT(), 16, 17, 0, 0, 0)
    let body1 = AstPool.add_node(pool, NK_INT_LIT(), 21, 23, 10, 0, 0)
    let arm1 = AstPool.add_node(pool, NK_MATCH_ARM(), 16, 23, pat1, body1, 0)
    // Arm 2: _ → body 20
    let pat2 = AstPool.add_node(pool, NK_PAT_WILDCARD(), 28, 29, 0, 0, 0)
    let body2 = AstPool.add_node(pool, NK_INT_LIT(), 33, 35, 20, 0, 0)
    let arm2 = AstPool.add_node(pool, NK_MATCH_ARM(), 28, 35, pat2, body2, 0)
    let arm_start = AstPool.add_extra(pool, arm1)
    AstPool.add_extra(pool, arm2)
    let match_node = AstPool.add_node(pool, NK_MATCH(), 4, 35, subject, arm_start, 2)
    let name_sym = AstPool.add_string(pool, "f")
    let e0 = AstPool.add_extra(pool, 0)
    AstPool.add_extra(pool, 0)
    AstPool.add_extra(pool, 0)
    let fn_node = AstPool.add_node(pool, NK_FN_DECL(), 0, 40, name_sym, match_node, e0)
    AstPool.add_decl(pool, fn_node)
    var types = TypeTable.new()
    let src = "fn f:\n    match 1\n        0 -> 10\n        _ -> 20\n"
    var builder = MirBuilder.new(pool, types, src)
    let mir = MirBuilder.lower_fn(builder, fn_node)
    // Match lowering creates multiple blocks
    assert(MirBody.block_count(mir) >= 2)

fn main:
    test_match_keyword()
    test_parse_match_int()
    test_parse_match_two_arms()
    test_parse_match_wildcard()
    test_mir_match_lowering()
    println("ok")
