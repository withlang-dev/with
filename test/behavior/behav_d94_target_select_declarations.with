//! expect-stdout: ok
// §17.5 (D94): at module level a comptime match or comptime if on the
// target selects declarations. The taken arm's declarations are the
// module's; an arm not taken is parsed and nothing more, so it may name
// what exists only on its own target. Each arm calls a helper only that arm
// declares: whichever host runs this, the arm not taken names a function
// that does not exist there.
use std.os

comptime match Target.os:
    .Windows =>
        fn windows_separator(): "\\"
        fn separator(): windows_separator()
    .Macos | .Linux | .Wasi =>
        fn posix_separator(): "/"
        fn separator(): posix_separator()

comptime if Target.arch == .Wasm32 or Target.arch == .Wasm64:
    const WORD_BYTES = 4
else if Target.arch == .Aarch64:
    const WORD_BYTES = 8
else:
    const WORD_BYTES = 8

comptime match Target.arch:
    .Aarch64 | .X86_64 =>
        type Native { wide: i64 }
    _ =>
        type Native { wide: i32 }

fn main:
    let native = Native { wide: 1 }
    let expected = comptime match Target.os:
        .Windows => "\\"
        .Macos => "/"
        .Linux => "/"
        .Wasi => "/"
    assert(separator() == expected)
    assert(WORD_BYTES == (if Target.arch == .Wasm32 or Target.arch == .Wasm64: 4 else: 8))
    assert(native.wide == 1)
    print("ok")
