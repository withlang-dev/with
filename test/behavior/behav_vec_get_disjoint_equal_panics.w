//! skip-windows: issue #797: panic exits 1 not 134 on native Windows
//! expect-exit: 134
//! expect-stderr: Vec.get_disjoint requires distinct in-bounds indices

fn main:
    var xs = Vec.new()
    xs.push(1)
    let _slots = xs.get_disjoint(0, 0)
