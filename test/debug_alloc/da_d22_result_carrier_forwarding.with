//! expect-debug-alloc: leak count=0
// D22 acceptance cell, promoted 2026-10-18 (the matrix's metadata follows).
// owner-stage: 5
// required-verdict: compile-and-run under `--debug-alloc`
// exact-type: `carry` is `Result[&i32, str]`; `view` is `&i32`; `snapshot` is `i32`
// expected-diagnostic: none
// origin-set: carrier and `view` have `{map}`; contextual Copy gives `snapshot` `{}`
// drop-behavior: map storage remains singly owned and drops once; leak count=0

use std.collections.HashMap
fn carry(map: &HashMap[i32, i32]) -> Result[&i32, str]:
    Ok(map.get(1).unwrap())

fn main:
    var map: HashMap[i32, i32] = HashMap.new()
    map.insert(1, 81)
    let view = carry(&map).unwrap()
    let snapshot: i32 = view
    map.clear()
    assert(snapshot == 81)
