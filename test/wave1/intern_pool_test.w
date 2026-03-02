//! expect-stdout: ok

use compiler.foundation.Ids
use compiler.foundation.Types
use compiler.foundation.Values
use compiler.foundation.InternPool

fn main:
    var p = InternPool.init()

    // String/symbol interning.
    let s0 = p.intern_str("alpha")
    let s1 = p.intern_str("beta")
    let s2 = p.intern_str("alpha")
    assert(symbol_raw(s0) == symbol_raw(s2))
    assert(symbol_raw(s0) != symbol_raw(s1))
    assert(p.resolve_symbol(s0) == "alpha")
    assert(p.resolve_symbol(s1) == "beta")
    assert(p.symbol_count() == 2)

    // Type interning.
    let ty_i32 = p.intern_type(type_key_named("i32"))
    let ty_i32_2 = p.intern_type(type_key_named("i32"))
    assert(type_id_raw(ty_i32) == type_id_raw(ty_i32_2))

    let ty_ptr = p.intern_type(type_key_ptr(ty_i32, false))
    let ty_ptr_mut = p.intern_type(type_key_ptr(ty_i32, true))
    assert(type_id_raw(ty_ptr) != type_id_raw(ty_ptr_mut))

    let k = p.resolve_type(ty_ptr)
    assert(k.tag == TYPE_KEY_PTR())
    assert(k.arg0 == type_id_raw(ty_i32))
    assert(k.flags == 0)
    assert(p.type_count() == 3)

    // Value interning.
    let v0 = p.intern_value(value_key_int(5))
    let v1 = p.intern_value(value_key_int(5))
    let v2 = p.intern_value(value_key_bool(true))
    let v3 = p.intern_value(value_key_string("hello"))
    let v4 = p.intern_value(value_key_type_marker(ty_i32))
    assert(value_id_raw(v0) == value_id_raw(v1))
    assert(value_id_raw(v0) != value_id_raw(v2))
    assert(value_id_raw(v2) != value_id_raw(v3))
    assert(value_id_raw(v3) != value_id_raw(v4))

    let rv = p.resolve_value(v3)
    assert(rv.tag == VALUE_KEY_STRING())
    assert(rv.text_value == "hello")
    assert(p.value_count() == 4)

    println("ok")
