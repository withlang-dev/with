//! expect-check-fail: type mismatch in binding
// A reference cannot convert its pointee (§4.2.6): `&u32` viewed as `&i32`
// would reread the bits with the other sign.
fn main:
    let big: u32 = 4000000000
    let r: &i32 = &big
    print(f"{r}")
