//! expect-check-fail: parameter 1 is taken as `&Bag` (observes) by the function and as `Bag` (takes) by the type wanted; the two modes do not convert (§3.8a). Write the closure: `(x) => x.peek()`

// D223 (§9.3a): a mode mismatch names both modes and the closure, not only the two types.
type Bag { n: i32 }
impl Bag:
    fn peek() -> i32: self.n
    fn pick[U](u: U) -> U: u
fn takes(f: fn(Bag) -> i32, b: Bag) -> i32: f(b)
fn main: print(takes(Bag.peek, Bag { n: 1 }))
