//! expect-check-fail: expected ':' or '{' to introduce body
// §13.1.1.3: an opaque `dyn Iter[T]` return is rejected; return a concrete
// ephemeral iterator type instead.
fn find(n: i64) -> dyn Iter[i64]:
    todo()
fn main:
    print("no")
