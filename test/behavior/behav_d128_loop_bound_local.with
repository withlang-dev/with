//! expect-stdout: 5
//! expect-stdout: 1

// D128 (§4.2.1): a loop over a range whose bound is a literal-typed local
// (`let unique = 6000; for i in 0..unique`) is a loop over a literal
// range: a demand on the loop variable decides the bound's local too, so
// `narrow(i)` makes `i` and `unique` both i32 and nothing is cast.

fn narrow(i: i32) -> i32: i + 1

fn main:
    let unique = 5
    var total = 0
    for i in 0..unique: total = narrow(i)
    print(total)
    let lo = 1
    let hi = lo + 3
    var n = 0
    for j in lo..hi: n = narrow(j) - j
    print(n)
