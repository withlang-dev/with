//! expect-stdout: 7 9

// #2047: the free channel builtins over an i64 handle (Channel(cap),
// send(ch, v), recv(ch)). MirLower lowered them with no operands, so codegen
// read whatever operands followed the call (#2043). Codegen also called the
// runtime as with_channel_send(ptr, i64) and with_channel_recv(ch) against
// rt/channel_runtime.w's `(i64, *const u8)` and `(i64, *mut u8) -> i32`, so
// `recv` printed an address. Every runtime call now goes through
// call_runtime_checked, which reports a call that disagrees with the
// declaration as a compiler bug.
fn main:
    let ch = Channel(4)
    send(ch, 7)
    send(ch, 9)
    let a = recv(ch)
    let b = recv(ch)
    print(f"{a} {b}")
