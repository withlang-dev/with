//! expect-check-fail: view `h` may originate from `n`, which no longer lives here

// #1783: `keep2` stores through `keep`; the store-in-receiver summary
// follows the call chain (keep is checked before keep2, keep2 before main).
type Holder = ephemeral { v: List[&i32] }
impl Holder:
    mut fn keep(x: &i32): self.v.push(x)
    mut fn keep2(x: &i32): self.keep(x)
fn main:
    var h = Holder { v: List.new() }
    if true:
        let n = 5
        h.keep2(&n)
    print(h.v[0])
