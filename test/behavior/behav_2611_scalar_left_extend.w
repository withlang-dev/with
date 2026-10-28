//! expect-stdout: 20 -8 0.2 8 12 3 true
// D166 (§11.7): a scalar on the left is the scalar's operator, written
// the way Scala writes it, as an extension method of the scalar's type
// (`extend f64:`, §9.5). `V.sub` serves `a - 2.0`; `extend f64` serves
// `2.0 - a`; each runs its own order. Primitive beside primitive stays
// builtin arithmetic.
type V { x: f64 }

impl V:
    fn sub(self: &Self, rhs: f64) -> V: V { x: self.x - rhs }

extend f64:
    fn mul(self: &Self, v: &V) -> V: V { x: *self * v.x }
    fn sub(self: &Self, v: &V) -> V: V { x: *self - v.x }
    fn div(self: &Self, v: &V) -> V: V { x: *self / v.x }

fn main:
    let a = V { x: 10.0 }
    let k: f64 = 2.0
    let scaled = 2.0 * a
    let left = 2.0 - a
    let ratio = k / a
    let right = a - 2.0
    print(f"{scaled.x} {left.x} {ratio.x} {right.x} {7 + 5} {1.5 * 2.0} {1 == 1}")
