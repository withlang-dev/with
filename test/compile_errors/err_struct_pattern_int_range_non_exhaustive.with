//! expect-check-fail: non-exhaustive match on 'B': `B { b: 255 }` is not covered

// #1388 (§9.7): a u8 field matched by `0..=254` leaves 255 uncovered.

type B { b: u8 }

fn f(v: B) -> i32:
    match v:
        B { b: 0..=254 } => 1

fn main:
    print(f(B { b: 1 }))
