//! expect-stdout: ok

use std.collections.Vec
use std.libc.atoi

var conversions: [3]extern "C" fn(*const i8) -> i32 = [atoi, atoi, null]

fn invoke(callback: &fn(i32) -> i32): callback(20)
fn invoke_c(callback: &extern "C" fn(*const i8) -> i32): callback(c"21".ptr)

fn main:
    assert(conversions[0](c"21".ptr) == 21)
    assert(conversions[1](c"-7".ptr) == -7)
    assert(conversions[2] == null)
    assert(invoke_c(conversions[0]) == 21)
    let increase: fn(i32) -> i32 = value => value + 1
    assert(invoke(increase) == 21)
    var callbacks: Vec[fn(i32) -> i32] = Vec.new()
    callbacks.push(increase)
    assert(callbacks[0](30) == 31)
    assert(callbacks.get(0)(40) == 41)
    print("ok")
