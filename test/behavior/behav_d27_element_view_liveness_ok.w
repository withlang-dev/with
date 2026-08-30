//! expect-stdout: 171
//! 171
//! 17

// The conforming spellings around #887's rejection:
// 1. NLL: the view's last use precedes the mutation — legal (§21.1 rule 4).
// 2. A cast establishes an owned-value demand (D22 §6.2 / D27 R3), so the
//    element SNAPSHOTS and later mutation is free — the GHASH shift shape.
use std.builtins.print_i32
fn main:
    var v: [u8; 2] = [0xABu8, 0u8]
    let cur = v[0]
    print_i32(cur as i32)
    v[0] = 0x11u8
    var w: [u8; 2] = [0xABu8, 0u8]
    let old = w[0] as u32
    w[0] = 0x11u8
    print_i32(old as i32)
    print_i32(w[0] as i32)
