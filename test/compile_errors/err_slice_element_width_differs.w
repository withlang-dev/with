//! expect-check-fail: wrong argument type in call to 'head'

// §4.2.6: a slice views its elements in place and cannot convert them, as
// a reference cannot convert its pointee. An `[]i64` accepted as `[]i32`
// read the low half of each element (`head` printed 5 for 5 + 7).
fn head(xs: []i32) -> i32: xs[0] + xs[1]

fn main:
    let wide: List[i64] = [5, 7]
    print(head(wide[0..2]))
