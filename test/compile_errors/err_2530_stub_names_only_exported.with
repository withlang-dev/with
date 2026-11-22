//! only-on: darwin
//! env: SDKROOT=
//! env: WITH_SDKROOT=
//! expect-build-fail: undefined symbol: _sqlite3_enable_load_extension
// #2530: the embedded sysroot's libsqlite3 stub named every function
// sqlite3.h declares, but Apple builds SQLite with
// SQLITE_OMIT_LOAD_EXTENSION: a call linked against the stub and
// crashed when it ran. A stub names only what macOS exports
// (build/darwin_exports), so the call fails at link, as it does against
// Apple's own SDK.
use c_import("sqlite3.h", link: "sqlite3")

fn main:
    unsafe:
        print(sqlite3_enable_load_extension(null, 1))
