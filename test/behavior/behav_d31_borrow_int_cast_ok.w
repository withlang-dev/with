//! expect-stdout: 3
//! 65

// D31 (§16.11): both blessed intents compile and behave. The address intent
// (`&raw const place as u64`, and the `&place as *T` pointer spelling) puns a
// str over a stack buffer through `&raw mut` — the #888 pattern, proving raw
// stores at every offset are honored across a call boundary. The value intent
// stays `place as u64`, no borrow.
use std.builtins.print_i32
fn show_len(s: &str) -> i32: s.len() as i32
fn show_b0(s: &str) -> i32:  s.byte_at(0)
fn main:
    var chunk: str = ""
    let sp = &raw mut chunk as *mut u8
    var target: [u8; 4] = [65u8, 66u8, 67u8, 0u8]
    unsafe:
        *(sp as *mut u64) = (&raw const target[0]) as u64
        *((sp + 8u64) as *mut i64) = 3
    print_i32(show_len(chunk))
    print_i32(show_b0(chunk))
    // value intent: no borrow, direct element cast
    let v = target[0] as u64
    if v != 65: print_i32(-1)
    // pointer-spelling address intent also stays legal
    let addr = (&target[1] as *const u8) as u64
    if addr == 0: print_i32(-2)
