//! expect-error: `Vector[T, N]` writes the element first and its count second

// D119 Amendment 1 (§4.3d): the retired `Vector[N, T]` spelling is refused
// by naming the order, not by calling the lane type a bad lane count.

fn f(v: Vector[4, f32]) -> f32: v[0]

fn main:
    print(f(f32x4(1, 2, 3, 4)))
