//! expect-check-fail: returned view may outlive its origin 'xs'

// #3360 (§21.1): an inherited default method's returned tail is checked as
// any function's. `xs` is the method's own: it drops when the body ends, so
// a view of its element cannot be returned. The default body's own smaller
// check had no origin rule and accepted it.
trait Pick:
    fn tag(self: &Self) -> i32
    fn first(self: &Self, xs: List[str]) -> &str:
        xs[0]

type S { t: i32 }
impl Pick for S:
    fn tag(self: &Self) -> i32: self.t

fn main:
    let s = S { t: 1 }
    print(s.first(["a", "b"]))
