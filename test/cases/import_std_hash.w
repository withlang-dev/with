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
    0
