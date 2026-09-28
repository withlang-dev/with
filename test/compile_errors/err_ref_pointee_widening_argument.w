//! expect-check-fail: wrong argument type in call to 'show'
// §4.2.6 converts values, not the place a reference views: `&i32` where
// `&i64` is expected read eight bytes of a four-byte local.
fn show(r: &i64): print(f"{r}")

fn main:
    let z: i32 = -5
    show(&z)
