//! args: --emit-c --overflow=wrap
//! expect-build-fail: C backend is LLVM-only for List.get_disjoint by design

fn main:
    var xs = List.new()
    xs.push(1)
    xs.push(2)
    let _slots = xs.get_disjoint(0, 1)
