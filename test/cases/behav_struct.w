//! expect-stdout: ok

// Behavior test: structs
// Tests: type declaration, construction, field access, methods, defaults

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

fn test_type_keyword:
    var tokens = lex("type impl extend")
    assert(TokenList.tag_at(tokens, 0) == TK_KW_TYPE())
    assert(TokenList.tag_at(tokens, 1) == TK_KW_IMPL())
    assert(TokenList.tag_at(tokens, 2) == TK_KW_EXTEND())

fn test_parse_struct_decl:
    let src = "type Point = {\n    x: i32,\n    y: i32,\n}\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    assert(AstPool.decl_count(p.pool) == 1)
    let decl = AstPool.get_decl(p.pool, 0)
    assert(AstPool.kind(p.pool, decl) == NK_TYPE_DECL())

fn test_parse_struct_lit:
    let src = "fn f:\n    Point { x: 1, y: 2 }\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_STRUCT_LIT())

fn test_parse_field_access:
    let src = "fn f:\n    p.x\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_FIELD_ACCESS())

fn test_type_struct:
    var types = TypeTable.new()
    var pool = AstPool.new()
    var field_names = Vec.new()
    field_names.push(AstPool.add_string(pool, "x"))
    field_names.push(AstPool.add_string(pool, "y"))
    var field_types = Vec.new()
    field_types.push(TYPE_I32())
    field_types.push(TYPE_I32())
    var field_defaults = Vec.new()
    field_defaults.push(0)
    field_defaults.push(0)
    let name_sym = AstPool.add_string(pool, "Point")
    let sid = TypeTable.add_struct(types, name_sym, field_names, field_types, field_defaults)
    assert(TypeTable.kind(types, sid) == TK_STRUCT())
    assert(TypeTable.struct_field_count(types, sid) == 2)
    assert(TypeTable.struct_field_type(types, sid, 0) == TYPE_I32())
    assert(TypeTable.struct_field_type(types, sid, 1) == TYPE_I32())

fn test_type_struct_lookup:
    var types = TypeTable.new()
    var pool = AstPool.new()
    var field_names = Vec.new()
    field_names.push(AstPool.add_string(pool, "x"))
    var field_types = Vec.new()
    field_types.push(TYPE_F64())
    var field_defaults = Vec.new()
    field_defaults.push(0)
    let name_sym = AstPool.add_string(pool, "Vec3")
    let sid = TypeTable.add_struct(types, name_sym, field_names, field_types, field_defaults)
    TypeTable.register_name(types, "Vec3", sid)
    // Look up by name
    let found = TypeTable.lookup(types, "Vec3")
    assert(found == sid)
    // Non-existent struct
    let not_found = TypeTable.lookup(types, "NoSuchType")
    assert(not_found == -1)

fn test_type_copy:
    var types = TypeTable.new()
    // Primitive types are copy
    assert(TypeTable.is_copy(types, TYPE_I32()) == true)
    assert(TypeTable.is_copy(types, TYPE_BOOL()) == true)
    assert(TypeTable.is_copy(types, TYPE_F64()) == true)
    // Str is not copy (has heap allocation in general)
    assert(TypeTable.is_copy(types, TYPE_STR()) == false)

fn main:
    test_type_keyword()
    test_parse_struct_decl()
    test_parse_struct_lit()
    test_parse_field_access()
    test_type_struct()
    test_type_struct_lookup()
    test_type_copy()
    println("ok")
