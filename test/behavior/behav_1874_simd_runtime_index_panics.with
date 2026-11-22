//! expect-exit: 134
//! expect-stderr: index out of bounds

// §4.3d (D78, #1874): a runtime lane index follows §4.3a's array rule and
// panics out of range.
fn lane(v: f32x4, i: i32) -> f32: v[i]

fn main:
    let v = f32x4(1, 2, 3, 4)
    print(f"{lane(v, 4)}")
