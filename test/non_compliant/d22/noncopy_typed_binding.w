//! D22-NON-COMPLIANT
//! owner-stage: 8
//! required-verdict: check-fail at the typed binding
//! exact-type: lookup elimination is `&List[i64]`; demand is owned `List[i64]`
//! expected-diagnostic: a borrowed `List[i64]` cannot become owned because it is not Copy; suggest explicit `.cloned()` only if applicable
//! origin-set: no owned result is formed; the view would have `{map}`
//! drop-behavior: rejection precedes codegen; the map remains the sole owner

use std.collections.HashMap
fn main:
    var map: HashMap[i32, List[i64]] = HashMap.new()
    let stored: List[i64] = List.new()
    stored.push(111)
    map.insert(1, move stored)
    let owned: List[i64] = map.get(1).unwrap()
    assert(owned[0] == 111)
