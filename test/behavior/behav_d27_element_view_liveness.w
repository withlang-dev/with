//! expect-stdout: 171
// D144 (amending D27 R3 for plain bits): an unannotated `let` of a
// plain-bits element place takes the value, so `cur` is 0xAB and the write
// after it is fine. #887 (the GHASH corruption) read the post-mutation
// byte through a silent view; the value cannot see the write.
use std.builtins.print_i32
fn main:
    var v: [u8; 2] = [0xABu8, 0u8]
    let cur = v[0]
    v[0] = 0x11u8
    print_i32(cur as i32)
