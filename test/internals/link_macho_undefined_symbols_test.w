//! only-on: darwin
//! expect-stdout: ok

use compiler.Link
use compiler.Runtime
use std.process

// #1915: a native macOS link reads an object's undefined symbols itself, as
// `nm -u` printed them, instead of running the host's nm (which is Xcode's).
// This binary is a Mach-O file whose undefined symbols are what it imports
// from libSystem; `main` it defines.

fn has_line(text: &str, name: &str) -> bool:
    for line in text.split("\n"):
        if line == name: return true
    false

fn main:
    let undef = link_stage_macho_undefined_symbols(args()[0])
    assert(undef != "<probe-failed>")
    assert(has_line(undef, "_malloc"))
    assert(has_line(undef, "_free"))
    assert(not has_line(undef, "_main"))
    let not_macho = runtime_getenv("TMPDIR") ++ f"/with-not-macho-{runtime_getpid()}.txt"
    assert(runtime_write_file(not_macho, "not an object file\n") == 0)
    assert(link_stage_macho_undefined_symbols(not_macho) == "<probe-failed>")
    let _ = runtime_remove_file(not_macho)
    print("ok")
