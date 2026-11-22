//! expect-debug-alloc: leak count=0
// D22 acceptance cell, promoted 2026-10-18 (the matrix's metadata follows).
// owner-stage: 6
// required-verdict: compile-and-run under `--debug-alloc`
// exact-type: `Owner.map` is an owned `HashMap[i32, i32]`
// expected-diagnostic: none
// origin-set: no ephemeral view escapes
// drop-behavior: aggregate construction transfers the map into `Owner`; the map header and tables drop exactly once

use std.collections.HashMap
type Owner { map: HashMap[i32, i32] }

fn make_owner() -> Owner:
    let map: HashMap[i32, i32] = HashMap.new()
    Owner { map }

fn main:
    let owner = make_owner()
    assert(owner.map.len() == 0)
