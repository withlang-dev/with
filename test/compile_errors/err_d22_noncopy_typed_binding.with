//! expect-error: type mismatch in binding
// D22 acceptance cell, promoted 2026-10-18 (the matrix's metadata follows).
// owner-stage: 8
// required-verdict: check-fail at the typed binding
// exact-type: lookup elimination is `&List[i64]`; demand is owned `List[i64]`
// expected-diagnostic: a borrowed `List[i64]` cannot become owned because it is not Copy; suggest explicit `.cloned()` only if applicable
// origin-set: no owned result is formed; the view would have `{map}`
// drop-behavior: rejection precedes codegen; the map remains the sole owner

use std.collections.HashMap
resource type Job { id: i64 }
impl Clone for Job:
    fn clone() -> Job: Job { id: self.id }

fn main:
    var map: HashMap[i32, Job] = HashMap.new()
    map.insert(1, Job { id: 111 })
    let owned: Job = map.get(1).unwrap()
    assert(owned.id == 111)
