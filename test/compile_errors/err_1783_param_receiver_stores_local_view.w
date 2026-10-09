//! expect-check-fail: returned ephemeral value may outlive its origin 'n'

// #1783: a store through a method into an owned parameter's field, then the
// parameter returned: the view of the local `n` would leave `fill`.
type Holder = ephemeral { v: List[&i32] }
impl Holder:
    mut fn keep(x: &i32): self.v.push(x)
type Outer = ephemeral { h: Holder }
fn fill(o: Outer) -> Outer:
    var out = o
    let n = 5
    out.h.keep(&n)
    out
fn main:
    let o = fill(Outer { h: Holder { v: List.new() } })
    print(o.h.v[0])
