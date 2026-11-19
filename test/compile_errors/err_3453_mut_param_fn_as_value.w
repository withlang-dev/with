//! expect-check-fail: `bump` takes a `mut` parameter: it is called directly, never used as a value (§3.8a)
//! expect-check-fail: = help: a function type cannot say `mut`, so a call through the value could not pass the caller's place

// #3453: as a `fn(Bag) -> i32` value, `bump` was called with its argument
// by value while its prologue expected the caller's place, and the program
// segfaulted.
type Bag { n: i32 }

fn bump(mut b: Bag) -> i32:
    b.n += 1
    b.n

fn apply(body: fn(Bag) -> i32, b: Bag) -> i32: body(b)

fn main:
    let x = Bag { n: 0 }
    print(apply(bump, x))
