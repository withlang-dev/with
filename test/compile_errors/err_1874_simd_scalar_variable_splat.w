//! expect-error: f32x4.splat(s)

// §4.3d (D78, #1874): a scalar variable bound alone as a vector is refused;
// the broadcast is spelled, because a type mistake there would silently
// become one.
fn main:
    let s: f32 = 1.5
    let v: f32x4 = s
    print(f"{v[0]}")
