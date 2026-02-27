//! expect-stdout: ok

// Compile error test: undefined types
// Tests that the type system handles missing types correctly

use Ast
use Type
use Sema
use InternPool

fn test_type_lookup_missing:
    var types = TypeTable.new()
    assert(TypeTable.lookup(types, "NoSuchType") == -1)
    assert(TypeTable.lookup(types, "Unknown") == -1)
    assert(TypeTable.lookup(types, "Foo") == -1)

fn test_builtin_types_exist:
    var types = TypeTable.new()
    assert(TypeTable.lookup(types, "i32") == TYPE_I32())
    assert(TypeTable.lookup(types, "bool") == TYPE_BOOL())
    assert(TypeTable.lookup(types, "str") == TYPE_STR())
    assert(TypeTable.lookup(types, "void") == TYPE_VOID())
    assert(TypeTable.lookup(types, "i8") == TYPE_I8())
    assert(TypeTable.lookup(types, "i16") == TYPE_I16())
    assert(TypeTable.lookup(types, "i64") == TYPE_I64())
    assert(TypeTable.lookup(types, "u8") == TYPE_U8())
    assert(TypeTable.lookup(types, "u16") == TYPE_U16())
    assert(TypeTable.lookup(types, "u32") == TYPE_U32())
    assert(TypeTable.lookup(types, "u64") == TYPE_U64())
    assert(TypeTable.lookup(types, "f32") == TYPE_F32())
    assert(TypeTable.lookup(types, "f64") == TYPE_F64())

fn main:
    test_type_lookup_missing()
    test_builtin_types_exist()
    println("ok")
