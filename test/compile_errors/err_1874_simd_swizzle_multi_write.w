//! expect-error: a multi-lane swizzle is read, not assigned

// §4.3d (D78, #1874): a single component is a lane and is written like
// one; a multi-lane swizzle write is not specified.
fn main:
    var v = f32x4(1, 2, 3, 4)
    v.xy = f32x2_of(v)
    print(f"{v[0]}")

fn f32x2_of(v: f32x4) -> Vector[2, f32]: v.zw
