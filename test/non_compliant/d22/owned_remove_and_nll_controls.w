//! D22-NON-COMPLIANT
//! owner-stage: 6
//! required-verdict: compile-and-run
//! exact-type: `view` is `&List[i64]`; `owned` is `List[i64]`
//! expected-diagnostic: none; mutation follows the view's final use
//! origin-set: `view` has `{map}` until its final use; `owned` has `{}`
//! drop-behavior: clear drops the first List; remove transfers the replacement; each buffer drops exactly once

use std.collections.HashMap
fn main:
    var map: HashMap[i32, List[i64]] = HashMap.new()
    let values: List[i64] = List.new()
    values.push(47)
    map.insert(1, move values)

    let view = map.get(1).unwrap()
    assert(view.len() == 1)  // last use: the borrow ends here
    map.clear()              // legal after the last view use

    let replacement: List[i64] = List.new()
    replacement.push(48)
    map.insert(1, move replacement)
    let owned = map.remove(1).unwrap()
    map.clear()
    assert(owned[0] == 48)
