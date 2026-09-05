//! args: --overflow=wrap
//! expect-stdout: ok

// S0 for #943, --overflow=wrap lane.
//
// `2147483647i64 + 1i64` does not overflow i64 — the correct answer is
// 2147483648 in every overflow mode. The comptime evaluator does the
// arithmetic at 32 bits, so it applies i32 overflow *semantics* to an
// expression that never overflows:
//
//     --overflow=wrap      comptime -2147483648, runtime 2147483648
//     --overflow=saturate  comptime  2147483647, runtime 2147483648
//
// This is the governing rule stated as a test: comptime and runtime must reach
// the same decision about whether an operation overflows. Under the default
// panic mode the same expression is a compile error, pinned separately in
// test/compile_errors/comptime_int_width_overflow.w.

comptime fn edge -> i64:
    2147483647i64 + 1i64

const CT: i64 = comptime edge()

fn main:
    var r: i64 = 2147483647
    let rt = r + 1

    assert(rt == 2147483648)
    assert(CT == 2147483648)
    assert(CT == rt)
    print("ok")
