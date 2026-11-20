//! expect-check-fail: `List[i32]` has no method `map` (§9.3a)

// D223: a type has no fields to read; a name it does not have is refused as a method.
fn main:
    let m = List[i32].map
    print(1)
