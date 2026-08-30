//! expect-check-fail: is a live view into it

// D27 R3: an unannotated `let` of an element place binds the VIEW. §21.1
// rule 1 then requires rejecting mutation of the viewed place while the
// view is live — this was silently accepted (#887, the GHASH corruption):
// the stale read printed the post-mutation byte.
use std.builtins.print_i32
fn main:
    var v: [u8; 2] = [0xABu8, 0u8]
    let cur = v[0]
    v[0] = 0x11u8
    print_i32(cur as i32)
