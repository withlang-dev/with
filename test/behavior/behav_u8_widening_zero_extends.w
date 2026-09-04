//! expect-stdout: 255
//! expect-stdout: 255
//! expect-stdout: 255
//! expect-stdout: 255
//! expect-stdout: 255
//! expect-stdout: 255
//! expect-stdout: 255
//! expect-stdout: 255
//! expect-stdout: 255
//! expect-stdout: 200
//! expect-stdout: 255
//! expect-stdout: 255

// #1017: an unsigned source zero-extends on every spelling of a widening
// (spec §1323) — element place, view binding, materialized u8 local, str
// index, call argument, `as` cast. Codegen used to sign-extend a u8 that
// arrived as a call argument or through a str index (str's element type was
// tabled as i32, byte_at's old return type), so 0xFF read as -1.
use std.builtins.print_i64
fn take(x: i64) -> i64: x
fn take32(x: i32) -> i32: x

fn main:
    var v: Vec[u8] = Vec.new()
    v.push(255 as u8)
    let b: u8 = v[0]
    let w: i64 = b
    print_i64(w)
    print_i64(take(b))
    print_i64(take(v[0]))
    print_i64(take32(b) as i64)
    print_i64(take32(v[0]) as i64)
    let s = "\xff"
    print_i64(take(s[0]))
    print_i64(s[0] as i64)
    let sb = s[0]
    print_i64(take(sb))
    let e = v[0]
    print_i64(take(e))
    let c: u8 = 200 as u8
    print_i64(take(c))
    if s[0] == 255 as u8: print_i64(255) else: print_i64(-1)
    var total: i64 = 0
    for i in 0..s.len():
        total = total + s[i]
    print_i64(total)
