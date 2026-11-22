//! expect-stdout: 5 0 9000000000

// D114 (§4.2.1): an untyped literal arm beside a view of a number takes the
// number's type (`if ok: xs[i] else: 0` of an `&i32` is i32), as it does
// beside the number itself; it is neither the isize default nor a promotion.
fn take(x: i32): x

fn main:
    let xs: List[i32] = [4, 5]
    let wide: List[i64] = [9000000000]
    let i = 1
    let hit = if i < xs.len(): xs[i] else: 0
    let miss = if i > xs.len(): xs[i] else: 0
    let big = if wide.len() > 0: wide[0] else: 0
    let big_i64: i64 = big
    print(f"{take(hit)} {take(miss)} {big_i64}")
