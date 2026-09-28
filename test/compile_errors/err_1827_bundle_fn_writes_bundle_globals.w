//! expect-check-fail: call to `to_upper` mutates global `allocation_limit` while `r` is a live view into it

// #1827 (§9.1c: globals are places; §21.1 rule 1; D39): `to_upper` is a
// bundle function — the c_algorithms bundle's interface declares it with no
// body in this program — and `allocation_limit` is a `var` that bundle
// exports. A declaration states nothing about the globals its body writes,
// so the call counts as writing every global its bundle exports: assuming
// the write can only refuse a valid program; assuming none would let a view
// of the bundle's storage dangle across a call that rewrites it.
use std.c_algorithms.defs

fn main:
    let r = &allocation_limit
    let u = to_upper(97)
    print(f"{u} {r}")
