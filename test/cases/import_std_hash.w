// Test: std.hash import
use std.hash

fn main() -> i32 =
    let a = hash_i64(42)
    let b = hash_i64(42)
    let c = hash_i64(43)
    assert(a == b)
    assert(a != c)

    let p1 = hash_pair(1, 2)
    let p2 = hash_pair(2, 1)
    assert(p1 != p2)

    let s1 = hash_str("abc")
    let s2 = hash_str("abc")
    let s3 = hash_str("abd")
    assert(s1 == s2)
    assert(s1 != s3)

    var h1 = hasher()
    h1.update_i64(10)
    h1.update_str("abc")
    let hv1 = h1.finish()

    var h2 = default_hasher()
    h2.update_i64(10)
    h2.update_str("abc")
    let hv2 = h2.finish()
    assert(hv1 == hv2)

    var h3 = hasher()
    h3.update_str("abc")
    h3.update_i64(10)
    let hv3 = h3.finish()
    assert(hv1 != hv3)
    0
