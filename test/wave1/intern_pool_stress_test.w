//! expect-stdout: ok

use compiler.foundation.Ids
use compiler.foundation.InternPool

extern fn int_to_string(n: i32) -> str

fn symbol_name(i: i32) -> str:
    "sym_" ++ int_to_string(i)

fn main:
    var p1 = InternPool.init()
    var p2 = InternPool.init()

    let unique = 6000

    // First pass: force table growth with strictly increasing inserts.
    for i in 0..unique:
        let s = symbol_name(i)
        let a = p1.intern_str(s)
        let b = p2.intern_str(s)
        assert(symbol_raw(a) == i + 1)
        assert(symbol_raw(a) == symbol_raw(b))
        assert(p1.resolve_symbol(a) == s)

    assert(p1.symbol_count() == unique)
    assert(p2.symbol_count() == unique)

    // Second pass: high-volume duplicate storm in deterministic pseudo-random
    // order. IDs must remain stable and equal across both pools.
    for round in 0..4:
        for i in 0..unique:
            let idx = (i * 37 + round * 101) % unique
            let s = symbol_name(idx)
            let a = p1.intern_str(s)
            let b = p2.intern_str(s)
            assert(symbol_raw(a) == idx + 1)
            assert(symbol_raw(a) == symbol_raw(b))
            assert(p1.resolve_symbol(a) == s)

    assert(p1.symbol_count() == unique)
    assert(p2.symbol_count() == unique)

    println("ok")
