//! expect-stdout: ok

use InternPool

fn main:
    var pool = InternPool.new()
    let a = InternPool.intern(pool, "hello")
    let b = InternPool.intern(pool, "world")
    let c = InternPool.intern(pool, "hello")

    // Same string returns same symbol
    assert(a == c)
    // Different strings return different symbols
    assert(a != b)
    // IDs are sequential from 0
    assert(a == 0)
    assert(b == 1)

    // Resolve returns original string
    let s = InternPool.resolve(pool, a)
    assert(s == "hello")
    let s2 = InternPool.resolve(pool, b)
    assert(s2 == "world")

    println("ok")
