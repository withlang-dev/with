//! expect-stdout: 2 4 8 16 | 64 32 16 8

// §4.2.4 lists `<<` and `>>` among the bitwise operators, and §4.3d (D80)
// broadcasts a scalar on either side of a lane-wise operator: `2 << v`
// shifts the broadcast 2 by each lane of v.
fn main:
    let v = u32x4(0, 1, 2, 3)
    let left = 2 << v
    let base: u32 = 64
    let right = base >> v
    print(f"{left[0]} {left[1]} {left[2]} {left[3]} | {right[0]} {right[1]} {right[2]} {right[3]}")
