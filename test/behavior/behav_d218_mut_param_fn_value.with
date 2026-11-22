//! expect-stdout: 1
//! expect-stdout: 2
//! expect-stdout: 2

// D218 (§3.8a): a function type states the mode. A function with a `mut`
// parameter is a value of type `fn(mut T) -> R`, and a call through the
// value writes the caller's place, as a direct call does. (As a plain
// `fn(T) -> R` value it was called with its argument by value and
// segfaulted, #3453; it was then refused until the type could say `mut`.)
type Bag { n: i32 }

fn bump(mut b: Bag) -> i32:
    b.n += 1
    b.n

fn apply(body: fn(mut Bag) -> i32, mut b: Bag) -> i32: body(b)

fn main:
    var x = Bag { n: 0 }
    let f = bump
    print(f(x))
    print(apply(bump, x))
    print(x.n)
