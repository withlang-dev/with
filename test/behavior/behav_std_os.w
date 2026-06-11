//! expect-stdout: ok

use std.os

fn valid_os(s: str) -> bool:
    s == "Macos" or s == "Linux" or s == "Windows"

fn valid_arch(s: str) -> bool:
    s == "armv8" or s == "aarch64" or s == "x86_64"

fn main:
    assert(valid_os(os()), "unexpected std.os.os(): " ++ os())
    assert(valid_arch(arch()), "unexpected std.os.arch(): " ++ arch())
    assert(os_kind() != OsKind.Unknown)
    assert(arch_kind() != ArchKind.Unknown)
    assert(hostname().len() > 0)
    assert(process_id() > 0)
    assert(set_env("WITH_STD_OS_TEST", "ok") == 0)
    assert(has_env("WITH_STD_OS_TEST"))
    assert(env("WITH_STD_OS_TEST") == "ok")
    assert(path_exists("docs/with-specification.md"))
    print("ok")
