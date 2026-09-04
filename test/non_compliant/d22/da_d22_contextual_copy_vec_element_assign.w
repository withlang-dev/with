//! D22-NON-COMPLIANT
//! owner-stage: 6
//! required-verdict: compile-and-run under `--debug-alloc`
//! exact-type: inferred `view` remains `&i32`; the element assignment `slots[0] = view` establishes an owned `i32` demand for its value (the retired `Vec.set_i32` intrinsic did the same, #1007)
//! expected-diagnostic: none
//! origin-set: `view` has `{map}`; the value stored in `slots` has `{}`
//! drop-behavior: the pointee is copied once into `slots`; both containers drop once; leak count=0
//! expect-debug-alloc: leak count=0

use std.collections.HashMap
fn main:
    var map: HashMap[i32, i32] = HashMap.new()
    map.insert(1, 41)

    var slots: Vec[i32] = Vec.new()
    slots.push(0)

    let view = map.get(1).unwrap()
    slots[0] = view
    map.clear()

    assert(slots.get(0) == 41)
