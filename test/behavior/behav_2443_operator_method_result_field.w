//! expect-stdout: 8
//! expect-stdout: -10

// #2443 (D65): an operator that resolves to a method has the method's
// return type, recorded by Sema like every expression's. Unrecorded, MIR
// fell back to arithmetic over `V` and `f64` for `(a - 2.0)`, typed it
// Unit, and `.x` projected a field out of a scalar (an ICE).
type V { x: f64 }
impl V:
    fn sub(self: &Self, rhs: f64) -> V:
        V { x: self.x - rhs }
    fn neg(self: &Self) -> V:
        V { x: 0.0 - self.x }

fn main:
    let a = V { x: 10.0 }
    let t = (a - 2.0).x
    print(f"{t}")
    print(f"{(-a).x}")
