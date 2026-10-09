//! expect-debug-alloc: leak count=0

use std.collections.HashSet
fn main:
    var set: HashSet[List[i64]] = HashSet.new()
    let values: List[i64] = List.new()
    values.push(7)
    values.push(9)
    set.insert(move values)
    assert(set.len() == 1)
