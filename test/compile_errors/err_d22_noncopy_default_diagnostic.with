//! expect-error: `??` would need to copy a `Job`, which is not Copy
//! expect-check-fail: help: call `.clone()` on the borrowed side
// D22 acceptance cell, promoted 2026-10-18 (the matrix's metadata follows).
// owner-stage: 8
// required-verdict: check-fail at the `??` join
// exact-type: success is `&List[i64]`; default is owned `List[i64]`
// expected-diagnostic: `??` would need to copy a non-Copy List; offer only applicable `.cloned()`, borrowed-default, or `remove` remedies
// origin-set: no result is formed; success would have `{jobs}`
// drop-behavior: rejection precedes codegen; both map and default retain ownership

use std.collections.HashMap
resource type Job { id: i64 }
impl Clone for Job:
    fn clone() -> Job: Job { id: self.id }

fn main:
    var jobs: HashMap[i32, Job] = HashMap.new()
    jobs.insert(1, Job { id: 54 })

    // Must explain that ?? would need to copy a non-Copy Job, then offer
    // .clone(), a borrowed default, or remove only when each is applicable.
    let owned = jobs.get(1) ?? Job { id: 0 }
    assert(owned.id == 54)
