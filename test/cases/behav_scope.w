//! expect-stdout: ok

// Behavior test: variable scoping
// Tests: let/var, shadowing, nested scopes

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

fn test_let_var_keywords:
    var tokens = lex("let var")
    assert(TokenList.tag_at(tokens, 0) == TK_KW_LET())
    assert(TokenList.tag_at(tokens, 1) == TK_KW_VAR())

fn test_parse_let:
    let src = "fn f:\n    let x = 42\n    x\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_BLOCK())

fn test_parse_var:
    let src = "fn f:\n    var x = 42\n    x\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_BLOCK())

fn test_scope_chain:
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    Sema.define_var(s, "x", TYPE_I32(), 0)
    assert(Sema.lookup_var(s, "x") >= 0)
    Sema.push_scope(s)
    // x visible from parent
    assert(Sema.lookup_var(s, "x") >= 0)
    // Shadow with new x
    Sema.define_var(s, "x", TYPE_BOOL(), 0)
    let info = Sema.lookup_var(s, "x")
    assert(var_type_id(info) == TYPE_BOOL())
    // Define y only in child
    Sema.define_var(s, "y", TYPE_STR(), 1)
    assert(Sema.lookup_var(s, "y") >= 0)
    Sema.pop_scope(s)
    // After pop, original x should still be visible
    assert(Sema.lookup_var(s, "x") >= 0)

fn test_assign_parse:
    let src = "fn f:\n    x = 42\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_ASSIGN())

fn main:
    test_let_var_keywords()
    test_parse_let()
    test_parse_var()
    test_scope_chain()
    test_assign_parse()
    println("ok")
