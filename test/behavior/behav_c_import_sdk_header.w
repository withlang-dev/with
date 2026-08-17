//! skip-windows: #799: c_import("stdio.h") needs system headers, but the c_import clang invocation (src/compiler/ClangBridge.w) wires macOS -isysroot/-resource-dir with no Windows MSVC/UCRT/UM include dirs or windows target triple, so <stdio.h> is not found on native Windows; inline-decl c_import (no system header) works and is un-skipped
// §16.1: a system-header c_import resolves the target macOS SDK without
// spawning xcrun (env SDKROOT/WITH_SDKROOT, with.toml [c_import] sdk_path, or
// a well-known SDK path). A successful import with modeled constants proves
// the SDK sysroot was found.

use c_import("stdio.h")

fn test_sdk_header_import_resolves:
    assert(SEEK_SET == 0)
    assert(SEEK_END == 2)
