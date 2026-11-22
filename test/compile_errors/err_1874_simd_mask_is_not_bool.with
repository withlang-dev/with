//! expect-error: comparison of vectors yields a mask

// §4.3d (D78, #1874): `==` on vectors is lane-wise and yields a Mask, not
// a bool; `.all()` or `.any()` reduces it.
fn main:
    let a = i32x4(1, 2, 3, 4)
    if a == a:
        print("same")
