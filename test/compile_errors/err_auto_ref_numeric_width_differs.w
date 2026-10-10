//! expect-check-fail: wrong argument type in call to 'f'

// §3.8, §4.2.6: an auto-referenced argument is viewed in its own place, so
// its numeric type must be the pointee's. An `i32` place accepted for
// `x: &i64` was read as eight bytes: -1 printed 4294967295.
fn f(x: &i64) -> i64: *x

fn main:
    let a: i32 = -1
    print(f(a))
