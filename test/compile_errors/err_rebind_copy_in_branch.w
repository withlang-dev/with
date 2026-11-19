//! expect-check-fail: shadowing is not allowed for 'x'

// D220 (§29.8): the old `x` would come back after the block, which is
// shadowing.
fn main:
    let c = true
    let x = 1
    if c:
        let x = x + 1
        print(x)
    print(x)
