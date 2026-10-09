//! D22-NON-COMPLIANT
//! owner-stage: 6
//! required-verdict: compile-and-run under `--debug-alloc`
//! exact-type: `found` is `Option[&List[i64]]`; `view` is `&List[i64]`; `removed` is `Option[List[i64]]`
//! expected-diagnostic: none
//! origin-set: `view` has `{map}`; removed values have `{}`
//! drop-behavior: replaced, removed, and retained List buffers drop exactly once; leak count=0
//! expect-debug-alloc: leak count=0

// D22 gives BTreeMap the same ownership split as HashMap: get borrows map
// storage uniformly, while insert rotation/replacement and remove transfer
// every non-Copy value exactly once.
use std.collections.BTreeMap
fn values(a: i64, b: i64):
    let out: List[i64] = List.new()
    out.push(a)
    out.push(b)
    out

fn main:
    let map: BTreeMap[i32, List[i64]] = BTreeMap.new()
    map.insert(30, values(30, 31))
    map.insert(10, values(10, 11))
    map.insert(20, values(20, 21))
    map.insert(20, values(200, 201))
    assert(map.len() == 3)

    let found: Option[&List[i64]] = map.get(20)
    assert(found.is_some())
    let view = found.unwrap()
    assert(view.len() == 2)
    assert(view[0] == 200)

    let removed: Option[List[i64]] = map.remove(20)
    assert(removed.is_some())
    let owned = removed.unwrap()
    assert(owned.len() == 2)
    assert(owned[1] == 201)
    assert(map.get(20).is_none())
    assert(map.get(10).is_some())
    assert(map.get(30).is_some())

    let first = map.remove(10).unwrap()
    assert(map.get(30).is_some())
    let last = map.remove(30).unwrap()
    assert(first[0] == 10)
    assert(last[0] == 30)
