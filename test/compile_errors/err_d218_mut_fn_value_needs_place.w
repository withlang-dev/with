//! expect-check-fail: a `mut` parameter needs a mutable place: `x` is a `let` binding (§3.8a)

// D218: a call through a `fn(mut T) -> R` value follows the direct call's
// rule for its argument.
type Bag { n: i32 }
fn bump(mut b: Bag) -> i32:
    b.n += 1
    b.n

fn main:
    let x = Bag { n: 0 }
    let f = bump
    print(f(x))
