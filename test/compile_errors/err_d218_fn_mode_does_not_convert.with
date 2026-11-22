//! expect-check-fail: type mismatch in binding

// D218 (§3.8a): `fn(mut T) -> R` and `fn(T) -> R` are different types and
// neither converts to the other.
type Bag { n: i32 }
fn plain(b: Bag) -> i32: b.n
fn bump(mut b: Bag) -> i32: b.n

fn main:
    let wrong: fn(mut Bag) -> i32 = plain
    let also: fn(Bag) -> i32 = bump
    print(1)
