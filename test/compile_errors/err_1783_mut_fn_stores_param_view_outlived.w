//! expect-check-fail: view `h` may originate from `n`, which no longer lives here

// #1783 (§21.1 rule 6, D22): `keep` stores a view of its parameter into the
// receiver (`self.v.push(x)`, `self.r = Some(x)`), so the caller's `h` views
// what the argument views. `n` dies with the block; reading `h` after that
// reads a dangling reference and is refused.
type Holder = ephemeral { v: List[&i32], r: Option[&i32] }
impl Holder:
    mut fn keep(x: &i32):
        self.v.push(x)
        self.r = Some(x)
fn main:
    var h = Holder { v: List.new(), r: None }
    if true:
        let n = 5
        h.keep(&n)
    print(h.r.unwrap())
