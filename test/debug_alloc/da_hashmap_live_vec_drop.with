//! expect-debug-alloc: leak count=0

use std.collections.HashMap
fn main:
    var map: HashMap[i32, List[i64]] = HashMap.new()
    let values: List[i64] = List.new()
    values.push(7)
    values.push(9)
    map.insert(1, move values)
    assert(map.len() == 1)
