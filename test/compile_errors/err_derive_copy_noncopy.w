//! expect-check-fail: cannot derive Copy for a type with non-Copy fields
// D120: a struct of values is a value; this one is declared a resource
// so it still moves and still takes no copy.
resource type NonCopy { s: str }
@[derive(Copy)]
type Bad { n: NonCopy }
fn main:
    print("no")
