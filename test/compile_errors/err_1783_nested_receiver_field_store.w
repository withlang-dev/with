//! expect-check-fail: view `h` may originate from `n`, which no longer lives here

// #1783: the storage is what the receiver path's ROOT reaches, whatever the
// spelling — `self.inner.v.push(x)` stores into the caller's `h`.
type Inner = ephemeral { v: Vec[&i32] }
type Holder = ephemeral { inner: Inner }
impl Holder:
    mut fn keep(x: &i32): self.inner.v.push(x)
fn main:
    var h = Holder { inner: Inner { v: Vec.new() } }
    if true:
        let n = 5
        h.keep(&n)
    print(h.inner.v[0])
