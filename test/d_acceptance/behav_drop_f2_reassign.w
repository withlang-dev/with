//! expect-stdout: 2

// Drop-exactly-once (§21): shape=f2, scenario=reassign. Runs the
// scenario in its own fn so scope-exit drops fire, counts via a global.
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
    x = mk()
fn main:
    scenario()
    assert(DROPS == 2)
    print_i32(DROPS)
