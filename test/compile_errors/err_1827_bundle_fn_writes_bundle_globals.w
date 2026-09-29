//! expect-check-fail: call to `alloc_test_set_limit` mutates global `allocation_limit` while `r` is a live view into it

// #1827 (§9.1c: globals are places; §21.1 rule 1; D39): `allocation_limit`
// is a `var` the c_algorithms bundle exports through its interface, and
// `alloc_test_set_limit` (the corpus's alloc_testing harness module, compiled
// from source beside the bundle) assigns it: a view of `allocation_limit`
// live across the call is refused, exactly as across any source callee.
// behav_1827_bundle_fn_precise_global_writes.w holds the same view across
// `to_upper`, a bundle function that declares no global write (Eric,
// 2026-09-29: a bundle function's global writes are its declared, checked
// contract, and none declared means none).
use std.c_algorithms.defs
use std.c_algorithms.alloc_testing

fn main:
    let r = &allocation_limit
    alloc_test_set_limit(3)
    print(f"{r}")
