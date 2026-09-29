//! expect-error: lane index 4 is out of range for i32x4

// §4.3d (D78, #1874): a constant lane index is checked at compile time.
fn main:
    let v = i32x4(1, 2, 3, 4)
    print(f"{v[4]}")
