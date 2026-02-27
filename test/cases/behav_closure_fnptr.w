//! expect-stdout: ok

// Behavior test: non-capturing closures as fn pointers (Rust ui/closures/)
// Tests: fn pointer type creation, fn arrays, fn type equality,
// variadic fn types

use Type

fn test_fn_ptr_basic:
    var types = TypeTable.new()
    var params = Vec.new()
    params.push(TYPE_I32())
    let ft = TypeTable.add_fn(types, params, TYPE_I32(), 0)
    assert(TypeTable.kind(types, ft) == TK_FN())
    assert(TypeTable.fn_is_variadic(types, ft) == 0)

fn test_fn_ptr_not_variadic:
    var types = TypeTable.new()
    var params = Vec.new()
    params.push(TYPE_STR())
    let ft = TypeTable.add_fn(types, params, TYPE_VOID(), 0)
    assert(TypeTable.fn_is_variadic(types, ft) == 0)

fn test_fn_ptr_variadic:
    var types = TypeTable.new()
    var params = Vec.new()
    params.push(TYPE_STR())
    let ft = TypeTable.add_fn(types, params, TYPE_I32(), 1)
    assert(TypeTable.fn_is_variadic(types, ft) == 1)

fn test_fn_ptr_array:
    // Array of fn pointers: [3]fn(i32)->i32
    var types = TypeTable.new()
    var params = Vec.new()
    params.push(TYPE_I32())
    let fn_type = TypeTable.add_fn(types, params, TYPE_I32(), 0)
    let arr_type = TypeTable.add_array(types, fn_type, 3)
    assert(TypeTable.is_array(types, arr_type))
    assert(TypeTable.array_size(types, arr_type) == 3)
    assert(TypeTable.array_elem_type(types, arr_type) == fn_type)
    assert(TypeTable.is_fn(types, TypeTable.array_elem_type(types, arr_type)))

fn test_fn_ptr_not_copy:
    // fn types are not copy (they're complex types)
    var types = TypeTable.new()
    var params = Vec.new()
    let ft = TypeTable.add_fn(types, params, TYPE_I32(), 0)
    // fn types are not in the copy list
    assert(not TypeTable.is_copy(types, ft))

fn test_fn_ptr_in_struct:
    // Struct with fn pointer field
    var types = TypeTable.new()
    var params = Vec.new()
    params.push(TYPE_I32())
    let fn_type = TypeTable.add_fn(types, params, TYPE_I32(), 0)
    var field_names = Vec.new()
    field_names.push(1)  // "callback"
    var field_types = Vec.new()
    field_types.push(fn_type)
    var field_defaults = Vec.new()
    field_defaults.push(0)
    let st = TypeTable.add_struct(types, 50, field_names, field_types, field_defaults)
    assert(TypeTable.struct_field_count(types, st) == 1)
    assert(TypeTable.struct_field_type(types, st, 0) == fn_type)

fn test_fn_type_equality:
    // Two fn types with same signature should be structurally different
    // (each add_fn creates a new type id)
    var types = TypeTable.new()
    var p1 = Vec.new()
    p1.push(TYPE_I32())
    let ft1 = TypeTable.add_fn(types, p1, TYPE_I32(), 0)
    var p2 = Vec.new()
    p2.push(TYPE_I32())
    let ft2 = TypeTable.add_fn(types, p2, TYPE_I32(), 0)
    // Different TypeIds (structural equality not checked for fn types by types_equal)
    assert(ft1 != ft2)
    // But same kind
    assert(TypeTable.kind(types, ft1) == TypeTable.kind(types, ft2))

fn main:
    test_fn_ptr_basic()
    test_fn_ptr_not_variadic()
    test_fn_ptr_variadic()
    test_fn_ptr_array()
    test_fn_ptr_not_copy()
    test_fn_ptr_in_struct()
    test_fn_type_equality()
    println("ok")
