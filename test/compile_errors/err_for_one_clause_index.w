//! expect-error: a `for` over an Option or Result is a one-clause comprehension (§13.6a), which binds no index

// §13.6a: a comprehension clause is not a loop; it has no index to bind.
fn main:
    let o: Option[i32] = Some(3)
    for x, i in o:
        print(f"{x} {i}")
