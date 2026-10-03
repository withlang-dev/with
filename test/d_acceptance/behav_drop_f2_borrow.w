//! expect-stdout: 1

// Drop-exactly-once (§21): shape=f2, scenario=borrow. Runs the
// scenario in its own fn so scope-exit drops fire, counts via a global.
var DROPS: i32 = 0
var PTARGET: i32 = 0
type S { a: i32, b: i32 }
impl Drop for S:
    fn drop(move self: Self):
        DROPS = DROPS + 1
fn mk() -> S: S { a: 1, b: 2 }
fn use_s(x: S): ()
fn scenario():
    let x = mk()
    use_s(x)
fn main:
    scenario()
    assert(DROPS == 1)
    print_i32(DROPS)
