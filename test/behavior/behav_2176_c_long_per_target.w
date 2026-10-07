//! expect-stdout: ok

// #2176 (§16.1): c_import's C type aliases are the target's. `long` is 32
// bits on Windows and wasm32, 64 elsewhere, and `char` is unsigned on
// AArch64 Linux; the With side (`c_long`, `sizeof[S]()`) and the C side
// (`sizeof(struct S)`, parsed by clang for the same target) agree on every
// host this runs on.
use std.sysinfo
use c_import("struct S { long a; long b; };
static inline unsigned long s_size(void) { return sizeof(struct S); }
static inline int char_min(void) { return (int)(char)255; }
")

const LONG_BYTES: i32 = comptime match Target.os:
    .Windows => 4
    .Macos => 8
    .Linux => 8
    .Wasi => 4

fn main:
    assert(sizeof[c_long]() == LONG_BYTES as u64)
    assert(sizeof[S]() == s_size() as u64)
    // (char)255 is -1 where char is signed, 255 where it is unsigned: the
    // alias's signedness matches the parsed target's.
    let signed_char = char_min() == -1
    assert(signed_char == (sizeof[c_char]() == 1 and (0 as c_char) as i32 - 1 < 0 and (255 as u8 as c_char) as i32 == -1))
    print("ok")
