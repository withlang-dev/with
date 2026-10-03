//! expect-error: `==` on `(i8, f32x8)` is refused: it holds `f32x8`, whose `==` is lane-wise and yields a mask, not one `bool` (§4.3d); compare that part with `(a == b).all()`

// #1995 (§4.3d, §11.7): `==` on a vector is lane-wise and yields a Mask;
// `==` on an aggregate is one `bool` (`eq(...) -> bool`). An aggregate
// holding a vector has no structural equality: "all lanes equal" is one
// reading among two, which §4.3d refuses to pick for a mask (`m == n`).
// Before, Sema accepted it and codegen emitted `icmp eq <8 x float>`.

type V8 = Vector[8, f32]

fn main:
    let w: (i8, V8) = (1, V8.splat(1))
    let ww = w
    print(f"{ww == w}")
