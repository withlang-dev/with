//! expect-check-fail: shadowing is not allowed for 'x'

// D220 (§29.8): the read ends the old binding on every later iteration, so
// this is not an accumulator and is refused.
fn main:
    let x = 1
    for i in 0..3:
        let x = x + 1
        print(x)
