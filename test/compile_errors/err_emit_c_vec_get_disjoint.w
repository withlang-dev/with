//! args: --emit-c --overflow=wrap
//! expect-build-fail: C backend is LLVM-only for Vec.get_disjoint by design

fn main:
    var xs = Vec.new()
    xs.push(1)
    xs.push(2)
    let _slots = xs.get_disjoint(0, 1)
