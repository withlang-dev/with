//! expect-error: lane-wise operator needs vectors of one lane signedness

// §4.3d (D78, #1874): lanes widen per §4.2 only within one signedness;
// i32x4 + u32x4 needs an explicit `as`, as i32 + u32 does.
fn main:
    let a = i32x4(1, 2, 3, 4)
    let b = u32x4(1, 2, 3, 4)
    let c = a + b
    print(f"{c[0]}")
