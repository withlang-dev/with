//! expect-error: writing one is not specified

// §4.3d (D80, #1874): `m[i]` reads a mask lane as a bool; the spec does
// not define writing one, so the compiler refuses it.
fn main:
    var m = m32x4.splat(false)
    m[1] = true
    print(f"{m[1]}")
