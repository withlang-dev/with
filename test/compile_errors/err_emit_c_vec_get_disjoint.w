//! args: --emit-c
//! expect-build-fail: C backend does not yet support Vec.get_disjoint

fn main:
    var xs = Vec.new()
    xs.push(1)
    xs.push(2)
    let _slots = xs.get_disjoint(0, 1)
