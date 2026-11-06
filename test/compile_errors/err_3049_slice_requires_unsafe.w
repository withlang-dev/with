//! expect-check-fail: unsafe

// #3049 (§16.11): `slice(p, len)` requires an `unsafe` context.

fn main:
    var buf: [i32; 2] = [1, 2]
    let p = &raw const buf[0]
    let s = slice(p, 2)
    print(s.len())
