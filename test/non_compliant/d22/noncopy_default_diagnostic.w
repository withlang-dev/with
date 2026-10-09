//! D22-NON-COMPLIANT
//! owner-stage: 8
//! required-verdict: check-fail at the `??` join
//! exact-type: success is `&List[i64]`; default is owned `List[i64]`
//! expected-diagnostic: `??` would need to copy a non-Copy List; offer only applicable `.cloned()`, borrowed-default, or `remove` remedies
//! origin-set: no result is formed; success would have `{jobs}`
//! drop-behavior: rejection precedes codegen; both map and default retain ownership

use std.collections.HashMap
fn main:
    var jobs: HashMap[i32, List[i64]] = HashMap.new()
    let stored: List[i64] = List.new()
    stored.push(54)
    jobs.insert(1, move stored)

    // Must explain that ?? would need to copy a non-Copy List, then offer
    // .cloned(), a borrowed default, or remove only when each is applicable.
    let owned = jobs.get(1) ?? List.new()
    assert(owned.len() == 1)
