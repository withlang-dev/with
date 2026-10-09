//! D22-NON-COMPLIANT
//! owner-stage: 6
//! required-verdict: compile-and-run under `--debug-alloc`
//! exact-type: generic direct and pattern forwarding are uniformly `Option[&V]` for `i32` and `List[i64]`
//! expected-diagnostic: none
//! origin-set: each forwarded result has only its receiver map origin
//! drop-behavior: lookup never creates an owner; remove transfers the List; all allocations drop once; leak count=0
//! expect-debug-alloc: leak count=0

use std.collections.HashMap
fn find[K, V](map: &HashMap[K, V], key: K) -> Option[&V]:
    map.get(key)

fn find_through_pattern[K, V](map: &HashMap[K, V], key: K) -> Option[&V]:
    match map.get(key):
        Some(value) => Some(value)
        None => None

fn main:
    var counts: HashMap[i32, i32] = HashMap.new()
    counts.insert(1, 71)
    let count: Option[&i32] = find(&counts, 1)
    assert(count.unwrap() == 71)
    let patterned_count: Option[&i32] = find_through_pattern(&counts, 1)
    assert(patterned_count.unwrap() == 71)

    var jobs: HashMap[i32, List[i64]] = HashMap.new()
    let stored: List[i64] = List.new()
    stored.push(72)
    jobs.insert(1, move stored)
    let job: Option[&List[i64]] = find(&jobs, 1)
    assert(job.unwrap()[0] == 72)
    let patterned_job: Option[&List[i64]] = find_through_pattern(&jobs, 1)
    assert(patterned_job.unwrap()[0] == 72)

    let owned = jobs.remove(1).unwrap()
    assert(owned[0] == 72)
