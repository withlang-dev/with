//! expect-check-fail: `List[i32].len` is built into the compiler and is not yet a function value (§9.3a)

// D223 (§9.3a): a method the compiler implements itself has no function to name yet; refused, never guessed.
type Bag { n: i32 }
impl Bag:
    fn peek() -> i32: self.n
    fn pick[U](u: U) -> U: u
fn main:
    let f = List[i32].len
    print(1)
