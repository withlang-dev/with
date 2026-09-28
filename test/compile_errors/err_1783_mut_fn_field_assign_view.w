//! expect-check-fail: view `h` may originate from `n`, which no longer lives here

// #1783 (§21.1 rule 6): a field assignment inside the method (`self.r = x`)
// is a store into the receiver as much as a push is.
type Holder = ephemeral { r: &i32 }
impl Holder:
    mut fn set(x: &i32): self.r = x
fn main:
    let z = 0
    var h = Holder { r: &z }
    if true:
        let n = 5
        h.set(&n)
    print(h.r)
