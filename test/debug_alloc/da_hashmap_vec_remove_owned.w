//! expect-debug-alloc: leak count=0

use std.collections.HashMap
fn main:
    var map: HashMap[i32, List[i64]] = HashMap.new()
    let values: List[i64] = List.new()
    values.push(7)
    values.push(9)
    map.insert(1, move values)
    let removed: Option[List[i64]] = map.remove(1)
    let owned = removed.unwrap()
    assert(owned.len() == 2)
