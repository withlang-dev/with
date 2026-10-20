//! check-only

// D91 (§17.1a) under D30: compile-time code reads the target's OS and
// architecture from the build's target, also when the runtime is in-unit
// and `with_sysinfo_os` has a body there. That body asks the host (and its
// c"..." literal is not comptime-evaluable): every std module computing a
// constant from `Target.os` (std.libc's ULONG_MAX) failed to check.
use std.os

const WORD = comptime match Target.os:
    .Windows => "windows"
    .Macos => "macos"
    .Linux => "linux"
    .Wasi => "wasi"

const WIDE = comptime if Target.arch == .Aarch64 or Target.arch == .X86_64: 8 else: 4

fn main:
    print(f"{WORD} {WIDE}")
