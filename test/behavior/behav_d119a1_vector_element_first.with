//! expect-stdout: 30 30
//! expect-stdout: 5 16 16
//! expect-stdout: generic 10 55

// D119 Amendment 1 (§4.3d): `Vector[T, N]` — the element first, then its
// count, the same order as `[T; N]` (§4.3a). The aliases are unchanged, and
// a generic binds T from the argument's lane type and N from its lane count
// by the same mechanism, whatever their spelling order.

fn dot[N](a: Vector[f32, N], b: Vector[f32, N]) -> f32:
    (a * b).reduce_add()

fn sum[T](v: Vector[T, 4]) -> T: v.reduce_add()

fn main:
    let x = f32x4(1, 2, 3, 4)
    let y = Vector[f32, 4](1, 2, 3, 4)
    print(f"{dot(x, x) as i32} {dot(y, y) as i32}")
    print(f"{Vector[i32, 3](5, 6, 7)[0]} {size_of[Vector[f32, 3]]()} {align_of[Vector[f32, 3]]()}")
    print(f"generic {sum(i32x4(1, 2, 3, 4))} {sum(i32x4(10, 20, 30, 40)) - 45}")
