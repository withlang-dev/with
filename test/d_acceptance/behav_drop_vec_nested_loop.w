//! expect-stdout: 4

// Drop-exactly-once (§21): shape=vec, scenario=nested_loop. Runs the
// scenario in its own fn so scope-exit drops fire, counts via a global.
use std.builtins.print_i32
var DROPS: i32 = 0
var PTARGET: i32 = 0
type S { a: i32, v: Vec[i32] }
impl Drop for S:
    fn drop(move self: Self):
        DROPS = DROPS + 1
fn mk() -> S: S { a: 1, v: Vec.new() }
fn use_s(x: S): ()
fn scenario():
    for i in 0..2:
        for j in 0..2:
            let x = mk()
fn main:
    scenario()
    assert(DROPS == 4)
    print_i32(DROPS)
