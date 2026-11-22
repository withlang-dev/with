//! expect-stdout: ok

// D155 (§16.1): the C aliases are the compiler's builtins, the target's, and
// no import, migration or module needs to declare one. `char` is unsigned on
// AArch64 Linux and on wasm, `long` is 32 bits on Windows and wasm32, and a C
// string literal's bytes are `c_char`s: `c"…".ptr` is `*const c_char`. One
// expectation per target pins the widths and signs, so an alias that drifts
// on one host is caught here, not by a seed leg.
use std.os.Target

const LONG_BYTES: u64 = comptime match Target.os:
    .Windows => 4u64
    .Macos => 8u64
    .Linux => 8u64
    .Wasi => 4u64

const CHAR_IS_UNSIGNED: bool = comptime match Target.os:
    .Windows => false
    .Macos => false
    .Linux => comptime match Target.arch:
        .Aarch64 => true
        .X86_64 => false
        .Wasm32 => true
        .Wasm64 => true
    .Wasi => true

fn main:
    assert(sizeof[c_char]() == 1)
    assert(sizeof[c_short]() == 2 and sizeof[c_ushort]() == 2)
    assert(sizeof[c_int]() == 4 and sizeof[c_uint]() == 4)
    assert(sizeof[c_long]() == LONG_BYTES and sizeof[c_ulong]() == LONG_BYTES)
    assert(sizeof[c_longlong]() == 8 and sizeof[c_ulonglong]() == 8)
    // 0xff as the target's char: 255 where char is unsigned, -1 where signed.
    let ff = (255 as u8 as c_char) as i32
    assert(ff == (if CHAR_IS_UNSIGNED: 255 else: -1))
    // The literal's bytes are c_chars on every target.
    let p: *const c_char = c"ok".ptr
    let first = unsafe { *p } as i32
    assert(first == 111)
    print("ok")
