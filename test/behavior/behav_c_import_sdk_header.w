// §16.1: a system-header c_import resolves the target SDK without spawning
// xcrun. On macOS this is the darwin sysroot the compiler carries, or the SDK
// with.toml [c_import] sdk_path names (§16.1, D81, #1915); on
// native Windows the MSVC CRT +
// Windows SDK include dirs (WITH_WINDOWS_*_INCDIR, wired by ClangBridge.w). A
// successful import with modeled constants proves the include dirs were found.

use c_import("stdio.h")

fn test_sdk_header_import_resolves:
    assert(SEEK_SET == 0)
    assert(SEEK_END == 2)
