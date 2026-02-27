//! expect-stdout: ok

// Behavior test: enums
// Tests: simple enums, payload enums, match on enums, variant shorthand

use Token
use Lexer
use Ast
use Type
use Sema
use InternPool

fn lex(source: str) -> TokenList:
    var l = Lexer.new(source, 0)
    Lexer.tokenize(l)

fn test_parse_enum_decl:
    let src = "type Color = enum:\n    Red\n    Green\n    Blue\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    assert(AstPool.decl_count(p.pool) == 1)
    let decl = AstPool.get_decl(p.pool, 0)
    assert(AstPool.kind(p.pool, decl) == NK_TYPE_DECL())

fn test_type_enum:
    var types = TypeTable.new()
    var pool = AstPool.new()
    var vnames = Vec.new()
    vnames.push(AstPool.add_string(pool, "Red"))
    vnames.push(AstPool.add_string(pool, "Green"))
    vnames.push(AstPool.add_string(pool, "Blue"))
    var vpayloads = Vec.new()
    vpayloads.push(0)
    vpayloads.push(0)
    vpayloads.push(0)
    var vptypes = Vec.new()
    let name_sym = AstPool.add_string(pool, "Color")
    let eid = TypeTable.add_enum(types, name_sym, vnames, vpayloads, vptypes)
    assert(TypeTable.kind(types, eid) == TK_ENUM())
    assert(TypeTable.enum_variant_count(types, eid) == 3)

fn test_sema_variant_lookup:
    var intern = InternPool.new()
    var pool = AstPool.new()
    AstPool.add_node(pool, 0, 0, 0, 0, 0, 0)
    var s = Sema.new(pool, "", intern)
    // Register Color enum
    var vnames = Vec.new()
    vnames.push(AstPool.add_string(pool, "Red"))
    vnames.push(AstPool.add_string(pool, "Green"))
    var vpayloads = Vec.new()
    vpayloads.push(0)
    vpayloads.push(0)
    var vptypes = Vec.new()
    let eid = TypeTable.add_enum(s.types, AstPool.add_string(pool, "Color"), vnames, vpayloads, vptypes)
    s.variant_names.push("Red")
    s.variant_enum_types.push(eid)
    s.variant_indices.push(0)
    s.variant_names.push("Green")
    s.variant_enum_types.push(eid)
    s.variant_indices.push(1)
    // Check that "Red" resolves to Color type
    let sym = AstPool.add_string(pool, "Red")
    let n = AstPool.add_node(pool, NK_IDENT(), 0, 3, sym, 0, 0)
    let t = Sema.check_expr(s, n)
    assert(t == eid)

fn test_parse_match_enum:
    let src = "fn f:\n    match x\n        0 -> 1\n        _ -> 2\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_MATCH())
    assert(AstPool.get_data2(p.pool, body) == 2)  // 2 arms

fn test_dot_ident_token:
    // .Red is a variant shorthand token
    var tokens = lex(".Red")
    assert(TokenList.tag_at(tokens, 0) == TK_DOT_IDENT())

fn main:
    test_parse_enum_decl()
    test_type_enum()
    test_sema_variant_lookup()
    test_parse_match_enum()
    test_dot_ident_token()
    println("ok")
