//! expect-stdout: ok

// Behavior test: record update with copy semantics (Rust ui/structs-enums/)
// Tests: struct construction, field access, copy types remain valid after
// record update, struct type properties

use Token
use Lexer
use Ast
use Type
use InternPool
use Parser

fn lex(source: str) -> TokenList:
    var l = Lexer.new(source, 0)
    Lexer.tokenize(l)

fn test_struct_type_construction:
    var types = TypeTable.new()
    var intern = InternPool.new()
    let name = InternPool.intern(intern, "Point")
    var field_names = Vec.new()
    let fx = InternPool.intern(intern, "x")
    let fy = InternPool.intern(intern, "y")
    field_names.push(fx)
    field_names.push(fy)
    var field_types = Vec.new()
    field_types.push(TYPE_I32())
    field_types.push(TYPE_I32())
    var field_defaults = Vec.new()
    field_defaults.push(0)
    field_defaults.push(0)
    let tid = TypeTable.add_struct(types, name, field_names, field_types, field_defaults)
    assert(TypeTable.is_struct(types, tid))
    assert(TypeTable.struct_field_count(types, tid) == 2)
    assert(TypeTable.struct_field_type(types, tid, 0) == TYPE_I32())
    assert(TypeTable.struct_field_type(types, tid, 1) == TYPE_I32())

fn test_struct_not_copy:
    // Structs are NOT copy types by default
    var types = TypeTable.new()
    var fn1 = Vec.new()
    fn1.push(0)
    var ft1 = Vec.new()
    ft1.push(TYPE_I32())
    var fd1 = Vec.new()
    fd1.push(0)
    let st = TypeTable.add_struct(types, 1, fn1, ft1, fd1)
    assert(not TypeTable.is_copy(types, st))

fn test_struct_with_defaults:
    var types = TypeTable.new()
    var fn1 = Vec.new()
    fn1.push(1)
    fn1.push(2)
    var ft1 = Vec.new()
    ft1.push(TYPE_I32())
    ft1.push(TYPE_I32())
    var fd1 = Vec.new()
    fd1.push(1)  // field 0 has default
    fd1.push(0)  // field 1 no default
    let st = TypeTable.add_struct(types, 10, fn1, ft1, fd1)
    assert(TypeTable.struct_field_has_default(types, st, 0) == 1)
    assert(TypeTable.struct_field_has_default(types, st, 1) == 0)

fn test_parse_record_update:
    // { expr with field: val }
    let src = "fn f:\n    { p with x: 10 }\n"
    var tokens = lex(src)
    var p = Parser.new(tokens, src)
    Parser.parse_module(p)
    let decl = AstPool.get_decl(p.pool, 0)
    let body = AstPool.get_data1(p.pool, decl)
    assert(AstPool.kind(p.pool, body) == NK_RECORD_UPDATE())

fn test_struct_name_lookup:
    var types = TypeTable.new()
    var fn1 = Vec.new()
    fn1.push(0)
    var ft1 = Vec.new()
    ft1.push(TYPE_I32())
    var fd1 = Vec.new()
    fd1.push(0)
    let st = TypeTable.add_struct(types, 42, fn1, ft1, fd1)
    TypeTable.register_name(types, "MyStruct", st)
    assert(TypeTable.lookup(types, "MyStruct") == st)

fn test_struct_type_equality:
    // Struct types are nominal — same name → same TypeId
    var types = TypeTable.new()
    var fn1 = Vec.new()
    fn1.push(0)
    var ft1 = Vec.new()
    ft1.push(TYPE_I32())
    var fd1 = Vec.new()
    fd1.push(0)
    let st1 = TypeTable.add_struct(types, 1, fn1, ft1, fd1)
    // Different registration → different TypeId
    var fn2 = Vec.new()
    fn2.push(0)
    var ft2 = Vec.new()
    ft2.push(TYPE_I32())
    var fd2 = Vec.new()
    fd2.push(0)
    let st2 = TypeTable.add_struct(types, 2, fn2, ft2, fd2)
    assert(st1 != st2)
    // types_equal returns false for different struct TypeIds
    assert(TypeTable.types_equal(types, st1, st2) == false)
    // Same TypeId is always equal
    assert(TypeTable.types_equal(types, st1, st1) == true)

fn test_copy_types_after_update:
    // Copy types (i32, bool, f64) remain valid after being "used"
    // This verifies the is_copy predicate covers all primitive types
    var types = TypeTable.new()
    assert(TypeTable.is_copy(types, TYPE_I32()) == true)
    assert(TypeTable.is_copy(types, TYPE_I64()) == true)
    assert(TypeTable.is_copy(types, TYPE_F32()) == true)
    assert(TypeTable.is_copy(types, TYPE_F64()) == true)
    assert(TypeTable.is_copy(types, TYPE_BOOL()) == true)
    assert(TypeTable.is_copy(types, TYPE_U8()) == true)
    assert(TypeTable.is_copy(types, TYPE_UNIT()) == true)
    assert(TypeTable.is_copy(types, TYPE_VOID()) == true)

fn main:
    test_struct_type_construction()
    test_struct_not_copy()
    test_struct_with_defaults()
    test_parse_record_update()
    test_struct_name_lookup()
    test_struct_type_equality()
    test_copy_types_after_update()
    println("ok")
