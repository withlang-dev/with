// §16.1: a system-header c_import resolves the target macOS SDK without
// spawning xcrun (env SDKROOT/WITH_SDKROOT, with.toml [c_import] sdk_path, or
// a well-known SDK path). A successful import with modeled constants proves
// the SDK sysroot was found.

use c_import("stdio.h")

fn test_sdk_header_import_resolves:
    assert(SEEK_SET == 0)
    assert(SEEK_END == 2)
