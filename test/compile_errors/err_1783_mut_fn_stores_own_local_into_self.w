//! expect-check-fail: this call stores a view of `n` into `self`, and `self` outlives this call: `n` does not live past this call

// #1783 (§21.1): the receiver is the caller's place (D21) and outlives the
// call; a view of the method's own local stored into it would dangle the
// moment the method returns.
type Holder = ephemeral { v: List[&i32] }
impl Holder:
    mut fn bad():
        let n = 5
        self.v.push(&n)
fn main:
    var h = Holder { v: List.new() }
    h.bad()
    print(h.v[0])
