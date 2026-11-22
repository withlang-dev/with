//! expect-stdout: 5

// #1617: a static `Type.fn` (no self) called through an instance takes no
// receiver argument.
type B { n: i32 }
impl B:
    fn make(p: i32) -> B: B { n: p }
fn main:
    let b = B { n: 1 }
    let c = b.make(5)
    print(c.n)
