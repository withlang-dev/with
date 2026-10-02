//! expect-stdout: 3

// Drop-exactly-once (§21): shape=f2, scenario=cond_reinit. Runs the
// scenario in its own fn so scope-exit drops fire, counts via a global.
// The consuming call and its reinit share one conditional path, so the
// loop back-edge always carries a live x: a reinit on only SOME repeat
// paths after an unconditional move is ill-formed under §3.8 move
// semantics (the former spelling relied on the superseded D5 share-place
// reading of `use_s(x)`).
use std.builtins.print_i32
var DROPS: i32 = 0
var PTARGET: i32 = 0
type S { a: i32, b: i32 }
impl Drop for S:
    fn drop(move self: Self):
        DROPS = DROPS + 1
fn mk() -> S: S { a: 1, b: 2 }
fn use_s(x: S): ()
fn scenario():
    var x = mk()
    for i in 0..3:
        if i < 2:
            use_s(x)
            x = mk()
fn main:
    scenario()
    assert(DROPS == 3)
    print_i32(DROPS)
