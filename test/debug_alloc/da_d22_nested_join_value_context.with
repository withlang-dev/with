//! expect-debug-alloc: leak count=0
// D22 acceptance cell, promoted 2026-10-18 (the matrix's metadata follows).
// owner-stage: 5
// required-verdict: compile-and-run under `--debug-alloc`
// exact-type: inferred `view` is `&i32`; enclosing call, assignment, and operator demands keep all three nested joins owned `i32`
// expected-diagnostic: none
// origin-set: every result is owned and has `{}`
// drop-behavior: no reference or owner is duplicated; leak count=0

use std.collections.HashMap
fn take(value: i32): value + 1

fn main:
    var map: HashMap[i32, i32] = HashMap.new()
    map.insert(1, 73)
    let view = map.get(1).unwrap()
    let nested = take(if true: view else: 70)
    var assigned: i32 = 0
    assigned = if false: 71 else: view
    let operated = 1 + (if true: view else: 74)
    map.clear()
    assert(nested == 74)
    assert(assigned == 73)
    assert(operated == 74)
