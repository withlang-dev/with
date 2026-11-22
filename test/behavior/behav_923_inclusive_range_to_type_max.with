//! expect-stdout: 6 6 4 2 6 6
// #923: `a..=b` ends at b; stepping past it would overflow when b is the
// type's maximum. `for i in (250 as u8)..=hi` (hi = 255) panicked "u8
// addition out of range" after its sixth pass.
fn main:
    let hi: u8 = 255
    var n = 0
    for i in (250 as u8)..=hi: n = n + 1
    let r = (250 as u8)..=hi
    var m = 0
    for i in r: m = m + 1
    var k = 0
    for i in 0..=3: k = k + 1
    let top: i64 = 9223372036854775807
    var w = 0
    for i in (top - 1)..=top: w = w + 1
    let xs: List[u8] = [i for i in (250 as u8)..=hi]
    let r2 = (250 as u8)..=hi
    let ys: List[u8] = [i for i in r2]
    print(f"{n} {m} {k} {w} {xs.len()} {ys.len()}")
