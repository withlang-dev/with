//! expect-stdout: known
//! expect-stdout: known
//! expect-stdout: ok
// #2949 (§17.5, D91): `Target.os` is a compile-time constant, so a
// `pub const` or a `let` takes a `comptime match` over it; the value is the
// target's, decided when the program is compiled. Runs under the release
// compiler (the lane's `:test`), which serves std as interfaces: a constant
// it never loaded must still be the import gate's case, not "a runtime
// value" (#2248's symptom).
use std.os.Target

pub const NAME: str = comptime match Target.os:
    .Macos => "mac"
    .Linux => "linux"
    .Windows => "win"
    .Wasi => "wasm"

fn arch_word() -> str:
    comptime match Target.arch:
        .X86_64 => "x86_64"
        .Aarch64 => "aarch64"
        .Wasm32 => "wasm32"

fn main:
    print(if NAME == "mac" or NAME == "linux" or NAME == "win" or NAME == "wasm": "known" else: NAME)
    let a = arch_word()
    print(if a == "x86_64" or a == "aarch64" or a == "wasm32": "known" else: a)
    comptime if Target.os == .Windows:
        print("ok")
    else:
        print("ok")
