//! expect-check-fail: view `h` may originate from `n`, which no longer lives here

// #1783 (§21.1 rule 6): `h.v.push(&n)` stores into `h` exactly as
// `v.push(&n)` stores into `v`; the receiver's spelling never decided it.
type Holder = ephemeral { v: Vec[&i32] }
fn main:
    var h = Holder { v: Vec.new() }
    if true:
        let n = 5
        h.v.push(&n)
    print(h.v[0])
