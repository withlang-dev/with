//! expect-debug-alloc: leak count=0
// D22 acceptance cell, promoted 2026-10-18. D22 nullable view carriers must preserve Option predicate polarity.

use std.collections.HashMap
fn main:
    var map: HashMap[i32, i32] = HashMap.new()
    map.insert(1, 7)

    let present: Option[&i32] = map.get(1)
    assert(present.is_some())
    assert(not present.is_none())

    let missing: Option[&i32] = map.get(2)
    assert(missing.is_none())
    assert(not missing.is_some())

    assert(map.get(2).is_none())
    assert(not map.get(1).is_none())
    assert(map.get(1).is_some())
    assert(not map.get(2).is_some())

    var wide: HashMap[i32, i64] = HashMap.new()
    wide.insert(1, 9)
    assert(wide.get(2).is_none())
    assert(not wide.get(1).is_none())
