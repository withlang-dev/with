//! expect-stdout: dot 10 36 3
//! expect-stdout: first 7 9

// §4.3d (D78, #1874): generic code spells the parameterized form, and the
// lane count is inferred from the arguments — the spec's own `dot`.
fn dot[N](a: Vector[f32, N], b: Vector[f32, N]) -> f32: (a * b).reduce_add()

fn first[N, T](v: Vector[T, N]) -> T: v[0]

fn main:
    let four = dot(f32x4(1, 2, 3, 4), f32x4(1, 1, 1, 1))
    let eight = dot(f32x8(1, 2, 3, 4, 5, 6, 7, 8), f32x8.splat(1))
    let three = dot(Vector[f32, 3](1, 1, 1), Vector[f32, 3](1, 1, 1))
    print(f"dot {four as i32} {eight as i32} {three as i32}")
    print(f"first {first(i32x4(7, 8, 9, 10))} {first(Vector[i64, 3](9, 8, 7))}")
