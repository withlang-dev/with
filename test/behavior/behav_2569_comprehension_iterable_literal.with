//! expect-stdout: 3 16 3

// #2569: a binding's collection demand is the comprehension's, not its
// iterable's: the sequence literal in `for k in [4, 2, 3]` is a List.
use std.collections.BTreeMap
use std.collections.BTreeSet
use std.collections.HashMap
fn main:
    let squares: BTreeMap[i32, i32] = [k: k * k for k in [4, 2, 3]]
    let evens: BTreeSet[i32] = [x for x in [8, 2, 6, 2]]
    let named: HashMap[str, i32] = [s: s.len() as i32 for s in ["ab", "cde"]]
    print(f"{squares.len()} {squares.get(4) ?? 0} {evens.len()}")
    if named.len() != 2: print("bad")
