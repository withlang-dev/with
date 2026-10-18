//! expect-error: cannot mutate `primary` while `view` is a live view into it
// D22 acceptance cell, promoted 2026-10-18 (the matrix's metadata follows).
// owner-stage: 4
// required-verdict: check-fail at `primary.clear()`
// exact-type: `view` is `&i32`
// expected-diagnostic: cannot mutate `primary` while `view` is a live view into it
// origin-set: `Result.unwrap_or` gives `view` `{primary, fallback}`
// drop-behavior: rejection precedes codegen; both maps retain ownership

use std.collections.HashMap
fn main:
    var primary: HashMap[i32, i32] = HashMap.new()
    var fallback: HashMap[i32, i32] = HashMap.new()
    primary.insert(1, 91)
    fallback.insert(1, 92)
    let result: Result[&i32, str] = Ok(primary.get(1).unwrap())
    let view = result.unwrap_or(fallback.get(1).unwrap())
    primary.clear()
    assert(view == 91)
