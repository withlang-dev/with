//! D22-NON-COMPLIANT
//! owner-stage: 5
//! required-verdict: compile-and-run under `--debug-alloc`
//! exact-type: fixed-array `values` and dynamic `collected` are owned sequences of `i32`
//! expected-diagnostic: none
//! origin-set: the owned sequence elements have `{}`
//! drop-behavior: reference arm is copied once; map storage drops once; leak count=0
//! expect-debug-alloc: leak count=0

use std.collections.HashMap
fn main:
    var map: HashMap[i32, i32] = HashMap.new()
    map.insert(1, 65)
    let values = [map.get(1).unwrap(), 66]
    let collected: List[i32] = [map.get(1).unwrap(), 67]
    map.clear()
    assert(values[0] == 65)
    assert(values[1] == 66)
    assert(collected[0] == 65)
    assert(collected[1] == 67)
