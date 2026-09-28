//! expect-check-fail: view `h` may originate from `n`, which no longer lives here

// #1783 (§21.1 rule 6, §3.8): `h.keep(n)` auto-references `n` for the `&i32`
// parameter, and `keep` stores that view into the receiver — the same store
// as `h.keep(&n)`.
type Holder = ephemeral { v: Vec[&i32] }
impl Holder:
    mut fn keep(x: &i32): self.v.push(x)
fn main:
    var h = Holder { v: Vec.new() }
    if true:
        let n = 5
        h.keep(n)
    print(h.v[0])
