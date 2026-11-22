//! expect-error: short-circuits

// §4.3d (D80, #1874): `and` and `or` are refused on a mask — they
// short-circuit, and lanes cannot; `&` and `|` combine masks.
fn main:
    let v = i32x4(1, 2, 3, 4)
    let m = (v > 1) and (v < 4)
    print(f"{m.any()}")
