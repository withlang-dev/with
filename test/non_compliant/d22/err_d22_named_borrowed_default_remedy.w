//! D22-NON-COMPLIANT
//! owner-stage: 8
//! required-verdict: check-fail at the `??` join
//! exact-type: success is `&List[i64]`; the named default is owned `List[i64]`
//! expected-diagnostic: `??` would need to copy a `List[i64]`, which is not Copy; suggest a lifetime-correct borrowed default
//! origin-set: no result is formed; success would have `{jobs}`
//! drop-behavior: rejection precedes codegen; `jobs` and `fallback` retain ownership

use std.collections.HashMap
fn main:
    var jobs: HashMap[i32, List[i64]] = HashMap.new()
    let stored: List[i64] = List.new()
    jobs.insert(1, move stored)
    let fallback: List[i64] = List.new()
    let owned = jobs.get(1) ?? fallback
    assert(owned.len() == 0)
