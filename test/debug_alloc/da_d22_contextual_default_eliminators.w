//! expect-debug-alloc: leak count=0
// D22 acceptance cell, promoted 2026-10-18 (the matrix's metadata follows).
// owner-stage: 5
// required-verdict: compile-and-run under `--debug-alloc`
// exact-type: each `unwrap_or`/`unwrap_or_else` join result is owned `i32`
// expected-diagnostic: none
// origin-set: contextual Copy ends `{map}` on every result
// drop-behavior: no duplicate owner is created; map storage drops once; leak count=0

use std.collections.HashMap
fn main:
    var map: HashMap[i32, i32] = HashMap.new()
    map.insert(1, 73)

    let option_default = map.get(1).unwrap_or(0)
    let option_lazy = map.get(1).unwrap_or_else(() => 0)
    let result: Result[&i32, str] = Ok(map.get(1).unwrap())
    let result_default = result.unwrap_or(0)
    let result2: Result[&i32, str] = Ok(map.get(1).unwrap())
    let result_lazy = result2.unwrap_or_else((_) => 0)

    map.clear()
    assert(option_default == 73)
    assert(option_lazy == 73)
    assert(result_default == 73)
    assert(result_lazy == 73)
