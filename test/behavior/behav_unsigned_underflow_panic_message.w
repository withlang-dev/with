//! skip-windows: issue #797: panic exits 1 not 134 on native Windows
//! expect-exit: 134
//! expect-stderr: integer overflow: u64 subtraction wrapped below zero

// #630: unsigned subtraction wrapping below zero must name the real cause,
// not just say "integer overflow". (Originally pinned via v.len() - 1; D11
// made len() signed so that expression no longer traps — the message is now
// pinned through a pure u64 underflow on a runtime value.)

use std.builtins.print_i64
fn main:
    let v: Vec[i32] = Vec.new()
    let zero: u64 = v.len() as u64
    let n = zero - 1
    print_i64(n as i64)
