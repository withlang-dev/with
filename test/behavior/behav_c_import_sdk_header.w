// §16.1: a system-header c_import resolves the target SDK without spawning
// xcrun. On macOS this is the SDK sysroot (env SDKROOT/WITH_SDKROOT, with.toml
// [c_import] sdk_path, or a well-known path); on native Windows the MSVC CRT +
// Windows SDK include dirs (WITH_WINDOWS_*_INCDIR, wired by ClangBridge.w). A
// successful import with modeled constants proves the include dirs were found.

use c_import("stdio.h")

fn test_sdk_header_import_resolves:
    assert(SEEK_SET == 0)
    assert(SEEK_END == 2)
