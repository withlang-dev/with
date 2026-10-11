//! expect-check-fail: no implicit conversion joins them

// D125 (§4.2.1 rule 8): typed arms of a join that disagree are an error; no
// arm's width wins (an i32 arm and an i64 arm do not join at i64).
fn main:
    let a: i32 = 1
    let b: i64 = 2
    let c = true
    let x = if c: a else: b
    print(x)
