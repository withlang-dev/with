//! expect-check-fail: `b.peek` without a call is not a value (§9.3a)

// D223 (§9.3a): the bound form is refused in every receiver mode; the closure says it.
type Bag { n: i32 }
impl Bag:
    fn peek() -> i32: self.n
    fn pick[U](u: U) -> U: u
fn main:
    let b = Bag { n: 1 }
    let f = b.peek
    print(1)
