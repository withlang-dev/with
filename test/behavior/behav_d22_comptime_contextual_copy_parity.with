// D22 acceptance cell, promoted 2026-10-18 (the matrix's metadata follows).
// owner-stage: 7
// required-verdict: comptime, native, and C-emitted execution all produce `117`
// exact-type: comptime lookup is `Option[&i32]`; declared return context materializes owned `i32`
// expected-diagnostic: none in any semantic engine or backend
// origin-set: the returned contextual Copy has `{}`
// drop-behavior: comptime storage is finalized once; native and C map storage drop once

use std.collections.HashMap
fn d22_lookup() -> i32:
    var map: HashMap[i32, i32] = HashMap.new()
    map.insert(1, 117)
    map.get(1).unwrap()

const D22_VALUE: i32 = comptime d22_lookup()

fn main: assert(D22_VALUE == 117)
