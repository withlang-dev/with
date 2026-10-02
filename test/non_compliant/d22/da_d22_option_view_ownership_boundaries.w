//! D22-NON-COMPLIANT
//! owner-stage: 5
//! required-verdict: compile-and-run under `--debug-alloc`
//! exact-type: `copied` is `Option[i32]`; `cloned` is `Option[Vec[i64]]`
//! expected-diagnostic: none
//! origin-set: `.copied()` and `.cloned()` results both have `{}`
//! drop-behavior: copied scalar is independent; cloned and map-owned Vec buffers each drop once; leak count=0
//! expect-debug-alloc: leak count=0

use std.collections.HashMap
fn main:
    var counts: HashMap[i32, i32] = HashMap.new()
    counts.insert(1, 61)
    let copied: Option[i32] = counts.get(1).copied()
    counts.clear()
    assert(copied.unwrap() == 61)

    var jobs: HashMap[i32, Vec[i64]] = HashMap.new()
    let stored: Vec[i64] = Vec.new()
    stored.push(62)
    jobs.insert(1, move stored)
    let cloned: Option[Vec[i64]] = jobs.get(1).cloned()
    jobs.clear()
    let owned = cloned.unwrap()
    assert(owned[0] == 62)
