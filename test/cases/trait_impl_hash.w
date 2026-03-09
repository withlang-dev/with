//! expect-stdout: ok

// Test: prelude-provided Hash trait impls for i32, i64, bool.

fn main:
    let a: i32 = 42
    let h1 = a.hash_value()
    let h2 = a.hash_value()
    assert(h1 == h2)

    let b: i32 = 43
    assert(a.hash_value() != b.hash_value())

    let c: i64 = 100
    assert(c.hash_value() != 0)

    let t = true
    let f = false
    assert(t.hash_value() == 1)
    assert(f.hash_value() == 0)

    let s1 = "hello"
    let s2 = "hello"
    let s3 = "world"
    assert(s1.hash_value() == s2.hash_value())
    assert(s1.hash_value() != s3.hash_value())

    println("ok")
