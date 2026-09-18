//! os probe: layer-1 wrappers vs libc-documented values (python3 oracle).

use std.os

fn main:
    print(os())
    print(arch())
    print(hostname())
    assert(os_kind() != OsKind.Unknown)
    assert(arch_kind() != ArchKind.Unknown)
    assert(process_id() > 0)
    assert(process_id() == posix_process_id())
    if posix_fd_is_terminal(1):
        print("tty")
    else:
        print("notty")
    assert(set_env("WITH_AUDIT_OS_PROBE", "probe-ok") == 0)
    assert(has_env("WITH_AUDIT_OS_PROBE"))
    assert(env("WITH_AUDIT_OS_PROBE") == "probe-ok")
    assert(env("WITH_AUDIT_OS_DEFINITELY_UNSET") == "")
    assert(has_env("WITH_AUDIT_OS_DEFINITELY_UNSET") == false)
    assert(path_exists("lib/std/os.w"))
    assert(path_exists("no-such-audit-file-xyz") == false)
    print("ok")
