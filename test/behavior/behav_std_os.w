//! expect-stdout: ok

use std.os

fn valid_os(s: str) -> bool:
    s == "Macos" or s == "Linux" or s == "Windows"

fn valid_arch(s: str) -> bool:
    s == "aarch64" or s == "x86_64"

fn main:
    assert(valid_os(os()), "unexpected std.os.os(): " ++ os())
    assert(valid_arch(arch()), "unexpected std.os.arch(): " ++ arch())
    assert(os_kind() == Target.os)
    assert(arch_kind() == Target.arch)
    assert(hostname().len() > 0)
    assert(process_id() > 0)
    assert(set_env("WITH_STD_OS_TEST", "ok") == 0)
    assert(has_env("WITH_STD_OS_TEST"))
    assert(env("WITH_STD_OS_TEST") == "ok")
    assert(path_exists("docs/spec/README.md"))
    print("ok")
