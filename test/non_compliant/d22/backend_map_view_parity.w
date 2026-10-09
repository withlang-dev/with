//! D22-NON-COMPLIANT
//! owner-stage: 7
//! required-verdict: native and C-emitted execution both succeed
//! exact-type: `get` yields `Option[&List[i64]]`; `remove` yields `Option[List[i64]]`
//! expected-diagnostic: none in either backend
//! origin-set: `view` has `{map}`; `owned` has `{}`
//! drop-behavior: lookup creates no owner; remove transfers one owner; all buffers and map storage drop once

use std.collections.HashMap
fn main:
    var map: HashMap[i32, List[i64]] = HashMap.new()
    let stored: List[i64] = List.new()
    stored.push(118)
    map.insert(1, move stored)
    let view: &List[i64] = map.get(1).unwrap()
    assert(view[0] == 118)
    let owned: List[i64] = map.remove(1).unwrap()
    assert(owned[0] == 118)
