//! expect-check-fail: `List.rest` is a method of a generic type and the type's arguments are missing (§9.3a)

// D223 (§9.3a): a method of a generic type is named through the instance, `List[i32].rest`.
type Bag { n: i32 }
impl Bag:
    fn peek() -> i32: self.n
    fn pick[U](u: U) -> U: u
fn main:
    let f = List.rest
    print(1)
