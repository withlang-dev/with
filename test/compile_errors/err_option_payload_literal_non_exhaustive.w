//! expect-check-fail: non-exhaustive match on 'Option[i32]': `Some(0)` is not covered

// #1388 (§9.7): `Some(5)` covers one Some, not the variant; the arm list
// used to count as exhaustive and Some(6) took the None arm.

fn g(o: Option[i32]) -> i32:
    match o:
        Some(5) => 1
        None => 2

fn main:
    print(g(Some(6)))
