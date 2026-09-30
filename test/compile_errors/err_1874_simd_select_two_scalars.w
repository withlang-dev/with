//! expect-error: a scalar operand broadcasts only beside a vector operand

// §4.3d (v7.16): `m.select(a, b)` broadcasts a scalar operand beside a
// vector or where the context gives the vector type; two scalars with no
// such context have no one meaning.
fn main:
    let m = m32x4.splat(true)
    let r = m.select(1, 2)
    print(f"{r[0]}")
