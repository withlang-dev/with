//! expect-stdout: 42 1 9

// D140: a method in an impl of a trait may omit its parameter and return
// types; they are the trait's declaration, instantiated for the impl.
pub trait Scale:
    fn scale(self: &Self, k: i32) -> i32

// `unit`, not `one`: std.traits implements `One.one` for f64, and two traits' methods of one
// name on one type collide on the `f64.one` symbol (#2520).
pub trait Unit1:
    fn unit() -> Self

pub trait Pair:
    fn pair(self: &Self, a: i32, b: i32) -> i32

type P { v: i32 }

impl Scale for P: fn scale(k): self.v * k
impl Unit1 for f64: fn unit(): 1.0
impl Pair for P: fn pair(a, b): self.v + a + b

fn main:
    let p = P { v: 6 }
    print(f"{p.scale(7)} {f64.unit()} {p.pair(1, 2)}")
