//! expect-error: cannot iterate over `Counter`: its `next()` returns `i32`, not `Option[T]`

// #1828 (§13.2): `for` steps an iterator whose next() returns Option[T].
// A next() returning i32 passed check and the loop printed nothing.
type Counter:
    n: i32

extend Counter:
    mut fn next() -> i32: self.n

fn main:
    let c = Counter { n: 3 }
    for x in c:
        print(f"{x}")
