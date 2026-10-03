//! only-on: linux
//! expect-stdout: ok

use compiler.Link
use compiler.Runtime
use std.process

// #1915: a Linux link reads an object's undefined symbols itself, as
// `nm -u` printed them, instead of running the host's nm: a host without
// binutils otherwise failed the probe and the compiler's own link left out
// LLVM and libclang. This binary is an ELF file whose undefined symbols are
// what it imports from glibc; `main` it defines.

// A symbol table name may carry its version (`malloc@GLIBC_2.17`).
fn has_symbol(text: &str, name: &str) -> bool:
    for line in text.split("\n"):
        if line == name or line.starts_with(name ++ "@"): return true
    false

fn main:
    let undef = link_stage_elf_undefined_symbols(args()[0])
    assert(undef != "<probe-failed>" and undef != "<not-elf>")
    assert(has_symbol(undef, "malloc"))
    assert(has_symbol(undef, "free"))
    assert(not has_symbol(undef, "main"))
    let not_elf = runtime_getenv("TMPDIR") ++ f"/with-not-elf-{runtime_getpid()}.txt"
    assert(runtime_write_file(not_elf, "not an object file\n") == 0)
    assert(link_stage_elf_undefined_symbols(not_elf) == "<not-elf>")
    let _ = runtime_remove_file(not_elf)
    print("ok")
