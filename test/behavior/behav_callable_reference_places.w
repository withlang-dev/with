//! expect-stdout: ok

use std.collections.Vec
use std.libc.atoi

// D102 (§16.6): an `extern "C" fn` is never null; the slot that may be
// empty is `Option` of it.
var conversions: [3]Option[extern "C" fn(*const i8) -> i32] = [Some(atoi), Some(atoi), None]

fn invoke(callback: &fn(i32) -> i32): callback(20)
fn invoke_c(callback: &extern "C" fn(*const i8) -> i32): callback(c"21".ptr)

fn main:
    assert(conversions[0].unwrap()(c"21".ptr) == 21)
    assert(conversions[1].unwrap()(c"-7".ptr) == -7)
    assert(conversions[2].is_none())
    assert(invoke_c(conversions[0].unwrap()) == 21)
    let increase: fn(i32) -> i32 = value => value + 1
    assert(invoke(increase) == 21)
    var callbacks: Vec[fn(i32) -> i32] = Vec.new()
    callbacks.push(increase)
    assert(callbacks[0](30) == 31)
    assert(callbacks[0](40) == 41)
    print("ok")
