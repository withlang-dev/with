//! expect-error: implicit integer narrowing or sign change from `i64` to `i32`

// §4.2.6 (#1803): `??` joins the payload and the fallback under the
// binding's demand; an i64 payload does not narrow into i32 implicitly.
fn main:
    let found: Option[i64] = Some(5000000000)
    let x: i32 = found ?? 0
    print(f"{x}")
