//! expect-stdout: ok

use compiler.foundation.Ids

fn main:
    let f_bad = file_id_invalid()
    assert(not file_id_is_valid(f_bad))

    let f = file_id_from_raw(7)
    assert(file_id_is_valid(f))
    assert(file_id_raw(f) == 7)

    let m = module_id_from_raw(11)
    assert(module_id_raw(m) == 11)
    assert(module_id_is_valid(m))

    let d = def_id_from_raw(21)
    let i = item_id_from_raw(22)
    let t = type_id_from_raw(23)
    let v = value_id_from_raw(24)
    let s = symbol_from_raw(25)
    let a = arena_id_from_raw(26)

    assert(def_id_raw(d) == 21)
    assert(item_id_raw(i) == 22)
    assert(type_id_raw(t) == 23)
    assert(value_id_raw(v) == 24)
    assert(symbol_raw(s) == 25)
    assert(arena_id_raw(a) == 26)

    assert(def_id_is_valid(d))
    assert(item_id_is_valid(i))
    assert(type_id_is_valid(t))
    assert(value_id_is_valid(v))
    assert(symbol_is_valid(s))
    assert(arena_id_is_valid(a))

    println("ok")
