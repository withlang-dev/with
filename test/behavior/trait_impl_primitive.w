//! expect-stdout: ok

// Test: prelude-provided trait impls for primitive types (i32, bool).
// Eq and Default impls come from lib/std/traits.w via prelude.

fn main:
    let a: i32 = 42
    let b: i32 = 42
    let c: i32 = 7
    assert(a.eq(b))
    assert(not a.eq(c))
    let d = i32.default()
    assert(d == 0)
    let t = true
    let f = false
    assert(t.eq(true))
    assert(not t.eq(f))
    let df = bool.default()
    assert(not df)
    print("ok")
