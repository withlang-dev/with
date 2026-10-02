//! D22-NON-COMPLIANT
//! owner-stage: 6
//! required-verdict: compile-and-run under `--debug-alloc`
//! exact-type: replacement preserves `HashMap[K, V]`; lookup remains `Option[&V]`
//! expected-diagnostic: none
//! origin-set: lookup views retain only the map receiver origin
//! drop-behavior: displaced values and unused duplicate keys drop once; retained entries drop once; leak count=0
//! expect-debug-alloc: leak count=0

use std.collections.HashMap
use std.collections.HashSet
fn values(n: i64) -> Vec[i64]:
    let out: Vec[i64] = Vec.new()
    out.push(n)
    out

fn main:
    var values_by_id: HashMap[i32, Vec[i64]] = HashMap.new()
    values_by_id.insert(1, values(1))
    values_by_id.insert(1, values(2))
    assert(values_by_id.get(1).unwrap()[0] == 2)

    var counts: HashMap[str, i32] = HashMap.new()
    let first = "owned" ++ "-key"
    let second = "owned-" ++ "key"
    counts.insert(first, 1)
    counts.insert(second, 2)
    assert(counts.get("owned-key").unwrap() == 2)

    var names: HashSet[str] = HashSet.new()
    let name_first = "owned" ++ "-member"
    let name_second = "owned-" ++ "member"
    names.insert(name_first)
    names.insert(name_second)
    assert(names.len() == 1)
