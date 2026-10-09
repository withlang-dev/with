//! expect-check-fail: view `h` may originate from `n`, which no longer lives here

// #1783 (§21.1 rule 6): a `move fn` owns its receiver; the view stored into
// it travels with the returned value to the caller's binding.
type Holder = ephemeral { v: List[&i32] }
impl Holder:
    move fn with(x: &i32) -> Holder:
        var s = self
        s.v.push(x)
        s
fn main:
    var h = Holder { v: List.new() }
    if true:
        let n = 5
        h = h.with(&n)
    print(h.v[0])
