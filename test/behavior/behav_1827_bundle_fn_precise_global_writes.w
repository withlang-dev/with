//! expect-stdout: 65 -1

// #1827 (§21.1 rule 1; D39, Eric 2026-09-29): a call of a bundle function
// writes exactly its declared write set, and no declaration means none — a
// contract the bundle build checked against the body. `to_upper` is a
// bundle function (the c_algorithms bundle's interface declares it with no
// body in this program) that declares no global write, so a view of
// `allocation_limit`, a `var` the same bundle exports, stays live across the
// call. (The parent compiler refused this as a call that "counts as writing
// every global its bundle exports"; err_1827_bundle_fn_writes_bundle_globals.w
// is a call that does write it.)
use std.c_algorithms.defs

fn main:
    let r = &allocation_limit
    let u = to_upper(97)
    print(f"{u} {r}")
