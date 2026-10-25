//! expect-error: collect[C]() gathers an iterator, and `List[isize]` is not one
// #2319: collect[C]() over a List resolved to nothing and said nothing;
// MIR then stopped: "BUG: user generic call lacks a concrete contract".
fn main:
    let xs = [1, 2]
    let ys: List[isize] = xs.map(it + 1).collect[List]()
    print(ys.len())
