//! expect-stdout: ok

// D91 (§17.5): `Target.os` and `Target.arch` are compile-time constants of
// `std.os`'s enums, the target's and not the host's. A per-target value is
// a `comptime match`, exhaustive over every target; a `comptime if` selects
// code, and the branch not taken is not compiled (it may name what exists
// only on its own target).

use std.os.Target
use std.sysinfo

const SEPARATOR: str = comptime match Target.os:
    .Windows => "\\"
    .Macos => "/"
    .Linux => "/"
    .Wasi => "/"

const POINTER_BITS: i32 = comptime match Target.arch:
    .Aarch64 => 64
    .X86_64 => 64
    .Wasm32 => 32
    .Wasm64 => 64

fn family() -> str:
    // No test runs as a wasm64 program, so this branch is never the taken one.
    comptime if Target.arch == .Wasm64:
        a_name_only_wasm64_declares()
    else:
        "native"

fn name_of_target() -> str:
    match Target.os:
        .Macos => "Macos"
        .Linux => "Linux"
        .Windows => "Windows"
        .Wasi => "Wasi"

fn main:
    // This test runs where it was compiled, so the target is the host.
    assert(name_of_target() == sysinfo.os())
    assert(POINTER_BITS == 64)
    if sysinfo.os() == "Windows":
        assert(SEPARATOR == "\\")
    else:
        assert(SEPARATOR == "/")
        assert(family() == "native")
    print("ok")
