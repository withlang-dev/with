//! expect-check-fail: view `h` may originate from `n`, which no longer lives here

// #1783 (§21.1 rule 6): `h.v.push(n)` auto-references `n` into a
// `Vec[&i32]` — the argument's own type is `i32`, the slot's is `&i32`,
// and the slot decides that a view is stored.
type H = ephemeral { v: Vec[&i32] }
fn main:
    var h = H { v: Vec.new() }
    if true:
        let n = 5
        h.v.push(n)
    print(h.v.len32())
