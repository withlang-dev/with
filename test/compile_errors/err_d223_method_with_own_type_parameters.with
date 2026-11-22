//! expect-check-fail: `Bag.pick` has type parameters of its own, so it names no one function (§9.3a)

// D223 (§9.3a): a method with type parameters of its own has no one instance to name.
type Bag { n: i32 }
impl Bag:
    fn peek() -> i32: self.n
    fn pick[U](u: U) -> U: u
fn main:
    let f = Bag.pick
    print(1)
