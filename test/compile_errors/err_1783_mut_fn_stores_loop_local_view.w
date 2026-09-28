//! expect-check-fail: view `h` may originate from `n`, which no longer lives here

// #1783 (§21.1 rule 6): the loop local `n` dies every iteration; the views
// `keep` stored into `h` outlive it, so `h` may not be read afterwards.
type Holder = ephemeral { v: Vec[&i32] }
impl Holder:
    mut fn keep(x: &i32): self.v.push(x)
fn main:
    var h = Holder { v: Vec.new() }
    for i in 0..3:
        let n = i * 10
        h.keep(&n)
    for k in 0..3: print(h.v[k])
