//! expect-check-fail: view may outlive its origin 'n', which is dropped at the end of this block

// #1783 (§21.1 rule 6): `h.r = &n` stores a view of `n` into `h`.
type H = ephemeral { r: &i32 }
fn main:
    let z = 0
    var h = H { r: &z }
    if true:
        let n = 5
        h.r = &n
    print(h.r)
