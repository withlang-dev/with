// D22 acceptance cell, promoted 2026-10-18 (the matrix's metadata follows).
// owner-stage: 3
// required-verdict: compile-and-run
// exact-type: `?? break` and `?? continue` expose exact `&i32` success payloads
// expected-diagnostic: none
// origin-set: each live loop-local view has `{map}` until contextual Copy into `result`
// drop-behavior: contextual copies are independent; map storage drops once

use std.collections.HashMap
fn via_break(map: &HashMap[i32, i32]) -> i32:
    var result = 0
    loop:
        let view = map.get(1) ?? break
        result = view
        break
    result

fn via_continue(map: &HashMap[i32, i32]) -> i32:
    var result = 0
    for key in 0..2:
        let view = map.get(key) ?? continue
        result = view
    result

fn main:
    var map: HashMap[i32, i32] = HashMap.new()
    map.insert(1, 114)
    assert(via_break(&map) == 114)
    assert(via_continue(&map) == 114)
