//! expect-error: `!=` on `P` is refused: it holds `f32x4`, whose `==` is lane-wise and yields a mask, not one `bool` (§4.3d); compare that part with `(a == b).all()`

// #1995: the same for a record field, through an array.

type P { tag: i32, lanes: [Vector[4, f32]; 2] }

fn main:
    let a = P { tag: 1, lanes: [Vector[4, f32].splat(1), Vector[4, f32].splat(2)] }
    let b = P { tag: 1, lanes: [Vector[4, f32].splat(1), Vector[4, f32].splat(2)] }
    print(f"{a != b}")
