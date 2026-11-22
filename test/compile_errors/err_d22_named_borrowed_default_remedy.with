//! expect-error: `??` would need to copy a `Job`, which is not Copy
//! expect-check-fail: help: call `.clone()` on the borrowed side
// D22 acceptance cell, promoted 2026-10-18 (the matrix's metadata follows).
// owner-stage: 8
// required-verdict: check-fail at the `??` join
// exact-type: success is `&List[i64]`; the named default is owned `List[i64]`
// expected-diagnostic: `??` would need to copy a `List[i64]`, which is not Copy; suggest a lifetime-correct borrowed default
// origin-set: no result is formed; success would have `{jobs}`
// drop-behavior: rejection precedes codegen; `jobs` and `fallback` retain ownership

use std.collections.HashMap
resource type Job { id: i64 }
impl Clone for Job:
    fn clone() -> Job: Job { id: self.id }

fn main:
    var jobs: HashMap[i32, Job] = HashMap.new()
    jobs.insert(1, Job { id: 54 })
    let fallback = Job { id: 0 }
    let owned = jobs.get(1) ?? fallback
    assert(owned.id == 54)
