//! expect-stdout: ok

// #652: an unannotated trait-impl method whose inferred return matches the
// trait's explicit return type must be accepted, not rejected against the
// signature's placeholder void.
trait Bar:
    fn val(self: &Self) -> i32

type D { m: i32 }

impl Bar for D:
    fn val(self: &Self): self.m

fn main:
    let d = D { m: 9 }
    assert(d.val() == 9)
    print("ok")
